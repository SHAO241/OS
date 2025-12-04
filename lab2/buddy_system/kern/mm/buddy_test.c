#include <pmm.h>
#include <stdio.h>
#include <assert.h>

// 详细的伙伴系统测试
void buddy_detailed_test(void) {
     
    // 测试4: 分配大块
    cprintf("测试4: 分配大块...\n");
    struct Page *large = alloc_pages(128);
    assert(large != NULL);
    free_pages(large, 128);
    cprintf("大块分配测试通过\n");
    
    cprintf("=== 所有测试通过! ===\n");
}
