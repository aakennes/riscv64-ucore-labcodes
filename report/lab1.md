# lab1

## 练习一：理解内核启动中的程序入口操作

原问题：

> 阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？

### la sp, kernstacktop

- 作用：将kernstacktop的地址传入sp（栈指针）寄存器中。
- 目的：为操作系统内核开辟一个栈空间，以便操作系统内核启动

### tail kern_init

- 作用：tail，即tail call，尾调用kern_init函数。需要注意的是tail与call存在区别，前者不建立新的栈帧以提高效率
- 目的：直接跳转到kern_init标签处，开始函数执行。观察init.c的函数，可以发现，这一过程对操作系统的内核进行初始化，如初始化各种数据结构、创建进程、加载设备驱动程序等。

## 练习二：完善中断处理

原问题：

> 请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。
>
> 要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

编程实现：

只需对trap.c进行修改即可

```C++
case IRQ_S_TIMER:
    clock_set_next_event();
    ticks+=1;
    if(ticks==TICK_NUM)//直接用100也可以，但全局变量定义了TICK_NUM，那就用吧
    {
        print_ticks();
        num+=1;
        ticks=0;
    }
    if(num==10)
    {
        sbi_shutdown();//参见./libs/sbi.h
    }
    break;
```

根据代码里面的注释和提示进行编程即可。每100ticks进行一次中断，并且打印相关信息。最后，在连续中断十次之后，再调用shut_down()进行关机。

定时器中断处理的流程：

在clock.c中进行中断处理。

OpenSBI提供的sbi_set_timer()接口，可以传入一个时刻，让它在那个时刻触发一次时钟中断。具体参见源代码中的注释部分。

clock的初始化函数如下：

```c
// Hardcode timebase
static uint64_t timebase = 100000;

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```

SIE（Supervisor Interrupt Enable，启用监管者中断）用于控制和管理处理器的中断状态。在初始化clock时，需要先开启时钟中断。调用 clock_set_next_event() 设置时钟中断事件。

在 clock_set_next_event() 里面，调用sbi_set_timer()接口，将timer的数值变为 get_cycles() + timebase。这样一来，下次时钟中断的发生时间就是当前时间的timebase之后。


## Challenge1

```
描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。
```

### 描述ucore中处理中断异常的流程（从异常的产生开始）

指令发生中断或异常后（在这里是`set_csr`使能时钟中断后，通过`clock_set_next_event`触发`sbi_set_timer`，调用`sbi_call(SBI_SET_TIMER, stime_value, 0, 0)`;后，调用`sbi_call`触发的时钟中断），跳转到初始化`stvec`时（`sbi.c`的`sbi_type`）设置好的处理程序地址，也就是`(trspentry.S)__alltrap`处，通过`SAVE_ALL`保存现场，跳转到`trap`（`jal trap`），并根据`tf->scause`判断是中断还是异常，跳转到对应的处理分支，根据中断/异常类型进入不同分支进行处理，处理完毕后，返回到(`trspentry.S`)`__trapret`，恢复现场，通过sret指令跳转回原来的程序

### 其中mov a0，sp的目的是什么

将栈顶指针作为参数放入`a0`，在传入`trap`时，就可以通过这个栈来获取寄存器的值

### SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的

如图，是连续存储的，由于地址是连续的，所以可以通过偏移来寻址
![alt text](image.png)

### __alltraps 中都需要保存所有寄存器吗

`x0`的值永远是0，可以不保存

## Challenge2

```
在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？
```

### csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么

- `csrw sscratch sp` 将原先的栈顶sp指针保存到sscratch寄存器中
- `csrrw s0, sscratch, x0` 将sscratch寄存器保存到s0（保存现场），再将x0保存到sscratch寄存器，由Challenge1所述，x0的值是0，也就是将sscratch清零，进行上下文切换，也就是先保存现场，再进行上下文切换

总的来说，就是通过sscratch寄存器保存中断和异常时sp的值，处理完毕后恢复现场

### save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

- `scause`寄存器保存了导致异常和中断的原因和相关代码
- `stval`寄存器保存了异常的附加信息（地址异常的地址、非法指令异常的指令地址等）

这两个寄存器的主要作用是处理异常程序时提供重要的信息，当异常已经被处理完毕，显然不需要恢复这两个寄存器的内容了。

## Challenge3

```
编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。
```

```cpp
case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%x\n",tf->epc);
            tf->epc+=4;//指令长度4字节
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type: breakpoint\n");
            cprintf("ebreak caught at 0x%x\n",tf->epc);
            tf->epc+=2;//断点长度2字节
            break;
```

## 补充知识点
### scratch的作用
上下文保存和恢复、临时数据存储、存储中断处理需要的信息、特权模式切换时存储用户模式信息
### stevc的前两位
异常处理模式，00直接模式；01向量模式
### 为什么触发下一时钟时，ecall不会直接重复执行

### 内部中断和外部中断
- 外部中断：由计算机外设发出的中断请求，如键盘、打印机等
- 内部中断：硬件出错（突然掉电、奇偶校验错）或运算出错（除数为零、运算溢出、单步中断）所引起的中断
### 是不是所有中断都能复原
除以0就不能