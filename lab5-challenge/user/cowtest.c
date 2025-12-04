/*
 * cowtest.c - Test Copy-on-Write mechanism
 * 
 * This test verifies that COW is working correctly:
 * 1. Parent and child share the same physical pages initially
 * 2. When either process writes, a new page is allocated
 * 3. Changes in one process are not visible to the other
 */

#include <stdio.h>
#include <ulib.h>

#define MAGIC_VALUE 0xDEADBEEF
#define MODIFIED_VALUE 0x12345678

// Global variable to test COW
volatile int shared_data = MAGIC_VALUE;

// Large array to test multiple COW pages
#define ARRAY_SIZE 256
volatile int test_array[ARRAY_SIZE];

int main(void)
{
    int i;
    
    cprintf("COW Test Program Start\n");
    cprintf("Initial shared_data = 0x%x (expect 0x%x)\n", shared_data, MAGIC_VALUE);
    
    // Initialize test array
    for (i = 0; i < ARRAY_SIZE; i++)
    {
        test_array[i] = i;
    }
    
    cprintf("Test array initialized\n");
    
    int pid = fork();
    
    if (pid < 0)
    {
        panic("fork failed!\n");
    }
    else if (pid == 0)
    {
        // Child process
        cprintf("\n[Child] PID = %d\n", getpid());
        cprintf("[Child] Before write: shared_data = 0x%x\n", shared_data);
        
        // Verify initial values
        if (shared_data != MAGIC_VALUE)
        {
            cprintf("[Child] ERROR: shared_data should be 0x%x, got 0x%x\n", 
                    MAGIC_VALUE, shared_data);
        }
        
        // Write to shared_data - this should trigger COW
        cprintf("[Child] Writing to shared_data (COW should trigger)...\n");
        shared_data = MODIFIED_VALUE;
        cprintf("[Child] After write: shared_data = 0x%x\n", shared_data);
        
        if (shared_data != MODIFIED_VALUE)
        {
            cprintf("[Child] ERROR: write failed!\n");
        }
        
        // Modify some array elements
        cprintf("[Child] Modifying test_array[0] and test_array[100]...\n");
        test_array[0] = 9999;
        test_array[100] = 8888;
        
        cprintf("[Child] test_array[0] = %d, test_array[100] = %d\n", 
                test_array[0], test_array[100]);
        
        cprintf("[Child] COW Test in child completed\n");
        exit(0);
    }
    else
    {
        // Parent process
        cprintf("\n[Parent] PID = %d, Child PID = %d\n", getpid(), pid);
        
        // Wait for child to complete its modifications
        int child_pid = waitpid(pid, NULL);
        
        cprintf("\n[Parent] Child (PID %d) exited\n", child_pid);
        
        // Check that parent's data is unchanged
        cprintf("[Parent] shared_data = 0x%x (should still be 0x%x)\n", 
                shared_data, MAGIC_VALUE);
        
        if (shared_data != MAGIC_VALUE)
        {
            cprintf("[Parent] ERROR: COW failed! Parent data was modified!\n");
            cprintf("COW Test FAILED!\n");
        }
        else
        {
            cprintf("[Parent] SUCCESS: Parent data unchanged after child write\n");
        }
        
        // Check array values
        cprintf("[Parent] test_array[0] = %d (should be 0)\n", test_array[0]);
        cprintf("[Parent] test_array[100] = %d (should be 100)\n", test_array[100]);
        
        if (test_array[0] != 0 || test_array[100] != 100)
        {
            cprintf("[Parent] ERROR: Array values corrupted!\n");
            cprintf("COW Test FAILED!\n");
        }
        else
        {
            cprintf("[Parent] SUCCESS: Array values unchanged\n");
            cprintf("\n*** COW Test PASSED! ***\n");
        }
    }
    
    cprintf("COW Test Program End\n");
    return 0;
}
