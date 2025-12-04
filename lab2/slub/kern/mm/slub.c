#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

// 支持的大小类别（字节）
static size_t kmalloc_sizes[SLUB_SIZE_COUNT] = {
    8, 16, 32, 64, 128, 256, 512, 1024, 2048
};

// 每种大小对应的缓存
static struct kmem_cache kmalloc_caches[SLUB_SIZE_COUNT];

// 统计信息
static size_t total_slabs = 0;
static size_t total_allocated = 0;

// ==================== 辅助函数 ====================

// 从Page获取slab元数据（存储在页的开头）
struct slab_meta *page_to_slab(struct Page *page) {
    uintptr_t pa = page2pa(page);
    uintptr_t va = pa + PHYSICAL_MEMORY_OFFSET;
    return (struct slab_meta *)va;
}

// 根据对象大小选择合适的缓存索引
static int get_cache_index(size_t size) {
    int i;
    for (i = 0; i < SLUB_SIZE_COUNT; i++) {
        if (size <= kmalloc_sizes[i]) {
            return i;
        }
    }
    return -1;  // 大小超出范围
}

// 对齐到8字节
static inline size_t align_size(size_t size) {
    return (size + 7) & ~7;
}

// 初始化slab（将一页划分为多个对象并建立freelist）
static void init_slab(struct Page *page, struct kmem_cache *cache) {
    // 标记为slab页
    SetPageSlab(page);
    
    // 获取页的虚拟地址
    uintptr_t pa = page2pa(page);
    uintptr_t va = pa + PHYSICAL_MEMORY_OFFSET;
    
    // 在页的开头存储元数据
    struct slab_meta *meta = (struct slab_meta *)va;
    meta->cache = cache;
    meta->inuse = 0;
    
    // 计算可用空间（减去元数据大小）
    size_t meta_size = align_size(sizeof(struct slab_meta));
    size_t available = PGSIZE - meta_size;
    size_t num = available / cache->size;
    meta->objects = num;
    
    // 对象起始地址（元数据之后）
    uintptr_t obj_start = va + meta_size;
    
    // 建立freelist：每个对象的开头存储下一个对象的指针
    struct freelist_node *current = (struct freelist_node *)obj_start;
    meta->freelist = current;
    
    int i;
    for (i = 0; i < num - 1; i++) {
        struct freelist_node *next = (struct freelist_node *)(obj_start + (i + 1) * cache->size);
        current->next = next;
        current = next;
    }
    current->next = NULL;  // 最后一个对象
}

// 从slab分配一个对象
static void *alloc_from_slab(struct Page *page) {
    struct slab_meta *meta = page_to_slab(page);
    
    if (meta->freelist == NULL) {
        return NULL;  // slab已满
    }
    
    // 从freelist取出第一个对象
    void *obj = (void *)meta->freelist;
    meta->freelist = meta->freelist->next;
    meta->inuse++;
    
    return obj;
}

// 将对象归还到slab
static void free_to_slab(struct Page *page, void *objp) {
    struct slab_meta *meta = page_to_slab(page);
    struct freelist_node *node = (struct freelist_node *)objp;
    
    // 将对象插入到freelist头部
    node->next = meta->freelist;
    meta->freelist = node;
    meta->inuse--;
}

// 分配新的slab
static struct Page *alloc_new_slab(struct kmem_cache *cache) {
    // 从页分配器分配一页
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }
    
    // 初始化slab
    init_slab(page, cache);
    total_slabs++;
    
    return page;
}

// 释放slab回页分配器
static void free_slab(struct Page *page) {
    ClearPageSlab(page);
    free_page(page);
    total_slabs--;
}

// ==================== 初始化函数 ====================

