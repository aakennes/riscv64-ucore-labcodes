
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01660613          	addi	a2,a2,22 # 80204028 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	175000ef          	jal	ra,80200996 <memset>

    cons_init();  // init the console
    80200026:	14a000ef          	jal	ra,80200170 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	97e58593          	addi	a1,a1,-1666 # 802009a8 <etext>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	99650513          	addi	a0,a0,-1642 # 802009c8 <etext+0x20>
    8020003a:	030000ef          	jal	ra,8020006a <cprintf>

    print_kerninfo();
    8020003e:	062000ef          	jal	ra,802000a0 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	13e000ef          	jal	ra,80200180 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0e8000ef          	jal	ra,8020012e <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	130000ef          	jal	ra,8020017a <intr_enable>
    
    while (1)
    8020004e:	a001                	j	8020004e <kern_init+0x44>

0000000080200050 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200050:	1141                	addi	sp,sp,-16
    80200052:	e022                	sd	s0,0(sp)
    80200054:	e406                	sd	ra,8(sp)
    80200056:	842e                	mv	s0,a1
    cons_putc(c);
    80200058:	11a000ef          	jal	ra,80200172 <cons_putc>
    (*cnt)++;
    8020005c:	401c                	lw	a5,0(s0)
}
    8020005e:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200060:	2785                	addiw	a5,a5,1
    80200062:	c01c                	sw	a5,0(s0)
}
    80200064:	6402                	ld	s0,0(sp)
    80200066:	0141                	addi	sp,sp,16
    80200068:	8082                	ret

000000008020006a <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    8020006a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    8020006c:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200070:	8e2a                	mv	t3,a0
    80200072:	f42e                	sd	a1,40(sp)
    80200074:	f832                	sd	a2,48(sp)
    80200076:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200078:	00000517          	auipc	a0,0x0
    8020007c:	fd850513          	addi	a0,a0,-40 # 80200050 <cputch>
    80200080:	004c                	addi	a1,sp,4
    80200082:	869a                	mv	a3,t1
    80200084:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    80200086:	ec06                	sd	ra,24(sp)
    80200088:	e0ba                	sd	a4,64(sp)
    8020008a:	e4be                	sd	a5,72(sp)
    8020008c:	e8c2                	sd	a6,80(sp)
    8020008e:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200090:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200092:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200094:	516000ef          	jal	ra,802005aa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200098:	60e2                	ld	ra,24(sp)
    8020009a:	4512                	lw	a0,4(sp)
    8020009c:	6125                	addi	sp,sp,96
    8020009e:	8082                	ret

00000000802000a0 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a0:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a2:	00001517          	auipc	a0,0x1
    802000a6:	92e50513          	addi	a0,a0,-1746 # 802009d0 <etext+0x28>
void print_kerninfo(void) {
    802000aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000ac:	fbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5a58593          	addi	a1,a1,-166 # 8020000a <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	93850513          	addi	a0,a0,-1736 # 802009f0 <etext+0x48>
    802000c0:	fabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	8e458593          	addi	a1,a1,-1820 # 802009a8 <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	94450513          	addi	a0,a0,-1724 # 80200a10 <etext+0x68>
    802000d4:	f97ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3858593          	addi	a1,a1,-200 # 80204010 <ticks>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	95050513          	addi	a0,a0,-1712 # 80200a30 <etext+0x88>
    802000e8:	f83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f3c58593          	addi	a1,a1,-196 # 80204028 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	95c50513          	addi	a0,a0,-1700 # 80200a50 <etext+0xa8>
    802000fc:	f6fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200100:	00004597          	auipc	a1,0x4
    80200104:	32758593          	addi	a1,a1,807 # 80204427 <end+0x3ff>
    80200108:	00000797          	auipc	a5,0x0
    8020010c:	f0278793          	addi	a5,a5,-254 # 8020000a <kern_init>
    80200110:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200114:	43f7d593          	srai	a1,a5,0x3f
}
    80200118:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	3ff5f593          	andi	a1,a1,1023
    8020011e:	95be                	add	a1,a1,a5
    80200120:	85a9                	srai	a1,a1,0xa
    80200122:	00001517          	auipc	a0,0x1
    80200126:	94e50513          	addi	a0,a0,-1714 # 80200a70 <etext+0xc8>
}
    8020012a:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020012c:	bf3d                	j	8020006a <cprintf>

000000008020012e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    8020012e:	1141                	addi	sp,sp,-16
    80200130:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200132:	02000793          	li	a5,32
    80200136:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020013a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020013e:	67e1                	lui	a5,0x18
    80200140:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200144:	953e                	add	a0,a0,a5
    80200146:	001000ef          	jal	ra,80200946 <sbi_set_timer>
}
    8020014a:	60a2                	ld	ra,8(sp)
    ticks = 0;
    8020014c:	00004797          	auipc	a5,0x4
    80200150:	ec07b223          	sd	zero,-316(a5) # 80204010 <ticks>
    cprintf("++ setup timer interrupts\n");
    80200154:	00001517          	auipc	a0,0x1
    80200158:	94c50513          	addi	a0,a0,-1716 # 80200aa0 <etext+0xf8>
}
    8020015c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    8020015e:	b731                	j	8020006a <cprintf>

0000000080200160 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200160:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200164:	67e1                	lui	a5,0x18
    80200166:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    8020016a:	953e                	add	a0,a0,a5
    8020016c:	7da0006f          	j	80200946 <sbi_set_timer>

0000000080200170 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200170:	8082                	ret

0000000080200172 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200172:	0ff57513          	andi	a0,a0,255
    80200176:	7b60006f          	j	8020092c <sbi_console_putchar>

000000008020017a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    8020017a:	100167f3          	csrrsi	a5,sstatus,2
    8020017e:	8082                	ret

0000000080200180 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200180:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200184:	00000797          	auipc	a5,0x0
    80200188:	30478793          	addi	a5,a5,772 # 80200488 <__alltraps>
    8020018c:	10579073          	csrw	stvec,a5
}
    80200190:	8082                	ret

