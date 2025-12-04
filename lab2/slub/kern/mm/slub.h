#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>

// SLUB分配器：两层内存管理架构
// 第一层：基于pmm的页级分配
// 第二层：基于页的任意大小对象分配

// 支持的对象大小类别（字节）
#define SLUB_MIN_SIZE       8
#define SLUB_MAX_SIZE       2048
#define SLUB_SIZE_COUNT     9

// slab页标志
#define PG_slab             2       // 标记这是一个slab页

#define SetPageSlab(page)       ((page)->flags |= (1UL << PG_slab))
#define ClearPageSlab(page)     ((page)->flags &= ~(1UL << PG_slab))
#define PageSlab(page)          (((page)->flags >> PG_slab) & 1)

// freelist节点：存储在空闲对象的开头
struct freelist_node {
    struct freelist_node *next;
};

// slab元数据：存储在每个slab页的开头
struct slab_meta {
    struct kmem_cache *cache;       // 所属的缓存
    struct freelist_node *freelist; // 空闲对象链表
    unsigned int inuse;             // 已使用的对象数量
    unsigned int objects;           // 总对象数量
};

// kmem_cache_node: 管理slab链表
struct kmem_cache_node {
    list_entry_t partial;       // 部分使用的slab链表
    list_entry_t full;          // 完全使用的slab链表
    unsigned long nr_partial;   // partial链表中的slab数量
    unsigned long nr_full;      // full链表中的slab数量
};

// kmem_cache: 特定大小对象的缓存
struct kmem_cache {
    const char *name;               // 缓存名称
    size_t size;                    // 对象大小（对齐后）
    size_t objsize;                 // 实际对象大小
    unsigned int num;               // 每个slab中的对象数量
    struct kmem_cache_node node;    // slab链表管理
};

// 从Page获取slab元数据（声明，在slub.c中实现）
struct slab_meta *page_to_slab(struct Page *page);

// SLUB分配器接口
void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *objp);

// 获取统计信息
size_t slub_allocated_size(void);

// 测试函数（在slub_test.c中实现）
void slub_check(void);

#endif /* !__KERN_MM_SLUB_H__ */

