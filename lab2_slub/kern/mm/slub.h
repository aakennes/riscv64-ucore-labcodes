#ifndef __KERN_MM_SLUB_FIT_PMM_H__
#define  __KERN_MM_SLUB_FIT_PMM_H__

#include "list.h"
#include <pmm.h>

// slub实现原理参考自https://blog.csdn.net/lukuen/article/details/6935068
// 下列slub的结构参考自https://github.com/chenfangxin/buddy_slub/blob/master/rte_slub.h

struct kmem_cache_cpu {
    void **freelist; // 指向下一个空闲object的指针
    struct Page *page; // slab/page 起始指针
};

struct kmem_cache_node {
    uint64_t nr_partial; // partial slab链表中slab的数量 
    struct list_entry partial; // partial slab链表表头
};

struct kmem_cache {
    struct kmem_cache_cpu cpu_slab; // 单核CPU，原版是每个CPU一个
	int32_t size; // mem_cache中slab的规格
	int32_t offset; // 页中的空闲slab组成一个链表，在slab中偏移量为offset的地方中存放下一个slab的地址
	uint64_t oo; 
    // oo = order<<OO_SHIFT |slab_num（存在slab占用多个页的情况）
    // 用来存放分配给slub的页框的阶数(批发2^order页)和 slub中的object数量(低OO_SHIFT位)
	struct kmem_cache_node local_node;
	uint64_t min_partial;
    // 限制struct kmem_cache_node中的partial链表slab的数量。如果大于这个min_partial的值，那么多余的slab就会被释放
};


#endif /* ! __KERN_MM_SLUB_FIT_PMM_H__ */