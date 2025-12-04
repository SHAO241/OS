
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
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	6cc50513          	addi	a0,a0,1740 # ffffffffc0201718 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	6d650513          	addi	a0,a0,1750 # ffffffffc0201738 <etext+0x22>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	6a858593          	addi	a1,a1,1704 # ffffffffc0201716 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	6e250513          	addi	a0,a0,1762 # ffffffffc0201758 <etext+0x42>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201778 <etext+0x62>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0206078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	6fa50513          	addi	a0,a0,1786 # ffffffffc0201798 <etext+0x82>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0206477 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	6ee50513          	addi	a0,a0,1774 # ffffffffc02017b8 <etext+0xa2>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <free_area>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	616010ef          	jal	ffffffffc0201704 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	e2650513          	addi	a0,a0,-474 # ffffffffc0201f20 <etext+0x80a>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	7b1000ef          	jal	ffffffffc02010ba <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	1b8010ef          	jal	ffffffffc02012f4 <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	184010ef          	jal	ffffffffc02012f4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00006317          	auipc	t1,0x6
ffffffffc02001cc:	e6832303          	lw	t1,-408(t1) # ffffffffc0206030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	5f850513          	addi	a0,a0,1528 # ffffffffc02017e8 <etext+0xd2>
    is_panic = 1;
ffffffffc02001f8:	00006697          	auipc	a3,0x6
ffffffffc02001fc:	e2e6ac23          	sw	a4,-456(a3) # ffffffffc0206030 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	5fa50513          	addi	a0,a0,1530 # ffffffffc0201808 <etext+0xf2>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	4360106f          	j	ffffffffc020165a <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	5e650513          	addi	a0,a0,1510 # ffffffffc0201810 <etext+0xfa>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	5de50513          	addi	a0,a0,1502 # ffffffffc0201820 <etext+0x10a>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00006417          	auipc	s0,0x6
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	5d850513          	addi	a0,a0,1496 # ffffffffc0201830 <etext+0x11a>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	5e250513          	addi	a0,a0,1506 # ffffffffc0201848 <etext+0x132>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9e75>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	5b850513          	addi	a0,a0,1464 # ffffffffc0201910 <etext+0x1fa>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	5e050513          	addi	a0,a0,1504 # ffffffffc0201948 <etext+0x232>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	4ec50513          	addi	a0,a0,1260 # ffffffffc0201868 <etext+0x152>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	2b2010ef          	jal	ffffffffc0201674 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	4c458593          	addi	a1,a1,1220 # ffffffffc0201890 <etext+0x17a>
ffffffffc02003d4:	308010ef          	jal	ffffffffc02016dc <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	4a058593          	addi	a1,a1,1184 # ffffffffc0201898 <etext+0x182>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	27a010ef          	jal	ffffffffc02016a8 <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	45250513          	addi	a0,a0,1106 # ffffffffc02018a0 <etext+0x18a>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	3a850513          	addi	a0,a0,936 # ffffffffc02018c0 <etext+0x1aa>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	3ae50513          	addi	a0,a0,942 # ffffffffc02018d8 <etext+0x1c2>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	3bc50513          	addi	a0,a0,956 # ffffffffc02018f8 <etext+0x1e2>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00006797          	auipc	a5,0x6
ffffffffc020054c:	ae97bc23          	sd	s1,-1288(a5) # ffffffffc0206040 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00006797          	auipc	a5,0x6
ffffffffc0200554:	ae87b423          	sd	s0,-1304(a5) # ffffffffc0206038 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00006517          	auipc	a0,0x6
ffffffffc020055e:	ae653503          	ld	a0,-1306(a0) # ffffffffc0206040 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00006517          	auipc	a0,0x6
ffffffffc0200568:	ad453503          	ld	a0,-1324(a0) # ffffffffc0206038 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020056e:	00006797          	auipc	a5,0x6
ffffffffc0200572:	aaa78793          	addi	a5,a5,-1366 # ffffffffc0206018 <free_area>
ffffffffc0200576:	e79c                	sd	a5,8(a5)
ffffffffc0200578:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020057a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020057e:	8082                	ret

