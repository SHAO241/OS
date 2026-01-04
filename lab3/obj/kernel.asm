
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	697010ef          	jal	ffffffffc0201f02 <memset>
    dtb_init();
ffffffffc0200070:	3c6000ef          	jal	ffffffffc0200436 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3b4000ef          	jal	ffffffffc0200428 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	ea050513          	addi	a0,a0,-352 # ffffffffc0201f18 <etext+0x4>
ffffffffc0200080:	08c000ef          	jal	ffffffffc020010c <cputs>

    print_kerninfo();
ffffffffc0200084:	0e4000ef          	jal	ffffffffc0200168 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	700000ef          	jal	ffffffffc0200788 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	70c010ef          	jal	ffffffffc0201798 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	6f8000ef          	jal	ffffffffc0200788 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	352000ef          	jal	ffffffffc02003e6 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	6e4000ef          	jal	ffffffffc020077c <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
ffffffffc02000a0:	ec06                	sd	ra,24(sp)
ffffffffc02000a2:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc02000a4:	386000ef          	jal	ffffffffc020042a <cons_putc>
    (*cnt) ++;
ffffffffc02000a8:	65a2                	ld	a1,8(sp)
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc02000ac:	419c                	lw	a5,0(a1)
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c19c                	sw	a5,0(a1)
}
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b6:	1101                	addi	sp,sp,-32
ffffffffc02000b8:	862a                	mv	a2,a0
ffffffffc02000ba:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000bc:	00000517          	auipc	a0,0x0
ffffffffc02000c0:	fe250513          	addi	a0,a0,-30 # ffffffffc020009e <cputch>
ffffffffc02000c4:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000c8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	111010ef          	jal	ffffffffc02019da <vprintfmt>
    return cnt;
}
ffffffffc02000ce:	60e2                	ld	ra,24(sp)
ffffffffc02000d0:	4532                	lw	a0,12(sp)
ffffffffc02000d2:	6105                	addi	sp,sp,32
ffffffffc02000d4:	8082                	ret

ffffffffc02000d6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000d8:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000dc:	f42e                	sd	a1,40(sp)
ffffffffc02000de:	f832                	sd	a2,48(sp)
ffffffffc02000e0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e2:	862a                	mv	a2,a0
ffffffffc02000e4:	004c                	addi	a1,sp,4
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f0:	ec06                	sd	ra,24(sp)
ffffffffc02000f2:	e0ba                	sd	a4,64(sp)
ffffffffc02000f4:	e4be                	sd	a5,72(sp)
ffffffffc02000f6:	e8c2                	sd	a6,80(sp)
ffffffffc02000f8:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02000fa:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02000fc:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000fe:	0dd010ef          	jal	ffffffffc02019da <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200102:	60e2                	ld	ra,24(sp)
ffffffffc0200104:	4512                	lw	a0,4(sp)
ffffffffc0200106:	6125                	addi	sp,sp,96
ffffffffc0200108:	8082                	ret

ffffffffc020010a <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010a:	a605                	j	ffffffffc020042a <cons_putc>

ffffffffc020010c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020010c:	1101                	addi	sp,sp,-32
ffffffffc020010e:	e822                	sd	s0,16(sp)
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200114:	00054503          	lbu	a0,0(a0)
ffffffffc0200118:	c51d                	beqz	a0,ffffffffc0200146 <cputs+0x3a>
ffffffffc020011a:	e426                	sd	s1,8(sp)
ffffffffc020011c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020011e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200120:	30a000ef          	jal	ffffffffc020042a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200124:	00044503          	lbu	a0,0(s0)
ffffffffc0200128:	0405                	addi	s0,s0,1
ffffffffc020012a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020012c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020012e:	f96d                	bnez	a0,ffffffffc0200120 <cputs+0x14>
    cons_putc(c);
ffffffffc0200130:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200132:	0027841b          	addiw	s0,a5,2
ffffffffc0200136:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc0200138:	2f2000ef          	jal	ffffffffc020042a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020013c:	60e2                	ld	ra,24(sp)
ffffffffc020013e:	8522                	mv	a0,s0
ffffffffc0200140:	6442                	ld	s0,16(sp)
ffffffffc0200142:	6105                	addi	sp,sp,32
ffffffffc0200144:	8082                	ret
    cons_putc(c);
ffffffffc0200146:	4529                	li	a0,10
ffffffffc0200148:	2e2000ef          	jal	ffffffffc020042a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
}
ffffffffc020014e:	60e2                	ld	ra,24(sp)
ffffffffc0200150:	8522                	mv	a0,s0
ffffffffc0200152:	6442                	ld	s0,16(sp)
ffffffffc0200154:	6105                	addi	sp,sp,32
ffffffffc0200156:	8082                	ret

ffffffffc0200158 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200158:	1141                	addi	sp,sp,-16
ffffffffc020015a:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020015c:	2d6000ef          	jal	ffffffffc0200432 <cons_getc>
ffffffffc0200160:	dd75                	beqz	a0,ffffffffc020015c <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
ffffffffc0200164:	0141                	addi	sp,sp,16
ffffffffc0200166:	8082                	ret

ffffffffc0200168 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200168:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	dce50513          	addi	a0,a0,-562 # ffffffffc0201f38 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200172:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200174:	f63ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200178:	00000597          	auipc	a1,0x0
ffffffffc020017c:	edc58593          	addi	a1,a1,-292 # ffffffffc0200054 <kern_init>
ffffffffc0200180:	00002517          	auipc	a0,0x2
ffffffffc0200184:	dd850513          	addi	a0,a0,-552 # ffffffffc0201f58 <etext+0x44>
ffffffffc0200188:	f4fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020018c:	00002597          	auipc	a1,0x2
ffffffffc0200190:	d8858593          	addi	a1,a1,-632 # ffffffffc0201f14 <etext>
ffffffffc0200194:	00002517          	auipc	a0,0x2
ffffffffc0200198:	de450513          	addi	a0,a0,-540 # ffffffffc0201f78 <etext+0x64>
ffffffffc020019c:	f3bff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a0:	00006597          	auipc	a1,0x6
ffffffffc02001a4:	e8858593          	addi	a1,a1,-376 # ffffffffc0206028 <free_area>
ffffffffc02001a8:	00002517          	auipc	a0,0x2
ffffffffc02001ac:	df050513          	addi	a0,a0,-528 # ffffffffc0201f98 <etext+0x84>
ffffffffc02001b0:	f27ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b4:	00006597          	auipc	a1,0x6
ffffffffc02001b8:	2ec58593          	addi	a1,a1,748 # ffffffffc02064a0 <end>
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	dfc50513          	addi	a0,a0,-516 # ffffffffc0201fb8 <etext+0xa4>
ffffffffc02001c4:	f13ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c8:	00000717          	auipc	a4,0x0
ffffffffc02001cc:	e8c70713          	addi	a4,a4,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	00006797          	auipc	a5,0x6
ffffffffc02001d4:	6cf78793          	addi	a5,a5,1743 # ffffffffc020689f <end+0x3ff>
ffffffffc02001d8:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001de:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e4:	95be                	add	a1,a1,a5
ffffffffc02001e6:	85a9                	srai	a1,a1,0xa
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	df050513          	addi	a0,a0,-528 # ffffffffc0201fd8 <etext+0xc4>
}
ffffffffc02001f0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f2:	b5d5                	j	ffffffffc02000d6 <cprintf>

ffffffffc02001f4 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f4:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f6:	00002617          	auipc	a2,0x2
ffffffffc02001fa:	e1260613          	addi	a2,a2,-494 # ffffffffc0202008 <etext+0xf4>
ffffffffc02001fe:	04d00593          	li	a1,77
ffffffffc0200202:	00002517          	auipc	a0,0x2
ffffffffc0200206:	e1e50513          	addi	a0,a0,-482 # ffffffffc0202020 <etext+0x10c>
void print_stackframe(void) {
ffffffffc020020a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020c:	17c000ef          	jal	ffffffffc0200388 <__panic>

ffffffffc0200210 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200210:	1101                	addi	sp,sp,-32
ffffffffc0200212:	e822                	sd	s0,16(sp)
ffffffffc0200214:	e426                	sd	s1,8(sp)
ffffffffc0200216:	ec06                	sd	ra,24(sp)
ffffffffc0200218:	00003417          	auipc	s0,0x3
ffffffffc020021c:	b8040413          	addi	s0,s0,-1152 # ffffffffc0202d98 <commands>
ffffffffc0200220:	00003497          	auipc	s1,0x3
ffffffffc0200224:	bc048493          	addi	s1,s1,-1088 # ffffffffc0202de0 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200228:	6410                	ld	a2,8(s0)
ffffffffc020022a:	600c                	ld	a1,0(s0)
ffffffffc020022c:	00002517          	auipc	a0,0x2
ffffffffc0200230:	e0c50513          	addi	a0,a0,-500 # ffffffffc0202038 <etext+0x124>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200234:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200236:	ea1ff0ef          	jal	ffffffffc02000d6 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020023a:	fe9417e3          	bne	s0,s1,ffffffffc0200228 <mon_help+0x18>
    }
    return 0;
}
ffffffffc020023e:	60e2                	ld	ra,24(sp)
ffffffffc0200240:	6442                	ld	s0,16(sp)
ffffffffc0200242:	64a2                	ld	s1,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	6105                	addi	sp,sp,32
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	f1bff0ef          	jal	ffffffffc0200168 <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f97ff0ef          	jal	ffffffffc02001f4 <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7131                	addi	sp,sp,-192
ffffffffc020026c:	e952                	sd	s4,144(sp)
ffffffffc020026e:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	dd850513          	addi	a0,a0,-552 # ffffffffc0202048 <etext+0x134>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	fd06                	sd	ra,184(sp)
ffffffffc020027a:	f922                	sd	s0,176(sp)
ffffffffc020027c:	f526                	sd	s1,168(sp)
ffffffffc020027e:	ed4e                	sd	s3,152(sp)
ffffffffc0200280:	e556                	sd	s5,136(sp)
ffffffffc0200282:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200284:	e53ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200288:	00002517          	auipc	a0,0x2
ffffffffc020028c:	de850513          	addi	a0,a0,-536 # ffffffffc0202070 <etext+0x15c>
ffffffffc0200290:	e47ff0ef          	jal	ffffffffc02000d6 <cprintf>
    if (tf != NULL) {
ffffffffc0200294:	000a0563          	beqz	s4,ffffffffc020029e <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200298:	8552                	mv	a0,s4
ffffffffc020029a:	6ce000ef          	jal	ffffffffc0200968 <print_trapframe>
ffffffffc020029e:	00003a97          	auipc	s5,0x3
ffffffffc02002a2:	afaa8a93          	addi	s5,s5,-1286 # ffffffffc0202d98 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc02002a6:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002a8:	00002517          	auipc	a0,0x2
ffffffffc02002ac:	df050513          	addi	a0,a0,-528 # ffffffffc0202098 <etext+0x184>
ffffffffc02002b0:	291010ef          	jal	ffffffffc0201d40 <readline>
ffffffffc02002b4:	842a                	mv	s0,a0
ffffffffc02002b6:	d96d                	beqz	a0,ffffffffc02002a8 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002bc:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002be:	e99d                	bnez	a1,ffffffffc02002f4 <kmonitor+0x8a>
    int argc = 0;
ffffffffc02002c0:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc02002c2:	fe0b03e3          	beqz	s6,ffffffffc02002a8 <kmonitor+0x3e>
ffffffffc02002c6:	00003497          	auipc	s1,0x3
ffffffffc02002ca:	ad248493          	addi	s1,s1,-1326 # ffffffffc0202d98 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002d0:	6582                	ld	a1,0(sp)
ffffffffc02002d2:	6088                	ld	a0,0(s1)
ffffffffc02002d4:	3c1010ef          	jal	ffffffffc0201e94 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d8:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002da:	c149                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002dc:	2405                	addiw	s0,s0,1
ffffffffc02002de:	04e1                	addi	s1,s1,24
ffffffffc02002e0:	fef418e3          	bne	s0,a5,ffffffffc02002d0 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00002517          	auipc	a0,0x2
ffffffffc02002ea:	de250513          	addi	a0,a0,-542 # ffffffffc02020c8 <etext+0x1b4>
ffffffffc02002ee:	de9ff0ef          	jal	ffffffffc02000d6 <cprintf>
    return 0;
ffffffffc02002f2:	bf5d                	j	ffffffffc02002a8 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f4:	00002517          	auipc	a0,0x2
ffffffffc02002f8:	dac50513          	addi	a0,a0,-596 # ffffffffc02020a0 <etext+0x18c>
ffffffffc02002fc:	3f5010ef          	jal	ffffffffc0201ef0 <strchr>
ffffffffc0200300:	c901                	beqz	a0,ffffffffc0200310 <kmonitor+0xa6>
ffffffffc0200302:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200306:	00040023          	sb	zero,0(s0)
ffffffffc020030a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030c:	d9d5                	beqz	a1,ffffffffc02002c0 <kmonitor+0x56>
ffffffffc020030e:	b7dd                	j	ffffffffc02002f4 <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc0200310:	00044783          	lbu	a5,0(s0)
ffffffffc0200314:	d7d5                	beqz	a5,ffffffffc02002c0 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc0200316:	03348b63          	beq	s1,s3,ffffffffc020034c <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc020031a:	00349793          	slli	a5,s1,0x3
ffffffffc020031e:	978a                	add	a5,a5,sp
ffffffffc0200320:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200322:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200326:	2485                	addiw	s1,s1,1
ffffffffc0200328:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020032a:	e591                	bnez	a1,ffffffffc0200336 <kmonitor+0xcc>
ffffffffc020032c:	bf59                	j	ffffffffc02002c2 <kmonitor+0x58>
ffffffffc020032e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200332:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200334:	d5d1                	beqz	a1,ffffffffc02002c0 <kmonitor+0x56>
ffffffffc0200336:	00002517          	auipc	a0,0x2
ffffffffc020033a:	d6a50513          	addi	a0,a0,-662 # ffffffffc02020a0 <etext+0x18c>
ffffffffc020033e:	3b3010ef          	jal	ffffffffc0201ef0 <strchr>
ffffffffc0200342:	d575                	beqz	a0,ffffffffc020032e <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	00044583          	lbu	a1,0(s0)
ffffffffc0200348:	dda5                	beqz	a1,ffffffffc02002c0 <kmonitor+0x56>
ffffffffc020034a:	b76d                	j	ffffffffc02002f4 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020034c:	45c1                	li	a1,16
ffffffffc020034e:	00002517          	auipc	a0,0x2
ffffffffc0200352:	d5a50513          	addi	a0,a0,-678 # ffffffffc02020a8 <etext+0x194>
ffffffffc0200356:	d81ff0ef          	jal	ffffffffc02000d6 <cprintf>
ffffffffc020035a:	b7c1                	j	ffffffffc020031a <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020035c:	00141793          	slli	a5,s0,0x1
ffffffffc0200360:	97a2                	add	a5,a5,s0
ffffffffc0200362:	078e                	slli	a5,a5,0x3
ffffffffc0200364:	97d6                	add	a5,a5,s5
ffffffffc0200366:	6b9c                	ld	a5,16(a5)
ffffffffc0200368:	fffb051b          	addiw	a0,s6,-1
ffffffffc020036c:	8652                	mv	a2,s4
ffffffffc020036e:	002c                	addi	a1,sp,8
ffffffffc0200370:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200372:	f2055be3          	bgez	a0,ffffffffc02002a8 <kmonitor+0x3e>
}
ffffffffc0200376:	70ea                	ld	ra,184(sp)
ffffffffc0200378:	744a                	ld	s0,176(sp)
ffffffffc020037a:	74aa                	ld	s1,168(sp)
ffffffffc020037c:	69ea                	ld	s3,152(sp)
ffffffffc020037e:	6a4a                	ld	s4,144(sp)
ffffffffc0200380:	6aaa                	ld	s5,136(sp)
ffffffffc0200382:	6b0a                	ld	s6,128(sp)
ffffffffc0200384:	6129                	addi	sp,sp,192
ffffffffc0200386:	8082                	ret

ffffffffc0200388 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200388:	00006317          	auipc	t1,0x6
ffffffffc020038c:	0b832303          	lw	t1,184(t1) # ffffffffc0206440 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200390:	715d                	addi	sp,sp,-80
ffffffffc0200392:	ec06                	sd	ra,24(sp)
ffffffffc0200394:	f436                	sd	a3,40(sp)
ffffffffc0200396:	f83a                	sd	a4,48(sp)
ffffffffc0200398:	fc3e                	sd	a5,56(sp)
ffffffffc020039a:	e0c2                	sd	a6,64(sp)
ffffffffc020039c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020039e:	02031e63          	bnez	t1,ffffffffc02003da <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003a2:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003a4:	103c                	addi	a5,sp,40
ffffffffc02003a6:	e822                	sd	s0,16(sp)
ffffffffc02003a8:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003aa:	862e                	mv	a2,a1
ffffffffc02003ac:	85aa                	mv	a1,a0
ffffffffc02003ae:	00002517          	auipc	a0,0x2
ffffffffc02003b2:	dc250513          	addi	a0,a0,-574 # ffffffffc0202170 <etext+0x25c>
    is_panic = 1;
ffffffffc02003b6:	00006697          	auipc	a3,0x6
ffffffffc02003ba:	08e6a523          	sw	a4,138(a3) # ffffffffc0206440 <is_panic>
    va_start(ap, fmt);
ffffffffc02003be:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003c0:	d17ff0ef          	jal	ffffffffc02000d6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003c4:	65a2                	ld	a1,8(sp)
ffffffffc02003c6:	8522                	mv	a0,s0
ffffffffc02003c8:	cefff0ef          	jal	ffffffffc02000b6 <vcprintf>
    cprintf("\n");
ffffffffc02003cc:	00002517          	auipc	a0,0x2
ffffffffc02003d0:	dc450513          	addi	a0,a0,-572 # ffffffffc0202190 <etext+0x27c>
ffffffffc02003d4:	d03ff0ef          	jal	ffffffffc02000d6 <cprintf>
ffffffffc02003d8:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003da:	3a8000ef          	jal	ffffffffc0200782 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003de:	4501                	li	a0,0
ffffffffc02003e0:	e8bff0ef          	jal	ffffffffc020026a <kmonitor>
    while (1) {
ffffffffc02003e4:	bfed                	j	ffffffffc02003de <__panic+0x56>

ffffffffc02003e6 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc02003e6:	1141                	addi	sp,sp,-16
ffffffffc02003e8:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc02003ea:	02000793          	li	a5,32
ffffffffc02003ee:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003f2:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003f6:	67e1                	lui	a5,0x18
ffffffffc02003f8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02003fc:	953e                	add	a0,a0,a5
ffffffffc02003fe:	213010ef          	jal	ffffffffc0201e10 <sbi_set_timer>
}
ffffffffc0200402:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200404:	00006797          	auipc	a5,0x6
ffffffffc0200408:	0407b223          	sd	zero,68(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020040c:	00002517          	auipc	a0,0x2
ffffffffc0200410:	d8c50513          	addi	a0,a0,-628 # ffffffffc0202198 <etext+0x284>
}
ffffffffc0200414:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200416:	b1c1                	j	ffffffffc02000d6 <cprintf>

ffffffffc0200418 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	1ed0106f          	j	ffffffffc0201e10 <sbi_set_timer>

ffffffffc0200428 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200428:	8082                	ret

ffffffffc020042a <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020042a:	0ff57513          	zext.b	a0,a0
ffffffffc020042e:	1c90106f          	j	ffffffffc0201df6 <sbi_console_putchar>

