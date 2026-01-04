
bin/kernel:     file format elf64-littleriscv


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
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	49450513          	addi	a0,a0,1172 # ffffffffc02014e0 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	49e50513          	addi	a0,a0,1182 # ffffffffc0201500 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	46e58593          	addi	a1,a1,1134 # ffffffffc02014dc <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0201520 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	4b650513          	addi	a0,a0,1206 # ffffffffc0201540 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	ff258593          	addi	a1,a1,-14 # ffffffffc0206088 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	4c250513          	addi	a0,a0,1218 # ffffffffc0201560 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	3dd58593          	addi	a1,a1,989 # ffffffffc0206487 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	4b450513          	addi	a0,a0,1204 # ffffffffc0201580 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	fa860613          	addi	a2,a2,-88 # ffffffffc0206088 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	3da010ef          	jal	ra,ffffffffc02014ca <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	4b450513          	addi	a0,a0,1204 # ffffffffc02015b0 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	561000ef          	jal	ra,ffffffffc0200e6c <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	775000ef          	jal	ra,ffffffffc02010b4 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	73f000ef          	jal	ra,ffffffffc02010b4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0206030 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	3de50513          	addi	a0,a0,990 # ffffffffc02015d0 <etext+0xf4>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	57850513          	addi	a0,a0,1400 # ffffffffc0201780 <etext+0x2a4>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	21a0106f          	j	ffffffffc0201436 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	3ce50513          	addi	a0,a0,974 # ffffffffc02015f0 <etext+0x114>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	3b050513          	addi	a0,a0,944 # ffffffffc0201600 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	3aa50513          	addi	a0,a0,938 # ffffffffc0201610 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	3b250513          	addi	a0,a0,946 # ffffffffc0201628 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9e65>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	34890913          	addi	s2,s2,840 # ffffffffc0201678 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	33248493          	addi	s1,s1,818 # ffffffffc0201670 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	35e50513          	addi	a0,a0,862 # ffffffffc02016f0 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	38a50513          	addi	a0,a0,906 # ffffffffc0201728 <etext+0x24c>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	26a50513          	addi	a0,a0,618 # ffffffffc0201648 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	064010ef          	jal	ra,ffffffffc0201450 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	0aa010ef          	jal	ra,ffffffffc02014a4 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	7f7000ef          	jal	ra,ffffffffc0201486 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	1dc50513          	addi	a0,a0,476 # ffffffffc0201680 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	12e50513          	addi	a0,a0,302 # ffffffffc02016a0 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	13450513          	addi	a0,a0,308 # ffffffffc02016b8 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	14250513          	addi	a0,a0,322 # ffffffffc02016d8 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	18650513          	addi	a0,a0,390 # ffffffffc0201728 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	a887b723          	sd	s0,-1394(a5) # ffffffffc0206038 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	a967b723          	sd	s6,-1394(a5) # ffffffffc0206040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	a7c53503          	ld	a0,-1412(a0) # ffffffffc0206038 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	a7a53503          	ld	a0,-1414(a0) # ffffffffc0206040 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0206018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
}

static void
buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
    buddy_sys = NULL;
ffffffffc02005e0:	00006797          	auipc	a5,0x6
ffffffffc02005e4:	a607b823          	sd	zero,-1424(a5) # ffffffffc0206050 <buddy_sys>
    buddy_base = NULL;
ffffffffc02005e8:	00006797          	auipc	a5,0x6
ffffffffc02005ec:	a607b023          	sd	zero,-1440(a5) # ffffffffc0206048 <buddy_base>
}
ffffffffc02005f0:	8082                	ret

