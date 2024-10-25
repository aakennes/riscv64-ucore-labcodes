#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include "slub.h"

extern struct Page *
buddy_fit_alloc_pages(size_t n);

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
    list_init(&n->partial);
    n->nr_full = 0;
    list_init(&n->full);
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

static void* new_slab_alloc(struct kmem_cache *s,struct kmem_cache_cpu *n){
    s->oo++;
    return n->page = *(void**)n->freelist = buddy_fit_alloc_pages(s->size);
}

/* TODO:slab_alloc 向kmem_cache中申请一块内存
 * params : 
 *  kmem_cache - 要申请的kmem_cache
 * return : 返回所申请的object
 * methods: 分三种情况
 *  1. 第一次申请：向伙伴系统申请空闲内存页，放在kmem_cache_cpu中
 *  2. kmem_cache_cpu上有空闲的object，直接把kmem_cache_cpu中保存的一个空闲object返回给用户，并把freelist指向下一个空闲的object
 *  3. kmem_cache_cpu上没有空闲的object，将kmem_cache_cpu目前的slab移动到kmem_cache_node的full池中，然后重复第一次申请
 */ 
static void* slab_alloc(struct kmem_cache *s){
    if(oo_objectnum(s->oo) == 0){
        return new_slab_alloc(s, &s->cpu_slab);
    }
    void **object = s->cpu_slab.freelist;
    if(object != NULL){
        // 更新freelist
        s->cpu_slab.freelist = *(void **)(object + s->offset);
    }else{
        // 移动slab至full池
        list_add(&s->local_node.full, *object);
        s->local_node.nr_full++;
        *object = new_slab_alloc(s, &s->cpu_slab);
    }
    return *object;
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
    while(index <= MAX_CACHE_NUM && size >= nowsize * index){
        index++;
    }
    return slab_alloc(&slab_caches[index]);
}

