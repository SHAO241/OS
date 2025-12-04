#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init();  // init the console
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);

    print_kerninfo();

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table

    pmm_init();  // init physical memory management

    idt_init();  // init interrupt descriptor table

    clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt

//<<<<<<<<<<<<<<<<<<<<  在这里添加测试代码！ >>>>>>>>>>>>>>>>>>>>

    // --- 测试断点异常 (Breakpoint Exception) ---
    // __asm__ volatile (内联汇编) 用于在C代码中插入汇编指令
    // ebreak 是一条特殊的指令，它的唯一作用就是触发一个断点异常
    cprintf("+++ Now triggering a breakpoint exception! +++\n");
    __asm__ volatile("ebreak");
    cprintf("+++ Breakpoint exception handled, execution continues. +++\n");


    // --- 测试非法指令异常 (Illegal Instruction Exception) ---
    // (测试时请注释掉上面的 ebreak 测试代码)
    // 在RISC-V中 vmret是一条非法指令
    cprintf("+++ Now triggering an illegal instruction exception! +++\n");
    __asm__ volatile("mret");
    cprintf("+++ Illegal instruction handled, execution continues. +++\n");


    /* do nothing */
    while (1)
        ;
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

