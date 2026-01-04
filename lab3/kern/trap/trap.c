#include <assert.h>
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <kdebug.h>
#include <memlayout.h>
#include <mmu.h>
#include <riscv.h>
#include <stdio.h>
#include <trap.h>
#include <sbi.h>

#define TICK_NUM 100

// 为 riscv.h 中定义的宏创建别名
#define sscratch CSR_SSCRATCH
#define stvec    CSR_STVEC
// // 用于记录时钟中断的次数
// int ticks = 0;
// 用于记录 "100 ticks" 打印的行数
int print_counts = 0;

static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S
 */
void idt_init(void) {
    /* LAB3 2312991 : STEP 2 */
    /* (1) 每个中断服务程序(ISR)的入口地址在哪里？
     * 所有的ISR入口地址都存储在 __vectors 数组中。 uintptr_t __vectors[] 在哪里？
     * __vectors[] 位于 kern/trap/vector.S 文件中，该文件由 tools/vector.c 生成。
     * (在 lab3 目录下尝试 "make" 命令, 你就会在 kern/trap 目录中找到 vector.S 文件)
     * 你可以使用 "extern uintptr_t __vectors[];" 来定义这个外部变量，稍后会用到。
     * (2) 现在你需要在中断描述符表(IDT)中设置ISR的条目。
     * 你能在这个文件中看到 idt[256] 吗？是的，它就是IDT！你可以使用 SETGATE
     * 宏来设置IDT的每个条目。
     * (3) 设置完IDT的内容后，你需要通过 'lidt' 指令来告诉CPU IDT的位置。
     * 你不知道这条指令的含义？谷歌一下！并查看 libs/x86.h 来了解更多信息。
     * 注意: lidt 的参数是 idt_pd，试着找到它！
     */
    extern uintptr_t __vectors[];
    extern void __alltraps(void);
    /* 将 supervisor 模式的 scratch 寄存器 (sscratch) 设置为 0,
     * 这向异常处理向量表明我们当前正在内核中执行。*/
    write_csr(sscratch, 0);
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
}

/* trap_in_kernel - 测试中断/异常是否发生在内核态 */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
}

void print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB3 EXERCISE1   2312991 :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event(); // (1) 设置下一次时钟中断
            ticks++;                // (2) 计数器加一
            if (ticks == TICK_NUM) 
            {
                ticks = 0;
                print_ticks();      // (3) 输出100ticks
                print_counts++;     // (4) 打印次数加一
                if (print_counts == 10)
                {
                    sbi_shutdown();     // 调用关机函数
                }
            }
            break;
        case IRQ_H_TIMER:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_TIMER:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
            break;
        case IRQ_H_EXT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_EXT:
            cprintf("Machine software interrupt\n");
            break;
        default:
            print_trapframe(tf);
            break;
    }
}

void exception_handler(struct trapframe *tf) 
{
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB3 CHALLENGE3   2312991 :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            cprintf("Exception type:Illegal instruction\n");
            tf->epc += 4; // 更新 tf->epc 寄存器

            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB3 CHALLLENGE3   2312991 :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            cprintf("Exception type: breakpoint\n");

            // --- 开始: 判断并输出指令长度的代码 ---

            // 1. 定义一个变量来存储指令长度
            int length = 0;

            // 2. 从 epc 指向的内存地址读取前 16-bit (2字节) 的指令码
            //    需要将 uintptr_t 类型的 epc 强制转换为指针类型
            uint16_t instruction_word = *(uint16_t *)(tf->epc);

            // 3. 检查指令码的最低两位 (LSBs)
            //    0x3 在二进制中是 0b11
            if ((instruction_word & 0x3) == 0x3) {
                // 如果最低两位是 '11'，则是标准的 32-bit (4字节) 指令
                length = 4;
            } else {
                // 如果最低两位不是 '11' (即 00, 01, 10)，则是 16-bit (2字节) 压缩指令
                length = 2;
            }

            // 4. 使用 cprintf 输出指令长度
            cprintf("Instruction Length: %d bytes\n", length);

            // 5. 根据计算出的长度来更新 epc
            tf->epc += length;
            
            // --- 结束: 判断并输出指令长度的代码 --

            break;
        case CAUSE_MISALIGNED_LOAD:
            break;
        case CAUSE_FAULT_LOAD:
            break;
        case CAUSE_MISALIGNED_STORE:
            break;
        case CAUSE_FAULT_STORE:
            break;
        case CAUSE_USER_ECALL:
            break;
        case CAUSE_SUPERVISOR_ECALL:
            break;
        case CAUSE_HYPERVISOR_ECALL:
            break;
        case CAUSE_MACHINE_ECALL:
            break;
        default:
            print_trapframe(tf);
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
}

/* *
 * trap - 处理或分发一个异常/中断。当trap()函数返回时，
 * kern/trap/trapentry.S 中的代码会恢复保存在trapframe中的
 * 旧CPU状态，然后使用 iret 指令从异常中返回。
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
