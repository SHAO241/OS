#include <defs.h>
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>
#include <stat.h>
#include <lock.h>
void
exit(int error_code) {
    sys_exit(error_code);
    cprintf("BUG: exit failed.\n");
    while (1);
}

int
fork(void) {
    return sys_fork();
}

int
wait(void) {
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    int64_t exit_code_store;
    int ret;

    // 1. 如果用户传了 NULL，直接透传给系统调用
    if (store == NULL) {
        return sys_wait(pid, NULL);
    }

    // 2. 使用本地的 64 位变量接收内核返回的值
    // 这样满足 sys_wait 对 int64_t* 的类型要求
    ret = sys_wait(pid, &exit_code_store);

    // 3. 将 64 位结果安全地转换为 32 位 int 赋值给用户的 store
    // 只有在系统调用返回后才赋值，避免访问非法内存
    if (ret == 0 && store != NULL) {
        *store = (int)exit_code_store;
    }

    return ret;
}

void
yield(void) {
    sys_yield();
}

int
kill(int pid) {
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
}

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    sys_pgdir();
}

unsigned int
gettime_msec(void) {
    return (unsigned int)sys_gettime();
}

void
lab6_set_priority(uint32_t priority)
{
    sys_lab6_set_priority(priority);
}

int
sleep(unsigned int time) {
    return sys_sleep(time);
}
int
__exec(const char *name, const char **argv) {
    int argc = 0;
    while (argv[argc] != NULL) {
        argc ++;
    }
    return sys_exec(name, argc, argv);
}
