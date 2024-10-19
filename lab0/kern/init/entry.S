#include <mmu.h>
#include <memlayout.h>

# The ,"ax",@progbits tells the assembler that the section is allocatable ("a"), executable ("x") and contains data ("@progbits").
# 从这里开始.text 这个section, "ax"(可分配可执行) 和 %progbits(包含初始化数据)描述这个section的特征
    .section .text,"ax",%progbits
    .globl kern_entry  
    # 使得ld能够看到kern_entry这个符号所在的位置, globl和global同义，声明全局符号，链接器在链接多个文件时可以看到这个符号
kern_entry: # 内核的启动入口
    la sp, bootstacktop 
    # la 是一个伪指令，用于加载地址。在这里，它将地址 bootstacktop 加载到 sp（堆栈指针）
    tail kern_init
    # 与普通的跳转不同，tail 不会保存返回地址
#开始data section
.section .data
    # .align 2^12, 按照2^PGSHIFT进行地址对齐, 也就是对齐到下一页 PGSHIFT在 mmu.h定义
    .align PGSHIFT 
    .global bootstack #内核栈
bootstack:
    .space KSTACKSIZE #留出KSTACKSIZE这么多个字节的内存
    .global bootstacktop #之后内核栈将要从高地址向低地址增长, 初始时的内核栈为空
bootstacktop: