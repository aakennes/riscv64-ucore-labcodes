### lab1

### 练习一：理解内核启动中的程序入口操作

原问题：

> 阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？

#### la sp, kernstacktop

- 作用：将kernstacktop的地址传入sp（栈指针）寄存器中。
- 目的：为操作系统内核开辟一个栈空间，以便操作系统内核启动

#### tail kern_init

- 作用：tail，即tail call，尾调用kern_init函数。需要注意的是tail与call存在区别，前者不建立新的栈帧以提高效率
- 目的：直接跳转到kern_init标签处，开始函数执行。观察init.c的函数，可以发现，这一过程对操作系统的内核进行初始化，如初始化各种数据结构、创建进程、加载设备驱动程序等。

### 练习二：完善中断处理

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

### Challenge1:

