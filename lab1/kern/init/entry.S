#include <mmu.h>
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
# load address. 本质上是将bootstacktop的地址放入栈指针寄存器
# 目的：将栈指针初始化为内核的栈顶地址，为操作系统的内核提供可用的栈空间
    la sp, bootstacktop 

# tail: 即tail call，是RISC-V的一个伪指令
# 效果：类似函数调用，但是和call相比有所不同
# 目的：直接执行跳转kern_init标签，且不建立新的栈帧以优化结构提高效率
# kern_init的函数作用参见init.c
    tail kern_init

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop: