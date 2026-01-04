
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

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
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0203ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	60c50513          	addi	a0,a0,1548 # ffffffffc0201658 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	61650513          	addi	a0,a0,1558 # ffffffffc0201678 <etext+0x22>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5e858593          	addi	a1,a1,1512 # ffffffffc0201656 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	62250513          	addi	a0,a0,1570 # ffffffffc0201698 <etext+0x42>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	62e50513          	addi	a0,a0,1582 # ffffffffc02016b8 <etext+0x62>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	63a50513          	addi	a0,a0,1594 # ffffffffc02016d8 <etext+0x82>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00005797          	auipc	a5,0x5
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0205477 <end+0x3ff>
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
ffffffffc02000ce:	62e50513          	addi	a0,a0,1582 # ffffffffc02016f8 <etext+0xa2>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00005517          	auipc	a0,0x5
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0205018 <free_area>
ffffffffc02000de:	00005617          	auipc	a2,0x5
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	556010ef          	jal	ffffffffc0201644 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	cee50513          	addi	a0,a0,-786 # ffffffffc0201de8 <etext+0x792>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	6f1000ef          	jal	ffffffffc0200ffa <pmm_init>

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
ffffffffc020013c:	0f8010ef          	jal	ffffffffc0201234 <vprintfmt>
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
ffffffffc0200170:	0c4010ef          	jal	ffffffffc0201234 <vprintfmt>
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
ffffffffc02001c8:	00005317          	auipc	t1,0x5
ffffffffc02001cc:	e6832303          	lw	t1,-408(t1) # ffffffffc0205030 <is_panic>
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
ffffffffc02001f4:	53850513          	addi	a0,a0,1336 # ffffffffc0201728 <etext+0xd2>
    is_panic = 1;
ffffffffc02001f8:	00005697          	auipc	a3,0x5
ffffffffc02001fc:	e2e6ac23          	sw	a4,-456(a3) # ffffffffc0205030 <is_panic>
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
ffffffffc0200212:	53a50513          	addi	a0,a0,1338 # ffffffffc0201748 <etext+0xf2>
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
ffffffffc0200224:	3760106f          	j	ffffffffc020159a <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	52650513          	addi	a0,a0,1318 # ffffffffc0201750 <etext+0xfa>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00005597          	auipc	a1,0x5
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	51e50513          	addi	a0,a0,1310 # ffffffffc0201760 <etext+0x10a>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00005417          	auipc	s0,0x5
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0205008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	51850513          	addi	a0,a0,1304 # ffffffffc0201770 <etext+0x11a>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	52250513          	addi	a0,a0,1314 # ffffffffc0201788 <etext+0x132>
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
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfedae75>
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
ffffffffc020035c:	4f850513          	addi	a0,a0,1272 # ffffffffc0201850 <etext+0x1fa>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	52050513          	addi	a0,a0,1312 # ffffffffc0201888 <etext+0x232>
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
ffffffffc0200380:	42c50513          	addi	a0,a0,1068 # ffffffffc02017a8 <etext+0x152>
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
ffffffffc02003c2:	1f2010ef          	jal	ffffffffc02015b4 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	40458593          	addi	a1,a1,1028 # ffffffffc02017d0 <etext+0x17a>
ffffffffc02003d4:	248010ef          	jal	ffffffffc020161c <strncmp>
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
ffffffffc02003fc:	3e058593          	addi	a1,a1,992 # ffffffffc02017d8 <etext+0x182>
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
ffffffffc020042e:	1ba010ef          	jal	ffffffffc02015e8 <strcmp>
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
ffffffffc0200452:	39250513          	addi	a0,a0,914 # ffffffffc02017e0 <etext+0x18a>
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
ffffffffc020051c:	2e850513          	addi	a0,a0,744 # ffffffffc0201800 <etext+0x1aa>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	2ee50513          	addi	a0,a0,750 # ffffffffc0201818 <etext+0x1c2>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	2fc50513          	addi	a0,a0,764 # ffffffffc0201838 <etext+0x1e2>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00005797          	auipc	a5,0x5
ffffffffc020054c:	ae97bc23          	sd	s1,-1288(a5) # ffffffffc0205040 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00005797          	auipc	a5,0x5
ffffffffc0200554:	ae87b423          	sd	s0,-1304(a5) # ffffffffc0205038 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00005517          	auipc	a0,0x5
ffffffffc020055e:	ae653503          	ld	a0,-1306(a0) # ffffffffc0205040 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00005517          	auipc	a0,0x5
ffffffffc0200568:	ad453503          	ld	a0,-1324(a0) # ffffffffc0205038 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020056e:	00005797          	auipc	a5,0x5
ffffffffc0200572:	aaa78793          	addi	a5,a5,-1366 # ffffffffc0205018 <free_area>
ffffffffc0200576:	e79c                	sd	a5,8(a5)
ffffffffc0200578:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020057a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020057e:	8082                	ret

ffffffffc0200580 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200580:	00005517          	auipc	a0,0x5
ffffffffc0200584:	aa856503          	lwu	a0,-1368(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200588:	8082                	ret

ffffffffc020058a <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020058a:	c545                	beqz	a0,ffffffffc0200632 <best_fit_alloc_pages+0xa8>
    if (n > nr_free) {
ffffffffc020058c:	00005897          	auipc	a7,0x5
ffffffffc0200590:	a9c8a883          	lw	a7,-1380(a7) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200594:	862a                	mv	a2,a0
ffffffffc0200596:	00005597          	auipc	a1,0x5
ffffffffc020059a:	a8258593          	addi	a1,a1,-1406 # ffffffffc0205018 <free_area>
ffffffffc020059e:	02089793          	slli	a5,a7,0x20
ffffffffc02005a2:	9381                	srli	a5,a5,0x20
ffffffffc02005a4:	08a7e563          	bltu	a5,a0,ffffffffc020062e <best_fit_alloc_pages+0xa4>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005a8:	659c                	ld	a5,8(a1)
    struct Page *best_page = NULL;
ffffffffc02005aa:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ac:	08b78063          	beq	a5,a1,ffffffffc020062c <best_fit_alloc_pages+0xa2>
    int best_n = -1;
ffffffffc02005b0:	587d                	li	a6,-1
        if (p->property >= n) 
ffffffffc02005b2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02005b6:	02071693          	slli	a3,a4,0x20
ffffffffc02005ba:	9281                	srli	a3,a3,0x20
ffffffffc02005bc:	00c6ea63          	bltu	a3,a2,ffffffffc02005d0 <best_fit_alloc_pages+0x46>
            if(best_n == -1 || best_n > p->property)
ffffffffc02005c0:	01076563          	bltu	a4,a6,ffffffffc02005ca <best_fit_alloc_pages+0x40>
ffffffffc02005c4:	00180693          	addi	a3,a6,1 # ff0001 <kern_entry-0xffffffffbf20ffff>
ffffffffc02005c8:	e681                	bnez	a3,ffffffffc02005d0 <best_fit_alloc_pages+0x46>
                best_n = p->property;
ffffffffc02005ca:	883a                	mv	a6,a4
        struct Page *p = le2page(le, page_link);
ffffffffc02005cc:	fe878513          	addi	a0,a5,-24
ffffffffc02005d0:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005d2:	feb790e3          	bne	a5,a1,ffffffffc02005b2 <best_fit_alloc_pages+0x28>
    if (page != NULL) {
ffffffffc02005d6:	c939                	beqz	a0,ffffffffc020062c <best_fit_alloc_pages+0xa2>
        if (page->property > n) {
ffffffffc02005d8:	01052803          	lw	a6,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005dc:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02005de:	7114                	ld	a3,32(a0)
ffffffffc02005e0:	02081793          	slli	a5,a6,0x20
ffffffffc02005e4:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02005e6:	e714                	sd	a3,8(a4)
    next->prev = prev;
ffffffffc02005e8:	e298                	sd	a4,0(a3)
ffffffffc02005ea:	02f67963          	bgeu	a2,a5,ffffffffc020061c <best_fit_alloc_pages+0x92>
            struct Page *p = page + n;
ffffffffc02005ee:	00261793          	slli	a5,a2,0x2
ffffffffc02005f2:	97b2                	add	a5,a5,a2
ffffffffc02005f4:	078e                	slli	a5,a5,0x3
ffffffffc02005f6:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc02005f8:	0087b303          	ld	t1,8(a5)
            p->property = page->property - n;
ffffffffc02005fc:	40c8083b          	subw	a6,a6,a2
ffffffffc0200600:	0107a823          	sw	a6,16(a5)
            SetPageProperty(p);
ffffffffc0200604:	00236813          	ori	a6,t1,2
ffffffffc0200608:	0107b423          	sd	a6,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020060c:	01878813          	addi	a6,a5,24
    prev->next = next->prev = elm;
ffffffffc0200610:	0106b023          	sd	a6,0(a3)
ffffffffc0200614:	01073423          	sd	a6,8(a4)
    elm->next = next;
ffffffffc0200618:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc020061a:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc020061c:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020061e:	40c888bb          	subw	a7,a7,a2
ffffffffc0200622:	0115a823          	sw	a7,16(a1)
        ClearPageProperty(page);
ffffffffc0200626:	9bf5                	andi	a5,a5,-3
ffffffffc0200628:	e51c                	sd	a5,8(a0)
ffffffffc020062a:	8082                	ret
}
ffffffffc020062c:	8082                	ret
        return NULL;
ffffffffc020062e:	4501                	li	a0,0
ffffffffc0200630:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200632:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200634:	00001697          	auipc	a3,0x1
ffffffffc0200638:	26c68693          	addi	a3,a3,620 # ffffffffc02018a0 <etext+0x24a>
ffffffffc020063c:	00001617          	auipc	a2,0x1
ffffffffc0200640:	26c60613          	addi	a2,a2,620 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200644:	06d00593          	li	a1,109
ffffffffc0200648:	00001517          	auipc	a0,0x1
ffffffffc020064c:	27850513          	addi	a0,a0,632 # ffffffffc02018c0 <etext+0x26a>
best_fit_alloc_pages(size_t n) {
ffffffffc0200650:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200652:	b77ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200656 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200656:	711d                	addi	sp,sp,-96
ffffffffc0200658:	e0ca                	sd	s2,64(sp)
    return listelm->next;
ffffffffc020065a:	00005917          	auipc	s2,0x5
ffffffffc020065e:	9be90913          	addi	s2,s2,-1602 # ffffffffc0205018 <free_area>
ffffffffc0200662:	00893783          	ld	a5,8(s2)
ffffffffc0200666:	ec86                	sd	ra,88(sp)
ffffffffc0200668:	e8a2                	sd	s0,80(sp)
ffffffffc020066a:	e4a6                	sd	s1,72(sp)
ffffffffc020066c:	fc4e                	sd	s3,56(sp)
ffffffffc020066e:	f852                	sd	s4,48(sp)
ffffffffc0200670:	f456                	sd	s5,40(sp)
ffffffffc0200672:	f05a                	sd	s6,32(sp)
ffffffffc0200674:	ec5e                	sd	s7,24(sp)
ffffffffc0200676:	e862                	sd	s8,16(sp)
ffffffffc0200678:	e466                	sd	s9,8(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020067a:	2b278f63          	beq	a5,s2,ffffffffc0200938 <best_fit_check+0x2e2>
    int count = 0, total = 0;
ffffffffc020067e:	4401                	li	s0,0
ffffffffc0200680:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200682:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200686:	8b09                	andi	a4,a4,2
ffffffffc0200688:	2a070c63          	beqz	a4,ffffffffc0200940 <best_fit_check+0x2ea>
        count ++, total += p->property;
ffffffffc020068c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200690:	679c                	ld	a5,8(a5)
ffffffffc0200692:	2485                	addiw	s1,s1,1
ffffffffc0200694:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200696:	ff2796e3          	bne	a5,s2,ffffffffc0200682 <best_fit_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc020069a:	89a2                	mv	s3,s0
ffffffffc020069c:	153000ef          	jal	ffffffffc0200fee <nr_free_pages>
ffffffffc02006a0:	39351063          	bne	a0,s3,ffffffffc0200a20 <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006a4:	4505                	li	a0,1
ffffffffc02006a6:	131000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02006aa:	8aaa                	mv	s5,a0
ffffffffc02006ac:	3a050a63          	beqz	a0,ffffffffc0200a60 <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006b0:	4505                	li	a0,1
ffffffffc02006b2:	125000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02006b6:	89aa                	mv	s3,a0
ffffffffc02006b8:	38050463          	beqz	a0,ffffffffc0200a40 <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006bc:	4505                	li	a0,1
ffffffffc02006be:	119000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02006c2:	8a2a                	mv	s4,a0
ffffffffc02006c4:	30050e63          	beqz	a0,ffffffffc02009e0 <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006c8:	40aa87b3          	sub	a5,s5,a0
ffffffffc02006cc:	40a98733          	sub	a4,s3,a0
ffffffffc02006d0:	0017b793          	seqz	a5,a5
ffffffffc02006d4:	00173713          	seqz	a4,a4
ffffffffc02006d8:	8fd9                	or	a5,a5,a4
ffffffffc02006da:	2e079363          	bnez	a5,ffffffffc02009c0 <best_fit_check+0x36a>
ffffffffc02006de:	2f3a8163          	beq	s5,s3,ffffffffc02009c0 <best_fit_check+0x36a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02006e2:	000aa783          	lw	a5,0(s5)
ffffffffc02006e6:	26079d63          	bnez	a5,ffffffffc0200960 <best_fit_check+0x30a>
ffffffffc02006ea:	0009a783          	lw	a5,0(s3)
ffffffffc02006ee:	26079963          	bnez	a5,ffffffffc0200960 <best_fit_check+0x30a>
ffffffffc02006f2:	411c                	lw	a5,0(a0)
ffffffffc02006f4:	26079663          	bnez	a5,ffffffffc0200960 <best_fit_check+0x30a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02006f8:	00005797          	auipc	a5,0x5
ffffffffc02006fc:	9787b783          	ld	a5,-1672(a5) # ffffffffc0205070 <pages>
ffffffffc0200700:	ccccd737          	lui	a4,0xccccd
ffffffffc0200704:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac7c55>
ffffffffc0200708:	02071693          	slli	a3,a4,0x20
ffffffffc020070c:	96ba                	add	a3,a3,a4
ffffffffc020070e:	40fa8733          	sub	a4,s5,a5
ffffffffc0200712:	870d                	srai	a4,a4,0x3
ffffffffc0200714:	02d70733          	mul	a4,a4,a3
ffffffffc0200718:	00002517          	auipc	a0,0x2
ffffffffc020071c:	8b853503          	ld	a0,-1864(a0) # ffffffffc0201fd0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200720:	00005697          	auipc	a3,0x5
ffffffffc0200724:	9486b683          	ld	a3,-1720(a3) # ffffffffc0205068 <npage>
ffffffffc0200728:	06b2                	slli	a3,a3,0xc
ffffffffc020072a:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc020072c:	0732                	slli	a4,a4,0xc
ffffffffc020072e:	26d77963          	bgeu	a4,a3,ffffffffc02009a0 <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200732:	ccccd5b7          	lui	a1,0xccccd
ffffffffc0200736:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac7c55>
ffffffffc020073a:	02059613          	slli	a2,a1,0x20
ffffffffc020073e:	40f98733          	sub	a4,s3,a5
ffffffffc0200742:	962e                	add	a2,a2,a1
ffffffffc0200744:	870d                	srai	a4,a4,0x3
ffffffffc0200746:	02c70733          	mul	a4,a4,a2
ffffffffc020074a:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020074c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020074e:	40d77963          	bgeu	a4,a3,ffffffffc0200b60 <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200752:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200756:	878d                	srai	a5,a5,0x3
ffffffffc0200758:	02c787b3          	mul	a5,a5,a2
ffffffffc020075c:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020075e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200760:	3ed7f063          	bgeu	a5,a3,ffffffffc0200b40 <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc0200764:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200766:	00093c03          	ld	s8,0(s2)
ffffffffc020076a:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc020076e:	00005b17          	auipc	s6,0x5
ffffffffc0200772:	8bab2b03          	lw	s6,-1862(s6) # ffffffffc0205028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200776:	01293023          	sd	s2,0(s2)
ffffffffc020077a:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc020077e:	00005797          	auipc	a5,0x5
ffffffffc0200782:	8a07a523          	sw	zero,-1878(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200786:	051000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc020078a:	38051b63          	bnez	a0,ffffffffc0200b20 <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc020078e:	8556                	mv	a0,s5
ffffffffc0200790:	4585                	li	a1,1
ffffffffc0200792:	051000ef          	jal	ffffffffc0200fe2 <free_pages>
    free_page(p1);
ffffffffc0200796:	854e                	mv	a0,s3
ffffffffc0200798:	4585                	li	a1,1
ffffffffc020079a:	049000ef          	jal	ffffffffc0200fe2 <free_pages>
    free_page(p2);
ffffffffc020079e:	8552                	mv	a0,s4
ffffffffc02007a0:	4585                	li	a1,1
ffffffffc02007a2:	041000ef          	jal	ffffffffc0200fe2 <free_pages>
    assert(nr_free == 3);
ffffffffc02007a6:	00005717          	auipc	a4,0x5
ffffffffc02007aa:	88272703          	lw	a4,-1918(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc02007ae:	478d                	li	a5,3
ffffffffc02007b0:	34f71863          	bne	a4,a5,ffffffffc0200b00 <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007b4:	4505                	li	a0,1
ffffffffc02007b6:	021000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02007ba:	89aa                	mv	s3,a0
ffffffffc02007bc:	32050263          	beqz	a0,ffffffffc0200ae0 <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007c0:	4505                	li	a0,1
ffffffffc02007c2:	015000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02007c6:	8aaa                	mv	s5,a0
ffffffffc02007c8:	2e050c63          	beqz	a0,ffffffffc0200ac0 <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007cc:	4505                	li	a0,1
ffffffffc02007ce:	009000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02007d2:	8a2a                	mv	s4,a0
ffffffffc02007d4:	2c050663          	beqz	a0,ffffffffc0200aa0 <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc02007d8:	4505                	li	a0,1
ffffffffc02007da:	7fc000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02007de:	2a051163          	bnez	a0,ffffffffc0200a80 <best_fit_check+0x42a>
    free_page(p0);
ffffffffc02007e2:	4585                	li	a1,1
ffffffffc02007e4:	854e                	mv	a0,s3
ffffffffc02007e6:	7fc000ef          	jal	ffffffffc0200fe2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02007ea:	00893783          	ld	a5,8(s2)
ffffffffc02007ee:	19278963          	beq	a5,s2,ffffffffc0200980 <best_fit_check+0x32a>
    assert((p = alloc_page()) == p0);
ffffffffc02007f2:	4505                	li	a0,1
ffffffffc02007f4:	7e2000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02007f8:	8caa                	mv	s9,a0
ffffffffc02007fa:	54a99363          	bne	s3,a0,ffffffffc0200d40 <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc02007fe:	4505                	li	a0,1
ffffffffc0200800:	7d6000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc0200804:	50051e63          	bnez	a0,ffffffffc0200d20 <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc0200808:	00005797          	auipc	a5,0x5
ffffffffc020080c:	8207a783          	lw	a5,-2016(a5) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200810:	4e079863          	bnez	a5,ffffffffc0200d00 <best_fit_check+0x6aa>
    free_page(p);
ffffffffc0200814:	8566                	mv	a0,s9
ffffffffc0200816:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200818:	01893023          	sd	s8,0(s2)
ffffffffc020081c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200820:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200824:	7be000ef          	jal	ffffffffc0200fe2 <free_pages>
    free_page(p1);
ffffffffc0200828:	8556                	mv	a0,s5
ffffffffc020082a:	4585                	li	a1,1
ffffffffc020082c:	7b6000ef          	jal	ffffffffc0200fe2 <free_pages>
    free_page(p2);
ffffffffc0200830:	8552                	mv	a0,s4
ffffffffc0200832:	4585                	li	a1,1
ffffffffc0200834:	7ae000ef          	jal	ffffffffc0200fe2 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200838:	4515                	li	a0,5
ffffffffc020083a:	79c000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc020083e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200840:	4a050063          	beqz	a0,ffffffffc0200ce0 <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc0200844:	651c                	ld	a5,8(a0)
ffffffffc0200846:	8b89                	andi	a5,a5,2
ffffffffc0200848:	46079c63          	bnez	a5,ffffffffc0200cc0 <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020084c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020084e:	00093b83          	ld	s7,0(s2)
ffffffffc0200852:	00893b03          	ld	s6,8(s2)
ffffffffc0200856:	01293023          	sd	s2,0(s2)
ffffffffc020085a:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc020085e:	778000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc0200862:	42051f63          	bnez	a0,ffffffffc0200ca0 <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200866:	4589                	li	a1,2
ffffffffc0200868:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc020086c:	00004c17          	auipc	s8,0x4
ffffffffc0200870:	7bcc2c03          	lw	s8,1980(s8) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 4, 1);
ffffffffc0200874:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc0200878:	00004797          	auipc	a5,0x4
ffffffffc020087c:	7a07a823          	sw	zero,1968(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200880:	762000ef          	jal	ffffffffc0200fe2 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200884:	8556                	mv	a0,s5
ffffffffc0200886:	4585                	li	a1,1
ffffffffc0200888:	75a000ef          	jal	ffffffffc0200fe2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020088c:	4511                	li	a0,4
ffffffffc020088e:	748000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc0200892:	3e051763          	bnez	a0,ffffffffc0200c80 <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200896:	0309b783          	ld	a5,48(s3)
ffffffffc020089a:	8b89                	andi	a5,a5,2
ffffffffc020089c:	3c078263          	beqz	a5,ffffffffc0200c60 <best_fit_check+0x60a>
ffffffffc02008a0:	0389ac83          	lw	s9,56(s3)
ffffffffc02008a4:	4789                	li	a5,2
ffffffffc02008a6:	3afc9d63          	bne	s9,a5,ffffffffc0200c60 <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008aa:	4505                	li	a0,1
ffffffffc02008ac:	72a000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02008b0:	8a2a                	mv	s4,a0
ffffffffc02008b2:	38050763          	beqz	a0,ffffffffc0200c40 <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008b6:	8566                	mv	a0,s9
ffffffffc02008b8:	71e000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02008bc:	36050263          	beqz	a0,ffffffffc0200c20 <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc02008c0:	354a9063          	bne	s5,s4,ffffffffc0200c00 <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008c4:	854e                	mv	a0,s3
ffffffffc02008c6:	4595                	li	a1,5
ffffffffc02008c8:	71a000ef          	jal	ffffffffc0200fe2 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008cc:	4515                	li	a0,5
ffffffffc02008ce:	708000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02008d2:	89aa                	mv	s3,a0
ffffffffc02008d4:	30050663          	beqz	a0,ffffffffc0200be0 <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc02008d8:	4505                	li	a0,1
ffffffffc02008da:	6fc000ef          	jal	ffffffffc0200fd6 <alloc_pages>
ffffffffc02008de:	2e051163          	bnez	a0,ffffffffc0200bc0 <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008e2:	00004797          	auipc	a5,0x4
ffffffffc02008e6:	7467a783          	lw	a5,1862(a5) # ffffffffc0205028 <free_area+0x10>
ffffffffc02008ea:	2a079b63          	bnez	a5,ffffffffc0200ba0 <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008ee:	854e                	mv	a0,s3
ffffffffc02008f0:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc02008f2:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc02008f6:	01793023          	sd	s7,0(s2)
ffffffffc02008fa:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc02008fe:	6e4000ef          	jal	ffffffffc0200fe2 <free_pages>
    return listelm->next;
ffffffffc0200902:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200906:	01278963          	beq	a5,s2,ffffffffc0200918 <best_fit_check+0x2c2>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020090a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020090e:	679c                	ld	a5,8(a5)
ffffffffc0200910:	34fd                	addiw	s1,s1,-1
ffffffffc0200912:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200914:	ff279be3          	bne	a5,s2,ffffffffc020090a <best_fit_check+0x2b4>
    }
    assert(count == 0);
ffffffffc0200918:	26049463          	bnez	s1,ffffffffc0200b80 <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc020091c:	e075                	bnez	s0,ffffffffc0200a00 <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc020091e:	60e6                	ld	ra,88(sp)
ffffffffc0200920:	6446                	ld	s0,80(sp)
ffffffffc0200922:	64a6                	ld	s1,72(sp)
ffffffffc0200924:	6906                	ld	s2,64(sp)
ffffffffc0200926:	79e2                	ld	s3,56(sp)
ffffffffc0200928:	7a42                	ld	s4,48(sp)
ffffffffc020092a:	7aa2                	ld	s5,40(sp)
ffffffffc020092c:	7b02                	ld	s6,32(sp)
ffffffffc020092e:	6be2                	ld	s7,24(sp)
ffffffffc0200930:	6c42                	ld	s8,16(sp)
ffffffffc0200932:	6ca2                	ld	s9,8(sp)
ffffffffc0200934:	6125                	addi	sp,sp,96
ffffffffc0200936:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200938:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020093a:	4401                	li	s0,0
ffffffffc020093c:	4481                	li	s1,0
ffffffffc020093e:	bbb9                	j	ffffffffc020069c <best_fit_check+0x46>
        assert(PageProperty(p));
ffffffffc0200940:	00001697          	auipc	a3,0x1
ffffffffc0200944:	f9868693          	addi	a3,a3,-104 # ffffffffc02018d8 <etext+0x282>
ffffffffc0200948:	00001617          	auipc	a2,0x1
ffffffffc020094c:	f6060613          	addi	a2,a2,-160 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200950:	11800593          	li	a1,280
ffffffffc0200954:	00001517          	auipc	a0,0x1
ffffffffc0200958:	f6c50513          	addi	a0,a0,-148 # ffffffffc02018c0 <etext+0x26a>
ffffffffc020095c:	86dff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200960:	00001697          	auipc	a3,0x1
ffffffffc0200964:	03068693          	addi	a3,a3,48 # ffffffffc0201990 <etext+0x33a>
ffffffffc0200968:	00001617          	auipc	a2,0x1
ffffffffc020096c:	f4060613          	addi	a2,a2,-192 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200970:	0e500593          	li	a1,229
ffffffffc0200974:	00001517          	auipc	a0,0x1
ffffffffc0200978:	f4c50513          	addi	a0,a0,-180 # ffffffffc02018c0 <etext+0x26a>
ffffffffc020097c:	84dff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200980:	00001697          	auipc	a3,0x1
ffffffffc0200984:	0d868693          	addi	a3,a3,216 # ffffffffc0201a58 <etext+0x402>
ffffffffc0200988:	00001617          	auipc	a2,0x1
ffffffffc020098c:	f2060613          	addi	a2,a2,-224 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200990:	10000593          	li	a1,256
ffffffffc0200994:	00001517          	auipc	a0,0x1
ffffffffc0200998:	f2c50513          	addi	a0,a0,-212 # ffffffffc02018c0 <etext+0x26a>
ffffffffc020099c:	82dff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009a0:	00001697          	auipc	a3,0x1
ffffffffc02009a4:	03068693          	addi	a3,a3,48 # ffffffffc02019d0 <etext+0x37a>
ffffffffc02009a8:	00001617          	auipc	a2,0x1
ffffffffc02009ac:	f0060613          	addi	a2,a2,-256 # ffffffffc02018a8 <etext+0x252>
ffffffffc02009b0:	0e700593          	li	a1,231
ffffffffc02009b4:	00001517          	auipc	a0,0x1
ffffffffc02009b8:	f0c50513          	addi	a0,a0,-244 # ffffffffc02018c0 <etext+0x26a>
ffffffffc02009bc:	80dff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009c0:	00001697          	auipc	a3,0x1
ffffffffc02009c4:	fa868693          	addi	a3,a3,-88 # ffffffffc0201968 <etext+0x312>
ffffffffc02009c8:	00001617          	auipc	a2,0x1
ffffffffc02009cc:	ee060613          	addi	a2,a2,-288 # ffffffffc02018a8 <etext+0x252>
ffffffffc02009d0:	0e400593          	li	a1,228
ffffffffc02009d4:	00001517          	auipc	a0,0x1
ffffffffc02009d8:	eec50513          	addi	a0,a0,-276 # ffffffffc02018c0 <etext+0x26a>
ffffffffc02009dc:	fecff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e0:	00001697          	auipc	a3,0x1
ffffffffc02009e4:	f6868693          	addi	a3,a3,-152 # ffffffffc0201948 <etext+0x2f2>
ffffffffc02009e8:	00001617          	auipc	a2,0x1
ffffffffc02009ec:	ec060613          	addi	a2,a2,-320 # ffffffffc02018a8 <etext+0x252>
ffffffffc02009f0:	0e200593          	li	a1,226
ffffffffc02009f4:	00001517          	auipc	a0,0x1
ffffffffc02009f8:	ecc50513          	addi	a0,a0,-308 # ffffffffc02018c0 <etext+0x26a>
ffffffffc02009fc:	fccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc0200a00:	00001697          	auipc	a3,0x1
ffffffffc0200a04:	18868693          	addi	a3,a3,392 # ffffffffc0201b88 <etext+0x532>
ffffffffc0200a08:	00001617          	auipc	a2,0x1
ffffffffc0200a0c:	ea060613          	addi	a2,a2,-352 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200a10:	15a00593          	li	a1,346
ffffffffc0200a14:	00001517          	auipc	a0,0x1
ffffffffc0200a18:	eac50513          	addi	a0,a0,-340 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200a1c:	facff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a20:	00001697          	auipc	a3,0x1
ffffffffc0200a24:	ec868693          	addi	a3,a3,-312 # ffffffffc02018e8 <etext+0x292>
ffffffffc0200a28:	00001617          	auipc	a2,0x1
ffffffffc0200a2c:	e8060613          	addi	a2,a2,-384 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200a30:	11b00593          	li	a1,283
ffffffffc0200a34:	00001517          	auipc	a0,0x1
ffffffffc0200a38:	e8c50513          	addi	a0,a0,-372 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200a3c:	f8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a40:	00001697          	auipc	a3,0x1
ffffffffc0200a44:	ee868693          	addi	a3,a3,-280 # ffffffffc0201928 <etext+0x2d2>
ffffffffc0200a48:	00001617          	auipc	a2,0x1
ffffffffc0200a4c:	e6060613          	addi	a2,a2,-416 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200a50:	0e100593          	li	a1,225
ffffffffc0200a54:	00001517          	auipc	a0,0x1
ffffffffc0200a58:	e6c50513          	addi	a0,a0,-404 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200a5c:	f6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a60:	00001697          	auipc	a3,0x1
ffffffffc0200a64:	ea868693          	addi	a3,a3,-344 # ffffffffc0201908 <etext+0x2b2>
ffffffffc0200a68:	00001617          	auipc	a2,0x1
ffffffffc0200a6c:	e4060613          	addi	a2,a2,-448 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200a70:	0e000593          	li	a1,224
ffffffffc0200a74:	00001517          	auipc	a0,0x1
ffffffffc0200a78:	e4c50513          	addi	a0,a0,-436 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200a7c:	f4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a80:	00001697          	auipc	a3,0x1
ffffffffc0200a84:	fb068693          	addi	a3,a3,-80 # ffffffffc0201a30 <etext+0x3da>
ffffffffc0200a88:	00001617          	auipc	a2,0x1
ffffffffc0200a8c:	e2060613          	addi	a2,a2,-480 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200a90:	0fd00593          	li	a1,253
ffffffffc0200a94:	00001517          	auipc	a0,0x1
ffffffffc0200a98:	e2c50513          	addi	a0,a0,-468 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200a9c:	f2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aa0:	00001697          	auipc	a3,0x1
ffffffffc0200aa4:	ea868693          	addi	a3,a3,-344 # ffffffffc0201948 <etext+0x2f2>
ffffffffc0200aa8:	00001617          	auipc	a2,0x1
ffffffffc0200aac:	e0060613          	addi	a2,a2,-512 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200ab0:	0fb00593          	li	a1,251
ffffffffc0200ab4:	00001517          	auipc	a0,0x1
ffffffffc0200ab8:	e0c50513          	addi	a0,a0,-500 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200abc:	f0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ac0:	00001697          	auipc	a3,0x1
ffffffffc0200ac4:	e6868693          	addi	a3,a3,-408 # ffffffffc0201928 <etext+0x2d2>
ffffffffc0200ac8:	00001617          	auipc	a2,0x1
ffffffffc0200acc:	de060613          	addi	a2,a2,-544 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200ad0:	0fa00593          	li	a1,250
ffffffffc0200ad4:	00001517          	auipc	a0,0x1
ffffffffc0200ad8:	dec50513          	addi	a0,a0,-532 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200adc:	eecff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ae0:	00001697          	auipc	a3,0x1
ffffffffc0200ae4:	e2868693          	addi	a3,a3,-472 # ffffffffc0201908 <etext+0x2b2>
ffffffffc0200ae8:	00001617          	auipc	a2,0x1
ffffffffc0200aec:	dc060613          	addi	a2,a2,-576 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200af0:	0f900593          	li	a1,249
ffffffffc0200af4:	00001517          	auipc	a0,0x1
ffffffffc0200af8:	dcc50513          	addi	a0,a0,-564 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200afc:	eccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc0200b00:	00001697          	auipc	a3,0x1
ffffffffc0200b04:	f4868693          	addi	a3,a3,-184 # ffffffffc0201a48 <etext+0x3f2>
ffffffffc0200b08:	00001617          	auipc	a2,0x1
ffffffffc0200b0c:	da060613          	addi	a2,a2,-608 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200b10:	0f700593          	li	a1,247
ffffffffc0200b14:	00001517          	auipc	a0,0x1
ffffffffc0200b18:	dac50513          	addi	a0,a0,-596 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200b1c:	eacff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b20:	00001697          	auipc	a3,0x1
ffffffffc0200b24:	f1068693          	addi	a3,a3,-240 # ffffffffc0201a30 <etext+0x3da>
ffffffffc0200b28:	00001617          	auipc	a2,0x1
ffffffffc0200b2c:	d8060613          	addi	a2,a2,-640 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200b30:	0f200593          	li	a1,242
ffffffffc0200b34:	00001517          	auipc	a0,0x1
ffffffffc0200b38:	d8c50513          	addi	a0,a0,-628 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200b3c:	e8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b40:	00001697          	auipc	a3,0x1
ffffffffc0200b44:	ed068693          	addi	a3,a3,-304 # ffffffffc0201a10 <etext+0x3ba>
ffffffffc0200b48:	00001617          	auipc	a2,0x1
ffffffffc0200b4c:	d6060613          	addi	a2,a2,-672 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200b50:	0e900593          	li	a1,233
ffffffffc0200b54:	00001517          	auipc	a0,0x1
ffffffffc0200b58:	d6c50513          	addi	a0,a0,-660 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200b5c:	e6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b60:	00001697          	auipc	a3,0x1
ffffffffc0200b64:	e9068693          	addi	a3,a3,-368 # ffffffffc02019f0 <etext+0x39a>
ffffffffc0200b68:	00001617          	auipc	a2,0x1
ffffffffc0200b6c:	d4060613          	addi	a2,a2,-704 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200b70:	0e800593          	li	a1,232
ffffffffc0200b74:	00001517          	auipc	a0,0x1
ffffffffc0200b78:	d4c50513          	addi	a0,a0,-692 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200b7c:	e4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0200b80:	00001697          	auipc	a3,0x1
ffffffffc0200b84:	ff868693          	addi	a3,a3,-8 # ffffffffc0201b78 <etext+0x522>
ffffffffc0200b88:	00001617          	auipc	a2,0x1
ffffffffc0200b8c:	d2060613          	addi	a2,a2,-736 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200b90:	15900593          	li	a1,345
ffffffffc0200b94:	00001517          	auipc	a0,0x1
ffffffffc0200b98:	d2c50513          	addi	a0,a0,-724 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200b9c:	e2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200ba0:	00001697          	auipc	a3,0x1
ffffffffc0200ba4:	ef068693          	addi	a3,a3,-272 # ffffffffc0201a90 <etext+0x43a>
ffffffffc0200ba8:	00001617          	auipc	a2,0x1
ffffffffc0200bac:	d0060613          	addi	a2,a2,-768 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200bb0:	14e00593          	li	a1,334
ffffffffc0200bb4:	00001517          	auipc	a0,0x1
ffffffffc0200bb8:	d0c50513          	addi	a0,a0,-756 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200bbc:	e0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bc0:	00001697          	auipc	a3,0x1
ffffffffc0200bc4:	e7068693          	addi	a3,a3,-400 # ffffffffc0201a30 <etext+0x3da>
ffffffffc0200bc8:	00001617          	auipc	a2,0x1
ffffffffc0200bcc:	ce060613          	addi	a2,a2,-800 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200bd0:	14800593          	li	a1,328
ffffffffc0200bd4:	00001517          	auipc	a0,0x1
ffffffffc0200bd8:	cec50513          	addi	a0,a0,-788 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200bdc:	decff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200be0:	00001697          	auipc	a3,0x1
ffffffffc0200be4:	f7868693          	addi	a3,a3,-136 # ffffffffc0201b58 <etext+0x502>
ffffffffc0200be8:	00001617          	auipc	a2,0x1
ffffffffc0200bec:	cc060613          	addi	a2,a2,-832 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200bf0:	14700593          	li	a1,327
ffffffffc0200bf4:	00001517          	auipc	a0,0x1
ffffffffc0200bf8:	ccc50513          	addi	a0,a0,-820 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200bfc:	dccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c00:	00001697          	auipc	a3,0x1
ffffffffc0200c04:	f4868693          	addi	a3,a3,-184 # ffffffffc0201b48 <etext+0x4f2>
ffffffffc0200c08:	00001617          	auipc	a2,0x1
ffffffffc0200c0c:	ca060613          	addi	a2,a2,-864 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200c10:	13f00593          	li	a1,319
ffffffffc0200c14:	00001517          	auipc	a0,0x1
ffffffffc0200c18:	cac50513          	addi	a0,a0,-852 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200c1c:	dacff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c20:	00001697          	auipc	a3,0x1
ffffffffc0200c24:	f1068693          	addi	a3,a3,-240 # ffffffffc0201b30 <etext+0x4da>
ffffffffc0200c28:	00001617          	auipc	a2,0x1
ffffffffc0200c2c:	c8060613          	addi	a2,a2,-896 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200c30:	13e00593          	li	a1,318
ffffffffc0200c34:	00001517          	auipc	a0,0x1
ffffffffc0200c38:	c8c50513          	addi	a0,a0,-884 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200c3c:	d8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c40:	00001697          	auipc	a3,0x1
ffffffffc0200c44:	ed068693          	addi	a3,a3,-304 # ffffffffc0201b10 <etext+0x4ba>
ffffffffc0200c48:	00001617          	auipc	a2,0x1
ffffffffc0200c4c:	c6060613          	addi	a2,a2,-928 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200c50:	13d00593          	li	a1,317
ffffffffc0200c54:	00001517          	auipc	a0,0x1
ffffffffc0200c58:	c6c50513          	addi	a0,a0,-916 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200c5c:	d6cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c60:	00001697          	auipc	a3,0x1
ffffffffc0200c64:	e8068693          	addi	a3,a3,-384 # ffffffffc0201ae0 <etext+0x48a>
ffffffffc0200c68:	00001617          	auipc	a2,0x1
ffffffffc0200c6c:	c4060613          	addi	a2,a2,-960 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200c70:	13b00593          	li	a1,315
ffffffffc0200c74:	00001517          	auipc	a0,0x1
ffffffffc0200c78:	c4c50513          	addi	a0,a0,-948 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200c7c:	d4cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c80:	00001697          	auipc	a3,0x1
ffffffffc0200c84:	e4868693          	addi	a3,a3,-440 # ffffffffc0201ac8 <etext+0x472>
ffffffffc0200c88:	00001617          	auipc	a2,0x1
ffffffffc0200c8c:	c2060613          	addi	a2,a2,-992 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200c90:	13a00593          	li	a1,314
ffffffffc0200c94:	00001517          	auipc	a0,0x1
ffffffffc0200c98:	c2c50513          	addi	a0,a0,-980 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200c9c:	d2cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ca0:	00001697          	auipc	a3,0x1
ffffffffc0200ca4:	d9068693          	addi	a3,a3,-624 # ffffffffc0201a30 <etext+0x3da>
ffffffffc0200ca8:	00001617          	auipc	a2,0x1
ffffffffc0200cac:	c0060613          	addi	a2,a2,-1024 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200cb0:	12e00593          	li	a1,302
ffffffffc0200cb4:	00001517          	auipc	a0,0x1
ffffffffc0200cb8:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200cbc:	d0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cc0:	00001697          	auipc	a3,0x1
ffffffffc0200cc4:	df068693          	addi	a3,a3,-528 # ffffffffc0201ab0 <etext+0x45a>
ffffffffc0200cc8:	00001617          	auipc	a2,0x1
ffffffffc0200ccc:	be060613          	addi	a2,a2,-1056 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200cd0:	12500593          	li	a1,293
ffffffffc0200cd4:	00001517          	auipc	a0,0x1
ffffffffc0200cd8:	bec50513          	addi	a0,a0,-1044 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200cdc:	cecff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0200ce0:	00001697          	auipc	a3,0x1
ffffffffc0200ce4:	dc068693          	addi	a3,a3,-576 # ffffffffc0201aa0 <etext+0x44a>
ffffffffc0200ce8:	00001617          	auipc	a2,0x1
ffffffffc0200cec:	bc060613          	addi	a2,a2,-1088 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200cf0:	12400593          	li	a1,292
ffffffffc0200cf4:	00001517          	auipc	a0,0x1
ffffffffc0200cf8:	bcc50513          	addi	a0,a0,-1076 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200cfc:	cccff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200d00:	00001697          	auipc	a3,0x1
ffffffffc0200d04:	d9068693          	addi	a3,a3,-624 # ffffffffc0201a90 <etext+0x43a>
ffffffffc0200d08:	00001617          	auipc	a2,0x1
ffffffffc0200d0c:	ba060613          	addi	a2,a2,-1120 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200d10:	10600593          	li	a1,262
ffffffffc0200d14:	00001517          	auipc	a0,0x1
ffffffffc0200d18:	bac50513          	addi	a0,a0,-1108 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200d1c:	cacff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d20:	00001697          	auipc	a3,0x1
ffffffffc0200d24:	d1068693          	addi	a3,a3,-752 # ffffffffc0201a30 <etext+0x3da>
ffffffffc0200d28:	00001617          	auipc	a2,0x1
ffffffffc0200d2c:	b8060613          	addi	a2,a2,-1152 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200d30:	10400593          	li	a1,260
ffffffffc0200d34:	00001517          	auipc	a0,0x1
ffffffffc0200d38:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200d3c:	c8cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d40:	00001697          	auipc	a3,0x1
ffffffffc0200d44:	d3068693          	addi	a3,a3,-720 # ffffffffc0201a70 <etext+0x41a>
ffffffffc0200d48:	00001617          	auipc	a2,0x1
ffffffffc0200d4c:	b6060613          	addi	a2,a2,-1184 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200d50:	10300593          	li	a1,259
ffffffffc0200d54:	00001517          	auipc	a0,0x1
ffffffffc0200d58:	b6c50513          	addi	a0,a0,-1172 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200d5c:	c6cff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200d60 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d60:	1141                	addi	sp,sp,-16
ffffffffc0200d62:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d64:	14058e63          	beqz	a1,ffffffffc0200ec0 <best_fit_free_pages+0x160>
    for (; p != base + n; p ++) {
ffffffffc0200d68:	00259713          	slli	a4,a1,0x2
ffffffffc0200d6c:	972e                	add	a4,a4,a1
ffffffffc0200d6e:	070e                	slli	a4,a4,0x3
ffffffffc0200d70:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200d74:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200d76:	cf09                	beqz	a4,ffffffffc0200d90 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d78:	6798                	ld	a4,8(a5)
ffffffffc0200d7a:	8b0d                	andi	a4,a4,3
ffffffffc0200d7c:	12071263          	bnez	a4,ffffffffc0200ea0 <best_fit_free_pages+0x140>
        p->flags = 0;
ffffffffc0200d80:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d84:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d88:	02878793          	addi	a5,a5,40
ffffffffc0200d8c:	fed796e3          	bne	a5,a3,ffffffffc0200d78 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d90:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200d94:	00004717          	auipc	a4,0x4
ffffffffc0200d98:	29472703          	lw	a4,660(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200d9c:	00004697          	auipc	a3,0x4
ffffffffc0200da0:	27c68693          	addi	a3,a3,636 # ffffffffc0205018 <free_area>
    return list->next == list;
ffffffffc0200da4:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200da6:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc0200daa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dac:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200dae:	9f2d                	addw	a4,a4,a1
ffffffffc0200db0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200db2:	0ad78763          	beq	a5,a3,ffffffffc0200e60 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0200db6:	fe878713          	addi	a4,a5,-24
ffffffffc0200dba:	4801                	li	a6,0
ffffffffc0200dbc:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200dc0:	00e56a63          	bltu	a0,a4,ffffffffc0200dd4 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200dc4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dc6:	06d70563          	beq	a4,a3,ffffffffc0200e30 <best_fit_free_pages+0xd0>
    struct Page *p = base;
ffffffffc0200dca:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200dcc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dd0:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dc4 <best_fit_free_pages+0x64>
ffffffffc0200dd4:	00080463          	beqz	a6,ffffffffc0200ddc <best_fit_free_pages+0x7c>
ffffffffc0200dd8:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200ddc:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200de0:	e390                	sd	a2,0(a5)
ffffffffc0200de2:	00c83423          	sd	a2,8(a6)
    elm->prev = prev;
ffffffffc0200de6:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc0200dea:	f11c                	sd	a5,32(a0)
    if (le != &free_list) 
ffffffffc0200dec:	02d80063          	beq	a6,a3,ffffffffc0200e0c <best_fit_free_pages+0xac>
        if (p + p->property == base)
ffffffffc0200df0:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200df4:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base)
ffffffffc0200df8:	020e1613          	slli	a2,t3,0x20
ffffffffc0200dfc:	9201                	srli	a2,a2,0x20
ffffffffc0200dfe:	00261713          	slli	a4,a2,0x2
ffffffffc0200e02:	9732                	add	a4,a4,a2
ffffffffc0200e04:	070e                	slli	a4,a4,0x3
ffffffffc0200e06:	971a                	add	a4,a4,t1
ffffffffc0200e08:	02e50e63          	beq	a0,a4,ffffffffc0200e44 <best_fit_free_pages+0xe4>
    if (le != &free_list) 
ffffffffc0200e0c:	00d78f63          	beq	a5,a3,ffffffffc0200e2a <best_fit_free_pages+0xca>
        if (base + base->property == p) 
ffffffffc0200e10:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200e12:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) 
ffffffffc0200e16:	02059613          	slli	a2,a1,0x20
ffffffffc0200e1a:	9201                	srli	a2,a2,0x20
ffffffffc0200e1c:	00261713          	slli	a4,a2,0x2
ffffffffc0200e20:	9732                	add	a4,a4,a2
ffffffffc0200e22:	070e                	slli	a4,a4,0x3
ffffffffc0200e24:	972a                	add	a4,a4,a0
ffffffffc0200e26:	04e68a63          	beq	a3,a4,ffffffffc0200e7a <best_fit_free_pages+0x11a>
}
ffffffffc0200e2a:	60a2                	ld	ra,8(sp)
ffffffffc0200e2c:	0141                	addi	sp,sp,16
ffffffffc0200e2e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e30:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e32:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e34:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e36:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e38:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3a:	02d70c63          	beq	a4,a3,ffffffffc0200e72 <best_fit_free_pages+0x112>
ffffffffc0200e3e:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200e40:	87ba                	mv	a5,a4
ffffffffc0200e42:	b769                	j	ffffffffc0200dcc <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e44:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e48:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e4c:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e50:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e54:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e58:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e5c:	851a                	mv	a0,t1
ffffffffc0200e5e:	b77d                	j	ffffffffc0200e0c <best_fit_free_pages+0xac>
}
ffffffffc0200e60:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e62:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200e66:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e68:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200e6a:	e398                	sd	a4,0(a5)
ffffffffc0200e6c:	e798                	sd	a4,8(a5)
}
ffffffffc0200e6e:	0141                	addi	sp,sp,16
ffffffffc0200e70:	8082                	ret
    return listelm->prev;
ffffffffc0200e72:	883e                	mv	a6,a5
ffffffffc0200e74:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e76:	87b6                	mv	a5,a3
ffffffffc0200e78:	bf95                	j	ffffffffc0200dec <best_fit_free_pages+0x8c>
            base->property += p->property;
ffffffffc0200e7a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e7e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e82:	0007b803          	ld	a6,0(a5)
ffffffffc0200e86:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e88:	9ead                	addw	a3,a3,a1
ffffffffc0200e8a:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200e8c:	9b75                	andi	a4,a4,-3
ffffffffc0200e8e:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e92:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e94:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e98:	01063023          	sd	a6,0(a2)
ffffffffc0200e9c:	0141                	addi	sp,sp,16
ffffffffc0200e9e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ea0:	00001697          	auipc	a3,0x1
ffffffffc0200ea4:	cf868693          	addi	a3,a3,-776 # ffffffffc0201b98 <etext+0x542>
ffffffffc0200ea8:	00001617          	auipc	a2,0x1
ffffffffc0200eac:	a0060613          	addi	a2,a2,-1536 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200eb0:	09c00593          	li	a1,156
ffffffffc0200eb4:	00001517          	auipc	a0,0x1
ffffffffc0200eb8:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200ebc:	b0cff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200ec0:	00001697          	auipc	a3,0x1
ffffffffc0200ec4:	9e068693          	addi	a3,a3,-1568 # ffffffffc02018a0 <etext+0x24a>
ffffffffc0200ec8:	00001617          	auipc	a2,0x1
ffffffffc0200ecc:	9e060613          	addi	a2,a2,-1568 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200ed0:	09900593          	li	a1,153
ffffffffc0200ed4:	00001517          	auipc	a0,0x1
ffffffffc0200ed8:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200edc:	aecff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200ee0 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200ee0:	1141                	addi	sp,sp,-16
ffffffffc0200ee2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ee4:	c9e9                	beqz	a1,ffffffffc0200fb6 <best_fit_init_memmap+0xd6>
    for (; p != base + n; p ++) {
ffffffffc0200ee6:	00259713          	slli	a4,a1,0x2
ffffffffc0200eea:	972e                	add	a4,a4,a1
ffffffffc0200eec:	070e                	slli	a4,a4,0x3
ffffffffc0200eee:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200ef2:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200ef4:	cf11                	beqz	a4,ffffffffc0200f10 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ef6:	6798                	ld	a4,8(a5)
ffffffffc0200ef8:	8b05                	andi	a4,a4,1
ffffffffc0200efa:	cf51                	beqz	a4,ffffffffc0200f96 <best_fit_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc0200efc:	0007a823          	sw	zero,16(a5)
ffffffffc0200f00:	0007b423          	sd	zero,8(a5)
ffffffffc0200f04:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f08:	02878793          	addi	a5,a5,40
ffffffffc0200f0c:	fed795e3          	bne	a5,a3,ffffffffc0200ef6 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f10:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f12:	00004717          	auipc	a4,0x4
ffffffffc0200f16:	11672703          	lw	a4,278(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200f1a:	00004697          	auipc	a3,0x4
ffffffffc0200f1e:	0fe68693          	addi	a3,a3,254 # ffffffffc0205018 <free_area>
    return list->next == list;
ffffffffc0200f22:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f24:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f28:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f2a:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f2c:	9f2d                	addw	a4,a4,a1
ffffffffc0200f2e:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f30:	04d78663          	beq	a5,a3,ffffffffc0200f7c <best_fit_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f34:	fe878713          	addi	a4,a5,-24
ffffffffc0200f38:	4581                	li	a1,0
ffffffffc0200f3a:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0200f3e:	00e56a63          	bltu	a0,a4,ffffffffc0200f52 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f42:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0200f44:	02d70263          	beq	a4,a3,ffffffffc0200f68 <best_fit_init_memmap+0x88>
    struct Page *p = base;
ffffffffc0200f48:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f4a:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0200f4e:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f42 <best_fit_init_memmap+0x62>
ffffffffc0200f52:	c199                	beqz	a1,ffffffffc0200f58 <best_fit_init_memmap+0x78>
ffffffffc0200f54:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f58:	6398                	ld	a4,0(a5)
}
ffffffffc0200f5a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f5c:	e390                	sd	a2,0(a5)
ffffffffc0200f5e:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0200f60:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200f62:	f11c                	sd	a5,32(a0)
ffffffffc0200f64:	0141                	addi	sp,sp,16
ffffffffc0200f66:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f68:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f6a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f6c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f6e:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200f70:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f72:	00d70e63          	beq	a4,a3,ffffffffc0200f8e <best_fit_init_memmap+0xae>
ffffffffc0200f76:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0200f78:	87ba                	mv	a5,a4
ffffffffc0200f7a:	bfc1                	j	ffffffffc0200f4a <best_fit_init_memmap+0x6a>
}
ffffffffc0200f7c:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f7e:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200f82:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f84:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200f86:	e398                	sd	a4,0(a5)
ffffffffc0200f88:	e798                	sd	a4,8(a5)
}
ffffffffc0200f8a:	0141                	addi	sp,sp,16
ffffffffc0200f8c:	8082                	ret
ffffffffc0200f8e:	60a2                	ld	ra,8(sp)
ffffffffc0200f90:	e290                	sd	a2,0(a3)
ffffffffc0200f92:	0141                	addi	sp,sp,16
ffffffffc0200f94:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f96:	00001697          	auipc	a3,0x1
ffffffffc0200f9a:	c2a68693          	addi	a3,a3,-982 # ffffffffc0201bc0 <etext+0x56a>
ffffffffc0200f9e:	00001617          	auipc	a2,0x1
ffffffffc0200fa2:	90a60613          	addi	a2,a2,-1782 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200fa6:	04a00593          	li	a1,74
ffffffffc0200faa:	00001517          	auipc	a0,0x1
ffffffffc0200fae:	91650513          	addi	a0,a0,-1770 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200fb2:	a16ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200fb6:	00001697          	auipc	a3,0x1
ffffffffc0200fba:	8ea68693          	addi	a3,a3,-1814 # ffffffffc02018a0 <etext+0x24a>
ffffffffc0200fbe:	00001617          	auipc	a2,0x1
ffffffffc0200fc2:	8ea60613          	addi	a2,a2,-1814 # ffffffffc02018a8 <etext+0x252>
ffffffffc0200fc6:	04700593          	li	a1,71
ffffffffc0200fca:	00001517          	auipc	a0,0x1
ffffffffc0200fce:	8f650513          	addi	a0,a0,-1802 # ffffffffc02018c0 <etext+0x26a>
ffffffffc0200fd2:	9f6ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200fd6 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fd6:	00004797          	auipc	a5,0x4
ffffffffc0200fda:	0727b783          	ld	a5,114(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fde:	6f9c                	ld	a5,24(a5)
ffffffffc0200fe0:	8782                	jr	a5

ffffffffc0200fe2 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fe2:	00004797          	auipc	a5,0x4
ffffffffc0200fe6:	0667b783          	ld	a5,102(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fea:	739c                	ld	a5,32(a5)
ffffffffc0200fec:	8782                	jr	a5

ffffffffc0200fee <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fee:	00004797          	auipc	a5,0x4
ffffffffc0200ff2:	05a7b783          	ld	a5,90(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200ff6:	779c                	ld	a5,40(a5)
ffffffffc0200ff8:	8782                	jr	a5

ffffffffc0200ffa <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ffa:	00001797          	auipc	a5,0x1
ffffffffc0200ffe:	e0e78793          	addi	a5,a5,-498 # ffffffffc0201e08 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201002:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201004:	7139                	addi	sp,sp,-64
ffffffffc0201006:	fc06                	sd	ra,56(sp)
ffffffffc0201008:	f822                	sd	s0,48(sp)
ffffffffc020100a:	f426                	sd	s1,40(sp)
ffffffffc020100c:	ec4e                	sd	s3,24(sp)
ffffffffc020100e:	f04a                	sd	s2,32(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201010:	00004417          	auipc	s0,0x4
ffffffffc0201014:	03840413          	addi	s0,s0,56 # ffffffffc0205048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201018:	00001517          	auipc	a0,0x1
ffffffffc020101c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0201be8 <etext+0x592>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201020:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201022:	926ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc0201026:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201028:	00004497          	auipc	s1,0x4
ffffffffc020102c:	03848493          	addi	s1,s1,56 # ffffffffc0205060 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201030:	679c                	ld	a5,8(a5)
ffffffffc0201032:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201034:	57f5                	li	a5,-3
ffffffffc0201036:	07fa                	slli	a5,a5,0x1e
ffffffffc0201038:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020103a:	d20ff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc020103e:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201040:	d24ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201044:	14050c63          	beqz	a0,ffffffffc020119c <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201048:	00a98933          	add	s2,s3,a0
ffffffffc020104c:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc020104e:	00001517          	auipc	a0,0x1
ffffffffc0201052:	be250513          	addi	a0,a0,-1054 # ffffffffc0201c30 <etext+0x5da>
ffffffffc0201056:	8f2ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020105a:	65a2                	ld	a1,8(sp)
ffffffffc020105c:	864e                	mv	a2,s3
ffffffffc020105e:	fff90693          	addi	a3,s2,-1
ffffffffc0201062:	00001517          	auipc	a0,0x1
ffffffffc0201066:	be650513          	addi	a0,a0,-1050 # ffffffffc0201c48 <etext+0x5f2>
ffffffffc020106a:	8deff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020106e:	c80007b7          	lui	a5,0xc8000
ffffffffc0201072:	85ca                	mv	a1,s2
ffffffffc0201074:	0d27e263          	bltu	a5,s2,ffffffffc0201138 <pmm_init+0x13e>
ffffffffc0201078:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020107a:	00005697          	auipc	a3,0x5
ffffffffc020107e:	ffd68693          	addi	a3,a3,-3 # ffffffffc0206077 <end+0xfff>
ffffffffc0201082:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0201084:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201086:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc020108a:	00004797          	auipc	a5,0x4
ffffffffc020108e:	fcb7bf23          	sd	a1,-34(a5) # ffffffffc0205068 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201092:	00004797          	auipc	a5,0x4
ffffffffc0201096:	fcd7bf23          	sd	a3,-34(a5) # ffffffffc0205070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020109a:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020109c:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020109e:	02080963          	beqz	a6,ffffffffc02010d0 <pmm_init+0xd6>
ffffffffc02010a2:	00259613          	slli	a2,a1,0x2
ffffffffc02010a6:	962e                	add	a2,a2,a1
ffffffffc02010a8:	fec007b7          	lui	a5,0xfec00
ffffffffc02010ac:	97b6                	add	a5,a5,a3
ffffffffc02010ae:	060e                	slli	a2,a2,0x3
ffffffffc02010b0:	963e                	add	a2,a2,a5
ffffffffc02010b2:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc02010b4:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010b6:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc02010ba:	00176713          	ori	a4,a4,1
ffffffffc02010be:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010c2:	fec799e3          	bne	a5,a2,ffffffffc02010b4 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c6:	00281793          	slli	a5,a6,0x2
ffffffffc02010ca:	97c2                	add	a5,a5,a6
ffffffffc02010cc:	078e                	slli	a5,a5,0x3
ffffffffc02010ce:	96be                	add	a3,a3,a5
ffffffffc02010d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02010d4:	0af6e863          	bltu	a3,a5,ffffffffc0201184 <pmm_init+0x18a>
ffffffffc02010d8:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010da:	77fd                	lui	a5,0xfffff
ffffffffc02010dc:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010e2:	0526ed63          	bltu	a3,s2,ffffffffc020113c <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010e6:	601c                	ld	a5,0(s0)
ffffffffc02010e8:	7b9c                	ld	a5,48(a5)
ffffffffc02010ea:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010ec:	00001517          	auipc	a0,0x1
ffffffffc02010f0:	be450513          	addi	a0,a0,-1052 # ffffffffc0201cd0 <etext+0x67a>
ffffffffc02010f4:	854ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010f8:	00003597          	auipc	a1,0x3
ffffffffc02010fc:	f0858593          	addi	a1,a1,-248 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0201100:	00004797          	auipc	a5,0x4
ffffffffc0201104:	f4b7bc23          	sd	a1,-168(a5) # ffffffffc0205058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201108:	c02007b7          	lui	a5,0xc0200
ffffffffc020110c:	0af5e463          	bltu	a1,a5,ffffffffc02011b4 <pmm_init+0x1ba>
ffffffffc0201110:	609c                	ld	a5,0(s1)
}
ffffffffc0201112:	7442                	ld	s0,48(sp)
ffffffffc0201114:	70e2                	ld	ra,56(sp)
ffffffffc0201116:	74a2                	ld	s1,40(sp)
ffffffffc0201118:	7902                	ld	s2,32(sp)
ffffffffc020111a:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020111c:	40f586b3          	sub	a3,a1,a5
ffffffffc0201120:	00004797          	auipc	a5,0x4
ffffffffc0201124:	f2d7b823          	sd	a3,-208(a5) # ffffffffc0205050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201128:	00001517          	auipc	a0,0x1
ffffffffc020112c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0201cf0 <etext+0x69a>
ffffffffc0201130:	8636                	mv	a2,a3
}
ffffffffc0201132:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201134:	814ff06f          	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201138:	85be                	mv	a1,a5
ffffffffc020113a:	bf3d                	j	ffffffffc0201078 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020113c:	6705                	lui	a4,0x1
ffffffffc020113e:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201140:	96ba                	add	a3,a3,a4
ffffffffc0201142:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201144:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201148:	02b7f263          	bgeu	a5,a1,ffffffffc020116c <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc020114c:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020114e:	fff80637          	lui	a2,0xfff80
ffffffffc0201152:	97b2                	add	a5,a5,a2
ffffffffc0201154:	00279513          	slli	a0,a5,0x2
ffffffffc0201158:	953e                	add	a0,a0,a5
ffffffffc020115a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020115c:	40d90933          	sub	s2,s2,a3
ffffffffc0201160:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201162:	00c95593          	srli	a1,s2,0xc
ffffffffc0201166:	9546                	add	a0,a0,a7
ffffffffc0201168:	9782                	jalr	a5
}
ffffffffc020116a:	bfb5                	j	ffffffffc02010e6 <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc020116c:	00001617          	auipc	a2,0x1
ffffffffc0201170:	b3460613          	addi	a2,a2,-1228 # ffffffffc0201ca0 <etext+0x64a>
ffffffffc0201174:	06a00593          	li	a1,106
ffffffffc0201178:	00001517          	auipc	a0,0x1
ffffffffc020117c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0201cc0 <etext+0x66a>
ffffffffc0201180:	848ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201184:	00001617          	auipc	a2,0x1
ffffffffc0201188:	af460613          	addi	a2,a2,-1292 # ffffffffc0201c78 <etext+0x622>
ffffffffc020118c:	05e00593          	li	a1,94
ffffffffc0201190:	00001517          	auipc	a0,0x1
ffffffffc0201194:	a9050513          	addi	a0,a0,-1392 # ffffffffc0201c20 <etext+0x5ca>
ffffffffc0201198:	830ff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc020119c:	00001617          	auipc	a2,0x1
ffffffffc02011a0:	a6460613          	addi	a2,a2,-1436 # ffffffffc0201c00 <etext+0x5aa>
ffffffffc02011a4:	04600593          	li	a1,70
ffffffffc02011a8:	00001517          	auipc	a0,0x1
ffffffffc02011ac:	a7850513          	addi	a0,a0,-1416 # ffffffffc0201c20 <etext+0x5ca>
ffffffffc02011b0:	818ff0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011b4:	86ae                	mv	a3,a1
ffffffffc02011b6:	00001617          	auipc	a2,0x1
ffffffffc02011ba:	ac260613          	addi	a2,a2,-1342 # ffffffffc0201c78 <etext+0x622>
ffffffffc02011be:	07900593          	li	a1,121
ffffffffc02011c2:	00001517          	auipc	a0,0x1
ffffffffc02011c6:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0201c20 <etext+0x5ca>
ffffffffc02011ca:	ffffe0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc02011ce <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011ce:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011d0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011d4:	f022                	sd	s0,32(sp)
ffffffffc02011d6:	ec26                	sd	s1,24(sp)
ffffffffc02011d8:	e84a                	sd	s2,16(sp)
ffffffffc02011da:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011dc:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011e0:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011e2:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011e6:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011ea:	84aa                	mv	s1,a0
ffffffffc02011ec:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02011ee:	03067d63          	bgeu	a2,a6,ffffffffc0201228 <printnum+0x5a>
ffffffffc02011f2:	e44e                	sd	s3,8(sp)
ffffffffc02011f4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02011f6:	4785                	li	a5,1
ffffffffc02011f8:	00e7d763          	bge	a5,a4,ffffffffc0201206 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02011fc:	85ca                	mv	a1,s2
ffffffffc02011fe:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201200:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201202:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201204:	fc65                	bnez	s0,ffffffffc02011fc <printnum+0x2e>
ffffffffc0201206:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201208:	00001797          	auipc	a5,0x1
ffffffffc020120c:	b2878793          	addi	a5,a5,-1240 # ffffffffc0201d30 <etext+0x6da>
ffffffffc0201210:	97d2                	add	a5,a5,s4
}
ffffffffc0201212:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201214:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201218:	70a2                	ld	ra,40(sp)
ffffffffc020121a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020121c:	85ca                	mv	a1,s2
ffffffffc020121e:	87a6                	mv	a5,s1
}
ffffffffc0201220:	6942                	ld	s2,16(sp)
ffffffffc0201222:	64e2                	ld	s1,24(sp)
ffffffffc0201224:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201226:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201228:	03065633          	divu	a2,a2,a6
ffffffffc020122c:	8722                	mv	a4,s0
ffffffffc020122e:	fa1ff0ef          	jal	ffffffffc02011ce <printnum>
ffffffffc0201232:	bfd9                	j	ffffffffc0201208 <printnum+0x3a>

ffffffffc0201234 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201234:	7119                	addi	sp,sp,-128
ffffffffc0201236:	f4a6                	sd	s1,104(sp)
ffffffffc0201238:	f0ca                	sd	s2,96(sp)
ffffffffc020123a:	ecce                	sd	s3,88(sp)
ffffffffc020123c:	e8d2                	sd	s4,80(sp)
ffffffffc020123e:	e4d6                	sd	s5,72(sp)
ffffffffc0201240:	e0da                	sd	s6,64(sp)
ffffffffc0201242:	f862                	sd	s8,48(sp)
ffffffffc0201244:	fc86                	sd	ra,120(sp)
ffffffffc0201246:	f8a2                	sd	s0,112(sp)
ffffffffc0201248:	fc5e                	sd	s7,56(sp)
ffffffffc020124a:	f466                	sd	s9,40(sp)
ffffffffc020124c:	f06a                	sd	s10,32(sp)
ffffffffc020124e:	ec6e                	sd	s11,24(sp)
ffffffffc0201250:	84aa                	mv	s1,a0
ffffffffc0201252:	8c32                	mv	s8,a2
ffffffffc0201254:	8a36                	mv	s4,a3
ffffffffc0201256:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201258:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020125c:	05500b13          	li	s6,85
ffffffffc0201260:	00001a97          	auipc	s5,0x1
ffffffffc0201264:	be0a8a93          	addi	s5,s5,-1056 # ffffffffc0201e40 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201268:	000c4503          	lbu	a0,0(s8)
ffffffffc020126c:	001c0413          	addi	s0,s8,1
ffffffffc0201270:	01350a63          	beq	a0,s3,ffffffffc0201284 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201274:	cd0d                	beqz	a0,ffffffffc02012ae <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201276:	85ca                	mv	a1,s2
ffffffffc0201278:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020127a:	00044503          	lbu	a0,0(s0)
ffffffffc020127e:	0405                	addi	s0,s0,1
ffffffffc0201280:	ff351ae3          	bne	a0,s3,ffffffffc0201274 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201284:	5cfd                	li	s9,-1
ffffffffc0201286:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201288:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020128c:	4b81                	li	s7,0
ffffffffc020128e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201290:	00044683          	lbu	a3,0(s0)
ffffffffc0201294:	00140c13          	addi	s8,s0,1
ffffffffc0201298:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020129c:	0ff5f593          	zext.b	a1,a1
ffffffffc02012a0:	02bb6663          	bltu	s6,a1,ffffffffc02012cc <vprintfmt+0x98>
ffffffffc02012a4:	058a                	slli	a1,a1,0x2
ffffffffc02012a6:	95d6                	add	a1,a1,s5
ffffffffc02012a8:	4198                	lw	a4,0(a1)
ffffffffc02012aa:	9756                	add	a4,a4,s5
ffffffffc02012ac:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02012ae:	70e6                	ld	ra,120(sp)
ffffffffc02012b0:	7446                	ld	s0,112(sp)
ffffffffc02012b2:	74a6                	ld	s1,104(sp)
ffffffffc02012b4:	7906                	ld	s2,96(sp)
ffffffffc02012b6:	69e6                	ld	s3,88(sp)
ffffffffc02012b8:	6a46                	ld	s4,80(sp)
ffffffffc02012ba:	6aa6                	ld	s5,72(sp)
ffffffffc02012bc:	6b06                	ld	s6,64(sp)
ffffffffc02012be:	7be2                	ld	s7,56(sp)
ffffffffc02012c0:	7c42                	ld	s8,48(sp)
ffffffffc02012c2:	7ca2                	ld	s9,40(sp)
ffffffffc02012c4:	7d02                	ld	s10,32(sp)
ffffffffc02012c6:	6de2                	ld	s11,24(sp)
ffffffffc02012c8:	6109                	addi	sp,sp,128
ffffffffc02012ca:	8082                	ret
            putch('%', putdat);
ffffffffc02012cc:	85ca                	mv	a1,s2
ffffffffc02012ce:	02500513          	li	a0,37
ffffffffc02012d2:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02012d4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02012d8:	02500713          	li	a4,37
ffffffffc02012dc:	8c22                	mv	s8,s0
ffffffffc02012de:	f8e785e3          	beq	a5,a4,ffffffffc0201268 <vprintfmt+0x34>
ffffffffc02012e2:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02012e6:	1c7d                	addi	s8,s8,-1
ffffffffc02012e8:	fee79de3          	bne	a5,a4,ffffffffc02012e2 <vprintfmt+0xae>
ffffffffc02012ec:	bfb5                	j	ffffffffc0201268 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02012ee:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02012f2:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02012f4:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02012f8:	fd06071b          	addiw	a4,a2,-48
ffffffffc02012fc:	24e56a63          	bltu	a0,a4,ffffffffc0201550 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201300:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201302:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0201304:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201308:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020130c:	0197073b          	addw	a4,a4,s9
ffffffffc0201310:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201314:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201316:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020131a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020131c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201320:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201324:	feb570e3          	bgeu	a0,a1,ffffffffc0201304 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201328:	f60d54e3          	bgez	s10,ffffffffc0201290 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020132c:	8d66                	mv	s10,s9
ffffffffc020132e:	5cfd                	li	s9,-1
ffffffffc0201330:	b785                	j	ffffffffc0201290 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201332:	8db6                	mv	s11,a3
ffffffffc0201334:	8462                	mv	s0,s8
ffffffffc0201336:	bfa9                	j	ffffffffc0201290 <vprintfmt+0x5c>
ffffffffc0201338:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020133a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020133c:	bf91                	j	ffffffffc0201290 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020133e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201340:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201344:	00f74463          	blt	a4,a5,ffffffffc020134c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201348:	1a078763          	beqz	a5,ffffffffc02014f6 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020134c:	000a3603          	ld	a2,0(s4)
ffffffffc0201350:	46c1                	li	a3,16
ffffffffc0201352:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201354:	000d879b          	sext.w	a5,s11
ffffffffc0201358:	876a                	mv	a4,s10
ffffffffc020135a:	85ca                	mv	a1,s2
ffffffffc020135c:	8526                	mv	a0,s1
ffffffffc020135e:	e71ff0ef          	jal	ffffffffc02011ce <printnum>
            break;
ffffffffc0201362:	b719                	j	ffffffffc0201268 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201364:	000a2503          	lw	a0,0(s4)
ffffffffc0201368:	85ca                	mv	a1,s2
ffffffffc020136a:	0a21                	addi	s4,s4,8
ffffffffc020136c:	9482                	jalr	s1
            break;
ffffffffc020136e:	bded                	j	ffffffffc0201268 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201370:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201372:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201376:	00f74463          	blt	a4,a5,ffffffffc020137e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020137a:	16078963          	beqz	a5,ffffffffc02014ec <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020137e:	000a3603          	ld	a2,0(s4)
ffffffffc0201382:	46a9                	li	a3,10
ffffffffc0201384:	8a2e                	mv	s4,a1
ffffffffc0201386:	b7f9                	j	ffffffffc0201354 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201388:	85ca                	mv	a1,s2
ffffffffc020138a:	03000513          	li	a0,48
ffffffffc020138e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201390:	85ca                	mv	a1,s2
ffffffffc0201392:	07800513          	li	a0,120
ffffffffc0201396:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201398:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020139c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020139e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02013a0:	bf55                	j	ffffffffc0201354 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02013a2:	85ca                	mv	a1,s2
ffffffffc02013a4:	02500513          	li	a0,37
ffffffffc02013a8:	9482                	jalr	s1
            break;
ffffffffc02013aa:	bd7d                	j	ffffffffc0201268 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02013ac:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b0:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02013b2:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02013b4:	bf95                	j	ffffffffc0201328 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02013b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013b8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013bc:	00f74463          	blt	a4,a5,ffffffffc02013c4 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02013c0:	12078163          	beqz	a5,ffffffffc02014e2 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02013c4:	000a3603          	ld	a2,0(s4)
ffffffffc02013c8:	46a1                	li	a3,8
ffffffffc02013ca:	8a2e                	mv	s4,a1
ffffffffc02013cc:	b761                	j	ffffffffc0201354 <vprintfmt+0x120>
            if (width < 0)
ffffffffc02013ce:	876a                	mv	a4,s10
ffffffffc02013d0:	000d5363          	bgez	s10,ffffffffc02013d6 <vprintfmt+0x1a2>
ffffffffc02013d4:	4701                	li	a4,0
ffffffffc02013d6:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013da:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02013dc:	bd55                	j	ffffffffc0201290 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc02013de:	000d841b          	sext.w	s0,s11
ffffffffc02013e2:	fd340793          	addi	a5,s0,-45
ffffffffc02013e6:	00f037b3          	snez	a5,a5
ffffffffc02013ea:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013ee:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02013f2:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013f4:	008a0793          	addi	a5,s4,8
ffffffffc02013f8:	e43e                	sd	a5,8(sp)
ffffffffc02013fa:	100d8c63          	beqz	s11,ffffffffc0201512 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02013fe:	12071363          	bnez	a4,ffffffffc0201524 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201402:	000dc783          	lbu	a5,0(s11)
ffffffffc0201406:	0007851b          	sext.w	a0,a5
ffffffffc020140a:	c78d                	beqz	a5,ffffffffc0201434 <vprintfmt+0x200>
ffffffffc020140c:	0d85                	addi	s11,s11,1
ffffffffc020140e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201410:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201414:	000cc563          	bltz	s9,ffffffffc020141e <vprintfmt+0x1ea>
ffffffffc0201418:	3cfd                	addiw	s9,s9,-1
ffffffffc020141a:	008c8d63          	beq	s9,s0,ffffffffc0201434 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020141e:	020b9663          	bnez	s7,ffffffffc020144a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201422:	85ca                	mv	a1,s2
ffffffffc0201424:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201426:	000dc783          	lbu	a5,0(s11)
ffffffffc020142a:	0d85                	addi	s11,s11,1
ffffffffc020142c:	3d7d                	addiw	s10,s10,-1
ffffffffc020142e:	0007851b          	sext.w	a0,a5
ffffffffc0201432:	f3ed                	bnez	a5,ffffffffc0201414 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201434:	01a05963          	blez	s10,ffffffffc0201446 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201438:	85ca                	mv	a1,s2
ffffffffc020143a:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020143e:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201440:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201442:	fe0d1be3          	bnez	s10,ffffffffc0201438 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201446:	6a22                	ld	s4,8(sp)
ffffffffc0201448:	b505                	j	ffffffffc0201268 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020144a:	3781                	addiw	a5,a5,-32
ffffffffc020144c:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201422 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201450:	03f00513          	li	a0,63
ffffffffc0201454:	85ca                	mv	a1,s2
ffffffffc0201456:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201458:	000dc783          	lbu	a5,0(s11)
ffffffffc020145c:	0d85                	addi	s11,s11,1
ffffffffc020145e:	3d7d                	addiw	s10,s10,-1
ffffffffc0201460:	0007851b          	sext.w	a0,a5
ffffffffc0201464:	dbe1                	beqz	a5,ffffffffc0201434 <vprintfmt+0x200>
ffffffffc0201466:	fa0cd9e3          	bgez	s9,ffffffffc0201418 <vprintfmt+0x1e4>
ffffffffc020146a:	b7c5                	j	ffffffffc020144a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020146c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201470:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201472:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201474:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201478:	8fb9                	xor	a5,a5,a4
ffffffffc020147a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020147e:	02d64563          	blt	a2,a3,ffffffffc02014a8 <vprintfmt+0x274>
ffffffffc0201482:	00001797          	auipc	a5,0x1
ffffffffc0201486:	b1678793          	addi	a5,a5,-1258 # ffffffffc0201f98 <error_string>
ffffffffc020148a:	00369713          	slli	a4,a3,0x3
ffffffffc020148e:	97ba                	add	a5,a5,a4
ffffffffc0201490:	639c                	ld	a5,0(a5)
ffffffffc0201492:	cb99                	beqz	a5,ffffffffc02014a8 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201494:	86be                	mv	a3,a5
ffffffffc0201496:	00001617          	auipc	a2,0x1
ffffffffc020149a:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0201d60 <etext+0x70a>
ffffffffc020149e:	85ca                	mv	a1,s2
ffffffffc02014a0:	8526                	mv	a0,s1
ffffffffc02014a2:	0d8000ef          	jal	ffffffffc020157a <printfmt>
ffffffffc02014a6:	b3c9                	j	ffffffffc0201268 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02014a8:	00001617          	auipc	a2,0x1
ffffffffc02014ac:	8a860613          	addi	a2,a2,-1880 # ffffffffc0201d50 <etext+0x6fa>
ffffffffc02014b0:	85ca                	mv	a1,s2
ffffffffc02014b2:	8526                	mv	a0,s1
ffffffffc02014b4:	0c6000ef          	jal	ffffffffc020157a <printfmt>
ffffffffc02014b8:	bb45                	j	ffffffffc0201268 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02014ba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014bc:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02014c0:	00f74363          	blt	a4,a5,ffffffffc02014c6 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02014c4:	cf81                	beqz	a5,ffffffffc02014dc <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02014c6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02014ca:	02044b63          	bltz	s0,ffffffffc0201500 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02014ce:	8622                	mv	a2,s0
ffffffffc02014d0:	8a5e                	mv	s4,s7
ffffffffc02014d2:	46a9                	li	a3,10
ffffffffc02014d4:	b541                	j	ffffffffc0201354 <vprintfmt+0x120>
            lflag ++;
ffffffffc02014d6:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014d8:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02014da:	bb5d                	j	ffffffffc0201290 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc02014dc:	000a2403          	lw	s0,0(s4)
ffffffffc02014e0:	b7ed                	j	ffffffffc02014ca <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02014e2:	000a6603          	lwu	a2,0(s4)
ffffffffc02014e6:	46a1                	li	a3,8
ffffffffc02014e8:	8a2e                	mv	s4,a1
ffffffffc02014ea:	b5ad                	j	ffffffffc0201354 <vprintfmt+0x120>
ffffffffc02014ec:	000a6603          	lwu	a2,0(s4)
ffffffffc02014f0:	46a9                	li	a3,10
ffffffffc02014f2:	8a2e                	mv	s4,a1
ffffffffc02014f4:	b585                	j	ffffffffc0201354 <vprintfmt+0x120>
ffffffffc02014f6:	000a6603          	lwu	a2,0(s4)
ffffffffc02014fa:	46c1                	li	a3,16
ffffffffc02014fc:	8a2e                	mv	s4,a1
ffffffffc02014fe:	bd99                	j	ffffffffc0201354 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201500:	85ca                	mv	a1,s2
ffffffffc0201502:	02d00513          	li	a0,45
ffffffffc0201506:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201508:	40800633          	neg	a2,s0
ffffffffc020150c:	8a5e                	mv	s4,s7
ffffffffc020150e:	46a9                	li	a3,10
ffffffffc0201510:	b591                	j	ffffffffc0201354 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201512:	e329                	bnez	a4,ffffffffc0201554 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201514:	02800793          	li	a5,40
ffffffffc0201518:	853e                	mv	a0,a5
ffffffffc020151a:	00001d97          	auipc	s11,0x1
ffffffffc020151e:	82fd8d93          	addi	s11,s11,-2001 # ffffffffc0201d49 <etext+0x6f3>
ffffffffc0201522:	b5f5                	j	ffffffffc020140e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201524:	85e6                	mv	a1,s9
ffffffffc0201526:	856e                	mv	a0,s11
ffffffffc0201528:	0a4000ef          	jal	ffffffffc02015cc <strnlen>
ffffffffc020152c:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201530:	01a05863          	blez	s10,ffffffffc0201540 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201534:	85ca                	mv	a1,s2
ffffffffc0201536:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201538:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020153a:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020153c:	fe0d1ce3          	bnez	s10,ffffffffc0201534 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201540:	000dc783          	lbu	a5,0(s11)
ffffffffc0201544:	0007851b          	sext.w	a0,a5
ffffffffc0201548:	ec0792e3          	bnez	a5,ffffffffc020140c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020154c:	6a22                	ld	s4,8(sp)
ffffffffc020154e:	bb29                	j	ffffffffc0201268 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201550:	8462                	mv	s0,s8
ffffffffc0201552:	bbd9                	j	ffffffffc0201328 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201554:	85e6                	mv	a1,s9
ffffffffc0201556:	00000517          	auipc	a0,0x0
ffffffffc020155a:	7f250513          	addi	a0,a0,2034 # ffffffffc0201d48 <etext+0x6f2>
ffffffffc020155e:	06e000ef          	jal	ffffffffc02015cc <strnlen>
ffffffffc0201562:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201566:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020156a:	00000d97          	auipc	s11,0x0
ffffffffc020156e:	7ded8d93          	addi	s11,s11,2014 # ffffffffc0201d48 <etext+0x6f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201572:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201574:	fda040e3          	bgtz	s10,ffffffffc0201534 <vprintfmt+0x300>
ffffffffc0201578:	bd51                	j	ffffffffc020140c <vprintfmt+0x1d8>

ffffffffc020157a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020157a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020157c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201580:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201582:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201584:	ec06                	sd	ra,24(sp)
ffffffffc0201586:	f83a                	sd	a4,48(sp)
ffffffffc0201588:	fc3e                	sd	a5,56(sp)
ffffffffc020158a:	e0c2                	sd	a6,64(sp)
ffffffffc020158c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020158e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201590:	ca5ff0ef          	jal	ffffffffc0201234 <vprintfmt>
}
ffffffffc0201594:	60e2                	ld	ra,24(sp)
ffffffffc0201596:	6161                	addi	sp,sp,80
ffffffffc0201598:	8082                	ret

