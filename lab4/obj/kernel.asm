
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

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
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49e60613          	addi	a2,a2,1182 # ffffffffc020d4f0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0207ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	613030ef          	jal	ffffffffc0203e74 <memset>
    dtb_init();
ffffffffc0200066:	4c2000ef          	jal	ffffffffc0200528 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	44c000ef          	jal	ffffffffc02004b6 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e5a58593          	addi	a1,a1,-422 # ffffffffc0203ec8 <etext+0x6>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e7250513          	addi	a0,a0,-398 # ffffffffc0203ee8 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	158000ef          	jal	ffffffffc02001da <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0d0020ef          	jal	ffffffffc0202156 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	7f0000ef          	jal	ffffffffc020087a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	7ee000ef          	jal	ffffffffc020087c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	641020ef          	jal	ffffffffc0202ed2 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	5a6030ef          	jal	ffffffffc020363c <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	3ca000ef          	jal	ffffffffc0200464 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	7d0000ef          	jal	ffffffffc020086e <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7f2030ef          	jal	ffffffffc0203894 <cpu_idle>

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
ffffffffc02000b6:	00004517          	auipc	a0,0x4
ffffffffc02000ba:	e3a50513          	addi	a0,a0,-454 # ffffffffc0203ef0 <etext+0x2e>
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
ffffffffc02000c6:	00009997          	auipc	s3,0x9
ffffffffc02000ca:	f6a98993          	addi	s3,s3,-150 # ffffffffc0209030 <buf>
        c = getchar();
ffffffffc02000ce:	0fc000ef          	jal	ffffffffc02001ca <getchar>
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
ffffffffc02000fc:	0ce000ef          	jal	ffffffffc02001ca <getchar>
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
ffffffffc0200140:	00009517          	auipc	a0,0x9
ffffffffc0200144:	ef050513          	addi	a0,a0,-272 # ffffffffc0209030 <buf>
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
ffffffffc0200162:	356000ef          	jal	ffffffffc02004b8 <cons_putc>
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
ffffffffc0200188:	0d3030ef          	jal	ffffffffc0203a5a <vprintfmt>
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
ffffffffc02001bc:	09f030ef          	jal	ffffffffc0203a5a <vprintfmt>
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
ffffffffc02001c8:	acc5                	j	ffffffffc02004b8 <cons_putc>

ffffffffc02001ca <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001ca:	1141                	addi	sp,sp,-16
ffffffffc02001cc:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ce:	31e000ef          	jal	ffffffffc02004ec <cons_getc>
ffffffffc02001d2:	dd75                	beqz	a0,ffffffffc02001ce <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	0141                	addi	sp,sp,16
ffffffffc02001d8:	8082                	ret

ffffffffc02001da <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00004517          	auipc	a0,0x4
ffffffffc02001e0:	d1c50513          	addi	a0,a0,-740 # ffffffffc0203ef8 <etext+0x36>
{
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	fafff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6058593          	addi	a1,a1,-416 # ffffffffc020004a <kern_init>
ffffffffc02001f2:	00004517          	auipc	a0,0x4
ffffffffc02001f6:	d2650513          	addi	a0,a0,-730 # ffffffffc0203f18 <etext+0x56>
ffffffffc02001fa:	f9bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fe:	00004597          	auipc	a1,0x4
ffffffffc0200202:	cc458593          	addi	a1,a1,-828 # ffffffffc0203ec2 <etext>
ffffffffc0200206:	00004517          	auipc	a0,0x4
ffffffffc020020a:	d3250513          	addi	a0,a0,-718 # ffffffffc0203f38 <etext+0x76>
ffffffffc020020e:	f87ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200212:	00009597          	auipc	a1,0x9
ffffffffc0200216:	e1e58593          	addi	a1,a1,-482 # ffffffffc0209030 <buf>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0203f58 <etext+0x96>
ffffffffc0200222:	f73ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200226:	0000d597          	auipc	a1,0xd
ffffffffc020022a:	2ca58593          	addi	a1,a1,714 # ffffffffc020d4f0 <end>
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	d4a50513          	addi	a0,a0,-694 # ffffffffc0203f78 <etext+0xb6>
ffffffffc0200236:	f5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	00000717          	auipc	a4,0x0
ffffffffc020023e:	e1070713          	addi	a4,a4,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	0000d797          	auipc	a5,0xd
ffffffffc0200246:	6ad78793          	addi	a5,a5,1709 # ffffffffc020d8ef <end+0x3ff>
ffffffffc020024a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200250:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200252:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200256:	95be                	add	a1,a1,a5
ffffffffc0200258:	85a9                	srai	a1,a1,0xa
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0203f98 <etext+0xd6>
}
ffffffffc0200262:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200264:	bf05                	j	ffffffffc0200194 <cprintf>