ffffffffc0200580 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200580:	00006517          	auipc	a0,0x6
ffffffffc0200584:	aa856503          	lwu	a0,-1368(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200588:	8082                	ret

ffffffffc020058a <default_alloc_pages>:
    assert(n > 0);
ffffffffc020058a:	cd41                	beqz	a0,ffffffffc0200622 <default_alloc_pages+0x98>
    if (n > nr_free) {
ffffffffc020058c:	00006597          	auipc	a1,0x6
ffffffffc0200590:	a9c5a583          	lw	a1,-1380(a1) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200594:	86aa                	mv	a3,a0
ffffffffc0200596:	02059793          	slli	a5,a1,0x20
ffffffffc020059a:	9381                	srli	a5,a5,0x20
ffffffffc020059c:	00a7ef63          	bltu	a5,a0,ffffffffc02005ba <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02005a0:	00006617          	auipc	a2,0x6
ffffffffc02005a4:	a7860613          	addi	a2,a2,-1416 # ffffffffc0206018 <free_area>
ffffffffc02005a8:	87b2                	mv	a5,a2
ffffffffc02005aa:	a029                	j	ffffffffc02005b4 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc02005ac:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02005b0:	00d77763          	bgeu	a4,a3,ffffffffc02005be <default_alloc_pages+0x34>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005b4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005b6:	fec79be3          	bne	a5,a2,ffffffffc02005ac <default_alloc_pages+0x22>
        return NULL;
ffffffffc02005ba:	4501                	li	a0,0
}
ffffffffc02005bc:	8082                	ret
        if (page->property > n) {
ffffffffc02005be:	ff87a303          	lw	t1,-8(a5)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005c2:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02005c6:	0087b883          	ld	a7,8(a5)
ffffffffc02005ca:	02031713          	slli	a4,t1,0x20
ffffffffc02005ce:	9301                	srli	a4,a4,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02005d0:	01183423          	sd	a7,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc02005d4:	0108b023          	sd	a6,0(a7)
        struct Page *p = le2page(le, page_link);
ffffffffc02005d8:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02005dc:	02e6fb63          	bgeu	a3,a4,ffffffffc0200612 <default_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc02005e0:	00269713          	slli	a4,a3,0x2
ffffffffc02005e4:	9736                	add	a4,a4,a3
ffffffffc02005e6:	070e                	slli	a4,a4,0x3
ffffffffc02005e8:	972a                	add	a4,a4,a0
            SetPageProperty(p);
ffffffffc02005ea:	00873e03          	ld	t3,8(a4)
            p->property = page->property - n;
ffffffffc02005ee:	40d3033b          	subw	t1,t1,a3
ffffffffc02005f2:	00672823          	sw	t1,16(a4)
            SetPageProperty(p);
ffffffffc02005f6:	002e6313          	ori	t1,t3,2
ffffffffc02005fa:	00673423          	sd	t1,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc02005fe:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0200602:	0068b023          	sd	t1,0(a7)
ffffffffc0200606:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020060a:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020060e:	01073c23          	sd	a6,24(a4)
        ClearPageProperty(page);
ffffffffc0200612:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc0200616:	9d95                	subw	a1,a1,a3
ffffffffc0200618:	ca0c                	sw	a1,16(a2)
        ClearPageProperty(page);
ffffffffc020061a:	9b75                	andi	a4,a4,-3
ffffffffc020061c:	fee7b823          	sd	a4,-16(a5)
ffffffffc0200620:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0200622:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200624:	00001697          	auipc	a3,0x1
ffffffffc0200628:	33c68693          	addi	a3,a3,828 # ffffffffc0201960 <etext+0x24a>
ffffffffc020062c:	00001617          	auipc	a2,0x1
ffffffffc0200630:	33c60613          	addi	a2,a2,828 # ffffffffc0201968 <etext+0x252>
ffffffffc0200634:	06200593          	li	a1,98
ffffffffc0200638:	00001517          	auipc	a0,0x1
ffffffffc020063c:	34850513          	addi	a0,a0,840 # ffffffffc0201980 <etext+0x26a>
default_alloc_pages(size_t n) {
ffffffffc0200640:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200642:	b87ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200646 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200646:	711d                	addi	sp,sp,-96
ffffffffc0200648:	e0ca                	sd	s2,64(sp)
    return listelm->next;
ffffffffc020064a:	00006917          	auipc	s2,0x6
ffffffffc020064e:	9ce90913          	addi	s2,s2,-1586 # ffffffffc0206018 <free_area>
ffffffffc0200652:	00893783          	ld	a5,8(s2)
ffffffffc0200656:	ec86                	sd	ra,88(sp)
ffffffffc0200658:	e8a2                	sd	s0,80(sp)
ffffffffc020065a:	e4a6                	sd	s1,72(sp)
ffffffffc020065c:	fc4e                	sd	s3,56(sp)
ffffffffc020065e:	f852                	sd	s4,48(sp)
ffffffffc0200660:	f456                	sd	s5,40(sp)
ffffffffc0200662:	f05a                	sd	s6,32(sp)
ffffffffc0200664:	ec5e                	sd	s7,24(sp)
ffffffffc0200666:	e862                	sd	s8,16(sp)
ffffffffc0200668:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020066a:	31278763          	beq	a5,s2,ffffffffc0200978 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc020066e:	4401                	li	s0,0
ffffffffc0200670:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200672:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200676:	8b09                	andi	a4,a4,2
ffffffffc0200678:	30070463          	beqz	a4,ffffffffc0200980 <default_check+0x33a>
        count ++, total += p->property;
ffffffffc020067c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200680:	679c                	ld	a5,8(a5)
ffffffffc0200682:	2485                	addiw	s1,s1,1
ffffffffc0200684:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200686:	ff2796e3          	bne	a5,s2,ffffffffc0200672 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc020068a:	89a2                	mv	s3,s0
ffffffffc020068c:	223000ef          	jal	ffffffffc02010ae <nr_free_pages>
ffffffffc0200690:	75351863          	bne	a0,s3,ffffffffc0200de0 <default_check+0x79a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200694:	4505                	li	a0,1
ffffffffc0200696:	201000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc020069a:	8aaa                	mv	s5,a0
ffffffffc020069c:	48050263          	beqz	a0,ffffffffc0200b20 <default_check+0x4da>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006a0:	4505                	li	a0,1
ffffffffc02006a2:	1f5000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02006a6:	89aa                	mv	s3,a0
ffffffffc02006a8:	74050c63          	beqz	a0,ffffffffc0200e00 <default_check+0x7ba>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006ac:	4505                	li	a0,1
ffffffffc02006ae:	1e9000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02006b2:	8a2a                	mv	s4,a0
ffffffffc02006b4:	4e050663          	beqz	a0,ffffffffc0200ba0 <default_check+0x55a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006b8:	40aa87b3          	sub	a5,s5,a0
ffffffffc02006bc:	40a98733          	sub	a4,s3,a0
ffffffffc02006c0:	0017b793          	seqz	a5,a5
ffffffffc02006c4:	00173713          	seqz	a4,a4
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
ffffffffc02006ca:	32079b63          	bnez	a5,ffffffffc0200a00 <default_check+0x3ba>
ffffffffc02006ce:	333a8963          	beq	s5,s3,ffffffffc0200a00 <default_check+0x3ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02006d2:	000aa783          	lw	a5,0(s5)
ffffffffc02006d6:	2c079563          	bnez	a5,ffffffffc02009a0 <default_check+0x35a>
ffffffffc02006da:	0009a783          	lw	a5,0(s3)
ffffffffc02006de:	2c079163          	bnez	a5,ffffffffc02009a0 <default_check+0x35a>
ffffffffc02006e2:	411c                	lw	a5,0(a0)
ffffffffc02006e4:	2a079e63          	bnez	a5,ffffffffc02009a0 <default_check+0x35a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02006e8:	00006797          	auipc	a5,0x6
ffffffffc02006ec:	9887b783          	ld	a5,-1656(a5) # ffffffffc0206070 <pages>
ffffffffc02006f0:	ccccd737          	lui	a4,0xccccd
ffffffffc02006f4:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc02006f8:	02071693          	slli	a3,a4,0x20
ffffffffc02006fc:	96ba                	add	a3,a3,a4
ffffffffc02006fe:	40fa8733          	sub	a4,s5,a5
ffffffffc0200702:	870d                	srai	a4,a4,0x3
ffffffffc0200704:	02d70733          	mul	a4,a4,a3
ffffffffc0200708:	00002517          	auipc	a0,0x2
ffffffffc020070c:	a0053503          	ld	a0,-1536(a0) # ffffffffc0202108 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200710:	00006697          	auipc	a3,0x6
ffffffffc0200714:	9586b683          	ld	a3,-1704(a3) # ffffffffc0206068 <npage>
ffffffffc0200718:	06b2                	slli	a3,a3,0xc
ffffffffc020071a:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc020071c:	0732                	slli	a4,a4,0xc
ffffffffc020071e:	2cd77163          	bgeu	a4,a3,ffffffffc02009e0 <default_check+0x39a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200722:	ccccd5b7          	lui	a1,0xccccd
ffffffffc0200726:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc020072a:	02059613          	slli	a2,a1,0x20
ffffffffc020072e:	40f98733          	sub	a4,s3,a5
ffffffffc0200732:	962e                	add	a2,a2,a1
ffffffffc0200734:	870d                	srai	a4,a4,0x3
ffffffffc0200736:	02c70733          	mul	a4,a4,a2
ffffffffc020073a:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020073c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020073e:	4ed77163          	bgeu	a4,a3,ffffffffc0200c20 <default_check+0x5da>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200742:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200746:	878d                	srai	a5,a5,0x3
ffffffffc0200748:	02c787b3          	mul	a5,a5,a2
ffffffffc020074c:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020074e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200750:	32d7f863          	bgeu	a5,a3,ffffffffc0200a80 <default_check+0x43a>
    assert(alloc_page() == NULL);
ffffffffc0200754:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200756:	00093c03          	ld	s8,0(s2)
ffffffffc020075a:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc020075e:	00006b17          	auipc	s6,0x6
ffffffffc0200762:	8cab2b03          	lw	s6,-1846(s6) # ffffffffc0206028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200766:	01293023          	sd	s2,0(s2)
ffffffffc020076a:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc020076e:	00006797          	auipc	a5,0x6
ffffffffc0200772:	8a07ad23          	sw	zero,-1862(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200776:	121000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc020077a:	2e051363          	bnez	a0,ffffffffc0200a60 <default_check+0x41a>
    free_page(p0);
ffffffffc020077e:	8556                	mv	a0,s5
ffffffffc0200780:	4585                	li	a1,1
ffffffffc0200782:	121000ef          	jal	ffffffffc02010a2 <free_pages>
    free_page(p1);
ffffffffc0200786:	854e                	mv	a0,s3
ffffffffc0200788:	4585                	li	a1,1
ffffffffc020078a:	119000ef          	jal	ffffffffc02010a2 <free_pages>
    free_page(p2);
ffffffffc020078e:	8552                	mv	a0,s4
ffffffffc0200790:	4585                	li	a1,1
ffffffffc0200792:	111000ef          	jal	ffffffffc02010a2 <free_pages>
    assert(nr_free == 3);
ffffffffc0200796:	00006717          	auipc	a4,0x6
ffffffffc020079a:	89272703          	lw	a4,-1902(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc020079e:	478d                	li	a5,3
ffffffffc02007a0:	2af71063          	bne	a4,a5,ffffffffc0200a40 <default_check+0x3fa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007a4:	4505                	li	a0,1
ffffffffc02007a6:	0f1000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02007aa:	89aa                	mv	s3,a0
ffffffffc02007ac:	26050a63          	beqz	a0,ffffffffc0200a20 <default_check+0x3da>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007b0:	4505                	li	a0,1
ffffffffc02007b2:	0e5000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02007b6:	8aaa                	mv	s5,a0
ffffffffc02007b8:	3c050463          	beqz	a0,ffffffffc0200b80 <default_check+0x53a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007bc:	4505                	li	a0,1
ffffffffc02007be:	0d9000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02007c2:	8a2a                	mv	s4,a0
ffffffffc02007c4:	38050e63          	beqz	a0,ffffffffc0200b60 <default_check+0x51a>
    assert(alloc_page() == NULL);
ffffffffc02007c8:	4505                	li	a0,1
ffffffffc02007ca:	0cd000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02007ce:	36051963          	bnez	a0,ffffffffc0200b40 <default_check+0x4fa>
    free_page(p0);
ffffffffc02007d2:	4585                	li	a1,1
ffffffffc02007d4:	854e                	mv	a0,s3
ffffffffc02007d6:	0cd000ef          	jal	ffffffffc02010a2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02007da:	00893783          	ld	a5,8(s2)
ffffffffc02007de:	1f278163          	beq	a5,s2,ffffffffc02009c0 <default_check+0x37a>
    assert((p = alloc_page()) == p0);
ffffffffc02007e2:	4505                	li	a0,1
ffffffffc02007e4:	0b3000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02007e8:	8caa                	mv	s9,a0
ffffffffc02007ea:	30a99b63          	bne	s3,a0,ffffffffc0200b00 <default_check+0x4ba>
    assert(alloc_page() == NULL);
ffffffffc02007ee:	4505                	li	a0,1
ffffffffc02007f0:	0a7000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02007f4:	2e051663          	bnez	a0,ffffffffc0200ae0 <default_check+0x49a>
    assert(nr_free == 0);
ffffffffc02007f8:	00006797          	auipc	a5,0x6
ffffffffc02007fc:	8307a783          	lw	a5,-2000(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200800:	2c079063          	bnez	a5,ffffffffc0200ac0 <default_check+0x47a>
    free_page(p);
ffffffffc0200804:	8566                	mv	a0,s9
ffffffffc0200806:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200808:	01893023          	sd	s8,0(s2)
ffffffffc020080c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200810:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200814:	08f000ef          	jal	ffffffffc02010a2 <free_pages>
    free_page(p1);
ffffffffc0200818:	8556                	mv	a0,s5
ffffffffc020081a:	4585                	li	a1,1
ffffffffc020081c:	087000ef          	jal	ffffffffc02010a2 <free_pages>
    free_page(p2);
ffffffffc0200820:	8552                	mv	a0,s4
ffffffffc0200822:	4585                	li	a1,1
ffffffffc0200824:	07f000ef          	jal	ffffffffc02010a2 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200828:	4515                	li	a0,5
ffffffffc020082a:	06d000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc020082e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200830:	26050863          	beqz	a0,ffffffffc0200aa0 <default_check+0x45a>
    assert(!PageProperty(p0));
ffffffffc0200834:	651c                	ld	a5,8(a0)
ffffffffc0200836:	8b89                	andi	a5,a5,2
ffffffffc0200838:	54079463          	bnez	a5,ffffffffc0200d80 <default_check+0x73a>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020083c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020083e:	00093b83          	ld	s7,0(s2)
ffffffffc0200842:	00893b03          	ld	s6,8(s2)
ffffffffc0200846:	01293023          	sd	s2,0(s2)
ffffffffc020084a:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc020084e:	049000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc0200852:	50051763          	bnez	a0,ffffffffc0200d60 <default_check+0x71a>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200856:	05098a13          	addi	s4,s3,80
ffffffffc020085a:	8552                	mv	a0,s4
ffffffffc020085c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020085e:	00005c17          	auipc	s8,0x5
ffffffffc0200862:	7cac2c03          	lw	s8,1994(s8) # ffffffffc0206028 <free_area+0x10>
    nr_free = 0;
ffffffffc0200866:	00005797          	auipc	a5,0x5
ffffffffc020086a:	7c07a123          	sw	zero,1986(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020086e:	035000ef          	jal	ffffffffc02010a2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200872:	4511                	li	a0,4
ffffffffc0200874:	023000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc0200878:	4c051463          	bnez	a0,ffffffffc0200d40 <default_check+0x6fa>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020087c:	0589b783          	ld	a5,88(s3)
ffffffffc0200880:	8b89                	andi	a5,a5,2
ffffffffc0200882:	48078f63          	beqz	a5,ffffffffc0200d20 <default_check+0x6da>
ffffffffc0200886:	0609a503          	lw	a0,96(s3)
ffffffffc020088a:	478d                	li	a5,3
ffffffffc020088c:	48f51a63          	bne	a0,a5,ffffffffc0200d20 <default_check+0x6da>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200890:	007000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc0200894:	8aaa                	mv	s5,a0
ffffffffc0200896:	46050563          	beqz	a0,ffffffffc0200d00 <default_check+0x6ba>
    assert(alloc_page() == NULL);
ffffffffc020089a:	4505                	li	a0,1
ffffffffc020089c:	7fa000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02008a0:	44051063          	bnez	a0,ffffffffc0200ce0 <default_check+0x69a>
    assert(p0 + 2 == p1);
ffffffffc02008a4:	415a1e63          	bne	s4,s5,ffffffffc0200cc0 <default_check+0x67a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02008a8:	4585                	li	a1,1
ffffffffc02008aa:	854e                	mv	a0,s3
ffffffffc02008ac:	7f6000ef          	jal	ffffffffc02010a2 <free_pages>
    free_pages(p1, 3);
ffffffffc02008b0:	8552                	mv	a0,s4
ffffffffc02008b2:	458d                	li	a1,3
ffffffffc02008b4:	7ee000ef          	jal	ffffffffc02010a2 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02008b8:	0089b783          	ld	a5,8(s3)
ffffffffc02008bc:	8b89                	andi	a5,a5,2
ffffffffc02008be:	3e078163          	beqz	a5,ffffffffc0200ca0 <default_check+0x65a>
ffffffffc02008c2:	0109aa83          	lw	s5,16(s3)
ffffffffc02008c6:	4785                	li	a5,1
ffffffffc02008c8:	3cfa9c63          	bne	s5,a5,ffffffffc0200ca0 <default_check+0x65a>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02008cc:	008a3783          	ld	a5,8(s4)
ffffffffc02008d0:	8b89                	andi	a5,a5,2
ffffffffc02008d2:	3a078763          	beqz	a5,ffffffffc0200c80 <default_check+0x63a>
ffffffffc02008d6:	010a2703          	lw	a4,16(s4)
ffffffffc02008da:	478d                	li	a5,3
ffffffffc02008dc:	3af71263          	bne	a4,a5,ffffffffc0200c80 <default_check+0x63a>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02008e0:	8556                	mv	a0,s5
ffffffffc02008e2:	7b4000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02008e6:	36a99d63          	bne	s3,a0,ffffffffc0200c60 <default_check+0x61a>
    free_page(p0);
ffffffffc02008ea:	85d6                	mv	a1,s5
ffffffffc02008ec:	7b6000ef          	jal	ffffffffc02010a2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02008f0:	4509                	li	a0,2
ffffffffc02008f2:	7a4000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc02008f6:	34aa1563          	bne	s4,a0,ffffffffc0200c40 <default_check+0x5fa>

    free_pages(p0, 2);
ffffffffc02008fa:	4589                	li	a1,2
ffffffffc02008fc:	7a6000ef          	jal	ffffffffc02010a2 <free_pages>
    free_page(p2);
ffffffffc0200900:	02898513          	addi	a0,s3,40
ffffffffc0200904:	85d6                	mv	a1,s5
ffffffffc0200906:	79c000ef          	jal	ffffffffc02010a2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020090a:	4515                	li	a0,5
ffffffffc020090c:	78a000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc0200910:	89aa                	mv	s3,a0
ffffffffc0200912:	48050763          	beqz	a0,ffffffffc0200da0 <default_check+0x75a>
    assert(alloc_page() == NULL);
ffffffffc0200916:	8556                	mv	a0,s5
ffffffffc0200918:	77e000ef          	jal	ffffffffc0201096 <alloc_pages>
ffffffffc020091c:	2e051263          	bnez	a0,ffffffffc0200c00 <default_check+0x5ba>

    assert(nr_free == 0);
ffffffffc0200920:	00005797          	auipc	a5,0x5
ffffffffc0200924:	7087a783          	lw	a5,1800(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200928:	2a079c63          	bnez	a5,ffffffffc0200be0 <default_check+0x59a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020092c:	854e                	mv	a0,s3
ffffffffc020092e:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200930:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200934:	01793023          	sd	s7,0(s2)
ffffffffc0200938:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc020093c:	766000ef          	jal	ffffffffc02010a2 <free_pages>
    return listelm->next;
ffffffffc0200940:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200944:	01278963          	beq	a5,s2,ffffffffc0200956 <default_check+0x310>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200948:	ff87a703          	lw	a4,-8(a5)
ffffffffc020094c:	679c                	ld	a5,8(a5)
ffffffffc020094e:	34fd                	addiw	s1,s1,-1
ffffffffc0200950:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200952:	ff279be3          	bne	a5,s2,ffffffffc0200948 <default_check+0x302>
    }
    assert(count == 0);
ffffffffc0200956:	26049563          	bnez	s1,ffffffffc0200bc0 <default_check+0x57a>
    assert(total == 0);
ffffffffc020095a:	46041363          	bnez	s0,ffffffffc0200dc0 <default_check+0x77a>
}
ffffffffc020095e:	60e6                	ld	ra,88(sp)
ffffffffc0200960:	6446                	ld	s0,80(sp)
ffffffffc0200962:	64a6                	ld	s1,72(sp)
ffffffffc0200964:	6906                	ld	s2,64(sp)
ffffffffc0200966:	79e2                	ld	s3,56(sp)
ffffffffc0200968:	7a42                	ld	s4,48(sp)
ffffffffc020096a:	7aa2                	ld	s5,40(sp)
ffffffffc020096c:	7b02                	ld	s6,32(sp)
ffffffffc020096e:	6be2                	ld	s7,24(sp)
ffffffffc0200970:	6c42                	ld	s8,16(sp)
ffffffffc0200972:	6ca2                	ld	s9,8(sp)
ffffffffc0200974:	6125                	addi	sp,sp,96
ffffffffc0200976:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200978:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020097a:	4401                	li	s0,0
ffffffffc020097c:	4481                	li	s1,0
ffffffffc020097e:	b339                	j	ffffffffc020068c <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0200980:	00001697          	auipc	a3,0x1
ffffffffc0200984:	01868693          	addi	a3,a3,24 # ffffffffc0201998 <etext+0x282>
ffffffffc0200988:	00001617          	auipc	a2,0x1
ffffffffc020098c:	fe060613          	addi	a2,a2,-32 # ffffffffc0201968 <etext+0x252>
ffffffffc0200990:	0f000593          	li	a1,240
ffffffffc0200994:	00001517          	auipc	a0,0x1
ffffffffc0200998:	fec50513          	addi	a0,a0,-20 # ffffffffc0201980 <etext+0x26a>
ffffffffc020099c:	82dff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02009a0:	00001697          	auipc	a3,0x1
ffffffffc02009a4:	0b068693          	addi	a3,a3,176 # ffffffffc0201a50 <etext+0x33a>
ffffffffc02009a8:	00001617          	auipc	a2,0x1
ffffffffc02009ac:	fc060613          	addi	a2,a2,-64 # ffffffffc0201968 <etext+0x252>
ffffffffc02009b0:	0be00593          	li	a1,190
ffffffffc02009b4:	00001517          	auipc	a0,0x1
ffffffffc02009b8:	fcc50513          	addi	a0,a0,-52 # ffffffffc0201980 <etext+0x26a>
ffffffffc02009bc:	80dff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009c0:	00001697          	auipc	a3,0x1
ffffffffc02009c4:	15868693          	addi	a3,a3,344 # ffffffffc0201b18 <etext+0x402>
ffffffffc02009c8:	00001617          	auipc	a2,0x1
ffffffffc02009cc:	fa060613          	addi	a2,a2,-96 # ffffffffc0201968 <etext+0x252>
ffffffffc02009d0:	0d900593          	li	a1,217
ffffffffc02009d4:	00001517          	auipc	a0,0x1
ffffffffc02009d8:	fac50513          	addi	a0,a0,-84 # ffffffffc0201980 <etext+0x26a>
ffffffffc02009dc:	fecff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009e0:	00001697          	auipc	a3,0x1
ffffffffc02009e4:	0b068693          	addi	a3,a3,176 # ffffffffc0201a90 <etext+0x37a>
ffffffffc02009e8:	00001617          	auipc	a2,0x1
ffffffffc02009ec:	f8060613          	addi	a2,a2,-128 # ffffffffc0201968 <etext+0x252>
ffffffffc02009f0:	0c000593          	li	a1,192
ffffffffc02009f4:	00001517          	auipc	a0,0x1
ffffffffc02009f8:	f8c50513          	addi	a0,a0,-116 # ffffffffc0201980 <etext+0x26a>
ffffffffc02009fc:	fccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200a00:	00001697          	auipc	a3,0x1
ffffffffc0200a04:	02868693          	addi	a3,a3,40 # ffffffffc0201a28 <etext+0x312>
ffffffffc0200a08:	00001617          	auipc	a2,0x1
ffffffffc0200a0c:	f6060613          	addi	a2,a2,-160 # ffffffffc0201968 <etext+0x252>
ffffffffc0200a10:	0bd00593          	li	a1,189
ffffffffc0200a14:	00001517          	auipc	a0,0x1
ffffffffc0200a18:	f6c50513          	addi	a0,a0,-148 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200a1c:	facff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a20:	00001697          	auipc	a3,0x1
ffffffffc0200a24:	fa868693          	addi	a3,a3,-88 # ffffffffc02019c8 <etext+0x2b2>
ffffffffc0200a28:	00001617          	auipc	a2,0x1
ffffffffc0200a2c:	f4060613          	addi	a2,a2,-192 # ffffffffc0201968 <etext+0x252>
ffffffffc0200a30:	0d200593          	li	a1,210
ffffffffc0200a34:	00001517          	auipc	a0,0x1
ffffffffc0200a38:	f4c50513          	addi	a0,a0,-180 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200a3c:	f8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc0200a40:	00001697          	auipc	a3,0x1
ffffffffc0200a44:	0c868693          	addi	a3,a3,200 # ffffffffc0201b08 <etext+0x3f2>
ffffffffc0200a48:	00001617          	auipc	a2,0x1
ffffffffc0200a4c:	f2060613          	addi	a2,a2,-224 # ffffffffc0201968 <etext+0x252>
ffffffffc0200a50:	0d000593          	li	a1,208
ffffffffc0200a54:	00001517          	auipc	a0,0x1
ffffffffc0200a58:	f2c50513          	addi	a0,a0,-212 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200a5c:	f6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a60:	00001697          	auipc	a3,0x1
ffffffffc0200a64:	09068693          	addi	a3,a3,144 # ffffffffc0201af0 <etext+0x3da>
ffffffffc0200a68:	00001617          	auipc	a2,0x1
ffffffffc0200a6c:	f0060613          	addi	a2,a2,-256 # ffffffffc0201968 <etext+0x252>
ffffffffc0200a70:	0cb00593          	li	a1,203
ffffffffc0200a74:	00001517          	auipc	a0,0x1
ffffffffc0200a78:	f0c50513          	addi	a0,a0,-244 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200a7c:	f4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a80:	00001697          	auipc	a3,0x1
ffffffffc0200a84:	05068693          	addi	a3,a3,80 # ffffffffc0201ad0 <etext+0x3ba>
ffffffffc0200a88:	00001617          	auipc	a2,0x1
ffffffffc0200a8c:	ee060613          	addi	a2,a2,-288 # ffffffffc0201968 <etext+0x252>
ffffffffc0200a90:	0c200593          	li	a1,194
ffffffffc0200a94:	00001517          	auipc	a0,0x1
ffffffffc0200a98:	eec50513          	addi	a0,a0,-276 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200a9c:	f2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0200aa0:	00001697          	auipc	a3,0x1
ffffffffc0200aa4:	0c068693          	addi	a3,a3,192 # ffffffffc0201b60 <etext+0x44a>
ffffffffc0200aa8:	00001617          	auipc	a2,0x1
ffffffffc0200aac:	ec060613          	addi	a2,a2,-320 # ffffffffc0201968 <etext+0x252>
ffffffffc0200ab0:	0f800593          	li	a1,248
ffffffffc0200ab4:	00001517          	auipc	a0,0x1
ffffffffc0200ab8:	ecc50513          	addi	a0,a0,-308 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200abc:	f0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200ac0:	00001697          	auipc	a3,0x1
ffffffffc0200ac4:	09068693          	addi	a3,a3,144 # ffffffffc0201b50 <etext+0x43a>
ffffffffc0200ac8:	00001617          	auipc	a2,0x1
ffffffffc0200acc:	ea060613          	addi	a2,a2,-352 # ffffffffc0201968 <etext+0x252>
ffffffffc0200ad0:	0df00593          	li	a1,223
ffffffffc0200ad4:	00001517          	auipc	a0,0x1
ffffffffc0200ad8:	eac50513          	addi	a0,a0,-340 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200adc:	eecff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ae0:	00001697          	auipc	a3,0x1
ffffffffc0200ae4:	01068693          	addi	a3,a3,16 # ffffffffc0201af0 <etext+0x3da>
ffffffffc0200ae8:	00001617          	auipc	a2,0x1
ffffffffc0200aec:	e8060613          	addi	a2,a2,-384 # ffffffffc0201968 <etext+0x252>
ffffffffc0200af0:	0dd00593          	li	a1,221
ffffffffc0200af4:	00001517          	auipc	a0,0x1
ffffffffc0200af8:	e8c50513          	addi	a0,a0,-372 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200afc:	eccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200b00:	00001697          	auipc	a3,0x1
ffffffffc0200b04:	03068693          	addi	a3,a3,48 # ffffffffc0201b30 <etext+0x41a>
ffffffffc0200b08:	00001617          	auipc	a2,0x1
ffffffffc0200b0c:	e6060613          	addi	a2,a2,-416 # ffffffffc0201968 <etext+0x252>
ffffffffc0200b10:	0dc00593          	li	a1,220
ffffffffc0200b14:	00001517          	auipc	a0,0x1
ffffffffc0200b18:	e6c50513          	addi	a0,a0,-404 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200b1c:	eacff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b20:	00001697          	auipc	a3,0x1
ffffffffc0200b24:	ea868693          	addi	a3,a3,-344 # ffffffffc02019c8 <etext+0x2b2>
ffffffffc0200b28:	00001617          	auipc	a2,0x1
ffffffffc0200b2c:	e4060613          	addi	a2,a2,-448 # ffffffffc0201968 <etext+0x252>
ffffffffc0200b30:	0b900593          	li	a1,185
ffffffffc0200b34:	00001517          	auipc	a0,0x1
ffffffffc0200b38:	e4c50513          	addi	a0,a0,-436 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200b3c:	e8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b40:	00001697          	auipc	a3,0x1
ffffffffc0200b44:	fb068693          	addi	a3,a3,-80 # ffffffffc0201af0 <etext+0x3da>
ffffffffc0200b48:	00001617          	auipc	a2,0x1
ffffffffc0200b4c:	e2060613          	addi	a2,a2,-480 # ffffffffc0201968 <etext+0x252>
ffffffffc0200b50:	0d600593          	li	a1,214
ffffffffc0200b54:	00001517          	auipc	a0,0x1
ffffffffc0200b58:	e2c50513          	addi	a0,a0,-468 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200b5c:	e6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b60:	00001697          	auipc	a3,0x1
ffffffffc0200b64:	ea868693          	addi	a3,a3,-344 # ffffffffc0201a08 <etext+0x2f2>
ffffffffc0200b68:	00001617          	auipc	a2,0x1
ffffffffc0200b6c:	e0060613          	addi	a2,a2,-512 # ffffffffc0201968 <etext+0x252>
ffffffffc0200b70:	0d400593          	li	a1,212
ffffffffc0200b74:	00001517          	auipc	a0,0x1
ffffffffc0200b78:	e0c50513          	addi	a0,a0,-500 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200b7c:	e4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b80:	00001697          	auipc	a3,0x1
ffffffffc0200b84:	e6868693          	addi	a3,a3,-408 # ffffffffc02019e8 <etext+0x2d2>
ffffffffc0200b88:	00001617          	auipc	a2,0x1
ffffffffc0200b8c:	de060613          	addi	a2,a2,-544 # ffffffffc0201968 <etext+0x252>
ffffffffc0200b90:	0d300593          	li	a1,211
ffffffffc0200b94:	00001517          	auipc	a0,0x1
ffffffffc0200b98:	dec50513          	addi	a0,a0,-532 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200b9c:	e2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ba0:	00001697          	auipc	a3,0x1
ffffffffc0200ba4:	e6868693          	addi	a3,a3,-408 # ffffffffc0201a08 <etext+0x2f2>
ffffffffc0200ba8:	00001617          	auipc	a2,0x1
ffffffffc0200bac:	dc060613          	addi	a2,a2,-576 # ffffffffc0201968 <etext+0x252>
ffffffffc0200bb0:	0bb00593          	li	a1,187
ffffffffc0200bb4:	00001517          	auipc	a0,0x1
ffffffffc0200bb8:	dcc50513          	addi	a0,a0,-564 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200bbc:	e0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0200bc0:	00001697          	auipc	a3,0x1
ffffffffc0200bc4:	0f068693          	addi	a3,a3,240 # ffffffffc0201cb0 <etext+0x59a>
ffffffffc0200bc8:	00001617          	auipc	a2,0x1
ffffffffc0200bcc:	da060613          	addi	a2,a2,-608 # ffffffffc0201968 <etext+0x252>
ffffffffc0200bd0:	12500593          	li	a1,293
ffffffffc0200bd4:	00001517          	auipc	a0,0x1
ffffffffc0200bd8:	dac50513          	addi	a0,a0,-596 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200bdc:	decff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200be0:	00001697          	auipc	a3,0x1
ffffffffc0200be4:	f7068693          	addi	a3,a3,-144 # ffffffffc0201b50 <etext+0x43a>
ffffffffc0200be8:	00001617          	auipc	a2,0x1
ffffffffc0200bec:	d8060613          	addi	a2,a2,-640 # ffffffffc0201968 <etext+0x252>
ffffffffc0200bf0:	11a00593          	li	a1,282
ffffffffc0200bf4:	00001517          	auipc	a0,0x1
ffffffffc0200bf8:	d8c50513          	addi	a0,a0,-628 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200bfc:	dccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c00:	00001697          	auipc	a3,0x1
ffffffffc0200c04:	ef068693          	addi	a3,a3,-272 # ffffffffc0201af0 <etext+0x3da>
ffffffffc0200c08:	00001617          	auipc	a2,0x1
ffffffffc0200c0c:	d6060613          	addi	a2,a2,-672 # ffffffffc0201968 <etext+0x252>
ffffffffc0200c10:	11800593          	li	a1,280
ffffffffc0200c14:	00001517          	auipc	a0,0x1
ffffffffc0200c18:	d6c50513          	addi	a0,a0,-660 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200c1c:	dacff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c20:	00001697          	auipc	a3,0x1
ffffffffc0200c24:	e9068693          	addi	a3,a3,-368 # ffffffffc0201ab0 <etext+0x39a>
ffffffffc0200c28:	00001617          	auipc	a2,0x1
ffffffffc0200c2c:	d4060613          	addi	a2,a2,-704 # ffffffffc0201968 <etext+0x252>
ffffffffc0200c30:	0c100593          	li	a1,193
ffffffffc0200c34:	00001517          	auipc	a0,0x1
ffffffffc0200c38:	d4c50513          	addi	a0,a0,-692 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200c3c:	d8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200c40:	00001697          	auipc	a3,0x1
ffffffffc0200c44:	03068693          	addi	a3,a3,48 # ffffffffc0201c70 <etext+0x55a>
ffffffffc0200c48:	00001617          	auipc	a2,0x1
ffffffffc0200c4c:	d2060613          	addi	a2,a2,-736 # ffffffffc0201968 <etext+0x252>
ffffffffc0200c50:	11200593          	li	a1,274
ffffffffc0200c54:	00001517          	auipc	a0,0x1
ffffffffc0200c58:	d2c50513          	addi	a0,a0,-724 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200c5c:	d6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200c60:	00001697          	auipc	a3,0x1
ffffffffc0200c64:	ff068693          	addi	a3,a3,-16 # ffffffffc0201c50 <etext+0x53a>
ffffffffc0200c68:	00001617          	auipc	a2,0x1
ffffffffc0200c6c:	d0060613          	addi	a2,a2,-768 # ffffffffc0201968 <etext+0x252>
ffffffffc0200c70:	11000593          	li	a1,272
ffffffffc0200c74:	00001517          	auipc	a0,0x1
ffffffffc0200c78:	d0c50513          	addi	a0,a0,-756 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200c7c:	d4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200c80:	00001697          	auipc	a3,0x1
ffffffffc0200c84:	fa868693          	addi	a3,a3,-88 # ffffffffc0201c28 <etext+0x512>
ffffffffc0200c88:	00001617          	auipc	a2,0x1
ffffffffc0200c8c:	ce060613          	addi	a2,a2,-800 # ffffffffc0201968 <etext+0x252>
ffffffffc0200c90:	10e00593          	li	a1,270
ffffffffc0200c94:	00001517          	auipc	a0,0x1
ffffffffc0200c98:	cec50513          	addi	a0,a0,-788 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200c9c:	d2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200ca0:	00001697          	auipc	a3,0x1
ffffffffc0200ca4:	f6068693          	addi	a3,a3,-160 # ffffffffc0201c00 <etext+0x4ea>
ffffffffc0200ca8:	00001617          	auipc	a2,0x1
ffffffffc0200cac:	cc060613          	addi	a2,a2,-832 # ffffffffc0201968 <etext+0x252>
ffffffffc0200cb0:	10d00593          	li	a1,269
ffffffffc0200cb4:	00001517          	auipc	a0,0x1
ffffffffc0200cb8:	ccc50513          	addi	a0,a0,-820 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200cbc:	d0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0200cc0:	00001697          	auipc	a3,0x1
ffffffffc0200cc4:	f3068693          	addi	a3,a3,-208 # ffffffffc0201bf0 <etext+0x4da>
ffffffffc0200cc8:	00001617          	auipc	a2,0x1
ffffffffc0200ccc:	ca060613          	addi	a2,a2,-864 # ffffffffc0201968 <etext+0x252>
ffffffffc0200cd0:	10800593          	li	a1,264
ffffffffc0200cd4:	00001517          	auipc	a0,0x1
ffffffffc0200cd8:	cac50513          	addi	a0,a0,-852 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200cdc:	cecff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ce0:	00001697          	auipc	a3,0x1
ffffffffc0200ce4:	e1068693          	addi	a3,a3,-496 # ffffffffc0201af0 <etext+0x3da>
ffffffffc0200ce8:	00001617          	auipc	a2,0x1
ffffffffc0200cec:	c8060613          	addi	a2,a2,-896 # ffffffffc0201968 <etext+0x252>
ffffffffc0200cf0:	10700593          	li	a1,263
ffffffffc0200cf4:	00001517          	auipc	a0,0x1
ffffffffc0200cf8:	c8c50513          	addi	a0,a0,-884 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200cfc:	cccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d00:	00001697          	auipc	a3,0x1
ffffffffc0200d04:	ed068693          	addi	a3,a3,-304 # ffffffffc0201bd0 <etext+0x4ba>
ffffffffc0200d08:	00001617          	auipc	a2,0x1
ffffffffc0200d0c:	c6060613          	addi	a2,a2,-928 # ffffffffc0201968 <etext+0x252>
ffffffffc0200d10:	10600593          	li	a1,262
ffffffffc0200d14:	00001517          	auipc	a0,0x1
ffffffffc0200d18:	c6c50513          	addi	a0,a0,-916 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200d1c:	cacff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d20:	00001697          	auipc	a3,0x1
ffffffffc0200d24:	e8068693          	addi	a3,a3,-384 # ffffffffc0201ba0 <etext+0x48a>
ffffffffc0200d28:	00001617          	auipc	a2,0x1
ffffffffc0200d2c:	c4060613          	addi	a2,a2,-960 # ffffffffc0201968 <etext+0x252>
ffffffffc0200d30:	10500593          	li	a1,261
ffffffffc0200d34:	00001517          	auipc	a0,0x1
ffffffffc0200d38:	c4c50513          	addi	a0,a0,-948 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200d3c:	c8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d40:	00001697          	auipc	a3,0x1
ffffffffc0200d44:	e4868693          	addi	a3,a3,-440 # ffffffffc0201b88 <etext+0x472>
ffffffffc0200d48:	00001617          	auipc	a2,0x1
ffffffffc0200d4c:	c2060613          	addi	a2,a2,-992 # ffffffffc0201968 <etext+0x252>
ffffffffc0200d50:	10400593          	li	a1,260
ffffffffc0200d54:	00001517          	auipc	a0,0x1
ffffffffc0200d58:	c2c50513          	addi	a0,a0,-980 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200d5c:	c6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d60:	00001697          	auipc	a3,0x1
ffffffffc0200d64:	d9068693          	addi	a3,a3,-624 # ffffffffc0201af0 <etext+0x3da>
ffffffffc0200d68:	00001617          	auipc	a2,0x1
ffffffffc0200d6c:	c0060613          	addi	a2,a2,-1024 # ffffffffc0201968 <etext+0x252>
ffffffffc0200d70:	0fe00593          	li	a1,254
ffffffffc0200d74:	00001517          	auipc	a0,0x1
ffffffffc0200d78:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200d7c:	c4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200d80:	00001697          	auipc	a3,0x1
ffffffffc0200d84:	df068693          	addi	a3,a3,-528 # ffffffffc0201b70 <etext+0x45a>
ffffffffc0200d88:	00001617          	auipc	a2,0x1
ffffffffc0200d8c:	be060613          	addi	a2,a2,-1056 # ffffffffc0201968 <etext+0x252>
ffffffffc0200d90:	0f900593          	li	a1,249
ffffffffc0200d94:	00001517          	auipc	a0,0x1
ffffffffc0200d98:	bec50513          	addi	a0,a0,-1044 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200d9c:	c2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200da0:	00001697          	auipc	a3,0x1
ffffffffc0200da4:	ef068693          	addi	a3,a3,-272 # ffffffffc0201c90 <etext+0x57a>
ffffffffc0200da8:	00001617          	auipc	a2,0x1
ffffffffc0200dac:	bc060613          	addi	a2,a2,-1088 # ffffffffc0201968 <etext+0x252>
ffffffffc0200db0:	11700593          	li	a1,279
ffffffffc0200db4:	00001517          	auipc	a0,0x1
ffffffffc0200db8:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200dbc:	c0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc0200dc0:	00001697          	auipc	a3,0x1
ffffffffc0200dc4:	f0068693          	addi	a3,a3,-256 # ffffffffc0201cc0 <etext+0x5aa>
ffffffffc0200dc8:	00001617          	auipc	a2,0x1
ffffffffc0200dcc:	ba060613          	addi	a2,a2,-1120 # ffffffffc0201968 <etext+0x252>
ffffffffc0200dd0:	12600593          	li	a1,294
ffffffffc0200dd4:	00001517          	auipc	a0,0x1
ffffffffc0200dd8:	bac50513          	addi	a0,a0,-1108 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200ddc:	becff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200de0:	00001697          	auipc	a3,0x1
ffffffffc0200de4:	bc868693          	addi	a3,a3,-1080 # ffffffffc02019a8 <etext+0x292>
ffffffffc0200de8:	00001617          	auipc	a2,0x1
ffffffffc0200dec:	b8060613          	addi	a2,a2,-1152 # ffffffffc0201968 <etext+0x252>
ffffffffc0200df0:	0f300593          	li	a1,243
ffffffffc0200df4:	00001517          	auipc	a0,0x1
ffffffffc0200df8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200dfc:	bccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e00:	00001697          	auipc	a3,0x1
ffffffffc0200e04:	be868693          	addi	a3,a3,-1048 # ffffffffc02019e8 <etext+0x2d2>
ffffffffc0200e08:	00001617          	auipc	a2,0x1
ffffffffc0200e0c:	b6060613          	addi	a2,a2,-1184 # ffffffffc0201968 <etext+0x252>
ffffffffc0200e10:	0ba00593          	li	a1,186
ffffffffc0200e14:	00001517          	auipc	a0,0x1
ffffffffc0200e18:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200e1c:	bacff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200e20 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0200e20:	1141                	addi	sp,sp,-16
ffffffffc0200e22:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200e24:	14058e63          	beqz	a1,ffffffffc0200f80 <default_free_pages+0x160>
    for (; p != base + n; p ++) {
ffffffffc0200e28:	00259713          	slli	a4,a1,0x2
ffffffffc0200e2c:	972e                	add	a4,a4,a1
ffffffffc0200e2e:	070e                	slli	a4,a4,0x3
ffffffffc0200e30:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200e34:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200e36:	cf09                	beqz	a4,ffffffffc0200e50 <default_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200e38:	6798                	ld	a4,8(a5)
ffffffffc0200e3a:	8b0d                	andi	a4,a4,3
ffffffffc0200e3c:	12071263          	bnez	a4,ffffffffc0200f60 <default_free_pages+0x140>
        p->flags = 0;
ffffffffc0200e40:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200e44:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200e48:	02878793          	addi	a5,a5,40
ffffffffc0200e4c:	fed796e3          	bne	a5,a3,ffffffffc0200e38 <default_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200e50:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200e54:	00005717          	auipc	a4,0x5
ffffffffc0200e58:	1d472703          	lw	a4,468(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200e5c:	00005697          	auipc	a3,0x5
ffffffffc0200e60:	1bc68693          	addi	a3,a3,444 # ffffffffc0206018 <free_area>
    return list->next == list;
ffffffffc0200e64:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200e66:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc0200e6a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200e6c:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200e6e:	9f2d                	addw	a4,a4,a1
ffffffffc0200e70:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200e72:	0ad78763          	beq	a5,a3,ffffffffc0200f20 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0200e76:	fe878713          	addi	a4,a5,-24
ffffffffc0200e7a:	4801                	li	a6,0
ffffffffc0200e7c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200e80:	00e56a63          	bltu	a0,a4,ffffffffc0200e94 <default_free_pages+0x74>
    return listelm->next;
ffffffffc0200e84:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200e86:	06d70563          	beq	a4,a3,ffffffffc0200ef0 <default_free_pages+0xd0>
    struct Page *p = base;
ffffffffc0200e8a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200e8c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200e90:	fee57ae3          	bgeu	a0,a4,ffffffffc0200e84 <default_free_pages+0x64>
ffffffffc0200e94:	00080463          	beqz	a6,ffffffffc0200e9c <default_free_pages+0x7c>
ffffffffc0200e98:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200e9c:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200ea0:	e390                	sd	a2,0(a5)
ffffffffc0200ea2:	00c83423          	sd	a2,8(a6)
    elm->prev = prev;
ffffffffc0200ea6:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc0200eaa:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0200eac:	02d80063          	beq	a6,a3,ffffffffc0200ecc <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0200eb0:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200eb4:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200eb8:	020e1613          	slli	a2,t3,0x20
ffffffffc0200ebc:	9201                	srli	a2,a2,0x20
ffffffffc0200ebe:	00261713          	slli	a4,a2,0x2
ffffffffc0200ec2:	9732                	add	a4,a4,a2
ffffffffc0200ec4:	070e                	slli	a4,a4,0x3
ffffffffc0200ec6:	971a                	add	a4,a4,t1
ffffffffc0200ec8:	02e50e63          	beq	a0,a4,ffffffffc0200f04 <default_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200ecc:	00d78f63          	beq	a5,a3,ffffffffc0200eea <default_free_pages+0xca>
        if (base + base->property == p) {
ffffffffc0200ed0:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200ed2:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200ed6:	02059613          	slli	a2,a1,0x20
ffffffffc0200eda:	9201                	srli	a2,a2,0x20
ffffffffc0200edc:	00261713          	slli	a4,a2,0x2
ffffffffc0200ee0:	9732                	add	a4,a4,a2
ffffffffc0200ee2:	070e                	slli	a4,a4,0x3
ffffffffc0200ee4:	972a                	add	a4,a4,a0
ffffffffc0200ee6:	04e68a63          	beq	a3,a4,ffffffffc0200f3a <default_free_pages+0x11a>
}
ffffffffc0200eea:	60a2                	ld	ra,8(sp)
ffffffffc0200eec:	0141                	addi	sp,sp,16
ffffffffc0200eee:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200ef0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200ef2:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200ef4:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200ef6:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200ef8:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200efa:	02d70c63          	beq	a4,a3,ffffffffc0200f32 <default_free_pages+0x112>
ffffffffc0200efe:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200f00:	87ba                	mv	a5,a4
ffffffffc0200f02:	b769                	j	ffffffffc0200e8c <default_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200f04:	01c585bb          	addw	a1,a1,t3
ffffffffc0200f08:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200f0c:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200f10:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200f14:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200f18:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200f1c:	851a                	mv	a0,t1
ffffffffc0200f1e:	b77d                	j	ffffffffc0200ecc <default_free_pages+0xac>
}
ffffffffc0200f20:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f22:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200f26:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f28:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200f2a:	e398                	sd	a4,0(a5)
ffffffffc0200f2c:	e798                	sd	a4,8(a5)
}
ffffffffc0200f2e:	0141                	addi	sp,sp,16
ffffffffc0200f30:	8082                	ret
    return listelm->prev;
ffffffffc0200f32:	883e                	mv	a6,a5
ffffffffc0200f34:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f36:	87b6                	mv	a5,a3
ffffffffc0200f38:	bf95                	j	ffffffffc0200eac <default_free_pages+0x8c>
            base->property += p->property;
ffffffffc0200f3a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200f3e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200f42:	0007b803          	ld	a6,0(a5)
ffffffffc0200f46:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200f48:	9ead                	addw	a3,a3,a1
ffffffffc0200f4a:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200f4c:	9b75                	andi	a4,a4,-3
ffffffffc0200f4e:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200f52:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200f54:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200f58:	01063023          	sd	a6,0(a2)
ffffffffc0200f5c:	0141                	addi	sp,sp,16
ffffffffc0200f5e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f60:	00001697          	auipc	a3,0x1
ffffffffc0200f64:	d7068693          	addi	a3,a3,-656 # ffffffffc0201cd0 <etext+0x5ba>
ffffffffc0200f68:	00001617          	auipc	a2,0x1
ffffffffc0200f6c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0201968 <etext+0x252>
ffffffffc0200f70:	08300593          	li	a1,131
ffffffffc0200f74:	00001517          	auipc	a0,0x1
ffffffffc0200f78:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200f7c:	a4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200f80:	00001697          	auipc	a3,0x1
ffffffffc0200f84:	9e068693          	addi	a3,a3,-1568 # ffffffffc0201960 <etext+0x24a>
ffffffffc0200f88:	00001617          	auipc	a2,0x1
ffffffffc0200f8c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0201968 <etext+0x252>
ffffffffc0200f90:	08000593          	li	a1,128
ffffffffc0200f94:	00001517          	auipc	a0,0x1
ffffffffc0200f98:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0201980 <etext+0x26a>
ffffffffc0200f9c:	a2cff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200fa0 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0200fa0:	1141                	addi	sp,sp,-16
ffffffffc0200fa2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fa4:	c9e9                	beqz	a1,ffffffffc0201076 <default_init_memmap+0xd6>
    for (; p != base + n; p ++) {
ffffffffc0200fa6:	00259713          	slli	a4,a1,0x2
ffffffffc0200faa:	972e                	add	a4,a4,a1
ffffffffc0200fac:	070e                	slli	a4,a4,0x3
ffffffffc0200fae:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200fb2:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200fb4:	cf11                	beqz	a4,ffffffffc0200fd0 <default_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200fb6:	6798                	ld	a4,8(a5)
ffffffffc0200fb8:	8b05                	andi	a4,a4,1
ffffffffc0200fba:	cf51                	beqz	a4,ffffffffc0201056 <default_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc0200fbc:	0007a823          	sw	zero,16(a5)
ffffffffc0200fc0:	0007b423          	sd	zero,8(a5)
ffffffffc0200fc4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200fc8:	02878793          	addi	a5,a5,40
ffffffffc0200fcc:	fed795e3          	bne	a5,a3,ffffffffc0200fb6 <default_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200fd0:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200fd2:	00005717          	auipc	a4,0x5
ffffffffc0200fd6:	05672703          	lw	a4,86(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200fda:	00005697          	auipc	a3,0x5
ffffffffc0200fde:	03e68693          	addi	a3,a3,62 # ffffffffc0206018 <free_area>
    return list->next == list;
ffffffffc0200fe2:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200fe4:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200fe8:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200fea:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200fec:	9f2d                	addw	a4,a4,a1
ffffffffc0200fee:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200ff0:	04d78663          	beq	a5,a3,ffffffffc020103c <default_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc0200ff4:	fe878713          	addi	a4,a5,-24
ffffffffc0200ff8:	4581                	li	a1,0
ffffffffc0200ffa:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200ffe:	00e56a63          	bltu	a0,a4,ffffffffc0201012 <default_init_memmap+0x72>
    return listelm->next;
ffffffffc0201002:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201004:	02d70263          	beq	a4,a3,ffffffffc0201028 <default_init_memmap+0x88>
    struct Page *p = base;
ffffffffc0201008:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020100a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020100e:	fee57ae3          	bgeu	a0,a4,ffffffffc0201002 <default_init_memmap+0x62>
ffffffffc0201012:	c199                	beqz	a1,ffffffffc0201018 <default_init_memmap+0x78>
ffffffffc0201014:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201018:	6398                	ld	a4,0(a5)
}
ffffffffc020101a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020101c:	e390                	sd	a2,0(a5)
ffffffffc020101e:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0201020:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201022:	f11c                	sd	a5,32(a0)
ffffffffc0201024:	0141                	addi	sp,sp,16
ffffffffc0201026:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201028:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020102a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020102c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020102e:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201030:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201032:	00d70e63          	beq	a4,a3,ffffffffc020104e <default_init_memmap+0xae>
ffffffffc0201036:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201038:	87ba                	mv	a5,a4
ffffffffc020103a:	bfc1                	j	ffffffffc020100a <default_init_memmap+0x6a>
}
ffffffffc020103c:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020103e:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201042:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201044:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201046:	e398                	sd	a4,0(a5)
ffffffffc0201048:	e798                	sd	a4,8(a5)
}
ffffffffc020104a:	0141                	addi	sp,sp,16
ffffffffc020104c:	8082                	ret
ffffffffc020104e:	60a2                	ld	ra,8(sp)
ffffffffc0201050:	e290                	sd	a2,0(a3)
ffffffffc0201052:	0141                	addi	sp,sp,16
ffffffffc0201054:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201056:	00001697          	auipc	a3,0x1
ffffffffc020105a:	ca268693          	addi	a3,a3,-862 # ffffffffc0201cf8 <etext+0x5e2>
ffffffffc020105e:	00001617          	auipc	a2,0x1
ffffffffc0201062:	90a60613          	addi	a2,a2,-1782 # ffffffffc0201968 <etext+0x252>
ffffffffc0201066:	04900593          	li	a1,73
ffffffffc020106a:	00001517          	auipc	a0,0x1
ffffffffc020106e:	91650513          	addi	a0,a0,-1770 # ffffffffc0201980 <etext+0x26a>
ffffffffc0201072:	956ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0201076:	00001697          	auipc	a3,0x1
ffffffffc020107a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0201960 <etext+0x24a>
ffffffffc020107e:	00001617          	auipc	a2,0x1
ffffffffc0201082:	8ea60613          	addi	a2,a2,-1814 # ffffffffc0201968 <etext+0x252>
ffffffffc0201086:	04600593          	li	a1,70
ffffffffc020108a:	00001517          	auipc	a0,0x1
ffffffffc020108e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0201980 <etext+0x26a>
ffffffffc0201092:	936ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0201096 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201096:	00005797          	auipc	a5,0x5
ffffffffc020109a:	fb27b783          	ld	a5,-78(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc020109e:	6f9c                	ld	a5,24(a5)
ffffffffc02010a0:	8782                	jr	a5

ffffffffc02010a2 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02010a2:	00005797          	auipc	a5,0x5
ffffffffc02010a6:	fa67b783          	ld	a5,-90(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc02010aa:	739c                	ld	a5,32(a5)
ffffffffc02010ac:	8782                	jr	a5

ffffffffc02010ae <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02010ae:	00005797          	auipc	a5,0x5
ffffffffc02010b2:	f9a7b783          	ld	a5,-102(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc02010b6:	779c                	ld	a5,40(a5)
ffffffffc02010b8:	8782                	jr	a5

ffffffffc02010ba <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02010ba:	00001797          	auipc	a5,0x1
ffffffffc02010be:	e8678793          	addi	a5,a5,-378 # ffffffffc0201f40 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010c2:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02010c4:	7139                	addi	sp,sp,-64
ffffffffc02010c6:	fc06                	sd	ra,56(sp)
ffffffffc02010c8:	f822                	sd	s0,48(sp)
ffffffffc02010ca:	f426                	sd	s1,40(sp)
ffffffffc02010cc:	ec4e                	sd	s3,24(sp)
ffffffffc02010ce:	f04a                	sd	s2,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02010d0:	00005417          	auipc	s0,0x5
ffffffffc02010d4:	f7840413          	addi	s0,s0,-136 # ffffffffc0206048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010d8:	00001517          	auipc	a0,0x1
ffffffffc02010dc:	c4850513          	addi	a0,a0,-952 # ffffffffc0201d20 <etext+0x60a>
    pmm_manager = &default_pmm_manager;
ffffffffc02010e0:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010e2:	866ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc02010e6:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010e8:	00005497          	auipc	s1,0x5
ffffffffc02010ec:	f7848493          	addi	s1,s1,-136 # ffffffffc0206060 <va_pa_offset>
    pmm_manager->init();
ffffffffc02010f0:	679c                	ld	a5,8(a5)
ffffffffc02010f2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010f4:	57f5                	li	a5,-3
ffffffffc02010f6:	07fa                	slli	a5,a5,0x1e
ffffffffc02010f8:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02010fa:	c60ff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc02010fe:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201100:	c64ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201104:	14050c63          	beqz	a0,ffffffffc020125c <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201108:	00a98933          	add	s2,s3,a0
ffffffffc020110c:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc020110e:	00001517          	auipc	a0,0x1
ffffffffc0201112:	c5a50513          	addi	a0,a0,-934 # ffffffffc0201d68 <etext+0x652>
ffffffffc0201116:	832ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020111a:	65a2                	ld	a1,8(sp)
ffffffffc020111c:	864e                	mv	a2,s3
ffffffffc020111e:	fff90693          	addi	a3,s2,-1
ffffffffc0201122:	00001517          	auipc	a0,0x1
ffffffffc0201126:	c5e50513          	addi	a0,a0,-930 # ffffffffc0201d80 <etext+0x66a>
ffffffffc020112a:	81eff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020112e:	c80007b7          	lui	a5,0xc8000
ffffffffc0201132:	85ca                	mv	a1,s2
ffffffffc0201134:	0d27e263          	bltu	a5,s2,ffffffffc02011f8 <pmm_init+0x13e>
ffffffffc0201138:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020113a:	00006697          	auipc	a3,0x6
ffffffffc020113e:	f3d68693          	addi	a3,a3,-195 # ffffffffc0207077 <end+0xfff>
ffffffffc0201142:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0201144:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201146:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc020114a:	00005797          	auipc	a5,0x5
ffffffffc020114e:	f0b7bf23          	sd	a1,-226(a5) # ffffffffc0206068 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201152:	00005797          	auipc	a5,0x5
ffffffffc0201156:	f0d7bf23          	sd	a3,-226(a5) # ffffffffc0206070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020115a:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020115c:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020115e:	02080963          	beqz	a6,ffffffffc0201190 <pmm_init+0xd6>
ffffffffc0201162:	00259613          	slli	a2,a1,0x2
ffffffffc0201166:	962e                	add	a2,a2,a1
ffffffffc0201168:	fec007b7          	lui	a5,0xfec00
ffffffffc020116c:	97b6                	add	a5,a5,a3
ffffffffc020116e:	060e                	slli	a2,a2,0x3
ffffffffc0201170:	963e                	add	a2,a2,a5
ffffffffc0201172:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0201174:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201176:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9fb0>
        SetPageReserved(pages + i);
ffffffffc020117a:	00176713          	ori	a4,a4,1
ffffffffc020117e:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201182:	fec799e3          	bne	a5,a2,ffffffffc0201174 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201186:	00281793          	slli	a5,a6,0x2
ffffffffc020118a:	97c2                	add	a5,a5,a6
ffffffffc020118c:	078e                	slli	a5,a5,0x3
ffffffffc020118e:	96be                	add	a3,a3,a5
ffffffffc0201190:	c02007b7          	lui	a5,0xc0200
ffffffffc0201194:	0af6e863          	bltu	a3,a5,ffffffffc0201244 <pmm_init+0x18a>
ffffffffc0201198:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020119a:	77fd                	lui	a5,0xfffff
ffffffffc020119c:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011a0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02011a2:	0526ed63          	bltu	a3,s2,ffffffffc02011fc <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02011a6:	601c                	ld	a5,0(s0)
ffffffffc02011a8:	7b9c                	ld	a5,48(a5)
ffffffffc02011aa:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011ac:	00001517          	auipc	a0,0x1
ffffffffc02011b0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0201e08 <etext+0x6f2>
ffffffffc02011b4:	f95fe0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02011b8:	00004597          	auipc	a1,0x4
ffffffffc02011bc:	e4858593          	addi	a1,a1,-440 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02011c0:	00005797          	auipc	a5,0x5
ffffffffc02011c4:	e8b7bc23          	sd	a1,-360(a5) # ffffffffc0206058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011c8:	c02007b7          	lui	a5,0xc0200
ffffffffc02011cc:	0af5e463          	bltu	a1,a5,ffffffffc0201274 <pmm_init+0x1ba>
ffffffffc02011d0:	609c                	ld	a5,0(s1)
}
ffffffffc02011d2:	7442                	ld	s0,48(sp)
ffffffffc02011d4:	70e2                	ld	ra,56(sp)
ffffffffc02011d6:	74a2                	ld	s1,40(sp)
ffffffffc02011d8:	7902                	ld	s2,32(sp)
ffffffffc02011da:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02011dc:	40f586b3          	sub	a3,a1,a5
ffffffffc02011e0:	00005797          	auipc	a5,0x5
ffffffffc02011e4:	e6d7b823          	sd	a3,-400(a5) # ffffffffc0206050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011e8:	00001517          	auipc	a0,0x1
ffffffffc02011ec:	c4050513          	addi	a0,a0,-960 # ffffffffc0201e28 <etext+0x712>
ffffffffc02011f0:	8636                	mv	a2,a3
}
ffffffffc02011f2:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011f4:	f55fe06f          	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02011f8:	85be                	mv	a1,a5
ffffffffc02011fa:	bf3d                	j	ffffffffc0201138 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02011fc:	6705                	lui	a4,0x1
ffffffffc02011fe:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201200:	96ba                	add	a3,a3,a4
ffffffffc0201202:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201204:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201208:	02b7f263          	bgeu	a5,a1,ffffffffc020122c <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc020120c:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020120e:	fff80637          	lui	a2,0xfff80
ffffffffc0201212:	97b2                	add	a5,a5,a2
ffffffffc0201214:	00279513          	slli	a0,a5,0x2
ffffffffc0201218:	953e                	add	a0,a0,a5
ffffffffc020121a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020121c:	40d90933          	sub	s2,s2,a3
ffffffffc0201220:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201222:	00c95593          	srli	a1,s2,0xc
ffffffffc0201226:	9546                	add	a0,a0,a7
ffffffffc0201228:	9782                	jalr	a5
}
ffffffffc020122a:	bfb5                	j	ffffffffc02011a6 <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc020122c:	00001617          	auipc	a2,0x1
ffffffffc0201230:	bac60613          	addi	a2,a2,-1108 # ffffffffc0201dd8 <etext+0x6c2>
ffffffffc0201234:	06a00593          	li	a1,106
ffffffffc0201238:	00001517          	auipc	a0,0x1
ffffffffc020123c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0201df8 <etext+0x6e2>
ffffffffc0201240:	f89fe0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201244:	00001617          	auipc	a2,0x1
ffffffffc0201248:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0201db0 <etext+0x69a>
ffffffffc020124c:	05e00593          	li	a1,94
ffffffffc0201250:	00001517          	auipc	a0,0x1
ffffffffc0201254:	b0850513          	addi	a0,a0,-1272 # ffffffffc0201d58 <etext+0x642>
ffffffffc0201258:	f71fe0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc020125c:	00001617          	auipc	a2,0x1
ffffffffc0201260:	adc60613          	addi	a2,a2,-1316 # ffffffffc0201d38 <etext+0x622>
ffffffffc0201264:	04600593          	li	a1,70
ffffffffc0201268:	00001517          	auipc	a0,0x1
ffffffffc020126c:	af050513          	addi	a0,a0,-1296 # ffffffffc0201d58 <etext+0x642>
ffffffffc0201270:	f59fe0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201274:	86ae                	mv	a3,a1
ffffffffc0201276:	00001617          	auipc	a2,0x1
ffffffffc020127a:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0201db0 <etext+0x69a>
ffffffffc020127e:	07900593          	li	a1,121
ffffffffc0201282:	00001517          	auipc	a0,0x1
ffffffffc0201286:	ad650513          	addi	a0,a0,-1322 # ffffffffc0201d58 <etext+0x642>
ffffffffc020128a:	f3ffe0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc020128e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020128e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201290:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201294:	f022                	sd	s0,32(sp)
ffffffffc0201296:	ec26                	sd	s1,24(sp)
ffffffffc0201298:	e84a                	sd	s2,16(sp)
ffffffffc020129a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020129c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012a0:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012a2:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02012a6:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012aa:	84aa                	mv	s1,a0
ffffffffc02012ac:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02012ae:	03067d63          	bgeu	a2,a6,ffffffffc02012e8 <printnum+0x5a>
ffffffffc02012b2:	e44e                	sd	s3,8(sp)
ffffffffc02012b4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02012b6:	4785                	li	a5,1
ffffffffc02012b8:	00e7d763          	bge	a5,a4,ffffffffc02012c6 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02012bc:	85ca                	mv	a1,s2
ffffffffc02012be:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02012c0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02012c2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02012c4:	fc65                	bnez	s0,ffffffffc02012bc <printnum+0x2e>
ffffffffc02012c6:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012c8:	00001797          	auipc	a5,0x1
ffffffffc02012cc:	ba078793          	addi	a5,a5,-1120 # ffffffffc0201e68 <etext+0x752>
ffffffffc02012d0:	97d2                	add	a5,a5,s4
}
ffffffffc02012d2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012d4:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02012d8:	70a2                	ld	ra,40(sp)
ffffffffc02012da:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012dc:	85ca                	mv	a1,s2
ffffffffc02012de:	87a6                	mv	a5,s1
}
ffffffffc02012e0:	6942                	ld	s2,16(sp)
ffffffffc02012e2:	64e2                	ld	s1,24(sp)
ffffffffc02012e4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012e6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02012e8:	03065633          	divu	a2,a2,a6
ffffffffc02012ec:	8722                	mv	a4,s0
ffffffffc02012ee:	fa1ff0ef          	jal	ffffffffc020128e <printnum>
ffffffffc02012f2:	bfd9                	j	ffffffffc02012c8 <printnum+0x3a>

ffffffffc02012f4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012f4:	7119                	addi	sp,sp,-128
ffffffffc02012f6:	f4a6                	sd	s1,104(sp)
ffffffffc02012f8:	f0ca                	sd	s2,96(sp)
ffffffffc02012fa:	ecce                	sd	s3,88(sp)
ffffffffc02012fc:	e8d2                	sd	s4,80(sp)
ffffffffc02012fe:	e4d6                	sd	s5,72(sp)
ffffffffc0201300:	e0da                	sd	s6,64(sp)
ffffffffc0201302:	f862                	sd	s8,48(sp)
ffffffffc0201304:	fc86                	sd	ra,120(sp)
ffffffffc0201306:	f8a2                	sd	s0,112(sp)
ffffffffc0201308:	fc5e                	sd	s7,56(sp)
ffffffffc020130a:	f466                	sd	s9,40(sp)
ffffffffc020130c:	f06a                	sd	s10,32(sp)
ffffffffc020130e:	ec6e                	sd	s11,24(sp)
ffffffffc0201310:	84aa                	mv	s1,a0
ffffffffc0201312:	8c32                	mv	s8,a2
ffffffffc0201314:	8a36                	mv	s4,a3
ffffffffc0201316:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201318:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020131c:	05500b13          	li	s6,85
ffffffffc0201320:	00001a97          	auipc	s5,0x1
ffffffffc0201324:	c58a8a93          	addi	s5,s5,-936 # ffffffffc0201f78 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201328:	000c4503          	lbu	a0,0(s8)
ffffffffc020132c:	001c0413          	addi	s0,s8,1
ffffffffc0201330:	01350a63          	beq	a0,s3,ffffffffc0201344 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201334:	cd0d                	beqz	a0,ffffffffc020136e <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201336:	85ca                	mv	a1,s2
ffffffffc0201338:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020133a:	00044503          	lbu	a0,0(s0)
ffffffffc020133e:	0405                	addi	s0,s0,1
ffffffffc0201340:	ff351ae3          	bne	a0,s3,ffffffffc0201334 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201344:	5cfd                	li	s9,-1
ffffffffc0201346:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201348:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020134c:	4b81                	li	s7,0
ffffffffc020134e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201350:	00044683          	lbu	a3,0(s0)
ffffffffc0201354:	00140c13          	addi	s8,s0,1
ffffffffc0201358:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020135c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201360:	02bb6663          	bltu	s6,a1,ffffffffc020138c <vprintfmt+0x98>
ffffffffc0201364:	058a                	slli	a1,a1,0x2
ffffffffc0201366:	95d6                	add	a1,a1,s5
ffffffffc0201368:	4198                	lw	a4,0(a1)
ffffffffc020136a:	9756                	add	a4,a4,s5
ffffffffc020136c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020136e:	70e6                	ld	ra,120(sp)
ffffffffc0201370:	7446                	ld	s0,112(sp)
ffffffffc0201372:	74a6                	ld	s1,104(sp)
ffffffffc0201374:	7906                	ld	s2,96(sp)
ffffffffc0201376:	69e6                	ld	s3,88(sp)
ffffffffc0201378:	6a46                	ld	s4,80(sp)
ffffffffc020137a:	6aa6                	ld	s5,72(sp)
ffffffffc020137c:	6b06                	ld	s6,64(sp)
ffffffffc020137e:	7be2                	ld	s7,56(sp)
ffffffffc0201380:	7c42                	ld	s8,48(sp)
ffffffffc0201382:	7ca2                	ld	s9,40(sp)
ffffffffc0201384:	7d02                	ld	s10,32(sp)
ffffffffc0201386:	6de2                	ld	s11,24(sp)
ffffffffc0201388:	6109                	addi	sp,sp,128
ffffffffc020138a:	8082                	ret
            putch('%', putdat);
ffffffffc020138c:	85ca                	mv	a1,s2
ffffffffc020138e:	02500513          	li	a0,37
ffffffffc0201392:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201394:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201398:	02500713          	li	a4,37
ffffffffc020139c:	8c22                	mv	s8,s0
ffffffffc020139e:	f8e785e3          	beq	a5,a4,ffffffffc0201328 <vprintfmt+0x34>
ffffffffc02013a2:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02013a6:	1c7d                	addi	s8,s8,-1
ffffffffc02013a8:	fee79de3          	bne	a5,a4,ffffffffc02013a2 <vprintfmt+0xae>
ffffffffc02013ac:	bfb5                	j	ffffffffc0201328 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02013ae:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02013b2:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02013b4:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02013b8:	fd06071b          	addiw	a4,a2,-48
ffffffffc02013bc:	24e56a63          	bltu	a0,a4,ffffffffc0201610 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02013c0:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013c2:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02013c4:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02013c8:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02013cc:	0197073b          	addw	a4,a4,s9
ffffffffc02013d0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013d4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013d6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02013da:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013dc:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02013e0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02013e4:	feb570e3          	bgeu	a0,a1,ffffffffc02013c4 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02013e8:	f60d54e3          	bgez	s10,ffffffffc0201350 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02013ec:	8d66                	mv	s10,s9
ffffffffc02013ee:	5cfd                	li	s9,-1
ffffffffc02013f0:	b785                	j	ffffffffc0201350 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013f2:	8db6                	mv	s11,a3
ffffffffc02013f4:	8462                	mv	s0,s8
ffffffffc02013f6:	bfa9                	j	ffffffffc0201350 <vprintfmt+0x5c>
ffffffffc02013f8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02013fa:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02013fc:	bf91                	j	ffffffffc0201350 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02013fe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201400:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201404:	00f74463          	blt	a4,a5,ffffffffc020140c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201408:	1a078763          	beqz	a5,ffffffffc02015b6 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020140c:	000a3603          	ld	a2,0(s4)
ffffffffc0201410:	46c1                	li	a3,16
ffffffffc0201412:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201414:	000d879b          	sext.w	a5,s11
ffffffffc0201418:	876a                	mv	a4,s10
ffffffffc020141a:	85ca                	mv	a1,s2
ffffffffc020141c:	8526                	mv	a0,s1
ffffffffc020141e:	e71ff0ef          	jal	ffffffffc020128e <printnum>
            break;
ffffffffc0201422:	b719                	j	ffffffffc0201328 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201424:	000a2503          	lw	a0,0(s4)
ffffffffc0201428:	85ca                	mv	a1,s2
ffffffffc020142a:	0a21                	addi	s4,s4,8
ffffffffc020142c:	9482                	jalr	s1
            break;
ffffffffc020142e:	bded                	j	ffffffffc0201328 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201430:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201432:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201436:	00f74463          	blt	a4,a5,ffffffffc020143e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020143a:	16078963          	beqz	a5,ffffffffc02015ac <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020143e:	000a3603          	ld	a2,0(s4)
ffffffffc0201442:	46a9                	li	a3,10
ffffffffc0201444:	8a2e                	mv	s4,a1
ffffffffc0201446:	b7f9                	j	ffffffffc0201414 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201448:	85ca                	mv	a1,s2
ffffffffc020144a:	03000513          	li	a0,48
ffffffffc020144e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201450:	85ca                	mv	a1,s2
ffffffffc0201452:	07800513          	li	a0,120
ffffffffc0201456:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201458:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020145c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020145e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201460:	bf55                	j	ffffffffc0201414 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201462:	85ca                	mv	a1,s2
ffffffffc0201464:	02500513          	li	a0,37
ffffffffc0201468:	9482                	jalr	s1
            break;
ffffffffc020146a:	bd7d                	j	ffffffffc0201328 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020146c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201470:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201472:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201474:	bf95                	j	ffffffffc02013e8 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201476:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201478:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020147c:	00f74463          	blt	a4,a5,ffffffffc0201484 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201480:	12078163          	beqz	a5,ffffffffc02015a2 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201484:	000a3603          	ld	a2,0(s4)
ffffffffc0201488:	46a1                	li	a3,8
ffffffffc020148a:	8a2e                	mv	s4,a1
ffffffffc020148c:	b761                	j	ffffffffc0201414 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020148e:	876a                	mv	a4,s10
ffffffffc0201490:	000d5363          	bgez	s10,ffffffffc0201496 <vprintfmt+0x1a2>
ffffffffc0201494:	4701                	li	a4,0
ffffffffc0201496:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020149a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020149c:	bd55                	j	ffffffffc0201350 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020149e:	000d841b          	sext.w	s0,s11
ffffffffc02014a2:	fd340793          	addi	a5,s0,-45
ffffffffc02014a6:	00f037b3          	snez	a5,a5
ffffffffc02014aa:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014ae:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02014b2:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014b4:	008a0793          	addi	a5,s4,8
ffffffffc02014b8:	e43e                	sd	a5,8(sp)
ffffffffc02014ba:	100d8c63          	beqz	s11,ffffffffc02015d2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02014be:	12071363          	bnez	a4,ffffffffc02015e4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014c2:	000dc783          	lbu	a5,0(s11)
ffffffffc02014c6:	0007851b          	sext.w	a0,a5
ffffffffc02014ca:	c78d                	beqz	a5,ffffffffc02014f4 <vprintfmt+0x200>
ffffffffc02014cc:	0d85                	addi	s11,s11,1
ffffffffc02014ce:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014d0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014d4:	000cc563          	bltz	s9,ffffffffc02014de <vprintfmt+0x1ea>
ffffffffc02014d8:	3cfd                	addiw	s9,s9,-1
ffffffffc02014da:	008c8d63          	beq	s9,s0,ffffffffc02014f4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014de:	020b9663          	bnez	s7,ffffffffc020150a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02014e2:	85ca                	mv	a1,s2
ffffffffc02014e4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014e6:	000dc783          	lbu	a5,0(s11)
ffffffffc02014ea:	0d85                	addi	s11,s11,1
ffffffffc02014ec:	3d7d                	addiw	s10,s10,-1
ffffffffc02014ee:	0007851b          	sext.w	a0,a5
ffffffffc02014f2:	f3ed                	bnez	a5,ffffffffc02014d4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02014f4:	01a05963          	blez	s10,ffffffffc0201506 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02014f8:	85ca                	mv	a1,s2
ffffffffc02014fa:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02014fe:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201500:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201502:	fe0d1be3          	bnez	s10,ffffffffc02014f8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201506:	6a22                	ld	s4,8(sp)
ffffffffc0201508:	b505                	j	ffffffffc0201328 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020150a:	3781                	addiw	a5,a5,-32
ffffffffc020150c:	fcfa7be3          	bgeu	s4,a5,ffffffffc02014e2 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201510:	03f00513          	li	a0,63
ffffffffc0201514:	85ca                	mv	a1,s2
ffffffffc0201516:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201518:	000dc783          	lbu	a5,0(s11)
ffffffffc020151c:	0d85                	addi	s11,s11,1
ffffffffc020151e:	3d7d                	addiw	s10,s10,-1
ffffffffc0201520:	0007851b          	sext.w	a0,a5
ffffffffc0201524:	dbe1                	beqz	a5,ffffffffc02014f4 <vprintfmt+0x200>
ffffffffc0201526:	fa0cd9e3          	bgez	s9,ffffffffc02014d8 <vprintfmt+0x1e4>
ffffffffc020152a:	b7c5                	j	ffffffffc020150a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020152c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201530:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201532:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201534:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201538:	8fb9                	xor	a5,a5,a4
ffffffffc020153a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020153e:	02d64563          	blt	a2,a3,ffffffffc0201568 <vprintfmt+0x274>
ffffffffc0201542:	00001797          	auipc	a5,0x1
ffffffffc0201546:	b8e78793          	addi	a5,a5,-1138 # ffffffffc02020d0 <error_string>
ffffffffc020154a:	00369713          	slli	a4,a3,0x3
ffffffffc020154e:	97ba                	add	a5,a5,a4
ffffffffc0201550:	639c                	ld	a5,0(a5)
ffffffffc0201552:	cb99                	beqz	a5,ffffffffc0201568 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201554:	86be                	mv	a3,a5
ffffffffc0201556:	00001617          	auipc	a2,0x1
ffffffffc020155a:	94260613          	addi	a2,a2,-1726 # ffffffffc0201e98 <etext+0x782>
ffffffffc020155e:	85ca                	mv	a1,s2
ffffffffc0201560:	8526                	mv	a0,s1
ffffffffc0201562:	0d8000ef          	jal	ffffffffc020163a <printfmt>
ffffffffc0201566:	b3c9                	j	ffffffffc0201328 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201568:	00001617          	auipc	a2,0x1
ffffffffc020156c:	92060613          	addi	a2,a2,-1760 # ffffffffc0201e88 <etext+0x772>
ffffffffc0201570:	85ca                	mv	a1,s2
ffffffffc0201572:	8526                	mv	a0,s1
ffffffffc0201574:	0c6000ef          	jal	ffffffffc020163a <printfmt>
ffffffffc0201578:	bb45                	j	ffffffffc0201328 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020157a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020157c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201580:	00f74363          	blt	a4,a5,ffffffffc0201586 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201584:	cf81                	beqz	a5,ffffffffc020159c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201586:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020158a:	02044b63          	bltz	s0,ffffffffc02015c0 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020158e:	8622                	mv	a2,s0
ffffffffc0201590:	8a5e                	mv	s4,s7
ffffffffc0201592:	46a9                	li	a3,10
ffffffffc0201594:	b541                	j	ffffffffc0201414 <vprintfmt+0x120>
            lflag ++;
ffffffffc0201596:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201598:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020159a:	bb5d                	j	ffffffffc0201350 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020159c:	000a2403          	lw	s0,0(s4)
ffffffffc02015a0:	b7ed                	j	ffffffffc020158a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02015a2:	000a6603          	lwu	a2,0(s4)
ffffffffc02015a6:	46a1                	li	a3,8
ffffffffc02015a8:	8a2e                	mv	s4,a1
ffffffffc02015aa:	b5ad                	j	ffffffffc0201414 <vprintfmt+0x120>
ffffffffc02015ac:	000a6603          	lwu	a2,0(s4)
ffffffffc02015b0:	46a9                	li	a3,10
ffffffffc02015b2:	8a2e                	mv	s4,a1
ffffffffc02015b4:	b585                	j	ffffffffc0201414 <vprintfmt+0x120>
ffffffffc02015b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02015ba:	46c1                	li	a3,16
ffffffffc02015bc:	8a2e                	mv	s4,a1
ffffffffc02015be:	bd99                	j	ffffffffc0201414 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02015c0:	85ca                	mv	a1,s2
ffffffffc02015c2:	02d00513          	li	a0,45
ffffffffc02015c6:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02015c8:	40800633          	neg	a2,s0
ffffffffc02015cc:	8a5e                	mv	s4,s7
ffffffffc02015ce:	46a9                	li	a3,10
ffffffffc02015d0:	b591                	j	ffffffffc0201414 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02015d2:	e329                	bnez	a4,ffffffffc0201614 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015d4:	02800793          	li	a5,40
ffffffffc02015d8:	853e                	mv	a0,a5
ffffffffc02015da:	00001d97          	auipc	s11,0x1
ffffffffc02015de:	8a7d8d93          	addi	s11,s11,-1881 # ffffffffc0201e81 <etext+0x76b>
ffffffffc02015e2:	b5f5                	j	ffffffffc02014ce <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015e4:	85e6                	mv	a1,s9
ffffffffc02015e6:	856e                	mv	a0,s11
ffffffffc02015e8:	0a4000ef          	jal	ffffffffc020168c <strnlen>
ffffffffc02015ec:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02015f0:	01a05863          	blez	s10,ffffffffc0201600 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02015f4:	85ca                	mv	a1,s2
ffffffffc02015f6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015f8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02015fa:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015fc:	fe0d1ce3          	bnez	s10,ffffffffc02015f4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201600:	000dc783          	lbu	a5,0(s11)
ffffffffc0201604:	0007851b          	sext.w	a0,a5
ffffffffc0201608:	ec0792e3          	bnez	a5,ffffffffc02014cc <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020160c:	6a22                	ld	s4,8(sp)
ffffffffc020160e:	bb29                	j	ffffffffc0201328 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201610:	8462                	mv	s0,s8
ffffffffc0201612:	bbd9                	j	ffffffffc02013e8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201614:	85e6                	mv	a1,s9
ffffffffc0201616:	00001517          	auipc	a0,0x1
ffffffffc020161a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201e80 <etext+0x76a>
ffffffffc020161e:	06e000ef          	jal	ffffffffc020168c <strnlen>
ffffffffc0201622:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201626:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020162a:	00001d97          	auipc	s11,0x1
ffffffffc020162e:	856d8d93          	addi	s11,s11,-1962 # ffffffffc0201e80 <etext+0x76a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201632:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201634:	fda040e3          	bgtz	s10,ffffffffc02015f4 <vprintfmt+0x300>
ffffffffc0201638:	bd51                	j	ffffffffc02014cc <vprintfmt+0x1d8>

ffffffffc020163a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020163a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020163c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201640:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201642:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201644:	ec06                	sd	ra,24(sp)
ffffffffc0201646:	f83a                	sd	a4,48(sp)
ffffffffc0201648:	fc3e                	sd	a5,56(sp)
ffffffffc020164a:	e0c2                	sd	a6,64(sp)
ffffffffc020164c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020164e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201650:	ca5ff0ef          	jal	ffffffffc02012f4 <vprintfmt>
}
ffffffffc0201654:	60e2                	ld	ra,24(sp)
ffffffffc0201656:	6161                	addi	sp,sp,80
ffffffffc0201658:	8082                	ret

ffffffffc020165a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020165a:	00005717          	auipc	a4,0x5
ffffffffc020165e:	9b673703          	ld	a4,-1610(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201662:	4781                	li	a5,0
ffffffffc0201664:	88ba                	mv	a7,a4
ffffffffc0201666:	852a                	mv	a0,a0
ffffffffc0201668:	85be                	mv	a1,a5
ffffffffc020166a:	863e                	mv	a2,a5
ffffffffc020166c:	00000073          	ecall
ffffffffc0201670:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201672:	8082                	ret

ffffffffc0201674 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201674:	00054783          	lbu	a5,0(a0)
ffffffffc0201678:	cb81                	beqz	a5,ffffffffc0201688 <strlen+0x14>
    size_t cnt = 0;
ffffffffc020167a:	4781                	li	a5,0
        cnt ++;
ffffffffc020167c:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc020167e:	00f50733          	add	a4,a0,a5
ffffffffc0201682:	00074703          	lbu	a4,0(a4)
ffffffffc0201686:	fb7d                	bnez	a4,ffffffffc020167c <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201688:	853e                	mv	a0,a5
ffffffffc020168a:	8082                	ret

ffffffffc020168c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020168c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020168e:	e589                	bnez	a1,ffffffffc0201698 <strnlen+0xc>
ffffffffc0201690:	a811                	j	ffffffffc02016a4 <strnlen+0x18>
        cnt ++;
ffffffffc0201692:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201694:	00f58863          	beq	a1,a5,ffffffffc02016a4 <strnlen+0x18>
ffffffffc0201698:	00f50733          	add	a4,a0,a5
ffffffffc020169c:	00074703          	lbu	a4,0(a4)
ffffffffc02016a0:	fb6d                	bnez	a4,ffffffffc0201692 <strnlen+0x6>
ffffffffc02016a2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02016a4:	852e                	mv	a0,a1
ffffffffc02016a6:	8082                	ret

ffffffffc02016a8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016a8:	00054783          	lbu	a5,0(a0)
ffffffffc02016ac:	e791                	bnez	a5,ffffffffc02016b8 <strcmp+0x10>
ffffffffc02016ae:	a01d                	j	ffffffffc02016d4 <strcmp+0x2c>
ffffffffc02016b0:	00054783          	lbu	a5,0(a0)
ffffffffc02016b4:	cb99                	beqz	a5,ffffffffc02016ca <strcmp+0x22>
ffffffffc02016b6:	0585                	addi	a1,a1,1
ffffffffc02016b8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02016bc:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016be:	fef709e3          	beq	a4,a5,ffffffffc02016b0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016c2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02016c6:	9d19                	subw	a0,a0,a4
ffffffffc02016c8:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016ca:	0015c703          	lbu	a4,1(a1)
ffffffffc02016ce:	4501                	li	a0,0
}
ffffffffc02016d0:	9d19                	subw	a0,a0,a4
ffffffffc02016d2:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016d4:	0005c703          	lbu	a4,0(a1)
ffffffffc02016d8:	4501                	li	a0,0
ffffffffc02016da:	b7f5                	j	ffffffffc02016c6 <strcmp+0x1e>

ffffffffc02016dc <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016dc:	ce01                	beqz	a2,ffffffffc02016f4 <strncmp+0x18>
ffffffffc02016de:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02016e2:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016e4:	cb91                	beqz	a5,ffffffffc02016f8 <strncmp+0x1c>
ffffffffc02016e6:	0005c703          	lbu	a4,0(a1)
ffffffffc02016ea:	00f71763          	bne	a4,a5,ffffffffc02016f8 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02016ee:	0505                	addi	a0,a0,1
ffffffffc02016f0:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016f2:	f675                	bnez	a2,ffffffffc02016de <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016f4:	4501                	li	a0,0
ffffffffc02016f6:	8082                	ret
ffffffffc02016f8:	00054503          	lbu	a0,0(a0)
ffffffffc02016fc:	0005c783          	lbu	a5,0(a1)
ffffffffc0201700:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201702:	8082                	ret

ffffffffc0201704 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201704:	ca01                	beqz	a2,ffffffffc0201714 <memset+0x10>
ffffffffc0201706:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201708:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020170a:	0785                	addi	a5,a5,1
ffffffffc020170c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201710:	fef61de3          	bne	a2,a5,ffffffffc020170a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201714:	8082                	ret