ffffffffc020159a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020159a:	00004717          	auipc	a4,0x4
ffffffffc020159e:	a7673703          	ld	a4,-1418(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015a2:	4781                	li	a5,0
ffffffffc02015a4:	88ba                	mv	a7,a4
ffffffffc02015a6:	852a                	mv	a0,a0
ffffffffc02015a8:	85be                	mv	a1,a5
ffffffffc02015aa:	863e                	mv	a2,a5
ffffffffc02015ac:	00000073          	ecall
ffffffffc02015b0:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015b2:	8082                	ret

ffffffffc02015b4 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02015b4:	00054783          	lbu	a5,0(a0)
ffffffffc02015b8:	cb81                	beqz	a5,ffffffffc02015c8 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02015ba:	4781                	li	a5,0
        cnt ++;
ffffffffc02015bc:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02015be:	00f50733          	add	a4,a0,a5
ffffffffc02015c2:	00074703          	lbu	a4,0(a4)
ffffffffc02015c6:	fb7d                	bnez	a4,ffffffffc02015bc <strlen+0x8>
    }
    return cnt;
}
ffffffffc02015c8:	853e                	mv	a0,a5
ffffffffc02015ca:	8082                	ret

ffffffffc02015cc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02015cc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015ce:	e589                	bnez	a1,ffffffffc02015d8 <strnlen+0xc>
ffffffffc02015d0:	a811                	j	ffffffffc02015e4 <strnlen+0x18>
        cnt ++;