ffffffffc0200266 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00004617          	auipc	a2,0x4
ffffffffc020026c:	d6060613          	addi	a2,a2,-672 # ffffffffc0203fc8 <etext+0x106>
ffffffffc0200270:	04900593          	li	a1,73
ffffffffc0200274:	00004517          	auipc	a0,0x4
ffffffffc0200278:	d6c50513          	addi	a0,a0,-660 # ffffffffc0203fe0 <etext+0x11e>
{
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	188000ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1101                	addi	sp,sp,-32
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	e426                	sd	s1,8(sp)
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	00005417          	auipc	s0,0x5
ffffffffc020028e:	50e40413          	addi	s0,s0,1294 # ffffffffc0205798 <commands>
ffffffffc0200292:	00005497          	auipc	s1,0x5
ffffffffc0200296:	54e48493          	addi	s1,s1,1358 # ffffffffc02057e0 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029a:	6410                	ld	a2,8(s0)
ffffffffc020029c:	600c                	ld	a1,0(s0)
ffffffffc020029e:	00004517          	auipc	a0,0x4
ffffffffc02002a2:	d5a50513          	addi	a0,a0,-678 # ffffffffc0203ff8 <etext+0x136>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002a6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a8:	eedff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ac:	fe9417e3          	bne	s0,s1,ffffffffc020029a <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002b0:	60e2                	ld	ra,24(sp)
ffffffffc02002b2:	6442                	ld	s0,16(sp)
ffffffffc02002b4:	64a2                	ld	s1,8(sp)
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	6105                	addi	sp,sp,32
ffffffffc02002ba:	8082                	ret

ffffffffc02002bc <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002bc:	1141                	addi	sp,sp,-16
ffffffffc02002be:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c0:	f1bff0ef          	jal	ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002c4:	60a2                	ld	ra,8(sp)
ffffffffc02002c6:	4501                	li	a0,0
ffffffffc02002c8:	0141                	addi	sp,sp,16
ffffffffc02002ca:	8082                	ret

ffffffffc02002cc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	1141                	addi	sp,sp,-16
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d0:	f97ff0ef          	jal	ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002d4:	60a2                	ld	ra,8(sp)
ffffffffc02002d6:	4501                	li	a0,0
ffffffffc02002d8:	0141                	addi	sp,sp,16
ffffffffc02002da:	8082                	ret

ffffffffc02002dc <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002dc:	7131                	addi	sp,sp,-192
ffffffffc02002de:	e952                	sd	s4,144(sp)
ffffffffc02002e0:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e2:	00004517          	auipc	a0,0x4
ffffffffc02002e6:	d2650513          	addi	a0,a0,-730 # ffffffffc0204008 <etext+0x146>
kmonitor(struct trapframe *tf) {
ffffffffc02002ea:	fd06                	sd	ra,184(sp)
ffffffffc02002ec:	f922                	sd	s0,176(sp)
ffffffffc02002ee:	f526                	sd	s1,168(sp)
ffffffffc02002f0:	f14a                	sd	s2,160(sp)
ffffffffc02002f2:	e556                	sd	s5,136(sp)
ffffffffc02002f4:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f6:	e9fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002fa:	00004517          	auipc	a0,0x4
ffffffffc02002fe:	d3650513          	addi	a0,a0,-714 # ffffffffc0204030 <etext+0x16e>
ffffffffc0200302:	e93ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc0200306:	000a0563          	beqz	s4,ffffffffc0200310 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020030a:	8552                	mv	a0,s4
ffffffffc020030c:	758000ef          	jal	ffffffffc0200a64 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200310:	4501                	li	a0,0
ffffffffc0200312:	4581                	li	a1,0
ffffffffc0200314:	4601                	li	a2,0
ffffffffc0200316:	48a1                	li	a7,8
ffffffffc0200318:	00000073          	ecall
ffffffffc020031c:	00005a97          	auipc	s5,0x5
ffffffffc0200320:	47ca8a93          	addi	s5,s5,1148 # ffffffffc0205798 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200324:	493d                	li	s2,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200326:	00004517          	auipc	a0,0x4
ffffffffc020032a:	d3250513          	addi	a0,a0,-718 # ffffffffc0204058 <etext+0x196>
ffffffffc020032e:	d79ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200332:	842a                	mv	s0,a0
ffffffffc0200334:	d96d                	beqz	a0,ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200336:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020033a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	e99d                	bnez	a1,ffffffffc0200372 <kmonitor+0x96>
    int argc = 0;
ffffffffc020033e:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200340:	fe0b03e3          	beqz	s6,ffffffffc0200326 <kmonitor+0x4a>
ffffffffc0200344:	00005497          	auipc	s1,0x5
ffffffffc0200348:	45448493          	addi	s1,s1,1108 # ffffffffc0205798 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034e:	6582                	ld	a1,0(sp)
ffffffffc0200350:	6088                	ld	a0,0(s1)
ffffffffc0200352:	2b5030ef          	jal	ffffffffc0203e06 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200358:	c149                	beqz	a0,ffffffffc02003da <kmonitor+0xfe>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	2405                	addiw	s0,s0,1
ffffffffc020035c:	04e1                	addi	s1,s1,24
ffffffffc020035e:	fef418e3          	bne	s0,a5,ffffffffc020034e <kmonitor+0x72>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200362:	6582                	ld	a1,0(sp)
ffffffffc0200364:	00004517          	auipc	a0,0x4
ffffffffc0200368:	d2450513          	addi	a0,a0,-732 # ffffffffc0204088 <etext+0x1c6>
ffffffffc020036c:	e29ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200370:	bf5d                	j	ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	00004517          	auipc	a0,0x4
ffffffffc0200376:	cee50513          	addi	a0,a0,-786 # ffffffffc0204060 <etext+0x19e>
ffffffffc020037a:	2e9030ef          	jal	ffffffffc0203e62 <strchr>
ffffffffc020037e:	c901                	beqz	a0,ffffffffc020038e <kmonitor+0xb2>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200384:	00040023          	sb	zero,0(s0)
ffffffffc0200388:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	d9d5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc020038c:	b7dd                	j	ffffffffc0200372 <kmonitor+0x96>
        if (*buf == '\0') {
ffffffffc020038e:	00044783          	lbu	a5,0(s0)
ffffffffc0200392:	d7d5                	beqz	a5,ffffffffc020033e <kmonitor+0x62>
        if (argc == MAXARGS - 1) {
ffffffffc0200394:	03248b63          	beq	s1,s2,ffffffffc02003ca <kmonitor+0xee>
        argv[argc ++] = buf;
ffffffffc0200398:	00349793          	slli	a5,s1,0x3
ffffffffc020039c:	978a                	add	a5,a5,sp
ffffffffc020039e:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a4:	2485                	addiw	s1,s1,1
ffffffffc02003a6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a8:	e591                	bnez	a1,ffffffffc02003b4 <kmonitor+0xd8>
ffffffffc02003aa:	bf59                	j	ffffffffc0200340 <kmonitor+0x64>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b2:	d5d1                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003b4:	00004517          	auipc	a0,0x4
ffffffffc02003b8:	cac50513          	addi	a0,a0,-852 # ffffffffc0204060 <etext+0x19e>
ffffffffc02003bc:	2a7030ef          	jal	ffffffffc0203e62 <strchr>
ffffffffc02003c0:	d575                	beqz	a0,ffffffffc02003ac <kmonitor+0xd0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c2:	00044583          	lbu	a1,0(s0)
ffffffffc02003c6:	dda5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003c8:	b76d                	j	ffffffffc0200372 <kmonitor+0x96>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ca:	45c1                	li	a1,16
ffffffffc02003cc:	00004517          	auipc	a0,0x4
ffffffffc02003d0:	c9c50513          	addi	a0,a0,-868 # ffffffffc0204068 <etext+0x1a6>
ffffffffc02003d4:	dc1ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02003d8:	b7c1                	j	ffffffffc0200398 <kmonitor+0xbc>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003da:	00141793          	slli	a5,s0,0x1
ffffffffc02003de:	97a2                	add	a5,a5,s0
ffffffffc02003e0:	078e                	slli	a5,a5,0x3
ffffffffc02003e2:	97d6                	add	a5,a5,s5
ffffffffc02003e4:	6b9c                	ld	a5,16(a5)
ffffffffc02003e6:	fffb051b          	addiw	a0,s6,-1
ffffffffc02003ea:	8652                	mv	a2,s4
ffffffffc02003ec:	002c                	addi	a1,sp,8
ffffffffc02003ee:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f0:	f2055be3          	bgez	a0,ffffffffc0200326 <kmonitor+0x4a>
}
ffffffffc02003f4:	70ea                	ld	ra,184(sp)
ffffffffc02003f6:	744a                	ld	s0,176(sp)
ffffffffc02003f8:	74aa                	ld	s1,168(sp)
ffffffffc02003fa:	790a                	ld	s2,160(sp)
ffffffffc02003fc:	6a4a                	ld	s4,144(sp)
ffffffffc02003fe:	6aaa                	ld	s5,136(sp)
ffffffffc0200400:	6b0a                	ld	s6,128(sp)
ffffffffc0200402:	6129                	addi	sp,sp,192
ffffffffc0200404:	8082                	ret

ffffffffc0200406 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200406:	0000d317          	auipc	t1,0xd
ffffffffc020040a:	06232303          	lw	t1,98(t1) # ffffffffc020d468 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020040e:	715d                	addi	sp,sp,-80
ffffffffc0200410:	ec06                	sd	ra,24(sp)
ffffffffc0200412:	f436                	sd	a3,40(sp)
ffffffffc0200414:	f83a                	sd	a4,48(sp)
ffffffffc0200416:	fc3e                	sd	a5,56(sp)
ffffffffc0200418:	e0c2                	sd	a6,64(sp)
ffffffffc020041a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020041c:	02031e63          	bnez	t1,ffffffffc0200458 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200420:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200422:	103c                	addi	a5,sp,40
ffffffffc0200424:	e822                	sd	s0,16(sp)
ffffffffc0200426:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200428:	862e                	mv	a2,a1
ffffffffc020042a:	85aa                	mv	a1,a0
ffffffffc020042c:	00004517          	auipc	a0,0x4
ffffffffc0200430:	d0450513          	addi	a0,a0,-764 # ffffffffc0204130 <etext+0x26e>
    is_panic = 1;
ffffffffc0200434:	0000d697          	auipc	a3,0xd
ffffffffc0200438:	02e6aa23          	sw	a4,52(a3) # ffffffffc020d468 <is_panic>
    va_start(ap, fmt);
ffffffffc020043c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020043e:	d57ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200442:	65a2                	ld	a1,8(sp)
ffffffffc0200444:	8522                	mv	a0,s0
ffffffffc0200446:	d2fff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020044a:	00004517          	auipc	a0,0x4
ffffffffc020044e:	d0650513          	addi	a0,a0,-762 # ffffffffc0204150 <etext+0x28e>
ffffffffc0200452:	d43ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200456:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200458:	41c000ef          	jal	ffffffffc0200874 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020045c:	4501                	li	a0,0
ffffffffc020045e:	e7fff0ef          	jal	ffffffffc02002dc <kmonitor>
    while (1) {
ffffffffc0200462:	bfed                	j	ffffffffc020045c <__panic+0x56>

ffffffffc0200464 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	0000d717          	auipc	a4,0xd
ffffffffc020046e:	00f73323          	sd	a5,6(a4) # ffffffffc020d470 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200472:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200476:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200478:	953e                	add	a0,a0,a5
ffffffffc020047a:	4601                	li	a2,0
ffffffffc020047c:	4881                	li	a7,0
ffffffffc020047e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200482:	02000793          	li	a5,32
ffffffffc0200486:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00004517          	auipc	a0,0x4
ffffffffc020048e:	cce50513          	addi	a0,a0,-818 # ffffffffc0204158 <etext+0x296>
    ticks = 0;
ffffffffc0200492:	0000d797          	auipc	a5,0xd
ffffffffc0200496:	fe07b323          	sd	zero,-26(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020049a:	b9ed                	j	ffffffffc0200194 <cprintf>

ffffffffc020049c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a0:	0000d797          	auipc	a5,0xd
ffffffffc02004a4:	fd07b783          	ld	a5,-48(a5) # ffffffffc020d470 <timebase>
ffffffffc02004a8:	4581                	li	a1,0
ffffffffc02004aa:	4601                	li	a2,0
ffffffffc02004ac:	953e                	add	a0,a0,a5
ffffffffc02004ae:	4881                	li	a7,0
ffffffffc02004b0:	00000073          	ecall
ffffffffc02004b4:	8082                	ret

ffffffffc02004b6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004b6:	8082                	ret

ffffffffc02004b8 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b8:	100027f3          	csrr	a5,sstatus
ffffffffc02004bc:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004be:	0ff57513          	zext.b	a0,a0
ffffffffc02004c2:	e799                	bnez	a5,ffffffffc02004d0 <cons_putc+0x18>
ffffffffc02004c4:	4581                	li	a1,0
ffffffffc02004c6:	4601                	li	a2,0
ffffffffc02004c8:	4885                	li	a7,1
ffffffffc02004ca:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02004ce:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02004d0:	1101                	addi	sp,sp,-32
ffffffffc02004d2:	ec06                	sd	ra,24(sp)
ffffffffc02004d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02004d6:	39e000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02004da:	6522                	ld	a0,8(sp)
ffffffffc02004dc:	4581                	li	a1,0
ffffffffc02004de:	4601                	li	a2,0
ffffffffc02004e0:	4885                	li	a7,1
ffffffffc02004e2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004e6:	60e2                	ld	ra,24(sp)
ffffffffc02004e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004ea:	a651                	j	ffffffffc020086e <intr_enable>

ffffffffc02004ec <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ec:	100027f3          	csrr	a5,sstatus
ffffffffc02004f0:	8b89                	andi	a5,a5,2
ffffffffc02004f2:	eb89                	bnez	a5,ffffffffc0200504 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004f4:	4501                	li	a0,0
ffffffffc02004f6:	4581                	li	a1,0
ffffffffc02004f8:	4601                	li	a2,0
ffffffffc02004fa:	4889                	li	a7,2
ffffffffc02004fc:	00000073          	ecall
ffffffffc0200500:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200502:	8082                	ret
int cons_getc(void) {
ffffffffc0200504:	1101                	addi	sp,sp,-32
ffffffffc0200506:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200508:	36c000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020050c:	4501                	li	a0,0
ffffffffc020050e:	4581                	li	a1,0
ffffffffc0200510:	4601                	li	a2,0
ffffffffc0200512:	4889                	li	a7,2
ffffffffc0200514:	00000073          	ecall
ffffffffc0200518:	2501                	sext.w	a0,a0
ffffffffc020051a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020051c:	352000ef          	jal	ffffffffc020086e <intr_enable>
}
ffffffffc0200520:	60e2                	ld	ra,24(sp)
ffffffffc0200522:	6522                	ld	a0,8(sp)
ffffffffc0200524:	6105                	addi	sp,sp,32
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200528:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020052a:	00004517          	auipc	a0,0x4
ffffffffc020052e:	c4e50513          	addi	a0,a0,-946 # ffffffffc0204178 <etext+0x2b6>
void dtb_init(void) {
ffffffffc0200532:	f406                	sd	ra,40(sp)
ffffffffc0200534:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200536:	c5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020053a:	00009597          	auipc	a1,0x9
ffffffffc020053e:	ac65b583          	ld	a1,-1338(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200542:	00004517          	auipc	a0,0x4
ffffffffc0200546:	c4650513          	addi	a0,a0,-954 # ffffffffc0204188 <etext+0x2c6>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020054a:	00009417          	auipc	s0,0x9
ffffffffc020054e:	abe40413          	addi	s0,s0,-1346 # ffffffffc0209008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200552:	c43ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200556:	600c                	ld	a1,0(s0)
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	c4050513          	addi	a0,a0,-960 # ffffffffc0204198 <etext+0x2d6>
ffffffffc0200560:	c35ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200564:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	c4a50513          	addi	a0,a0,-950 # ffffffffc02041b0 <etext+0x2ee>
    if (boot_dtb == 0) {
ffffffffc020056e:	10070163          	beqz	a4,ffffffffc0200670 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200572:	57f5                	li	a5,-3
ffffffffc0200574:	07fa                	slli	a5,a5,0x1e
ffffffffc0200576:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200578:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020057a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020057e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed29fd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200586:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200592:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200596:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	8e49                	or	a2,a2,a0
ffffffffc020059a:	0ff7f793          	zext.b	a5,a5
ffffffffc020059e:	8dd1                	or	a1,a1,a2
ffffffffc02005a0:	07a2                	slli	a5,a5,0x8
ffffffffc02005a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02005a8:	0cd59863          	bne	a1,a3,ffffffffc0200678 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02005ac:	4710                	lw	a2,8(a4)
ffffffffc02005ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02005b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02005be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02005c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02005ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02005da:	01c56533          	or	a0,a0,t3
ffffffffc02005de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02005f2:	8c49                	or	s0,s0,a0
ffffffffc02005f4:	0622                	slli	a2,a2,0x8
ffffffffc02005f6:	8fcd                	or	a5,a5,a1
ffffffffc02005f8:	06a2                	slli	a3,a3,0x8
ffffffffc02005fa:	8c51                	or	s0,s0,a2
ffffffffc02005fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200600:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200602:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200604:	9381                	srli	a5,a5,0x20
ffffffffc0200606:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200608:	4301                	li	t1,0
        switch (token) {
ffffffffc020060a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020060c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020060e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200612:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200614:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200616:	0087579b          	srliw	a5,a4,0x8
ffffffffc020061a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200626:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062e:	8ed1                	or	a3,a3,a2
ffffffffc0200630:	0ff77713          	zext.b	a4,a4
ffffffffc0200634:	8fd5                	or	a5,a5,a3
ffffffffc0200636:	0722                	slli	a4,a4,0x8
ffffffffc0200638:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020063a:	05178763          	beq	a5,a7,ffffffffc0200688 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200640:	00f8e963          	bltu	a7,a5,ffffffffc0200652 <dtb_init+0x12a>
ffffffffc0200644:	07c78d63          	beq	a5,t3,ffffffffc02006be <dtb_init+0x196>
ffffffffc0200648:	4709                	li	a4,2
ffffffffc020064a:	00e79763          	bne	a5,a4,ffffffffc0200658 <dtb_init+0x130>
ffffffffc020064e:	4301                	li	t1,0
ffffffffc0200650:	b7d1                	j	ffffffffc0200614 <dtb_init+0xec>
ffffffffc0200652:	4711                	li	a4,4
ffffffffc0200654:	fce780e3          	beq	a5,a4,ffffffffc0200614 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200658:	00004517          	auipc	a0,0x4
ffffffffc020065c:	c2050513          	addi	a0,a0,-992 # ffffffffc0204278 <etext+0x3b6>
ffffffffc0200660:	b35ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200664:	64e2                	ld	s1,24(sp)
ffffffffc0200666:	6942                	ld	s2,16(sp)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	c4850513          	addi	a0,a0,-952 # ffffffffc02042b0 <etext+0x3ee>
}
ffffffffc0200670:	7402                	ld	s0,32(sp)
ffffffffc0200672:	70a2                	ld	ra,40(sp)
ffffffffc0200674:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200676:	be39                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200678:	7402                	ld	s0,32(sp)
ffffffffc020067a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	00004517          	auipc	a0,0x4
ffffffffc0200680:	b5450513          	addi	a0,a0,-1196 # ffffffffc02041d0 <etext+0x30e>
}
ffffffffc0200684:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	b639                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200688:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020068e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200692:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200696:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	8ed1                	or	a3,a3,a2
ffffffffc02006a4:	0ff77713          	zext.b	a4,a4
ffffffffc02006a8:	8fd5                	or	a5,a5,a3
ffffffffc02006aa:	0722                	slli	a4,a4,0x8
ffffffffc02006ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	04031463          	bnez	t1,ffffffffc02006f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006b2:	1782                	slli	a5,a5,0x20
ffffffffc02006b4:	9381                	srli	a5,a5,0x20
ffffffffc02006b6:	043d                	addi	s0,s0,15
ffffffffc02006b8:	943e                	add	s0,s0,a5
ffffffffc02006ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02006bc:	bfa1                	j	ffffffffc0200614 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02006be:	8522                	mv	a0,s0
ffffffffc02006c0:	e01a                	sd	t1,0(sp)
ffffffffc02006c2:	6fe030ef          	jal	ffffffffc0203dc0 <strlen>
ffffffffc02006c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006c8:	4619                	li	a2,6
ffffffffc02006ca:	8522                	mv	a0,s0
ffffffffc02006cc:	00004597          	auipc	a1,0x4
ffffffffc02006d0:	b2c58593          	addi	a1,a1,-1236 # ffffffffc02041f8 <etext+0x336>
ffffffffc02006d4:	766030ef          	jal	ffffffffc0203e3a <strncmp>
ffffffffc02006d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006da:	0411                	addi	s0,s0,4
ffffffffc02006dc:	0004879b          	sext.w	a5,s1
ffffffffc02006e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02006ec:	00ff0837          	lui	a6,0xff0
ffffffffc02006f0:	488d                	li	a7,3
ffffffffc02006f2:	4e05                	li	t3,1
ffffffffc02006f4:	b705                	j	ffffffffc0200614 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	b0858593          	addi	a1,a1,-1272 # ffffffffc0204200 <etext+0x33e>
ffffffffc0200700:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020070e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071a:	8ed1                	or	a3,a3,a2
ffffffffc020071c:	0ff77713          	zext.b	a4,a4
ffffffffc0200720:	0722                	slli	a4,a4,0x8
ffffffffc0200722:	8d55                	or	a0,a0,a3
ffffffffc0200724:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200726:	1502                	slli	a0,a0,0x20
ffffffffc0200728:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020072a:	954a                	add	a0,a0,s2
ffffffffc020072c:	e01a                	sd	t1,0(sp)
ffffffffc020072e:	6d8030ef          	jal	ffffffffc0203e06 <strcmp>
ffffffffc0200732:	67a2                	ld	a5,8(sp)
ffffffffc0200734:	473d                	li	a4,15
ffffffffc0200736:	6302                	ld	t1,0(sp)
ffffffffc0200738:	00ff0837          	lui	a6,0xff0
ffffffffc020073c:	488d                	li	a7,3
ffffffffc020073e:	4e05                	li	t3,1
ffffffffc0200740:	f6f779e3          	bgeu	a4,a5,ffffffffc02006b2 <dtb_init+0x18a>
ffffffffc0200744:	f53d                	bnez	a0,ffffffffc02006b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200746:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020074a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020074e:	00004517          	auipc	a0,0x4
ffffffffc0200752:	aba50513          	addi	a0,a0,-1350 # ffffffffc0204208 <etext+0x346>
           fdt32_to_cpu(x >> 32);
ffffffffc0200756:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020075e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200762:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020076e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200772:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200776:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077e:	01037333          	and	t1,t1,a6
ffffffffc0200782:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200786:	01e5e5b3          	or	a1,a1,t5
ffffffffc020078a:	0ff7f793          	zext.b	a5,a5
ffffffffc020078e:	01de6e33          	or	t3,t3,t4
ffffffffc0200792:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200796:	01067633          	and	a2,a2,a6
ffffffffc020079a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020079e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	07a2                	slli	a5,a5,0x8
ffffffffc02007a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02007a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02007ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02007b0:	8ddd                	or	a1,a1,a5
ffffffffc02007b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02007ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d6:	08a2                	slli	a7,a7,0x8
ffffffffc02007d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02007e4:	01de6833          	or	a6,t3,t4
ffffffffc02007e8:	0ff77713          	zext.b	a4,a4
ffffffffc02007ec:	01166633          	or	a2,a2,a7
ffffffffc02007f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02007f4:	06a2                	slli	a3,a3,0x8
ffffffffc02007f6:	01046433          	or	s0,s0,a6
ffffffffc02007fa:	0722                	slli	a4,a4,0x8
ffffffffc02007fc:	8fd5                	or	a5,a5,a3
ffffffffc02007fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200800:	1582                	slli	a1,a1,0x20
ffffffffc0200802:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200804:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	9201                	srli	a2,a2,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020080a:	1402                	slli	s0,s0,0x20
ffffffffc020080c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200810:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200812:	983ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200816:	85a6                	mv	a1,s1
ffffffffc0200818:	00004517          	auipc	a0,0x4
ffffffffc020081c:	a1050513          	addi	a0,a0,-1520 # ffffffffc0204228 <etext+0x366>
ffffffffc0200820:	975ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200824:	01445613          	srli	a2,s0,0x14
ffffffffc0200828:	85a2                	mv	a1,s0
ffffffffc020082a:	00004517          	auipc	a0,0x4
ffffffffc020082e:	a1650513          	addi	a0,a0,-1514 # ffffffffc0204240 <etext+0x37e>
ffffffffc0200832:	963ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200836:	009405b3          	add	a1,s0,s1
ffffffffc020083a:	15fd                	addi	a1,a1,-1
ffffffffc020083c:	00004517          	auipc	a0,0x4
ffffffffc0200840:	a2450513          	addi	a0,a0,-1500 # ffffffffc0204260 <etext+0x39e>
ffffffffc0200844:	951ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc0200848:	0000d797          	auipc	a5,0xd
ffffffffc020084c:	c497b023          	sd	s1,-960(a5) # ffffffffc020d488 <memory_base>
        memory_size = mem_size;
ffffffffc0200850:	0000d797          	auipc	a5,0xd
ffffffffc0200854:	c287b823          	sd	s0,-976(a5) # ffffffffc020d480 <memory_size>
ffffffffc0200858:	b531                	j	ffffffffc0200664 <dtb_init+0x13c>

ffffffffc020085a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020085a:	0000d517          	auipc	a0,0xd
ffffffffc020085e:	c2e53503          	ld	a0,-978(a0) # ffffffffc020d488 <memory_base>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200864:	0000d517          	auipc	a0,0xd
ffffffffc0200868:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d480 <memory_size>
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200874:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200878:	8082                	ret

ffffffffc020087a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020087a:	8082                	ret

ffffffffc020087c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200880:	00000797          	auipc	a5,0x0
ffffffffc0200884:	3fc78793          	addi	a5,a5,1020 # ffffffffc0200c7c <__alltraps>
ffffffffc0200888:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020088c:	000407b7          	lui	a5,0x40
ffffffffc0200890:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200894:	8082                	ret

ffffffffc0200896 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200896:	610c                	ld	a1,0(a0)
{
ffffffffc0200898:	1141                	addi	sp,sp,-16
ffffffffc020089a:	e022                	sd	s0,0(sp)
ffffffffc020089c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020089e:	00004517          	auipc	a0,0x4
ffffffffc02008a2:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02042c8 <etext+0x406>
{
ffffffffc02008a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a8:	8edff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008ac:	640c                	ld	a1,8(s0)
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	a3250513          	addi	a0,a0,-1486 # ffffffffc02042e0 <etext+0x41e>
ffffffffc02008b6:	8dfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008ba:	680c                	ld	a1,16(s0)
ffffffffc02008bc:	00004517          	auipc	a0,0x4
ffffffffc02008c0:	a3c50513          	addi	a0,a0,-1476 # ffffffffc02042f8 <etext+0x436>
ffffffffc02008c4:	8d1ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008c8:	6c0c                	ld	a1,24(s0)
ffffffffc02008ca:	00004517          	auipc	a0,0x4
ffffffffc02008ce:	a4650513          	addi	a0,a0,-1466 # ffffffffc0204310 <etext+0x44e>
ffffffffc02008d2:	8c3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008d6:	700c                	ld	a1,32(s0)
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204328 <etext+0x466>
ffffffffc02008e0:	8b5ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008e4:	740c                	ld	a1,40(s0)
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0204340 <etext+0x47e>
ffffffffc02008ee:	8a7ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008f2:	780c                	ld	a1,48(s0)
ffffffffc02008f4:	00004517          	auipc	a0,0x4
ffffffffc02008f8:	a6450513          	addi	a0,a0,-1436 # ffffffffc0204358 <etext+0x496>
ffffffffc02008fc:	899ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200900:	7c0c                	ld	a1,56(s0)
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0204370 <etext+0x4ae>
ffffffffc020090a:	88bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020090e:	602c                	ld	a1,64(s0)
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	a7850513          	addi	a0,a0,-1416 # ffffffffc0204388 <etext+0x4c6>
ffffffffc0200918:	87dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020091c:	642c                	ld	a1,72(s0)
ffffffffc020091e:	00004517          	auipc	a0,0x4
ffffffffc0200922:	a8250513          	addi	a0,a0,-1406 # ffffffffc02043a0 <etext+0x4de>
ffffffffc0200926:	86fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020092a:	682c                	ld	a1,80(s0)
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	a8c50513          	addi	a0,a0,-1396 # ffffffffc02043b8 <etext+0x4f6>
ffffffffc0200934:	861ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200938:	6c2c                	ld	a1,88(s0)
ffffffffc020093a:	00004517          	auipc	a0,0x4
ffffffffc020093e:	a9650513          	addi	a0,a0,-1386 # ffffffffc02043d0 <etext+0x50e>
ffffffffc0200942:	853ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200946:	702c                	ld	a1,96(s0)
ffffffffc0200948:	00004517          	auipc	a0,0x4
ffffffffc020094c:	aa050513          	addi	a0,a0,-1376 # ffffffffc02043e8 <etext+0x526>
ffffffffc0200950:	845ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200954:	742c                	ld	a1,104(s0)
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0204400 <etext+0x53e>
ffffffffc020095e:	837ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200962:	782c                	ld	a1,112(s0)
ffffffffc0200964:	00004517          	auipc	a0,0x4
ffffffffc0200968:	ab450513          	addi	a0,a0,-1356 # ffffffffc0204418 <etext+0x556>
ffffffffc020096c:	829ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200970:	7c2c                	ld	a1,120(s0)
ffffffffc0200972:	00004517          	auipc	a0,0x4
ffffffffc0200976:	abe50513          	addi	a0,a0,-1346 # ffffffffc0204430 <etext+0x56e>
ffffffffc020097a:	81bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020097e:	604c                	ld	a1,128(s0)
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	ac850513          	addi	a0,a0,-1336 # ffffffffc0204448 <etext+0x586>
ffffffffc0200988:	80dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020098c:	644c                	ld	a1,136(s0)
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	ad250513          	addi	a0,a0,-1326 # ffffffffc0204460 <etext+0x59e>
ffffffffc0200996:	ffeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020099a:	684c                	ld	a1,144(s0)
ffffffffc020099c:	00004517          	auipc	a0,0x4
ffffffffc02009a0:	adc50513          	addi	a0,a0,-1316 # ffffffffc0204478 <etext+0x5b6>
ffffffffc02009a4:	ff0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009a8:	6c4c                	ld	a1,152(s0)
ffffffffc02009aa:	00004517          	auipc	a0,0x4
ffffffffc02009ae:	ae650513          	addi	a0,a0,-1306 # ffffffffc0204490 <etext+0x5ce>
ffffffffc02009b2:	fe2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009b6:	704c                	ld	a1,160(s0)
ffffffffc02009b8:	00004517          	auipc	a0,0x4
ffffffffc02009bc:	af050513          	addi	a0,a0,-1296 # ffffffffc02044a8 <etext+0x5e6>
ffffffffc02009c0:	fd4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009c4:	744c                	ld	a1,168(s0)
ffffffffc02009c6:	00004517          	auipc	a0,0x4
ffffffffc02009ca:	afa50513          	addi	a0,a0,-1286 # ffffffffc02044c0 <etext+0x5fe>
ffffffffc02009ce:	fc6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009d2:	784c                	ld	a1,176(s0)
ffffffffc02009d4:	00004517          	auipc	a0,0x4
ffffffffc02009d8:	b0450513          	addi	a0,a0,-1276 # ffffffffc02044d8 <etext+0x616>
ffffffffc02009dc:	fb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009e0:	7c4c                	ld	a1,184(s0)
ffffffffc02009e2:	00004517          	auipc	a0,0x4
ffffffffc02009e6:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02044f0 <etext+0x62e>
ffffffffc02009ea:	faaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ee:	606c                	ld	a1,192(s0)
ffffffffc02009f0:	00004517          	auipc	a0,0x4
ffffffffc02009f4:	b1850513          	addi	a0,a0,-1256 # ffffffffc0204508 <etext+0x646>
ffffffffc02009f8:	f9cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009fc:	646c                	ld	a1,200(s0)
ffffffffc02009fe:	00004517          	auipc	a0,0x4
ffffffffc0200a02:	b2250513          	addi	a0,a0,-1246 # ffffffffc0204520 <etext+0x65e>
ffffffffc0200a06:	f8eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a0a:	686c                	ld	a1,208(s0)
ffffffffc0200a0c:	00004517          	auipc	a0,0x4
ffffffffc0200a10:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0204538 <etext+0x676>
ffffffffc0200a14:	f80ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a18:	6c6c                	ld	a1,216(s0)
ffffffffc0200a1a:	00004517          	auipc	a0,0x4
ffffffffc0200a1e:	b3650513          	addi	a0,a0,-1226 # ffffffffc0204550 <etext+0x68e>
ffffffffc0200a22:	f72ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a26:	706c                	ld	a1,224(s0)
ffffffffc0200a28:	00004517          	auipc	a0,0x4
ffffffffc0200a2c:	b4050513          	addi	a0,a0,-1216 # ffffffffc0204568 <etext+0x6a6>
ffffffffc0200a30:	f64ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a34:	746c                	ld	a1,232(s0)
ffffffffc0200a36:	00004517          	auipc	a0,0x4
ffffffffc0200a3a:	b4a50513          	addi	a0,a0,-1206 # ffffffffc0204580 <etext+0x6be>
ffffffffc0200a3e:	f56ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a42:	786c                	ld	a1,240(s0)
ffffffffc0200a44:	00004517          	auipc	a0,0x4
ffffffffc0200a48:	b5450513          	addi	a0,a0,-1196 # ffffffffc0204598 <etext+0x6d6>
ffffffffc0200a4c:	f48ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a50:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a52:	6402                	ld	s0,0(sp)
ffffffffc0200a54:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a56:	00004517          	auipc	a0,0x4
ffffffffc0200a5a:	b5a50513          	addi	a0,a0,-1190 # ffffffffc02045b0 <etext+0x6ee>
}
ffffffffc0200a5e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a60:	f34ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200a64 <print_trapframe>:
{
ffffffffc0200a64:	1141                	addi	sp,sp,-16
ffffffffc0200a66:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a68:	85aa                	mv	a1,a0
{
ffffffffc0200a6a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6c:	00004517          	auipc	a0,0x4
ffffffffc0200a70:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02045c8 <etext+0x706>
{
ffffffffc0200a74:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a76:	f1eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a7a:	8522                	mv	a0,s0
ffffffffc0200a7c:	e1bff0ef          	jal	ffffffffc0200896 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a80:	10043583          	ld	a1,256(s0)
ffffffffc0200a84:	00004517          	auipc	a0,0x4
ffffffffc0200a88:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02045e0 <etext+0x71e>
ffffffffc0200a8c:	f08ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a90:	10843583          	ld	a1,264(s0)
ffffffffc0200a94:	00004517          	auipc	a0,0x4
ffffffffc0200a98:	b6450513          	addi	a0,a0,-1180 # ffffffffc02045f8 <etext+0x736>
ffffffffc0200a9c:	ef8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200aa0:	11043583          	ld	a1,272(s0)
ffffffffc0200aa4:	00004517          	auipc	a0,0x4
ffffffffc0200aa8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204610 <etext+0x74e>
ffffffffc0200aac:	ee8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200ab4:	6402                	ld	s0,0(sp)
ffffffffc0200ab6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab8:	00004517          	auipc	a0,0x4
ffffffffc0200abc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204628 <etext+0x766>
}
ffffffffc0200ac0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ac2:	ed2ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ac6 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200ac6:	11853783          	ld	a5,280(a0)
ffffffffc0200aca:	472d                	li	a4,11
ffffffffc0200acc:	0786                	slli	a5,a5,0x1
ffffffffc0200ace:	8385                	srli	a5,a5,0x1
ffffffffc0200ad0:	08f76d63          	bltu	a4,a5,ffffffffc0200b6a <interrupt_handler+0xa4>
ffffffffc0200ad4:	00005717          	auipc	a4,0x5
ffffffffc0200ad8:	d0c70713          	addi	a4,a4,-756 # ffffffffc02057e0 <commands+0x48>
ffffffffc0200adc:	078a                	slli	a5,a5,0x2
ffffffffc0200ade:	97ba                	add	a5,a5,a4
ffffffffc0200ae0:	439c                	lw	a5,0(a5)
ffffffffc0200ae2:	97ba                	add	a5,a5,a4
ffffffffc0200ae4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ae6:	00004517          	auipc	a0,0x4
ffffffffc0200aea:	bba50513          	addi	a0,a0,-1094 # ffffffffc02046a0 <etext+0x7de>
ffffffffc0200aee:	ea6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0204680 <etext+0x7be>
ffffffffc0200afa:	e9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200afe:	00004517          	auipc	a0,0x4
ffffffffc0200b02:	b4250513          	addi	a0,a0,-1214 # ffffffffc0204640 <etext+0x77e>
ffffffffc0200b06:	e8eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	b5650513          	addi	a0,a0,-1194 # ffffffffc0204660 <etext+0x79e>
ffffffffc0200b12:	e82ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200b16:	1141                	addi	sp,sp,-16
ffffffffc0200b18:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event(); // (1) 设置下一次时钟中断
ffffffffc0200b1a:	983ff0ef          	jal	ffffffffc020049c <clock_set_next_event>
        ticks++;                // (2) 计数器加一
ffffffffc0200b1e:	0000d797          	auipc	a5,0xd
ffffffffc0200b22:	95a78793          	addi	a5,a5,-1702 # ffffffffc020d478 <ticks>
ffffffffc0200b26:	6394                	ld	a3,0(a5)
        if (ticks % TICK_NUM == 0) 
ffffffffc0200b28:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200b2c:	28f70713          	addi	a4,a4,655 # 28f5c28f <kern_entry-0xffffffff972a3d71>
        ticks++;                // (2) 计数器加一
ffffffffc0200b30:	0685                	addi	a3,a3,1
ffffffffc0200b32:	e394                	sd	a3,0(a5)
        if (ticks % TICK_NUM == 0) 
ffffffffc0200b34:	6390                	ld	a2,0(a5)
ffffffffc0200b36:	5c28f6b7          	lui	a3,0x5c28f
ffffffffc0200b3a:	1702                	slli	a4,a4,0x20
ffffffffc0200b3c:	5c368693          	addi	a3,a3,1475 # 5c28f5c3 <kern_entry-0xffffffff63f70a3d>
ffffffffc0200b40:	00265793          	srli	a5,a2,0x2
ffffffffc0200b44:	9736                	add	a4,a4,a3
ffffffffc0200b46:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200b4a:	06400593          	li	a1,100
ffffffffc0200b4e:	8389                	srli	a5,a5,0x2
ffffffffc0200b50:	02b787b3          	mul	a5,a5,a1
ffffffffc0200b54:	00f60c63          	beq	a2,a5,ffffffffc0200b6c <interrupt_handler+0xa6>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b58:	60a2                	ld	ra,8(sp)
ffffffffc0200b5a:	0141                	addi	sp,sp,16
ffffffffc0200b5c:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b5e:	00004517          	auipc	a0,0x4
ffffffffc0200b62:	b7250513          	addi	a0,a0,-1166 # ffffffffc02046d0 <etext+0x80e>
ffffffffc0200b66:	e2eff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200b6a:	bded                	j	ffffffffc0200a64 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b6c:	00004517          	auipc	a0,0x4
ffffffffc0200b70:	b5450513          	addi	a0,a0,-1196 # ffffffffc02046c0 <etext+0x7fe>
ffffffffc0200b74:	e20ff0ef          	jal	ffffffffc0200194 <cprintf>
            print_counts++;     // (4) 打印次数加一
ffffffffc0200b78:	0000d797          	auipc	a5,0xd
ffffffffc0200b7c:	9187a783          	lw	a5,-1768(a5) # ffffffffc020d490 <print_counts>
            if (print_counts == 10)
ffffffffc0200b80:	4729                	li	a4,10
            print_counts++;     // (4) 打印次数加一
ffffffffc0200b82:	2785                	addiw	a5,a5,1
ffffffffc0200b84:	0000d697          	auipc	a3,0xd
ffffffffc0200b88:	90f6a623          	sw	a5,-1780(a3) # ffffffffc020d490 <print_counts>
            if (print_counts == 10)
ffffffffc0200b8c:	fce796e3          	bne	a5,a4,ffffffffc0200b58 <interrupt_handler+0x92>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200b90:	4501                	li	a0,0
ffffffffc0200b92:	4581                	li	a1,0
ffffffffc0200b94:	4601                	li	a2,0
ffffffffc0200b96:	48a1                	li	a7,8
ffffffffc0200b98:	00000073          	ecall
}
ffffffffc0200b9c:	bf75                	j	ffffffffc0200b58 <interrupt_handler+0x92>

ffffffffc0200b9e <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200b9e:	11853783          	ld	a5,280(a0)
ffffffffc0200ba2:	473d                	li	a4,15
ffffffffc0200ba4:	0cf76563          	bltu	a4,a5,ffffffffc0200c6e <exception_handler+0xd0>
ffffffffc0200ba8:	00005717          	auipc	a4,0x5
ffffffffc0200bac:	c6870713          	addi	a4,a4,-920 # ffffffffc0205810 <commands+0x78>
ffffffffc0200bb0:	078a                	slli	a5,a5,0x2
ffffffffc0200bb2:	97ba                	add	a5,a5,a4
ffffffffc0200bb4:	439c                	lw	a5,0(a5)
ffffffffc0200bb6:	97ba                	add	a5,a5,a4
ffffffffc0200bb8:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	cb650513          	addi	a0,a0,-842 # ffffffffc0204870 <etext+0x9ae>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	b2a50513          	addi	a0,a0,-1238 # ffffffffc02046f0 <etext+0x82e>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200bd2:	00004517          	auipc	a0,0x4
ffffffffc0200bd6:	b3e50513          	addi	a0,a0,-1218 # ffffffffc0204710 <etext+0x84e>
ffffffffc0200bda:	dbaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200bde:	00004517          	auipc	a0,0x4
ffffffffc0200be2:	b5250513          	addi	a0,a0,-1198 # ffffffffc0204730 <etext+0x86e>
ffffffffc0200be6:	daeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200bea:	00004517          	auipc	a0,0x4
ffffffffc0200bee:	b5e50513          	addi	a0,a0,-1186 # ffffffffc0204748 <etext+0x886>
ffffffffc0200bf2:	da2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200bf6:	00004517          	auipc	a0,0x4
ffffffffc0200bfa:	b6250513          	addi	a0,a0,-1182 # ffffffffc0204758 <etext+0x896>
ffffffffc0200bfe:	d96ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200c02:	00004517          	auipc	a0,0x4
ffffffffc0200c06:	b7650513          	addi	a0,a0,-1162 # ffffffffc0204778 <etext+0x8b6>
ffffffffc0200c0a:	d8aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200c0e:	00004517          	auipc	a0,0x4
ffffffffc0200c12:	b8250513          	addi	a0,a0,-1150 # ffffffffc0204790 <etext+0x8ce>
ffffffffc0200c16:	d7eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c1a:	00004517          	auipc	a0,0x4
ffffffffc0200c1e:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02047a8 <etext+0x8e6>
ffffffffc0200c22:	d72ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c26:	00004517          	auipc	a0,0x4
ffffffffc0200c2a:	b9a50513          	addi	a0,a0,-1126 # ffffffffc02047c0 <etext+0x8fe>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c32:	00004517          	auipc	a0,0x4
ffffffffc0200c36:	bae50513          	addi	a0,a0,-1106 # ffffffffc02047e0 <etext+0x91e>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c3e:	00004517          	auipc	a0,0x4
ffffffffc0200c42:	bc250513          	addi	a0,a0,-1086 # ffffffffc0204800 <etext+0x93e>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c4a:	00004517          	auipc	a0,0x4
ffffffffc0200c4e:	bd650513          	addi	a0,a0,-1066 # ffffffffc0204820 <etext+0x95e>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200c56:	00004517          	auipc	a0,0x4
ffffffffc0200c5a:	bea50513          	addi	a0,a0,-1046 # ffffffffc0204840 <etext+0x97e>
ffffffffc0200c5e:	d36ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200c62:	00004517          	auipc	a0,0x4
ffffffffc0200c66:	bf650513          	addi	a0,a0,-1034 # ffffffffc0204858 <etext+0x996>
ffffffffc0200c6a:	d2aff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200c6e:	bbdd                	j	ffffffffc0200a64 <print_trapframe>

ffffffffc0200c70 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c70:	11853783          	ld	a5,280(a0)
ffffffffc0200c74:	0007c363          	bltz	a5,ffffffffc0200c7a <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c78:	b71d                	j	ffffffffc0200b9e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c7a:	b5b1                	j	ffffffffc0200ac6 <interrupt_handler>

ffffffffc0200c7c <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c7c:	14011073          	csrw	sscratch,sp
ffffffffc0200c80:	712d                	addi	sp,sp,-288
ffffffffc0200c82:	e406                	sd	ra,8(sp)
ffffffffc0200c84:	ec0e                	sd	gp,24(sp)
ffffffffc0200c86:	f012                	sd	tp,32(sp)
ffffffffc0200c88:	f416                	sd	t0,40(sp)
ffffffffc0200c8a:	f81a                	sd	t1,48(sp)
ffffffffc0200c8c:	fc1e                	sd	t2,56(sp)
ffffffffc0200c8e:	e0a2                	sd	s0,64(sp)
ffffffffc0200c90:	e4a6                	sd	s1,72(sp)
ffffffffc0200c92:	e8aa                	sd	a0,80(sp)
ffffffffc0200c94:	ecae                	sd	a1,88(sp)
ffffffffc0200c96:	f0b2                	sd	a2,96(sp)
ffffffffc0200c98:	f4b6                	sd	a3,104(sp)
ffffffffc0200c9a:	f8ba                	sd	a4,112(sp)
ffffffffc0200c9c:	fcbe                	sd	a5,120(sp)
ffffffffc0200c9e:	e142                	sd	a6,128(sp)
ffffffffc0200ca0:	e546                	sd	a7,136(sp)
ffffffffc0200ca2:	e94a                	sd	s2,144(sp)
ffffffffc0200ca4:	ed4e                	sd	s3,152(sp)
ffffffffc0200ca6:	f152                	sd	s4,160(sp)
ffffffffc0200ca8:	f556                	sd	s5,168(sp)
ffffffffc0200caa:	f95a                	sd	s6,176(sp)
ffffffffc0200cac:	fd5e                	sd	s7,184(sp)
ffffffffc0200cae:	e1e2                	sd	s8,192(sp)
ffffffffc0200cb0:	e5e6                	sd	s9,200(sp)
ffffffffc0200cb2:	e9ea                	sd	s10,208(sp)
ffffffffc0200cb4:	edee                	sd	s11,216(sp)
ffffffffc0200cb6:	f1f2                	sd	t3,224(sp)
ffffffffc0200cb8:	f5f6                	sd	t4,232(sp)
ffffffffc0200cba:	f9fa                	sd	t5,240(sp)
ffffffffc0200cbc:	fdfe                	sd	t6,248(sp)
ffffffffc0200cbe:	14002473          	csrr	s0,sscratch
ffffffffc0200cc2:	100024f3          	csrr	s1,sstatus
ffffffffc0200cc6:	14102973          	csrr	s2,sepc
ffffffffc0200cca:	143029f3          	csrr	s3,stval
ffffffffc0200cce:	14202a73          	csrr	s4,scause
ffffffffc0200cd2:	e822                	sd	s0,16(sp)
ffffffffc0200cd4:	e226                	sd	s1,256(sp)
ffffffffc0200cd6:	e64a                	sd	s2,264(sp)
ffffffffc0200cd8:	ea4e                	sd	s3,272(sp)
ffffffffc0200cda:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200cdc:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cde:	f93ff0ef          	jal	ffffffffc0200c70 <trap>

ffffffffc0200ce2 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ce2:	6492                	ld	s1,256(sp)
ffffffffc0200ce4:	6932                	ld	s2,264(sp)
ffffffffc0200ce6:	10049073          	csrw	sstatus,s1
ffffffffc0200cea:	14191073          	csrw	sepc,s2
ffffffffc0200cee:	60a2                	ld	ra,8(sp)
ffffffffc0200cf0:	61e2                	ld	gp,24(sp)
ffffffffc0200cf2:	7202                	ld	tp,32(sp)
ffffffffc0200cf4:	72a2                	ld	t0,40(sp)
ffffffffc0200cf6:	7342                	ld	t1,48(sp)
ffffffffc0200cf8:	73e2                	ld	t2,56(sp)
ffffffffc0200cfa:	6406                	ld	s0,64(sp)
ffffffffc0200cfc:	64a6                	ld	s1,72(sp)
ffffffffc0200cfe:	6546                	ld	a0,80(sp)
ffffffffc0200d00:	65e6                	ld	a1,88(sp)
ffffffffc0200d02:	7606                	ld	a2,96(sp)
ffffffffc0200d04:	76a6                	ld	a3,104(sp)
ffffffffc0200d06:	7746                	ld	a4,112(sp)
ffffffffc0200d08:	77e6                	ld	a5,120(sp)
ffffffffc0200d0a:	680a                	ld	a6,128(sp)
ffffffffc0200d0c:	68aa                	ld	a7,136(sp)
ffffffffc0200d0e:	694a                	ld	s2,144(sp)
ffffffffc0200d10:	69ea                	ld	s3,152(sp)
ffffffffc0200d12:	7a0a                	ld	s4,160(sp)
ffffffffc0200d14:	7aaa                	ld	s5,168(sp)
ffffffffc0200d16:	7b4a                	ld	s6,176(sp)
ffffffffc0200d18:	7bea                	ld	s7,184(sp)
ffffffffc0200d1a:	6c0e                	ld	s8,192(sp)
ffffffffc0200d1c:	6cae                	ld	s9,200(sp)
ffffffffc0200d1e:	6d4e                	ld	s10,208(sp)
ffffffffc0200d20:	6dee                	ld	s11,216(sp)
ffffffffc0200d22:	7e0e                	ld	t3,224(sp)
ffffffffc0200d24:	7eae                	ld	t4,232(sp)
ffffffffc0200d26:	7f4e                	ld	t5,240(sp)
ffffffffc0200d28:	7fee                	ld	t6,248(sp)
ffffffffc0200d2a:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d2c:	10200073          	sret

ffffffffc0200d30 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d30:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d32:	bf45                	j	ffffffffc0200ce2 <__trapret>
ffffffffc0200d34:	0001                	nop

ffffffffc0200d36 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d36:	00008797          	auipc	a5,0x8
ffffffffc0200d3a:	6fa78793          	addi	a5,a5,1786 # ffffffffc0209430 <free_area>
ffffffffc0200d3e:	e79c                	sd	a5,8(a5)
ffffffffc0200d40:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d42:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d46:	8082                	ret

ffffffffc0200d48 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d48:	00008517          	auipc	a0,0x8
ffffffffc0200d4c:	6f856503          	lwu	a0,1784(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200d50:	8082                	ret

ffffffffc0200d52 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d52:	711d                	addi	sp,sp,-96
ffffffffc0200d54:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d56:	00008917          	auipc	s2,0x8
ffffffffc0200d5a:	6da90913          	addi	s2,s2,1754 # ffffffffc0209430 <free_area>
ffffffffc0200d5e:	00893783          	ld	a5,8(s2)
ffffffffc0200d62:	ec86                	sd	ra,88(sp)
ffffffffc0200d64:	e8a2                	sd	s0,80(sp)
ffffffffc0200d66:	e4a6                	sd	s1,72(sp)
ffffffffc0200d68:	fc4e                	sd	s3,56(sp)
ffffffffc0200d6a:	f852                	sd	s4,48(sp)
ffffffffc0200d6c:	f456                	sd	s5,40(sp)
ffffffffc0200d6e:	f05a                	sd	s6,32(sp)
ffffffffc0200d70:	ec5e                	sd	s7,24(sp)
ffffffffc0200d72:	e862                	sd	s8,16(sp)
ffffffffc0200d74:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d76:	2f278763          	beq	a5,s2,ffffffffc0201064 <default_check+0x312>
    int count = 0, total = 0;
ffffffffc0200d7a:	4401                	li	s0,0
ffffffffc0200d7c:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d7e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d82:	8b09                	andi	a4,a4,2
ffffffffc0200d84:	2e070463          	beqz	a4,ffffffffc020106c <default_check+0x31a>
        count ++, total += p->property;
ffffffffc0200d88:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d8c:	679c                	ld	a5,8(a5)
ffffffffc0200d8e:	2485                	addiw	s1,s1,1
ffffffffc0200d90:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d92:	ff2796e3          	bne	a5,s2,ffffffffc0200d7e <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200d96:	89a2                	mv	s3,s0
ffffffffc0200d98:	745000ef          	jal	ffffffffc0201cdc <nr_free_pages>
ffffffffc0200d9c:	73351863          	bne	a0,s3,ffffffffc02014cc <default_check+0x77a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200da0:	4505                	li	a0,1
ffffffffc0200da2:	6c9000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200da6:	8a2a                	mv	s4,a0
ffffffffc0200da8:	46050263          	beqz	a0,ffffffffc020120c <default_check+0x4ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dac:	4505                	li	a0,1
ffffffffc0200dae:	6bd000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200db2:	89aa                	mv	s3,a0
ffffffffc0200db4:	72050c63          	beqz	a0,ffffffffc02014ec <default_check+0x79a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200db8:	4505                	li	a0,1
ffffffffc0200dba:	6b1000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200dbe:	8aaa                	mv	s5,a0
ffffffffc0200dc0:	4c050663          	beqz	a0,ffffffffc020128c <default_check+0x53a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dc4:	40aa07b3          	sub	a5,s4,a0
ffffffffc0200dc8:	40a98733          	sub	a4,s3,a0
ffffffffc0200dcc:	0017b793          	seqz	a5,a5
ffffffffc0200dd0:	00173713          	seqz	a4,a4
ffffffffc0200dd4:	8fd9                	or	a5,a5,a4
ffffffffc0200dd6:	30079b63          	bnez	a5,ffffffffc02010ec <default_check+0x39a>
ffffffffc0200dda:	313a0963          	beq	s4,s3,ffffffffc02010ec <default_check+0x39a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dde:	000a2783          	lw	a5,0(s4)
ffffffffc0200de2:	2a079563          	bnez	a5,ffffffffc020108c <default_check+0x33a>
ffffffffc0200de6:	0009a783          	lw	a5,0(s3)
ffffffffc0200dea:	2a079163          	bnez	a5,ffffffffc020108c <default_check+0x33a>
ffffffffc0200dee:	411c                	lw	a5,0(a0)
ffffffffc0200df0:	28079e63          	bnez	a5,ffffffffc020108c <default_check+0x33a>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200df4:	0000c797          	auipc	a5,0xc
ffffffffc0200df8:	6d47b783          	ld	a5,1748(a5) # ffffffffc020d4c8 <pages>
ffffffffc0200dfc:	00005617          	auipc	a2,0x5
ffffffffc0200e00:	c1c63603          	ld	a2,-996(a2) # ffffffffc0205a18 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e04:	0000c697          	auipc	a3,0xc
ffffffffc0200e08:	6bc6b683          	ld	a3,1724(a3) # ffffffffc020d4c0 <npage>
ffffffffc0200e0c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e10:	8719                	srai	a4,a4,0x6
ffffffffc0200e12:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e14:	0732                	slli	a4,a4,0xc
ffffffffc0200e16:	06b2                	slli	a3,a3,0xc
ffffffffc0200e18:	2ad77a63          	bgeu	a4,a3,ffffffffc02010cc <default_check+0x37a>
    return page - pages + nbase;
ffffffffc0200e1c:	40f98733          	sub	a4,s3,a5
ffffffffc0200e20:	8719                	srai	a4,a4,0x6
ffffffffc0200e22:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e24:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e26:	4ed77363          	bgeu	a4,a3,ffffffffc020130c <default_check+0x5ba>
    return page - pages + nbase;
ffffffffc0200e2a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e2e:	8799                	srai	a5,a5,0x6
ffffffffc0200e30:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e32:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e34:	32d7fc63          	bgeu	a5,a3,ffffffffc020116c <default_check+0x41a>
    assert(alloc_page() == NULL);
ffffffffc0200e38:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e3a:	00093c03          	ld	s8,0(s2)
ffffffffc0200e3e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e42:	00008b17          	auipc	s6,0x8
ffffffffc0200e46:	5feb2b03          	lw	s6,1534(s6) # ffffffffc0209440 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200e4a:	01293023          	sd	s2,0(s2)
ffffffffc0200e4e:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200e52:	00008797          	auipc	a5,0x8
ffffffffc0200e56:	5e07a723          	sw	zero,1518(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e5a:	611000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200e5e:	2e051763          	bnez	a0,ffffffffc020114c <default_check+0x3fa>
    free_page(p0);
ffffffffc0200e62:	8552                	mv	a0,s4
ffffffffc0200e64:	4585                	li	a1,1
ffffffffc0200e66:	63f000ef          	jal	ffffffffc0201ca4 <free_pages>
    free_page(p1);
ffffffffc0200e6a:	854e                	mv	a0,s3
ffffffffc0200e6c:	4585                	li	a1,1
ffffffffc0200e6e:	637000ef          	jal	ffffffffc0201ca4 <free_pages>
    free_page(p2);
ffffffffc0200e72:	8556                	mv	a0,s5
ffffffffc0200e74:	4585                	li	a1,1
ffffffffc0200e76:	62f000ef          	jal	ffffffffc0201ca4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e7a:	00008717          	auipc	a4,0x8
ffffffffc0200e7e:	5c672703          	lw	a4,1478(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e82:	478d                	li	a5,3
ffffffffc0200e84:	2af71463          	bne	a4,a5,ffffffffc020112c <default_check+0x3da>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e88:	4505                	li	a0,1
ffffffffc0200e8a:	5e1000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200e8e:	89aa                	mv	s3,a0
ffffffffc0200e90:	26050e63          	beqz	a0,ffffffffc020110c <default_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	5d5000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200e9a:	8aaa                	mv	s5,a0
ffffffffc0200e9c:	3c050863          	beqz	a0,ffffffffc020126c <default_check+0x51a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ea0:	4505                	li	a0,1
ffffffffc0200ea2:	5c9000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200ea6:	8a2a                	mv	s4,a0
ffffffffc0200ea8:	3a050263          	beqz	a0,ffffffffc020124c <default_check+0x4fa>
    assert(alloc_page() == NULL);
ffffffffc0200eac:	4505                	li	a0,1
ffffffffc0200eae:	5bd000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200eb2:	36051d63          	bnez	a0,ffffffffc020122c <default_check+0x4da>
    free_page(p0);
ffffffffc0200eb6:	4585                	li	a1,1
ffffffffc0200eb8:	854e                	mv	a0,s3
ffffffffc0200eba:	5eb000ef          	jal	ffffffffc0201ca4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ebe:	00893783          	ld	a5,8(s2)
ffffffffc0200ec2:	1f278563          	beq	a5,s2,ffffffffc02010ac <default_check+0x35a>
    assert((p = alloc_page()) == p0);
ffffffffc0200ec6:	4505                	li	a0,1
ffffffffc0200ec8:	5a3000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200ecc:	8caa                	mv	s9,a0
ffffffffc0200ece:	30a99f63          	bne	s3,a0,ffffffffc02011ec <default_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200ed2:	4505                	li	a0,1
ffffffffc0200ed4:	597000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200ed8:	2e051a63          	bnez	a0,ffffffffc02011cc <default_check+0x47a>
    assert(nr_free == 0);
ffffffffc0200edc:	00008797          	auipc	a5,0x8
ffffffffc0200ee0:	5647a783          	lw	a5,1380(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200ee4:	2c079463          	bnez	a5,ffffffffc02011ac <default_check+0x45a>
    free_page(p);
ffffffffc0200ee8:	8566                	mv	a0,s9
ffffffffc0200eea:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200eec:	01893023          	sd	s8,0(s2)
ffffffffc0200ef0:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200ef4:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200ef8:	5ad000ef          	jal	ffffffffc0201ca4 <free_pages>
    free_page(p1);
ffffffffc0200efc:	8556                	mv	a0,s5
ffffffffc0200efe:	4585                	li	a1,1
ffffffffc0200f00:	5a5000ef          	jal	ffffffffc0201ca4 <free_pages>
    free_page(p2);
ffffffffc0200f04:	8552                	mv	a0,s4
ffffffffc0200f06:	4585                	li	a1,1
ffffffffc0200f08:	59d000ef          	jal	ffffffffc0201ca4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f0c:	4515                	li	a0,5
ffffffffc0200f0e:	55d000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200f12:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f14:	26050c63          	beqz	a0,ffffffffc020118c <default_check+0x43a>
ffffffffc0200f18:	651c                	ld	a5,8(a0)
ffffffffc0200f1a:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f1c:	8b85                	andi	a5,a5,1
ffffffffc0200f1e:	54079763          	bnez	a5,ffffffffc020146c <default_check+0x71a>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f22:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f24:	00093b83          	ld	s7,0(s2)
ffffffffc0200f28:	00893b03          	ld	s6,8(s2)
ffffffffc0200f2c:	01293023          	sd	s2,0(s2)
ffffffffc0200f30:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200f34:	537000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200f38:	50051a63          	bnez	a0,ffffffffc020144c <default_check+0x6fa>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f3c:	08098a13          	addi	s4,s3,128
ffffffffc0200f40:	8552                	mv	a0,s4
ffffffffc0200f42:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f44:	00008c17          	auipc	s8,0x8
ffffffffc0200f48:	4fcc2c03          	lw	s8,1276(s8) # ffffffffc0209440 <free_area+0x10>
    nr_free = 0;
ffffffffc0200f4c:	00008797          	auipc	a5,0x8
ffffffffc0200f50:	4e07aa23          	sw	zero,1268(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f54:	551000ef          	jal	ffffffffc0201ca4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f58:	4511                	li	a0,4
ffffffffc0200f5a:	511000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200f5e:	4c051763          	bnez	a0,ffffffffc020142c <default_check+0x6da>
ffffffffc0200f62:	0889b783          	ld	a5,136(s3)
ffffffffc0200f66:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f68:	8b85                	andi	a5,a5,1
ffffffffc0200f6a:	4a078163          	beqz	a5,ffffffffc020140c <default_check+0x6ba>
ffffffffc0200f6e:	0909a503          	lw	a0,144(s3)
ffffffffc0200f72:	478d                	li	a5,3
ffffffffc0200f74:	48f51c63          	bne	a0,a5,ffffffffc020140c <default_check+0x6ba>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f78:	4f3000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200f7c:	8aaa                	mv	s5,a0
ffffffffc0200f7e:	46050763          	beqz	a0,ffffffffc02013ec <default_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200f82:	4505                	li	a0,1
ffffffffc0200f84:	4e7000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200f88:	44051263          	bnez	a0,ffffffffc02013cc <default_check+0x67a>
    assert(p0 + 2 == p1);
ffffffffc0200f8c:	435a1063          	bne	s4,s5,ffffffffc02013ac <default_check+0x65a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f90:	4585                	li	a1,1
ffffffffc0200f92:	854e                	mv	a0,s3
ffffffffc0200f94:	511000ef          	jal	ffffffffc0201ca4 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f98:	8552                	mv	a0,s4
ffffffffc0200f9a:	458d                	li	a1,3
ffffffffc0200f9c:	509000ef          	jal	ffffffffc0201ca4 <free_pages>
ffffffffc0200fa0:	0089b783          	ld	a5,8(s3)
ffffffffc0200fa4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200fa6:	8b85                	andi	a5,a5,1
ffffffffc0200fa8:	3e078263          	beqz	a5,ffffffffc020138c <default_check+0x63a>
ffffffffc0200fac:	0109aa83          	lw	s5,16(s3)
ffffffffc0200fb0:	4785                	li	a5,1
ffffffffc0200fb2:	3cfa9d63          	bne	s5,a5,ffffffffc020138c <default_check+0x63a>
ffffffffc0200fb6:	008a3783          	ld	a5,8(s4)
ffffffffc0200fba:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200fbc:	8b85                	andi	a5,a5,1
ffffffffc0200fbe:	3a078763          	beqz	a5,ffffffffc020136c <default_check+0x61a>
ffffffffc0200fc2:	010a2703          	lw	a4,16(s4)
ffffffffc0200fc6:	478d                	li	a5,3
ffffffffc0200fc8:	3af71263          	bne	a4,a5,ffffffffc020136c <default_check+0x61a>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200fcc:	8556                	mv	a0,s5
ffffffffc0200fce:	49d000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200fd2:	36a99d63          	bne	s3,a0,ffffffffc020134c <default_check+0x5fa>
    free_page(p0);
ffffffffc0200fd6:	85d6                	mv	a1,s5
ffffffffc0200fd8:	4cd000ef          	jal	ffffffffc0201ca4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200fdc:	4509                	li	a0,2
ffffffffc0200fde:	48d000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200fe2:	34aa1563          	bne	s4,a0,ffffffffc020132c <default_check+0x5da>

    free_pages(p0, 2);
ffffffffc0200fe6:	4589                	li	a1,2
ffffffffc0200fe8:	4bd000ef          	jal	ffffffffc0201ca4 <free_pages>
    free_page(p2);
ffffffffc0200fec:	04098513          	addi	a0,s3,64
ffffffffc0200ff0:	85d6                	mv	a1,s5
ffffffffc0200ff2:	4b3000ef          	jal	ffffffffc0201ca4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ff6:	4515                	li	a0,5
ffffffffc0200ff8:	473000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0200ffc:	89aa                	mv	s3,a0
ffffffffc0200ffe:	48050763          	beqz	a0,ffffffffc020148c <default_check+0x73a>
    assert(alloc_page() == NULL);
ffffffffc0201002:	8556                	mv	a0,s5
ffffffffc0201004:	467000ef          	jal	ffffffffc0201c6a <alloc_pages>
ffffffffc0201008:	2e051263          	bnez	a0,ffffffffc02012ec <default_check+0x59a>

    assert(nr_free == 0);
ffffffffc020100c:	00008797          	auipc	a5,0x8
ffffffffc0201010:	4347a783          	lw	a5,1076(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201014:	2a079c63          	bnez	a5,ffffffffc02012cc <default_check+0x57a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201018:	854e                	mv	a0,s3
ffffffffc020101a:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc020101c:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201020:	01793023          	sd	s7,0(s2)
ffffffffc0201024:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201028:	47d000ef          	jal	ffffffffc0201ca4 <free_pages>
    return listelm->next;
ffffffffc020102c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201030:	01278963          	beq	a5,s2,ffffffffc0201042 <default_check+0x2f0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201034:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201038:	679c                	ld	a5,8(a5)
ffffffffc020103a:	34fd                	addiw	s1,s1,-1
ffffffffc020103c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020103e:	ff279be3          	bne	a5,s2,ffffffffc0201034 <default_check+0x2e2>
    }
    assert(count == 0);
ffffffffc0201042:	26049563          	bnez	s1,ffffffffc02012ac <default_check+0x55a>
    assert(total == 0);
ffffffffc0201046:	46041363          	bnez	s0,ffffffffc02014ac <default_check+0x75a>
}
ffffffffc020104a:	60e6                	ld	ra,88(sp)
ffffffffc020104c:	6446                	ld	s0,80(sp)
ffffffffc020104e:	64a6                	ld	s1,72(sp)
ffffffffc0201050:	6906                	ld	s2,64(sp)
ffffffffc0201052:	79e2                	ld	s3,56(sp)
ffffffffc0201054:	7a42                	ld	s4,48(sp)
ffffffffc0201056:	7aa2                	ld	s5,40(sp)
ffffffffc0201058:	7b02                	ld	s6,32(sp)
ffffffffc020105a:	6be2                	ld	s7,24(sp)
ffffffffc020105c:	6c42                	ld	s8,16(sp)
ffffffffc020105e:	6ca2                	ld	s9,8(sp)
ffffffffc0201060:	6125                	addi	sp,sp,96
ffffffffc0201062:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201064:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201066:	4401                	li	s0,0
ffffffffc0201068:	4481                	li	s1,0
ffffffffc020106a:	b33d                	j	ffffffffc0200d98 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc020106c:	00004697          	auipc	a3,0x4
ffffffffc0201070:	81c68693          	addi	a3,a3,-2020 # ffffffffc0204888 <etext+0x9c6>
ffffffffc0201074:	00004617          	auipc	a2,0x4
ffffffffc0201078:	82460613          	addi	a2,a2,-2012 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020107c:	0f000593          	li	a1,240
ffffffffc0201080:	00004517          	auipc	a0,0x4
ffffffffc0201084:	83050513          	addi	a0,a0,-2000 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201088:	b7eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020108c:	00004697          	auipc	a3,0x4
ffffffffc0201090:	8e468693          	addi	a3,a3,-1820 # ffffffffc0204970 <etext+0xaae>
ffffffffc0201094:	00004617          	auipc	a2,0x4
ffffffffc0201098:	80460613          	addi	a2,a2,-2044 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020109c:	0be00593          	li	a1,190
ffffffffc02010a0:	00004517          	auipc	a0,0x4
ffffffffc02010a4:	81050513          	addi	a0,a0,-2032 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02010a8:	b5eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010ac:	00004697          	auipc	a3,0x4
ffffffffc02010b0:	98c68693          	addi	a3,a3,-1652 # ffffffffc0204a38 <etext+0xb76>
ffffffffc02010b4:	00003617          	auipc	a2,0x3
ffffffffc02010b8:	7e460613          	addi	a2,a2,2020 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02010bc:	0d900593          	li	a1,217
ffffffffc02010c0:	00003517          	auipc	a0,0x3
ffffffffc02010c4:	7f050513          	addi	a0,a0,2032 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02010c8:	b3eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010cc:	00004697          	auipc	a3,0x4
ffffffffc02010d0:	8e468693          	addi	a3,a3,-1820 # ffffffffc02049b0 <etext+0xaee>
ffffffffc02010d4:	00003617          	auipc	a2,0x3
ffffffffc02010d8:	7c460613          	addi	a2,a2,1988 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02010dc:	0c000593          	li	a1,192
ffffffffc02010e0:	00003517          	auipc	a0,0x3
ffffffffc02010e4:	7d050513          	addi	a0,a0,2000 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02010e8:	b1eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010ec:	00004697          	auipc	a3,0x4
ffffffffc02010f0:	85c68693          	addi	a3,a3,-1956 # ffffffffc0204948 <etext+0xa86>
ffffffffc02010f4:	00003617          	auipc	a2,0x3
ffffffffc02010f8:	7a460613          	addi	a2,a2,1956 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02010fc:	0bd00593          	li	a1,189
ffffffffc0201100:	00003517          	auipc	a0,0x3
ffffffffc0201104:	7b050513          	addi	a0,a0,1968 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201108:	afeff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020110c:	00003697          	auipc	a3,0x3
ffffffffc0201110:	7dc68693          	addi	a3,a3,2012 # ffffffffc02048e8 <etext+0xa26>
ffffffffc0201114:	00003617          	auipc	a2,0x3
ffffffffc0201118:	78460613          	addi	a2,a2,1924 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020111c:	0d200593          	li	a1,210
ffffffffc0201120:	00003517          	auipc	a0,0x3
ffffffffc0201124:	79050513          	addi	a0,a0,1936 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201128:	adeff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 3);
ffffffffc020112c:	00004697          	auipc	a3,0x4
ffffffffc0201130:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0204a28 <etext+0xb66>
ffffffffc0201134:	00003617          	auipc	a2,0x3
ffffffffc0201138:	76460613          	addi	a2,a2,1892 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020113c:	0d000593          	li	a1,208
ffffffffc0201140:	00003517          	auipc	a0,0x3
ffffffffc0201144:	77050513          	addi	a0,a0,1904 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201148:	abeff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020114c:	00004697          	auipc	a3,0x4
ffffffffc0201150:	8c468693          	addi	a3,a3,-1852 # ffffffffc0204a10 <etext+0xb4e>
ffffffffc0201154:	00003617          	auipc	a2,0x3
ffffffffc0201158:	74460613          	addi	a2,a2,1860 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020115c:	0cb00593          	li	a1,203
ffffffffc0201160:	00003517          	auipc	a0,0x3
ffffffffc0201164:	75050513          	addi	a0,a0,1872 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201168:	a9eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020116c:	00004697          	auipc	a3,0x4
ffffffffc0201170:	88468693          	addi	a3,a3,-1916 # ffffffffc02049f0 <etext+0xb2e>
ffffffffc0201174:	00003617          	auipc	a2,0x3
ffffffffc0201178:	72460613          	addi	a2,a2,1828 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020117c:	0c200593          	li	a1,194
ffffffffc0201180:	00003517          	auipc	a0,0x3
ffffffffc0201184:	73050513          	addi	a0,a0,1840 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201188:	a7eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != NULL);
ffffffffc020118c:	00004697          	auipc	a3,0x4
ffffffffc0201190:	8f468693          	addi	a3,a3,-1804 # ffffffffc0204a80 <etext+0xbbe>
ffffffffc0201194:	00003617          	auipc	a2,0x3
ffffffffc0201198:	70460613          	addi	a2,a2,1796 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020119c:	0f800593          	li	a1,248
ffffffffc02011a0:	00003517          	auipc	a0,0x3
ffffffffc02011a4:	71050513          	addi	a0,a0,1808 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02011a8:	a5eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02011ac:	00004697          	auipc	a3,0x4
ffffffffc02011b0:	8c468693          	addi	a3,a3,-1852 # ffffffffc0204a70 <etext+0xbae>
ffffffffc02011b4:	00003617          	auipc	a2,0x3
ffffffffc02011b8:	6e460613          	addi	a2,a2,1764 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02011bc:	0df00593          	li	a1,223
ffffffffc02011c0:	00003517          	auipc	a0,0x3
ffffffffc02011c4:	6f050513          	addi	a0,a0,1776 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02011c8:	a3eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011cc:	00004697          	auipc	a3,0x4
ffffffffc02011d0:	84468693          	addi	a3,a3,-1980 # ffffffffc0204a10 <etext+0xb4e>
ffffffffc02011d4:	00003617          	auipc	a2,0x3
ffffffffc02011d8:	6c460613          	addi	a2,a2,1732 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02011dc:	0dd00593          	li	a1,221
ffffffffc02011e0:	00003517          	auipc	a0,0x3
ffffffffc02011e4:	6d050513          	addi	a0,a0,1744 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02011e8:	a1eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02011ec:	00004697          	auipc	a3,0x4
ffffffffc02011f0:	86468693          	addi	a3,a3,-1948 # ffffffffc0204a50 <etext+0xb8e>
ffffffffc02011f4:	00003617          	auipc	a2,0x3
ffffffffc02011f8:	6a460613          	addi	a2,a2,1700 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02011fc:	0dc00593          	li	a1,220
ffffffffc0201200:	00003517          	auipc	a0,0x3
ffffffffc0201204:	6b050513          	addi	a0,a0,1712 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201208:	9feff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020120c:	00003697          	auipc	a3,0x3
ffffffffc0201210:	6dc68693          	addi	a3,a3,1756 # ffffffffc02048e8 <etext+0xa26>
ffffffffc0201214:	00003617          	auipc	a2,0x3
ffffffffc0201218:	68460613          	addi	a2,a2,1668 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020121c:	0b900593          	li	a1,185
ffffffffc0201220:	00003517          	auipc	a0,0x3
ffffffffc0201224:	69050513          	addi	a0,a0,1680 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201228:	9deff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020122c:	00003697          	auipc	a3,0x3
ffffffffc0201230:	7e468693          	addi	a3,a3,2020 # ffffffffc0204a10 <etext+0xb4e>
ffffffffc0201234:	00003617          	auipc	a2,0x3
ffffffffc0201238:	66460613          	addi	a2,a2,1636 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020123c:	0d600593          	li	a1,214
ffffffffc0201240:	00003517          	auipc	a0,0x3
ffffffffc0201244:	67050513          	addi	a0,a0,1648 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201248:	9beff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020124c:	00003697          	auipc	a3,0x3
ffffffffc0201250:	6dc68693          	addi	a3,a3,1756 # ffffffffc0204928 <etext+0xa66>
ffffffffc0201254:	00003617          	auipc	a2,0x3
ffffffffc0201258:	64460613          	addi	a2,a2,1604 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020125c:	0d400593          	li	a1,212
ffffffffc0201260:	00003517          	auipc	a0,0x3
ffffffffc0201264:	65050513          	addi	a0,a0,1616 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201268:	99eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020126c:	00003697          	auipc	a3,0x3
ffffffffc0201270:	69c68693          	addi	a3,a3,1692 # ffffffffc0204908 <etext+0xa46>
ffffffffc0201274:	00003617          	auipc	a2,0x3
ffffffffc0201278:	62460613          	addi	a2,a2,1572 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020127c:	0d300593          	li	a1,211
ffffffffc0201280:	00003517          	auipc	a0,0x3
ffffffffc0201284:	63050513          	addi	a0,a0,1584 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201288:	97eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020128c:	00003697          	auipc	a3,0x3
ffffffffc0201290:	69c68693          	addi	a3,a3,1692 # ffffffffc0204928 <etext+0xa66>
ffffffffc0201294:	00003617          	auipc	a2,0x3
ffffffffc0201298:	60460613          	addi	a2,a2,1540 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020129c:	0bb00593          	li	a1,187
ffffffffc02012a0:	00003517          	auipc	a0,0x3
ffffffffc02012a4:	61050513          	addi	a0,a0,1552 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02012a8:	95eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(count == 0);
ffffffffc02012ac:	00004697          	auipc	a3,0x4
ffffffffc02012b0:	92468693          	addi	a3,a3,-1756 # ffffffffc0204bd0 <etext+0xd0e>
ffffffffc02012b4:	00003617          	auipc	a2,0x3
ffffffffc02012b8:	5e460613          	addi	a2,a2,1508 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02012bc:	12500593          	li	a1,293
ffffffffc02012c0:	00003517          	auipc	a0,0x3
ffffffffc02012c4:	5f050513          	addi	a0,a0,1520 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02012c8:	93eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02012cc:	00003697          	auipc	a3,0x3
ffffffffc02012d0:	7a468693          	addi	a3,a3,1956 # ffffffffc0204a70 <etext+0xbae>
ffffffffc02012d4:	00003617          	auipc	a2,0x3
ffffffffc02012d8:	5c460613          	addi	a2,a2,1476 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02012dc:	11a00593          	li	a1,282
ffffffffc02012e0:	00003517          	auipc	a0,0x3
ffffffffc02012e4:	5d050513          	addi	a0,a0,1488 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02012e8:	91eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012ec:	00003697          	auipc	a3,0x3
ffffffffc02012f0:	72468693          	addi	a3,a3,1828 # ffffffffc0204a10 <etext+0xb4e>
ffffffffc02012f4:	00003617          	auipc	a2,0x3
ffffffffc02012f8:	5a460613          	addi	a2,a2,1444 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02012fc:	11800593          	li	a1,280
ffffffffc0201300:	00003517          	auipc	a0,0x3
ffffffffc0201304:	5b050513          	addi	a0,a0,1456 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201308:	8feff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020130c:	00003697          	auipc	a3,0x3
ffffffffc0201310:	6c468693          	addi	a3,a3,1732 # ffffffffc02049d0 <etext+0xb0e>
ffffffffc0201314:	00003617          	auipc	a2,0x3
ffffffffc0201318:	58460613          	addi	a2,a2,1412 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020131c:	0c100593          	li	a1,193
ffffffffc0201320:	00003517          	auipc	a0,0x3
ffffffffc0201324:	59050513          	addi	a0,a0,1424 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201328:	8deff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020132c:	00004697          	auipc	a3,0x4
ffffffffc0201330:	86468693          	addi	a3,a3,-1948 # ffffffffc0204b90 <etext+0xcce>
ffffffffc0201334:	00003617          	auipc	a2,0x3
ffffffffc0201338:	56460613          	addi	a2,a2,1380 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020133c:	11200593          	li	a1,274
ffffffffc0201340:	00003517          	auipc	a0,0x3
ffffffffc0201344:	57050513          	addi	a0,a0,1392 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201348:	8beff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020134c:	00004697          	auipc	a3,0x4
ffffffffc0201350:	82468693          	addi	a3,a3,-2012 # ffffffffc0204b70 <etext+0xcae>
ffffffffc0201354:	00003617          	auipc	a2,0x3
ffffffffc0201358:	54460613          	addi	a2,a2,1348 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020135c:	11000593          	li	a1,272
ffffffffc0201360:	00003517          	auipc	a0,0x3
ffffffffc0201364:	55050513          	addi	a0,a0,1360 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201368:	89eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020136c:	00003697          	auipc	a3,0x3
ffffffffc0201370:	7dc68693          	addi	a3,a3,2012 # ffffffffc0204b48 <etext+0xc86>
ffffffffc0201374:	00003617          	auipc	a2,0x3
ffffffffc0201378:	52460613          	addi	a2,a2,1316 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020137c:	10e00593          	li	a1,270
ffffffffc0201380:	00003517          	auipc	a0,0x3
ffffffffc0201384:	53050513          	addi	a0,a0,1328 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201388:	87eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020138c:	00003697          	auipc	a3,0x3
ffffffffc0201390:	79468693          	addi	a3,a3,1940 # ffffffffc0204b20 <etext+0xc5e>
ffffffffc0201394:	00003617          	auipc	a2,0x3
ffffffffc0201398:	50460613          	addi	a2,a2,1284 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020139c:	10d00593          	li	a1,269
ffffffffc02013a0:	00003517          	auipc	a0,0x3
ffffffffc02013a4:	51050513          	addi	a0,a0,1296 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02013a8:	85eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02013ac:	00003697          	auipc	a3,0x3
ffffffffc02013b0:	76468693          	addi	a3,a3,1892 # ffffffffc0204b10 <etext+0xc4e>
ffffffffc02013b4:	00003617          	auipc	a2,0x3
ffffffffc02013b8:	4e460613          	addi	a2,a2,1252 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02013bc:	10800593          	li	a1,264
ffffffffc02013c0:	00003517          	auipc	a0,0x3
ffffffffc02013c4:	4f050513          	addi	a0,a0,1264 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02013c8:	83eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013cc:	00003697          	auipc	a3,0x3
ffffffffc02013d0:	64468693          	addi	a3,a3,1604 # ffffffffc0204a10 <etext+0xb4e>
ffffffffc02013d4:	00003617          	auipc	a2,0x3
ffffffffc02013d8:	4c460613          	addi	a2,a2,1220 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02013dc:	10700593          	li	a1,263
ffffffffc02013e0:	00003517          	auipc	a0,0x3
ffffffffc02013e4:	4d050513          	addi	a0,a0,1232 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02013e8:	81eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013ec:	00003697          	auipc	a3,0x3
ffffffffc02013f0:	70468693          	addi	a3,a3,1796 # ffffffffc0204af0 <etext+0xc2e>
ffffffffc02013f4:	00003617          	auipc	a2,0x3
ffffffffc02013f8:	4a460613          	addi	a2,a2,1188 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02013fc:	10600593          	li	a1,262
ffffffffc0201400:	00003517          	auipc	a0,0x3
ffffffffc0201404:	4b050513          	addi	a0,a0,1200 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201408:	ffffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020140c:	00003697          	auipc	a3,0x3
ffffffffc0201410:	6b468693          	addi	a3,a3,1716 # ffffffffc0204ac0 <etext+0xbfe>
ffffffffc0201414:	00003617          	auipc	a2,0x3
ffffffffc0201418:	48460613          	addi	a2,a2,1156 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020141c:	10500593          	li	a1,261
ffffffffc0201420:	00003517          	auipc	a0,0x3
ffffffffc0201424:	49050513          	addi	a0,a0,1168 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201428:	fdffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020142c:	00003697          	auipc	a3,0x3
ffffffffc0201430:	67c68693          	addi	a3,a3,1660 # ffffffffc0204aa8 <etext+0xbe6>
ffffffffc0201434:	00003617          	auipc	a2,0x3
ffffffffc0201438:	46460613          	addi	a2,a2,1124 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020143c:	10400593          	li	a1,260
ffffffffc0201440:	00003517          	auipc	a0,0x3
ffffffffc0201444:	47050513          	addi	a0,a0,1136 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201448:	fbffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020144c:	00003697          	auipc	a3,0x3
ffffffffc0201450:	5c468693          	addi	a3,a3,1476 # ffffffffc0204a10 <etext+0xb4e>
ffffffffc0201454:	00003617          	auipc	a2,0x3
ffffffffc0201458:	44460613          	addi	a2,a2,1092 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020145c:	0fe00593          	li	a1,254
ffffffffc0201460:	00003517          	auipc	a0,0x3
ffffffffc0201464:	45050513          	addi	a0,a0,1104 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201468:	f9ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(!PageProperty(p0));
ffffffffc020146c:	00003697          	auipc	a3,0x3
ffffffffc0201470:	62468693          	addi	a3,a3,1572 # ffffffffc0204a90 <etext+0xbce>
ffffffffc0201474:	00003617          	auipc	a2,0x3
ffffffffc0201478:	42460613          	addi	a2,a2,1060 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020147c:	0f900593          	li	a1,249
ffffffffc0201480:	00003517          	auipc	a0,0x3
ffffffffc0201484:	43050513          	addi	a0,a0,1072 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201488:	f7ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020148c:	00003697          	auipc	a3,0x3
ffffffffc0201490:	72468693          	addi	a3,a3,1828 # ffffffffc0204bb0 <etext+0xcee>
ffffffffc0201494:	00003617          	auipc	a2,0x3
ffffffffc0201498:	40460613          	addi	a2,a2,1028 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020149c:	11700593          	li	a1,279
ffffffffc02014a0:	00003517          	auipc	a0,0x3
ffffffffc02014a4:	41050513          	addi	a0,a0,1040 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02014a8:	f5ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == 0);
ffffffffc02014ac:	00003697          	auipc	a3,0x3
ffffffffc02014b0:	73468693          	addi	a3,a3,1844 # ffffffffc0204be0 <etext+0xd1e>
ffffffffc02014b4:	00003617          	auipc	a2,0x3
ffffffffc02014b8:	3e460613          	addi	a2,a2,996 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02014bc:	12600593          	li	a1,294
ffffffffc02014c0:	00003517          	auipc	a0,0x3
ffffffffc02014c4:	3f050513          	addi	a0,a0,1008 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02014c8:	f3ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == nr_free_pages());
ffffffffc02014cc:	00003697          	auipc	a3,0x3
ffffffffc02014d0:	3fc68693          	addi	a3,a3,1020 # ffffffffc02048c8 <etext+0xa06>
ffffffffc02014d4:	00003617          	auipc	a2,0x3
ffffffffc02014d8:	3c460613          	addi	a2,a2,964 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02014dc:	0f300593          	li	a1,243
ffffffffc02014e0:	00003517          	auipc	a0,0x3
ffffffffc02014e4:	3d050513          	addi	a0,a0,976 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc02014e8:	f1ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014ec:	00003697          	auipc	a3,0x3
ffffffffc02014f0:	41c68693          	addi	a3,a3,1052 # ffffffffc0204908 <etext+0xa46>
ffffffffc02014f4:	00003617          	auipc	a2,0x3
ffffffffc02014f8:	3a460613          	addi	a2,a2,932 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02014fc:	0ba00593          	li	a1,186
ffffffffc0201500:	00003517          	auipc	a0,0x3
ffffffffc0201504:	3b050513          	addi	a0,a0,944 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201508:	efffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020150c <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020150c:	1141                	addi	sp,sp,-16
ffffffffc020150e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201510:	14058663          	beqz	a1,ffffffffc020165c <default_free_pages+0x150>
    for (; p != base + n; p ++) {
ffffffffc0201514:	00659713          	slli	a4,a1,0x6
ffffffffc0201518:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020151c:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020151e:	c30d                	beqz	a4,ffffffffc0201540 <default_free_pages+0x34>
ffffffffc0201520:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201522:	8b05                	andi	a4,a4,1
ffffffffc0201524:	10071c63          	bnez	a4,ffffffffc020163c <default_free_pages+0x130>
ffffffffc0201528:	6798                	ld	a4,8(a5)
ffffffffc020152a:	8b09                	andi	a4,a4,2
ffffffffc020152c:	10071863          	bnez	a4,ffffffffc020163c <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201530:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201534:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201538:	04078793          	addi	a5,a5,64
ffffffffc020153c:	fed792e3          	bne	a5,a3,ffffffffc0201520 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201540:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201542:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201546:	4789                	li	a5,2
ffffffffc0201548:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020154c:	00008717          	auipc	a4,0x8
ffffffffc0201550:	ef472703          	lw	a4,-268(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201554:	00008697          	auipc	a3,0x8
ffffffffc0201558:	edc68693          	addi	a3,a3,-292 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc020155c:	669c                	ld	a5,8(a3)
ffffffffc020155e:	9f2d                	addw	a4,a4,a1
ffffffffc0201560:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201562:	0ad78163          	beq	a5,a3,ffffffffc0201604 <default_free_pages+0xf8>
            struct Page* page = le2page(le, page_link);
ffffffffc0201566:	fe878713          	addi	a4,a5,-24
ffffffffc020156a:	4581                	li	a1,0
ffffffffc020156c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201570:	00e56a63          	bltu	a0,a4,ffffffffc0201584 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201574:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201576:	04d70c63          	beq	a4,a3,ffffffffc02015ce <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020157a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020157c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201580:	fee57ae3          	bgeu	a0,a4,ffffffffc0201574 <default_free_pages+0x68>
ffffffffc0201584:	c199                	beqz	a1,ffffffffc020158a <default_free_pages+0x7e>
ffffffffc0201586:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020158a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020158c:	e390                	sd	a2,0(a5)
ffffffffc020158e:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201590:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201592:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201594:	00d70d63          	beq	a4,a3,ffffffffc02015ae <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201598:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020159c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02015a0:	02059813          	slli	a6,a1,0x20
ffffffffc02015a4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02015a8:	97b2                	add	a5,a5,a2
ffffffffc02015aa:	02f50c63          	beq	a0,a5,ffffffffc02015e2 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02015ae:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02015b0:	00d78c63          	beq	a5,a3,ffffffffc02015c8 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02015b4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015b6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02015ba:	02061593          	slli	a1,a2,0x20
ffffffffc02015be:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015c2:	972a                	add	a4,a4,a0
ffffffffc02015c4:	04e68c63          	beq	a3,a4,ffffffffc020161c <default_free_pages+0x110>
}
ffffffffc02015c8:	60a2                	ld	ra,8(sp)
ffffffffc02015ca:	0141                	addi	sp,sp,16
ffffffffc02015cc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015d0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015d2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015d4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015d6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015d8:	02d70f63          	beq	a4,a3,ffffffffc0201616 <default_free_pages+0x10a>
ffffffffc02015dc:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02015de:	87ba                	mv	a5,a4
ffffffffc02015e0:	bf71                	j	ffffffffc020157c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02015e2:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015e4:	5875                	li	a6,-3
ffffffffc02015e6:	9fad                	addw	a5,a5,a1
ffffffffc02015e8:	fef72c23          	sw	a5,-8(a4)
ffffffffc02015ec:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015f0:	01853803          	ld	a6,24(a0)
ffffffffc02015f4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02015f6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02015f8:	00b83423          	sd	a1,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    return listelm->next;
ffffffffc02015fc:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02015fe:	0105b023          	sd	a6,0(a1)
ffffffffc0201602:	b77d                	j	ffffffffc02015b0 <default_free_pages+0xa4>
}
ffffffffc0201604:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201606:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020160a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020160c:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020160e:	e398                	sd	a4,0(a5)
ffffffffc0201610:	e798                	sd	a4,8(a5)
}
ffffffffc0201612:	0141                	addi	sp,sp,16
ffffffffc0201614:	8082                	ret
ffffffffc0201616:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201618:	873e                	mv	a4,a5
ffffffffc020161a:	bfad                	j	ffffffffc0201594 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020161c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201620:	56f5                	li	a3,-3
ffffffffc0201622:	9f31                	addw	a4,a4,a2
ffffffffc0201624:	c918                	sw	a4,16(a0)
ffffffffc0201626:	ff078713          	addi	a4,a5,-16
ffffffffc020162a:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020162e:	6398                	ld	a4,0(a5)
ffffffffc0201630:	679c                	ld	a5,8(a5)
}
ffffffffc0201632:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201634:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201636:	e398                	sd	a4,0(a5)
ffffffffc0201638:	0141                	addi	sp,sp,16
ffffffffc020163a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020163c:	00003697          	auipc	a3,0x3
ffffffffc0201640:	5bc68693          	addi	a3,a3,1468 # ffffffffc0204bf8 <etext+0xd36>
ffffffffc0201644:	00003617          	auipc	a2,0x3
ffffffffc0201648:	25460613          	addi	a2,a2,596 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020164c:	08300593          	li	a1,131
ffffffffc0201650:	00003517          	auipc	a0,0x3
ffffffffc0201654:	26050513          	addi	a0,a0,608 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201658:	daffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc020165c:	00003697          	auipc	a3,0x3
ffffffffc0201660:	59468693          	addi	a3,a3,1428 # ffffffffc0204bf0 <etext+0xd2e>
ffffffffc0201664:	00003617          	auipc	a2,0x3
ffffffffc0201668:	23460613          	addi	a2,a2,564 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020166c:	08000593          	li	a1,128
ffffffffc0201670:	00003517          	auipc	a0,0x3
ffffffffc0201674:	24050513          	addi	a0,a0,576 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201678:	d8ffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020167c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020167c:	c951                	beqz	a0,ffffffffc0201710 <default_alloc_pages+0x94>
    if (n > nr_free) {
ffffffffc020167e:	00008597          	auipc	a1,0x8
ffffffffc0201682:	dc25a583          	lw	a1,-574(a1) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201686:	86aa                	mv	a3,a0
ffffffffc0201688:	02059793          	slli	a5,a1,0x20
ffffffffc020168c:	9381                	srli	a5,a5,0x20
ffffffffc020168e:	00a7ef63          	bltu	a5,a0,ffffffffc02016ac <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201692:	00008617          	auipc	a2,0x8
ffffffffc0201696:	d9e60613          	addi	a2,a2,-610 # ffffffffc0209430 <free_area>
ffffffffc020169a:	87b2                	mv	a5,a2
ffffffffc020169c:	a029                	j	ffffffffc02016a6 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc020169e:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02016a2:	00d77763          	bgeu	a4,a3,ffffffffc02016b0 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02016a6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02016a8:	fec79be3          	bne	a5,a2,ffffffffc020169e <default_alloc_pages+0x22>
        return NULL;
ffffffffc02016ac:	4501                	li	a0,0
}
ffffffffc02016ae:	8082                	ret
        if (page->property > n) {
ffffffffc02016b0:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02016b4:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016b8:	6798                	ld	a4,8(a5)
ffffffffc02016ba:	02089313          	slli	t1,a7,0x20
ffffffffc02016be:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02016c2:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02016c6:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02016ca:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02016ce:	0266fa63          	bgeu	a3,t1,ffffffffc0201702 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02016d2:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02016d6:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02016da:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016dc:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016e0:	00870313          	addi	t1,a4,8
ffffffffc02016e4:	4889                	li	a7,2
ffffffffc02016e6:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02016ea:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02016ee:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02016f2:	0068b023          	sd	t1,0(a7)
ffffffffc02016f6:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02016fa:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02016fe:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201702:	9d95                	subw	a1,a1,a3
ffffffffc0201704:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201706:	5775                	li	a4,-3
ffffffffc0201708:	17c1                	addi	a5,a5,-16
ffffffffc020170a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020170e:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201710:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201712:	00003697          	auipc	a3,0x3
ffffffffc0201716:	4de68693          	addi	a3,a3,1246 # ffffffffc0204bf0 <etext+0xd2e>
ffffffffc020171a:	00003617          	auipc	a2,0x3
ffffffffc020171e:	17e60613          	addi	a2,a2,382 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0201722:	06200593          	li	a1,98
ffffffffc0201726:	00003517          	auipc	a0,0x3
ffffffffc020172a:	18a50513          	addi	a0,a0,394 # ffffffffc02048b0 <etext+0x9ee>
default_alloc_pages(size_t n) {
ffffffffc020172e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201730:	cd7fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201734 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201734:	1141                	addi	sp,sp,-16
ffffffffc0201736:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201738:	c9e1                	beqz	a1,ffffffffc0201808 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020173a:	00659713          	slli	a4,a1,0x6
ffffffffc020173e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201742:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201744:	cf11                	beqz	a4,ffffffffc0201760 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201746:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201748:	8b05                	andi	a4,a4,1
ffffffffc020174a:	cf59                	beqz	a4,ffffffffc02017e8 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020174c:	0007a823          	sw	zero,16(a5)
ffffffffc0201750:	0007b423          	sd	zero,8(a5)
ffffffffc0201754:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201758:	04078793          	addi	a5,a5,64
ffffffffc020175c:	fed795e3          	bne	a5,a3,ffffffffc0201746 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201760:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201762:	4789                	li	a5,2
ffffffffc0201764:	00850713          	addi	a4,a0,8
ffffffffc0201768:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020176c:	00008717          	auipc	a4,0x8
ffffffffc0201770:	cd472703          	lw	a4,-812(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201774:	00008697          	auipc	a3,0x8
ffffffffc0201778:	cbc68693          	addi	a3,a3,-836 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc020177c:	669c                	ld	a5,8(a3)
ffffffffc020177e:	9f2d                	addw	a4,a4,a1
ffffffffc0201780:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201782:	04d78663          	beq	a5,a3,ffffffffc02017ce <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201786:	fe878713          	addi	a4,a5,-24
ffffffffc020178a:	4581                	li	a1,0
ffffffffc020178c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201790:	00e56a63          	bltu	a0,a4,ffffffffc02017a4 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201794:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201796:	02d70263          	beq	a4,a3,ffffffffc02017ba <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020179a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020179c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02017a0:	fee57ae3          	bgeu	a0,a4,ffffffffc0201794 <default_init_memmap+0x60>
ffffffffc02017a4:	c199                	beqz	a1,ffffffffc02017aa <default_init_memmap+0x76>
ffffffffc02017a6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017aa:	6398                	ld	a4,0(a5)
}
ffffffffc02017ac:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017ae:	e390                	sd	a2,0(a5)
ffffffffc02017b0:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02017b2:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017b4:	f11c                	sd	a5,32(a0)
ffffffffc02017b6:	0141                	addi	sp,sp,16
ffffffffc02017b8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017ba:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017bc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017be:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017c0:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017c2:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017c4:	00d70e63          	beq	a4,a3,ffffffffc02017e0 <default_init_memmap+0xac>
ffffffffc02017c8:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02017ca:	87ba                	mv	a5,a4
ffffffffc02017cc:	bfc1                	j	ffffffffc020179c <default_init_memmap+0x68>
}
ffffffffc02017ce:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02017d0:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02017d4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017d6:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02017d8:	e398                	sd	a4,0(a5)
ffffffffc02017da:	e798                	sd	a4,8(a5)
}
ffffffffc02017dc:	0141                	addi	sp,sp,16
ffffffffc02017de:	8082                	ret
ffffffffc02017e0:	60a2                	ld	ra,8(sp)
ffffffffc02017e2:	e290                	sd	a2,0(a3)
ffffffffc02017e4:	0141                	addi	sp,sp,16
ffffffffc02017e6:	8082                	ret
        assert(PageReserved(p));
ffffffffc02017e8:	00003697          	auipc	a3,0x3
ffffffffc02017ec:	43868693          	addi	a3,a3,1080 # ffffffffc0204c20 <etext+0xd5e>
ffffffffc02017f0:	00003617          	auipc	a2,0x3
ffffffffc02017f4:	0a860613          	addi	a2,a2,168 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02017f8:	04900593          	li	a1,73
ffffffffc02017fc:	00003517          	auipc	a0,0x3
ffffffffc0201800:	0b450513          	addi	a0,a0,180 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201804:	c03fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc0201808:	00003697          	auipc	a3,0x3
ffffffffc020180c:	3e868693          	addi	a3,a3,1000 # ffffffffc0204bf0 <etext+0xd2e>
ffffffffc0201810:	00003617          	auipc	a2,0x3
ffffffffc0201814:	08860613          	addi	a2,a2,136 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0201818:	04600593          	li	a1,70
ffffffffc020181c:	00003517          	auipc	a0,0x3
ffffffffc0201820:	09450513          	addi	a0,a0,148 # ffffffffc02048b0 <etext+0x9ee>
ffffffffc0201824:	be3fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201828 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201828:	c531                	beqz	a0,ffffffffc0201874 <slob_free+0x4c>
		return;

	if (size)
ffffffffc020182a:	e9b9                	bnez	a1,ffffffffc0201880 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020182c:	100027f3          	csrr	a5,sstatus
ffffffffc0201830:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201832:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201834:	efb1                	bnez	a5,ffffffffc0201890 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201836:	00007797          	auipc	a5,0x7
ffffffffc020183a:	7ea7b783          	ld	a5,2026(a5) # ffffffffc0209020 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020183e:	873e                	mv	a4,a5
ffffffffc0201840:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201842:	02a77a63          	bgeu	a4,a0,ffffffffc0201876 <slob_free+0x4e>
ffffffffc0201846:	00f56463          	bltu	a0,a5,ffffffffc020184e <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020184a:	fef76ae3          	bltu	a4,a5,ffffffffc020183e <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc020184e:	4110                	lw	a2,0(a0)
ffffffffc0201850:	00461693          	slli	a3,a2,0x4
ffffffffc0201854:	96aa                	add	a3,a3,a0
ffffffffc0201856:	0ad78463          	beq	a5,a3,ffffffffc02018fe <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc020185a:	4310                	lw	a2,0(a4)
ffffffffc020185c:	e51c                	sd	a5,8(a0)
ffffffffc020185e:	00461693          	slli	a3,a2,0x4
ffffffffc0201862:	96ba                	add	a3,a3,a4
ffffffffc0201864:	08d50163          	beq	a0,a3,ffffffffc02018e6 <slob_free+0xbe>
ffffffffc0201868:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc020186a:	00007797          	auipc	a5,0x7
ffffffffc020186e:	7ae7bb23          	sd	a4,1974(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc0201872:	e9a5                	bnez	a1,ffffffffc02018e2 <slob_free+0xba>
ffffffffc0201874:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201876:	fcf574e3          	bgeu	a0,a5,ffffffffc020183e <slob_free+0x16>
ffffffffc020187a:	fcf762e3          	bltu	a4,a5,ffffffffc020183e <slob_free+0x16>
ffffffffc020187e:	bfc1                	j	ffffffffc020184e <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201880:	25bd                	addiw	a1,a1,15
ffffffffc0201882:	8191                	srli	a1,a1,0x4
ffffffffc0201884:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201886:	100027f3          	csrr	a5,sstatus
ffffffffc020188a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020188c:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020188e:	d7c5                	beqz	a5,ffffffffc0201836 <slob_free+0xe>
{
ffffffffc0201890:	1101                	addi	sp,sp,-32
ffffffffc0201892:	e42a                	sd	a0,8(sp)
ffffffffc0201894:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201896:	fdffe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc020189a:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020189c:	00007797          	auipc	a5,0x7
ffffffffc02018a0:	7847b783          	ld	a5,1924(a5) # ffffffffc0209020 <slobfree>
ffffffffc02018a4:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018a6:	873e                	mv	a4,a5
ffffffffc02018a8:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018aa:	06a77663          	bgeu	a4,a0,ffffffffc0201916 <slob_free+0xee>
ffffffffc02018ae:	00f56463          	bltu	a0,a5,ffffffffc02018b6 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018b2:	fef76ae3          	bltu	a4,a5,ffffffffc02018a6 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc02018b6:	4110                	lw	a2,0(a0)
ffffffffc02018b8:	00461693          	slli	a3,a2,0x4
ffffffffc02018bc:	96aa                	add	a3,a3,a0
ffffffffc02018be:	06d78363          	beq	a5,a3,ffffffffc0201924 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc02018c2:	4310                	lw	a2,0(a4)
ffffffffc02018c4:	e51c                	sd	a5,8(a0)
ffffffffc02018c6:	00461693          	slli	a3,a2,0x4
ffffffffc02018ca:	96ba                	add	a3,a3,a4
ffffffffc02018cc:	06d50163          	beq	a0,a3,ffffffffc020192e <slob_free+0x106>
ffffffffc02018d0:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc02018d2:	00007797          	auipc	a5,0x7
ffffffffc02018d6:	74e7b723          	sd	a4,1870(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018da:	e1a9                	bnez	a1,ffffffffc020191c <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018dc:	60e2                	ld	ra,24(sp)
ffffffffc02018de:	6105                	addi	sp,sp,32
ffffffffc02018e0:	8082                	ret
        intr_enable();
ffffffffc02018e2:	f8dfe06f          	j	ffffffffc020086e <intr_enable>
		cur->units += b->units;
ffffffffc02018e6:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc02018e8:	853e                	mv	a0,a5
ffffffffc02018ea:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc02018ec:	00c687bb          	addw	a5,a3,a2
ffffffffc02018f0:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc02018f2:	00007797          	auipc	a5,0x7
ffffffffc02018f6:	72e7b723          	sd	a4,1838(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018fa:	ddad                	beqz	a1,ffffffffc0201874 <slob_free+0x4c>
ffffffffc02018fc:	b7dd                	j	ffffffffc02018e2 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc02018fe:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201900:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201902:	9eb1                	addw	a3,a3,a2
ffffffffc0201904:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201906:	4310                	lw	a2,0(a4)
ffffffffc0201908:	e51c                	sd	a5,8(a0)
ffffffffc020190a:	00461693          	slli	a3,a2,0x4
ffffffffc020190e:	96ba                	add	a3,a3,a4
ffffffffc0201910:	f4d51ce3          	bne	a0,a3,ffffffffc0201868 <slob_free+0x40>
ffffffffc0201914:	bfc9                	j	ffffffffc02018e6 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201916:	f8f56ee3          	bltu	a0,a5,ffffffffc02018b2 <slob_free+0x8a>
ffffffffc020191a:	b771                	j	ffffffffc02018a6 <slob_free+0x7e>
}
ffffffffc020191c:	60e2                	ld	ra,24(sp)
ffffffffc020191e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201920:	f4ffe06f          	j	ffffffffc020086e <intr_enable>
		b->units += cur->next->units;
ffffffffc0201924:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201926:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201928:	9eb1                	addw	a3,a3,a2
ffffffffc020192a:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc020192c:	bf59                	j	ffffffffc02018c2 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc020192e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201930:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201932:	00c687bb          	addw	a5,a3,a2
ffffffffc0201936:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201938:	bf61                	j	ffffffffc02018d0 <slob_free+0xa8>

ffffffffc020193a <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc020193a:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020193c:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc020193e:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201942:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201944:	326000ef          	jal	ffffffffc0201c6a <alloc_pages>
	if (!page)
ffffffffc0201948:	c91d                	beqz	a0,ffffffffc020197e <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc020194a:	0000c697          	auipc	a3,0xc
ffffffffc020194e:	b7e6b683          	ld	a3,-1154(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201952:	00004797          	auipc	a5,0x4
ffffffffc0201956:	0c67b783          	ld	a5,198(a5) # ffffffffc0205a18 <nbase>
    return KADDR(page2pa(page));
ffffffffc020195a:	0000c717          	auipc	a4,0xc
ffffffffc020195e:	b6673703          	ld	a4,-1178(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc0201962:	8d15                	sub	a0,a0,a3
ffffffffc0201964:	8519                	srai	a0,a0,0x6
ffffffffc0201966:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201968:	00c51793          	slli	a5,a0,0xc
ffffffffc020196c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020196e:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201970:	00e7fa63          	bgeu	a5,a4,ffffffffc0201984 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201974:	0000c797          	auipc	a5,0xc
ffffffffc0201978:	b447b783          	ld	a5,-1212(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc020197c:	953e                	add	a0,a0,a5
}
ffffffffc020197e:	60a2                	ld	ra,8(sp)
ffffffffc0201980:	0141                	addi	sp,sp,16
ffffffffc0201982:	8082                	ret
ffffffffc0201984:	86aa                	mv	a3,a0
ffffffffc0201986:	00003617          	auipc	a2,0x3
ffffffffc020198a:	2c260613          	addi	a2,a2,706 # ffffffffc0204c48 <etext+0xd86>
ffffffffc020198e:	07100593          	li	a1,113
ffffffffc0201992:	00003517          	auipc	a0,0x3
ffffffffc0201996:	2de50513          	addi	a0,a0,734 # ffffffffc0204c70 <etext+0xdae>
ffffffffc020199a:	a6dfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020199e <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020199e:	7179                	addi	sp,sp,-48
ffffffffc02019a0:	f406                	sd	ra,40(sp)
ffffffffc02019a2:	f022                	sd	s0,32(sp)
ffffffffc02019a4:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019a6:	01050713          	addi	a4,a0,16
ffffffffc02019aa:	6785                	lui	a5,0x1
ffffffffc02019ac:	0af77e63          	bgeu	a4,a5,ffffffffc0201a68 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019b0:	00f50413          	addi	s0,a0,15
ffffffffc02019b4:	8011                	srli	s0,s0,0x4
ffffffffc02019b6:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b8:	100025f3          	csrr	a1,sstatus
ffffffffc02019bc:	8989                	andi	a1,a1,2
ffffffffc02019be:	edd1                	bnez	a1,ffffffffc0201a5a <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc02019c0:	00007497          	auipc	s1,0x7
ffffffffc02019c4:	66048493          	addi	s1,s1,1632 # ffffffffc0209020 <slobfree>
ffffffffc02019c8:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019ca:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc02019cc:	4314                	lw	a3,0(a4)
ffffffffc02019ce:	0886da63          	bge	a3,s0,ffffffffc0201a62 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc02019d2:	00e60a63          	beq	a2,a4,ffffffffc02019e6 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019d6:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc02019d8:	4394                	lw	a3,0(a5)
ffffffffc02019da:	0286d863          	bge	a3,s0,ffffffffc0201a0a <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc02019de:	6090                	ld	a2,0(s1)
ffffffffc02019e0:	873e                	mv	a4,a5
ffffffffc02019e2:	fee61ae3          	bne	a2,a4,ffffffffc02019d6 <slob_alloc.constprop.0+0x38>
    if (flag) {
ffffffffc02019e6:	e9b1                	bnez	a1,ffffffffc0201a3a <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019e8:	4501                	li	a0,0
ffffffffc02019ea:	f51ff0ef          	jal	ffffffffc020193a <__slob_get_free_pages.constprop.0>
ffffffffc02019ee:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc02019f0:	c915                	beqz	a0,ffffffffc0201a24 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019f2:	6585                	lui	a1,0x1
ffffffffc02019f4:	e35ff0ef          	jal	ffffffffc0201828 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019f8:	100025f3          	csrr	a1,sstatus
ffffffffc02019fc:	8989                	andi	a1,a1,2
ffffffffc02019fe:	e98d                	bnez	a1,ffffffffc0201a30 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201a00:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a02:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201a04:	4394                	lw	a3,0(a5)
ffffffffc0201a06:	fc86cce3          	blt	a3,s0,ffffffffc02019de <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a0a:	04d40563          	beq	s0,a3,ffffffffc0201a54 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201a0e:	00441613          	slli	a2,s0,0x4
ffffffffc0201a12:	963e                	add	a2,a2,a5
ffffffffc0201a14:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201a16:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201a18:	9e81                	subw	a3,a3,s0
ffffffffc0201a1a:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201a1c:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201a1e:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201a20:	e098                	sd	a4,0(s1)
    if (flag) {
ffffffffc0201a22:	ed99                	bnez	a1,ffffffffc0201a40 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201a24:	70a2                	ld	ra,40(sp)
ffffffffc0201a26:	7402                	ld	s0,32(sp)
ffffffffc0201a28:	64e2                	ld	s1,24(sp)
ffffffffc0201a2a:	853e                	mv	a0,a5
ffffffffc0201a2c:	6145                	addi	sp,sp,48
ffffffffc0201a2e:	8082                	ret
        intr_disable();
ffffffffc0201a30:	e45fe0ef          	jal	ffffffffc0200874 <intr_disable>
			cur = slobfree;
ffffffffc0201a34:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201a36:	4585                	li	a1,1
ffffffffc0201a38:	b7e9                	j	ffffffffc0201a02 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201a3a:	e35fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a3e:	b76d                	j	ffffffffc02019e8 <slob_alloc.constprop.0+0x4a>
ffffffffc0201a40:	e43e                	sd	a5,8(sp)
ffffffffc0201a42:	e2dfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a46:	67a2                	ld	a5,8(sp)
}
ffffffffc0201a48:	70a2                	ld	ra,40(sp)
ffffffffc0201a4a:	7402                	ld	s0,32(sp)
ffffffffc0201a4c:	64e2                	ld	s1,24(sp)
ffffffffc0201a4e:	853e                	mv	a0,a5
ffffffffc0201a50:	6145                	addi	sp,sp,48
ffffffffc0201a52:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a54:	6794                	ld	a3,8(a5)
ffffffffc0201a56:	e714                	sd	a3,8(a4)
ffffffffc0201a58:	b7e1                	j	ffffffffc0201a20 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201a5a:	e1bfe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0201a5e:	4585                	li	a1,1
ffffffffc0201a60:	b785                	j	ffffffffc02019c0 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a62:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201a64:	8732                	mv	a4,a2
ffffffffc0201a66:	b755                	j	ffffffffc0201a0a <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a68:	00003697          	auipc	a3,0x3
ffffffffc0201a6c:	21868693          	addi	a3,a3,536 # ffffffffc0204c80 <etext+0xdbe>
ffffffffc0201a70:	00003617          	auipc	a2,0x3
ffffffffc0201a74:	e2860613          	addi	a2,a2,-472 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0201a78:	06300593          	li	a1,99
ffffffffc0201a7c:	00003517          	auipc	a0,0x3
ffffffffc0201a80:	22450513          	addi	a0,a0,548 # ffffffffc0204ca0 <etext+0xdde>
ffffffffc0201a84:	983fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201a88 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a88:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a8a:	00003517          	auipc	a0,0x3
ffffffffc0201a8e:	22e50513          	addi	a0,a0,558 # ffffffffc0204cb8 <etext+0xdf6>
{
ffffffffc0201a92:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a94:	f00fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a98:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a9a:	00003517          	auipc	a0,0x3
ffffffffc0201a9e:	23650513          	addi	a0,a0,566 # ffffffffc0204cd0 <etext+0xe0e>
}
ffffffffc0201aa2:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201aa4:	ef0fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201aa8 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201aa8:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aaa:	6685                	lui	a3,0x1
{
ffffffffc0201aac:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aae:	16bd                	addi	a3,a3,-17 # fef <kern_entry-0xffffffffc01ff011>
ffffffffc0201ab0:	04a6f963          	bgeu	a3,a0,ffffffffc0201b02 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ab4:	e42a                	sd	a0,8(sp)
ffffffffc0201ab6:	4561                	li	a0,24
ffffffffc0201ab8:	e822                	sd	s0,16(sp)
ffffffffc0201aba:	ee5ff0ef          	jal	ffffffffc020199e <slob_alloc.constprop.0>
ffffffffc0201abe:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201ac0:	c541                	beqz	a0,ffffffffc0201b48 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201ac2:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201ac4:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201ac6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ac8:	00f75763          	bge	a4,a5,ffffffffc0201ad6 <kmalloc+0x2e>
ffffffffc0201acc:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201ad0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ad2:	fef74de3          	blt	a4,a5,ffffffffc0201acc <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201ad6:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ad8:	e63ff0ef          	jal	ffffffffc020193a <__slob_get_free_pages.constprop.0>
ffffffffc0201adc:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201ade:	cd31                	beqz	a0,ffffffffc0201b3a <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ae0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ae4:	8b89                	andi	a5,a5,2
ffffffffc0201ae6:	eb85                	bnez	a5,ffffffffc0201b16 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201ae8:	0000c797          	auipc	a5,0xc
ffffffffc0201aec:	9b07b783          	ld	a5,-1616(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201af0:	0000c717          	auipc	a4,0xc
ffffffffc0201af4:	9a873423          	sd	s0,-1624(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201af8:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0201afa:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201afc:	60e2                	ld	ra,24(sp)
ffffffffc0201afe:	6105                	addi	sp,sp,32
ffffffffc0201b00:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b02:	0541                	addi	a0,a0,16
ffffffffc0201b04:	e9bff0ef          	jal	ffffffffc020199e <slob_alloc.constprop.0>
ffffffffc0201b08:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b0a:	0541                	addi	a0,a0,16
ffffffffc0201b0c:	fbe5                	bnez	a5,ffffffffc0201afc <kmalloc+0x54>
		return 0;
ffffffffc0201b0e:	4501                	li	a0,0
}
ffffffffc0201b10:	60e2                	ld	ra,24(sp)
ffffffffc0201b12:	6105                	addi	sp,sp,32
ffffffffc0201b14:	8082                	ret
        intr_disable();
ffffffffc0201b16:	d5ffe0ef          	jal	ffffffffc0200874 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b1a:	0000c797          	auipc	a5,0xc
ffffffffc0201b1e:	97e7b783          	ld	a5,-1666(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201b22:	0000c717          	auipc	a4,0xc
ffffffffc0201b26:	96873b23          	sd	s0,-1674(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201b2a:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201b2c:	d43fe0ef          	jal	ffffffffc020086e <intr_enable>
		return bb->pages;
ffffffffc0201b30:	6408                	ld	a0,8(s0)
}
ffffffffc0201b32:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201b34:	6442                	ld	s0,16(sp)
}
ffffffffc0201b36:	6105                	addi	sp,sp,32
ffffffffc0201b38:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b3a:	8522                	mv	a0,s0
ffffffffc0201b3c:	45e1                	li	a1,24
ffffffffc0201b3e:	cebff0ef          	jal	ffffffffc0201828 <slob_free>
		return 0;
ffffffffc0201b42:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b44:	6442                	ld	s0,16(sp)
ffffffffc0201b46:	b7e9                	j	ffffffffc0201b10 <kmalloc+0x68>
ffffffffc0201b48:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201b4a:	4501                	li	a0,0
ffffffffc0201b4c:	b7d1                	j	ffffffffc0201b10 <kmalloc+0x68>

ffffffffc0201b4e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b4e:	c571                	beqz	a0,ffffffffc0201c1a <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b50:	03451793          	slli	a5,a0,0x34
ffffffffc0201b54:	e3e1                	bnez	a5,ffffffffc0201c14 <kfree+0xc6>
{
ffffffffc0201b56:	1101                	addi	sp,sp,-32
ffffffffc0201b58:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b5a:	100027f3          	csrr	a5,sstatus
ffffffffc0201b5e:	8b89                	andi	a5,a5,2
ffffffffc0201b60:	e7c1                	bnez	a5,ffffffffc0201be8 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b62:	0000c797          	auipc	a5,0xc
ffffffffc0201b66:	9367b783          	ld	a5,-1738(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b6a:	4581                	li	a1,0
ffffffffc0201b6c:	cbad                	beqz	a5,ffffffffc0201bde <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b6e:	0000c617          	auipc	a2,0xc
ffffffffc0201b72:	92a60613          	addi	a2,a2,-1750 # ffffffffc020d498 <bigblocks>
ffffffffc0201b76:	a021                	j	ffffffffc0201b7e <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b78:	01070613          	addi	a2,a4,16
ffffffffc0201b7c:	c3a5                	beqz	a5,ffffffffc0201bdc <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201b7e:	6794                	ld	a3,8(a5)
ffffffffc0201b80:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201b82:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b84:	fea69ae3          	bne	a3,a0,ffffffffc0201b78 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201b88:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc0201b8a:	edb5                	bnez	a1,ffffffffc0201c06 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201b8c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b90:	0af56263          	bltu	a0,a5,ffffffffc0201c34 <kfree+0xe6>
ffffffffc0201b94:	0000c797          	auipc	a5,0xc
ffffffffc0201b98:	9247b783          	ld	a5,-1756(a5) # ffffffffc020d4b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201b9c:	0000c697          	auipc	a3,0xc
ffffffffc0201ba0:	9246b683          	ld	a3,-1756(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201ba4:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201ba6:	00c55793          	srli	a5,a0,0xc
ffffffffc0201baa:	06d7f963          	bgeu	a5,a3,ffffffffc0201c1c <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bae:	00004617          	auipc	a2,0x4
ffffffffc0201bb2:	e6a63603          	ld	a2,-406(a2) # ffffffffc0205a18 <nbase>
ffffffffc0201bb6:	0000c517          	auipc	a0,0xc
ffffffffc0201bba:	91253503          	ld	a0,-1774(a0) # ffffffffc020d4c8 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201bbe:	4314                	lw	a3,0(a4)
ffffffffc0201bc0:	8f91                	sub	a5,a5,a2
ffffffffc0201bc2:	079a                	slli	a5,a5,0x6
ffffffffc0201bc4:	4585                	li	a1,1
ffffffffc0201bc6:	953e                	add	a0,a0,a5
ffffffffc0201bc8:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201bcc:	e03a                	sd	a4,0(sp)
ffffffffc0201bce:	0d6000ef          	jal	ffffffffc0201ca4 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bd2:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bd4:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bd6:	45e1                	li	a1,24
}
ffffffffc0201bd8:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bda:	b1b9                	j	ffffffffc0201828 <slob_free>
ffffffffc0201bdc:	e185                	bnez	a1,ffffffffc0201bfc <kfree+0xae>
}
ffffffffc0201bde:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201be0:	1541                	addi	a0,a0,-16
ffffffffc0201be2:	4581                	li	a1,0
}
ffffffffc0201be4:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201be6:	b189                	j	ffffffffc0201828 <slob_free>
        intr_disable();
ffffffffc0201be8:	e02a                	sd	a0,0(sp)
ffffffffc0201bea:	c8bfe0ef          	jal	ffffffffc0200874 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bee:	0000c797          	auipc	a5,0xc
ffffffffc0201bf2:	8aa7b783          	ld	a5,-1878(a5) # ffffffffc020d498 <bigblocks>
ffffffffc0201bf6:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201bf8:	4585                	li	a1,1
ffffffffc0201bfa:	fbb5                	bnez	a5,ffffffffc0201b6e <kfree+0x20>
ffffffffc0201bfc:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201bfe:	c71fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201c02:	6502                	ld	a0,0(sp)
ffffffffc0201c04:	bfe9                	j	ffffffffc0201bde <kfree+0x90>
ffffffffc0201c06:	e42a                	sd	a0,8(sp)
ffffffffc0201c08:	e03a                	sd	a4,0(sp)
ffffffffc0201c0a:	c65fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201c0e:	6522                	ld	a0,8(sp)
ffffffffc0201c10:	6702                	ld	a4,0(sp)
ffffffffc0201c12:	bfad                	j	ffffffffc0201b8c <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c14:	1541                	addi	a0,a0,-16
ffffffffc0201c16:	4581                	li	a1,0
ffffffffc0201c18:	b901                	j	ffffffffc0201828 <slob_free>
ffffffffc0201c1a:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c1c:	00003617          	auipc	a2,0x3
ffffffffc0201c20:	0fc60613          	addi	a2,a2,252 # ffffffffc0204d18 <etext+0xe56>
ffffffffc0201c24:	06900593          	li	a1,105
ffffffffc0201c28:	00003517          	auipc	a0,0x3
ffffffffc0201c2c:	04850513          	addi	a0,a0,72 # ffffffffc0204c70 <etext+0xdae>
ffffffffc0201c30:	fd6fe0ef          	jal	ffffffffc0200406 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c34:	86aa                	mv	a3,a0
ffffffffc0201c36:	00003617          	auipc	a2,0x3
ffffffffc0201c3a:	0ba60613          	addi	a2,a2,186 # ffffffffc0204cf0 <etext+0xe2e>
ffffffffc0201c3e:	07700593          	li	a1,119
ffffffffc0201c42:	00003517          	auipc	a0,0x3
ffffffffc0201c46:	02e50513          	addi	a0,a0,46 # ffffffffc0204c70 <etext+0xdae>
ffffffffc0201c4a:	fbcfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c4e <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c4e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c50:	00003617          	auipc	a2,0x3
ffffffffc0201c54:	0c860613          	addi	a2,a2,200 # ffffffffc0204d18 <etext+0xe56>
ffffffffc0201c58:	06900593          	li	a1,105
ffffffffc0201c5c:	00003517          	auipc	a0,0x3
ffffffffc0201c60:	01450513          	addi	a0,a0,20 # ffffffffc0204c70 <etext+0xdae>
pa2page(uintptr_t pa)
ffffffffc0201c64:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c66:	fa0fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c6a <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c6a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c6e:	8b89                	andi	a5,a5,2
ffffffffc0201c70:	e799                	bnez	a5,ffffffffc0201c7e <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c72:	0000c797          	auipc	a5,0xc
ffffffffc0201c76:	82e7b783          	ld	a5,-2002(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c7a:	6f9c                	ld	a5,24(a5)
ffffffffc0201c7c:	8782                	jr	a5
{
ffffffffc0201c7e:	1101                	addi	sp,sp,-32
ffffffffc0201c80:	ec06                	sd	ra,24(sp)
ffffffffc0201c82:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201c84:	bf1fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c88:	0000c797          	auipc	a5,0xc
ffffffffc0201c8c:	8187b783          	ld	a5,-2024(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c90:	6522                	ld	a0,8(sp)
ffffffffc0201c92:	6f9c                	ld	a5,24(a5)
ffffffffc0201c94:	9782                	jalr	a5
ffffffffc0201c96:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c98:	bd7fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201c9c:	60e2                	ld	ra,24(sp)
ffffffffc0201c9e:	6522                	ld	a0,8(sp)
ffffffffc0201ca0:	6105                	addi	sp,sp,32
ffffffffc0201ca2:	8082                	ret

ffffffffc0201ca4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ca4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ca8:	8b89                	andi	a5,a5,2
ffffffffc0201caa:	e799                	bnez	a5,ffffffffc0201cb8 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201cac:	0000b797          	auipc	a5,0xb
ffffffffc0201cb0:	7f47b783          	ld	a5,2036(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cb4:	739c                	ld	a5,32(a5)
ffffffffc0201cb6:	8782                	jr	a5
{
ffffffffc0201cb8:	1101                	addi	sp,sp,-32
ffffffffc0201cba:	ec06                	sd	ra,24(sp)
ffffffffc0201cbc:	e42e                	sd	a1,8(sp)
ffffffffc0201cbe:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201cc0:	bb5fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cc4:	0000b797          	auipc	a5,0xb
ffffffffc0201cc8:	7dc7b783          	ld	a5,2012(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ccc:	65a2                	ld	a1,8(sp)
ffffffffc0201cce:	6502                	ld	a0,0(sp)
ffffffffc0201cd0:	739c                	ld	a5,32(a5)
ffffffffc0201cd2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201cd4:	60e2                	ld	ra,24(sp)
ffffffffc0201cd6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cd8:	b97fe06f          	j	ffffffffc020086e <intr_enable>

ffffffffc0201cdc <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cdc:	100027f3          	csrr	a5,sstatus
ffffffffc0201ce0:	8b89                	andi	a5,a5,2
ffffffffc0201ce2:	e799                	bnez	a5,ffffffffc0201cf0 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ce4:	0000b797          	auipc	a5,0xb
ffffffffc0201ce8:	7bc7b783          	ld	a5,1980(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cec:	779c                	ld	a5,40(a5)
ffffffffc0201cee:	8782                	jr	a5
{
ffffffffc0201cf0:	1101                	addi	sp,sp,-32
ffffffffc0201cf2:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201cf4:	b81fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cf8:	0000b797          	auipc	a5,0xb
ffffffffc0201cfc:	7a87b783          	ld	a5,1960(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d00:	779c                	ld	a5,40(a5)
ffffffffc0201d02:	9782                	jalr	a5
ffffffffc0201d04:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201d06:	b69fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d0a:	60e2                	ld	ra,24(sp)
ffffffffc0201d0c:	6522                	ld	a0,8(sp)
ffffffffc0201d0e:	6105                	addi	sp,sp,32
ffffffffc0201d10:	8082                	ret

ffffffffc0201d12 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d12:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d16:	1ff7f793          	andi	a5,a5,511
ffffffffc0201d1a:	078e                	slli	a5,a5,0x3
ffffffffc0201d1c:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d20:	6314                	ld	a3,0(a4)
{
ffffffffc0201d22:	7139                	addi	sp,sp,-64
ffffffffc0201d24:	f822                	sd	s0,48(sp)
ffffffffc0201d26:	f426                	sd	s1,40(sp)
ffffffffc0201d28:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d2a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d2e:	842e                	mv	s0,a1
ffffffffc0201d30:	8832                	mv	a6,a2
ffffffffc0201d32:	0000b497          	auipc	s1,0xb
ffffffffc0201d36:	78e48493          	addi	s1,s1,1934 # ffffffffc020d4c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d3a:	ebd1                	bnez	a5,ffffffffc0201dce <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d3c:	16060d63          	beqz	a2,ffffffffc0201eb6 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d40:	100027f3          	csrr	a5,sstatus
ffffffffc0201d44:	8b89                	andi	a5,a5,2
ffffffffc0201d46:	16079e63          	bnez	a5,ffffffffc0201ec2 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d4a:	0000b797          	auipc	a5,0xb
ffffffffc0201d4e:	7567b783          	ld	a5,1878(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d52:	4505                	li	a0,1
ffffffffc0201d54:	e43a                	sd	a4,8(sp)
ffffffffc0201d56:	6f9c                	ld	a5,24(a5)
ffffffffc0201d58:	e832                	sd	a2,16(sp)
ffffffffc0201d5a:	9782                	jalr	a5
ffffffffc0201d5c:	6722                	ld	a4,8(sp)
ffffffffc0201d5e:	6842                	ld	a6,16(sp)
ffffffffc0201d60:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d62:	14078a63          	beqz	a5,ffffffffc0201eb6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201d66:	0000b517          	auipc	a0,0xb
ffffffffc0201d6a:	76253503          	ld	a0,1890(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201d6e:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d72:	0000b497          	auipc	s1,0xb
ffffffffc0201d76:	74e48493          	addi	s1,s1,1870 # ffffffffc020d4c0 <npage>
ffffffffc0201d7a:	40a78533          	sub	a0,a5,a0
ffffffffc0201d7e:	8519                	srai	a0,a0,0x6
ffffffffc0201d80:	9546                	add	a0,a0,a7
ffffffffc0201d82:	6090                	ld	a2,0(s1)
ffffffffc0201d84:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201d88:	4585                	li	a1,1
ffffffffc0201d8a:	82b1                	srli	a3,a3,0xc
ffffffffc0201d8c:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d8e:	0532                	slli	a0,a0,0xc
ffffffffc0201d90:	1ac6f763          	bgeu	a3,a2,ffffffffc0201f3e <get_pte+0x22c>
ffffffffc0201d94:	0000b697          	auipc	a3,0xb
ffffffffc0201d98:	7246b683          	ld	a3,1828(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201d9c:	6605                	lui	a2,0x1
ffffffffc0201d9e:	4581                	li	a1,0
ffffffffc0201da0:	9536                	add	a0,a0,a3
ffffffffc0201da2:	ec42                	sd	a6,24(sp)
ffffffffc0201da4:	e83e                	sd	a5,16(sp)
ffffffffc0201da6:	e43a                	sd	a4,8(sp)
ffffffffc0201da8:	0cc020ef          	jal	ffffffffc0203e74 <memset>
    return page - pages + nbase;
ffffffffc0201dac:	0000b697          	auipc	a3,0xb
ffffffffc0201db0:	71c6b683          	ld	a3,1820(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201db4:	67c2                	ld	a5,16(sp)
ffffffffc0201db6:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201dba:	6722                	ld	a4,8(sp)
ffffffffc0201dbc:	40d786b3          	sub	a3,a5,a3
ffffffffc0201dc0:	8699                	srai	a3,a3,0x6
ffffffffc0201dc2:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201dc4:	06aa                	slli	a3,a3,0xa
ffffffffc0201dc6:	6862                	ld	a6,24(sp)
ffffffffc0201dc8:	0116e693          	ori	a3,a3,17
ffffffffc0201dcc:	e314                	sd	a3,0(a4)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201dce:	c006f693          	andi	a3,a3,-1024
ffffffffc0201dd2:	6098                	ld	a4,0(s1)
ffffffffc0201dd4:	068a                	slli	a3,a3,0x2
ffffffffc0201dd6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201dda:	14e7f663          	bgeu	a5,a4,ffffffffc0201f26 <get_pte+0x214>
ffffffffc0201dde:	0000b897          	auipc	a7,0xb
ffffffffc0201de2:	6da88893          	addi	a7,a7,1754 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201de6:	0008b603          	ld	a2,0(a7)
ffffffffc0201dea:	01545793          	srli	a5,s0,0x15
ffffffffc0201dee:	1ff7f793          	andi	a5,a5,511
ffffffffc0201df2:	96b2                	add	a3,a3,a2
ffffffffc0201df4:	078e                	slli	a5,a5,0x3
ffffffffc0201df6:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201df8:	6394                	ld	a3,0(a5)
ffffffffc0201dfa:	0016f613          	andi	a2,a3,1
ffffffffc0201dfe:	e659                	bnez	a2,ffffffffc0201e8c <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e00:	0a080b63          	beqz	a6,ffffffffc0201eb6 <get_pte+0x1a4>
ffffffffc0201e04:	10002773          	csrr	a4,sstatus
ffffffffc0201e08:	8b09                	andi	a4,a4,2
ffffffffc0201e0a:	ef71                	bnez	a4,ffffffffc0201ee6 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e0c:	0000b717          	auipc	a4,0xb
ffffffffc0201e10:	69473703          	ld	a4,1684(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201e14:	4505                	li	a0,1
ffffffffc0201e16:	e43e                	sd	a5,8(sp)
ffffffffc0201e18:	6f18                	ld	a4,24(a4)
ffffffffc0201e1a:	9702                	jalr	a4
ffffffffc0201e1c:	67a2                	ld	a5,8(sp)
ffffffffc0201e1e:	872a                	mv	a4,a0
ffffffffc0201e20:	0000b897          	auipc	a7,0xb
ffffffffc0201e24:	69888893          	addi	a7,a7,1688 # ffffffffc020d4b8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e28:	c759                	beqz	a4,ffffffffc0201eb6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201e2a:	0000b697          	auipc	a3,0xb
ffffffffc0201e2e:	69e6b683          	ld	a3,1694(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e32:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e36:	608c                	ld	a1,0(s1)
ffffffffc0201e38:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e3c:	8699                	srai	a3,a3,0x6
ffffffffc0201e3e:	96c2                	add	a3,a3,a6
ffffffffc0201e40:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201e44:	4505                	li	a0,1
ffffffffc0201e46:	8231                	srli	a2,a2,0xc
ffffffffc0201e48:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e4a:	06b2                	slli	a3,a3,0xc
ffffffffc0201e4c:	10b67663          	bgeu	a2,a1,ffffffffc0201f58 <get_pte+0x246>
ffffffffc0201e50:	0008b503          	ld	a0,0(a7)
ffffffffc0201e54:	6605                	lui	a2,0x1
ffffffffc0201e56:	4581                	li	a1,0
ffffffffc0201e58:	9536                	add	a0,a0,a3
ffffffffc0201e5a:	e83a                	sd	a4,16(sp)
ffffffffc0201e5c:	e43e                	sd	a5,8(sp)
ffffffffc0201e5e:	016020ef          	jal	ffffffffc0203e74 <memset>
    return page - pages + nbase;
ffffffffc0201e62:	0000b697          	auipc	a3,0xb
ffffffffc0201e66:	6666b683          	ld	a3,1638(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e6a:	6742                	ld	a4,16(sp)
ffffffffc0201e6c:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e70:	67a2                	ld	a5,8(sp)
ffffffffc0201e72:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e76:	8699                	srai	a3,a3,0x6
ffffffffc0201e78:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e7a:	06aa                	slli	a3,a3,0xa
ffffffffc0201e7c:	0116e693          	ori	a3,a3,17
ffffffffc0201e80:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e82:	6098                	ld	a4,0(s1)
ffffffffc0201e84:	0000b897          	auipc	a7,0xb
ffffffffc0201e88:	63488893          	addi	a7,a7,1588 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201e8c:	c006f693          	andi	a3,a3,-1024
ffffffffc0201e90:	068a                	slli	a3,a3,0x2
ffffffffc0201e92:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e96:	06e7fc63          	bgeu	a5,a4,ffffffffc0201f0e <get_pte+0x1fc>
ffffffffc0201e9a:	0008b783          	ld	a5,0(a7)
ffffffffc0201e9e:	8031                	srli	s0,s0,0xc
ffffffffc0201ea0:	1ff47413          	andi	s0,s0,511
ffffffffc0201ea4:	040e                	slli	s0,s0,0x3
ffffffffc0201ea6:	96be                	add	a3,a3,a5
}
ffffffffc0201ea8:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201eaa:	00868533          	add	a0,a3,s0
}
ffffffffc0201eae:	7442                	ld	s0,48(sp)
ffffffffc0201eb0:	74a2                	ld	s1,40(sp)
ffffffffc0201eb2:	6121                	addi	sp,sp,64
ffffffffc0201eb4:	8082                	ret
ffffffffc0201eb6:	70e2                	ld	ra,56(sp)
ffffffffc0201eb8:	7442                	ld	s0,48(sp)
ffffffffc0201eba:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0201ebc:	4501                	li	a0,0
}
ffffffffc0201ebe:	6121                	addi	sp,sp,64
ffffffffc0201ec0:	8082                	ret
        intr_disable();
ffffffffc0201ec2:	e83a                	sd	a4,16(sp)
ffffffffc0201ec4:	ec32                	sd	a2,24(sp)
ffffffffc0201ec6:	9affe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eca:	0000b797          	auipc	a5,0xb
ffffffffc0201ece:	5d67b783          	ld	a5,1494(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ed2:	4505                	li	a0,1
ffffffffc0201ed4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ed6:	9782                	jalr	a5
ffffffffc0201ed8:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201eda:	995fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201ede:	6862                	ld	a6,24(sp)
ffffffffc0201ee0:	6742                	ld	a4,16(sp)
ffffffffc0201ee2:	67a2                	ld	a5,8(sp)
ffffffffc0201ee4:	bdbd                	j	ffffffffc0201d62 <get_pte+0x50>
        intr_disable();
ffffffffc0201ee6:	e83e                	sd	a5,16(sp)
ffffffffc0201ee8:	98dfe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0201eec:	0000b717          	auipc	a4,0xb
ffffffffc0201ef0:	5b473703          	ld	a4,1460(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ef4:	4505                	li	a0,1
ffffffffc0201ef6:	6f18                	ld	a4,24(a4)
ffffffffc0201ef8:	9702                	jalr	a4
ffffffffc0201efa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201efc:	973fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201f00:	6722                	ld	a4,8(sp)
ffffffffc0201f02:	67c2                	ld	a5,16(sp)
ffffffffc0201f04:	0000b897          	auipc	a7,0xb
ffffffffc0201f08:	5b488893          	addi	a7,a7,1460 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201f0c:	bf31                	j	ffffffffc0201e28 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f0e:	00003617          	auipc	a2,0x3
ffffffffc0201f12:	d3a60613          	addi	a2,a2,-710 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0201f16:	0fb00593          	li	a1,251
ffffffffc0201f1a:	00003517          	auipc	a0,0x3
ffffffffc0201f1e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0201f22:	ce4fe0ef          	jal	ffffffffc0200406 <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f26:	00003617          	auipc	a2,0x3
ffffffffc0201f2a:	d2260613          	addi	a2,a2,-734 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0201f2e:	0ee00593          	li	a1,238
ffffffffc0201f32:	00003517          	auipc	a0,0x3
ffffffffc0201f36:	e0650513          	addi	a0,a0,-506 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0201f3a:	cccfe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f3e:	86aa                	mv	a3,a0
ffffffffc0201f40:	00003617          	auipc	a2,0x3
ffffffffc0201f44:	d0860613          	addi	a2,a2,-760 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0201f48:	0eb00593          	li	a1,235
ffffffffc0201f4c:	00003517          	auipc	a0,0x3
ffffffffc0201f50:	dec50513          	addi	a0,a0,-532 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0201f54:	cb2fe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f58:	00003617          	auipc	a2,0x3
ffffffffc0201f5c:	cf060613          	addi	a2,a2,-784 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0201f60:	0f800593          	li	a1,248
ffffffffc0201f64:	00003517          	auipc	a0,0x3
ffffffffc0201f68:	dd450513          	addi	a0,a0,-556 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0201f6c:	c9afe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201f70 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f70:	1141                	addi	sp,sp,-16
ffffffffc0201f72:	e022                	sd	s0,0(sp)
ffffffffc0201f74:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f76:	4601                	li	a2,0
{
ffffffffc0201f78:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f7a:	d99ff0ef          	jal	ffffffffc0201d12 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f7e:	c011                	beqz	s0,ffffffffc0201f82 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f80:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f82:	c511                	beqz	a0,ffffffffc0201f8e <get_page+0x1e>
ffffffffc0201f84:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f86:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f88:	0017f713          	andi	a4,a5,1
ffffffffc0201f8c:	e709                	bnez	a4,ffffffffc0201f96 <get_page+0x26>
}
ffffffffc0201f8e:	60a2                	ld	ra,8(sp)
ffffffffc0201f90:	6402                	ld	s0,0(sp)
ffffffffc0201f92:	0141                	addi	sp,sp,16
ffffffffc0201f94:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201f96:	0000b717          	auipc	a4,0xb
ffffffffc0201f9a:	52a73703          	ld	a4,1322(a4) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f9e:	078a                	slli	a5,a5,0x2
ffffffffc0201fa0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fa2:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fc0 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fa6:	0000b517          	auipc	a0,0xb
ffffffffc0201faa:	52253503          	ld	a0,1314(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201fae:	60a2                	ld	ra,8(sp)
ffffffffc0201fb0:	6402                	ld	s0,0(sp)
ffffffffc0201fb2:	079a                	slli	a5,a5,0x6
ffffffffc0201fb4:	fe000737          	lui	a4,0xfe000
ffffffffc0201fb8:	97ba                	add	a5,a5,a4
ffffffffc0201fba:	953e                	add	a0,a0,a5
ffffffffc0201fbc:	0141                	addi	sp,sp,16
ffffffffc0201fbe:	8082                	ret
ffffffffc0201fc0:	c8fff0ef          	jal	ffffffffc0201c4e <pa2page.part.0>

ffffffffc0201fc4 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fc4:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fc6:	4601                	li	a2,0
{
ffffffffc0201fc8:	e822                	sd	s0,16(sp)
ffffffffc0201fca:	ec06                	sd	ra,24(sp)
ffffffffc0201fcc:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fce:	d45ff0ef          	jal	ffffffffc0201d12 <get_pte>
    if (ptep != NULL)
ffffffffc0201fd2:	c511                	beqz	a0,ffffffffc0201fde <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0201fd4:	6118                	ld	a4,0(a0)
ffffffffc0201fd6:	87aa                	mv	a5,a0
ffffffffc0201fd8:	00177693          	andi	a3,a4,1
ffffffffc0201fdc:	e689                	bnez	a3,ffffffffc0201fe6 <page_remove+0x22>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fde:	60e2                	ld	ra,24(sp)
ffffffffc0201fe0:	6442                	ld	s0,16(sp)
ffffffffc0201fe2:	6105                	addi	sp,sp,32
ffffffffc0201fe4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201fe6:	0000b697          	auipc	a3,0xb
ffffffffc0201fea:	4da6b683          	ld	a3,1242(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fee:	070a                	slli	a4,a4,0x2
ffffffffc0201ff0:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0201ff2:	06d77563          	bgeu	a4,a3,ffffffffc020205c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ff6:	0000b517          	auipc	a0,0xb
ffffffffc0201ffa:	4d253503          	ld	a0,1234(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201ffe:	071a                	slli	a4,a4,0x6
ffffffffc0202000:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202004:	9736                	add	a4,a4,a3
ffffffffc0202006:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202008:	4118                	lw	a4,0(a0)
ffffffffc020200a:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3ddf2b0f>
ffffffffc020200c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020200e:	cb09                	beqz	a4,ffffffffc0202020 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202010:	0007b023          	sd	zero,0(a5)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202014:	12040073          	sfence.vma	s0
}
ffffffffc0202018:	60e2                	ld	ra,24(sp)
ffffffffc020201a:	6442                	ld	s0,16(sp)
ffffffffc020201c:	6105                	addi	sp,sp,32
ffffffffc020201e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202020:	10002773          	csrr	a4,sstatus
ffffffffc0202024:	8b09                	andi	a4,a4,2
ffffffffc0202026:	eb19                	bnez	a4,ffffffffc020203c <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202028:	0000b717          	auipc	a4,0xb
ffffffffc020202c:	47873703          	ld	a4,1144(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202030:	4585                	li	a1,1
ffffffffc0202032:	e03e                	sd	a5,0(sp)
ffffffffc0202034:	7318                	ld	a4,32(a4)
ffffffffc0202036:	9702                	jalr	a4
    if (flag) {
ffffffffc0202038:	6782                	ld	a5,0(sp)
ffffffffc020203a:	bfd9                	j	ffffffffc0202010 <page_remove+0x4c>
        intr_disable();
ffffffffc020203c:	e43e                	sd	a5,8(sp)
ffffffffc020203e:	e02a                	sd	a0,0(sp)
ffffffffc0202040:	835fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202044:	0000b717          	auipc	a4,0xb
ffffffffc0202048:	45c73703          	ld	a4,1116(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc020204c:	6502                	ld	a0,0(sp)
ffffffffc020204e:	4585                	li	a1,1
ffffffffc0202050:	7318                	ld	a4,32(a4)
ffffffffc0202052:	9702                	jalr	a4
        intr_enable();
ffffffffc0202054:	81bfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202058:	67a2                	ld	a5,8(sp)
ffffffffc020205a:	bf5d                	j	ffffffffc0202010 <page_remove+0x4c>
ffffffffc020205c:	bf3ff0ef          	jal	ffffffffc0201c4e <pa2page.part.0>

ffffffffc0202060 <page_insert>:
{
ffffffffc0202060:	7139                	addi	sp,sp,-64
ffffffffc0202062:	f426                	sd	s1,40(sp)
ffffffffc0202064:	84b2                	mv	s1,a2
ffffffffc0202066:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202068:	4605                	li	a2,1
{
ffffffffc020206a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020206c:	85a6                	mv	a1,s1
{
ffffffffc020206e:	fc06                	sd	ra,56(sp)
ffffffffc0202070:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202072:	ca1ff0ef          	jal	ffffffffc0201d12 <get_pte>
    if (ptep == NULL)
ffffffffc0202076:	cd61                	beqz	a0,ffffffffc020214e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202078:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020207a:	611c                	ld	a5,0(a0)
ffffffffc020207c:	66a2                	ld	a3,8(sp)
ffffffffc020207e:	0015861b          	addiw	a2,a1,1 # 1001 <kern_entry-0xffffffffc01fefff>
ffffffffc0202082:	c010                	sw	a2,0(s0)
ffffffffc0202084:	0017f613          	andi	a2,a5,1
ffffffffc0202088:	872a                	mv	a4,a0
ffffffffc020208a:	e61d                	bnez	a2,ffffffffc02020b8 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020208c:	0000b617          	auipc	a2,0xb
ffffffffc0202090:	43c63603          	ld	a2,1084(a2) # ffffffffc020d4c8 <pages>
    return page - pages + nbase;
ffffffffc0202094:	8c11                	sub	s0,s0,a2
ffffffffc0202096:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202098:	200007b7          	lui	a5,0x20000
ffffffffc020209c:	042a                	slli	s0,s0,0xa
ffffffffc020209e:	943e                	add	s0,s0,a5
ffffffffc02020a0:	8ec1                	or	a3,a3,s0
ffffffffc02020a2:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02020a6:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020a8:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02020ac:	4501                	li	a0,0
}
ffffffffc02020ae:	70e2                	ld	ra,56(sp)
ffffffffc02020b0:	7442                	ld	s0,48(sp)
ffffffffc02020b2:	74a2                	ld	s1,40(sp)
ffffffffc02020b4:	6121                	addi	sp,sp,64
ffffffffc02020b6:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020b8:	0000b617          	auipc	a2,0xb
ffffffffc02020bc:	40863603          	ld	a2,1032(a2) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020c0:	078a                	slli	a5,a5,0x2
ffffffffc02020c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020c4:	08c7f763          	bgeu	a5,a2,ffffffffc0202152 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020c8:	0000b617          	auipc	a2,0xb
ffffffffc02020cc:	40063603          	ld	a2,1024(a2) # ffffffffc020d4c8 <pages>
ffffffffc02020d0:	fe000537          	lui	a0,0xfe000
ffffffffc02020d4:	079a                	slli	a5,a5,0x6
ffffffffc02020d6:	97aa                	add	a5,a5,a0
ffffffffc02020d8:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02020dc:	00a40963          	beq	s0,a0,ffffffffc02020ee <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02020e0:	411c                	lw	a5,0(a0)
ffffffffc02020e2:	37fd                	addiw	a5,a5,-1 # 1fffffff <kern_entry-0xffffffffa0200001>
ffffffffc02020e4:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc02020e6:	c791                	beqz	a5,ffffffffc02020f2 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020e8:	12048073          	sfence.vma	s1
}
ffffffffc02020ec:	b765                	j	ffffffffc0202094 <page_insert+0x34>
ffffffffc02020ee:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02020f0:	b755                	j	ffffffffc0202094 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020f2:	100027f3          	csrr	a5,sstatus
ffffffffc02020f6:	8b89                	andi	a5,a5,2
ffffffffc02020f8:	e39d                	bnez	a5,ffffffffc020211e <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02020fa:	0000b797          	auipc	a5,0xb
ffffffffc02020fe:	3a67b783          	ld	a5,934(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202102:	4585                	li	a1,1
ffffffffc0202104:	e83a                	sd	a4,16(sp)
ffffffffc0202106:	739c                	ld	a5,32(a5)
ffffffffc0202108:	e436                	sd	a3,8(sp)
ffffffffc020210a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020210c:	0000b617          	auipc	a2,0xb
ffffffffc0202110:	3bc63603          	ld	a2,956(a2) # ffffffffc020d4c8 <pages>
ffffffffc0202114:	66a2                	ld	a3,8(sp)
ffffffffc0202116:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202118:	12048073          	sfence.vma	s1
ffffffffc020211c:	bfa5                	j	ffffffffc0202094 <page_insert+0x34>
        intr_disable();
ffffffffc020211e:	ec3a                	sd	a4,24(sp)
ffffffffc0202120:	e836                	sd	a3,16(sp)
ffffffffc0202122:	e42a                	sd	a0,8(sp)
ffffffffc0202124:	f50fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202128:	0000b797          	auipc	a5,0xb
ffffffffc020212c:	3787b783          	ld	a5,888(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202130:	6522                	ld	a0,8(sp)
ffffffffc0202132:	4585                	li	a1,1
ffffffffc0202134:	739c                	ld	a5,32(a5)
ffffffffc0202136:	9782                	jalr	a5
        intr_enable();
ffffffffc0202138:	f36fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020213c:	0000b617          	auipc	a2,0xb
ffffffffc0202140:	38c63603          	ld	a2,908(a2) # ffffffffc020d4c8 <pages>
ffffffffc0202144:	6762                	ld	a4,24(sp)
ffffffffc0202146:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202148:	12048073          	sfence.vma	s1
ffffffffc020214c:	b7a1                	j	ffffffffc0202094 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc020214e:	5571                	li	a0,-4
ffffffffc0202150:	bfb9                	j	ffffffffc02020ae <page_insert+0x4e>
ffffffffc0202152:	afdff0ef          	jal	ffffffffc0201c4e <pa2page.part.0>

ffffffffc0202156 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202156:	00003797          	auipc	a5,0x3
ffffffffc020215a:	6fa78793          	addi	a5,a5,1786 # ffffffffc0205850 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020215e:	638c                	ld	a1,0(a5)
{
ffffffffc0202160:	7159                	addi	sp,sp,-112
ffffffffc0202162:	f486                	sd	ra,104(sp)
ffffffffc0202164:	e8ca                	sd	s2,80(sp)
ffffffffc0202166:	e4ce                	sd	s3,72(sp)
ffffffffc0202168:	f85a                	sd	s6,48(sp)
ffffffffc020216a:	f0a2                	sd	s0,96(sp)
ffffffffc020216c:	eca6                	sd	s1,88(sp)
ffffffffc020216e:	e0d2                	sd	s4,64(sp)
ffffffffc0202170:	fc56                	sd	s5,56(sp)
ffffffffc0202172:	f45e                	sd	s7,40(sp)
ffffffffc0202174:	f062                	sd	s8,32(sp)
ffffffffc0202176:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202178:	0000bb17          	auipc	s6,0xb
ffffffffc020217c:	328b0b13          	addi	s6,s6,808 # ffffffffc020d4a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202180:	00003517          	auipc	a0,0x3
ffffffffc0202184:	bc850513          	addi	a0,a0,-1080 # ffffffffc0204d48 <etext+0xe86>
    pmm_manager = &default_pmm_manager;
ffffffffc0202188:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020218c:	808fe0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202190:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202194:	0000b997          	auipc	s3,0xb
ffffffffc0202198:	32498993          	addi	s3,s3,804 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc020219c:	679c                	ld	a5,8(a5)
ffffffffc020219e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021a0:	57f5                	li	a5,-3
ffffffffc02021a2:	07fa                	slli	a5,a5,0x1e
ffffffffc02021a4:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021a8:	eb2fe0ef          	jal	ffffffffc020085a <get_memory_base>
ffffffffc02021ac:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021ae:	eb6fe0ef          	jal	ffffffffc0200864 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021b2:	70050e63          	beqz	a0,ffffffffc02028ce <pmm_init+0x778>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021b6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021b8:	00003517          	auipc	a0,0x3
ffffffffc02021bc:	bc850513          	addi	a0,a0,-1080 # ffffffffc0204d80 <etext+0xebe>
ffffffffc02021c0:	fd5fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021c4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021c8:	864a                	mv	a2,s2
ffffffffc02021ca:	85a6                	mv	a1,s1
ffffffffc02021cc:	fff40693          	addi	a3,s0,-1
ffffffffc02021d0:	00003517          	auipc	a0,0x3
ffffffffc02021d4:	bc850513          	addi	a0,a0,-1080 # ffffffffc0204d98 <etext+0xed6>
ffffffffc02021d8:	fbdfd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02021dc:	c80007b7          	lui	a5,0xc8000
ffffffffc02021e0:	8522                	mv	a0,s0
ffffffffc02021e2:	5287ed63          	bltu	a5,s0,ffffffffc020271c <pmm_init+0x5c6>
ffffffffc02021e6:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021e8:	0000c617          	auipc	a2,0xc
ffffffffc02021ec:	30760613          	addi	a2,a2,775 # ffffffffc020e4ef <end+0xfff>
ffffffffc02021f0:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02021f2:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021f4:	0000bb97          	auipc	s7,0xb
ffffffffc02021f8:	2d4b8b93          	addi	s7,s7,724 # ffffffffc020d4c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02021fc:	0000b497          	auipc	s1,0xb
ffffffffc0202200:	2c448493          	addi	s1,s1,708 # ffffffffc020d4c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202204:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202208:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020220a:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020220e:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202210:	02f50763          	beq	a0,a5,ffffffffc020223e <pmm_init+0xe8>
ffffffffc0202214:	4701                	li	a4,0
ffffffffc0202216:	4585                	li	a1,1
ffffffffc0202218:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020221c:	00671793          	slli	a5,a4,0x6
ffffffffc0202220:	97b2                	add	a5,a5,a2
ffffffffc0202222:	07a1                	addi	a5,a5,8 # 80008 <kern_entry-0xffffffffc017fff8>
ffffffffc0202224:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202228:	6088                	ld	a0,0(s1)
ffffffffc020222a:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020222c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202230:	00d507b3          	add	a5,a0,a3
ffffffffc0202234:	fef764e3          	bltu	a4,a5,ffffffffc020221c <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202238:	079a                	slli	a5,a5,0x6
ffffffffc020223a:	00f606b3          	add	a3,a2,a5
ffffffffc020223e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202242:	16f6eee3          	bltu	a3,a5,ffffffffc0202bbe <pmm_init+0xa68>
ffffffffc0202246:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020224a:	77fd                	lui	a5,0xfffff
ffffffffc020224c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020224e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202250:	4e86ed63          	bltu	a3,s0,ffffffffc020274a <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202254:	00003517          	auipc	a0,0x3
ffffffffc0202258:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204dc0 <etext+0xefe>
ffffffffc020225c:	f39fd0ef          	jal	ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202260:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202264:	0000b917          	auipc	s2,0xb
ffffffffc0202268:	24c90913          	addi	s2,s2,588 # ffffffffc020d4b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020226c:	7b9c                	ld	a5,48(a5)
ffffffffc020226e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202270:	00003517          	auipc	a0,0x3
ffffffffc0202274:	b6850513          	addi	a0,a0,-1176 # ffffffffc0204dd8 <etext+0xf16>
ffffffffc0202278:	f1dfd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020227c:	00006697          	auipc	a3,0x6
ffffffffc0202280:	d8468693          	addi	a3,a3,-636 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202284:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202288:	c02007b7          	lui	a5,0xc0200
ffffffffc020228c:	2af6eee3          	bltu	a3,a5,ffffffffc0202d48 <pmm_init+0xbf2>
ffffffffc0202290:	0009b783          	ld	a5,0(s3)
ffffffffc0202294:	8e9d                	sub	a3,a3,a5
ffffffffc0202296:	0000b797          	auipc	a5,0xb
ffffffffc020229a:	20d7b923          	sd	a3,530(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020229e:	100027f3          	csrr	a5,sstatus
ffffffffc02022a2:	8b89                	andi	a5,a5,2
ffffffffc02022a4:	48079963          	bnez	a5,ffffffffc0202736 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022a8:	000b3783          	ld	a5,0(s6)
ffffffffc02022ac:	779c                	ld	a5,40(a5)
ffffffffc02022ae:	9782                	jalr	a5
ffffffffc02022b0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022b2:	6098                	ld	a4,0(s1)
ffffffffc02022b4:	c80007b7          	lui	a5,0xc8000
ffffffffc02022b8:	83b1                	srli	a5,a5,0xc
ffffffffc02022ba:	66e7e663          	bltu	a5,a4,ffffffffc0202926 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022be:	00093503          	ld	a0,0(s2)
ffffffffc02022c2:	64050263          	beqz	a0,ffffffffc0202906 <pmm_init+0x7b0>
ffffffffc02022c6:	03451793          	slli	a5,a0,0x34
ffffffffc02022ca:	62079e63          	bnez	a5,ffffffffc0202906 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022ce:	4601                	li	a2,0
ffffffffc02022d0:	4581                	li	a1,0
ffffffffc02022d2:	c9fff0ef          	jal	ffffffffc0201f70 <get_page>
ffffffffc02022d6:	240519e3          	bnez	a0,ffffffffc0202d28 <pmm_init+0xbd2>
ffffffffc02022da:	100027f3          	csrr	a5,sstatus
ffffffffc02022de:	8b89                	andi	a5,a5,2
ffffffffc02022e0:	44079063          	bnez	a5,ffffffffc0202720 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022e4:	000b3783          	ld	a5,0(s6)
ffffffffc02022e8:	4505                	li	a0,1
ffffffffc02022ea:	6f9c                	ld	a5,24(a5)
ffffffffc02022ec:	9782                	jalr	a5
ffffffffc02022ee:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022f0:	00093503          	ld	a0,0(s2)
ffffffffc02022f4:	4681                	li	a3,0
ffffffffc02022f6:	4601                	li	a2,0
ffffffffc02022f8:	85d2                	mv	a1,s4
ffffffffc02022fa:	d67ff0ef          	jal	ffffffffc0202060 <page_insert>
ffffffffc02022fe:	280511e3          	bnez	a0,ffffffffc0202d80 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202302:	00093503          	ld	a0,0(s2)
ffffffffc0202306:	4601                	li	a2,0
ffffffffc0202308:	4581                	li	a1,0
ffffffffc020230a:	a09ff0ef          	jal	ffffffffc0201d12 <get_pte>
ffffffffc020230e:	240509e3          	beqz	a0,ffffffffc0202d60 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202312:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202314:	0017f713          	andi	a4,a5,1
ffffffffc0202318:	58070f63          	beqz	a4,ffffffffc02028b6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020231c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020231e:	078a                	slli	a5,a5,0x2
ffffffffc0202320:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202322:	58e7f863          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202326:	000bb683          	ld	a3,0(s7)
ffffffffc020232a:	079a                	slli	a5,a5,0x6
ffffffffc020232c:	fe000637          	lui	a2,0xfe000
ffffffffc0202330:	97b2                	add	a5,a5,a2
ffffffffc0202332:	97b6                	add	a5,a5,a3
ffffffffc0202334:	14fa1ae3          	bne	s4,a5,ffffffffc0202c88 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202338:	000a2683          	lw	a3,0(s4)
ffffffffc020233c:	4785                	li	a5,1
ffffffffc020233e:	12f695e3          	bne	a3,a5,ffffffffc0202c68 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202342:	00093503          	ld	a0,0(s2)
ffffffffc0202346:	77fd                	lui	a5,0xfffff
ffffffffc0202348:	6114                	ld	a3,0(a0)
ffffffffc020234a:	068a                	slli	a3,a3,0x2
ffffffffc020234c:	8efd                	and	a3,a3,a5
ffffffffc020234e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202352:	0ee67fe3          	bgeu	a2,a4,ffffffffc0202c50 <pmm_init+0xafa>
ffffffffc0202356:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020235a:	96e2                	add	a3,a3,s8
ffffffffc020235c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202360:	0a8a                	slli	s5,s5,0x2
ffffffffc0202362:	00fafab3          	and	s5,s5,a5
ffffffffc0202366:	00cad793          	srli	a5,s5,0xc
ffffffffc020236a:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0202c36 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020236e:	4601                	li	a2,0
ffffffffc0202370:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202372:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202374:	99fff0ef          	jal	ffffffffc0201d12 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202378:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020237a:	05851ee3          	bne	a0,s8,ffffffffc0202bd6 <pmm_init+0xa80>
ffffffffc020237e:	100027f3          	csrr	a5,sstatus
ffffffffc0202382:	8b89                	andi	a5,a5,2
ffffffffc0202384:	3e079b63          	bnez	a5,ffffffffc020277a <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202388:	000b3783          	ld	a5,0(s6)
ffffffffc020238c:	4505                	li	a0,1
ffffffffc020238e:	6f9c                	ld	a5,24(a5)
ffffffffc0202390:	9782                	jalr	a5
ffffffffc0202392:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202394:	00093503          	ld	a0,0(s2)
ffffffffc0202398:	46d1                	li	a3,20
ffffffffc020239a:	6605                	lui	a2,0x1
ffffffffc020239c:	85e2                	mv	a1,s8
ffffffffc020239e:	cc3ff0ef          	jal	ffffffffc0202060 <page_insert>
ffffffffc02023a2:	06051ae3          	bnez	a0,ffffffffc0202c16 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023a6:	00093503          	ld	a0,0(s2)
ffffffffc02023aa:	4601                	li	a2,0
ffffffffc02023ac:	6585                	lui	a1,0x1
ffffffffc02023ae:	965ff0ef          	jal	ffffffffc0201d12 <get_pte>
ffffffffc02023b2:	040502e3          	beqz	a0,ffffffffc0202bf6 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02023b6:	611c                	ld	a5,0(a0)
ffffffffc02023b8:	0107f713          	andi	a4,a5,16
ffffffffc02023bc:	7e070163          	beqz	a4,ffffffffc0202b9e <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02023c0:	8b91                	andi	a5,a5,4
ffffffffc02023c2:	7a078e63          	beqz	a5,ffffffffc0202b7e <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023c6:	00093503          	ld	a0,0(s2)
ffffffffc02023ca:	611c                	ld	a5,0(a0)
ffffffffc02023cc:	8bc1                	andi	a5,a5,16
ffffffffc02023ce:	78078863          	beqz	a5,ffffffffc0202b5e <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02023d2:	000c2703          	lw	a4,0(s8)
ffffffffc02023d6:	4785                	li	a5,1
ffffffffc02023d8:	76f71363          	bne	a4,a5,ffffffffc0202b3e <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023dc:	4681                	li	a3,0
ffffffffc02023de:	6605                	lui	a2,0x1
ffffffffc02023e0:	85d2                	mv	a1,s4
ffffffffc02023e2:	c7fff0ef          	jal	ffffffffc0202060 <page_insert>
ffffffffc02023e6:	72051c63          	bnez	a0,ffffffffc0202b1e <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02023ea:	000a2703          	lw	a4,0(s4)
ffffffffc02023ee:	4789                	li	a5,2
ffffffffc02023f0:	70f71763          	bne	a4,a5,ffffffffc0202afe <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc02023f4:	000c2783          	lw	a5,0(s8)
ffffffffc02023f8:	6e079363          	bnez	a5,ffffffffc0202ade <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023fc:	00093503          	ld	a0,0(s2)
ffffffffc0202400:	4601                	li	a2,0
ffffffffc0202402:	6585                	lui	a1,0x1
ffffffffc0202404:	90fff0ef          	jal	ffffffffc0201d12 <get_pte>
ffffffffc0202408:	6a050b63          	beqz	a0,ffffffffc0202abe <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc020240c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020240e:	00177793          	andi	a5,a4,1
ffffffffc0202412:	4a078263          	beqz	a5,ffffffffc02028b6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202416:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202418:	00271793          	slli	a5,a4,0x2
ffffffffc020241c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020241e:	48d7fa63          	bgeu	a5,a3,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202422:	000bb683          	ld	a3,0(s7)
ffffffffc0202426:	fff80ab7          	lui	s5,0xfff80
ffffffffc020242a:	97d6                	add	a5,a5,s5
ffffffffc020242c:	079a                	slli	a5,a5,0x6
ffffffffc020242e:	97b6                	add	a5,a5,a3
ffffffffc0202430:	66fa1763          	bne	s4,a5,ffffffffc0202a9e <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202434:	8b41                	andi	a4,a4,16
ffffffffc0202436:	64071463          	bnez	a4,ffffffffc0202a7e <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020243a:	00093503          	ld	a0,0(s2)
ffffffffc020243e:	4581                	li	a1,0
ffffffffc0202440:	b85ff0ef          	jal	ffffffffc0201fc4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202444:	000a2c83          	lw	s9,0(s4)
ffffffffc0202448:	4785                	li	a5,1
ffffffffc020244a:	60fc9a63          	bne	s9,a5,ffffffffc0202a5e <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc020244e:	000c2783          	lw	a5,0(s8)
ffffffffc0202452:	5e079663          	bnez	a5,ffffffffc0202a3e <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202456:	00093503          	ld	a0,0(s2)
ffffffffc020245a:	6585                	lui	a1,0x1
ffffffffc020245c:	b69ff0ef          	jal	ffffffffc0201fc4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202460:	000a2783          	lw	a5,0(s4)
ffffffffc0202464:	52079d63          	bnez	a5,ffffffffc020299e <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202468:	000c2783          	lw	a5,0(s8)
ffffffffc020246c:	50079963          	bnez	a5,ffffffffc020297e <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202470:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202474:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202476:	000a3783          	ld	a5,0(s4)
ffffffffc020247a:	078a                	slli	a5,a5,0x2
ffffffffc020247c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020247e:	42e7fa63          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202482:	000bb503          	ld	a0,0(s7)
ffffffffc0202486:	97d6                	add	a5,a5,s5
ffffffffc0202488:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc020248a:	00f506b3          	add	a3,a0,a5
ffffffffc020248e:	4294                	lw	a3,0(a3)
ffffffffc0202490:	4d969763          	bne	a3,s9,ffffffffc020295e <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202494:	8799                	srai	a5,a5,0x6
ffffffffc0202496:	00080637          	lui	a2,0x80
ffffffffc020249a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020249c:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02024a0:	4ae7f363          	bgeu	a5,a4,ffffffffc0202946 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024a4:	0009b783          	ld	a5,0(s3)
ffffffffc02024a8:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc02024aa:	639c                	ld	a5,0(a5)
ffffffffc02024ac:	078a                	slli	a5,a5,0x2
ffffffffc02024ae:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024b0:	40e7f163          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024b4:	8f91                	sub	a5,a5,a2
ffffffffc02024b6:	079a                	slli	a5,a5,0x6
ffffffffc02024b8:	953e                	add	a0,a0,a5
ffffffffc02024ba:	100027f3          	csrr	a5,sstatus
ffffffffc02024be:	8b89                	andi	a5,a5,2
ffffffffc02024c0:	30079863          	bnez	a5,ffffffffc02027d0 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc02024c4:	000b3783          	ld	a5,0(s6)
ffffffffc02024c8:	4585                	li	a1,1
ffffffffc02024ca:	739c                	ld	a5,32(a5)
ffffffffc02024cc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024ce:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024d2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d4:	078a                	slli	a5,a5,0x2
ffffffffc02024d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024d8:	3ce7fd63          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024dc:	000bb503          	ld	a0,0(s7)
ffffffffc02024e0:	fe000737          	lui	a4,0xfe000
ffffffffc02024e4:	079a                	slli	a5,a5,0x6
ffffffffc02024e6:	97ba                	add	a5,a5,a4
ffffffffc02024e8:	953e                	add	a0,a0,a5
ffffffffc02024ea:	100027f3          	csrr	a5,sstatus
ffffffffc02024ee:	8b89                	andi	a5,a5,2
ffffffffc02024f0:	2c079463          	bnez	a5,ffffffffc02027b8 <pmm_init+0x662>
ffffffffc02024f4:	000b3783          	ld	a5,0(s6)
ffffffffc02024f8:	4585                	li	a1,1
ffffffffc02024fa:	739c                	ld	a5,32(a5)
ffffffffc02024fc:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02024fe:	00093783          	ld	a5,0(s2)
ffffffffc0202502:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b10>
    asm volatile("sfence.vma");
ffffffffc0202506:	12000073          	sfence.vma
ffffffffc020250a:	100027f3          	csrr	a5,sstatus
ffffffffc020250e:	8b89                	andi	a5,a5,2
ffffffffc0202510:	28079a63          	bnez	a5,ffffffffc02027a4 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202514:	000b3783          	ld	a5,0(s6)
ffffffffc0202518:	779c                	ld	a5,40(a5)
ffffffffc020251a:	9782                	jalr	a5
ffffffffc020251c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc020251e:	4d441063          	bne	s0,s4,ffffffffc02029de <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202522:	00003517          	auipc	a0,0x3
ffffffffc0202526:	c0650513          	addi	a0,a0,-1018 # ffffffffc0205128 <etext+0x1266>
ffffffffc020252a:	c6bfd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc020252e:	100027f3          	csrr	a5,sstatus
ffffffffc0202532:	8b89                	andi	a5,a5,2
ffffffffc0202534:	24079e63          	bnez	a5,ffffffffc0202790 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202538:	000b3783          	ld	a5,0(s6)
ffffffffc020253c:	779c                	ld	a5,40(a5)
ffffffffc020253e:	9782                	jalr	a5
ffffffffc0202540:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202542:	609c                	ld	a5,0(s1)
ffffffffc0202544:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202548:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020254a:	00c79713          	slli	a4,a5,0xc
ffffffffc020254e:	6a85                	lui	s5,0x1
ffffffffc0202550:	02e47c63          	bgeu	s0,a4,ffffffffc0202588 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202554:	00c45713          	srli	a4,s0,0xc
ffffffffc0202558:	30f77063          	bgeu	a4,a5,ffffffffc0202858 <pmm_init+0x702>
ffffffffc020255c:	0009b583          	ld	a1,0(s3)
ffffffffc0202560:	00093503          	ld	a0,0(s2)
ffffffffc0202564:	4601                	li	a2,0
ffffffffc0202566:	95a2                	add	a1,a1,s0
ffffffffc0202568:	faaff0ef          	jal	ffffffffc0201d12 <get_pte>
ffffffffc020256c:	32050363          	beqz	a0,ffffffffc0202892 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202570:	611c                	ld	a5,0(a0)
ffffffffc0202572:	078a                	slli	a5,a5,0x2
ffffffffc0202574:	0147f7b3          	and	a5,a5,s4
ffffffffc0202578:	2e879d63          	bne	a5,s0,ffffffffc0202872 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020257c:	609c                	ld	a5,0(s1)
ffffffffc020257e:	9456                	add	s0,s0,s5
ffffffffc0202580:	00c79713          	slli	a4,a5,0xc
ffffffffc0202584:	fce468e3          	bltu	s0,a4,ffffffffc0202554 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202588:	00093783          	ld	a5,0(s2)
ffffffffc020258c:	639c                	ld	a5,0(a5)
ffffffffc020258e:	42079863          	bnez	a5,ffffffffc02029be <pmm_init+0x868>
ffffffffc0202592:	100027f3          	csrr	a5,sstatus
ffffffffc0202596:	8b89                	andi	a5,a5,2
ffffffffc0202598:	24079863          	bnez	a5,ffffffffc02027e8 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc020259c:	000b3783          	ld	a5,0(s6)
ffffffffc02025a0:	4505                	li	a0,1
ffffffffc02025a2:	6f9c                	ld	a5,24(a5)
ffffffffc02025a4:	9782                	jalr	a5
ffffffffc02025a6:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025a8:	00093503          	ld	a0,0(s2)
ffffffffc02025ac:	4699                	li	a3,6
ffffffffc02025ae:	10000613          	li	a2,256
ffffffffc02025b2:	85a2                	mv	a1,s0
ffffffffc02025b4:	aadff0ef          	jal	ffffffffc0202060 <page_insert>
ffffffffc02025b8:	46051363          	bnez	a0,ffffffffc0202a1e <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc02025bc:	4018                	lw	a4,0(s0)
ffffffffc02025be:	4785                	li	a5,1
ffffffffc02025c0:	42f71f63          	bne	a4,a5,ffffffffc02029fe <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025c4:	00093503          	ld	a0,0(s2)
ffffffffc02025c8:	6605                	lui	a2,0x1
ffffffffc02025ca:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025ce:	4699                	li	a3,6
ffffffffc02025d0:	85a2                	mv	a1,s0
ffffffffc02025d2:	a8fff0ef          	jal	ffffffffc0202060 <page_insert>
ffffffffc02025d6:	72051963          	bnez	a0,ffffffffc0202d08 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc02025da:	4018                	lw	a4,0(s0)
ffffffffc02025dc:	4789                	li	a5,2
ffffffffc02025de:	70f71563          	bne	a4,a5,ffffffffc0202ce8 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025e2:	00003597          	auipc	a1,0x3
ffffffffc02025e6:	c8e58593          	addi	a1,a1,-882 # ffffffffc0205270 <etext+0x13ae>
ffffffffc02025ea:	10000513          	li	a0,256
ffffffffc02025ee:	007010ef          	jal	ffffffffc0203df4 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025f2:	6585                	lui	a1,0x1
ffffffffc02025f4:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025f8:	10000513          	li	a0,256
ffffffffc02025fc:	00b010ef          	jal	ffffffffc0203e06 <strcmp>
ffffffffc0202600:	6c051463          	bnez	a0,ffffffffc0202cc8 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202604:	000bb683          	ld	a3,0(s7)
ffffffffc0202608:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc020260c:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc020260e:	40d406b3          	sub	a3,s0,a3
ffffffffc0202612:	8699                	srai	a3,a3,0x6
ffffffffc0202614:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202616:	00c69793          	slli	a5,a3,0xc
ffffffffc020261a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020261c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020261e:	32e7f463          	bgeu	a5,a4,ffffffffc0202946 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202622:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202626:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020262a:	97b6                	add	a5,a5,a3
ffffffffc020262c:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202630:	790010ef          	jal	ffffffffc0203dc0 <strlen>
ffffffffc0202634:	66051a63          	bnez	a0,ffffffffc0202ca8 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202638:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020263c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020263e:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fdf1b10>
ffffffffc0202642:	078a                	slli	a5,a5,0x2
ffffffffc0202644:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202646:	26e7f663          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc020264a:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020264e:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202946 <pmm_init+0x7f0>
ffffffffc0202652:	0009b783          	ld	a5,0(s3)
ffffffffc0202656:	00f689b3          	add	s3,a3,a5
ffffffffc020265a:	100027f3          	csrr	a5,sstatus
ffffffffc020265e:	8b89                	andi	a5,a5,2
ffffffffc0202660:	1e079163          	bnez	a5,ffffffffc0202842 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202664:	000b3783          	ld	a5,0(s6)
ffffffffc0202668:	8522                	mv	a0,s0
ffffffffc020266a:	4585                	li	a1,1
ffffffffc020266c:	739c                	ld	a5,32(a5)
ffffffffc020266e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202670:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202674:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202676:	078a                	slli	a5,a5,0x2
ffffffffc0202678:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020267a:	22e7fc63          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020267e:	000bb503          	ld	a0,0(s7)
ffffffffc0202682:	fe000737          	lui	a4,0xfe000
ffffffffc0202686:	079a                	slli	a5,a5,0x6
ffffffffc0202688:	97ba                	add	a5,a5,a4
ffffffffc020268a:	953e                	add	a0,a0,a5
ffffffffc020268c:	100027f3          	csrr	a5,sstatus
ffffffffc0202690:	8b89                	andi	a5,a5,2
ffffffffc0202692:	18079c63          	bnez	a5,ffffffffc020282a <pmm_init+0x6d4>
ffffffffc0202696:	000b3783          	ld	a5,0(s6)
ffffffffc020269a:	4585                	li	a1,1
ffffffffc020269c:	739c                	ld	a5,32(a5)
ffffffffc020269e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02026a4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a6:	078a                	slli	a5,a5,0x2
ffffffffc02026a8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026aa:	20e7f463          	bgeu	a5,a4,ffffffffc02028b2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02026ae:	000bb503          	ld	a0,0(s7)
ffffffffc02026b2:	fe000737          	lui	a4,0xfe000
ffffffffc02026b6:	079a                	slli	a5,a5,0x6
ffffffffc02026b8:	97ba                	add	a5,a5,a4
ffffffffc02026ba:	953e                	add	a0,a0,a5
ffffffffc02026bc:	100027f3          	csrr	a5,sstatus
ffffffffc02026c0:	8b89                	andi	a5,a5,2
ffffffffc02026c2:	14079863          	bnez	a5,ffffffffc0202812 <pmm_init+0x6bc>
ffffffffc02026c6:	000b3783          	ld	a5,0(s6)
ffffffffc02026ca:	4585                	li	a1,1
ffffffffc02026cc:	739c                	ld	a5,32(a5)
ffffffffc02026ce:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026d0:	00093783          	ld	a5,0(s2)
ffffffffc02026d4:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026d8:	12000073          	sfence.vma
ffffffffc02026dc:	100027f3          	csrr	a5,sstatus
ffffffffc02026e0:	8b89                	andi	a5,a5,2
ffffffffc02026e2:	10079e63          	bnez	a5,ffffffffc02027fe <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026e6:	000b3783          	ld	a5,0(s6)
ffffffffc02026ea:	779c                	ld	a5,40(a5)
ffffffffc02026ec:	9782                	jalr	a5
ffffffffc02026ee:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026f0:	1e8c1b63          	bne	s8,s0,ffffffffc02028e6 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026f4:	00003517          	auipc	a0,0x3
ffffffffc02026f8:	bf450513          	addi	a0,a0,-1036 # ffffffffc02052e8 <etext+0x1426>
ffffffffc02026fc:	a99fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202700:	7406                	ld	s0,96(sp)
ffffffffc0202702:	70a6                	ld	ra,104(sp)
ffffffffc0202704:	64e6                	ld	s1,88(sp)
ffffffffc0202706:	6946                	ld	s2,80(sp)
ffffffffc0202708:	69a6                	ld	s3,72(sp)
ffffffffc020270a:	6a06                	ld	s4,64(sp)
ffffffffc020270c:	7ae2                	ld	s5,56(sp)
ffffffffc020270e:	7b42                	ld	s6,48(sp)
ffffffffc0202710:	7ba2                	ld	s7,40(sp)
ffffffffc0202712:	7c02                	ld	s8,32(sp)
ffffffffc0202714:	6ce2                	ld	s9,24(sp)
ffffffffc0202716:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202718:	b70ff06f          	j	ffffffffc0201a88 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc020271c:	853e                	mv	a0,a5
ffffffffc020271e:	b4e1                	j	ffffffffc02021e6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202720:	954fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202724:	000b3783          	ld	a5,0(s6)
ffffffffc0202728:	4505                	li	a0,1
ffffffffc020272a:	6f9c                	ld	a5,24(a5)
ffffffffc020272c:	9782                	jalr	a5
ffffffffc020272e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202730:	93efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202734:	be75                	j	ffffffffc02022f0 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202736:	93efe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020273a:	000b3783          	ld	a5,0(s6)
ffffffffc020273e:	779c                	ld	a5,40(a5)
ffffffffc0202740:	9782                	jalr	a5
ffffffffc0202742:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202744:	92afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202748:	b6ad                	j	ffffffffc02022b2 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020274a:	6705                	lui	a4,0x1
ffffffffc020274c:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020274e:	96ba                	add	a3,a3,a4
ffffffffc0202750:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202752:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202756:	14a77e63          	bgeu	a4,a0,ffffffffc02028b2 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc020275a:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020275e:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202760:	071a                	slli	a4,a4,0x6
ffffffffc0202762:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202766:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202768:	6a9c                	ld	a5,16(a3)
ffffffffc020276a:	00c45593          	srli	a1,s0,0xc
ffffffffc020276e:	00e60533          	add	a0,a2,a4
ffffffffc0202772:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202774:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202778:	bcf1                	j	ffffffffc0202254 <pmm_init+0xfe>
        intr_disable();
ffffffffc020277a:	8fafe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020277e:	000b3783          	ld	a5,0(s6)
ffffffffc0202782:	4505                	li	a0,1
ffffffffc0202784:	6f9c                	ld	a5,24(a5)
ffffffffc0202786:	9782                	jalr	a5
ffffffffc0202788:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020278a:	8e4fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020278e:	b119                	j	ffffffffc0202394 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202790:	8e4fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202794:	000b3783          	ld	a5,0(s6)
ffffffffc0202798:	779c                	ld	a5,40(a5)
ffffffffc020279a:	9782                	jalr	a5
ffffffffc020279c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020279e:	8d0fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027a2:	b345                	j	ffffffffc0202542 <pmm_init+0x3ec>
        intr_disable();
ffffffffc02027a4:	8d0fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027a8:	000b3783          	ld	a5,0(s6)
ffffffffc02027ac:	779c                	ld	a5,40(a5)
ffffffffc02027ae:	9782                	jalr	a5
ffffffffc02027b0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027b2:	8bcfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027b6:	b3a5                	j	ffffffffc020251e <pmm_init+0x3c8>
ffffffffc02027b8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027ba:	8bafe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027be:	000b3783          	ld	a5,0(s6)
ffffffffc02027c2:	6522                	ld	a0,8(sp)
ffffffffc02027c4:	4585                	li	a1,1
ffffffffc02027c6:	739c                	ld	a5,32(a5)
ffffffffc02027c8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ca:	8a4fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027ce:	bb05                	j	ffffffffc02024fe <pmm_init+0x3a8>
ffffffffc02027d0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d2:	8a2fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027d6:	000b3783          	ld	a5,0(s6)
ffffffffc02027da:	6522                	ld	a0,8(sp)
ffffffffc02027dc:	4585                	li	a1,1
ffffffffc02027de:	739c                	ld	a5,32(a5)
ffffffffc02027e0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e2:	88cfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027e6:	b1e5                	j	ffffffffc02024ce <pmm_init+0x378>
        intr_disable();
ffffffffc02027e8:	88cfe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027ec:	000b3783          	ld	a5,0(s6)
ffffffffc02027f0:	4505                	li	a0,1
ffffffffc02027f2:	6f9c                	ld	a5,24(a5)
ffffffffc02027f4:	9782                	jalr	a5
ffffffffc02027f6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027f8:	876fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027fc:	b375                	j	ffffffffc02025a8 <pmm_init+0x452>
        intr_disable();
ffffffffc02027fe:	876fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202802:	000b3783          	ld	a5,0(s6)
ffffffffc0202806:	779c                	ld	a5,40(a5)
ffffffffc0202808:	9782                	jalr	a5
ffffffffc020280a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020280c:	862fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202810:	b5c5                	j	ffffffffc02026f0 <pmm_init+0x59a>
ffffffffc0202812:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202814:	860fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202818:	000b3783          	ld	a5,0(s6)
ffffffffc020281c:	6522                	ld	a0,8(sp)
ffffffffc020281e:	4585                	li	a1,1
ffffffffc0202820:	739c                	ld	a5,32(a5)
ffffffffc0202822:	9782                	jalr	a5
        intr_enable();
ffffffffc0202824:	84afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202828:	b565                	j	ffffffffc02026d0 <pmm_init+0x57a>
ffffffffc020282a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020282c:	848fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202830:	000b3783          	ld	a5,0(s6)
ffffffffc0202834:	6522                	ld	a0,8(sp)
ffffffffc0202836:	4585                	li	a1,1
ffffffffc0202838:	739c                	ld	a5,32(a5)
ffffffffc020283a:	9782                	jalr	a5
        intr_enable();
ffffffffc020283c:	832fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202840:	b585                	j	ffffffffc02026a0 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202842:	832fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202846:	000b3783          	ld	a5,0(s6)
ffffffffc020284a:	8522                	mv	a0,s0
ffffffffc020284c:	4585                	li	a1,1
ffffffffc020284e:	739c                	ld	a5,32(a5)
ffffffffc0202850:	9782                	jalr	a5
        intr_enable();
ffffffffc0202852:	81cfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202856:	bd29                	j	ffffffffc0202670 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202858:	86a2                	mv	a3,s0
ffffffffc020285a:	00002617          	auipc	a2,0x2
ffffffffc020285e:	3ee60613          	addi	a2,a2,1006 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0202862:	1a400593          	li	a1,420
ffffffffc0202866:	00002517          	auipc	a0,0x2
ffffffffc020286a:	4d250513          	addi	a0,a0,1234 # ffffffffc0204d38 <etext+0xe76>
ffffffffc020286e:	b99fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202872:	00003697          	auipc	a3,0x3
ffffffffc0202876:	91668693          	addi	a3,a3,-1770 # ffffffffc0205188 <etext+0x12c6>
ffffffffc020287a:	00002617          	auipc	a2,0x2
ffffffffc020287e:	01e60613          	addi	a2,a2,30 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202882:	1a500593          	li	a1,421
ffffffffc0202886:	00002517          	auipc	a0,0x2
ffffffffc020288a:	4b250513          	addi	a0,a0,1202 # ffffffffc0204d38 <etext+0xe76>
ffffffffc020288e:	b79fd0ef          	jal	ffffffffc0200406 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202892:	00003697          	auipc	a3,0x3
ffffffffc0202896:	8b668693          	addi	a3,a3,-1866 # ffffffffc0205148 <etext+0x1286>
ffffffffc020289a:	00002617          	auipc	a2,0x2
ffffffffc020289e:	ffe60613          	addi	a2,a2,-2 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02028a2:	1a400593          	li	a1,420
ffffffffc02028a6:	00002517          	auipc	a0,0x2
ffffffffc02028aa:	49250513          	addi	a0,a0,1170 # ffffffffc0204d38 <etext+0xe76>
ffffffffc02028ae:	b59fd0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02028b2:	b9cff0ef          	jal	ffffffffc0201c4e <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc02028b6:	00002617          	auipc	a2,0x2
ffffffffc02028ba:	63260613          	addi	a2,a2,1586 # ffffffffc0204ee8 <etext+0x1026>
ffffffffc02028be:	07f00593          	li	a1,127
ffffffffc02028c2:	00002517          	auipc	a0,0x2
ffffffffc02028c6:	3ae50513          	addi	a0,a0,942 # ffffffffc0204c70 <etext+0xdae>
ffffffffc02028ca:	b3dfd0ef          	jal	ffffffffc0200406 <__panic>
        panic("DTB memory info not available");
ffffffffc02028ce:	00002617          	auipc	a2,0x2
ffffffffc02028d2:	49260613          	addi	a2,a2,1170 # ffffffffc0204d60 <etext+0xe9e>
ffffffffc02028d6:	06400593          	li	a1,100
ffffffffc02028da:	00002517          	auipc	a0,0x2
ffffffffc02028de:	45e50513          	addi	a0,a0,1118 # ffffffffc0204d38 <etext+0xe76>
ffffffffc02028e2:	b25fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02028e6:	00003697          	auipc	a3,0x3
ffffffffc02028ea:	81a68693          	addi	a3,a3,-2022 # ffffffffc0205100 <etext+0x123e>
ffffffffc02028ee:	00002617          	auipc	a2,0x2
ffffffffc02028f2:	faa60613          	addi	a2,a2,-86 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02028f6:	1bf00593          	li	a1,447
ffffffffc02028fa:	00002517          	auipc	a0,0x2
ffffffffc02028fe:	43e50513          	addi	a0,a0,1086 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202902:	b05fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202906:	00002697          	auipc	a3,0x2
ffffffffc020290a:	51268693          	addi	a3,a3,1298 # ffffffffc0204e18 <etext+0xf56>
ffffffffc020290e:	00002617          	auipc	a2,0x2
ffffffffc0202912:	f8a60613          	addi	a2,a2,-118 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202916:	16600593          	li	a1,358
ffffffffc020291a:	00002517          	auipc	a0,0x2
ffffffffc020291e:	41e50513          	addi	a0,a0,1054 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202922:	ae5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202926:	00002697          	auipc	a3,0x2
ffffffffc020292a:	4d268693          	addi	a3,a3,1234 # ffffffffc0204df8 <etext+0xf36>
ffffffffc020292e:	00002617          	auipc	a2,0x2
ffffffffc0202932:	f6a60613          	addi	a2,a2,-150 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202936:	16500593          	li	a1,357
ffffffffc020293a:	00002517          	auipc	a0,0x2
ffffffffc020293e:	3fe50513          	addi	a0,a0,1022 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202942:	ac5fd0ef          	jal	ffffffffc0200406 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202946:	00002617          	auipc	a2,0x2
ffffffffc020294a:	30260613          	addi	a2,a2,770 # ffffffffc0204c48 <etext+0xd86>
ffffffffc020294e:	07100593          	li	a1,113
ffffffffc0202952:	00002517          	auipc	a0,0x2
ffffffffc0202956:	31e50513          	addi	a0,a0,798 # ffffffffc0204c70 <etext+0xdae>
ffffffffc020295a:	aadfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020295e:	00002697          	auipc	a3,0x2
ffffffffc0202962:	77268693          	addi	a3,a3,1906 # ffffffffc02050d0 <etext+0x120e>
ffffffffc0202966:	00002617          	auipc	a2,0x2
ffffffffc020296a:	f3260613          	addi	a2,a2,-206 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020296e:	18d00593          	li	a1,397
ffffffffc0202972:	00002517          	auipc	a0,0x2
ffffffffc0202976:	3c650513          	addi	a0,a0,966 # ffffffffc0204d38 <etext+0xe76>
ffffffffc020297a:	a8dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020297e:	00002697          	auipc	a3,0x2
ffffffffc0202982:	70a68693          	addi	a3,a3,1802 # ffffffffc0205088 <etext+0x11c6>
ffffffffc0202986:	00002617          	auipc	a2,0x2
ffffffffc020298a:	f1260613          	addi	a2,a2,-238 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020298e:	18b00593          	li	a1,395
ffffffffc0202992:	00002517          	auipc	a0,0x2
ffffffffc0202996:	3a650513          	addi	a0,a0,934 # ffffffffc0204d38 <etext+0xe76>
ffffffffc020299a:	a6dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020299e:	00002697          	auipc	a3,0x2
ffffffffc02029a2:	71a68693          	addi	a3,a3,1818 # ffffffffc02050b8 <etext+0x11f6>
ffffffffc02029a6:	00002617          	auipc	a2,0x2
ffffffffc02029aa:	ef260613          	addi	a2,a2,-270 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02029ae:	18a00593          	li	a1,394
ffffffffc02029b2:	00002517          	auipc	a0,0x2
ffffffffc02029b6:	38650513          	addi	a0,a0,902 # ffffffffc0204d38 <etext+0xe76>
ffffffffc02029ba:	a4dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029be:	00002697          	auipc	a3,0x2
ffffffffc02029c2:	7e268693          	addi	a3,a3,2018 # ffffffffc02051a0 <etext+0x12de>
ffffffffc02029c6:	00002617          	auipc	a2,0x2
ffffffffc02029ca:	ed260613          	addi	a2,a2,-302 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02029ce:	1a800593          	li	a1,424
ffffffffc02029d2:	00002517          	auipc	a0,0x2
ffffffffc02029d6:	36650513          	addi	a0,a0,870 # ffffffffc0204d38 <etext+0xe76>
ffffffffc02029da:	a2dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029de:	00002697          	auipc	a3,0x2
ffffffffc02029e2:	72268693          	addi	a3,a3,1826 # ffffffffc0205100 <etext+0x123e>
ffffffffc02029e6:	00002617          	auipc	a2,0x2
ffffffffc02029ea:	eb260613          	addi	a2,a2,-334 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02029ee:	19500593          	li	a1,405
ffffffffc02029f2:	00002517          	auipc	a0,0x2
ffffffffc02029f6:	34650513          	addi	a0,a0,838 # ffffffffc0204d38 <etext+0xe76>
ffffffffc02029fa:	a0dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029fe:	00002697          	auipc	a3,0x2
ffffffffc0202a02:	7fa68693          	addi	a3,a3,2042 # ffffffffc02051f8 <etext+0x1336>
ffffffffc0202a06:	00002617          	auipc	a2,0x2
ffffffffc0202a0a:	e9260613          	addi	a2,a2,-366 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202a0e:	1ad00593          	li	a1,429
ffffffffc0202a12:	00002517          	auipc	a0,0x2
ffffffffc0202a16:	32650513          	addi	a0,a0,806 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202a1a:	9edfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a1e:	00002697          	auipc	a3,0x2
ffffffffc0202a22:	79a68693          	addi	a3,a3,1946 # ffffffffc02051b8 <etext+0x12f6>
ffffffffc0202a26:	00002617          	auipc	a2,0x2
ffffffffc0202a2a:	e7260613          	addi	a2,a2,-398 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202a2e:	1ac00593          	li	a1,428
ffffffffc0202a32:	00002517          	auipc	a0,0x2
ffffffffc0202a36:	30650513          	addi	a0,a0,774 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202a3a:	9cdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a3e:	00002697          	auipc	a3,0x2
ffffffffc0202a42:	64a68693          	addi	a3,a3,1610 # ffffffffc0205088 <etext+0x11c6>
ffffffffc0202a46:	00002617          	auipc	a2,0x2
ffffffffc0202a4a:	e5260613          	addi	a2,a2,-430 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202a4e:	18700593          	li	a1,391
ffffffffc0202a52:	00002517          	auipc	a0,0x2
ffffffffc0202a56:	2e650513          	addi	a0,a0,742 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202a5a:	9adfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a5e:	00002697          	auipc	a3,0x2
ffffffffc0202a62:	4ca68693          	addi	a3,a3,1226 # ffffffffc0204f28 <etext+0x1066>
ffffffffc0202a66:	00002617          	auipc	a2,0x2
ffffffffc0202a6a:	e3260613          	addi	a2,a2,-462 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202a6e:	18600593          	li	a1,390
ffffffffc0202a72:	00002517          	auipc	a0,0x2
ffffffffc0202a76:	2c650513          	addi	a0,a0,710 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202a7a:	98dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a7e:	00002697          	auipc	a3,0x2
ffffffffc0202a82:	62268693          	addi	a3,a3,1570 # ffffffffc02050a0 <etext+0x11de>
ffffffffc0202a86:	00002617          	auipc	a2,0x2
ffffffffc0202a8a:	e1260613          	addi	a2,a2,-494 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202a8e:	18300593          	li	a1,387
ffffffffc0202a92:	00002517          	auipc	a0,0x2
ffffffffc0202a96:	2a650513          	addi	a0,a0,678 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202a9a:	96dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a9e:	00002697          	auipc	a3,0x2
ffffffffc0202aa2:	47268693          	addi	a3,a3,1138 # ffffffffc0204f10 <etext+0x104e>
ffffffffc0202aa6:	00002617          	auipc	a2,0x2
ffffffffc0202aaa:	df260613          	addi	a2,a2,-526 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202aae:	18200593          	li	a1,386
ffffffffc0202ab2:	00002517          	auipc	a0,0x2
ffffffffc0202ab6:	28650513          	addi	a0,a0,646 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202aba:	94dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202abe:	00002697          	auipc	a3,0x2
ffffffffc0202ac2:	4f268693          	addi	a3,a3,1266 # ffffffffc0204fb0 <etext+0x10ee>
ffffffffc0202ac6:	00002617          	auipc	a2,0x2
ffffffffc0202aca:	dd260613          	addi	a2,a2,-558 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202ace:	18100593          	li	a1,385
ffffffffc0202ad2:	00002517          	auipc	a0,0x2
ffffffffc0202ad6:	26650513          	addi	a0,a0,614 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202ada:	92dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ade:	00002697          	auipc	a3,0x2
ffffffffc0202ae2:	5aa68693          	addi	a3,a3,1450 # ffffffffc0205088 <etext+0x11c6>
ffffffffc0202ae6:	00002617          	auipc	a2,0x2
ffffffffc0202aea:	db260613          	addi	a2,a2,-590 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202aee:	18000593          	li	a1,384
ffffffffc0202af2:	00002517          	auipc	a0,0x2
ffffffffc0202af6:	24650513          	addi	a0,a0,582 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202afa:	90dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202afe:	00002697          	auipc	a3,0x2
ffffffffc0202b02:	57268693          	addi	a3,a3,1394 # ffffffffc0205070 <etext+0x11ae>
ffffffffc0202b06:	00002617          	auipc	a2,0x2
ffffffffc0202b0a:	d9260613          	addi	a2,a2,-622 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202b0e:	17f00593          	li	a1,383
ffffffffc0202b12:	00002517          	auipc	a0,0x2
ffffffffc0202b16:	22650513          	addi	a0,a0,550 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202b1a:	8edfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b1e:	00002697          	auipc	a3,0x2
ffffffffc0202b22:	52268693          	addi	a3,a3,1314 # ffffffffc0205040 <etext+0x117e>
ffffffffc0202b26:	00002617          	auipc	a2,0x2
ffffffffc0202b2a:	d7260613          	addi	a2,a2,-654 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202b2e:	17e00593          	li	a1,382
ffffffffc0202b32:	00002517          	auipc	a0,0x2
ffffffffc0202b36:	20650513          	addi	a0,a0,518 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202b3a:	8cdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b3e:	00002697          	auipc	a3,0x2
ffffffffc0202b42:	4ea68693          	addi	a3,a3,1258 # ffffffffc0205028 <etext+0x1166>
ffffffffc0202b46:	00002617          	auipc	a2,0x2
ffffffffc0202b4a:	d5260613          	addi	a2,a2,-686 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202b4e:	17c00593          	li	a1,380
ffffffffc0202b52:	00002517          	auipc	a0,0x2
ffffffffc0202b56:	1e650513          	addi	a0,a0,486 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202b5a:	8adfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b5e:	00002697          	auipc	a3,0x2
ffffffffc0202b62:	4aa68693          	addi	a3,a3,1194 # ffffffffc0205008 <etext+0x1146>
ffffffffc0202b66:	00002617          	auipc	a2,0x2
ffffffffc0202b6a:	d3260613          	addi	a2,a2,-718 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202b6e:	17b00593          	li	a1,379
ffffffffc0202b72:	00002517          	auipc	a0,0x2
ffffffffc0202b76:	1c650513          	addi	a0,a0,454 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202b7a:	88dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b7e:	00002697          	auipc	a3,0x2
ffffffffc0202b82:	47a68693          	addi	a3,a3,1146 # ffffffffc0204ff8 <etext+0x1136>
ffffffffc0202b86:	00002617          	auipc	a2,0x2
ffffffffc0202b8a:	d1260613          	addi	a2,a2,-750 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202b8e:	17a00593          	li	a1,378
ffffffffc0202b92:	00002517          	auipc	a0,0x2
ffffffffc0202b96:	1a650513          	addi	a0,a0,422 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202b9a:	86dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b9e:	00002697          	auipc	a3,0x2
ffffffffc0202ba2:	44a68693          	addi	a3,a3,1098 # ffffffffc0204fe8 <etext+0x1126>
ffffffffc0202ba6:	00002617          	auipc	a2,0x2
ffffffffc0202baa:	cf260613          	addi	a2,a2,-782 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202bae:	17900593          	li	a1,377
ffffffffc0202bb2:	00002517          	auipc	a0,0x2
ffffffffc0202bb6:	18650513          	addi	a0,a0,390 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202bba:	84dfd0ef          	jal	ffffffffc0200406 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202bbe:	00002617          	auipc	a2,0x2
ffffffffc0202bc2:	13260613          	addi	a2,a2,306 # ffffffffc0204cf0 <etext+0xe2e>
ffffffffc0202bc6:	08000593          	li	a1,128
ffffffffc0202bca:	00002517          	auipc	a0,0x2
ffffffffc0202bce:	16e50513          	addi	a0,a0,366 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202bd2:	835fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202bd6:	00002697          	auipc	a3,0x2
ffffffffc0202bda:	36a68693          	addi	a3,a3,874 # ffffffffc0204f40 <etext+0x107e>
ffffffffc0202bde:	00002617          	auipc	a2,0x2
ffffffffc0202be2:	cba60613          	addi	a2,a2,-838 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202be6:	17400593          	li	a1,372
ffffffffc0202bea:	00002517          	auipc	a0,0x2
ffffffffc0202bee:	14e50513          	addi	a0,a0,334 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202bf2:	815fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bf6:	00002697          	auipc	a3,0x2
ffffffffc0202bfa:	3ba68693          	addi	a3,a3,954 # ffffffffc0204fb0 <etext+0x10ee>
ffffffffc0202bfe:	00002617          	auipc	a2,0x2
ffffffffc0202c02:	c9a60613          	addi	a2,a2,-870 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202c06:	17800593          	li	a1,376
ffffffffc0202c0a:	00002517          	auipc	a0,0x2
ffffffffc0202c0e:	12e50513          	addi	a0,a0,302 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202c12:	ff4fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c16:	00002697          	auipc	a3,0x2
ffffffffc0202c1a:	35a68693          	addi	a3,a3,858 # ffffffffc0204f70 <etext+0x10ae>
ffffffffc0202c1e:	00002617          	auipc	a2,0x2
ffffffffc0202c22:	c7a60613          	addi	a2,a2,-902 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202c26:	17700593          	li	a1,375
ffffffffc0202c2a:	00002517          	auipc	a0,0x2
ffffffffc0202c2e:	10e50513          	addi	a0,a0,270 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202c32:	fd4fd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c36:	86d6                	mv	a3,s5
ffffffffc0202c38:	00002617          	auipc	a2,0x2
ffffffffc0202c3c:	01060613          	addi	a2,a2,16 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0202c40:	17300593          	li	a1,371
ffffffffc0202c44:	00002517          	auipc	a0,0x2
ffffffffc0202c48:	0f450513          	addi	a0,a0,244 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202c4c:	fbafd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c50:	00002617          	auipc	a2,0x2
ffffffffc0202c54:	ff860613          	addi	a2,a2,-8 # ffffffffc0204c48 <etext+0xd86>
ffffffffc0202c58:	17200593          	li	a1,370
ffffffffc0202c5c:	00002517          	auipc	a0,0x2
ffffffffc0202c60:	0dc50513          	addi	a0,a0,220 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202c64:	fa2fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c68:	00002697          	auipc	a3,0x2
ffffffffc0202c6c:	2c068693          	addi	a3,a3,704 # ffffffffc0204f28 <etext+0x1066>
ffffffffc0202c70:	00002617          	auipc	a2,0x2
ffffffffc0202c74:	c2860613          	addi	a2,a2,-984 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202c78:	17000593          	li	a1,368
ffffffffc0202c7c:	00002517          	auipc	a0,0x2
ffffffffc0202c80:	0bc50513          	addi	a0,a0,188 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202c84:	f82fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c88:	00002697          	auipc	a3,0x2
ffffffffc0202c8c:	28868693          	addi	a3,a3,648 # ffffffffc0204f10 <etext+0x104e>
ffffffffc0202c90:	00002617          	auipc	a2,0x2
ffffffffc0202c94:	c0860613          	addi	a2,a2,-1016 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202c98:	16f00593          	li	a1,367
ffffffffc0202c9c:	00002517          	auipc	a0,0x2
ffffffffc0202ca0:	09c50513          	addi	a0,a0,156 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202ca4:	f62fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca8:	00002697          	auipc	a3,0x2
ffffffffc0202cac:	61868693          	addi	a3,a3,1560 # ffffffffc02052c0 <etext+0x13fe>
ffffffffc0202cb0:	00002617          	auipc	a2,0x2
ffffffffc0202cb4:	be860613          	addi	a2,a2,-1048 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202cb8:	1b600593          	li	a1,438
ffffffffc0202cbc:	00002517          	auipc	a0,0x2
ffffffffc0202cc0:	07c50513          	addi	a0,a0,124 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202cc4:	f42fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cc8:	00002697          	auipc	a3,0x2
ffffffffc0202ccc:	5c068693          	addi	a3,a3,1472 # ffffffffc0205288 <etext+0x13c6>
ffffffffc0202cd0:	00002617          	auipc	a2,0x2
ffffffffc0202cd4:	bc860613          	addi	a2,a2,-1080 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202cd8:	1b300593          	li	a1,435
ffffffffc0202cdc:	00002517          	auipc	a0,0x2
ffffffffc0202ce0:	05c50513          	addi	a0,a0,92 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202ce4:	f22fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202ce8:	00002697          	auipc	a3,0x2
ffffffffc0202cec:	57068693          	addi	a3,a3,1392 # ffffffffc0205258 <etext+0x1396>
ffffffffc0202cf0:	00002617          	auipc	a2,0x2
ffffffffc0202cf4:	ba860613          	addi	a2,a2,-1112 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202cf8:	1af00593          	li	a1,431
ffffffffc0202cfc:	00002517          	auipc	a0,0x2
ffffffffc0202d00:	03c50513          	addi	a0,a0,60 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202d04:	f02fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d08:	00002697          	auipc	a3,0x2
ffffffffc0202d0c:	50868693          	addi	a3,a3,1288 # ffffffffc0205210 <etext+0x134e>
ffffffffc0202d10:	00002617          	auipc	a2,0x2
ffffffffc0202d14:	b8860613          	addi	a2,a2,-1144 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202d18:	1ae00593          	li	a1,430
ffffffffc0202d1c:	00002517          	auipc	a0,0x2
ffffffffc0202d20:	01c50513          	addi	a0,a0,28 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202d24:	ee2fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202d28:	00002697          	auipc	a3,0x2
ffffffffc0202d2c:	13068693          	addi	a3,a3,304 # ffffffffc0204e58 <etext+0xf96>
ffffffffc0202d30:	00002617          	auipc	a2,0x2
ffffffffc0202d34:	b6860613          	addi	a2,a2,-1176 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202d38:	16700593          	li	a1,359
ffffffffc0202d3c:	00002517          	auipc	a0,0x2
ffffffffc0202d40:	ffc50513          	addi	a0,a0,-4 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202d44:	ec2fd0ef          	jal	ffffffffc0200406 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d48:	00002617          	auipc	a2,0x2
ffffffffc0202d4c:	fa860613          	addi	a2,a2,-88 # ffffffffc0204cf0 <etext+0xe2e>
ffffffffc0202d50:	0cb00593          	li	a1,203
ffffffffc0202d54:	00002517          	auipc	a0,0x2
ffffffffc0202d58:	fe450513          	addi	a0,a0,-28 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202d5c:	eaafd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d60:	00002697          	auipc	a3,0x2
ffffffffc0202d64:	15868693          	addi	a3,a3,344 # ffffffffc0204eb8 <etext+0xff6>
ffffffffc0202d68:	00002617          	auipc	a2,0x2
ffffffffc0202d6c:	b3060613          	addi	a2,a2,-1232 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202d70:	16e00593          	li	a1,366
ffffffffc0202d74:	00002517          	auipc	a0,0x2
ffffffffc0202d78:	fc450513          	addi	a0,a0,-60 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202d7c:	e8afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d80:	00002697          	auipc	a3,0x2
ffffffffc0202d84:	10868693          	addi	a3,a3,264 # ffffffffc0204e88 <etext+0xfc6>
ffffffffc0202d88:	00002617          	auipc	a2,0x2
ffffffffc0202d8c:	b1060613          	addi	a2,a2,-1264 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202d90:	16b00593          	li	a1,363
ffffffffc0202d94:	00002517          	auipc	a0,0x2
ffffffffc0202d98:	fa450513          	addi	a0,a0,-92 # ffffffffc0204d38 <etext+0xe76>
ffffffffc0202d9c:	e6afd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202da0 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202da0:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202da2:	00002697          	auipc	a3,0x2
ffffffffc0202da6:	56668693          	addi	a3,a3,1382 # ffffffffc0205308 <etext+0x1446>
ffffffffc0202daa:	00002617          	auipc	a2,0x2
ffffffffc0202dae:	aee60613          	addi	a2,a2,-1298 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202db2:	08800593          	li	a1,136
ffffffffc0202db6:	00002517          	auipc	a0,0x2
ffffffffc0202dba:	57250513          	addi	a0,a0,1394 # ffffffffc0205328 <etext+0x1466>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dbe:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202dc0:	e46fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202dc4 <find_vma>:
    if (mm != NULL)
ffffffffc0202dc4:	c505                	beqz	a0,ffffffffc0202dec <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0202dc6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dc8:	c781                	beqz	a5,ffffffffc0202dd0 <find_vma+0xc>
ffffffffc0202dca:	6798                	ld	a4,8(a5)
ffffffffc0202dcc:	02e5f363          	bgeu	a1,a4,ffffffffc0202df2 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dd0:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0202dd2:	00f50d63          	beq	a0,a5,ffffffffc0202dec <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dd6:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3ddf2af8>
ffffffffc0202dda:	00e5e663          	bltu	a1,a4,ffffffffc0202de6 <find_vma+0x22>
ffffffffc0202dde:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202de2:	00e5ee63          	bltu	a1,a4,ffffffffc0202dfe <find_vma+0x3a>
ffffffffc0202de6:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202de8:	fef517e3          	bne	a0,a5,ffffffffc0202dd6 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0202dec:	4781                	li	a5,0
}
ffffffffc0202dee:	853e                	mv	a0,a5
ffffffffc0202df0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202df2:	6b98                	ld	a4,16(a5)
ffffffffc0202df4:	fce5fee3          	bgeu	a1,a4,ffffffffc0202dd0 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0202df8:	e91c                	sd	a5,16(a0)
}
ffffffffc0202dfa:	853e                	mv	a0,a5
ffffffffc0202dfc:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202dfe:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202e00:	e91c                	sd	a5,16(a0)
ffffffffc0202e02:	bfe5                	j	ffffffffc0202dfa <find_vma+0x36>

ffffffffc0202e04 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e04:	6590                	ld	a2,8(a1)
ffffffffc0202e06:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e0a:	1141                	addi	sp,sp,-16
ffffffffc0202e0c:	e406                	sd	ra,8(sp)
ffffffffc0202e0e:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e10:	01066763          	bltu	a2,a6,ffffffffc0202e1e <insert_vma_struct+0x1a>
ffffffffc0202e14:	a8b9                	j	ffffffffc0202e72 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e16:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e1a:	04e66763          	bltu	a2,a4,ffffffffc0202e68 <insert_vma_struct+0x64>
ffffffffc0202e1e:	86be                	mv	a3,a5
ffffffffc0202e20:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e22:	fef51ae3          	bne	a0,a5,ffffffffc0202e16 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e26:	02a68463          	beq	a3,a0,ffffffffc0202e4e <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e2a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e2e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e32:	08e8f063          	bgeu	a7,a4,ffffffffc0202eb2 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e36:	04e66e63          	bltu	a2,a4,ffffffffc0202e92 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202e3a:	00f50a63          	beq	a0,a5,ffffffffc0202e4e <insert_vma_struct+0x4a>
ffffffffc0202e3e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e42:	05076863          	bltu	a4,a6,ffffffffc0202e92 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e46:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e4a:	02c77263          	bgeu	a4,a2,ffffffffc0202e6e <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e4e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e50:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e52:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e56:	e390                	sd	a2,0(a5)
ffffffffc0202e58:	e690                	sd	a2,8(a3)
}
ffffffffc0202e5a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e5c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e5e:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e60:	2705                	addiw	a4,a4,1
ffffffffc0202e62:	d118                	sw	a4,32(a0)
}
ffffffffc0202e64:	0141                	addi	sp,sp,16
ffffffffc0202e66:	8082                	ret
    if (le_prev != list)
ffffffffc0202e68:	fca691e3          	bne	a3,a0,ffffffffc0202e2a <insert_vma_struct+0x26>
ffffffffc0202e6c:	bfd9                	j	ffffffffc0202e42 <insert_vma_struct+0x3e>
ffffffffc0202e6e:	f33ff0ef          	jal	ffffffffc0202da0 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e72:	00002697          	auipc	a3,0x2
ffffffffc0202e76:	4c668693          	addi	a3,a3,1222 # ffffffffc0205338 <etext+0x1476>
ffffffffc0202e7a:	00002617          	auipc	a2,0x2
ffffffffc0202e7e:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202e82:	08e00593          	li	a1,142
ffffffffc0202e86:	00002517          	auipc	a0,0x2
ffffffffc0202e8a:	4a250513          	addi	a0,a0,1186 # ffffffffc0205328 <etext+0x1466>
ffffffffc0202e8e:	d78fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e92:	00002697          	auipc	a3,0x2
ffffffffc0202e96:	4e668693          	addi	a3,a3,1254 # ffffffffc0205378 <etext+0x14b6>
ffffffffc0202e9a:	00002617          	auipc	a2,0x2
ffffffffc0202e9e:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202ea2:	08700593          	li	a1,135
ffffffffc0202ea6:	00002517          	auipc	a0,0x2
ffffffffc0202eaa:	48250513          	addi	a0,a0,1154 # ffffffffc0205328 <etext+0x1466>
ffffffffc0202eae:	d58fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202eb2:	00002697          	auipc	a3,0x2
ffffffffc0202eb6:	4a668693          	addi	a3,a3,1190 # ffffffffc0205358 <etext+0x1496>
ffffffffc0202eba:	00002617          	auipc	a2,0x2
ffffffffc0202ebe:	9de60613          	addi	a2,a2,-1570 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0202ec2:	08600593          	li	a1,134
ffffffffc0202ec6:	00002517          	auipc	a0,0x2
ffffffffc0202eca:	46250513          	addi	a0,a0,1122 # ffffffffc0205328 <etext+0x1466>
ffffffffc0202ece:	d38fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202ed2 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202ed2:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ed4:	03000513          	li	a0,48
{
ffffffffc0202ed8:	fc06                	sd	ra,56(sp)
ffffffffc0202eda:	f822                	sd	s0,48(sp)
ffffffffc0202edc:	f426                	sd	s1,40(sp)
ffffffffc0202ede:	f04a                	sd	s2,32(sp)
ffffffffc0202ee0:	ec4e                	sd	s3,24(sp)
ffffffffc0202ee2:	e852                	sd	s4,16(sp)
ffffffffc0202ee4:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ee6:	bc3fe0ef          	jal	ffffffffc0201aa8 <kmalloc>
    if (mm != NULL)
ffffffffc0202eea:	18050a63          	beqz	a0,ffffffffc020307e <vmm_init+0x1ac>
ffffffffc0202eee:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0202ef0:	e508                	sd	a0,8(a0)
ffffffffc0202ef2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ef4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ef8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202efc:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202f00:	02053423          	sd	zero,40(a0)
ffffffffc0202f04:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f08:	03000513          	li	a0,48
ffffffffc0202f0c:	b9dfe0ef          	jal	ffffffffc0201aa8 <kmalloc>
    if (vma != NULL)
ffffffffc0202f10:	14050763          	beqz	a0,ffffffffc020305e <vmm_init+0x18c>
        vma->vm_end = vm_end;
ffffffffc0202f14:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f18:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f1a:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f1e:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f20:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0202f22:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0202f24:	8522                	mv	a0,s0
ffffffffc0202f26:	edfff0ef          	jal	ffffffffc0202e04 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f2a:	fcf9                	bnez	s1,ffffffffc0202f08 <vmm_init+0x36>
ffffffffc0202f2c:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f30:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f34:	03000513          	li	a0,48
ffffffffc0202f38:	b71fe0ef          	jal	ffffffffc0201aa8 <kmalloc>
    if (vma != NULL)
ffffffffc0202f3c:	16050163          	beqz	a0,ffffffffc020309e <vmm_init+0x1cc>
        vma->vm_end = vm_end;
ffffffffc0202f40:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f44:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f46:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f4a:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f4c:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f4e:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0202f50:	8522                	mv	a0,s0
ffffffffc0202f52:	eb3ff0ef          	jal	ffffffffc0202e04 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f56:	fd249fe3          	bne	s1,s2,ffffffffc0202f34 <vmm_init+0x62>
    return listelm->next;
ffffffffc0202f5a:	641c                	ld	a5,8(s0)
ffffffffc0202f5c:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f5e:	1fb00593          	li	a1,507
ffffffffc0202f62:	8abe                	mv	s5,a5
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f64:	20f40d63          	beq	s0,a5,ffffffffc020317e <vmm_init+0x2ac>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f68:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f6c:	ffe70693          	addi	a3,a4,-2
ffffffffc0202f70:	14d61763          	bne	a2,a3,ffffffffc02030be <vmm_init+0x1ec>
ffffffffc0202f74:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f78:	14e69363          	bne	a3,a4,ffffffffc02030be <vmm_init+0x1ec>
    for (i = 1; i <= step2; i++)
ffffffffc0202f7c:	0715                	addi	a4,a4,5
ffffffffc0202f7e:	679c                	ld	a5,8(a5)
ffffffffc0202f80:	feb712e3          	bne	a4,a1,ffffffffc0202f64 <vmm_init+0x92>
ffffffffc0202f84:	491d                	li	s2,7
ffffffffc0202f86:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f88:	85a6                	mv	a1,s1
ffffffffc0202f8a:	8522                	mv	a0,s0
ffffffffc0202f8c:	e39ff0ef          	jal	ffffffffc0202dc4 <find_vma>
ffffffffc0202f90:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202f92:	22050663          	beqz	a0,ffffffffc02031be <vmm_init+0x2ec>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f96:	00148593          	addi	a1,s1,1
ffffffffc0202f9a:	8522                	mv	a0,s0
ffffffffc0202f9c:	e29ff0ef          	jal	ffffffffc0202dc4 <find_vma>
ffffffffc0202fa0:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fa2:	1e050e63          	beqz	a0,ffffffffc020319e <vmm_init+0x2cc>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202fa6:	85ca                	mv	a1,s2
ffffffffc0202fa8:	8522                	mv	a0,s0
ffffffffc0202faa:	e1bff0ef          	jal	ffffffffc0202dc4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202fae:	1a051863          	bnez	a0,ffffffffc020315e <vmm_init+0x28c>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fb2:	00348593          	addi	a1,s1,3
ffffffffc0202fb6:	8522                	mv	a0,s0
ffffffffc0202fb8:	e0dff0ef          	jal	ffffffffc0202dc4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202fbc:	18051163          	bnez	a0,ffffffffc020313e <vmm_init+0x26c>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202fc0:	00448593          	addi	a1,s1,4
ffffffffc0202fc4:	8522                	mv	a0,s0
ffffffffc0202fc6:	dffff0ef          	jal	ffffffffc0202dc4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202fca:	14051a63          	bnez	a0,ffffffffc020311e <vmm_init+0x24c>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202fce:	008a3783          	ld	a5,8(s4)
ffffffffc0202fd2:	12979663          	bne	a5,s1,ffffffffc02030fe <vmm_init+0x22c>
ffffffffc0202fd6:	010a3783          	ld	a5,16(s4)
ffffffffc0202fda:	13279263          	bne	a5,s2,ffffffffc02030fe <vmm_init+0x22c>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202fde:	0089b783          	ld	a5,8(s3)
ffffffffc0202fe2:	0e979e63          	bne	a5,s1,ffffffffc02030de <vmm_init+0x20c>
ffffffffc0202fe6:	0109b783          	ld	a5,16(s3)
ffffffffc0202fea:	0f279a63          	bne	a5,s2,ffffffffc02030de <vmm_init+0x20c>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fee:	0495                	addi	s1,s1,5
ffffffffc0202ff0:	1f900793          	li	a5,505
ffffffffc0202ff4:	0915                	addi	s2,s2,5
ffffffffc0202ff6:	f8f499e3          	bne	s1,a5,ffffffffc0202f88 <vmm_init+0xb6>
ffffffffc0202ffa:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202ffc:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202ffe:	85a6                	mv	a1,s1
ffffffffc0203000:	8522                	mv	a0,s0
ffffffffc0203002:	dc3ff0ef          	jal	ffffffffc0202dc4 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203006:	1c051c63          	bnez	a0,ffffffffc02031de <vmm_init+0x30c>
    for (i = 4; i >= 0; i--)
ffffffffc020300a:	14fd                	addi	s1,s1,-1
ffffffffc020300c:	ff2499e3          	bne	s1,s2,ffffffffc0202ffe <vmm_init+0x12c>
    while ((le = list_next(list)) != list)
ffffffffc0203010:	028a8063          	beq	s5,s0,ffffffffc0203030 <vmm_init+0x15e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203014:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc0203018:	000ab703          	ld	a4,0(s5)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020301c:	fe0a8513          	addi	a0,s5,-32
    prev->next = next;
ffffffffc0203020:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203022:	e398                	sd	a4,0(a5)
ffffffffc0203024:	b2bfe0ef          	jal	ffffffffc0201b4e <kfree>
    return listelm->next;
ffffffffc0203028:	641c                	ld	a5,8(s0)
ffffffffc020302a:	8abe                	mv	s5,a5
    while ((le = list_next(list)) != list)
ffffffffc020302c:	fef414e3          	bne	s0,a5,ffffffffc0203014 <vmm_init+0x142>
    kfree(mm); // kfree mm
ffffffffc0203030:	8522                	mv	a0,s0
ffffffffc0203032:	b1dfe0ef          	jal	ffffffffc0201b4e <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203036:	00002517          	auipc	a0,0x2
ffffffffc020303a:	4c250513          	addi	a0,a0,1218 # ffffffffc02054f8 <etext+0x1636>
ffffffffc020303e:	956fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203042:	7442                	ld	s0,48(sp)
ffffffffc0203044:	70e2                	ld	ra,56(sp)
ffffffffc0203046:	74a2                	ld	s1,40(sp)
ffffffffc0203048:	7902                	ld	s2,32(sp)
ffffffffc020304a:	69e2                	ld	s3,24(sp)
ffffffffc020304c:	6a42                	ld	s4,16(sp)
ffffffffc020304e:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203050:	00002517          	auipc	a0,0x2
ffffffffc0203054:	4c850513          	addi	a0,a0,1224 # ffffffffc0205518 <etext+0x1656>
}
ffffffffc0203058:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020305a:	93afd06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc020305e:	00002697          	auipc	a3,0x2
ffffffffc0203062:	34a68693          	addi	a3,a3,842 # ffffffffc02053a8 <etext+0x14e6>
ffffffffc0203066:	00002617          	auipc	a2,0x2
ffffffffc020306a:	83260613          	addi	a2,a2,-1998 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020306e:	0da00593          	li	a1,218
ffffffffc0203072:	00002517          	auipc	a0,0x2
ffffffffc0203076:	2b650513          	addi	a0,a0,694 # ffffffffc0205328 <etext+0x1466>
ffffffffc020307a:	b8cfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(mm != NULL);
ffffffffc020307e:	00002697          	auipc	a3,0x2
ffffffffc0203082:	31a68693          	addi	a3,a3,794 # ffffffffc0205398 <etext+0x14d6>
ffffffffc0203086:	00002617          	auipc	a2,0x2
ffffffffc020308a:	81260613          	addi	a2,a2,-2030 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020308e:	0d200593          	li	a1,210
ffffffffc0203092:	00002517          	auipc	a0,0x2
ffffffffc0203096:	29650513          	addi	a0,a0,662 # ffffffffc0205328 <etext+0x1466>
ffffffffc020309a:	b6cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma != NULL);
ffffffffc020309e:	00002697          	auipc	a3,0x2
ffffffffc02030a2:	30a68693          	addi	a3,a3,778 # ffffffffc02053a8 <etext+0x14e6>
ffffffffc02030a6:	00001617          	auipc	a2,0x1
ffffffffc02030aa:	7f260613          	addi	a2,a2,2034 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02030ae:	0e100593          	li	a1,225
ffffffffc02030b2:	00002517          	auipc	a0,0x2
ffffffffc02030b6:	27650513          	addi	a0,a0,630 # ffffffffc0205328 <etext+0x1466>
ffffffffc02030ba:	b4cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030be:	00002697          	auipc	a3,0x2
ffffffffc02030c2:	31268693          	addi	a3,a3,786 # ffffffffc02053d0 <etext+0x150e>
ffffffffc02030c6:	00001617          	auipc	a2,0x1
ffffffffc02030ca:	7d260613          	addi	a2,a2,2002 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02030ce:	0eb00593          	li	a1,235
ffffffffc02030d2:	00002517          	auipc	a0,0x2
ffffffffc02030d6:	25650513          	addi	a0,a0,598 # ffffffffc0205328 <etext+0x1466>
ffffffffc02030da:	b2cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030de:	00002697          	auipc	a3,0x2
ffffffffc02030e2:	3aa68693          	addi	a3,a3,938 # ffffffffc0205488 <etext+0x15c6>
ffffffffc02030e6:	00001617          	auipc	a2,0x1
ffffffffc02030ea:	7b260613          	addi	a2,a2,1970 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02030ee:	0fd00593          	li	a1,253
ffffffffc02030f2:	00002517          	auipc	a0,0x2
ffffffffc02030f6:	23650513          	addi	a0,a0,566 # ffffffffc0205328 <etext+0x1466>
ffffffffc02030fa:	b0cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030fe:	00002697          	auipc	a3,0x2
ffffffffc0203102:	35a68693          	addi	a3,a3,858 # ffffffffc0205458 <etext+0x1596>
ffffffffc0203106:	00001617          	auipc	a2,0x1
ffffffffc020310a:	79260613          	addi	a2,a2,1938 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020310e:	0fc00593          	li	a1,252
ffffffffc0203112:	00002517          	auipc	a0,0x2
ffffffffc0203116:	21650513          	addi	a0,a0,534 # ffffffffc0205328 <etext+0x1466>
ffffffffc020311a:	aecfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma5 == NULL);
ffffffffc020311e:	00002697          	auipc	a3,0x2
ffffffffc0203122:	32a68693          	addi	a3,a3,810 # ffffffffc0205448 <etext+0x1586>
ffffffffc0203126:	00001617          	auipc	a2,0x1
ffffffffc020312a:	77260613          	addi	a2,a2,1906 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020312e:	0fa00593          	li	a1,250
ffffffffc0203132:	00002517          	auipc	a0,0x2
ffffffffc0203136:	1f650513          	addi	a0,a0,502 # ffffffffc0205328 <etext+0x1466>
ffffffffc020313a:	accfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma4 == NULL);
ffffffffc020313e:	00002697          	auipc	a3,0x2
ffffffffc0203142:	2fa68693          	addi	a3,a3,762 # ffffffffc0205438 <etext+0x1576>
ffffffffc0203146:	00001617          	auipc	a2,0x1
ffffffffc020314a:	75260613          	addi	a2,a2,1874 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020314e:	0f800593          	li	a1,248
ffffffffc0203152:	00002517          	auipc	a0,0x2
ffffffffc0203156:	1d650513          	addi	a0,a0,470 # ffffffffc0205328 <etext+0x1466>
ffffffffc020315a:	aacfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma3 == NULL);
ffffffffc020315e:	00002697          	auipc	a3,0x2
ffffffffc0203162:	2ca68693          	addi	a3,a3,714 # ffffffffc0205428 <etext+0x1566>
ffffffffc0203166:	00001617          	auipc	a2,0x1
ffffffffc020316a:	73260613          	addi	a2,a2,1842 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020316e:	0f600593          	li	a1,246
ffffffffc0203172:	00002517          	auipc	a0,0x2
ffffffffc0203176:	1b650513          	addi	a0,a0,438 # ffffffffc0205328 <etext+0x1466>
ffffffffc020317a:	a8cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020317e:	00002697          	auipc	a3,0x2
ffffffffc0203182:	23a68693          	addi	a3,a3,570 # ffffffffc02053b8 <etext+0x14f6>
ffffffffc0203186:	00001617          	auipc	a2,0x1
ffffffffc020318a:	71260613          	addi	a2,a2,1810 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020318e:	0e900593          	li	a1,233
ffffffffc0203192:	00002517          	auipc	a0,0x2
ffffffffc0203196:	19650513          	addi	a0,a0,406 # ffffffffc0205328 <etext+0x1466>
ffffffffc020319a:	a6cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2 != NULL);
ffffffffc020319e:	00002697          	auipc	a3,0x2
ffffffffc02031a2:	27a68693          	addi	a3,a3,634 # ffffffffc0205418 <etext+0x1556>
ffffffffc02031a6:	00001617          	auipc	a2,0x1
ffffffffc02031aa:	6f260613          	addi	a2,a2,1778 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02031ae:	0f400593          	li	a1,244
ffffffffc02031b2:	00002517          	auipc	a0,0x2
ffffffffc02031b6:	17650513          	addi	a0,a0,374 # ffffffffc0205328 <etext+0x1466>
ffffffffc02031ba:	a4cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1 != NULL);
ffffffffc02031be:	00002697          	auipc	a3,0x2
ffffffffc02031c2:	24a68693          	addi	a3,a3,586 # ffffffffc0205408 <etext+0x1546>
ffffffffc02031c6:	00001617          	auipc	a2,0x1
ffffffffc02031ca:	6d260613          	addi	a2,a2,1746 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02031ce:	0f200593          	li	a1,242
ffffffffc02031d2:	00002517          	auipc	a0,0x2
ffffffffc02031d6:	15650513          	addi	a0,a0,342 # ffffffffc0205328 <etext+0x1466>
ffffffffc02031da:	a2cfd0ef          	jal	ffffffffc0200406 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02031de:	6914                	ld	a3,16(a0)
ffffffffc02031e0:	6510                	ld	a2,8(a0)
ffffffffc02031e2:	0004859b          	sext.w	a1,s1
ffffffffc02031e6:	00002517          	auipc	a0,0x2
ffffffffc02031ea:	2d250513          	addi	a0,a0,722 # ffffffffc02054b8 <etext+0x15f6>
ffffffffc02031ee:	fa7fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc02031f2:	00002697          	auipc	a3,0x2
ffffffffc02031f6:	2ee68693          	addi	a3,a3,750 # ffffffffc02054e0 <etext+0x161e>
ffffffffc02031fa:	00001617          	auipc	a2,0x1
ffffffffc02031fe:	69e60613          	addi	a2,a2,1694 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0203202:	10700593          	li	a1,263
ffffffffc0203206:	00002517          	auipc	a0,0x2
ffffffffc020320a:	12250513          	addi	a0,a0,290 # ffffffffc0205328 <etext+0x1466>
ffffffffc020320e:	9f8fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203212 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203212:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203214:	9402                	jalr	s0

	jal do_exit
ffffffffc0203216:	40a000ef          	jal	ffffffffc0203620 <do_exit>

ffffffffc020321a <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020321a:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020321c:	0e800513          	li	a0,232
{
ffffffffc0203220:	e022                	sd	s0,0(sp)
ffffffffc0203222:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203224:	885fe0ef          	jal	ffffffffc0201aa8 <kmalloc>
ffffffffc0203228:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020322a:	c521                	beqz	a0,ffffffffc0203272 <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;                     // 设置进程为未初始化状态
ffffffffc020322c:	57fd                	li	a5,-1
ffffffffc020322e:	1782                	slli	a5,a5,0x20
ffffffffc0203230:	e11c                	sd	a5,0(a0)
        proc->pid = -1;                                // 未分配PID
        proc->runs = 0;                                // 运行次数初始化为0
ffffffffc0203232:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                              // 内核栈地址初始化为0
ffffffffc0203236:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                        // 不需要调度
ffffffffc020323a:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;                           // 父进程为空
ffffffffc020323e:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                               // 内存管理结构为空
ffffffffc0203242:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0203246:	07000613          	li	a2,112
ffffffffc020324a:	4581                	li	a1,0
ffffffffc020324c:	03050513          	addi	a0,a0,48
ffffffffc0203250:	425000ef          	jal	ffffffffc0203e74 <memset>
        proc->tf = NULL;                               // 中断帧指针为空
        proc->pgdir = boot_pgdir_pa;                   // 页目录为内核页目录的物理地址
ffffffffc0203254:	0000a797          	auipc	a5,0xa
ffffffffc0203258:	2547b783          	ld	a5,596(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
        proc->tf = NULL;                               // 中断帧指针为空
ffffffffc020325c:	0a043023          	sd	zero,160(s0) # ffffffffc02000a0 <kern_init+0x56>
        proc->flags = 0;                               // 标志位为0
ffffffffc0203260:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;                   // 页目录为内核页目录的物理地址
ffffffffc0203264:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);      // 进程名初始化为0
ffffffffc0203266:	0b440513          	addi	a0,s0,180
ffffffffc020326a:	4641                	li	a2,16
ffffffffc020326c:	4581                	li	a1,0
ffffffffc020326e:	407000ef          	jal	ffffffffc0203e74 <memset>
    }
    return proc;
}
ffffffffc0203272:	60a2                	ld	ra,8(sp)
ffffffffc0203274:	8522                	mv	a0,s0
ffffffffc0203276:	6402                	ld	s0,0(sp)
ffffffffc0203278:	0141                	addi	sp,sp,16
ffffffffc020327a:	8082                	ret

ffffffffc020327c <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020327c:	0000a797          	auipc	a5,0xa
ffffffffc0203280:	25c7b783          	ld	a5,604(a5) # ffffffffc020d4d8 <current>
ffffffffc0203284:	73c8                	ld	a0,160(a5)
ffffffffc0203286:	aabfd06f          	j	ffffffffc0200d30 <forkrets>

ffffffffc020328a <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020328a:	1101                	addi	sp,sp,-32
ffffffffc020328c:	e822                	sd	s0,16(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020328e:	0000a417          	auipc	s0,0xa
ffffffffc0203292:	24a43403          	ld	s0,586(s0) # ffffffffc020d4d8 <current>
{
ffffffffc0203296:	e04a                	sd	s2,0(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203298:	4641                	li	a2,16
{
ffffffffc020329a:	892a                	mv	s2,a0
    memset(name, 0, sizeof(name));
ffffffffc020329c:	4581                	li	a1,0
ffffffffc020329e:	00006517          	auipc	a0,0x6
ffffffffc02032a2:	1aa50513          	addi	a0,a0,426 # ffffffffc0209448 <name.2>
{
ffffffffc02032a6:	ec06                	sd	ra,24(sp)
ffffffffc02032a8:	e426                	sd	s1,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032aa:	4044                	lw	s1,4(s0)
    memset(name, 0, sizeof(name));
ffffffffc02032ac:	3c9000ef          	jal	ffffffffc0203e74 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032b0:	0b440593          	addi	a1,s0,180
ffffffffc02032b4:	463d                	li	a2,15
ffffffffc02032b6:	00006517          	auipc	a0,0x6
ffffffffc02032ba:	19250513          	addi	a0,a0,402 # ffffffffc0209448 <name.2>
ffffffffc02032be:	3c9000ef          	jal	ffffffffc0203e86 <memcpy>
ffffffffc02032c2:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032c4:	85a6                	mv	a1,s1
ffffffffc02032c6:	00002517          	auipc	a0,0x2
ffffffffc02032ca:	26a50513          	addi	a0,a0,618 # ffffffffc0205530 <etext+0x166e>
ffffffffc02032ce:	ec7fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032d2:	85ca                	mv	a1,s2
ffffffffc02032d4:	00002517          	auipc	a0,0x2
ffffffffc02032d8:	28450513          	addi	a0,a0,644 # ffffffffc0205558 <etext+0x1696>
ffffffffc02032dc:	eb9fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032e0:	00002517          	auipc	a0,0x2
ffffffffc02032e4:	28850513          	addi	a0,a0,648 # ffffffffc0205568 <etext+0x16a6>
ffffffffc02032e8:	eadfc0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032ec:	60e2                	ld	ra,24(sp)
ffffffffc02032ee:	6442                	ld	s0,16(sp)
ffffffffc02032f0:	64a2                	ld	s1,8(sp)
ffffffffc02032f2:	6902                	ld	s2,0(sp)
ffffffffc02032f4:	4501                	li	a0,0
ffffffffc02032f6:	6105                	addi	sp,sp,32
ffffffffc02032f8:	8082                	ret

ffffffffc02032fa <proc_run>:
    if (proc != current)
ffffffffc02032fa:	0000a717          	auipc	a4,0xa
ffffffffc02032fe:	1de73703          	ld	a4,478(a4) # ffffffffc020d4d8 <current>
ffffffffc0203302:	04a70563          	beq	a4,a0,ffffffffc020334c <proc_run+0x52>
{
ffffffffc0203306:	1101                	addi	sp,sp,-32
ffffffffc0203308:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020330a:	100027f3          	csrr	a5,sstatus
ffffffffc020330e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203310:	4681                	li	a3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203312:	ef95                	bnez	a5,ffffffffc020334e <proc_run+0x54>
            lsatp(next->pgdir);
ffffffffc0203314:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203316:	80000637          	lui	a2,0x80000
ffffffffc020331a:	e036                	sd	a3,0(sp)
ffffffffc020331c:	00c7d79b          	srliw	a5,a5,0xc
            current = proc;
ffffffffc0203320:	0000a597          	auipc	a1,0xa
ffffffffc0203324:	1aa5bc23          	sd	a0,440(a1) # ffffffffc020d4d8 <current>
ffffffffc0203328:	8fd1                	or	a5,a5,a2
ffffffffc020332a:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc020332e:	03050593          	addi	a1,a0,48
ffffffffc0203332:	03070513          	addi	a0,a4,48
ffffffffc0203336:	578000ef          	jal	ffffffffc02038ae <switch_to>
    if (flag) {
ffffffffc020333a:	6682                	ld	a3,0(sp)
ffffffffc020333c:	e681                	bnez	a3,ffffffffc0203344 <proc_run+0x4a>
}
ffffffffc020333e:	60e2                	ld	ra,24(sp)
ffffffffc0203340:	6105                	addi	sp,sp,32
ffffffffc0203342:	8082                	ret
ffffffffc0203344:	60e2                	ld	ra,24(sp)
ffffffffc0203346:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203348:	d26fd06f          	j	ffffffffc020086e <intr_enable>
ffffffffc020334c:	8082                	ret
ffffffffc020334e:	e42a                	sd	a0,8(sp)
ffffffffc0203350:	e03a                	sd	a4,0(sp)
        intr_disable();
ffffffffc0203352:	d22fd0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0203356:	6522                	ld	a0,8(sp)
ffffffffc0203358:	6702                	ld	a4,0(sp)
ffffffffc020335a:	4685                	li	a3,1
ffffffffc020335c:	bf65                	j	ffffffffc0203314 <proc_run+0x1a>

ffffffffc020335e <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc020335e:	0000a717          	auipc	a4,0xa
ffffffffc0203362:	17272703          	lw	a4,370(a4) # ffffffffc020d4d0 <nr_process>
ffffffffc0203366:	6785                	lui	a5,0x1
ffffffffc0203368:	22f75663          	bge	a4,a5,ffffffffc0203594 <do_fork+0x236>
{
ffffffffc020336c:	7179                	addi	sp,sp,-48
ffffffffc020336e:	f022                	sd	s0,32(sp)
ffffffffc0203370:	ec26                	sd	s1,24(sp)
ffffffffc0203372:	e84a                	sd	s2,16(sp)
ffffffffc0203374:	f406                	sd	ra,40(sp)
ffffffffc0203376:	892e                	mv	s2,a1
ffffffffc0203378:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020337a:	ea1ff0ef          	jal	ffffffffc020321a <alloc_proc>
ffffffffc020337e:	84aa                	mv	s1,a0
ffffffffc0203380:	20050863          	beqz	a0,ffffffffc0203590 <do_fork+0x232>
ffffffffc0203384:	e44e                	sd	s3,8(sp)
    proc->parent = current;
ffffffffc0203386:	0000a997          	auipc	s3,0xa
ffffffffc020338a:	15298993          	addi	s3,s3,338 # ffffffffc020d4d8 <current>
ffffffffc020338e:	0009b783          	ld	a5,0(s3)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203392:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203394:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203396:	8d5fe0ef          	jal	ffffffffc0201c6a <alloc_pages>
    if (page != NULL)
ffffffffc020339a:	1e050763          	beqz	a0,ffffffffc0203588 <do_fork+0x22a>
    return page - pages + nbase;
ffffffffc020339e:	0000a697          	auipc	a3,0xa
ffffffffc02033a2:	12a6b683          	ld	a3,298(a3) # ffffffffc020d4c8 <pages>
ffffffffc02033a6:	00002797          	auipc	a5,0x2
ffffffffc02033aa:	6727b783          	ld	a5,1650(a5) # ffffffffc0205a18 <nbase>
    return KADDR(page2pa(page));
ffffffffc02033ae:	0000a717          	auipc	a4,0xa
ffffffffc02033b2:	11273703          	ld	a4,274(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc02033b6:	40d506b3          	sub	a3,a0,a3
ffffffffc02033ba:	8699                	srai	a3,a3,0x6
ffffffffc02033bc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02033be:	00c69793          	slli	a5,a3,0xc
ffffffffc02033c2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02033c4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033c6:	1ee7f963          	bgeu	a5,a4,ffffffffc02035b8 <do_fork+0x25a>
    assert(current->mm == NULL);
ffffffffc02033ca:	0009b783          	ld	a5,0(s3)
ffffffffc02033ce:	0000a717          	auipc	a4,0xa
ffffffffc02033d2:	0ea73703          	ld	a4,234(a4) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc02033d6:	779c                	ld	a5,40(a5)
ffffffffc02033d8:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033da:	e894                	sd	a3,16(s1)
    assert(current->mm == NULL);
ffffffffc02033dc:	1a079e63          	bnez	a5,ffffffffc0203598 <do_fork+0x23a>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033e0:	6789                	lui	a5,0x2
ffffffffc02033e2:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033e6:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033e8:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033ea:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02033ec:	87b6                	mv	a5,a3
ffffffffc02033ee:	12040713          	addi	a4,s0,288
ffffffffc02033f2:	6a0c                	ld	a1,16(a2)
ffffffffc02033f4:	00063803          	ld	a6,0(a2) # ffffffff80000000 <kern_entry-0x40200000>
ffffffffc02033f8:	6608                	ld	a0,8(a2)
ffffffffc02033fa:	eb8c                	sd	a1,16(a5)
ffffffffc02033fc:	0107b023          	sd	a6,0(a5)
ffffffffc0203400:	e788                	sd	a0,8(a5)
ffffffffc0203402:	6e0c                	ld	a1,24(a2)
ffffffffc0203404:	02060613          	addi	a2,a2,32
ffffffffc0203408:	02078793          	addi	a5,a5,32
ffffffffc020340c:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0203410:	fee611e3          	bne	a2,a4,ffffffffc02033f2 <do_fork+0x94>
    proc->tf->gpr.a0 = 0;
ffffffffc0203414:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203418:	10090b63          	beqz	s2,ffffffffc020352e <do_fork+0x1d0>
ffffffffc020341c:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203420:	00000797          	auipc	a5,0x0
ffffffffc0203424:	e5c78793          	addi	a5,a5,-420 # ffffffffc020327c <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203428:	fc94                	sd	a3,56(s1)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020342a:	f89c                	sd	a5,48(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020342c:	100027f3          	csrr	a5,sstatus
ffffffffc0203430:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203432:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203434:	10079c63          	bnez	a5,ffffffffc020354c <do_fork+0x1ee>
    if (++last_pid >= MAX_PID)
ffffffffc0203438:	00006517          	auipc	a0,0x6
ffffffffc020343c:	bf452503          	lw	a0,-1036(a0) # ffffffffc020902c <last_pid.1>
ffffffffc0203440:	6789                	lui	a5,0x2
ffffffffc0203442:	2505                	addiw	a0,a0,1
ffffffffc0203444:	00006717          	auipc	a4,0x6
ffffffffc0203448:	bea72423          	sw	a0,-1048(a4) # ffffffffc020902c <last_pid.1>
ffffffffc020344c:	10f55f63          	bge	a0,a5,ffffffffc020356a <do_fork+0x20c>
    if (last_pid >= next_safe)
ffffffffc0203450:	00006797          	auipc	a5,0x6
ffffffffc0203454:	bd87a783          	lw	a5,-1064(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc0203458:	0000a417          	auipc	s0,0xa
ffffffffc020345c:	00040413          	mv	s0,s0
ffffffffc0203460:	06f54563          	blt	a0,a5,ffffffffc02034ca <do_fork+0x16c>
ffffffffc0203464:	0000a417          	auipc	s0,0xa
ffffffffc0203468:	ff440413          	addi	s0,s0,-12 # ffffffffc020d458 <proc_list>
ffffffffc020346c:	00843883          	ld	a7,8(s0)
        next_safe = MAX_PID;
ffffffffc0203470:	6789                	lui	a5,0x2
ffffffffc0203472:	00006717          	auipc	a4,0x6
ffffffffc0203476:	baf72b23          	sw	a5,-1098(a4) # ffffffffc0209028 <next_safe.0>
ffffffffc020347a:	86aa                	mv	a3,a0
ffffffffc020347c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020347e:	04888063          	beq	a7,s0,ffffffffc02034be <do_fork+0x160>
ffffffffc0203482:	882e                	mv	a6,a1
ffffffffc0203484:	87c6                	mv	a5,a7
ffffffffc0203486:	6609                	lui	a2,0x2
ffffffffc0203488:	a811                	j	ffffffffc020349c <do_fork+0x13e>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020348a:	00e6d663          	bge	a3,a4,ffffffffc0203496 <do_fork+0x138>
ffffffffc020348e:	00c75463          	bge	a4,a2,ffffffffc0203496 <do_fork+0x138>
                next_safe = proc->pid;
ffffffffc0203492:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203494:	4805                	li	a6,1
ffffffffc0203496:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203498:	00878d63          	beq	a5,s0,ffffffffc02034b2 <do_fork+0x154>
            if (proc->pid == last_pid)
ffffffffc020349c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034a0:	fed715e3          	bne	a4,a3,ffffffffc020348a <do_fork+0x12c>
                if (++last_pid >= next_safe)
ffffffffc02034a4:	2685                	addiw	a3,a3,1
ffffffffc02034a6:	0cc6db63          	bge	a3,a2,ffffffffc020357c <do_fork+0x21e>
ffffffffc02034aa:	679c                	ld	a5,8(a5)
ffffffffc02034ac:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034ae:	fe8797e3          	bne	a5,s0,ffffffffc020349c <do_fork+0x13e>
ffffffffc02034b2:	00080663          	beqz	a6,ffffffffc02034be <do_fork+0x160>
ffffffffc02034b6:	00006797          	auipc	a5,0x6
ffffffffc02034ba:	b6c7a923          	sw	a2,-1166(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc02034be:	c591                	beqz	a1,ffffffffc02034ca <do_fork+0x16c>
ffffffffc02034c0:	00006797          	auipc	a5,0x6
ffffffffc02034c4:	b6d7a623          	sw	a3,-1172(a5) # ffffffffc020902c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034c8:	8536                	mv	a0,a3
        proc->pid = get_pid();     // 分配PID
ffffffffc02034ca:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034cc:	45a9                	li	a1,10
ffffffffc02034ce:	510000ef          	jal	ffffffffc02039de <hash32>
ffffffffc02034d2:	02051793          	slli	a5,a0,0x20
ffffffffc02034d6:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02034da:	00006797          	auipc	a5,0x6
ffffffffc02034de:	f7e78793          	addi	a5,a5,-130 # ffffffffc0209458 <hash_list>
ffffffffc02034e2:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02034e4:	6510                	ld	a2,8(a0)
ffffffffc02034e6:	0d848793          	addi	a5,s1,216
ffffffffc02034ea:	6414                	ld	a3,8(s0)
        nr_process++;              // 进程数加1
ffffffffc02034ec:	0000a717          	auipc	a4,0xa
ffffffffc02034f0:	fe472703          	lw	a4,-28(a4) # ffffffffc020d4d0 <nr_process>
    prev->next = next->prev = elm;
ffffffffc02034f4:	e21c                	sd	a5,0(a2)
ffffffffc02034f6:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02034f8:	f0f0                	sd	a2,224(s1)
    elm->prev = prev;
ffffffffc02034fa:	ece8                	sd	a0,216(s1)
        list_add(&proc_list, &(proc->list_link)); // 加入进程链表
ffffffffc02034fc:	0c848613          	addi	a2,s1,200
    prev->next = next->prev = elm;
ffffffffc0203500:	e290                	sd	a2,0(a3)
        nr_process++;              // 进程数加1
ffffffffc0203502:	0017079b          	addiw	a5,a4,1
ffffffffc0203506:	e410                	sd	a2,8(s0)
    elm->next = next;
ffffffffc0203508:	e8f4                	sd	a3,208(s1)
    elm->prev = prev;
ffffffffc020350a:	e4e0                	sd	s0,200(s1)
ffffffffc020350c:	0000a717          	auipc	a4,0xa
ffffffffc0203510:	fcf72223          	sw	a5,-60(a4) # ffffffffc020d4d0 <nr_process>
    if (flag) {
ffffffffc0203514:	06091163          	bnez	s2,ffffffffc0203576 <do_fork+0x218>
    wakeup_proc(proc);
ffffffffc0203518:	8526                	mv	a0,s1
ffffffffc020351a:	3fe000ef          	jal	ffffffffc0203918 <wakeup_proc>
    ret = proc->pid;
ffffffffc020351e:	40c8                	lw	a0,4(s1)
ffffffffc0203520:	69a2                	ld	s3,8(sp)
}
ffffffffc0203522:	70a2                	ld	ra,40(sp)
ffffffffc0203524:	7402                	ld	s0,32(sp)
ffffffffc0203526:	64e2                	ld	s1,24(sp)
ffffffffc0203528:	6942                	ld	s2,16(sp)
ffffffffc020352a:	6145                	addi	sp,sp,48
ffffffffc020352c:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020352e:	8936                	mv	s2,a3
ffffffffc0203530:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203534:	00000797          	auipc	a5,0x0
ffffffffc0203538:	d4878793          	addi	a5,a5,-696 # ffffffffc020327c <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020353c:	fc94                	sd	a3,56(s1)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020353e:	f89c                	sd	a5,48(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203540:	100027f3          	csrr	a5,sstatus
ffffffffc0203544:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203546:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203548:	ee0788e3          	beqz	a5,ffffffffc0203438 <do_fork+0xda>
        intr_disable();
ffffffffc020354c:	b28fd0ef          	jal	ffffffffc0200874 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc0203550:	00006517          	auipc	a0,0x6
ffffffffc0203554:	adc52503          	lw	a0,-1316(a0) # ffffffffc020902c <last_pid.1>
ffffffffc0203558:	6789                	lui	a5,0x2
        return 1;
ffffffffc020355a:	4905                	li	s2,1
ffffffffc020355c:	2505                	addiw	a0,a0,1
ffffffffc020355e:	00006717          	auipc	a4,0x6
ffffffffc0203562:	aca72723          	sw	a0,-1330(a4) # ffffffffc020902c <last_pid.1>
ffffffffc0203566:	eef545e3          	blt	a0,a5,ffffffffc0203450 <do_fork+0xf2>
        last_pid = 1;
ffffffffc020356a:	4505                	li	a0,1
ffffffffc020356c:	00006797          	auipc	a5,0x6
ffffffffc0203570:	aca7a023          	sw	a0,-1344(a5) # ffffffffc020902c <last_pid.1>
        goto inside;
ffffffffc0203574:	bdc5                	j	ffffffffc0203464 <do_fork+0x106>
        intr_enable();
ffffffffc0203576:	af8fd0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020357a:	bf79                	j	ffffffffc0203518 <do_fork+0x1ba>
                    if (last_pid >= MAX_PID)
ffffffffc020357c:	6789                	lui	a5,0x2
ffffffffc020357e:	00f6c363          	blt	a3,a5,ffffffffc0203584 <do_fork+0x226>
                        last_pid = 1;
ffffffffc0203582:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203584:	4585                	li	a1,1
ffffffffc0203586:	bde5                	j	ffffffffc020347e <do_fork+0x120>
    kfree(proc);
ffffffffc0203588:	8526                	mv	a0,s1
ffffffffc020358a:	dc4fe0ef          	jal	ffffffffc0201b4e <kfree>
ffffffffc020358e:	69a2                	ld	s3,8(sp)
    ret = -E_NO_MEM;
ffffffffc0203590:	5571                	li	a0,-4
ffffffffc0203592:	bf41                	j	ffffffffc0203522 <do_fork+0x1c4>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203594:	556d                	li	a0,-5
}
ffffffffc0203596:	8082                	ret
    assert(current->mm == NULL);
ffffffffc0203598:	00002697          	auipc	a3,0x2
ffffffffc020359c:	ff068693          	addi	a3,a3,-16 # ffffffffc0205588 <etext+0x16c6>
ffffffffc02035a0:	00001617          	auipc	a2,0x1
ffffffffc02035a4:	2f860613          	addi	a2,a2,760 # ffffffffc0204898 <etext+0x9d6>
ffffffffc02035a8:	12500593          	li	a1,293
ffffffffc02035ac:	00002517          	auipc	a0,0x2
ffffffffc02035b0:	ff450513          	addi	a0,a0,-12 # ffffffffc02055a0 <etext+0x16de>
ffffffffc02035b4:	e53fc0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02035b8:	00001617          	auipc	a2,0x1
ffffffffc02035bc:	69060613          	addi	a2,a2,1680 # ffffffffc0204c48 <etext+0xd86>
ffffffffc02035c0:	07100593          	li	a1,113
ffffffffc02035c4:	00001517          	auipc	a0,0x1
ffffffffc02035c8:	6ac50513          	addi	a0,a0,1708 # ffffffffc0204c70 <etext+0xdae>
ffffffffc02035cc:	e3bfc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02035d0 <kernel_thread>:
{
ffffffffc02035d0:	7129                	addi	sp,sp,-320
ffffffffc02035d2:	fa22                	sd	s0,304(sp)
ffffffffc02035d4:	f626                	sd	s1,296(sp)
ffffffffc02035d6:	f24a                	sd	s2,288(sp)
ffffffffc02035d8:	842a                	mv	s0,a0
ffffffffc02035da:	84ae                	mv	s1,a1
ffffffffc02035dc:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035de:	850a                	mv	a0,sp
ffffffffc02035e0:	12000613          	li	a2,288
ffffffffc02035e4:	4581                	li	a1,0
{
ffffffffc02035e6:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035e8:	08d000ef          	jal	ffffffffc0203e74 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035ec:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035ee:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035f0:	100027f3          	csrr	a5,sstatus
ffffffffc02035f4:	edd7f793          	andi	a5,a5,-291
ffffffffc02035f8:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035fc:	860a                	mv	a2,sp
ffffffffc02035fe:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203602:	00000717          	auipc	a4,0x0
ffffffffc0203606:	c1070713          	addi	a4,a4,-1008 # ffffffffc0203212 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020360a:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020360c:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020360e:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203610:	d4fff0ef          	jal	ffffffffc020335e <do_fork>
}
ffffffffc0203614:	70f2                	ld	ra,312(sp)
ffffffffc0203616:	7452                	ld	s0,304(sp)
ffffffffc0203618:	74b2                	ld	s1,296(sp)
ffffffffc020361a:	7912                	ld	s2,288(sp)
ffffffffc020361c:	6131                	addi	sp,sp,320
ffffffffc020361e:	8082                	ret

ffffffffc0203620 <do_exit>:
{
ffffffffc0203620:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203622:	00002617          	auipc	a2,0x2
ffffffffc0203626:	f9660613          	addi	a2,a2,-106 # ffffffffc02055b8 <etext+0x16f6>
ffffffffc020362a:	19800593          	li	a1,408
ffffffffc020362e:	00002517          	auipc	a0,0x2
ffffffffc0203632:	f7250513          	addi	a0,a0,-142 # ffffffffc02055a0 <etext+0x16de>
{
ffffffffc0203636:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc0203638:	dcffc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020363c <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc020363c:	7179                	addi	sp,sp,-48
ffffffffc020363e:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203640:	0000a797          	auipc	a5,0xa
ffffffffc0203644:	e1878793          	addi	a5,a5,-488 # ffffffffc020d458 <proc_list>
ffffffffc0203648:	f406                	sd	ra,40(sp)
ffffffffc020364a:	f022                	sd	s0,32(sp)
ffffffffc020364c:	e84a                	sd	s2,16(sp)
ffffffffc020364e:	e44e                	sd	s3,8(sp)
ffffffffc0203650:	00006497          	auipc	s1,0x6
ffffffffc0203654:	e0848493          	addi	s1,s1,-504 # ffffffffc0209458 <hash_list>
ffffffffc0203658:	e79c                	sd	a5,8(a5)
ffffffffc020365a:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020365c:	0000a717          	auipc	a4,0xa
ffffffffc0203660:	dfc70713          	addi	a4,a4,-516 # ffffffffc020d458 <proc_list>
ffffffffc0203664:	87a6                	mv	a5,s1
ffffffffc0203666:	e79c                	sd	a5,8(a5)
ffffffffc0203668:	e39c                	sd	a5,0(a5)
ffffffffc020366a:	07c1                	addi	a5,a5,16
ffffffffc020366c:	fee79de3          	bne	a5,a4,ffffffffc0203666 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203670:	babff0ef          	jal	ffffffffc020321a <alloc_proc>
ffffffffc0203674:	0000a917          	auipc	s2,0xa
ffffffffc0203678:	e7490913          	addi	s2,s2,-396 # ffffffffc020d4e8 <idleproc>
ffffffffc020367c:	00a93023          	sd	a0,0(s2)
ffffffffc0203680:	1a050263          	beqz	a0,ffffffffc0203824 <proc_init+0x1e8>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203684:	07000513          	li	a0,112
ffffffffc0203688:	c20fe0ef          	jal	ffffffffc0201aa8 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020368c:	07000613          	li	a2,112
ffffffffc0203690:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203692:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203694:	7e0000ef          	jal	ffffffffc0203e74 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0203698:	00093503          	ld	a0,0(s2)
ffffffffc020369c:	85a2                	mv	a1,s0
ffffffffc020369e:	07000613          	li	a2,112
ffffffffc02036a2:	03050513          	addi	a0,a0,48
ffffffffc02036a6:	7f8000ef          	jal	ffffffffc0203e9e <memcmp>
ffffffffc02036aa:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036ac:	453d                	li	a0,15
ffffffffc02036ae:	bfafe0ef          	jal	ffffffffc0201aa8 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036b2:	463d                	li	a2,15
ffffffffc02036b4:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036b6:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036b8:	7bc000ef          	jal	ffffffffc0203e74 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02036bc:	00093503          	ld	a0,0(s2)
ffffffffc02036c0:	85a2                	mv	a1,s0
ffffffffc02036c2:	463d                	li	a2,15
ffffffffc02036c4:	0b450513          	addi	a0,a0,180
ffffffffc02036c8:	7d6000ef          	jal	ffffffffc0203e9e <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02036cc:	00093783          	ld	a5,0(s2)
ffffffffc02036d0:	0000a717          	auipc	a4,0xa
ffffffffc02036d4:	dd873703          	ld	a4,-552(a4) # ffffffffc020d4a8 <boot_pgdir_pa>
ffffffffc02036d8:	77d4                	ld	a3,168(a5)
ffffffffc02036da:	0ee68863          	beq	a3,a4,ffffffffc02037ca <proc_init+0x18e>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02036de:	4709                	li	a4,2
ffffffffc02036e0:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036e2:	00003717          	auipc	a4,0x3
ffffffffc02036e6:	91e70713          	addi	a4,a4,-1762 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036ea:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036ee:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036f0:	4705                	li	a4,1
ffffffffc02036f2:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036f4:	8522                	mv	a0,s0
ffffffffc02036f6:	4641                	li	a2,16
ffffffffc02036f8:	4581                	li	a1,0
ffffffffc02036fa:	77a000ef          	jal	ffffffffc0203e74 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036fe:	8522                	mv	a0,s0
ffffffffc0203700:	463d                	li	a2,15
ffffffffc0203702:	00002597          	auipc	a1,0x2
ffffffffc0203706:	efe58593          	addi	a1,a1,-258 # ffffffffc0205600 <etext+0x173e>
ffffffffc020370a:	77c000ef          	jal	ffffffffc0203e86 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020370e:	0000a797          	auipc	a5,0xa
ffffffffc0203712:	dc27a783          	lw	a5,-574(a5) # ffffffffc020d4d0 <nr_process>

    current = idleproc;
ffffffffc0203716:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020371a:	4601                	li	a2,0
    nr_process++;
ffffffffc020371c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020371e:	00002597          	auipc	a1,0x2
ffffffffc0203722:	eea58593          	addi	a1,a1,-278 # ffffffffc0205608 <etext+0x1746>
ffffffffc0203726:	00000517          	auipc	a0,0x0
ffffffffc020372a:	b6450513          	addi	a0,a0,-1180 # ffffffffc020328a <init_main>
    current = idleproc;
ffffffffc020372e:	0000a697          	auipc	a3,0xa
ffffffffc0203732:	dae6b523          	sd	a4,-598(a3) # ffffffffc020d4d8 <current>
    nr_process++;
ffffffffc0203736:	0000a717          	auipc	a4,0xa
ffffffffc020373a:	d8f72d23          	sw	a5,-614(a4) # ffffffffc020d4d0 <nr_process>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020373e:	e93ff0ef          	jal	ffffffffc02035d0 <kernel_thread>
ffffffffc0203742:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203744:	0ea05c63          	blez	a0,ffffffffc020383c <proc_init+0x200>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203748:	6789                	lui	a5,0x2
ffffffffc020374a:	17f9                	addi	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc020374c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203750:	02e7e463          	bltu	a5,a4,ffffffffc0203778 <proc_init+0x13c>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203754:	45a9                	li	a1,10
ffffffffc0203756:	288000ef          	jal	ffffffffc02039de <hash32>
ffffffffc020375a:	02051713          	slli	a4,a0,0x20
ffffffffc020375e:	01c75793          	srli	a5,a4,0x1c
ffffffffc0203762:	00f486b3          	add	a3,s1,a5
ffffffffc0203766:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0203768:	a029                	j	ffffffffc0203772 <proc_init+0x136>
            if (proc->pid == pid)
ffffffffc020376a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020376e:	0a870863          	beq	a4,s0,ffffffffc020381e <proc_init+0x1e2>
    return listelm->next;
ffffffffc0203772:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203774:	fef69be3          	bne	a3,a5,ffffffffc020376a <proc_init+0x12e>
    return NULL;
ffffffffc0203778:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020377a:	0b478413          	addi	s0,a5,180
ffffffffc020377e:	4641                	li	a2,16
ffffffffc0203780:	4581                	li	a1,0
ffffffffc0203782:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203784:	0000a717          	auipc	a4,0xa
ffffffffc0203788:	d4f73e23          	sd	a5,-676(a4) # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020378c:	6e8000ef          	jal	ffffffffc0203e74 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203790:	8522                	mv	a0,s0
ffffffffc0203792:	463d                	li	a2,15
ffffffffc0203794:	00002597          	auipc	a1,0x2
ffffffffc0203798:	ea458593          	addi	a1,a1,-348 # ffffffffc0205638 <etext+0x1776>
ffffffffc020379c:	6ea000ef          	jal	ffffffffc0203e86 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037a0:	00093783          	ld	a5,0(s2)
ffffffffc02037a4:	cbe1                	beqz	a5,ffffffffc0203874 <proc_init+0x238>
ffffffffc02037a6:	43dc                	lw	a5,4(a5)
ffffffffc02037a8:	e7f1                	bnez	a5,ffffffffc0203874 <proc_init+0x238>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037aa:	0000a797          	auipc	a5,0xa
ffffffffc02037ae:	d367b783          	ld	a5,-714(a5) # ffffffffc020d4e0 <initproc>
ffffffffc02037b2:	c3cd                	beqz	a5,ffffffffc0203854 <proc_init+0x218>
ffffffffc02037b4:	43d8                	lw	a4,4(a5)
ffffffffc02037b6:	4785                	li	a5,1
ffffffffc02037b8:	08f71e63          	bne	a4,a5,ffffffffc0203854 <proc_init+0x218>
}
ffffffffc02037bc:	70a2                	ld	ra,40(sp)
ffffffffc02037be:	7402                	ld	s0,32(sp)
ffffffffc02037c0:	64e2                	ld	s1,24(sp)
ffffffffc02037c2:	6942                	ld	s2,16(sp)
ffffffffc02037c4:	69a2                	ld	s3,8(sp)
ffffffffc02037c6:	6145                	addi	sp,sp,48
ffffffffc02037c8:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02037ca:	73d8                	ld	a4,160(a5)
ffffffffc02037cc:	f00719e3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037d0:	f00997e3          	bnez	s3,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037d4:	4398                	lw	a4,0(a5)
ffffffffc02037d6:	f00714e3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037da:	43d4                	lw	a3,4(a5)
ffffffffc02037dc:	577d                	li	a4,-1
ffffffffc02037de:	f0e690e3          	bne	a3,a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037e2:	4798                	lw	a4,8(a5)
ffffffffc02037e4:	ee071de3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037e8:	6b98                	ld	a4,16(a5)
ffffffffc02037ea:	ee071ae3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037ee:	4f98                	lw	a4,24(a5)
ffffffffc02037f0:	ee0717e3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037f4:	7398                	ld	a4,32(a5)
ffffffffc02037f6:	ee0714e3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc02037fa:	7798                	ld	a4,40(a5)
ffffffffc02037fc:	ee0711e3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
ffffffffc0203800:	0b07a703          	lw	a4,176(a5)
ffffffffc0203804:	8f49                	or	a4,a4,a0
ffffffffc0203806:	2701                	sext.w	a4,a4
ffffffffc0203808:	ec071be3          	bnez	a4,ffffffffc02036de <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc020380c:	00002517          	auipc	a0,0x2
ffffffffc0203810:	ddc50513          	addi	a0,a0,-548 # ffffffffc02055e8 <etext+0x1726>
ffffffffc0203814:	981fc0ef          	jal	ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203818:	00093783          	ld	a5,0(s2)
ffffffffc020381c:	b5c9                	j	ffffffffc02036de <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020381e:	f2878793          	addi	a5,a5,-216
ffffffffc0203822:	bfa1                	j	ffffffffc020377a <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
ffffffffc0203824:	00002617          	auipc	a2,0x2
ffffffffc0203828:	dac60613          	addi	a2,a2,-596 # ffffffffc02055d0 <etext+0x170e>
ffffffffc020382c:	1b300593          	li	a1,435
ffffffffc0203830:	00002517          	auipc	a0,0x2
ffffffffc0203834:	d7050513          	addi	a0,a0,-656 # ffffffffc02055a0 <etext+0x16de>
ffffffffc0203838:	bcffc0ef          	jal	ffffffffc0200406 <__panic>
        panic("create init_main failed.\n");
ffffffffc020383c:	00002617          	auipc	a2,0x2
ffffffffc0203840:	ddc60613          	addi	a2,a2,-548 # ffffffffc0205618 <etext+0x1756>
ffffffffc0203844:	1d000593          	li	a1,464
ffffffffc0203848:	00002517          	auipc	a0,0x2
ffffffffc020384c:	d5850513          	addi	a0,a0,-680 # ffffffffc02055a0 <etext+0x16de>
ffffffffc0203850:	bb7fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203854:	00002697          	auipc	a3,0x2
ffffffffc0203858:	e1468693          	addi	a3,a3,-492 # ffffffffc0205668 <etext+0x17a6>
ffffffffc020385c:	00001617          	auipc	a2,0x1
ffffffffc0203860:	03c60613          	addi	a2,a2,60 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0203864:	1d700593          	li	a1,471
ffffffffc0203868:	00002517          	auipc	a0,0x2
ffffffffc020386c:	d3850513          	addi	a0,a0,-712 # ffffffffc02055a0 <etext+0x16de>
ffffffffc0203870:	b97fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203874:	00002697          	auipc	a3,0x2
ffffffffc0203878:	dcc68693          	addi	a3,a3,-564 # ffffffffc0205640 <etext+0x177e>
ffffffffc020387c:	00001617          	auipc	a2,0x1
ffffffffc0203880:	01c60613          	addi	a2,a2,28 # ffffffffc0204898 <etext+0x9d6>
ffffffffc0203884:	1d600593          	li	a1,470
ffffffffc0203888:	00002517          	auipc	a0,0x2
ffffffffc020388c:	d1850513          	addi	a0,a0,-744 # ffffffffc02055a0 <etext+0x16de>
ffffffffc0203890:	b77fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203894 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203894:	1141                	addi	sp,sp,-16
ffffffffc0203896:	e022                	sd	s0,0(sp)
ffffffffc0203898:	e406                	sd	ra,8(sp)
ffffffffc020389a:	0000a417          	auipc	s0,0xa
ffffffffc020389e:	c3e40413          	addi	s0,s0,-962 # ffffffffc020d4d8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038a2:	6018                	ld	a4,0(s0)
ffffffffc02038a4:	4f1c                	lw	a5,24(a4)
ffffffffc02038a6:	dffd                	beqz	a5,ffffffffc02038a4 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02038a8:	0a2000ef          	jal	ffffffffc020394a <schedule>
ffffffffc02038ac:	bfdd                	j	ffffffffc02038a2 <cpu_idle+0xe>

ffffffffc02038ae <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02038ae:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02038b2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02038b6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02038b8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02038ba:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02038be:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02038c2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02038c6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02038ca:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02038ce:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02038d2:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02038d6:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02038da:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02038de:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02038e2:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02038e6:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02038ea:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038ec:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038ee:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038f2:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038f6:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038fa:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02038fe:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203902:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203906:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020390a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020390e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203912:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203916:	8082                	ret

ffffffffc0203918 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203918:	411c                	lw	a5,0(a0)
ffffffffc020391a:	4705                	li	a4,1
ffffffffc020391c:	37f9                	addiw	a5,a5,-2
ffffffffc020391e:	00f77563          	bgeu	a4,a5,ffffffffc0203928 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc0203922:	4789                	li	a5,2
ffffffffc0203924:	c11c                	sw	a5,0(a0)
ffffffffc0203926:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203928:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020392a:	00002697          	auipc	a3,0x2
ffffffffc020392e:	d6668693          	addi	a3,a3,-666 # ffffffffc0205690 <etext+0x17ce>
ffffffffc0203932:	00001617          	auipc	a2,0x1
ffffffffc0203936:	f6660613          	addi	a2,a2,-154 # ffffffffc0204898 <etext+0x9d6>
ffffffffc020393a:	45a5                	li	a1,9
ffffffffc020393c:	00002517          	auipc	a0,0x2
ffffffffc0203940:	d9450513          	addi	a0,a0,-620 # ffffffffc02056d0 <etext+0x180e>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203944:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203946:	ac1fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020394a <schedule>:
}

void
schedule(void) {
ffffffffc020394a:	1101                	addi	sp,sp,-32
ffffffffc020394c:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020394e:	100027f3          	csrr	a5,sstatus
ffffffffc0203952:	8b89                	andi	a5,a5,2
ffffffffc0203954:	4301                	li	t1,0
ffffffffc0203956:	e3c1                	bnez	a5,ffffffffc02039d6 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203958:	0000a897          	auipc	a7,0xa
ffffffffc020395c:	b808b883          	ld	a7,-1152(a7) # ffffffffc020d4d8 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203960:	0000a517          	auipc	a0,0xa
ffffffffc0203964:	b8853503          	ld	a0,-1144(a0) # ffffffffc020d4e8 <idleproc>
        current->need_resched = 0;
ffffffffc0203968:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020396c:	04a88f63          	beq	a7,a0,ffffffffc02039ca <schedule+0x80>
ffffffffc0203970:	0c888693          	addi	a3,a7,200
ffffffffc0203974:	0000a617          	auipc	a2,0xa
ffffffffc0203978:	ae460613          	addi	a2,a2,-1308 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020397c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020397e:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203980:	4809                	li	a6,2
ffffffffc0203982:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203984:	00c78863          	beq	a5,a2,ffffffffc0203994 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203988:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020398c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203990:	03070363          	beq	a4,a6,ffffffffc02039b6 <schedule+0x6c>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203994:	fef697e3          	bne	a3,a5,ffffffffc0203982 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203998:	ed99                	bnez	a1,ffffffffc02039b6 <schedule+0x6c>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020399a:	451c                	lw	a5,8(a0)
ffffffffc020399c:	2785                	addiw	a5,a5,1
ffffffffc020399e:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02039a0:	00a88663          	beq	a7,a0,ffffffffc02039ac <schedule+0x62>
ffffffffc02039a4:	e41a                	sd	t1,8(sp)
            proc_run(next);
ffffffffc02039a6:	955ff0ef          	jal	ffffffffc02032fa <proc_run>
ffffffffc02039aa:	6322                	ld	t1,8(sp)
    if (flag) {
ffffffffc02039ac:	00031b63          	bnez	t1,ffffffffc02039c2 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02039b0:	60e2                	ld	ra,24(sp)
ffffffffc02039b2:	6105                	addi	sp,sp,32
ffffffffc02039b4:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039b6:	4198                	lw	a4,0(a1)
ffffffffc02039b8:	4789                	li	a5,2
ffffffffc02039ba:	fef710e3          	bne	a4,a5,ffffffffc020399a <schedule+0x50>
ffffffffc02039be:	852e                	mv	a0,a1
ffffffffc02039c0:	bfe9                	j	ffffffffc020399a <schedule+0x50>
}
ffffffffc02039c2:	60e2                	ld	ra,24(sp)
ffffffffc02039c4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02039c6:	ea9fc06f          	j	ffffffffc020086e <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039ca:	0000a617          	auipc	a2,0xa
ffffffffc02039ce:	a8e60613          	addi	a2,a2,-1394 # ffffffffc020d458 <proc_list>
ffffffffc02039d2:	86b2                	mv	a3,a2
ffffffffc02039d4:	b765                	j	ffffffffc020397c <schedule+0x32>
        intr_disable();
ffffffffc02039d6:	e9ffc0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc02039da:	4305                	li	t1,1
ffffffffc02039dc:	bfb5                	j	ffffffffc0203958 <schedule+0xe>

ffffffffc02039de <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02039de:	9e3707b7          	lui	a5,0x9e370
ffffffffc02039e2:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc02039e4:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039e8:	02000513          	li	a0,32
ffffffffc02039ec:	9d0d                	subw	a0,a0,a1
}
ffffffffc02039ee:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02039f2:	8082                	ret

ffffffffc02039f4 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039f4:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039f6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039fa:	f022                	sd	s0,32(sp)
ffffffffc02039fc:	ec26                	sd	s1,24(sp)
ffffffffc02039fe:	e84a                	sd	s2,16(sp)
ffffffffc0203a00:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a02:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a06:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a08:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a0c:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a10:	84aa                	mv	s1,a0
ffffffffc0203a12:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0203a14:	03067d63          	bgeu	a2,a6,ffffffffc0203a4e <printnum+0x5a>
ffffffffc0203a18:	e44e                	sd	s3,8(sp)
ffffffffc0203a1a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a1c:	4785                	li	a5,1
ffffffffc0203a1e:	00e7d763          	bge	a5,a4,ffffffffc0203a2c <printnum+0x38>
            putch(padc, putdat);
ffffffffc0203a22:	85ca                	mv	a1,s2
ffffffffc0203a24:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0203a26:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a28:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a2a:	fc65                	bnez	s0,ffffffffc0203a22 <printnum+0x2e>
ffffffffc0203a2c:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a2e:	00002797          	auipc	a5,0x2
ffffffffc0203a32:	cba78793          	addi	a5,a5,-838 # ffffffffc02056e8 <etext+0x1826>
ffffffffc0203a36:	97d2                	add	a5,a5,s4
}
ffffffffc0203a38:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a3a:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0203a3e:	70a2                	ld	ra,40(sp)
ffffffffc0203a40:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a42:	85ca                	mv	a1,s2
ffffffffc0203a44:	87a6                	mv	a5,s1
}
ffffffffc0203a46:	6942                	ld	s2,16(sp)
ffffffffc0203a48:	64e2                	ld	s1,24(sp)
ffffffffc0203a4a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a4c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a4e:	03065633          	divu	a2,a2,a6
ffffffffc0203a52:	8722                	mv	a4,s0
ffffffffc0203a54:	fa1ff0ef          	jal	ffffffffc02039f4 <printnum>
ffffffffc0203a58:	bfd9                	j	ffffffffc0203a2e <printnum+0x3a>

ffffffffc0203a5a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a5a:	7119                	addi	sp,sp,-128
ffffffffc0203a5c:	f4a6                	sd	s1,104(sp)
ffffffffc0203a5e:	f0ca                	sd	s2,96(sp)
ffffffffc0203a60:	ecce                	sd	s3,88(sp)
ffffffffc0203a62:	e8d2                	sd	s4,80(sp)
ffffffffc0203a64:	e4d6                	sd	s5,72(sp)
ffffffffc0203a66:	e0da                	sd	s6,64(sp)
ffffffffc0203a68:	f862                	sd	s8,48(sp)
ffffffffc0203a6a:	fc86                	sd	ra,120(sp)
ffffffffc0203a6c:	f8a2                	sd	s0,112(sp)
ffffffffc0203a6e:	fc5e                	sd	s7,56(sp)
ffffffffc0203a70:	f466                	sd	s9,40(sp)
ffffffffc0203a72:	f06a                	sd	s10,32(sp)
ffffffffc0203a74:	ec6e                	sd	s11,24(sp)
ffffffffc0203a76:	84aa                	mv	s1,a0
ffffffffc0203a78:	8c32                	mv	s8,a2
ffffffffc0203a7a:	8a36                	mv	s4,a3
ffffffffc0203a7c:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a7e:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a82:	05500b13          	li	s6,85
ffffffffc0203a86:	00002a97          	auipc	s5,0x2
ffffffffc0203a8a:	e02a8a93          	addi	s5,s5,-510 # ffffffffc0205888 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a8e:	000c4503          	lbu	a0,0(s8)
ffffffffc0203a92:	001c0413          	addi	s0,s8,1
ffffffffc0203a96:	01350a63          	beq	a0,s3,ffffffffc0203aaa <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0203a9a:	cd0d                	beqz	a0,ffffffffc0203ad4 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0203a9c:	85ca                	mv	a1,s2
ffffffffc0203a9e:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203aa0:	00044503          	lbu	a0,0(s0)
ffffffffc0203aa4:	0405                	addi	s0,s0,1
ffffffffc0203aa6:	ff351ae3          	bne	a0,s3,ffffffffc0203a9a <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0203aaa:	5cfd                	li	s9,-1
ffffffffc0203aac:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0203aae:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0203ab2:	4b81                	li	s7,0
ffffffffc0203ab4:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ab6:	00044683          	lbu	a3,0(s0)
ffffffffc0203aba:	00140c13          	addi	s8,s0,1
ffffffffc0203abe:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0203ac2:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ac6:	02bb6663          	bltu	s6,a1,ffffffffc0203af2 <vprintfmt+0x98>
ffffffffc0203aca:	058a                	slli	a1,a1,0x2
ffffffffc0203acc:	95d6                	add	a1,a1,s5
ffffffffc0203ace:	4198                	lw	a4,0(a1)
ffffffffc0203ad0:	9756                	add	a4,a4,s5
ffffffffc0203ad2:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203ad4:	70e6                	ld	ra,120(sp)
ffffffffc0203ad6:	7446                	ld	s0,112(sp)
ffffffffc0203ad8:	74a6                	ld	s1,104(sp)
ffffffffc0203ada:	7906                	ld	s2,96(sp)
ffffffffc0203adc:	69e6                	ld	s3,88(sp)
ffffffffc0203ade:	6a46                	ld	s4,80(sp)
ffffffffc0203ae0:	6aa6                	ld	s5,72(sp)
ffffffffc0203ae2:	6b06                	ld	s6,64(sp)
ffffffffc0203ae4:	7be2                	ld	s7,56(sp)
ffffffffc0203ae6:	7c42                	ld	s8,48(sp)
ffffffffc0203ae8:	7ca2                	ld	s9,40(sp)
ffffffffc0203aea:	7d02                	ld	s10,32(sp)
ffffffffc0203aec:	6de2                	ld	s11,24(sp)
ffffffffc0203aee:	6109                	addi	sp,sp,128
ffffffffc0203af0:	8082                	ret
            putch('%', putdat);
ffffffffc0203af2:	85ca                	mv	a1,s2
ffffffffc0203af4:	02500513          	li	a0,37
ffffffffc0203af8:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203afa:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203afe:	02500713          	li	a4,37
ffffffffc0203b02:	8c22                	mv	s8,s0
ffffffffc0203b04:	f8e785e3          	beq	a5,a4,ffffffffc0203a8e <vprintfmt+0x34>
ffffffffc0203b08:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203b0c:	1c7d                	addi	s8,s8,-1
ffffffffc0203b0e:	fee79de3          	bne	a5,a4,ffffffffc0203b08 <vprintfmt+0xae>
ffffffffc0203b12:	bfb5                	j	ffffffffc0203a8e <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203b14:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203b18:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0203b1a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203b1e:	fd06071b          	addiw	a4,a2,-48
ffffffffc0203b22:	24e56a63          	bltu	a0,a4,ffffffffc0203d76 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0203b26:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b28:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0203b2a:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0203b2e:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b32:	0197073b          	addw	a4,a4,s9
ffffffffc0203b36:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b3a:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b3c:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b40:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b42:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0203b46:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203b4a:	feb570e3          	bgeu	a0,a1,ffffffffc0203b2a <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0203b4e:	f60d54e3          	bgez	s10,ffffffffc0203ab6 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203b52:	8d66                	mv	s10,s9
ffffffffc0203b54:	5cfd                	li	s9,-1
ffffffffc0203b56:	b785                	j	ffffffffc0203ab6 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b58:	8db6                	mv	s11,a3
ffffffffc0203b5a:	8462                	mv	s0,s8
ffffffffc0203b5c:	bfa9                	j	ffffffffc0203ab6 <vprintfmt+0x5c>
ffffffffc0203b5e:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203b60:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203b62:	bf91                	j	ffffffffc0203ab6 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203b64:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b66:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b6a:	00f74463          	blt	a4,a5,ffffffffc0203b72 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0203b6e:	1a078763          	beqz	a5,ffffffffc0203d1c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0203b72:	000a3603          	ld	a2,0(s4)
ffffffffc0203b76:	46c1                	li	a3,16
ffffffffc0203b78:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b7a:	000d879b          	sext.w	a5,s11
ffffffffc0203b7e:	876a                	mv	a4,s10
ffffffffc0203b80:	85ca                	mv	a1,s2
ffffffffc0203b82:	8526                	mv	a0,s1
ffffffffc0203b84:	e71ff0ef          	jal	ffffffffc02039f4 <printnum>
            break;
ffffffffc0203b88:	b719                	j	ffffffffc0203a8e <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b8a:	000a2503          	lw	a0,0(s4)
ffffffffc0203b8e:	85ca                	mv	a1,s2
ffffffffc0203b90:	0a21                	addi	s4,s4,8
ffffffffc0203b92:	9482                	jalr	s1
            break;
ffffffffc0203b94:	bded                	j	ffffffffc0203a8e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203b96:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b98:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b9c:	00f74463          	blt	a4,a5,ffffffffc0203ba4 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203ba0:	16078963          	beqz	a5,ffffffffc0203d12 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0203ba4:	000a3603          	ld	a2,0(s4)
ffffffffc0203ba8:	46a9                	li	a3,10
ffffffffc0203baa:	8a2e                	mv	s4,a1
ffffffffc0203bac:	b7f9                	j	ffffffffc0203b7a <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0203bae:	85ca                	mv	a1,s2
ffffffffc0203bb0:	03000513          	li	a0,48
ffffffffc0203bb4:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0203bb6:	85ca                	mv	a1,s2
ffffffffc0203bb8:	07800513          	li	a0,120
ffffffffc0203bbc:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bbe:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203bc2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bc4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203bc6:	bf55                	j	ffffffffc0203b7a <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0203bc8:	85ca                	mv	a1,s2
ffffffffc0203bca:	02500513          	li	a0,37
ffffffffc0203bce:	9482                	jalr	s1
            break;
ffffffffc0203bd0:	bd7d                	j	ffffffffc0203a8e <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203bd2:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bd6:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203bd8:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203bda:	bf95                	j	ffffffffc0203b4e <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0203bdc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bde:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203be2:	00f74463          	blt	a4,a5,ffffffffc0203bea <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0203be6:	12078163          	beqz	a5,ffffffffc0203d08 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0203bea:	000a3603          	ld	a2,0(s4)
ffffffffc0203bee:	46a1                	li	a3,8
ffffffffc0203bf0:	8a2e                	mv	s4,a1
ffffffffc0203bf2:	b761                	j	ffffffffc0203b7a <vprintfmt+0x120>
            if (width < 0)
ffffffffc0203bf4:	876a                	mv	a4,s10
ffffffffc0203bf6:	000d5363          	bgez	s10,ffffffffc0203bfc <vprintfmt+0x1a2>
ffffffffc0203bfa:	4701                	li	a4,0
ffffffffc0203bfc:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c00:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203c02:	bd55                	j	ffffffffc0203ab6 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0203c04:	000d841b          	sext.w	s0,s11
ffffffffc0203c08:	fd340793          	addi	a5,s0,-45
ffffffffc0203c0c:	00f037b3          	snez	a5,a5
ffffffffc0203c10:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c14:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0203c18:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c1a:	008a0793          	addi	a5,s4,8
ffffffffc0203c1e:	e43e                	sd	a5,8(sp)
ffffffffc0203c20:	100d8c63          	beqz	s11,ffffffffc0203d38 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0203c24:	12071363          	bnez	a4,ffffffffc0203d4a <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c28:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c2c:	0007851b          	sext.w	a0,a5
ffffffffc0203c30:	c78d                	beqz	a5,ffffffffc0203c5a <vprintfmt+0x200>
ffffffffc0203c32:	0d85                	addi	s11,s11,1
ffffffffc0203c34:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c36:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c3a:	000cc563          	bltz	s9,ffffffffc0203c44 <vprintfmt+0x1ea>
ffffffffc0203c3e:	3cfd                	addiw	s9,s9,-1
ffffffffc0203c40:	008c8d63          	beq	s9,s0,ffffffffc0203c5a <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c44:	020b9663          	bnez	s7,ffffffffc0203c70 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0203c48:	85ca                	mv	a1,s2
ffffffffc0203c4a:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c4c:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c50:	0d85                	addi	s11,s11,1
ffffffffc0203c52:	3d7d                	addiw	s10,s10,-1
ffffffffc0203c54:	0007851b          	sext.w	a0,a5
ffffffffc0203c58:	f3ed                	bnez	a5,ffffffffc0203c3a <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0203c5a:	01a05963          	blez	s10,ffffffffc0203c6c <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0203c5e:	85ca                	mv	a1,s2
ffffffffc0203c60:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0203c64:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0203c66:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0203c68:	fe0d1be3          	bnez	s10,ffffffffc0203c5e <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c6c:	6a22                	ld	s4,8(sp)
ffffffffc0203c6e:	b505                	j	ffffffffc0203a8e <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c70:	3781                	addiw	a5,a5,-32
ffffffffc0203c72:	fcfa7be3          	bgeu	s4,a5,ffffffffc0203c48 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0203c76:	03f00513          	li	a0,63
ffffffffc0203c7a:	85ca                	mv	a1,s2
ffffffffc0203c7c:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c7e:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c82:	0d85                	addi	s11,s11,1
ffffffffc0203c84:	3d7d                	addiw	s10,s10,-1
ffffffffc0203c86:	0007851b          	sext.w	a0,a5
ffffffffc0203c8a:	dbe1                	beqz	a5,ffffffffc0203c5a <vprintfmt+0x200>
ffffffffc0203c8c:	fa0cd9e3          	bgez	s9,ffffffffc0203c3e <vprintfmt+0x1e4>
ffffffffc0203c90:	b7c5                	j	ffffffffc0203c70 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0203c92:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c96:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0203c98:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c9a:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0203c9e:	8fb9                	xor	a5,a5,a4
ffffffffc0203ca0:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203ca4:	02d64563          	blt	a2,a3,ffffffffc0203cce <vprintfmt+0x274>
ffffffffc0203ca8:	00002797          	auipc	a5,0x2
ffffffffc0203cac:	d3878793          	addi	a5,a5,-712 # ffffffffc02059e0 <error_string>
ffffffffc0203cb0:	00369713          	slli	a4,a3,0x3
ffffffffc0203cb4:	97ba                	add	a5,a5,a4
ffffffffc0203cb6:	639c                	ld	a5,0(a5)
ffffffffc0203cb8:	cb99                	beqz	a5,ffffffffc0203cce <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203cba:	86be                	mv	a3,a5
ffffffffc0203cbc:	00000617          	auipc	a2,0x0
ffffffffc0203cc0:	23460613          	addi	a2,a2,564 # ffffffffc0203ef0 <etext+0x2e>
ffffffffc0203cc4:	85ca                	mv	a1,s2
ffffffffc0203cc6:	8526                	mv	a0,s1
ffffffffc0203cc8:	0d8000ef          	jal	ffffffffc0203da0 <printfmt>
ffffffffc0203ccc:	b3c9                	j	ffffffffc0203a8e <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203cce:	00002617          	auipc	a2,0x2
ffffffffc0203cd2:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0205708 <etext+0x1846>
ffffffffc0203cd6:	85ca                	mv	a1,s2
ffffffffc0203cd8:	8526                	mv	a0,s1
ffffffffc0203cda:	0c6000ef          	jal	ffffffffc0203da0 <printfmt>
ffffffffc0203cde:	bb45                	j	ffffffffc0203a8e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203ce0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203ce2:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203ce6:	00f74363          	blt	a4,a5,ffffffffc0203cec <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0203cea:	cf81                	beqz	a5,ffffffffc0203d02 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0203cec:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203cf0:	02044b63          	bltz	s0,ffffffffc0203d26 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0203cf4:	8622                	mv	a2,s0
ffffffffc0203cf6:	8a5e                	mv	s4,s7
ffffffffc0203cf8:	46a9                	li	a3,10
ffffffffc0203cfa:	b541                	j	ffffffffc0203b7a <vprintfmt+0x120>
            lflag ++;
ffffffffc0203cfc:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cfe:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203d00:	bb5d                	j	ffffffffc0203ab6 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0203d02:	000a2403          	lw	s0,0(s4)
ffffffffc0203d06:	b7ed                	j	ffffffffc0203cf0 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0203d08:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d0c:	46a1                	li	a3,8
ffffffffc0203d0e:	8a2e                	mv	s4,a1
ffffffffc0203d10:	b5ad                	j	ffffffffc0203b7a <vprintfmt+0x120>
ffffffffc0203d12:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d16:	46a9                	li	a3,10
ffffffffc0203d18:	8a2e                	mv	s4,a1
ffffffffc0203d1a:	b585                	j	ffffffffc0203b7a <vprintfmt+0x120>
ffffffffc0203d1c:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d20:	46c1                	li	a3,16
ffffffffc0203d22:	8a2e                	mv	s4,a1
ffffffffc0203d24:	bd99                	j	ffffffffc0203b7a <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0203d26:	85ca                	mv	a1,s2
ffffffffc0203d28:	02d00513          	li	a0,45
ffffffffc0203d2c:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0203d2e:	40800633          	neg	a2,s0
ffffffffc0203d32:	8a5e                	mv	s4,s7
ffffffffc0203d34:	46a9                	li	a3,10
ffffffffc0203d36:	b591                	j	ffffffffc0203b7a <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0203d38:	e329                	bnez	a4,ffffffffc0203d7a <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d3a:	02800793          	li	a5,40
ffffffffc0203d3e:	853e                	mv	a0,a5
ffffffffc0203d40:	00002d97          	auipc	s11,0x2
ffffffffc0203d44:	9c1d8d93          	addi	s11,s11,-1599 # ffffffffc0205701 <etext+0x183f>
ffffffffc0203d48:	b5f5                	j	ffffffffc0203c34 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d4a:	85e6                	mv	a1,s9
ffffffffc0203d4c:	856e                	mv	a0,s11
ffffffffc0203d4e:	08a000ef          	jal	ffffffffc0203dd8 <strnlen>
ffffffffc0203d52:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0203d56:	01a05863          	blez	s10,ffffffffc0203d66 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0203d5a:	85ca                	mv	a1,s2
ffffffffc0203d5c:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d5e:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0203d60:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d62:	fe0d1ce3          	bnez	s10,ffffffffc0203d5a <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d66:	000dc783          	lbu	a5,0(s11)
ffffffffc0203d6a:	0007851b          	sext.w	a0,a5
ffffffffc0203d6e:	ec0792e3          	bnez	a5,ffffffffc0203c32 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203d72:	6a22                	ld	s4,8(sp)
ffffffffc0203d74:	bb29                	j	ffffffffc0203a8e <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d76:	8462                	mv	s0,s8
ffffffffc0203d78:	bbd9                	j	ffffffffc0203b4e <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d7a:	85e6                	mv	a1,s9
ffffffffc0203d7c:	00002517          	auipc	a0,0x2
ffffffffc0203d80:	98450513          	addi	a0,a0,-1660 # ffffffffc0205700 <etext+0x183e>
ffffffffc0203d84:	054000ef          	jal	ffffffffc0203dd8 <strnlen>
ffffffffc0203d88:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d8c:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0203d90:	00002d97          	auipc	s11,0x2
ffffffffc0203d94:	970d8d93          	addi	s11,s11,-1680 # ffffffffc0205700 <etext+0x183e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d98:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d9a:	fda040e3          	bgtz	s10,ffffffffc0203d5a <vprintfmt+0x300>
ffffffffc0203d9e:	bd51                	j	ffffffffc0203c32 <vprintfmt+0x1d8>

ffffffffc0203da0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203da0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203da2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203da6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203da8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203daa:	ec06                	sd	ra,24(sp)
ffffffffc0203dac:	f83a                	sd	a4,48(sp)
ffffffffc0203dae:	fc3e                	sd	a5,56(sp)
ffffffffc0203db0:	e0c2                	sd	a6,64(sp)
ffffffffc0203db2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203db4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203db6:	ca5ff0ef          	jal	ffffffffc0203a5a <vprintfmt>
}
ffffffffc0203dba:	60e2                	ld	ra,24(sp)
ffffffffc0203dbc:	6161                	addi	sp,sp,80
ffffffffc0203dbe:	8082                	ret

ffffffffc0203dc0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203dc0:	00054783          	lbu	a5,0(a0)
ffffffffc0203dc4:	cb81                	beqz	a5,ffffffffc0203dd4 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0203dc6:	4781                	li	a5,0
        cnt ++;
ffffffffc0203dc8:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203dca:	00f50733          	add	a4,a0,a5
ffffffffc0203dce:	00074703          	lbu	a4,0(a4)
ffffffffc0203dd2:	fb7d                	bnez	a4,ffffffffc0203dc8 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203dd4:	853e                	mv	a0,a5
ffffffffc0203dd6:	8082                	ret

ffffffffc0203dd8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203dd8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dda:	e589                	bnez	a1,ffffffffc0203de4 <strnlen+0xc>
ffffffffc0203ddc:	a811                	j	ffffffffc0203df0 <strnlen+0x18>
        cnt ++;
ffffffffc0203dde:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203de0:	00f58863          	beq	a1,a5,ffffffffc0203df0 <strnlen+0x18>
ffffffffc0203de4:	00f50733          	add	a4,a0,a5
ffffffffc0203de8:	00074703          	lbu	a4,0(a4)
ffffffffc0203dec:	fb6d                	bnez	a4,ffffffffc0203dde <strnlen+0x6>
ffffffffc0203dee:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203df0:	852e                	mv	a0,a1
ffffffffc0203df2:	8082                	ret

ffffffffc0203df4 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203df4:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203df6:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dfa:	0585                	addi	a1,a1,1
ffffffffc0203dfc:	0785                	addi	a5,a5,1
ffffffffc0203dfe:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e02:	fb75                	bnez	a4,ffffffffc0203df6 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e04:	8082                	ret

ffffffffc0203e06 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e06:	00054783          	lbu	a5,0(a0)
ffffffffc0203e0a:	e791                	bnez	a5,ffffffffc0203e16 <strcmp+0x10>
ffffffffc0203e0c:	a01d                	j	ffffffffc0203e32 <strcmp+0x2c>
ffffffffc0203e0e:	00054783          	lbu	a5,0(a0)
ffffffffc0203e12:	cb99                	beqz	a5,ffffffffc0203e28 <strcmp+0x22>
ffffffffc0203e14:	0585                	addi	a1,a1,1
ffffffffc0203e16:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0203e1a:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e1c:	fef709e3          	beq	a4,a5,ffffffffc0203e0e <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e20:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e24:	9d19                	subw	a0,a0,a4
ffffffffc0203e26:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e28:	0015c703          	lbu	a4,1(a1)
ffffffffc0203e2c:	4501                	li	a0,0
}
ffffffffc0203e2e:	9d19                	subw	a0,a0,a4
ffffffffc0203e30:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e32:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e36:	4501                	li	a0,0
ffffffffc0203e38:	b7f5                	j	ffffffffc0203e24 <strcmp+0x1e>

ffffffffc0203e3a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e3a:	ce01                	beqz	a2,ffffffffc0203e52 <strncmp+0x18>
ffffffffc0203e3c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e40:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e42:	cb91                	beqz	a5,ffffffffc0203e56 <strncmp+0x1c>
ffffffffc0203e44:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e48:	00f71763          	bne	a4,a5,ffffffffc0203e56 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0203e4c:	0505                	addi	a0,a0,1
ffffffffc0203e4e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e50:	f675                	bnez	a2,ffffffffc0203e3c <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e52:	4501                	li	a0,0
ffffffffc0203e54:	8082                	ret
ffffffffc0203e56:	00054503          	lbu	a0,0(a0)
ffffffffc0203e5a:	0005c783          	lbu	a5,0(a1)
ffffffffc0203e5e:	9d1d                	subw	a0,a0,a5
}
ffffffffc0203e60:	8082                	ret

ffffffffc0203e62 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e62:	a021                	j	ffffffffc0203e6a <strchr+0x8>
        if (*s == c) {
ffffffffc0203e64:	00f58763          	beq	a1,a5,ffffffffc0203e72 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0203e68:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e6a:	00054783          	lbu	a5,0(a0)
ffffffffc0203e6e:	fbfd                	bnez	a5,ffffffffc0203e64 <strchr+0x2>
    }
    return NULL;
ffffffffc0203e70:	4501                	li	a0,0
}
ffffffffc0203e72:	8082                	ret

ffffffffc0203e74 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e74:	ca01                	beqz	a2,ffffffffc0203e84 <memset+0x10>
ffffffffc0203e76:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e78:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e7a:	0785                	addi	a5,a5,1
ffffffffc0203e7c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e80:	fef61de3          	bne	a2,a5,ffffffffc0203e7a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e84:	8082                	ret

ffffffffc0203e86 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e86:	ca19                	beqz	a2,ffffffffc0203e9c <memcpy+0x16>
ffffffffc0203e88:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e8a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e8c:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e90:	0585                	addi	a1,a1,1
ffffffffc0203e92:	0785                	addi	a5,a5,1
ffffffffc0203e94:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e98:	feb61ae3          	bne	a2,a1,ffffffffc0203e8c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e9c:	8082                	ret

ffffffffc0203e9e <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e9e:	c205                	beqz	a2,ffffffffc0203ebe <memcmp+0x20>
ffffffffc0203ea0:	962a                	add	a2,a2,a0
ffffffffc0203ea2:	a019                	j	ffffffffc0203ea8 <memcmp+0xa>
ffffffffc0203ea4:	00c50d63          	beq	a0,a2,ffffffffc0203ebe <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203ea8:	00054783          	lbu	a5,0(a0)
ffffffffc0203eac:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203eb0:	0505                	addi	a0,a0,1
ffffffffc0203eb2:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203eb4:	fee788e3          	beq	a5,a4,ffffffffc0203ea4 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203eb8:	40e7853b          	subw	a0,a5,a4
ffffffffc0203ebc:	8082                	ret
    }
    return 0;
ffffffffc0203ebe:	4501                	li	a0,0
}
ffffffffc0203ec0:	8082                	ret
