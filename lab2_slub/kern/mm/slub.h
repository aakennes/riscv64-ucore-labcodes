#ifndef __KERN_MM_SLUB_FIT_PMM_H__
#define  __KERN_MM_SLUB_FIT_PMM_H__

#include "list.h"
#include <pmm.h>

// slub实现原理参考自https://blog.csdn.net/lukuen/article/details/6935068
// 下列slub的结构参考自https://github.com/chenfangxin/buddy_slub/blob/master/rte_slub.h

/* object的结构：objsize + void*(8字节)
 * 例如kmem_cache中的size大小为2^4，则objsize = 2^4，
 * void*为指向下一个object的指针，void*的地址 = object首地址+offset
 * offset默认为4Bytes，即存储objsize的整型空间
 */
struct kmem_cache_cpu {
    void **freelist;   // 指向下一个空闲object的指针
    struct Page *page; // slab/多页page 起始指针
};

struct kmem_cache_node {
    uint64_t nr_partial; // partial slab链表中slab的数量 
    uint64_t nr_full;
    list_entry_t partial; // partial slab链表表头
    list_entry_t full;
};

struct kmem_cache {
    struct kmem_cache_cpu cpu_slab; // 单核CPU，原版是每个CPU一个
	int32_t size; // mem_cache中slab的规格
	int32_t offset; // 页中的空闲slab组成一个链表，在slab中偏移量为offset的地方中存放下一个slab的地址
	uint64_t oo; 
    uint64_t maxobjnum_perslab;
    // oo = order<<OO_SHIFT |slab_num（存在slab占用多个页的情况）
    // 用来存放分配给slub的页框的阶数(批发2^order页)和 kmem_cache中的object数量(低OO_SHIFT位)
	struct kmem_cache_node local_node;
	uint64_t min_partial;
    // 限制struct kmem_cache_node中的partial链表slab的数量。如果大于这个min_partial的值，那么多余的slab就会被释放
};

void slub_system_init(struct kmem_cache *slab_caches, int cache_num);
void* slub_alloc(struct kmem_cache *slab_caches, uint32_t size);
void slub_free(struct kmem_cache *s, size_t size, void* object);

#endif /* ! __KERN_MM_SLUB_FIT_PMM_H__ */