0000000080200192 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200192:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    80200194:	1141                	addi	sp,sp,-16
    80200196:	e022                	sd	s0,0(sp)
    80200198:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019a:	00001517          	auipc	a0,0x1
    8020019e:	92650513          	addi	a0,a0,-1754 # 80200ac0 <etext+0x118>
void print_regs(struct pushregs *gpr) {
    802001a2:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a4:	ec7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001a8:	640c                	ld	a1,8(s0)
    802001aa:	00001517          	auipc	a0,0x1
    802001ae:	92e50513          	addi	a0,a0,-1746 # 80200ad8 <etext+0x130>
    802001b2:	eb9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001b6:	680c                	ld	a1,16(s0)
    802001b8:	00001517          	auipc	a0,0x1
    802001bc:	93850513          	addi	a0,a0,-1736 # 80200af0 <etext+0x148>
    802001c0:	eabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001c4:	6c0c                	ld	a1,24(s0)
    802001c6:	00001517          	auipc	a0,0x1
    802001ca:	94250513          	addi	a0,a0,-1726 # 80200b08 <etext+0x160>
    802001ce:	e9dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001d2:	700c                	ld	a1,32(s0)
    802001d4:	00001517          	auipc	a0,0x1
    802001d8:	94c50513          	addi	a0,a0,-1716 # 80200b20 <etext+0x178>
    802001dc:	e8fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e0:	740c                	ld	a1,40(s0)
    802001e2:	00001517          	auipc	a0,0x1
    802001e6:	95650513          	addi	a0,a0,-1706 # 80200b38 <etext+0x190>
    802001ea:	e81ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001ee:	780c                	ld	a1,48(s0)
    802001f0:	00001517          	auipc	a0,0x1
    802001f4:	96050513          	addi	a0,a0,-1696 # 80200b50 <etext+0x1a8>
    802001f8:	e73ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    802001fc:	7c0c                	ld	a1,56(s0)
    802001fe:	00001517          	auipc	a0,0x1
    80200202:	96a50513          	addi	a0,a0,-1686 # 80200b68 <etext+0x1c0>
    80200206:	e65ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    8020020a:	602c                	ld	a1,64(s0)
    8020020c:	00001517          	auipc	a0,0x1
    80200210:	97450513          	addi	a0,a0,-1676 # 80200b80 <etext+0x1d8>
    80200214:	e57ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200218:	642c                	ld	a1,72(s0)
    8020021a:	00001517          	auipc	a0,0x1
    8020021e:	97e50513          	addi	a0,a0,-1666 # 80200b98 <etext+0x1f0>
    80200222:	e49ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    80200226:	682c                	ld	a1,80(s0)
    80200228:	00001517          	auipc	a0,0x1
    8020022c:	98850513          	addi	a0,a0,-1656 # 80200bb0 <etext+0x208>
    80200230:	e3bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200234:	6c2c                	ld	a1,88(s0)
    80200236:	00001517          	auipc	a0,0x1
    8020023a:	99250513          	addi	a0,a0,-1646 # 80200bc8 <etext+0x220>
    8020023e:	e2dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200242:	702c                	ld	a1,96(s0)
    80200244:	00001517          	auipc	a0,0x1
    80200248:	99c50513          	addi	a0,a0,-1636 # 80200be0 <etext+0x238>
    8020024c:	e1fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200250:	742c                	ld	a1,104(s0)
    80200252:	00001517          	auipc	a0,0x1
    80200256:	9a650513          	addi	a0,a0,-1626 # 80200bf8 <etext+0x250>
    8020025a:	e11ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    8020025e:	782c                	ld	a1,112(s0)
    80200260:	00001517          	auipc	a0,0x1
    80200264:	9b050513          	addi	a0,a0,-1616 # 80200c10 <etext+0x268>
    80200268:	e03ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    8020026c:	7c2c                	ld	a1,120(s0)
    8020026e:	00001517          	auipc	a0,0x1
    80200272:	9ba50513          	addi	a0,a0,-1606 # 80200c28 <etext+0x280>
    80200276:	df5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    8020027a:	604c                	ld	a1,128(s0)
    8020027c:	00001517          	auipc	a0,0x1
    80200280:	9c450513          	addi	a0,a0,-1596 # 80200c40 <etext+0x298>
    80200284:	de7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200288:	644c                	ld	a1,136(s0)
    8020028a:	00001517          	auipc	a0,0x1
    8020028e:	9ce50513          	addi	a0,a0,-1586 # 80200c58 <etext+0x2b0>
    80200292:	dd9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    80200296:	684c                	ld	a1,144(s0)
    80200298:	00001517          	auipc	a0,0x1
    8020029c:	9d850513          	addi	a0,a0,-1576 # 80200c70 <etext+0x2c8>
    802002a0:	dcbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002a4:	6c4c                	ld	a1,152(s0)
    802002a6:	00001517          	auipc	a0,0x1
    802002aa:	9e250513          	addi	a0,a0,-1566 # 80200c88 <etext+0x2e0>
    802002ae:	dbdff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002b2:	704c                	ld	a1,160(s0)
    802002b4:	00001517          	auipc	a0,0x1
    802002b8:	9ec50513          	addi	a0,a0,-1556 # 80200ca0 <etext+0x2f8>
    802002bc:	dafff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c0:	744c                	ld	a1,168(s0)
    802002c2:	00001517          	auipc	a0,0x1
    802002c6:	9f650513          	addi	a0,a0,-1546 # 80200cb8 <etext+0x310>
    802002ca:	da1ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002ce:	784c                	ld	a1,176(s0)
    802002d0:	00001517          	auipc	a0,0x1
    802002d4:	a0050513          	addi	a0,a0,-1536 # 80200cd0 <etext+0x328>
    802002d8:	d93ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002dc:	7c4c                	ld	a1,184(s0)
    802002de:	00001517          	auipc	a0,0x1
    802002e2:	a0a50513          	addi	a0,a0,-1526 # 80200ce8 <etext+0x340>
    802002e6:	d85ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002ea:	606c                	ld	a1,192(s0)
    802002ec:	00001517          	auipc	a0,0x1
    802002f0:	a1450513          	addi	a0,a0,-1516 # 80200d00 <etext+0x358>
    802002f4:	d77ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002f8:	646c                	ld	a1,200(s0)
    802002fa:	00001517          	auipc	a0,0x1
    802002fe:	a1e50513          	addi	a0,a0,-1506 # 80200d18 <etext+0x370>
    80200302:	d69ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    80200306:	686c                	ld	a1,208(s0)
    80200308:	00001517          	auipc	a0,0x1
    8020030c:	a2850513          	addi	a0,a0,-1496 # 80200d30 <etext+0x388>
    80200310:	d5bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200314:	6c6c                	ld	a1,216(s0)
    80200316:	00001517          	auipc	a0,0x1
    8020031a:	a3250513          	addi	a0,a0,-1486 # 80200d48 <etext+0x3a0>
    8020031e:	d4dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200322:	706c                	ld	a1,224(s0)
    80200324:	00001517          	auipc	a0,0x1
    80200328:	a3c50513          	addi	a0,a0,-1476 # 80200d60 <etext+0x3b8>
    8020032c:	d3fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200330:	746c                	ld	a1,232(s0)
    80200332:	00001517          	auipc	a0,0x1
    80200336:	a4650513          	addi	a0,a0,-1466 # 80200d78 <etext+0x3d0>
    8020033a:	d31ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    8020033e:	786c                	ld	a1,240(s0)
    80200340:	00001517          	auipc	a0,0x1
    80200344:	a5050513          	addi	a0,a0,-1456 # 80200d90 <etext+0x3e8>
    80200348:	d23ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020034c:	7c6c                	ld	a1,248(s0)
}
    8020034e:	6402                	ld	s0,0(sp)
    80200350:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200352:	00001517          	auipc	a0,0x1
    80200356:	a5650513          	addi	a0,a0,-1450 # 80200da8 <etext+0x400>
}
    8020035a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020035c:	b339                	j	8020006a <cprintf>

