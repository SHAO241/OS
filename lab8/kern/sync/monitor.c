#include <stdio.h>
#include <monitor.h>
#include <kmalloc.h>
#include <assert.h>

// Initialize monitor.
void     
monitor_init (monitor_t * mtp, size_t num_cv) {
    int i;
    assert(num_cv > 0);
    mtp->next_count = 0;
    mtp->cv = NULL;
    sem_init(&(mtp->mutex), 1); // unlocked
    sem_init(&(mtp->next), 0);
    mtp->cv = (condvar_t *) kmalloc(sizeof(condvar_t) * num_cv);
    assert(mtp->cv != NULL);
    for(i = 0; i < num_cv; i++){
        mtp->cv[i].count = 0;
        sem_init(&(mtp->cv[i].sem), 0);
        mtp->cv[i].owner = mtp;
    }
}

// Free monitor.
void
monitor_free (monitor_t * mtp, size_t num_cv) {
    kfree(mtp->cv);
}

// Unlock one of threads waiting on the condition variable. 
void 
cond_signal (condvar_t *cvp) {
    // LAB7: 填写你在lab7中实现的代码
    cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
   
    /*
     * Hoare 管程语义：
     * 如果有线程在等待（cvp->count > 0），由于 Hoare 语义要求 Signal 的线程
     * 必须立刻将锁交给被唤醒的线程，所以 Signal 线程自己需要睡眠。
     * * 1. owner->next_count++ : 表示发出 signal 的线程（我自己）即将进入 next 队列等待。
     * 2. up(&cvp->sem)       : 唤醒在条件变量上等待的那个线程。
     * 3. down(&owner->next)  : 我自己（发出 signal 的线程）进入睡眠，等待被唤醒。
     * 4. owner->next_count-- : 醒来后，表示我退出了 next 队列。
     */
     
    if (cvp->count > 0) {
        monitor_t *mtp = cvp->owner;
        mtp->next_count++;
        up(&(cvp->sem));
        down(&(mtp->next));
        mtp->next_count--;
    }
    
    cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
}

// Suspend calling thread on a condition variable waiting for condition. 
void
cond_wait (condvar_t *cvp) {
    // LAB7: 填写你在lab7中实现的代码
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
   
    /*
     * Hoare 管程语义：
     * 当前线程因为条件不满足需要等待。
     * * 1. cvp->count++        : 我要在条件变量上等待了，计数加 1。
     * 2. 释放锁逻辑：
     * if (mtp->next_count > 0) : 如果有线程（即之前发出 signal 的线程）挂起在 next 队列上，
     * 优先唤醒它们（up(&mtp->next)）。
     * else                     : 如果没有 urgent 的线程，则释放管程互斥锁（up(&mtp->mutex)），让外面的线程进来。
     * 3. down(&cvp->sem)     : 我自己睡眠在条件变量的信号量上。
     * 4. cvp->count--        : 醒来后，等待计数减 1。
     */

    cvp->count++;
    monitor_t *mtp = cvp->owner;
    
    if (mtp->next_count > 0) {
        up(&(mtp->next));
    } else {
        up(&(mtp->mutex));
    }
    
    down(&(cvp->sem));
    cvp->count--;
    
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
}