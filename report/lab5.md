# lab5
## 练习0：填写已有实验
```
本实验依赖实验2/3/4。请把你做的实验2/3/4的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行lab5的测试应用程序，可能需对已完成的实验2/3/4的代码进行进一步改进。
```
### 改进部分
改进部分全部在`kern/process/proc.c`中
#### alloc_proc
在创建完新进程后，需要将进程的等待状态`wait_state`设为0，`cptr`, `yptr`, `optr`三个指针初始化为空指针。
```c
//LAB5 YOUR CODE : (update LAB4 steps)
    /*
    * below fields(add in LAB5) in proc_struct need to be initialized  
    *       uint32_t wait_state;                        // waiting state
    *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
    */
proc->wait_state=0;//等待状态为0
proc->cptr=proc->yptr=proc->optr=NULL;//进程间指针初始化为NULL
```

#### do_fork
`do_fork`进行子进程的处理时，需要在第一步创建空间后设置子进程的父进程为自身，并确认当前进程的等待状态正确。此外，在第五步插入进程列表时，由于改成了使用`set_links`方法，因此需要对应进行修改，而`nr_process`等相关的操作在`set_links`中已经做了，因此不需要重复进行了。
```c
//    1. call alloc_proc to allocate a proc_struct
proc = alloc_proc();
if (proc == NULL)
{
    goto fork_out;
}
proc->parent=current;//设置父进程
assert(current->wait_state==0);//当前进程的等待状态

//    5. insert proc_struct into hash_list && proc_list
bool intr_flag;
local_intr_save(intr_flag);
{
    proc->pid = get_pid();
    hash_proc(proc);
    set_links(proc);//设置进程间关系
}
local_intr_restore(intr_flag)
```

## 练习1: 加载应用程序并执行（需要编码）
```
do_execv函数调用load_icode（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充load_icode的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好proc_struct结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。
```

初始化用户环境的中断帧tf中，主要需要修改用户栈顶、用户程序入口并更新状态。
```c
/* LAB5:EXERCISE1 YOUR CODE
    * should set tf->gpr.sp, tf->epc, tf->status
    * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
    *          tf->gpr.sp should be user stack top (the value of sp)
    *          tf->epc should be entry point of user program (the value of sepc)
    *          tf->status should be appropriate for user program (the value of sstatus)
    *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
    */
tf->gpr.sp=USERTOP;//gpr.sp需要是用户栈顶
tf->epc=elf->e_entry;//epc需要是用户程序入口
// 当前状态 清零特权级 清零中断使能状态 进入用户模式
tf->status=(read_csr(sstatus)& ~SSTATUS_SPP & ~SSTATUS_SPIE);
```

### 问题
```
请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。
```
- `proc.c`中，`init_main`函数：init进程创建完毕后，进入`do_wait`阶段，使用`schedule`进行调度，进入`user_main`函数
- `user_main`函数通过一系列的宏变换最终调用了`kernel_execve`，执行了`ebreak`中断，执行`SYS_exec`调用，通过设置a7寄存器的值为10来说明这不是一个普通的断点中断，需要转发`syscall`，在内核态使用系统调用从而完成上下文切换。（`kern/trap/trap.c`中的`execption_handler`中可以看到对于`gpr.a7`的值进行了特判，来转发至`syscall`中。）
- `syscall`函数进行参数的解析，并根据调用号进入对应的系统调用（在这里为`SYS_exec`）
- `sys_exec`中，调用执行`do_execve`
- `do_execve`中，先回收自身所占用的用户空间，然后调用`load_icode`用新的程序覆盖内存空间，形成一个执行新程序的新进程。
- `load_icode`中
    * 创建了一个新的mm和对应的页目录
    * 将`text`和`data`段的内容进行复制
    * 在进程的内存空间中构建BSS段
        * 初始化、获取elf头、获取程序头、验证elf文件
        * 遍历程序头、检查程序头为`ELF_PT_LOAD`的程序头，检查大小是否正确
        * 根据程序头标志设置内存映射权限、使用`mm_map`函数设置新的虚拟内存区域vma
        * 计算数据地址、分配内存页、复制`text`和`data`段
        * 初始化`BSS`段，分配内存页、处理未对齐的情况
    * 构建用户栈
    * 设置当前进程的mm, sr3，并让cr3寄存器的值指向页目录的地址
    * 修改用户环境的中断栈
        * `gpr.sp`指向用户栈顶 __*中断时使用内核栈，返回时切换用户栈*__
        * `epc`指向用户程序入口，__*返回时可以返回用户程序*__
        * 清零特权级、清零中断使能、进入用户模式 __*返回用户态，禁用中断*__
    * 由于最后设置了用户栈，上下文切换后会通过`trapret`回到用户态，执行用户程序。

## 练习2: 父进程复制自己的内存空间给子进程（需要编码）
```
创建子进程的函数do_fork在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过copy_range函数（位于kern/mm/pmm.c中）实现的，请补充copy_range的实现，确保能够正确执行。
```