000000008020035e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    8020035e:	1141                	addi	sp,sp,-16
    80200360:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200362:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200364:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200366:	00001517          	auipc	a0,0x1
    8020036a:	a5a50513          	addi	a0,a0,-1446 # 80200dc0 <etext+0x418>
void print_trapframe(struct trapframe *tf) {
    8020036e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200370:	cfbff0ef          	jal	ra,8020006a <cprintf>
    print_regs(&tf->gpr);
    80200374:	8522                	mv	a0,s0
    80200376:	e1dff0ef          	jal	ra,80200192 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    8020037a:	10043583          	ld	a1,256(s0)
    8020037e:	00001517          	auipc	a0,0x1
    80200382:	a5a50513          	addi	a0,a0,-1446 # 80200dd8 <etext+0x430>
    80200386:	ce5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    8020038a:	10843583          	ld	a1,264(s0)
    8020038e:	00001517          	auipc	a0,0x1
    80200392:	a6250513          	addi	a0,a0,-1438 # 80200df0 <etext+0x448>
    80200396:	cd5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    8020039a:	11043583          	ld	a1,272(s0)
    8020039e:	00001517          	auipc	a0,0x1
    802003a2:	a6a50513          	addi	a0,a0,-1430 # 80200e08 <etext+0x460>
    802003a6:	cc5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003aa:	11843583          	ld	a1,280(s0)
}
    802003ae:	6402                	ld	s0,0(sp)
    802003b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b2:	00001517          	auipc	a0,0x1
    802003b6:	a6e50513          	addi	a0,a0,-1426 # 80200e20 <etext+0x478>
}
    802003ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003bc:	b17d                	j	8020006a <cprintf>

00000000802003be <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003be:	11853783          	ld	a5,280(a0)
    802003c2:	472d                	li	a4,11
    802003c4:	0786                	slli	a5,a5,0x1
    802003c6:	8385                	srli	a5,a5,0x1
    802003c8:	08f76163          	bltu	a4,a5,8020044a <interrupt_handler+0x8c>
    802003cc:	00001717          	auipc	a4,0x1
    802003d0:	b1c70713          	addi	a4,a4,-1252 # 80200ee8 <etext+0x540>
    802003d4:	078a                	slli	a5,a5,0x2
    802003d6:	97ba                	add	a5,a5,a4
    802003d8:	439c                	lw	a5,0(a5)
    802003da:	97ba                	add	a5,a5,a4
    802003dc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003de:	00001517          	auipc	a0,0x1
    802003e2:	aba50513          	addi	a0,a0,-1350 # 80200e98 <etext+0x4f0>
    802003e6:	b151                	j	8020006a <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003e8:	00001517          	auipc	a0,0x1
    802003ec:	a9050513          	addi	a0,a0,-1392 # 80200e78 <etext+0x4d0>
    802003f0:	b9ad                	j	8020006a <cprintf>
            cprintf("User software interrupt\n");
    802003f2:	00001517          	auipc	a0,0x1
    802003f6:	a4650513          	addi	a0,a0,-1466 # 80200e38 <etext+0x490>
    802003fa:	b985                	j	8020006a <cprintf>
            cprintf("Supervisor software interrupt\n");
    802003fc:	00001517          	auipc	a0,0x1
    80200400:	a5c50513          	addi	a0,a0,-1444 # 80200e58 <etext+0x4b0>
    80200404:	b19d                	j	8020006a <cprintf>
