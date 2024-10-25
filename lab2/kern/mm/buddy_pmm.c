#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

//线段树辅助函数
#define left_leaf(idx) ((idx<<1)+1)
#define right_leaf(idx) ((idx<<1)+2)
#define parent(idx) ((idx>>1)-1)

#define is_pow2(x) (!((x)&((x)-1)))
#define mmax(a,b) ((a)>(b)?(a):(b))

#define maxm 65536
//板子取下一个整次幂函数
static unsigned fixsize(unsigned size) {
  size |= size >> 1;
  size |= size >> 2;
  size |= size >> 4;
  size |= size >> 8;
  size |= size >> 16;
  return size+1;
}

struct node{
    unsigned size;//节点管理的总块数，有一说一可以不要
    unsigned maxx;//最长的空闲块有多大
};
struct node root[maxm];
int total_size=0;//总管理块数

static void
buddy_fit_init(void)
{
    list_init(&free_list);
    nr_free = 0;
}

/*
size:总空闲空闲空间
node_num:节点的块数
循环，给每个结点赋maxx
*/
static void buddy_init(int size)
{
    if(!is_pow2(size)||size<=0)  return;
    unsigned node_size;
    root[0].size=size;
    node_size=size<<1;
    for(int i=0;i<size*2-1;i++)
    {
        if(is_pow2(i+1))  node_size>>=1; 
        root[i].maxx=node_size;       
    }
    return;
}
static void
buddy_fit_init_memmap(struct Page *base, size_t n)
{
    //继承自best_fit_pmm.c
    //----------
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
    base->property = 0;//使用线段树后，base页的property不需要了
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
    //----------
    unsigned leq_size=is_pow2(n)?n:(fixsize(n)>>1);
    //正好是2的n次幂，直接进行初始化
    //否则，只能取整数次幂进行管理
    buddy_init(leq_size);
    total_size=n;
}

/*
辅助函数，用来寻找是否存在节点，找到最合适的节点，分配空间和更新父节点的longest值
*/
static int buddy2_alloc
(struct node* self,int size)
{
    unsigned node_size;
    unsigned idx=0;
    unsigned offset=0;
    unsigned idxl,idxr;

    if(self==NULL)  return -1;
    if(self[idx].maxx<size)  return -1;

    for(node_size=self->size;node_size!=size;node_size>>=1)
    {
        idxl=-1;
        idxr=-1;
        if(self[left_leaf(idx)].maxx>=size)  idxl=left_leaf(idx);
        if(self[right_leaf(idx)].maxx>=size)  idxr=right_leaf(idx);
        if(idxl!=-1&&idxr==-1)  idx=idxl;
        if(idxl==-1&&idxr!=-1)  idx=idxr;
        if(idxl!=-1&&idxr!=-1)  idx=self[idxl].maxx<=self[idxr].maxx?idxl:idxr;
    }
    self[idx].maxx=0;//已使用
    //偏移：索引*节点大小-内存池大小
    //当前节点的内存块在整个内存池的结束位置-整个内存池的大小=起始位置
    offset=(idx+1)*node_size-self->size;
    idx=parent(idx);
    /*
        关于为什么不会出现连续的块：
        分配是按整二次幂进行的，而由于这里已经会有一个块（最下面那个）被修改
        所以说，在每层中，都有一个完整的结构被破坏
    */
    for(;idx>=0;idx=parent(idx))
    {
        self[idx].maxx=mmax(self[left_leaf(idx)].maxx,self[right_leaf(idx)].maxx);
    }
    return offset;

}

/*
实行页面的分批额，首先判断合法性（能不能分配，计算符合条件的值）
调用上面辅助函数计算空闲块
找到空闲块的第一页
nrfree削减，page->property记录空闲块的大小
*/
static struct Page *
buddy_fit_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > nr_free)
    {
        return NULL;
    }
    if(n<=0)  n=1;
    else n=fixsize(n);
    
    unsigned long offset=buddy2_alloc(root,n);
    if(offset==-1)
    {
        cprintf("Something wrong when allocating a page.\n");
    }
    else
    {
        cprintf("Page %ld are allocated.\n",offset);
    }
    //first fit
    
    list_entry_t *le = &free_list; // le: list end
    struct Page *base=le2page(list_next(le),page_link);//头页
    struct Page *page=base+offset;// 目标空闲page
    nr_free -= n;            // 当前可用的空闲页面减少
    page->property=n;
    //ClearPageProperty(page);
    return page;
}