ffffffffc0200432 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200432:	1f90106f          	j	ffffffffc0201e2a <sbi_console_getchar>

ffffffffc0200436 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200436:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc0200438:	00002517          	auipc	a0,0x2
ffffffffc020043c:	d8050513          	addi	a0,a0,-640 # ffffffffc02021b8 <etext+0x2a4>
void dtb_init(void) {
ffffffffc0200440:	f406                	sd	ra,40(sp)
ffffffffc0200442:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200444:	c93ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200448:	00006597          	auipc	a1,0x6
ffffffffc020044c:	bb85b583          	ld	a1,-1096(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200450:	00002517          	auipc	a0,0x2
ffffffffc0200454:	d7850513          	addi	a0,a0,-648 # ffffffffc02021c8 <etext+0x2b4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200458:	00006417          	auipc	s0,0x6
ffffffffc020045c:	bb040413          	addi	s0,s0,-1104 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200460:	c77ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200464:	600c                	ld	a1,0(s0)
ffffffffc0200466:	00002517          	auipc	a0,0x2
ffffffffc020046a:	d7250513          	addi	a0,a0,-654 # ffffffffc02021d8 <etext+0x2c4>
ffffffffc020046e:	c69ff0ef          	jal	ffffffffc02000d6 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200472:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	d7c50513          	addi	a0,a0,-644 # ffffffffc02021f0 <etext+0x2dc>
    if (boot_dtb == 0) {
ffffffffc020047c:	10070163          	beqz	a4,ffffffffc020057e <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200480:	57f5                	li	a5,-3
ffffffffc0200482:	07fa                	slli	a5,a5,0x1e
ffffffffc0200484:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200486:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200488:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020048c:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9a4d>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200490:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200494:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200498:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049c:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a4:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a6:	8e49                	or	a2,a2,a0
ffffffffc02004a8:	0ff7f793          	zext.b	a5,a5
ffffffffc02004ac:	8dd1                	or	a1,a1,a2
ffffffffc02004ae:	07a2                	slli	a5,a5,0x8
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b2:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02004b6:	0cd59863          	bne	a1,a3,ffffffffc0200586 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02004ba:	4710                	lw	a2,8(a4)
ffffffffc02004bc:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02004be:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0086541b          	srliw	s0,a2,0x8
ffffffffc02004c4:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c8:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02004cc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0186151b          	slliw	a0,a2,0x18
ffffffffc02004d4:	0186959b          	slliw	a1,a3,0x18
ffffffffc02004d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004dc:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e4:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02004e8:	01c56533          	or	a0,a0,t3
ffffffffc02004ec:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0ff6f693          	zext.b	a3,a3
ffffffffc0200500:	8c49                	or	s0,s0,a0
ffffffffc0200502:	0622                	slli	a2,a2,0x8
ffffffffc0200504:	8fcd                	or	a5,a5,a1
ffffffffc0200506:	06a2                	slli	a3,a3,0x8
ffffffffc0200508:	8c51                	or	s0,s0,a2
ffffffffc020050a:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020050c:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020050e:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200510:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200512:	9381                	srli	a5,a5,0x20
ffffffffc0200514:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200516:	4301                	li	t1,0
        switch (token) {
ffffffffc0200518:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020051a:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020051c:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200520:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200522:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200528:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200530:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200534:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200538:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	8ed1                	or	a3,a3,a2
ffffffffc020053e:	0ff77713          	zext.b	a4,a4
ffffffffc0200542:	8fd5                	or	a5,a5,a3
ffffffffc0200544:	0722                	slli	a4,a4,0x8
ffffffffc0200546:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc0200548:	05178763          	beq	a5,a7,ffffffffc0200596 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020054c:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc020054e:	00f8e963          	bltu	a7,a5,ffffffffc0200560 <dtb_init+0x12a>
ffffffffc0200552:	07c78d63          	beq	a5,t3,ffffffffc02005cc <dtb_init+0x196>
ffffffffc0200556:	4709                	li	a4,2
ffffffffc0200558:	00e79763          	bne	a5,a4,ffffffffc0200566 <dtb_init+0x130>
ffffffffc020055c:	4301                	li	t1,0
ffffffffc020055e:	b7d1                	j	ffffffffc0200522 <dtb_init+0xec>
ffffffffc0200560:	4711                	li	a4,4
ffffffffc0200562:	fce780e3          	beq	a5,a4,ffffffffc0200522 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	d5250513          	addi	a0,a0,-686 # ffffffffc02022b8 <etext+0x3a4>
ffffffffc020056e:	b69ff0ef          	jal	ffffffffc02000d6 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200572:	64e2                	ld	s1,24(sp)
ffffffffc0200574:	6942                	ld	s2,16(sp)
ffffffffc0200576:	00002517          	auipc	a0,0x2
ffffffffc020057a:	d7a50513          	addi	a0,a0,-646 # ffffffffc02022f0 <etext+0x3dc>
}
ffffffffc020057e:	7402                	ld	s0,32(sp)
ffffffffc0200580:	70a2                	ld	ra,40(sp)
ffffffffc0200582:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200584:	be89                	j	ffffffffc02000d6 <cprintf>
}
ffffffffc0200586:	7402                	ld	s0,32(sp)
ffffffffc0200588:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	c8650513          	addi	a0,a0,-890 # ffffffffc0202210 <etext+0x2fc>
}
ffffffffc0200592:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200594:	b689                	j	ffffffffc02000d6 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200596:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200598:	0087579b          	srliw	a5,a4,0x8
ffffffffc020059c:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a8:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b0:	8ed1                	or	a3,a3,a2
ffffffffc02005b2:	0ff77713          	zext.b	a4,a4
ffffffffc02005b6:	8fd5                	or	a5,a5,a3
ffffffffc02005b8:	0722                	slli	a4,a4,0x8
ffffffffc02005ba:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005bc:	04031463          	bnez	t1,ffffffffc0200604 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02005c0:	1782                	slli	a5,a5,0x20
ffffffffc02005c2:	9381                	srli	a5,a5,0x20
ffffffffc02005c4:	043d                	addi	s0,s0,15
ffffffffc02005c6:	943e                	add	s0,s0,a5
ffffffffc02005c8:	9871                	andi	s0,s0,-4
                break;
ffffffffc02005ca:	bfa1                	j	ffffffffc0200522 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02005cc:	8522                	mv	a0,s0
ffffffffc02005ce:	e01a                	sd	t1,0(sp)
ffffffffc02005d0:	091010ef          	jal	ffffffffc0201e60 <strlen>
ffffffffc02005d4:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	4619                	li	a2,6
ffffffffc02005d8:	8522                	mv	a0,s0
ffffffffc02005da:	00002597          	auipc	a1,0x2
ffffffffc02005de:	c5e58593          	addi	a1,a1,-930 # ffffffffc0202238 <etext+0x324>
ffffffffc02005e2:	0e7010ef          	jal	ffffffffc0201ec8 <strncmp>
ffffffffc02005e6:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02005e8:	0411                	addi	s0,s0,4
ffffffffc02005ea:	0004879b          	sext.w	a5,s1
ffffffffc02005ee:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005f0:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02005f4:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005f6:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02005fa:	00ff0837          	lui	a6,0xff0
ffffffffc02005fe:	488d                	li	a7,3
ffffffffc0200600:	4e05                	li	t3,1
ffffffffc0200602:	b705                	j	ffffffffc0200522 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200604:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200606:	00002597          	auipc	a1,0x2
ffffffffc020060a:	c3a58593          	addi	a1,a1,-966 # ffffffffc0202240 <etext+0x32c>
ffffffffc020060e:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200610:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200614:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200618:	0187169b          	slliw	a3,a4,0x18
ffffffffc020061c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200620:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8ed1                	or	a3,a3,a2
ffffffffc020062a:	0ff77713          	zext.b	a4,a4
ffffffffc020062e:	0722                	slli	a4,a4,0x8
ffffffffc0200630:	8d55                	or	a0,a0,a3
ffffffffc0200632:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200634:	1502                	slli	a0,a0,0x20
ffffffffc0200636:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200638:	954a                	add	a0,a0,s2
ffffffffc020063a:	e01a                	sd	t1,0(sp)
ffffffffc020063c:	059010ef          	jal	ffffffffc0201e94 <strcmp>
ffffffffc0200640:	67a2                	ld	a5,8(sp)
ffffffffc0200642:	473d                	li	a4,15
ffffffffc0200644:	6302                	ld	t1,0(sp)
ffffffffc0200646:	00ff0837          	lui	a6,0xff0
ffffffffc020064a:	488d                	li	a7,3
ffffffffc020064c:	4e05                	li	t3,1
ffffffffc020064e:	f6f779e3          	bgeu	a4,a5,ffffffffc02005c0 <dtb_init+0x18a>
ffffffffc0200652:	f53d                	bnez	a0,ffffffffc02005c0 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200654:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200658:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020065c:	00002517          	auipc	a0,0x2
ffffffffc0200660:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202248 <etext+0x334>
           fdt32_to_cpu(x >> 32);
ffffffffc0200664:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200668:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020066c:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200670:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200674:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200678:	0187959b          	slliw	a1,a5,0x18
ffffffffc020067c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200688:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	01037333          	and	t1,t1,a6
ffffffffc0200690:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200698:	0ff7f793          	zext.b	a5,a5
ffffffffc020069c:	01de6e33          	or	t3,t3,t4
ffffffffc02006a0:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	01067633          	and	a2,a2,a6
ffffffffc02006a8:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02006ac:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	07a2                	slli	a5,a5,0x8
ffffffffc02006b2:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02006b6:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02006ba:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02006be:	8ddd                	or	a1,a1,a5
ffffffffc02006c0:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0186979b          	slliw	a5,a3,0x18
ffffffffc02006c8:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006cc:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d0:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e4:	08a2                	slli	a7,a7,0x8
ffffffffc02006e6:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ea:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02006f2:	01de6833          	or	a6,t3,t4
ffffffffc02006f6:	0ff77713          	zext.b	a4,a4
ffffffffc02006fa:	01166633          	or	a2,a2,a7
ffffffffc02006fe:	0067e7b3          	or	a5,a5,t1
ffffffffc0200702:	06a2                	slli	a3,a3,0x8
ffffffffc0200704:	01046433          	or	s0,s0,a6
ffffffffc0200708:	0722                	slli	a4,a4,0x8
ffffffffc020070a:	8fd5                	or	a5,a5,a3
ffffffffc020070c:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc020070e:	1582                	slli	a1,a1,0x20
ffffffffc0200710:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200712:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200714:	9201                	srli	a2,a2,0x20
ffffffffc0200716:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200718:	1402                	slli	s0,s0,0x20
ffffffffc020071a:	00b7e4b3          	or	s1,a5,a1
ffffffffc020071e:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200720:	9b7ff0ef          	jal	ffffffffc02000d6 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200724:	85a6                	mv	a1,s1
ffffffffc0200726:	00002517          	auipc	a0,0x2
ffffffffc020072a:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202268 <etext+0x354>
ffffffffc020072e:	9a9ff0ef          	jal	ffffffffc02000d6 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200732:	01445613          	srli	a2,s0,0x14
ffffffffc0200736:	85a2                	mv	a1,s0
ffffffffc0200738:	00002517          	auipc	a0,0x2
ffffffffc020073c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0202280 <etext+0x36c>
ffffffffc0200740:	997ff0ef          	jal	ffffffffc02000d6 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200744:	009405b3          	add	a1,s0,s1
ffffffffc0200748:	15fd                	addi	a1,a1,-1
ffffffffc020074a:	00002517          	auipc	a0,0x2
ffffffffc020074e:	b5650513          	addi	a0,a0,-1194 # ffffffffc02022a0 <etext+0x38c>
ffffffffc0200752:	985ff0ef          	jal	ffffffffc02000d6 <cprintf>
        memory_base = mem_base;
ffffffffc0200756:	00006797          	auipc	a5,0x6
ffffffffc020075a:	d097b123          	sd	s1,-766(a5) # ffffffffc0206458 <memory_base>
        memory_size = mem_size;
ffffffffc020075e:	00006797          	auipc	a5,0x6
ffffffffc0200762:	ce87b923          	sd	s0,-782(a5) # ffffffffc0206450 <memory_size>
ffffffffc0200766:	b531                	j	ffffffffc0200572 <dtb_init+0x13c>

ffffffffc0200768 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200768:	00006517          	auipc	a0,0x6
ffffffffc020076c:	cf053503          	ld	a0,-784(a0) # ffffffffc0206458 <memory_base>
ffffffffc0200770:	8082                	ret

ffffffffc0200772 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200772:	00006517          	auipc	a0,0x6
ffffffffc0200776:	cde53503          	ld	a0,-802(a0) # ffffffffc0206450 <memory_size>
ffffffffc020077a:	8082                	ret

ffffffffc020077c <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020077c:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200780:	8082                	ret

ffffffffc0200782 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200782:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200786:	8082                	ret

ffffffffc0200788 <idt_init>:
     */
    extern uintptr_t __vectors[];
    extern void __alltraps(void);
    /* 将 supervisor 模式的 scratch 寄存器 (sscratch) 设置为 0,
     * 这向异常处理向量表明我们当前正在内核中执行。*/
    write_csr(sscratch, 0);
ffffffffc0200788:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020078c:	00000797          	auipc	a5,0x0
ffffffffc0200790:	38078793          	addi	a5,a5,896 # ffffffffc0200b0c <__alltraps>
ffffffffc0200794:	10579073          	csrw	stvec,a5
}
ffffffffc0200798:	8082                	ret

ffffffffc020079a <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020079a:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020079c:	1141                	addi	sp,sp,-16
ffffffffc020079e:	e022                	sd	s0,0(sp)
ffffffffc02007a0:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007a2:	00002517          	auipc	a0,0x2
ffffffffc02007a6:	b6650513          	addi	a0,a0,-1178 # ffffffffc0202308 <etext+0x3f4>
void print_regs(struct pushregs *gpr) {
ffffffffc02007aa:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007ac:	92bff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02007b0:	640c                	ld	a1,8(s0)
ffffffffc02007b2:	00002517          	auipc	a0,0x2
ffffffffc02007b6:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202320 <etext+0x40c>
ffffffffc02007ba:	91dff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02007be:	680c                	ld	a1,16(s0)
ffffffffc02007c0:	00002517          	auipc	a0,0x2
ffffffffc02007c4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202338 <etext+0x424>
ffffffffc02007c8:	90fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02007cc:	6c0c                	ld	a1,24(s0)
ffffffffc02007ce:	00002517          	auipc	a0,0x2
ffffffffc02007d2:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202350 <etext+0x43c>
ffffffffc02007d6:	901ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02007da:	700c                	ld	a1,32(s0)
ffffffffc02007dc:	00002517          	auipc	a0,0x2
ffffffffc02007e0:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202368 <etext+0x454>
ffffffffc02007e4:	8f3ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02007e8:	740c                	ld	a1,40(s0)
ffffffffc02007ea:	00002517          	auipc	a0,0x2
ffffffffc02007ee:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202380 <etext+0x46c>
ffffffffc02007f2:	8e5ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02007f6:	780c                	ld	a1,48(s0)
ffffffffc02007f8:	00002517          	auipc	a0,0x2
ffffffffc02007fc:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202398 <etext+0x484>
ffffffffc0200800:	8d7ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200804:	7c0c                	ld	a1,56(s0)
ffffffffc0200806:	00002517          	auipc	a0,0x2
ffffffffc020080a:	baa50513          	addi	a0,a0,-1110 # ffffffffc02023b0 <etext+0x49c>
ffffffffc020080e:	8c9ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200812:	602c                	ld	a1,64(s0)
ffffffffc0200814:	00002517          	auipc	a0,0x2
ffffffffc0200818:	bb450513          	addi	a0,a0,-1100 # ffffffffc02023c8 <etext+0x4b4>
ffffffffc020081c:	8bbff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200820:	642c                	ld	a1,72(s0)
ffffffffc0200822:	00002517          	auipc	a0,0x2
ffffffffc0200826:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02023e0 <etext+0x4cc>
ffffffffc020082a:	8adff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020082e:	682c                	ld	a1,80(s0)
ffffffffc0200830:	00002517          	auipc	a0,0x2
ffffffffc0200834:	bc850513          	addi	a0,a0,-1080 # ffffffffc02023f8 <etext+0x4e4>
ffffffffc0200838:	89fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020083c:	6c2c                	ld	a1,88(s0)
ffffffffc020083e:	00002517          	auipc	a0,0x2
ffffffffc0200842:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202410 <etext+0x4fc>
ffffffffc0200846:	891ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020084a:	702c                	ld	a1,96(s0)
ffffffffc020084c:	00002517          	auipc	a0,0x2
ffffffffc0200850:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202428 <etext+0x514>
ffffffffc0200854:	883ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200858:	742c                	ld	a1,104(s0)
ffffffffc020085a:	00002517          	auipc	a0,0x2
ffffffffc020085e:	be650513          	addi	a0,a0,-1050 # ffffffffc0202440 <etext+0x52c>
ffffffffc0200862:	875ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200866:	782c                	ld	a1,112(s0)
ffffffffc0200868:	00002517          	auipc	a0,0x2
ffffffffc020086c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202458 <etext+0x544>
ffffffffc0200870:	867ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200874:	7c2c                	ld	a1,120(s0)
ffffffffc0200876:	00002517          	auipc	a0,0x2
ffffffffc020087a:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202470 <etext+0x55c>
ffffffffc020087e:	859ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200882:	604c                	ld	a1,128(s0)
ffffffffc0200884:	00002517          	auipc	a0,0x2
ffffffffc0200888:	c0450513          	addi	a0,a0,-1020 # ffffffffc0202488 <etext+0x574>
ffffffffc020088c:	84bff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200890:	644c                	ld	a1,136(s0)
ffffffffc0200892:	00002517          	auipc	a0,0x2
ffffffffc0200896:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02024a0 <etext+0x58c>
ffffffffc020089a:	83dff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020089e:	684c                	ld	a1,144(s0)
ffffffffc02008a0:	00002517          	auipc	a0,0x2
ffffffffc02008a4:	c1850513          	addi	a0,a0,-1000 # ffffffffc02024b8 <etext+0x5a4>
ffffffffc02008a8:	82fff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02008ac:	6c4c                	ld	a1,152(s0)
ffffffffc02008ae:	00002517          	auipc	a0,0x2
ffffffffc02008b2:	c2250513          	addi	a0,a0,-990 # ffffffffc02024d0 <etext+0x5bc>
ffffffffc02008b6:	821ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02008ba:	704c                	ld	a1,160(s0)
ffffffffc02008bc:	00002517          	auipc	a0,0x2
ffffffffc02008c0:	c2c50513          	addi	a0,a0,-980 # ffffffffc02024e8 <etext+0x5d4>
ffffffffc02008c4:	813ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02008c8:	744c                	ld	a1,168(s0)
ffffffffc02008ca:	00002517          	auipc	a0,0x2
ffffffffc02008ce:	c3650513          	addi	a0,a0,-970 # ffffffffc0202500 <etext+0x5ec>
ffffffffc02008d2:	805ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02008d6:	784c                	ld	a1,176(s0)
ffffffffc02008d8:	00002517          	auipc	a0,0x2
ffffffffc02008dc:	c4050513          	addi	a0,a0,-960 # ffffffffc0202518 <etext+0x604>
ffffffffc02008e0:	ff6ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02008e4:	7c4c                	ld	a1,184(s0)
ffffffffc02008e6:	00002517          	auipc	a0,0x2
ffffffffc02008ea:	c4a50513          	addi	a0,a0,-950 # ffffffffc0202530 <etext+0x61c>
ffffffffc02008ee:	fe8ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02008f2:	606c                	ld	a1,192(s0)
ffffffffc02008f4:	00002517          	auipc	a0,0x2
ffffffffc02008f8:	c5450513          	addi	a0,a0,-940 # ffffffffc0202548 <etext+0x634>
ffffffffc02008fc:	fdaff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200900:	646c                	ld	a1,200(s0)
ffffffffc0200902:	00002517          	auipc	a0,0x2
ffffffffc0200906:	c5e50513          	addi	a0,a0,-930 # ffffffffc0202560 <etext+0x64c>
ffffffffc020090a:	fccff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc020090e:	686c                	ld	a1,208(s0)
ffffffffc0200910:	00002517          	auipc	a0,0x2
ffffffffc0200914:	c6850513          	addi	a0,a0,-920 # ffffffffc0202578 <etext+0x664>
ffffffffc0200918:	fbeff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc020091c:	6c6c                	ld	a1,216(s0)
ffffffffc020091e:	00002517          	auipc	a0,0x2
ffffffffc0200922:	c7250513          	addi	a0,a0,-910 # ffffffffc0202590 <etext+0x67c>
ffffffffc0200926:	fb0ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020092a:	706c                	ld	a1,224(s0)
ffffffffc020092c:	00002517          	auipc	a0,0x2
ffffffffc0200930:	c7c50513          	addi	a0,a0,-900 # ffffffffc02025a8 <etext+0x694>
ffffffffc0200934:	fa2ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200938:	746c                	ld	a1,232(s0)
ffffffffc020093a:	00002517          	auipc	a0,0x2
ffffffffc020093e:	c8650513          	addi	a0,a0,-890 # ffffffffc02025c0 <etext+0x6ac>
ffffffffc0200942:	f94ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200946:	786c                	ld	a1,240(s0)
ffffffffc0200948:	00002517          	auipc	a0,0x2
ffffffffc020094c:	c9050513          	addi	a0,a0,-880 # ffffffffc02025d8 <etext+0x6c4>
ffffffffc0200950:	f86ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200954:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200956:	6402                	ld	s0,0(sp)
ffffffffc0200958:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020095a:	00002517          	auipc	a0,0x2
ffffffffc020095e:	c9650513          	addi	a0,a0,-874 # ffffffffc02025f0 <etext+0x6dc>
}
ffffffffc0200962:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200964:	f72ff06f          	j	ffffffffc02000d6 <cprintf>

ffffffffc0200968 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200968:	1141                	addi	sp,sp,-16
ffffffffc020096a:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020096c:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc020096e:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	c9850513          	addi	a0,a0,-872 # ffffffffc0202608 <etext+0x6f4>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200978:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020097a:	f5cff0ef          	jal	ffffffffc02000d6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc020097e:	8522                	mv	a0,s0
ffffffffc0200980:	e1bff0ef          	jal	ffffffffc020079a <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200984:	10043583          	ld	a1,256(s0)
ffffffffc0200988:	00002517          	auipc	a0,0x2
ffffffffc020098c:	c9850513          	addi	a0,a0,-872 # ffffffffc0202620 <etext+0x70c>
ffffffffc0200990:	f46ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200994:	10843583          	ld	a1,264(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	ca050513          	addi	a0,a0,-864 # ffffffffc0202638 <etext+0x724>
ffffffffc02009a0:	f36ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc02009a4:	11043583          	ld	a1,272(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	ca850513          	addi	a0,a0,-856 # ffffffffc0202650 <etext+0x73c>
ffffffffc02009b0:	f26ff0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02009b4:	11843583          	ld	a1,280(s0)
}
ffffffffc02009b8:	6402                	ld	s0,0(sp)
ffffffffc02009ba:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02009bc:	00002517          	auipc	a0,0x2
ffffffffc02009c0:	cac50513          	addi	a0,a0,-852 # ffffffffc0202668 <etext+0x754>
}
ffffffffc02009c4:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02009c6:	f10ff06f          	j	ffffffffc02000d6 <cprintf>

ffffffffc02009ca <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc02009ca:	11853783          	ld	a5,280(a0)
ffffffffc02009ce:	472d                	li	a4,11
ffffffffc02009d0:	0786                	slli	a5,a5,0x1
ffffffffc02009d2:	8385                	srli	a5,a5,0x1
ffffffffc02009d4:	08f76263          	bltu	a4,a5,ffffffffc0200a58 <interrupt_handler+0x8e>
ffffffffc02009d8:	00002717          	auipc	a4,0x2
ffffffffc02009dc:	40870713          	addi	a4,a4,1032 # ffffffffc0202de0 <commands+0x48>
ffffffffc02009e0:	078a                	slli	a5,a5,0x2
ffffffffc02009e2:	97ba                	add	a5,a5,a4
ffffffffc02009e4:	439c                	lw	a5,0(a5)
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	cf650513          	addi	a0,a0,-778 # ffffffffc02026e0 <etext+0x7cc>
ffffffffc02009f2:	ee4ff06f          	j	ffffffffc02000d6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009f6:	00002517          	auipc	a0,0x2
ffffffffc02009fa:	cca50513          	addi	a0,a0,-822 # ffffffffc02026c0 <etext+0x7ac>
ffffffffc02009fe:	ed8ff06f          	j	ffffffffc02000d6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	c7e50513          	addi	a0,a0,-898 # ffffffffc0202680 <etext+0x76c>
ffffffffc0200a0a:	eccff06f          	j	ffffffffc02000d6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	cf250513          	addi	a0,a0,-782 # ffffffffc0202700 <etext+0x7ec>
ffffffffc0200a16:	ec0ff06f          	j	ffffffffc02000d6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a1a:	1141                	addi	sp,sp,-16
ffffffffc0200a1c:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event(); // (1) 设置下一次时钟中断
ffffffffc0200a1e:	9fbff0ef          	jal	ffffffffc0200418 <clock_set_next_event>
            ticks++;                // (2) 计数器加一
ffffffffc0200a22:	00006797          	auipc	a5,0x6
ffffffffc0200a26:	a2678793          	addi	a5,a5,-1498 # ffffffffc0206448 <ticks>
ffffffffc0200a2a:	6398                	ld	a4,0(a5)
            if (ticks == TICK_NUM) 
ffffffffc0200a2c:	06400693          	li	a3,100
            ticks++;                // (2) 计数器加一
ffffffffc0200a30:	0705                	addi	a4,a4,1
ffffffffc0200a32:	e398                	sd	a4,0(a5)
            if (ticks == TICK_NUM) 
ffffffffc0200a34:	638c                	ld	a1,0(a5)
ffffffffc0200a36:	02d58263          	beq	a1,a3,ffffffffc0200a5a <interrupt_handler+0x90>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a3a:	60a2                	ld	ra,8(sp)
ffffffffc0200a3c:	0141                	addi	sp,sp,16
ffffffffc0200a3e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a40:	00002517          	auipc	a0,0x2
ffffffffc0200a44:	ce850513          	addi	a0,a0,-792 # ffffffffc0202728 <etext+0x814>
ffffffffc0200a48:	e8eff06f          	j	ffffffffc02000d6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	c5450513          	addi	a0,a0,-940 # ffffffffc02026a0 <etext+0x78c>
ffffffffc0200a54:	e82ff06f          	j	ffffffffc02000d6 <cprintf>
            print_trapframe(tf);
ffffffffc0200a58:	bf01                	j	ffffffffc0200968 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	cbe50513          	addi	a0,a0,-834 # ffffffffc0202718 <etext+0x804>
                ticks = 0;
ffffffffc0200a62:	00006797          	auipc	a5,0x6
ffffffffc0200a66:	9e07b323          	sd	zero,-1562(a5) # ffffffffc0206448 <ticks>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200a6a:	e6cff0ef          	jal	ffffffffc02000d6 <cprintf>
                print_counts++;     // (4) 打印次数加一
ffffffffc0200a6e:	00006797          	auipc	a5,0x6
ffffffffc0200a72:	9f27a783          	lw	a5,-1550(a5) # ffffffffc0206460 <print_counts>
                if (print_counts == 10)
ffffffffc0200a76:	4729                	li	a4,10
                print_counts++;     // (4) 打印次数加一
ffffffffc0200a78:	2785                	addiw	a5,a5,1
ffffffffc0200a7a:	00006697          	auipc	a3,0x6
ffffffffc0200a7e:	9ef6a323          	sw	a5,-1562(a3) # ffffffffc0206460 <print_counts>
                if (print_counts == 10)
ffffffffc0200a82:	fae79ce3          	bne	a5,a4,ffffffffc0200a3a <interrupt_handler+0x70>
}
ffffffffc0200a86:	60a2                	ld	ra,8(sp)
ffffffffc0200a88:	0141                	addi	sp,sp,16
                    sbi_shutdown();     // 调用关机函数
ffffffffc0200a8a:	3bc0106f          	j	ffffffffc0201e46 <sbi_shutdown>

ffffffffc0200a8e <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200a8e:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a92:	1101                	addi	sp,sp,-32
ffffffffc0200a94:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200a96:	468d                	li	a3,3
ffffffffc0200a98:	04d78663          	beq	a5,a3,ffffffffc0200ae4 <exception_handler+0x56>
ffffffffc0200a9c:	02f6ed63          	bltu	a3,a5,ffffffffc0200ad6 <exception_handler+0x48>
ffffffffc0200aa0:	4689                	li	a3,2
ffffffffc0200aa2:	02d79763          	bne	a5,a3,ffffffffc0200ad0 <exception_handler+0x42>
             /* LAB3 CHALLENGE3   2312991 :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200aa6:	10853583          	ld	a1,264(a0)
ffffffffc0200aaa:	e42a                	sd	a0,8(sp)
ffffffffc0200aac:	00002517          	auipc	a0,0x2
ffffffffc0200ab0:	c9c50513          	addi	a0,a0,-868 # ffffffffc0202748 <etext+0x834>
ffffffffc0200ab4:	e22ff0ef          	jal	ffffffffc02000d6 <cprintf>
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200ab8:	00002517          	auipc	a0,0x2
ffffffffc0200abc:	cb850513          	addi	a0,a0,-840 # ffffffffc0202770 <etext+0x85c>
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            cprintf("Exception type: breakpoint\n");
ffffffffc0200ac0:	e16ff0ef          	jal	ffffffffc02000d6 <cprintf>
            tf->epc += 4; // 更新 tf->epc 寄存器
ffffffffc0200ac4:	6722                	ld	a4,8(sp)
ffffffffc0200ac6:	10873783          	ld	a5,264(a4)
ffffffffc0200aca:	0791                	addi	a5,a5,4
ffffffffc0200acc:	10f73423          	sd	a5,264(a4)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ad0:	60e2                	ld	ra,24(sp)
ffffffffc0200ad2:	6105                	addi	sp,sp,32
ffffffffc0200ad4:	8082                	ret
    switch (tf->cause) {
ffffffffc0200ad6:	17f1                	addi	a5,a5,-4
ffffffffc0200ad8:	471d                	li	a4,7
ffffffffc0200ada:	fef77be3          	bgeu	a4,a5,ffffffffc0200ad0 <exception_handler+0x42>
}
ffffffffc0200ade:	60e2                	ld	ra,24(sp)
ffffffffc0200ae0:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200ae2:	b559                	j	ffffffffc0200968 <print_trapframe>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200ae4:	10853583          	ld	a1,264(a0)
ffffffffc0200ae8:	e42a                	sd	a0,8(sp)
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	cae50513          	addi	a0,a0,-850 # ffffffffc0202798 <etext+0x884>
ffffffffc0200af2:	de4ff0ef          	jal	ffffffffc02000d6 <cprintf>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	cc250513          	addi	a0,a0,-830 # ffffffffc02027b8 <etext+0x8a4>
ffffffffc0200afe:	b7c9                	j	ffffffffc0200ac0 <exception_handler+0x32>

ffffffffc0200b00 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b00:	11853783          	ld	a5,280(a0)
ffffffffc0200b04:	0007c363          	bltz	a5,ffffffffc0200b0a <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b08:	b759                	j	ffffffffc0200a8e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b0a:	b5c1                	j	ffffffffc02009ca <interrupt_handler>

ffffffffc0200b0c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b0c:	14011073          	csrw	sscratch,sp
ffffffffc0200b10:	712d                	addi	sp,sp,-288
ffffffffc0200b12:	e002                	sd	zero,0(sp)
ffffffffc0200b14:	e406                	sd	ra,8(sp)
ffffffffc0200b16:	ec0e                	sd	gp,24(sp)
ffffffffc0200b18:	f012                	sd	tp,32(sp)
ffffffffc0200b1a:	f416                	sd	t0,40(sp)
ffffffffc0200b1c:	f81a                	sd	t1,48(sp)
ffffffffc0200b1e:	fc1e                	sd	t2,56(sp)
ffffffffc0200b20:	e0a2                	sd	s0,64(sp)
ffffffffc0200b22:	e4a6                	sd	s1,72(sp)
ffffffffc0200b24:	e8aa                	sd	a0,80(sp)
ffffffffc0200b26:	ecae                	sd	a1,88(sp)
ffffffffc0200b28:	f0b2                	sd	a2,96(sp)
ffffffffc0200b2a:	f4b6                	sd	a3,104(sp)
ffffffffc0200b2c:	f8ba                	sd	a4,112(sp)
ffffffffc0200b2e:	fcbe                	sd	a5,120(sp)
ffffffffc0200b30:	e142                	sd	a6,128(sp)
ffffffffc0200b32:	e546                	sd	a7,136(sp)
ffffffffc0200b34:	e94a                	sd	s2,144(sp)
ffffffffc0200b36:	ed4e                	sd	s3,152(sp)
ffffffffc0200b38:	f152                	sd	s4,160(sp)
ffffffffc0200b3a:	f556                	sd	s5,168(sp)
ffffffffc0200b3c:	f95a                	sd	s6,176(sp)
ffffffffc0200b3e:	fd5e                	sd	s7,184(sp)
ffffffffc0200b40:	e1e2                	sd	s8,192(sp)
ffffffffc0200b42:	e5e6                	sd	s9,200(sp)
ffffffffc0200b44:	e9ea                	sd	s10,208(sp)
ffffffffc0200b46:	edee                	sd	s11,216(sp)
ffffffffc0200b48:	f1f2                	sd	t3,224(sp)
ffffffffc0200b4a:	f5f6                	sd	t4,232(sp)
ffffffffc0200b4c:	f9fa                	sd	t5,240(sp)
ffffffffc0200b4e:	fdfe                	sd	t6,248(sp)
ffffffffc0200b50:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200b54:	100024f3          	csrr	s1,sstatus
ffffffffc0200b58:	14102973          	csrr	s2,sepc
ffffffffc0200b5c:	143029f3          	csrr	s3,stval
ffffffffc0200b60:	14202a73          	csrr	s4,scause
ffffffffc0200b64:	e822                	sd	s0,16(sp)
ffffffffc0200b66:	e226                	sd	s1,256(sp)
ffffffffc0200b68:	e64a                	sd	s2,264(sp)
ffffffffc0200b6a:	ea4e                	sd	s3,272(sp)
ffffffffc0200b6c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b6e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b70:	f91ff0ef          	jal	ffffffffc0200b00 <trap>

ffffffffc0200b74 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b74:	6492                	ld	s1,256(sp)
ffffffffc0200b76:	6932                	ld	s2,264(sp)
ffffffffc0200b78:	10049073          	csrw	sstatus,s1
ffffffffc0200b7c:	14191073          	csrw	sepc,s2
ffffffffc0200b80:	60a2                	ld	ra,8(sp)
ffffffffc0200b82:	61e2                	ld	gp,24(sp)
ffffffffc0200b84:	7202                	ld	tp,32(sp)
ffffffffc0200b86:	72a2                	ld	t0,40(sp)
ffffffffc0200b88:	7342                	ld	t1,48(sp)
ffffffffc0200b8a:	73e2                	ld	t2,56(sp)
ffffffffc0200b8c:	6406                	ld	s0,64(sp)
ffffffffc0200b8e:	64a6                	ld	s1,72(sp)
ffffffffc0200b90:	6546                	ld	a0,80(sp)
ffffffffc0200b92:	65e6                	ld	a1,88(sp)
ffffffffc0200b94:	7606                	ld	a2,96(sp)
ffffffffc0200b96:	76a6                	ld	a3,104(sp)
ffffffffc0200b98:	7746                	ld	a4,112(sp)
ffffffffc0200b9a:	77e6                	ld	a5,120(sp)
ffffffffc0200b9c:	680a                	ld	a6,128(sp)
ffffffffc0200b9e:	68aa                	ld	a7,136(sp)
ffffffffc0200ba0:	694a                	ld	s2,144(sp)
ffffffffc0200ba2:	69ea                	ld	s3,152(sp)
ffffffffc0200ba4:	7a0a                	ld	s4,160(sp)
ffffffffc0200ba6:	7aaa                	ld	s5,168(sp)
ffffffffc0200ba8:	7b4a                	ld	s6,176(sp)
ffffffffc0200baa:	7bea                	ld	s7,184(sp)
ffffffffc0200bac:	6c0e                	ld	s8,192(sp)
ffffffffc0200bae:	6cae                	ld	s9,200(sp)
ffffffffc0200bb0:	6d4e                	ld	s10,208(sp)
ffffffffc0200bb2:	6dee                	ld	s11,216(sp)
ffffffffc0200bb4:	7e0e                	ld	t3,224(sp)
ffffffffc0200bb6:	7eae                	ld	t4,232(sp)
ffffffffc0200bb8:	7f4e                	ld	t5,240(sp)
ffffffffc0200bba:	7fee                	ld	t6,248(sp)
ffffffffc0200bbc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200bbe:	10200073          	sret

ffffffffc0200bc2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200bc2:	00005797          	auipc	a5,0x5
ffffffffc0200bc6:	46678793          	addi	a5,a5,1126 # ffffffffc0206028 <free_area>
ffffffffc0200bca:	e79c                	sd	a5,8(a5)
ffffffffc0200bcc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200bce:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200bd2:	8082                	ret

ffffffffc0200bd4 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	46456503          	lwu	a0,1124(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200bdc:	8082                	ret

ffffffffc0200bde <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200bde:	711d                	addi	sp,sp,-96
ffffffffc0200be0:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200be2:	00005917          	auipc	s2,0x5
ffffffffc0200be6:	44690913          	addi	s2,s2,1094 # ffffffffc0206028 <free_area>
ffffffffc0200bea:	00893783          	ld	a5,8(s2)
ffffffffc0200bee:	ec86                	sd	ra,88(sp)
ffffffffc0200bf0:	e8a2                	sd	s0,80(sp)
ffffffffc0200bf2:	e4a6                	sd	s1,72(sp)
ffffffffc0200bf4:	fc4e                	sd	s3,56(sp)
ffffffffc0200bf6:	f852                	sd	s4,48(sp)
ffffffffc0200bf8:	f456                	sd	s5,40(sp)
ffffffffc0200bfa:	f05a                	sd	s6,32(sp)
ffffffffc0200bfc:	ec5e                	sd	s7,24(sp)
ffffffffc0200bfe:	e862                	sd	s8,16(sp)
ffffffffc0200c00:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c02:	31278b63          	beq	a5,s2,ffffffffc0200f18 <default_check+0x33a>
    int count = 0, total = 0;
ffffffffc0200c06:	4401                	li	s0,0
ffffffffc0200c08:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c0a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c0e:	8b09                	andi	a4,a4,2
ffffffffc0200c10:	30070863          	beqz	a4,ffffffffc0200f20 <default_check+0x342>
        count ++, total += p->property;
ffffffffc0200c14:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c18:	679c                	ld	a5,8(a5)
ffffffffc0200c1a:	2485                	addiw	s1,s1,1
ffffffffc0200c1c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c1e:	ff2796e3          	bne	a5,s2,ffffffffc0200c0a <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200c22:	89a2                	mv	s3,s0
ffffffffc0200c24:	33f000ef          	jal	ffffffffc0201762 <nr_free_pages>
ffffffffc0200c28:	75351c63          	bne	a0,s3,ffffffffc0201380 <default_check+0x7a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c2c:	4505                	li	a0,1
ffffffffc0200c2e:	2c3000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200c32:	8aaa                	mv	s5,a0
ffffffffc0200c34:	48050663          	beqz	a0,ffffffffc02010c0 <default_check+0x4e2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c38:	4505                	li	a0,1
ffffffffc0200c3a:	2b7000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200c3e:	89aa                	mv	s3,a0
ffffffffc0200c40:	76050063          	beqz	a0,ffffffffc02013a0 <default_check+0x7c2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c44:	4505                	li	a0,1
ffffffffc0200c46:	2ab000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200c4a:	8a2a                	mv	s4,a0
ffffffffc0200c4c:	4e050a63          	beqz	a0,ffffffffc0201140 <default_check+0x562>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c50:	40aa87b3          	sub	a5,s5,a0
ffffffffc0200c54:	40a98733          	sub	a4,s3,a0
ffffffffc0200c58:	0017b793          	seqz	a5,a5
ffffffffc0200c5c:	00173713          	seqz	a4,a4
ffffffffc0200c60:	8fd9                	or	a5,a5,a4
ffffffffc0200c62:	32079f63          	bnez	a5,ffffffffc0200fa0 <default_check+0x3c2>
ffffffffc0200c66:	333a8d63          	beq	s5,s3,ffffffffc0200fa0 <default_check+0x3c2>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c6a:	000aa783          	lw	a5,0(s5)
ffffffffc0200c6e:	2c079963          	bnez	a5,ffffffffc0200f40 <default_check+0x362>
ffffffffc0200c72:	0009a783          	lw	a5,0(s3)
ffffffffc0200c76:	2c079563          	bnez	a5,ffffffffc0200f40 <default_check+0x362>
ffffffffc0200c7a:	411c                	lw	a5,0(a0)
ffffffffc0200c7c:	2c079263          	bnez	a5,ffffffffc0200f40 <default_check+0x362>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c80:	00006797          	auipc	a5,0x6
ffffffffc0200c84:	8107b783          	ld	a5,-2032(a5) # ffffffffc0206490 <pages>
ffffffffc0200c88:	ccccd737          	lui	a4,0xccccd
ffffffffc0200c8c:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac682d>
ffffffffc0200c90:	02071693          	slli	a3,a4,0x20
ffffffffc0200c94:	96ba                	add	a3,a3,a4
ffffffffc0200c96:	40fa8733          	sub	a4,s5,a5
ffffffffc0200c9a:	870d                	srai	a4,a4,0x3
ffffffffc0200c9c:	02d70733          	mul	a4,a4,a3
ffffffffc0200ca0:	00002517          	auipc	a0,0x2
ffffffffc0200ca4:	33853503          	ld	a0,824(a0) # ffffffffc0202fd8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ca8:	00005697          	auipc	a3,0x5
ffffffffc0200cac:	7e06b683          	ld	a3,2016(a3) # ffffffffc0206488 <npage>
ffffffffc0200cb0:	06b2                	slli	a3,a3,0xc
ffffffffc0200cb2:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cb4:	0732                	slli	a4,a4,0xc
ffffffffc0200cb6:	2cd77563          	bgeu	a4,a3,ffffffffc0200f80 <default_check+0x3a2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cba:	ccccd5b7          	lui	a1,0xccccd
ffffffffc0200cbe:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac682d>
ffffffffc0200cc2:	02059613          	slli	a2,a1,0x20
ffffffffc0200cc6:	40f98733          	sub	a4,s3,a5
ffffffffc0200cca:	962e                	add	a2,a2,a1
ffffffffc0200ccc:	870d                	srai	a4,a4,0x3
ffffffffc0200cce:	02c70733          	mul	a4,a4,a2
ffffffffc0200cd2:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cd4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cd6:	4ed77563          	bgeu	a4,a3,ffffffffc02011c0 <default_check+0x5e2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cda:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200cde:	878d                	srai	a5,a5,0x3
ffffffffc0200ce0:	02c787b3          	mul	a5,a5,a2
ffffffffc0200ce4:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ce6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ce8:	32d7fc63          	bgeu	a5,a3,ffffffffc0201020 <default_check+0x442>
    assert(alloc_page() == NULL);
ffffffffc0200cec:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200cee:	00093c03          	ld	s8,0(s2)
ffffffffc0200cf2:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200cf6:	00005b17          	auipc	s6,0x5
ffffffffc0200cfa:	342b2b03          	lw	s6,834(s6) # ffffffffc0206038 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200cfe:	01293023          	sd	s2,0(s2)
ffffffffc0200d02:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200d06:	00005797          	auipc	a5,0x5
ffffffffc0200d0a:	3207a923          	sw	zero,818(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d0e:	1e3000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d12:	2e051763          	bnez	a0,ffffffffc0201000 <default_check+0x422>
    free_page(p0);
ffffffffc0200d16:	8556                	mv	a0,s5
ffffffffc0200d18:	4585                	li	a1,1
ffffffffc0200d1a:	211000ef          	jal	ffffffffc020172a <free_pages>
    free_page(p1);
ffffffffc0200d1e:	854e                	mv	a0,s3
ffffffffc0200d20:	4585                	li	a1,1
ffffffffc0200d22:	209000ef          	jal	ffffffffc020172a <free_pages>
    free_page(p2);
ffffffffc0200d26:	8552                	mv	a0,s4
ffffffffc0200d28:	4585                	li	a1,1
ffffffffc0200d2a:	201000ef          	jal	ffffffffc020172a <free_pages>
    assert(nr_free == 3);
ffffffffc0200d2e:	00005717          	auipc	a4,0x5
ffffffffc0200d32:	30a72703          	lw	a4,778(a4) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200d36:	478d                	li	a5,3
ffffffffc0200d38:	2af71463          	bne	a4,a5,ffffffffc0200fe0 <default_check+0x402>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d3c:	4505                	li	a0,1
ffffffffc0200d3e:	1b3000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d42:	89aa                	mv	s3,a0
ffffffffc0200d44:	26050e63          	beqz	a0,ffffffffc0200fc0 <default_check+0x3e2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d48:	4505                	li	a0,1
ffffffffc0200d4a:	1a7000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d4e:	8aaa                	mv	s5,a0
ffffffffc0200d50:	3c050863          	beqz	a0,ffffffffc0201120 <default_check+0x542>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d54:	4505                	li	a0,1
ffffffffc0200d56:	19b000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d5a:	8a2a                	mv	s4,a0
ffffffffc0200d5c:	3a050263          	beqz	a0,ffffffffc0201100 <default_check+0x522>
    assert(alloc_page() == NULL);
ffffffffc0200d60:	4505                	li	a0,1
ffffffffc0200d62:	18f000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d66:	36051d63          	bnez	a0,ffffffffc02010e0 <default_check+0x502>
    free_page(p0);
ffffffffc0200d6a:	4585                	li	a1,1
ffffffffc0200d6c:	854e                	mv	a0,s3
ffffffffc0200d6e:	1bd000ef          	jal	ffffffffc020172a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200d72:	00893783          	ld	a5,8(s2)
ffffffffc0200d76:	1f278563          	beq	a5,s2,ffffffffc0200f60 <default_check+0x382>
    assert((p = alloc_page()) == p0);
ffffffffc0200d7a:	4505                	li	a0,1
ffffffffc0200d7c:	175000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d80:	8caa                	mv	s9,a0
ffffffffc0200d82:	30a99f63          	bne	s3,a0,ffffffffc02010a0 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200d86:	4505                	li	a0,1
ffffffffc0200d88:	169000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200d8c:	2e051a63          	bnez	a0,ffffffffc0201080 <default_check+0x4a2>
    assert(nr_free == 0);
ffffffffc0200d90:	00005797          	auipc	a5,0x5
ffffffffc0200d94:	2a87a783          	lw	a5,680(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200d98:	2c079463          	bnez	a5,ffffffffc0201060 <default_check+0x482>
    free_page(p);
ffffffffc0200d9c:	8566                	mv	a0,s9
ffffffffc0200d9e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200da0:	01893023          	sd	s8,0(s2)
ffffffffc0200da4:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200da8:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200dac:	17f000ef          	jal	ffffffffc020172a <free_pages>
    free_page(p1);
ffffffffc0200db0:	8556                	mv	a0,s5
ffffffffc0200db2:	4585                	li	a1,1
ffffffffc0200db4:	177000ef          	jal	ffffffffc020172a <free_pages>
    free_page(p2);
ffffffffc0200db8:	8552                	mv	a0,s4
ffffffffc0200dba:	4585                	li	a1,1
ffffffffc0200dbc:	16f000ef          	jal	ffffffffc020172a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200dc0:	4515                	li	a0,5
ffffffffc0200dc2:	12f000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200dc6:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200dc8:	26050c63          	beqz	a0,ffffffffc0201040 <default_check+0x462>
ffffffffc0200dcc:	651c                	ld	a5,8(a0)
ffffffffc0200dce:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200dd0:	8b85                	andi	a5,a5,1
ffffffffc0200dd2:	54079763          	bnez	a5,ffffffffc0201320 <default_check+0x742>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200dd6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200dd8:	00093b83          	ld	s7,0(s2)
ffffffffc0200ddc:	00893b03          	ld	s6,8(s2)
ffffffffc0200de0:	01293023          	sd	s2,0(s2)
ffffffffc0200de4:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200de8:	109000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200dec:	50051a63          	bnez	a0,ffffffffc0201300 <default_check+0x722>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200df0:	05098a13          	addi	s4,s3,80
ffffffffc0200df4:	8552                	mv	a0,s4
ffffffffc0200df6:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200df8:	00005c17          	auipc	s8,0x5
ffffffffc0200dfc:	240c2c03          	lw	s8,576(s8) # ffffffffc0206038 <free_area+0x10>
    nr_free = 0;
ffffffffc0200e00:	00005797          	auipc	a5,0x5
ffffffffc0200e04:	2207ac23          	sw	zero,568(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e08:	123000ef          	jal	ffffffffc020172a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e0c:	4511                	li	a0,4
ffffffffc0200e0e:	0e3000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200e12:	4c051763          	bnez	a0,ffffffffc02012e0 <default_check+0x702>
ffffffffc0200e16:	0589b783          	ld	a5,88(s3)
ffffffffc0200e1a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e1c:	8b85                	andi	a5,a5,1
ffffffffc0200e1e:	4a078163          	beqz	a5,ffffffffc02012c0 <default_check+0x6e2>
ffffffffc0200e22:	0609a503          	lw	a0,96(s3)
ffffffffc0200e26:	478d                	li	a5,3
ffffffffc0200e28:	48f51c63          	bne	a0,a5,ffffffffc02012c0 <default_check+0x6e2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e2c:	0c5000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200e30:	8aaa                	mv	s5,a0
ffffffffc0200e32:	46050763          	beqz	a0,ffffffffc02012a0 <default_check+0x6c2>
    assert(alloc_page() == NULL);
ffffffffc0200e36:	4505                	li	a0,1
ffffffffc0200e38:	0b9000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200e3c:	44051263          	bnez	a0,ffffffffc0201280 <default_check+0x6a2>
    assert(p0 + 2 == p1);
ffffffffc0200e40:	435a1063          	bne	s4,s5,ffffffffc0201260 <default_check+0x682>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e44:	4585                	li	a1,1
ffffffffc0200e46:	854e                	mv	a0,s3
ffffffffc0200e48:	0e3000ef          	jal	ffffffffc020172a <free_pages>
    free_pages(p1, 3);
ffffffffc0200e4c:	8552                	mv	a0,s4
ffffffffc0200e4e:	458d                	li	a1,3
ffffffffc0200e50:	0db000ef          	jal	ffffffffc020172a <free_pages>
ffffffffc0200e54:	0089b783          	ld	a5,8(s3)
ffffffffc0200e58:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200e5a:	8b85                	andi	a5,a5,1
ffffffffc0200e5c:	3e078263          	beqz	a5,ffffffffc0201240 <default_check+0x662>
ffffffffc0200e60:	0109aa83          	lw	s5,16(s3)
ffffffffc0200e64:	4785                	li	a5,1
ffffffffc0200e66:	3cfa9d63          	bne	s5,a5,ffffffffc0201240 <default_check+0x662>
ffffffffc0200e6a:	008a3783          	ld	a5,8(s4)
ffffffffc0200e6e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e70:	8b85                	andi	a5,a5,1
ffffffffc0200e72:	3a078763          	beqz	a5,ffffffffc0201220 <default_check+0x642>
ffffffffc0200e76:	010a2703          	lw	a4,16(s4)
ffffffffc0200e7a:	478d                	li	a5,3
ffffffffc0200e7c:	3af71263          	bne	a4,a5,ffffffffc0201220 <default_check+0x642>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200e80:	8556                	mv	a0,s5
ffffffffc0200e82:	06f000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200e86:	36a99d63          	bne	s3,a0,ffffffffc0201200 <default_check+0x622>
    free_page(p0);
ffffffffc0200e8a:	85d6                	mv	a1,s5
ffffffffc0200e8c:	09f000ef          	jal	ffffffffc020172a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200e90:	4509                	li	a0,2
ffffffffc0200e92:	05f000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200e96:	34aa1563          	bne	s4,a0,ffffffffc02011e0 <default_check+0x602>

    free_pages(p0, 2);
ffffffffc0200e9a:	4589                	li	a1,2
ffffffffc0200e9c:	08f000ef          	jal	ffffffffc020172a <free_pages>
    free_page(p2);
ffffffffc0200ea0:	02898513          	addi	a0,s3,40
ffffffffc0200ea4:	85d6                	mv	a1,s5
ffffffffc0200ea6:	085000ef          	jal	ffffffffc020172a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200eaa:	4515                	li	a0,5
ffffffffc0200eac:	045000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200eb0:	89aa                	mv	s3,a0
ffffffffc0200eb2:	48050763          	beqz	a0,ffffffffc0201340 <default_check+0x762>
    assert(alloc_page() == NULL);
ffffffffc0200eb6:	8556                	mv	a0,s5
ffffffffc0200eb8:	039000ef          	jal	ffffffffc02016f0 <alloc_pages>
ffffffffc0200ebc:	2e051263          	bnez	a0,ffffffffc02011a0 <default_check+0x5c2>

    assert(nr_free == 0);
ffffffffc0200ec0:	00005797          	auipc	a5,0x5
ffffffffc0200ec4:	1787a783          	lw	a5,376(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200ec8:	2a079c63          	bnez	a5,ffffffffc0201180 <default_check+0x5a2>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ecc:	854e                	mv	a0,s3
ffffffffc0200ece:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200ed0:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200ed4:	01793023          	sd	s7,0(s2)
ffffffffc0200ed8:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200edc:	04f000ef          	jal	ffffffffc020172a <free_pages>
    return listelm->next;
ffffffffc0200ee0:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ee4:	01278963          	beq	a5,s2,ffffffffc0200ef6 <default_check+0x318>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200ee8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eec:	679c                	ld	a5,8(a5)
ffffffffc0200eee:	34fd                	addiw	s1,s1,-1
ffffffffc0200ef0:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ef2:	ff279be3          	bne	a5,s2,ffffffffc0200ee8 <default_check+0x30a>
    }
    assert(count == 0);
ffffffffc0200ef6:	26049563          	bnez	s1,ffffffffc0201160 <default_check+0x582>
    assert(total == 0);
ffffffffc0200efa:	46041363          	bnez	s0,ffffffffc0201360 <default_check+0x782>
}
ffffffffc0200efe:	60e6                	ld	ra,88(sp)
ffffffffc0200f00:	6446                	ld	s0,80(sp)
ffffffffc0200f02:	64a6                	ld	s1,72(sp)
ffffffffc0200f04:	6906                	ld	s2,64(sp)
ffffffffc0200f06:	79e2                	ld	s3,56(sp)
ffffffffc0200f08:	7a42                	ld	s4,48(sp)
ffffffffc0200f0a:	7aa2                	ld	s5,40(sp)
ffffffffc0200f0c:	7b02                	ld	s6,32(sp)
ffffffffc0200f0e:	6be2                	ld	s7,24(sp)
ffffffffc0200f10:	6c42                	ld	s8,16(sp)
ffffffffc0200f12:	6ca2                	ld	s9,8(sp)
ffffffffc0200f14:	6125                	addi	sp,sp,96
ffffffffc0200f16:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f18:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f1a:	4401                	li	s0,0
ffffffffc0200f1c:	4481                	li	s1,0
ffffffffc0200f1e:	b319                	j	ffffffffc0200c24 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0200f20:	00002697          	auipc	a3,0x2
ffffffffc0200f24:	8b868693          	addi	a3,a3,-1864 # ffffffffc02027d8 <etext+0x8c4>
ffffffffc0200f28:	00002617          	auipc	a2,0x2
ffffffffc0200f2c:	8c060613          	addi	a2,a2,-1856 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200f30:	0f000593          	li	a1,240
ffffffffc0200f34:	00002517          	auipc	a0,0x2
ffffffffc0200f38:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200f3c:	c4cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f40:	00002697          	auipc	a3,0x2
ffffffffc0200f44:	98068693          	addi	a3,a3,-1664 # ffffffffc02028c0 <etext+0x9ac>
ffffffffc0200f48:	00002617          	auipc	a2,0x2
ffffffffc0200f4c:	8a060613          	addi	a2,a2,-1888 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200f50:	0be00593          	li	a1,190
ffffffffc0200f54:	00002517          	auipc	a0,0x2
ffffffffc0200f58:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200f5c:	c2cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f60:	00002697          	auipc	a3,0x2
ffffffffc0200f64:	a2868693          	addi	a3,a3,-1496 # ffffffffc0202988 <etext+0xa74>
ffffffffc0200f68:	00002617          	auipc	a2,0x2
ffffffffc0200f6c:	88060613          	addi	a2,a2,-1920 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200f70:	0d900593          	li	a1,217
ffffffffc0200f74:	00002517          	auipc	a0,0x2
ffffffffc0200f78:	88c50513          	addi	a0,a0,-1908 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200f7c:	c0cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f80:	00002697          	auipc	a3,0x2
ffffffffc0200f84:	98068693          	addi	a3,a3,-1664 # ffffffffc0202900 <etext+0x9ec>
ffffffffc0200f88:	00002617          	auipc	a2,0x2
ffffffffc0200f8c:	86060613          	addi	a2,a2,-1952 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200f90:	0c000593          	li	a1,192
ffffffffc0200f94:	00002517          	auipc	a0,0x2
ffffffffc0200f98:	86c50513          	addi	a0,a0,-1940 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200f9c:	becff0ef          	jal	ffffffffc0200388 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fa0:	00002697          	auipc	a3,0x2
ffffffffc0200fa4:	8f868693          	addi	a3,a3,-1800 # ffffffffc0202898 <etext+0x984>
ffffffffc0200fa8:	00002617          	auipc	a2,0x2
ffffffffc0200fac:	84060613          	addi	a2,a2,-1984 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200fb0:	0bd00593          	li	a1,189
ffffffffc0200fb4:	00002517          	auipc	a0,0x2
ffffffffc0200fb8:	84c50513          	addi	a0,a0,-1972 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200fbc:	bccff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fc0:	00002697          	auipc	a3,0x2
ffffffffc0200fc4:	87868693          	addi	a3,a3,-1928 # ffffffffc0202838 <etext+0x924>
ffffffffc0200fc8:	00002617          	auipc	a2,0x2
ffffffffc0200fcc:	82060613          	addi	a2,a2,-2016 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200fd0:	0d200593          	li	a1,210
ffffffffc0200fd4:	00002517          	auipc	a0,0x2
ffffffffc0200fd8:	82c50513          	addi	a0,a0,-2004 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200fdc:	bacff0ef          	jal	ffffffffc0200388 <__panic>
    assert(nr_free == 3);
ffffffffc0200fe0:	00002697          	auipc	a3,0x2
ffffffffc0200fe4:	99868693          	addi	a3,a3,-1640 # ffffffffc0202978 <etext+0xa64>
ffffffffc0200fe8:	00002617          	auipc	a2,0x2
ffffffffc0200fec:	80060613          	addi	a2,a2,-2048 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0200ff0:	0d000593          	li	a1,208
ffffffffc0200ff4:	00002517          	auipc	a0,0x2
ffffffffc0200ff8:	80c50513          	addi	a0,a0,-2036 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0200ffc:	b8cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201000:	00002697          	auipc	a3,0x2
ffffffffc0201004:	96068693          	addi	a3,a3,-1696 # ffffffffc0202960 <etext+0xa4c>
ffffffffc0201008:	00001617          	auipc	a2,0x1
ffffffffc020100c:	7e060613          	addi	a2,a2,2016 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201010:	0cb00593          	li	a1,203
ffffffffc0201014:	00001517          	auipc	a0,0x1
ffffffffc0201018:	7ec50513          	addi	a0,a0,2028 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020101c:	b6cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201020:	00002697          	auipc	a3,0x2
ffffffffc0201024:	92068693          	addi	a3,a3,-1760 # ffffffffc0202940 <etext+0xa2c>
ffffffffc0201028:	00001617          	auipc	a2,0x1
ffffffffc020102c:	7c060613          	addi	a2,a2,1984 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201030:	0c200593          	li	a1,194
ffffffffc0201034:	00001517          	auipc	a0,0x1
ffffffffc0201038:	7cc50513          	addi	a0,a0,1996 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020103c:	b4cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(p0 != NULL);
ffffffffc0201040:	00002697          	auipc	a3,0x2
ffffffffc0201044:	99068693          	addi	a3,a3,-1648 # ffffffffc02029d0 <etext+0xabc>
ffffffffc0201048:	00001617          	auipc	a2,0x1
ffffffffc020104c:	7a060613          	addi	a2,a2,1952 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201050:	0f800593          	li	a1,248
ffffffffc0201054:	00001517          	auipc	a0,0x1
ffffffffc0201058:	7ac50513          	addi	a0,a0,1964 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020105c:	b2cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(nr_free == 0);
ffffffffc0201060:	00002697          	auipc	a3,0x2
ffffffffc0201064:	96068693          	addi	a3,a3,-1696 # ffffffffc02029c0 <etext+0xaac>
ffffffffc0201068:	00001617          	auipc	a2,0x1
ffffffffc020106c:	78060613          	addi	a2,a2,1920 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201070:	0df00593          	li	a1,223
ffffffffc0201074:	00001517          	auipc	a0,0x1
ffffffffc0201078:	78c50513          	addi	a0,a0,1932 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020107c:	b0cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201080:	00002697          	auipc	a3,0x2
ffffffffc0201084:	8e068693          	addi	a3,a3,-1824 # ffffffffc0202960 <etext+0xa4c>
ffffffffc0201088:	00001617          	auipc	a2,0x1
ffffffffc020108c:	76060613          	addi	a2,a2,1888 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201090:	0dd00593          	li	a1,221
ffffffffc0201094:	00001517          	auipc	a0,0x1
ffffffffc0201098:	76c50513          	addi	a0,a0,1900 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020109c:	aecff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010a0:	00002697          	auipc	a3,0x2
ffffffffc02010a4:	90068693          	addi	a3,a3,-1792 # ffffffffc02029a0 <etext+0xa8c>
ffffffffc02010a8:	00001617          	auipc	a2,0x1
ffffffffc02010ac:	74060613          	addi	a2,a2,1856 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02010b0:	0dc00593          	li	a1,220
ffffffffc02010b4:	00001517          	auipc	a0,0x1
ffffffffc02010b8:	74c50513          	addi	a0,a0,1868 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02010bc:	accff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010c0:	00001697          	auipc	a3,0x1
ffffffffc02010c4:	77868693          	addi	a3,a3,1912 # ffffffffc0202838 <etext+0x924>
ffffffffc02010c8:	00001617          	auipc	a2,0x1
ffffffffc02010cc:	72060613          	addi	a2,a2,1824 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02010d0:	0b900593          	li	a1,185
ffffffffc02010d4:	00001517          	auipc	a0,0x1
ffffffffc02010d8:	72c50513          	addi	a0,a0,1836 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02010dc:	aacff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010e0:	00002697          	auipc	a3,0x2
ffffffffc02010e4:	88068693          	addi	a3,a3,-1920 # ffffffffc0202960 <etext+0xa4c>
ffffffffc02010e8:	00001617          	auipc	a2,0x1
ffffffffc02010ec:	70060613          	addi	a2,a2,1792 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02010f0:	0d600593          	li	a1,214
ffffffffc02010f4:	00001517          	auipc	a0,0x1
ffffffffc02010f8:	70c50513          	addi	a0,a0,1804 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02010fc:	a8cff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201100:	00001697          	auipc	a3,0x1
ffffffffc0201104:	77868693          	addi	a3,a3,1912 # ffffffffc0202878 <etext+0x964>
ffffffffc0201108:	00001617          	auipc	a2,0x1
ffffffffc020110c:	6e060613          	addi	a2,a2,1760 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201110:	0d400593          	li	a1,212
ffffffffc0201114:	00001517          	auipc	a0,0x1
ffffffffc0201118:	6ec50513          	addi	a0,a0,1772 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020111c:	a6cff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201120:	00001697          	auipc	a3,0x1
ffffffffc0201124:	73868693          	addi	a3,a3,1848 # ffffffffc0202858 <etext+0x944>
ffffffffc0201128:	00001617          	auipc	a2,0x1
ffffffffc020112c:	6c060613          	addi	a2,a2,1728 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201130:	0d300593          	li	a1,211
ffffffffc0201134:	00001517          	auipc	a0,0x1
ffffffffc0201138:	6cc50513          	addi	a0,a0,1740 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020113c:	a4cff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201140:	00001697          	auipc	a3,0x1
ffffffffc0201144:	73868693          	addi	a3,a3,1848 # ffffffffc0202878 <etext+0x964>
ffffffffc0201148:	00001617          	auipc	a2,0x1
ffffffffc020114c:	6a060613          	addi	a2,a2,1696 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201150:	0bb00593          	li	a1,187
ffffffffc0201154:	00001517          	auipc	a0,0x1
ffffffffc0201158:	6ac50513          	addi	a0,a0,1708 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020115c:	a2cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(count == 0);
ffffffffc0201160:	00002697          	auipc	a3,0x2
ffffffffc0201164:	9c068693          	addi	a3,a3,-1600 # ffffffffc0202b20 <etext+0xc0c>
ffffffffc0201168:	00001617          	auipc	a2,0x1
ffffffffc020116c:	68060613          	addi	a2,a2,1664 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201170:	12500593          	li	a1,293
ffffffffc0201174:	00001517          	auipc	a0,0x1
ffffffffc0201178:	68c50513          	addi	a0,a0,1676 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020117c:	a0cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(nr_free == 0);
ffffffffc0201180:	00002697          	auipc	a3,0x2
ffffffffc0201184:	84068693          	addi	a3,a3,-1984 # ffffffffc02029c0 <etext+0xaac>
ffffffffc0201188:	00001617          	auipc	a2,0x1
ffffffffc020118c:	66060613          	addi	a2,a2,1632 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201190:	11a00593          	li	a1,282
ffffffffc0201194:	00001517          	auipc	a0,0x1
ffffffffc0201198:	66c50513          	addi	a0,a0,1644 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020119c:	9ecff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011a0:	00001697          	auipc	a3,0x1
ffffffffc02011a4:	7c068693          	addi	a3,a3,1984 # ffffffffc0202960 <etext+0xa4c>
ffffffffc02011a8:	00001617          	auipc	a2,0x1
ffffffffc02011ac:	64060613          	addi	a2,a2,1600 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02011b0:	11800593          	li	a1,280
ffffffffc02011b4:	00001517          	auipc	a0,0x1
ffffffffc02011b8:	64c50513          	addi	a0,a0,1612 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02011bc:	9ccff0ef          	jal	ffffffffc0200388 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02011c0:	00001697          	auipc	a3,0x1
ffffffffc02011c4:	76068693          	addi	a3,a3,1888 # ffffffffc0202920 <etext+0xa0c>
ffffffffc02011c8:	00001617          	auipc	a2,0x1
ffffffffc02011cc:	62060613          	addi	a2,a2,1568 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02011d0:	0c100593          	li	a1,193
ffffffffc02011d4:	00001517          	auipc	a0,0x1
ffffffffc02011d8:	62c50513          	addi	a0,a0,1580 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02011dc:	9acff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011e0:	00002697          	auipc	a3,0x2
ffffffffc02011e4:	90068693          	addi	a3,a3,-1792 # ffffffffc0202ae0 <etext+0xbcc>
ffffffffc02011e8:	00001617          	auipc	a2,0x1
ffffffffc02011ec:	60060613          	addi	a2,a2,1536 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02011f0:	11200593          	li	a1,274
ffffffffc02011f4:	00001517          	auipc	a0,0x1
ffffffffc02011f8:	60c50513          	addi	a0,a0,1548 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02011fc:	98cff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201200:	00002697          	auipc	a3,0x2
ffffffffc0201204:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202ac0 <etext+0xbac>
ffffffffc0201208:	00001617          	auipc	a2,0x1
ffffffffc020120c:	5e060613          	addi	a2,a2,1504 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201210:	11000593          	li	a1,272
ffffffffc0201214:	00001517          	auipc	a0,0x1
ffffffffc0201218:	5ec50513          	addi	a0,a0,1516 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020121c:	96cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201220:	00002697          	auipc	a3,0x2
ffffffffc0201224:	87868693          	addi	a3,a3,-1928 # ffffffffc0202a98 <etext+0xb84>
ffffffffc0201228:	00001617          	auipc	a2,0x1
ffffffffc020122c:	5c060613          	addi	a2,a2,1472 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201230:	10e00593          	li	a1,270
ffffffffc0201234:	00001517          	auipc	a0,0x1
ffffffffc0201238:	5cc50513          	addi	a0,a0,1484 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020123c:	94cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201240:	00002697          	auipc	a3,0x2
ffffffffc0201244:	83068693          	addi	a3,a3,-2000 # ffffffffc0202a70 <etext+0xb5c>
ffffffffc0201248:	00001617          	auipc	a2,0x1
ffffffffc020124c:	5a060613          	addi	a2,a2,1440 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201250:	10d00593          	li	a1,269
ffffffffc0201254:	00001517          	auipc	a0,0x1
ffffffffc0201258:	5ac50513          	addi	a0,a0,1452 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020125c:	92cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201260:	00002697          	auipc	a3,0x2
ffffffffc0201264:	80068693          	addi	a3,a3,-2048 # ffffffffc0202a60 <etext+0xb4c>
ffffffffc0201268:	00001617          	auipc	a2,0x1
ffffffffc020126c:	58060613          	addi	a2,a2,1408 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201270:	10800593          	li	a1,264
ffffffffc0201274:	00001517          	auipc	a0,0x1
ffffffffc0201278:	58c50513          	addi	a0,a0,1420 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020127c:	90cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201280:	00001697          	auipc	a3,0x1
ffffffffc0201284:	6e068693          	addi	a3,a3,1760 # ffffffffc0202960 <etext+0xa4c>
ffffffffc0201288:	00001617          	auipc	a2,0x1
ffffffffc020128c:	56060613          	addi	a2,a2,1376 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201290:	10700593          	li	a1,263
ffffffffc0201294:	00001517          	auipc	a0,0x1
ffffffffc0201298:	56c50513          	addi	a0,a0,1388 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020129c:	8ecff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02012a0:	00001697          	auipc	a3,0x1
ffffffffc02012a4:	7a068693          	addi	a3,a3,1952 # ffffffffc0202a40 <etext+0xb2c>
ffffffffc02012a8:	00001617          	auipc	a2,0x1
ffffffffc02012ac:	54060613          	addi	a2,a2,1344 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02012b0:	10600593          	li	a1,262
ffffffffc02012b4:	00001517          	auipc	a0,0x1
ffffffffc02012b8:	54c50513          	addi	a0,a0,1356 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02012bc:	8ccff0ef          	jal	ffffffffc0200388 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02012c0:	00001697          	auipc	a3,0x1
ffffffffc02012c4:	75068693          	addi	a3,a3,1872 # ffffffffc0202a10 <etext+0xafc>
ffffffffc02012c8:	00001617          	auipc	a2,0x1
ffffffffc02012cc:	52060613          	addi	a2,a2,1312 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02012d0:	10500593          	li	a1,261
ffffffffc02012d4:	00001517          	auipc	a0,0x1
ffffffffc02012d8:	52c50513          	addi	a0,a0,1324 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02012dc:	8acff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02012e0:	00001697          	auipc	a3,0x1
ffffffffc02012e4:	71868693          	addi	a3,a3,1816 # ffffffffc02029f8 <etext+0xae4>
ffffffffc02012e8:	00001617          	auipc	a2,0x1
ffffffffc02012ec:	50060613          	addi	a2,a2,1280 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02012f0:	10400593          	li	a1,260
ffffffffc02012f4:	00001517          	auipc	a0,0x1
ffffffffc02012f8:	50c50513          	addi	a0,a0,1292 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02012fc:	88cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201300:	00001697          	auipc	a3,0x1
ffffffffc0201304:	66068693          	addi	a3,a3,1632 # ffffffffc0202960 <etext+0xa4c>
ffffffffc0201308:	00001617          	auipc	a2,0x1
ffffffffc020130c:	4e060613          	addi	a2,a2,1248 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201310:	0fe00593          	li	a1,254
ffffffffc0201314:	00001517          	auipc	a0,0x1
ffffffffc0201318:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020131c:	86cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201320:	00001697          	auipc	a3,0x1
ffffffffc0201324:	6c068693          	addi	a3,a3,1728 # ffffffffc02029e0 <etext+0xacc>
ffffffffc0201328:	00001617          	auipc	a2,0x1
ffffffffc020132c:	4c060613          	addi	a2,a2,1216 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201330:	0f900593          	li	a1,249
ffffffffc0201334:	00001517          	auipc	a0,0x1
ffffffffc0201338:	4cc50513          	addi	a0,a0,1228 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020133c:	84cff0ef          	jal	ffffffffc0200388 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201340:	00001697          	auipc	a3,0x1
ffffffffc0201344:	7c068693          	addi	a3,a3,1984 # ffffffffc0202b00 <etext+0xbec>
ffffffffc0201348:	00001617          	auipc	a2,0x1
ffffffffc020134c:	4a060613          	addi	a2,a2,1184 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201350:	11700593          	li	a1,279
ffffffffc0201354:	00001517          	auipc	a0,0x1
ffffffffc0201358:	4ac50513          	addi	a0,a0,1196 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020135c:	82cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(total == 0);
ffffffffc0201360:	00001697          	auipc	a3,0x1
ffffffffc0201364:	7d068693          	addi	a3,a3,2000 # ffffffffc0202b30 <etext+0xc1c>
ffffffffc0201368:	00001617          	auipc	a2,0x1
ffffffffc020136c:	48060613          	addi	a2,a2,1152 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201370:	12600593          	li	a1,294
ffffffffc0201374:	00001517          	auipc	a0,0x1
ffffffffc0201378:	48c50513          	addi	a0,a0,1164 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020137c:	80cff0ef          	jal	ffffffffc0200388 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201380:	00001697          	auipc	a3,0x1
ffffffffc0201384:	49868693          	addi	a3,a3,1176 # ffffffffc0202818 <etext+0x904>
ffffffffc0201388:	00001617          	auipc	a2,0x1
ffffffffc020138c:	46060613          	addi	a2,a2,1120 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc0201390:	0f300593          	li	a1,243
ffffffffc0201394:	00001517          	auipc	a0,0x1
ffffffffc0201398:	46c50513          	addi	a0,a0,1132 # ffffffffc0202800 <etext+0x8ec>
ffffffffc020139c:	fedfe0ef          	jal	ffffffffc0200388 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013a0:	00001697          	auipc	a3,0x1
ffffffffc02013a4:	4b868693          	addi	a3,a3,1208 # ffffffffc0202858 <etext+0x944>
ffffffffc02013a8:	00001617          	auipc	a2,0x1
ffffffffc02013ac:	44060613          	addi	a2,a2,1088 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02013b0:	0ba00593          	li	a1,186
ffffffffc02013b4:	00001517          	auipc	a0,0x1
ffffffffc02013b8:	44c50513          	addi	a0,a0,1100 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02013bc:	fcdfe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc02013c0 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02013c0:	1141                	addi	sp,sp,-16
ffffffffc02013c2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013c4:	14058c63          	beqz	a1,ffffffffc020151c <default_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc02013c8:	00259713          	slli	a4,a1,0x2
ffffffffc02013cc:	972e                	add	a4,a4,a1
ffffffffc02013ce:	070e                	slli	a4,a4,0x3
ffffffffc02013d0:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02013d4:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02013d6:	c30d                	beqz	a4,ffffffffc02013f8 <default_free_pages+0x38>
ffffffffc02013d8:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02013da:	8b05                	andi	a4,a4,1
ffffffffc02013dc:	12071063          	bnez	a4,ffffffffc02014fc <default_free_pages+0x13c>
ffffffffc02013e0:	6798                	ld	a4,8(a5)
ffffffffc02013e2:	8b09                	andi	a4,a4,2
ffffffffc02013e4:	10071c63          	bnez	a4,ffffffffc02014fc <default_free_pages+0x13c>
        p->flags = 0;
ffffffffc02013e8:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02013ec:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02013f0:	02878793          	addi	a5,a5,40
ffffffffc02013f4:	fed792e3          	bne	a5,a3,ffffffffc02013d8 <default_free_pages+0x18>
    base->property = n;
ffffffffc02013f8:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02013fa:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02013fe:	4789                	li	a5,2
ffffffffc0201400:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201404:	00005717          	auipc	a4,0x5
ffffffffc0201408:	c3472703          	lw	a4,-972(a4) # ffffffffc0206038 <free_area+0x10>
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	c1c68693          	addi	a3,a3,-996 # ffffffffc0206028 <free_area>
    return list->next == list;
ffffffffc0201414:	669c                	ld	a5,8(a3)
ffffffffc0201416:	9f2d                	addw	a4,a4,a1
ffffffffc0201418:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020141a:	0ad78563          	beq	a5,a3,ffffffffc02014c4 <default_free_pages+0x104>
            struct Page* page = le2page(le, page_link);
ffffffffc020141e:	fe878713          	addi	a4,a5,-24
ffffffffc0201422:	4581                	li	a1,0
ffffffffc0201424:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201428:	00e56a63          	bltu	a0,a4,ffffffffc020143c <default_free_pages+0x7c>
    return listelm->next;
ffffffffc020142c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020142e:	06d70263          	beq	a4,a3,ffffffffc0201492 <default_free_pages+0xd2>
    struct Page *p = base;
ffffffffc0201432:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201434:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201438:	fee57ae3          	bgeu	a0,a4,ffffffffc020142c <default_free_pages+0x6c>
ffffffffc020143c:	c199                	beqz	a1,ffffffffc0201442 <default_free_pages+0x82>
ffffffffc020143e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201442:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201444:	e390                	sd	a2,0(a5)
ffffffffc0201446:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201448:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020144a:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc020144c:	02d70063          	beq	a4,a3,ffffffffc020146c <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201450:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201454:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201458:	02081613          	slli	a2,a6,0x20
ffffffffc020145c:	9201                	srli	a2,a2,0x20
ffffffffc020145e:	00261793          	slli	a5,a2,0x2
ffffffffc0201462:	97b2                	add	a5,a5,a2
ffffffffc0201464:	078e                	slli	a5,a5,0x3
ffffffffc0201466:	97ae                	add	a5,a5,a1
ffffffffc0201468:	02f50f63          	beq	a0,a5,ffffffffc02014a6 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc020146c:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020146e:	00d70f63          	beq	a4,a3,ffffffffc020148c <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201472:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201474:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201478:	02059613          	slli	a2,a1,0x20
ffffffffc020147c:	9201                	srli	a2,a2,0x20
ffffffffc020147e:	00261793          	slli	a5,a2,0x2
ffffffffc0201482:	97b2                	add	a5,a5,a2
ffffffffc0201484:	078e                	slli	a5,a5,0x3
ffffffffc0201486:	97aa                	add	a5,a5,a0
ffffffffc0201488:	04f68a63          	beq	a3,a5,ffffffffc02014dc <default_free_pages+0x11c>
}
ffffffffc020148c:	60a2                	ld	ra,8(sp)
ffffffffc020148e:	0141                	addi	sp,sp,16
ffffffffc0201490:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201492:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201494:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201496:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201498:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020149a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020149c:	02d70d63          	beq	a4,a3,ffffffffc02014d6 <default_free_pages+0x116>
ffffffffc02014a0:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02014a2:	87ba                	mv	a5,a4
ffffffffc02014a4:	bf41                	j	ffffffffc0201434 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02014a6:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014a8:	5675                	li	a2,-3
ffffffffc02014aa:	010787bb          	addw	a5,a5,a6
ffffffffc02014ae:	fef72c23          	sw	a5,-8(a4)
ffffffffc02014b2:	60c8b02f          	amoand.d	zero,a2,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014b6:	6d10                	ld	a2,24(a0)
ffffffffc02014b8:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014ba:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02014bc:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02014be:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02014c0:	e390                	sd	a2,0(a5)
ffffffffc02014c2:	b775                	j	ffffffffc020146e <default_free_pages+0xae>
}
ffffffffc02014c4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02014c6:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02014ca:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014cc:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02014ce:	e398                	sd	a4,0(a5)
ffffffffc02014d0:	e798                	sd	a4,8(a5)
}
ffffffffc02014d2:	0141                	addi	sp,sp,16
ffffffffc02014d4:	8082                	ret
ffffffffc02014d6:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02014d8:	873e                	mv	a4,a5
ffffffffc02014da:	bf8d                	j	ffffffffc020144c <default_free_pages+0x8c>
            base->property += p->property;
ffffffffc02014dc:	ff872783          	lw	a5,-8(a4)
ffffffffc02014e0:	56f5                	li	a3,-3
ffffffffc02014e2:	9fad                	addw	a5,a5,a1
ffffffffc02014e4:	c91c                	sw	a5,16(a0)
ffffffffc02014e6:	ff070793          	addi	a5,a4,-16
ffffffffc02014ea:	60d7b02f          	amoand.d	zero,a3,(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014ee:	6314                	ld	a3,0(a4)
ffffffffc02014f0:	671c                	ld	a5,8(a4)
}
ffffffffc02014f2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02014f4:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02014f6:	e394                	sd	a3,0(a5)
ffffffffc02014f8:	0141                	addi	sp,sp,16
ffffffffc02014fa:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014fc:	00001697          	auipc	a3,0x1
ffffffffc0201500:	64c68693          	addi	a3,a3,1612 # ffffffffc0202b48 <etext+0xc34>
ffffffffc0201504:	00001617          	auipc	a2,0x1
ffffffffc0201508:	2e460613          	addi	a2,a2,740 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc020150c:	08300593          	li	a1,131
ffffffffc0201510:	00001517          	auipc	a0,0x1
ffffffffc0201514:	2f050513          	addi	a0,a0,752 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0201518:	e71fe0ef          	jal	ffffffffc0200388 <__panic>
    assert(n > 0);
ffffffffc020151c:	00001697          	auipc	a3,0x1
ffffffffc0201520:	62468693          	addi	a3,a3,1572 # ffffffffc0202b40 <etext+0xc2c>
ffffffffc0201524:	00001617          	auipc	a2,0x1
ffffffffc0201528:	2c460613          	addi	a2,a2,708 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc020152c:	08000593          	li	a1,128
ffffffffc0201530:	00001517          	auipc	a0,0x1
ffffffffc0201534:	2d050513          	addi	a0,a0,720 # ffffffffc0202800 <etext+0x8ec>
ffffffffc0201538:	e51fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc020153c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020153c:	cd41                	beqz	a0,ffffffffc02015d4 <default_alloc_pages+0x98>
    if (n > nr_free) {
ffffffffc020153e:	00005597          	auipc	a1,0x5
ffffffffc0201542:	afa5a583          	lw	a1,-1286(a1) # ffffffffc0206038 <free_area+0x10>
ffffffffc0201546:	86aa                	mv	a3,a0
ffffffffc0201548:	02059793          	slli	a5,a1,0x20
ffffffffc020154c:	9381                	srli	a5,a5,0x20
ffffffffc020154e:	00a7ef63          	bltu	a5,a0,ffffffffc020156c <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201552:	00005617          	auipc	a2,0x5
ffffffffc0201556:	ad660613          	addi	a2,a2,-1322 # ffffffffc0206028 <free_area>
ffffffffc020155a:	87b2                	mv	a5,a2
ffffffffc020155c:	a029                	j	ffffffffc0201566 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc020155e:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0201562:	00d77763          	bgeu	a4,a3,ffffffffc0201570 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc0201566:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201568:	fec79be3          	bne	a5,a2,ffffffffc020155e <default_alloc_pages+0x22>
        return NULL;
ffffffffc020156c:	4501                	li	a0,0
}
ffffffffc020156e:	8082                	ret
        if (page->property > n) {
ffffffffc0201570:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201574:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201578:	6798                	ld	a4,8(a5)
ffffffffc020157a:	02089313          	slli	t1,a7,0x20
ffffffffc020157e:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc0201582:	00e83423          	sd	a4,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc0201586:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020158a:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc020158e:	0266fc63          	bgeu	a3,t1,ffffffffc02015c6 <default_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc0201592:	00269713          	slli	a4,a3,0x2
ffffffffc0201596:	9736                	add	a4,a4,a3
ffffffffc0201598:	070e                	slli	a4,a4,0x3
            p->property = page->property - n;
ffffffffc020159a:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020159e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02015a0:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015a4:	00870313          	addi	t1,a4,8
ffffffffc02015a8:	4889                	li	a7,2
ffffffffc02015aa:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015ae:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02015b2:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02015b6:	0068b023          	sd	t1,0(a7)
ffffffffc02015ba:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02015be:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02015c2:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc02015c6:	9d95                	subw	a1,a1,a3
ffffffffc02015c8:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015ca:	5775                	li	a4,-3
ffffffffc02015cc:	17c1                	addi	a5,a5,-16
ffffffffc02015ce:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02015d2:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02015d4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02015d6:	00001697          	auipc	a3,0x1
ffffffffc02015da:	56a68693          	addi	a3,a3,1386 # ffffffffc0202b40 <etext+0xc2c>
ffffffffc02015de:	00001617          	auipc	a2,0x1
ffffffffc02015e2:	20a60613          	addi	a2,a2,522 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02015e6:	06200593          	li	a1,98
ffffffffc02015ea:	00001517          	auipc	a0,0x1
ffffffffc02015ee:	21650513          	addi	a0,a0,534 # ffffffffc0202800 <etext+0x8ec>
default_alloc_pages(size_t n) {
ffffffffc02015f2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015f4:	d95fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc02015f8 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02015f8:	1141                	addi	sp,sp,-16
ffffffffc02015fa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015fc:	c9f1                	beqz	a1,ffffffffc02016d0 <default_init_memmap+0xd8>
    for (; p != base + n; p ++) {
ffffffffc02015fe:	00259713          	slli	a4,a1,0x2
ffffffffc0201602:	972e                	add	a4,a4,a1
ffffffffc0201604:	070e                	slli	a4,a4,0x3
ffffffffc0201606:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020160a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020160c:	cf11                	beqz	a4,ffffffffc0201628 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020160e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201610:	8b05                	andi	a4,a4,1
ffffffffc0201612:	cf59                	beqz	a4,ffffffffc02016b0 <default_init_memmap+0xb8>
        p->flags = p->property = 0;
ffffffffc0201614:	0007a823          	sw	zero,16(a5)
ffffffffc0201618:	0007b423          	sd	zero,8(a5)
ffffffffc020161c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201620:	02878793          	addi	a5,a5,40
ffffffffc0201624:	fed795e3          	bne	a5,a3,ffffffffc020160e <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201628:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020162a:	4789                	li	a5,2
ffffffffc020162c:	00850713          	addi	a4,a0,8
ffffffffc0201630:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201634:	00005717          	auipc	a4,0x5
ffffffffc0201638:	a0472703          	lw	a4,-1532(a4) # ffffffffc0206038 <free_area+0x10>
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	9ec68693          	addi	a3,a3,-1556 # ffffffffc0206028 <free_area>
    return list->next == list;
ffffffffc0201644:	669c                	ld	a5,8(a3)
ffffffffc0201646:	9f2d                	addw	a4,a4,a1
ffffffffc0201648:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020164a:	04d78663          	beq	a5,a3,ffffffffc0201696 <default_init_memmap+0x9e>
            struct Page* page = le2page(le, page_link);
ffffffffc020164e:	fe878713          	addi	a4,a5,-24
ffffffffc0201652:	4581                	li	a1,0
ffffffffc0201654:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201658:	00e56a63          	bltu	a0,a4,ffffffffc020166c <default_init_memmap+0x74>
    return listelm->next;
ffffffffc020165c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020165e:	02d70263          	beq	a4,a3,ffffffffc0201682 <default_init_memmap+0x8a>
    struct Page *p = base;
ffffffffc0201662:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201664:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201668:	fee57ae3          	bgeu	a0,a4,ffffffffc020165c <default_init_memmap+0x64>
ffffffffc020166c:	c199                	beqz	a1,ffffffffc0201672 <default_init_memmap+0x7a>
ffffffffc020166e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201672:	6398                	ld	a4,0(a5)
}
ffffffffc0201674:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201676:	e390                	sd	a2,0(a5)
ffffffffc0201678:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc020167a:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020167c:	f11c                	sd	a5,32(a0)
ffffffffc020167e:	0141                	addi	sp,sp,16
ffffffffc0201680:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201682:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201684:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201686:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201688:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020168a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020168c:	00d70e63          	beq	a4,a3,ffffffffc02016a8 <default_init_memmap+0xb0>
ffffffffc0201690:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201692:	87ba                	mv	a5,a4
ffffffffc0201694:	bfc1                	j	ffffffffc0201664 <default_init_memmap+0x6c>
}
ffffffffc0201696:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201698:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020169c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020169e:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02016a0:	e398                	sd	a4,0(a5)
ffffffffc02016a2:	e798                	sd	a4,8(a5)
}
ffffffffc02016a4:	0141                	addi	sp,sp,16
ffffffffc02016a6:	8082                	ret
ffffffffc02016a8:	60a2                	ld	ra,8(sp)
ffffffffc02016aa:	e290                	sd	a2,0(a3)
ffffffffc02016ac:	0141                	addi	sp,sp,16
ffffffffc02016ae:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016b0:	00001697          	auipc	a3,0x1
ffffffffc02016b4:	4c068693          	addi	a3,a3,1216 # ffffffffc0202b70 <etext+0xc5c>
ffffffffc02016b8:	00001617          	auipc	a2,0x1
ffffffffc02016bc:	13060613          	addi	a2,a2,304 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02016c0:	04900593          	li	a1,73
ffffffffc02016c4:	00001517          	auipc	a0,0x1
ffffffffc02016c8:	13c50513          	addi	a0,a0,316 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02016cc:	cbdfe0ef          	jal	ffffffffc0200388 <__panic>
    assert(n > 0);
ffffffffc02016d0:	00001697          	auipc	a3,0x1
ffffffffc02016d4:	47068693          	addi	a3,a3,1136 # ffffffffc0202b40 <etext+0xc2c>
ffffffffc02016d8:	00001617          	auipc	a2,0x1
ffffffffc02016dc:	11060613          	addi	a2,a2,272 # ffffffffc02027e8 <etext+0x8d4>
ffffffffc02016e0:	04600593          	li	a1,70
ffffffffc02016e4:	00001517          	auipc	a0,0x1
ffffffffc02016e8:	11c50513          	addi	a0,a0,284 # ffffffffc0202800 <etext+0x8ec>
ffffffffc02016ec:	c9dfe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc02016f0 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016f0:	100027f3          	csrr	a5,sstatus
ffffffffc02016f4:	8b89                	andi	a5,a5,2
ffffffffc02016f6:	e799                	bnez	a5,ffffffffc0201704 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016f8:	00005797          	auipc	a5,0x5
ffffffffc02016fc:	d707b783          	ld	a5,-656(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201700:	6f9c                	ld	a5,24(a5)
ffffffffc0201702:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201704:	1101                	addi	sp,sp,-32
ffffffffc0201706:	ec06                	sd	ra,24(sp)
ffffffffc0201708:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020170a:	878ff0ef          	jal	ffffffffc0200782 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020170e:	00005797          	auipc	a5,0x5
ffffffffc0201712:	d5a7b783          	ld	a5,-678(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201716:	6522                	ld	a0,8(sp)
ffffffffc0201718:	6f9c                	ld	a5,24(a5)
ffffffffc020171a:	9782                	jalr	a5
ffffffffc020171c:	e42a                	sd	a0,8(sp)
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020171e:	85eff0ef          	jal	ffffffffc020077c <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201722:	60e2                	ld	ra,24(sp)
ffffffffc0201724:	6522                	ld	a0,8(sp)
ffffffffc0201726:	6105                	addi	sp,sp,32
ffffffffc0201728:	8082                	ret

ffffffffc020172a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020172a:	100027f3          	csrr	a5,sstatus
ffffffffc020172e:	8b89                	andi	a5,a5,2
ffffffffc0201730:	e799                	bnez	a5,ffffffffc020173e <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201732:	00005797          	auipc	a5,0x5
ffffffffc0201736:	d367b783          	ld	a5,-714(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc020173a:	739c                	ld	a5,32(a5)
ffffffffc020173c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020173e:	1101                	addi	sp,sp,-32
ffffffffc0201740:	ec06                	sd	ra,24(sp)
ffffffffc0201742:	e42e                	sd	a1,8(sp)
ffffffffc0201744:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201746:	83cff0ef          	jal	ffffffffc0200782 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020174a:	00005797          	auipc	a5,0x5
ffffffffc020174e:	d1e7b783          	ld	a5,-738(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201752:	65a2                	ld	a1,8(sp)
ffffffffc0201754:	6502                	ld	a0,0(sp)
ffffffffc0201756:	739c                	ld	a5,32(a5)
ffffffffc0201758:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020175a:	60e2                	ld	ra,24(sp)
ffffffffc020175c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020175e:	81eff06f          	j	ffffffffc020077c <intr_enable>

ffffffffc0201762 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201762:	100027f3          	csrr	a5,sstatus
ffffffffc0201766:	8b89                	andi	a5,a5,2
ffffffffc0201768:	e799                	bnez	a5,ffffffffc0201776 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020176a:	00005797          	auipc	a5,0x5
ffffffffc020176e:	cfe7b783          	ld	a5,-770(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201772:	779c                	ld	a5,40(a5)
ffffffffc0201774:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201776:	1101                	addi	sp,sp,-32
ffffffffc0201778:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020177a:	808ff0ef          	jal	ffffffffc0200782 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020177e:	00005797          	auipc	a5,0x5
ffffffffc0201782:	cea7b783          	ld	a5,-790(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201786:	779c                	ld	a5,40(a5)
ffffffffc0201788:	9782                	jalr	a5
ffffffffc020178a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020178c:	ff1fe0ef          	jal	ffffffffc020077c <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201790:	60e2                	ld	ra,24(sp)
ffffffffc0201792:	6522                	ld	a0,8(sp)
ffffffffc0201794:	6105                	addi	sp,sp,32
ffffffffc0201796:	8082                	ret

ffffffffc0201798 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201798:	00001797          	auipc	a5,0x1
ffffffffc020179c:	67878793          	addi	a5,a5,1656 # ffffffffc0202e10 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017a0:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017a2:	7139                	addi	sp,sp,-64
ffffffffc02017a4:	fc06                	sd	ra,56(sp)
ffffffffc02017a6:	f822                	sd	s0,48(sp)
ffffffffc02017a8:	f426                	sd	s1,40(sp)
ffffffffc02017aa:	ec4e                	sd	s3,24(sp)
ffffffffc02017ac:	f04a                	sd	s2,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02017ae:	00005417          	auipc	s0,0x5
ffffffffc02017b2:	cba40413          	addi	s0,s0,-838 # ffffffffc0206468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017b6:	00001517          	auipc	a0,0x1
ffffffffc02017ba:	3e250513          	addi	a0,a0,994 # ffffffffc0202b98 <etext+0xc84>
    pmm_manager = &default_pmm_manager;
ffffffffc02017be:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017c0:	917fe0ef          	jal	ffffffffc02000d6 <cprintf>
    pmm_manager->init();
ffffffffc02017c4:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017c6:	00005497          	auipc	s1,0x5
ffffffffc02017ca:	cba48493          	addi	s1,s1,-838 # ffffffffc0206480 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017ce:	679c                	ld	a5,8(a5)
ffffffffc02017d0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017d2:	57f5                	li	a5,-3
ffffffffc02017d4:	07fa                	slli	a5,a5,0x1e
ffffffffc02017d6:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017d8:	f91fe0ef          	jal	ffffffffc0200768 <get_memory_base>
ffffffffc02017dc:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017de:	f95fe0ef          	jal	ffffffffc0200772 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017e2:	16050063          	beqz	a0,ffffffffc0201942 <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017e6:	00a98933          	add	s2,s3,a0
ffffffffc02017ea:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc02017ec:	00001517          	auipc	a0,0x1
ffffffffc02017f0:	3f450513          	addi	a0,a0,1012 # ffffffffc0202be0 <etext+0xccc>
ffffffffc02017f4:	8e3fe0ef          	jal	ffffffffc02000d6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02017f8:	65a2                	ld	a1,8(sp)
ffffffffc02017fa:	864e                	mv	a2,s3
ffffffffc02017fc:	fff90693          	addi	a3,s2,-1
ffffffffc0201800:	00001517          	auipc	a0,0x1
ffffffffc0201804:	3f850513          	addi	a0,a0,1016 # ffffffffc0202bf8 <etext+0xce4>
ffffffffc0201808:	8cffe0ef          	jal	ffffffffc02000d6 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020180c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201810:	864a                	mv	a2,s2
ffffffffc0201812:	0d27e563          	bltu	a5,s2,ffffffffc02018dc <pmm_init+0x144>
ffffffffc0201816:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201818:	00006697          	auipc	a3,0x6
ffffffffc020181c:	c8768693          	addi	a3,a3,-889 # ffffffffc020749f <end+0xfff>
ffffffffc0201820:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0201822:	8231                	srli	a2,a2,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201824:	00005817          	auipc	a6,0x5
ffffffffc0201828:	c6c80813          	addi	a6,a6,-916 # ffffffffc0206490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020182c:	00005517          	auipc	a0,0x5
ffffffffc0201830:	c5c50513          	addi	a0,a0,-932 # ffffffffc0206488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201834:	00d83023          	sd	a3,0(a6)
    npage = maxpa / PGSIZE;
ffffffffc0201838:	e110                	sd	a2,0(a0)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020183a:	00080737          	lui	a4,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020183e:	87b6                	mv	a5,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201840:	02e60a63          	beq	a2,a4,ffffffffc0201874 <pmm_init+0xdc>
ffffffffc0201844:	4701                	li	a4,0
ffffffffc0201846:	4781                	li	a5,0
ffffffffc0201848:	4305                	li	t1,1
ffffffffc020184a:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc020184e:	96ba                	add	a3,a3,a4
ffffffffc0201850:	06a1                	addi	a3,a3,8
ffffffffc0201852:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201856:	6110                	ld	a2,0(a0)
ffffffffc0201858:	0785                	addi	a5,a5,1 # fffffffffffff001 <end+0x3fdf8b61>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020185a:	00083683          	ld	a3,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020185e:	011605b3          	add	a1,a2,a7
ffffffffc0201862:	02870713          	addi	a4,a4,40 # 80028 <kern_entry-0xffffffffc017ffd8>
ffffffffc0201866:	feb7e4e3          	bltu	a5,a1,ffffffffc020184e <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020186a:	00259793          	slli	a5,a1,0x2
ffffffffc020186e:	97ae                	add	a5,a5,a1
ffffffffc0201870:	078e                	slli	a5,a5,0x3
ffffffffc0201872:	97b6                	add	a5,a5,a3
ffffffffc0201874:	c0200737          	lui	a4,0xc0200
ffffffffc0201878:	0ae7e863          	bltu	a5,a4,ffffffffc0201928 <pmm_init+0x190>
ffffffffc020187c:	608c                	ld	a1,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020187e:	777d                	lui	a4,0xfffff
ffffffffc0201880:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201884:	8f8d                	sub	a5,a5,a1
    if (freemem < mem_end) {
ffffffffc0201886:	0527ed63          	bltu	a5,s2,ffffffffc02018e0 <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020188a:	601c                	ld	a5,0(s0)
ffffffffc020188c:	7b9c                	ld	a5,48(a5)
ffffffffc020188e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201890:	00001517          	auipc	a0,0x1
ffffffffc0201894:	3f050513          	addi	a0,a0,1008 # ffffffffc0202c80 <etext+0xd6c>
ffffffffc0201898:	83ffe0ef          	jal	ffffffffc02000d6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020189c:	00003597          	auipc	a1,0x3
ffffffffc02018a0:	76458593          	addi	a1,a1,1892 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018a4:	00005797          	auipc	a5,0x5
ffffffffc02018a8:	bcb7ba23          	sd	a1,-1068(a5) # ffffffffc0206478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018ac:	c02007b7          	lui	a5,0xc0200
ffffffffc02018b0:	0af5e563          	bltu	a1,a5,ffffffffc020195a <pmm_init+0x1c2>
ffffffffc02018b4:	609c                	ld	a5,0(s1)
}
ffffffffc02018b6:	7442                	ld	s0,48(sp)
ffffffffc02018b8:	70e2                	ld	ra,56(sp)
ffffffffc02018ba:	74a2                	ld	s1,40(sp)
ffffffffc02018bc:	7902                	ld	s2,32(sp)
ffffffffc02018be:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018c0:	40f586b3          	sub	a3,a1,a5
ffffffffc02018c4:	00005797          	auipc	a5,0x5
ffffffffc02018c8:	bad7b623          	sd	a3,-1108(a5) # ffffffffc0206470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018cc:	00001517          	auipc	a0,0x1
ffffffffc02018d0:	3d450513          	addi	a0,a0,980 # ffffffffc0202ca0 <etext+0xd8c>
ffffffffc02018d4:	8636                	mv	a2,a3
}
ffffffffc02018d6:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018d8:	ffefe06f          	j	ffffffffc02000d6 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02018dc:	863e                	mv	a2,a5
ffffffffc02018de:	bf25                	j	ffffffffc0201816 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018e0:	6585                	lui	a1,0x1
ffffffffc02018e2:	15fd                	addi	a1,a1,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02018e4:	97ae                	add	a5,a5,a1
ffffffffc02018e6:	8ff9                	and	a5,a5,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018e8:	00c7d713          	srli	a4,a5,0xc
ffffffffc02018ec:	02c77263          	bgeu	a4,a2,ffffffffc0201910 <pmm_init+0x178>
    pmm_manager->init_memmap(base, n);
ffffffffc02018f0:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02018f2:	fff805b7          	lui	a1,0xfff80
ffffffffc02018f6:	972e                	add	a4,a4,a1
ffffffffc02018f8:	00271513          	slli	a0,a4,0x2
ffffffffc02018fc:	953a                	add	a0,a0,a4
ffffffffc02018fe:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201900:	40f90933          	sub	s2,s2,a5
ffffffffc0201904:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201906:	00c95593          	srli	a1,s2,0xc
ffffffffc020190a:	9536                	add	a0,a0,a3
ffffffffc020190c:	9702                	jalr	a4
}
ffffffffc020190e:	bfb5                	j	ffffffffc020188a <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201910:	00001617          	auipc	a2,0x1
ffffffffc0201914:	34060613          	addi	a2,a2,832 # ffffffffc0202c50 <etext+0xd3c>
ffffffffc0201918:	06b00593          	li	a1,107
ffffffffc020191c:	00001517          	auipc	a0,0x1
ffffffffc0201920:	35450513          	addi	a0,a0,852 # ffffffffc0202c70 <etext+0xd5c>
ffffffffc0201924:	a65fe0ef          	jal	ffffffffc0200388 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201928:	86be                	mv	a3,a5
ffffffffc020192a:	00001617          	auipc	a2,0x1
ffffffffc020192e:	2fe60613          	addi	a2,a2,766 # ffffffffc0202c28 <etext+0xd14>
ffffffffc0201932:	07100593          	li	a1,113
ffffffffc0201936:	00001517          	auipc	a0,0x1
ffffffffc020193a:	29a50513          	addi	a0,a0,666 # ffffffffc0202bd0 <etext+0xcbc>
ffffffffc020193e:	a4bfe0ef          	jal	ffffffffc0200388 <__panic>
        panic("DTB memory info not available");
ffffffffc0201942:	00001617          	auipc	a2,0x1
ffffffffc0201946:	26e60613          	addi	a2,a2,622 # ffffffffc0202bb0 <etext+0xc9c>
ffffffffc020194a:	05a00593          	li	a1,90
ffffffffc020194e:	00001517          	auipc	a0,0x1
ffffffffc0201952:	28250513          	addi	a0,a0,642 # ffffffffc0202bd0 <etext+0xcbc>
ffffffffc0201956:	a33fe0ef          	jal	ffffffffc0200388 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020195a:	86ae                	mv	a3,a1
ffffffffc020195c:	00001617          	auipc	a2,0x1
ffffffffc0201960:	2cc60613          	addi	a2,a2,716 # ffffffffc0202c28 <etext+0xd14>
ffffffffc0201964:	08c00593          	li	a1,140
ffffffffc0201968:	00001517          	auipc	a0,0x1
ffffffffc020196c:	26850513          	addi	a0,a0,616 # ffffffffc0202bd0 <etext+0xcbc>
ffffffffc0201970:	a19fe0ef          	jal	ffffffffc0200388 <__panic>

ffffffffc0201974 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201974:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201976:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020197a:	f022                	sd	s0,32(sp)
ffffffffc020197c:	ec26                	sd	s1,24(sp)
ffffffffc020197e:	e84a                	sd	s2,16(sp)
ffffffffc0201980:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201982:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201986:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201988:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020198c:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b5f>
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201990:	84aa                	mv	s1,a0
ffffffffc0201992:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0201994:	03067d63          	bgeu	a2,a6,ffffffffc02019ce <printnum+0x5a>
ffffffffc0201998:	e44e                	sd	s3,8(sp)
ffffffffc020199a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020199c:	4785                	li	a5,1
ffffffffc020199e:	00e7d763          	bge	a5,a4,ffffffffc02019ac <printnum+0x38>
            putch(padc, putdat);
ffffffffc02019a2:	85ca                	mv	a1,s2
ffffffffc02019a4:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02019a6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019a8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019aa:	fc65                	bnez	s0,ffffffffc02019a2 <printnum+0x2e>
ffffffffc02019ac:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ae:	00001797          	auipc	a5,0x1
ffffffffc02019b2:	33278793          	addi	a5,a5,818 # ffffffffc0202ce0 <etext+0xdcc>
ffffffffc02019b6:	97d2                	add	a5,a5,s4
}
ffffffffc02019b8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ba:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02019be:	70a2                	ld	ra,40(sp)
ffffffffc02019c0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019c2:	85ca                	mv	a1,s2
ffffffffc02019c4:	87a6                	mv	a5,s1
}
ffffffffc02019c6:	6942                	ld	s2,16(sp)
ffffffffc02019c8:	64e2                	ld	s1,24(sp)
ffffffffc02019ca:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019cc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019ce:	03065633          	divu	a2,a2,a6
ffffffffc02019d2:	8722                	mv	a4,s0
ffffffffc02019d4:	fa1ff0ef          	jal	ffffffffc0201974 <printnum>
ffffffffc02019d8:	bfd9                	j	ffffffffc02019ae <printnum+0x3a>

ffffffffc02019da <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019da:	7119                	addi	sp,sp,-128
ffffffffc02019dc:	f4a6                	sd	s1,104(sp)
ffffffffc02019de:	f0ca                	sd	s2,96(sp)
ffffffffc02019e0:	ecce                	sd	s3,88(sp)
ffffffffc02019e2:	e8d2                	sd	s4,80(sp)
ffffffffc02019e4:	e4d6                	sd	s5,72(sp)
ffffffffc02019e6:	e0da                	sd	s6,64(sp)
ffffffffc02019e8:	f862                	sd	s8,48(sp)
ffffffffc02019ea:	fc86                	sd	ra,120(sp)
ffffffffc02019ec:	f8a2                	sd	s0,112(sp)
ffffffffc02019ee:	fc5e                	sd	s7,56(sp)
ffffffffc02019f0:	f466                	sd	s9,40(sp)
ffffffffc02019f2:	f06a                	sd	s10,32(sp)
ffffffffc02019f4:	ec6e                	sd	s11,24(sp)
ffffffffc02019f6:	84aa                	mv	s1,a0
ffffffffc02019f8:	8c32                	mv	s8,a2
ffffffffc02019fa:	8a36                	mv	s4,a3
ffffffffc02019fc:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019fe:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a02:	05500b13          	li	s6,85
ffffffffc0201a06:	00001a97          	auipc	s5,0x1
ffffffffc0201a0a:	442a8a93          	addi	s5,s5,1090 # ffffffffc0202e48 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a0e:	000c4503          	lbu	a0,0(s8)
ffffffffc0201a12:	001c0413          	addi	s0,s8,1
ffffffffc0201a16:	01350a63          	beq	a0,s3,ffffffffc0201a2a <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201a1a:	cd0d                	beqz	a0,ffffffffc0201a54 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201a1c:	85ca                	mv	a1,s2
ffffffffc0201a1e:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a20:	00044503          	lbu	a0,0(s0)
ffffffffc0201a24:	0405                	addi	s0,s0,1
ffffffffc0201a26:	ff351ae3          	bne	a0,s3,ffffffffc0201a1a <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201a2a:	5cfd                	li	s9,-1
ffffffffc0201a2c:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201a2e:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201a32:	4b81                	li	s7,0
ffffffffc0201a34:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a36:	00044683          	lbu	a3,0(s0)
ffffffffc0201a3a:	00140c13          	addi	s8,s0,1
ffffffffc0201a3e:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201a42:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a46:	02bb6663          	bltu	s6,a1,ffffffffc0201a72 <vprintfmt+0x98>
ffffffffc0201a4a:	058a                	slli	a1,a1,0x2
ffffffffc0201a4c:	95d6                	add	a1,a1,s5
ffffffffc0201a4e:	4198                	lw	a4,0(a1)
ffffffffc0201a50:	9756                	add	a4,a4,s5
ffffffffc0201a52:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a54:	70e6                	ld	ra,120(sp)
ffffffffc0201a56:	7446                	ld	s0,112(sp)
ffffffffc0201a58:	74a6                	ld	s1,104(sp)
ffffffffc0201a5a:	7906                	ld	s2,96(sp)
ffffffffc0201a5c:	69e6                	ld	s3,88(sp)
ffffffffc0201a5e:	6a46                	ld	s4,80(sp)
ffffffffc0201a60:	6aa6                	ld	s5,72(sp)
ffffffffc0201a62:	6b06                	ld	s6,64(sp)
ffffffffc0201a64:	7be2                	ld	s7,56(sp)
ffffffffc0201a66:	7c42                	ld	s8,48(sp)
ffffffffc0201a68:	7ca2                	ld	s9,40(sp)
ffffffffc0201a6a:	7d02                	ld	s10,32(sp)
ffffffffc0201a6c:	6de2                	ld	s11,24(sp)
ffffffffc0201a6e:	6109                	addi	sp,sp,128
ffffffffc0201a70:	8082                	ret
            putch('%', putdat);
ffffffffc0201a72:	85ca                	mv	a1,s2
ffffffffc0201a74:	02500513          	li	a0,37
ffffffffc0201a78:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a7a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a7e:	02500713          	li	a4,37
ffffffffc0201a82:	8c22                	mv	s8,s0
ffffffffc0201a84:	f8e785e3          	beq	a5,a4,ffffffffc0201a0e <vprintfmt+0x34>
ffffffffc0201a88:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201a8c:	1c7d                	addi	s8,s8,-1
ffffffffc0201a8e:	fee79de3          	bne	a5,a4,ffffffffc0201a88 <vprintfmt+0xae>
ffffffffc0201a92:	bfb5                	j	ffffffffc0201a0e <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201a94:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201a98:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0201a9a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201a9e:	fd06071b          	addiw	a4,a2,-48
ffffffffc0201aa2:	24e56a63          	bltu	a0,a4,ffffffffc0201cf6 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201aa6:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa8:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0201aaa:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201aae:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201ab2:	0197073b          	addw	a4,a4,s9
ffffffffc0201ab6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201aba:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201abc:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201ac0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201ac2:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201ac6:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201aca:	feb570e3          	bgeu	a0,a1,ffffffffc0201aaa <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201ace:	f60d54e3          	bgez	s10,ffffffffc0201a36 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201ad2:	8d66                	mv	s10,s9
ffffffffc0201ad4:	5cfd                	li	s9,-1
ffffffffc0201ad6:	b785                	j	ffffffffc0201a36 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ad8:	8db6                	mv	s11,a3
ffffffffc0201ada:	8462                	mv	s0,s8
ffffffffc0201adc:	bfa9                	j	ffffffffc0201a36 <vprintfmt+0x5c>
ffffffffc0201ade:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201ae0:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201ae2:	bf91                	j	ffffffffc0201a36 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201ae4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ae6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201aea:	00f74463          	blt	a4,a5,ffffffffc0201af2 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201aee:	1a078763          	beqz	a5,ffffffffc0201c9c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0201af2:	000a3603          	ld	a2,0(s4)
ffffffffc0201af6:	46c1                	li	a3,16
ffffffffc0201af8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201afa:	000d879b          	sext.w	a5,s11
ffffffffc0201afe:	876a                	mv	a4,s10
ffffffffc0201b00:	85ca                	mv	a1,s2
ffffffffc0201b02:	8526                	mv	a0,s1
ffffffffc0201b04:	e71ff0ef          	jal	ffffffffc0201974 <printnum>
            break;
ffffffffc0201b08:	b719                	j	ffffffffc0201a0e <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b0a:	000a2503          	lw	a0,0(s4)
ffffffffc0201b0e:	85ca                	mv	a1,s2
ffffffffc0201b10:	0a21                	addi	s4,s4,8
ffffffffc0201b12:	9482                	jalr	s1
            break;
ffffffffc0201b14:	bded                	j	ffffffffc0201a0e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201b16:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b18:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b1c:	00f74463          	blt	a4,a5,ffffffffc0201b24 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201b20:	16078963          	beqz	a5,ffffffffc0201c92 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0201b24:	000a3603          	ld	a2,0(s4)
ffffffffc0201b28:	46a9                	li	a3,10
ffffffffc0201b2a:	8a2e                	mv	s4,a1
ffffffffc0201b2c:	b7f9                	j	ffffffffc0201afa <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201b2e:	85ca                	mv	a1,s2
ffffffffc0201b30:	03000513          	li	a0,48
ffffffffc0201b34:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201b36:	85ca                	mv	a1,s2
ffffffffc0201b38:	07800513          	li	a0,120
ffffffffc0201b3c:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b3e:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201b42:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b44:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b46:	bf55                	j	ffffffffc0201afa <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201b48:	85ca                	mv	a1,s2
ffffffffc0201b4a:	02500513          	li	a0,37
ffffffffc0201b4e:	9482                	jalr	s1
            break;
ffffffffc0201b50:	bd7d                	j	ffffffffc0201a0e <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201b52:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b56:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201b58:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201b5a:	bf95                	j	ffffffffc0201ace <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201b5c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b5e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b62:	00f74463          	blt	a4,a5,ffffffffc0201b6a <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201b66:	12078163          	beqz	a5,ffffffffc0201c88 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201b6a:	000a3603          	ld	a2,0(s4)
ffffffffc0201b6e:	46a1                	li	a3,8
ffffffffc0201b70:	8a2e                	mv	s4,a1
ffffffffc0201b72:	b761                	j	ffffffffc0201afa <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201b74:	876a                	mv	a4,s10
ffffffffc0201b76:	000d5363          	bgez	s10,ffffffffc0201b7c <vprintfmt+0x1a2>
ffffffffc0201b7a:	4701                	li	a4,0
ffffffffc0201b7c:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b80:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201b82:	bd55                	j	ffffffffc0201a36 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0201b84:	000d841b          	sext.w	s0,s11
ffffffffc0201b88:	fd340793          	addi	a5,s0,-45
ffffffffc0201b8c:	00f037b3          	snez	a5,a5
ffffffffc0201b90:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b94:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0201b98:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b9a:	008a0793          	addi	a5,s4,8
ffffffffc0201b9e:	e43e                	sd	a5,8(sp)
ffffffffc0201ba0:	100d8c63          	beqz	s11,ffffffffc0201cb8 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201ba4:	12071363          	bnez	a4,ffffffffc0201cca <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ba8:	000dc783          	lbu	a5,0(s11)
ffffffffc0201bac:	0007851b          	sext.w	a0,a5
ffffffffc0201bb0:	c78d                	beqz	a5,ffffffffc0201bda <vprintfmt+0x200>
ffffffffc0201bb2:	0d85                	addi	s11,s11,1
ffffffffc0201bb4:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bb6:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bba:	000cc563          	bltz	s9,ffffffffc0201bc4 <vprintfmt+0x1ea>
ffffffffc0201bbe:	3cfd                	addiw	s9,s9,-1
ffffffffc0201bc0:	008c8d63          	beq	s9,s0,ffffffffc0201bda <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bc4:	020b9663          	bnez	s7,ffffffffc0201bf0 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201bc8:	85ca                	mv	a1,s2
ffffffffc0201bca:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bcc:	000dc783          	lbu	a5,0(s11)
ffffffffc0201bd0:	0d85                	addi	s11,s11,1
ffffffffc0201bd2:	3d7d                	addiw	s10,s10,-1
ffffffffc0201bd4:	0007851b          	sext.w	a0,a5
ffffffffc0201bd8:	f3ed                	bnez	a5,ffffffffc0201bba <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201bda:	01a05963          	blez	s10,ffffffffc0201bec <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201bde:	85ca                	mv	a1,s2
ffffffffc0201be0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201be4:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201be6:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201be8:	fe0d1be3          	bnez	s10,ffffffffc0201bde <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bec:	6a22                	ld	s4,8(sp)
ffffffffc0201bee:	b505                	j	ffffffffc0201a0e <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bf0:	3781                	addiw	a5,a5,-32
ffffffffc0201bf2:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201bc8 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201bf6:	03f00513          	li	a0,63
ffffffffc0201bfa:	85ca                	mv	a1,s2
ffffffffc0201bfc:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bfe:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c02:	0d85                	addi	s11,s11,1
ffffffffc0201c04:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c06:	0007851b          	sext.w	a0,a5
ffffffffc0201c0a:	dbe1                	beqz	a5,ffffffffc0201bda <vprintfmt+0x200>
ffffffffc0201c0c:	fa0cd9e3          	bgez	s9,ffffffffc0201bbe <vprintfmt+0x1e4>
ffffffffc0201c10:	b7c5                	j	ffffffffc0201bf0 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0201c12:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c16:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201c18:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c1a:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201c1e:	8fb9                	xor	a5,a5,a4
ffffffffc0201c20:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c24:	02d64563          	blt	a2,a3,ffffffffc0201c4e <vprintfmt+0x274>
ffffffffc0201c28:	00001797          	auipc	a5,0x1
ffffffffc0201c2c:	37878793          	addi	a5,a5,888 # ffffffffc0202fa0 <error_string>
ffffffffc0201c30:	00369713          	slli	a4,a3,0x3
ffffffffc0201c34:	97ba                	add	a5,a5,a4
ffffffffc0201c36:	639c                	ld	a5,0(a5)
ffffffffc0201c38:	cb99                	beqz	a5,ffffffffc0201c4e <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c3a:	86be                	mv	a3,a5
ffffffffc0201c3c:	00001617          	auipc	a2,0x1
ffffffffc0201c40:	0d460613          	addi	a2,a2,212 # ffffffffc0202d10 <etext+0xdfc>
ffffffffc0201c44:	85ca                	mv	a1,s2
ffffffffc0201c46:	8526                	mv	a0,s1
ffffffffc0201c48:	0d8000ef          	jal	ffffffffc0201d20 <printfmt>
ffffffffc0201c4c:	b3c9                	j	ffffffffc0201a0e <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c4e:	00001617          	auipc	a2,0x1
ffffffffc0201c52:	0b260613          	addi	a2,a2,178 # ffffffffc0202d00 <etext+0xdec>
ffffffffc0201c56:	85ca                	mv	a1,s2
ffffffffc0201c58:	8526                	mv	a0,s1
ffffffffc0201c5a:	0c6000ef          	jal	ffffffffc0201d20 <printfmt>
ffffffffc0201c5e:	bb45                	j	ffffffffc0201a0e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c60:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c62:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201c66:	00f74363          	blt	a4,a5,ffffffffc0201c6c <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201c6a:	cf81                	beqz	a5,ffffffffc0201c82 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201c6c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c70:	02044b63          	bltz	s0,ffffffffc0201ca6 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201c74:	8622                	mv	a2,s0
ffffffffc0201c76:	8a5e                	mv	s4,s7
ffffffffc0201c78:	46a9                	li	a3,10
ffffffffc0201c7a:	b541                	j	ffffffffc0201afa <vprintfmt+0x120>
            lflag ++;
ffffffffc0201c7c:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c7e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c80:	bb5d                	j	ffffffffc0201a36 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201c82:	000a2403          	lw	s0,0(s4)
ffffffffc0201c86:	b7ed                	j	ffffffffc0201c70 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201c88:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c8c:	46a1                	li	a3,8
ffffffffc0201c8e:	8a2e                	mv	s4,a1
ffffffffc0201c90:	b5ad                	j	ffffffffc0201afa <vprintfmt+0x120>
ffffffffc0201c92:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c96:	46a9                	li	a3,10
ffffffffc0201c98:	8a2e                	mv	s4,a1
ffffffffc0201c9a:	b585                	j	ffffffffc0201afa <vprintfmt+0x120>
ffffffffc0201c9c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ca0:	46c1                	li	a3,16
ffffffffc0201ca2:	8a2e                	mv	s4,a1
ffffffffc0201ca4:	bd99                	j	ffffffffc0201afa <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201ca6:	85ca                	mv	a1,s2
ffffffffc0201ca8:	02d00513          	li	a0,45
ffffffffc0201cac:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201cae:	40800633          	neg	a2,s0
ffffffffc0201cb2:	8a5e                	mv	s4,s7
ffffffffc0201cb4:	46a9                	li	a3,10
ffffffffc0201cb6:	b591                	j	ffffffffc0201afa <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201cb8:	e329                	bnez	a4,ffffffffc0201cfa <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cba:	02800793          	li	a5,40
ffffffffc0201cbe:	853e                	mv	a0,a5
ffffffffc0201cc0:	00001d97          	auipc	s11,0x1
ffffffffc0201cc4:	039d8d93          	addi	s11,s11,57 # ffffffffc0202cf9 <etext+0xde5>
ffffffffc0201cc8:	b5f5                	j	ffffffffc0201bb4 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cca:	85e6                	mv	a1,s9
ffffffffc0201ccc:	856e                	mv	a0,s11
ffffffffc0201cce:	1aa000ef          	jal	ffffffffc0201e78 <strnlen>
ffffffffc0201cd2:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201cd6:	01a05863          	blez	s10,ffffffffc0201ce6 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201cda:	85ca                	mv	a1,s2
ffffffffc0201cdc:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cde:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0201ce0:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201ce2:	fe0d1ce3          	bnez	s10,ffffffffc0201cda <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ce6:	000dc783          	lbu	a5,0(s11)
ffffffffc0201cea:	0007851b          	sext.w	a0,a5
ffffffffc0201cee:	ec0792e3          	bnez	a5,ffffffffc0201bb2 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cf2:	6a22                	ld	s4,8(sp)
ffffffffc0201cf4:	bb29                	j	ffffffffc0201a0e <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cf6:	8462                	mv	s0,s8
ffffffffc0201cf8:	bbd9                	j	ffffffffc0201ace <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cfa:	85e6                	mv	a1,s9
ffffffffc0201cfc:	00001517          	auipc	a0,0x1
ffffffffc0201d00:	ffc50513          	addi	a0,a0,-4 # ffffffffc0202cf8 <etext+0xde4>
ffffffffc0201d04:	174000ef          	jal	ffffffffc0201e78 <strnlen>
ffffffffc0201d08:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d0c:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0201d10:	00001d97          	auipc	s11,0x1
ffffffffc0201d14:	fe8d8d93          	addi	s11,s11,-24 # ffffffffc0202cf8 <etext+0xde4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d18:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d1a:	fda040e3          	bgtz	s10,ffffffffc0201cda <vprintfmt+0x300>
ffffffffc0201d1e:	bd51                	j	ffffffffc0201bb2 <vprintfmt+0x1d8>

ffffffffc0201d20 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d20:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d22:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d26:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d28:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d2a:	ec06                	sd	ra,24(sp)
ffffffffc0201d2c:	f83a                	sd	a4,48(sp)
ffffffffc0201d2e:	fc3e                	sd	a5,56(sp)
ffffffffc0201d30:	e0c2                	sd	a6,64(sp)
ffffffffc0201d32:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d34:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d36:	ca5ff0ef          	jal	ffffffffc02019da <vprintfmt>
}
ffffffffc0201d3a:	60e2                	ld	ra,24(sp)
ffffffffc0201d3c:	6161                	addi	sp,sp,80
ffffffffc0201d3e:	8082                	ret

ffffffffc0201d40 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d40:	7179                	addi	sp,sp,-48
ffffffffc0201d42:	f406                	sd	ra,40(sp)
ffffffffc0201d44:	f022                	sd	s0,32(sp)
ffffffffc0201d46:	ec26                	sd	s1,24(sp)
ffffffffc0201d48:	e84a                	sd	s2,16(sp)
ffffffffc0201d4a:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc0201d4c:	c901                	beqz	a0,ffffffffc0201d5c <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc0201d4e:	85aa                	mv	a1,a0
ffffffffc0201d50:	00001517          	auipc	a0,0x1
ffffffffc0201d54:	fc050513          	addi	a0,a0,-64 # ffffffffc0202d10 <etext+0xdfc>
ffffffffc0201d58:	b7efe0ef          	jal	ffffffffc02000d6 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201d5c:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d5e:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc0201d60:	00004997          	auipc	s3,0x4
ffffffffc0201d64:	2e098993          	addi	s3,s3,736 # ffffffffc0206040 <buf>
        c = getchar();
ffffffffc0201d68:	bf0fe0ef          	jal	ffffffffc0200158 <getchar>
ffffffffc0201d6c:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d6e:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d72:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d76:	ff650693          	addi	a3,a0,-10
ffffffffc0201d7a:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0201d7e:	02054963          	bltz	a0,ffffffffc0201db0 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d82:	02a95f63          	bge	s2,a0,ffffffffc0201dc0 <readline+0x80>
ffffffffc0201d86:	cf0d                	beqz	a4,ffffffffc0201dc0 <readline+0x80>
            cputchar(c);
ffffffffc0201d88:	b82fe0ef          	jal	ffffffffc020010a <cputchar>
            buf[i ++] = c;
ffffffffc0201d8c:	009987b3          	add	a5,s3,s1
ffffffffc0201d90:	00878023          	sb	s0,0(a5)
ffffffffc0201d94:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0201d96:	bc2fe0ef          	jal	ffffffffc0200158 <getchar>
ffffffffc0201d9a:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0201d9c:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201da0:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc0201da4:	ff650693          	addi	a3,a0,-10
ffffffffc0201da8:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0201dac:	fc055be3          	bgez	a0,ffffffffc0201d82 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0201db0:	70a2                	ld	ra,40(sp)
ffffffffc0201db2:	7402                	ld	s0,32(sp)
ffffffffc0201db4:	64e2                	ld	s1,24(sp)
ffffffffc0201db6:	6942                	ld	s2,16(sp)
ffffffffc0201db8:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0201dba:	4501                	li	a0,0
}
ffffffffc0201dbc:	6145                	addi	sp,sp,48
ffffffffc0201dbe:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0201dc0:	eb81                	bnez	a5,ffffffffc0201dd0 <readline+0x90>
            cputchar(c);
ffffffffc0201dc2:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc0201dc4:	00905663          	blez	s1,ffffffffc0201dd0 <readline+0x90>
            cputchar(c);
ffffffffc0201dc8:	b42fe0ef          	jal	ffffffffc020010a <cputchar>
            i --;
ffffffffc0201dcc:	34fd                	addiw	s1,s1,-1
ffffffffc0201dce:	bf69                	j	ffffffffc0201d68 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0201dd0:	c291                	beqz	a3,ffffffffc0201dd4 <readline+0x94>
ffffffffc0201dd2:	fa59                	bnez	a2,ffffffffc0201d68 <readline+0x28>
            cputchar(c);
ffffffffc0201dd4:	8522                	mv	a0,s0
ffffffffc0201dd6:	b34fe0ef          	jal	ffffffffc020010a <cputchar>
            buf[i] = '\0';
ffffffffc0201dda:	00004517          	auipc	a0,0x4
ffffffffc0201dde:	26650513          	addi	a0,a0,614 # ffffffffc0206040 <buf>
ffffffffc0201de2:	94aa                	add	s1,s1,a0
ffffffffc0201de4:	00048023          	sb	zero,0(s1)
}
ffffffffc0201de8:	70a2                	ld	ra,40(sp)
ffffffffc0201dea:	7402                	ld	s0,32(sp)
ffffffffc0201dec:	64e2                	ld	s1,24(sp)
ffffffffc0201dee:	6942                	ld	s2,16(sp)
ffffffffc0201df0:	69a2                	ld	s3,8(sp)
ffffffffc0201df2:	6145                	addi	sp,sp,48
ffffffffc0201df4:	8082                	ret

ffffffffc0201df6 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201df6:	00004717          	auipc	a4,0x4
ffffffffc0201dfa:	22a73703          	ld	a4,554(a4) # ffffffffc0206020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dfe:	4781                	li	a5,0
ffffffffc0201e00:	88ba                	mv	a7,a4
ffffffffc0201e02:	852a                	mv	a0,a0
ffffffffc0201e04:	85be                	mv	a1,a5
ffffffffc0201e06:	863e                	mv	a2,a5
ffffffffc0201e08:	00000073          	ecall
ffffffffc0201e0c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e0e:	8082                	ret

ffffffffc0201e10 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e10:	00004717          	auipc	a4,0x4
ffffffffc0201e14:	68873703          	ld	a4,1672(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e18:	4781                	li	a5,0
ffffffffc0201e1a:	88ba                	mv	a7,a4
ffffffffc0201e1c:	852a                	mv	a0,a0
ffffffffc0201e1e:	85be                	mv	a1,a5
ffffffffc0201e20:	863e                	mv	a2,a5
ffffffffc0201e22:	00000073          	ecall
ffffffffc0201e26:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e28:	8082                	ret

ffffffffc0201e2a <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e2a:	00004797          	auipc	a5,0x4
ffffffffc0201e2e:	1ee7b783          	ld	a5,494(a5) # ffffffffc0206018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e32:	4501                	li	a0,0
ffffffffc0201e34:	88be                	mv	a7,a5
ffffffffc0201e36:	852a                	mv	a0,a0
ffffffffc0201e38:	85aa                	mv	a1,a0
ffffffffc0201e3a:	862a                	mv	a2,a0
ffffffffc0201e3c:	00000073          	ecall
ffffffffc0201e40:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e42:	2501                	sext.w	a0,a0
ffffffffc0201e44:	8082                	ret

ffffffffc0201e46 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e46:	00004717          	auipc	a4,0x4
ffffffffc0201e4a:	1ca73703          	ld	a4,458(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201e4e:	4781                	li	a5,0
ffffffffc0201e50:	88ba                	mv	a7,a4
ffffffffc0201e52:	853e                	mv	a0,a5
ffffffffc0201e54:	85be                	mv	a1,a5
ffffffffc0201e56:	863e                	mv	a2,a5
ffffffffc0201e58:	00000073          	ecall
ffffffffc0201e5c:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e5e:	8082                	ret

ffffffffc0201e60 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e60:	00054783          	lbu	a5,0(a0)
ffffffffc0201e64:	cb81                	beqz	a5,ffffffffc0201e74 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0201e66:	4781                	li	a5,0
        cnt ++;
ffffffffc0201e68:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201e6a:	00f50733          	add	a4,a0,a5
ffffffffc0201e6e:	00074703          	lbu	a4,0(a4)
ffffffffc0201e72:	fb7d                	bnez	a4,ffffffffc0201e68 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201e74:	853e                	mv	a0,a5
ffffffffc0201e76:	8082                	ret

ffffffffc0201e78 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e78:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e7a:	e589                	bnez	a1,ffffffffc0201e84 <strnlen+0xc>
ffffffffc0201e7c:	a811                	j	ffffffffc0201e90 <strnlen+0x18>
        cnt ++;
ffffffffc0201e7e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e80:	00f58863          	beq	a1,a5,ffffffffc0201e90 <strnlen+0x18>
ffffffffc0201e84:	00f50733          	add	a4,a0,a5
ffffffffc0201e88:	00074703          	lbu	a4,0(a4)
ffffffffc0201e8c:	fb6d                	bnez	a4,ffffffffc0201e7e <strnlen+0x6>
ffffffffc0201e8e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e90:	852e                	mv	a0,a1
ffffffffc0201e92:	8082                	ret

ffffffffc0201e94 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e94:	00054783          	lbu	a5,0(a0)
ffffffffc0201e98:	e791                	bnez	a5,ffffffffc0201ea4 <strcmp+0x10>
ffffffffc0201e9a:	a01d                	j	ffffffffc0201ec0 <strcmp+0x2c>
ffffffffc0201e9c:	00054783          	lbu	a5,0(a0)
ffffffffc0201ea0:	cb99                	beqz	a5,ffffffffc0201eb6 <strcmp+0x22>
ffffffffc0201ea2:	0585                	addi	a1,a1,1 # fffffffffff80001 <end+0x3fd79b61>
ffffffffc0201ea4:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201ea8:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eaa:	fef709e3          	beq	a4,a5,ffffffffc0201e9c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eae:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201eb2:	9d19                	subw	a0,a0,a4
ffffffffc0201eb4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eb6:	0015c703          	lbu	a4,1(a1)
ffffffffc0201eba:	4501                	li	a0,0
}
ffffffffc0201ebc:	9d19                	subw	a0,a0,a4
ffffffffc0201ebe:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ec0:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ec4:	4501                	li	a0,0
ffffffffc0201ec6:	b7f5                	j	ffffffffc0201eb2 <strcmp+0x1e>

ffffffffc0201ec8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ec8:	ce01                	beqz	a2,ffffffffc0201ee0 <strncmp+0x18>
ffffffffc0201eca:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ece:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ed0:	cb91                	beqz	a5,ffffffffc0201ee4 <strncmp+0x1c>
ffffffffc0201ed2:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ed6:	00f71763          	bne	a4,a5,ffffffffc0201ee4 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201eda:	0505                	addi	a0,a0,1
ffffffffc0201edc:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ede:	f675                	bnez	a2,ffffffffc0201eca <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ee0:	4501                	li	a0,0
ffffffffc0201ee2:	8082                	ret
ffffffffc0201ee4:	00054503          	lbu	a0,0(a0)
ffffffffc0201ee8:	0005c783          	lbu	a5,0(a1)
ffffffffc0201eec:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201eee:	8082                	ret

ffffffffc0201ef0 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201ef0:	a021                	j	ffffffffc0201ef8 <strchr+0x8>
        if (*s == c) {
ffffffffc0201ef2:	00f58763          	beq	a1,a5,ffffffffc0201f00 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0201ef6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201ef8:	00054783          	lbu	a5,0(a0)
ffffffffc0201efc:	fbfd                	bnez	a5,ffffffffc0201ef2 <strchr+0x2>
    }
    return NULL;
ffffffffc0201efe:	4501                	li	a0,0
}
ffffffffc0201f00:	8082                	ret

ffffffffc0201f02 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f02:	ca01                	beqz	a2,ffffffffc0201f12 <memset+0x10>
ffffffffc0201f04:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f06:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f08:	0785                	addi	a5,a5,1
ffffffffc0201f0a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f0e:	fef61de3          	bne	a2,a5,ffffffffc0201f08 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f12:	8082                	ret