void interrupt_handler(struct trapframe *tf) {
    80200406:	1141                	addi	sp,sp,-16
    80200408:	e022                	sd	s0,0(sp)
    8020040a:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
    8020040c:	d55ff0ef          	jal	ra,80200160 <clock_set_next_event>
            ticks+=1;
    80200410:	00004797          	auipc	a5,0x4
    80200414:	c0078793          	addi	a5,a5,-1024 # 80204010 <ticks>
    80200418:	6398                	ld	a4,0(a5)
            if(ticks==TICK_NUM)//直接用100也可以，但全局变量定义了TICK_NUM，那就用吧
    8020041a:	06400693          	li	a3,100
    8020041e:	00004417          	auipc	s0,0x4
    80200422:	bfa40413          	addi	s0,s0,-1030 # 80204018 <num>
            ticks+=1;
    80200426:	0705                	addi	a4,a4,1
    80200428:	e398                	sd	a4,0(a5)
            if(ticks==TICK_NUM)//直接用100也可以，但全局变量定义了TICK_NUM，那就用吧
    8020042a:	639c                	ld	a5,0(a5)
    8020042c:	02d78063          	beq	a5,a3,8020044c <interrupt_handler+0x8e>
            {
                print_ticks();
                num+=1;
                ticks=0;
            }
            if(num==10)
    80200430:	6018                	ld	a4,0(s0)
    80200432:	47a9                	li	a5,10
    80200434:	02f70c63          	beq	a4,a5,8020046c <interrupt_handler+0xae>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    80200438:	60a2                	ld	ra,8(sp)
    8020043a:	6402                	ld	s0,0(sp)
    8020043c:	0141                	addi	sp,sp,16
    8020043e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
    80200440:	00001517          	auipc	a0,0x1
    80200444:	a8850513          	addi	a0,a0,-1400 # 80200ec8 <etext+0x520>
    80200448:	b10d                	j	8020006a <cprintf>
            print_trapframe(tf);
    8020044a:	bf11                	j	8020035e <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    8020044c:	06400593          	li	a1,100
    80200450:	00001517          	auipc	a0,0x1
    80200454:	a6850513          	addi	a0,a0,-1432 # 80200eb8 <etext+0x510>
    80200458:	c13ff0ef          	jal	ra,8020006a <cprintf>
                num+=1;
    8020045c:	601c                	ld	a5,0(s0)
    8020045e:	0785                	addi	a5,a5,1
    80200460:	e01c                	sd	a5,0(s0)
                ticks=0;
    80200462:	00004797          	auipc	a5,0x4
    80200466:	ba07b723          	sd	zero,-1106(a5) # 80204010 <ticks>
    8020046a:	b7d9                	j	80200430 <interrupt_handler+0x72>
}
    8020046c:	6402                	ld	s0,0(sp)
    8020046e:	60a2                	ld	ra,8(sp)
    80200470:	0141                	addi	sp,sp,16
                sbi_shutdown();//参见./libs/sbi.h
    80200472:	a1fd                	j	80200960 <sbi_shutdown>

0000000080200474 <trap>:
    }
}

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    80200474:	11853783          	ld	a5,280(a0)
    80200478:	0007c763          	bltz	a5,80200486 <trap+0x12>
    switch (tf->cause) {
    8020047c:	472d                	li	a4,11
    8020047e:	00f76363          	bltu	a4,a5,80200484 <trap+0x10>
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) { trap_dispatch(tf); }
    80200482:	8082                	ret
            print_trapframe(tf);
    80200484:	bde9                	j	8020035e <print_trapframe>
        interrupt_handler(tf);
    80200486:	bf25                	j	802003be <interrupt_handler>

0000000080200488 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    80200488:	14011073          	csrw	sscratch,sp
    8020048c:	712d                	addi	sp,sp,-288
    8020048e:	e002                	sd	zero,0(sp)
    80200490:	e406                	sd	ra,8(sp)
    80200492:	ec0e                	sd	gp,24(sp)
    80200494:	f012                	sd	tp,32(sp)
    80200496:	f416                	sd	t0,40(sp)
    80200498:	f81a                	sd	t1,48(sp)
    8020049a:	fc1e                	sd	t2,56(sp)
    8020049c:	e0a2                	sd	s0,64(sp)
    8020049e:	e4a6                	sd	s1,72(sp)
    802004a0:	e8aa                	sd	a0,80(sp)
    802004a2:	ecae                	sd	a1,88(sp)
    802004a4:	f0b2                	sd	a2,96(sp)
    802004a6:	f4b6                	sd	a3,104(sp)
    802004a8:	f8ba                	sd	a4,112(sp)
    802004aa:	fcbe                	sd	a5,120(sp)
    802004ac:	e142                	sd	a6,128(sp)
    802004ae:	e546                	sd	a7,136(sp)
    802004b0:	e94a                	sd	s2,144(sp)
    802004b2:	ed4e                	sd	s3,152(sp)
    802004b4:	f152                	sd	s4,160(sp)
    802004b6:	f556                	sd	s5,168(sp)
    802004b8:	f95a                	sd	s6,176(sp)
    802004ba:	fd5e                	sd	s7,184(sp)
    802004bc:	e1e2                	sd	s8,192(sp)
    802004be:	e5e6                	sd	s9,200(sp)
    802004c0:	e9ea                	sd	s10,208(sp)
    802004c2:	edee                	sd	s11,216(sp)
    802004c4:	f1f2                	sd	t3,224(sp)
    802004c6:	f5f6                	sd	t4,232(sp)
    802004c8:	f9fa                	sd	t5,240(sp)
    802004ca:	fdfe                	sd	t6,248(sp)
    802004cc:	14001473          	csrrw	s0,sscratch,zero
    802004d0:	100024f3          	csrr	s1,sstatus
    802004d4:	14102973          	csrr	s2,sepc
    802004d8:	143029f3          	csrr	s3,stval
    802004dc:	14202a73          	csrr	s4,scause
    802004e0:	e822                	sd	s0,16(sp)
    802004e2:	e226                	sd	s1,256(sp)
    802004e4:	e64a                	sd	s2,264(sp)
    802004e6:	ea4e                	sd	s3,272(sp)
    802004e8:	ee52                	sd	s4,280(sp)

    move  a0, sp
    802004ea:	850a                	mv	a0,sp
    jal trap
    802004ec:	f89ff0ef          	jal	ra,80200474 <trap>