void slub_init(void) {
    int i;
    
    // 初始化每个大小类的缓存
    for (i = 0; i < SLUB_SIZE_COUNT; i++) {
        struct kmem_cache *cache = &kmalloc_caches[i];
        
        // 设置缓存属性
        cache->size = kmalloc_sizes[i];
        cache->objsize = kmalloc_sizes[i];
        
        // 计算每个slab可容纳的对象数（考虑元数据）
        size_t meta_size = align_size(sizeof(struct slab_meta));
        size_t available = PGSIZE - meta_size;
        cache->num = available / cache->size;
        
        // 初始化slab链表
        list_init(&cache->node.partial);
        list_init(&cache->node.full);
        cache->node.nr_partial = 0;
        cache->node.nr_full = 0;
        
        // 设置缓存名称
        cache->name = "kmalloc-cache";
    }
    
    cprintf("SLUB allocator initialized\n");
    cprintf("  Size classes: ");
    for (i = 0; i < SLUB_SIZE_COUNT; i++) {
        cprintf("%d ", kmalloc_sizes[i]);
    }
    cprintf("bytes\n");
    cprintf("  Meta size: %d bytes\n", sizeof(struct slab_meta));
}

// ==================== 分配函数 ====================

void *kmalloc(size_t size) {
    if (size == 0 || size > SLUB_MAX_SIZE) {
        cprintf("kmalloc: invalid size %d\n", size);
        return NULL;
    }
    
    // 选择合适的缓存
    int index = get_cache_index(size);
    if (index < 0) {
        cprintf("kmalloc: no cache for size %d\n", size);
        return NULL;
    }
    
    cprintf("kmalloc: size=%d, cache_index=%d, cache_size=%d\n", size, index, kmalloc_sizes[index]);
    
    struct kmem_cache *cache = &kmalloc_caches[index];
    struct Page *page = NULL;
    void *obj = NULL;
    
    // 尝试从partial链表分配
    if (!list_empty(&cache->node.partial)) {
        cprintf("kmalloc: using existing partial slab\n");
        list_entry_t *le = list_next(&cache->node.partial);
        page = le2page(le, page_link);
        
        obj = alloc_from_slab(page);
        
        // 如果slab变满，移到full链表
        struct slab_meta *meta = page_to_slab(page);
        if (meta->inuse == meta->objects) {
            list_del(&page->page_link);
            list_add(&cache->node.full, &page->page_link);
            cache->node.nr_partial--;
            cache->node.nr_full++;
        }
    }
    // 如果partial为空，分配新slab
    else {
        cprintf("kmalloc: allocating new slab...\n");
        page = alloc_new_slab(cache);
        if (page == NULL) {
            cprintf("kmalloc: failed to allocate new slab\n");
            return NULL;
        }
        cprintf("kmalloc: new slab allocated\n");
        
        obj = alloc_from_slab(page);
        cprintf("kmalloc: object allocated from new slab\n");
        
        // 将slab加入partial链表（因为还有空闲对象）
        list_add(&cache->node.partial, &page->page_link);
        cache->node.nr_partial++;
    }
    
    if (obj != NULL) {
        total_allocated += cache->size;
    }
    
    return obj;
}

// ==================== 释放函数 ====================

void kfree(void *objp) {
    if (objp == NULL) {
        return;
    }
    
    // 根据地址找到所属页
    uintptr_t va = (uintptr_t)objp;
    uintptr_t pa = va - PHYSICAL_MEMORY_OFFSET;
    struct Page *page = pa2page(pa);
    
    // 检查是否是slab页
    if (!PageSlab(page)) {
        cprintf("Warning: kfree on non-slab page\n");
        return;
    }
    
    // 获取slab元数据
    struct slab_meta *meta = page_to_slab(page);
    struct kmem_cache *cache = meta->cache;
    
    if (cache == NULL) {
        cprintf("Warning: kfree on invalid slab\n");
        return;
    }
    
    // 记录释放前的状态
    int was_full = (meta->inuse == meta->objects);
    
    // 将对象归还到slab
    free_to_slab(page, objp);
    total_allocated -= cache->size;
    
    // 如果slab从full变为partial，移到partial链表
    if (was_full) {
        list_del(&page->page_link);
        list_add(&cache->node.partial, &page->page_link);
        cache->node.nr_full--;
        cache->node.nr_partial++;
    }
    // 如果slab完全空闲，考虑释放（保留至少一个partial slab）
    else if (meta->inuse == 0 && cache->node.nr_partial > 1) {
        list_del(&page->page_link);
        cache->node.nr_partial--;
        free_slab(page);
    }
}

// ==================== 统计函数 ====================

size_t slub_allocated_size(void) {
    return total_allocated;
}
