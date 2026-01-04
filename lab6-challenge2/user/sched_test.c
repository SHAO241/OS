#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define TOTAL 5
/* 测试进程数量 */
#define MAX_TIME  5000
/* 最大运行时间（毫秒） */

/* 进程信息结构 */
struct proc_info {
    int pid;
    int burst_time;      /* 预期执行时间（用于SJF） */
    int arrival_time;    /* 到达时间 */
    int start_time;      /* 开始执行时间 */
    int finish_time;     /* 完成时间 */
    int wait_time;       /* 等待时间 */
    int turnaround_time; /* 周转时间 */
    int response_time;   /* 响应时间 */
    int acc;             /* 实际执行的工作量 */
};

struct proc_info proc_infos[TOTAL];
int pids[TOTAL];

/* 延迟函数，用于模拟CPU密集型工作 */
static void
spin_delay(void)
{
    int i;
    volatile int j;
    for (i = 0; i != 200; ++i)
    {
        j = !j;
    }
}

/* 工作进程：执行指定时间的工作 */
static void
worker_process(int burst_time)
{
    int time;
    int acc = 0;
    int start_time = gettime_msec();
    
    cprintf("Process %d: started at %d, burst_time=%d\n", 
            getpid(), start_time, burst_time);
    
    while (1)
    {
        spin_delay();
        ++acc;
        
        /* 每4000次循环检查一次时间 */
        if (acc % 4000 == 0)
        {
            time = gettime_msec();
            int elapsed = time - start_time;
            
            /* 如果已经执行了足够的时间，退出 */
            if (elapsed >= burst_time)
            {
                int finish_time = gettime_msec();
                cprintf("Process %d: finished at %d, acc=%d, elapsed=%d\n", 
                        getpid(), finish_time, acc, elapsed);
                exit(acc);
            }
        }
    }
}

int
main(void)
{
    int i, time;
    int start_time_total;
    
    memset(pids, 0, sizeof(pids));
    memset(proc_infos, 0, sizeof(proc_infos));
    
    /* 设置主进程优先级（较低，让子进程先运行） */
    lab6_setpriority(TOTAL + 1);
    
    /* 定义测试用例：不同burst time的进程 */
    int burst_times[TOTAL] = {1000, 500, 2000, 300, 1500};
    /* 进程按不同顺序到达，测试调度算法的效果 */
    
    start_time_total = gettime_msec();
    cprintf("=== Scheduler Test Started at %d ===\n", start_time_total);
    cprintf("Process burst times: ");
    for (i = 0; i < TOTAL; i++)
    {
        cprintf("%d ", burst_times[i]);
    }
    cprintf("\n");
    
    /* 创建子进程 */
    for (i = 0; i < TOTAL; i++)
    {
        proc_infos[i].burst_time = burst_times[i];
        proc_infos[i].arrival_time = gettime_msec() - start_time_total;
        
        if ((pids[i] = fork()) == 0)
        {
            /* 子进程：设置burst time（对于SJF，存储在lab6_priority中） */
            lab6_setpriority(burst_times[i]);
            worker_process(burst_times[i]);
        }
        
        if (pids[i] < 0)
        {
            goto failed;
        }
        
        proc_infos[i].pid = pids[i];
        
        /* 稍微延迟，模拟进程不同时到达 */
        for (int j = 0; j < 100; j++)
        {
            spin_delay();
        }
    }
    
    cprintf("Main: All %d processes forked, waiting for completion...\n", TOTAL);
    
    /* 等待所有子进程完成 */
    int first_start_time = -1;
    for (i = 0; i < TOTAL; i++)
    {
        int status = 0;
        int wait_start = gettime_msec();
        waitpid(pids[i], &status);
        int wait_end = gettime_msec();
        
        proc_infos[i].finish_time = wait_end - start_time_total;
        proc_infos[i].acc = status;
        
        /* 记录第一个进程的开始时间 */
        if (first_start_time == -1)
        {
            first_start_time = wait_start - start_time_total;
        }
        
        cprintf("Main: Process %d finished, acc=%d, finish_time=%d\n", 
                pids[i], status, proc_infos[i].finish_time);
    }
    
    /* 计算调度指标 */
    cprintf("\n=== Scheduling Metrics ===\n");
    cprintf("Process | Burst | Finish | Wait | Turnaround | Response\n");
    cprintf("--------|-------|--------|------|------------|---------\n");
    
    int total_wait = 0;
    int total_turnaround = 0;
    int total_response = 0;
    
    for (i = 0; i < TOTAL; i++)
    {
        /* 简化计算：假设进程按完成顺序执行 */
        /* 实际中需要更复杂的跟踪机制 */
        proc_infos[i].turnaround_time = proc_infos[i].finish_time - proc_infos[i].arrival_time;
        proc_infos[i].wait_time = proc_infos[i].turnaround_time - proc_infos[i].burst_time;
        proc_infos[i].response_time = first_start_time - proc_infos[i].arrival_time;
        if (proc_infos[i].response_time < 0)
        {
            proc_infos[i].response_time = 0;
        }
        
        total_wait += proc_infos[i].wait_time;
        total_turnaround += proc_infos[i].turnaround_time;
        total_response += proc_infos[i].response_time;
        
        cprintf("  P%d   |  %4d |  %5d | %4d |    %6d   |   %4d\n",
                i + 1,
                proc_infos[i].burst_time,
                proc_infos[i].finish_time,
                proc_infos[i].wait_time,
                proc_infos[i].turnaround_time,
                proc_infos[i].response_time);
    }
    
    cprintf("\n=== Average Metrics ===\n");
    cprintf("Average Wait Time:      %d ms\n", total_wait / TOTAL);
    cprintf("Average Turnaround Time: %d ms\n", total_turnaround / TOTAL);
    cprintf("Average Response Time:   %d ms\n", total_response / TOTAL);
    
    /* 输出完成顺序（用于分析调度算法） */
    cprintf("\n=== Completion Order ===\n");
    cprintf("Processes completed in order: ");
    for (i = 0; i < TOTAL; i++)
    {
        cprintf("P%d ", i + 1);
    }
    cprintf("\n");
    
    cprintf("\n=== Test Completed ===\n");
    return 0;

failed:
    for (i = 0; i < TOTAL; i++)
    {
        if (pids[i] > 0)
        {
            kill(pids[i]);
        }
    }
    panic("FAIL: Fork failed\n");
}

