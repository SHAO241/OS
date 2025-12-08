
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00097517          	auipc	a0,0x97
ffffffffc020004e:	28e50513          	addi	a0,a0,654 # ffffffffc02972d8 <buf>
ffffffffc0200052:	0009b617          	auipc	a2,0x9b
ffffffffc0200056:	73660613          	addi	a2,a2,1846 # ffffffffc029b788 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7b4050ef          	jal	ffffffffc0205816 <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	7d258593          	addi	a1,a1,2002 # ffffffffc0205840 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	7ea50513          	addi	a0,a0,2026 # ffffffffc0205860 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6fc020ef          	jal	ffffffffc0202782 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	1e9030ef          	jal	ffffffffc0203a7a <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	6cb040ef          	jal	ffffffffc0204f60 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	05e050ef          	jal	ffffffffc0205100 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00005517          	auipc	a0,0x5
ffffffffc02000ba:	7b250513          	addi	a0,a0,1970 # ffffffffc0205868 <etext+0x28>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00097997          	auipc	s3,0x97
ffffffffc02000ca:	21298993          	addi	s3,s3,530 # ffffffffc02972d8 <buf>
        c = getchar();
ffffffffc02000ce:	148000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	11a000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00097517          	auipc	a0,0x97
ffffffffc0200144:	19850513          	addi	a0,a0,408 # ffffffffc02972d8 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	3e6000ef          	jal	ffffffffc0200548 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	274050ef          	jal	ffffffffc02053fc <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	240050ef          	jal	ffffffffc02053fc <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	a641                	j	ffffffffc0200548 <cons_putc>

ffffffffc02001ca <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ca:	1101                	addi	sp,sp,-32
ffffffffc02001cc:	e822                	sd	s0,16(sp)
ffffffffc02001ce:	ec06                	sd	ra,24(sp)
ffffffffc02001d0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d2:	00054503          	lbu	a0,0(a0)
ffffffffc02001d6:	c51d                	beqz	a0,ffffffffc0200204 <cputs+0x3a>
ffffffffc02001d8:	e426                	sd	s1,8(sp)
ffffffffc02001da:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001dc:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001de:	36a000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e2:	00044503          	lbu	a0,0(s0)
ffffffffc02001e6:	0405                	addi	s0,s0,1
ffffffffc02001e8:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ea:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001ec:	f96d                	bnez	a0,ffffffffc02001de <cputs+0x14>
    cons_putc(c);
ffffffffc02001ee:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f0:	0027841b          	addiw	s0,a5,2
ffffffffc02001f4:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001f6:	352000ef          	jal	ffffffffc0200548 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret
    cons_putc(c);
ffffffffc0200204:	4529                	li	a0,10
ffffffffc0200206:	342000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020a:	4405                	li	s0,1
}
ffffffffc020020c:	60e2                	ld	ra,24(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	6442                	ld	s0,16(sp)
ffffffffc0200212:	6105                	addi	sp,sp,32
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200216:	1141                	addi	sp,sp,-16
ffffffffc0200218:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021a:	362000ef          	jal	ffffffffc020057c <cons_getc>
ffffffffc020021e:	dd75                	beqz	a0,ffffffffc020021a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	0141                	addi	sp,sp,16
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc0200226:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	00005517          	auipc	a0,0x5
ffffffffc020022c:	64850513          	addi	a0,a0,1608 # ffffffffc0205870 <etext+0x30>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	65250513          	addi	a0,a0,1618 # ffffffffc0205890 <etext+0x50>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	5f658593          	addi	a1,a1,1526 # ffffffffc0205840 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	65e50513          	addi	a0,a0,1630 # ffffffffc02058b0 <etext+0x70>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	07a58593          	addi	a1,a1,122 # ffffffffc02972d8 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	66a50513          	addi	a0,a0,1642 # ffffffffc02058d0 <etext+0x90>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	51658593          	addi	a1,a1,1302 # ffffffffc029b788 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	67650513          	addi	a0,a0,1654 # ffffffffc02058f0 <etext+0xb0>
ffffffffc0200282:	f13ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200286:	00000717          	auipc	a4,0x0
ffffffffc020028a:	dc470713          	addi	a4,a4,-572 # ffffffffc020004a <kern_init>
ffffffffc020028e:	0009c797          	auipc	a5,0x9c
ffffffffc0200292:	8f978793          	addi	a5,a5,-1799 # ffffffffc029bb87 <end+0x3ff>
ffffffffc0200296:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	66a50513          	addi	a0,a0,1642 # ffffffffc0205910 <etext+0xd0>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	b5d5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	68c60613          	addi	a2,a2,1676 # ffffffffc0205940 <etext+0x100>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	69850513          	addi	a0,a0,1688 # ffffffffc0205958 <etext+0x118>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	17c000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002ce:	1101                	addi	sp,sp,-32
ffffffffc02002d0:	e822                	sd	s0,16(sp)
ffffffffc02002d2:	e426                	sd	s1,8(sp)
ffffffffc02002d4:	ec06                	sd	ra,24(sp)
ffffffffc02002d6:	00007417          	auipc	s0,0x7
ffffffffc02002da:	2c240413          	addi	s0,s0,706 # ffffffffc0207598 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	30248493          	addi	s1,s1,770 # ffffffffc02075e0 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	68650513          	addi	a0,a0,1670 # ffffffffc0205970 <etext+0x130>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f2:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f4:	ea1ff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f8:	fe9417e3          	bne	s0,s1,ffffffffc02002e6 <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002fc:	60e2                	ld	ra,24(sp)
ffffffffc02002fe:	6442                	ld	s0,16(sp)
ffffffffc0200300:	64a2                	ld	s1,8(sp)
ffffffffc0200302:	4501                	li	a0,0
ffffffffc0200304:	6105                	addi	sp,sp,32
ffffffffc0200306:	8082                	ret

ffffffffc0200308 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200308:	1141                	addi	sp,sp,-16
ffffffffc020030a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030c:	f1bff0ef          	jal	ffffffffc0200226 <print_kerninfo>
    return 0;
}
ffffffffc0200310:	60a2                	ld	ra,8(sp)
ffffffffc0200312:	4501                	li	a0,0
ffffffffc0200314:	0141                	addi	sp,sp,16
ffffffffc0200316:	8082                	ret

ffffffffc0200318 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200318:	1141                	addi	sp,sp,-16
ffffffffc020031a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031c:	f97ff0ef          	jal	ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200320:	60a2                	ld	ra,8(sp)
ffffffffc0200322:	4501                	li	a0,0
ffffffffc0200324:	0141                	addi	sp,sp,16
ffffffffc0200326:	8082                	ret

ffffffffc0200328 <kmonitor>:
{
ffffffffc0200328:	7131                	addi	sp,sp,-192
ffffffffc020032a:	e952                	sd	s4,144(sp)
ffffffffc020032c:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032e:	00005517          	auipc	a0,0x5
ffffffffc0200332:	65250513          	addi	a0,a0,1618 # ffffffffc0205980 <etext+0x140>
{
ffffffffc0200336:	fd06                	sd	ra,184(sp)
ffffffffc0200338:	f922                	sd	s0,176(sp)
ffffffffc020033a:	f526                	sd	s1,168(sp)
ffffffffc020033c:	ed4e                	sd	s3,152(sp)
ffffffffc020033e:	e556                	sd	s5,136(sp)
ffffffffc0200340:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	e53ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200346:	00005517          	auipc	a0,0x5
ffffffffc020034a:	66250513          	addi	a0,a0,1634 # ffffffffc02059a8 <etext+0x168>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	23ca8a93          	addi	s5,s5,572 # ffffffffc0207598 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	66a50513          	addi	a0,a0,1642 # ffffffffc02059d0 <etext+0x190>
ffffffffc020036e:	d39ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200372:	842a                	mv	s0,a0
ffffffffc0200374:	d96d                	beqz	a0,ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200376:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020037c:	e99d                	bnez	a1,ffffffffc02003b2 <kmonitor+0x8a>
    int argc = 0;
ffffffffc020037e:	8b26                	mv	s6,s1
    if (argc == 0)
ffffffffc0200380:	fe0b03e3          	beqz	s6,ffffffffc0200366 <kmonitor+0x3e>
ffffffffc0200384:	00007497          	auipc	s1,0x7
ffffffffc0200388:	21448493          	addi	s1,s1,532 # ffffffffc0207598 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	416050ef          	jal	ffffffffc02057a8 <strcmp>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200396:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200398:	c149                	beqz	a0,ffffffffc020041a <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	04e1                	addi	s1,s1,24
ffffffffc020039e:	fef418e3          	bne	s0,a5,ffffffffc020038e <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a2:	6582                	ld	a1,0(sp)
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	65c50513          	addi	a0,a0,1628 # ffffffffc0205a00 <etext+0x1c0>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	62650513          	addi	a0,a0,1574 # ffffffffc02059d8 <etext+0x198>
ffffffffc02003ba:	44a050ef          	jal	ffffffffc0205804 <strchr>
ffffffffc02003be:	c901                	beqz	a0,ffffffffc02003ce <kmonitor+0xa6>
ffffffffc02003c0:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02003c4:	00040023          	sb	zero,0(s0)
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ca:	d9d5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003cc:	b7dd                	j	ffffffffc02003b2 <kmonitor+0x8a>
        if (*buf == '\0')
ffffffffc02003ce:	00044783          	lbu	a5,0(s0)
ffffffffc02003d2:	d7d5                	beqz	a5,ffffffffc020037e <kmonitor+0x56>
        if (argc == MAXARGS - 1)
ffffffffc02003d4:	03348b63          	beq	s1,s3,ffffffffc020040a <kmonitor+0xe2>
        argv[argc++] = buf;
ffffffffc02003d8:	00349793          	slli	a5,s1,0x3
ffffffffc02003dc:	978a                	add	a5,a5,sp
ffffffffc02003de:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e0:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02003e4:	2485                	addiw	s1,s1,1
ffffffffc02003e6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e8:	e591                	bnez	a1,ffffffffc02003f4 <kmonitor+0xcc>
ffffffffc02003ea:	bf59                	j	ffffffffc0200380 <kmonitor+0x58>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003f2:	d5d1                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003f4:	00005517          	auipc	a0,0x5
ffffffffc02003f8:	5e450513          	addi	a0,a0,1508 # ffffffffc02059d8 <etext+0x198>
ffffffffc02003fc:	408050ef          	jal	ffffffffc0205804 <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	5d450513          	addi	a0,a0,1492 # ffffffffc02059e0 <etext+0x1a0>
ffffffffc0200414:	d81ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200418:	b7c1                	j	ffffffffc02003d8 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97d6                	add	a5,a5,s5
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042a:	8652                	mv	a2,s4
ffffffffc020042c:	002c                	addi	a1,sp,8
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200430:	f2055be3          	bgez	a0,ffffffffc0200366 <kmonitor+0x3e>
}
ffffffffc0200434:	70ea                	ld	ra,184(sp)
ffffffffc0200436:	744a                	ld	s0,176(sp)
ffffffffc0200438:	74aa                	ld	s1,168(sp)
ffffffffc020043a:	69ea                	ld	s3,152(sp)
ffffffffc020043c:	6a4a                	ld	s4,144(sp)
ffffffffc020043e:	6aaa                	ld	s5,136(sp)
ffffffffc0200440:	6b0a                	ld	s6,128(sp)
ffffffffc0200442:	6129                	addi	sp,sp,192
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc0200446:	0009b317          	auipc	t1,0x9b
ffffffffc020044a:	2ba33303          	ld	t1,698(t1) # ffffffffc029b700 <is_panic>
{
ffffffffc020044e:	715d                	addi	sp,sp,-80
ffffffffc0200450:	ec06                	sd	ra,24(sp)
ffffffffc0200452:	f436                	sd	a3,40(sp)
ffffffffc0200454:	f83a                	sd	a4,48(sp)
ffffffffc0200456:	fc3e                	sd	a5,56(sp)
ffffffffc0200458:	e0c2                	sd	a6,64(sp)
ffffffffc020045a:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020045c:	02031e63          	bnez	t1,ffffffffc0200498 <__panic+0x52>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200460:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200462:	103c                	addi	a5,sp,40
ffffffffc0200464:	e822                	sd	s0,16(sp)
ffffffffc0200466:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200468:	862e                	mv	a2,a1
ffffffffc020046a:	85aa                	mv	a1,a0
ffffffffc020046c:	00005517          	auipc	a0,0x5
ffffffffc0200470:	63c50513          	addi	a0,a0,1596 # ffffffffc0205aa8 <etext+0x268>
    is_panic = 1;
ffffffffc0200474:	0009b697          	auipc	a3,0x9b
ffffffffc0200478:	28e6b623          	sd	a4,652(a3) # ffffffffc029b700 <is_panic>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00005517          	auipc	a0,0x5
ffffffffc020048e:	63e50513          	addi	a0,a0,1598 # ffffffffc0205ac8 <etext+0x288>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200498:	4501                	li	a0,0
ffffffffc020049a:	4581                	li	a1,0
ffffffffc020049c:	4601                	li	a2,0
ffffffffc020049e:	48a1                	li	a7,8
ffffffffc02004a0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a4:	460000ef          	jal	ffffffffc0200904 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e7fff0ef          	jal	ffffffffc0200328 <kmonitor>
    while (1)
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x62>

ffffffffc02004b0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004b0:	715d                	addi	sp,sp,-80
ffffffffc02004b2:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	02810313          	addi	t1,sp,40
{
ffffffffc02004b8:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ba:	862e                	mv	a2,a1
ffffffffc02004bc:	85aa                	mv	a1,a0
ffffffffc02004be:	00005517          	auipc	a0,0x5
ffffffffc02004c2:	61250513          	addi	a0,a0,1554 # ffffffffc0205ad0 <etext+0x290>
{
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
ffffffffc02004c8:	f436                	sd	a3,40(sp)
ffffffffc02004ca:	f83a                	sd	a4,48(sp)
ffffffffc02004cc:	fc3e                	sd	a5,56(sp)
ffffffffc02004ce:	e0c2                	sd	a6,64(sp)
ffffffffc02004d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d2:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d4:	cc1ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004d8:	65a2                	ld	a1,8(sp)
ffffffffc02004da:	8522                	mv	a0,s0
ffffffffc02004dc:	c99ff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004e0:	00005517          	auipc	a0,0x5
ffffffffc02004e4:	5e850513          	addi	a0,a0,1512 # ffffffffc0205ac8 <etext+0x288>
ffffffffc02004e8:	cadff0ef          	jal	ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6442                	ld	s0,16(sp)
ffffffffc02004f0:	6161                	addi	sp,sp,80
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f4:	67e1                	lui	a5,0x18
ffffffffc02004f6:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xe4c8>
ffffffffc02004fa:	0009b717          	auipc	a4,0x9b
ffffffffc02004fe:	20f73723          	sd	a5,526(a4) # ffffffffc029b708 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200502:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200506:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200508:	953e                	add	a0,a0,a5
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4881                	li	a7,0
ffffffffc020050e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200512:	02000793          	li	a5,32
ffffffffc0200516:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051a:	00005517          	auipc	a0,0x5
ffffffffc020051e:	5d650513          	addi	a0,a0,1494 # ffffffffc0205af0 <etext+0x2b0>
    ticks = 0;
ffffffffc0200522:	0009b797          	auipc	a5,0x9b
ffffffffc0200526:	1e07b723          	sd	zero,494(a5) # ffffffffc029b710 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	b1ad                	j	ffffffffc0200194 <cprintf>

ffffffffc020052c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200530:	0009b797          	auipc	a5,0x9b
ffffffffc0200534:	1d87b783          	ld	a5,472(a5) # ffffffffc029b708 <timebase>
ffffffffc0200538:	4581                	li	a1,0
ffffffffc020053a:	4601                	li	a2,0
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	8082                	ret

ffffffffc0200546 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200546:	8082                	ret

ffffffffc0200548 <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200548:	100027f3          	csrr	a5,sstatus
ffffffffc020054c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020054e:	0ff57513          	zext.b	a0,a0
ffffffffc0200552:	e799                	bnez	a5,ffffffffc0200560 <cons_putc+0x18>
ffffffffc0200554:	4581                	li	a1,0
ffffffffc0200556:	4601                	li	a2,0
ffffffffc0200558:	4885                	li	a7,1
ffffffffc020055a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020055e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200560:	1101                	addi	sp,sp,-32
ffffffffc0200562:	ec06                	sd	ra,24(sp)
ffffffffc0200564:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200566:	39e000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020056a:	6522                	ld	a0,8(sp)
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4885                	li	a7,1
ffffffffc0200572:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200576:	60e2                	ld	ra,24(sp)
ffffffffc0200578:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020057a:	a651                	j	ffffffffc02008fe <intr_enable>

ffffffffc020057c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020057c:	100027f3          	csrr	a5,sstatus
ffffffffc0200580:	8b89                	andi	a5,a5,2
ffffffffc0200582:	eb89                	bnez	a5,ffffffffc0200594 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4889                	li	a7,2
ffffffffc020058c:	00000073          	ecall
ffffffffc0200590:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200592:	8082                	ret
int cons_getc(void) {
ffffffffc0200594:	1101                	addi	sp,sp,-32
ffffffffc0200596:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200598:	36c000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020059c:	4501                	li	a0,0
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4889                	li	a7,2
ffffffffc02005a4:	00000073          	ecall
ffffffffc02005a8:	2501                	sext.w	a0,a0
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ac:	352000ef          	jal	ffffffffc02008fe <intr_enable>
}
ffffffffc02005b0:	60e2                	ld	ra,24(sp)
ffffffffc02005b2:	6522                	ld	a0,8(sp)
ffffffffc02005b4:	6105                	addi	sp,sp,32
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b8:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	55650513          	addi	a0,a0,1366 # ffffffffc0205b10 <etext+0x2d0>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	54e50513          	addi	a0,a0,1358 # ffffffffc0205b20 <etext+0x2e0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	54850513          	addi	a0,a0,1352 # ffffffffc0205b30 <etext+0x2f0>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	55250513          	addi	a0,a0,1362 # ffffffffc0205b48 <etext+0x308>
    if (boot_dtb == 0) {
ffffffffc02005fe:	10070163          	beqz	a4,ffffffffc0200700 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200602:	57f5                	li	a5,-3
ffffffffc0200604:	07fa                	slli	a5,a5,0x1e
ffffffffc0200606:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200608:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020060a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020060e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe44765>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200616:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8e49                	or	a2,a2,a0
ffffffffc020062a:	0ff7f793          	zext.b	a5,a5
ffffffffc020062e:	8dd1                	or	a1,a1,a2
ffffffffc0200630:	07a2                	slli	a5,a5,0x8
ffffffffc0200632:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200638:	0cd59863          	bne	a1,a3,ffffffffc0200708 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020063c:	4710                	lw	a2,8(a4)
ffffffffc020063e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200646:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020064e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200656:	0186959b          	slliw	a1,a3,0x18
ffffffffc020065a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020066a:	01c56533          	or	a0,a0,t3
ffffffffc020066e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200682:	8c49                	or	s0,s0,a0
ffffffffc0200684:	0622                	slli	a2,a2,0x8
ffffffffc0200686:	8fcd                	or	a5,a5,a1
ffffffffc0200688:	06a2                	slli	a3,a3,0x8
ffffffffc020068a:	8c51                	or	s0,s0,a2
ffffffffc020068c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200690:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200692:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200694:	9381                	srli	a5,a5,0x20
ffffffffc0200696:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200698:	4301                	li	t1,0
        switch (token) {
ffffffffc020069a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020069c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020069e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc02006a2:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a4:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006aa:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	8ed1                	or	a3,a3,a2
ffffffffc02006c0:	0ff77713          	zext.b	a4,a4
ffffffffc02006c4:	8fd5                	or	a5,a5,a3
ffffffffc02006c6:	0722                	slli	a4,a4,0x8
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006ca:	05178763          	beq	a5,a7,ffffffffc0200718 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ce:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006d0:	00f8e963          	bltu	a7,a5,ffffffffc02006e2 <dtb_init+0x12a>
ffffffffc02006d4:	07c78d63          	beq	a5,t3,ffffffffc020074e <dtb_init+0x196>
ffffffffc02006d8:	4709                	li	a4,2
ffffffffc02006da:	00e79763          	bne	a5,a4,ffffffffc02006e8 <dtb_init+0x130>
ffffffffc02006de:	4301                	li	t1,0
ffffffffc02006e0:	b7d1                	j	ffffffffc02006a4 <dtb_init+0xec>
ffffffffc02006e2:	4711                	li	a4,4
ffffffffc02006e4:	fce780e3          	beq	a5,a4,ffffffffc02006a4 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e8:	00005517          	auipc	a0,0x5
ffffffffc02006ec:	52850513          	addi	a0,a0,1320 # ffffffffc0205c10 <etext+0x3d0>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	55050513          	addi	a0,a0,1360 # ffffffffc0205c48 <etext+0x408>
}
ffffffffc0200700:	7402                	ld	s0,32(sp)
ffffffffc0200702:	70a2                	ld	ra,40(sp)
ffffffffc0200704:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200706:	b479                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200708:	7402                	ld	s0,32(sp)
ffffffffc020070a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020070c:	00005517          	auipc	a0,0x5
ffffffffc0200710:	45c50513          	addi	a0,a0,1116 # ffffffffc0205b68 <etext+0x328>
}
ffffffffc0200714:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200716:	bcbd                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200718:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020071e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	8ed1                	or	a3,a3,a2
ffffffffc0200734:	0ff77713          	zext.b	a4,a4
ffffffffc0200738:	8fd5                	or	a5,a5,a3
ffffffffc020073a:	0722                	slli	a4,a4,0x8
ffffffffc020073c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020073e:	04031463          	bnez	t1,ffffffffc0200786 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200742:	1782                	slli	a5,a5,0x20
ffffffffc0200744:	9381                	srli	a5,a5,0x20
ffffffffc0200746:	043d                	addi	s0,s0,15
ffffffffc0200748:	943e                	add	s0,s0,a5
ffffffffc020074a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020074c:	bfa1                	j	ffffffffc02006a4 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020074e:	8522                	mv	a0,s0
ffffffffc0200750:	e01a                	sd	t1,0(sp)
ffffffffc0200752:	010050ef          	jal	ffffffffc0205762 <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	43458593          	addi	a1,a1,1076 # ffffffffc0205b90 <etext+0x350>
ffffffffc0200764:	078050ef          	jal	ffffffffc02057dc <strncmp>
ffffffffc0200768:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020076a:	0411                	addi	s0,s0,4
ffffffffc020076c:	0004879b          	sext.w	a5,s1
ffffffffc0200770:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200776:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200778:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020077c:	00ff0837          	lui	a6,0xff0
ffffffffc0200780:	488d                	li	a7,3
ffffffffc0200782:	4e05                	li	t3,1
ffffffffc0200784:	b705                	j	ffffffffc02006a4 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200786:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200788:	00005597          	auipc	a1,0x5
ffffffffc020078c:	41058593          	addi	a1,a1,1040 # ffffffffc0205b98 <etext+0x358>
ffffffffc0200790:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200792:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200796:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020079e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	8ed1                	or	a3,a3,a2
ffffffffc02007ac:	0ff77713          	zext.b	a4,a4
ffffffffc02007b0:	0722                	slli	a4,a4,0x8
ffffffffc02007b2:	8d55                	or	a0,a0,a3
ffffffffc02007b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b6:	1502                	slli	a0,a0,0x20
ffffffffc02007b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	954a                	add	a0,a0,s2
ffffffffc02007bc:	e01a                	sd	t1,0(sp)
ffffffffc02007be:	7eb040ef          	jal	ffffffffc02057a8 <strcmp>
ffffffffc02007c2:	67a2                	ld	a5,8(sp)
ffffffffc02007c4:	473d                	li	a4,15
ffffffffc02007c6:	6302                	ld	t1,0(sp)
ffffffffc02007c8:	00ff0837          	lui	a6,0xff0
ffffffffc02007cc:	488d                	li	a7,3
ffffffffc02007ce:	4e05                	li	t3,1
ffffffffc02007d0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200742 <dtb_init+0x18a>
ffffffffc02007d4:	f53d                	bnez	a0,ffffffffc0200742 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	3c250513          	addi	a0,a0,962 # ffffffffc0205ba0 <etext+0x360>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ea:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007ee:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007fe:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200802:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	01037333          	and	t1,t1,a6
ffffffffc0200812:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200816:	01e5e5b3          	or	a1,a1,t5
ffffffffc020081a:	0ff7f793          	zext.b	a5,a5
ffffffffc020081e:	01de6e33          	or	t3,t3,t4
ffffffffc0200822:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200826:	01067633          	and	a2,a2,a6
ffffffffc020082a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020082e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	07a2                	slli	a5,a5,0x8
ffffffffc0200834:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200838:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020083c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200840:	8ddd                	or	a1,a1,a5
ffffffffc0200842:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200846:	0186979b          	slliw	a5,a3,0x18
ffffffffc020084a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	08a2                	slli	a7,a7,0x8
ffffffffc0200868:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200870:	0ff6f693          	zext.b	a3,a3
ffffffffc0200874:	01de6833          	or	a6,t3,t4
ffffffffc0200878:	0ff77713          	zext.b	a4,a4
ffffffffc020087c:	01166633          	or	a2,a2,a7
ffffffffc0200880:	0067e7b3          	or	a5,a5,t1
ffffffffc0200884:	06a2                	slli	a3,a3,0x8
ffffffffc0200886:	01046433          	or	s0,s0,a6
ffffffffc020088a:	0722                	slli	a4,a4,0x8
ffffffffc020088c:	8fd5                	or	a5,a5,a3
ffffffffc020088e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200896:	9201                	srli	a2,a2,0x20
ffffffffc0200898:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089a:	1402                	slli	s0,s0,0x20
ffffffffc020089c:	00b7e4b3          	or	s1,a5,a1
ffffffffc02008a0:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008a2:	8f3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a6:	85a6                	mv	a1,s1
ffffffffc02008a8:	00005517          	auipc	a0,0x5
ffffffffc02008ac:	31850513          	addi	a0,a0,792 # ffffffffc0205bc0 <etext+0x380>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	31e50513          	addi	a0,a0,798 # ffffffffc0205bd8 <etext+0x398>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	32c50513          	addi	a0,a0,812 # ffffffffc0205bf8 <etext+0x3b8>
ffffffffc02008d4:	8c1ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008d8:	0009b797          	auipc	a5,0x9b
ffffffffc02008dc:	e497b423          	sd	s1,-440(a5) # ffffffffc029b720 <memory_base>
        memory_size = mem_size;
ffffffffc02008e0:	0009b797          	auipc	a5,0x9b
ffffffffc02008e4:	e287bc23          	sd	s0,-456(a5) # ffffffffc029b718 <memory_size>
ffffffffc02008e8:	b531                	j	ffffffffc02006f4 <dtb_init+0x13c>

ffffffffc02008ea <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008ea:	0009b517          	auipc	a0,0x9b
ffffffffc02008ee:	e3653503          	ld	a0,-458(a0) # ffffffffc029b720 <memory_base>
ffffffffc02008f2:	8082                	ret

ffffffffc02008f4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008f4:	0009b517          	auipc	a0,0x9b
ffffffffc02008f8:	e2453503          	ld	a0,-476(a0) # ffffffffc029b718 <memory_size>
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200904:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200908:	8082                	ret

ffffffffc020090a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020090c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200910:	00000797          	auipc	a5,0x0
ffffffffc0200914:	4f878793          	addi	a5,a5,1272 # ffffffffc0200e08 <__alltraps>
ffffffffc0200918:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020091c:	000407b7          	lui	a5,0x40
ffffffffc0200920:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200924:	8082                	ret

ffffffffc0200926 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200926:	610c                	ld	a1,0(a0)
{
ffffffffc0200928:	1141                	addi	sp,sp,-16
ffffffffc020092a:	e022                	sd	s0,0(sp)
ffffffffc020092c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	33250513          	addi	a0,a0,818 # ffffffffc0205c60 <etext+0x420>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	33a50513          	addi	a0,a0,826 # ffffffffc0205c78 <etext+0x438>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	34450513          	addi	a0,a0,836 # ffffffffc0205c90 <etext+0x450>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	34e50513          	addi	a0,a0,846 # ffffffffc0205ca8 <etext+0x468>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	35850513          	addi	a0,a0,856 # ffffffffc0205cc0 <etext+0x480>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	36250513          	addi	a0,a0,866 # ffffffffc0205cd8 <etext+0x498>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	36c50513          	addi	a0,a0,876 # ffffffffc0205cf0 <etext+0x4b0>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	37650513          	addi	a0,a0,886 # ffffffffc0205d08 <etext+0x4c8>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	38050513          	addi	a0,a0,896 # ffffffffc0205d20 <etext+0x4e0>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	38a50513          	addi	a0,a0,906 # ffffffffc0205d38 <etext+0x4f8>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	39450513          	addi	a0,a0,916 # ffffffffc0205d50 <etext+0x510>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	39e50513          	addi	a0,a0,926 # ffffffffc0205d68 <etext+0x528>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	3a850513          	addi	a0,a0,936 # ffffffffc0205d80 <etext+0x540>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	3b250513          	addi	a0,a0,946 # ffffffffc0205d98 <etext+0x558>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	3bc50513          	addi	a0,a0,956 # ffffffffc0205db0 <etext+0x570>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	3c650513          	addi	a0,a0,966 # ffffffffc0205dc8 <etext+0x588>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	3d050513          	addi	a0,a0,976 # ffffffffc0205de0 <etext+0x5a0>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	3da50513          	addi	a0,a0,986 # ffffffffc0205df8 <etext+0x5b8>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	3e450513          	addi	a0,a0,996 # ffffffffc0205e10 <etext+0x5d0>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205e28 <etext+0x5e8>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	3f850513          	addi	a0,a0,1016 # ffffffffc0205e40 <etext+0x600>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	40250513          	addi	a0,a0,1026 # ffffffffc0205e58 <etext+0x618>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	40c50513          	addi	a0,a0,1036 # ffffffffc0205e70 <etext+0x630>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	41650513          	addi	a0,a0,1046 # ffffffffc0205e88 <etext+0x648>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	42050513          	addi	a0,a0,1056 # ffffffffc0205ea0 <etext+0x660>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	42a50513          	addi	a0,a0,1066 # ffffffffc0205eb8 <etext+0x678>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	43450513          	addi	a0,a0,1076 # ffffffffc0205ed0 <etext+0x690>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	43e50513          	addi	a0,a0,1086 # ffffffffc0205ee8 <etext+0x6a8>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	44850513          	addi	a0,a0,1096 # ffffffffc0205f00 <etext+0x6c0>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	45250513          	addi	a0,a0,1106 # ffffffffc0205f18 <etext+0x6d8>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	45c50513          	addi	a0,a0,1116 # ffffffffc0205f30 <etext+0x6f0>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	46250513          	addi	a0,a0,1122 # ffffffffc0205f48 <etext+0x708>
}
ffffffffc0200aee:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af0:	ea4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200af4 <print_trapframe>:
{
ffffffffc0200af4:	1141                	addi	sp,sp,-16
ffffffffc0200af6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af8:	85aa                	mv	a1,a0
{
ffffffffc0200afa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200afc:	00005517          	auipc	a0,0x5
ffffffffc0200b00:	46450513          	addi	a0,a0,1124 # ffffffffc0205f60 <etext+0x720>
{
ffffffffc0200b04:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b06:	e8eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b0a:	8522                	mv	a0,s0
ffffffffc0200b0c:	e1bff0ef          	jal	ffffffffc0200926 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b10:	10043583          	ld	a1,256(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	46450513          	addi	a0,a0,1124 # ffffffffc0205f78 <etext+0x738>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	46c50513          	addi	a0,a0,1132 # ffffffffc0205f90 <etext+0x750>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	47450513          	addi	a0,a0,1140 # ffffffffc0205fa8 <etext+0x768>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	47050513          	addi	a0,a0,1136 # ffffffffc0205fb8 <etext+0x778>
}
ffffffffc0200b50:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	e42ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b56 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b56:	11853783          	ld	a5,280(a0)
ffffffffc0200b5a:	472d                	li	a4,11
ffffffffc0200b5c:	0786                	slli	a5,a5,0x1
ffffffffc0200b5e:	8385                	srli	a5,a5,0x1
ffffffffc0200b60:	08f76d63          	bltu	a4,a5,ffffffffc0200bfa <interrupt_handler+0xa4>
ffffffffc0200b64:	00007717          	auipc	a4,0x7
ffffffffc0200b68:	a7c70713          	addi	a4,a4,-1412 # ffffffffc02075e0 <commands+0x48>
ffffffffc0200b6c:	078a                	slli	a5,a5,0x2
ffffffffc0200b6e:	97ba                	add	a5,a5,a4
ffffffffc0200b70:	439c                	lw	a5,0(a5)
ffffffffc0200b72:	97ba                	add	a5,a5,a4
ffffffffc0200b74:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206030 <etext+0x7f0>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	48e50513          	addi	a0,a0,1166 # ffffffffc0206010 <etext+0x7d0>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	44250513          	addi	a0,a0,1090 # ffffffffc0205fd0 <etext+0x790>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	45650513          	addi	a0,a0,1110 # ffffffffc0205ff0 <etext+0x7b0>
ffffffffc0200ba2:	df2ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200ba6:	1141                	addi	sp,sp,-16
ffffffffc0200ba8:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
       clock_set_next_event(); // (1) 设置下一次时钟中断
ffffffffc0200baa:	983ff0ef          	jal	ffffffffc020052c <clock_set_next_event>
        ticks++;                // (2) 计数器加一
ffffffffc0200bae:	0009b797          	auipc	a5,0x9b
ffffffffc0200bb2:	b6278793          	addi	a5,a5,-1182 # ffffffffc029b710 <ticks>
ffffffffc0200bb6:	6394                	ld	a3,0(a5)
        if (ticks % TICK_NUM == 0) 
ffffffffc0200bb8:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200bbc:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_exit_out_size+0x28f520b7>
        ticks++;                // (2) 计数器加一
ffffffffc0200bc0:	0685                	addi	a3,a3,1
ffffffffc0200bc2:	e394                	sd	a3,0(a5)
        if (ticks % TICK_NUM == 0) 
ffffffffc0200bc4:	6390                	ld	a2,0(a5)
ffffffffc0200bc6:	5c28f6b7          	lui	a3,0x5c28f
ffffffffc0200bca:	1702                	slli	a4,a4,0x20
ffffffffc0200bcc:	5c368693          	addi	a3,a3,1475 # 5c28f5c3 <_binary_obj___user_exit_out_size+0x5c2853eb>
ffffffffc0200bd0:	00265793          	srli	a5,a2,0x2
ffffffffc0200bd4:	9736                	add	a4,a4,a3
ffffffffc0200bd6:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200bda:	06400593          	li	a1,100
ffffffffc0200bde:	8389                	srli	a5,a5,0x2
ffffffffc0200be0:	02b787b3          	mul	a5,a5,a1
ffffffffc0200be4:	00f60c63          	beq	a2,a5,ffffffffc0200bfc <interrupt_handler+0xa6>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200be8:	60a2                	ld	ra,8(sp)
ffffffffc0200bea:	0141                	addi	sp,sp,16
ffffffffc0200bec:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bee:	00005517          	auipc	a0,0x5
ffffffffc0200bf2:	47250513          	addi	a0,a0,1138 # ffffffffc0206060 <etext+0x820>
ffffffffc0200bf6:	d9eff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bfa:	bded                	j	ffffffffc0200af4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200bfc:	00005517          	auipc	a0,0x5
ffffffffc0200c00:	45450513          	addi	a0,a0,1108 # ffffffffc0206050 <etext+0x810>
ffffffffc0200c04:	d90ff0ef          	jal	ffffffffc0200194 <cprintf>
            print_counts++;     // (4) 打印次数加一
ffffffffc0200c08:	0009b797          	auipc	a5,0x9b
ffffffffc0200c0c:	b207a783          	lw	a5,-1248(a5) # ffffffffc029b728 <print_counts>
            if (print_counts == 10)
ffffffffc0200c10:	4729                	li	a4,10
            print_counts++;     // (4) 打印次数加一
ffffffffc0200c12:	2785                	addiw	a5,a5,1
ffffffffc0200c14:	0009b697          	auipc	a3,0x9b
ffffffffc0200c18:	b0f6aa23          	sw	a5,-1260(a3) # ffffffffc029b728 <print_counts>
            if (print_counts == 10)
ffffffffc0200c1c:	fce796e3          	bne	a5,a4,ffffffffc0200be8 <interrupt_handler+0x92>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c20:	4501                	li	a0,0
ffffffffc0200c22:	4581                	li	a1,0
ffffffffc0200c24:	4601                	li	a2,0
ffffffffc0200c26:	48a1                	li	a7,8
ffffffffc0200c28:	00000073          	ecall
}
ffffffffc0200c2c:	bf75                	j	ffffffffc0200be8 <interrupt_handler+0x92>

ffffffffc0200c2e <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c2e:	11853783          	ld	a5,280(a0)
ffffffffc0200c32:	473d                	li	a4,15
ffffffffc0200c34:	14f76763          	bltu	a4,a5,ffffffffc0200d82 <exception_handler+0x154>
ffffffffc0200c38:	00007717          	auipc	a4,0x7
ffffffffc0200c3c:	9d870713          	addi	a4,a4,-1576 # ffffffffc0207610 <commands+0x78>
ffffffffc0200c40:	078a                	slli	a5,a5,0x2
ffffffffc0200c42:	97ba                	add	a5,a5,a4
ffffffffc0200c44:	439c                	lw	a5,0(a5)
{
ffffffffc0200c46:	1101                	addi	sp,sp,-32
ffffffffc0200c48:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c4a:	97ba                	add	a5,a5,a4
ffffffffc0200c4c:	86aa                	mv	a3,a0
ffffffffc0200c4e:	8782                	jr	a5
ffffffffc0200c50:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c52:	00005517          	auipc	a0,0x5
ffffffffc0200c56:	51650513          	addi	a0,a0,1302 # ffffffffc0206168 <etext+0x928>
ffffffffc0200c5a:	d3aff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200c5e:	66a2                	ld	a3,8(sp)
ffffffffc0200c60:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c64:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c66:	0791                	addi	a5,a5,4
ffffffffc0200c68:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c6c:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c6e:	6960406f          	j	ffffffffc0205304 <syscall>
}
ffffffffc0200c72:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c74:	00005517          	auipc	a0,0x5
ffffffffc0200c78:	51450513          	addi	a0,a0,1300 # ffffffffc0206188 <etext+0x948>
}
ffffffffc0200c7c:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c7e:	d16ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c82:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c84:	00005517          	auipc	a0,0x5
ffffffffc0200c88:	52450513          	addi	a0,a0,1316 # ffffffffc02061a8 <etext+0x968>
}
ffffffffc0200c8c:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c8e:	d06ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c92:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c94:	00005517          	auipc	a0,0x5
ffffffffc0200c98:	53450513          	addi	a0,a0,1332 # ffffffffc02061c8 <etext+0x988>
}
ffffffffc0200c9c:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c9e:	cf6ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200ca2:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200ca4:	00005517          	auipc	a0,0x5
ffffffffc0200ca8:	53c50513          	addi	a0,a0,1340 # ffffffffc02061e0 <etext+0x9a0>
}
ffffffffc0200cac:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200cae:	ce6ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cb2:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200cb4:	00005517          	auipc	a0,0x5
ffffffffc0200cb8:	54450513          	addi	a0,a0,1348 # ffffffffc02061f8 <etext+0x9b8>
}
ffffffffc0200cbc:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200cbe:	cd6ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cc2:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200cc4:	00005517          	auipc	a0,0x5
ffffffffc0200cc8:	3bc50513          	addi	a0,a0,956 # ffffffffc0206080 <etext+0x840>
}
ffffffffc0200ccc:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cce:	cc6ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cd2:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cd4:	00005517          	auipc	a0,0x5
ffffffffc0200cd8:	3cc50513          	addi	a0,a0,972 # ffffffffc02060a0 <etext+0x860>
}
ffffffffc0200cdc:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cde:	cb6ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200ce2:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200ce4:	00005517          	auipc	a0,0x5
ffffffffc0200ce8:	3dc50513          	addi	a0,a0,988 # ffffffffc02060c0 <etext+0x880>
}
ffffffffc0200cec:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cee:	ca6ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200cf2:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cf4:	00005517          	auipc	a0,0x5
ffffffffc0200cf8:	3e450513          	addi	a0,a0,996 # ffffffffc02060d8 <etext+0x898>
ffffffffc0200cfc:	c98ff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d00:	66a2                	ld	a3,8(sp)
ffffffffc0200d02:	47a9                	li	a5,10
ffffffffc0200d04:	66d8                	ld	a4,136(a3)
ffffffffc0200d06:	04f70c63          	beq	a4,a5,ffffffffc0200d5e <exception_handler+0x130>
}
ffffffffc0200d0a:	60e2                	ld	ra,24(sp)
ffffffffc0200d0c:	6105                	addi	sp,sp,32
ffffffffc0200d0e:	8082                	ret
ffffffffc0200d10:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200d12:	00005517          	auipc	a0,0x5
ffffffffc0200d16:	3d650513          	addi	a0,a0,982 # ffffffffc02060e8 <etext+0x8a8>
}
ffffffffc0200d1a:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200d1c:	c78ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d20:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	3e650513          	addi	a0,a0,998 # ffffffffc0206108 <etext+0x8c8>
}
ffffffffc0200d2a:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d2c:	c68ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d30:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d32:	00005517          	auipc	a0,0x5
ffffffffc0200d36:	41e50513          	addi	a0,a0,1054 # ffffffffc0206150 <etext+0x910>
}
ffffffffc0200d3a:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d3c:	c58ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d40:	60e2                	ld	ra,24(sp)
ffffffffc0200d42:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d44:	bb45                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d46:	00005617          	auipc	a2,0x5
ffffffffc0200d4a:	3da60613          	addi	a2,a2,986 # ffffffffc0206120 <etext+0x8e0>
ffffffffc0200d4e:	0c400593          	li	a1,196
ffffffffc0200d52:	00005517          	auipc	a0,0x5
ffffffffc0200d56:	3e650513          	addi	a0,a0,998 # ffffffffc0206138 <etext+0x8f8>
ffffffffc0200d5a:	eecff0ef          	jal	ffffffffc0200446 <__panic>
            tf->epc += 4;
ffffffffc0200d5e:	1086b783          	ld	a5,264(a3)
ffffffffc0200d62:	0791                	addi	a5,a5,4
ffffffffc0200d64:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200d68:	59c040ef          	jal	ffffffffc0205304 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d6c:	0009b717          	auipc	a4,0x9b
ffffffffc0200d70:	a0473703          	ld	a4,-1532(a4) # ffffffffc029b770 <current>
ffffffffc0200d74:	6522                	ld	a0,8(sp)
}
ffffffffc0200d76:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d78:	6b0c                	ld	a1,16(a4)
ffffffffc0200d7a:	6789                	lui	a5,0x2
ffffffffc0200d7c:	95be                	add	a1,a1,a5
}
ffffffffc0200d7e:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d80:	aa99                	j	ffffffffc0200ed6 <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200d82:	bb8d                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200d84 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d84:	0009b717          	auipc	a4,0x9b
ffffffffc0200d88:	9ec73703          	ld	a4,-1556(a4) # ffffffffc029b770 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d8c:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d90:	cf21                	beqz	a4,ffffffffc0200de8 <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d92:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d96:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d9a:	1101                	addi	sp,sp,-32
ffffffffc0200d9c:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d9e:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200da2:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200da4:	e432                	sd	a2,8(sp)
ffffffffc0200da6:	e042                	sd	a6,0(sp)
ffffffffc0200da8:	0205c763          	bltz	a1,ffffffffc0200dd6 <trap+0x52>
        exception_handler(tf);
ffffffffc0200dac:	e83ff0ef          	jal	ffffffffc0200c2e <exception_handler>
ffffffffc0200db0:	6622                	ld	a2,8(sp)
ffffffffc0200db2:	6802                	ld	a6,0(sp)
ffffffffc0200db4:	0009b697          	auipc	a3,0x9b
ffffffffc0200db8:	9bc68693          	addi	a3,a3,-1604 # ffffffffc029b770 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200dbc:	6298                	ld	a4,0(a3)
ffffffffc0200dbe:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200dc2:	e619                	bnez	a2,ffffffffc0200dd0 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dc4:	0b072783          	lw	a5,176(a4)
ffffffffc0200dc8:	8b85                	andi	a5,a5,1
ffffffffc0200dca:	e79d                	bnez	a5,ffffffffc0200df8 <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200dcc:	6f1c                	ld	a5,24(a4)
ffffffffc0200dce:	e38d                	bnez	a5,ffffffffc0200df0 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200dd0:	60e2                	ld	ra,24(sp)
ffffffffc0200dd2:	6105                	addi	sp,sp,32
ffffffffc0200dd4:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dd6:	d81ff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200dda:	6802                	ld	a6,0(sp)
ffffffffc0200ddc:	6622                	ld	a2,8(sp)
ffffffffc0200dde:	0009b697          	auipc	a3,0x9b
ffffffffc0200de2:	99268693          	addi	a3,a3,-1646 # ffffffffc029b770 <current>
ffffffffc0200de6:	bfd9                	j	ffffffffc0200dbc <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200de8:	0005c363          	bltz	a1,ffffffffc0200dee <trap+0x6a>
        exception_handler(tf);
ffffffffc0200dec:	b589                	j	ffffffffc0200c2e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dee:	b3a5                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200df0:	60e2                	ld	ra,24(sp)
ffffffffc0200df2:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200df4:	4240406f          	j	ffffffffc0205218 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200df8:	555d                	li	a0,-9
ffffffffc0200dfa:	6ba030ef          	jal	ffffffffc02044b4 <do_exit>
            if (current->need_resched)
ffffffffc0200dfe:	0009b717          	auipc	a4,0x9b
ffffffffc0200e02:	97273703          	ld	a4,-1678(a4) # ffffffffc029b770 <current>
ffffffffc0200e06:	b7d9                	j	ffffffffc0200dcc <trap+0x48>

ffffffffc0200e08 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e08:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e0c:	00011463          	bnez	sp,ffffffffc0200e14 <__alltraps+0xc>
ffffffffc0200e10:	14002173          	csrr	sp,sscratch
ffffffffc0200e14:	712d                	addi	sp,sp,-288
ffffffffc0200e16:	e002                	sd	zero,0(sp)
ffffffffc0200e18:	e406                	sd	ra,8(sp)
ffffffffc0200e1a:	ec0e                	sd	gp,24(sp)
ffffffffc0200e1c:	f012                	sd	tp,32(sp)
ffffffffc0200e1e:	f416                	sd	t0,40(sp)
ffffffffc0200e20:	f81a                	sd	t1,48(sp)
ffffffffc0200e22:	fc1e                	sd	t2,56(sp)
ffffffffc0200e24:	e0a2                	sd	s0,64(sp)
ffffffffc0200e26:	e4a6                	sd	s1,72(sp)
ffffffffc0200e28:	e8aa                	sd	a0,80(sp)
ffffffffc0200e2a:	ecae                	sd	a1,88(sp)
ffffffffc0200e2c:	f0b2                	sd	a2,96(sp)
ffffffffc0200e2e:	f4b6                	sd	a3,104(sp)
ffffffffc0200e30:	f8ba                	sd	a4,112(sp)
ffffffffc0200e32:	fcbe                	sd	a5,120(sp)
ffffffffc0200e34:	e142                	sd	a6,128(sp)
ffffffffc0200e36:	e546                	sd	a7,136(sp)
ffffffffc0200e38:	e94a                	sd	s2,144(sp)
ffffffffc0200e3a:	ed4e                	sd	s3,152(sp)
ffffffffc0200e3c:	f152                	sd	s4,160(sp)
ffffffffc0200e3e:	f556                	sd	s5,168(sp)
ffffffffc0200e40:	f95a                	sd	s6,176(sp)
ffffffffc0200e42:	fd5e                	sd	s7,184(sp)
ffffffffc0200e44:	e1e2                	sd	s8,192(sp)
ffffffffc0200e46:	e5e6                	sd	s9,200(sp)
ffffffffc0200e48:	e9ea                	sd	s10,208(sp)
ffffffffc0200e4a:	edee                	sd	s11,216(sp)
ffffffffc0200e4c:	f1f2                	sd	t3,224(sp)
ffffffffc0200e4e:	f5f6                	sd	t4,232(sp)
ffffffffc0200e50:	f9fa                	sd	t5,240(sp)
ffffffffc0200e52:	fdfe                	sd	t6,248(sp)
ffffffffc0200e54:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e58:	100024f3          	csrr	s1,sstatus
ffffffffc0200e5c:	14102973          	csrr	s2,sepc
ffffffffc0200e60:	143029f3          	csrr	s3,stval
ffffffffc0200e64:	14202a73          	csrr	s4,scause
ffffffffc0200e68:	e822                	sd	s0,16(sp)
ffffffffc0200e6a:	e226                	sd	s1,256(sp)
ffffffffc0200e6c:	e64a                	sd	s2,264(sp)
ffffffffc0200e6e:	ea4e                	sd	s3,272(sp)
ffffffffc0200e70:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e72:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e74:	f11ff0ef          	jal	ffffffffc0200d84 <trap>

ffffffffc0200e78 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e78:	6492                	ld	s1,256(sp)
ffffffffc0200e7a:	6932                	ld	s2,264(sp)
ffffffffc0200e7c:	1004f413          	andi	s0,s1,256
ffffffffc0200e80:	e401                	bnez	s0,ffffffffc0200e88 <__trapret+0x10>
ffffffffc0200e82:	1200                	addi	s0,sp,288
ffffffffc0200e84:	14041073          	csrw	sscratch,s0
ffffffffc0200e88:	10049073          	csrw	sstatus,s1
ffffffffc0200e8c:	14191073          	csrw	sepc,s2
ffffffffc0200e90:	60a2                	ld	ra,8(sp)
ffffffffc0200e92:	61e2                	ld	gp,24(sp)
ffffffffc0200e94:	7202                	ld	tp,32(sp)
ffffffffc0200e96:	72a2                	ld	t0,40(sp)
ffffffffc0200e98:	7342                	ld	t1,48(sp)
ffffffffc0200e9a:	73e2                	ld	t2,56(sp)
ffffffffc0200e9c:	6406                	ld	s0,64(sp)
ffffffffc0200e9e:	64a6                	ld	s1,72(sp)
ffffffffc0200ea0:	6546                	ld	a0,80(sp)
ffffffffc0200ea2:	65e6                	ld	a1,88(sp)
ffffffffc0200ea4:	7606                	ld	a2,96(sp)
ffffffffc0200ea6:	76a6                	ld	a3,104(sp)
ffffffffc0200ea8:	7746                	ld	a4,112(sp)
ffffffffc0200eaa:	77e6                	ld	a5,120(sp)
ffffffffc0200eac:	680a                	ld	a6,128(sp)
ffffffffc0200eae:	68aa                	ld	a7,136(sp)
ffffffffc0200eb0:	694a                	ld	s2,144(sp)
ffffffffc0200eb2:	69ea                	ld	s3,152(sp)
ffffffffc0200eb4:	7a0a                	ld	s4,160(sp)
ffffffffc0200eb6:	7aaa                	ld	s5,168(sp)
ffffffffc0200eb8:	7b4a                	ld	s6,176(sp)
ffffffffc0200eba:	7bea                	ld	s7,184(sp)
ffffffffc0200ebc:	6c0e                	ld	s8,192(sp)
ffffffffc0200ebe:	6cae                	ld	s9,200(sp)
ffffffffc0200ec0:	6d4e                	ld	s10,208(sp)
ffffffffc0200ec2:	6dee                	ld	s11,216(sp)
ffffffffc0200ec4:	7e0e                	ld	t3,224(sp)
ffffffffc0200ec6:	7eae                	ld	t4,232(sp)
ffffffffc0200ec8:	7f4e                	ld	t5,240(sp)
ffffffffc0200eca:	7fee                	ld	t6,248(sp)
ffffffffc0200ecc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200ece:	10200073          	sret

ffffffffc0200ed2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ed2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200ed4:	b755                	j	ffffffffc0200e78 <__trapret>

ffffffffc0200ed6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200ed6:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200eda:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200ede:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200ee2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200ee6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200eea:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200eee:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ef2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200ef6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200efa:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200efc:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200efe:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f00:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f02:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f04:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f06:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f08:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f0a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f0c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f0e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f10:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f12:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f14:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f16:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f18:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f1a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f1c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f1e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f20:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f22:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f24:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f26:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f28:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f2a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f2c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f2e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f30:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f32:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f34:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f36:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f38:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f3a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f3c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f3e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f40:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f42:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f44:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f46:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f48:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f4a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f4c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f4e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f50:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f52:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f54:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f56:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f58:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f5a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f5c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f5e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f60:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f62:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f64:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f66:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f68:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f6a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f6c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f6e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f70:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f72:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f74:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f76:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f78:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f7a:	812e                	mv	sp,a1
ffffffffc0200f7c:	bdf5                	j	ffffffffc0200e78 <__trapret>

ffffffffc0200f7e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f7e:	00096797          	auipc	a5,0x96
ffffffffc0200f82:	75a78793          	addi	a5,a5,1882 # ffffffffc02976d8 <free_area>
ffffffffc0200f86:	e79c                	sd	a5,8(a5)
ffffffffc0200f88:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f8a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f8e:	8082                	ret

ffffffffc0200f90 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f90:	00096517          	auipc	a0,0x96
ffffffffc0200f94:	75856503          	lwu	a0,1880(a0) # ffffffffc02976e8 <free_area+0x10>
ffffffffc0200f98:	8082                	ret

ffffffffc0200f9a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f9a:	711d                	addi	sp,sp,-96
ffffffffc0200f9c:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f9e:	00096917          	auipc	s2,0x96
ffffffffc0200fa2:	73a90913          	addi	s2,s2,1850 # ffffffffc02976d8 <free_area>
ffffffffc0200fa6:	00893783          	ld	a5,8(s2)
ffffffffc0200faa:	ec86                	sd	ra,88(sp)
ffffffffc0200fac:	e8a2                	sd	s0,80(sp)
ffffffffc0200fae:	e4a6                	sd	s1,72(sp)
ffffffffc0200fb0:	fc4e                	sd	s3,56(sp)
ffffffffc0200fb2:	f852                	sd	s4,48(sp)
ffffffffc0200fb4:	f456                	sd	s5,40(sp)
ffffffffc0200fb6:	f05a                	sd	s6,32(sp)
ffffffffc0200fb8:	ec5e                	sd	s7,24(sp)
ffffffffc0200fba:	e862                	sd	s8,16(sp)
ffffffffc0200fbc:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fbe:	2f278363          	beq	a5,s2,ffffffffc02012a4 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200fc2:	4401                	li	s0,0
ffffffffc0200fc4:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200fc6:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fca:	8b09                	andi	a4,a4,2
ffffffffc0200fcc:	2e070063          	beqz	a4,ffffffffc02012ac <default_check+0x312>
        count++, total += p->property;
ffffffffc0200fd0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fd4:	679c                	ld	a5,8(a5)
ffffffffc0200fd6:	2485                	addiw	s1,s1,1
ffffffffc0200fd8:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fda:	ff2796e3          	bne	a5,s2,ffffffffc0200fc6 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200fde:	89a2                	mv	s3,s0
ffffffffc0200fe0:	741000ef          	jal	ffffffffc0201f20 <nr_free_pages>
ffffffffc0200fe4:	73351463          	bne	a0,s3,ffffffffc020170c <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fe8:	4505                	li	a0,1
ffffffffc0200fea:	6c5000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0200fee:	8a2a                	mv	s4,a0
ffffffffc0200ff0:	44050e63          	beqz	a0,ffffffffc020144c <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	6b9000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0200ffa:	89aa                	mv	s3,a0
ffffffffc0200ffc:	72050863          	beqz	a0,ffffffffc020172c <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	6ad000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0201006:	8aaa                	mv	s5,a0
ffffffffc0201008:	4c050263          	beqz	a0,ffffffffc02014cc <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020100c:	40a987b3          	sub	a5,s3,a0
ffffffffc0201010:	40aa0733          	sub	a4,s4,a0
ffffffffc0201014:	0017b793          	seqz	a5,a5
ffffffffc0201018:	00173713          	seqz	a4,a4
ffffffffc020101c:	8fd9                	or	a5,a5,a4
ffffffffc020101e:	30079763          	bnez	a5,ffffffffc020132c <default_check+0x392>
ffffffffc0201022:	313a0563          	beq	s4,s3,ffffffffc020132c <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201026:	000a2783          	lw	a5,0(s4)
ffffffffc020102a:	2a079163          	bnez	a5,ffffffffc02012cc <default_check+0x332>
ffffffffc020102e:	0009a783          	lw	a5,0(s3)
ffffffffc0201032:	28079d63          	bnez	a5,ffffffffc02012cc <default_check+0x332>
ffffffffc0201036:	411c                	lw	a5,0(a0)
ffffffffc0201038:	28079a63          	bnez	a5,ffffffffc02012cc <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020103c:	0009a797          	auipc	a5,0x9a
ffffffffc0201040:	7247b783          	ld	a5,1828(a5) # ffffffffc029b760 <pages>
ffffffffc0201044:	00007617          	auipc	a2,0x7
ffffffffc0201048:	96463603          	ld	a2,-1692(a2) # ffffffffc02079a8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020104c:	0009a697          	auipc	a3,0x9a
ffffffffc0201050:	70c6b683          	ld	a3,1804(a3) # ffffffffc029b758 <npage>
ffffffffc0201054:	40fa0733          	sub	a4,s4,a5
ffffffffc0201058:	8719                	srai	a4,a4,0x6
ffffffffc020105a:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020105c:	0732                	slli	a4,a4,0xc
ffffffffc020105e:	06b2                	slli	a3,a3,0xc
ffffffffc0201060:	2ad77663          	bgeu	a4,a3,ffffffffc020130c <default_check+0x372>
    return page - pages + nbase;
ffffffffc0201064:	40f98733          	sub	a4,s3,a5
ffffffffc0201068:	8719                	srai	a4,a4,0x6
ffffffffc020106a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020106c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020106e:	4cd77f63          	bgeu	a4,a3,ffffffffc020154c <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0201072:	40f507b3          	sub	a5,a0,a5
ffffffffc0201076:	8799                	srai	a5,a5,0x6
ffffffffc0201078:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020107a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020107c:	32d7f863          	bgeu	a5,a3,ffffffffc02013ac <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0201080:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201082:	00093c03          	ld	s8,0(s2)
ffffffffc0201086:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc020108a:	00096b17          	auipc	s6,0x96
ffffffffc020108e:	65eb2b03          	lw	s6,1630(s6) # ffffffffc02976e8 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0201092:	01293023          	sd	s2,0(s2)
ffffffffc0201096:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc020109a:	00096797          	auipc	a5,0x96
ffffffffc020109e:	6407a723          	sw	zero,1614(a5) # ffffffffc02976e8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010a2:	60d000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02010a6:	2e051363          	bnez	a0,ffffffffc020138c <default_check+0x3f2>
    free_page(p0);
ffffffffc02010aa:	8552                	mv	a0,s4
ffffffffc02010ac:	4585                	li	a1,1
ffffffffc02010ae:	63b000ef          	jal	ffffffffc0201ee8 <free_pages>
    free_page(p1);
ffffffffc02010b2:	854e                	mv	a0,s3
ffffffffc02010b4:	4585                	li	a1,1
ffffffffc02010b6:	633000ef          	jal	ffffffffc0201ee8 <free_pages>
    free_page(p2);
ffffffffc02010ba:	8556                	mv	a0,s5
ffffffffc02010bc:	4585                	li	a1,1
ffffffffc02010be:	62b000ef          	jal	ffffffffc0201ee8 <free_pages>
    assert(nr_free == 3);
ffffffffc02010c2:	00096717          	auipc	a4,0x96
ffffffffc02010c6:	62672703          	lw	a4,1574(a4) # ffffffffc02976e8 <free_area+0x10>
ffffffffc02010ca:	478d                	li	a5,3
ffffffffc02010cc:	2af71063          	bne	a4,a5,ffffffffc020136c <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010d0:	4505                	li	a0,1
ffffffffc02010d2:	5dd000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02010d6:	89aa                	mv	s3,a0
ffffffffc02010d8:	26050a63          	beqz	a0,ffffffffc020134c <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010dc:	4505                	li	a0,1
ffffffffc02010de:	5d1000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02010e2:	8aaa                	mv	s5,a0
ffffffffc02010e4:	3c050463          	beqz	a0,ffffffffc02014ac <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010e8:	4505                	li	a0,1
ffffffffc02010ea:	5c5000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02010ee:	8a2a                	mv	s4,a0
ffffffffc02010f0:	38050e63          	beqz	a0,ffffffffc020148c <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc02010f4:	4505                	li	a0,1
ffffffffc02010f6:	5b9000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02010fa:	36051963          	bnez	a0,ffffffffc020146c <default_check+0x4d2>
    free_page(p0);
ffffffffc02010fe:	4585                	li	a1,1
ffffffffc0201100:	854e                	mv	a0,s3
ffffffffc0201102:	5e7000ef          	jal	ffffffffc0201ee8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201106:	00893783          	ld	a5,8(s2)
ffffffffc020110a:	1f278163          	beq	a5,s2,ffffffffc02012ec <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc020110e:	4505                	li	a0,1
ffffffffc0201110:	59f000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0201114:	8caa                	mv	s9,a0
ffffffffc0201116:	30a99b63          	bne	s3,a0,ffffffffc020142c <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc020111a:	4505                	li	a0,1
ffffffffc020111c:	593000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0201120:	2e051663          	bnez	a0,ffffffffc020140c <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201124:	00096797          	auipc	a5,0x96
ffffffffc0201128:	5c47a783          	lw	a5,1476(a5) # ffffffffc02976e8 <free_area+0x10>
ffffffffc020112c:	2c079063          	bnez	a5,ffffffffc02013ec <default_check+0x452>
    free_page(p);
ffffffffc0201130:	8566                	mv	a0,s9
ffffffffc0201132:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201134:	01893023          	sd	s8,0(s2)
ffffffffc0201138:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc020113c:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201140:	5a9000ef          	jal	ffffffffc0201ee8 <free_pages>
    free_page(p1);
ffffffffc0201144:	8556                	mv	a0,s5
ffffffffc0201146:	4585                	li	a1,1
ffffffffc0201148:	5a1000ef          	jal	ffffffffc0201ee8 <free_pages>
    free_page(p2);
ffffffffc020114c:	8552                	mv	a0,s4
ffffffffc020114e:	4585                	li	a1,1
ffffffffc0201150:	599000ef          	jal	ffffffffc0201ee8 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201154:	4515                	li	a0,5
ffffffffc0201156:	559000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc020115a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020115c:	26050863          	beqz	a0,ffffffffc02013cc <default_check+0x432>
ffffffffc0201160:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc0201162:	8b89                	andi	a5,a5,2
ffffffffc0201164:	54079463          	bnez	a5,ffffffffc02016ac <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201168:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020116a:	00093b83          	ld	s7,0(s2)
ffffffffc020116e:	00893b03          	ld	s6,8(s2)
ffffffffc0201172:	01293023          	sd	s2,0(s2)
ffffffffc0201176:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc020117a:	535000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc020117e:	50051763          	bnez	a0,ffffffffc020168c <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201182:	08098a13          	addi	s4,s3,128
ffffffffc0201186:	8552                	mv	a0,s4
ffffffffc0201188:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020118a:	00096c17          	auipc	s8,0x96
ffffffffc020118e:	55ec2c03          	lw	s8,1374(s8) # ffffffffc02976e8 <free_area+0x10>
    nr_free = 0;
ffffffffc0201192:	00096797          	auipc	a5,0x96
ffffffffc0201196:	5407ab23          	sw	zero,1366(a5) # ffffffffc02976e8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020119a:	54f000ef          	jal	ffffffffc0201ee8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020119e:	4511                	li	a0,4
ffffffffc02011a0:	50f000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02011a4:	4c051463          	bnez	a0,ffffffffc020166c <default_check+0x6d2>
ffffffffc02011a8:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011ac:	8b89                	andi	a5,a5,2
ffffffffc02011ae:	48078f63          	beqz	a5,ffffffffc020164c <default_check+0x6b2>
ffffffffc02011b2:	0909a503          	lw	a0,144(s3)
ffffffffc02011b6:	478d                	li	a5,3
ffffffffc02011b8:	48f51a63          	bne	a0,a5,ffffffffc020164c <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011bc:	4f3000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02011c0:	8aaa                	mv	s5,a0
ffffffffc02011c2:	46050563          	beqz	a0,ffffffffc020162c <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02011c6:	4505                	li	a0,1
ffffffffc02011c8:	4e7000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc02011cc:	44051063          	bnez	a0,ffffffffc020160c <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02011d0:	415a1e63          	bne	s4,s5,ffffffffc02015ec <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011d4:	4585                	li	a1,1
ffffffffc02011d6:	854e                	mv	a0,s3
ffffffffc02011d8:	511000ef          	jal	ffffffffc0201ee8 <free_pages>
    free_pages(p1, 3);
ffffffffc02011dc:	8552                	mv	a0,s4
ffffffffc02011de:	458d                	li	a1,3
ffffffffc02011e0:	509000ef          	jal	ffffffffc0201ee8 <free_pages>
ffffffffc02011e4:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011e8:	8b89                	andi	a5,a5,2
ffffffffc02011ea:	3e078163          	beqz	a5,ffffffffc02015cc <default_check+0x632>
ffffffffc02011ee:	0109aa83          	lw	s5,16(s3)
ffffffffc02011f2:	4785                	li	a5,1
ffffffffc02011f4:	3cfa9c63          	bne	s5,a5,ffffffffc02015cc <default_check+0x632>
ffffffffc02011f8:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011fc:	8b89                	andi	a5,a5,2
ffffffffc02011fe:	3a078763          	beqz	a5,ffffffffc02015ac <default_check+0x612>
ffffffffc0201202:	010a2703          	lw	a4,16(s4)
ffffffffc0201206:	478d                	li	a5,3
ffffffffc0201208:	3af71263          	bne	a4,a5,ffffffffc02015ac <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020120c:	8556                	mv	a0,s5
ffffffffc020120e:	4a1000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0201212:	36a99d63          	bne	s3,a0,ffffffffc020158c <default_check+0x5f2>
    free_page(p0);
ffffffffc0201216:	85d6                	mv	a1,s5
ffffffffc0201218:	4d1000ef          	jal	ffffffffc0201ee8 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020121c:	4509                	li	a0,2
ffffffffc020121e:	491000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0201222:	34aa1563          	bne	s4,a0,ffffffffc020156c <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc0201226:	4589                	li	a1,2
ffffffffc0201228:	4c1000ef          	jal	ffffffffc0201ee8 <free_pages>
    free_page(p2);
ffffffffc020122c:	04098513          	addi	a0,s3,64
ffffffffc0201230:	85d6                	mv	a1,s5
ffffffffc0201232:	4b7000ef          	jal	ffffffffc0201ee8 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201236:	4515                	li	a0,5
ffffffffc0201238:	477000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc020123c:	89aa                	mv	s3,a0
ffffffffc020123e:	48050763          	beqz	a0,ffffffffc02016cc <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc0201242:	8556                	mv	a0,s5
ffffffffc0201244:	46b000ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0201248:	2e051263          	bnez	a0,ffffffffc020152c <default_check+0x592>

    assert(nr_free == 0);
ffffffffc020124c:	00096797          	auipc	a5,0x96
ffffffffc0201250:	49c7a783          	lw	a5,1180(a5) # ffffffffc02976e8 <free_area+0x10>
ffffffffc0201254:	2a079c63          	bnez	a5,ffffffffc020150c <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201258:	854e                	mv	a0,s3
ffffffffc020125a:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc020125c:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201260:	01793023          	sd	s7,0(s2)
ffffffffc0201264:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201268:	481000ef          	jal	ffffffffc0201ee8 <free_pages>
    return listelm->next;
ffffffffc020126c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201270:	01278963          	beq	a5,s2,ffffffffc0201282 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201274:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201278:	679c                	ld	a5,8(a5)
ffffffffc020127a:	34fd                	addiw	s1,s1,-1
ffffffffc020127c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020127e:	ff279be3          	bne	a5,s2,ffffffffc0201274 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc0201282:	26049563          	bnez	s1,ffffffffc02014ec <default_check+0x552>
    assert(total == 0);
ffffffffc0201286:	46041363          	bnez	s0,ffffffffc02016ec <default_check+0x752>
}
ffffffffc020128a:	60e6                	ld	ra,88(sp)
ffffffffc020128c:	6446                	ld	s0,80(sp)
ffffffffc020128e:	64a6                	ld	s1,72(sp)
ffffffffc0201290:	6906                	ld	s2,64(sp)
ffffffffc0201292:	79e2                	ld	s3,56(sp)
ffffffffc0201294:	7a42                	ld	s4,48(sp)
ffffffffc0201296:	7aa2                	ld	s5,40(sp)
ffffffffc0201298:	7b02                	ld	s6,32(sp)
ffffffffc020129a:	6be2                	ld	s7,24(sp)
ffffffffc020129c:	6c42                	ld	s8,16(sp)
ffffffffc020129e:	6ca2                	ld	s9,8(sp)
ffffffffc02012a0:	6125                	addi	sp,sp,96
ffffffffc02012a2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012a4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012a6:	4401                	li	s0,0
ffffffffc02012a8:	4481                	li	s1,0
ffffffffc02012aa:	bb1d                	j	ffffffffc0200fe0 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc02012ac:	00005697          	auipc	a3,0x5
ffffffffc02012b0:	f6468693          	addi	a3,a3,-156 # ffffffffc0206210 <etext+0x9d0>
ffffffffc02012b4:	00005617          	auipc	a2,0x5
ffffffffc02012b8:	f6c60613          	addi	a2,a2,-148 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02012bc:	11000593          	li	a1,272
ffffffffc02012c0:	00005517          	auipc	a0,0x5
ffffffffc02012c4:	f7850513          	addi	a0,a0,-136 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02012c8:	97eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012cc:	00005697          	auipc	a3,0x5
ffffffffc02012d0:	02c68693          	addi	a3,a3,44 # ffffffffc02062f8 <etext+0xab8>
ffffffffc02012d4:	00005617          	auipc	a2,0x5
ffffffffc02012d8:	f4c60613          	addi	a2,a2,-180 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02012dc:	0dc00593          	li	a1,220
ffffffffc02012e0:	00005517          	auipc	a0,0x5
ffffffffc02012e4:	f5850513          	addi	a0,a0,-168 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02012e8:	95eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012ec:	00005697          	auipc	a3,0x5
ffffffffc02012f0:	0d468693          	addi	a3,a3,212 # ffffffffc02063c0 <etext+0xb80>
ffffffffc02012f4:	00005617          	auipc	a2,0x5
ffffffffc02012f8:	f2c60613          	addi	a2,a2,-212 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02012fc:	0f700593          	li	a1,247
ffffffffc0201300:	00005517          	auipc	a0,0x5
ffffffffc0201304:	f3850513          	addi	a0,a0,-200 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201308:	93eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020130c:	00005697          	auipc	a3,0x5
ffffffffc0201310:	02c68693          	addi	a3,a3,44 # ffffffffc0206338 <etext+0xaf8>
ffffffffc0201314:	00005617          	auipc	a2,0x5
ffffffffc0201318:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020131c:	0de00593          	li	a1,222
ffffffffc0201320:	00005517          	auipc	a0,0x5
ffffffffc0201324:	f1850513          	addi	a0,a0,-232 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201328:	91eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020132c:	00005697          	auipc	a3,0x5
ffffffffc0201330:	fa468693          	addi	a3,a3,-92 # ffffffffc02062d0 <etext+0xa90>
ffffffffc0201334:	00005617          	auipc	a2,0x5
ffffffffc0201338:	eec60613          	addi	a2,a2,-276 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020133c:	0db00593          	li	a1,219
ffffffffc0201340:	00005517          	auipc	a0,0x5
ffffffffc0201344:	ef850513          	addi	a0,a0,-264 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201348:	8feff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020134c:	00005697          	auipc	a3,0x5
ffffffffc0201350:	f2468693          	addi	a3,a3,-220 # ffffffffc0206270 <etext+0xa30>
ffffffffc0201354:	00005617          	auipc	a2,0x5
ffffffffc0201358:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020135c:	0f000593          	li	a1,240
ffffffffc0201360:	00005517          	auipc	a0,0x5
ffffffffc0201364:	ed850513          	addi	a0,a0,-296 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201368:	8deff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	04468693          	addi	a3,a3,68 # ffffffffc02063b0 <etext+0xb70>
ffffffffc0201374:	00005617          	auipc	a2,0x5
ffffffffc0201378:	eac60613          	addi	a2,a2,-340 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020137c:	0ee00593          	li	a1,238
ffffffffc0201380:	00005517          	auipc	a0,0x5
ffffffffc0201384:	eb850513          	addi	a0,a0,-328 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201388:	8beff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020138c:	00005697          	auipc	a3,0x5
ffffffffc0201390:	00c68693          	addi	a3,a3,12 # ffffffffc0206398 <etext+0xb58>
ffffffffc0201394:	00005617          	auipc	a2,0x5
ffffffffc0201398:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020139c:	0e900593          	li	a1,233
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	e9850513          	addi	a0,a0,-360 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02013a8:	89eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013ac:	00005697          	auipc	a3,0x5
ffffffffc02013b0:	fcc68693          	addi	a3,a3,-52 # ffffffffc0206378 <etext+0xb38>
ffffffffc02013b4:	00005617          	auipc	a2,0x5
ffffffffc02013b8:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02013bc:	0e000593          	li	a1,224
ffffffffc02013c0:	00005517          	auipc	a0,0x5
ffffffffc02013c4:	e7850513          	addi	a0,a0,-392 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02013c8:	87eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc02013cc:	00005697          	auipc	a3,0x5
ffffffffc02013d0:	03c68693          	addi	a3,a3,60 # ffffffffc0206408 <etext+0xbc8>
ffffffffc02013d4:	00005617          	auipc	a2,0x5
ffffffffc02013d8:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02013dc:	11800593          	li	a1,280
ffffffffc02013e0:	00005517          	auipc	a0,0x5
ffffffffc02013e4:	e5850513          	addi	a0,a0,-424 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02013e8:	85eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02013ec:	00005697          	auipc	a3,0x5
ffffffffc02013f0:	00c68693          	addi	a3,a3,12 # ffffffffc02063f8 <etext+0xbb8>
ffffffffc02013f4:	00005617          	auipc	a2,0x5
ffffffffc02013f8:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02013fc:	0fd00593          	li	a1,253
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	e3850513          	addi	a0,a0,-456 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201408:	83eff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	f8c68693          	addi	a3,a3,-116 # ffffffffc0206398 <etext+0xb58>
ffffffffc0201414:	00005617          	auipc	a2,0x5
ffffffffc0201418:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020141c:	0fb00593          	li	a1,251
ffffffffc0201420:	00005517          	auipc	a0,0x5
ffffffffc0201424:	e1850513          	addi	a0,a0,-488 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201428:	81eff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	fac68693          	addi	a3,a3,-84 # ffffffffc02063d8 <etext+0xb98>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	dec60613          	addi	a2,a2,-532 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020143c:	0fa00593          	li	a1,250
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	df850513          	addi	a0,a0,-520 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201448:	ffffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	e2468693          	addi	a3,a3,-476 # ffffffffc0206270 <etext+0xa30>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020145c:	0d700593          	li	a1,215
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	dd850513          	addi	a0,a0,-552 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201468:	fdffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	f2c68693          	addi	a3,a3,-212 # ffffffffc0206398 <etext+0xb58>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	dac60613          	addi	a2,a2,-596 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020147c:	0f400593          	li	a1,244
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	db850513          	addi	a0,a0,-584 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201488:	fbffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	e2468693          	addi	a3,a3,-476 # ffffffffc02062b0 <etext+0xa70>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	d8c60613          	addi	a2,a2,-628 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020149c:	0f200593          	li	a1,242
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	d9850513          	addi	a0,a0,-616 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02014a8:	f9ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	de468693          	addi	a3,a3,-540 # ffffffffc0206290 <etext+0xa50>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02014bc:	0f100593          	li	a1,241
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	d7850513          	addi	a0,a0,-648 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02014c8:	f7ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	de468693          	addi	a3,a3,-540 # ffffffffc02062b0 <etext+0xa70>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02014dc:	0d900593          	li	a1,217
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	d5850513          	addi	a0,a0,-680 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02014e8:	f5ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	06c68693          	addi	a3,a3,108 # ffffffffc0206558 <etext+0xd18>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02014fc:	14600593          	li	a1,326
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	d3850513          	addi	a0,a0,-712 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201508:	f3ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	eec68693          	addi	a3,a3,-276 # ffffffffc02063f8 <etext+0xbb8>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020151c:	13a00593          	li	a1,314
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	d1850513          	addi	a0,a0,-744 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201528:	f1ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	e6c68693          	addi	a3,a3,-404 # ffffffffc0206398 <etext+0xb58>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	cec60613          	addi	a2,a2,-788 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020153c:	13800593          	li	a1,312
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	cf850513          	addi	a0,a0,-776 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201548:	efffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	e0c68693          	addi	a3,a3,-500 # ffffffffc0206358 <etext+0xb18>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020155c:	0df00593          	li	a1,223
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	cd850513          	addi	a0,a0,-808 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201568:	edffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	fac68693          	addi	a3,a3,-84 # ffffffffc0206518 <etext+0xcd8>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	cac60613          	addi	a2,a2,-852 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020157c:	13200593          	li	a1,306
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	cb850513          	addi	a0,a0,-840 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201588:	ebffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	f6c68693          	addi	a3,a3,-148 # ffffffffc02064f8 <etext+0xcb8>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020159c:	13000593          	li	a1,304
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	c9850513          	addi	a0,a0,-872 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02015a8:	e9ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	f2468693          	addi	a3,a3,-220 # ffffffffc02064d0 <etext+0xc90>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02015bc:	12e00593          	li	a1,302
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	c7850513          	addi	a0,a0,-904 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02015c8:	e7ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	edc68693          	addi	a3,a3,-292 # ffffffffc02064a8 <etext+0xc68>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02015dc:	12d00593          	li	a1,301
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	c5850513          	addi	a0,a0,-936 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02015e8:	e5ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	eac68693          	addi	a3,a3,-340 # ffffffffc0206498 <etext+0xc58>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02015fc:	12800593          	li	a1,296
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	c3850513          	addi	a0,a0,-968 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201608:	e3ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	d8c68693          	addi	a3,a3,-628 # ffffffffc0206398 <etext+0xb58>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020161c:	12700593          	li	a1,295
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	c1850513          	addi	a0,a0,-1000 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201628:	e1ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	e4c68693          	addi	a3,a3,-436 # ffffffffc0206478 <etext+0xc38>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	bec60613          	addi	a2,a2,-1044 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020163c:	12600593          	li	a1,294
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	bf850513          	addi	a0,a0,-1032 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201648:	dfffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	dfc68693          	addi	a3,a3,-516 # ffffffffc0206448 <etext+0xc08>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020165c:	12500593          	li	a1,293
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	bd850513          	addi	a0,a0,-1064 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201668:	ddffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	dc468693          	addi	a3,a3,-572 # ffffffffc0206430 <etext+0xbf0>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	bac60613          	addi	a2,a2,-1108 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020167c:	12400593          	li	a1,292
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201688:	dbffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	d0c68693          	addi	a3,a3,-756 # ffffffffc0206398 <etext+0xb58>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020169c:	11e00593          	li	a1,286
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	b9850513          	addi	a0,a0,-1128 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02016a8:	d9ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	d6c68693          	addi	a3,a3,-660 # ffffffffc0206418 <etext+0xbd8>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02016bc:	11900593          	li	a1,281
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02016c8:	d7ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	e6c68693          	addi	a3,a3,-404 # ffffffffc0206538 <etext+0xcf8>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02016dc:	13700593          	li	a1,311
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	b5850513          	addi	a0,a0,-1192 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02016e8:	d5ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	e7c68693          	addi	a3,a3,-388 # ffffffffc0206568 <etext+0xd28>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02016fc:	14700593          	li	a1,327
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	b3850513          	addi	a0,a0,-1224 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201708:	d3ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	b4468693          	addi	a3,a3,-1212 # ffffffffc0206250 <etext+0xa10>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020171c:	11300593          	li	a1,275
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	b1850513          	addi	a0,a0,-1256 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201728:	d1ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	b6468693          	addi	a3,a3,-1180 # ffffffffc0206290 <etext+0xa50>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	aec60613          	addi	a2,a2,-1300 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020173c:	0d800593          	li	a1,216
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	af850513          	addi	a0,a0,-1288 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201748:	cfffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020174c <default_free_pages>:
{
ffffffffc020174c:	1141                	addi	sp,sp,-16
ffffffffc020174e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201750:	14058663          	beqz	a1,ffffffffc020189c <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201754:	00659713          	slli	a4,a1,0x6
ffffffffc0201758:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020175c:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020175e:	c30d                	beqz	a4,ffffffffc0201780 <default_free_pages+0x34>
ffffffffc0201760:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201762:	8b05                	andi	a4,a4,1
ffffffffc0201764:	10071c63          	bnez	a4,ffffffffc020187c <default_free_pages+0x130>
ffffffffc0201768:	6798                	ld	a4,8(a5)
ffffffffc020176a:	8b09                	andi	a4,a4,2
ffffffffc020176c:	10071863          	bnez	a4,ffffffffc020187c <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201770:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201774:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201778:	04078793          	addi	a5,a5,64
ffffffffc020177c:	fed792e3          	bne	a5,a3,ffffffffc0201760 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201780:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201782:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201786:	4789                	li	a5,2
ffffffffc0201788:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020178c:	00096717          	auipc	a4,0x96
ffffffffc0201790:	f5c72703          	lw	a4,-164(a4) # ffffffffc02976e8 <free_area+0x10>
ffffffffc0201794:	00096697          	auipc	a3,0x96
ffffffffc0201798:	f4468693          	addi	a3,a3,-188 # ffffffffc02976d8 <free_area>
    return list->next == list;
ffffffffc020179c:	669c                	ld	a5,8(a3)
ffffffffc020179e:	9f2d                	addw	a4,a4,a1
ffffffffc02017a0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02017a2:	0ad78163          	beq	a5,a3,ffffffffc0201844 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc02017a6:	fe878713          	addi	a4,a5,-24
ffffffffc02017aa:	4581                	li	a1,0
ffffffffc02017ac:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02017b0:	00e56a63          	bltu	a0,a4,ffffffffc02017c4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017b4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017b6:	04d70c63          	beq	a4,a3,ffffffffc020180e <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02017ba:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017bc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017c0:	fee57ae3          	bgeu	a0,a4,ffffffffc02017b4 <default_free_pages+0x68>
ffffffffc02017c4:	c199                	beqz	a1,ffffffffc02017ca <default_free_pages+0x7e>
ffffffffc02017c6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ca:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017cc:	e390                	sd	a2,0(a5)
ffffffffc02017ce:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02017d0:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017d2:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02017d4:	00d70d63          	beq	a4,a3,ffffffffc02017ee <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017d8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017dc:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017e0:	02059813          	slli	a6,a1,0x20
ffffffffc02017e4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017e8:	97b2                	add	a5,a5,a2
ffffffffc02017ea:	02f50c63          	beq	a0,a5,ffffffffc0201822 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017ee:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017f0:	00d78c63          	beq	a5,a3,ffffffffc0201808 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017f4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017f6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017fa:	02061593          	slli	a1,a2,0x20
ffffffffc02017fe:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201802:	972a                	add	a4,a4,a0
ffffffffc0201804:	04e68c63          	beq	a3,a4,ffffffffc020185c <default_free_pages+0x110>
}
ffffffffc0201808:	60a2                	ld	ra,8(sp)
ffffffffc020180a:	0141                	addi	sp,sp,16
ffffffffc020180c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020180e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201810:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201812:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201814:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201816:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201818:	02d70f63          	beq	a4,a3,ffffffffc0201856 <default_free_pages+0x10a>
ffffffffc020181c:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020181e:	87ba                	mv	a5,a4
ffffffffc0201820:	bf71                	j	ffffffffc02017bc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201822:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201824:	5875                	li	a6,-3
ffffffffc0201826:	9fad                	addw	a5,a5,a1
ffffffffc0201828:	fef72c23          	sw	a5,-8(a4)
ffffffffc020182c:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201830:	01853803          	ld	a6,24(a0)
ffffffffc0201834:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201836:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201838:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e30>
    return listelm->next;
ffffffffc020183c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020183e:	0105b023          	sd	a6,0(a1)
ffffffffc0201842:	b77d                	j	ffffffffc02017f0 <default_free_pages+0xa4>
}
ffffffffc0201844:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201846:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020184a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020184c:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020184e:	e398                	sd	a4,0(a5)
ffffffffc0201850:	e798                	sd	a4,8(a5)
}
ffffffffc0201852:	0141                	addi	sp,sp,16
ffffffffc0201854:	8082                	ret
ffffffffc0201856:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201858:	873e                	mv	a4,a5
ffffffffc020185a:	bfad                	j	ffffffffc02017d4 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020185c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201860:	56f5                	li	a3,-3
ffffffffc0201862:	9f31                	addw	a4,a4,a2
ffffffffc0201864:	c918                	sw	a4,16(a0)
ffffffffc0201866:	ff078713          	addi	a4,a5,-16
ffffffffc020186a:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020186e:	6398                	ld	a4,0(a5)
ffffffffc0201870:	679c                	ld	a5,8(a5)
}
ffffffffc0201872:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201874:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201876:	e398                	sd	a4,0(a5)
ffffffffc0201878:	0141                	addi	sp,sp,16
ffffffffc020187a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020187c:	00005697          	auipc	a3,0x5
ffffffffc0201880:	d0468693          	addi	a3,a3,-764 # ffffffffc0206580 <etext+0xd40>
ffffffffc0201884:	00005617          	auipc	a2,0x5
ffffffffc0201888:	99c60613          	addi	a2,a2,-1636 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020188c:	09400593          	li	a1,148
ffffffffc0201890:	00005517          	auipc	a0,0x5
ffffffffc0201894:	9a850513          	addi	a0,a0,-1624 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201898:	baffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc020189c:	00005697          	auipc	a3,0x5
ffffffffc02018a0:	cdc68693          	addi	a3,a3,-804 # ffffffffc0206578 <etext+0xd38>
ffffffffc02018a4:	00005617          	auipc	a2,0x5
ffffffffc02018a8:	97c60613          	addi	a2,a2,-1668 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02018ac:	09000593          	li	a1,144
ffffffffc02018b0:	00005517          	auipc	a0,0x5
ffffffffc02018b4:	98850513          	addi	a0,a0,-1656 # ffffffffc0206238 <etext+0x9f8>
ffffffffc02018b8:	b8ffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02018bc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018bc:	c951                	beqz	a0,ffffffffc0201950 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02018be:	00096597          	auipc	a1,0x96
ffffffffc02018c2:	e2a5a583          	lw	a1,-470(a1) # ffffffffc02976e8 <free_area+0x10>
ffffffffc02018c6:	86aa                	mv	a3,a0
ffffffffc02018c8:	02059793          	slli	a5,a1,0x20
ffffffffc02018cc:	9381                	srli	a5,a5,0x20
ffffffffc02018ce:	00a7ef63          	bltu	a5,a0,ffffffffc02018ec <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02018d2:	00096617          	auipc	a2,0x96
ffffffffc02018d6:	e0660613          	addi	a2,a2,-506 # ffffffffc02976d8 <free_area>
ffffffffc02018da:	87b2                	mv	a5,a2
ffffffffc02018dc:	a029                	j	ffffffffc02018e6 <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02018de:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02018e2:	00d77763          	bgeu	a4,a3,ffffffffc02018f0 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02018e6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018e8:	fec79be3          	bne	a5,a2,ffffffffc02018de <default_alloc_pages+0x22>
        return NULL;
ffffffffc02018ec:	4501                	li	a0,0
}
ffffffffc02018ee:	8082                	ret
        if (page->property > n)
ffffffffc02018f0:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02018f4:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018f8:	6798                	ld	a4,8(a5)
ffffffffc02018fa:	02089313          	slli	t1,a7,0x20
ffffffffc02018fe:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc0201902:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201906:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020190a:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc020190e:	0266fa63          	bgeu	a3,t1,ffffffffc0201942 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0201912:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc0201916:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020191a:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020191c:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201920:	00870313          	addi	t1,a4,8
ffffffffc0201924:	4889                	li	a7,2
ffffffffc0201926:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020192a:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020192e:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201932:	0068b023          	sd	t1,0(a7)
ffffffffc0201936:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020193a:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020193e:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201942:	9d95                	subw	a1,a1,a3
ffffffffc0201944:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201946:	5775                	li	a4,-3
ffffffffc0201948:	17c1                	addi	a5,a5,-16
ffffffffc020194a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020194e:	8082                	ret
{
ffffffffc0201950:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201952:	00005697          	auipc	a3,0x5
ffffffffc0201956:	c2668693          	addi	a3,a3,-986 # ffffffffc0206578 <etext+0xd38>
ffffffffc020195a:	00005617          	auipc	a2,0x5
ffffffffc020195e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0201962:	06c00593          	li	a1,108
ffffffffc0201966:	00005517          	auipc	a0,0x5
ffffffffc020196a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0206238 <etext+0x9f8>
{
ffffffffc020196e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201970:	ad7fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201974 <default_init_memmap>:
{
ffffffffc0201974:	1141                	addi	sp,sp,-16
ffffffffc0201976:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201978:	c9e1                	beqz	a1,ffffffffc0201a48 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc020197a:	00659713          	slli	a4,a1,0x6
ffffffffc020197e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201982:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201984:	cf11                	beqz	a4,ffffffffc02019a0 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201986:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201988:	8b05                	andi	a4,a4,1
ffffffffc020198a:	cf59                	beqz	a4,ffffffffc0201a28 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020198c:	0007a823          	sw	zero,16(a5)
ffffffffc0201990:	0007b423          	sd	zero,8(a5)
ffffffffc0201994:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201998:	04078793          	addi	a5,a5,64
ffffffffc020199c:	fed795e3          	bne	a5,a3,ffffffffc0201986 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019a0:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019a2:	4789                	li	a5,2
ffffffffc02019a4:	00850713          	addi	a4,a0,8
ffffffffc02019a8:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019ac:	00096717          	auipc	a4,0x96
ffffffffc02019b0:	d3c72703          	lw	a4,-708(a4) # ffffffffc02976e8 <free_area+0x10>
ffffffffc02019b4:	00096697          	auipc	a3,0x96
ffffffffc02019b8:	d2468693          	addi	a3,a3,-732 # ffffffffc02976d8 <free_area>
    return list->next == list;
ffffffffc02019bc:	669c                	ld	a5,8(a3)
ffffffffc02019be:	9f2d                	addw	a4,a4,a1
ffffffffc02019c0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02019c2:	04d78663          	beq	a5,a3,ffffffffc0201a0e <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02019c6:	fe878713          	addi	a4,a5,-24
ffffffffc02019ca:	4581                	li	a1,0
ffffffffc02019cc:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02019d0:	00e56a63          	bltu	a0,a4,ffffffffc02019e4 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019d4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019d6:	02d70263          	beq	a4,a3,ffffffffc02019fa <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02019da:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019dc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019e0:	fee57ae3          	bgeu	a0,a4,ffffffffc02019d4 <default_init_memmap+0x60>
ffffffffc02019e4:	c199                	beqz	a1,ffffffffc02019ea <default_init_memmap+0x76>
ffffffffc02019e6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019ea:	6398                	ld	a4,0(a5)
}
ffffffffc02019ec:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019ee:	e390                	sd	a2,0(a5)
ffffffffc02019f0:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02019f2:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02019f4:	f11c                	sd	a5,32(a0)
ffffffffc02019f6:	0141                	addi	sp,sp,16
ffffffffc02019f8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019fa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019fc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019fe:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a00:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201a02:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a04:	00d70e63          	beq	a4,a3,ffffffffc0201a20 <default_init_memmap+0xac>
ffffffffc0201a08:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201a0a:	87ba                	mv	a5,a4
ffffffffc0201a0c:	bfc1                	j	ffffffffc02019dc <default_init_memmap+0x68>
}
ffffffffc0201a0e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a10:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201a14:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a16:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201a18:	e398                	sd	a4,0(a5)
ffffffffc0201a1a:	e798                	sd	a4,8(a5)
}
ffffffffc0201a1c:	0141                	addi	sp,sp,16
ffffffffc0201a1e:	8082                	ret
ffffffffc0201a20:	60a2                	ld	ra,8(sp)
ffffffffc0201a22:	e290                	sd	a2,0(a3)
ffffffffc0201a24:	0141                	addi	sp,sp,16
ffffffffc0201a26:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a28:	00005697          	auipc	a3,0x5
ffffffffc0201a2c:	b8068693          	addi	a3,a3,-1152 # ffffffffc02065a8 <etext+0xd68>
ffffffffc0201a30:	00004617          	auipc	a2,0x4
ffffffffc0201a34:	7f060613          	addi	a2,a2,2032 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0201a38:	04b00593          	li	a1,75
ffffffffc0201a3c:	00004517          	auipc	a0,0x4
ffffffffc0201a40:	7fc50513          	addi	a0,a0,2044 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201a44:	a03fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a48:	00005697          	auipc	a3,0x5
ffffffffc0201a4c:	b3068693          	addi	a3,a3,-1232 # ffffffffc0206578 <etext+0xd38>
ffffffffc0201a50:	00004617          	auipc	a2,0x4
ffffffffc0201a54:	7d060613          	addi	a2,a2,2000 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0201a58:	04700593          	li	a1,71
ffffffffc0201a5c:	00004517          	auipc	a0,0x4
ffffffffc0201a60:	7dc50513          	addi	a0,a0,2012 # ffffffffc0206238 <etext+0x9f8>
ffffffffc0201a64:	9e3fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a68 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a68:	c531                	beqz	a0,ffffffffc0201ab4 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201a6a:	e9b9                	bnez	a1,ffffffffc0201ac0 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a70:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a72:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a74:	efb1                	bnez	a5,ffffffffc0201ad0 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a76:	00096797          	auipc	a5,0x96
ffffffffc0201a7a:	8527b783          	ld	a5,-1966(a5) # ffffffffc02972c8 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a7e:	873e                	mv	a4,a5
ffffffffc0201a80:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a82:	02a77a63          	bgeu	a4,a0,ffffffffc0201ab6 <slob_free+0x4e>
ffffffffc0201a86:	00f56463          	bltu	a0,a5,ffffffffc0201a8e <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a8a:	fef76ae3          	bltu	a4,a5,ffffffffc0201a7e <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a8e:	4110                	lw	a2,0(a0)
ffffffffc0201a90:	00461693          	slli	a3,a2,0x4
ffffffffc0201a94:	96aa                	add	a3,a3,a0
ffffffffc0201a96:	0ad78463          	beq	a5,a3,ffffffffc0201b3e <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a9a:	4310                	lw	a2,0(a4)
ffffffffc0201a9c:	e51c                	sd	a5,8(a0)
ffffffffc0201a9e:	00461693          	slli	a3,a2,0x4
ffffffffc0201aa2:	96ba                	add	a3,a3,a4
ffffffffc0201aa4:	08d50163          	beq	a0,a3,ffffffffc0201b26 <slob_free+0xbe>
ffffffffc0201aa8:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201aaa:	00096797          	auipc	a5,0x96
ffffffffc0201aae:	80e7bf23          	sd	a4,-2018(a5) # ffffffffc02972c8 <slobfree>
    if (flag)
ffffffffc0201ab2:	e9a5                	bnez	a1,ffffffffc0201b22 <slob_free+0xba>
ffffffffc0201ab4:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ab6:	fcf574e3          	bgeu	a0,a5,ffffffffc0201a7e <slob_free+0x16>
ffffffffc0201aba:	fcf762e3          	bltu	a4,a5,ffffffffc0201a7e <slob_free+0x16>
ffffffffc0201abe:	bfc1                	j	ffffffffc0201a8e <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201ac0:	25bd                	addiw	a1,a1,15
ffffffffc0201ac2:	8191                	srli	a1,a1,0x4
ffffffffc0201ac4:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ac6:	100027f3          	csrr	a5,sstatus
ffffffffc0201aca:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201acc:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ace:	d7c5                	beqz	a5,ffffffffc0201a76 <slob_free+0xe>
{
ffffffffc0201ad0:	1101                	addi	sp,sp,-32
ffffffffc0201ad2:	e42a                	sd	a0,8(sp)
ffffffffc0201ad4:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201ad6:	e2ffe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201ada:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201adc:	00095797          	auipc	a5,0x95
ffffffffc0201ae0:	7ec7b783          	ld	a5,2028(a5) # ffffffffc02972c8 <slobfree>
ffffffffc0201ae4:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ae6:	873e                	mv	a4,a5
ffffffffc0201ae8:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aea:	06a77663          	bgeu	a4,a0,ffffffffc0201b56 <slob_free+0xee>
ffffffffc0201aee:	00f56463          	bltu	a0,a5,ffffffffc0201af6 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201af2:	fef76ae3          	bltu	a4,a5,ffffffffc0201ae6 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201af6:	4110                	lw	a2,0(a0)
ffffffffc0201af8:	00461693          	slli	a3,a2,0x4
ffffffffc0201afc:	96aa                	add	a3,a3,a0
ffffffffc0201afe:	06d78363          	beq	a5,a3,ffffffffc0201b64 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201b02:	4310                	lw	a2,0(a4)
ffffffffc0201b04:	e51c                	sd	a5,8(a0)
ffffffffc0201b06:	00461693          	slli	a3,a2,0x4
ffffffffc0201b0a:	96ba                	add	a3,a3,a4
ffffffffc0201b0c:	06d50163          	beq	a0,a3,ffffffffc0201b6e <slob_free+0x106>
ffffffffc0201b10:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201b12:	00095797          	auipc	a5,0x95
ffffffffc0201b16:	7ae7bb23          	sd	a4,1974(a5) # ffffffffc02972c8 <slobfree>
    if (flag)
ffffffffc0201b1a:	e1a9                	bnez	a1,ffffffffc0201b5c <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b1c:	60e2                	ld	ra,24(sp)
ffffffffc0201b1e:	6105                	addi	sp,sp,32
ffffffffc0201b20:	8082                	ret
        intr_enable();
ffffffffc0201b22:	dddfe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b26:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b28:	853e                	mv	a0,a5
ffffffffc0201b2a:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b2c:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b30:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b32:	00095797          	auipc	a5,0x95
ffffffffc0201b36:	78e7bb23          	sd	a4,1942(a5) # ffffffffc02972c8 <slobfree>
    if (flag)
ffffffffc0201b3a:	ddad                	beqz	a1,ffffffffc0201ab4 <slob_free+0x4c>
ffffffffc0201b3c:	b7dd                	j	ffffffffc0201b22 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b3e:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b40:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b42:	9eb1                	addw	a3,a3,a2
ffffffffc0201b44:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b46:	4310                	lw	a2,0(a4)
ffffffffc0201b48:	e51c                	sd	a5,8(a0)
ffffffffc0201b4a:	00461693          	slli	a3,a2,0x4
ffffffffc0201b4e:	96ba                	add	a3,a3,a4
ffffffffc0201b50:	f4d51ce3          	bne	a0,a3,ffffffffc0201aa8 <slob_free+0x40>
ffffffffc0201b54:	bfc9                	j	ffffffffc0201b26 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b56:	f8f56ee3          	bltu	a0,a5,ffffffffc0201af2 <slob_free+0x8a>
ffffffffc0201b5a:	b771                	j	ffffffffc0201ae6 <slob_free+0x7e>
}
ffffffffc0201b5c:	60e2                	ld	ra,24(sp)
ffffffffc0201b5e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201b60:	d9ffe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201b64:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b66:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b68:	9eb1                	addw	a3,a3,a2
ffffffffc0201b6a:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201b6c:	bf59                	j	ffffffffc0201b02 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201b6e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b70:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201b72:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b76:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201b78:	bf61                	j	ffffffffc0201b10 <slob_free+0xa8>

ffffffffc0201b7a <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b7a:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b7c:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b7e:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b82:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b84:	32a000ef          	jal	ffffffffc0201eae <alloc_pages>
	if (!page)
ffffffffc0201b88:	c91d                	beqz	a0,ffffffffc0201bbe <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b8a:	0009a697          	auipc	a3,0x9a
ffffffffc0201b8e:	bd66b683          	ld	a3,-1066(a3) # ffffffffc029b760 <pages>
ffffffffc0201b92:	00006797          	auipc	a5,0x6
ffffffffc0201b96:	e167b783          	ld	a5,-490(a5) # ffffffffc02079a8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201b9a:	0009a717          	auipc	a4,0x9a
ffffffffc0201b9e:	bbe73703          	ld	a4,-1090(a4) # ffffffffc029b758 <npage>
    return page - pages + nbase;
ffffffffc0201ba2:	8d15                	sub	a0,a0,a3
ffffffffc0201ba4:	8519                	srai	a0,a0,0x6
ffffffffc0201ba6:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201ba8:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bac:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bae:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bb0:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bc4 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bb4:	0009a797          	auipc	a5,0x9a
ffffffffc0201bb8:	b9c7b783          	ld	a5,-1124(a5) # ffffffffc029b750 <va_pa_offset>
ffffffffc0201bbc:	953e                	add	a0,a0,a5
}
ffffffffc0201bbe:	60a2                	ld	ra,8(sp)
ffffffffc0201bc0:	0141                	addi	sp,sp,16
ffffffffc0201bc2:	8082                	ret
ffffffffc0201bc4:	86aa                	mv	a3,a0
ffffffffc0201bc6:	00005617          	auipc	a2,0x5
ffffffffc0201bca:	a0a60613          	addi	a2,a2,-1526 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0201bce:	07100593          	li	a1,113
ffffffffc0201bd2:	00005517          	auipc	a0,0x5
ffffffffc0201bd6:	a2650513          	addi	a0,a0,-1498 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0201bda:	86dfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201bde <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bde:	7179                	addi	sp,sp,-48
ffffffffc0201be0:	f406                	sd	ra,40(sp)
ffffffffc0201be2:	f022                	sd	s0,32(sp)
ffffffffc0201be4:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201be6:	01050713          	addi	a4,a0,16
ffffffffc0201bea:	6785                	lui	a5,0x1
ffffffffc0201bec:	0af77e63          	bgeu	a4,a5,ffffffffc0201ca8 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bf0:	00f50413          	addi	s0,a0,15
ffffffffc0201bf4:	8011                	srli	s0,s0,0x4
ffffffffc0201bf6:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bf8:	100025f3          	csrr	a1,sstatus
ffffffffc0201bfc:	8989                	andi	a1,a1,2
ffffffffc0201bfe:	edd1                	bnez	a1,ffffffffc0201c9a <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201c00:	00095497          	auipc	s1,0x95
ffffffffc0201c04:	6c848493          	addi	s1,s1,1736 # ffffffffc02972c8 <slobfree>
ffffffffc0201c08:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c0a:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201c0c:	4314                	lw	a3,0(a4)
ffffffffc0201c0e:	0886da63          	bge	a3,s0,ffffffffc0201ca2 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201c12:	00e60a63          	beq	a2,a4,ffffffffc0201c26 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c16:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c18:	4394                	lw	a3,0(a5)
ffffffffc0201c1a:	0286d863          	bge	a3,s0,ffffffffc0201c4a <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c1e:	6090                	ld	a2,0(s1)
ffffffffc0201c20:	873e                	mv	a4,a5
ffffffffc0201c22:	fee61ae3          	bne	a2,a4,ffffffffc0201c16 <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c26:	e9b1                	bnez	a1,ffffffffc0201c7a <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c28:	4501                	li	a0,0
ffffffffc0201c2a:	f51ff0ef          	jal	ffffffffc0201b7a <__slob_get_free_pages.constprop.0>
ffffffffc0201c2e:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c30:	c915                	beqz	a0,ffffffffc0201c64 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c32:	6585                	lui	a1,0x1
ffffffffc0201c34:	e35ff0ef          	jal	ffffffffc0201a68 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c38:	100025f3          	csrr	a1,sstatus
ffffffffc0201c3c:	8989                	andi	a1,a1,2
ffffffffc0201c3e:	e98d                	bnez	a1,ffffffffc0201c70 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c40:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c42:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c44:	4394                	lw	a3,0(a5)
ffffffffc0201c46:	fc86cce3          	blt	a3,s0,ffffffffc0201c1e <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c4a:	04d40563          	beq	s0,a3,ffffffffc0201c94 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c4e:	00441613          	slli	a2,s0,0x4
ffffffffc0201c52:	963e                	add	a2,a2,a5
ffffffffc0201c54:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c56:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c58:	9e81                	subw	a3,a3,s0
ffffffffc0201c5a:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c5c:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c5e:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201c60:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201c62:	ed99                	bnez	a1,ffffffffc0201c80 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201c64:	70a2                	ld	ra,40(sp)
ffffffffc0201c66:	7402                	ld	s0,32(sp)
ffffffffc0201c68:	64e2                	ld	s1,24(sp)
ffffffffc0201c6a:	853e                	mv	a0,a5
ffffffffc0201c6c:	6145                	addi	sp,sp,48
ffffffffc0201c6e:	8082                	ret
        intr_disable();
ffffffffc0201c70:	c95fe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201c74:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201c76:	4585                	li	a1,1
ffffffffc0201c78:	b7e9                	j	ffffffffc0201c42 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201c7a:	c85fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c7e:	b76d                	j	ffffffffc0201c28 <slob_alloc.constprop.0+0x4a>
ffffffffc0201c80:	e43e                	sd	a5,8(sp)
ffffffffc0201c82:	c7dfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c86:	67a2                	ld	a5,8(sp)
}
ffffffffc0201c88:	70a2                	ld	ra,40(sp)
ffffffffc0201c8a:	7402                	ld	s0,32(sp)
ffffffffc0201c8c:	64e2                	ld	s1,24(sp)
ffffffffc0201c8e:	853e                	mv	a0,a5
ffffffffc0201c90:	6145                	addi	sp,sp,48
ffffffffc0201c92:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c94:	6794                	ld	a3,8(a5)
ffffffffc0201c96:	e714                	sd	a3,8(a4)
ffffffffc0201c98:	b7e1                	j	ffffffffc0201c60 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201c9a:	c6bfe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201c9e:	4585                	li	a1,1
ffffffffc0201ca0:	b785                	j	ffffffffc0201c00 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ca2:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201ca4:	8732                	mv	a4,a2
ffffffffc0201ca6:	b755                	j	ffffffffc0201c4a <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201ca8:	00005697          	auipc	a3,0x5
ffffffffc0201cac:	96068693          	addi	a3,a3,-1696 # ffffffffc0206608 <etext+0xdc8>
ffffffffc0201cb0:	00004617          	auipc	a2,0x4
ffffffffc0201cb4:	57060613          	addi	a2,a2,1392 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0201cb8:	06300593          	li	a1,99
ffffffffc0201cbc:	00005517          	auipc	a0,0x5
ffffffffc0201cc0:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206628 <etext+0xde8>
ffffffffc0201cc4:	f82fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201cc8 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cc8:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cca:	00005517          	auipc	a0,0x5
ffffffffc0201cce:	97650513          	addi	a0,a0,-1674 # ffffffffc0206640 <etext+0xe00>
{
ffffffffc0201cd2:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cd4:	cc0fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cd8:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cda:	00005517          	auipc	a0,0x5
ffffffffc0201cde:	97e50513          	addi	a0,a0,-1666 # ffffffffc0206658 <etext+0xe18>
}
ffffffffc0201ce2:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ce4:	cb0fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ce8 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201ce8:	4501                	li	a0,0
ffffffffc0201cea:	8082                	ret

ffffffffc0201cec <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cec:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cee:	6685                	lui	a3,0x1
{
ffffffffc0201cf0:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cf2:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7be1>
ffffffffc0201cf4:	04a6f963          	bgeu	a3,a0,ffffffffc0201d46 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cf8:	e42a                	sd	a0,8(sp)
ffffffffc0201cfa:	4561                	li	a0,24
ffffffffc0201cfc:	e822                	sd	s0,16(sp)
ffffffffc0201cfe:	ee1ff0ef          	jal	ffffffffc0201bde <slob_alloc.constprop.0>
ffffffffc0201d02:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201d04:	c541                	beqz	a0,ffffffffc0201d8c <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201d06:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201d08:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201d0a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d0c:	00f75763          	bge	a4,a5,ffffffffc0201d1a <kmalloc+0x2e>
ffffffffc0201d10:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201d14:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d16:	fef74de3          	blt	a4,a5,ffffffffc0201d10 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201d1a:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d1c:	e5fff0ef          	jal	ffffffffc0201b7a <__slob_get_free_pages.constprop.0>
ffffffffc0201d20:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d22:	cd31                	beqz	a0,ffffffffc0201d7e <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d24:	100027f3          	csrr	a5,sstatus
ffffffffc0201d28:	8b89                	andi	a5,a5,2
ffffffffc0201d2a:	eb85                	bnez	a5,ffffffffc0201d5a <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d2c:	0009a797          	auipc	a5,0x9a
ffffffffc0201d30:	a047b783          	ld	a5,-1532(a5) # ffffffffc029b730 <bigblocks>
		bigblocks = bb;
ffffffffc0201d34:	0009a717          	auipc	a4,0x9a
ffffffffc0201d38:	9e873e23          	sd	s0,-1540(a4) # ffffffffc029b730 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d3c:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d3e:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d40:	60e2                	ld	ra,24(sp)
ffffffffc0201d42:	6105                	addi	sp,sp,32
ffffffffc0201d44:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d46:	0541                	addi	a0,a0,16
ffffffffc0201d48:	e97ff0ef          	jal	ffffffffc0201bde <slob_alloc.constprop.0>
ffffffffc0201d4c:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d4e:	0541                	addi	a0,a0,16
ffffffffc0201d50:	fbe5                	bnez	a5,ffffffffc0201d40 <kmalloc+0x54>
		return 0;
ffffffffc0201d52:	4501                	li	a0,0
}
ffffffffc0201d54:	60e2                	ld	ra,24(sp)
ffffffffc0201d56:	6105                	addi	sp,sp,32
ffffffffc0201d58:	8082                	ret
        intr_disable();
ffffffffc0201d5a:	babfe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d5e:	0009a797          	auipc	a5,0x9a
ffffffffc0201d62:	9d27b783          	ld	a5,-1582(a5) # ffffffffc029b730 <bigblocks>
		bigblocks = bb;
ffffffffc0201d66:	0009a717          	auipc	a4,0x9a
ffffffffc0201d6a:	9c873523          	sd	s0,-1590(a4) # ffffffffc029b730 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d6e:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201d70:	b8ffe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201d74:	6408                	ld	a0,8(s0)
}
ffffffffc0201d76:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201d78:	6442                	ld	s0,16(sp)
}
ffffffffc0201d7a:	6105                	addi	sp,sp,32
ffffffffc0201d7c:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d7e:	8522                	mv	a0,s0
ffffffffc0201d80:	45e1                	li	a1,24
ffffffffc0201d82:	ce7ff0ef          	jal	ffffffffc0201a68 <slob_free>
		return 0;
ffffffffc0201d86:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d88:	6442                	ld	s0,16(sp)
ffffffffc0201d8a:	b7e9                	j	ffffffffc0201d54 <kmalloc+0x68>
ffffffffc0201d8c:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201d8e:	4501                	li	a0,0
ffffffffc0201d90:	b7d1                	j	ffffffffc0201d54 <kmalloc+0x68>

ffffffffc0201d92 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d92:	c571                	beqz	a0,ffffffffc0201e5e <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d94:	03451793          	slli	a5,a0,0x34
ffffffffc0201d98:	e3e1                	bnez	a5,ffffffffc0201e58 <kfree+0xc6>
{
ffffffffc0201d9a:	1101                	addi	sp,sp,-32
ffffffffc0201d9c:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d9e:	100027f3          	csrr	a5,sstatus
ffffffffc0201da2:	8b89                	andi	a5,a5,2
ffffffffc0201da4:	e7c1                	bnez	a5,ffffffffc0201e2c <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201da6:	0009a797          	auipc	a5,0x9a
ffffffffc0201daa:	98a7b783          	ld	a5,-1654(a5) # ffffffffc029b730 <bigblocks>
    return 0;
ffffffffc0201dae:	4581                	li	a1,0
ffffffffc0201db0:	cbad                	beqz	a5,ffffffffc0201e22 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201db2:	0009a617          	auipc	a2,0x9a
ffffffffc0201db6:	97e60613          	addi	a2,a2,-1666 # ffffffffc029b730 <bigblocks>
ffffffffc0201dba:	a021                	j	ffffffffc0201dc2 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dbc:	01070613          	addi	a2,a4,16
ffffffffc0201dc0:	c3a5                	beqz	a5,ffffffffc0201e20 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201dc2:	6794                	ld	a3,8(a5)
ffffffffc0201dc4:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201dc6:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201dc8:	fea69ae3          	bne	a3,a0,ffffffffc0201dbc <kfree+0x2a>
				*last = bb->next;
ffffffffc0201dcc:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201dce:	edb5                	bnez	a1,ffffffffc0201e4a <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201dd0:	c02007b7          	lui	a5,0xc0200
ffffffffc0201dd4:	0af56263          	bltu	a0,a5,ffffffffc0201e78 <kfree+0xe6>
ffffffffc0201dd8:	0009a797          	auipc	a5,0x9a
ffffffffc0201ddc:	9787b783          	ld	a5,-1672(a5) # ffffffffc029b750 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201de0:	0009a697          	auipc	a3,0x9a
ffffffffc0201de4:	9786b683          	ld	a3,-1672(a3) # ffffffffc029b758 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201de8:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201dea:	00c55793          	srli	a5,a0,0xc
ffffffffc0201dee:	06d7f963          	bgeu	a5,a3,ffffffffc0201e60 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201df2:	00006617          	auipc	a2,0x6
ffffffffc0201df6:	bb663603          	ld	a2,-1098(a2) # ffffffffc02079a8 <nbase>
ffffffffc0201dfa:	0009a517          	auipc	a0,0x9a
ffffffffc0201dfe:	96653503          	ld	a0,-1690(a0) # ffffffffc029b760 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e02:	4314                	lw	a3,0(a4)
ffffffffc0201e04:	8f91                	sub	a5,a5,a2
ffffffffc0201e06:	079a                	slli	a5,a5,0x6
ffffffffc0201e08:	4585                	li	a1,1
ffffffffc0201e0a:	953e                	add	a0,a0,a5
ffffffffc0201e0c:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201e10:	e03a                	sd	a4,0(sp)
ffffffffc0201e12:	0d6000ef          	jal	ffffffffc0201ee8 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e16:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e18:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e1a:	45e1                	li	a1,24
}
ffffffffc0201e1c:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e1e:	b1a9                	j	ffffffffc0201a68 <slob_free>
ffffffffc0201e20:	e185                	bnez	a1,ffffffffc0201e40 <kfree+0xae>
}
ffffffffc0201e22:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e24:	1541                	addi	a0,a0,-16
ffffffffc0201e26:	4581                	li	a1,0
}
ffffffffc0201e28:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e2a:	b93d                	j	ffffffffc0201a68 <slob_free>
        intr_disable();
ffffffffc0201e2c:	e02a                	sd	a0,0(sp)
ffffffffc0201e2e:	ad7fe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e32:	0009a797          	auipc	a5,0x9a
ffffffffc0201e36:	8fe7b783          	ld	a5,-1794(a5) # ffffffffc029b730 <bigblocks>
ffffffffc0201e3a:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e3c:	4585                	li	a1,1
ffffffffc0201e3e:	fbb5                	bnez	a5,ffffffffc0201db2 <kfree+0x20>
ffffffffc0201e40:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e42:	abdfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e46:	6502                	ld	a0,0(sp)
ffffffffc0201e48:	bfe9                	j	ffffffffc0201e22 <kfree+0x90>
ffffffffc0201e4a:	e42a                	sd	a0,8(sp)
ffffffffc0201e4c:	e03a                	sd	a4,0(sp)
ffffffffc0201e4e:	ab1fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e52:	6522                	ld	a0,8(sp)
ffffffffc0201e54:	6702                	ld	a4,0(sp)
ffffffffc0201e56:	bfad                	j	ffffffffc0201dd0 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e58:	1541                	addi	a0,a0,-16
ffffffffc0201e5a:	4581                	li	a1,0
ffffffffc0201e5c:	b131                	j	ffffffffc0201a68 <slob_free>
ffffffffc0201e5e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e60:	00005617          	auipc	a2,0x5
ffffffffc0201e64:	84060613          	addi	a2,a2,-1984 # ffffffffc02066a0 <etext+0xe60>
ffffffffc0201e68:	06900593          	li	a1,105
ffffffffc0201e6c:	00004517          	auipc	a0,0x4
ffffffffc0201e70:	78c50513          	addi	a0,a0,1932 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0201e74:	dd2fe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e78:	86aa                	mv	a3,a0
ffffffffc0201e7a:	00004617          	auipc	a2,0x4
ffffffffc0201e7e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0206678 <etext+0xe38>
ffffffffc0201e82:	07700593          	li	a1,119
ffffffffc0201e86:	00004517          	auipc	a0,0x4
ffffffffc0201e8a:	77250513          	addi	a0,a0,1906 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0201e8e:	db8fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e92 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e92:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e94:	00005617          	auipc	a2,0x5
ffffffffc0201e98:	80c60613          	addi	a2,a2,-2036 # ffffffffc02066a0 <etext+0xe60>
ffffffffc0201e9c:	06900593          	li	a1,105
ffffffffc0201ea0:	00004517          	auipc	a0,0x4
ffffffffc0201ea4:	75850513          	addi	a0,a0,1880 # ffffffffc02065f8 <etext+0xdb8>
pa2page(uintptr_t pa)
ffffffffc0201ea8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201eaa:	d9cfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201eae <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eae:	100027f3          	csrr	a5,sstatus
ffffffffc0201eb2:	8b89                	andi	a5,a5,2
ffffffffc0201eb4:	e799                	bnez	a5,ffffffffc0201ec2 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eb6:	0009a797          	auipc	a5,0x9a
ffffffffc0201eba:	8827b783          	ld	a5,-1918(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201ebe:	6f9c                	ld	a5,24(a5)
ffffffffc0201ec0:	8782                	jr	a5
{
ffffffffc0201ec2:	1101                	addi	sp,sp,-32
ffffffffc0201ec4:	ec06                	sd	ra,24(sp)
ffffffffc0201ec6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201ec8:	a3dfe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ecc:	0009a797          	auipc	a5,0x9a
ffffffffc0201ed0:	86c7b783          	ld	a5,-1940(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201ed4:	6522                	ld	a0,8(sp)
ffffffffc0201ed6:	6f9c                	ld	a5,24(a5)
ffffffffc0201ed8:	9782                	jalr	a5
ffffffffc0201eda:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201edc:	a23fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ee0:	60e2                	ld	ra,24(sp)
ffffffffc0201ee2:	6522                	ld	a0,8(sp)
ffffffffc0201ee4:	6105                	addi	sp,sp,32
ffffffffc0201ee6:	8082                	ret

ffffffffc0201ee8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ee8:	100027f3          	csrr	a5,sstatus
ffffffffc0201eec:	8b89                	andi	a5,a5,2
ffffffffc0201eee:	e799                	bnez	a5,ffffffffc0201efc <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ef0:	0009a797          	auipc	a5,0x9a
ffffffffc0201ef4:	8487b783          	ld	a5,-1976(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201ef8:	739c                	ld	a5,32(a5)
ffffffffc0201efa:	8782                	jr	a5
{
ffffffffc0201efc:	1101                	addi	sp,sp,-32
ffffffffc0201efe:	ec06                	sd	ra,24(sp)
ffffffffc0201f00:	e42e                	sd	a1,8(sp)
ffffffffc0201f02:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201f04:	a01fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f08:	0009a797          	auipc	a5,0x9a
ffffffffc0201f0c:	8307b783          	ld	a5,-2000(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201f10:	65a2                	ld	a1,8(sp)
ffffffffc0201f12:	6502                	ld	a0,0(sp)
ffffffffc0201f14:	739c                	ld	a5,32(a5)
ffffffffc0201f16:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f18:	60e2                	ld	ra,24(sp)
ffffffffc0201f1a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f1c:	9e3fe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f20 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f20:	100027f3          	csrr	a5,sstatus
ffffffffc0201f24:	8b89                	andi	a5,a5,2
ffffffffc0201f26:	e799                	bnez	a5,ffffffffc0201f34 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f28:	0009a797          	auipc	a5,0x9a
ffffffffc0201f2c:	8107b783          	ld	a5,-2032(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201f30:	779c                	ld	a5,40(a5)
ffffffffc0201f32:	8782                	jr	a5
{
ffffffffc0201f34:	1101                	addi	sp,sp,-32
ffffffffc0201f36:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f38:	9cdfe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f3c:	00099797          	auipc	a5,0x99
ffffffffc0201f40:	7fc7b783          	ld	a5,2044(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201f44:	779c                	ld	a5,40(a5)
ffffffffc0201f46:	9782                	jalr	a5
ffffffffc0201f48:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f4a:	9b5fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f4e:	60e2                	ld	ra,24(sp)
ffffffffc0201f50:	6522                	ld	a0,8(sp)
ffffffffc0201f52:	6105                	addi	sp,sp,32
ffffffffc0201f54:	8082                	ret

ffffffffc0201f56 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f56:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f5a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f5e:	078e                	slli	a5,a5,0x3
ffffffffc0201f60:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f64:	6314                	ld	a3,0(a4)
{
ffffffffc0201f66:	7139                	addi	sp,sp,-64
ffffffffc0201f68:	f822                	sd	s0,48(sp)
ffffffffc0201f6a:	f426                	sd	s1,40(sp)
ffffffffc0201f6c:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f6e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f72:	842e                	mv	s0,a1
ffffffffc0201f74:	8832                	mv	a6,a2
ffffffffc0201f76:	00099497          	auipc	s1,0x99
ffffffffc0201f7a:	7e248493          	addi	s1,s1,2018 # ffffffffc029b758 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f7e:	ebd1                	bnez	a5,ffffffffc0202012 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f80:	16060d63          	beqz	a2,ffffffffc02020fa <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f84:	100027f3          	csrr	a5,sstatus
ffffffffc0201f88:	8b89                	andi	a5,a5,2
ffffffffc0201f8a:	16079e63          	bnez	a5,ffffffffc0202106 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f8e:	00099797          	auipc	a5,0x99
ffffffffc0201f92:	7aa7b783          	ld	a5,1962(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0201f96:	4505                	li	a0,1
ffffffffc0201f98:	e43a                	sd	a4,8(sp)
ffffffffc0201f9a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f9c:	e832                	sd	a2,16(sp)
ffffffffc0201f9e:	9782                	jalr	a5
ffffffffc0201fa0:	6722                	ld	a4,8(sp)
ffffffffc0201fa2:	6842                	ld	a6,16(sp)
ffffffffc0201fa4:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fa6:	14078a63          	beqz	a5,ffffffffc02020fa <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201faa:	00099517          	auipc	a0,0x99
ffffffffc0201fae:	7b653503          	ld	a0,1974(a0) # ffffffffc029b760 <pages>
ffffffffc0201fb2:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fb6:	00099497          	auipc	s1,0x99
ffffffffc0201fba:	7a248493          	addi	s1,s1,1954 # ffffffffc029b758 <npage>
ffffffffc0201fbe:	40a78533          	sub	a0,a5,a0
ffffffffc0201fc2:	8519                	srai	a0,a0,0x6
ffffffffc0201fc4:	9546                	add	a0,a0,a7
ffffffffc0201fc6:	6090                	ld	a2,0(s1)
ffffffffc0201fc8:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201fcc:	4585                	li	a1,1
ffffffffc0201fce:	82b1                	srli	a3,a3,0xc
ffffffffc0201fd0:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fd2:	0532                	slli	a0,a0,0xc
ffffffffc0201fd4:	1ac6f763          	bgeu	a3,a2,ffffffffc0202182 <get_pte+0x22c>
ffffffffc0201fd8:	00099697          	auipc	a3,0x99
ffffffffc0201fdc:	7786b683          	ld	a3,1912(a3) # ffffffffc029b750 <va_pa_offset>
ffffffffc0201fe0:	6605                	lui	a2,0x1
ffffffffc0201fe2:	4581                	li	a1,0
ffffffffc0201fe4:	9536                	add	a0,a0,a3
ffffffffc0201fe6:	ec42                	sd	a6,24(sp)
ffffffffc0201fe8:	e83e                	sd	a5,16(sp)
ffffffffc0201fea:	e43a                	sd	a4,8(sp)
ffffffffc0201fec:	02b030ef          	jal	ffffffffc0205816 <memset>
    return page - pages + nbase;
ffffffffc0201ff0:	00099697          	auipc	a3,0x99
ffffffffc0201ff4:	7706b683          	ld	a3,1904(a3) # ffffffffc029b760 <pages>
ffffffffc0201ff8:	67c2                	ld	a5,16(sp)
ffffffffc0201ffa:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ffe:	6722                	ld	a4,8(sp)
ffffffffc0202000:	40d786b3          	sub	a3,a5,a3
ffffffffc0202004:	8699                	srai	a3,a3,0x6
ffffffffc0202006:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202008:	06aa                	slli	a3,a3,0xa
ffffffffc020200a:	6862                	ld	a6,24(sp)
ffffffffc020200c:	0116e693          	ori	a3,a3,17
ffffffffc0202010:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202012:	c006f693          	andi	a3,a3,-1024
ffffffffc0202016:	6098                	ld	a4,0(s1)
ffffffffc0202018:	068a                	slli	a3,a3,0x2
ffffffffc020201a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020201e:	14e7f663          	bgeu	a5,a4,ffffffffc020216a <get_pte+0x214>
ffffffffc0202022:	00099897          	auipc	a7,0x99
ffffffffc0202026:	72e88893          	addi	a7,a7,1838 # ffffffffc029b750 <va_pa_offset>
ffffffffc020202a:	0008b603          	ld	a2,0(a7)
ffffffffc020202e:	01545793          	srli	a5,s0,0x15
ffffffffc0202032:	1ff7f793          	andi	a5,a5,511
ffffffffc0202036:	96b2                	add	a3,a3,a2
ffffffffc0202038:	078e                	slli	a5,a5,0x3
ffffffffc020203a:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020203c:	6394                	ld	a3,0(a5)
ffffffffc020203e:	0016f613          	andi	a2,a3,1
ffffffffc0202042:	e659                	bnez	a2,ffffffffc02020d0 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202044:	0a080b63          	beqz	a6,ffffffffc02020fa <get_pte+0x1a4>
ffffffffc0202048:	10002773          	csrr	a4,sstatus
ffffffffc020204c:	8b09                	andi	a4,a4,2
ffffffffc020204e:	ef71                	bnez	a4,ffffffffc020212a <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202050:	00099717          	auipc	a4,0x99
ffffffffc0202054:	6e873703          	ld	a4,1768(a4) # ffffffffc029b738 <pmm_manager>
ffffffffc0202058:	4505                	li	a0,1
ffffffffc020205a:	e43e                	sd	a5,8(sp)
ffffffffc020205c:	6f18                	ld	a4,24(a4)
ffffffffc020205e:	9702                	jalr	a4
ffffffffc0202060:	67a2                	ld	a5,8(sp)
ffffffffc0202062:	872a                	mv	a4,a0
ffffffffc0202064:	00099897          	auipc	a7,0x99
ffffffffc0202068:	6ec88893          	addi	a7,a7,1772 # ffffffffc029b750 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020206c:	c759                	beqz	a4,ffffffffc02020fa <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc020206e:	00099697          	auipc	a3,0x99
ffffffffc0202072:	6f26b683          	ld	a3,1778(a3) # ffffffffc029b760 <pages>
ffffffffc0202076:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020207a:	608c                	ld	a1,0(s1)
ffffffffc020207c:	40d706b3          	sub	a3,a4,a3
ffffffffc0202080:	8699                	srai	a3,a3,0x6
ffffffffc0202082:	96c2                	add	a3,a3,a6
ffffffffc0202084:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0202088:	4505                	li	a0,1
ffffffffc020208a:	8231                	srli	a2,a2,0xc
ffffffffc020208c:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc020208e:	06b2                	slli	a3,a3,0xc
ffffffffc0202090:	10b67663          	bgeu	a2,a1,ffffffffc020219c <get_pte+0x246>
ffffffffc0202094:	0008b503          	ld	a0,0(a7)
ffffffffc0202098:	6605                	lui	a2,0x1
ffffffffc020209a:	4581                	li	a1,0
ffffffffc020209c:	9536                	add	a0,a0,a3
ffffffffc020209e:	e83a                	sd	a4,16(sp)
ffffffffc02020a0:	e43e                	sd	a5,8(sp)
ffffffffc02020a2:	774030ef          	jal	ffffffffc0205816 <memset>
    return page - pages + nbase;
ffffffffc02020a6:	00099697          	auipc	a3,0x99
ffffffffc02020aa:	6ba6b683          	ld	a3,1722(a3) # ffffffffc029b760 <pages>
ffffffffc02020ae:	6742                	ld	a4,16(sp)
ffffffffc02020b0:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020b4:	67a2                	ld	a5,8(sp)
ffffffffc02020b6:	40d706b3          	sub	a3,a4,a3
ffffffffc02020ba:	8699                	srai	a3,a3,0x6
ffffffffc02020bc:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020be:	06aa                	slli	a3,a3,0xa
ffffffffc02020c0:	0116e693          	ori	a3,a3,17
ffffffffc02020c4:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020c6:	6098                	ld	a4,0(s1)
ffffffffc02020c8:	00099897          	auipc	a7,0x99
ffffffffc02020cc:	68888893          	addi	a7,a7,1672 # ffffffffc029b750 <va_pa_offset>
ffffffffc02020d0:	c006f693          	andi	a3,a3,-1024
ffffffffc02020d4:	068a                	slli	a3,a3,0x2
ffffffffc02020d6:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020da:	06e7fc63          	bgeu	a5,a4,ffffffffc0202152 <get_pte+0x1fc>
ffffffffc02020de:	0008b783          	ld	a5,0(a7)
ffffffffc02020e2:	8031                	srli	s0,s0,0xc
ffffffffc02020e4:	1ff47413          	andi	s0,s0,511
ffffffffc02020e8:	040e                	slli	s0,s0,0x3
ffffffffc02020ea:	96be                	add	a3,a3,a5
}
ffffffffc02020ec:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020ee:	00868533          	add	a0,a3,s0
}
ffffffffc02020f2:	7442                	ld	s0,48(sp)
ffffffffc02020f4:	74a2                	ld	s1,40(sp)
ffffffffc02020f6:	6121                	addi	sp,sp,64
ffffffffc02020f8:	8082                	ret
ffffffffc02020fa:	70e2                	ld	ra,56(sp)
ffffffffc02020fc:	7442                	ld	s0,48(sp)
ffffffffc02020fe:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202100:	4501                	li	a0,0
}
ffffffffc0202102:	6121                	addi	sp,sp,64
ffffffffc0202104:	8082                	ret
        intr_disable();
ffffffffc0202106:	e83a                	sd	a4,16(sp)
ffffffffc0202108:	ec32                	sd	a2,24(sp)
ffffffffc020210a:	ffafe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020210e:	00099797          	auipc	a5,0x99
ffffffffc0202112:	62a7b783          	ld	a5,1578(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0202116:	4505                	li	a0,1
ffffffffc0202118:	6f9c                	ld	a5,24(a5)
ffffffffc020211a:	9782                	jalr	a5
ffffffffc020211c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020211e:	fe0fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202122:	6862                	ld	a6,24(sp)
ffffffffc0202124:	6742                	ld	a4,16(sp)
ffffffffc0202126:	67a2                	ld	a5,8(sp)
ffffffffc0202128:	bdbd                	j	ffffffffc0201fa6 <get_pte+0x50>
        intr_disable();
ffffffffc020212a:	e83e                	sd	a5,16(sp)
ffffffffc020212c:	fd8fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202130:	00099717          	auipc	a4,0x99
ffffffffc0202134:	60873703          	ld	a4,1544(a4) # ffffffffc029b738 <pmm_manager>
ffffffffc0202138:	4505                	li	a0,1
ffffffffc020213a:	6f18                	ld	a4,24(a4)
ffffffffc020213c:	9702                	jalr	a4
ffffffffc020213e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202140:	fbefe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202144:	6722                	ld	a4,8(sp)
ffffffffc0202146:	67c2                	ld	a5,16(sp)
ffffffffc0202148:	00099897          	auipc	a7,0x99
ffffffffc020214c:	60888893          	addi	a7,a7,1544 # ffffffffc029b750 <va_pa_offset>
ffffffffc0202150:	bf31                	j	ffffffffc020206c <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202152:	00004617          	auipc	a2,0x4
ffffffffc0202156:	47e60613          	addi	a2,a2,1150 # ffffffffc02065d0 <etext+0xd90>
ffffffffc020215a:	0fa00593          	li	a1,250
ffffffffc020215e:	00004517          	auipc	a0,0x4
ffffffffc0202162:	56250513          	addi	a0,a0,1378 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202166:	ae0fe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020216a:	00004617          	auipc	a2,0x4
ffffffffc020216e:	46660613          	addi	a2,a2,1126 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0202172:	0ed00593          	li	a1,237
ffffffffc0202176:	00004517          	auipc	a0,0x4
ffffffffc020217a:	54a50513          	addi	a0,a0,1354 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020217e:	ac8fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202182:	86aa                	mv	a3,a0
ffffffffc0202184:	00004617          	auipc	a2,0x4
ffffffffc0202188:	44c60613          	addi	a2,a2,1100 # ffffffffc02065d0 <etext+0xd90>
ffffffffc020218c:	0e900593          	li	a1,233
ffffffffc0202190:	00004517          	auipc	a0,0x4
ffffffffc0202194:	53050513          	addi	a0,a0,1328 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202198:	aaefe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020219c:	00004617          	auipc	a2,0x4
ffffffffc02021a0:	43460613          	addi	a2,a2,1076 # ffffffffc02065d0 <etext+0xd90>
ffffffffc02021a4:	0f700593          	li	a1,247
ffffffffc02021a8:	00004517          	auipc	a0,0x4
ffffffffc02021ac:	51850513          	addi	a0,a0,1304 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02021b0:	a96fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02021b4 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021b4:	1141                	addi	sp,sp,-16
ffffffffc02021b6:	e022                	sd	s0,0(sp)
ffffffffc02021b8:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021ba:	4601                	li	a2,0
{
ffffffffc02021bc:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021be:	d99ff0ef          	jal	ffffffffc0201f56 <get_pte>
    if (ptep_store != NULL)
ffffffffc02021c2:	c011                	beqz	s0,ffffffffc02021c6 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021c4:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021c6:	c511                	beqz	a0,ffffffffc02021d2 <get_page+0x1e>
ffffffffc02021c8:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021ca:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021cc:	0017f713          	andi	a4,a5,1
ffffffffc02021d0:	e709                	bnez	a4,ffffffffc02021da <get_page+0x26>
}
ffffffffc02021d2:	60a2                	ld	ra,8(sp)
ffffffffc02021d4:	6402                	ld	s0,0(sp)
ffffffffc02021d6:	0141                	addi	sp,sp,16
ffffffffc02021d8:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02021da:	00099717          	auipc	a4,0x99
ffffffffc02021de:	57e73703          	ld	a4,1406(a4) # ffffffffc029b758 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021e2:	078a                	slli	a5,a5,0x2
ffffffffc02021e4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021e6:	00e7ff63          	bgeu	a5,a4,ffffffffc0202204 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02021ea:	00099517          	auipc	a0,0x99
ffffffffc02021ee:	57653503          	ld	a0,1398(a0) # ffffffffc029b760 <pages>
ffffffffc02021f2:	60a2                	ld	ra,8(sp)
ffffffffc02021f4:	6402                	ld	s0,0(sp)
ffffffffc02021f6:	079a                	slli	a5,a5,0x6
ffffffffc02021f8:	fe000737          	lui	a4,0xfe000
ffffffffc02021fc:	97ba                	add	a5,a5,a4
ffffffffc02021fe:	953e                	add	a0,a0,a5
ffffffffc0202200:	0141                	addi	sp,sp,16
ffffffffc0202202:	8082                	ret
ffffffffc0202204:	c8fff0ef          	jal	ffffffffc0201e92 <pa2page.part.0>

ffffffffc0202208 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202208:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020220a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020220e:	e486                	sd	ra,72(sp)
ffffffffc0202210:	e0a2                	sd	s0,64(sp)
ffffffffc0202212:	fc26                	sd	s1,56(sp)
ffffffffc0202214:	f84a                	sd	s2,48(sp)
ffffffffc0202216:	f44e                	sd	s3,40(sp)
ffffffffc0202218:	f052                	sd	s4,32(sp)
ffffffffc020221a:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020221c:	03479713          	slli	a4,a5,0x34
ffffffffc0202220:	ef61                	bnez	a4,ffffffffc02022f8 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202222:	00200a37          	lui	s4,0x200
ffffffffc0202226:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020222a:	0145b733          	sltu	a4,a1,s4
ffffffffc020222e:	0017b793          	seqz	a5,a5
ffffffffc0202232:	8fd9                	or	a5,a5,a4
ffffffffc0202234:	842e                	mv	s0,a1
ffffffffc0202236:	84b2                	mv	s1,a2
ffffffffc0202238:	e3e5                	bnez	a5,ffffffffc0202318 <unmap_range+0x110>
ffffffffc020223a:	4785                	li	a5,1
ffffffffc020223c:	07fe                	slli	a5,a5,0x1f
ffffffffc020223e:	0785                	addi	a5,a5,1
ffffffffc0202240:	892a                	mv	s2,a0
ffffffffc0202242:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202244:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202248:	0cf67863          	bgeu	a2,a5,ffffffffc0202318 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020224c:	4601                	li	a2,0
ffffffffc020224e:	85a2                	mv	a1,s0
ffffffffc0202250:	854a                	mv	a0,s2
ffffffffc0202252:	d05ff0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc0202256:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202258:	cd31                	beqz	a0,ffffffffc02022b4 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc020225a:	6118                	ld	a4,0(a0)
ffffffffc020225c:	ef11                	bnez	a4,ffffffffc0202278 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020225e:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202260:	c019                	beqz	s0,ffffffffc0202266 <unmap_range+0x5e>
ffffffffc0202262:	fe9465e3          	bltu	s0,s1,ffffffffc020224c <unmap_range+0x44>
}
ffffffffc0202266:	60a6                	ld	ra,72(sp)
ffffffffc0202268:	6406                	ld	s0,64(sp)
ffffffffc020226a:	74e2                	ld	s1,56(sp)
ffffffffc020226c:	7942                	ld	s2,48(sp)
ffffffffc020226e:	79a2                	ld	s3,40(sp)
ffffffffc0202270:	7a02                	ld	s4,32(sp)
ffffffffc0202272:	6ae2                	ld	s5,24(sp)
ffffffffc0202274:	6161                	addi	sp,sp,80
ffffffffc0202276:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202278:	00177693          	andi	a3,a4,1
ffffffffc020227c:	d2ed                	beqz	a3,ffffffffc020225e <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc020227e:	00099697          	auipc	a3,0x99
ffffffffc0202282:	4da6b683          	ld	a3,1242(a3) # ffffffffc029b758 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202286:	070a                	slli	a4,a4,0x2
ffffffffc0202288:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020228a:	0ad77763          	bgeu	a4,a3,ffffffffc0202338 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc020228e:	00099517          	auipc	a0,0x99
ffffffffc0202292:	4d253503          	ld	a0,1234(a0) # ffffffffc029b760 <pages>
ffffffffc0202296:	071a                	slli	a4,a4,0x6
ffffffffc0202298:	fe0006b7          	lui	a3,0xfe000
ffffffffc020229c:	9736                	add	a4,a4,a3
ffffffffc020229e:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc02022a0:	4118                	lw	a4,0(a0)
ffffffffc02022a2:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd64877>
ffffffffc02022a4:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02022a6:	cb19                	beqz	a4,ffffffffc02022bc <unmap_range+0xb4>
        *ptep = 0;
ffffffffc02022a8:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02022ac:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02022b0:	944e                	add	s0,s0,s3
ffffffffc02022b2:	b77d                	j	ffffffffc0202260 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022b4:	9452                	add	s0,s0,s4
ffffffffc02022b6:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02022ba:	b75d                	j	ffffffffc0202260 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022bc:	10002773          	csrr	a4,sstatus
ffffffffc02022c0:	8b09                	andi	a4,a4,2
ffffffffc02022c2:	eb19                	bnez	a4,ffffffffc02022d8 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02022c4:	00099717          	auipc	a4,0x99
ffffffffc02022c8:	47473703          	ld	a4,1140(a4) # ffffffffc029b738 <pmm_manager>
ffffffffc02022cc:	4585                	li	a1,1
ffffffffc02022ce:	e03e                	sd	a5,0(sp)
ffffffffc02022d0:	7318                	ld	a4,32(a4)
ffffffffc02022d2:	9702                	jalr	a4
    if (flag)
ffffffffc02022d4:	6782                	ld	a5,0(sp)
ffffffffc02022d6:	bfc9                	j	ffffffffc02022a8 <unmap_range+0xa0>
        intr_disable();
ffffffffc02022d8:	e43e                	sd	a5,8(sp)
ffffffffc02022da:	e02a                	sd	a0,0(sp)
ffffffffc02022dc:	e28fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02022e0:	00099717          	auipc	a4,0x99
ffffffffc02022e4:	45873703          	ld	a4,1112(a4) # ffffffffc029b738 <pmm_manager>
ffffffffc02022e8:	6502                	ld	a0,0(sp)
ffffffffc02022ea:	4585                	li	a1,1
ffffffffc02022ec:	7318                	ld	a4,32(a4)
ffffffffc02022ee:	9702                	jalr	a4
        intr_enable();
ffffffffc02022f0:	e0efe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02022f4:	67a2                	ld	a5,8(sp)
ffffffffc02022f6:	bf4d                	j	ffffffffc02022a8 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022f8:	00004697          	auipc	a3,0x4
ffffffffc02022fc:	3d868693          	addi	a3,a3,984 # ffffffffc02066d0 <etext+0xe90>
ffffffffc0202300:	00004617          	auipc	a2,0x4
ffffffffc0202304:	f2060613          	addi	a2,a2,-224 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202308:	12000593          	li	a1,288
ffffffffc020230c:	00004517          	auipc	a0,0x4
ffffffffc0202310:	3b450513          	addi	a0,a0,948 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202314:	932fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202318:	00004697          	auipc	a3,0x4
ffffffffc020231c:	3e868693          	addi	a3,a3,1000 # ffffffffc0206700 <etext+0xec0>
ffffffffc0202320:	00004617          	auipc	a2,0x4
ffffffffc0202324:	f0060613          	addi	a2,a2,-256 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202328:	12100593          	li	a1,289
ffffffffc020232c:	00004517          	auipc	a0,0x4
ffffffffc0202330:	39450513          	addi	a0,a0,916 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202334:	912fe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202338:	b5bff0ef          	jal	ffffffffc0201e92 <pa2page.part.0>

ffffffffc020233c <exit_range>:
{
ffffffffc020233c:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020233e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202342:	ed06                	sd	ra,152(sp)
ffffffffc0202344:	e922                	sd	s0,144(sp)
ffffffffc0202346:	e526                	sd	s1,136(sp)
ffffffffc0202348:	e14a                	sd	s2,128(sp)
ffffffffc020234a:	fcce                	sd	s3,120(sp)
ffffffffc020234c:	f8d2                	sd	s4,112(sp)
ffffffffc020234e:	f4d6                	sd	s5,104(sp)
ffffffffc0202350:	f0da                	sd	s6,96(sp)
ffffffffc0202352:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202354:	17d2                	slli	a5,a5,0x34
ffffffffc0202356:	22079263          	bnez	a5,ffffffffc020257a <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc020235a:	00200937          	lui	s2,0x200
ffffffffc020235e:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202362:	0125b733          	sltu	a4,a1,s2
ffffffffc0202366:	0017b793          	seqz	a5,a5
ffffffffc020236a:	8fd9                	or	a5,a5,a4
ffffffffc020236c:	26079263          	bnez	a5,ffffffffc02025d0 <exit_range+0x294>
ffffffffc0202370:	4785                	li	a5,1
ffffffffc0202372:	07fe                	slli	a5,a5,0x1f
ffffffffc0202374:	0785                	addi	a5,a5,1
ffffffffc0202376:	24f67d63          	bgeu	a2,a5,ffffffffc02025d0 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020237a:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020237e:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202382:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202384:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202386:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc020238a:	00099a97          	auipc	s5,0x99
ffffffffc020238e:	3cea8a93          	addi	s5,s5,974 # ffffffffc029b758 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202392:	400009b7          	lui	s3,0x40000
ffffffffc0202396:	a809                	j	ffffffffc02023a8 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc0202398:	013487b3          	add	a5,s1,s3
ffffffffc020239c:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02023a0:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02023a2:	c3f1                	beqz	a5,ffffffffc0202466 <exit_range+0x12a>
ffffffffc02023a4:	0cc7f163          	bgeu	a5,a2,ffffffffc0202466 <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023a8:	01e4d413          	srli	s0,s1,0x1e
ffffffffc02023ac:	1ff47413          	andi	s0,s0,511
ffffffffc02023b0:	040e                	slli	s0,s0,0x3
ffffffffc02023b2:	9452                	add	s0,s0,s4
ffffffffc02023b4:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02023b8:	0018f793          	andi	a5,a7,1
ffffffffc02023bc:	dff1                	beqz	a5,ffffffffc0202398 <exit_range+0x5c>
ffffffffc02023be:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023c2:	088a                	slli	a7,a7,0x2
ffffffffc02023c4:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02023c8:	20f8f263          	bgeu	a7,a5,ffffffffc02025cc <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023cc:	fff802b7          	lui	t0,0xfff80
ffffffffc02023d0:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02023d4:	000803b7          	lui	t2,0x80
ffffffffc02023d8:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02023dc:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023e0:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02023e2:	1cf77863          	bgeu	a4,a5,ffffffffc02025b2 <exit_range+0x276>
ffffffffc02023e6:	00099f97          	auipc	t6,0x99
ffffffffc02023ea:	36af8f93          	addi	t6,t6,874 # ffffffffc029b750 <va_pa_offset>
ffffffffc02023ee:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02023f2:	4e85                	li	t4,1
ffffffffc02023f4:	6b05                	lui	s6,0x1
ffffffffc02023f6:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023f8:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023fc:	01585713          	srli	a4,a6,0x15
ffffffffc0202400:	1ff77713          	andi	a4,a4,511
ffffffffc0202404:	070e                	slli	a4,a4,0x3
ffffffffc0202406:	9772                	add	a4,a4,t3
ffffffffc0202408:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc020240a:	0017f693          	andi	a3,a5,1
ffffffffc020240e:	e6bd                	bnez	a3,ffffffffc020247c <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202410:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc0202412:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202414:	00080863          	beqz	a6,ffffffffc0202424 <exit_range+0xe8>
ffffffffc0202418:	879a                	mv	a5,t1
ffffffffc020241a:	00667363          	bgeu	a2,t1,ffffffffc0202420 <exit_range+0xe4>
ffffffffc020241e:	87b2                	mv	a5,a2
ffffffffc0202420:	fcf86ee3          	bltu	a6,a5,ffffffffc02023fc <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202424:	f60e8ae3          	beqz	t4,ffffffffc0202398 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202428:	000ab783          	ld	a5,0(s5)
ffffffffc020242c:	1af8f063          	bgeu	a7,a5,ffffffffc02025cc <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202430:	00099517          	auipc	a0,0x99
ffffffffc0202434:	33053503          	ld	a0,816(a0) # ffffffffc029b760 <pages>
ffffffffc0202438:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020243a:	100027f3          	csrr	a5,sstatus
ffffffffc020243e:	8b89                	andi	a5,a5,2
ffffffffc0202440:	10079b63          	bnez	a5,ffffffffc0202556 <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202444:	00099797          	auipc	a5,0x99
ffffffffc0202448:	2f47b783          	ld	a5,756(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc020244c:	4585                	li	a1,1
ffffffffc020244e:	e432                	sd	a2,8(sp)
ffffffffc0202450:	739c                	ld	a5,32(a5)
ffffffffc0202452:	9782                	jalr	a5
ffffffffc0202454:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202456:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc020245a:	013487b3          	add	a5,s1,s3
ffffffffc020245e:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202462:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202464:	f3a1                	bnez	a5,ffffffffc02023a4 <exit_range+0x68>
}
ffffffffc0202466:	60ea                	ld	ra,152(sp)
ffffffffc0202468:	644a                	ld	s0,144(sp)
ffffffffc020246a:	64aa                	ld	s1,136(sp)
ffffffffc020246c:	690a                	ld	s2,128(sp)
ffffffffc020246e:	79e6                	ld	s3,120(sp)
ffffffffc0202470:	7a46                	ld	s4,112(sp)
ffffffffc0202472:	7aa6                	ld	s5,104(sp)
ffffffffc0202474:	7b06                	ld	s6,96(sp)
ffffffffc0202476:	6be6                	ld	s7,88(sp)
ffffffffc0202478:	610d                	addi	sp,sp,160
ffffffffc020247a:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020247c:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202480:	078a                	slli	a5,a5,0x2
ffffffffc0202482:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202484:	14a7f463          	bgeu	a5,a0,ffffffffc02025cc <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202488:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc020248a:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc020248e:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202492:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc0202496:	10abf263          	bgeu	s7,a0,ffffffffc020259a <exit_range+0x25e>
ffffffffc020249a:	000fb783          	ld	a5,0(t6)
ffffffffc020249e:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024a0:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc02024a4:	629c                	ld	a5,0(a3)
ffffffffc02024a6:	8b85                	andi	a5,a5,1
ffffffffc02024a8:	f7ad                	bnez	a5,ffffffffc0202412 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024aa:	06a1                	addi	a3,a3,8
ffffffffc02024ac:	fea69ce3          	bne	a3,a0,ffffffffc02024a4 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc02024b0:	00099517          	auipc	a0,0x99
ffffffffc02024b4:	2b053503          	ld	a0,688(a0) # ffffffffc029b760 <pages>
ffffffffc02024b8:	952e                	add	a0,a0,a1
ffffffffc02024ba:	100027f3          	csrr	a5,sstatus
ffffffffc02024be:	8b89                	andi	a5,a5,2
ffffffffc02024c0:	e3b9                	bnez	a5,ffffffffc0202506 <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02024c2:	00099797          	auipc	a5,0x99
ffffffffc02024c6:	2767b783          	ld	a5,630(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc02024ca:	4585                	li	a1,1
ffffffffc02024cc:	e0b2                	sd	a2,64(sp)
ffffffffc02024ce:	739c                	ld	a5,32(a5)
ffffffffc02024d0:	fc1a                	sd	t1,56(sp)
ffffffffc02024d2:	f846                	sd	a7,48(sp)
ffffffffc02024d4:	f47a                	sd	t5,40(sp)
ffffffffc02024d6:	f072                	sd	t3,32(sp)
ffffffffc02024d8:	ec76                	sd	t4,24(sp)
ffffffffc02024da:	e842                	sd	a6,16(sp)
ffffffffc02024dc:	e43a                	sd	a4,8(sp)
ffffffffc02024de:	9782                	jalr	a5
    if (flag)
ffffffffc02024e0:	6722                	ld	a4,8(sp)
ffffffffc02024e2:	6842                	ld	a6,16(sp)
ffffffffc02024e4:	6ee2                	ld	t4,24(sp)
ffffffffc02024e6:	7e02                	ld	t3,32(sp)
ffffffffc02024e8:	7f22                	ld	t5,40(sp)
ffffffffc02024ea:	78c2                	ld	a7,48(sp)
ffffffffc02024ec:	7362                	ld	t1,56(sp)
ffffffffc02024ee:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024f0:	fff802b7          	lui	t0,0xfff80
ffffffffc02024f4:	000803b7          	lui	t2,0x80
ffffffffc02024f8:	00099f97          	auipc	t6,0x99
ffffffffc02024fc:	258f8f93          	addi	t6,t6,600 # ffffffffc029b750 <va_pa_offset>
ffffffffc0202500:	00073023          	sd	zero,0(a4)
ffffffffc0202504:	b739                	j	ffffffffc0202412 <exit_range+0xd6>
        intr_disable();
ffffffffc0202506:	e4b2                	sd	a2,72(sp)
ffffffffc0202508:	e09a                	sd	t1,64(sp)
ffffffffc020250a:	fc46                	sd	a7,56(sp)
ffffffffc020250c:	f47a                	sd	t5,40(sp)
ffffffffc020250e:	f072                	sd	t3,32(sp)
ffffffffc0202510:	ec76                	sd	t4,24(sp)
ffffffffc0202512:	e842                	sd	a6,16(sp)
ffffffffc0202514:	e43a                	sd	a4,8(sp)
ffffffffc0202516:	f82a                	sd	a0,48(sp)
ffffffffc0202518:	becfe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020251c:	00099797          	auipc	a5,0x99
ffffffffc0202520:	21c7b783          	ld	a5,540(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0202524:	7542                	ld	a0,48(sp)
ffffffffc0202526:	4585                	li	a1,1
ffffffffc0202528:	739c                	ld	a5,32(a5)
ffffffffc020252a:	9782                	jalr	a5
        intr_enable();
ffffffffc020252c:	bd2fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202530:	6722                	ld	a4,8(sp)
ffffffffc0202532:	6626                	ld	a2,72(sp)
ffffffffc0202534:	6306                	ld	t1,64(sp)
ffffffffc0202536:	78e2                	ld	a7,56(sp)
ffffffffc0202538:	7f22                	ld	t5,40(sp)
ffffffffc020253a:	7e02                	ld	t3,32(sp)
ffffffffc020253c:	6ee2                	ld	t4,24(sp)
ffffffffc020253e:	6842                	ld	a6,16(sp)
ffffffffc0202540:	00099f97          	auipc	t6,0x99
ffffffffc0202544:	210f8f93          	addi	t6,t6,528 # ffffffffc029b750 <va_pa_offset>
ffffffffc0202548:	000803b7          	lui	t2,0x80
ffffffffc020254c:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202550:	00073023          	sd	zero,0(a4)
ffffffffc0202554:	bd7d                	j	ffffffffc0202412 <exit_range+0xd6>
        intr_disable();
ffffffffc0202556:	e832                	sd	a2,16(sp)
ffffffffc0202558:	e42a                	sd	a0,8(sp)
ffffffffc020255a:	baafe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020255e:	00099797          	auipc	a5,0x99
ffffffffc0202562:	1da7b783          	ld	a5,474(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0202566:	6522                	ld	a0,8(sp)
ffffffffc0202568:	4585                	li	a1,1
ffffffffc020256a:	739c                	ld	a5,32(a5)
ffffffffc020256c:	9782                	jalr	a5
        intr_enable();
ffffffffc020256e:	b90fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202572:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202574:	00043023          	sd	zero,0(s0)
ffffffffc0202578:	b5cd                	j	ffffffffc020245a <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020257a:	00004697          	auipc	a3,0x4
ffffffffc020257e:	15668693          	addi	a3,a3,342 # ffffffffc02066d0 <etext+0xe90>
ffffffffc0202582:	00004617          	auipc	a2,0x4
ffffffffc0202586:	c9e60613          	addi	a2,a2,-866 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020258a:	13500593          	li	a1,309
ffffffffc020258e:	00004517          	auipc	a0,0x4
ffffffffc0202592:	13250513          	addi	a0,a0,306 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202596:	eb1fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020259a:	00004617          	auipc	a2,0x4
ffffffffc020259e:	03660613          	addi	a2,a2,54 # ffffffffc02065d0 <etext+0xd90>
ffffffffc02025a2:	07100593          	li	a1,113
ffffffffc02025a6:	00004517          	auipc	a0,0x4
ffffffffc02025aa:	05250513          	addi	a0,a0,82 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02025ae:	e99fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025b2:	86f2                	mv	a3,t3
ffffffffc02025b4:	00004617          	auipc	a2,0x4
ffffffffc02025b8:	01c60613          	addi	a2,a2,28 # ffffffffc02065d0 <etext+0xd90>
ffffffffc02025bc:	07100593          	li	a1,113
ffffffffc02025c0:	00004517          	auipc	a0,0x4
ffffffffc02025c4:	03850513          	addi	a0,a0,56 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02025c8:	e7ffd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025cc:	8c7ff0ef          	jal	ffffffffc0201e92 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025d0:	00004697          	auipc	a3,0x4
ffffffffc02025d4:	13068693          	addi	a3,a3,304 # ffffffffc0206700 <etext+0xec0>
ffffffffc02025d8:	00004617          	auipc	a2,0x4
ffffffffc02025dc:	c4860613          	addi	a2,a2,-952 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02025e0:	13600593          	li	a1,310
ffffffffc02025e4:	00004517          	auipc	a0,0x4
ffffffffc02025e8:	0dc50513          	addi	a0,a0,220 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02025ec:	e5bfd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02025f0 <page_remove>:
{
ffffffffc02025f0:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025f2:	4601                	li	a2,0
{
ffffffffc02025f4:	e822                	sd	s0,16(sp)
ffffffffc02025f6:	ec06                	sd	ra,24(sp)
ffffffffc02025f8:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025fa:	95dff0ef          	jal	ffffffffc0201f56 <get_pte>
    if (ptep != NULL)
ffffffffc02025fe:	c511                	beqz	a0,ffffffffc020260a <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0202600:	6118                	ld	a4,0(a0)
ffffffffc0202602:	87aa                	mv	a5,a0
ffffffffc0202604:	00177693          	andi	a3,a4,1
ffffffffc0202608:	e689                	bnez	a3,ffffffffc0202612 <page_remove+0x22>
}
ffffffffc020260a:	60e2                	ld	ra,24(sp)
ffffffffc020260c:	6442                	ld	s0,16(sp)
ffffffffc020260e:	6105                	addi	sp,sp,32
ffffffffc0202610:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202612:	00099697          	auipc	a3,0x99
ffffffffc0202616:	1466b683          	ld	a3,326(a3) # ffffffffc029b758 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020261a:	070a                	slli	a4,a4,0x2
ffffffffc020261c:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020261e:	06d77563          	bgeu	a4,a3,ffffffffc0202688 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202622:	00099517          	auipc	a0,0x99
ffffffffc0202626:	13e53503          	ld	a0,318(a0) # ffffffffc029b760 <pages>
ffffffffc020262a:	071a                	slli	a4,a4,0x6
ffffffffc020262c:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202630:	9736                	add	a4,a4,a3
ffffffffc0202632:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202634:	4118                	lw	a4,0(a0)
ffffffffc0202636:	377d                	addiw	a4,a4,-1
ffffffffc0202638:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020263a:	cb09                	beqz	a4,ffffffffc020264c <page_remove+0x5c>
        *ptep = 0;
ffffffffc020263c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202640:	12040073          	sfence.vma	s0
}
ffffffffc0202644:	60e2                	ld	ra,24(sp)
ffffffffc0202646:	6442                	ld	s0,16(sp)
ffffffffc0202648:	6105                	addi	sp,sp,32
ffffffffc020264a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020264c:	10002773          	csrr	a4,sstatus
ffffffffc0202650:	8b09                	andi	a4,a4,2
ffffffffc0202652:	eb19                	bnez	a4,ffffffffc0202668 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202654:	00099717          	auipc	a4,0x99
ffffffffc0202658:	0e473703          	ld	a4,228(a4) # ffffffffc029b738 <pmm_manager>
ffffffffc020265c:	4585                	li	a1,1
ffffffffc020265e:	e03e                	sd	a5,0(sp)
ffffffffc0202660:	7318                	ld	a4,32(a4)
ffffffffc0202662:	9702                	jalr	a4
    if (flag)
ffffffffc0202664:	6782                	ld	a5,0(sp)
ffffffffc0202666:	bfd9                	j	ffffffffc020263c <page_remove+0x4c>
        intr_disable();
ffffffffc0202668:	e43e                	sd	a5,8(sp)
ffffffffc020266a:	e02a                	sd	a0,0(sp)
ffffffffc020266c:	a98fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202670:	00099717          	auipc	a4,0x99
ffffffffc0202674:	0c873703          	ld	a4,200(a4) # ffffffffc029b738 <pmm_manager>
ffffffffc0202678:	6502                	ld	a0,0(sp)
ffffffffc020267a:	4585                	li	a1,1
ffffffffc020267c:	7318                	ld	a4,32(a4)
ffffffffc020267e:	9702                	jalr	a4
        intr_enable();
ffffffffc0202680:	a7efe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202684:	67a2                	ld	a5,8(sp)
ffffffffc0202686:	bf5d                	j	ffffffffc020263c <page_remove+0x4c>
ffffffffc0202688:	80bff0ef          	jal	ffffffffc0201e92 <pa2page.part.0>

ffffffffc020268c <page_insert>:
{
ffffffffc020268c:	7139                	addi	sp,sp,-64
ffffffffc020268e:	f426                	sd	s1,40(sp)
ffffffffc0202690:	84b2                	mv	s1,a2
ffffffffc0202692:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202694:	4605                	li	a2,1
{
ffffffffc0202696:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202698:	85a6                	mv	a1,s1
{
ffffffffc020269a:	fc06                	sd	ra,56(sp)
ffffffffc020269c:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020269e:	8b9ff0ef          	jal	ffffffffc0201f56 <get_pte>
    if (ptep == NULL)
ffffffffc02026a2:	cd61                	beqz	a0,ffffffffc020277a <page_insert+0xee>
    page->ref += 1;
ffffffffc02026a4:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026a6:	611c                	ld	a5,0(a0)
ffffffffc02026a8:	66a2                	ld	a3,8(sp)
ffffffffc02026aa:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7bcf>
ffffffffc02026ae:	c010                	sw	a2,0(s0)
ffffffffc02026b0:	0017f613          	andi	a2,a5,1
ffffffffc02026b4:	872a                	mv	a4,a0
ffffffffc02026b6:	e61d                	bnez	a2,ffffffffc02026e4 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc02026b8:	00099617          	auipc	a2,0x99
ffffffffc02026bc:	0a863603          	ld	a2,168(a2) # ffffffffc029b760 <pages>
    return page - pages + nbase;
ffffffffc02026c0:	8c11                	sub	s0,s0,a2
ffffffffc02026c2:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026c4:	200007b7          	lui	a5,0x20000
ffffffffc02026c8:	042a                	slli	s0,s0,0xa
ffffffffc02026ca:	943e                	add	s0,s0,a5
ffffffffc02026cc:	8ec1                	or	a3,a3,s0
ffffffffc02026ce:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026d2:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026d4:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02026d8:	4501                	li	a0,0
}
ffffffffc02026da:	70e2                	ld	ra,56(sp)
ffffffffc02026dc:	7442                	ld	s0,48(sp)
ffffffffc02026de:	74a2                	ld	s1,40(sp)
ffffffffc02026e0:	6121                	addi	sp,sp,64
ffffffffc02026e2:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026e4:	00099617          	auipc	a2,0x99
ffffffffc02026e8:	07463603          	ld	a2,116(a2) # ffffffffc029b758 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026ec:	078a                	slli	a5,a5,0x2
ffffffffc02026ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026f0:	08c7f763          	bgeu	a5,a2,ffffffffc020277e <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026f4:	00099617          	auipc	a2,0x99
ffffffffc02026f8:	06c63603          	ld	a2,108(a2) # ffffffffc029b760 <pages>
ffffffffc02026fc:	fe000537          	lui	a0,0xfe000
ffffffffc0202700:	079a                	slli	a5,a5,0x6
ffffffffc0202702:	97aa                	add	a5,a5,a0
ffffffffc0202704:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc0202708:	00a40963          	beq	s0,a0,ffffffffc020271a <page_insert+0x8e>
    page->ref -= 1;
ffffffffc020270c:	411c                	lw	a5,0(a0)
ffffffffc020270e:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e27>
ffffffffc0202710:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202712:	c791                	beqz	a5,ffffffffc020271e <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202714:	12048073          	sfence.vma	s1
}
ffffffffc0202718:	b765                	j	ffffffffc02026c0 <page_insert+0x34>
ffffffffc020271a:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc020271c:	b755                	j	ffffffffc02026c0 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020271e:	100027f3          	csrr	a5,sstatus
ffffffffc0202722:	8b89                	andi	a5,a5,2
ffffffffc0202724:	e39d                	bnez	a5,ffffffffc020274a <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc0202726:	00099797          	auipc	a5,0x99
ffffffffc020272a:	0127b783          	ld	a5,18(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc020272e:	4585                	li	a1,1
ffffffffc0202730:	e83a                	sd	a4,16(sp)
ffffffffc0202732:	739c                	ld	a5,32(a5)
ffffffffc0202734:	e436                	sd	a3,8(sp)
ffffffffc0202736:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202738:	00099617          	auipc	a2,0x99
ffffffffc020273c:	02863603          	ld	a2,40(a2) # ffffffffc029b760 <pages>
ffffffffc0202740:	66a2                	ld	a3,8(sp)
ffffffffc0202742:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202744:	12048073          	sfence.vma	s1
ffffffffc0202748:	bfa5                	j	ffffffffc02026c0 <page_insert+0x34>
        intr_disable();
ffffffffc020274a:	ec3a                	sd	a4,24(sp)
ffffffffc020274c:	e836                	sd	a3,16(sp)
ffffffffc020274e:	e42a                	sd	a0,8(sp)
ffffffffc0202750:	9b4fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202754:	00099797          	auipc	a5,0x99
ffffffffc0202758:	fe47b783          	ld	a5,-28(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc020275c:	6522                	ld	a0,8(sp)
ffffffffc020275e:	4585                	li	a1,1
ffffffffc0202760:	739c                	ld	a5,32(a5)
ffffffffc0202762:	9782                	jalr	a5
        intr_enable();
ffffffffc0202764:	99afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202768:	00099617          	auipc	a2,0x99
ffffffffc020276c:	ff863603          	ld	a2,-8(a2) # ffffffffc029b760 <pages>
ffffffffc0202770:	6762                	ld	a4,24(sp)
ffffffffc0202772:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202774:	12048073          	sfence.vma	s1
ffffffffc0202778:	b7a1                	j	ffffffffc02026c0 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc020277a:	5571                	li	a0,-4
ffffffffc020277c:	bfb9                	j	ffffffffc02026da <page_insert+0x4e>
ffffffffc020277e:	f14ff0ef          	jal	ffffffffc0201e92 <pa2page.part.0>

ffffffffc0202782 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202782:	00005797          	auipc	a5,0x5
ffffffffc0202786:	ece78793          	addi	a5,a5,-306 # ffffffffc0207650 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020278a:	638c                	ld	a1,0(a5)
{
ffffffffc020278c:	7159                	addi	sp,sp,-112
ffffffffc020278e:	f486                	sd	ra,104(sp)
ffffffffc0202790:	e8ca                	sd	s2,80(sp)
ffffffffc0202792:	e4ce                	sd	s3,72(sp)
ffffffffc0202794:	f85a                	sd	s6,48(sp)
ffffffffc0202796:	f0a2                	sd	s0,96(sp)
ffffffffc0202798:	eca6                	sd	s1,88(sp)
ffffffffc020279a:	e0d2                	sd	s4,64(sp)
ffffffffc020279c:	fc56                	sd	s5,56(sp)
ffffffffc020279e:	f45e                	sd	s7,40(sp)
ffffffffc02027a0:	f062                	sd	s8,32(sp)
ffffffffc02027a2:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027a4:	00099b17          	auipc	s6,0x99
ffffffffc02027a8:	f94b0b13          	addi	s6,s6,-108 # ffffffffc029b738 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ac:	00004517          	auipc	a0,0x4
ffffffffc02027b0:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206718 <etext+0xed8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027b4:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027b8:	9ddfd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027bc:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027c0:	00099997          	auipc	s3,0x99
ffffffffc02027c4:	f9098993          	addi	s3,s3,-112 # ffffffffc029b750 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027c8:	679c                	ld	a5,8(a5)
ffffffffc02027ca:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027cc:	57f5                	li	a5,-3
ffffffffc02027ce:	07fa                	slli	a5,a5,0x1e
ffffffffc02027d0:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027d4:	916fe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc02027d8:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027da:	91afe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027de:	70050e63          	beqz	a0,ffffffffc0202efa <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027e2:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027e4:	00004517          	auipc	a0,0x4
ffffffffc02027e8:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206750 <etext+0xf10>
ffffffffc02027ec:	9a9fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027f0:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027f4:	864a                	mv	a2,s2
ffffffffc02027f6:	85a6                	mv	a1,s1
ffffffffc02027f8:	fff40693          	addi	a3,s0,-1
ffffffffc02027fc:	00004517          	auipc	a0,0x4
ffffffffc0202800:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206768 <etext+0xf28>
ffffffffc0202804:	991fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc0202808:	c80007b7          	lui	a5,0xc8000
ffffffffc020280c:	8522                	mv	a0,s0
ffffffffc020280e:	5287ed63          	bltu	a5,s0,ffffffffc0202d48 <pmm_init+0x5c6>
ffffffffc0202812:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202814:	0009a617          	auipc	a2,0x9a
ffffffffc0202818:	f7360613          	addi	a2,a2,-141 # ffffffffc029c787 <end+0xfff>
ffffffffc020281c:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc020281e:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202820:	00099b97          	auipc	s7,0x99
ffffffffc0202824:	f40b8b93          	addi	s7,s7,-192 # ffffffffc029b760 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202828:	00099497          	auipc	s1,0x99
ffffffffc020282c:	f3048493          	addi	s1,s1,-208 # ffffffffc029b758 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202830:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202834:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202836:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020283a:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020283c:	02f50763          	beq	a0,a5,ffffffffc020286a <pmm_init+0xe8>
ffffffffc0202840:	4701                	li	a4,0
ffffffffc0202842:	4585                	li	a1,1
ffffffffc0202844:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202848:	00671793          	slli	a5,a4,0x6
ffffffffc020284c:	97b2                	add	a5,a5,a2
ffffffffc020284e:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e30>
ffffffffc0202850:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202854:	6088                	ld	a0,0(s1)
ffffffffc0202856:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202858:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020285c:	00d507b3          	add	a5,a0,a3
ffffffffc0202860:	fef764e3          	bltu	a4,a5,ffffffffc0202848 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202864:	079a                	slli	a5,a5,0x6
ffffffffc0202866:	00f606b3          	add	a3,a2,a5
ffffffffc020286a:	c02007b7          	lui	a5,0xc0200
ffffffffc020286e:	16f6eee3          	bltu	a3,a5,ffffffffc02031ea <pmm_init+0xa68>
ffffffffc0202872:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202876:	77fd                	lui	a5,0xfffff
ffffffffc0202878:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020287a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020287c:	4e86ed63          	bltu	a3,s0,ffffffffc0202d76 <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202880:	00004517          	auipc	a0,0x4
ffffffffc0202884:	f1050513          	addi	a0,a0,-240 # ffffffffc0206790 <etext+0xf50>
ffffffffc0202888:	90dfd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020288c:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202890:	00099917          	auipc	s2,0x99
ffffffffc0202894:	eb890913          	addi	s2,s2,-328 # ffffffffc029b748 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202898:	7b9c                	ld	a5,48(a5)
ffffffffc020289a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020289c:	00004517          	auipc	a0,0x4
ffffffffc02028a0:	f0c50513          	addi	a0,a0,-244 # ffffffffc02067a8 <etext+0xf68>
ffffffffc02028a4:	8f1fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028a8:	00007697          	auipc	a3,0x7
ffffffffc02028ac:	75868693          	addi	a3,a3,1880 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02028b0:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028b4:	c02007b7          	lui	a5,0xc0200
ffffffffc02028b8:	2af6eee3          	bltu	a3,a5,ffffffffc0203374 <pmm_init+0xbf2>
ffffffffc02028bc:	0009b783          	ld	a5,0(s3)
ffffffffc02028c0:	8e9d                	sub	a3,a3,a5
ffffffffc02028c2:	00099797          	auipc	a5,0x99
ffffffffc02028c6:	e6d7bf23          	sd	a3,-386(a5) # ffffffffc029b740 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028ca:	100027f3          	csrr	a5,sstatus
ffffffffc02028ce:	8b89                	andi	a5,a5,2
ffffffffc02028d0:	48079963          	bnez	a5,ffffffffc0202d62 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028d4:	000b3783          	ld	a5,0(s6)
ffffffffc02028d8:	779c                	ld	a5,40(a5)
ffffffffc02028da:	9782                	jalr	a5
ffffffffc02028dc:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028de:	6098                	ld	a4,0(s1)
ffffffffc02028e0:	c80007b7          	lui	a5,0xc8000
ffffffffc02028e4:	83b1                	srli	a5,a5,0xc
ffffffffc02028e6:	66e7e663          	bltu	a5,a4,ffffffffc0202f52 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028ea:	00093503          	ld	a0,0(s2)
ffffffffc02028ee:	64050263          	beqz	a0,ffffffffc0202f32 <pmm_init+0x7b0>
ffffffffc02028f2:	03451793          	slli	a5,a0,0x34
ffffffffc02028f6:	62079e63          	bnez	a5,ffffffffc0202f32 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028fa:	4601                	li	a2,0
ffffffffc02028fc:	4581                	li	a1,0
ffffffffc02028fe:	8b7ff0ef          	jal	ffffffffc02021b4 <get_page>
ffffffffc0202902:	240519e3          	bnez	a0,ffffffffc0203354 <pmm_init+0xbd2>
ffffffffc0202906:	100027f3          	csrr	a5,sstatus
ffffffffc020290a:	8b89                	andi	a5,a5,2
ffffffffc020290c:	44079063          	bnez	a5,ffffffffc0202d4c <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202910:	000b3783          	ld	a5,0(s6)
ffffffffc0202914:	4505                	li	a0,1
ffffffffc0202916:	6f9c                	ld	a5,24(a5)
ffffffffc0202918:	9782                	jalr	a5
ffffffffc020291a:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020291c:	00093503          	ld	a0,0(s2)
ffffffffc0202920:	4681                	li	a3,0
ffffffffc0202922:	4601                	li	a2,0
ffffffffc0202924:	85d2                	mv	a1,s4
ffffffffc0202926:	d67ff0ef          	jal	ffffffffc020268c <page_insert>
ffffffffc020292a:	280511e3          	bnez	a0,ffffffffc02033ac <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020292e:	00093503          	ld	a0,0(s2)
ffffffffc0202932:	4601                	li	a2,0
ffffffffc0202934:	4581                	li	a1,0
ffffffffc0202936:	e20ff0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc020293a:	240509e3          	beqz	a0,ffffffffc020338c <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc020293e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202940:	0017f713          	andi	a4,a5,1
ffffffffc0202944:	58070f63          	beqz	a4,ffffffffc0202ee2 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202948:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020294a:	078a                	slli	a5,a5,0x2
ffffffffc020294c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020294e:	58e7f863          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202952:	000bb683          	ld	a3,0(s7)
ffffffffc0202956:	079a                	slli	a5,a5,0x6
ffffffffc0202958:	fe000637          	lui	a2,0xfe000
ffffffffc020295c:	97b2                	add	a5,a5,a2
ffffffffc020295e:	97b6                	add	a5,a5,a3
ffffffffc0202960:	14fa1ae3          	bne	s4,a5,ffffffffc02032b4 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202964:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e28>
ffffffffc0202968:	4785                	li	a5,1
ffffffffc020296a:	12f695e3          	bne	a3,a5,ffffffffc0203294 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020296e:	00093503          	ld	a0,0(s2)
ffffffffc0202972:	77fd                	lui	a5,0xfffff
ffffffffc0202974:	6114                	ld	a3,0(a0)
ffffffffc0202976:	068a                	slli	a3,a3,0x2
ffffffffc0202978:	8efd                	and	a3,a3,a5
ffffffffc020297a:	00c6d613          	srli	a2,a3,0xc
ffffffffc020297e:	0ee67fe3          	bgeu	a2,a4,ffffffffc020327c <pmm_init+0xafa>
ffffffffc0202982:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202986:	96e2                	add	a3,a3,s8
ffffffffc0202988:	0006ba83          	ld	s5,0(a3)
ffffffffc020298c:	0a8a                	slli	s5,s5,0x2
ffffffffc020298e:	00fafab3          	and	s5,s5,a5
ffffffffc0202992:	00cad793          	srli	a5,s5,0xc
ffffffffc0202996:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0203262 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020299a:	4601                	li	a2,0
ffffffffc020299c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020299e:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029a0:	db6ff0ef          	jal	ffffffffc0201f56 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029a4:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029a6:	05851ee3          	bne	a0,s8,ffffffffc0203202 <pmm_init+0xa80>
ffffffffc02029aa:	100027f3          	csrr	a5,sstatus
ffffffffc02029ae:	8b89                	andi	a5,a5,2
ffffffffc02029b0:	3e079b63          	bnez	a5,ffffffffc0202da6 <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029b4:	000b3783          	ld	a5,0(s6)
ffffffffc02029b8:	4505                	li	a0,1
ffffffffc02029ba:	6f9c                	ld	a5,24(a5)
ffffffffc02029bc:	9782                	jalr	a5
ffffffffc02029be:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029c0:	00093503          	ld	a0,0(s2)
ffffffffc02029c4:	46d1                	li	a3,20
ffffffffc02029c6:	6605                	lui	a2,0x1
ffffffffc02029c8:	85e2                	mv	a1,s8
ffffffffc02029ca:	cc3ff0ef          	jal	ffffffffc020268c <page_insert>
ffffffffc02029ce:	06051ae3          	bnez	a0,ffffffffc0203242 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029d2:	00093503          	ld	a0,0(s2)
ffffffffc02029d6:	4601                	li	a2,0
ffffffffc02029d8:	6585                	lui	a1,0x1
ffffffffc02029da:	d7cff0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc02029de:	040502e3          	beqz	a0,ffffffffc0203222 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02029e2:	611c                	ld	a5,0(a0)
ffffffffc02029e4:	0107f713          	andi	a4,a5,16
ffffffffc02029e8:	7e070163          	beqz	a4,ffffffffc02031ca <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02029ec:	8b91                	andi	a5,a5,4
ffffffffc02029ee:	7a078e63          	beqz	a5,ffffffffc02031aa <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029f2:	00093503          	ld	a0,0(s2)
ffffffffc02029f6:	611c                	ld	a5,0(a0)
ffffffffc02029f8:	8bc1                	andi	a5,a5,16
ffffffffc02029fa:	78078863          	beqz	a5,ffffffffc020318a <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02029fe:	000c2703          	lw	a4,0(s8)
ffffffffc0202a02:	4785                	li	a5,1
ffffffffc0202a04:	76f71363          	bne	a4,a5,ffffffffc020316a <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a08:	4681                	li	a3,0
ffffffffc0202a0a:	6605                	lui	a2,0x1
ffffffffc0202a0c:	85d2                	mv	a1,s4
ffffffffc0202a0e:	c7fff0ef          	jal	ffffffffc020268c <page_insert>
ffffffffc0202a12:	72051c63          	bnez	a0,ffffffffc020314a <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202a16:	000a2703          	lw	a4,0(s4)
ffffffffc0202a1a:	4789                	li	a5,2
ffffffffc0202a1c:	70f71763          	bne	a4,a5,ffffffffc020312a <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a20:	000c2783          	lw	a5,0(s8)
ffffffffc0202a24:	6e079363          	bnez	a5,ffffffffc020310a <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a28:	00093503          	ld	a0,0(s2)
ffffffffc0202a2c:	4601                	li	a2,0
ffffffffc0202a2e:	6585                	lui	a1,0x1
ffffffffc0202a30:	d26ff0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc0202a34:	6a050b63          	beqz	a0,ffffffffc02030ea <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a38:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a3a:	00177793          	andi	a5,a4,1
ffffffffc0202a3e:	4a078263          	beqz	a5,ffffffffc0202ee2 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a42:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a44:	00271793          	slli	a5,a4,0x2
ffffffffc0202a48:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a4a:	48d7fa63          	bgeu	a5,a3,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a4e:	000bb683          	ld	a3,0(s7)
ffffffffc0202a52:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a56:	97d6                	add	a5,a5,s5
ffffffffc0202a58:	079a                	slli	a5,a5,0x6
ffffffffc0202a5a:	97b6                	add	a5,a5,a3
ffffffffc0202a5c:	66fa1763          	bne	s4,a5,ffffffffc02030ca <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a60:	8b41                	andi	a4,a4,16
ffffffffc0202a62:	64071463          	bnez	a4,ffffffffc02030aa <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a66:	00093503          	ld	a0,0(s2)
ffffffffc0202a6a:	4581                	li	a1,0
ffffffffc0202a6c:	b85ff0ef          	jal	ffffffffc02025f0 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a70:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a74:	4785                	li	a5,1
ffffffffc0202a76:	60fc9a63          	bne	s9,a5,ffffffffc020308a <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202a7a:	000c2783          	lw	a5,0(s8)
ffffffffc0202a7e:	5e079663          	bnez	a5,ffffffffc020306a <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a82:	00093503          	ld	a0,0(s2)
ffffffffc0202a86:	6585                	lui	a1,0x1
ffffffffc0202a88:	b69ff0ef          	jal	ffffffffc02025f0 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a8c:	000a2783          	lw	a5,0(s4)
ffffffffc0202a90:	52079d63          	bnez	a5,ffffffffc0202fca <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202a94:	000c2783          	lw	a5,0(s8)
ffffffffc0202a98:	50079963          	bnez	a5,ffffffffc0202faa <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a9c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202aa0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aa2:	000a3783          	ld	a5,0(s4)
ffffffffc0202aa6:	078a                	slli	a5,a5,0x2
ffffffffc0202aa8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aaa:	42e7fa63          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aae:	000bb503          	ld	a0,0(s7)
ffffffffc0202ab2:	97d6                	add	a5,a5,s5
ffffffffc0202ab4:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202ab6:	00f506b3          	add	a3,a0,a5
ffffffffc0202aba:	4294                	lw	a3,0(a3)
ffffffffc0202abc:	4d969763          	bne	a3,s9,ffffffffc0202f8a <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202ac0:	8799                	srai	a5,a5,0x6
ffffffffc0202ac2:	00080637          	lui	a2,0x80
ffffffffc0202ac6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ac8:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202acc:	4ae7f363          	bgeu	a5,a4,ffffffffc0202f72 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ad0:	0009b783          	ld	a5,0(s3)
ffffffffc0202ad4:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ad6:	639c                	ld	a5,0(a5)
ffffffffc0202ad8:	078a                	slli	a5,a5,0x2
ffffffffc0202ada:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202adc:	40e7f163          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ae0:	8f91                	sub	a5,a5,a2
ffffffffc0202ae2:	079a                	slli	a5,a5,0x6
ffffffffc0202ae4:	953e                	add	a0,a0,a5
ffffffffc0202ae6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aea:	8b89                	andi	a5,a5,2
ffffffffc0202aec:	30079863          	bnez	a5,ffffffffc0202dfc <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202af0:	000b3783          	ld	a5,0(s6)
ffffffffc0202af4:	4585                	li	a1,1
ffffffffc0202af6:	739c                	ld	a5,32(a5)
ffffffffc0202af8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202afe:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b00:	078a                	slli	a5,a5,0x2
ffffffffc0202b02:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b04:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b08:	000bb503          	ld	a0,0(s7)
ffffffffc0202b0c:	fe000737          	lui	a4,0xfe000
ffffffffc0202b10:	079a                	slli	a5,a5,0x6
ffffffffc0202b12:	97ba                	add	a5,a5,a4
ffffffffc0202b14:	953e                	add	a0,a0,a5
ffffffffc0202b16:	100027f3          	csrr	a5,sstatus
ffffffffc0202b1a:	8b89                	andi	a5,a5,2
ffffffffc0202b1c:	2c079463          	bnez	a5,ffffffffc0202de4 <pmm_init+0x662>
ffffffffc0202b20:	000b3783          	ld	a5,0(s6)
ffffffffc0202b24:	4585                	li	a1,1
ffffffffc0202b26:	739c                	ld	a5,32(a5)
ffffffffc0202b28:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b2a:	00093783          	ld	a5,0(s2)
ffffffffc0202b2e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd63878>
    asm volatile("sfence.vma");
ffffffffc0202b32:	12000073          	sfence.vma
ffffffffc0202b36:	100027f3          	csrr	a5,sstatus
ffffffffc0202b3a:	8b89                	andi	a5,a5,2
ffffffffc0202b3c:	28079a63          	bnez	a5,ffffffffc0202dd0 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b40:	000b3783          	ld	a5,0(s6)
ffffffffc0202b44:	779c                	ld	a5,40(a5)
ffffffffc0202b46:	9782                	jalr	a5
ffffffffc0202b48:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b4a:	4d441063          	bne	s0,s4,ffffffffc020300a <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b4e:	00004517          	auipc	a0,0x4
ffffffffc0202b52:	faa50513          	addi	a0,a0,-86 # ffffffffc0206af8 <etext+0x12b8>
ffffffffc0202b56:	e3efd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202b5a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b5e:	8b89                	andi	a5,a5,2
ffffffffc0202b60:	24079e63          	bnez	a5,ffffffffc0202dbc <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b64:	000b3783          	ld	a5,0(s6)
ffffffffc0202b68:	779c                	ld	a5,40(a5)
ffffffffc0202b6a:	9782                	jalr	a5
ffffffffc0202b6c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b6e:	609c                	ld	a5,0(s1)
ffffffffc0202b70:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b74:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b76:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b7a:	6a85                	lui	s5,0x1
ffffffffc0202b7c:	02e47c63          	bgeu	s0,a4,ffffffffc0202bb4 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b80:	00c45713          	srli	a4,s0,0xc
ffffffffc0202b84:	30f77063          	bgeu	a4,a5,ffffffffc0202e84 <pmm_init+0x702>
ffffffffc0202b88:	0009b583          	ld	a1,0(s3)
ffffffffc0202b8c:	00093503          	ld	a0,0(s2)
ffffffffc0202b90:	4601                	li	a2,0
ffffffffc0202b92:	95a2                	add	a1,a1,s0
ffffffffc0202b94:	bc2ff0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc0202b98:	32050363          	beqz	a0,ffffffffc0202ebe <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b9c:	611c                	ld	a5,0(a0)
ffffffffc0202b9e:	078a                	slli	a5,a5,0x2
ffffffffc0202ba0:	0147f7b3          	and	a5,a5,s4
ffffffffc0202ba4:	2e879d63          	bne	a5,s0,ffffffffc0202e9e <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202ba8:	609c                	ld	a5,0(s1)
ffffffffc0202baa:	9456                	add	s0,s0,s5
ffffffffc0202bac:	00c79713          	slli	a4,a5,0xc
ffffffffc0202bb0:	fce468e3          	bltu	s0,a4,ffffffffc0202b80 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bb4:	00093783          	ld	a5,0(s2)
ffffffffc0202bb8:	639c                	ld	a5,0(a5)
ffffffffc0202bba:	42079863          	bnez	a5,ffffffffc0202fea <pmm_init+0x868>
ffffffffc0202bbe:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc2:	8b89                	andi	a5,a5,2
ffffffffc0202bc4:	24079863          	bnez	a5,ffffffffc0202e14 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202bcc:	4505                	li	a0,1
ffffffffc0202bce:	6f9c                	ld	a5,24(a5)
ffffffffc0202bd0:	9782                	jalr	a5
ffffffffc0202bd2:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	4699                	li	a3,6
ffffffffc0202bda:	10000613          	li	a2,256
ffffffffc0202bde:	85a2                	mv	a1,s0
ffffffffc0202be0:	aadff0ef          	jal	ffffffffc020268c <page_insert>
ffffffffc0202be4:	46051363          	bnez	a0,ffffffffc020304a <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202be8:	4018                	lw	a4,0(s0)
ffffffffc0202bea:	4785                	li	a5,1
ffffffffc0202bec:	42f71f63          	bne	a4,a5,ffffffffc020302a <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bf0:	00093503          	ld	a0,0(s2)
ffffffffc0202bf4:	6605                	lui	a2,0x1
ffffffffc0202bf6:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7ad0>
ffffffffc0202bfa:	4699                	li	a3,6
ffffffffc0202bfc:	85a2                	mv	a1,s0
ffffffffc0202bfe:	a8fff0ef          	jal	ffffffffc020268c <page_insert>
ffffffffc0202c02:	72051963          	bnez	a0,ffffffffc0203334 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202c06:	4018                	lw	a4,0(s0)
ffffffffc0202c08:	4789                	li	a5,2
ffffffffc0202c0a:	70f71563          	bne	a4,a5,ffffffffc0203314 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c0e:	00004597          	auipc	a1,0x4
ffffffffc0202c12:	03258593          	addi	a1,a1,50 # ffffffffc0206c40 <etext+0x1400>
ffffffffc0202c16:	10000513          	li	a0,256
ffffffffc0202c1a:	37d020ef          	jal	ffffffffc0205796 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c1e:	6585                	lui	a1,0x1
ffffffffc0202c20:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7ad0>
ffffffffc0202c24:	10000513          	li	a0,256
ffffffffc0202c28:	381020ef          	jal	ffffffffc02057a8 <strcmp>
ffffffffc0202c2c:	6c051463          	bnez	a0,ffffffffc02032f4 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c30:	000bb683          	ld	a3,0(s7)
ffffffffc0202c34:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c38:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c3a:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c3e:	8699                	srai	a3,a3,0x6
ffffffffc0202c40:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c42:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c46:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c48:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c4a:	32e7f463          	bgeu	a5,a4,ffffffffc0202f72 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c4e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c52:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c56:	97b6                	add	a5,a5,a3
ffffffffc0202c58:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f28>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c5c:	307020ef          	jal	ffffffffc0205762 <strlen>
ffffffffc0202c60:	66051a63          	bnez	a0,ffffffffc02032d4 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c64:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c68:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c6a:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd63878>
ffffffffc0202c6e:	078a                	slli	a5,a5,0x2
ffffffffc0202c70:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c72:	26e7f663          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c76:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202c7a:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202f72 <pmm_init+0x7f0>
ffffffffc0202c7e:	0009b783          	ld	a5,0(s3)
ffffffffc0202c82:	00f689b3          	add	s3,a3,a5
ffffffffc0202c86:	100027f3          	csrr	a5,sstatus
ffffffffc0202c8a:	8b89                	andi	a5,a5,2
ffffffffc0202c8c:	1e079163          	bnez	a5,ffffffffc0202e6e <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202c90:	000b3783          	ld	a5,0(s6)
ffffffffc0202c94:	8522                	mv	a0,s0
ffffffffc0202c96:	4585                	li	a1,1
ffffffffc0202c98:	739c                	ld	a5,32(a5)
ffffffffc0202c9a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c9c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202ca0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ca2:	078a                	slli	a5,a5,0x2
ffffffffc0202ca4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ca6:	22e7fc63          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202caa:	000bb503          	ld	a0,0(s7)
ffffffffc0202cae:	fe000737          	lui	a4,0xfe000
ffffffffc0202cb2:	079a                	slli	a5,a5,0x6
ffffffffc0202cb4:	97ba                	add	a5,a5,a4
ffffffffc0202cb6:	953e                	add	a0,a0,a5
ffffffffc0202cb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cbc:	8b89                	andi	a5,a5,2
ffffffffc0202cbe:	18079c63          	bnez	a5,ffffffffc0202e56 <pmm_init+0x6d4>
ffffffffc0202cc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc6:	4585                	li	a1,1
ffffffffc0202cc8:	739c                	ld	a5,32(a5)
ffffffffc0202cca:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ccc:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202cd0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cd2:	078a                	slli	a5,a5,0x2
ffffffffc0202cd4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cd6:	20e7f463          	bgeu	a5,a4,ffffffffc0202ede <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cda:	000bb503          	ld	a0,0(s7)
ffffffffc0202cde:	fe000737          	lui	a4,0xfe000
ffffffffc0202ce2:	079a                	slli	a5,a5,0x6
ffffffffc0202ce4:	97ba                	add	a5,a5,a4
ffffffffc0202ce6:	953e                	add	a0,a0,a5
ffffffffc0202ce8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cec:	8b89                	andi	a5,a5,2
ffffffffc0202cee:	14079863          	bnez	a5,ffffffffc0202e3e <pmm_init+0x6bc>
ffffffffc0202cf2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf6:	4585                	li	a1,1
ffffffffc0202cf8:	739c                	ld	a5,32(a5)
ffffffffc0202cfa:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cfc:	00093783          	ld	a5,0(s2)
ffffffffc0202d00:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d04:	12000073          	sfence.vma
ffffffffc0202d08:	100027f3          	csrr	a5,sstatus
ffffffffc0202d0c:	8b89                	andi	a5,a5,2
ffffffffc0202d0e:	10079e63          	bnez	a5,ffffffffc0202e2a <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d12:	000b3783          	ld	a5,0(s6)
ffffffffc0202d16:	779c                	ld	a5,40(a5)
ffffffffc0202d18:	9782                	jalr	a5
ffffffffc0202d1a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d1c:	1e8c1b63          	bne	s8,s0,ffffffffc0202f12 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d20:	00004517          	auipc	a0,0x4
ffffffffc0202d24:	f9850513          	addi	a0,a0,-104 # ffffffffc0206cb8 <etext+0x1478>
ffffffffc0202d28:	c6cfd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d2c:	7406                	ld	s0,96(sp)
ffffffffc0202d2e:	70a6                	ld	ra,104(sp)
ffffffffc0202d30:	64e6                	ld	s1,88(sp)
ffffffffc0202d32:	6946                	ld	s2,80(sp)
ffffffffc0202d34:	69a6                	ld	s3,72(sp)
ffffffffc0202d36:	6a06                	ld	s4,64(sp)
ffffffffc0202d38:	7ae2                	ld	s5,56(sp)
ffffffffc0202d3a:	7b42                	ld	s6,48(sp)
ffffffffc0202d3c:	7ba2                	ld	s7,40(sp)
ffffffffc0202d3e:	7c02                	ld	s8,32(sp)
ffffffffc0202d40:	6ce2                	ld	s9,24(sp)
ffffffffc0202d42:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d44:	f85fe06f          	j	ffffffffc0201cc8 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d48:	853e                	mv	a0,a5
ffffffffc0202d4a:	b4e1                	j	ffffffffc0202812 <pmm_init+0x90>
        intr_disable();
ffffffffc0202d4c:	bb9fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d50:	000b3783          	ld	a5,0(s6)
ffffffffc0202d54:	4505                	li	a0,1
ffffffffc0202d56:	6f9c                	ld	a5,24(a5)
ffffffffc0202d58:	9782                	jalr	a5
ffffffffc0202d5a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d5c:	ba3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d60:	be75                	j	ffffffffc020291c <pmm_init+0x19a>
        intr_disable();
ffffffffc0202d62:	ba3fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d66:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6a:	779c                	ld	a5,40(a5)
ffffffffc0202d6c:	9782                	jalr	a5
ffffffffc0202d6e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d70:	b8ffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d74:	b6ad                	j	ffffffffc02028de <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d76:	6705                	lui	a4,0x1
ffffffffc0202d78:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7bd1>
ffffffffc0202d7a:	96ba                	add	a3,a3,a4
ffffffffc0202d7c:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d7e:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d82:	14a77e63          	bgeu	a4,a0,ffffffffc0202ede <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d86:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d8a:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202d8c:	071a                	slli	a4,a4,0x6
ffffffffc0202d8e:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202d92:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202d94:	6a9c                	ld	a5,16(a3)
ffffffffc0202d96:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d9a:	00e60533          	add	a0,a2,a4
ffffffffc0202d9e:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202da0:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202da4:	bcf1                	j	ffffffffc0202880 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202da6:	b5ffd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202daa:	000b3783          	ld	a5,0(s6)
ffffffffc0202dae:	4505                	li	a0,1
ffffffffc0202db0:	6f9c                	ld	a5,24(a5)
ffffffffc0202db2:	9782                	jalr	a5
ffffffffc0202db4:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202db6:	b49fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dba:	b119                	j	ffffffffc02029c0 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202dbc:	b49fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dc0:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc4:	779c                	ld	a5,40(a5)
ffffffffc0202dc6:	9782                	jalr	a5
ffffffffc0202dc8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dca:	b35fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dce:	b345                	j	ffffffffc0202b6e <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202dd0:	b35fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202dd4:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd8:	779c                	ld	a5,40(a5)
ffffffffc0202dda:	9782                	jalr	a5
ffffffffc0202ddc:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dde:	b21fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202de2:	b3a5                	j	ffffffffc0202b4a <pmm_init+0x3c8>
ffffffffc0202de4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202de6:	b1ffd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dea:	000b3783          	ld	a5,0(s6)
ffffffffc0202dee:	6522                	ld	a0,8(sp)
ffffffffc0202df0:	4585                	li	a1,1
ffffffffc0202df2:	739c                	ld	a5,32(a5)
ffffffffc0202df4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202df6:	b09fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dfa:	bb05                	j	ffffffffc0202b2a <pmm_init+0x3a8>
ffffffffc0202dfc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dfe:	b07fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e02:	000b3783          	ld	a5,0(s6)
ffffffffc0202e06:	6522                	ld	a0,8(sp)
ffffffffc0202e08:	4585                	li	a1,1
ffffffffc0202e0a:	739c                	ld	a5,32(a5)
ffffffffc0202e0c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e0e:	af1fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e12:	b1e5                	j	ffffffffc0202afa <pmm_init+0x378>
        intr_disable();
ffffffffc0202e14:	af1fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e18:	000b3783          	ld	a5,0(s6)
ffffffffc0202e1c:	4505                	li	a0,1
ffffffffc0202e1e:	6f9c                	ld	a5,24(a5)
ffffffffc0202e20:	9782                	jalr	a5
ffffffffc0202e22:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e24:	adbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e28:	b375                	j	ffffffffc0202bd4 <pmm_init+0x452>
        intr_disable();
ffffffffc0202e2a:	adbfd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e32:	779c                	ld	a5,40(a5)
ffffffffc0202e34:	9782                	jalr	a5
ffffffffc0202e36:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e38:	ac7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e3c:	b5c5                	j	ffffffffc0202d1c <pmm_init+0x59a>
ffffffffc0202e3e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e40:	ac5fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e44:	000b3783          	ld	a5,0(s6)
ffffffffc0202e48:	6522                	ld	a0,8(sp)
ffffffffc0202e4a:	4585                	li	a1,1
ffffffffc0202e4c:	739c                	ld	a5,32(a5)
ffffffffc0202e4e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e50:	aaffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e54:	b565                	j	ffffffffc0202cfc <pmm_init+0x57a>
ffffffffc0202e56:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e58:	aadfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e5c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e60:	6522                	ld	a0,8(sp)
ffffffffc0202e62:	4585                	li	a1,1
ffffffffc0202e64:	739c                	ld	a5,32(a5)
ffffffffc0202e66:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e68:	a97fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e6c:	b585                	j	ffffffffc0202ccc <pmm_init+0x54a>
        intr_disable();
ffffffffc0202e6e:	a97fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e72:	000b3783          	ld	a5,0(s6)
ffffffffc0202e76:	8522                	mv	a0,s0
ffffffffc0202e78:	4585                	li	a1,1
ffffffffc0202e7a:	739c                	ld	a5,32(a5)
ffffffffc0202e7c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e7e:	a81fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e82:	bd29                	j	ffffffffc0202c9c <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e84:	86a2                	mv	a3,s0
ffffffffc0202e86:	00003617          	auipc	a2,0x3
ffffffffc0202e8a:	74a60613          	addi	a2,a2,1866 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0202e8e:	24f00593          	li	a1,591
ffffffffc0202e92:	00004517          	auipc	a0,0x4
ffffffffc0202e96:	82e50513          	addi	a0,a0,-2002 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202e9a:	dacfd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e9e:	00004697          	auipc	a3,0x4
ffffffffc0202ea2:	cba68693          	addi	a3,a3,-838 # ffffffffc0206b58 <etext+0x1318>
ffffffffc0202ea6:	00003617          	auipc	a2,0x3
ffffffffc0202eaa:	37a60613          	addi	a2,a2,890 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202eae:	25000593          	li	a1,592
ffffffffc0202eb2:	00004517          	auipc	a0,0x4
ffffffffc0202eb6:	80e50513          	addi	a0,a0,-2034 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202eba:	d8cfd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ebe:	00004697          	auipc	a3,0x4
ffffffffc0202ec2:	c5a68693          	addi	a3,a3,-934 # ffffffffc0206b18 <etext+0x12d8>
ffffffffc0202ec6:	00003617          	auipc	a2,0x3
ffffffffc0202eca:	35a60613          	addi	a2,a2,858 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202ece:	24f00593          	li	a1,591
ffffffffc0202ed2:	00003517          	auipc	a0,0x3
ffffffffc0202ed6:	7ee50513          	addi	a0,a0,2030 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202eda:	d6cfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202ede:	fb5fe0ef          	jal	ffffffffc0201e92 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202ee2:	00004617          	auipc	a2,0x4
ffffffffc0202ee6:	9d660613          	addi	a2,a2,-1578 # ffffffffc02068b8 <etext+0x1078>
ffffffffc0202eea:	07f00593          	li	a1,127
ffffffffc0202eee:	00003517          	auipc	a0,0x3
ffffffffc0202ef2:	70a50513          	addi	a0,a0,1802 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0202ef6:	d50fd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202efa:	00004617          	auipc	a2,0x4
ffffffffc0202efe:	83660613          	addi	a2,a2,-1994 # ffffffffc0206730 <etext+0xef0>
ffffffffc0202f02:	06500593          	li	a1,101
ffffffffc0202f06:	00003517          	auipc	a0,0x3
ffffffffc0202f0a:	7ba50513          	addi	a0,a0,1978 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202f0e:	d38fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f12:	00004697          	auipc	a3,0x4
ffffffffc0202f16:	bbe68693          	addi	a3,a3,-1090 # ffffffffc0206ad0 <etext+0x1290>
ffffffffc0202f1a:	00003617          	auipc	a2,0x3
ffffffffc0202f1e:	30660613          	addi	a2,a2,774 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202f22:	26a00593          	li	a1,618
ffffffffc0202f26:	00003517          	auipc	a0,0x3
ffffffffc0202f2a:	79a50513          	addi	a0,a0,1946 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202f2e:	d18fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f32:	00004697          	auipc	a3,0x4
ffffffffc0202f36:	8b668693          	addi	a3,a3,-1866 # ffffffffc02067e8 <etext+0xfa8>
ffffffffc0202f3a:	00003617          	auipc	a2,0x3
ffffffffc0202f3e:	2e660613          	addi	a2,a2,742 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202f42:	21100593          	li	a1,529
ffffffffc0202f46:	00003517          	auipc	a0,0x3
ffffffffc0202f4a:	77a50513          	addi	a0,a0,1914 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202f4e:	cf8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f52:	00004697          	auipc	a3,0x4
ffffffffc0202f56:	87668693          	addi	a3,a3,-1930 # ffffffffc02067c8 <etext+0xf88>
ffffffffc0202f5a:	00003617          	auipc	a2,0x3
ffffffffc0202f5e:	2c660613          	addi	a2,a2,710 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202f62:	21000593          	li	a1,528
ffffffffc0202f66:	00003517          	auipc	a0,0x3
ffffffffc0202f6a:	75a50513          	addi	a0,a0,1882 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202f6e:	cd8fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f72:	00003617          	auipc	a2,0x3
ffffffffc0202f76:	65e60613          	addi	a2,a2,1630 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0202f7a:	07100593          	li	a1,113
ffffffffc0202f7e:	00003517          	auipc	a0,0x3
ffffffffc0202f82:	67a50513          	addi	a0,a0,1658 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0202f86:	cc0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f8a:	00004697          	auipc	a3,0x4
ffffffffc0202f8e:	b1668693          	addi	a3,a3,-1258 # ffffffffc0206aa0 <etext+0x1260>
ffffffffc0202f92:	00003617          	auipc	a2,0x3
ffffffffc0202f96:	28e60613          	addi	a2,a2,654 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202f9a:	23800593          	li	a1,568
ffffffffc0202f9e:	00003517          	auipc	a0,0x3
ffffffffc0202fa2:	72250513          	addi	a0,a0,1826 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202fa6:	ca0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202faa:	00004697          	auipc	a3,0x4
ffffffffc0202fae:	aae68693          	addi	a3,a3,-1362 # ffffffffc0206a58 <etext+0x1218>
ffffffffc0202fb2:	00003617          	auipc	a2,0x3
ffffffffc0202fb6:	26e60613          	addi	a2,a2,622 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202fba:	23600593          	li	a1,566
ffffffffc0202fbe:	00003517          	auipc	a0,0x3
ffffffffc0202fc2:	70250513          	addi	a0,a0,1794 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202fc6:	c80fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fca:	00004697          	auipc	a3,0x4
ffffffffc0202fce:	abe68693          	addi	a3,a3,-1346 # ffffffffc0206a88 <etext+0x1248>
ffffffffc0202fd2:	00003617          	auipc	a2,0x3
ffffffffc0202fd6:	24e60613          	addi	a2,a2,590 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202fda:	23500593          	li	a1,565
ffffffffc0202fde:	00003517          	auipc	a0,0x3
ffffffffc0202fe2:	6e250513          	addi	a0,a0,1762 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0202fe6:	c60fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fea:	00004697          	auipc	a3,0x4
ffffffffc0202fee:	b8668693          	addi	a3,a3,-1146 # ffffffffc0206b70 <etext+0x1330>
ffffffffc0202ff2:	00003617          	auipc	a2,0x3
ffffffffc0202ff6:	22e60613          	addi	a2,a2,558 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0202ffa:	25300593          	li	a1,595
ffffffffc0202ffe:	00003517          	auipc	a0,0x3
ffffffffc0203002:	6c250513          	addi	a0,a0,1730 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203006:	c40fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020300a:	00004697          	auipc	a3,0x4
ffffffffc020300e:	ac668693          	addi	a3,a3,-1338 # ffffffffc0206ad0 <etext+0x1290>
ffffffffc0203012:	00003617          	auipc	a2,0x3
ffffffffc0203016:	20e60613          	addi	a2,a2,526 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020301a:	24000593          	li	a1,576
ffffffffc020301e:	00003517          	auipc	a0,0x3
ffffffffc0203022:	6a250513          	addi	a0,a0,1698 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203026:	c20fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020302a:	00004697          	auipc	a3,0x4
ffffffffc020302e:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0206bc8 <etext+0x1388>
ffffffffc0203032:	00003617          	auipc	a2,0x3
ffffffffc0203036:	1ee60613          	addi	a2,a2,494 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020303a:	25800593          	li	a1,600
ffffffffc020303e:	00003517          	auipc	a0,0x3
ffffffffc0203042:	68250513          	addi	a0,a0,1666 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203046:	c00fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020304a:	00004697          	auipc	a3,0x4
ffffffffc020304e:	b3e68693          	addi	a3,a3,-1218 # ffffffffc0206b88 <etext+0x1348>
ffffffffc0203052:	00003617          	auipc	a2,0x3
ffffffffc0203056:	1ce60613          	addi	a2,a2,462 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020305a:	25700593          	li	a1,599
ffffffffc020305e:	00003517          	auipc	a0,0x3
ffffffffc0203062:	66250513          	addi	a0,a0,1634 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203066:	be0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020306a:	00004697          	auipc	a3,0x4
ffffffffc020306e:	9ee68693          	addi	a3,a3,-1554 # ffffffffc0206a58 <etext+0x1218>
ffffffffc0203072:	00003617          	auipc	a2,0x3
ffffffffc0203076:	1ae60613          	addi	a2,a2,430 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020307a:	23200593          	li	a1,562
ffffffffc020307e:	00003517          	auipc	a0,0x3
ffffffffc0203082:	64250513          	addi	a0,a0,1602 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203086:	bc0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020308a:	00004697          	auipc	a3,0x4
ffffffffc020308e:	86e68693          	addi	a3,a3,-1938 # ffffffffc02068f8 <etext+0x10b8>
ffffffffc0203092:	00003617          	auipc	a2,0x3
ffffffffc0203096:	18e60613          	addi	a2,a2,398 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020309a:	23100593          	li	a1,561
ffffffffc020309e:	00003517          	auipc	a0,0x3
ffffffffc02030a2:	62250513          	addi	a0,a0,1570 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02030a6:	ba0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030aa:	00004697          	auipc	a3,0x4
ffffffffc02030ae:	9c668693          	addi	a3,a3,-1594 # ffffffffc0206a70 <etext+0x1230>
ffffffffc02030b2:	00003617          	auipc	a2,0x3
ffffffffc02030b6:	16e60613          	addi	a2,a2,366 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02030ba:	22e00593          	li	a1,558
ffffffffc02030be:	00003517          	auipc	a0,0x3
ffffffffc02030c2:	60250513          	addi	a0,a0,1538 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02030c6:	b80fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030ca:	00004697          	auipc	a3,0x4
ffffffffc02030ce:	81668693          	addi	a3,a3,-2026 # ffffffffc02068e0 <etext+0x10a0>
ffffffffc02030d2:	00003617          	auipc	a2,0x3
ffffffffc02030d6:	14e60613          	addi	a2,a2,334 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02030da:	22d00593          	li	a1,557
ffffffffc02030de:	00003517          	auipc	a0,0x3
ffffffffc02030e2:	5e250513          	addi	a0,a0,1506 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02030e6:	b60fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030ea:	00004697          	auipc	a3,0x4
ffffffffc02030ee:	89668693          	addi	a3,a3,-1898 # ffffffffc0206980 <etext+0x1140>
ffffffffc02030f2:	00003617          	auipc	a2,0x3
ffffffffc02030f6:	12e60613          	addi	a2,a2,302 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02030fa:	22c00593          	li	a1,556
ffffffffc02030fe:	00003517          	auipc	a0,0x3
ffffffffc0203102:	5c250513          	addi	a0,a0,1474 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203106:	b40fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020310a:	00004697          	auipc	a3,0x4
ffffffffc020310e:	94e68693          	addi	a3,a3,-1714 # ffffffffc0206a58 <etext+0x1218>
ffffffffc0203112:	00003617          	auipc	a2,0x3
ffffffffc0203116:	10e60613          	addi	a2,a2,270 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020311a:	22b00593          	li	a1,555
ffffffffc020311e:	00003517          	auipc	a0,0x3
ffffffffc0203122:	5a250513          	addi	a0,a0,1442 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203126:	b20fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020312a:	00004697          	auipc	a3,0x4
ffffffffc020312e:	91668693          	addi	a3,a3,-1770 # ffffffffc0206a40 <etext+0x1200>
ffffffffc0203132:	00003617          	auipc	a2,0x3
ffffffffc0203136:	0ee60613          	addi	a2,a2,238 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020313a:	22a00593          	li	a1,554
ffffffffc020313e:	00003517          	auipc	a0,0x3
ffffffffc0203142:	58250513          	addi	a0,a0,1410 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203146:	b00fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020314a:	00004697          	auipc	a3,0x4
ffffffffc020314e:	8c668693          	addi	a3,a3,-1850 # ffffffffc0206a10 <etext+0x11d0>
ffffffffc0203152:	00003617          	auipc	a2,0x3
ffffffffc0203156:	0ce60613          	addi	a2,a2,206 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020315a:	22900593          	li	a1,553
ffffffffc020315e:	00003517          	auipc	a0,0x3
ffffffffc0203162:	56250513          	addi	a0,a0,1378 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203166:	ae0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020316a:	00004697          	auipc	a3,0x4
ffffffffc020316e:	88e68693          	addi	a3,a3,-1906 # ffffffffc02069f8 <etext+0x11b8>
ffffffffc0203172:	00003617          	auipc	a2,0x3
ffffffffc0203176:	0ae60613          	addi	a2,a2,174 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020317a:	22700593          	li	a1,551
ffffffffc020317e:	00003517          	auipc	a0,0x3
ffffffffc0203182:	54250513          	addi	a0,a0,1346 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203186:	ac0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020318a:	00004697          	auipc	a3,0x4
ffffffffc020318e:	84e68693          	addi	a3,a3,-1970 # ffffffffc02069d8 <etext+0x1198>
ffffffffc0203192:	00003617          	auipc	a2,0x3
ffffffffc0203196:	08e60613          	addi	a2,a2,142 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020319a:	22600593          	li	a1,550
ffffffffc020319e:	00003517          	auipc	a0,0x3
ffffffffc02031a2:	52250513          	addi	a0,a0,1314 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02031a6:	aa0fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031aa:	00004697          	auipc	a3,0x4
ffffffffc02031ae:	81e68693          	addi	a3,a3,-2018 # ffffffffc02069c8 <etext+0x1188>
ffffffffc02031b2:	00003617          	auipc	a2,0x3
ffffffffc02031b6:	06e60613          	addi	a2,a2,110 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02031ba:	22500593          	li	a1,549
ffffffffc02031be:	00003517          	auipc	a0,0x3
ffffffffc02031c2:	50250513          	addi	a0,a0,1282 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02031c6:	a80fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031ca:	00003697          	auipc	a3,0x3
ffffffffc02031ce:	7ee68693          	addi	a3,a3,2030 # ffffffffc02069b8 <etext+0x1178>
ffffffffc02031d2:	00003617          	auipc	a2,0x3
ffffffffc02031d6:	04e60613          	addi	a2,a2,78 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02031da:	22400593          	li	a1,548
ffffffffc02031de:	00003517          	auipc	a0,0x3
ffffffffc02031e2:	4e250513          	addi	a0,a0,1250 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02031e6:	a60fd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031ea:	00003617          	auipc	a2,0x3
ffffffffc02031ee:	48e60613          	addi	a2,a2,1166 # ffffffffc0206678 <etext+0xe38>
ffffffffc02031f2:	08100593          	li	a1,129
ffffffffc02031f6:	00003517          	auipc	a0,0x3
ffffffffc02031fa:	4ca50513          	addi	a0,a0,1226 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02031fe:	a48fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203202:	00003697          	auipc	a3,0x3
ffffffffc0203206:	70e68693          	addi	a3,a3,1806 # ffffffffc0206910 <etext+0x10d0>
ffffffffc020320a:	00003617          	auipc	a2,0x3
ffffffffc020320e:	01660613          	addi	a2,a2,22 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203212:	21f00593          	li	a1,543
ffffffffc0203216:	00003517          	auipc	a0,0x3
ffffffffc020321a:	4aa50513          	addi	a0,a0,1194 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020321e:	a28fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203222:	00003697          	auipc	a3,0x3
ffffffffc0203226:	75e68693          	addi	a3,a3,1886 # ffffffffc0206980 <etext+0x1140>
ffffffffc020322a:	00003617          	auipc	a2,0x3
ffffffffc020322e:	ff660613          	addi	a2,a2,-10 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203232:	22300593          	li	a1,547
ffffffffc0203236:	00003517          	auipc	a0,0x3
ffffffffc020323a:	48a50513          	addi	a0,a0,1162 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020323e:	a08fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203242:	00003697          	auipc	a3,0x3
ffffffffc0203246:	6fe68693          	addi	a3,a3,1790 # ffffffffc0206940 <etext+0x1100>
ffffffffc020324a:	00003617          	auipc	a2,0x3
ffffffffc020324e:	fd660613          	addi	a2,a2,-42 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203252:	22200593          	li	a1,546
ffffffffc0203256:	00003517          	auipc	a0,0x3
ffffffffc020325a:	46a50513          	addi	a0,a0,1130 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020325e:	9e8fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203262:	86d6                	mv	a3,s5
ffffffffc0203264:	00003617          	auipc	a2,0x3
ffffffffc0203268:	36c60613          	addi	a2,a2,876 # ffffffffc02065d0 <etext+0xd90>
ffffffffc020326c:	21e00593          	li	a1,542
ffffffffc0203270:	00003517          	auipc	a0,0x3
ffffffffc0203274:	45050513          	addi	a0,a0,1104 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203278:	9cefd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020327c:	00003617          	auipc	a2,0x3
ffffffffc0203280:	35460613          	addi	a2,a2,852 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0203284:	21d00593          	li	a1,541
ffffffffc0203288:	00003517          	auipc	a0,0x3
ffffffffc020328c:	43850513          	addi	a0,a0,1080 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203290:	9b6fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203294:	00003697          	auipc	a3,0x3
ffffffffc0203298:	66468693          	addi	a3,a3,1636 # ffffffffc02068f8 <etext+0x10b8>
ffffffffc020329c:	00003617          	auipc	a2,0x3
ffffffffc02032a0:	f8460613          	addi	a2,a2,-124 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02032a4:	21b00593          	li	a1,539
ffffffffc02032a8:	00003517          	auipc	a0,0x3
ffffffffc02032ac:	41850513          	addi	a0,a0,1048 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02032b0:	996fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032b4:	00003697          	auipc	a3,0x3
ffffffffc02032b8:	62c68693          	addi	a3,a3,1580 # ffffffffc02068e0 <etext+0x10a0>
ffffffffc02032bc:	00003617          	auipc	a2,0x3
ffffffffc02032c0:	f6460613          	addi	a2,a2,-156 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02032c4:	21a00593          	li	a1,538
ffffffffc02032c8:	00003517          	auipc	a0,0x3
ffffffffc02032cc:	3f850513          	addi	a0,a0,1016 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02032d0:	976fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032d4:	00004697          	auipc	a3,0x4
ffffffffc02032d8:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0206c90 <etext+0x1450>
ffffffffc02032dc:	00003617          	auipc	a2,0x3
ffffffffc02032e0:	f4460613          	addi	a2,a2,-188 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02032e4:	26100593          	li	a1,609
ffffffffc02032e8:	00003517          	auipc	a0,0x3
ffffffffc02032ec:	3d850513          	addi	a0,a0,984 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02032f0:	956fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032f4:	00004697          	auipc	a3,0x4
ffffffffc02032f8:	96468693          	addi	a3,a3,-1692 # ffffffffc0206c58 <etext+0x1418>
ffffffffc02032fc:	00003617          	auipc	a2,0x3
ffffffffc0203300:	f2460613          	addi	a2,a2,-220 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203304:	25e00593          	li	a1,606
ffffffffc0203308:	00003517          	auipc	a0,0x3
ffffffffc020330c:	3b850513          	addi	a0,a0,952 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203310:	936fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203314:	00004697          	auipc	a3,0x4
ffffffffc0203318:	91468693          	addi	a3,a3,-1772 # ffffffffc0206c28 <etext+0x13e8>
ffffffffc020331c:	00003617          	auipc	a2,0x3
ffffffffc0203320:	f0460613          	addi	a2,a2,-252 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203324:	25a00593          	li	a1,602
ffffffffc0203328:	00003517          	auipc	a0,0x3
ffffffffc020332c:	39850513          	addi	a0,a0,920 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203330:	916fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203334:	00004697          	auipc	a3,0x4
ffffffffc0203338:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0206be0 <etext+0x13a0>
ffffffffc020333c:	00003617          	auipc	a2,0x3
ffffffffc0203340:	ee460613          	addi	a2,a2,-284 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203344:	25900593          	li	a1,601
ffffffffc0203348:	00003517          	auipc	a0,0x3
ffffffffc020334c:	37850513          	addi	a0,a0,888 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203350:	8f6fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203354:	00003697          	auipc	a3,0x3
ffffffffc0203358:	4d468693          	addi	a3,a3,1236 # ffffffffc0206828 <etext+0xfe8>
ffffffffc020335c:	00003617          	auipc	a2,0x3
ffffffffc0203360:	ec460613          	addi	a2,a2,-316 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203364:	21200593          	li	a1,530
ffffffffc0203368:	00003517          	auipc	a0,0x3
ffffffffc020336c:	35850513          	addi	a0,a0,856 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203370:	8d6fd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203374:	00003617          	auipc	a2,0x3
ffffffffc0203378:	30460613          	addi	a2,a2,772 # ffffffffc0206678 <etext+0xe38>
ffffffffc020337c:	0c900593          	li	a1,201
ffffffffc0203380:	00003517          	auipc	a0,0x3
ffffffffc0203384:	34050513          	addi	a0,a0,832 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203388:	8befd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020338c:	00003697          	auipc	a3,0x3
ffffffffc0203390:	4fc68693          	addi	a3,a3,1276 # ffffffffc0206888 <etext+0x1048>
ffffffffc0203394:	00003617          	auipc	a2,0x3
ffffffffc0203398:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020339c:	21900593          	li	a1,537
ffffffffc02033a0:	00003517          	auipc	a0,0x3
ffffffffc02033a4:	32050513          	addi	a0,a0,800 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02033a8:	89efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033ac:	00003697          	auipc	a3,0x3
ffffffffc02033b0:	4ac68693          	addi	a3,a3,1196 # ffffffffc0206858 <etext+0x1018>
ffffffffc02033b4:	00003617          	auipc	a2,0x3
ffffffffc02033b8:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02033bc:	21600593          	li	a1,534
ffffffffc02033c0:	00003517          	auipc	a0,0x3
ffffffffc02033c4:	30050513          	addi	a0,a0,768 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02033c8:	87efd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02033cc <copy_range>:
{
ffffffffc02033cc:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033ce:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033d2:	f486                	sd	ra,104(sp)
ffffffffc02033d4:	f0a2                	sd	s0,96(sp)
ffffffffc02033d6:	eca6                	sd	s1,88(sp)
ffffffffc02033d8:	e8ca                	sd	s2,80(sp)
ffffffffc02033da:	e4ce                	sd	s3,72(sp)
ffffffffc02033dc:	e0d2                	sd	s4,64(sp)
ffffffffc02033de:	fc56                	sd	s5,56(sp)
ffffffffc02033e0:	f85a                	sd	s6,48(sp)
ffffffffc02033e2:	f45e                	sd	s7,40(sp)
ffffffffc02033e4:	f062                	sd	s8,32(sp)
ffffffffc02033e6:	ec66                	sd	s9,24(sp)
ffffffffc02033e8:	e86a                	sd	s10,16(sp)
ffffffffc02033ea:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033ec:	03479713          	slli	a4,a5,0x34
ffffffffc02033f0:	20071f63          	bnez	a4,ffffffffc020360e <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc02033f4:	002007b7          	lui	a5,0x200
ffffffffc02033f8:	00d63733          	sltu	a4,a2,a3
ffffffffc02033fc:	00f637b3          	sltu	a5,a2,a5
ffffffffc0203400:	00173713          	seqz	a4,a4
ffffffffc0203404:	8fd9                	or	a5,a5,a4
ffffffffc0203406:	8432                	mv	s0,a2
ffffffffc0203408:	8936                	mv	s2,a3
ffffffffc020340a:	1e079263          	bnez	a5,ffffffffc02035ee <copy_range+0x222>
ffffffffc020340e:	4785                	li	a5,1
ffffffffc0203410:	07fe                	slli	a5,a5,0x1f
ffffffffc0203412:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e29>
ffffffffc0203414:	1cf6fd63          	bgeu	a3,a5,ffffffffc02035ee <copy_range+0x222>
ffffffffc0203418:	5b7d                	li	s6,-1
ffffffffc020341a:	8baa                	mv	s7,a0
ffffffffc020341c:	8a2e                	mv	s4,a1
ffffffffc020341e:	6a85                	lui	s5,0x1
ffffffffc0203420:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc0203424:	00098c97          	auipc	s9,0x98
ffffffffc0203428:	334c8c93          	addi	s9,s9,820 # ffffffffc029b758 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020342c:	00098c17          	auipc	s8,0x98
ffffffffc0203430:	334c0c13          	addi	s8,s8,820 # ffffffffc029b760 <pages>
ffffffffc0203434:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203438:	4601                	li	a2,0
ffffffffc020343a:	85a2                	mv	a1,s0
ffffffffc020343c:	8552                	mv	a0,s4
ffffffffc020343e:	b19fe0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc0203442:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203444:	0e050a63          	beqz	a0,ffffffffc0203538 <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc0203448:	611c                	ld	a5,0(a0)
ffffffffc020344a:	8b85                	andi	a5,a5,1
ffffffffc020344c:	e78d                	bnez	a5,ffffffffc0203476 <copy_range+0xaa>
        start += PGSIZE;
ffffffffc020344e:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0203450:	c019                	beqz	s0,ffffffffc0203456 <copy_range+0x8a>
ffffffffc0203452:	ff2463e3          	bltu	s0,s2,ffffffffc0203438 <copy_range+0x6c>
    return 0;
ffffffffc0203456:	4501                	li	a0,0
}
ffffffffc0203458:	70a6                	ld	ra,104(sp)
ffffffffc020345a:	7406                	ld	s0,96(sp)
ffffffffc020345c:	64e6                	ld	s1,88(sp)
ffffffffc020345e:	6946                	ld	s2,80(sp)
ffffffffc0203460:	69a6                	ld	s3,72(sp)
ffffffffc0203462:	6a06                	ld	s4,64(sp)
ffffffffc0203464:	7ae2                	ld	s5,56(sp)
ffffffffc0203466:	7b42                	ld	s6,48(sp)
ffffffffc0203468:	7ba2                	ld	s7,40(sp)
ffffffffc020346a:	7c02                	ld	s8,32(sp)
ffffffffc020346c:	6ce2                	ld	s9,24(sp)
ffffffffc020346e:	6d42                	ld	s10,16(sp)
ffffffffc0203470:	6da2                	ld	s11,8(sp)
ffffffffc0203472:	6165                	addi	sp,sp,112
ffffffffc0203474:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203476:	4605                	li	a2,1
ffffffffc0203478:	85a2                	mv	a1,s0
ffffffffc020347a:	855e                	mv	a0,s7
ffffffffc020347c:	adbfe0ef          	jal	ffffffffc0201f56 <get_pte>
ffffffffc0203480:	c165                	beqz	a0,ffffffffc0203560 <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203482:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203486:	0019f793          	andi	a5,s3,1
ffffffffc020348a:	14078663          	beqz	a5,ffffffffc02035d6 <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc020348e:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203492:	00299793          	slli	a5,s3,0x2
ffffffffc0203496:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203498:	12e7f363          	bgeu	a5,a4,ffffffffc02035be <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc020349c:	000c3483          	ld	s1,0(s8)
ffffffffc02034a0:	97ea                	add	a5,a5,s10
ffffffffc02034a2:	079a                	slli	a5,a5,0x6
ffffffffc02034a4:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034a6:	100027f3          	csrr	a5,sstatus
ffffffffc02034aa:	8b89                	andi	a5,a5,2
ffffffffc02034ac:	efc9                	bnez	a5,ffffffffc0203546 <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034ae:	00098797          	auipc	a5,0x98
ffffffffc02034b2:	28a7b783          	ld	a5,650(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc02034b6:	4505                	li	a0,1
ffffffffc02034b8:	6f9c                	ld	a5,24(a5)
ffffffffc02034ba:	9782                	jalr	a5
ffffffffc02034bc:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc02034be:	c0e5                	beqz	s1,ffffffffc020359e <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc02034c0:	0a0d8f63          	beqz	s11,ffffffffc020357e <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc02034c4:	000c3783          	ld	a5,0(s8)
ffffffffc02034c8:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc02034cc:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc02034d0:	40f486b3          	sub	a3,s1,a5
ffffffffc02034d4:	8699                	srai	a3,a3,0x6
ffffffffc02034d6:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02034d8:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034dc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034de:	08e5f463          	bgeu	a1,a4,ffffffffc0203566 <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc02034e2:	40fd87b3          	sub	a5,s11,a5
ffffffffc02034e6:	8799                	srai	a5,a5,0x6
ffffffffc02034e8:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc02034ea:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034ee:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034f0:	06e67a63          	bgeu	a2,a4,ffffffffc0203564 <copy_range+0x198>
ffffffffc02034f4:	00098517          	auipc	a0,0x98
ffffffffc02034f8:	25c53503          	ld	a0,604(a0) # ffffffffc029b750 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034fc:	6605                	lui	a2,0x1
ffffffffc02034fe:	00a685b3          	add	a1,a3,a0
ffffffffc0203502:	953e                	add	a0,a0,a5
ffffffffc0203504:	324020ef          	jal	ffffffffc0205828 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc0203508:	01f9f693          	andi	a3,s3,31
ffffffffc020350c:	85ee                	mv	a1,s11
ffffffffc020350e:	8622                	mv	a2,s0
ffffffffc0203510:	855e                	mv	a0,s7
ffffffffc0203512:	97aff0ef          	jal	ffffffffc020268c <page_insert>
            assert(ret == 0);
ffffffffc0203516:	dd05                	beqz	a0,ffffffffc020344e <copy_range+0x82>
ffffffffc0203518:	00003697          	auipc	a3,0x3
ffffffffc020351c:	7e068693          	addi	a3,a3,2016 # ffffffffc0206cf8 <etext+0x14b8>
ffffffffc0203520:	00003617          	auipc	a2,0x3
ffffffffc0203524:	d0060613          	addi	a2,a2,-768 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203528:	1ae00593          	li	a1,430
ffffffffc020352c:	00003517          	auipc	a0,0x3
ffffffffc0203530:	19450513          	addi	a0,a0,404 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203534:	f13fc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203538:	002007b7          	lui	a5,0x200
ffffffffc020353c:	97a2                	add	a5,a5,s0
ffffffffc020353e:	ffe00437          	lui	s0,0xffe00
ffffffffc0203542:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0203544:	b731                	j	ffffffffc0203450 <copy_range+0x84>
        intr_disable();
ffffffffc0203546:	bbefd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020354a:	00098797          	auipc	a5,0x98
ffffffffc020354e:	1ee7b783          	ld	a5,494(a5) # ffffffffc029b738 <pmm_manager>
ffffffffc0203552:	4505                	li	a0,1
ffffffffc0203554:	6f9c                	ld	a5,24(a5)
ffffffffc0203556:	9782                	jalr	a5
ffffffffc0203558:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc020355a:	ba4fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020355e:	b785                	j	ffffffffc02034be <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc0203560:	5571                	li	a0,-4
ffffffffc0203562:	bddd                	j	ffffffffc0203458 <copy_range+0x8c>
ffffffffc0203564:	86be                	mv	a3,a5
ffffffffc0203566:	00003617          	auipc	a2,0x3
ffffffffc020356a:	06a60613          	addi	a2,a2,106 # ffffffffc02065d0 <etext+0xd90>
ffffffffc020356e:	07100593          	li	a1,113
ffffffffc0203572:	00003517          	auipc	a0,0x3
ffffffffc0203576:	08650513          	addi	a0,a0,134 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc020357a:	ecdfc0ef          	jal	ffffffffc0200446 <__panic>
            assert(npage != NULL);
ffffffffc020357e:	00003697          	auipc	a3,0x3
ffffffffc0203582:	76a68693          	addi	a3,a3,1898 # ffffffffc0206ce8 <etext+0x14a8>
ffffffffc0203586:	00003617          	auipc	a2,0x3
ffffffffc020358a:	c9a60613          	addi	a2,a2,-870 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020358e:	19500593          	li	a1,405
ffffffffc0203592:	00003517          	auipc	a0,0x3
ffffffffc0203596:	12e50513          	addi	a0,a0,302 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020359a:	eadfc0ef          	jal	ffffffffc0200446 <__panic>
            assert(page != NULL);
ffffffffc020359e:	00003697          	auipc	a3,0x3
ffffffffc02035a2:	73a68693          	addi	a3,a3,1850 # ffffffffc0206cd8 <etext+0x1498>
ffffffffc02035a6:	00003617          	auipc	a2,0x3
ffffffffc02035aa:	c7a60613          	addi	a2,a2,-902 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02035ae:	19400593          	li	a1,404
ffffffffc02035b2:	00003517          	auipc	a0,0x3
ffffffffc02035b6:	10e50513          	addi	a0,a0,270 # ffffffffc02066c0 <etext+0xe80>
ffffffffc02035ba:	e8dfc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035be:	00003617          	auipc	a2,0x3
ffffffffc02035c2:	0e260613          	addi	a2,a2,226 # ffffffffc02066a0 <etext+0xe60>
ffffffffc02035c6:	06900593          	li	a1,105
ffffffffc02035ca:	00003517          	auipc	a0,0x3
ffffffffc02035ce:	02e50513          	addi	a0,a0,46 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02035d2:	e75fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035d6:	00003617          	auipc	a2,0x3
ffffffffc02035da:	2e260613          	addi	a2,a2,738 # ffffffffc02068b8 <etext+0x1078>
ffffffffc02035de:	07f00593          	li	a1,127
ffffffffc02035e2:	00003517          	auipc	a0,0x3
ffffffffc02035e6:	01650513          	addi	a0,a0,22 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02035ea:	e5dfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02035ee:	00003697          	auipc	a3,0x3
ffffffffc02035f2:	11268693          	addi	a3,a3,274 # ffffffffc0206700 <etext+0xec0>
ffffffffc02035f6:	00003617          	auipc	a2,0x3
ffffffffc02035fa:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02035fe:	17c00593          	li	a1,380
ffffffffc0203602:	00003517          	auipc	a0,0x3
ffffffffc0203606:	0be50513          	addi	a0,a0,190 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020360a:	e3dfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020360e:	00003697          	auipc	a3,0x3
ffffffffc0203612:	0c268693          	addi	a3,a3,194 # ffffffffc02066d0 <etext+0xe90>
ffffffffc0203616:	00003617          	auipc	a2,0x3
ffffffffc020361a:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020361e:	17b00593          	li	a1,379
ffffffffc0203622:	00003517          	auipc	a0,0x3
ffffffffc0203626:	09e50513          	addi	a0,a0,158 # ffffffffc02066c0 <etext+0xe80>
ffffffffc020362a:	e1dfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020362e <pgdir_alloc_page>:
{
ffffffffc020362e:	7139                	addi	sp,sp,-64
ffffffffc0203630:	f426                	sd	s1,40(sp)
ffffffffc0203632:	f04a                	sd	s2,32(sp)
ffffffffc0203634:	ec4e                	sd	s3,24(sp)
ffffffffc0203636:	fc06                	sd	ra,56(sp)
ffffffffc0203638:	f822                	sd	s0,48(sp)
ffffffffc020363a:	892a                	mv	s2,a0
ffffffffc020363c:	84ae                	mv	s1,a1
ffffffffc020363e:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203640:	100027f3          	csrr	a5,sstatus
ffffffffc0203644:	8b89                	andi	a5,a5,2
ffffffffc0203646:	ebb5                	bnez	a5,ffffffffc02036ba <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203648:	00098417          	auipc	s0,0x98
ffffffffc020364c:	0f040413          	addi	s0,s0,240 # ffffffffc029b738 <pmm_manager>
ffffffffc0203650:	601c                	ld	a5,0(s0)
ffffffffc0203652:	4505                	li	a0,1
ffffffffc0203654:	6f9c                	ld	a5,24(a5)
ffffffffc0203656:	9782                	jalr	a5
ffffffffc0203658:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc020365a:	c5b9                	beqz	a1,ffffffffc02036a8 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc020365c:	86ce                	mv	a3,s3
ffffffffc020365e:	854a                	mv	a0,s2
ffffffffc0203660:	8626                	mv	a2,s1
ffffffffc0203662:	e42e                	sd	a1,8(sp)
ffffffffc0203664:	828ff0ef          	jal	ffffffffc020268c <page_insert>
ffffffffc0203668:	65a2                	ld	a1,8(sp)
ffffffffc020366a:	e515                	bnez	a0,ffffffffc0203696 <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc020366c:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc020366e:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc0203670:	4785                	li	a5,1
ffffffffc0203672:	02f70c63          	beq	a4,a5,ffffffffc02036aa <pgdir_alloc_page+0x7c>
ffffffffc0203676:	00003697          	auipc	a3,0x3
ffffffffc020367a:	69268693          	addi	a3,a3,1682 # ffffffffc0206d08 <etext+0x14c8>
ffffffffc020367e:	00003617          	auipc	a2,0x3
ffffffffc0203682:	ba260613          	addi	a2,a2,-1118 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203686:	1f700593          	li	a1,503
ffffffffc020368a:	00003517          	auipc	a0,0x3
ffffffffc020368e:	03650513          	addi	a0,a0,54 # ffffffffc02066c0 <etext+0xe80>
ffffffffc0203692:	db5fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0203696:	100027f3          	csrr	a5,sstatus
ffffffffc020369a:	8b89                	andi	a5,a5,2
ffffffffc020369c:	ef95                	bnez	a5,ffffffffc02036d8 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc020369e:	601c                	ld	a5,0(s0)
ffffffffc02036a0:	852e                	mv	a0,a1
ffffffffc02036a2:	4585                	li	a1,1
ffffffffc02036a4:	739c                	ld	a5,32(a5)
ffffffffc02036a6:	9782                	jalr	a5
            return NULL;
ffffffffc02036a8:	4581                	li	a1,0
}
ffffffffc02036aa:	70e2                	ld	ra,56(sp)
ffffffffc02036ac:	7442                	ld	s0,48(sp)
ffffffffc02036ae:	74a2                	ld	s1,40(sp)
ffffffffc02036b0:	7902                	ld	s2,32(sp)
ffffffffc02036b2:	69e2                	ld	s3,24(sp)
ffffffffc02036b4:	852e                	mv	a0,a1
ffffffffc02036b6:	6121                	addi	sp,sp,64
ffffffffc02036b8:	8082                	ret
        intr_disable();
ffffffffc02036ba:	a4afd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036be:	00098417          	auipc	s0,0x98
ffffffffc02036c2:	07a40413          	addi	s0,s0,122 # ffffffffc029b738 <pmm_manager>
ffffffffc02036c6:	601c                	ld	a5,0(s0)
ffffffffc02036c8:	4505                	li	a0,1
ffffffffc02036ca:	6f9c                	ld	a5,24(a5)
ffffffffc02036cc:	9782                	jalr	a5
ffffffffc02036ce:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02036d0:	a2efd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036d4:	65a2                	ld	a1,8(sp)
ffffffffc02036d6:	b751                	j	ffffffffc020365a <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02036d8:	a2cfd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02036dc:	601c                	ld	a5,0(s0)
ffffffffc02036de:	6522                	ld	a0,8(sp)
ffffffffc02036e0:	4585                	li	a1,1
ffffffffc02036e2:	739c                	ld	a5,32(a5)
ffffffffc02036e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02036e6:	a18fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036ea:	bf7d                	j	ffffffffc02036a8 <pgdir_alloc_page+0x7a>

ffffffffc02036ec <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036ec:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036ee:	00003697          	auipc	a3,0x3
ffffffffc02036f2:	63268693          	addi	a3,a3,1586 # ffffffffc0206d20 <etext+0x14e0>
ffffffffc02036f6:	00003617          	auipc	a2,0x3
ffffffffc02036fa:	b2a60613          	addi	a2,a2,-1238 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02036fe:	07400593          	li	a1,116
ffffffffc0203702:	00003517          	auipc	a0,0x3
ffffffffc0203706:	63e50513          	addi	a0,a0,1598 # ffffffffc0206d40 <etext+0x1500>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020370a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020370c:	d3bfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203710 <mm_create>:
{
ffffffffc0203710:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203712:	04000513          	li	a0,64
{
ffffffffc0203716:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203718:	dd4fe0ef          	jal	ffffffffc0201cec <kmalloc>
    if (mm != NULL)
ffffffffc020371c:	cd19                	beqz	a0,ffffffffc020373a <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020371e:	e508                	sd	a0,8(a0)
ffffffffc0203720:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203722:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203726:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020372a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020372e:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203732:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203736:	02053c23          	sd	zero,56(a0)
}
ffffffffc020373a:	60a2                	ld	ra,8(sp)
ffffffffc020373c:	0141                	addi	sp,sp,16
ffffffffc020373e:	8082                	ret

ffffffffc0203740 <find_vma>:
    if (mm != NULL)
ffffffffc0203740:	c505                	beqz	a0,ffffffffc0203768 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0203742:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203744:	c781                	beqz	a5,ffffffffc020374c <find_vma+0xc>
ffffffffc0203746:	6798                	ld	a4,8(a5)
ffffffffc0203748:	02e5f363          	bgeu	a1,a4,ffffffffc020376e <find_vma+0x2e>
    return listelm->next;
ffffffffc020374c:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc020374e:	00f50d63          	beq	a0,a5,ffffffffc0203768 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203752:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203756:	00e5e663          	bltu	a1,a4,ffffffffc0203762 <find_vma+0x22>
ffffffffc020375a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020375e:	00e5ee63          	bltu	a1,a4,ffffffffc020377a <find_vma+0x3a>
ffffffffc0203762:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203764:	fef517e3          	bne	a0,a5,ffffffffc0203752 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0203768:	4781                	li	a5,0
}
ffffffffc020376a:	853e                	mv	a0,a5
ffffffffc020376c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020376e:	6b98                	ld	a4,16(a5)
ffffffffc0203770:	fce5fee3          	bgeu	a1,a4,ffffffffc020374c <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0203774:	e91c                	sd	a5,16(a0)
}
ffffffffc0203776:	853e                	mv	a0,a5
ffffffffc0203778:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc020377a:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc020377c:	e91c                	sd	a5,16(a0)
ffffffffc020377e:	bfe5                	j	ffffffffc0203776 <find_vma+0x36>

ffffffffc0203780 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203780:	6590                	ld	a2,8(a1)
ffffffffc0203782:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203786:	1141                	addi	sp,sp,-16
ffffffffc0203788:	e406                	sd	ra,8(sp)
ffffffffc020378a:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020378c:	01066763          	bltu	a2,a6,ffffffffc020379a <insert_vma_struct+0x1a>
ffffffffc0203790:	a8b9                	j	ffffffffc02037ee <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203792:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203796:	04e66763          	bltu	a2,a4,ffffffffc02037e4 <insert_vma_struct+0x64>
ffffffffc020379a:	86be                	mv	a3,a5
ffffffffc020379c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020379e:	fef51ae3          	bne	a0,a5,ffffffffc0203792 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02037a2:	02a68463          	beq	a3,a0,ffffffffc02037ca <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02037a6:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037aa:	fe86b883          	ld	a7,-24(a3)
ffffffffc02037ae:	08e8f063          	bgeu	a7,a4,ffffffffc020382e <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037b2:	04e66e63          	bltu	a2,a4,ffffffffc020380e <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02037b6:	00f50a63          	beq	a0,a5,ffffffffc02037ca <insert_vma_struct+0x4a>
ffffffffc02037ba:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037be:	05076863          	bltu	a4,a6,ffffffffc020380e <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02037c2:	ff07b603          	ld	a2,-16(a5)
ffffffffc02037c6:	02c77263          	bgeu	a4,a2,ffffffffc02037ea <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02037ca:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02037cc:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02037ce:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02037d2:	e390                	sd	a2,0(a5)
ffffffffc02037d4:	e690                	sd	a2,8(a3)
}
ffffffffc02037d6:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02037d8:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02037da:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02037dc:	2705                	addiw	a4,a4,1
ffffffffc02037de:	d118                	sw	a4,32(a0)
}
ffffffffc02037e0:	0141                	addi	sp,sp,16
ffffffffc02037e2:	8082                	ret
    if (le_prev != list)
ffffffffc02037e4:	fca691e3          	bne	a3,a0,ffffffffc02037a6 <insert_vma_struct+0x26>
ffffffffc02037e8:	bfd9                	j	ffffffffc02037be <insert_vma_struct+0x3e>
ffffffffc02037ea:	f03ff0ef          	jal	ffffffffc02036ec <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037ee:	00003697          	auipc	a3,0x3
ffffffffc02037f2:	56268693          	addi	a3,a3,1378 # ffffffffc0206d50 <etext+0x1510>
ffffffffc02037f6:	00003617          	auipc	a2,0x3
ffffffffc02037fa:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02037fe:	07a00593          	li	a1,122
ffffffffc0203802:	00003517          	auipc	a0,0x3
ffffffffc0203806:	53e50513          	addi	a0,a0,1342 # ffffffffc0206d40 <etext+0x1500>
ffffffffc020380a:	c3dfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020380e:	00003697          	auipc	a3,0x3
ffffffffc0203812:	58268693          	addi	a3,a3,1410 # ffffffffc0206d90 <etext+0x1550>
ffffffffc0203816:	00003617          	auipc	a2,0x3
ffffffffc020381a:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020381e:	07300593          	li	a1,115
ffffffffc0203822:	00003517          	auipc	a0,0x3
ffffffffc0203826:	51e50513          	addi	a0,a0,1310 # ffffffffc0206d40 <etext+0x1500>
ffffffffc020382a:	c1dfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020382e:	00003697          	auipc	a3,0x3
ffffffffc0203832:	54268693          	addi	a3,a3,1346 # ffffffffc0206d70 <etext+0x1530>
ffffffffc0203836:	00003617          	auipc	a2,0x3
ffffffffc020383a:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020383e:	07200593          	li	a1,114
ffffffffc0203842:	00003517          	auipc	a0,0x3
ffffffffc0203846:	4fe50513          	addi	a0,a0,1278 # ffffffffc0206d40 <etext+0x1500>
ffffffffc020384a:	bfdfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020384e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020384e:	591c                	lw	a5,48(a0)
{
ffffffffc0203850:	1141                	addi	sp,sp,-16
ffffffffc0203852:	e406                	sd	ra,8(sp)
ffffffffc0203854:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203856:	e78d                	bnez	a5,ffffffffc0203880 <mm_destroy+0x32>
ffffffffc0203858:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020385a:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc020385c:	00a40c63          	beq	s0,a0,ffffffffc0203874 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203860:	6118                	ld	a4,0(a0)
ffffffffc0203862:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203864:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203866:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203868:	e398                	sd	a4,0(a5)
ffffffffc020386a:	d28fe0ef          	jal	ffffffffc0201d92 <kfree>
    return listelm->next;
ffffffffc020386e:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203870:	fea418e3          	bne	s0,a0,ffffffffc0203860 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203874:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203876:	6402                	ld	s0,0(sp)
ffffffffc0203878:	60a2                	ld	ra,8(sp)
ffffffffc020387a:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020387c:	d16fe06f          	j	ffffffffc0201d92 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203880:	00003697          	auipc	a3,0x3
ffffffffc0203884:	53068693          	addi	a3,a3,1328 # ffffffffc0206db0 <etext+0x1570>
ffffffffc0203888:	00003617          	auipc	a2,0x3
ffffffffc020388c:	99860613          	addi	a2,a2,-1640 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203890:	09e00593          	li	a1,158
ffffffffc0203894:	00003517          	auipc	a0,0x3
ffffffffc0203898:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206d40 <etext+0x1500>
ffffffffc020389c:	babfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02038a0 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038a0:	6785                	lui	a5,0x1
ffffffffc02038a2:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7bd1>
ffffffffc02038a4:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc02038a6:	4785                	li	a5,1
{
ffffffffc02038a8:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038aa:	962e                	add	a2,a2,a1
ffffffffc02038ac:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc02038ae:	07fe                	slli	a5,a5,0x1f
{
ffffffffc02038b0:	f822                	sd	s0,48(sp)
ffffffffc02038b2:	f426                	sd	s1,40(sp)
ffffffffc02038b4:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038b8:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02038bc:	0785                	addi	a5,a5,1
ffffffffc02038be:	0084b633          	sltu	a2,s1,s0
ffffffffc02038c2:	00f437b3          	sltu	a5,s0,a5
ffffffffc02038c6:	00163613          	seqz	a2,a2
ffffffffc02038ca:	0017b793          	seqz	a5,a5
{
ffffffffc02038ce:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02038d0:	8fd1                	or	a5,a5,a2
ffffffffc02038d2:	ebbd                	bnez	a5,ffffffffc0203948 <mm_map+0xa8>
ffffffffc02038d4:	002007b7          	lui	a5,0x200
ffffffffc02038d8:	06f4e863          	bltu	s1,a5,ffffffffc0203948 <mm_map+0xa8>
ffffffffc02038dc:	f04a                	sd	s2,32(sp)
ffffffffc02038de:	ec4e                	sd	s3,24(sp)
ffffffffc02038e0:	e852                	sd	s4,16(sp)
ffffffffc02038e2:	892a                	mv	s2,a0
ffffffffc02038e4:	89ba                	mv	s3,a4
ffffffffc02038e6:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02038e8:	c135                	beqz	a0,ffffffffc020394c <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02038ea:	85a6                	mv	a1,s1
ffffffffc02038ec:	e55ff0ef          	jal	ffffffffc0203740 <find_vma>
ffffffffc02038f0:	c501                	beqz	a0,ffffffffc02038f8 <mm_map+0x58>
ffffffffc02038f2:	651c                	ld	a5,8(a0)
ffffffffc02038f4:	0487e763          	bltu	a5,s0,ffffffffc0203942 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038f8:	03000513          	li	a0,48
ffffffffc02038fc:	bf0fe0ef          	jal	ffffffffc0201cec <kmalloc>
ffffffffc0203900:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203902:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203904:	c59d                	beqz	a1,ffffffffc0203932 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc0203906:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc0203908:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020390a:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020390e:	854a                	mv	a0,s2
ffffffffc0203910:	e42e                	sd	a1,8(sp)
ffffffffc0203912:	e6fff0ef          	jal	ffffffffc0203780 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc0203916:	65a2                	ld	a1,8(sp)
ffffffffc0203918:	00098463          	beqz	s3,ffffffffc0203920 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc020391c:	00b9b023          	sd	a1,0(s3)
ffffffffc0203920:	7902                	ld	s2,32(sp)
ffffffffc0203922:	69e2                	ld	s3,24(sp)
ffffffffc0203924:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc0203926:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203928:	70e2                	ld	ra,56(sp)
ffffffffc020392a:	7442                	ld	s0,48(sp)
ffffffffc020392c:	74a2                	ld	s1,40(sp)
ffffffffc020392e:	6121                	addi	sp,sp,64
ffffffffc0203930:	8082                	ret
ffffffffc0203932:	70e2                	ld	ra,56(sp)
ffffffffc0203934:	7442                	ld	s0,48(sp)
ffffffffc0203936:	7902                	ld	s2,32(sp)
ffffffffc0203938:	69e2                	ld	s3,24(sp)
ffffffffc020393a:	6a42                	ld	s4,16(sp)
ffffffffc020393c:	74a2                	ld	s1,40(sp)
ffffffffc020393e:	6121                	addi	sp,sp,64
ffffffffc0203940:	8082                	ret
ffffffffc0203942:	7902                	ld	s2,32(sp)
ffffffffc0203944:	69e2                	ld	s3,24(sp)
ffffffffc0203946:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203948:	5575                	li	a0,-3
ffffffffc020394a:	bff9                	j	ffffffffc0203928 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc020394c:	00003697          	auipc	a3,0x3
ffffffffc0203950:	47c68693          	addi	a3,a3,1148 # ffffffffc0206dc8 <etext+0x1588>
ffffffffc0203954:	00003617          	auipc	a2,0x3
ffffffffc0203958:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020395c:	0b300593          	li	a1,179
ffffffffc0203960:	00003517          	auipc	a0,0x3
ffffffffc0203964:	3e050513          	addi	a0,a0,992 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203968:	adffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020396c <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc020396c:	7139                	addi	sp,sp,-64
ffffffffc020396e:	fc06                	sd	ra,56(sp)
ffffffffc0203970:	f822                	sd	s0,48(sp)
ffffffffc0203972:	f426                	sd	s1,40(sp)
ffffffffc0203974:	f04a                	sd	s2,32(sp)
ffffffffc0203976:	ec4e                	sd	s3,24(sp)
ffffffffc0203978:	e852                	sd	s4,16(sp)
ffffffffc020397a:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc020397c:	c525                	beqz	a0,ffffffffc02039e4 <dup_mmap+0x78>
ffffffffc020397e:	892a                	mv	s2,a0
ffffffffc0203980:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203982:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203984:	c1a5                	beqz	a1,ffffffffc02039e4 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc0203986:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203988:	04848c63          	beq	s1,s0,ffffffffc02039e0 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020398c:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203990:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203994:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203998:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020399c:	b50fe0ef          	jal	ffffffffc0201cec <kmalloc>
    if (vma != NULL)
ffffffffc02039a0:	c515                	beqz	a0,ffffffffc02039cc <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039a2:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02039a4:	01553423          	sd	s5,8(a0)
ffffffffc02039a8:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039ac:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc02039b0:	854a                	mv	a0,s2
ffffffffc02039b2:	dcfff0ef          	jal	ffffffffc0203780 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039b6:	ff043683          	ld	a3,-16(s0)
ffffffffc02039ba:	fe843603          	ld	a2,-24(s0)
ffffffffc02039be:	6c8c                	ld	a1,24(s1)
ffffffffc02039c0:	01893503          	ld	a0,24(s2)
ffffffffc02039c4:	4701                	li	a4,0
ffffffffc02039c6:	a07ff0ef          	jal	ffffffffc02033cc <copy_range>
ffffffffc02039ca:	dd55                	beqz	a0,ffffffffc0203986 <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02039cc:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02039ce:	70e2                	ld	ra,56(sp)
ffffffffc02039d0:	7442                	ld	s0,48(sp)
ffffffffc02039d2:	74a2                	ld	s1,40(sp)
ffffffffc02039d4:	7902                	ld	s2,32(sp)
ffffffffc02039d6:	69e2                	ld	s3,24(sp)
ffffffffc02039d8:	6a42                	ld	s4,16(sp)
ffffffffc02039da:	6aa2                	ld	s5,8(sp)
ffffffffc02039dc:	6121                	addi	sp,sp,64
ffffffffc02039de:	8082                	ret
    return 0;
ffffffffc02039e0:	4501                	li	a0,0
ffffffffc02039e2:	b7f5                	j	ffffffffc02039ce <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc02039e4:	00003697          	auipc	a3,0x3
ffffffffc02039e8:	3f468693          	addi	a3,a3,1012 # ffffffffc0206dd8 <etext+0x1598>
ffffffffc02039ec:	00003617          	auipc	a2,0x3
ffffffffc02039f0:	83460613          	addi	a2,a2,-1996 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02039f4:	0cf00593          	li	a1,207
ffffffffc02039f8:	00003517          	auipc	a0,0x3
ffffffffc02039fc:	34850513          	addi	a0,a0,840 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203a00:	a47fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a04 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a04:	1101                	addi	sp,sp,-32
ffffffffc0203a06:	ec06                	sd	ra,24(sp)
ffffffffc0203a08:	e822                	sd	s0,16(sp)
ffffffffc0203a0a:	e426                	sd	s1,8(sp)
ffffffffc0203a0c:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a0e:	c531                	beqz	a0,ffffffffc0203a5a <exit_mmap+0x56>
ffffffffc0203a10:	591c                	lw	a5,48(a0)
ffffffffc0203a12:	84aa                	mv	s1,a0
ffffffffc0203a14:	e3b9                	bnez	a5,ffffffffc0203a5a <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a16:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a18:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a1c:	02850663          	beq	a0,s0,ffffffffc0203a48 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a20:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a24:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a28:	854a                	mv	a0,s2
ffffffffc0203a2a:	fdefe0ef          	jal	ffffffffc0202208 <unmap_range>
ffffffffc0203a2e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a30:	fe8498e3          	bne	s1,s0,ffffffffc0203a20 <exit_mmap+0x1c>
ffffffffc0203a34:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a36:	00848c63          	beq	s1,s0,ffffffffc0203a4e <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a3a:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a3e:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a42:	854a                	mv	a0,s2
ffffffffc0203a44:	8f9fe0ef          	jal	ffffffffc020233c <exit_range>
ffffffffc0203a48:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a4a:	fe8498e3          	bne	s1,s0,ffffffffc0203a3a <exit_mmap+0x36>
    }
}
ffffffffc0203a4e:	60e2                	ld	ra,24(sp)
ffffffffc0203a50:	6442                	ld	s0,16(sp)
ffffffffc0203a52:	64a2                	ld	s1,8(sp)
ffffffffc0203a54:	6902                	ld	s2,0(sp)
ffffffffc0203a56:	6105                	addi	sp,sp,32
ffffffffc0203a58:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a5a:	00003697          	auipc	a3,0x3
ffffffffc0203a5e:	39e68693          	addi	a3,a3,926 # ffffffffc0206df8 <etext+0x15b8>
ffffffffc0203a62:	00002617          	auipc	a2,0x2
ffffffffc0203a66:	7be60613          	addi	a2,a2,1982 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203a6a:	0e800593          	li	a1,232
ffffffffc0203a6e:	00003517          	auipc	a0,0x3
ffffffffc0203a72:	2d250513          	addi	a0,a0,722 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203a76:	9d1fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a7a <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a7a:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a7c:	04000513          	li	a0,64
{
ffffffffc0203a80:	f406                	sd	ra,40(sp)
ffffffffc0203a82:	f022                	sd	s0,32(sp)
ffffffffc0203a84:	ec26                	sd	s1,24(sp)
ffffffffc0203a86:	e84a                	sd	s2,16(sp)
ffffffffc0203a88:	e44e                	sd	s3,8(sp)
ffffffffc0203a8a:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a8c:	a60fe0ef          	jal	ffffffffc0201cec <kmalloc>
    if (mm != NULL)
ffffffffc0203a90:	16050c63          	beqz	a0,ffffffffc0203c08 <vmm_init+0x18e>
ffffffffc0203a94:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203a96:	e508                	sd	a0,8(a0)
ffffffffc0203a98:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a9a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a9e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203aa2:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203aa6:	02053423          	sd	zero,40(a0)
ffffffffc0203aaa:	02052823          	sw	zero,48(a0)
ffffffffc0203aae:	02053c23          	sd	zero,56(a0)
ffffffffc0203ab2:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ab6:	03000513          	li	a0,48
ffffffffc0203aba:	a32fe0ef          	jal	ffffffffc0201cec <kmalloc>
    if (vma != NULL)
ffffffffc0203abe:	12050563          	beqz	a0,ffffffffc0203be8 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203ac2:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203ac6:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ac8:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203acc:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ace:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203ad0:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203ad2:	8522                	mv	a0,s0
ffffffffc0203ad4:	cadff0ef          	jal	ffffffffc0203780 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203ad8:	fcf9                	bnez	s1,ffffffffc0203ab6 <vmm_init+0x3c>
ffffffffc0203ada:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ade:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ae2:	03000513          	li	a0,48
ffffffffc0203ae6:	a06fe0ef          	jal	ffffffffc0201cec <kmalloc>
    if (vma != NULL)
ffffffffc0203aea:	12050f63          	beqz	a0,ffffffffc0203c28 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203aee:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203af2:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203af4:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203af8:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203afa:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203afc:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203afe:	8522                	mv	a0,s0
ffffffffc0203b00:	c81ff0ef          	jal	ffffffffc0203780 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b04:	fd249fe3          	bne	s1,s2,ffffffffc0203ae2 <vmm_init+0x68>
    return listelm->next;
ffffffffc0203b08:	641c                	ld	a5,8(s0)
ffffffffc0203b0a:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203b0c:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203b10:	1ef40c63          	beq	s0,a5,ffffffffc0203d08 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b14:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5e10>
ffffffffc0203b18:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b1c:	12d61663          	bne	a2,a3,ffffffffc0203c48 <vmm_init+0x1ce>
ffffffffc0203b20:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b24:	12e69263          	bne	a3,a4,ffffffffc0203c48 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b28:	0715                	addi	a4,a4,5
ffffffffc0203b2a:	679c                	ld	a5,8(a5)
ffffffffc0203b2c:	feb712e3          	bne	a4,a1,ffffffffc0203b10 <vmm_init+0x96>
ffffffffc0203b30:	491d                	li	s2,7
ffffffffc0203b32:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b34:	85a6                	mv	a1,s1
ffffffffc0203b36:	8522                	mv	a0,s0
ffffffffc0203b38:	c09ff0ef          	jal	ffffffffc0203740 <find_vma>
ffffffffc0203b3c:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b3e:	20050563          	beqz	a0,ffffffffc0203d48 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b42:	00148593          	addi	a1,s1,1
ffffffffc0203b46:	8522                	mv	a0,s0
ffffffffc0203b48:	bf9ff0ef          	jal	ffffffffc0203740 <find_vma>
ffffffffc0203b4c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b4e:	1c050d63          	beqz	a0,ffffffffc0203d28 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b52:	85ca                	mv	a1,s2
ffffffffc0203b54:	8522                	mv	a0,s0
ffffffffc0203b56:	bebff0ef          	jal	ffffffffc0203740 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b5a:	18051763          	bnez	a0,ffffffffc0203ce8 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b5e:	00348593          	addi	a1,s1,3
ffffffffc0203b62:	8522                	mv	a0,s0
ffffffffc0203b64:	bddff0ef          	jal	ffffffffc0203740 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b68:	16051063          	bnez	a0,ffffffffc0203cc8 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b6c:	00448593          	addi	a1,s1,4
ffffffffc0203b70:	8522                	mv	a0,s0
ffffffffc0203b72:	bcfff0ef          	jal	ffffffffc0203740 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b76:	12051963          	bnez	a0,ffffffffc0203ca8 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b7a:	008a3783          	ld	a5,8(s4)
ffffffffc0203b7e:	10979563          	bne	a5,s1,ffffffffc0203c88 <vmm_init+0x20e>
ffffffffc0203b82:	010a3783          	ld	a5,16(s4)
ffffffffc0203b86:	11279163          	bne	a5,s2,ffffffffc0203c88 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b8a:	0089b783          	ld	a5,8(s3)
ffffffffc0203b8e:	0c979d63          	bne	a5,s1,ffffffffc0203c68 <vmm_init+0x1ee>
ffffffffc0203b92:	0109b783          	ld	a5,16(s3)
ffffffffc0203b96:	0d279963          	bne	a5,s2,ffffffffc0203c68 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b9a:	0495                	addi	s1,s1,5
ffffffffc0203b9c:	1f900793          	li	a5,505
ffffffffc0203ba0:	0915                	addi	s2,s2,5
ffffffffc0203ba2:	f8f499e3          	bne	s1,a5,ffffffffc0203b34 <vmm_init+0xba>
ffffffffc0203ba6:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203ba8:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203baa:	85a6                	mv	a1,s1
ffffffffc0203bac:	8522                	mv	a0,s0
ffffffffc0203bae:	b93ff0ef          	jal	ffffffffc0203740 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203bb2:	1a051b63          	bnez	a0,ffffffffc0203d68 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203bb6:	14fd                	addi	s1,s1,-1
ffffffffc0203bb8:	ff2499e3          	bne	s1,s2,ffffffffc0203baa <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203bbc:	8522                	mv	a0,s0
ffffffffc0203bbe:	c91ff0ef          	jal	ffffffffc020384e <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bc2:	00003517          	auipc	a0,0x3
ffffffffc0203bc6:	3a650513          	addi	a0,a0,934 # ffffffffc0206f68 <etext+0x1728>
ffffffffc0203bca:	dcafc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203bce:	7402                	ld	s0,32(sp)
ffffffffc0203bd0:	70a2                	ld	ra,40(sp)
ffffffffc0203bd2:	64e2                	ld	s1,24(sp)
ffffffffc0203bd4:	6942                	ld	s2,16(sp)
ffffffffc0203bd6:	69a2                	ld	s3,8(sp)
ffffffffc0203bd8:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bda:	00003517          	auipc	a0,0x3
ffffffffc0203bde:	3ae50513          	addi	a0,a0,942 # ffffffffc0206f88 <etext+0x1748>
}
ffffffffc0203be2:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203be4:	db0fc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203be8:	00003697          	auipc	a3,0x3
ffffffffc0203bec:	23068693          	addi	a3,a3,560 # ffffffffc0206e18 <etext+0x15d8>
ffffffffc0203bf0:	00002617          	auipc	a2,0x2
ffffffffc0203bf4:	63060613          	addi	a2,a2,1584 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203bf8:	12c00593          	li	a1,300
ffffffffc0203bfc:	00003517          	auipc	a0,0x3
ffffffffc0203c00:	14450513          	addi	a0,a0,324 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203c04:	843fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203c08:	00003697          	auipc	a3,0x3
ffffffffc0203c0c:	1c068693          	addi	a3,a3,448 # ffffffffc0206dc8 <etext+0x1588>
ffffffffc0203c10:	00002617          	auipc	a2,0x2
ffffffffc0203c14:	61060613          	addi	a2,a2,1552 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203c18:	12400593          	li	a1,292
ffffffffc0203c1c:	00003517          	auipc	a0,0x3
ffffffffc0203c20:	12450513          	addi	a0,a0,292 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203c24:	823fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203c28:	00003697          	auipc	a3,0x3
ffffffffc0203c2c:	1f068693          	addi	a3,a3,496 # ffffffffc0206e18 <etext+0x15d8>
ffffffffc0203c30:	00002617          	auipc	a2,0x2
ffffffffc0203c34:	5f060613          	addi	a2,a2,1520 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203c38:	13300593          	li	a1,307
ffffffffc0203c3c:	00003517          	auipc	a0,0x3
ffffffffc0203c40:	10450513          	addi	a0,a0,260 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203c44:	803fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c48:	00003697          	auipc	a3,0x3
ffffffffc0203c4c:	1f868693          	addi	a3,a3,504 # ffffffffc0206e40 <etext+0x1600>
ffffffffc0203c50:	00002617          	auipc	a2,0x2
ffffffffc0203c54:	5d060613          	addi	a2,a2,1488 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203c58:	13d00593          	li	a1,317
ffffffffc0203c5c:	00003517          	auipc	a0,0x3
ffffffffc0203c60:	0e450513          	addi	a0,a0,228 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203c64:	fe2fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c68:	00003697          	auipc	a3,0x3
ffffffffc0203c6c:	29068693          	addi	a3,a3,656 # ffffffffc0206ef8 <etext+0x16b8>
ffffffffc0203c70:	00002617          	auipc	a2,0x2
ffffffffc0203c74:	5b060613          	addi	a2,a2,1456 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203c78:	14f00593          	li	a1,335
ffffffffc0203c7c:	00003517          	auipc	a0,0x3
ffffffffc0203c80:	0c450513          	addi	a0,a0,196 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203c84:	fc2fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c88:	00003697          	auipc	a3,0x3
ffffffffc0203c8c:	24068693          	addi	a3,a3,576 # ffffffffc0206ec8 <etext+0x1688>
ffffffffc0203c90:	00002617          	auipc	a2,0x2
ffffffffc0203c94:	59060613          	addi	a2,a2,1424 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203c98:	14e00593          	li	a1,334
ffffffffc0203c9c:	00003517          	auipc	a0,0x3
ffffffffc0203ca0:	0a450513          	addi	a0,a0,164 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203ca4:	fa2fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203ca8:	00003697          	auipc	a3,0x3
ffffffffc0203cac:	21068693          	addi	a3,a3,528 # ffffffffc0206eb8 <etext+0x1678>
ffffffffc0203cb0:	00002617          	auipc	a2,0x2
ffffffffc0203cb4:	57060613          	addi	a2,a2,1392 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203cb8:	14c00593          	li	a1,332
ffffffffc0203cbc:	00003517          	auipc	a0,0x3
ffffffffc0203cc0:	08450513          	addi	a0,a0,132 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203cc4:	f82fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203cc8:	00003697          	auipc	a3,0x3
ffffffffc0203ccc:	1e068693          	addi	a3,a3,480 # ffffffffc0206ea8 <etext+0x1668>
ffffffffc0203cd0:	00002617          	auipc	a2,0x2
ffffffffc0203cd4:	55060613          	addi	a2,a2,1360 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203cd8:	14a00593          	li	a1,330
ffffffffc0203cdc:	00003517          	auipc	a0,0x3
ffffffffc0203ce0:	06450513          	addi	a0,a0,100 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203ce4:	f62fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203ce8:	00003697          	auipc	a3,0x3
ffffffffc0203cec:	1b068693          	addi	a3,a3,432 # ffffffffc0206e98 <etext+0x1658>
ffffffffc0203cf0:	00002617          	auipc	a2,0x2
ffffffffc0203cf4:	53060613          	addi	a2,a2,1328 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203cf8:	14800593          	li	a1,328
ffffffffc0203cfc:	00003517          	auipc	a0,0x3
ffffffffc0203d00:	04450513          	addi	a0,a0,68 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203d04:	f42fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d08:	00003697          	auipc	a3,0x3
ffffffffc0203d0c:	12068693          	addi	a3,a3,288 # ffffffffc0206e28 <etext+0x15e8>
ffffffffc0203d10:	00002617          	auipc	a2,0x2
ffffffffc0203d14:	51060613          	addi	a2,a2,1296 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203d18:	13b00593          	li	a1,315
ffffffffc0203d1c:	00003517          	auipc	a0,0x3
ffffffffc0203d20:	02450513          	addi	a0,a0,36 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203d24:	f22fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203d28:	00003697          	auipc	a3,0x3
ffffffffc0203d2c:	16068693          	addi	a3,a3,352 # ffffffffc0206e88 <etext+0x1648>
ffffffffc0203d30:	00002617          	auipc	a2,0x2
ffffffffc0203d34:	4f060613          	addi	a2,a2,1264 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203d38:	14600593          	li	a1,326
ffffffffc0203d3c:	00003517          	auipc	a0,0x3
ffffffffc0203d40:	00450513          	addi	a0,a0,4 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203d44:	f02fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203d48:	00003697          	auipc	a3,0x3
ffffffffc0203d4c:	13068693          	addi	a3,a3,304 # ffffffffc0206e78 <etext+0x1638>
ffffffffc0203d50:	00002617          	auipc	a2,0x2
ffffffffc0203d54:	4d060613          	addi	a2,a2,1232 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203d58:	14400593          	li	a1,324
ffffffffc0203d5c:	00003517          	auipc	a0,0x3
ffffffffc0203d60:	fe450513          	addi	a0,a0,-28 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203d64:	ee2fc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d68:	6914                	ld	a3,16(a0)
ffffffffc0203d6a:	6510                	ld	a2,8(a0)
ffffffffc0203d6c:	0004859b          	sext.w	a1,s1
ffffffffc0203d70:	00003517          	auipc	a0,0x3
ffffffffc0203d74:	1b850513          	addi	a0,a0,440 # ffffffffc0206f28 <etext+0x16e8>
ffffffffc0203d78:	c1cfc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203d7c:	00003697          	auipc	a3,0x3
ffffffffc0203d80:	1d468693          	addi	a3,a3,468 # ffffffffc0206f50 <etext+0x1710>
ffffffffc0203d84:	00002617          	auipc	a2,0x2
ffffffffc0203d88:	49c60613          	addi	a2,a2,1180 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0203d8c:	15900593          	li	a1,345
ffffffffc0203d90:	00003517          	auipc	a0,0x3
ffffffffc0203d94:	fb050513          	addi	a0,a0,-80 # ffffffffc0206d40 <etext+0x1500>
ffffffffc0203d98:	eaefc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203d9c <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d9c:	7179                	addi	sp,sp,-48
ffffffffc0203d9e:	f022                	sd	s0,32(sp)
ffffffffc0203da0:	f406                	sd	ra,40(sp)
ffffffffc0203da2:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203da4:	c52d                	beqz	a0,ffffffffc0203e0e <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203da6:	002007b7          	lui	a5,0x200
ffffffffc0203daa:	04f5ed63          	bltu	a1,a5,ffffffffc0203e04 <user_mem_check+0x68>
ffffffffc0203dae:	ec26                	sd	s1,24(sp)
ffffffffc0203db0:	00c584b3          	add	s1,a1,a2
ffffffffc0203db4:	0695ff63          	bgeu	a1,s1,ffffffffc0203e32 <user_mem_check+0x96>
ffffffffc0203db8:	4785                	li	a5,1
ffffffffc0203dba:	07fe                	slli	a5,a5,0x1f
ffffffffc0203dbc:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e29>
ffffffffc0203dbe:	06f4fa63          	bgeu	s1,a5,ffffffffc0203e32 <user_mem_check+0x96>
ffffffffc0203dc2:	e84a                	sd	s2,16(sp)
ffffffffc0203dc4:	e44e                	sd	s3,8(sp)
ffffffffc0203dc6:	8936                	mv	s2,a3
ffffffffc0203dc8:	89aa                	mv	s3,a0
ffffffffc0203dca:	a829                	j	ffffffffc0203de4 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dcc:	6685                	lui	a3,0x1
ffffffffc0203dce:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dd0:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dd4:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dd6:	c685                	beqz	a3,ffffffffc0203dfe <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dd8:	c399                	beqz	a5,ffffffffc0203dde <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dda:	02e46263          	bltu	s0,a4,ffffffffc0203dfe <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203dde:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203de0:	04947b63          	bgeu	s0,s1,ffffffffc0203e36 <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203de4:	85a2                	mv	a1,s0
ffffffffc0203de6:	854e                	mv	a0,s3
ffffffffc0203de8:	959ff0ef          	jal	ffffffffc0203740 <find_vma>
ffffffffc0203dec:	c909                	beqz	a0,ffffffffc0203dfe <user_mem_check+0x62>
ffffffffc0203dee:	6518                	ld	a4,8(a0)
ffffffffc0203df0:	00e46763          	bltu	s0,a4,ffffffffc0203dfe <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203df4:	4d1c                	lw	a5,24(a0)
ffffffffc0203df6:	fc091be3          	bnez	s2,ffffffffc0203dcc <user_mem_check+0x30>
ffffffffc0203dfa:	8b85                	andi	a5,a5,1
ffffffffc0203dfc:	f3ed                	bnez	a5,ffffffffc0203dde <user_mem_check+0x42>
ffffffffc0203dfe:	64e2                	ld	s1,24(sp)
ffffffffc0203e00:	6942                	ld	s2,16(sp)
ffffffffc0203e02:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203e04:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e06:	70a2                	ld	ra,40(sp)
ffffffffc0203e08:	7402                	ld	s0,32(sp)
ffffffffc0203e0a:	6145                	addi	sp,sp,48
ffffffffc0203e0c:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e0e:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e12:	fef5eae3          	bltu	a1,a5,ffffffffc0203e06 <user_mem_check+0x6a>
ffffffffc0203e16:	c80007b7          	lui	a5,0xc8000
ffffffffc0203e1a:	962e                	add	a2,a2,a1
ffffffffc0203e1c:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d64879>
ffffffffc0203e1e:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203e22:	00f63633          	sltu	a2,a2,a5
ffffffffc0203e26:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e28:	00867533          	and	a0,a2,s0
ffffffffc0203e2c:	7402                	ld	s0,32(sp)
ffffffffc0203e2e:	6145                	addi	sp,sp,48
ffffffffc0203e30:	8082                	ret
ffffffffc0203e32:	64e2                	ld	s1,24(sp)
ffffffffc0203e34:	bfc1                	j	ffffffffc0203e04 <user_mem_check+0x68>
ffffffffc0203e36:	64e2                	ld	s1,24(sp)
ffffffffc0203e38:	6942                	ld	s2,16(sp)
ffffffffc0203e3a:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e3c:	4505                	li	a0,1
ffffffffc0203e3e:	b7e1                	j	ffffffffc0203e06 <user_mem_check+0x6a>

ffffffffc0203e40 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e40:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e42:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e44:	670000ef          	jal	ffffffffc02044b4 <do_exit>

ffffffffc0203e48 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e48:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e4a:	10800513          	li	a0,264
{
ffffffffc0203e4e:	e022                	sd	s0,0(sp)
ffffffffc0203e50:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e52:	e9bfd0ef          	jal	ffffffffc0201cec <kmalloc>
ffffffffc0203e56:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e58:	cd21                	beqz	a0,ffffffffc0203eb0 <alloc_proc+0x68>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->state = PROC_UNINIT;                     // 设置进程为未初始化状态
ffffffffc0203e5a:	57fd                	li	a5,-1
ffffffffc0203e5c:	1782                	slli	a5,a5,0x20
ffffffffc0203e5e:	e11c                	sd	a5,0(a0)
        proc->pid = -1;                                // 未分配PID
        proc->runs = 0;                                // 运行次数初始化为0
ffffffffc0203e60:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                              // 内核栈地址初始化为0
ffffffffc0203e64:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                        // 不需要调度
ffffffffc0203e68:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                           // 父进程为空
ffffffffc0203e6c:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                               // 内存管理结构为空
ffffffffc0203e70:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0203e74:	07000613          	li	a2,112
ffffffffc0203e78:	4581                	li	a1,0
ffffffffc0203e7a:	03050513          	addi	a0,a0,48
ffffffffc0203e7e:	199010ef          	jal	ffffffffc0205816 <memset>
        proc->tf = NULL;                               // 中断帧指针为空
        proc->pgdir = boot_pgdir_pa;                   // 页目录为内核页目录的物理地址
ffffffffc0203e82:	00098797          	auipc	a5,0x98
ffffffffc0203e86:	8be7b783          	ld	a5,-1858(a5) # ffffffffc029b740 <boot_pgdir_pa>
        proc->tf = NULL;                               // 中断帧指针为空
ffffffffc0203e8a:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                               // 标志位为0
ffffffffc0203e8e:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;                   // 页目录为内核页目录的物理地址
ffffffffc0203e92:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);      // 进程名初始化为0
ffffffffc0203e94:	0b440513          	addi	a0,s0,180
ffffffffc0203e98:	4641                	li	a2,16
ffffffffc0203e9a:	4581                	li	a1,0
ffffffffc0203e9c:	17b010ef          	jal	ffffffffc0205816 <memset>
        proc->wait_state = 0;                          // 初始化等待状态
ffffffffc0203ea0:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->optr = proc->yptr = NULL;   // 初始化进程关系指针
ffffffffc0203ea4:	0e043c23          	sd	zero,248(s0)
ffffffffc0203ea8:	10043023          	sd	zero,256(s0)
ffffffffc0203eac:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0203eb0:	60a2                	ld	ra,8(sp)
ffffffffc0203eb2:	8522                	mv	a0,s0
ffffffffc0203eb4:	6402                	ld	s0,0(sp)
ffffffffc0203eb6:	0141                	addi	sp,sp,16
ffffffffc0203eb8:	8082                	ret

ffffffffc0203eba <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203eba:	00098797          	auipc	a5,0x98
ffffffffc0203ebe:	8b67b783          	ld	a5,-1866(a5) # ffffffffc029b770 <current>
ffffffffc0203ec2:	73c8                	ld	a0,160(a5)
ffffffffc0203ec4:	80efd06f          	j	ffffffffc0200ed2 <forkrets>

ffffffffc0203ec8 <user_main>:
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(exit);
ffffffffc0203ec8:	00098797          	auipc	a5,0x98
ffffffffc0203ecc:	8a87b783          	ld	a5,-1880(a5) # ffffffffc029b770 <current>
{
ffffffffc0203ed0:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(exit);
ffffffffc0203ed2:	00003617          	auipc	a2,0x3
ffffffffc0203ed6:	0ce60613          	addi	a2,a2,206 # ffffffffc0206fa0 <etext+0x1760>
ffffffffc0203eda:	43cc                	lw	a1,4(a5)
ffffffffc0203edc:	00003517          	auipc	a0,0x3
ffffffffc0203ee0:	0cc50513          	addi	a0,a0,204 # ffffffffc0206fa8 <etext+0x1768>
{
ffffffffc0203ee4:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(exit);
ffffffffc0203ee6:	aaefc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203eea:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203eee:	2ee78793          	addi	a5,a5,750 # a1d8 <_binary_obj___user_exit_out_size>
ffffffffc0203ef2:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203ef4:	00003517          	auipc	a0,0x3
ffffffffc0203ef8:	0ac50513          	addi	a0,a0,172 # ffffffffc0206fa0 <etext+0x1760>
ffffffffc0203efc:	00023797          	auipc	a5,0x23
ffffffffc0203f00:	52478793          	addi	a5,a5,1316 # ffffffffc0227420 <_binary_obj___user_exit_out_start>
ffffffffc0203f04:	f03e                	sd	a5,32(sp)
ffffffffc0203f06:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203f08:	e802                	sd	zero,16(sp)
ffffffffc0203f0a:	059010ef          	jal	ffffffffc0205762 <strlen>
ffffffffc0203f0e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203f10:	4511                	li	a0,4
ffffffffc0203f12:	55a2                	lw	a1,40(sp)
ffffffffc0203f14:	4662                	lw	a2,24(sp)
ffffffffc0203f16:	5682                	lw	a3,32(sp)
ffffffffc0203f18:	4722                	lw	a4,8(sp)
ffffffffc0203f1a:	48a9                	li	a7,10
ffffffffc0203f1c:	9002                	ebreak
ffffffffc0203f1e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f20:	65c2                	ld	a1,16(sp)
ffffffffc0203f22:	00003517          	auipc	a0,0x3
ffffffffc0203f26:	0ae50513          	addi	a0,a0,174 # ffffffffc0206fd0 <etext+0x1790>
ffffffffc0203f2a:	a6afc0ef          	jal	ffffffffc0200194 <cprintf>
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f2e:	00003617          	auipc	a2,0x3
ffffffffc0203f32:	0b260613          	addi	a2,a2,178 # ffffffffc0206fe0 <etext+0x17a0>
ffffffffc0203f36:	3c300593          	li	a1,963
ffffffffc0203f3a:	00003517          	auipc	a0,0x3
ffffffffc0203f3e:	0c650513          	addi	a0,a0,198 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0203f42:	d04fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f46 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f46:	6d14                	ld	a3,24(a0)
{
ffffffffc0203f48:	1141                	addi	sp,sp,-16
ffffffffc0203f4a:	e406                	sd	ra,8(sp)
ffffffffc0203f4c:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f50:	02f6ee63          	bltu	a3,a5,ffffffffc0203f8c <put_pgdir+0x46>
ffffffffc0203f54:	00097717          	auipc	a4,0x97
ffffffffc0203f58:	7fc73703          	ld	a4,2044(a4) # ffffffffc029b750 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f5c:	00097797          	auipc	a5,0x97
ffffffffc0203f60:	7fc7b783          	ld	a5,2044(a5) # ffffffffc029b758 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f64:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f66:	82b1                	srli	a3,a3,0xc
ffffffffc0203f68:	02f6fe63          	bgeu	a3,a5,ffffffffc0203fa4 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f6c:	00004797          	auipc	a5,0x4
ffffffffc0203f70:	a3c7b783          	ld	a5,-1476(a5) # ffffffffc02079a8 <nbase>
ffffffffc0203f74:	00097517          	auipc	a0,0x97
ffffffffc0203f78:	7ec53503          	ld	a0,2028(a0) # ffffffffc029b760 <pages>
}
ffffffffc0203f7c:	60a2                	ld	ra,8(sp)
ffffffffc0203f7e:	8e9d                	sub	a3,a3,a5
ffffffffc0203f80:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f82:	4585                	li	a1,1
ffffffffc0203f84:	9536                	add	a0,a0,a3
}
ffffffffc0203f86:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f88:	f61fd06f          	j	ffffffffc0201ee8 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f8c:	00002617          	auipc	a2,0x2
ffffffffc0203f90:	6ec60613          	addi	a2,a2,1772 # ffffffffc0206678 <etext+0xe38>
ffffffffc0203f94:	07700593          	li	a1,119
ffffffffc0203f98:	00002517          	auipc	a0,0x2
ffffffffc0203f9c:	66050513          	addi	a0,a0,1632 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0203fa0:	ca6fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203fa4:	00002617          	auipc	a2,0x2
ffffffffc0203fa8:	6fc60613          	addi	a2,a2,1788 # ffffffffc02066a0 <etext+0xe60>
ffffffffc0203fac:	06900593          	li	a1,105
ffffffffc0203fb0:	00002517          	auipc	a0,0x2
ffffffffc0203fb4:	64850513          	addi	a0,a0,1608 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0203fb8:	c8efc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203fbc <proc_run>:
    if (proc != current)
ffffffffc0203fbc:	00097697          	auipc	a3,0x97
ffffffffc0203fc0:	7b46b683          	ld	a3,1972(a3) # ffffffffc029b770 <current>
ffffffffc0203fc4:	04a68463          	beq	a3,a0,ffffffffc020400c <proc_run+0x50>
{
ffffffffc0203fc8:	1101                	addi	sp,sp,-32
ffffffffc0203fca:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fcc:	100027f3          	csrr	a5,sstatus
ffffffffc0203fd0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203fd2:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fd4:	ef8d                	bnez	a5,ffffffffc020400e <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fd6:	755c                	ld	a5,168(a0)
ffffffffc0203fd8:	577d                	li	a4,-1
ffffffffc0203fda:	177e                	slli	a4,a4,0x3f
ffffffffc0203fdc:	83b1                	srli	a5,a5,0xc
ffffffffc0203fde:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0203fe0:	00097597          	auipc	a1,0x97
ffffffffc0203fe4:	78a5b823          	sd	a0,1936(a1) # ffffffffc029b770 <current>
ffffffffc0203fe8:	8fd9                	or	a5,a5,a4
ffffffffc0203fea:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203fee:	03050593          	addi	a1,a0,48
ffffffffc0203ff2:	03068513          	addi	a0,a3,48
ffffffffc0203ff6:	124010ef          	jal	ffffffffc020511a <switch_to>
    if (flag)
ffffffffc0203ffa:	6602                	ld	a2,0(sp)
ffffffffc0203ffc:	e601                	bnez	a2,ffffffffc0204004 <proc_run+0x48>
}
ffffffffc0203ffe:	60e2                	ld	ra,24(sp)
ffffffffc0204000:	6105                	addi	sp,sp,32
ffffffffc0204002:	8082                	ret
ffffffffc0204004:	60e2                	ld	ra,24(sp)
ffffffffc0204006:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204008:	8f7fc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc020400c:	8082                	ret
ffffffffc020400e:	e42a                	sd	a0,8(sp)
ffffffffc0204010:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0204012:	8f3fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204016:	6522                	ld	a0,8(sp)
ffffffffc0204018:	6682                	ld	a3,0(sp)
ffffffffc020401a:	4605                	li	a2,1
ffffffffc020401c:	bf6d                	j	ffffffffc0203fd6 <proc_run+0x1a>

ffffffffc020401e <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc020401e:	00097717          	auipc	a4,0x97
ffffffffc0204022:	74a72703          	lw	a4,1866(a4) # ffffffffc029b768 <nr_process>
ffffffffc0204026:	6785                	lui	a5,0x1
ffffffffc0204028:	36f75d63          	bge	a4,a5,ffffffffc02043a2 <do_fork+0x384>
{
ffffffffc020402c:	711d                	addi	sp,sp,-96
ffffffffc020402e:	e8a2                	sd	s0,80(sp)
ffffffffc0204030:	e4a6                	sd	s1,72(sp)
ffffffffc0204032:	e0ca                	sd	s2,64(sp)
ffffffffc0204034:	e06a                	sd	s10,0(sp)
ffffffffc0204036:	ec86                	sd	ra,88(sp)
ffffffffc0204038:	892e                	mv	s2,a1
ffffffffc020403a:	84b2                	mv	s1,a2
ffffffffc020403c:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020403e:	e0bff0ef          	jal	ffffffffc0203e48 <alloc_proc>
ffffffffc0204042:	842a                	mv	s0,a0
ffffffffc0204044:	30050063          	beqz	a0,ffffffffc0204344 <do_fork+0x326>
    proc->parent = current;
ffffffffc0204048:	f05a                	sd	s6,32(sp)
ffffffffc020404a:	00097b17          	auipc	s6,0x97
ffffffffc020404e:	726b0b13          	addi	s6,s6,1830 # ffffffffc029b770 <current>
ffffffffc0204052:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0);
ffffffffc0204056:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7ae4>
    proc->parent = current;
ffffffffc020405a:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc020405c:	3c071263          	bnez	a4,ffffffffc0204420 <do_fork+0x402>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204060:	4509                	li	a0,2
ffffffffc0204062:	e4dfd0ef          	jal	ffffffffc0201eae <alloc_pages>
    if (page != NULL)
ffffffffc0204066:	2c050b63          	beqz	a0,ffffffffc020433c <do_fork+0x31e>
ffffffffc020406a:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc020406c:	00097997          	auipc	s3,0x97
ffffffffc0204070:	6f498993          	addi	s3,s3,1780 # ffffffffc029b760 <pages>
ffffffffc0204074:	0009b783          	ld	a5,0(s3)
ffffffffc0204078:	f852                	sd	s4,48(sp)
ffffffffc020407a:	00004a17          	auipc	s4,0x4
ffffffffc020407e:	92ea0a13          	addi	s4,s4,-1746 # ffffffffc02079a8 <nbase>
ffffffffc0204082:	e466                	sd	s9,8(sp)
ffffffffc0204084:	000a3c83          	ld	s9,0(s4)
ffffffffc0204088:	40f506b3          	sub	a3,a0,a5
ffffffffc020408c:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc020408e:	00097a97          	auipc	s5,0x97
ffffffffc0204092:	6caa8a93          	addi	s5,s5,1738 # ffffffffc029b758 <npage>
ffffffffc0204096:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc0204098:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020409a:	5c7d                	li	s8,-1
ffffffffc020409c:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc02040a0:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc02040a2:	00cc5c13          	srli	s8,s8,0xc
ffffffffc02040a6:	0186f733          	and	a4,a3,s8
ffffffffc02040aa:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc02040ac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040ae:	30f77863          	bgeu	a4,a5,ffffffffc02043be <do_fork+0x3a0>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02040b2:	000b3703          	ld	a4,0(s6)
ffffffffc02040b6:	00097b17          	auipc	s6,0x97
ffffffffc02040ba:	69ab0b13          	addi	s6,s6,1690 # ffffffffc029b750 <va_pa_offset>
ffffffffc02040be:	000b3783          	ld	a5,0(s6)
ffffffffc02040c2:	02873b83          	ld	s7,40(a4)
ffffffffc02040c6:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040c8:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc02040ca:	020b8863          	beqz	s7,ffffffffc02040fa <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc02040ce:	100d7793          	andi	a5,s10,256
ffffffffc02040d2:	18078b63          	beqz	a5,ffffffffc0204268 <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040d6:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040da:	018bb783          	ld	a5,24(s7)
ffffffffc02040de:	c02006b7          	lui	a3,0xc0200
ffffffffc02040e2:	2705                	addiw	a4,a4,1
ffffffffc02040e4:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc02040e8:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040ec:	2ed7e563          	bltu	a5,a3,ffffffffc02043d6 <do_fork+0x3b8>
ffffffffc02040f0:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040f4:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040f6:	8f99                	sub	a5,a5,a4
ffffffffc02040f8:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040fa:	6789                	lui	a5,0x2
ffffffffc02040fc:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6cf0>
ffffffffc0204100:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204102:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204104:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0204106:	87b6                	mv	a5,a3
ffffffffc0204108:	12048713          	addi	a4,s1,288
ffffffffc020410c:	6a0c                	ld	a1,16(a2)
ffffffffc020410e:	00063803          	ld	a6,0(a2)
ffffffffc0204112:	6608                	ld	a0,8(a2)
ffffffffc0204114:	eb8c                	sd	a1,16(a5)
ffffffffc0204116:	0107b023          	sd	a6,0(a5)
ffffffffc020411a:	e788                	sd	a0,8(a5)
ffffffffc020411c:	6e0c                	ld	a1,24(a2)
ffffffffc020411e:	02060613          	addi	a2,a2,32
ffffffffc0204122:	02078793          	addi	a5,a5,32
ffffffffc0204126:	feb7bc23          	sd	a1,-8(a5)
ffffffffc020412a:	fee611e3          	bne	a2,a4,ffffffffc020410c <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020412e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204132:	20090b63          	beqz	s2,ffffffffc0204348 <do_fork+0x32a>
ffffffffc0204136:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020413a:	00000797          	auipc	a5,0x0
ffffffffc020413e:	d8078793          	addi	a5,a5,-640 # ffffffffc0203eba <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204142:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204144:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204146:	100027f3          	csrr	a5,sstatus
ffffffffc020414a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020414c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020414e:	20079c63          	bnez	a5,ffffffffc0204366 <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc0204152:	00093517          	auipc	a0,0x93
ffffffffc0204156:	18252503          	lw	a0,386(a0) # ffffffffc02972d4 <last_pid.1>
ffffffffc020415a:	6789                	lui	a5,0x2
ffffffffc020415c:	2505                	addiw	a0,a0,1
ffffffffc020415e:	00093717          	auipc	a4,0x93
ffffffffc0204162:	16a72b23          	sw	a0,374(a4) # ffffffffc02972d4 <last_pid.1>
ffffffffc0204166:	20f55f63          	bge	a0,a5,ffffffffc0204384 <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc020416a:	00093797          	auipc	a5,0x93
ffffffffc020416e:	1667a783          	lw	a5,358(a5) # ffffffffc02972d0 <next_safe.0>
ffffffffc0204172:	00097497          	auipc	s1,0x97
ffffffffc0204176:	57e48493          	addi	s1,s1,1406 # ffffffffc029b6f0 <proc_list>
ffffffffc020417a:	06f54563          	blt	a0,a5,ffffffffc02041e4 <do_fork+0x1c6>
ffffffffc020417e:	00097497          	auipc	s1,0x97
ffffffffc0204182:	57248493          	addi	s1,s1,1394 # ffffffffc029b6f0 <proc_list>
ffffffffc0204186:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc020418a:	6789                	lui	a5,0x2
ffffffffc020418c:	00093717          	auipc	a4,0x93
ffffffffc0204190:	14f72223          	sw	a5,324(a4) # ffffffffc02972d0 <next_safe.0>
ffffffffc0204194:	86aa                	mv	a3,a0
ffffffffc0204196:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204198:	04988063          	beq	a7,s1,ffffffffc02041d8 <do_fork+0x1ba>
ffffffffc020419c:	882e                	mv	a6,a1
ffffffffc020419e:	87c6                	mv	a5,a7
ffffffffc02041a0:	6609                	lui	a2,0x2
ffffffffc02041a2:	a811                	j	ffffffffc02041b6 <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041a4:	00e6d663          	bge	a3,a4,ffffffffc02041b0 <do_fork+0x192>
ffffffffc02041a8:	00c75463          	bge	a4,a2,ffffffffc02041b0 <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc02041ac:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041ae:	4805                	li	a6,1
ffffffffc02041b0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041b2:	00978d63          	beq	a5,s1,ffffffffc02041cc <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc02041b6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6c94>
ffffffffc02041ba:	fed715e3          	bne	a4,a3,ffffffffc02041a4 <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc02041be:	2685                	addiw	a3,a3,1
ffffffffc02041c0:	1cc6db63          	bge	a3,a2,ffffffffc0204396 <do_fork+0x378>
ffffffffc02041c4:	679c                	ld	a5,8(a5)
ffffffffc02041c6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041c8:	fe9797e3          	bne	a5,s1,ffffffffc02041b6 <do_fork+0x198>
ffffffffc02041cc:	00080663          	beqz	a6,ffffffffc02041d8 <do_fork+0x1ba>
ffffffffc02041d0:	00093797          	auipc	a5,0x93
ffffffffc02041d4:	10c7a023          	sw	a2,256(a5) # ffffffffc02972d0 <next_safe.0>
ffffffffc02041d8:	c591                	beqz	a1,ffffffffc02041e4 <do_fork+0x1c6>
ffffffffc02041da:	00093797          	auipc	a5,0x93
ffffffffc02041de:	0ed7ad23          	sw	a3,250(a5) # ffffffffc02972d4 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041e2:	8536                	mv	a0,a3
        proc->pid = get_pid();     // 分配PID
ffffffffc02041e4:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041e6:	45a9                	li	a1,10
ffffffffc02041e8:	198010ef          	jal	ffffffffc0205380 <hash32>
ffffffffc02041ec:	02051793          	slli	a5,a0,0x20
ffffffffc02041f0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041f4:	00093797          	auipc	a5,0x93
ffffffffc02041f8:	4fc78793          	addi	a5,a5,1276 # ffffffffc02976f0 <hash_list>
ffffffffc02041fc:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041fe:	6518                	ld	a4,8(a0)
ffffffffc0204200:	0d840793          	addi	a5,s0,216
ffffffffc0204204:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0204206:	e31c                	sd	a5,0(a4)
ffffffffc0204208:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc020420a:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020420c:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204210:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204212:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204214:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc0204216:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020421a:	7b74                	ld	a3,240(a4)
ffffffffc020421c:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc020421e:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204220:	e464                	sd	s1,200(s0)
ffffffffc0204222:	10d43023          	sd	a3,256(s0)
ffffffffc0204226:	c299                	beqz	a3,ffffffffc020422c <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc0204228:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc020422a:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc020422c:	00097797          	auipc	a5,0x97
ffffffffc0204230:	53c7a783          	lw	a5,1340(a5) # ffffffffc029b768 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204234:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204236:	2785                	addiw	a5,a5,1
ffffffffc0204238:	00097717          	auipc	a4,0x97
ffffffffc020423c:	52f72823          	sw	a5,1328(a4) # ffffffffc029b768 <nr_process>
    if (flag)
ffffffffc0204240:	14091863          	bnez	s2,ffffffffc0204390 <do_fork+0x372>
    wakeup_proc(proc);
ffffffffc0204244:	8522                	mv	a0,s0
ffffffffc0204246:	73f000ef          	jal	ffffffffc0205184 <wakeup_proc>
    ret = proc->pid;
ffffffffc020424a:	4048                	lw	a0,4(s0)
ffffffffc020424c:	79e2                	ld	s3,56(sp)
ffffffffc020424e:	7a42                	ld	s4,48(sp)
ffffffffc0204250:	7aa2                	ld	s5,40(sp)
ffffffffc0204252:	7b02                	ld	s6,32(sp)
ffffffffc0204254:	6be2                	ld	s7,24(sp)
ffffffffc0204256:	6c42                	ld	s8,16(sp)
ffffffffc0204258:	6ca2                	ld	s9,8(sp)
}
ffffffffc020425a:	60e6                	ld	ra,88(sp)
ffffffffc020425c:	6446                	ld	s0,80(sp)
ffffffffc020425e:	64a6                	ld	s1,72(sp)
ffffffffc0204260:	6906                	ld	s2,64(sp)
ffffffffc0204262:	6d02                	ld	s10,0(sp)
ffffffffc0204264:	6125                	addi	sp,sp,96
ffffffffc0204266:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204268:	ca8ff0ef          	jal	ffffffffc0203710 <mm_create>
ffffffffc020426c:	8d2a                	mv	s10,a0
ffffffffc020426e:	c949                	beqz	a0,ffffffffc0204300 <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc0204270:	4505                	li	a0,1
ffffffffc0204272:	c3dfd0ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0204276:	c151                	beqz	a0,ffffffffc02042fa <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc0204278:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc020427c:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc0204280:	40e506b3          	sub	a3,a0,a4
ffffffffc0204284:	8699                	srai	a3,a3,0x6
ffffffffc0204286:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0204288:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc020428c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020428e:	1afc7f63          	bgeu	s8,a5,ffffffffc020444c <do_fork+0x42e>
ffffffffc0204292:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204296:	00097597          	auipc	a1,0x97
ffffffffc020429a:	4b25b583          	ld	a1,1202(a1) # ffffffffc029b748 <boot_pgdir_va>
ffffffffc020429e:	6605                	lui	a2,0x1
ffffffffc02042a0:	00f68c33          	add	s8,a3,a5
ffffffffc02042a4:	8562                	mv	a0,s8
ffffffffc02042a6:	582010ef          	jal	ffffffffc0205828 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02042aa:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc02042ae:	018d3c23          	sd	s8,24(s10) # fffffffffff80018 <end+0x3fce4890>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02042b2:	4c05                	li	s8,1
ffffffffc02042b4:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02042b8:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042bc:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042c0:	cb91                	beqz	a5,ffffffffc02042d4 <do_fork+0x2b6>
    {
        schedule();
ffffffffc02042c2:	757000ef          	jal	ffffffffc0205218 <schedule>
ffffffffc02042c6:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc02042ca:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042ce:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042d2:	fbe5                	bnez	a5,ffffffffc02042c2 <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042d4:	85de                	mv	a1,s7
ffffffffc02042d6:	856a                	mv	a0,s10
ffffffffc02042d8:	e94ff0ef          	jal	ffffffffc020396c <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042dc:	57f9                	li	a5,-2
ffffffffc02042de:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc02042e2:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042e4:	12078263          	beqz	a5,ffffffffc0204408 <do_fork+0x3ea>
    if ((mm = mm_create()) == NULL)
ffffffffc02042e8:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc02042ea:	de0506e3          	beqz	a0,ffffffffc02040d6 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc02042ee:	856a                	mv	a0,s10
ffffffffc02042f0:	f14ff0ef          	jal	ffffffffc0203a04 <exit_mmap>
    put_pgdir(mm);
ffffffffc02042f4:	856a                	mv	a0,s10
ffffffffc02042f6:	c51ff0ef          	jal	ffffffffc0203f46 <put_pgdir>
    mm_destroy(mm);
ffffffffc02042fa:	856a                	mv	a0,s10
ffffffffc02042fc:	d52ff0ef          	jal	ffffffffc020384e <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204300:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204302:	c02007b7          	lui	a5,0xc0200
ffffffffc0204306:	0ef6e563          	bltu	a3,a5,ffffffffc02043f0 <do_fork+0x3d2>
ffffffffc020430a:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc020430e:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc0204312:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204316:	83b1                	srli	a5,a5,0xc
ffffffffc0204318:	08e7f763          	bgeu	a5,a4,ffffffffc02043a6 <do_fork+0x388>
    return &pages[PPN(pa) - nbase];
ffffffffc020431c:	000a3703          	ld	a4,0(s4)
ffffffffc0204320:	0009b503          	ld	a0,0(s3)
ffffffffc0204324:	4589                	li	a1,2
ffffffffc0204326:	8f99                	sub	a5,a5,a4
ffffffffc0204328:	079a                	slli	a5,a5,0x6
ffffffffc020432a:	953e                	add	a0,a0,a5
ffffffffc020432c:	bbdfd0ef          	jal	ffffffffc0201ee8 <free_pages>
}
ffffffffc0204330:	79e2                	ld	s3,56(sp)
ffffffffc0204332:	7a42                	ld	s4,48(sp)
ffffffffc0204334:	7aa2                	ld	s5,40(sp)
ffffffffc0204336:	6be2                	ld	s7,24(sp)
ffffffffc0204338:	6c42                	ld	s8,16(sp)
ffffffffc020433a:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc020433c:	8522                	mv	a0,s0
ffffffffc020433e:	a55fd0ef          	jal	ffffffffc0201d92 <kfree>
ffffffffc0204342:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc0204344:	5571                	li	a0,-4
    return ret;
ffffffffc0204346:	bf11                	j	ffffffffc020425a <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204348:	8936                	mv	s2,a3
ffffffffc020434a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020434e:	00000797          	auipc	a5,0x0
ffffffffc0204352:	b6c78793          	addi	a5,a5,-1172 # ffffffffc0203eba <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204356:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204358:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020435a:	100027f3          	csrr	a5,sstatus
ffffffffc020435e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204360:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204362:	de0788e3          	beqz	a5,ffffffffc0204152 <do_fork+0x134>
        intr_disable();
ffffffffc0204366:	d9efc0ef          	jal	ffffffffc0200904 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc020436a:	00093517          	auipc	a0,0x93
ffffffffc020436e:	f6a52503          	lw	a0,-150(a0) # ffffffffc02972d4 <last_pid.1>
ffffffffc0204372:	6789                	lui	a5,0x2
        return 1;
ffffffffc0204374:	4905                	li	s2,1
ffffffffc0204376:	2505                	addiw	a0,a0,1
ffffffffc0204378:	00093717          	auipc	a4,0x93
ffffffffc020437c:	f4a72e23          	sw	a0,-164(a4) # ffffffffc02972d4 <last_pid.1>
ffffffffc0204380:	def545e3          	blt	a0,a5,ffffffffc020416a <do_fork+0x14c>
        last_pid = 1;
ffffffffc0204384:	4505                	li	a0,1
ffffffffc0204386:	00093797          	auipc	a5,0x93
ffffffffc020438a:	f4a7a723          	sw	a0,-178(a5) # ffffffffc02972d4 <last_pid.1>
        goto inside;
ffffffffc020438e:	bbc5                	j	ffffffffc020417e <do_fork+0x160>
        intr_enable();
ffffffffc0204390:	d6efc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0204394:	bd45                	j	ffffffffc0204244 <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc0204396:	6789                	lui	a5,0x2
ffffffffc0204398:	00f6c363          	blt	a3,a5,ffffffffc020439e <do_fork+0x380>
                        last_pid = 1;
ffffffffc020439c:	4685                	li	a3,1
                    goto repeat;
ffffffffc020439e:	4585                	li	a1,1
ffffffffc02043a0:	bbe5                	j	ffffffffc0204198 <do_fork+0x17a>
    int ret = -E_NO_FREE_PROC;
ffffffffc02043a2:	556d                	li	a0,-5
}
ffffffffc02043a4:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02043a6:	00002617          	auipc	a2,0x2
ffffffffc02043aa:	2fa60613          	addi	a2,a2,762 # ffffffffc02066a0 <etext+0xe60>
ffffffffc02043ae:	06900593          	li	a1,105
ffffffffc02043b2:	00002517          	auipc	a0,0x2
ffffffffc02043b6:	24650513          	addi	a0,a0,582 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02043ba:	88cfc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02043be:	00002617          	auipc	a2,0x2
ffffffffc02043c2:	21260613          	addi	a2,a2,530 # ffffffffc02065d0 <etext+0xd90>
ffffffffc02043c6:	07100593          	li	a1,113
ffffffffc02043ca:	00002517          	auipc	a0,0x2
ffffffffc02043ce:	22e50513          	addi	a0,a0,558 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02043d2:	874fc0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02043d6:	86be                	mv	a3,a5
ffffffffc02043d8:	00002617          	auipc	a2,0x2
ffffffffc02043dc:	2a060613          	addi	a2,a2,672 # ffffffffc0206678 <etext+0xe38>
ffffffffc02043e0:	19100593          	li	a1,401
ffffffffc02043e4:	00003517          	auipc	a0,0x3
ffffffffc02043e8:	c1c50513          	addi	a0,a0,-996 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02043ec:	85afc0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02043f0:	00002617          	auipc	a2,0x2
ffffffffc02043f4:	28860613          	addi	a2,a2,648 # ffffffffc0206678 <etext+0xe38>
ffffffffc02043f8:	07700593          	li	a1,119
ffffffffc02043fc:	00002517          	auipc	a0,0x2
ffffffffc0204400:	1fc50513          	addi	a0,a0,508 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0204404:	842fc0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204408:	00003617          	auipc	a2,0x3
ffffffffc020440c:	c3060613          	addi	a2,a2,-976 # ffffffffc0207038 <etext+0x17f8>
ffffffffc0204410:	03f00593          	li	a1,63
ffffffffc0204414:	00003517          	auipc	a0,0x3
ffffffffc0204418:	c3450513          	addi	a0,a0,-972 # ffffffffc0207048 <etext+0x1808>
ffffffffc020441c:	82afc0ef          	jal	ffffffffc0200446 <__panic>
    assert(current->wait_state == 0);
ffffffffc0204420:	00003697          	auipc	a3,0x3
ffffffffc0204424:	bf868693          	addi	a3,a3,-1032 # ffffffffc0207018 <etext+0x17d8>
ffffffffc0204428:	00002617          	auipc	a2,0x2
ffffffffc020442c:	df860613          	addi	a2,a2,-520 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204430:	1db00593          	li	a1,475
ffffffffc0204434:	00003517          	auipc	a0,0x3
ffffffffc0204438:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0207000 <etext+0x17c0>
ffffffffc020443c:	fc4e                	sd	s3,56(sp)
ffffffffc020443e:	f852                	sd	s4,48(sp)
ffffffffc0204440:	f456                	sd	s5,40(sp)
ffffffffc0204442:	ec5e                	sd	s7,24(sp)
ffffffffc0204444:	e862                	sd	s8,16(sp)
ffffffffc0204446:	e466                	sd	s9,8(sp)
ffffffffc0204448:	ffffb0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020444c:	00002617          	auipc	a2,0x2
ffffffffc0204450:	18460613          	addi	a2,a2,388 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0204454:	07100593          	li	a1,113
ffffffffc0204458:	00002517          	auipc	a0,0x2
ffffffffc020445c:	1a050513          	addi	a0,a0,416 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0204460:	fe7fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204464 <kernel_thread>:
{
ffffffffc0204464:	7129                	addi	sp,sp,-320
ffffffffc0204466:	fa22                	sd	s0,304(sp)
ffffffffc0204468:	f626                	sd	s1,296(sp)
ffffffffc020446a:	f24a                	sd	s2,288(sp)
ffffffffc020446c:	842a                	mv	s0,a0
ffffffffc020446e:	84ae                	mv	s1,a1
ffffffffc0204470:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204472:	850a                	mv	a0,sp
ffffffffc0204474:	12000613          	li	a2,288
ffffffffc0204478:	4581                	li	a1,0
{
ffffffffc020447a:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020447c:	39a010ef          	jal	ffffffffc0205816 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204480:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204482:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204484:	100027f3          	csrr	a5,sstatus
ffffffffc0204488:	edd7f793          	andi	a5,a5,-291
ffffffffc020448c:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204490:	860a                	mv	a2,sp
ffffffffc0204492:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204496:	00000717          	auipc	a4,0x0
ffffffffc020449a:	9aa70713          	addi	a4,a4,-1622 # ffffffffc0203e40 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020449e:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02044a0:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02044a2:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044a4:	b7bff0ef          	jal	ffffffffc020401e <do_fork>
}
ffffffffc02044a8:	70f2                	ld	ra,312(sp)
ffffffffc02044aa:	7452                	ld	s0,304(sp)
ffffffffc02044ac:	74b2                	ld	s1,296(sp)
ffffffffc02044ae:	7912                	ld	s2,288(sp)
ffffffffc02044b0:	6131                	addi	sp,sp,320
ffffffffc02044b2:	8082                	ret

ffffffffc02044b4 <do_exit>:
{
ffffffffc02044b4:	7179                	addi	sp,sp,-48
ffffffffc02044b6:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02044b8:	00097417          	auipc	s0,0x97
ffffffffc02044bc:	2b840413          	addi	s0,s0,696 # ffffffffc029b770 <current>
ffffffffc02044c0:	601c                	ld	a5,0(s0)
ffffffffc02044c2:	00097717          	auipc	a4,0x97
ffffffffc02044c6:	2be73703          	ld	a4,702(a4) # ffffffffc029b780 <idleproc>
{
ffffffffc02044ca:	f406                	sd	ra,40(sp)
ffffffffc02044cc:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02044ce:	0ce78b63          	beq	a5,a4,ffffffffc02045a4 <do_exit+0xf0>
    if (current == initproc)
ffffffffc02044d2:	00097497          	auipc	s1,0x97
ffffffffc02044d6:	2a648493          	addi	s1,s1,678 # ffffffffc029b778 <initproc>
ffffffffc02044da:	6098                	ld	a4,0(s1)
ffffffffc02044dc:	e84a                	sd	s2,16(sp)
ffffffffc02044de:	0ee78a63          	beq	a5,a4,ffffffffc02045d2 <do_exit+0x11e>
ffffffffc02044e2:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc02044e4:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02044e6:	c115                	beqz	a0,ffffffffc020450a <do_exit+0x56>
ffffffffc02044e8:	00097797          	auipc	a5,0x97
ffffffffc02044ec:	2587b783          	ld	a5,600(a5) # ffffffffc029b740 <boot_pgdir_pa>
ffffffffc02044f0:	577d                	li	a4,-1
ffffffffc02044f2:	177e                	slli	a4,a4,0x3f
ffffffffc02044f4:	83b1                	srli	a5,a5,0xc
ffffffffc02044f6:	8fd9                	or	a5,a5,a4
ffffffffc02044f8:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02044fc:	591c                	lw	a5,48(a0)
ffffffffc02044fe:	37fd                	addiw	a5,a5,-1
ffffffffc0204500:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc0204502:	cfd5                	beqz	a5,ffffffffc02045be <do_exit+0x10a>
        current->mm = NULL;
ffffffffc0204504:	601c                	ld	a5,0(s0)
ffffffffc0204506:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020450a:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc020450c:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204510:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204512:	100027f3          	csrr	a5,sstatus
ffffffffc0204516:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204518:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020451a:	ebe1                	bnez	a5,ffffffffc02045ea <do_exit+0x136>
        proc = current->parent;
ffffffffc020451c:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020451e:	800007b7          	lui	a5,0x80000
ffffffffc0204522:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        proc = current->parent;
ffffffffc0204524:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204526:	0ec52703          	lw	a4,236(a0)
ffffffffc020452a:	0cf70463          	beq	a4,a5,ffffffffc02045f2 <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc020452e:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204530:	800005b7          	lui	a1,0x80000
ffffffffc0204534:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        while (current->cptr != NULL)
ffffffffc0204536:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204538:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc020453a:	e789                	bnez	a5,ffffffffc0204544 <do_exit+0x90>
ffffffffc020453c:	a83d                	j	ffffffffc020457a <do_exit+0xc6>
ffffffffc020453e:	6018                	ld	a4,0(s0)
ffffffffc0204540:	7b7c                	ld	a5,240(a4)
ffffffffc0204542:	cf85                	beqz	a5,ffffffffc020457a <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204544:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204548:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020454a:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc020454c:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204550:	7978                	ld	a4,240(a0)
ffffffffc0204552:	10e7b023          	sd	a4,256(a5)
ffffffffc0204556:	c311                	beqz	a4,ffffffffc020455a <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204558:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020455a:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020455c:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020455e:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204560:	fcc71fe3          	bne	a4,a2,ffffffffc020453e <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204564:	0ec52783          	lw	a5,236(a0)
ffffffffc0204568:	fcb79be3          	bne	a5,a1,ffffffffc020453e <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc020456c:	419000ef          	jal	ffffffffc0205184 <wakeup_proc>
ffffffffc0204570:	800005b7          	lui	a1,0x80000
ffffffffc0204574:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
ffffffffc0204576:	460d                	li	a2,3
ffffffffc0204578:	b7d9                	j	ffffffffc020453e <do_exit+0x8a>
    if (flag)
ffffffffc020457a:	02091263          	bnez	s2,ffffffffc020459e <do_exit+0xea>
    schedule();
ffffffffc020457e:	49b000ef          	jal	ffffffffc0205218 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204582:	601c                	ld	a5,0(s0)
ffffffffc0204584:	00003617          	auipc	a2,0x3
ffffffffc0204588:	afc60613          	addi	a2,a2,-1284 # ffffffffc0207080 <etext+0x1840>
ffffffffc020458c:	24900593          	li	a1,585
ffffffffc0204590:	43d4                	lw	a3,4(a5)
ffffffffc0204592:	00003517          	auipc	a0,0x3
ffffffffc0204596:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0207000 <etext+0x17c0>
ffffffffc020459a:	eadfb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc020459e:	b60fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02045a2:	bff1                	j	ffffffffc020457e <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc02045a4:	00003617          	auipc	a2,0x3
ffffffffc02045a8:	abc60613          	addi	a2,a2,-1348 # ffffffffc0207060 <etext+0x1820>
ffffffffc02045ac:	21500593          	li	a1,533
ffffffffc02045b0:	00003517          	auipc	a0,0x3
ffffffffc02045b4:	a5050513          	addi	a0,a0,-1456 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02045b8:	e84a                	sd	s2,16(sp)
ffffffffc02045ba:	e8dfb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc02045be:	e42a                	sd	a0,8(sp)
ffffffffc02045c0:	c44ff0ef          	jal	ffffffffc0203a04 <exit_mmap>
            put_pgdir(mm);
ffffffffc02045c4:	6522                	ld	a0,8(sp)
ffffffffc02045c6:	981ff0ef          	jal	ffffffffc0203f46 <put_pgdir>
            mm_destroy(mm);
ffffffffc02045ca:	6522                	ld	a0,8(sp)
ffffffffc02045cc:	a82ff0ef          	jal	ffffffffc020384e <mm_destroy>
ffffffffc02045d0:	bf15                	j	ffffffffc0204504 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02045d2:	00003617          	auipc	a2,0x3
ffffffffc02045d6:	a9e60613          	addi	a2,a2,-1378 # ffffffffc0207070 <etext+0x1830>
ffffffffc02045da:	21900593          	li	a1,537
ffffffffc02045de:	00003517          	auipc	a0,0x3
ffffffffc02045e2:	a2250513          	addi	a0,a0,-1502 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02045e6:	e61fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc02045ea:	b1afc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02045ee:	4905                	li	s2,1
ffffffffc02045f0:	b735                	j	ffffffffc020451c <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02045f2:	393000ef          	jal	ffffffffc0205184 <wakeup_proc>
ffffffffc02045f6:	bf25                	j	ffffffffc020452e <do_exit+0x7a>

ffffffffc02045f8 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02045f8:	7179                	addi	sp,sp,-48
ffffffffc02045fa:	ec26                	sd	s1,24(sp)
ffffffffc02045fc:	e84a                	sd	s2,16(sp)
ffffffffc02045fe:	e44e                	sd	s3,8(sp)
ffffffffc0204600:	f406                	sd	ra,40(sp)
ffffffffc0204602:	f022                	sd	s0,32(sp)
ffffffffc0204604:	84aa                	mv	s1,a0
ffffffffc0204606:	892e                	mv	s2,a1
ffffffffc0204608:	00097997          	auipc	s3,0x97
ffffffffc020460c:	16898993          	addi	s3,s3,360 # ffffffffc029b770 <current>
    if (pid != 0)
ffffffffc0204610:	cd19                	beqz	a0,ffffffffc020462e <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204612:	6789                	lui	a5,0x2
ffffffffc0204614:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc0204616:	fff5071b          	addiw	a4,a0,-1
ffffffffc020461a:	12e7f563          	bgeu	a5,a4,ffffffffc0204744 <do_wait.part.0+0x14c>
}
ffffffffc020461e:	70a2                	ld	ra,40(sp)
ffffffffc0204620:	7402                	ld	s0,32(sp)
ffffffffc0204622:	64e2                	ld	s1,24(sp)
ffffffffc0204624:	6942                	ld	s2,16(sp)
ffffffffc0204626:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204628:	5579                	li	a0,-2
}
ffffffffc020462a:	6145                	addi	sp,sp,48
ffffffffc020462c:	8082                	ret
        proc = current->cptr;
ffffffffc020462e:	0009b703          	ld	a4,0(s3)
ffffffffc0204632:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204634:	d46d                	beqz	s0,ffffffffc020461e <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204636:	468d                	li	a3,3
ffffffffc0204638:	a021                	j	ffffffffc0204640 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020463a:	10043403          	ld	s0,256(s0)
ffffffffc020463e:	c075                	beqz	s0,ffffffffc0204722 <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204640:	401c                	lw	a5,0(s0)
ffffffffc0204642:	fed79ce3          	bne	a5,a3,ffffffffc020463a <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204646:	00097797          	auipc	a5,0x97
ffffffffc020464a:	13a7b783          	ld	a5,314(a5) # ffffffffc029b780 <idleproc>
ffffffffc020464e:	14878263          	beq	a5,s0,ffffffffc0204792 <do_wait.part.0+0x19a>
ffffffffc0204652:	00097797          	auipc	a5,0x97
ffffffffc0204656:	1267b783          	ld	a5,294(a5) # ffffffffc029b778 <initproc>
ffffffffc020465a:	12f40c63          	beq	s0,a5,ffffffffc0204792 <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc020465e:	00090663          	beqz	s2,ffffffffc020466a <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc0204662:	0e842783          	lw	a5,232(s0)
ffffffffc0204666:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020466a:	100027f3          	csrr	a5,sstatus
ffffffffc020466e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204670:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204672:	10079963          	bnez	a5,ffffffffc0204784 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204676:	6c74                	ld	a3,216(s0)
ffffffffc0204678:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc020467a:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020467e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204680:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204682:	6474                	ld	a3,200(s0)
ffffffffc0204684:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc0204686:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204688:	e314                	sd	a3,0(a4)
ffffffffc020468a:	c789                	beqz	a5,ffffffffc0204694 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc020468c:	7c78                	ld	a4,248(s0)
ffffffffc020468e:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc0204690:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc0204694:	7c78                	ld	a4,248(s0)
ffffffffc0204696:	c36d                	beqz	a4,ffffffffc0204778 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204698:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc020469c:	00097797          	auipc	a5,0x97
ffffffffc02046a0:	0cc7a783          	lw	a5,204(a5) # ffffffffc029b768 <nr_process>
ffffffffc02046a4:	37fd                	addiw	a5,a5,-1
ffffffffc02046a6:	00097717          	auipc	a4,0x97
ffffffffc02046aa:	0cf72123          	sw	a5,194(a4) # ffffffffc029b768 <nr_process>
    if (flag)
ffffffffc02046ae:	e271                	bnez	a2,ffffffffc0204772 <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02046b0:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02046b2:	c02007b7          	lui	a5,0xc0200
ffffffffc02046b6:	10f6e663          	bltu	a3,a5,ffffffffc02047c2 <do_wait.part.0+0x1ca>
ffffffffc02046ba:	00097717          	auipc	a4,0x97
ffffffffc02046be:	09673703          	ld	a4,150(a4) # ffffffffc029b750 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02046c2:	00097797          	auipc	a5,0x97
ffffffffc02046c6:	0967b783          	ld	a5,150(a5) # ffffffffc029b758 <npage>
    return pa2page(PADDR(kva));
ffffffffc02046ca:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02046cc:	82b1                	srli	a3,a3,0xc
ffffffffc02046ce:	0cf6fe63          	bgeu	a3,a5,ffffffffc02047aa <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02046d2:	00003797          	auipc	a5,0x3
ffffffffc02046d6:	2d67b783          	ld	a5,726(a5) # ffffffffc02079a8 <nbase>
ffffffffc02046da:	00097517          	auipc	a0,0x97
ffffffffc02046de:	08653503          	ld	a0,134(a0) # ffffffffc029b760 <pages>
ffffffffc02046e2:	4589                	li	a1,2
ffffffffc02046e4:	8e9d                	sub	a3,a3,a5
ffffffffc02046e6:	069a                	slli	a3,a3,0x6
ffffffffc02046e8:	9536                	add	a0,a0,a3
ffffffffc02046ea:	ffefd0ef          	jal	ffffffffc0201ee8 <free_pages>
    kfree(proc);
ffffffffc02046ee:	8522                	mv	a0,s0
ffffffffc02046f0:	ea2fd0ef          	jal	ffffffffc0201d92 <kfree>
}
ffffffffc02046f4:	70a2                	ld	ra,40(sp)
ffffffffc02046f6:	7402                	ld	s0,32(sp)
ffffffffc02046f8:	64e2                	ld	s1,24(sp)
ffffffffc02046fa:	6942                	ld	s2,16(sp)
ffffffffc02046fc:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02046fe:	4501                	li	a0,0
}
ffffffffc0204700:	6145                	addi	sp,sp,48
ffffffffc0204702:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204704:	00097997          	auipc	s3,0x97
ffffffffc0204708:	06c98993          	addi	s3,s3,108 # ffffffffc029b770 <current>
ffffffffc020470c:	0009b703          	ld	a4,0(s3)
ffffffffc0204710:	f487b683          	ld	a3,-184(a5)
ffffffffc0204714:	f0e695e3          	bne	a3,a4,ffffffffc020461e <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204718:	f287a603          	lw	a2,-216(a5)
ffffffffc020471c:	468d                	li	a3,3
ffffffffc020471e:	06d60063          	beq	a2,a3,ffffffffc020477e <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc0204722:	800007b7          	lui	a5,0x80000
ffffffffc0204726:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        current->state = PROC_SLEEPING;
ffffffffc0204728:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc020472a:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc020472e:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204730:	2e9000ef          	jal	ffffffffc0205218 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204734:	0009b783          	ld	a5,0(s3)
ffffffffc0204738:	0b07a783          	lw	a5,176(a5)
ffffffffc020473c:	8b85                	andi	a5,a5,1
ffffffffc020473e:	e7b9                	bnez	a5,ffffffffc020478c <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc0204740:	ee0487e3          	beqz	s1,ffffffffc020462e <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204744:	45a9                	li	a1,10
ffffffffc0204746:	8526                	mv	a0,s1
ffffffffc0204748:	439000ef          	jal	ffffffffc0205380 <hash32>
ffffffffc020474c:	02051793          	slli	a5,a0,0x20
ffffffffc0204750:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204754:	00093797          	auipc	a5,0x93
ffffffffc0204758:	f9c78793          	addi	a5,a5,-100 # ffffffffc02976f0 <hash_list>
ffffffffc020475c:	953e                	add	a0,a0,a5
ffffffffc020475e:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204760:	a029                	j	ffffffffc020476a <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc0204762:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204766:	f8970fe3          	beq	a4,s1,ffffffffc0204704 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc020476a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020476c:	fef51be3          	bne	a0,a5,ffffffffc0204762 <do_wait.part.0+0x16a>
ffffffffc0204770:	b57d                	j	ffffffffc020461e <do_wait.part.0+0x26>
        intr_enable();
ffffffffc0204772:	98cfc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0204776:	bf2d                	j	ffffffffc02046b0 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204778:	7018                	ld	a4,32(s0)
ffffffffc020477a:	fb7c                	sd	a5,240(a4)
ffffffffc020477c:	b705                	j	ffffffffc020469c <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020477e:	f2878413          	addi	s0,a5,-216
ffffffffc0204782:	b5d1                	j	ffffffffc0204646 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc0204784:	980fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204788:	4605                	li	a2,1
ffffffffc020478a:	b5f5                	j	ffffffffc0204676 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc020478c:	555d                	li	a0,-9
ffffffffc020478e:	d27ff0ef          	jal	ffffffffc02044b4 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc0204792:	00003617          	auipc	a2,0x3
ffffffffc0204796:	90e60613          	addi	a2,a2,-1778 # ffffffffc02070a0 <etext+0x1860>
ffffffffc020479a:	36b00593          	li	a1,875
ffffffffc020479e:	00003517          	auipc	a0,0x3
ffffffffc02047a2:	86250513          	addi	a0,a0,-1950 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02047a6:	ca1fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02047aa:	00002617          	auipc	a2,0x2
ffffffffc02047ae:	ef660613          	addi	a2,a2,-266 # ffffffffc02066a0 <etext+0xe60>
ffffffffc02047b2:	06900593          	li	a1,105
ffffffffc02047b6:	00002517          	auipc	a0,0x2
ffffffffc02047ba:	e4250513          	addi	a0,a0,-446 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02047be:	c89fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02047c2:	00002617          	auipc	a2,0x2
ffffffffc02047c6:	eb660613          	addi	a2,a2,-330 # ffffffffc0206678 <etext+0xe38>
ffffffffc02047ca:	07700593          	li	a1,119
ffffffffc02047ce:	00002517          	auipc	a0,0x2
ffffffffc02047d2:	e2a50513          	addi	a0,a0,-470 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc02047d6:	c71fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02047da <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047da:	1141                	addi	sp,sp,-16
ffffffffc02047dc:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047de:	f42fd0ef          	jal	ffffffffc0201f20 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047e2:	d06fd0ef          	jal	ffffffffc0201ce8 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047e6:	4601                	li	a2,0
ffffffffc02047e8:	4581                	li	a1,0
ffffffffc02047ea:	fffff517          	auipc	a0,0xfffff
ffffffffc02047ee:	6de50513          	addi	a0,a0,1758 # ffffffffc0203ec8 <user_main>
ffffffffc02047f2:	c73ff0ef          	jal	ffffffffc0204464 <kernel_thread>
    if (pid <= 0)
ffffffffc02047f6:	00a04563          	bgtz	a0,ffffffffc0204800 <init_main+0x26>
ffffffffc02047fa:	a071                	j	ffffffffc0204886 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047fc:	21d000ef          	jal	ffffffffc0205218 <schedule>
    if (code_store != NULL)
ffffffffc0204800:	4581                	li	a1,0
ffffffffc0204802:	4501                	li	a0,0
ffffffffc0204804:	df5ff0ef          	jal	ffffffffc02045f8 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204808:	d975                	beqz	a0,ffffffffc02047fc <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020480a:	00003517          	auipc	a0,0x3
ffffffffc020480e:	8d650513          	addi	a0,a0,-1834 # ffffffffc02070e0 <etext+0x18a0>
ffffffffc0204812:	983fb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204816:	00097797          	auipc	a5,0x97
ffffffffc020481a:	f627b783          	ld	a5,-158(a5) # ffffffffc029b778 <initproc>
ffffffffc020481e:	7bf8                	ld	a4,240(a5)
ffffffffc0204820:	e339                	bnez	a4,ffffffffc0204866 <init_main+0x8c>
ffffffffc0204822:	7ff8                	ld	a4,248(a5)
ffffffffc0204824:	e329                	bnez	a4,ffffffffc0204866 <init_main+0x8c>
ffffffffc0204826:	1007b703          	ld	a4,256(a5)
ffffffffc020482a:	ef15                	bnez	a4,ffffffffc0204866 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020482c:	00097697          	auipc	a3,0x97
ffffffffc0204830:	f3c6a683          	lw	a3,-196(a3) # ffffffffc029b768 <nr_process>
ffffffffc0204834:	4709                	li	a4,2
ffffffffc0204836:	0ae69463          	bne	a3,a4,ffffffffc02048de <init_main+0x104>
ffffffffc020483a:	00097697          	auipc	a3,0x97
ffffffffc020483e:	eb668693          	addi	a3,a3,-330 # ffffffffc029b6f0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204842:	6698                	ld	a4,8(a3)
ffffffffc0204844:	0c878793          	addi	a5,a5,200
ffffffffc0204848:	06f71b63          	bne	a4,a5,ffffffffc02048be <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020484c:	629c                	ld	a5,0(a3)
ffffffffc020484e:	04f71863          	bne	a4,a5,ffffffffc020489e <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204852:	00003517          	auipc	a0,0x3
ffffffffc0204856:	97650513          	addi	a0,a0,-1674 # ffffffffc02071c8 <etext+0x1988>
ffffffffc020485a:	93bfb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020485e:	60a2                	ld	ra,8(sp)
ffffffffc0204860:	4501                	li	a0,0
ffffffffc0204862:	0141                	addi	sp,sp,16
ffffffffc0204864:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204866:	00003697          	auipc	a3,0x3
ffffffffc020486a:	8a268693          	addi	a3,a3,-1886 # ffffffffc0207108 <etext+0x18c8>
ffffffffc020486e:	00002617          	auipc	a2,0x2
ffffffffc0204872:	9b260613          	addi	a2,a2,-1614 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204876:	3d900593          	li	a1,985
ffffffffc020487a:	00002517          	auipc	a0,0x2
ffffffffc020487e:	78650513          	addi	a0,a0,1926 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204882:	bc5fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204886:	00003617          	auipc	a2,0x3
ffffffffc020488a:	83a60613          	addi	a2,a2,-1990 # ffffffffc02070c0 <etext+0x1880>
ffffffffc020488e:	3d000593          	li	a1,976
ffffffffc0204892:	00002517          	auipc	a0,0x2
ffffffffc0204896:	76e50513          	addi	a0,a0,1902 # ffffffffc0207000 <etext+0x17c0>
ffffffffc020489a:	badfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020489e:	00003697          	auipc	a3,0x3
ffffffffc02048a2:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0207198 <etext+0x1958>
ffffffffc02048a6:	00002617          	auipc	a2,0x2
ffffffffc02048aa:	97a60613          	addi	a2,a2,-1670 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02048ae:	3dc00593          	li	a1,988
ffffffffc02048b2:	00002517          	auipc	a0,0x2
ffffffffc02048b6:	74e50513          	addi	a0,a0,1870 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02048ba:	b8dfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048be:	00003697          	auipc	a3,0x3
ffffffffc02048c2:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0207168 <etext+0x1928>
ffffffffc02048c6:	00002617          	auipc	a2,0x2
ffffffffc02048ca:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02048ce:	3db00593          	li	a1,987
ffffffffc02048d2:	00002517          	auipc	a0,0x2
ffffffffc02048d6:	72e50513          	addi	a0,a0,1838 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02048da:	b6dfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc02048de:	00003697          	auipc	a3,0x3
ffffffffc02048e2:	87a68693          	addi	a3,a3,-1926 # ffffffffc0207158 <etext+0x1918>
ffffffffc02048e6:	00002617          	auipc	a2,0x2
ffffffffc02048ea:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02048ee:	3da00593          	li	a1,986
ffffffffc02048f2:	00002517          	auipc	a0,0x2
ffffffffc02048f6:	70e50513          	addi	a0,a0,1806 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02048fa:	b4dfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02048fe <do_execve>:
{
ffffffffc02048fe:	7171                	addi	sp,sp,-176
ffffffffc0204900:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204902:	00097d17          	auipc	s10,0x97
ffffffffc0204906:	e6ed0d13          	addi	s10,s10,-402 # ffffffffc029b770 <current>
ffffffffc020490a:	000d3783          	ld	a5,0(s10)
{
ffffffffc020490e:	e94a                	sd	s2,144(sp)
ffffffffc0204910:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204912:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204916:	84ae                	mv	s1,a1
ffffffffc0204918:	e54e                	sd	s3,136(sp)
ffffffffc020491a:	ec32                	sd	a2,24(sp)
ffffffffc020491c:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020491e:	85aa                	mv	a1,a0
ffffffffc0204920:	8626                	mv	a2,s1
ffffffffc0204922:	854a                	mv	a0,s2
ffffffffc0204924:	4681                	li	a3,0
{
ffffffffc0204926:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204928:	c74ff0ef          	jal	ffffffffc0203d9c <user_mem_check>
ffffffffc020492c:	48050163          	beqz	a0,ffffffffc0204dae <do_execve+0x4b0>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204930:	4641                	li	a2,16
ffffffffc0204932:	1808                	addi	a0,sp,48
ffffffffc0204934:	4581                	li	a1,0
ffffffffc0204936:	6e1000ef          	jal	ffffffffc0205816 <memset>
    if (len > PROC_NAME_LEN)
ffffffffc020493a:	47bd                	li	a5,15
ffffffffc020493c:	8626                	mv	a2,s1
ffffffffc020493e:	0e97ef63          	bltu	a5,s1,ffffffffc0204a3c <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc0204942:	85ce                	mv	a1,s3
ffffffffc0204944:	1808                	addi	a0,sp,48
ffffffffc0204946:	6e3000ef          	jal	ffffffffc0205828 <memcpy>
    if (mm != NULL)
ffffffffc020494a:	10090063          	beqz	s2,ffffffffc0204a4a <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc020494e:	00002517          	auipc	a0,0x2
ffffffffc0204952:	47a50513          	addi	a0,a0,1146 # ffffffffc0206dc8 <etext+0x1588>
ffffffffc0204956:	875fb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc020495a:	00097797          	auipc	a5,0x97
ffffffffc020495e:	de67b783          	ld	a5,-538(a5) # ffffffffc029b740 <boot_pgdir_pa>
ffffffffc0204962:	577d                	li	a4,-1
ffffffffc0204964:	177e                	slli	a4,a4,0x3f
ffffffffc0204966:	83b1                	srli	a5,a5,0xc
ffffffffc0204968:	8fd9                	or	a5,a5,a4
ffffffffc020496a:	18079073          	csrw	satp,a5
ffffffffc020496e:	03092783          	lw	a5,48(s2)
ffffffffc0204972:	37fd                	addiw	a5,a5,-1
ffffffffc0204974:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204978:	30078763          	beqz	a5,ffffffffc0204c86 <do_execve+0x388>
        current->mm = NULL;
ffffffffc020497c:	000d3783          	ld	a5,0(s10)
ffffffffc0204980:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204984:	d8dfe0ef          	jal	ffffffffc0203710 <mm_create>
ffffffffc0204988:	892a                	mv	s2,a0
ffffffffc020498a:	22050263          	beqz	a0,ffffffffc0204bae <do_execve+0x2b0>
    if ((page = alloc_page()) == NULL)
ffffffffc020498e:	4505                	li	a0,1
ffffffffc0204990:	d1efd0ef          	jal	ffffffffc0201eae <alloc_pages>
ffffffffc0204994:	42050263          	beqz	a0,ffffffffc0204db8 <do_execve+0x4ba>
    return page - pages + nbase;
ffffffffc0204998:	f0e2                	sd	s8,96(sp)
ffffffffc020499a:	00097c17          	auipc	s8,0x97
ffffffffc020499e:	dc6c0c13          	addi	s8,s8,-570 # ffffffffc029b760 <pages>
ffffffffc02049a2:	000c3783          	ld	a5,0(s8)
ffffffffc02049a6:	f4de                	sd	s7,104(sp)
ffffffffc02049a8:	00003b97          	auipc	s7,0x3
ffffffffc02049ac:	000bbb83          	ld	s7,0(s7) # ffffffffc02079a8 <nbase>
ffffffffc02049b0:	40f506b3          	sub	a3,a0,a5
ffffffffc02049b4:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02049b6:	00097c97          	auipc	s9,0x97
ffffffffc02049ba:	da2c8c93          	addi	s9,s9,-606 # ffffffffc029b758 <npage>
ffffffffc02049be:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02049c0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02049c2:	5b7d                	li	s6,-1
ffffffffc02049c4:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02049c8:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02049ca:	00cb5713          	srli	a4,s6,0xc
ffffffffc02049ce:	e83a                	sd	a4,16(sp)
ffffffffc02049d0:	fcd6                	sd	s5,120(sp)
ffffffffc02049d2:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049d4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049d6:	40f77463          	bgeu	a4,a5,ffffffffc0204dde <do_execve+0x4e0>
ffffffffc02049da:	00097a97          	auipc	s5,0x97
ffffffffc02049de:	d76a8a93          	addi	s5,s5,-650 # ffffffffc029b750 <va_pa_offset>
ffffffffc02049e2:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049e6:	00097597          	auipc	a1,0x97
ffffffffc02049ea:	d625b583          	ld	a1,-670(a1) # ffffffffc029b748 <boot_pgdir_va>
ffffffffc02049ee:	6605                	lui	a2,0x1
ffffffffc02049f0:	00f684b3          	add	s1,a3,a5
ffffffffc02049f4:	8526                	mv	a0,s1
ffffffffc02049f6:	633000ef          	jal	ffffffffc0205828 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049fa:	66e2                	ld	a3,24(sp)
ffffffffc02049fc:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204a00:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a04:	4298                	lw	a4,0(a3)
ffffffffc0204a06:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba3a7>
ffffffffc0204a0a:	06f70863          	beq	a4,a5,ffffffffc0204a7a <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204a0e:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204a10:	854a                	mv	a0,s2
ffffffffc0204a12:	d34ff0ef          	jal	ffffffffc0203f46 <put_pgdir>
ffffffffc0204a16:	7ae6                	ld	s5,120(sp)
ffffffffc0204a18:	7b46                	ld	s6,112(sp)
ffffffffc0204a1a:	7ba6                	ld	s7,104(sp)
ffffffffc0204a1c:	7c06                	ld	s8,96(sp)
ffffffffc0204a1e:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204a20:	854a                	mv	a0,s2
ffffffffc0204a22:	e2dfe0ef          	jal	ffffffffc020384e <mm_destroy>
    do_exit(ret);
ffffffffc0204a26:	8526                	mv	a0,s1
ffffffffc0204a28:	f122                	sd	s0,160(sp)
ffffffffc0204a2a:	e152                	sd	s4,128(sp)
ffffffffc0204a2c:	fcd6                	sd	s5,120(sp)
ffffffffc0204a2e:	f8da                	sd	s6,112(sp)
ffffffffc0204a30:	f4de                	sd	s7,104(sp)
ffffffffc0204a32:	f0e2                	sd	s8,96(sp)
ffffffffc0204a34:	ece6                	sd	s9,88(sp)
ffffffffc0204a36:	e4ee                	sd	s11,72(sp)
ffffffffc0204a38:	a7dff0ef          	jal	ffffffffc02044b4 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204a3c:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204a3e:	85ce                	mv	a1,s3
ffffffffc0204a40:	1808                	addi	a0,sp,48
ffffffffc0204a42:	5e7000ef          	jal	ffffffffc0205828 <memcpy>
    if (mm != NULL)
ffffffffc0204a46:	f00914e3          	bnez	s2,ffffffffc020494e <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204a4a:	000d3783          	ld	a5,0(s10)
ffffffffc0204a4e:	779c                	ld	a5,40(a5)
ffffffffc0204a50:	db95                	beqz	a5,ffffffffc0204984 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a52:	00002617          	auipc	a2,0x2
ffffffffc0204a56:	79660613          	addi	a2,a2,1942 # ffffffffc02071e8 <etext+0x19a8>
ffffffffc0204a5a:	25500593          	li	a1,597
ffffffffc0204a5e:	00002517          	auipc	a0,0x2
ffffffffc0204a62:	5a250513          	addi	a0,a0,1442 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204a66:	f122                	sd	s0,160(sp)
ffffffffc0204a68:	e152                	sd	s4,128(sp)
ffffffffc0204a6a:	fcd6                	sd	s5,120(sp)
ffffffffc0204a6c:	f8da                	sd	s6,112(sp)
ffffffffc0204a6e:	f4de                	sd	s7,104(sp)
ffffffffc0204a70:	f0e2                	sd	s8,96(sp)
ffffffffc0204a72:	ece6                	sd	s9,88(sp)
ffffffffc0204a74:	e4ee                	sd	s11,72(sp)
ffffffffc0204a76:	9d1fb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a7a:	0386d703          	lhu	a4,56(a3)
ffffffffc0204a7e:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a80:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a84:	00371793          	slli	a5,a4,0x3
ffffffffc0204a88:	8f99                	sub	a5,a5,a4
ffffffffc0204a8a:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a8c:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a8e:	97d2                	add	a5,a5,s4
ffffffffc0204a90:	f122                	sd	s0,160(sp)
ffffffffc0204a92:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a94:	00fa7e63          	bgeu	s4,a5,ffffffffc0204ab0 <do_execve+0x1b2>
ffffffffc0204a98:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a9a:	000a2783          	lw	a5,0(s4)
ffffffffc0204a9e:	4705                	li	a4,1
ffffffffc0204aa0:	10e78963          	beq	a5,a4,ffffffffc0204bb2 <do_execve+0x2b4>
    for (; ph < ph_end; ph++)
ffffffffc0204aa4:	77a2                	ld	a5,40(sp)
ffffffffc0204aa6:	038a0a13          	addi	s4,s4,56
ffffffffc0204aaa:	fefa68e3          	bltu	s4,a5,ffffffffc0204a9a <do_execve+0x19c>
ffffffffc0204aae:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204ab0:	4701                	li	a4,0
ffffffffc0204ab2:	46ad                	li	a3,11
ffffffffc0204ab4:	00100637          	lui	a2,0x100
ffffffffc0204ab8:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204abc:	854a                	mv	a0,s2
ffffffffc0204abe:	de3fe0ef          	jal	ffffffffc02038a0 <mm_map>
ffffffffc0204ac2:	84aa                	mv	s1,a0
ffffffffc0204ac4:	1a051b63          	bnez	a0,ffffffffc0204c7a <do_execve+0x37c>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ac8:	01893503          	ld	a0,24(s2)
ffffffffc0204acc:	467d                	li	a2,31
ffffffffc0204ace:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204ad2:	b5dfe0ef          	jal	ffffffffc020362e <pgdir_alloc_page>
ffffffffc0204ad6:	3a050363          	beqz	a0,ffffffffc0204e7c <do_execve+0x57e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ada:	01893503          	ld	a0,24(s2)
ffffffffc0204ade:	467d                	li	a2,31
ffffffffc0204ae0:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204ae4:	b4bfe0ef          	jal	ffffffffc020362e <pgdir_alloc_page>
ffffffffc0204ae8:	36050963          	beqz	a0,ffffffffc0204e5a <do_execve+0x55c>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204aec:	01893503          	ld	a0,24(s2)
ffffffffc0204af0:	467d                	li	a2,31
ffffffffc0204af2:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204af6:	b39fe0ef          	jal	ffffffffc020362e <pgdir_alloc_page>
ffffffffc0204afa:	32050f63          	beqz	a0,ffffffffc0204e38 <do_execve+0x53a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204afe:	01893503          	ld	a0,24(s2)
ffffffffc0204b02:	467d                	li	a2,31
ffffffffc0204b04:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b08:	b27fe0ef          	jal	ffffffffc020362e <pgdir_alloc_page>
ffffffffc0204b0c:	30050563          	beqz	a0,ffffffffc0204e16 <do_execve+0x518>
    mm->mm_count += 1;
ffffffffc0204b10:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b14:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b18:	01893683          	ld	a3,24(s2)
ffffffffc0204b1c:	2785                	addiw	a5,a5,1
ffffffffc0204b1e:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b22:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e50>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b26:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b2a:	2cf6e963          	bltu	a3,a5,ffffffffc0204dfc <do_execve+0x4fe>
ffffffffc0204b2e:	000ab783          	ld	a5,0(s5)
ffffffffc0204b32:	577d                	li	a4,-1
ffffffffc0204b34:	177e                	slli	a4,a4,0x3f
ffffffffc0204b36:	8e9d                	sub	a3,a3,a5
ffffffffc0204b38:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b3c:	f654                	sd	a3,168(a2)
ffffffffc0204b3e:	8fd9                	or	a5,a5,a4
ffffffffc0204b40:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b44:	0a063903          	ld	s2,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b48:	4581                	li	a1,0
ffffffffc0204b4a:	12000613          	li	a2,288
ffffffffc0204b4e:	854a                	mv	a0,s2
ffffffffc0204b50:	4c7000ef          	jal	ffffffffc0205816 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204b54:	67e2                	ld	a5,24(sp)
ffffffffc0204b56:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b58:	4785                	li	a5,1
ffffffffc0204b5a:	07fe                	slli	a5,a5,0x1f
    tf->epc = elf->e_entry;
ffffffffc0204b5c:	10e93423          	sd	a4,264(s2)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b60:	00f93823          	sd	a5,16(s2)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b64:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b68:	000d3403          	ld	s0,0(s10)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b6c:	edf7f793          	andi	a5,a5,-289
ffffffffc0204b70:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b74:	0b440413          	addi	s0,s0,180
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b78:	10f93023          	sd	a5,256(s2)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b7c:	8522                	mv	a0,s0
ffffffffc0204b7e:	4641                	li	a2,16
ffffffffc0204b80:	4581                	li	a1,0
ffffffffc0204b82:	495000ef          	jal	ffffffffc0205816 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b86:	8522                	mv	a0,s0
ffffffffc0204b88:	180c                	addi	a1,sp,48
ffffffffc0204b8a:	463d                	li	a2,15
ffffffffc0204b8c:	49d000ef          	jal	ffffffffc0205828 <memcpy>
ffffffffc0204b90:	740a                	ld	s0,160(sp)
ffffffffc0204b92:	6a0a                	ld	s4,128(sp)
ffffffffc0204b94:	7ae6                	ld	s5,120(sp)
ffffffffc0204b96:	7b46                	ld	s6,112(sp)
ffffffffc0204b98:	7ba6                	ld	s7,104(sp)
ffffffffc0204b9a:	7c06                	ld	s8,96(sp)
ffffffffc0204b9c:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204b9e:	70aa                	ld	ra,168(sp)
ffffffffc0204ba0:	694a                	ld	s2,144(sp)
ffffffffc0204ba2:	69aa                	ld	s3,136(sp)
ffffffffc0204ba4:	6d46                	ld	s10,80(sp)
ffffffffc0204ba6:	8526                	mv	a0,s1
ffffffffc0204ba8:	64ea                	ld	s1,152(sp)
ffffffffc0204baa:	614d                	addi	sp,sp,176
ffffffffc0204bac:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204bae:	54f1                	li	s1,-4
ffffffffc0204bb0:	bd9d                	j	ffffffffc0204a26 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204bb2:	028a3603          	ld	a2,40(s4)
ffffffffc0204bb6:	020a3783          	ld	a5,32(s4)
ffffffffc0204bba:	20f66363          	bltu	a2,a5,ffffffffc0204dc0 <do_execve+0x4c2>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bbe:	004a2783          	lw	a5,4(s4)
ffffffffc0204bc2:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bc6:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bca:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bcc:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bce:	c6f1                	beqz	a3,ffffffffc0204c9a <do_execve+0x39c>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bd0:	1c079763          	bnez	a5,ffffffffc0204d9e <do_execve+0x4a0>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bd4:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204bd6:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204bda:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204bdc:	c709                	beqz	a4,ffffffffc0204be6 <do_execve+0x2e8>
            perm |= PTE_X;
ffffffffc0204bde:	67a2                	ld	a5,8(sp)
ffffffffc0204be0:	0087e793          	ori	a5,a5,8
ffffffffc0204be4:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204be6:	010a3583          	ld	a1,16(s4)
ffffffffc0204bea:	4701                	li	a4,0
ffffffffc0204bec:	854a                	mv	a0,s2
ffffffffc0204bee:	cb3fe0ef          	jal	ffffffffc02038a0 <mm_map>
ffffffffc0204bf2:	84aa                	mv	s1,a0
ffffffffc0204bf4:	1c051463          	bnez	a0,ffffffffc0204dbc <do_execve+0x4be>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bf8:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bfc:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c00:	77fd                	lui	a5,0xfffff
ffffffffc0204c02:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c06:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204c08:	1a9b7563          	bgeu	s6,s1,ffffffffc0204db2 <do_execve+0x4b4>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c0c:	008a3983          	ld	s3,8(s4)
ffffffffc0204c10:	67e2                	ld	a5,24(sp)
ffffffffc0204c12:	99be                	add	s3,s3,a5
ffffffffc0204c14:	a881                	j	ffffffffc0204c64 <do_execve+0x366>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c16:	6785                	lui	a5,0x1
ffffffffc0204c18:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204c1c:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204c20:	01b4e463          	bltu	s1,s11,ffffffffc0204c28 <do_execve+0x32a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c24:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204c28:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c2c:	67c2                	ld	a5,16(sp)
ffffffffc0204c2e:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204c32:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c36:	8699                	srai	a3,a3,0x6
ffffffffc0204c38:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c3a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c3e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c40:	18a87363          	bgeu	a6,a0,ffffffffc0204dc6 <do_execve+0x4c8>
ffffffffc0204c44:	000ab503          	ld	a0,0(s5)
ffffffffc0204c48:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c4c:	e032                	sd	a2,0(sp)
ffffffffc0204c4e:	9536                	add	a0,a0,a3
ffffffffc0204c50:	952e                	add	a0,a0,a1
ffffffffc0204c52:	85ce                	mv	a1,s3
ffffffffc0204c54:	3d5000ef          	jal	ffffffffc0205828 <memcpy>
            start += size, from += size;
ffffffffc0204c58:	6602                	ld	a2,0(sp)
ffffffffc0204c5a:	9b32                	add	s6,s6,a2
ffffffffc0204c5c:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204c5e:	049b7563          	bgeu	s6,s1,ffffffffc0204ca8 <do_execve+0x3aa>
ffffffffc0204c62:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c64:	01893503          	ld	a0,24(s2)
ffffffffc0204c68:	6622                	ld	a2,8(sp)
ffffffffc0204c6a:	e02e                	sd	a1,0(sp)
ffffffffc0204c6c:	9c3fe0ef          	jal	ffffffffc020362e <pgdir_alloc_page>
ffffffffc0204c70:	6582                	ld	a1,0(sp)
ffffffffc0204c72:	842a                	mv	s0,a0
ffffffffc0204c74:	f14d                	bnez	a0,ffffffffc0204c16 <do_execve+0x318>
ffffffffc0204c76:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204c78:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204c7a:	854a                	mv	a0,s2
ffffffffc0204c7c:	d89fe0ef          	jal	ffffffffc0203a04 <exit_mmap>
ffffffffc0204c80:	740a                	ld	s0,160(sp)
ffffffffc0204c82:	6a0a                	ld	s4,128(sp)
ffffffffc0204c84:	b371                	j	ffffffffc0204a10 <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204c86:	854a                	mv	a0,s2
ffffffffc0204c88:	d7dfe0ef          	jal	ffffffffc0203a04 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c8c:	854a                	mv	a0,s2
ffffffffc0204c8e:	ab8ff0ef          	jal	ffffffffc0203f46 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c92:	854a                	mv	a0,s2
ffffffffc0204c94:	bbbfe0ef          	jal	ffffffffc020384e <mm_destroy>
ffffffffc0204c98:	b1d5                	j	ffffffffc020497c <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c9a:	0e078e63          	beqz	a5,ffffffffc0204d96 <do_execve+0x498>
            perm |= PTE_R;
ffffffffc0204c9e:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204ca0:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204ca4:	e43e                	sd	a5,8(sp)
ffffffffc0204ca6:	bf1d                	j	ffffffffc0204bdc <do_execve+0x2de>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204ca8:	010a3483          	ld	s1,16(s4)
ffffffffc0204cac:	028a3683          	ld	a3,40(s4)
ffffffffc0204cb0:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204cb2:	07bb7c63          	bgeu	s6,s11,ffffffffc0204d2a <do_execve+0x42c>
            if (start == end)
ffffffffc0204cb6:	df6487e3          	beq	s1,s6,ffffffffc0204aa4 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204cba:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204cbe:	0fb4f563          	bgeu	s1,s11,ffffffffc0204da8 <do_execve+0x4aa>
    return page - pages + nbase;
ffffffffc0204cc2:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204cc6:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204cca:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cce:	8699                	srai	a3,a3,0x6
ffffffffc0204cd0:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204cd2:	00c69593          	slli	a1,a3,0xc
ffffffffc0204cd6:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cd8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cda:	0ec5f663          	bgeu	a1,a2,ffffffffc0204dc6 <do_execve+0x4c8>
ffffffffc0204cde:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204ce2:	6505                	lui	a0,0x1
ffffffffc0204ce4:	955a                	add	a0,a0,s6
ffffffffc0204ce6:	96b2                	add	a3,a3,a2
ffffffffc0204ce8:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cec:	9536                	add	a0,a0,a3
ffffffffc0204cee:	864e                	mv	a2,s3
ffffffffc0204cf0:	4581                	li	a1,0
ffffffffc0204cf2:	325000ef          	jal	ffffffffc0205816 <memset>
            start += size;
ffffffffc0204cf6:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204cf8:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204cfc:	01b4f463          	bgeu	s1,s11,ffffffffc0204d04 <do_execve+0x406>
ffffffffc0204d00:	db6482e3          	beq	s1,s6,ffffffffc0204aa4 <do_execve+0x1a6>
ffffffffc0204d04:	e299                	bnez	a3,ffffffffc0204d0a <do_execve+0x40c>
ffffffffc0204d06:	03bb0263          	beq	s6,s11,ffffffffc0204d2a <do_execve+0x42c>
ffffffffc0204d0a:	00002697          	auipc	a3,0x2
ffffffffc0204d0e:	50668693          	addi	a3,a3,1286 # ffffffffc0207210 <etext+0x19d0>
ffffffffc0204d12:	00001617          	auipc	a2,0x1
ffffffffc0204d16:	50e60613          	addi	a2,a2,1294 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204d1a:	2be00593          	li	a1,702
ffffffffc0204d1e:	00002517          	auipc	a0,0x2
ffffffffc0204d22:	2e250513          	addi	a0,a0,738 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204d26:	f20fb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204d2a:	d69b7de3          	bgeu	s6,s1,ffffffffc0204aa4 <do_execve+0x1a6>
ffffffffc0204d2e:	56fd                	li	a3,-1
ffffffffc0204d30:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d34:	f03e                	sd	a5,32(sp)
ffffffffc0204d36:	a0b9                	j	ffffffffc0204d84 <do_execve+0x486>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d38:	6785                	lui	a5,0x1
ffffffffc0204d3a:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204d3e:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d42:	0104e463          	bltu	s1,a6,ffffffffc0204d4a <do_execve+0x44c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d46:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204d4a:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204d4e:	7782                	ld	a5,32(sp)
ffffffffc0204d50:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204d54:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d58:	8699                	srai	a3,a3,0x6
ffffffffc0204d5a:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204d5c:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d60:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d62:	06b57263          	bgeu	a0,a1,ffffffffc0204dc6 <do_execve+0x4c8>
ffffffffc0204d66:	000ab583          	ld	a1,0(s5)
ffffffffc0204d6a:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d6e:	864e                	mv	a2,s3
ffffffffc0204d70:	96ae                	add	a3,a3,a1
ffffffffc0204d72:	9536                	add	a0,a0,a3
ffffffffc0204d74:	4581                	li	a1,0
            start += size;
ffffffffc0204d76:	9b4e                	add	s6,s6,s3
ffffffffc0204d78:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d7a:	29d000ef          	jal	ffffffffc0205816 <memset>
        while (start < end)
ffffffffc0204d7e:	d29b73e3          	bgeu	s6,s1,ffffffffc0204aa4 <do_execve+0x1a6>
ffffffffc0204d82:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d84:	01893503          	ld	a0,24(s2)
ffffffffc0204d88:	6622                	ld	a2,8(sp)
ffffffffc0204d8a:	85ee                	mv	a1,s11
ffffffffc0204d8c:	8a3fe0ef          	jal	ffffffffc020362e <pgdir_alloc_page>
ffffffffc0204d90:	842a                	mv	s0,a0
ffffffffc0204d92:	f15d                	bnez	a0,ffffffffc0204d38 <do_execve+0x43a>
ffffffffc0204d94:	b5cd                	j	ffffffffc0204c76 <do_execve+0x378>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d96:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d98:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d9a:	e43e                	sd	a5,8(sp)
ffffffffc0204d9c:	b581                	j	ffffffffc0204bdc <do_execve+0x2de>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d9e:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204da0:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204da4:	e43e                	sd	a5,8(sp)
ffffffffc0204da6:	bd1d                	j	ffffffffc0204bdc <do_execve+0x2de>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204da8:	416d89b3          	sub	s3,s11,s6
ffffffffc0204dac:	bf19                	j	ffffffffc0204cc2 <do_execve+0x3c4>
        return -E_INVAL;
ffffffffc0204dae:	54f5                	li	s1,-3
ffffffffc0204db0:	b3fd                	j	ffffffffc0204b9e <do_execve+0x2a0>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204db2:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204db4:	84da                	mv	s1,s6
ffffffffc0204db6:	bddd                	j	ffffffffc0204cac <do_execve+0x3ae>
    int ret = -E_NO_MEM;
ffffffffc0204db8:	54f1                	li	s1,-4
ffffffffc0204dba:	b19d                	j	ffffffffc0204a20 <do_execve+0x122>
ffffffffc0204dbc:	6da6                	ld	s11,72(sp)
ffffffffc0204dbe:	bd75                	j	ffffffffc0204c7a <do_execve+0x37c>
            ret = -E_INVAL_ELF;
ffffffffc0204dc0:	6da6                	ld	s11,72(sp)
ffffffffc0204dc2:	54e1                	li	s1,-8
ffffffffc0204dc4:	bd5d                	j	ffffffffc0204c7a <do_execve+0x37c>
ffffffffc0204dc6:	00002617          	auipc	a2,0x2
ffffffffc0204dca:	80a60613          	addi	a2,a2,-2038 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0204dce:	07100593          	li	a1,113
ffffffffc0204dd2:	00002517          	auipc	a0,0x2
ffffffffc0204dd6:	82650513          	addi	a0,a0,-2010 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0204dda:	e6cfb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204dde:	00001617          	auipc	a2,0x1
ffffffffc0204de2:	7f260613          	addi	a2,a2,2034 # ffffffffc02065d0 <etext+0xd90>
ffffffffc0204de6:	07100593          	li	a1,113
ffffffffc0204dea:	00002517          	auipc	a0,0x2
ffffffffc0204dee:	80e50513          	addi	a0,a0,-2034 # ffffffffc02065f8 <etext+0xdb8>
ffffffffc0204df2:	f122                	sd	s0,160(sp)
ffffffffc0204df4:	e152                	sd	s4,128(sp)
ffffffffc0204df6:	e4ee                	sd	s11,72(sp)
ffffffffc0204df8:	e4efb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204dfc:	00002617          	auipc	a2,0x2
ffffffffc0204e00:	87c60613          	addi	a2,a2,-1924 # ffffffffc0206678 <etext+0xe38>
ffffffffc0204e04:	2dd00593          	li	a1,733
ffffffffc0204e08:	00002517          	auipc	a0,0x2
ffffffffc0204e0c:	1f850513          	addi	a0,a0,504 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204e10:	e4ee                	sd	s11,72(sp)
ffffffffc0204e12:	e34fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e16:	00002697          	auipc	a3,0x2
ffffffffc0204e1a:	51268693          	addi	a3,a3,1298 # ffffffffc0207328 <etext+0x1ae8>
ffffffffc0204e1e:	00001617          	auipc	a2,0x1
ffffffffc0204e22:	40260613          	addi	a2,a2,1026 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204e26:	2d800593          	li	a1,728
ffffffffc0204e2a:	00002517          	auipc	a0,0x2
ffffffffc0204e2e:	1d650513          	addi	a0,a0,470 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204e32:	e4ee                	sd	s11,72(sp)
ffffffffc0204e34:	e12fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e38:	00002697          	auipc	a3,0x2
ffffffffc0204e3c:	4a868693          	addi	a3,a3,1192 # ffffffffc02072e0 <etext+0x1aa0>
ffffffffc0204e40:	00001617          	auipc	a2,0x1
ffffffffc0204e44:	3e060613          	addi	a2,a2,992 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204e48:	2d700593          	li	a1,727
ffffffffc0204e4c:	00002517          	auipc	a0,0x2
ffffffffc0204e50:	1b450513          	addi	a0,a0,436 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204e54:	e4ee                	sd	s11,72(sp)
ffffffffc0204e56:	df0fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e5a:	00002697          	auipc	a3,0x2
ffffffffc0204e5e:	43e68693          	addi	a3,a3,1086 # ffffffffc0207298 <etext+0x1a58>
ffffffffc0204e62:	00001617          	auipc	a2,0x1
ffffffffc0204e66:	3be60613          	addi	a2,a2,958 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204e6a:	2d600593          	li	a1,726
ffffffffc0204e6e:	00002517          	auipc	a0,0x2
ffffffffc0204e72:	19250513          	addi	a0,a0,402 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204e76:	e4ee                	sd	s11,72(sp)
ffffffffc0204e78:	dcefb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e7c:	00002697          	auipc	a3,0x2
ffffffffc0204e80:	3d468693          	addi	a3,a3,980 # ffffffffc0207250 <etext+0x1a10>
ffffffffc0204e84:	00001617          	auipc	a2,0x1
ffffffffc0204e88:	39c60613          	addi	a2,a2,924 # ffffffffc0206220 <etext+0x9e0>
ffffffffc0204e8c:	2d500593          	li	a1,725
ffffffffc0204e90:	00002517          	auipc	a0,0x2
ffffffffc0204e94:	17050513          	addi	a0,a0,368 # ffffffffc0207000 <etext+0x17c0>
ffffffffc0204e98:	e4ee                	sd	s11,72(sp)
ffffffffc0204e9a:	dacfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204e9e <do_yield>:
    current->need_resched = 1;
ffffffffc0204e9e:	00097797          	auipc	a5,0x97
ffffffffc0204ea2:	8d27b783          	ld	a5,-1838(a5) # ffffffffc029b770 <current>
ffffffffc0204ea6:	4705                	li	a4,1
}
ffffffffc0204ea8:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204eaa:	ef98                	sd	a4,24(a5)
}
ffffffffc0204eac:	8082                	ret

ffffffffc0204eae <do_wait>:
    if (code_store != NULL)
ffffffffc0204eae:	c59d                	beqz	a1,ffffffffc0204edc <do_wait+0x2e>
{
ffffffffc0204eb0:	1101                	addi	sp,sp,-32
ffffffffc0204eb2:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204eb4:	00097517          	auipc	a0,0x97
ffffffffc0204eb8:	8bc53503          	ld	a0,-1860(a0) # ffffffffc029b770 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204ebc:	4685                	li	a3,1
ffffffffc0204ebe:	4611                	li	a2,4
ffffffffc0204ec0:	7508                	ld	a0,40(a0)
{
ffffffffc0204ec2:	ec06                	sd	ra,24(sp)
ffffffffc0204ec4:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204ec6:	ed7fe0ef          	jal	ffffffffc0203d9c <user_mem_check>
ffffffffc0204eca:	6702                	ld	a4,0(sp)
ffffffffc0204ecc:	67a2                	ld	a5,8(sp)
ffffffffc0204ece:	c909                	beqz	a0,ffffffffc0204ee0 <do_wait+0x32>
}
ffffffffc0204ed0:	60e2                	ld	ra,24(sp)
ffffffffc0204ed2:	85be                	mv	a1,a5
ffffffffc0204ed4:	853a                	mv	a0,a4
ffffffffc0204ed6:	6105                	addi	sp,sp,32
ffffffffc0204ed8:	f20ff06f          	j	ffffffffc02045f8 <do_wait.part.0>
ffffffffc0204edc:	f1cff06f          	j	ffffffffc02045f8 <do_wait.part.0>
ffffffffc0204ee0:	60e2                	ld	ra,24(sp)
ffffffffc0204ee2:	5575                	li	a0,-3
ffffffffc0204ee4:	6105                	addi	sp,sp,32
ffffffffc0204ee6:	8082                	ret

ffffffffc0204ee8 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ee8:	6789                	lui	a5,0x2
ffffffffc0204eea:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204eee:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc0204ef0:	06e7e463          	bltu	a5,a4,ffffffffc0204f58 <do_kill+0x70>
{
ffffffffc0204ef4:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ef6:	45a9                	li	a1,10
{
ffffffffc0204ef8:	ec06                	sd	ra,24(sp)
ffffffffc0204efa:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204efc:	484000ef          	jal	ffffffffc0205380 <hash32>
ffffffffc0204f00:	02051793          	slli	a5,a0,0x20
ffffffffc0204f04:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204f08:	00092797          	auipc	a5,0x92
ffffffffc0204f0c:	7e878793          	addi	a5,a5,2024 # ffffffffc02976f0 <hash_list>
ffffffffc0204f10:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204f12:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f14:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f16:	a029                	j	ffffffffc0204f20 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204f18:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204f1c:	00c70963          	beq	a4,a2,ffffffffc0204f2e <do_kill+0x46>
ffffffffc0204f20:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204f22:	fea69be3          	bne	a3,a0,ffffffffc0204f18 <do_kill+0x30>
}
ffffffffc0204f26:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204f28:	5575                	li	a0,-3
}
ffffffffc0204f2a:	6105                	addi	sp,sp,32
ffffffffc0204f2c:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f2e:	fd852703          	lw	a4,-40(a0)
ffffffffc0204f32:	00177693          	andi	a3,a4,1
ffffffffc0204f36:	e29d                	bnez	a3,ffffffffc0204f5c <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f38:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204f3a:	00176713          	ori	a4,a4,1
ffffffffc0204f3e:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f42:	0006c663          	bltz	a3,ffffffffc0204f4e <do_kill+0x66>
            return 0;
ffffffffc0204f46:	4501                	li	a0,0
}
ffffffffc0204f48:	60e2                	ld	ra,24(sp)
ffffffffc0204f4a:	6105                	addi	sp,sp,32
ffffffffc0204f4c:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204f4e:	f2850513          	addi	a0,a0,-216
ffffffffc0204f52:	232000ef          	jal	ffffffffc0205184 <wakeup_proc>
ffffffffc0204f56:	bfc5                	j	ffffffffc0204f46 <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204f58:	5575                	li	a0,-3
}
ffffffffc0204f5a:	8082                	ret
        return -E_KILLED;
ffffffffc0204f5c:	555d                	li	a0,-9
ffffffffc0204f5e:	b7ed                	j	ffffffffc0204f48 <do_kill+0x60>

ffffffffc0204f60 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f60:	1101                	addi	sp,sp,-32
ffffffffc0204f62:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f64:	00096797          	auipc	a5,0x96
ffffffffc0204f68:	78c78793          	addi	a5,a5,1932 # ffffffffc029b6f0 <proc_list>
ffffffffc0204f6c:	ec06                	sd	ra,24(sp)
ffffffffc0204f6e:	e822                	sd	s0,16(sp)
ffffffffc0204f70:	e04a                	sd	s2,0(sp)
ffffffffc0204f72:	00092497          	auipc	s1,0x92
ffffffffc0204f76:	77e48493          	addi	s1,s1,1918 # ffffffffc02976f0 <hash_list>
ffffffffc0204f7a:	e79c                	sd	a5,8(a5)
ffffffffc0204f7c:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f7e:	00096717          	auipc	a4,0x96
ffffffffc0204f82:	77270713          	addi	a4,a4,1906 # ffffffffc029b6f0 <proc_list>
ffffffffc0204f86:	87a6                	mv	a5,s1
ffffffffc0204f88:	e79c                	sd	a5,8(a5)
ffffffffc0204f8a:	e39c                	sd	a5,0(a5)
ffffffffc0204f8c:	07c1                	addi	a5,a5,16
ffffffffc0204f8e:	fee79de3          	bne	a5,a4,ffffffffc0204f88 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f92:	eb7fe0ef          	jal	ffffffffc0203e48 <alloc_proc>
ffffffffc0204f96:	00096917          	auipc	s2,0x96
ffffffffc0204f9a:	7ea90913          	addi	s2,s2,2026 # ffffffffc029b780 <idleproc>
ffffffffc0204f9e:	00a93023          	sd	a0,0(s2)
ffffffffc0204fa2:	10050363          	beqz	a0,ffffffffc02050a8 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204fa6:	4789                	li	a5,2
ffffffffc0204fa8:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204faa:	00003797          	auipc	a5,0x3
ffffffffc0204fae:	05678793          	addi	a5,a5,86 # ffffffffc0208000 <bootstack>
ffffffffc0204fb2:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fb4:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204fb8:	4785                	li	a5,1
ffffffffc0204fba:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fbc:	4641                	li	a2,16
ffffffffc0204fbe:	8522                	mv	a0,s0
ffffffffc0204fc0:	4581                	li	a1,0
ffffffffc0204fc2:	055000ef          	jal	ffffffffc0205816 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fc6:	8522                	mv	a0,s0
ffffffffc0204fc8:	463d                	li	a2,15
ffffffffc0204fca:	00002597          	auipc	a1,0x2
ffffffffc0204fce:	3be58593          	addi	a1,a1,958 # ffffffffc0207388 <etext+0x1b48>
ffffffffc0204fd2:	057000ef          	jal	ffffffffc0205828 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204fd6:	00096797          	auipc	a5,0x96
ffffffffc0204fda:	7927a783          	lw	a5,1938(a5) # ffffffffc029b768 <nr_process>

    current = idleproc;
ffffffffc0204fde:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fe2:	4601                	li	a2,0
    nr_process++;
ffffffffc0204fe4:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fe6:	4581                	li	a1,0
ffffffffc0204fe8:	fffff517          	auipc	a0,0xfffff
ffffffffc0204fec:	7f250513          	addi	a0,a0,2034 # ffffffffc02047da <init_main>
    current = idleproc;
ffffffffc0204ff0:	00096697          	auipc	a3,0x96
ffffffffc0204ff4:	78e6b023          	sd	a4,1920(a3) # ffffffffc029b770 <current>
    nr_process++;
ffffffffc0204ff8:	00096717          	auipc	a4,0x96
ffffffffc0204ffc:	76f72823          	sw	a5,1904(a4) # ffffffffc029b768 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205000:	c64ff0ef          	jal	ffffffffc0204464 <kernel_thread>
ffffffffc0205004:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205006:	08a05563          	blez	a0,ffffffffc0205090 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc020500a:	6789                	lui	a5,0x2
ffffffffc020500c:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc020500e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205012:	02e7e463          	bltu	a5,a4,ffffffffc020503a <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205016:	45a9                	li	a1,10
ffffffffc0205018:	368000ef          	jal	ffffffffc0205380 <hash32>
ffffffffc020501c:	02051713          	slli	a4,a0,0x20
ffffffffc0205020:	01c75793          	srli	a5,a4,0x1c
ffffffffc0205024:	00f486b3          	add	a3,s1,a5
ffffffffc0205028:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020502a:	a029                	j	ffffffffc0205034 <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc020502c:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205030:	04870d63          	beq	a4,s0,ffffffffc020508a <proc_init+0x12a>
    return listelm->next;
ffffffffc0205034:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205036:	fef69be3          	bne	a3,a5,ffffffffc020502c <proc_init+0xcc>
    return NULL;
ffffffffc020503a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020503c:	0b478413          	addi	s0,a5,180
ffffffffc0205040:	4641                	li	a2,16
ffffffffc0205042:	4581                	li	a1,0
ffffffffc0205044:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205046:	00096717          	auipc	a4,0x96
ffffffffc020504a:	72f73923          	sd	a5,1842(a4) # ffffffffc029b778 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020504e:	7c8000ef          	jal	ffffffffc0205816 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205052:	8522                	mv	a0,s0
ffffffffc0205054:	463d                	li	a2,15
ffffffffc0205056:	00002597          	auipc	a1,0x2
ffffffffc020505a:	35a58593          	addi	a1,a1,858 # ffffffffc02073b0 <etext+0x1b70>
ffffffffc020505e:	7ca000ef          	jal	ffffffffc0205828 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205062:	00093783          	ld	a5,0(s2)
ffffffffc0205066:	cfad                	beqz	a5,ffffffffc02050e0 <proc_init+0x180>
ffffffffc0205068:	43dc                	lw	a5,4(a5)
ffffffffc020506a:	ebbd                	bnez	a5,ffffffffc02050e0 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020506c:	00096797          	auipc	a5,0x96
ffffffffc0205070:	70c7b783          	ld	a5,1804(a5) # ffffffffc029b778 <initproc>
ffffffffc0205074:	c7b1                	beqz	a5,ffffffffc02050c0 <proc_init+0x160>
ffffffffc0205076:	43d8                	lw	a4,4(a5)
ffffffffc0205078:	4785                	li	a5,1
ffffffffc020507a:	04f71363          	bne	a4,a5,ffffffffc02050c0 <proc_init+0x160>
}
ffffffffc020507e:	60e2                	ld	ra,24(sp)
ffffffffc0205080:	6442                	ld	s0,16(sp)
ffffffffc0205082:	64a2                	ld	s1,8(sp)
ffffffffc0205084:	6902                	ld	s2,0(sp)
ffffffffc0205086:	6105                	addi	sp,sp,32
ffffffffc0205088:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020508a:	f2878793          	addi	a5,a5,-216
ffffffffc020508e:	b77d                	j	ffffffffc020503c <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0205090:	00002617          	auipc	a2,0x2
ffffffffc0205094:	30060613          	addi	a2,a2,768 # ffffffffc0207390 <etext+0x1b50>
ffffffffc0205098:	3ff00593          	li	a1,1023
ffffffffc020509c:	00002517          	auipc	a0,0x2
ffffffffc02050a0:	f6450513          	addi	a0,a0,-156 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02050a4:	ba2fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02050a8:	00002617          	auipc	a2,0x2
ffffffffc02050ac:	2c860613          	addi	a2,a2,712 # ffffffffc0207370 <etext+0x1b30>
ffffffffc02050b0:	3f000593          	li	a1,1008
ffffffffc02050b4:	00002517          	auipc	a0,0x2
ffffffffc02050b8:	f4c50513          	addi	a0,a0,-180 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02050bc:	b8afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050c0:	00002697          	auipc	a3,0x2
ffffffffc02050c4:	32068693          	addi	a3,a3,800 # ffffffffc02073e0 <etext+0x1ba0>
ffffffffc02050c8:	00001617          	auipc	a2,0x1
ffffffffc02050cc:	15860613          	addi	a2,a2,344 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02050d0:	40600593          	li	a1,1030
ffffffffc02050d4:	00002517          	auipc	a0,0x2
ffffffffc02050d8:	f2c50513          	addi	a0,a0,-212 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02050dc:	b6afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050e0:	00002697          	auipc	a3,0x2
ffffffffc02050e4:	2d868693          	addi	a3,a3,728 # ffffffffc02073b8 <etext+0x1b78>
ffffffffc02050e8:	00001617          	auipc	a2,0x1
ffffffffc02050ec:	13860613          	addi	a2,a2,312 # ffffffffc0206220 <etext+0x9e0>
ffffffffc02050f0:	40500593          	li	a1,1029
ffffffffc02050f4:	00002517          	auipc	a0,0x2
ffffffffc02050f8:	f0c50513          	addi	a0,a0,-244 # ffffffffc0207000 <etext+0x17c0>
ffffffffc02050fc:	b4afb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205100 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205100:	1141                	addi	sp,sp,-16
ffffffffc0205102:	e022                	sd	s0,0(sp)
ffffffffc0205104:	e406                	sd	ra,8(sp)
ffffffffc0205106:	00096417          	auipc	s0,0x96
ffffffffc020510a:	66a40413          	addi	s0,s0,1642 # ffffffffc029b770 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020510e:	6018                	ld	a4,0(s0)
ffffffffc0205110:	6f1c                	ld	a5,24(a4)
ffffffffc0205112:	dffd                	beqz	a5,ffffffffc0205110 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205114:	104000ef          	jal	ffffffffc0205218 <schedule>
ffffffffc0205118:	bfdd                	j	ffffffffc020510e <cpu_idle+0xe>

ffffffffc020511a <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020511a:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020511e:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205122:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205124:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205126:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020512a:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020512e:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205132:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205136:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020513a:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020513e:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205142:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205146:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020514a:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020514e:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205152:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205156:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205158:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020515a:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020515e:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205162:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205166:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020516a:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020516e:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205172:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205176:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020517a:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020517e:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205182:	8082                	ret

ffffffffc0205184 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205184:	4118                	lw	a4,0(a0)
{
ffffffffc0205186:	1101                	addi	sp,sp,-32
ffffffffc0205188:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020518a:	478d                	li	a5,3
ffffffffc020518c:	06f70763          	beq	a4,a5,ffffffffc02051fa <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205190:	100027f3          	csrr	a5,sstatus
ffffffffc0205194:	8b89                	andi	a5,a5,2
ffffffffc0205196:	eb91                	bnez	a5,ffffffffc02051aa <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205198:	4789                	li	a5,2
ffffffffc020519a:	02f70763          	beq	a4,a5,ffffffffc02051c8 <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020519e:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc02051a0:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02051a2:	0e052623          	sw	zero,236(a0)
}
ffffffffc02051a6:	6105                	addi	sp,sp,32
ffffffffc02051a8:	8082                	ret
        intr_disable();
ffffffffc02051aa:	e42a                	sd	a0,8(sp)
ffffffffc02051ac:	f58fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051b0:	6522                	ld	a0,8(sp)
ffffffffc02051b2:	4789                	li	a5,2
ffffffffc02051b4:	4118                	lw	a4,0(a0)
ffffffffc02051b6:	02f70663          	beq	a4,a5,ffffffffc02051e2 <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc02051ba:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02051bc:	0e052623          	sw	zero,236(a0)
}
ffffffffc02051c0:	60e2                	ld	ra,24(sp)
ffffffffc02051c2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051c4:	f3afb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc02051c8:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc02051ca:	00002617          	auipc	a2,0x2
ffffffffc02051ce:	27660613          	addi	a2,a2,630 # ffffffffc0207440 <etext+0x1c00>
ffffffffc02051d2:	45d1                	li	a1,20
ffffffffc02051d4:	00002517          	auipc	a0,0x2
ffffffffc02051d8:	25450513          	addi	a0,a0,596 # ffffffffc0207428 <etext+0x1be8>
}
ffffffffc02051dc:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc02051de:	ad2fb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc02051e2:	00002617          	auipc	a2,0x2
ffffffffc02051e6:	25e60613          	addi	a2,a2,606 # ffffffffc0207440 <etext+0x1c00>
ffffffffc02051ea:	45d1                	li	a1,20
ffffffffc02051ec:	00002517          	auipc	a0,0x2
ffffffffc02051f0:	23c50513          	addi	a0,a0,572 # ffffffffc0207428 <etext+0x1be8>
ffffffffc02051f4:	abcfb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc02051f8:	b7e1                	j	ffffffffc02051c0 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051fa:	00002697          	auipc	a3,0x2
ffffffffc02051fe:	20e68693          	addi	a3,a3,526 # ffffffffc0207408 <etext+0x1bc8>
ffffffffc0205202:	00001617          	auipc	a2,0x1
ffffffffc0205206:	01e60613          	addi	a2,a2,30 # ffffffffc0206220 <etext+0x9e0>
ffffffffc020520a:	45a5                	li	a1,9
ffffffffc020520c:	00002517          	auipc	a0,0x2
ffffffffc0205210:	21c50513          	addi	a0,a0,540 # ffffffffc0207428 <etext+0x1be8>
ffffffffc0205214:	a32fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205218 <schedule>:

void schedule(void)
{
ffffffffc0205218:	1101                	addi	sp,sp,-32
ffffffffc020521a:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020521c:	100027f3          	csrr	a5,sstatus
ffffffffc0205220:	8b89                	andi	a5,a5,2
ffffffffc0205222:	4301                	li	t1,0
ffffffffc0205224:	e3c1                	bnez	a5,ffffffffc02052a4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205226:	00096897          	auipc	a7,0x96
ffffffffc020522a:	54a8b883          	ld	a7,1354(a7) # ffffffffc029b770 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020522e:	00096517          	auipc	a0,0x96
ffffffffc0205232:	55253503          	ld	a0,1362(a0) # ffffffffc029b780 <idleproc>
        current->need_resched = 0;
ffffffffc0205236:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020523a:	04a88f63          	beq	a7,a0,ffffffffc0205298 <schedule+0x80>
ffffffffc020523e:	0c888693          	addi	a3,a7,200
ffffffffc0205242:	00096617          	auipc	a2,0x96
ffffffffc0205246:	4ae60613          	addi	a2,a2,1198 # ffffffffc029b6f0 <proc_list>
        le = last;
ffffffffc020524a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020524c:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc020524e:	4809                	li	a6,2
ffffffffc0205250:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205252:	00c78863          	beq	a5,a2,ffffffffc0205262 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205256:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020525a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc020525e:	03070363          	beq	a4,a6,ffffffffc0205284 <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205262:	fef697e3          	bne	a3,a5,ffffffffc0205250 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205266:	ed99                	bnez	a1,ffffffffc0205284 <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205268:	451c                	lw	a5,8(a0)
ffffffffc020526a:	2785                	addiw	a5,a5,1
ffffffffc020526c:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc020526e:	00a88663          	beq	a7,a0,ffffffffc020527a <schedule+0x62>
ffffffffc0205272:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc0205274:	d49fe0ef          	jal	ffffffffc0203fbc <proc_run>
ffffffffc0205278:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc020527a:	00031b63          	bnez	t1,ffffffffc0205290 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020527e:	60e2                	ld	ra,24(sp)
ffffffffc0205280:	6105                	addi	sp,sp,32
ffffffffc0205282:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205284:	4198                	lw	a4,0(a1)
ffffffffc0205286:	4789                	li	a5,2
ffffffffc0205288:	fef710e3          	bne	a4,a5,ffffffffc0205268 <schedule+0x50>
ffffffffc020528c:	852e                	mv	a0,a1
ffffffffc020528e:	bfe9                	j	ffffffffc0205268 <schedule+0x50>
}
ffffffffc0205290:	60e2                	ld	ra,24(sp)
ffffffffc0205292:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205294:	e6afb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205298:	00096617          	auipc	a2,0x96
ffffffffc020529c:	45860613          	addi	a2,a2,1112 # ffffffffc029b6f0 <proc_list>
ffffffffc02052a0:	86b2                	mv	a3,a2
ffffffffc02052a2:	b765                	j	ffffffffc020524a <schedule+0x32>
        intr_disable();
ffffffffc02052a4:	e60fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02052a8:	4305                	li	t1,1
ffffffffc02052aa:	bfb5                	j	ffffffffc0205226 <schedule+0xe>

ffffffffc02052ac <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052ac:	00096797          	auipc	a5,0x96
ffffffffc02052b0:	4c47b783          	ld	a5,1220(a5) # ffffffffc029b770 <current>
}
ffffffffc02052b4:	43c8                	lw	a0,4(a5)
ffffffffc02052b6:	8082                	ret

ffffffffc02052b8 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052b8:	4501                	li	a0,0
ffffffffc02052ba:	8082                	ret

ffffffffc02052bc <sys_putc>:
    cputchar(c);
ffffffffc02052bc:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052be:	1141                	addi	sp,sp,-16
ffffffffc02052c0:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052c2:	f07fa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc02052c6:	60a2                	ld	ra,8(sp)
ffffffffc02052c8:	4501                	li	a0,0
ffffffffc02052ca:	0141                	addi	sp,sp,16
ffffffffc02052cc:	8082                	ret

ffffffffc02052ce <sys_kill>:
    return do_kill(pid);
ffffffffc02052ce:	4108                	lw	a0,0(a0)
ffffffffc02052d0:	c19ff06f          	j	ffffffffc0204ee8 <do_kill>

ffffffffc02052d4 <sys_yield>:
    return do_yield();
ffffffffc02052d4:	bcbff06f          	j	ffffffffc0204e9e <do_yield>

ffffffffc02052d8 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052d8:	6d14                	ld	a3,24(a0)
ffffffffc02052da:	6910                	ld	a2,16(a0)
ffffffffc02052dc:	650c                	ld	a1,8(a0)
ffffffffc02052de:	6108                	ld	a0,0(a0)
ffffffffc02052e0:	e1eff06f          	j	ffffffffc02048fe <do_execve>

ffffffffc02052e4 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052e4:	650c                	ld	a1,8(a0)
ffffffffc02052e6:	4108                	lw	a0,0(a0)
ffffffffc02052e8:	bc7ff06f          	j	ffffffffc0204eae <do_wait>

ffffffffc02052ec <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052ec:	00096797          	auipc	a5,0x96
ffffffffc02052f0:	4847b783          	ld	a5,1156(a5) # ffffffffc029b770 <current>
    return do_fork(0, stack, tf);
ffffffffc02052f4:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02052f6:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052f8:	6a0c                	ld	a1,16(a2)
ffffffffc02052fa:	d25fe06f          	j	ffffffffc020401e <do_fork>

ffffffffc02052fe <sys_exit>:
    return do_exit(error_code);
ffffffffc02052fe:	4108                	lw	a0,0(a0)
ffffffffc0205300:	9b4ff06f          	j	ffffffffc02044b4 <do_exit>

ffffffffc0205304 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc0205304:	00096697          	auipc	a3,0x96
ffffffffc0205308:	46c6b683          	ld	a3,1132(a3) # ffffffffc029b770 <current>
syscall(void) {
ffffffffc020530c:	715d                	addi	sp,sp,-80
ffffffffc020530e:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205310:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205312:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205314:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205316:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205318:	02d7ec63          	bltu	a5,a3,ffffffffc0205350 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc020531c:	00002797          	auipc	a5,0x2
ffffffffc0205320:	36c78793          	addi	a5,a5,876 # ffffffffc0207688 <syscalls>
ffffffffc0205324:	00369613          	slli	a2,a3,0x3
ffffffffc0205328:	97b2                	add	a5,a5,a2
ffffffffc020532a:	639c                	ld	a5,0(a5)
ffffffffc020532c:	c395                	beqz	a5,ffffffffc0205350 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc020532e:	7028                	ld	a0,96(s0)
ffffffffc0205330:	742c                	ld	a1,104(s0)
ffffffffc0205332:	7830                	ld	a2,112(s0)
ffffffffc0205334:	7c34                	ld	a3,120(s0)
ffffffffc0205336:	6c38                	ld	a4,88(s0)
ffffffffc0205338:	f02a                	sd	a0,32(sp)
ffffffffc020533a:	f42e                	sd	a1,40(sp)
ffffffffc020533c:	f832                	sd	a2,48(sp)
ffffffffc020533e:	fc36                	sd	a3,56(sp)
ffffffffc0205340:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205342:	0828                	addi	a0,sp,24
ffffffffc0205344:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205346:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205348:	e828                	sd	a0,80(s0)
}
ffffffffc020534a:	6406                	ld	s0,64(sp)
ffffffffc020534c:	6161                	addi	sp,sp,80
ffffffffc020534e:	8082                	ret
    print_trapframe(tf);
ffffffffc0205350:	8522                	mv	a0,s0
ffffffffc0205352:	e436                	sd	a3,8(sp)
ffffffffc0205354:	fa0fb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205358:	00096797          	auipc	a5,0x96
ffffffffc020535c:	4187b783          	ld	a5,1048(a5) # ffffffffc029b770 <current>
ffffffffc0205360:	66a2                	ld	a3,8(sp)
ffffffffc0205362:	00002617          	auipc	a2,0x2
ffffffffc0205366:	0fe60613          	addi	a2,a2,254 # ffffffffc0207460 <etext+0x1c20>
ffffffffc020536a:	43d8                	lw	a4,4(a5)
ffffffffc020536c:	06200593          	li	a1,98
ffffffffc0205370:	0b478793          	addi	a5,a5,180
ffffffffc0205374:	00002517          	auipc	a0,0x2
ffffffffc0205378:	11c50513          	addi	a0,a0,284 # ffffffffc0207490 <etext+0x1c50>
ffffffffc020537c:	8cafb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205380 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205380:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205384:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e29>
ffffffffc0205386:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc020538a:	02000513          	li	a0,32
ffffffffc020538e:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205390:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0205394:	8082                	ret

ffffffffc0205396 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205396:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205398:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020539c:	f022                	sd	s0,32(sp)
ffffffffc020539e:	ec26                	sd	s1,24(sp)
ffffffffc02053a0:	e84a                	sd	s2,16(sp)
ffffffffc02053a2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053a4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053a8:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053aa:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053ae:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053b2:	84aa                	mv	s1,a0
ffffffffc02053b4:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02053b6:	03067d63          	bgeu	a2,a6,ffffffffc02053f0 <printnum+0x5a>
ffffffffc02053ba:	e44e                	sd	s3,8(sp)
ffffffffc02053bc:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053be:	4785                	li	a5,1
ffffffffc02053c0:	00e7d763          	bge	a5,a4,ffffffffc02053ce <printnum+0x38>
            putch(padc, putdat);
ffffffffc02053c4:	85ca                	mv	a1,s2
ffffffffc02053c6:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02053c8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053ca:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053cc:	fc65                	bnez	s0,ffffffffc02053c4 <printnum+0x2e>
ffffffffc02053ce:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053d0:	00002797          	auipc	a5,0x2
ffffffffc02053d4:	0d878793          	addi	a5,a5,216 # ffffffffc02074a8 <etext+0x1c68>
ffffffffc02053d8:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053da:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053dc:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02053e0:	70a2                	ld	ra,40(sp)
ffffffffc02053e2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e4:	85ca                	mv	a1,s2
ffffffffc02053e6:	87a6                	mv	a5,s1
}
ffffffffc02053e8:	6942                	ld	s2,16(sp)
ffffffffc02053ea:	64e2                	ld	s1,24(sp)
ffffffffc02053ec:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053ee:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053f0:	03065633          	divu	a2,a2,a6
ffffffffc02053f4:	8722                	mv	a4,s0
ffffffffc02053f6:	fa1ff0ef          	jal	ffffffffc0205396 <printnum>
ffffffffc02053fa:	bfd9                	j	ffffffffc02053d0 <printnum+0x3a>

ffffffffc02053fc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053fc:	7119                	addi	sp,sp,-128
ffffffffc02053fe:	f4a6                	sd	s1,104(sp)
ffffffffc0205400:	f0ca                	sd	s2,96(sp)
ffffffffc0205402:	ecce                	sd	s3,88(sp)
ffffffffc0205404:	e8d2                	sd	s4,80(sp)
ffffffffc0205406:	e4d6                	sd	s5,72(sp)
ffffffffc0205408:	e0da                	sd	s6,64(sp)
ffffffffc020540a:	f862                	sd	s8,48(sp)
ffffffffc020540c:	fc86                	sd	ra,120(sp)
ffffffffc020540e:	f8a2                	sd	s0,112(sp)
ffffffffc0205410:	fc5e                	sd	s7,56(sp)
ffffffffc0205412:	f466                	sd	s9,40(sp)
ffffffffc0205414:	f06a                	sd	s10,32(sp)
ffffffffc0205416:	ec6e                	sd	s11,24(sp)
ffffffffc0205418:	84aa                	mv	s1,a0
ffffffffc020541a:	8c32                	mv	s8,a2
ffffffffc020541c:	8a36                	mv	s4,a3
ffffffffc020541e:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205420:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205424:	05500b13          	li	s6,85
ffffffffc0205428:	00002a97          	auipc	s5,0x2
ffffffffc020542c:	360a8a93          	addi	s5,s5,864 # ffffffffc0207788 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205430:	000c4503          	lbu	a0,0(s8)
ffffffffc0205434:	001c0413          	addi	s0,s8,1
ffffffffc0205438:	01350a63          	beq	a0,s3,ffffffffc020544c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc020543c:	cd0d                	beqz	a0,ffffffffc0205476 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc020543e:	85ca                	mv	a1,s2
ffffffffc0205440:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205442:	00044503          	lbu	a0,0(s0)
ffffffffc0205446:	0405                	addi	s0,s0,1
ffffffffc0205448:	ff351ae3          	bne	a0,s3,ffffffffc020543c <vprintfmt+0x40>
        width = precision = -1;
ffffffffc020544c:	5cfd                	li	s9,-1
ffffffffc020544e:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0205450:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0205454:	4b81                	li	s7,0
ffffffffc0205456:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205458:	00044683          	lbu	a3,0(s0)
ffffffffc020545c:	00140c13          	addi	s8,s0,1
ffffffffc0205460:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0205464:	0ff5f593          	zext.b	a1,a1
ffffffffc0205468:	02bb6663          	bltu	s6,a1,ffffffffc0205494 <vprintfmt+0x98>
ffffffffc020546c:	058a                	slli	a1,a1,0x2
ffffffffc020546e:	95d6                	add	a1,a1,s5
ffffffffc0205470:	4198                	lw	a4,0(a1)
ffffffffc0205472:	9756                	add	a4,a4,s5
ffffffffc0205474:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205476:	70e6                	ld	ra,120(sp)
ffffffffc0205478:	7446                	ld	s0,112(sp)
ffffffffc020547a:	74a6                	ld	s1,104(sp)
ffffffffc020547c:	7906                	ld	s2,96(sp)
ffffffffc020547e:	69e6                	ld	s3,88(sp)
ffffffffc0205480:	6a46                	ld	s4,80(sp)
ffffffffc0205482:	6aa6                	ld	s5,72(sp)
ffffffffc0205484:	6b06                	ld	s6,64(sp)
ffffffffc0205486:	7be2                	ld	s7,56(sp)
ffffffffc0205488:	7c42                	ld	s8,48(sp)
ffffffffc020548a:	7ca2                	ld	s9,40(sp)
ffffffffc020548c:	7d02                	ld	s10,32(sp)
ffffffffc020548e:	6de2                	ld	s11,24(sp)
ffffffffc0205490:	6109                	addi	sp,sp,128
ffffffffc0205492:	8082                	ret
            putch('%', putdat);
ffffffffc0205494:	85ca                	mv	a1,s2
ffffffffc0205496:	02500513          	li	a0,37
ffffffffc020549a:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020549c:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054a0:	02500713          	li	a4,37
ffffffffc02054a4:	8c22                	mv	s8,s0
ffffffffc02054a6:	f8e785e3          	beq	a5,a4,ffffffffc0205430 <vprintfmt+0x34>
ffffffffc02054aa:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02054ae:	1c7d                	addi	s8,s8,-1
ffffffffc02054b0:	fee79de3          	bne	a5,a4,ffffffffc02054aa <vprintfmt+0xae>
ffffffffc02054b4:	bfb5                	j	ffffffffc0205430 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02054b6:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02054ba:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02054bc:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02054c0:	fd06071b          	addiw	a4,a2,-48
ffffffffc02054c4:	24e56a63          	bltu	a0,a4,ffffffffc0205718 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02054c8:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054ca:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02054cc:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02054d0:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054d4:	0197073b          	addw	a4,a4,s9
ffffffffc02054d8:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054dc:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054de:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02054e2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02054e4:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02054e8:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02054ec:	feb570e3          	bgeu	a0,a1,ffffffffc02054cc <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02054f0:	f60d54e3          	bgez	s10,ffffffffc0205458 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02054f4:	8d66                	mv	s10,s9
ffffffffc02054f6:	5cfd                	li	s9,-1
ffffffffc02054f8:	b785                	j	ffffffffc0205458 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054fa:	8db6                	mv	s11,a3
ffffffffc02054fc:	8462                	mv	s0,s8
ffffffffc02054fe:	bfa9                	j	ffffffffc0205458 <vprintfmt+0x5c>
ffffffffc0205500:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0205502:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0205504:	bf91                	j	ffffffffc0205458 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0205506:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205508:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020550c:	00f74463          	blt	a4,a5,ffffffffc0205514 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205510:	1a078763          	beqz	a5,ffffffffc02056be <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205514:	000a3603          	ld	a2,0(s4)
ffffffffc0205518:	46c1                	li	a3,16
ffffffffc020551a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020551c:	000d879b          	sext.w	a5,s11
ffffffffc0205520:	876a                	mv	a4,s10
ffffffffc0205522:	85ca                	mv	a1,s2
ffffffffc0205524:	8526                	mv	a0,s1
ffffffffc0205526:	e71ff0ef          	jal	ffffffffc0205396 <printnum>
            break;
ffffffffc020552a:	b719                	j	ffffffffc0205430 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020552c:	000a2503          	lw	a0,0(s4)
ffffffffc0205530:	85ca                	mv	a1,s2
ffffffffc0205532:	0a21                	addi	s4,s4,8
ffffffffc0205534:	9482                	jalr	s1
            break;
ffffffffc0205536:	bded                	j	ffffffffc0205430 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205538:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020553a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020553e:	00f74463          	blt	a4,a5,ffffffffc0205546 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0205542:	16078963          	beqz	a5,ffffffffc02056b4 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0205546:	000a3603          	ld	a2,0(s4)
ffffffffc020554a:	46a9                	li	a3,10
ffffffffc020554c:	8a2e                	mv	s4,a1
ffffffffc020554e:	b7f9                	j	ffffffffc020551c <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0205550:	85ca                	mv	a1,s2
ffffffffc0205552:	03000513          	li	a0,48
ffffffffc0205556:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0205558:	85ca                	mv	a1,s2
ffffffffc020555a:	07800513          	li	a0,120
ffffffffc020555e:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205560:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0205564:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205566:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205568:	bf55                	j	ffffffffc020551c <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc020556a:	85ca                	mv	a1,s2
ffffffffc020556c:	02500513          	li	a0,37
ffffffffc0205570:	9482                	jalr	s1
            break;
ffffffffc0205572:	bd7d                	j	ffffffffc0205430 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0205574:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205578:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc020557a:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc020557c:	bf95                	j	ffffffffc02054f0 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc020557e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205580:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205584:	00f74463          	blt	a4,a5,ffffffffc020558c <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0205588:	12078163          	beqz	a5,ffffffffc02056aa <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc020558c:	000a3603          	ld	a2,0(s4)
ffffffffc0205590:	46a1                	li	a3,8
ffffffffc0205592:	8a2e                	mv	s4,a1
ffffffffc0205594:	b761                	j	ffffffffc020551c <vprintfmt+0x120>
            if (width < 0)
ffffffffc0205596:	876a                	mv	a4,s10
ffffffffc0205598:	000d5363          	bgez	s10,ffffffffc020559e <vprintfmt+0x1a2>
ffffffffc020559c:	4701                	li	a4,0
ffffffffc020559e:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a2:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02055a4:	bd55                	j	ffffffffc0205458 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc02055a6:	000d841b          	sext.w	s0,s11
ffffffffc02055aa:	fd340793          	addi	a5,s0,-45
ffffffffc02055ae:	00f037b3          	snez	a5,a5
ffffffffc02055b2:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055b6:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02055ba:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055bc:	008a0793          	addi	a5,s4,8
ffffffffc02055c0:	e43e                	sd	a5,8(sp)
ffffffffc02055c2:	100d8c63          	beqz	s11,ffffffffc02056da <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02055c6:	12071363          	bnez	a4,ffffffffc02056ec <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055ca:	000dc783          	lbu	a5,0(s11)
ffffffffc02055ce:	0007851b          	sext.w	a0,a5
ffffffffc02055d2:	c78d                	beqz	a5,ffffffffc02055fc <vprintfmt+0x200>
ffffffffc02055d4:	0d85                	addi	s11,s11,1
ffffffffc02055d6:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055d8:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055dc:	000cc563          	bltz	s9,ffffffffc02055e6 <vprintfmt+0x1ea>
ffffffffc02055e0:	3cfd                	addiw	s9,s9,-1
ffffffffc02055e2:	008c8d63          	beq	s9,s0,ffffffffc02055fc <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055e6:	020b9663          	bnez	s7,ffffffffc0205612 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02055ea:	85ca                	mv	a1,s2
ffffffffc02055ec:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055ee:	000dc783          	lbu	a5,0(s11)
ffffffffc02055f2:	0d85                	addi	s11,s11,1
ffffffffc02055f4:	3d7d                	addiw	s10,s10,-1
ffffffffc02055f6:	0007851b          	sext.w	a0,a5
ffffffffc02055fa:	f3ed                	bnez	a5,ffffffffc02055dc <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02055fc:	01a05963          	blez	s10,ffffffffc020560e <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205600:	85ca                	mv	a1,s2
ffffffffc0205602:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0205606:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205608:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc020560a:	fe0d1be3          	bnez	s10,ffffffffc0205600 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020560e:	6a22                	ld	s4,8(sp)
ffffffffc0205610:	b505                	j	ffffffffc0205430 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205612:	3781                	addiw	a5,a5,-32
ffffffffc0205614:	fcfa7be3          	bgeu	s4,a5,ffffffffc02055ea <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205618:	03f00513          	li	a0,63
ffffffffc020561c:	85ca                	mv	a1,s2
ffffffffc020561e:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205620:	000dc783          	lbu	a5,0(s11)
ffffffffc0205624:	0d85                	addi	s11,s11,1
ffffffffc0205626:	3d7d                	addiw	s10,s10,-1
ffffffffc0205628:	0007851b          	sext.w	a0,a5
ffffffffc020562c:	dbe1                	beqz	a5,ffffffffc02055fc <vprintfmt+0x200>
ffffffffc020562e:	fa0cd9e3          	bgez	s9,ffffffffc02055e0 <vprintfmt+0x1e4>
ffffffffc0205632:	b7c5                	j	ffffffffc0205612 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0205634:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205638:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc020563a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020563c:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205640:	8fb9                	xor	a5,a5,a4
ffffffffc0205642:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205646:	02d64563          	blt	a2,a3,ffffffffc0205670 <vprintfmt+0x274>
ffffffffc020564a:	00002797          	auipc	a5,0x2
ffffffffc020564e:	29678793          	addi	a5,a5,662 # ffffffffc02078e0 <error_string>
ffffffffc0205652:	00369713          	slli	a4,a3,0x3
ffffffffc0205656:	97ba                	add	a5,a5,a4
ffffffffc0205658:	639c                	ld	a5,0(a5)
ffffffffc020565a:	cb99                	beqz	a5,ffffffffc0205670 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc020565c:	86be                	mv	a3,a5
ffffffffc020565e:	00000617          	auipc	a2,0x0
ffffffffc0205662:	20a60613          	addi	a2,a2,522 # ffffffffc0205868 <etext+0x28>
ffffffffc0205666:	85ca                	mv	a1,s2
ffffffffc0205668:	8526                	mv	a0,s1
ffffffffc020566a:	0d8000ef          	jal	ffffffffc0205742 <printfmt>
ffffffffc020566e:	b3c9                	j	ffffffffc0205430 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205670:	00002617          	auipc	a2,0x2
ffffffffc0205674:	e5860613          	addi	a2,a2,-424 # ffffffffc02074c8 <etext+0x1c88>
ffffffffc0205678:	85ca                	mv	a1,s2
ffffffffc020567a:	8526                	mv	a0,s1
ffffffffc020567c:	0c6000ef          	jal	ffffffffc0205742 <printfmt>
ffffffffc0205680:	bb45                	j	ffffffffc0205430 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205682:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205684:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0205688:	00f74363          	blt	a4,a5,ffffffffc020568e <vprintfmt+0x292>
    else if (lflag) {
ffffffffc020568c:	cf81                	beqz	a5,ffffffffc02056a4 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc020568e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205692:	02044b63          	bltz	s0,ffffffffc02056c8 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0205696:	8622                	mv	a2,s0
ffffffffc0205698:	8a5e                	mv	s4,s7
ffffffffc020569a:	46a9                	li	a3,10
ffffffffc020569c:	b541                	j	ffffffffc020551c <vprintfmt+0x120>
            lflag ++;
ffffffffc020569e:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056a0:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02056a2:	bb5d                	j	ffffffffc0205458 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc02056a4:	000a2403          	lw	s0,0(s4)
ffffffffc02056a8:	b7ed                	j	ffffffffc0205692 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02056aa:	000a6603          	lwu	a2,0(s4)
ffffffffc02056ae:	46a1                	li	a3,8
ffffffffc02056b0:	8a2e                	mv	s4,a1
ffffffffc02056b2:	b5ad                	j	ffffffffc020551c <vprintfmt+0x120>
ffffffffc02056b4:	000a6603          	lwu	a2,0(s4)
ffffffffc02056b8:	46a9                	li	a3,10
ffffffffc02056ba:	8a2e                	mv	s4,a1
ffffffffc02056bc:	b585                	j	ffffffffc020551c <vprintfmt+0x120>
ffffffffc02056be:	000a6603          	lwu	a2,0(s4)
ffffffffc02056c2:	46c1                	li	a3,16
ffffffffc02056c4:	8a2e                	mv	s4,a1
ffffffffc02056c6:	bd99                	j	ffffffffc020551c <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02056c8:	85ca                	mv	a1,s2
ffffffffc02056ca:	02d00513          	li	a0,45
ffffffffc02056ce:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02056d0:	40800633          	neg	a2,s0
ffffffffc02056d4:	8a5e                	mv	s4,s7
ffffffffc02056d6:	46a9                	li	a3,10
ffffffffc02056d8:	b591                	j	ffffffffc020551c <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02056da:	e329                	bnez	a4,ffffffffc020571c <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056dc:	02800793          	li	a5,40
ffffffffc02056e0:	853e                	mv	a0,a5
ffffffffc02056e2:	00002d97          	auipc	s11,0x2
ffffffffc02056e6:	ddfd8d93          	addi	s11,s11,-545 # ffffffffc02074c1 <etext+0x1c81>
ffffffffc02056ea:	b5f5                	j	ffffffffc02055d6 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056ec:	85e6                	mv	a1,s9
ffffffffc02056ee:	856e                	mv	a0,s11
ffffffffc02056f0:	08a000ef          	jal	ffffffffc020577a <strnlen>
ffffffffc02056f4:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02056f8:	01a05863          	blez	s10,ffffffffc0205708 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02056fc:	85ca                	mv	a1,s2
ffffffffc02056fe:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205700:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0205702:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205704:	fe0d1ce3          	bnez	s10,ffffffffc02056fc <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205708:	000dc783          	lbu	a5,0(s11)
ffffffffc020570c:	0007851b          	sext.w	a0,a5
ffffffffc0205710:	ec0792e3          	bnez	a5,ffffffffc02055d4 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205714:	6a22                	ld	s4,8(sp)
ffffffffc0205716:	bb29                	j	ffffffffc0205430 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205718:	8462                	mv	s0,s8
ffffffffc020571a:	bbd9                	j	ffffffffc02054f0 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020571c:	85e6                	mv	a1,s9
ffffffffc020571e:	00002517          	auipc	a0,0x2
ffffffffc0205722:	da250513          	addi	a0,a0,-606 # ffffffffc02074c0 <etext+0x1c80>
ffffffffc0205726:	054000ef          	jal	ffffffffc020577a <strnlen>
ffffffffc020572a:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020572e:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0205732:	00002d97          	auipc	s11,0x2
ffffffffc0205736:	d8ed8d93          	addi	s11,s11,-626 # ffffffffc02074c0 <etext+0x1c80>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020573a:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020573c:	fda040e3          	bgtz	s10,ffffffffc02056fc <vprintfmt+0x300>
ffffffffc0205740:	bd51                	j	ffffffffc02055d4 <vprintfmt+0x1d8>

ffffffffc0205742 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205742:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205744:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205748:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020574a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020574c:	ec06                	sd	ra,24(sp)
ffffffffc020574e:	f83a                	sd	a4,48(sp)
ffffffffc0205750:	fc3e                	sd	a5,56(sp)
ffffffffc0205752:	e0c2                	sd	a6,64(sp)
ffffffffc0205754:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205756:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205758:	ca5ff0ef          	jal	ffffffffc02053fc <vprintfmt>
}
ffffffffc020575c:	60e2                	ld	ra,24(sp)
ffffffffc020575e:	6161                	addi	sp,sp,80
ffffffffc0205760:	8082                	ret

ffffffffc0205762 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205762:	00054783          	lbu	a5,0(a0)
ffffffffc0205766:	cb81                	beqz	a5,ffffffffc0205776 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0205768:	4781                	li	a5,0
        cnt ++;
ffffffffc020576a:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc020576c:	00f50733          	add	a4,a0,a5
ffffffffc0205770:	00074703          	lbu	a4,0(a4)
ffffffffc0205774:	fb7d                	bnez	a4,ffffffffc020576a <strlen+0x8>
    }
    return cnt;
}
ffffffffc0205776:	853e                	mv	a0,a5
ffffffffc0205778:	8082                	ret

ffffffffc020577a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020577a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020577c:	e589                	bnez	a1,ffffffffc0205786 <strnlen+0xc>
ffffffffc020577e:	a811                	j	ffffffffc0205792 <strnlen+0x18>
        cnt ++;
ffffffffc0205780:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205782:	00f58863          	beq	a1,a5,ffffffffc0205792 <strnlen+0x18>
ffffffffc0205786:	00f50733          	add	a4,a0,a5
ffffffffc020578a:	00074703          	lbu	a4,0(a4)
ffffffffc020578e:	fb6d                	bnez	a4,ffffffffc0205780 <strnlen+0x6>
ffffffffc0205790:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205792:	852e                	mv	a0,a1
ffffffffc0205794:	8082                	ret

ffffffffc0205796 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205796:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205798:	0005c703          	lbu	a4,0(a1)
ffffffffc020579c:	0585                	addi	a1,a1,1
ffffffffc020579e:	0785                	addi	a5,a5,1
ffffffffc02057a0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057a4:	fb75                	bnez	a4,ffffffffc0205798 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057a6:	8082                	ret

ffffffffc02057a8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057a8:	00054783          	lbu	a5,0(a0)
ffffffffc02057ac:	e791                	bnez	a5,ffffffffc02057b8 <strcmp+0x10>
ffffffffc02057ae:	a01d                	j	ffffffffc02057d4 <strcmp+0x2c>
ffffffffc02057b0:	00054783          	lbu	a5,0(a0)
ffffffffc02057b4:	cb99                	beqz	a5,ffffffffc02057ca <strcmp+0x22>
ffffffffc02057b6:	0585                	addi	a1,a1,1
ffffffffc02057b8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02057bc:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057be:	fef709e3          	beq	a4,a5,ffffffffc02057b0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057c2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057c6:	9d19                	subw	a0,a0,a4
ffffffffc02057c8:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057ca:	0015c703          	lbu	a4,1(a1)
ffffffffc02057ce:	4501                	li	a0,0
}
ffffffffc02057d0:	9d19                	subw	a0,a0,a4
ffffffffc02057d2:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057d4:	0005c703          	lbu	a4,0(a1)
ffffffffc02057d8:	4501                	li	a0,0
ffffffffc02057da:	b7f5                	j	ffffffffc02057c6 <strcmp+0x1e>

ffffffffc02057dc <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057dc:	ce01                	beqz	a2,ffffffffc02057f4 <strncmp+0x18>
ffffffffc02057de:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057e2:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057e4:	cb91                	beqz	a5,ffffffffc02057f8 <strncmp+0x1c>
ffffffffc02057e6:	0005c703          	lbu	a4,0(a1)
ffffffffc02057ea:	00f71763          	bne	a4,a5,ffffffffc02057f8 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02057ee:	0505                	addi	a0,a0,1
ffffffffc02057f0:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057f2:	f675                	bnez	a2,ffffffffc02057de <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057f4:	4501                	li	a0,0
ffffffffc02057f6:	8082                	ret
ffffffffc02057f8:	00054503          	lbu	a0,0(a0)
ffffffffc02057fc:	0005c783          	lbu	a5,0(a1)
ffffffffc0205800:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205802:	8082                	ret

ffffffffc0205804 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205804:	a021                	j	ffffffffc020580c <strchr+0x8>
        if (*s == c) {
ffffffffc0205806:	00f58763          	beq	a1,a5,ffffffffc0205814 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc020580a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020580c:	00054783          	lbu	a5,0(a0)
ffffffffc0205810:	fbfd                	bnez	a5,ffffffffc0205806 <strchr+0x2>
    }
    return NULL;
ffffffffc0205812:	4501                	li	a0,0
}
ffffffffc0205814:	8082                	ret

ffffffffc0205816 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205816:	ca01                	beqz	a2,ffffffffc0205826 <memset+0x10>
ffffffffc0205818:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020581a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020581c:	0785                	addi	a5,a5,1
ffffffffc020581e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205822:	fef61de3          	bne	a2,a5,ffffffffc020581c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205826:	8082                	ret

ffffffffc0205828 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205828:	ca19                	beqz	a2,ffffffffc020583e <memcpy+0x16>
ffffffffc020582a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020582c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020582e:	0005c703          	lbu	a4,0(a1)
ffffffffc0205832:	0585                	addi	a1,a1,1
ffffffffc0205834:	0785                	addi	a5,a5,1
ffffffffc0205836:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020583a:	feb61ae3          	bne	a2,a1,ffffffffc020582e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020583e:	8082                	ret