ffffffffc02015d2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015d4:	00f58863          	beq	a1,a5,ffffffffc02015e4 <strnlen+0x18>
ffffffffc02015d8:	00f50733          	add	a4,a0,a5
ffffffffc02015dc:	00074703          	lbu	a4,0(a4)
ffffffffc02015e0:	fb6d                	bnez	a4,ffffffffc02015d2 <strnlen+0x6>
ffffffffc02015e2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02015e4:	852e                	mv	a0,a1
ffffffffc02015e6:	8082                	ret

ffffffffc02015e8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015e8:	00054783          	lbu	a5,0(a0)
ffffffffc02015ec:	e791                	bnez	a5,ffffffffc02015f8 <strcmp+0x10>
ffffffffc02015ee:	a01d                	j	ffffffffc0201614 <strcmp+0x2c>
ffffffffc02015f0:	00054783          	lbu	a5,0(a0)
ffffffffc02015f4:	cb99                	beqz	a5,ffffffffc020160a <strcmp+0x22>
ffffffffc02015f6:	0585                	addi	a1,a1,1
ffffffffc02015f8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02015fc:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015fe:	fef709e3          	beq	a4,a5,ffffffffc02015f0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201602:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201606:	9d19                	subw	a0,a0,a4
ffffffffc0201608:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020160a:	0015c703          	lbu	a4,1(a1)
ffffffffc020160e:	4501                	li	a0,0
}
ffffffffc0201610:	9d19                	subw	a0,a0,a4
ffffffffc0201612:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201614:	0005c703          	lbu	a4,0(a1)
ffffffffc0201618:	4501                	li	a0,0
ffffffffc020161a:	b7f5                	j	ffffffffc0201606 <strcmp+0x1e>

ffffffffc020161c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020161c:	ce01                	beqz	a2,ffffffffc0201634 <strncmp+0x18>
ffffffffc020161e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201622:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201624:	cb91                	beqz	a5,ffffffffc0201638 <strncmp+0x1c>
ffffffffc0201626:	0005c703          	lbu	a4,0(a1)
ffffffffc020162a:	00f71763          	bne	a4,a5,ffffffffc0201638 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020162e:	0505                	addi	a0,a0,1
ffffffffc0201630:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201632:	f675                	bnez	a2,ffffffffc020161e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201634:	4501                	li	a0,0
ffffffffc0201636:	8082                	ret
ffffffffc0201638:	00054503          	lbu	a0,0(a0)
ffffffffc020163c:	0005c783          	lbu	a5,0(a1)
ffffffffc0201640:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201642:	8082                	ret

ffffffffc0201644 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201644:	ca01                	beqz	a2,ffffffffc0201654 <memset+0x10>
ffffffffc0201646:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201648:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020164a:	0785                	addi	a5,a5,1
ffffffffc020164c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201650:	fef61de3          	bne	a2,a5,ffffffffc020164a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201654:	8082                	ret