00000000802004f0 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    802004f0:	6492                	ld	s1,256(sp)
    802004f2:	6932                	ld	s2,264(sp)
    802004f4:	10049073          	csrw	sstatus,s1
    802004f8:	14191073          	csrw	sepc,s2
    802004fc:	60a2                	ld	ra,8(sp)
    802004fe:	61e2                	ld	gp,24(sp)
    80200500:	7202                	ld	tp,32(sp)
    80200502:	72a2                	ld	t0,40(sp)
    80200504:	7342                	ld	t1,48(sp)
    80200506:	73e2                	ld	t2,56(sp)
    80200508:	6406                	ld	s0,64(sp)
    8020050a:	64a6                	ld	s1,72(sp)
    8020050c:	6546                	ld	a0,80(sp)
    8020050e:	65e6                	ld	a1,88(sp)
    80200510:	7606                	ld	a2,96(sp)
    80200512:	76a6                	ld	a3,104(sp)
    80200514:	7746                	ld	a4,112(sp)
    80200516:	77e6                	ld	a5,120(sp)
    80200518:	680a                	ld	a6,128(sp)
    8020051a:	68aa                	ld	a7,136(sp)
    8020051c:	694a                	ld	s2,144(sp)
    8020051e:	69ea                	ld	s3,152(sp)
    80200520:	7a0a                	ld	s4,160(sp)
    80200522:	7aaa                	ld	s5,168(sp)
    80200524:	7b4a                	ld	s6,176(sp)
    80200526:	7bea                	ld	s7,184(sp)
    80200528:	6c0e                	ld	s8,192(sp)
    8020052a:	6cae                	ld	s9,200(sp)
    8020052c:	6d4e                	ld	s10,208(sp)
    8020052e:	6dee                	ld	s11,216(sp)
    80200530:	7e0e                	ld	t3,224(sp)
    80200532:	7eae                	ld	t4,232(sp)
    80200534:	7f4e                	ld	t5,240(sp)
    80200536:	7fee                	ld	t6,248(sp)
    80200538:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    8020053a:	10200073          	sret

000000008020053e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    8020053e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200542:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200544:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200548:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    8020054a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    8020054e:	f022                	sd	s0,32(sp)
    80200550:	ec26                	sd	s1,24(sp)
    80200552:	e84a                	sd	s2,16(sp)
    80200554:	f406                	sd	ra,40(sp)
    80200556:	e44e                	sd	s3,8(sp)
    80200558:	84aa                	mv	s1,a0
    8020055a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    8020055c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    80200560:	2a01                	sext.w	s4,s4
    if (num >= base) {
    80200562:	03067e63          	bgeu	a2,a6,8020059e <printnum+0x60>
    80200566:	89be                	mv	s3,a5
        while (-- width > 0)
    80200568:	00805763          	blez	s0,80200576 <printnum+0x38>
    8020056c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    8020056e:	85ca                	mv	a1,s2
    80200570:	854e                	mv	a0,s3
    80200572:	9482                	jalr	s1
        while (-- width > 0)
    80200574:	fc65                	bnez	s0,8020056c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    80200576:	1a02                	slli	s4,s4,0x20
    80200578:	00001797          	auipc	a5,0x1
    8020057c:	9a078793          	addi	a5,a5,-1632 # 80200f18 <etext+0x570>
    80200580:	020a5a13          	srli	s4,s4,0x20
    80200584:	9a3e                	add	s4,s4,a5
}
    80200586:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200588:	000a4503          	lbu	a0,0(s4)
}
    8020058c:	70a2                	ld	ra,40(sp)
    8020058e:	69a2                	ld	s3,8(sp)
    80200590:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200592:	85ca                	mv	a1,s2
    80200594:	87a6                	mv	a5,s1
}
    80200596:	6942                	ld	s2,16(sp)
    80200598:	64e2                	ld	s1,24(sp)
    8020059a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    8020059c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    8020059e:	03065633          	divu	a2,a2,a6
    802005a2:	8722                	mv	a4,s0
    802005a4:	f9bff0ef          	jal	ra,8020053e <printnum>
    802005a8:	b7f9                	j	80200576 <printnum+0x38>