```c
/* LAB5:EXERCISE2 YOUR CODE
    * replicate content of page to npage, build the map of phy addr of
    * nage with the linear addr start
    *
    * Some Useful MACROs and DEFINEs, you can use them in below
    * implementation.
    * MACROs or Functions:
    *    page2kva(struct Page *page): return the kernel vritual addr of
    * memory which page managed (SEE pmm.h)
    *    page_insert: build the map of phy addr of an Page with the
    * linear addr la
    *    memcpy: typical memory copy function
    *
    * (1) find src_kvaddr: the kernel virtual address of page
    * (2) find dst_kvaddr: the kernel virtual address of npage
    * (3) memory copy from src_kvaddr to dst_kvaddr, size is PGSIZE
    * (4) build the map of phy addr of  nage with the linear addr start
    */
void* src_kvaddr=page2kva(page);//源地址
void* dst_kvaddr=page2kva(npage);//目的地址
memcpy(dst_kvaddr,src_kvaddr,PGSIZE);//执行复制
ret=page_insert(to,npage,start,perm);//插入新页
```
### 问题
```
如何设计实现Copy on Write机制？给出概要设计，鼓励给出详细设计。

Copy-on-write（简称COW）的基本概念是指如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源了。若某使用者需要对这个资源A进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝—资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源A。
```

- 创建的时候，将父进程的页设置为只读，然后将这些页映射到新进程的地址空间中
- 当父进程或子进程尝试修改共享的内存页时，硬件会触发`page_fault`中断
- 此时捕获故障并检测是否是对一个只读页面进行写操作，如果是，并为尝试写入的进程创建该页的副本。新的页会被标记为可写，并映射到进程的地址空间中
- 操作系统会更新页表，使得尝试写入的进程使用新的页，但是其他进程依然可以使用原来的页，但是如果此时只有一个进程在用原来的这个页，可以直接将其设置为可写

## 练习3：理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）
```
请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：

请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
```

## challenge 1: 实现 Copy on Write （COW）机制

首先需要在do_fork对内存空间进行复制时，就将share变量设置为1.

调用路径：do_fork->copy_mm->dup_mmap。只需修改dup_mmap中的share即可。
```C
int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list)
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);

        // 注意这里的share要调整为1： 在fork时会调用dup_mmap。
        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
```

在lab5 EX2里，需要对之前的实现进行必要的修改：根据share来判断是否需要对内存空间进行共享。

```C
if (share)
{
    cprintf("COW successful.\n");
    page_insert(from, page, start, perm & (~PTE_W));
    ret=page_insert(to, page, start, perm & (~PTE_W));
}
else
{
    // 以下为原始implementation
    void *src_kvaddr = page2kva(page);         // 源地址
    void *dst_kvaddr = page2kva(npage);        // 目的地址
    memcpy(dst_kvaddr, src_kvaddr, PGSIZE);    // 执行复制
    ret = page_insert(to, npage, start, perm); // 插入新页
    // 以上为原始implementation
}

```

对于do_pgfault，需要额外判断一次是否正在写入一个只读界面：
```C
if ((*ptep & PTE_V) && (error_code == 0xf))
{
    cprintf("COW successful.\n");
    struct Page *page = pte2page(*ptep);
    if (page_ref(page) == 1)
    {
        // 页面引用数为1
        page_insert(mm->pgdir, page, addr, perm);
    }
    else
    {
        // 页面引用数大于1
        struct Page *npage = alloc_page();
        assert(npage != NULL);
        memcpy(page2kva(npage), page2kva(page), PGSIZE);
        if (page_insert(mm->pgdir, npage, addr, perm) != 0)
        {
            cprintf("page_insert in do_pgfault failed\n");
            goto failed;
        }
    }
}
```



## 补充
### 系统调用部分的代码
#### 内嵌汇编
```c
asm volatile (
    "ld a0, %1\n"
    "ld a1, %2\n"
    "ld a2, %3\n"
    "ld a3, %4\n"
    "ld a4, %5\n"
    "ld a5, %6\n"
    "ecall\n"
    "sd a0, %0"
    : "=m" (ret)
    : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
    :"memory");
//num存到a0寄存器， a[0]存到a1寄存器
//ecall的返回值存到ret
```

前面很好理解，就是传入参数、触发调用，获取返回值。后面的几行代码的使用了操作数约束，
- `:"=m" (ret)`：输入操作数约束，表示`ret`变量将要被写入内存，`=`是输出操作数，`m`是内存，后面则是C中的变量
- `:"m" (num)`及和后续：输入操作数约束，代表从后面的变量中提取，num和后续变量，作为%1-%6进行使用
- `:memory`： 克隆寄存器列表，表示汇编指令需要修改内存，因此通告编译器需要在汇编指令执行前后保持内存的一致性

