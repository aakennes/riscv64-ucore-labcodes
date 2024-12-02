# 任务要求

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

#### 练习1：理解基于FIFO的页面替换算法（思考题）
描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
 - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

1. 结构示意图

![alt text](pic/lab3_image1.png)

2. 流程说明

![alt text](pic/lab3_image2.png)

#### 练习2：深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
 - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
 - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

1. 
    sv39是三级页表， `get_pte()` 通过两层索引(由一级页表 PDX1 索引二级页表 PDX2，再索引到目标页表项 PTX)获取最终页表项, 而两端相似代码正是两层索引的实现, 每层索引都是先检查下一层索引是否存在, 不存在需要新建并初始化。

    sv32，sv39，sv48除了虚拟地址位宽不同外, 比较相关的就是页表层级分别为2, 3, 4级, 尽管每级页表索引命名不同, 但从上一级向下一级定位的过程相同, 实现也应该相似

2. 
    没必要。如果拆成两个函数的话, 当查找未找到(即目标页表项未创建某级目录索引时)上层可能还需要调用新建页表项的操作, 分函数实现需要再进行一次查找, 会导致创建页表项的效率偏低(需要查询新建页表项上级目录位置)。当前使用 create 控制是否需要新建比较合适。另外合二为一后代码比较简短，维护方便。

3. 
    页表中的页目录项和页表项通过 Page 结构体表示

#### 练习3：给未被映射的地址映射上物理页（需要编程）
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
> 请在实验报告中简要说明你的设计实现过程。

根据注释进行编写即可，较为简单。需要注意的是代码上下文中存在一些提示信息，仔细根据注释和要实现的功能进行分析即可。具体参见代码中的注释。
```C
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
{
    int ret = -E_INVAL;
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    if (vma == NULL || vma->vm_start > addr)
    {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
    {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);

    ret = -E_NO_MEM;

    pte_t *ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 1); 
    if (*ptep == 0)
    {
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
        {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    }
    else
    {
        if (swap_init_ok)
        {
            struct Page *page = NULL;
            /*
            swap_in函数的定义参见本目录下的swap.c
            其中，mm是一个param_out，返回值只是用于判断读取是否成功
            返回值为0的时候说明读取成功
            */
            ret = swap_in(mm, addr, &page); // 调用swap_in函数从磁盘上读取数据
            if (ret != 0)
            {
                cprintf("swap_in error at vmm.c\n");
                // 注意到函数最后面的返回值，有个failed标签
                goto failed;
            }
            
            //(2) According to the mm,
            // addr AND page, setup the
            // map of phy addr <--->
            // logical addr
            page_insert(mm->pgdir, page, addr, perm);
            //(3) make the page swappable.
            swap_map_swappable(mm, addr, page, 1);
            page->pra_vaddr = addr;
        }
        else
        {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }

    ret = 0;
failed:
    return ret;
}
```

请回答如下问题：
> 请描述页目录项（PageDirectoryEntry）和页表项（PageTableEntry）中组成部分对ucore实现页替换算法的潜在用处。

- 页目录项（PDE）和页表项（PTE）中，Accessed位用于记录page是否被访问，以及Dirty位是否被修改。替换算法可以根据这些记录来确定哪些页需要被驱逐。
- 页表项（PTE）用于记录从虚拟地址到屋里地址的映射。
- 页表项也用于记录物理页与swap磁盘上扇区的映射关系。


>  如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？

此时会固定的跳转到初始化stvec时设置好的处理程序地址，保存现场，准备进行中断。同时，将发生缺页中断的地址保存到`trapframe`中。

然后跳转到中断处理函数trap()，由`do_pgfault`处理page fault，然后返回__trapret恢复保存的寄存器，sret跳转回原程序。


> 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？
如果有，其对应关系是啥？

`Page` 和 `PTE,PDE` 有对应关系：当一个页对应的某一级页表项不存在时，会为其分配一个页，即存在全局变量 `Page` 中；当这个页面被换出的时候，它对应的页表项和页目录项也会释放对应页面，即从全局变量 `Page` 中删除。





#### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
> 请在实验报告中简要说明你的设计实现过程。

主要的难点在于clock里面的驱逐机制。只要理解clock替换算法本身即可，从成环的链表中逐个遍历，直到找到第一个需要驱逐的页为止。这个过程类似一个正在表盘上转动的时针，所以叫做clock算法。
```C
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    while (1) {
        /*LAB3 EXERCISE 4: YOUR CODE*/ 
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        
        // 获取当前页面对应的Page结构指针
        list_entry_t* entry = list_next(head);
        struct Page *page = le2page(entry, pra_page_link);
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        if (page-> visited == 0)
        {
            list_del(entry);
            *ptr_page = page;
            cprintf("curr_ptr %p\n", entry);
            break;
        }
        else
        {
            page-> visited = 0;
        }
        head=entry;
        
    }
    return 0;
}
```

请回答如下问题：
> 比较Clock页替换算法和FIFO算法的不同。

Clock算法与FIFO算法整体上有些类似，Clock是换出最先找到的`PTE_A`标志位为0的页。如果链表上所有页该标志位都为1，扫描一遍后，Clock并不会置换任何页，而是进行第二遍扫描。如果在进行第二次扫描之前，对应页又被访问了，则该页不会被置换出去，这即是Clock与FIFO最大的不同。  
值得注意的是，在这里我们使用的是`PTE_A`作为标志位，因为我们期望硬件在访问过程中会改变它的值。而如果使用`visited`字段来标识的话，该字段只有在缺页异常时才会进行更新，在扫描过后无法恢复，达不到Clock算法的目的，效果上等同于FIFO。  


#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

1. 空间: 大页表映射为动态创建, 需要在初始化时直接声明一大片内存地址, 当页表项较少时, 会产生大量无用空间; 而分级页表可以动态新建删除, 动态控制空间, 无用页表项会进行回收, 空间利用率极高。

2. 时间: 大页表的访问效率相对分级页表更高, 大页表只需要 ***一次*** 访问就可以定位到页表项, 而分级页表需要 ***级数-1*** 次访问。

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）
challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。
##### 设计与分析
由于并没有硬件支持，所以并不能知道内存页被访问的具体时间，然而，可以统计两次时钟中断之间有哪些页被访问过（内存页被访问时，PTE\_A位会被拉起），然后将这些访问过的页放到最前面，然后每次替换页时类似FIFO，将最前面的页进行替换即可。

关于PTE\_A置位是否正常的问题，可以查看[唐明昊学长的实验报告](https://github.com/mh-tang/OperatingSystem/blob/master/labReport/lab3.md)，其中对是否能够真正替换PTE\_A位的问题进行了详细的讨论，总的来说，第一次发生缺页异常时，硬件能够正常将PTE\_A置位，但是手动清空并访问后，并不能进行置位，这应当是由于程序的各种问题导致的，而正常情况下，是会将PTE\_A置位的，因此可以正常使用。

具体实现上，由于依然使用FIFO进行替换，因此主体部分之间复用FIFO代码即可。但是需要增加tick\_event的相关内容，也就是在时钟中断时需要进行的操作，遍历整张链表，将PTE\_A位被拉起的页放到最前面，并将PTE\_A的位重置。

具体的代码可以参考swap_lru.c的代码，在此不再赘述。

##### 测试
代码可以正确的通过[唐明昊学长的实验报告](https://github.com/mh-tang/OperatingSystem/blob/master/labReport/lab3.md)中的测试样例，另外也进行了其他测试，证明可以正确的完成任务。