00000000802005aa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    802005aa:	7119                	addi	sp,sp,-128
    802005ac:	f4a6                	sd	s1,104(sp)
    802005ae:	f0ca                	sd	s2,96(sp)
    802005b0:	ecce                	sd	s3,88(sp)
    802005b2:	e8d2                	sd	s4,80(sp)
    802005b4:	e4d6                	sd	s5,72(sp)
    802005b6:	e0da                	sd	s6,64(sp)
    802005b8:	fc5e                	sd	s7,56(sp)
    802005ba:	f06a                	sd	s10,32(sp)
    802005bc:	fc86                	sd	ra,120(sp)
    802005be:	f8a2                	sd	s0,112(sp)
    802005c0:	f862                	sd	s8,48(sp)
    802005c2:	f466                	sd	s9,40(sp)
    802005c4:	ec6e                	sd	s11,24(sp)
    802005c6:	892a                	mv	s2,a0
    802005c8:	84ae                	mv	s1,a1
    802005ca:	8d32                	mv	s10,a2
    802005cc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005ce:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    802005d2:	5b7d                	li	s6,-1
    802005d4:	00001a97          	auipc	s5,0x1
    802005d8:	978a8a93          	addi	s5,s5,-1672 # 80200f4c <etext+0x5a4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802005dc:	00001b97          	auipc	s7,0x1
    802005e0:	b4cb8b93          	addi	s7,s7,-1204 # 80201128 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005e4:	000d4503          	lbu	a0,0(s10)
    802005e8:	001d0413          	addi	s0,s10,1
    802005ec:	01350a63          	beq	a0,s3,80200600 <vprintfmt+0x56>
            if (ch == '\0') {
    802005f0:	c121                	beqz	a0,80200630 <vprintfmt+0x86>
            putch(ch, putdat);
    802005f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802005f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005f8:	fff44503          	lbu	a0,-1(s0)
    802005fc:	ff351ae3          	bne	a0,s3,802005f0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    80200600:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200604:	02000793          	li	a5,32
        lflag = altflag = 0;
    80200608:	4c81                	li	s9,0
    8020060a:	4881                	li	a7,0
        width = precision = -1;
    8020060c:	5c7d                	li	s8,-1
    8020060e:	5dfd                	li	s11,-1
    80200610:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    80200614:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200616:	fdd6059b          	addiw	a1,a2,-35
    8020061a:	0ff5f593          	andi	a1,a1,255
    8020061e:	00140d13          	addi	s10,s0,1
    80200622:	04b56263          	bltu	a0,a1,80200666 <vprintfmt+0xbc>
    80200626:	058a                	slli	a1,a1,0x2
    80200628:	95d6                	add	a1,a1,s5
    8020062a:	4194                	lw	a3,0(a1)
    8020062c:	96d6                	add	a3,a3,s5
    8020062e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200630:	70e6                	ld	ra,120(sp)
    80200632:	7446                	ld	s0,112(sp)
    80200634:	74a6                	ld	s1,104(sp)
    80200636:	7906                	ld	s2,96(sp)
    80200638:	69e6                	ld	s3,88(sp)
    8020063a:	6a46                	ld	s4,80(sp)
    8020063c:	6aa6                	ld	s5,72(sp)
    8020063e:	6b06                	ld	s6,64(sp)
    80200640:	7be2                	ld	s7,56(sp)
    80200642:	7c42                	ld	s8,48(sp)
    80200644:	7ca2                	ld	s9,40(sp)
    80200646:	7d02                	ld	s10,32(sp)
    80200648:	6de2                	ld	s11,24(sp)
    8020064a:	6109                	addi	sp,sp,128
    8020064c:	8082                	ret
            padc = '0';
    8020064e:	87b2                	mv	a5,a2
            goto reswitch;
    80200650:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    80200654:	846a                	mv	s0,s10
    80200656:	00140d13          	addi	s10,s0,1
    8020065a:	fdd6059b          	addiw	a1,a2,-35
    8020065e:	0ff5f593          	andi	a1,a1,255
    80200662:	fcb572e3          	bgeu	a0,a1,80200626 <vprintfmt+0x7c>
            putch('%', putdat);
    80200666:	85a6                	mv	a1,s1
    80200668:	02500513          	li	a0,37
    8020066c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    8020066e:	fff44783          	lbu	a5,-1(s0)
    80200672:	8d22                	mv	s10,s0
    80200674:	f73788e3          	beq	a5,s3,802005e4 <vprintfmt+0x3a>
    80200678:	ffed4783          	lbu	a5,-2(s10)
    8020067c:	1d7d                	addi	s10,s10,-1
    8020067e:	ff379de3          	bne	a5,s3,80200678 <vprintfmt+0xce>
    80200682:	b78d                	j	802005e4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    80200684:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    80200688:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    8020068c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    8020068e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    80200692:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200696:	02d86463          	bltu	a6,a3,802006be <vprintfmt+0x114>
                ch = *fmt;
    8020069a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    8020069e:	002c169b          	slliw	a3,s8,0x2
    802006a2:	0186873b          	addw	a4,a3,s8
    802006a6:	0017171b          	slliw	a4,a4,0x1
    802006aa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    802006ac:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    802006b0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    802006b2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    802006b6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    802006ba:	fed870e3          	bgeu	a6,a3,8020069a <vprintfmt+0xf0>
            if (width < 0)
    802006be:	f40ddce3          	bgez	s11,80200616 <vprintfmt+0x6c>
                width = precision, precision = -1;
    802006c2:	8de2                	mv	s11,s8
    802006c4:	5c7d                	li	s8,-1
    802006c6:	bf81                	j	80200616 <vprintfmt+0x6c>
            if (width < 0)
    802006c8:	fffdc693          	not	a3,s11
    802006cc:	96fd                	srai	a3,a3,0x3f
    802006ce:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    802006d2:	00144603          	lbu	a2,1(s0)
    802006d6:	2d81                	sext.w	s11,s11
    802006d8:	846a                	mv	s0,s10
            goto reswitch;
    802006da:	bf35                	j	80200616 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    802006dc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    802006e0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    802006e4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    802006e6:	846a                	mv	s0,s10
            goto process_precision;
    802006e8:	bfd9                	j	802006be <vprintfmt+0x114>
    if (lflag >= 2) {
    802006ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802006ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802006f0:	01174463          	blt	a4,a7,802006f8 <vprintfmt+0x14e>
    else if (lflag) {
    802006f4:	1a088e63          	beqz	a7,802008b0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    802006f8:	000a3603          	ld	a2,0(s4)
    802006fc:	46c1                	li	a3,16
    802006fe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    80200700:	2781                	sext.w	a5,a5
    80200702:	876e                	mv	a4,s11
    80200704:	85a6                	mv	a1,s1
    80200706:	854a                	mv	a0,s2
    80200708:	e37ff0ef          	jal	ra,8020053e <printnum>
            break;
    8020070c:	bde1                	j	802005e4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    8020070e:	000a2503          	lw	a0,0(s4)
    80200712:	85a6                	mv	a1,s1
    80200714:	0a21                	addi	s4,s4,8
    80200716:	9902                	jalr	s2
            break;
    80200718:	b5f1                	j	802005e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
    8020071a:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020071c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200720:	01174463          	blt	a4,a7,80200728 <vprintfmt+0x17e>
    else if (lflag) {
    80200724:	18088163          	beqz	a7,802008a6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    80200728:	000a3603          	ld	a2,0(s4)
    8020072c:	46a9                	li	a3,10
    8020072e:	8a2e                	mv	s4,a1
    80200730:	bfc1                	j	80200700 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    80200732:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    80200736:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200738:	846a                	mv	s0,s10
            goto reswitch;
    8020073a:	bdf1                	j	80200616 <vprintfmt+0x6c>
            putch(ch, putdat);
    8020073c:	85a6                	mv	a1,s1
    8020073e:	02500513          	li	a0,37
    80200742:	9902                	jalr	s2
            break;
    80200744:	b545                	j	802005e4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    80200746:	00144603          	lbu	a2,1(s0)
            lflag ++;
    8020074a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    8020074c:	846a                	mv	s0,s10
            goto reswitch;
    8020074e:	b5e1                	j	80200616 <vprintfmt+0x6c>
    if (lflag >= 2) {
    80200750:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200752:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200756:	01174463          	blt	a4,a7,8020075e <vprintfmt+0x1b4>
    else if (lflag) {
    8020075a:	14088163          	beqz	a7,8020089c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    8020075e:	000a3603          	ld	a2,0(s4)
    80200762:	46a1                	li	a3,8
    80200764:	8a2e                	mv	s4,a1
    80200766:	bf69                	j	80200700 <vprintfmt+0x156>
            putch('0', putdat);
    80200768:	03000513          	li	a0,48
    8020076c:	85a6                	mv	a1,s1
    8020076e:	e03e                	sd	a5,0(sp)
    80200770:	9902                	jalr	s2
            putch('x', putdat);
    80200772:	85a6                	mv	a1,s1
    80200774:	07800513          	li	a0,120
    80200778:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    8020077a:	0a21                	addi	s4,s4,8
            goto number;
    8020077c:	6782                	ld	a5,0(sp)
    8020077e:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    80200780:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    80200784:	bfb5                	j	80200700 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200786:	000a3403          	ld	s0,0(s4)
    8020078a:	008a0713          	addi	a4,s4,8
    8020078e:	e03a                	sd	a4,0(sp)
    80200790:	14040263          	beqz	s0,802008d4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    80200794:	0fb05763          	blez	s11,80200882 <vprintfmt+0x2d8>
    80200798:	02d00693          	li	a3,45
    8020079c:	0cd79163          	bne	a5,a3,8020085e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007a0:	00044783          	lbu	a5,0(s0)
    802007a4:	0007851b          	sext.w	a0,a5
    802007a8:	cf85                	beqz	a5,802007e0 <vprintfmt+0x236>
    802007aa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    802007ae:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007b2:	000c4563          	bltz	s8,802007bc <vprintfmt+0x212>
    802007b6:	3c7d                	addiw	s8,s8,-1
    802007b8:	036c0263          	beq	s8,s6,802007dc <vprintfmt+0x232>
                    putch('?', putdat);
    802007bc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    802007be:	0e0c8e63          	beqz	s9,802008ba <vprintfmt+0x310>
    802007c2:	3781                	addiw	a5,a5,-32
    802007c4:	0ef47b63          	bgeu	s0,a5,802008ba <vprintfmt+0x310>
                    putch('?', putdat);
    802007c8:	03f00513          	li	a0,63
    802007cc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007ce:	000a4783          	lbu	a5,0(s4)
    802007d2:	3dfd                	addiw	s11,s11,-1
    802007d4:	0a05                	addi	s4,s4,1
    802007d6:	0007851b          	sext.w	a0,a5
    802007da:	ffe1                	bnez	a5,802007b2 <vprintfmt+0x208>
            for (; width > 0; width --) {
    802007dc:	01b05963          	blez	s11,802007ee <vprintfmt+0x244>
    802007e0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    802007e2:	85a6                	mv	a1,s1
    802007e4:	02000513          	li	a0,32
    802007e8:	9902                	jalr	s2
            for (; width > 0; width --) {
    802007ea:	fe0d9be3          	bnez	s11,802007e0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    802007ee:	6a02                	ld	s4,0(sp)
    802007f0:	bbd5                	j	802005e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
    802007f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802007f4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    802007f8:	01174463          	blt	a4,a7,80200800 <vprintfmt+0x256>
    else if (lflag) {
    802007fc:	08088d63          	beqz	a7,80200896 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    80200800:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    80200804:	0a044d63          	bltz	s0,802008be <vprintfmt+0x314>
            num = getint(&ap, lflag);
    80200808:	8622                	mv	a2,s0
    8020080a:	8a66                	mv	s4,s9
    8020080c:	46a9                	li	a3,10
    8020080e:	bdcd                	j	80200700 <vprintfmt+0x156>
            err = va_arg(ap, int);
    80200810:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200814:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200816:	0a21                	addi	s4,s4,8
            if (err < 0) {
    80200818:	41f7d69b          	sraiw	a3,a5,0x1f
    8020081c:	8fb5                	xor	a5,a5,a3
    8020081e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200822:	02d74163          	blt	a4,a3,80200844 <vprintfmt+0x29a>
    80200826:	00369793          	slli	a5,a3,0x3
    8020082a:	97de                	add	a5,a5,s7
    8020082c:	639c                	ld	a5,0(a5)
    8020082e:	cb99                	beqz	a5,80200844 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    80200830:	86be                	mv	a3,a5
    80200832:	00000617          	auipc	a2,0x0
    80200836:	71660613          	addi	a2,a2,1814 # 80200f48 <etext+0x5a0>
    8020083a:	85a6                	mv	a1,s1
    8020083c:	854a                	mv	a0,s2
    8020083e:	0ce000ef          	jal	ra,8020090c <printfmt>
    80200842:	b34d                	j	802005e4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    80200844:	00000617          	auipc	a2,0x0
    80200848:	6f460613          	addi	a2,a2,1780 # 80200f38 <etext+0x590>
    8020084c:	85a6                	mv	a1,s1
    8020084e:	854a                	mv	a0,s2
    80200850:	0bc000ef          	jal	ra,8020090c <printfmt>
    80200854:	bb41                	j	802005e4 <vprintfmt+0x3a>
                p = "(null)";
    80200856:	00000417          	auipc	s0,0x0
    8020085a:	6da40413          	addi	s0,s0,1754 # 80200f30 <etext+0x588>
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020085e:	85e2                	mv	a1,s8
    80200860:	8522                	mv	a0,s0
    80200862:	e43e                	sd	a5,8(sp)
    80200864:	116000ef          	jal	ra,8020097a <strnlen>
    80200868:	40ad8dbb          	subw	s11,s11,a0
    8020086c:	01b05b63          	blez	s11,80200882 <vprintfmt+0x2d8>
                    putch(padc, putdat);
    80200870:	67a2                	ld	a5,8(sp)
    80200872:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200876:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200878:	85a6                	mv	a1,s1
    8020087a:	8552                	mv	a0,s4
    8020087c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020087e:	fe0d9ce3          	bnez	s11,80200876 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200882:	00044783          	lbu	a5,0(s0)
    80200886:	00140a13          	addi	s4,s0,1
    8020088a:	0007851b          	sext.w	a0,a5
    8020088e:	d3a5                	beqz	a5,802007ee <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    80200890:	05e00413          	li	s0,94
    80200894:	bf39                	j	802007b2 <vprintfmt+0x208>
        return va_arg(*ap, int);
    80200896:	000a2403          	lw	s0,0(s4)
    8020089a:	b7ad                	j	80200804 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    8020089c:	000a6603          	lwu	a2,0(s4)
    802008a0:	46a1                	li	a3,8
    802008a2:	8a2e                	mv	s4,a1
    802008a4:	bdb1                	j	80200700 <vprintfmt+0x156>
    802008a6:	000a6603          	lwu	a2,0(s4)
    802008aa:	46a9                	li	a3,10
    802008ac:	8a2e                	mv	s4,a1
    802008ae:	bd89                	j	80200700 <vprintfmt+0x156>
    802008b0:	000a6603          	lwu	a2,0(s4)
    802008b4:	46c1                	li	a3,16
    802008b6:	8a2e                	mv	s4,a1
    802008b8:	b5a1                	j	80200700 <vprintfmt+0x156>
                    putch(ch, putdat);
    802008ba:	9902                	jalr	s2
    802008bc:	bf09                	j	802007ce <vprintfmt+0x224>
                putch('-', putdat);
    802008be:	85a6                	mv	a1,s1
    802008c0:	02d00513          	li	a0,45
    802008c4:	e03e                	sd	a5,0(sp)
    802008c6:	9902                	jalr	s2
                num = -(long long)num;
    802008c8:	6782                	ld	a5,0(sp)
    802008ca:	8a66                	mv	s4,s9
    802008cc:	40800633          	neg	a2,s0
    802008d0:	46a9                	li	a3,10
    802008d2:	b53d                	j	80200700 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    802008d4:	03b05163          	blez	s11,802008f6 <vprintfmt+0x34c>
    802008d8:	02d00693          	li	a3,45
    802008dc:	f6d79de3          	bne	a5,a3,80200856 <vprintfmt+0x2ac>
                p = "(null)";
    802008e0:	00000417          	auipc	s0,0x0
    802008e4:	65040413          	addi	s0,s0,1616 # 80200f30 <etext+0x588>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802008e8:	02800793          	li	a5,40
    802008ec:	02800513          	li	a0,40
    802008f0:	00140a13          	addi	s4,s0,1
    802008f4:	bd6d                	j	802007ae <vprintfmt+0x204>
    802008f6:	00000a17          	auipc	s4,0x0
    802008fa:	63ba0a13          	addi	s4,s4,1595 # 80200f31 <etext+0x589>
    802008fe:	02800513          	li	a0,40
    80200902:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    80200906:	05e00413          	li	s0,94
    8020090a:	b565                	j	802007b2 <vprintfmt+0x208>

000000008020090c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020090c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    8020090e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200912:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200914:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200916:	ec06                	sd	ra,24(sp)
    80200918:	f83a                	sd	a4,48(sp)
    8020091a:	fc3e                	sd	a5,56(sp)
    8020091c:	e0c2                	sd	a6,64(sp)
    8020091e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    80200920:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200922:	c89ff0ef          	jal	ra,802005aa <vprintfmt>
}
    80200926:	60e2                	ld	ra,24(sp)
    80200928:	6161                	addi	sp,sp,80
    8020092a:	8082                	ret

000000008020092c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    8020092c:	4781                	li	a5,0
    8020092e:	00003717          	auipc	a4,0x3
    80200932:	6d273703          	ld	a4,1746(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    80200936:	88ba                	mv	a7,a4
    80200938:	852a                	mv	a0,a0
    8020093a:	85be                	mv	a1,a5
    8020093c:	863e                	mv	a2,a5
    8020093e:	00000073          	ecall
    80200942:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    80200944:	8082                	ret

0000000080200946 <sbi_set_timer>:
    __asm__ volatile (
    80200946:	4781                	li	a5,0
    80200948:	00003717          	auipc	a4,0x3
    8020094c:	6d873703          	ld	a4,1752(a4) # 80204020 <SBI_SET_TIMER>
    80200950:	88ba                	mv	a7,a4
    80200952:	852a                	mv	a0,a0
    80200954:	85be                	mv	a1,a5
    80200956:	863e                	mv	a2,a5
    80200958:	00000073          	ecall
    8020095c:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    8020095e:	8082                	ret

0000000080200960 <sbi_shutdown>:
    __asm__ volatile (
    80200960:	4781                	li	a5,0
    80200962:	00003717          	auipc	a4,0x3
    80200966:	6a673703          	ld	a4,1702(a4) # 80204008 <SBI_SHUTDOWN>
    8020096a:	88ba                	mv	a7,a4
    8020096c:	853e                	mv	a0,a5
    8020096e:	85be                	mv	a1,a5
    80200970:	863e                	mv	a2,a5
    80200972:	00000073          	ecall
    80200976:	87aa                	mv	a5,a0


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200978:	8082                	ret

000000008020097a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    8020097a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    8020097c:	e589                	bnez	a1,80200986 <strnlen+0xc>
    8020097e:	a811                	j	80200992 <strnlen+0x18>
        cnt ++;
    80200980:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    80200982:	00f58863          	beq	a1,a5,80200992 <strnlen+0x18>
    80200986:	00f50733          	add	a4,a0,a5
    8020098a:	00074703          	lbu	a4,0(a4)
    8020098e:	fb6d                	bnez	a4,80200980 <strnlen+0x6>
    80200990:	85be                	mv	a1,a5
    }
    return cnt;
}
    80200992:	852e                	mv	a0,a1
    80200994:	8082                	ret

0000000080200996 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    80200996:	ca01                	beqz	a2,802009a6 <memset+0x10>
    80200998:	962a                	add	a2,a2,a0
    char *p = s;
    8020099a:	87aa                	mv	a5,a0
        *p ++ = c;
    8020099c:	0785                	addi	a5,a5,1
    8020099e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    802009a2:	fec79de3          	bne	a5,a2,8020099c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    802009a6:	8082                	ret
