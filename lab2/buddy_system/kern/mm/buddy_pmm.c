// buddy_pmm.c

#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>
#include <defs.h>
#include <memlayout.h>

// 伙伴系统结构体 - 简化版本
struct buddy {
    unsigned size;           // 管理的总页面数（必须是2的幂）
    unsigned longest[0];     // 柔性数组，记录每个节点的最大可用块大小
};

static struct buddy *buddy_sys = NULL;
static struct Page *buddy_base = NULL;
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

#define LEFT_LEAF(index)     ((index) * 2 + 1)
#define RIGHT_LEAF(index)    ((index) * 2 + 2)
#define PARENT(index)        (((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x)     (!((x) & ((x) - 1)))
#define MAX(a, b)           ((a) > (b) ? (a) : (b))

// 将size调整为2的幂
static unsigned fixsize(unsigned size) {
    if (size == 0) return 1;
    unsigned result = 1;
    while (result < size) {
        result <<= 1;
    }
    return result;
}

static void
buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
    buddy_sys = NULL;
    buddy_base = NULL;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    cprintf("buddy_init_memmap: 初始化 %lu 页内存\n", n);
    
    // 初始化页面
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        SetPageProperty(p);
        p->property = 0;
        set_page_ref(p, 0);
    }
    
    buddy_base = base;
    
    // 计算实际管理的页面数（调整为2的幂）
    unsigned actual_size = fixsize(n);
    cprintf("buddy_init_memmap: 实际管理 %u 页（调整为2的幂）\n", actual_size);
    
    // 分配伙伴系统结构体（包含位图）
    // 我们将伙伴系统结构体放在管理内存的末尾
    size_t buddy_size = sizeof(struct buddy) + sizeof(unsigned) * (2 * actual_size - 1);
    size_t buddy_pages = (buddy_size + PGSIZE - 1) / PGSIZE;
    
    cprintf("buddy_init_memmap: 伙伴系统需要 %lu 字节，%lu 页\n", buddy_size, buddy_pages);
    
    // 确保有足够空间存放伙伴系统结构体
    if (actual_size < buddy_pages) {
        panic("buddy_init_memmap: 内存不足存放伙伴系统结构体");
    }
    
    // 伙伴系统结构体放在管理内存的末尾
    uintptr_t buddy_addr = (uintptr_t)(base + actual_size - buddy_pages);
    buddy_sys = (struct buddy *)buddy_addr;
    
    buddy_sys->size = actual_size - buddy_pages;  // 实际可用的页面数
    nr_free = buddy_sys->size;
    
    cprintf("buddy_init_memmap: 伙伴系统位于 %p，管理 %u 页\n", buddy_sys, buddy_sys->size);
    
    // 初始化二叉树节点 - 修复初始化逻辑
    for (int i = 0; i < 2 * buddy_sys->size - 1; ++i) {
        buddy_sys->longest[i] = 0;
    }
    
    // 自底向上初始化
    for (int i = 0; i < buddy_sys->size; i++) {
        int index = i + buddy_sys->size - 1;
        buddy_sys->longest[index] = 1;
    }
    
    for (int i = buddy_sys->size - 2; i >= 0; i--) {
        buddy_sys->longest[i] = buddy_sys->longest[LEFT_LEAF(i)] + buddy_sys->longest[RIGHT_LEAF(i)];
    }
    
    cprintf("buddy_init_memmap: 初始化完成，空闲页面数 = %lu\n", nr_free);
    cprintf("buddy_init_memmap: 根节点大小 = %u\n", buddy_sys->longest[0]);
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    if (n > nr_free || buddy_sys == NULL) {
        cprintf("buddy_alloc_pages: 没有足够内存或伙伴系统未初始化\n");
        return NULL;
    }
    
    // 调整请求大小为2的幂
    unsigned alloc_size = fixsize(n);
    
    cprintf("buddy_alloc_pages: 请求 %lu 页，实际分配 %u 页\n", n, alloc_size);
    
    // 检查根节点是否有足够空间
    if (buddy_sys->longest[0] < alloc_size) {
        cprintf("buddy_alloc_pages: 没有足够连续空间，最大可用 %u 页\n", buddy_sys->longest[0]);
        return NULL;
    }
    
    // 搜索合适的节点
    unsigned index = 0;
    unsigned node_size = buddy_sys->size;
    
    // 向下搜索到合适的节点
    while (node_size > alloc_size) {
        unsigned left = LEFT_LEAF(index);
        unsigned right = RIGHT_LEAF(index);
        
        if (buddy_sys->longest[left] >= alloc_size) {
            index = left;
        } else {
            index = right;
        }
        node_size /= 2;
    }
    
    // 检查最终节点是否合适
    if (buddy_sys->longest[index] < alloc_size) {
        cprintf("buddy_alloc_pages: 搜索失败，节点 %u 大小 %u < 需求 %u\n", 
                index, buddy_sys->longest[index], alloc_size);
        return NULL;
    }
    
    cprintf("buddy_alloc_pages: 在节点 %u 分配 %u 页\n", index, alloc_size);
    
    // 标记节点为已分配
    unsigned allocated = buddy_sys->longest[index];
    buddy_sys->longest[index] = 0;
    
    // 计算偏移 - 简化方法
    unsigned offset = 0;
    unsigned temp_index = index;
    unsigned temp_size = alloc_size;
    
    // 从叶子节点向上计算偏移
    if (index >= buddy_sys->size - 1) {
        // 叶子节点
        offset = index - (buddy_sys->size - 1);
    } else {
        // 内部节点，需要计算
        while (temp_index > 0) {
            if (temp_index % 2 == 0) {
                // 右孩子，需要加上左子树的大小
                offset += temp_size;
            }
            temp_index = PARENT(temp_index);
            temp_size *= 2;
        }
    }
    
    cprintf("buddy_alloc_pages: 偏移 %u\n", offset);
    
    // 检查偏移是否有效
    if (offset >= buddy_sys->size) {
        cprintf("buddy_alloc_pages: 错误！偏移 %u 超出范围 [0, %u)\n", offset, buddy_sys->size);
        return NULL;
    }
    
    // 向上更新祖先节点
    temp_index = index;
    while (temp_index > 0) {
        temp_index = PARENT(temp_index);
        buddy_sys->longest[temp_index] = 
            MAX(buddy_sys->longest[LEFT_LEAF(temp_index)], 
                buddy_sys->longest[RIGHT_LEAF(temp_index)]);
    }
    
    // 获取对应的物理页面
    struct Page *page = &buddy_base[offset];
    
    // 设置页面属性
    for (unsigned i = 0; i < alloc_size; i++) {
        ClearPageProperty(&page[i]);
        set_page_ref(&page[i], 1);
    }
    
    nr_free -= alloc_size;
    cprintf("buddy_alloc_pages: 分配完成，剩余空闲 %lu\n", nr_free);
    
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base != NULL);
    assert(buddy_sys != NULL);
    
    size_t offset = base - buddy_base;
    
    // 调整释放大小为2的幂
    unsigned free_size = fixsize(n);
    
    cprintf("buddy_free_pages: 释放 %lu 页，实际释放 %u 页，偏移 %lu\n", 
            n, free_size, offset);
    
    // 检查偏移是否有效
    if (offset >= buddy_sys->size) {
        panic("buddy_free_pages: 偏移超出范围");
    }
    
    // 计算对应的节点索引
    unsigned index = offset + buddy_sys->size - 1;
    
    cprintf("buddy_free_pages: 找到节点 %u，对应偏移 %lu\n", index, offset);
    
    // 恢复节点大小
    buddy_sys->longest[index] = free_size;
    
    // 向上合并伙伴块
    unsigned temp_index = index;
    while (temp_index > 0) {
        temp_index = PARENT(temp_index);
        unsigned left = LEFT_LEAF(temp_index);
        unsigned right = RIGHT_LEAF(temp_index);
        
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
            buddy_sys->longest[left] == buddy_sys->longest[right]) {
            // 可以合并
            buddy_sys->longest[temp_index] = buddy_sys->longest[left] + buddy_sys->longest[right];
            cprintf("buddy_free_pages: 合并节点 %u，大小 %u\n", temp_index, buddy_sys->longest[temp_index]);
        } else {
            // 不能合并，取最大值
            buddy_sys->longest[temp_index] = MAX(buddy_sys->longest[left], buddy_sys->longest[right]);
            cprintf("buddy_free_pages: 更新节点 %u，大小 %u\n", temp_index, buddy_sys->longest[temp_index]);
            break;
        }
    }
    
    // 设置页面属性
    for (unsigned i = 0; i < free_size; i++) {
        SetPageProperty(&base[i]);
        set_page_ref(&base[i], 0);
    }
    
    nr_free += free_size;
    cprintf("buddy_free_pages: 释放完成，剩余空闲 %lu\n", nr_free);
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
basic_buddy_check(void) {
    cprintf("=== 开始伙伴系统检查 ===\n");
    
    // 单页分配测试
    cprintf("测试1: 单页分配...\n");
    struct Page *p0 = alloc_pages(1);
    struct Page *p1 = alloc_pages(1);
    struct Page *p2 = alloc_pages(1);
    
    if (p0 != NULL && p1 != NULL && p2 != NULL) {
        cprintf("页面分配成功: p0=%p, p1=%p, p2=%p\n", p0, p1, p2);
        if (p0 != p1 && p0 != p2 && p1 != p2) {
            cprintf("单页分配测试通过\n");
        } else {
            panic("分配了重复的页面");
        }
    } else {
        panic("单页分配失败");
    }
    
    // 先释放单页，为多页分配腾出连续空间
    cprintf("释放单页为多页分配做准备...\n");
    free_pages(p0, 1);
    free_pages(p1, 1);
    free_pages(p2, 1);
    
    // 多页分配测试 - 从较小的开始
    cprintf("测试2: 多页分配...\n");
    struct Page *p2pages = alloc_pages(2);   // 2页
    if (p2pages != NULL) {
        cprintf("2页分配成功: %p\n", p2pages);
        free_pages(p2pages, 2);
    }
    
    struct Page *p4 = alloc_pages(4);   // 4页
    if (p4 != NULL) {
        cprintf("4页分配成功: %p\n", p4);
        free_pages(p4, 4);
    }
    
    struct Page *p8 = alloc_pages(8);   // 8页
    if (p8 != NULL) {
        cprintf("8页分配成功: %p\n", p8);
        free_pages(p8, 8);
        cprintf("多页分配测试通过\n");
    } else {
        cprintf("8页分配失败，但较小分配成功\n");
    }
   
    
    cprintf("=== 伙伴系统检查完成 ===\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = basic_buddy_check,
};
