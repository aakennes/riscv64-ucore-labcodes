#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include "slub.h"

// extern struct Page *
// buddy_fit_alloc_pages(size_t n);

extern struct Page *
best_fit_alloc_pages(size_t n);

#define MIN_PARTIAL_NUM 10
// 限制struct kmem_cache_node中的partial链表slab的数量。如果大于这个min_partial的值，那么多余的slab就会被释放

#define SLAB_BASE_SIZE 64
// 2^3~2^11 Bytes

#define MAX_CACHE_NUM 12

#define SLUB_OFFSET 32
// 4 Bytes，一个整型值，存储objsize


#define OO_SHIFT 16
#define OO_MASK ((1ul<<OO_SHIFT)-1)
// OO = SHIFT(order) | MASK(slabnum)

#define PAGE_SIZE 0x1000U

// TODO:calc_order 
// 计算size对应的order(size = 2^order)
static int calc_order(int size) {
    int ans = 0;
    while(size > 1){
        ans++;
        size /= 2;
    }
    return ans;
}

static int oo_order(uint64_t x){
    return x>>OO_SHIFT;
}

static int oo_objectnum(uint64_t x){
    return x & OO_MASK;
}

static void kmem_cache_cpu_init(struct kmem_cache_cpu *n){
    n->freelist = NULL;
    n->page = NULL;
}

static void kmem_cache_node_init(struct kmem_cache_node *n){
    n->nr_partial = 0;
    list_init(&(n->partial));
    n->nr_full = 0;
    list_init(&(n->full));
}



// TODO:kmem_cache_init 初始化kmem_cache
// 初始化kmem_cache中的各个参数
static void kmem_cache_init(struct kmem_cache *s, int size){
    int order = calc_order(size);
    kmem_cache_cpu_init(&s->cpu_slab);
    kmem_cache_node_init(&s->local_node);
    s->size = size;
    s->offset = SLUB_OFFSET;
    s->oo = order<<OO_SHIFT;
    s->maxobjnum_perslab = PAGE_SIZE/size;
    s->min_partial = MIN_PARTIAL_NUM;
}

/* TODO:slub_system_init 初始化slub系统
 * params : 
 *  slab_caches - kmem_cache的链表头  
 *  cachenum    - 初始化新建的kmemcache数量
 */
void slub_system_init(struct kmem_cache *slab_caches, int cache_num){
    for(int i = 0; i <= cache_num; ++i){
        kmem_cache_init(&slab_caches[i], SLAB_BASE_SIZE * (1<<i));
    }
}

static void* new_slab_alloc(struct kmem_cache *s,struct kmem_cache_cpu *c){
    s->oo++;
    struct Page *page = best_fit_alloc_pages(SLAB_BASE_SIZE);
    void *p, *start, *last;
    last = start = page;
    int i = 0;
    for(p = (void*)page; p < ((void*)page + PAGE_SIZE); p += s->size, i++){
        *(void **)(last+s->offset) = p;
        last = p;
    }
    *(void **)(last+s->offset) = NULL;	
    page->freelist = start;
    page->inuse = 0;
    page->objects = PAGE_SIZE/s->size;
    
    return page;
}

/* TODO:get_partial 从kmem_cache_node中获取一个半满状态的slab
 */
static struct Page* get_partial(struct kmem_cache *s){
    struct kmem_cache_node *n = &s->local_node;
    if(!n||!n->nr_partial){
		return NULL;
	}
    struct Page *page = NULL;      // 目标空闲page
    list_entry_t *le = &n->partial; // le: list end
    size_t min_size = n->nr_partial + 1; // 最小连续空闲页框数量
    
    while ((le = list_next(le)) != &n->partial)
    {
        struct Page *p = le2page(le, page_link);
        if(p->inuse < p->objects){
            // cprintf("%x\n",p);
            return p;
        }
    }
    return NULL;
}

/* TODO:add_partial 向kmem_cache_node的partial中添加一个slab
 */

static void add_partial(struct kmem_cache_node *n, struct Page* page){
    // n->nr_partial++;
    list_entry_t *page_link = &page->page_link;
    list_add(&n->partial, page_link);
}

/* TODO:add_full 向kmem_cache_node的full中添加一个slab
 */

static void add_full(struct kmem_cache_node *n, struct Page* page){
    n->nr_full++;
    list_entry_t *page_link = &page->page_link;
    list_add(&n->full, page_link);
}

/* TODO:del_partial 向kmem_cache_node的partial中删除一个slab
 */

static void del_partial(struct kmem_cache_node *n, struct Page* page){
    n->nr_full++;
    n->nr_partial--;
    list_entry_t *page_link = &page->page_link;
    list_del(page_link);
}

/* TODO:del_full 向kmem_cache_node的full中删除一个slab
 */

static void del_full(struct kmem_cache_node *n, struct Page* page){
    n->nr_full--;
    n->nr_partial++;
    list_entry_t *page_link = &page->page_link;
    list_del(page_link);
}

