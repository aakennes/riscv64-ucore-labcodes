## Lab2 实验报告

#### 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。
```
描述程序在进行物理内存分配的过程以及各个函数的作用。
```
ucore使用了C语言，虽然C语言没有面向对象，但是通过结构体内的函数指针的方法也可实现类似的面向对象的方法。通过将物理内存管理抽象成特定的函数，存储在pmm_manager结构体中，其中，从指导书中可以看到，pmm_manager的成员函数有：
```C
struct pmm_manager {
    const char *name;  // pmm名称
    void (*init)(void);  // 初始化pmm_manager内部的数据结构（如空闲页面的链表）
    void (*init_memmap)(struct Page *base,size_t n);  //初始化空闲页
    struct Page *(*alloc_pages)(size_t n);  // 分配至少n个物理页面, 根据分配算法可能返回不同的结果
    void (*free_pages)(struct Page *base, size_t n);  // 释放对应的物理页
    size_t (*nr_free_pages)(void);  // 返回空闲物理页面的数目
    void (*check)(void);            // 测试正确性
};
```
此外，还有两个标志位：
- `PG_reserved` 保留位，如果为1，说明这个页被内核保留了，不参与`alloc`和`free`，否则为0
- `PG_property` 如果为1，说明这个页是一段空闲页的头页，如果为0，说明这个页不是头页或这个页不是空闲的

```C
struct Page {
    int ref;                 // page frame's reference counter
    uint64_t flags;          // 状态
    unsigned int property;   // 空闲块的大小，只在空闲块头页记录
    list_entry_t page_link;  // 空闲物理内存双向链表
};
```

```
结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数
```
`default_pmm_c`定义了一个pmm，使用first fit算法。其中，主要有`default_init`, `default_init_memmap`, `default_alloc_pages`等函数，下面逐个介绍这些函数：

`default_init`进行了简单的初始化，初始化了双向链表，并初始化空闲页数量为0
```C
static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;//初始化空闲页数量
}
```

`default_init_memmap`进行了更详细的初始化，先检查n的合法性，然后检查每个位是否reserved，如果是reserved说明可用，否则说明这个页是非法页，然后将块内各个页的flag设为0，property设为0，flag设为0，表示该帧有效，然后重新将首页的property标志为1，然后将全局总页数加上块内的页数。若空闲页表是空，则直接加上去，否则从小到大遍历并插入合适的位置。
```C
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```

`default_alloc_pages`负责分配空间，遍历链表中第一个页数不小于申请页数的块，如果这个块比申请的更多，则分裂这个块，并把分裂出去的部分重新按照从小到大的顺序插入回去，如果找不到这么大的块，则返回NULL表示分配失败。
```C
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

free在检查n的合法性和每个页的合法性后，将他们删除，并重设property位，然后进行插入。插入后，若前面或后面是连续的，则需要进行合并。
```C
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

```
你的first fit算法是否有进一步的改进空间？
```
目前的first fit算法并没有很好的解决碎片化的问题。

#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？

#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。