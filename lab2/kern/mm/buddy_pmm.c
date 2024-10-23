#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

static void
buddy_fit_init(void)
{
    list_init(&free_list);
    nr_free = 0;
}

static void
buddy_fit_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        /*
        Znamya:
            page这个结构体的定义参见：./memlayout.h line 35
            set_page_ref函数的定义：./pmm.h line 94
            需要注意的是，类似15445，ucore里面页的操作基本上都是封装好的，参见pmm.h
        */
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list))
    {
        list_add(&free_list, &(base->page_link));
    }
    else
    {
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list)
        {
            struct Page *page = le2page(le, page_link);
            /*
            Znamya:
                有关list的所有函数，参见list.h，位于根目录的/libs下面
            */
            if (base < page)
            {
                // list_add_before: 将operand1插入到operand0的前面
                list_add_before(le, &(base->page_link));
                break;
            }
            else
            {
                if (list_next(le) == &free_list) // 代表已经抵达链表尾部
                {
                    // list_add_before: 将operand1插入到operand0的后面
                    list_add(le, &(base->page_link));
                }
            }
        }
    }
}

static struct Page *
buddy_fit_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > nr_free)
    {
        return NULL;
    }

    struct Page *page = NULL;      // 目标空闲page
    list_entry_t *le = &free_list; // le: list end
    size_t min_size = nr_free + 1; // 最小连续空闲页框数量

    // 以下部分主体沿用了first_fit的结构

    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n)
        {
            if (p->property < min_size)
            {
                min_size = p->property; // 结构体定义中的变量：the num of free block
                page = p;
            }
        }
    }

    // 以下代码与原始的first_fit没有区别
    // 此时，page指向最佳匹配的空闲页框，即best_fit
    // 需要排除特殊情况：若没有找到匹配的页框，则page为NULL
    // 以下操作将找到的page进行删除和空间分配
    if (page != NULL)
    {
        // list_prev: 获取目标page的前一个page的指针
        list_entry_t *prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        // 如果 page 的属性大于 n，表示 page 大于所需，需要将剩余的部分重新添加到空闲页框链表中。
        if (page->property > n)
        {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;            // 当前可用的空闲页面减少
        ClearPageProperty(page); // 由于目标页已经分配出去，此处清理page属性
    }

    return page;
}

static void
buddy_fit_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: YOUR CODE*/
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值

    // 以下代码直接沿用自default_pmm.c
    base->property = n;    // "设置当前页块的属性为释放的页块数"
    SetPageProperty(base); // 使用 SetPageProperty 函数将其标记为属性页框。
    nr_free += n;          // 最后增加nr_free的值

    if (list_empty(&free_list))
    {
        list_add(&free_list, &(base->page_link));
    }
    else
    {
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list)
        {
            struct Page *page = le2page(le, page_link);
            if (base < page)
            {
                list_add_before(le, &(base->page_link));
                break;
            }
            else if (list_next(le) == &free_list)
            {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t *le = list_prev(&(base->page_link));
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: YOUR CODE*/
        // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        
        // 以下代码同样继承自default_pmm.c

        if (p + p->property == base)
        {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link)); 
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        if (base + base->property == p)
        {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t
buddy_fit_nr_free_pages(void)
{
    return nr_free;
}

static void buddy_fit_check(void)
{

}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_fit_init,
    .init_memmap = buddy_fit_init_memmap,
    .alloc_pages = buddy_fit_alloc_pages,
    .free_pages = buddy_fit_free_pages,
    .nr_free_pages = buddy_fit_nr_free_pages,
    .check = buddy_fit_check,
};