/*
释放一块的具体过程
先解压出idx
向上合并和修改（注意可能出现的区间合并情况）

为什么node_size=1
因为在这里，idx的解压出来的是最下面的节点
*/
static void
buddy_fit_free(struct node* self,int offset)
{
    unsigned node_size,idx;
    unsigned idxl,idxr;
    node_size=1;
    idx=self->size+offset-1;
    //偏移
    //self->size-1是前面的辅助节点
    //offset是最下面一层的偏移，所以算出来是叶子节点
    //实际上是一个偷懒的lazytag
    self[idx].maxx=node_size;
    idx=parent(idx);
    for(;idx>=0;idx=parent(idx))
    {
        node_size<<=1;
        idxl=self[left_leaf(idx)].maxx;
        idxr=self[right_leaf(idx)].maxx;
        if(idxl+idxr==node_size)  self[idx].maxx=node_size;//并块
        else  self[idx].maxx=mmax(idxl,idxr);//没有
    }
}

/*
释放的过程：从先获取需要释放的空闲块的大小，删链表，然后维护那棵树
*/
static void
buddy_fit_free_pages(struct Page *base, size_t n)
{
    //-----first-fit-----
    assert(n > 0);
    n=base->property;//在这里实际上n没什么用
    //----------
    struct node* self=root;
    list_entry_t *le=&free_list;
    struct Page* start_page=le2page(list_next(le),page_link);
    unsigned int offset=base-start_page;//计算offset

    //合法性判断
    assert(self);
    assert(offset>=0);
    assert(offset<=self->size);

    //-----first-fit-----
    struct Page *p = base;
    for (; p != base + n; p ++) {
        // assert(!PageReserved(p) && !PageProperty(p));
        // p->flags = 0;
        assert(!PageReserved(p));
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free+=n;
    //----------
    buddy_fit_free(self,offset);
}

static size_t
buddy_fit_nr_free_pages(void)
{
    return nr_free;
}

static void buddy_fit_check(void)
{
    struct Page *p0, *p1,*p2;
    p0 = p1 = NULL;
    p2=NULL;
    struct Page *p3, *p4,*p5;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    free_page(p0);
    free_page(p1);
    free_page(p2);
    
    p0=alloc_pages(70);
    p1=alloc_pages(35);
    //注意，一个结构体指针是20个字节，有3个int,3*4，还有一个双向链表,两个指针是8。加载一起是20。
    cprintf("p0 %p\n",p0);
    cprintf("p1 %p\n",p1);
    cprintf("p1-p0 equal %p ?=128\n",p1-p0);//应该差128
    
    p2=alloc_pages(257);
    cprintf("p2 %p\n",p2);
    cprintf("p2-p1 equal %p ?=128+256\n",p2-p1);//应该差384
    
    p3=alloc_pages(63);
    cprintf("p3 %p\n",p3);
    cprintf("p3-p1 equal %p ?=64\n",p3-p1);//应该差64
    
    free_pages(p0,70);    
    cprintf("free p0!\n");
    free_pages(p1,35);
    cprintf("free p1!\n");
    free_pages(p3,63);    
    cprintf("free p3!\n");
    
    p4=alloc_pages(255);
    cprintf("p4 %p\n",p4);
    cprintf("p2-p4 equal %p ?=512\n",p2-p4);//应该差512
    
    p5=alloc_pages(255);
    cprintf("p5 %p\n",p5);
    cprintf("p5-p4 equal %p ?=256\n",p5-p4);//应该差256
        free_pages(p2,257);    
    cprintf("free p2!\n");
        free_pages(p4,255);    
    cprintf("free p4!\n"); 
            free_pages(p5,255);    
    cprintf("free p5!\n");   
    cprintf("CHECK DONE!\n") ;
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