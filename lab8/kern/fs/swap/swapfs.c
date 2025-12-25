#include <swapfs.h>
#include <mmu.h>
#include <fs.h>
#include <ide.h>
#include <pmm.h>
#include <assert.h>
size_t max_swap_offset;

// [手动添加] 如果找不到 swap.h，我们在这里手动定义 swap_offset
// swap entry 结构: 最低位(bit 0)为0，Bits 8-63 为 offset
#ifndef swap_offset
#define swap_offset(entry) ({                                       \
               size_t __offset = (entry >> 8);                        \
               __offset;                                            \
          })
#endif

void swapfs_init(void)
{
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO))
    {
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
}

int swapfs_read(swap_entry_t entry, struct Page *page)
{
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

int swapfs_write(swap_entry_t entry, struct Page *page)
{
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}
