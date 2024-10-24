#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include "slub.h"

#define MIN_PARTIAL_NUM 10
// 限制struct kmem_cache_node中的partial链表slab的数量。如果大于这个min_partial的值，那么多余的slab就会被释放

#define SLAB_BASE_SIZE 64
// 2^3~2^11 Bytes

#define SHM_CACHE_NUM 14


#define OO_SHIFT 16
#define OO_MASK ((1ul<<OO_SHIFT)-1)
// OO = SHIFT(order) | MASK(slabnum)

// TODO:calc_order 
// 计算size对应的order(size = 2^order)
int calc_order(int size){
    
}

int oo_order(uint64_t x){
    return x>>OO_SHIFT;
}

int oo_objectnum(uint64_t x){
    return x & OO_MASK;
}

void kmem_cache_cpu_init(struct kmem_cache_cpu *n){
    n->freelist = NULL;
    n->page = NULL;
}

void kmem_cache_node_init(struct kmem_cache_node *n){
    n->nr_partial = 0;
    list_init(&n->partial);
}

// TODO:kmem_cache_init 初始化kmem_cache
// 初始化kmem_cache中的各个参数
void kmem_cache_init(struct kmem_cache *s, int size){

    // int order 

}
/* TODO:slub_system_init 初始化slub系统
 * params : 
 *  slab_caches - kmem_cache的链表头  
 *  cachenum    - 初始化新建的kmemcache数量
 */
void slub_system_init(struct kmem_cache *slab_caches, int cache_num){

}

/* TODO:slub_alloc 向slub中申请一块内存
 * params : 
 *  size - 要申请的内存
 * return : 返回所申请的object
 * methods:
 *  1. 使用get_slab函数获取符合size的slab所在的kmemcache
 *  2. 使用alloc_slab函数创建
 */
void* slub_alloc(uint32_t size){

}

/* TODO:slab_alloc 向kmem_cache中申请一块内存
 * params : 
 *  kmem_cache - 要申请的kmem_cache
 * return : 返回所申请的object
 * methods:
 *  
 */
void* slab_alloc(struct kmem_cache *s){

}