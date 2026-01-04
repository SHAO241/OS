#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * FIFO_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be an empty list after initialization.
 *   - proc_num: set to 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 */
static void
FIFO_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->proc_num = 0;
    rq->lab6_run_pool = NULL;
}

/*
 * FIFO_enqueue inserts the process ``proc'' into the tail of run-queue
 * ``rq''. FIFO调度算法：先来先服务，按照入队顺序执行。
 * The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 */
static void
FIFO_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // FIFO: 先来先服务，添加到队列尾部
    proc->time_slice = rq->max_time_slice;
    proc->rq = rq;
    list_add_before(&rq->run_list, &proc->run_link);
    rq->proc_num++;
}

/*
 * FIFO_dequeue removes the process ``proc'' from the front of run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 */
static void
FIFO_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    list_del_init(&proc->run_link);
    if (rq->proc_num > 0)
    {
        rq->proc_num--;
    }
    proc->rq = NULL;
}

/*
 * FIFO_pick_next picks the element from the front of ``run-queue'',
 * and returns the corresponding process pointer. FIFO调度算法选择队列头部的进程。
 * Return NULL if there is no process in the queue.
 */
static struct proc_struct *
FIFO_pick_next(struct run_queue *rq)
{
    if (list_empty(&rq->run_list))
    {
        return NULL;
    }
    list_entry_t *le = list_next(&rq->run_list);
    return le2proc(le, run_link);
}

/*
 * FIFO_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 * 
 * FIFO调度算法：进程运行直到完成或主动让出CPU，不使用时间片限制。
 */
static void
FIFO_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // FIFO调度算法不使用时间片限制，进程运行直到完成
    // 但为了兼容框架，仍然更新时间片计数
    if (proc->time_slice > 0)
    {
        proc->time_slice--;
    }
    // FIFO不使用时间片强制切换，只依赖进程主动让出CPU
}

struct sched_class fifo_sched_class = {
    .name = "FIFO_scheduler",
    .init = FIFO_init,
    .enqueue = FIFO_enqueue,
    .dequeue = FIFO_dequeue,
    .pick_next = FIFO_pick_next,
    .proc_tick = FIFO_proc_tick,
};