/* TODO:free_object 在kmem_cache释放一个object
 * 1. 先在kmem_cache_cpu中查找，如果找到直接释放即可
 * 2. 在kmem_cache_node中查找
 *  2.1 如果目标slab是full的，需要将其移入partial
 *  2.2 如果目标slab是partial的，在释放后还需要判断slab是否全为空，全为空需要将整个slab释放
 * 由于目前pmm.h中无法实现根据任意地址定位到所属page，因此只能
 */

void free_object(struct kmem_cache *s, void* object){
    struct kmem_cache_cpu *c = &s->cpu_slab;
    struct kmem_cache_node *n = &s->local_node;
    if(!n){
		return;
	}
    
    // 在kmem_cache_node的full中
    struct Page *page = NULL;      // 目标空闲page
    list_entry_t *le = &n->full; // le: list end
    
    while ((le = list_next(le)) != &n->full)
    {
        struct Page *p = le2page(le, page_link);
        // cprintf("page loop1 %x %d %d %d\n",(void*)p,object - (void*)p,s->local_node.nr_full,s->local_node.nr_partial);
        if(object >= (void*)p && object - (void*)p < PAGE_SIZE){
            page = p;
            break;
        }
    }
    
    if(page){
        del_full(n, page);
        add_partial(n ,page);        
        *(void **)(object+s->offset) = page->freelist;
        page->freelist = object;
        page->inuse--;
        
        return;
    }
    
    // 在kmem_cache_node的partial中
    
    le = &n->partial; // le: list end
    while ((le = list_next(le)) != &n->partial)
    {
        struct Page *p = le2page(le, page_link);
        // cprintf("page loop2 %x %d %d %d\n",(void*)p,object - (void*)p,s->local_node.nr_full,s->local_node.nr_partial);
        if(object >= (void*)p && object - (void*)p < PAGE_SIZE){
            page = p;
            break;
        }
    }
    
    if(page){
        page->inuse--;
        *(void **)(object+s->offset) = page->freelist;
        page->freelist = object;
        return;
    }
    // 在kmem_cache_cpu中
    *(void **)(object+s->offset) = c->freelist;
    c->freelist = object;
    c->page->inuse--;
}

void slub_free(struct kmem_cache *slab_caches, size_t size, void* object){
    int index = 0;
    int nowsize = SLAB_BASE_SIZE;
    while(index <= MAX_CACHE_NUM && size >= (nowsize + 1) * (1 << index)){
        index++;
    }
    
    free_object(&slab_caches[index], object);
}

/* TODO:slab_alloc 向kmem_cache中申请一块内存
 * params : 
 *  kmem_cache - 要申请的kmem_cache
 * return : 返回所申请的object
 * methods: 分三种情况
 *  1. 第一次申请：向伙伴系统申请空闲内存页，放在kmem_cache_cpu中
 *  2. kmem_cache_cpu上有空闲的object，直接把kmem_cache_cpu中保存的一个空闲object返回给用户，并把freelist指向下一个空闲的object
 *  3. kmem_cache_cpu上没有空闲的object，则在kmem_cache_node中找寻空闲的object
 *  4. kmem_cache_cpu 和 kmem_cache_node上没有空闲的object，将kmem_cache_cpu目前的slab移动到kmem_cache_node的full池中，然后重复第一次申请
 */ 
static void* slab_alloc(struct kmem_cache *s){
    struct kmem_cache_cpu *c = &s->cpu_slab;
    if(!c->page){
        // cpu为初始化或上一个使用的page中找不到
        struct Page* newpage = get_partial(s);
        if(newpage){
            c->page = newpage;
        }else{
            cprintf("新开了一个slab\n");
            c->page = new_slab_alloc(s, c);
        }
        
    }
    
    void **object = c->freelist;
    if(!object){
        object = c->page->freelist; 
        if(!c->page->freelist){
            // 此时需要把目前的cpu slab移到node中
            struct Page* newpage = get_partial(s);
            if(newpage){
                del_partial(&s->local_node, newpage);
                c->page = newpage;
                c->freelist = c->page->freelist;
            }else{
                cprintf("新开了一个slab\n");
                add_full(&s->local_node, c->page);
                c->page = new_slab_alloc(s, c);
            }
            object = c->page->freelist;
        }
        
    }
    
    c->freelist = *(void **)(object + (s->offset>>3));
    c->page->inuse++;
    c->page->freelist = NULL;
    return object;
}

/* TODO:slub_alloc 向slub中申请一块内存
 * params : 
 *  size - 要申请的内存
 * return : 返回所申请的object
 * methods:
 *  1. 获取符合size的slab所在的kmemcache
 *  2. 使用alloc_slab函数创建
 */
void* slub_alloc(struct kmem_cache *slab_caches, uint32_t size){
    int index = 0;
    int nowsize = SLAB_BASE_SIZE;
    while(index <= MAX_CACHE_NUM && size >= (nowsize + 1) * (1 << index)){
        index++;
    }
    return slab_alloc(&slab_caches[index]);
}

