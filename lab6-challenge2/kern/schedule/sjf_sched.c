#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * SJF_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be an empty list after initialization.
 *   - proc_num: set to 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 */
static void
SJF_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->proc_num = 0;
    rq->lab6_run_pool = NULL;
}

/*
 * SJF_enqueue inserts the process ``proc'' into the run-queue ``rq''
 * in order of burst time (stored in proc->lab6_priority).
 * SJF调度算法：最短作业优先，按照预期执行时间（burst time）排序。
 * The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 *
 * proc->lab6_priority stores the burst time (expected execution time) of the process.
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 */
static void
SJF_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // SJF: 最短作业优先，按照burst time（存储在lab6_priority中）排序插入
    proc->time_slice = rq->max_time_slice;
    
    // 如果进程已经在队列中，先将其移除（防止重复插入导致链表破坏）
    if (proc->rq != NULL && proc->rq == rq)
    {
        list_del_init(&proc->run_link);
        if (rq->proc_num > 0)
        {
            rq->proc_num--;
        }
    }
    
    proc->rq = rq;
    
    // 如果队列为空，直接添加
    if (list_empty(&rq->run_list))
    {
        list_add_before(&rq->run_list, &proc->run_link);
    }
    else
    {
        // 找到合适的位置插入，保持按burst time从小到大排序
        list_entry_t *le = list_next(&rq->run_list);
        bool inserted = 0;
        while (le != &rq->run_list)
        {
            struct proc_struct *p = le2proc(le, run_link);
            // 如果当前进程的burst time小于等于队列中进程的burst time，插入到它之前
            if (proc->lab6_priority <= p->lab6_priority)
            {
                list_add_before(le, &proc->run_link);
                inserted = 1;
                break;
            }
            le = list_next(le);
        }
        // 如果遍历完整个队列还没插入，说明应该插入到队尾
        if (!inserted)
        {
            list_add_before(&rq->run_list, &proc->run_link);
        }
    }
    rq->proc_num++;
}

/*
 * SJF_dequeue removes the process ``proc'' from the run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 */
static void
SJF_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    list_del_init(&proc->run_link);
    if (rq->proc_num > 0)
    {
        rq->proc_num--;
    }
    proc->rq = NULL;
}

/*
 * SJF_pick_next picks the element from the front of ``run-queue'',
 * which should be the process with the shortest burst time.
 * and returns the corresponding process pointer.
 * Return NULL if there is no process in the queue.
 */
static struct proc_struct *
SJF_pick_next(struct run_queue *rq)
{
    if (list_empty(&rq->run_list))
    {
        return NULL;
    }
    // 由于enqueue时已经按burst time排序，队列头部就是最短作业
    list_entry_t *le = list_next(&rq->run_list);
    return le2proc(le, run_link);
}

/*
 * SJF_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 * 
 * SJF调度算法：进程运行直到完成或主动让出CPU，不使用时间片限制。
 */
static void
SJF_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // SJF调度算法不使用时间片限制，进程运行直到完成
    // 但为了兼容框架，仍然更新时间片计数
    if (proc->time_slice > 0)
    {
        proc->time_slice--;
    }
    // SJF不使用时间片强制切换，只依赖进程主动让出CPU
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = SJF_init,
    .enqueue = SJF_enqueue,
    .dequeue = SJF_dequeue,
    .pick_next = SJF_pick_next,
    .proc_tick = SJF_proc_tick,
};

