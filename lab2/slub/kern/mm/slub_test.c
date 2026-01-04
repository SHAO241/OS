#include <slub.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

// ==================== SLUB分配器测试 ====================

void slub_check(void) {
    cprintf("========== SLUB分配器测试 ==========\n");
    cprintf("开始执行测试...\n");
    
    // 测试1：基本分配与释放
    cprintf("\n[测试1] 基本分配与释放\n");
    cprintf("准备分配32字节...\n");
    {
        void *p1 = kmalloc(32);
        assert(p1 != NULL);
        cprintf("  分配32字节: %p\n", p1);
        
        // 写入数据验证可用性
        *(int *)p1 = 0x12345678;
        assert(*(int *)p1 == 0x12345678);
        cprintf("  数据写入验证: OK\n");
        
        kfree(p1);
        cprintf("  释放对象: OK\n");
        
        // 再次分配，应该复用刚释放的对象
        void *p2 = kmalloc(32);
        assert(p2 != NULL);
        cprintf("  再次分配32字节: %p ", p2);
        if (p2 == p1) {
            cprintf("(复用成功)\n");
        } else {
            cprintf("(新对象)\n");
        }
        kfree(p2);
    }
    cprintf("[测试1] 通过!\n");
    
    // 测试2：多种大小对象分配
    cprintf("\n[测试2] 多种大小对象分配\n");
    {
        void *objs[5];
        size_t sizes[] = {8, 64, 128, 256, 512};
        int i;
        
        // 分配不同大小的对象
        for (i = 0; i < 5; i++) {
            objs[i] = kmalloc(sizes[i]);
            assert(objs[i] != NULL);
            cprintf("  分配%d字节: %p\n", sizes[i], objs[i]);
            
            // 写入不同的数据
            *(int *)objs[i] = i * 0x1000;
        }
        
        // 验证数据独立性
        for (i = 0; i < 5; i++) {
            assert(*(int *)objs[i] == i * 0x1000);
        }
        cprintf("  数据独立性验证: OK\n");
        
        // 释放所有对象
        for (i = 0; i < 5; i++) {
            kfree(objs[i]);
        }
        cprintf("  释放所有对象: OK\n");
    }
    cprintf("[测试2] 通过!\n");
    
    // 测试3：连续分配测试（触发slab扩展）
    cprintf("\n[测试3] 连续分配测试\n");
    {
        #define TEST_ALLOC_COUNT 130
        void *objs[TEST_ALLOC_COUNT];
        int i;
        
        // 连续分配20个32字节对象（可能触发新slab分配）
        cprintf("  连续分配%d个32字节对象...\n", TEST_ALLOC_COUNT);
        for (i = 0; i < TEST_ALLOC_COUNT; i++) {
            objs[i] = kmalloc(32);
            assert(objs[i] != NULL);
            *(int *)objs[i] = i;
        }
        cprintf("  分配完成\n");
        
        // 验证数据
        for (i = 0; i < TEST_ALLOC_COUNT; i++) {
            assert(*(int *)objs[i] == i);
        }
        cprintf("  数据完整性验证: OK\n");
        
        // 释放一半对象
        for (i = 0; i < TEST_ALLOC_COUNT / 2; i++) {
            kfree(objs[i]);
        }
        cprintf("  释放一半对象: OK\n");
        
        // 再次分配，应该从partial链表复用
        for (i = 0; i < TEST_ALLOC_COUNT / 2; i++) {
            objs[i] = kmalloc(32);
            assert(objs[i] != NULL);
            *(int *)objs[i] = i + 1000;
        }
        cprintf("  重新分配: OK\n");
        
        // 释放所有对象
        for (i = 0; i < TEST_ALLOC_COUNT; i++) {
            kfree(objs[i]);
        }
        cprintf("  释放所有对象: OK\n");
    }
    cprintf("[测试3] 通过!\n");
    
    // 输出统计信息
    cprintf("\n========== 测试统计 ==========\n");
    cprintf("当前已分配: %d 字节\n", slub_allocated_size());
    cprintf("\n========== SLUB测试全部通过! ==========\n");
}