ffffffffc02005f2 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005f2:	00006517          	auipc	a0,0x6
ffffffffc02005f6:	a3656503          	lwu	a0,-1482(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <basic_buddy_check>:

static void
basic_buddy_check(void) {
ffffffffc02005fc:	1101                	addi	sp,sp,-32
    cprintf("=== 开始伙伴系统检查 ===\n");
ffffffffc02005fe:	00001517          	auipc	a0,0x1
ffffffffc0200602:	14250513          	addi	a0,a0,322 # ffffffffc0201740 <etext+0x264>
basic_buddy_check(void) {
ffffffffc0200606:	ec06                	sd	ra,24(sp)
ffffffffc0200608:	e822                	sd	s0,16(sp)
ffffffffc020060a:	e04a                	sd	s2,0(sp)
ffffffffc020060c:	e426                	sd	s1,8(sp)
    cprintf("=== 开始伙伴系统检查 ===\n");
ffffffffc020060e:	b3fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 单页分配测试
    cprintf("测试1: 单页分配...\n");
ffffffffc0200612:	00001517          	auipc	a0,0x1
ffffffffc0200616:	15650513          	addi	a0,a0,342 # ffffffffc0201768 <etext+0x28c>
ffffffffc020061a:	b33ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p0 = alloc_pages(1);
ffffffffc020061e:	4505                	li	a0,1
ffffffffc0200620:	035000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
ffffffffc0200624:	842a                	mv	s0,a0
    struct Page *p1 = alloc_pages(1);
ffffffffc0200626:	4505                	li	a0,1
ffffffffc0200628:	02d000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
ffffffffc020062c:	892a                	mv	s2,a0
    struct Page *p2 = alloc_pages(1);
ffffffffc020062e:	4505                	li	a0,1
ffffffffc0200630:	025000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
    
    if (p0 != NULL && p1 != NULL && p2 != NULL) {
ffffffffc0200634:	12040063          	beqz	s0,ffffffffc0200754 <basic_buddy_check+0x158>
ffffffffc0200638:	10090e63          	beqz	s2,ffffffffc0200754 <basic_buddy_check+0x158>
ffffffffc020063c:	84aa                	mv	s1,a0
ffffffffc020063e:	10050b63          	beqz	a0,ffffffffc0200754 <basic_buddy_check+0x158>
        cprintf("页面分配成功: p0=%p, p1=%p, p2=%p\n", p0, p1, p2);
ffffffffc0200642:	86aa                	mv	a3,a0
ffffffffc0200644:	864a                	mv	a2,s2
ffffffffc0200646:	85a2                	mv	a1,s0
ffffffffc0200648:	00001517          	auipc	a0,0x1
ffffffffc020064c:	14050513          	addi	a0,a0,320 # ffffffffc0201788 <etext+0x2ac>
ffffffffc0200650:	afdff0ef          	jal	ra,ffffffffc020014c <cprintf>
        if (p0 != p1 && p0 != p2 && p1 != p2) {
ffffffffc0200654:	0f240463          	beq	s0,s2,ffffffffc020073c <basic_buddy_check+0x140>
ffffffffc0200658:	0e940263          	beq	s0,s1,ffffffffc020073c <basic_buddy_check+0x140>
ffffffffc020065c:	0e990063          	beq	s2,s1,ffffffffc020073c <basic_buddy_check+0x140>
            cprintf("单页分配测试通过\n");
ffffffffc0200660:	00001517          	auipc	a0,0x1
ffffffffc0200664:	15850513          	addi	a0,a0,344 # ffffffffc02017b8 <etext+0x2dc>
ffffffffc0200668:	ae5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    } else {
        panic("单页分配失败");
    }
    
    // 先释放单页，为多页分配腾出连续空间
    cprintf("释放单页为多页分配做准备...\n");
ffffffffc020066c:	00001517          	auipc	a0,0x1
ffffffffc0200670:	16c50513          	addi	a0,a0,364 # ffffffffc02017d8 <etext+0x2fc>
ffffffffc0200674:	ad9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    free_pages(p0, 1);
ffffffffc0200678:	8522                	mv	a0,s0
ffffffffc020067a:	4585                	li	a1,1
ffffffffc020067c:	7e4000ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_pages(p1, 1);
ffffffffc0200680:	4585                	li	a1,1
ffffffffc0200682:	854a                	mv	a0,s2
ffffffffc0200684:	7dc000ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_pages(p2, 1);
ffffffffc0200688:	4585                	li	a1,1
ffffffffc020068a:	8526                	mv	a0,s1
ffffffffc020068c:	7d4000ef          	jal	ra,ffffffffc0200e60 <free_pages>
    
    // 多页分配测试 - 从较小的开始
    cprintf("测试2: 多页分配...\n");
ffffffffc0200690:	00001517          	auipc	a0,0x1
ffffffffc0200694:	17850513          	addi	a0,a0,376 # ffffffffc0201808 <etext+0x32c>
ffffffffc0200698:	ab5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p2pages = alloc_pages(2);   // 2页
ffffffffc020069c:	4509                	li	a0,2
ffffffffc020069e:	7b6000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
ffffffffc02006a2:	842a                	mv	s0,a0
    if (p2pages != NULL) {
ffffffffc02006a4:	cd01                	beqz	a0,ffffffffc02006bc <basic_buddy_check+0xc0>
        cprintf("2页分配成功: %p\n", p2pages);
ffffffffc02006a6:	85aa                	mv	a1,a0
ffffffffc02006a8:	00001517          	auipc	a0,0x1
ffffffffc02006ac:	1d050513          	addi	a0,a0,464 # ffffffffc0201878 <etext+0x39c>
ffffffffc02006b0:	a9dff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(p2pages, 2);
ffffffffc02006b4:	4589                	li	a1,2
ffffffffc02006b6:	8522                	mv	a0,s0
ffffffffc02006b8:	7a8000ef          	jal	ra,ffffffffc0200e60 <free_pages>
    }
    
    struct Page *p4 = alloc_pages(4);   // 4页
ffffffffc02006bc:	4511                	li	a0,4
ffffffffc02006be:	796000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
ffffffffc02006c2:	842a                	mv	s0,a0
    if (p4 != NULL) {
ffffffffc02006c4:	cd01                	beqz	a0,ffffffffc02006dc <basic_buddy_check+0xe0>
        cprintf("4页分配成功: %p\n", p4);
ffffffffc02006c6:	85aa                	mv	a1,a0
ffffffffc02006c8:	00001517          	auipc	a0,0x1
ffffffffc02006cc:	1c850513          	addi	a0,a0,456 # ffffffffc0201890 <etext+0x3b4>
ffffffffc02006d0:	a7dff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(p4, 4);
ffffffffc02006d4:	4591                	li	a1,4
ffffffffc02006d6:	8522                	mv	a0,s0
ffffffffc02006d8:	788000ef          	jal	ra,ffffffffc0200e60 <free_pages>
    }
    
    struct Page *p8 = alloc_pages(8);   // 8页
ffffffffc02006dc:	4521                	li	a0,8
ffffffffc02006de:	776000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
ffffffffc02006e2:	842a                	mv	s0,a0
    if (p8 != NULL) {
ffffffffc02006e4:	cd05                	beqz	a0,ffffffffc020071c <basic_buddy_check+0x120>
        cprintf("8页分配成功: %p\n", p8);
ffffffffc02006e6:	85aa                	mv	a1,a0
ffffffffc02006e8:	00001517          	auipc	a0,0x1
ffffffffc02006ec:	1c050513          	addi	a0,a0,448 # ffffffffc02018a8 <etext+0x3cc>
ffffffffc02006f0:	a5dff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_pages(p8, 8);
ffffffffc02006f4:	8522                	mv	a0,s0
ffffffffc02006f6:	45a1                	li	a1,8
ffffffffc02006f8:	768000ef          	jal	ra,ffffffffc0200e60 <free_pages>
        cprintf("多页分配测试通过\n");
ffffffffc02006fc:	00001517          	auipc	a0,0x1
ffffffffc0200700:	1c450513          	addi	a0,a0,452 # ffffffffc02018c0 <etext+0x3e4>
ffffffffc0200704:	a49ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("8页分配失败，但较小分配成功\n");
    }
   
    
    cprintf("=== 伙伴系统检查完成 ===\n");
}
ffffffffc0200708:	6442                	ld	s0,16(sp)
ffffffffc020070a:	60e2                	ld	ra,24(sp)
ffffffffc020070c:	64a2                	ld	s1,8(sp)
ffffffffc020070e:	6902                	ld	s2,0(sp)
    cprintf("=== 伙伴系统检查完成 ===\n");
ffffffffc0200710:	00001517          	auipc	a0,0x1
ffffffffc0200714:	20050513          	addi	a0,a0,512 # ffffffffc0201910 <etext+0x434>
}
ffffffffc0200718:	6105                	addi	sp,sp,32
    cprintf("=== 伙伴系统检查完成 ===\n");
ffffffffc020071a:	bc0d                	j	ffffffffc020014c <cprintf>
        cprintf("8页分配失败，但较小分配成功\n");
ffffffffc020071c:	00001517          	auipc	a0,0x1
ffffffffc0200720:	1c450513          	addi	a0,a0,452 # ffffffffc02018e0 <etext+0x404>
ffffffffc0200724:	a29ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200728:	6442                	ld	s0,16(sp)
ffffffffc020072a:	60e2                	ld	ra,24(sp)
ffffffffc020072c:	64a2                	ld	s1,8(sp)
ffffffffc020072e:	6902                	ld	s2,0(sp)
    cprintf("=== 伙伴系统检查完成 ===\n");
ffffffffc0200730:	00001517          	auipc	a0,0x1
ffffffffc0200734:	1e050513          	addi	a0,a0,480 # ffffffffc0201910 <etext+0x434>
}
ffffffffc0200738:	6105                	addi	sp,sp,32
    cprintf("=== 伙伴系统检查完成 ===\n");
ffffffffc020073a:	bc09                	j	ffffffffc020014c <cprintf>
            panic("分配了重复的页面");
ffffffffc020073c:	00001617          	auipc	a2,0x1
ffffffffc0200740:	0ec60613          	addi	a2,a2,236 # ffffffffc0201828 <etext+0x34c>
ffffffffc0200744:	12200593          	li	a1,290
ffffffffc0200748:	00001517          	auipc	a0,0x1
ffffffffc020074c:	10050513          	addi	a0,a0,256 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200750:	a73ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("单页分配失败");
ffffffffc0200754:	00001617          	auipc	a2,0x1
ffffffffc0200758:	10c60613          	addi	a2,a2,268 # ffffffffc0201860 <etext+0x384>
ffffffffc020075c:	12500593          	li	a1,293
ffffffffc0200760:	00001517          	auipc	a0,0x1
ffffffffc0200764:	0e850513          	addi	a0,a0,232 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200768:	a5bff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020076c <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc020076c:	7139                	addi	sp,sp,-64
ffffffffc020076e:	fc06                	sd	ra,56(sp)
ffffffffc0200770:	f822                	sd	s0,48(sp)
ffffffffc0200772:	f426                	sd	s1,40(sp)
ffffffffc0200774:	f04a                	sd	s2,32(sp)
ffffffffc0200776:	ec4e                	sd	s3,24(sp)
ffffffffc0200778:	e852                	sd	s4,16(sp)
ffffffffc020077a:	e456                	sd	s5,8(sp)
    assert(n > 0);
ffffffffc020077c:	1a058863          	beqz	a1,ffffffffc020092c <buddy_free_pages+0x1c0>
ffffffffc0200780:	84aa                	mv	s1,a0
    assert(base != NULL);
ffffffffc0200782:	16050963          	beqz	a0,ffffffffc02008f4 <buddy_free_pages+0x188>
    assert(buddy_sys != NULL);
ffffffffc0200786:	00006917          	auipc	s2,0x6
ffffffffc020078a:	8ca90913          	addi	s2,s2,-1846 # ffffffffc0206050 <buddy_sys>
ffffffffc020078e:	00093783          	ld	a5,0(s2)
ffffffffc0200792:	1a078d63          	beqz	a5,ffffffffc020094c <buddy_free_pages+0x1e0>
    size_t offset = base - buddy_base;
ffffffffc0200796:	00006a97          	auipc	s5,0x6
ffffffffc020079a:	8b2aba83          	ld	s5,-1870(s5) # ffffffffc0206048 <buddy_base>
ffffffffc020079e:	41550ab3          	sub	s5,a0,s5
ffffffffc02007a2:	403ada93          	srai	s5,s5,0x3
ffffffffc02007a6:	00002697          	auipc	a3,0x2
ffffffffc02007aa:	b126b683          	ld	a3,-1262(a3) # ffffffffc02022b8 <error_string+0x38>
    unsigned free_size = fixsize(n);
ffffffffc02007ae:	0005879b          	sext.w	a5,a1
    if (size == 0) return 1;
ffffffffc02007b2:	4a05                	li	s4,1
    size_t offset = base - buddy_base;
ffffffffc02007b4:	02da8ab3          	mul	s5,s5,a3
    if (size == 0) return 1;
ffffffffc02007b8:	00fa7663          	bgeu	s4,a5,ffffffffc02007c4 <buddy_free_pages+0x58>
        result <<= 1;
ffffffffc02007bc:	001a1a1b          	slliw	s4,s4,0x1
    while (result < size) {
ffffffffc02007c0:	fefa6ee3          	bltu	s4,a5,ffffffffc02007bc <buddy_free_pages+0x50>
    cprintf("buddy_free_pages: 释放 %lu 页，实际释放 %u 页，偏移 %lu\n", 
ffffffffc02007c4:	86d6                	mv	a3,s5
ffffffffc02007c6:	8652                	mv	a2,s4
ffffffffc02007c8:	00001517          	auipc	a0,0x1
ffffffffc02007cc:	1b850513          	addi	a0,a0,440 # ffffffffc0201980 <etext+0x4a4>
ffffffffc02007d0:	97dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (offset >= buddy_sys->size) {
ffffffffc02007d4:	00093783          	ld	a5,0(s2)
ffffffffc02007d8:	0007a983          	lw	s3,0(a5)
ffffffffc02007dc:	02099793          	slli	a5,s3,0x20
ffffffffc02007e0:	9381                	srli	a5,a5,0x20
ffffffffc02007e2:	12faf963          	bgeu	s5,a5,ffffffffc0200914 <buddy_free_pages+0x1a8>
    unsigned index = offset + buddy_sys->size - 1;
ffffffffc02007e6:	39fd                	addiw	s3,s3,-1
ffffffffc02007e8:	015989bb          	addw	s3,s3,s5
ffffffffc02007ec:	0009841b          	sext.w	s0,s3
    cprintf("buddy_free_pages: 找到节点 %u，对应偏移 %lu\n", index, offset);
ffffffffc02007f0:	8656                	mv	a2,s5
ffffffffc02007f2:	85a2                	mv	a1,s0
ffffffffc02007f4:	00001517          	auipc	a0,0x1
ffffffffc02007f8:	1fc50513          	addi	a0,a0,508 # ffffffffc02019f0 <etext+0x514>
ffffffffc02007fc:	951ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_sys->longest[index] = free_size;
ffffffffc0200800:	00093683          	ld	a3,0(s2)
ffffffffc0200804:	02099713          	slli	a4,s3,0x20
ffffffffc0200808:	01e75793          	srli	a5,a4,0x1e
ffffffffc020080c:	97b6                	add	a5,a5,a3
ffffffffc020080e:	0147a223          	sw	s4,4(a5)
            cprintf("buddy_free_pages: 合并节点 %u，大小 %u\n", temp_index, buddy_sys->longest[temp_index]);
ffffffffc0200812:	00001997          	auipc	s3,0x1
ffffffffc0200816:	21698993          	addi	s3,s3,534 # ffffffffc0201a28 <etext+0x54c>
    while (temp_index > 0) {
ffffffffc020081a:	e405                	bnez	s0,ffffffffc0200842 <buddy_free_pages+0xd6>
ffffffffc020081c:	a0b5                	j	ffffffffc0200888 <buddy_free_pages+0x11c>
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
ffffffffc020081e:	ce5d                	beqz	a2,ffffffffc02008dc <buddy_free_pages+0x170>
ffffffffc0200820:	0cc79063          	bne	a5,a2,ffffffffc02008e0 <buddy_free_pages+0x174>
            buddy_sys->longest[temp_index] = buddy_sys->longest[left] + buddy_sys->longest[right];
ffffffffc0200824:	02071613          	slli	a2,a4,0x20
ffffffffc0200828:	01e65713          	srli	a4,a2,0x1e
ffffffffc020082c:	9736                	add	a4,a4,a3
ffffffffc020082e:	0017961b          	slliw	a2,a5,0x1
ffffffffc0200832:	c350                	sw	a2,4(a4)
            cprintf("buddy_free_pages: 合并节点 %u，大小 %u\n", temp_index, buddy_sys->longest[temp_index]);
ffffffffc0200834:	85a2                	mv	a1,s0
ffffffffc0200836:	854e                	mv	a0,s3
ffffffffc0200838:	915ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (temp_index > 0) {
ffffffffc020083c:	c431                	beqz	s0,ffffffffc0200888 <buddy_free_pages+0x11c>
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
ffffffffc020083e:	00093683          	ld	a3,0(s2)
        temp_index = PARENT(temp_index);
ffffffffc0200842:	2405                	addiw	s0,s0,1
ffffffffc0200844:	0014571b          	srliw	a4,s0,0x1
ffffffffc0200848:	377d                	addiw	a4,a4,-1
        unsigned left = LEFT_LEAF(temp_index);
ffffffffc020084a:	0017179b          	slliw	a5,a4,0x1
ffffffffc020084e:	2785                	addiw	a5,a5,1
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
ffffffffc0200850:	02079613          	slli	a2,a5,0x20
ffffffffc0200854:	01e65793          	srli	a5,a2,0x1e
        unsigned right = RIGHT_LEAF(temp_index);
ffffffffc0200858:	9879                	andi	s0,s0,-2
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
ffffffffc020085a:	97b6                	add	a5,a5,a3
ffffffffc020085c:	1402                	slli	s0,s0,0x20
ffffffffc020085e:	9001                	srli	s0,s0,0x20
ffffffffc0200860:	43dc                	lw	a5,4(a5)
ffffffffc0200862:	040a                	slli	s0,s0,0x2
ffffffffc0200864:	9436                	add	s0,s0,a3
ffffffffc0200866:	4050                	lw	a2,4(s0)
        temp_index = PARENT(temp_index);
ffffffffc0200868:	0007041b          	sext.w	s0,a4
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
ffffffffc020086c:	fbcd                	bnez	a5,ffffffffc020081e <buddy_free_pages+0xb2>
            buddy_sys->longest[temp_index] = MAX(buddy_sys->longest[left], buddy_sys->longest[right]);
ffffffffc020086e:	02041713          	slli	a4,s0,0x20
ffffffffc0200872:	01e75793          	srli	a5,a4,0x1e
ffffffffc0200876:	96be                	add	a3,a3,a5
ffffffffc0200878:	c2d0                	sw	a2,4(a3)
            cprintf("buddy_free_pages: 更新节点 %u，大小 %u\n", temp_index, buddy_sys->longest[temp_index]);
ffffffffc020087a:	85a2                	mv	a1,s0
ffffffffc020087c:	00001517          	auipc	a0,0x1
ffffffffc0200880:	1dc50513          	addi	a0,a0,476 # ffffffffc0201a58 <etext+0x57c>
ffffffffc0200884:	8c9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            break;
ffffffffc0200888:	020a1793          	slli	a5,s4,0x20
ffffffffc020088c:	9381                	srli	a5,a5,0x20
ffffffffc020088e:	00279713          	slli	a4,a5,0x2
ffffffffc0200892:	973e                	add	a4,a4,a5
ffffffffc0200894:	04a1                	addi	s1,s1,8
ffffffffc0200896:	070e                	slli	a4,a4,0x3
ffffffffc0200898:	9726                	add	a4,a4,s1
        SetPageProperty(&base[i]);
ffffffffc020089a:	609c                	ld	a5,0(s1)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020089c:	fe04ac23          	sw	zero,-8(s1)
    for (unsigned i = 0; i < free_size; i++) {
ffffffffc02008a0:	02848493          	addi	s1,s1,40
        SetPageProperty(&base[i]);
ffffffffc02008a4:	0027e793          	ori	a5,a5,2
ffffffffc02008a8:	fcf4bc23          	sd	a5,-40(s1)
    for (unsigned i = 0; i < free_size; i++) {
ffffffffc02008ac:	fe9717e3          	bne	a4,s1,ffffffffc020089a <buddy_free_pages+0x12e>
    nr_free += free_size;
ffffffffc02008b0:	00005717          	auipc	a4,0x5
ffffffffc02008b4:	76870713          	addi	a4,a4,1896 # ffffffffc0206018 <free_area>
ffffffffc02008b8:	4b1c                	lw	a5,16(a4)
}
ffffffffc02008ba:	7442                	ld	s0,48(sp)
ffffffffc02008bc:	70e2                	ld	ra,56(sp)
ffffffffc02008be:	74a2                	ld	s1,40(sp)
ffffffffc02008c0:	7902                	ld	s2,32(sp)
ffffffffc02008c2:	69e2                	ld	s3,24(sp)
ffffffffc02008c4:	6aa2                	ld	s5,8(sp)
    nr_free += free_size;
ffffffffc02008c6:	014785bb          	addw	a1,a5,s4
}
ffffffffc02008ca:	6a42                	ld	s4,16(sp)
    nr_free += free_size;
ffffffffc02008cc:	cb0c                	sw	a1,16(a4)
    cprintf("buddy_free_pages: 释放完成，剩余空闲 %lu\n", nr_free);
ffffffffc02008ce:	00001517          	auipc	a0,0x1
ffffffffc02008d2:	1ba50513          	addi	a0,a0,442 # ffffffffc0201a88 <etext+0x5ac>
}
ffffffffc02008d6:	6121                	addi	sp,sp,64
    cprintf("buddy_free_pages: 释放完成，剩余空闲 %lu\n", nr_free);
ffffffffc02008d8:	875ff06f          	j	ffffffffc020014c <cprintf>
        if (buddy_sys->longest[left] > 0 && buddy_sys->longest[right] > 0 &&
ffffffffc02008dc:	863e                	mv	a2,a5
ffffffffc02008de:	bf41                	j	ffffffffc020086e <buddy_free_pages+0x102>
            buddy_sys->longest[temp_index] = MAX(buddy_sys->longest[left], buddy_sys->longest[right]);
ffffffffc02008e0:	873e                	mv	a4,a5
ffffffffc02008e2:	00c7e563          	bltu	a5,a2,ffffffffc02008ec <buddy_free_pages+0x180>
ffffffffc02008e6:	0007061b          	sext.w	a2,a4
ffffffffc02008ea:	b751                	j	ffffffffc020086e <buddy_free_pages+0x102>
ffffffffc02008ec:	8732                	mv	a4,a2
ffffffffc02008ee:	0007061b          	sext.w	a2,a4
ffffffffc02008f2:	bfb5                	j	ffffffffc020086e <buddy_free_pages+0x102>
    assert(base != NULL);
ffffffffc02008f4:	00001697          	auipc	a3,0x1
ffffffffc02008f8:	06468693          	addi	a3,a3,100 # ffffffffc0201958 <etext+0x47c>
ffffffffc02008fc:	00001617          	auipc	a2,0x1
ffffffffc0200900:	04460613          	addi	a2,a2,68 # ffffffffc0201940 <etext+0x464>
ffffffffc0200904:	0d800593          	li	a1,216
ffffffffc0200908:	00001517          	auipc	a0,0x1
ffffffffc020090c:	f4050513          	addi	a0,a0,-192 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200910:	8b3ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("buddy_free_pages: 偏移超出范围");
ffffffffc0200914:	00001617          	auipc	a2,0x1
ffffffffc0200918:	0b460613          	addi	a2,a2,180 # ffffffffc02019c8 <etext+0x4ec>
ffffffffc020091c:	0e500593          	li	a1,229
ffffffffc0200920:	00001517          	auipc	a0,0x1
ffffffffc0200924:	f2850513          	addi	a0,a0,-216 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200928:	89bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc020092c:	00001697          	auipc	a3,0x1
ffffffffc0200930:	00c68693          	addi	a3,a3,12 # ffffffffc0201938 <etext+0x45c>
ffffffffc0200934:	00001617          	auipc	a2,0x1
ffffffffc0200938:	00c60613          	addi	a2,a2,12 # ffffffffc0201940 <etext+0x464>
ffffffffc020093c:	0d700593          	li	a1,215
ffffffffc0200940:	00001517          	auipc	a0,0x1
ffffffffc0200944:	f0850513          	addi	a0,a0,-248 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200948:	87bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_sys != NULL);
ffffffffc020094c:	00001697          	auipc	a3,0x1
ffffffffc0200950:	01c68693          	addi	a3,a3,28 # ffffffffc0201968 <etext+0x48c>
ffffffffc0200954:	00001617          	auipc	a2,0x1
ffffffffc0200958:	fec60613          	addi	a2,a2,-20 # ffffffffc0201940 <etext+0x464>
ffffffffc020095c:	0d900593          	li	a1,217
ffffffffc0200960:	00001517          	auipc	a0,0x1
ffffffffc0200964:	ee850513          	addi	a0,a0,-280 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200968:	85bff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020096c <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc020096c:	7139                	addi	sp,sp,-64
ffffffffc020096e:	fc06                	sd	ra,56(sp)
ffffffffc0200970:	f822                	sd	s0,48(sp)
ffffffffc0200972:	f426                	sd	s1,40(sp)
ffffffffc0200974:	f04a                	sd	s2,32(sp)
ffffffffc0200976:	ec4e                	sd	s3,24(sp)
ffffffffc0200978:	e852                	sd	s4,16(sp)
ffffffffc020097a:	e456                	sd	s5,8(sp)
    assert(n > 0);
ffffffffc020097c:	26050163          	beqz	a0,ffffffffc0200bde <buddy_alloc_pages+0x272>
    if (n > nr_free || buddy_sys == NULL) {
ffffffffc0200980:	00005497          	auipc	s1,0x5
ffffffffc0200984:	69848493          	addi	s1,s1,1688 # ffffffffc0206018 <free_area>
ffffffffc0200988:	0104e783          	lwu	a5,16(s1)
ffffffffc020098c:	85aa                	mv	a1,a0
ffffffffc020098e:	1aa7eb63          	bltu	a5,a0,ffffffffc0200b44 <buddy_alloc_pages+0x1d8>
ffffffffc0200992:	00005a17          	auipc	s4,0x5
ffffffffc0200996:	6bea0a13          	addi	s4,s4,1726 # ffffffffc0206050 <buddy_sys>
ffffffffc020099a:	000a3783          	ld	a5,0(s4)
ffffffffc020099e:	1a078363          	beqz	a5,ffffffffc0200b44 <buddy_alloc_pages+0x1d8>
    while (result < size) {
ffffffffc02009a2:	4705                	li	a4,1
    unsigned alloc_size = fixsize(n);
ffffffffc02009a4:	0005079b          	sext.w	a5,a0
    unsigned result = 1;
ffffffffc02009a8:	4905                	li	s2,1
    while (result < size) {
ffffffffc02009aa:	00e50663          	beq	a0,a4,ffffffffc02009b6 <buddy_alloc_pages+0x4a>
        result <<= 1;
ffffffffc02009ae:	0019191b          	slliw	s2,s2,0x1
    while (result < size) {
ffffffffc02009b2:	fef96ee3          	bltu	s2,a5,ffffffffc02009ae <buddy_alloc_pages+0x42>
    cprintf("buddy_alloc_pages: 请求 %lu 页，实际分配 %u 页\n", n, alloc_size);
ffffffffc02009b6:	864a                	mv	a2,s2
ffffffffc02009b8:	00001517          	auipc	a0,0x1
ffffffffc02009bc:	15050513          	addi	a0,a0,336 # ffffffffc0201b08 <etext+0x62c>
ffffffffc02009c0:	f8cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy_sys->longest[0] < alloc_size) {
ffffffffc02009c4:	000a3603          	ld	a2,0(s4)
ffffffffc02009c8:	424c                	lw	a1,4(a2)
ffffffffc02009ca:	1d25ed63          	bltu	a1,s2,ffffffffc0200ba4 <buddy_alloc_pages+0x238>
    unsigned node_size = buddy_sys->size;
ffffffffc02009ce:	4218                	lw	a4,0(a2)
    while (node_size > alloc_size) {
ffffffffc02009d0:	18e97c63          	bgeu	s2,a4,ffffffffc0200b68 <buddy_alloc_pages+0x1fc>
    unsigned index = 0;
ffffffffc02009d4:	4401                	li	s0,0
        unsigned left = LEFT_LEAF(index);
ffffffffc02009d6:	0014169b          	slliw	a3,s0,0x1
ffffffffc02009da:	0016841b          	addiw	s0,a3,1
        if (buddy_sys->longest[left] >= alloc_size) {
ffffffffc02009de:	02041593          	slli	a1,s0,0x20
ffffffffc02009e2:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02009e6:	97b2                	add	a5,a5,a2
ffffffffc02009e8:	43dc                	lw	a5,4(a5)
ffffffffc02009ea:	0127f463          	bgeu	a5,s2,ffffffffc02009f2 <buddy_alloc_pages+0x86>
        unsigned right = RIGHT_LEAF(index);
ffffffffc02009ee:	0026841b          	addiw	s0,a3,2
        node_size /= 2;
ffffffffc02009f2:	0017571b          	srliw	a4,a4,0x1
    while (node_size > alloc_size) {
ffffffffc02009f6:	fee960e3          	bltu	s2,a4,ffffffffc02009d6 <buddy_alloc_pages+0x6a>
    if (buddy_sys->longest[index] < alloc_size) {
ffffffffc02009fa:	02041793          	slli	a5,s0,0x20
ffffffffc02009fe:	01e7d993          	srli	s3,a5,0x1e
ffffffffc0200a02:	964e                	add	a2,a2,s3
ffffffffc0200a04:	4250                	lw	a2,4(a2)
ffffffffc0200a06:	15266763          	bltu	a2,s2,ffffffffc0200b54 <buddy_alloc_pages+0x1e8>
    cprintf("buddy_alloc_pages: 在节点 %u 分配 %u 页\n", index, alloc_size);
ffffffffc0200a0a:	864a                	mv	a2,s2
ffffffffc0200a0c:	85a2                	mv	a1,s0
ffffffffc0200a0e:	00001517          	auipc	a0,0x1
ffffffffc0200a12:	1ca50513          	addi	a0,a0,458 # ffffffffc0201bd8 <etext+0x6fc>
ffffffffc0200a16:	f36ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    unsigned allocated = buddy_sys->longest[index];
ffffffffc0200a1a:	000a3703          	ld	a4,0(s4)
    if (index >= buddy_sys->size - 1) {
ffffffffc0200a1e:	431c                	lw	a5,0(a4)
    buddy_sys->longest[index] = 0;
ffffffffc0200a20:	974e                	add	a4,a4,s3
ffffffffc0200a22:	00072223          	sw	zero,4(a4)
    if (index >= buddy_sys->size - 1) {
ffffffffc0200a26:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200a2a:	0ee47263          	bgeu	s0,a4,ffffffffc0200b0e <buddy_alloc_pages+0x1a2>
        while (temp_index > 0) {
ffffffffc0200a2e:	18040363          	beqz	s0,ffffffffc0200bb4 <buddy_alloc_pages+0x248>
ffffffffc0200a32:	874a                	mv	a4,s2
ffffffffc0200a34:	87a2                	mv	a5,s0
    unsigned offset = 0;
ffffffffc0200a36:	4981                	li	s3,0
            if (temp_index % 2 == 0) {
ffffffffc0200a38:	0017f693          	andi	a3,a5,1
ffffffffc0200a3c:	e299                	bnez	a3,ffffffffc0200a42 <buddy_alloc_pages+0xd6>
                offset += temp_size;
ffffffffc0200a3e:	00e989bb          	addw	s3,s3,a4
            temp_index = PARENT(temp_index);
ffffffffc0200a42:	2785                	addiw	a5,a5,1
ffffffffc0200a44:	0017d79b          	srliw	a5,a5,0x1
ffffffffc0200a48:	37fd                	addiw	a5,a5,-1
            temp_size *= 2;
ffffffffc0200a4a:	0017171b          	slliw	a4,a4,0x1
        while (temp_index > 0) {
ffffffffc0200a4e:	f7ed                	bnez	a5,ffffffffc0200a38 <buddy_alloc_pages+0xcc>
    cprintf("buddy_alloc_pages: 偏移 %u\n", offset);
ffffffffc0200a50:	85ce                	mv	a1,s3
ffffffffc0200a52:	00001517          	auipc	a0,0x1
ffffffffc0200a56:	1b650513          	addi	a0,a0,438 # ffffffffc0201c08 <etext+0x72c>
ffffffffc0200a5a:	ef2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (offset >= buddy_sys->size) {
ffffffffc0200a5e:	000a3683          	ld	a3,0(s4)
ffffffffc0200a62:	4290                	lw	a2,0(a3)
ffffffffc0200a64:	16c9f463          	bgeu	s3,a2,ffffffffc0200bcc <buddy_alloc_pages+0x260>
    struct Page *page = &buddy_base[offset];
ffffffffc0200a68:	1982                	slli	s3,s3,0x20
ffffffffc0200a6a:	0209d993          	srli	s3,s3,0x20
ffffffffc0200a6e:	00299a93          	slli	s5,s3,0x2
ffffffffc0200a72:	99d6                	add	s3,s3,s5
ffffffffc0200a74:	00399a93          	slli	s5,s3,0x3
        temp_index = PARENT(temp_index);
ffffffffc0200a78:	2405                	addiw	s0,s0,1
ffffffffc0200a7a:	0014559b          	srliw	a1,s0,0x1
ffffffffc0200a7e:	35fd                	addiw	a1,a1,-1
            MAX(buddy_sys->longest[LEFT_LEAF(temp_index)], 
ffffffffc0200a80:	ffe47793          	andi	a5,s0,-2
ffffffffc0200a84:	0015971b          	slliw	a4,a1,0x1
ffffffffc0200a88:	2705                	addiw	a4,a4,1
ffffffffc0200a8a:	1782                	slli	a5,a5,0x20
ffffffffc0200a8c:	02071613          	slli	a2,a4,0x20
ffffffffc0200a90:	9381                	srli	a5,a5,0x20
ffffffffc0200a92:	01e65713          	srli	a4,a2,0x1e
ffffffffc0200a96:	078a                	slli	a5,a5,0x2
ffffffffc0200a98:	97b6                	add	a5,a5,a3
ffffffffc0200a9a:	9736                	add	a4,a4,a3
ffffffffc0200a9c:	43d0                	lw	a2,4(a5)
ffffffffc0200a9e:	4358                	lw	a4,4(a4)
        buddy_sys->longest[temp_index] = 
ffffffffc0200aa0:	02059513          	slli	a0,a1,0x20
ffffffffc0200aa4:	01e55793          	srli	a5,a0,0x1e
            MAX(buddy_sys->longest[LEFT_LEAF(temp_index)], 
ffffffffc0200aa8:	0006081b          	sext.w	a6,a2
ffffffffc0200aac:	0007089b          	sext.w	a7,a4
        temp_index = PARENT(temp_index);
ffffffffc0200ab0:	0005841b          	sext.w	s0,a1
        buddy_sys->longest[temp_index] = 
ffffffffc0200ab4:	97b6                	add	a5,a5,a3
            MAX(buddy_sys->longest[LEFT_LEAF(temp_index)], 
ffffffffc0200ab6:	0108f363          	bgeu	a7,a6,ffffffffc0200abc <buddy_alloc_pages+0x150>
ffffffffc0200aba:	8732                	mv	a4,a2
        buddy_sys->longest[temp_index] = 
ffffffffc0200abc:	c3d8                	sw	a4,4(a5)
    while (temp_index > 0) {
ffffffffc0200abe:	fc4d                	bnez	s0,ffffffffc0200a78 <buddy_alloc_pages+0x10c>
    struct Page *page = &buddy_base[offset];
ffffffffc0200ac0:	00005997          	auipc	s3,0x5
ffffffffc0200ac4:	5889b983          	ld	s3,1416(s3) # ffffffffc0206048 <buddy_base>
ffffffffc0200ac8:	99d6                	add	s3,s3,s5
    for (unsigned i = 0; i < alloc_size; i++) {
ffffffffc0200aca:	00898793          	addi	a5,s3,8
ffffffffc0200ace:	4681                	li	a3,0
ffffffffc0200ad0:	4605                	li	a2,1
        ClearPageProperty(&page[i]);
ffffffffc0200ad2:	6398                	ld	a4,0(a5)
ffffffffc0200ad4:	fec7ac23          	sw	a2,-8(a5)
    for (unsigned i = 0; i < alloc_size; i++) {
ffffffffc0200ad8:	2685                	addiw	a3,a3,1
        ClearPageProperty(&page[i]);
ffffffffc0200ada:	9b75                	andi	a4,a4,-3
ffffffffc0200adc:	e398                	sd	a4,0(a5)
    for (unsigned i = 0; i < alloc_size; i++) {
ffffffffc0200ade:	02878793          	addi	a5,a5,40
ffffffffc0200ae2:	ff26e8e3          	bltu	a3,s2,ffffffffc0200ad2 <buddy_alloc_pages+0x166>
    nr_free -= alloc_size;
ffffffffc0200ae6:	4894                	lw	a3,16(s1)
    cprintf("buddy_alloc_pages: 分配完成，剩余空闲 %lu\n", nr_free);
ffffffffc0200ae8:	00001517          	auipc	a0,0x1
ffffffffc0200aec:	18050513          	addi	a0,a0,384 # ffffffffc0201c68 <etext+0x78c>
    nr_free -= alloc_size;
ffffffffc0200af0:	412685bb          	subw	a1,a3,s2
ffffffffc0200af4:	c88c                	sw	a1,16(s1)
    cprintf("buddy_alloc_pages: 分配完成，剩余空闲 %lu\n", nr_free);
ffffffffc0200af6:	e56ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200afa:	70e2                	ld	ra,56(sp)
ffffffffc0200afc:	7442                	ld	s0,48(sp)
ffffffffc0200afe:	74a2                	ld	s1,40(sp)
ffffffffc0200b00:	7902                	ld	s2,32(sp)
ffffffffc0200b02:	6a42                	ld	s4,16(sp)
ffffffffc0200b04:	6aa2                	ld	s5,8(sp)
ffffffffc0200b06:	854e                	mv	a0,s3
ffffffffc0200b08:	69e2                	ld	s3,24(sp)
ffffffffc0200b0a:	6121                	addi	sp,sp,64
ffffffffc0200b0c:	8082                	ret
        offset = index - (buddy_sys->size - 1);
ffffffffc0200b0e:	40f407bb          	subw	a5,s0,a5
ffffffffc0200b12:	00178a9b          	addiw	s5,a5,1
ffffffffc0200b16:	000a899b          	sext.w	s3,s5
    cprintf("buddy_alloc_pages: 偏移 %u\n", offset);
ffffffffc0200b1a:	85ce                	mv	a1,s3
ffffffffc0200b1c:	00001517          	auipc	a0,0x1
ffffffffc0200b20:	0ec50513          	addi	a0,a0,236 # ffffffffc0201c08 <etext+0x72c>
ffffffffc0200b24:	e28ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (offset >= buddy_sys->size) {
ffffffffc0200b28:	000a3683          	ld	a3,0(s4)
ffffffffc0200b2c:	4290                	lw	a2,0(a3)
ffffffffc0200b2e:	08c9ff63          	bgeu	s3,a2,ffffffffc0200bcc <buddy_alloc_pages+0x260>
    struct Page *page = &buddy_base[offset];
ffffffffc0200b32:	1a82                	slli	s5,s5,0x20
ffffffffc0200b34:	020ada93          	srli	s5,s5,0x20
ffffffffc0200b38:	002a9993          	slli	s3,s5,0x2
ffffffffc0200b3c:	9ace                	add	s5,s5,s3
ffffffffc0200b3e:	0a8e                	slli	s5,s5,0x3
    while (temp_index > 0) {
ffffffffc0200b40:	fc05                	bnez	s0,ffffffffc0200a78 <buddy_alloc_pages+0x10c>
ffffffffc0200b42:	bfbd                	j	ffffffffc0200ac0 <buddy_alloc_pages+0x154>
        cprintf("buddy_alloc_pages: 没有足够内存或伙伴系统未初始化\n");
ffffffffc0200b44:	00001517          	auipc	a0,0x1
ffffffffc0200b48:	f7c50513          	addi	a0,a0,-132 # ffffffffc0201ac0 <etext+0x5e4>
ffffffffc0200b4c:	e00ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200b50:	4981                	li	s3,0
ffffffffc0200b52:	b765                	j	ffffffffc0200afa <buddy_alloc_pages+0x18e>
        cprintf("buddy_alloc_pages: 搜索失败，节点 %u 大小 %u < 需求 %u\n", 
ffffffffc0200b54:	86ca                	mv	a3,s2
ffffffffc0200b56:	85a2                	mv	a1,s0
ffffffffc0200b58:	00001517          	auipc	a0,0x1
ffffffffc0200b5c:	03850513          	addi	a0,a0,56 # ffffffffc0201b90 <etext+0x6b4>
ffffffffc0200b60:	decff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200b64:	4981                	li	s3,0
ffffffffc0200b66:	bf51                	j	ffffffffc0200afa <buddy_alloc_pages+0x18e>
    cprintf("buddy_alloc_pages: 在节点 %u 分配 %u 页\n", index, alloc_size);
ffffffffc0200b68:	864a                	mv	a2,s2
ffffffffc0200b6a:	4581                	li	a1,0
ffffffffc0200b6c:	00001517          	auipc	a0,0x1
ffffffffc0200b70:	06c50513          	addi	a0,a0,108 # ffffffffc0201bd8 <etext+0x6fc>
ffffffffc0200b74:	dd8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    unsigned allocated = buddy_sys->longest[index];
ffffffffc0200b78:	000a3783          	ld	a5,0(s4)
    if (index >= buddy_sys->size - 1) {
ffffffffc0200b7c:	4705                	li	a4,1
ffffffffc0200b7e:	4394                	lw	a3,0(a5)
    buddy_sys->longest[index] = 0;
ffffffffc0200b80:	0007a223          	sw	zero,4(a5)
    if (index >= buddy_sys->size - 1) {
ffffffffc0200b84:	02e69863          	bne	a3,a4,ffffffffc0200bb4 <buddy_alloc_pages+0x248>
    cprintf("buddy_alloc_pages: 偏移 %u\n", offset);
ffffffffc0200b88:	4581                	li	a1,0
ffffffffc0200b8a:	00001517          	auipc	a0,0x1
ffffffffc0200b8e:	07e50513          	addi	a0,a0,126 # ffffffffc0201c08 <etext+0x72c>
ffffffffc0200b92:	dbaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (offset >= buddy_sys->size) {
ffffffffc0200b96:	000a3783          	ld	a5,0(s4)
ffffffffc0200b9a:	4981                	li	s3,0
ffffffffc0200b9c:	4390                	lw	a2,0(a5)
ffffffffc0200b9e:	c61d                	beqz	a2,ffffffffc0200bcc <buddy_alloc_pages+0x260>
    struct Page *page = &buddy_base[offset];
ffffffffc0200ba0:	4a81                	li	s5,0
ffffffffc0200ba2:	bf39                	j	ffffffffc0200ac0 <buddy_alloc_pages+0x154>
        cprintf("buddy_alloc_pages: 没有足够连续空间，最大可用 %u 页\n", buddy_sys->longest[0]);
ffffffffc0200ba4:	00001517          	auipc	a0,0x1
ffffffffc0200ba8:	fa450513          	addi	a0,a0,-92 # ffffffffc0201b48 <etext+0x66c>
ffffffffc0200bac:	da0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200bb0:	4981                	li	s3,0
ffffffffc0200bb2:	b7a1                	j	ffffffffc0200afa <buddy_alloc_pages+0x18e>
    cprintf("buddy_alloc_pages: 偏移 %u\n", offset);
ffffffffc0200bb4:	4581                	li	a1,0
ffffffffc0200bb6:	00001517          	auipc	a0,0x1
ffffffffc0200bba:	05250513          	addi	a0,a0,82 # ffffffffc0201c08 <etext+0x72c>
ffffffffc0200bbe:	d8eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (offset >= buddy_sys->size) {
ffffffffc0200bc2:	000a3783          	ld	a5,0(s4)
ffffffffc0200bc6:	4390                	lw	a2,0(a5)
ffffffffc0200bc8:	fe61                	bnez	a2,ffffffffc0200ba0 <buddy_alloc_pages+0x234>
    unsigned offset = 0;
ffffffffc0200bca:	4981                	li	s3,0
        cprintf("buddy_alloc_pages: 错误！偏移 %u 超出范围 [0, %u)\n", offset, buddy_sys->size);
ffffffffc0200bcc:	85ce                	mv	a1,s3
ffffffffc0200bce:	00001517          	auipc	a0,0x1
ffffffffc0200bd2:	05a50513          	addi	a0,a0,90 # ffffffffc0201c28 <etext+0x74c>
ffffffffc0200bd6:	d76ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200bda:	4981                	li	s3,0
ffffffffc0200bdc:	bf39                	j	ffffffffc0200afa <buddy_alloc_pages+0x18e>
    assert(n > 0);
ffffffffc0200bde:	00001697          	auipc	a3,0x1
ffffffffc0200be2:	d5a68693          	addi	a3,a3,-678 # ffffffffc0201938 <etext+0x45c>
ffffffffc0200be6:	00001617          	auipc	a2,0x1
ffffffffc0200bea:	d5a60613          	addi	a2,a2,-678 # ffffffffc0201940 <etext+0x464>
ffffffffc0200bee:	07000593          	li	a1,112
ffffffffc0200bf2:	00001517          	auipc	a0,0x1
ffffffffc0200bf6:	c5650513          	addi	a0,a0,-938 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200bfa:	dc8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200bfe <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200bfe:	1101                	addi	sp,sp,-32
ffffffffc0200c00:	ec06                	sd	ra,24(sp)
ffffffffc0200c02:	e822                	sd	s0,16(sp)
ffffffffc0200c04:	e426                	sd	s1,8(sp)
ffffffffc0200c06:	e04a                	sd	s2,0(sp)
    assert(n > 0);
ffffffffc0200c08:	1a058c63          	beqz	a1,ffffffffc0200dc0 <buddy_init_memmap+0x1c2>
ffffffffc0200c0c:	892a                	mv	s2,a0
    cprintf("buddy_init_memmap: 初始化 %lu 页内存\n", n);
ffffffffc0200c0e:	00001517          	auipc	a0,0x1
ffffffffc0200c12:	09250513          	addi	a0,a0,146 # ffffffffc0201ca0 <etext+0x7c4>
ffffffffc0200c16:	842e                	mv	s0,a1
ffffffffc0200c18:	d34ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (; p != base + n; p++) {
ffffffffc0200c1c:	00241693          	slli	a3,s0,0x2
ffffffffc0200c20:	96a2                	add	a3,a3,s0
ffffffffc0200c22:	068e                	slli	a3,a3,0x3
ffffffffc0200c24:	96ca                	add	a3,a3,s2
ffffffffc0200c26:	87ca                	mv	a5,s2
        SetPageProperty(p);
ffffffffc0200c28:	4609                	li	a2,2
    for (; p != base + n; p++) {
ffffffffc0200c2a:	00d90f63          	beq	s2,a3,ffffffffc0200c48 <buddy_init_memmap+0x4a>
        assert(PageReserved(p));
ffffffffc0200c2e:	6798                	ld	a4,8(a5)
ffffffffc0200c30:	8b05                	andi	a4,a4,1
ffffffffc0200c32:	16070763          	beqz	a4,ffffffffc0200da0 <buddy_init_memmap+0x1a2>
        SetPageProperty(p);
ffffffffc0200c36:	e790                	sd	a2,8(a5)
        p->property = 0;
ffffffffc0200c38:	0007a823          	sw	zero,16(a5)
ffffffffc0200c3c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200c40:	02878793          	addi	a5,a5,40
ffffffffc0200c44:	fed795e3          	bne	a5,a3,ffffffffc0200c2e <buddy_init_memmap+0x30>
    buddy_base = base;
ffffffffc0200c48:	00005797          	auipc	a5,0x5
ffffffffc0200c4c:	4127b023          	sd	s2,1024(a5) # ffffffffc0206048 <buddy_base>
    unsigned actual_size = fixsize(n);
ffffffffc0200c50:	0004079b          	sext.w	a5,s0
    if (size == 0) return 1;
ffffffffc0200c54:	4705                	li	a4,1
    unsigned result = 1;
ffffffffc0200c56:	4405                	li	s0,1
    if (size == 0) return 1;
ffffffffc0200c58:	12f77363          	bgeu	a4,a5,ffffffffc0200d7e <buddy_init_memmap+0x180>
        result <<= 1;
ffffffffc0200c5c:	0014141b          	slliw	s0,s0,0x1
    while (result < size) {
ffffffffc0200c60:	fef46ee3          	bltu	s0,a5,ffffffffc0200c5c <buddy_init_memmap+0x5e>
    cprintf("buddy_init_memmap: 实际管理 %u 页（调整为2的幂）\n", actual_size);
ffffffffc0200c64:	85a2                	mv	a1,s0
ffffffffc0200c66:	00001517          	auipc	a0,0x1
ffffffffc0200c6a:	07a50513          	addi	a0,a0,122 # ffffffffc0201ce0 <etext+0x804>
ffffffffc0200c6e:	cdeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t buddy_size = sizeof(struct buddy) + sizeof(unsigned) * (2 * actual_size - 1);
ffffffffc0200c72:	0014159b          	slliw	a1,s0,0x1
ffffffffc0200c76:	35fd                	addiw	a1,a1,-1
ffffffffc0200c78:	02059793          	slli	a5,a1,0x20
ffffffffc0200c7c:	01e7d593          	srli	a1,a5,0x1e
    size_t buddy_pages = (buddy_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200c80:	6605                	lui	a2,0x1
    size_t buddy_size = sizeof(struct buddy) + sizeof(unsigned) * (2 * actual_size - 1);
ffffffffc0200c82:	0591                	addi	a1,a1,4
    size_t buddy_pages = (buddy_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200c84:	167d                	addi	a2,a2,-1
ffffffffc0200c86:	962e                	add	a2,a2,a1
ffffffffc0200c88:	00c65493          	srli	s1,a2,0xc
    cprintf("buddy_init_memmap: 伙伴系统需要 %lu 字节，%lu 页\n", buddy_size, buddy_pages);
ffffffffc0200c8c:	8626                	mv	a2,s1
ffffffffc0200c8e:	00001517          	auipc	a0,0x1
ffffffffc0200c92:	09250513          	addi	a0,a0,146 # ffffffffc0201d20 <etext+0x844>
ffffffffc0200c96:	cb6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (actual_size < buddy_pages) {
ffffffffc0200c9a:	02041793          	slli	a5,s0,0x20
ffffffffc0200c9e:	9381                	srli	a5,a5,0x20
ffffffffc0200ca0:	1497e063          	bltu	a5,s1,ffffffffc0200de0 <buddy_init_memmap+0x1e2>
    uintptr_t buddy_addr = (uintptr_t)(base + actual_size - buddy_pages);
ffffffffc0200ca4:	40978733          	sub	a4,a5,s1
ffffffffc0200ca8:	00271793          	slli	a5,a4,0x2
ffffffffc0200cac:	97ba                	add	a5,a5,a4
ffffffffc0200cae:	078e                	slli	a5,a5,0x3
ffffffffc0200cb0:	993e                	add	s2,s2,a5
    buddy_sys->size = actual_size - buddy_pages;  // 实际可用的页面数
ffffffffc0200cb2:	4094063b          	subw	a2,s0,s1
ffffffffc0200cb6:	00c92023          	sw	a2,0(s2)
    buddy_sys = (struct buddy *)buddy_addr;
ffffffffc0200cba:	00005417          	auipc	s0,0x5
ffffffffc0200cbe:	39640413          	addi	s0,s0,918 # ffffffffc0206050 <buddy_sys>
    cprintf("buddy_init_memmap: 伙伴系统位于 %p，管理 %u 页\n", buddy_sys, buddy_sys->size);
ffffffffc0200cc2:	85ca                	mv	a1,s2
    nr_free = buddy_sys->size;
ffffffffc0200cc4:	00005497          	auipc	s1,0x5
ffffffffc0200cc8:	35448493          	addi	s1,s1,852 # ffffffffc0206018 <free_area>
    cprintf("buddy_init_memmap: 伙伴系统位于 %p，管理 %u 页\n", buddy_sys, buddy_sys->size);
ffffffffc0200ccc:	00001517          	auipc	a0,0x1
ffffffffc0200cd0:	0d450513          	addi	a0,a0,212 # ffffffffc0201da0 <etext+0x8c4>
    nr_free = buddy_sys->size;
ffffffffc0200cd4:	c890                	sw	a2,16(s1)
    buddy_sys = (struct buddy *)buddy_addr;
ffffffffc0200cd6:	01243023          	sd	s2,0(s0)
    cprintf("buddy_init_memmap: 伙伴系统位于 %p，管理 %u 页\n", buddy_sys, buddy_sys->size);
ffffffffc0200cda:	c72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 2 * buddy_sys->size - 1; ++i) {
ffffffffc0200cde:	601c                	ld	a5,0(s0)
ffffffffc0200ce0:	438c                	lw	a1,0(a5)
ffffffffc0200ce2:	00878513          	addi	a0,a5,8
ffffffffc0200ce6:	00478713          	addi	a4,a5,4
ffffffffc0200cea:	0015961b          	slliw	a2,a1,0x1
ffffffffc0200cee:	ffe6069b          	addiw	a3,a2,-2
ffffffffc0200cf2:	1682                	slli	a3,a3,0x20
ffffffffc0200cf4:	82f9                	srli	a3,a3,0x1e
ffffffffc0200cf6:	367d                	addiw	a2,a2,-1
ffffffffc0200cf8:	96aa                	add	a3,a3,a0
        buddy_sys->longest[i] = 0;
ffffffffc0200cfa:	00072023          	sw	zero,0(a4)
    for (int i = 0; i < 2 * buddy_sys->size - 1; ++i) {
ffffffffc0200cfe:	0711                	addi	a4,a4,4
ffffffffc0200d00:	fee69de3          	bne	a3,a4,ffffffffc0200cfa <buddy_init_memmap+0xfc>
    for (int i = 0; i < buddy_sys->size; i++) {
ffffffffc0200d04:	fff5889b          	addiw	a7,a1,-1
ffffffffc0200d08:	8846                	mv	a6,a7
ffffffffc0200d0a:	8746                	mv	a4,a7
        buddy_sys->longest[index] = 1;
ffffffffc0200d0c:	4505                	li	a0,1
    for (int i = 0; i < buddy_sys->size; i++) {
ffffffffc0200d0e:	c5a1                	beqz	a1,ffffffffc0200d56 <buddy_init_memmap+0x158>
        buddy_sys->longest[index] = 1;
ffffffffc0200d10:	00271693          	slli	a3,a4,0x2
ffffffffc0200d14:	96be                	add	a3,a3,a5
ffffffffc0200d16:	c2c8                	sw	a0,4(a3)
    for (int i = 0; i < buddy_sys->size; i++) {
ffffffffc0200d18:	2705                	addiw	a4,a4,1
ffffffffc0200d1a:	fec71be3          	bne	a4,a2,ffffffffc0200d10 <buddy_init_memmap+0x112>
    for (int i = buddy_sys->size - 2; i >= 0; i--) {
ffffffffc0200d1e:	35f9                	addiw	a1,a1,-2
ffffffffc0200d20:	577d                	li	a4,-1
ffffffffc0200d22:	02e58a63          	beq	a1,a4,ffffffffc0200d56 <buddy_init_memmap+0x158>
ffffffffc0200d26:	00381713          	slli	a4,a6,0x3
ffffffffc0200d2a:	00281693          	slli	a3,a6,0x2
ffffffffc0200d2e:	40b00833          	neg	a6,a1
ffffffffc0200d32:	973e                	add	a4,a4,a5
ffffffffc0200d34:	080e                	slli	a6,a6,0x3
ffffffffc0200d36:	97b6                	add	a5,a5,a3
ffffffffc0200d38:	088e                	slli	a7,a7,0x3
ffffffffc0200d3a:	537d                	li	t1,-1
        buddy_sys->longest[i] = buddy_sys->longest[LEFT_LEAF(i)] + buddy_sys->longest[RIGHT_LEAF(i)];
ffffffffc0200d3c:	00e80633          	add	a2,a6,a4
ffffffffc0200d40:	9646                	add	a2,a2,a7
ffffffffc0200d42:	4308                	lw	a0,0(a4)
ffffffffc0200d44:	ffc62683          	lw	a3,-4(a2) # ffc <kern_entry-0xffffffffc01ff004>
    for (int i = buddy_sys->size - 2; i >= 0; i--) {
ffffffffc0200d48:	35fd                	addiw	a1,a1,-1
ffffffffc0200d4a:	1761                	addi	a4,a4,-8
        buddy_sys->longest[i] = buddy_sys->longest[LEFT_LEAF(i)] + buddy_sys->longest[RIGHT_LEAF(i)];
ffffffffc0200d4c:	9ea9                	addw	a3,a3,a0
ffffffffc0200d4e:	c394                	sw	a3,0(a5)
    for (int i = buddy_sys->size - 2; i >= 0; i--) {
ffffffffc0200d50:	17f1                	addi	a5,a5,-4
ffffffffc0200d52:	fe6595e3          	bne	a1,t1,ffffffffc0200d3c <buddy_init_memmap+0x13e>
    cprintf("buddy_init_memmap: 初始化完成，空闲页面数 = %lu\n", nr_free);
ffffffffc0200d56:	488c                	lw	a1,16(s1)
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	08850513          	addi	a0,a0,136 # ffffffffc0201de0 <etext+0x904>
ffffffffc0200d60:	becff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_init_memmap: 根节点大小 = %u\n", buddy_sys->longest[0]);
ffffffffc0200d64:	601c                	ld	a5,0(s0)
}
ffffffffc0200d66:	6442                	ld	s0,16(sp)
ffffffffc0200d68:	60e2                	ld	ra,24(sp)
ffffffffc0200d6a:	64a2                	ld	s1,8(sp)
ffffffffc0200d6c:	6902                	ld	s2,0(sp)
    cprintf("buddy_init_memmap: 根节点大小 = %u\n", buddy_sys->longest[0]);
ffffffffc0200d6e:	43cc                	lw	a1,4(a5)
ffffffffc0200d70:	00001517          	auipc	a0,0x1
ffffffffc0200d74:	0b050513          	addi	a0,a0,176 # ffffffffc0201e20 <etext+0x944>
}
ffffffffc0200d78:	6105                	addi	sp,sp,32
    cprintf("buddy_init_memmap: 根节点大小 = %u\n", buddy_sys->longest[0]);
ffffffffc0200d7a:	bd2ff06f          	j	ffffffffc020014c <cprintf>
    cprintf("buddy_init_memmap: 实际管理 %u 页（调整为2的幂）\n", actual_size);
ffffffffc0200d7e:	4585                	li	a1,1
ffffffffc0200d80:	00001517          	auipc	a0,0x1
ffffffffc0200d84:	f6050513          	addi	a0,a0,-160 # ffffffffc0201ce0 <etext+0x804>
ffffffffc0200d88:	bc4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy_init_memmap: 伙伴系统需要 %lu 字节，%lu 页\n", buddy_size, buddy_pages);
ffffffffc0200d8c:	4605                	li	a2,1
ffffffffc0200d8e:	45a1                	li	a1,8
ffffffffc0200d90:	00001517          	auipc	a0,0x1
ffffffffc0200d94:	f9050513          	addi	a0,a0,-112 # ffffffffc0201d20 <etext+0x844>
ffffffffc0200d98:	bb4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200d9c:	4601                	li	a2,0
ffffffffc0200d9e:	bf21                	j	ffffffffc0200cb6 <buddy_init_memmap+0xb8>
        assert(PageReserved(p));
ffffffffc0200da0:	00001697          	auipc	a3,0x1
ffffffffc0200da4:	f3068693          	addi	a3,a3,-208 # ffffffffc0201cd0 <etext+0x7f4>
ffffffffc0200da8:	00001617          	auipc	a2,0x1
ffffffffc0200dac:	b9860613          	addi	a2,a2,-1128 # ffffffffc0201940 <etext+0x464>
ffffffffc0200db0:	03900593          	li	a1,57
ffffffffc0200db4:	00001517          	auipc	a0,0x1
ffffffffc0200db8:	a9450513          	addi	a0,a0,-1388 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200dbc:	c06ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200dc0:	00001697          	auipc	a3,0x1
ffffffffc0200dc4:	b7868693          	addi	a3,a3,-1160 # ffffffffc0201938 <etext+0x45c>
ffffffffc0200dc8:	00001617          	auipc	a2,0x1
ffffffffc0200dcc:	b7860613          	addi	a2,a2,-1160 # ffffffffc0201940 <etext+0x464>
ffffffffc0200dd0:	03300593          	li	a1,51
ffffffffc0200dd4:	00001517          	auipc	a0,0x1
ffffffffc0200dd8:	a7450513          	addi	a0,a0,-1420 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200ddc:	be6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("buddy_init_memmap: 内存不足存放伙伴系统结构体");
ffffffffc0200de0:	00001617          	auipc	a2,0x1
ffffffffc0200de4:	f8060613          	addi	a2,a2,-128 # ffffffffc0201d60 <etext+0x884>
ffffffffc0200de8:	04f00593          	li	a1,79
ffffffffc0200dec:	00001517          	auipc	a0,0x1
ffffffffc0200df0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0201848 <etext+0x36c>
ffffffffc0200df4:	bceff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200df8 <buddy_detailed_test>:
#include <pmm.h>
#include <stdio.h>
#include <assert.h>

// 详细的伙伴系统测试
void buddy_detailed_test(void) {
ffffffffc0200df8:	1141                	addi	sp,sp,-16
     
    // 测试4: 分配大块
    cprintf("测试4: 分配大块...\n");
ffffffffc0200dfa:	00001517          	auipc	a0,0x1
ffffffffc0200dfe:	0a650513          	addi	a0,a0,166 # ffffffffc0201ea0 <buddy_pmm_manager+0x38>
void buddy_detailed_test(void) {
ffffffffc0200e02:	e406                	sd	ra,8(sp)
    cprintf("测试4: 分配大块...\n");
ffffffffc0200e04:	b48ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *large = alloc_pages(128);
ffffffffc0200e08:	08000513          	li	a0,128
ffffffffc0200e0c:	048000ef          	jal	ra,ffffffffc0200e54 <alloc_pages>
    assert(large != NULL);
ffffffffc0200e10:	c11d                	beqz	a0,ffffffffc0200e36 <buddy_detailed_test+0x3e>
    free_pages(large, 128);
ffffffffc0200e12:	08000593          	li	a1,128
ffffffffc0200e16:	04a000ef          	jal	ra,ffffffffc0200e60 <free_pages>
    cprintf("大块分配测试通过\n");
ffffffffc0200e1a:	00001517          	auipc	a0,0x1
ffffffffc0200e1e:	0ce50513          	addi	a0,a0,206 # ffffffffc0201ee8 <buddy_pmm_manager+0x80>
ffffffffc0200e22:	b2aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    cprintf("=== 所有测试通过! ===\n");
}
ffffffffc0200e26:	60a2                	ld	ra,8(sp)
    cprintf("=== 所有测试通过! ===\n");
ffffffffc0200e28:	00001517          	auipc	a0,0x1
ffffffffc0200e2c:	0e050513          	addi	a0,a0,224 # ffffffffc0201f08 <buddy_pmm_manager+0xa0>
}
ffffffffc0200e30:	0141                	addi	sp,sp,16
    cprintf("=== 所有测试通过! ===\n");
ffffffffc0200e32:	b1aff06f          	j	ffffffffc020014c <cprintf>
    assert(large != NULL);
ffffffffc0200e36:	00001697          	auipc	a3,0x1
ffffffffc0200e3a:	08a68693          	addi	a3,a3,138 # ffffffffc0201ec0 <buddy_pmm_manager+0x58>
ffffffffc0200e3e:	00001617          	auipc	a2,0x1
ffffffffc0200e42:	b0260613          	addi	a2,a2,-1278 # ffffffffc0201940 <etext+0x464>
ffffffffc0200e46:	45ad                	li	a1,11
ffffffffc0200e48:	00001517          	auipc	a0,0x1
ffffffffc0200e4c:	08850513          	addi	a0,a0,136 # ffffffffc0201ed0 <buddy_pmm_manager+0x68>
ffffffffc0200e50:	b72ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e54 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200e54:	00005797          	auipc	a5,0x5
ffffffffc0200e58:	2147b783          	ld	a5,532(a5) # ffffffffc0206068 <pmm_manager>
ffffffffc0200e5c:	6f9c                	ld	a5,24(a5)
ffffffffc0200e5e:	8782                	jr	a5

ffffffffc0200e60 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200e60:	00005797          	auipc	a5,0x5
ffffffffc0200e64:	2087b783          	ld	a5,520(a5) # ffffffffc0206068 <pmm_manager>
ffffffffc0200e68:	739c                	ld	a5,32(a5)
ffffffffc0200e6a:	8782                	jr	a5

ffffffffc0200e6c <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200e6c:	00001797          	auipc	a5,0x1
ffffffffc0200e70:	ffc78793          	addi	a5,a5,-4 # ffffffffc0201e68 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200e74:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200e76:	7179                	addi	sp,sp,-48
ffffffffc0200e78:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200e7a:	00001517          	auipc	a0,0x1
ffffffffc0200e7e:	0ae50513          	addi	a0,a0,174 # ffffffffc0201f28 <buddy_pmm_manager+0xc0>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200e82:	00005417          	auipc	s0,0x5
ffffffffc0200e86:	1e640413          	addi	s0,s0,486 # ffffffffc0206068 <pmm_manager>
void pmm_init(void) {
ffffffffc0200e8a:	f406                	sd	ra,40(sp)
ffffffffc0200e8c:	ec26                	sd	s1,24(sp)
ffffffffc0200e8e:	e44e                	sd	s3,8(sp)
ffffffffc0200e90:	e84a                	sd	s2,16(sp)
ffffffffc0200e92:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200e94:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200e96:	ab6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200e9a:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200e9c:	00005497          	auipc	s1,0x5
ffffffffc0200ea0:	1e448493          	addi	s1,s1,484 # ffffffffc0206080 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200ea4:	679c                	ld	a5,8(a5)
ffffffffc0200ea6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ea8:	57f5                	li	a5,-3
ffffffffc0200eaa:	07fa                	slli	a5,a5,0x1e
ffffffffc0200eac:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200eae:	f0eff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200eb2:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200eb4:	f12ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200eb8:	14050f63          	beqz	a0,ffffffffc0201016 <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200ebc:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	0b250513          	addi	a0,a0,178 # ffffffffc0201f70 <buddy_pmm_manager+0x108>
ffffffffc0200ec6:	a86ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200eca:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200ece:	864e                	mv	a2,s3
ffffffffc0200ed0:	fffa0693          	addi	a3,s4,-1
ffffffffc0200ed4:	85ca                	mv	a1,s2
ffffffffc0200ed6:	00001517          	auipc	a0,0x1
ffffffffc0200eda:	0b250513          	addi	a0,a0,178 # ffffffffc0201f88 <buddy_pmm_manager+0x120>
ffffffffc0200ede:	a6eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200ee2:	c80007b7          	lui	a5,0xc8000
ffffffffc0200ee6:	8652                	mv	a2,s4
ffffffffc0200ee8:	0d47e663          	bltu	a5,s4,ffffffffc0200fb4 <pmm_init+0x148>
ffffffffc0200eec:	00006797          	auipc	a5,0x6
ffffffffc0200ef0:	19b78793          	addi	a5,a5,411 # ffffffffc0207087 <end+0xfff>
ffffffffc0200ef4:	757d                	lui	a0,0xfffff
ffffffffc0200ef6:	8d7d                	and	a0,a0,a5
ffffffffc0200ef8:	8231                	srli	a2,a2,0xc
ffffffffc0200efa:	00005797          	auipc	a5,0x5
ffffffffc0200efe:	14c7bf23          	sd	a2,350(a5) # ffffffffc0206058 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f02:	00005797          	auipc	a5,0x5
ffffffffc0200f06:	14a7bf23          	sd	a0,350(a5) # ffffffffc0206060 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f0a:	000807b7          	lui	a5,0x80
ffffffffc0200f0e:	002005b7          	lui	a1,0x200
ffffffffc0200f12:	02f60563          	beq	a2,a5,ffffffffc0200f3c <pmm_init+0xd0>
ffffffffc0200f16:	00261593          	slli	a1,a2,0x2
ffffffffc0200f1a:	00c586b3          	add	a3,a1,a2
ffffffffc0200f1e:	fec007b7          	lui	a5,0xfec00
ffffffffc0200f22:	97aa                	add	a5,a5,a0
ffffffffc0200f24:	068e                	slli	a3,a3,0x3
ffffffffc0200f26:	96be                	add	a3,a3,a5
ffffffffc0200f28:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200f2a:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f2c:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9fa0>
        SetPageReserved(pages + i);
ffffffffc0200f30:	00176713          	ori	a4,a4,1
ffffffffc0200f34:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f38:	fef699e3          	bne	a3,a5,ffffffffc0200f2a <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f3c:	95b2                	add	a1,a1,a2
ffffffffc0200f3e:	fec006b7          	lui	a3,0xfec00
ffffffffc0200f42:	96aa                	add	a3,a3,a0
ffffffffc0200f44:	058e                	slli	a1,a1,0x3
ffffffffc0200f46:	96ae                	add	a3,a3,a1
ffffffffc0200f48:	c02007b7          	lui	a5,0xc0200
ffffffffc0200f4c:	0af6e963          	bltu	a3,a5,ffffffffc0200ffe <pmm_init+0x192>
ffffffffc0200f50:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200f52:	77fd                	lui	a5,0xfffff
ffffffffc0200f54:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f58:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200f5a:	06b6e063          	bltu	a3,a1,ffffffffc0200fba <pmm_init+0x14e>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200f5e:	601c                	ld	a5,0(s0)
ffffffffc0200f60:	7b9c                	ld	a5,48(a5)
ffffffffc0200f62:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200f64:	00001517          	auipc	a0,0x1
ffffffffc0200f68:	0ac50513          	addi	a0,a0,172 # ffffffffc0202010 <buddy_pmm_manager+0x1a8>
ffffffffc0200f6c:	9e0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    // 添加详细测试
    extern void buddy_detailed_test(void);
    buddy_detailed_test();
ffffffffc0200f70:	e89ff0ef          	jal	ra,ffffffffc0200df8 <buddy_detailed_test>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200f74:	00004597          	auipc	a1,0x4
ffffffffc0200f78:	08c58593          	addi	a1,a1,140 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200f7c:	00005797          	auipc	a5,0x5
ffffffffc0200f80:	0eb7be23          	sd	a1,252(a5) # ffffffffc0206078 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f84:	c02007b7          	lui	a5,0xc0200
ffffffffc0200f88:	0af5e363          	bltu	a1,a5,ffffffffc020102e <pmm_init+0x1c2>
ffffffffc0200f8c:	6090                	ld	a2,0(s1)
}
ffffffffc0200f8e:	7402                	ld	s0,32(sp)
ffffffffc0200f90:	70a2                	ld	ra,40(sp)
ffffffffc0200f92:	64e2                	ld	s1,24(sp)
ffffffffc0200f94:	6942                	ld	s2,16(sp)
ffffffffc0200f96:	69a2                	ld	s3,8(sp)
ffffffffc0200f98:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f9a:	40c58633          	sub	a2,a1,a2
ffffffffc0200f9e:	00005797          	auipc	a5,0x5
ffffffffc0200fa2:	0cc7b923          	sd	a2,210(a5) # ffffffffc0206070 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	08a50513          	addi	a0,a0,138 # ffffffffc0202030 <buddy_pmm_manager+0x1c8>
}
ffffffffc0200fae:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200fb0:	99cff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200fb4:	c8000637          	lui	a2,0xc8000
ffffffffc0200fb8:	bf15                	j	ffffffffc0200eec <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200fba:	6705                	lui	a4,0x1
ffffffffc0200fbc:	177d                	addi	a4,a4,-1
ffffffffc0200fbe:	96ba                	add	a3,a3,a4
ffffffffc0200fc0:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200fc2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200fc6:	02c7f063          	bgeu	a5,a2,ffffffffc0200fe6 <pmm_init+0x17a>
    pmm_manager->init_memmap(base, n);
ffffffffc0200fca:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200fcc:	fff80737          	lui	a4,0xfff80
ffffffffc0200fd0:	973e                	add	a4,a4,a5
ffffffffc0200fd2:	00271793          	slli	a5,a4,0x2
ffffffffc0200fd6:	97ba                	add	a5,a5,a4
ffffffffc0200fd8:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200fda:	8d95                	sub	a1,a1,a3
ffffffffc0200fdc:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200fde:	81b1                	srli	a1,a1,0xc
ffffffffc0200fe0:	953e                	add	a0,a0,a5
ffffffffc0200fe2:	9702                	jalr	a4
}
ffffffffc0200fe4:	bfad                	j	ffffffffc0200f5e <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200fe6:	00001617          	auipc	a2,0x1
ffffffffc0200fea:	ffa60613          	addi	a2,a2,-6 # ffffffffc0201fe0 <buddy_pmm_manager+0x178>
ffffffffc0200fee:	06a00593          	li	a1,106
ffffffffc0200ff2:	00001517          	auipc	a0,0x1
ffffffffc0200ff6:	00e50513          	addi	a0,a0,14 # ffffffffc0202000 <buddy_pmm_manager+0x198>
ffffffffc0200ffa:	9c8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ffe:	00001617          	auipc	a2,0x1
ffffffffc0201002:	fba60613          	addi	a2,a2,-70 # ffffffffc0201fb8 <buddy_pmm_manager+0x150>
ffffffffc0201006:	06000593          	li	a1,96
ffffffffc020100a:	00001517          	auipc	a0,0x1
ffffffffc020100e:	f5650513          	addi	a0,a0,-170 # ffffffffc0201f60 <buddy_pmm_manager+0xf8>
ffffffffc0201012:	9b0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0201016:	00001617          	auipc	a2,0x1
ffffffffc020101a:	f2a60613          	addi	a2,a2,-214 # ffffffffc0201f40 <buddy_pmm_manager+0xd8>
ffffffffc020101e:	04800593          	li	a1,72
ffffffffc0201022:	00001517          	auipc	a0,0x1
ffffffffc0201026:	f3e50513          	addi	a0,a0,-194 # ffffffffc0201f60 <buddy_pmm_manager+0xf8>
ffffffffc020102a:	998ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020102e:	86ae                	mv	a3,a1
ffffffffc0201030:	00001617          	auipc	a2,0x1
ffffffffc0201034:	f8860613          	addi	a2,a2,-120 # ffffffffc0201fb8 <buddy_pmm_manager+0x150>
ffffffffc0201038:	07b00593          	li	a1,123
ffffffffc020103c:	00001517          	auipc	a0,0x1
ffffffffc0201040:	f2450513          	addi	a0,a0,-220 # ffffffffc0201f60 <buddy_pmm_manager+0xf8>
ffffffffc0201044:	97eff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201048 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201048:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020104c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020104e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201052:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201054:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201058:	f022                	sd	s0,32(sp)
ffffffffc020105a:	ec26                	sd	s1,24(sp)
ffffffffc020105c:	e84a                	sd	s2,16(sp)
ffffffffc020105e:	f406                	sd	ra,40(sp)
ffffffffc0201060:	e44e                	sd	s3,8(sp)
ffffffffc0201062:	84aa                	mv	s1,a0
ffffffffc0201064:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201066:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020106a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020106c:	03067e63          	bgeu	a2,a6,ffffffffc02010a8 <printnum+0x60>
ffffffffc0201070:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201072:	00805763          	blez	s0,ffffffffc0201080 <printnum+0x38>
ffffffffc0201076:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201078:	85ca                	mv	a1,s2
ffffffffc020107a:	854e                	mv	a0,s3
ffffffffc020107c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020107e:	fc65                	bnez	s0,ffffffffc0201076 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201080:	1a02                	slli	s4,s4,0x20
ffffffffc0201082:	00001797          	auipc	a5,0x1
ffffffffc0201086:	fee78793          	addi	a5,a5,-18 # ffffffffc0202070 <buddy_pmm_manager+0x208>
ffffffffc020108a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020108e:	9a3e                	add	s4,s4,a5
}
ffffffffc0201090:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201092:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201096:	70a2                	ld	ra,40(sp)
ffffffffc0201098:	69a2                	ld	s3,8(sp)
ffffffffc020109a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020109c:	85ca                	mv	a1,s2
ffffffffc020109e:	87a6                	mv	a5,s1
}
ffffffffc02010a0:	6942                	ld	s2,16(sp)
ffffffffc02010a2:	64e2                	ld	s1,24(sp)
ffffffffc02010a4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010a6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02010a8:	03065633          	divu	a2,a2,a6
ffffffffc02010ac:	8722                	mv	a4,s0
ffffffffc02010ae:	f9bff0ef          	jal	ra,ffffffffc0201048 <printnum>
ffffffffc02010b2:	b7f9                	j	ffffffffc0201080 <printnum+0x38>

ffffffffc02010b4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02010b4:	7119                	addi	sp,sp,-128
ffffffffc02010b6:	f4a6                	sd	s1,104(sp)
ffffffffc02010b8:	f0ca                	sd	s2,96(sp)
ffffffffc02010ba:	ecce                	sd	s3,88(sp)
ffffffffc02010bc:	e8d2                	sd	s4,80(sp)
ffffffffc02010be:	e4d6                	sd	s5,72(sp)
ffffffffc02010c0:	e0da                	sd	s6,64(sp)
ffffffffc02010c2:	fc5e                	sd	s7,56(sp)
ffffffffc02010c4:	f06a                	sd	s10,32(sp)
ffffffffc02010c6:	fc86                	sd	ra,120(sp)
ffffffffc02010c8:	f8a2                	sd	s0,112(sp)
ffffffffc02010ca:	f862                	sd	s8,48(sp)
ffffffffc02010cc:	f466                	sd	s9,40(sp)
ffffffffc02010ce:	ec6e                	sd	s11,24(sp)
ffffffffc02010d0:	892a                	mv	s2,a0
ffffffffc02010d2:	84ae                	mv	s1,a1
ffffffffc02010d4:	8d32                	mv	s10,a2
ffffffffc02010d6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02010d8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02010dc:	5b7d                	li	s6,-1
ffffffffc02010de:	00001a97          	auipc	s5,0x1
ffffffffc02010e2:	fc6a8a93          	addi	s5,s5,-58 # ffffffffc02020a4 <buddy_pmm_manager+0x23c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02010e6:	00001b97          	auipc	s7,0x1
ffffffffc02010ea:	19ab8b93          	addi	s7,s7,410 # ffffffffc0202280 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02010ee:	000d4503          	lbu	a0,0(s10)
ffffffffc02010f2:	001d0413          	addi	s0,s10,1
ffffffffc02010f6:	01350a63          	beq	a0,s3,ffffffffc020110a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02010fa:	c121                	beqz	a0,ffffffffc020113a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02010fc:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02010fe:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201100:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201102:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201106:	ff351ae3          	bne	a0,s3,ffffffffc02010fa <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020110a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020110e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201112:	4c81                	li	s9,0
ffffffffc0201114:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201116:	5c7d                	li	s8,-1
ffffffffc0201118:	5dfd                	li	s11,-1
ffffffffc020111a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020111e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201120:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201124:	0ff5f593          	zext.b	a1,a1
ffffffffc0201128:	00140d13          	addi	s10,s0,1
ffffffffc020112c:	04b56263          	bltu	a0,a1,ffffffffc0201170 <vprintfmt+0xbc>
ffffffffc0201130:	058a                	slli	a1,a1,0x2
ffffffffc0201132:	95d6                	add	a1,a1,s5
ffffffffc0201134:	4194                	lw	a3,0(a1)
ffffffffc0201136:	96d6                	add	a3,a3,s5
ffffffffc0201138:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020113a:	70e6                	ld	ra,120(sp)
ffffffffc020113c:	7446                	ld	s0,112(sp)
ffffffffc020113e:	74a6                	ld	s1,104(sp)
ffffffffc0201140:	7906                	ld	s2,96(sp)
ffffffffc0201142:	69e6                	ld	s3,88(sp)
ffffffffc0201144:	6a46                	ld	s4,80(sp)
ffffffffc0201146:	6aa6                	ld	s5,72(sp)
ffffffffc0201148:	6b06                	ld	s6,64(sp)
ffffffffc020114a:	7be2                	ld	s7,56(sp)
ffffffffc020114c:	7c42                	ld	s8,48(sp)
ffffffffc020114e:	7ca2                	ld	s9,40(sp)
ffffffffc0201150:	7d02                	ld	s10,32(sp)
ffffffffc0201152:	6de2                	ld	s11,24(sp)
ffffffffc0201154:	6109                	addi	sp,sp,128
ffffffffc0201156:	8082                	ret
            padc = '0';
ffffffffc0201158:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020115a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020115e:	846a                	mv	s0,s10
ffffffffc0201160:	00140d13          	addi	s10,s0,1
ffffffffc0201164:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201168:	0ff5f593          	zext.b	a1,a1
ffffffffc020116c:	fcb572e3          	bgeu	a0,a1,ffffffffc0201130 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201170:	85a6                	mv	a1,s1
ffffffffc0201172:	02500513          	li	a0,37
ffffffffc0201176:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201178:	fff44783          	lbu	a5,-1(s0)
ffffffffc020117c:	8d22                	mv	s10,s0
ffffffffc020117e:	f73788e3          	beq	a5,s3,ffffffffc02010ee <vprintfmt+0x3a>
ffffffffc0201182:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201186:	1d7d                	addi	s10,s10,-1
ffffffffc0201188:	ff379de3          	bne	a5,s3,ffffffffc0201182 <vprintfmt+0xce>
ffffffffc020118c:	b78d                	j	ffffffffc02010ee <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020118e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201192:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201196:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201198:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020119c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02011a0:	02d86463          	bltu	a6,a3,ffffffffc02011c8 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02011a4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02011a8:	002c169b          	slliw	a3,s8,0x2
ffffffffc02011ac:	0186873b          	addw	a4,a3,s8
ffffffffc02011b0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02011b4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02011b6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02011ba:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02011bc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02011c0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02011c4:	fed870e3          	bgeu	a6,a3,ffffffffc02011a4 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02011c8:	f40ddce3          	bgez	s11,ffffffffc0201120 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02011cc:	8de2                	mv	s11,s8
ffffffffc02011ce:	5c7d                	li	s8,-1
ffffffffc02011d0:	bf81                	j	ffffffffc0201120 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02011d2:	fffdc693          	not	a3,s11
ffffffffc02011d6:	96fd                	srai	a3,a3,0x3f
ffffffffc02011d8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011dc:	00144603          	lbu	a2,1(s0)
ffffffffc02011e0:	2d81                	sext.w	s11,s11
ffffffffc02011e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02011e4:	bf35                	j	ffffffffc0201120 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02011e6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011ea:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02011ee:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011f0:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02011f2:	bfd9                	j	ffffffffc02011c8 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02011f4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02011f6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02011fa:	01174463          	blt	a4,a7,ffffffffc0201202 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02011fe:	1a088e63          	beqz	a7,ffffffffc02013ba <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201202:	000a3603          	ld	a2,0(s4)
ffffffffc0201206:	46c1                	li	a3,16
ffffffffc0201208:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020120a:	2781                	sext.w	a5,a5
ffffffffc020120c:	876e                	mv	a4,s11
ffffffffc020120e:	85a6                	mv	a1,s1
ffffffffc0201210:	854a                	mv	a0,s2
ffffffffc0201212:	e37ff0ef          	jal	ra,ffffffffc0201048 <printnum>
            break;
ffffffffc0201216:	bde1                	j	ffffffffc02010ee <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201218:	000a2503          	lw	a0,0(s4)
ffffffffc020121c:	85a6                	mv	a1,s1
ffffffffc020121e:	0a21                	addi	s4,s4,8
ffffffffc0201220:	9902                	jalr	s2
            break;
ffffffffc0201222:	b5f1                	j	ffffffffc02010ee <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201224:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201226:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020122a:	01174463          	blt	a4,a7,ffffffffc0201232 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020122e:	18088163          	beqz	a7,ffffffffc02013b0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201232:	000a3603          	ld	a2,0(s4)
ffffffffc0201236:	46a9                	li	a3,10
ffffffffc0201238:	8a2e                	mv	s4,a1
ffffffffc020123a:	bfc1                	j	ffffffffc020120a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020123c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201240:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201242:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201244:	bdf1                	j	ffffffffc0201120 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201246:	85a6                	mv	a1,s1
ffffffffc0201248:	02500513          	li	a0,37
ffffffffc020124c:	9902                	jalr	s2
            break;
ffffffffc020124e:	b545                	j	ffffffffc02010ee <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201250:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201254:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201256:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201258:	b5e1                	j	ffffffffc0201120 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020125a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020125c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201260:	01174463          	blt	a4,a7,ffffffffc0201268 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201264:	14088163          	beqz	a7,ffffffffc02013a6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201268:	000a3603          	ld	a2,0(s4)
ffffffffc020126c:	46a1                	li	a3,8
ffffffffc020126e:	8a2e                	mv	s4,a1
ffffffffc0201270:	bf69                	j	ffffffffc020120a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201272:	03000513          	li	a0,48
ffffffffc0201276:	85a6                	mv	a1,s1
ffffffffc0201278:	e03e                	sd	a5,0(sp)
ffffffffc020127a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020127c:	85a6                	mv	a1,s1
ffffffffc020127e:	07800513          	li	a0,120
ffffffffc0201282:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201284:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201286:	6782                	ld	a5,0(sp)
ffffffffc0201288:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020128a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020128e:	bfb5                	j	ffffffffc020120a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201290:	000a3403          	ld	s0,0(s4)
ffffffffc0201294:	008a0713          	addi	a4,s4,8
ffffffffc0201298:	e03a                	sd	a4,0(sp)
ffffffffc020129a:	14040263          	beqz	s0,ffffffffc02013de <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020129e:	0fb05763          	blez	s11,ffffffffc020138c <vprintfmt+0x2d8>
ffffffffc02012a2:	02d00693          	li	a3,45
ffffffffc02012a6:	0cd79163          	bne	a5,a3,ffffffffc0201368 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012aa:	00044783          	lbu	a5,0(s0)
ffffffffc02012ae:	0007851b          	sext.w	a0,a5
ffffffffc02012b2:	cf85                	beqz	a5,ffffffffc02012ea <vprintfmt+0x236>
ffffffffc02012b4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012b8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012bc:	000c4563          	bltz	s8,ffffffffc02012c6 <vprintfmt+0x212>
ffffffffc02012c0:	3c7d                	addiw	s8,s8,-1
ffffffffc02012c2:	036c0263          	beq	s8,s6,ffffffffc02012e6 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02012c6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012c8:	0e0c8e63          	beqz	s9,ffffffffc02013c4 <vprintfmt+0x310>
ffffffffc02012cc:	3781                	addiw	a5,a5,-32
ffffffffc02012ce:	0ef47b63          	bgeu	s0,a5,ffffffffc02013c4 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02012d2:	03f00513          	li	a0,63
ffffffffc02012d6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012d8:	000a4783          	lbu	a5,0(s4)
ffffffffc02012dc:	3dfd                	addiw	s11,s11,-1
ffffffffc02012de:	0a05                	addi	s4,s4,1
ffffffffc02012e0:	0007851b          	sext.w	a0,a5
ffffffffc02012e4:	ffe1                	bnez	a5,ffffffffc02012bc <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02012e6:	01b05963          	blez	s11,ffffffffc02012f8 <vprintfmt+0x244>
ffffffffc02012ea:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02012ec:	85a6                	mv	a1,s1
ffffffffc02012ee:	02000513          	li	a0,32
ffffffffc02012f2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02012f4:	fe0d9be3          	bnez	s11,ffffffffc02012ea <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02012f8:	6a02                	ld	s4,0(sp)
ffffffffc02012fa:	bbd5                	j	ffffffffc02010ee <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02012fc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012fe:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201302:	01174463          	blt	a4,a7,ffffffffc020130a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201306:	08088d63          	beqz	a7,ffffffffc02013a0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020130a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020130e:	0a044d63          	bltz	s0,ffffffffc02013c8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201312:	8622                	mv	a2,s0
ffffffffc0201314:	8a66                	mv	s4,s9
ffffffffc0201316:	46a9                	li	a3,10
ffffffffc0201318:	bdcd                	j	ffffffffc020120a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020131a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020131e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201320:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201322:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201326:	8fb5                	xor	a5,a5,a3
ffffffffc0201328:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020132c:	02d74163          	blt	a4,a3,ffffffffc020134e <vprintfmt+0x29a>
ffffffffc0201330:	00369793          	slli	a5,a3,0x3
ffffffffc0201334:	97de                	add	a5,a5,s7
ffffffffc0201336:	639c                	ld	a5,0(a5)
ffffffffc0201338:	cb99                	beqz	a5,ffffffffc020134e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020133a:	86be                	mv	a3,a5
ffffffffc020133c:	00001617          	auipc	a2,0x1
ffffffffc0201340:	d6460613          	addi	a2,a2,-668 # ffffffffc02020a0 <buddy_pmm_manager+0x238>
ffffffffc0201344:	85a6                	mv	a1,s1
ffffffffc0201346:	854a                	mv	a0,s2
ffffffffc0201348:	0ce000ef          	jal	ra,ffffffffc0201416 <printfmt>
ffffffffc020134c:	b34d                	j	ffffffffc02010ee <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020134e:	00001617          	auipc	a2,0x1
ffffffffc0201352:	d4260613          	addi	a2,a2,-702 # ffffffffc0202090 <buddy_pmm_manager+0x228>
ffffffffc0201356:	85a6                	mv	a1,s1
ffffffffc0201358:	854a                	mv	a0,s2
ffffffffc020135a:	0bc000ef          	jal	ra,ffffffffc0201416 <printfmt>
ffffffffc020135e:	bb41                	j	ffffffffc02010ee <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201360:	00001417          	auipc	s0,0x1
ffffffffc0201364:	d2840413          	addi	s0,s0,-728 # ffffffffc0202088 <buddy_pmm_manager+0x220>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201368:	85e2                	mv	a1,s8
ffffffffc020136a:	8522                	mv	a0,s0
ffffffffc020136c:	e43e                	sd	a5,8(sp)
ffffffffc020136e:	0fc000ef          	jal	ra,ffffffffc020146a <strnlen>
ffffffffc0201372:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201376:	01b05b63          	blez	s11,ffffffffc020138c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020137a:	67a2                	ld	a5,8(sp)
ffffffffc020137c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201380:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201382:	85a6                	mv	a1,s1
ffffffffc0201384:	8552                	mv	a0,s4
ffffffffc0201386:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201388:	fe0d9ce3          	bnez	s11,ffffffffc0201380 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020138c:	00044783          	lbu	a5,0(s0)
ffffffffc0201390:	00140a13          	addi	s4,s0,1
ffffffffc0201394:	0007851b          	sext.w	a0,a5
ffffffffc0201398:	d3a5                	beqz	a5,ffffffffc02012f8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020139a:	05e00413          	li	s0,94
ffffffffc020139e:	bf39                	j	ffffffffc02012bc <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02013a0:	000a2403          	lw	s0,0(s4)
ffffffffc02013a4:	b7ad                	j	ffffffffc020130e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02013a6:	000a6603          	lwu	a2,0(s4)
ffffffffc02013aa:	46a1                	li	a3,8
ffffffffc02013ac:	8a2e                	mv	s4,a1
ffffffffc02013ae:	bdb1                	j	ffffffffc020120a <vprintfmt+0x156>
ffffffffc02013b0:	000a6603          	lwu	a2,0(s4)
ffffffffc02013b4:	46a9                	li	a3,10
ffffffffc02013b6:	8a2e                	mv	s4,a1
ffffffffc02013b8:	bd89                	j	ffffffffc020120a <vprintfmt+0x156>
ffffffffc02013ba:	000a6603          	lwu	a2,0(s4)
ffffffffc02013be:	46c1                	li	a3,16
ffffffffc02013c0:	8a2e                	mv	s4,a1
ffffffffc02013c2:	b5a1                	j	ffffffffc020120a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02013c4:	9902                	jalr	s2
ffffffffc02013c6:	bf09                	j	ffffffffc02012d8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02013c8:	85a6                	mv	a1,s1
ffffffffc02013ca:	02d00513          	li	a0,45
ffffffffc02013ce:	e03e                	sd	a5,0(sp)
ffffffffc02013d0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02013d2:	6782                	ld	a5,0(sp)
ffffffffc02013d4:	8a66                	mv	s4,s9
ffffffffc02013d6:	40800633          	neg	a2,s0
ffffffffc02013da:	46a9                	li	a3,10
ffffffffc02013dc:	b53d                	j	ffffffffc020120a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02013de:	03b05163          	blez	s11,ffffffffc0201400 <vprintfmt+0x34c>
ffffffffc02013e2:	02d00693          	li	a3,45
ffffffffc02013e6:	f6d79de3          	bne	a5,a3,ffffffffc0201360 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02013ea:	00001417          	auipc	s0,0x1
ffffffffc02013ee:	c9e40413          	addi	s0,s0,-866 # ffffffffc0202088 <buddy_pmm_manager+0x220>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013f2:	02800793          	li	a5,40
ffffffffc02013f6:	02800513          	li	a0,40
ffffffffc02013fa:	00140a13          	addi	s4,s0,1
ffffffffc02013fe:	bd6d                	j	ffffffffc02012b8 <vprintfmt+0x204>
ffffffffc0201400:	00001a17          	auipc	s4,0x1
ffffffffc0201404:	c89a0a13          	addi	s4,s4,-887 # ffffffffc0202089 <buddy_pmm_manager+0x221>
ffffffffc0201408:	02800513          	li	a0,40
ffffffffc020140c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201410:	05e00413          	li	s0,94
ffffffffc0201414:	b565                	j	ffffffffc02012bc <vprintfmt+0x208>

ffffffffc0201416 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201416:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201418:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020141c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020141e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201420:	ec06                	sd	ra,24(sp)
ffffffffc0201422:	f83a                	sd	a4,48(sp)
ffffffffc0201424:	fc3e                	sd	a5,56(sp)
ffffffffc0201426:	e0c2                	sd	a6,64(sp)
ffffffffc0201428:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020142a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020142c:	c89ff0ef          	jal	ra,ffffffffc02010b4 <vprintfmt>
}
ffffffffc0201430:	60e2                	ld	ra,24(sp)
ffffffffc0201432:	6161                	addi	sp,sp,80
ffffffffc0201434:	8082                	ret

ffffffffc0201436 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201436:	4781                	li	a5,0
ffffffffc0201438:	00005717          	auipc	a4,0x5
ffffffffc020143c:	bd873703          	ld	a4,-1064(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201440:	88ba                	mv	a7,a4
ffffffffc0201442:	852a                	mv	a0,a0
ffffffffc0201444:	85be                	mv	a1,a5
ffffffffc0201446:	863e                	mv	a2,a5
ffffffffc0201448:	00000073          	ecall
ffffffffc020144c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020144e:	8082                	ret

ffffffffc0201450 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201450:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201454:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201456:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201458:	cb81                	beqz	a5,ffffffffc0201468 <strlen+0x18>
        cnt ++;
ffffffffc020145a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020145c:	00a707b3          	add	a5,a4,a0
ffffffffc0201460:	0007c783          	lbu	a5,0(a5)
ffffffffc0201464:	fbfd                	bnez	a5,ffffffffc020145a <strlen+0xa>
ffffffffc0201466:	8082                	ret
    }
    return cnt;
}
ffffffffc0201468:	8082                	ret

ffffffffc020146a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020146a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020146c:	e589                	bnez	a1,ffffffffc0201476 <strnlen+0xc>
ffffffffc020146e:	a811                	j	ffffffffc0201482 <strnlen+0x18>
        cnt ++;
ffffffffc0201470:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201472:	00f58863          	beq	a1,a5,ffffffffc0201482 <strnlen+0x18>
ffffffffc0201476:	00f50733          	add	a4,a0,a5
ffffffffc020147a:	00074703          	lbu	a4,0(a4)
ffffffffc020147e:	fb6d                	bnez	a4,ffffffffc0201470 <strnlen+0x6>
ffffffffc0201480:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201482:	852e                	mv	a0,a1
ffffffffc0201484:	8082                	ret

ffffffffc0201486 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201486:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020148a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020148e:	cb89                	beqz	a5,ffffffffc02014a0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201490:	0505                	addi	a0,a0,1
ffffffffc0201492:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201494:	fee789e3          	beq	a5,a4,ffffffffc0201486 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201498:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020149c:	9d19                	subw	a0,a0,a4
ffffffffc020149e:	8082                	ret
ffffffffc02014a0:	4501                	li	a0,0
ffffffffc02014a2:	bfed                	j	ffffffffc020149c <strcmp+0x16>

ffffffffc02014a4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014a4:	c20d                	beqz	a2,ffffffffc02014c6 <strncmp+0x22>
ffffffffc02014a6:	962e                	add	a2,a2,a1
ffffffffc02014a8:	a031                	j	ffffffffc02014b4 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02014aa:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014ac:	00e79a63          	bne	a5,a4,ffffffffc02014c0 <strncmp+0x1c>
ffffffffc02014b0:	00b60b63          	beq	a2,a1,ffffffffc02014c6 <strncmp+0x22>
ffffffffc02014b4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02014b8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014ba:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02014be:	f7f5                	bnez	a5,ffffffffc02014aa <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014c0:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02014c4:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014c6:	4501                	li	a0,0
ffffffffc02014c8:	8082                	ret

ffffffffc02014ca <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02014ca:	ca01                	beqz	a2,ffffffffc02014da <memset+0x10>
ffffffffc02014cc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02014ce:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02014d0:	0785                	addi	a5,a5,1
ffffffffc02014d2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02014d6:	fec79de3          	bne	a5,a2,ffffffffc02014d0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02014da:	8082                	ret
