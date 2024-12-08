# 任务要求

对实验报告的要求:

* 基于markdown格式来完成，以文本方式为主
* 填写各个基本练习中要求完成的报告内容
* 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
* 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

## 练习0: 填写已有实验

本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

## 练习1: 分配并初始化一个进程控制块（需要编码）

alloc_proc 函数（位于kern/process/proc.c中）负责分配并返回一个新的 struct proc_struct 结构, 用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

    【提示】在 alloc_proc 函数的实现中，需要初始化的 proc_struct 结构中的成员变量至少包括: state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题: 

* 请说明 proc_struct 中 `struct context context` 和 `struct trapframe *tf` 成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

#### Ans :

实验手册中的说明:

* `struct context context` : `context` 中保存了进程执行的上下文, 也就是几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态（进程切换的详细过程在后面会介绍）。切换过程的实现在kern/process/switch.S。进程上下文使用结构体 `struct context` 保存，其中包含了ra，sp，s0~s11共14个寄存器。

* `struct trapframe *tf` : `tf` 里保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中（注意这里需要保存的执行状态数量不同于上下文切换）。系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。

代码注释:

* `struct context context` : Switch here to run process

* `struct trapframe *tf` : Trap frame for current interrupt

实际作用:

* `struct context context` : context 用于恢复进程执行上下文, 只有一个使用函数 `switch_to`, 其使用函数定义位于 **switch.S**, 通过汇编语句 `STORE` 和 `LOAD` 实现寄存器的保存与恢复, 即前一个进程和后一个进程执行现场的保存和切换。

* `struct trapframe *tf` : tf 中除了保存各寄存器外, 还有一些状态值(线程状态 status 和 入口点 epc)。进程中断帧的使用有两处 : 创建内核线程( `kernel_thread` )需要先初始化中断帧; 复制内核线程( `copy_thread` )需要修改寄存器 a0 和 sp 的值(需要理解 `copy_thread` 函数)。当进程从用户空间跳到内核空间时，中断帧记录了进程在被中断前的状态。当内核需要跳回用户空间时，需要调整中断帧以恢复让进程继续执行的各寄存器值。

## 练习2: 为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread 函数通过调用 do_fork 函数完成具体内核线程的创建工作。do_kernel 函数会调用 alloc_proc 函数来分配并初始化一个进程控制块，但 alloc_proc 只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore 一般通过 do_fork 实际创建新的内核线程。do_fork 的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是 stack 和 trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的 do_fork 函数中的处理过程。它的大致执行步骤包括: 

* 调用 alloc_proc ，首先获得一块用户信息块。
* 为进程分配一个内核栈。
* 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
* 复制原进程上下文到新进程
* 将新进程添加到进程列表
* 唤醒新进程
* 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题: 

* 请说明ucore是否做到给每个新fork的线程一个唯一的id? 请说明你的分析和理由。

#### Ans:

在不超过最大进程数的前提下是:

```c
if (++last_pid >= MAX_PID){
    last_pid = 1;
    goto inside;
}
```

(问题, next_safe变量起什么作用?)



## 练习3: 编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括: 

* 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
* 禁用中断。你可以使用 `/kern/sync/sync.h` 中定义好的宏 `local_intr_save(x)` 和 `local_intr_restore(x)` 来实现关、开中断。
* 切换当前进程为要运行的进程。
* 切换页表，以便使用新进程的地址空间。`/libs/riscv.h` 中提供了 `lcr3(unsigned int cr3)` 函数, 可实现修改CR3寄存器值的功能。
* 实现上下文切换。`/kern/process` 中已经预先编写好了 `switch.S`，其中定义了 `switch_to()` 函数。可实现两个进程的context切换。
* 允许中断。

请回答如下问题: 

* 在本实验的执行过程中，创建且运行了几个内核线程？

    两个
    * `idle` 不断查询是否有可以执行的线程，如果有则进行调度和执行。在这里将`init`线程设置为runnable就可以下班了
    * `init` 在这里主要作用是输出hello world

完成代码编写后，编译并运行代码: make qemu

如果可以得到如 附录A所示的显示内容 (仅供参考, 不是标准答案输出), 则基本正确。

## 扩展练习 Challenge: 

* 说明语句 `local_intr_save(intr_flag);....local_intr_restore(intr_flag);` 是如何实现开关中断的？

#### Ans:

该语句在 `schedule` 函数中，主要的执行流是，`local_intr_save(intr_flag)`查询是否存处于中断（通过CSR寄存器的sstatus_sie是否为1），如果处于中断，则返回1并关闭中断（将`intr_flag`设置为1，并调用`intr_disable`函数）。而`local_intr_restore`则是若`(intr_flag)`为1，则开启中断（`intr_enable`）。

通过这样的先暂停中断再重启中断，可以保证两代码之间执行的代码在没有中断的情况下进行。以`proc_run`为例，为了保证`current`指针的原子性，使其仅在进程切换时被修改，需要屏蔽中断，此时可以先调用`local_intr_save`临时关闭中断，再使用`local_intr_restore`在处理完后恢复。

## 补充

可参考[这篇文章](https://zhuanlan.zhihu.com/p/541502926)

1. 创建并执行第一个内核进程的执行流
    
    * `init.c::kern_init` 中调用 `proc_init` 函数, 启动了创建内核线程的步骤
    * `proc_init`创建并初始化第 0 个内核线程 idleproc, 并通过 `kernel_thread` 函数创建第 1 个内核线程 initproc
        
        * `kernel_thread`通过实例化中断帧 tf 和 `do_fork` 函数实现
        * `do_fork` 函数作用是创建一个子进程, 通过 `copy_thread` 函数设置新创的子进程上下文和中断帧
        * 在后续的实验中, init_main 的工作就是创建特定的其他内核线程或用户进程
    * `init.c::kern_init` 最后执行 `cpu_idle`, 监听其他进程, 当存在其他进程时, 将第 0 号进程切换到其他进程执行, 即切换到第 1 个进程 initproc, 这一过程通过函数 `schedule` 实现
        * `schedule` 的执行逻辑比较简单 : 设置当前进程的 need_resched 标志位 -> 在 proc_list 队列中查找下一个处于“就绪”态的线程或进程next -> 调用 `proc_run` 函数，保存当前进程current的执行现场, 恢复新进程的执行现场, 完成进程切换

2. 