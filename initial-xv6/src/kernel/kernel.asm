
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	97013103          	ld	sp,-1680(sp) # 80008970 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	98070713          	addi	a4,a4,-1664 # 800089d0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	5ee78793          	addi	a5,a5,1518 # 80006650 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb93bf>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f0478793          	addi	a5,a5,-252 # 80000fb0 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	91e080e7          	jalr	-1762(ra) # 80002a48 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	98650513          	addi	a0,a0,-1658 # 80010b10 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b7c080e7          	jalr	-1156(ra) # 80000d0e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	97648493          	addi	s1,s1,-1674 # 80010b10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a0690913          	addi	s2,s2,-1530 # 80010ba8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	b2a080e7          	jalr	-1238(ra) # 80001cea <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	6ca080e7          	jalr	1738(ra) # 80002892 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	408080e7          	jalr	1032(ra) # 800025de <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	7e0080e7          	jalr	2016(ra) # 800029f2 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	8ea50513          	addi	a0,a0,-1814 # 80010b10 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b94080e7          	jalr	-1132(ra) # 80000dc2 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8d450513          	addi	a0,a0,-1836 # 80010b10 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b7e080e7          	jalr	-1154(ra) # 80000dc2 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	92f72b23          	sw	a5,-1738(a4) # 80010ba8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	84450513          	addi	a0,a0,-1980 # 80010b10 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a3a080e7          	jalr	-1478(ra) # 80000d0e <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	7ac080e7          	jalr	1964(ra) # 80002a9e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	81650513          	addi	a0,a0,-2026 # 80010b10 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	ac0080e7          	jalr	-1344(ra) # 80000dc2 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7f270713          	addi	a4,a4,2034 # 80010b10 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	7c878793          	addi	a5,a5,1992 # 80010b10 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8327a783          	lw	a5,-1998(a5) # 80010ba8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	78670713          	addi	a4,a4,1926 # 80010b10 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	77648493          	addi	s1,s1,1910 # 80010b10 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	73a70713          	addi	a4,a4,1850 # 80010b10 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	7cf72223          	sw	a5,1988(a4) # 80010bb0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6fe78793          	addi	a5,a5,1790 # 80010b10 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	76c7ab23          	sw	a2,1910(a5) # 80010bac <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	76a50513          	addi	a0,a0,1898 # 80010ba8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	1fc080e7          	jalr	508(ra) # 80002642 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	6b050513          	addi	a0,a0,1712 # 80010b10 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	816080e7          	jalr	-2026(ra) # 80000c7e <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00244797          	auipc	a5,0x244
    8000047c:	e3078793          	addi	a5,a5,-464 # 802442a8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6807a223          	sw	zero,1668(a5) # 80010bd0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	baa50513          	addi	a0,a0,-1110 # 80008118 <digits+0xd8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	40f72823          	sw	a5,1040(a4) # 80008990 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	614dad83          	lw	s11,1556(s11) # 80010bd0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	5be50513          	addi	a0,a0,1470 # 80010bb8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	70c080e7          	jalr	1804(ra) # 80000d0e <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	46050513          	addi	a0,a0,1120 # 80010bb8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	662080e7          	jalr	1634(ra) # 80000dc2 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	44448493          	addi	s1,s1,1092 # 80010bb8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	4f8080e7          	jalr	1272(ra) # 80000c7e <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	40450513          	addi	a0,a0,1028 # 80010bd8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	4a2080e7          	jalr	1186(ra) # 80000c7e <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	4ca080e7          	jalr	1226(ra) # 80000cc2 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1907a783          	lw	a5,400(a5) # 80008990 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	53c080e7          	jalr	1340(ra) # 80000d62 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1607b783          	ld	a5,352(a5) # 80008998 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	16073703          	ld	a4,352(a4) # 800089a0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	376a0a13          	addi	s4,s4,886 # 80010bd8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	12e48493          	addi	s1,s1,302 # 80008998 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	12e98993          	addi	s3,s3,302 # 800089a0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	dae080e7          	jalr	-594(ra) # 80002642 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	30850513          	addi	a0,a0,776 # 80010bd8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	436080e7          	jalr	1078(ra) # 80000d0e <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0b07a783          	lw	a5,176(a5) # 80008990 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	0b673703          	ld	a4,182(a4) # 800089a0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0a67b783          	ld	a5,166(a5) # 80008998 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	2da98993          	addi	s3,s3,730 # 80010bd8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	09248493          	addi	s1,s1,146 # 80008998 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	09290913          	addi	s2,s2,146 # 800089a0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	cc0080e7          	jalr	-832(ra) # 800025de <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	2a448493          	addi	s1,s1,676 # 80010bd8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	04e7bc23          	sd	a4,88(a5) # 800089a0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	468080e7          	jalr	1128(ra) # 80000dc2 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	21e48493          	addi	s1,s1,542 # 80010bd8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	34a080e7          	jalr	842(ra) # 80000d0e <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	3ec080e7          	jalr	1004(ra) # 80000dc2 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <increaseTheCount>:
    referenceCount[(uint64)p/PGSIZE]=1;
    kfree(p);
  }
}
void increaseTheCount(uint64 pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	1000                	addi	s0,sp,32
    800009f2:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    800009f4:	00010517          	auipc	a0,0x10
    800009f8:	21c50513          	addi	a0,a0,540 # 80010c10 <kmem>
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	312080e7          	jalr	786(ra) # 80000d0e <acquire>
  int page_number=pa/PGSIZE;
  if(pa>PHYSTOP || referenceCount[page_number]<1){
    80000a04:	4745                	li	a4,17
    80000a06:	076e                	slli	a4,a4,0x1b
    80000a08:	04976463          	bltu	a4,s1,80000a50 <increaseTheCount+0x68>
    80000a0c:	00c4d793          	srli	a5,s1,0xc
    80000a10:	2781                	sext.w	a5,a5
    80000a12:	00279693          	slli	a3,a5,0x2
    80000a16:	00010717          	auipc	a4,0x10
    80000a1a:	21a70713          	addi	a4,a4,538 # 80010c30 <referenceCount>
    80000a1e:	9736                	add	a4,a4,a3
    80000a20:	4318                	lw	a4,0(a4)
    80000a22:	02e05763          	blez	a4,80000a50 <increaseTheCount+0x68>
    
      panic("reference count error");
  }
  referenceCount[page_number]++;
    80000a26:	078a                	slli	a5,a5,0x2
    80000a28:	00010697          	auipc	a3,0x10
    80000a2c:	20868693          	addi	a3,a3,520 # 80010c30 <referenceCount>
    80000a30:	97b6                	add	a5,a5,a3
    80000a32:	2705                	addiw	a4,a4,1
    80000a34:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a36:	00010517          	auipc	a0,0x10
    80000a3a:	1da50513          	addi	a0,a0,474 # 80010c10 <kmem>
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	384080e7          	jalr	900(ra) # 80000dc2 <release>
}
    80000a46:	60e2                	ld	ra,24(sp)
    80000a48:	6442                	ld	s0,16(sp)
    80000a4a:	64a2                	ld	s1,8(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
      panic("reference count error");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae8080e7          	jalr	-1304(ra) # 80000540 <panic>

0000000080000a60 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	e04a                	sd	s2,0(sp)
    80000a6a:	1000                	addi	s0,sp,32
  struct run *r;
  r = (struct run*)pa;
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a6c:	03451793          	slli	a5,a0,0x34
    80000a70:	efa5                	bnez	a5,80000ae8 <kfree+0x88>
    80000a72:	84aa                	mv	s1,a0
    80000a74:	00245797          	auipc	a5,0x245
    80000a78:	9cc78793          	addi	a5,a5,-1588 # 80245440 <end>
    80000a7c:	06f56663          	bltu	a0,a5,80000ae8 <kfree+0x88>
    80000a80:	47c5                	li	a5,17
    80000a82:	07ee                	slli	a5,a5,0x1b
    80000a84:	06f57263          	bgeu	a0,a5,80000ae8 <kfree+0x88>
    panic("kfree");

  // // Fill with junk to catch dangling refs.
  // 
  acquire(&kmem.lock);
    80000a88:	00010517          	auipc	a0,0x10
    80000a8c:	18850513          	addi	a0,a0,392 # 80010c10 <kmem>
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	27e080e7          	jalr	638(ra) # 80000d0e <acquire>
  int page_no=(uint64)r/PGSIZE;
    80000a98:	00c4d793          	srli	a5,s1,0xc
    80000a9c:	2781                	sext.w	a5,a5
  if (referenceCount[page_no]<1){
    80000a9e:	00279693          	slli	a3,a5,0x2
    80000aa2:	00010717          	auipc	a4,0x10
    80000aa6:	18e70713          	addi	a4,a4,398 # 80010c30 <referenceCount>
    80000aaa:	9736                	add	a4,a4,a3
    80000aac:	4318                	lw	a4,0(a4)
    80000aae:	04e05563          	blez	a4,80000af8 <kfree+0x98>
    panic("memory 'kfree' panic");
  }
  referenceCount[page_no]-=1;
    80000ab2:	078a                	slli	a5,a5,0x2
    80000ab4:	00010917          	auipc	s2,0x10
    80000ab8:	17c90913          	addi	s2,s2,380 # 80010c30 <referenceCount>
    80000abc:	993e                	add	s2,s2,a5
    80000abe:	377d                	addiw	a4,a4,-1
    80000ac0:	00e92023          	sw	a4,0(s2)
  release(&kmem.lock);
    80000ac4:	00010517          	auipc	a0,0x10
    80000ac8:	14c50513          	addi	a0,a0,332 # 80010c10 <kmem>
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	2f6080e7          	jalr	758(ra) # 80000dc2 <release>
  if(referenceCount[page_no]>0){
    80000ad4:	00092783          	lw	a5,0(s2)
    80000ad8:	02f05863          	blez	a5,80000b08 <kfree+0xa8>
  memset(pa, 1, PGSIZE);
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000adc:	60e2                	ld	ra,24(sp)
    80000ade:	6442                	ld	s0,16(sp)
    80000ae0:	64a2                	ld	s1,8(sp)
    80000ae2:	6902                	ld	s2,0(sp)
    80000ae4:	6105                	addi	sp,sp,32
    80000ae6:	8082                	ret
    panic("kfree");
    80000ae8:	00007517          	auipc	a0,0x7
    80000aec:	59050513          	addi	a0,a0,1424 # 80008078 <digits+0x38>
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	a50080e7          	jalr	-1456(ra) # 80000540 <panic>
    panic("memory 'kfree' panic");
    80000af8:	00007517          	auipc	a0,0x7
    80000afc:	58850513          	addi	a0,a0,1416 # 80008080 <digits+0x40>
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	a40080e7          	jalr	-1472(ra) # 80000540 <panic>
  memset(pa, 1, PGSIZE);
    80000b08:	6605                	lui	a2,0x1
    80000b0a:	4585                	li	a1,1
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	2fc080e7          	jalr	764(ra) # 80000e0a <memset>
  acquire(&kmem.lock);
    80000b16:	00010917          	auipc	s2,0x10
    80000b1a:	0fa90913          	addi	s2,s2,250 # 80010c10 <kmem>
    80000b1e:	854a                	mv	a0,s2
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1ee080e7          	jalr	494(ra) # 80000d0e <acquire>
  r->next = kmem.freelist;
    80000b28:	01893783          	ld	a5,24(s2)
    80000b2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b32:	854a                	mv	a0,s2
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	28e080e7          	jalr	654(ra) # 80000dc2 <release>
    80000b3c:	b745                	j	80000adc <kfree+0x7c>

0000000080000b3e <freerange>:
{
    80000b3e:	7139                	addi	sp,sp,-64
    80000b40:	fc06                	sd	ra,56(sp)
    80000b42:	f822                	sd	s0,48(sp)
    80000b44:	f426                	sd	s1,40(sp)
    80000b46:	f04a                	sd	s2,32(sp)
    80000b48:	ec4e                	sd	s3,24(sp)
    80000b4a:	e852                	sd	s4,16(sp)
    80000b4c:	e456                	sd	s5,8(sp)
    80000b4e:	e05a                	sd	s6,0(sp)
    80000b50:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b52:	6785                	lui	a5,0x1
    80000b54:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b58:	953a                	add	a0,a0,a4
    80000b5a:	777d                	lui	a4,0xfffff
    80000b5c:	00e574b3          	and	s1,a0,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b60:	97a6                	add	a5,a5,s1
    80000b62:	02f5ea63          	bltu	a1,a5,80000b96 <freerange+0x58>
    80000b66:	892e                	mv	s2,a1
    referenceCount[(uint64)p/PGSIZE]=1;
    80000b68:	00010b17          	auipc	s6,0x10
    80000b6c:	0c8b0b13          	addi	s6,s6,200 # 80010c30 <referenceCount>
    80000b70:	4a85                	li	s5,1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b72:	6a05                	lui	s4,0x1
    80000b74:	6989                	lui	s3,0x2
    referenceCount[(uint64)p/PGSIZE]=1;
    80000b76:	00c4d793          	srli	a5,s1,0xc
    80000b7a:	078a                	slli	a5,a5,0x2
    80000b7c:	97da                	add	a5,a5,s6
    80000b7e:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000b82:	8526                	mv	a0,s1
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	edc080e7          	jalr	-292(ra) # 80000a60 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b8c:	87a6                	mv	a5,s1
    80000b8e:	94d2                	add	s1,s1,s4
    80000b90:	97ce                	add	a5,a5,s3
    80000b92:	fef972e3          	bgeu	s2,a5,80000b76 <freerange+0x38>
}
    80000b96:	70e2                	ld	ra,56(sp)
    80000b98:	7442                	ld	s0,48(sp)
    80000b9a:	74a2                	ld	s1,40(sp)
    80000b9c:	7902                	ld	s2,32(sp)
    80000b9e:	69e2                	ld	s3,24(sp)
    80000ba0:	6a42                	ld	s4,16(sp)
    80000ba2:	6aa2                	ld	s5,8(sp)
    80000ba4:	6b02                	ld	s6,0(sp)
    80000ba6:	6121                	addi	sp,sp,64
    80000ba8:	8082                	ret

0000000080000baa <kinit>:
{
    80000baa:	1141                	addi	sp,sp,-16
    80000bac:	e406                	sd	ra,8(sp)
    80000bae:	e022                	sd	s0,0(sp)
    80000bb0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bb2:	00007597          	auipc	a1,0x7
    80000bb6:	4e658593          	addi	a1,a1,1254 # 80008098 <digits+0x58>
    80000bba:	00010517          	auipc	a0,0x10
    80000bbe:	05650513          	addi	a0,a0,86 # 80010c10 <kmem>
    80000bc2:	00000097          	auipc	ra,0x0
    80000bc6:	0bc080e7          	jalr	188(ra) # 80000c7e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000bca:	45c5                	li	a1,17
    80000bcc:	05ee                	slli	a1,a1,0x1b
    80000bce:	00245517          	auipc	a0,0x245
    80000bd2:	87250513          	addi	a0,a0,-1934 # 80245440 <end>
    80000bd6:	00000097          	auipc	ra,0x0
    80000bda:	f68080e7          	jalr	-152(ra) # 80000b3e <freerange>
}
    80000bde:	60a2                	ld	ra,8(sp)
    80000be0:	6402                	ld	s0,0(sp)
    80000be2:	0141                	addi	sp,sp,16
    80000be4:	8082                	ret

0000000080000be6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000be6:	1101                	addi	sp,sp,-32
    80000be8:	ec06                	sd	ra,24(sp)
    80000bea:	e822                	sd	s0,16(sp)
    80000bec:	e426                	sd	s1,8(sp)
    80000bee:	1000                	addi	s0,sp,32
  struct run *r;
  acquire(&kmem.lock);
    80000bf0:	00010497          	auipc	s1,0x10
    80000bf4:	02048493          	addi	s1,s1,32 # 80010c10 <kmem>
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	114080e7          	jalr	276(ra) # 80000d0e <acquire>
  r = kmem.freelist;
    80000c02:	6c84                	ld	s1,24(s1)
  if(r){
    80000c04:	c4a5                	beqz	s1,80000c6c <kalloc+0x86>
    int page_number=(uint64)r/PGSIZE;
    80000c06:	00c4d793          	srli	a5,s1,0xc
    80000c0a:	2781                	sext.w	a5,a5
    if(referenceCount[page_number]!=0){
    80000c0c:	00279693          	slli	a3,a5,0x2
    80000c10:	00010717          	auipc	a4,0x10
    80000c14:	02070713          	addi	a4,a4,32 # 80010c30 <referenceCount>
    80000c18:	9736                	add	a4,a4,a3
    80000c1a:	4318                	lw	a4,0(a4)
    80000c1c:	e321                	bnez	a4,80000c5c <kalloc+0x76>
      panic("reference count error in kalloc");
    }
    referenceCount[page_number]=1;
    80000c1e:	078a                	slli	a5,a5,0x2
    80000c20:	00010717          	auipc	a4,0x10
    80000c24:	01070713          	addi	a4,a4,16 # 80010c30 <referenceCount>
    80000c28:	97ba                	add	a5,a5,a4
    80000c2a:	4705                	li	a4,1
    80000c2c:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000c2e:	609c                	ld	a5,0(s1)
    80000c30:	00010517          	auipc	a0,0x10
    80000c34:	fe050513          	addi	a0,a0,-32 # 80010c10 <kmem>
    80000c38:	ed1c                	sd	a5,24(a0)
  }
  release(&kmem.lock);
    80000c3a:	00000097          	auipc	ra,0x0
    80000c3e:	188080e7          	jalr	392(ra) # 80000dc2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c42:	6605                	lui	a2,0x1
    80000c44:	4595                	li	a1,5
    80000c46:	8526                	mv	a0,s1
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	1c2080e7          	jalr	450(ra) # 80000e0a <memset>
  return (void*)r;
}
    80000c50:	8526                	mv	a0,s1
    80000c52:	60e2                	ld	ra,24(sp)
    80000c54:	6442                	ld	s0,16(sp)
    80000c56:	64a2                	ld	s1,8(sp)
    80000c58:	6105                	addi	sp,sp,32
    80000c5a:	8082                	ret
      panic("reference count error in kalloc");
    80000c5c:	00007517          	auipc	a0,0x7
    80000c60:	44450513          	addi	a0,a0,1092 # 800080a0 <digits+0x60>
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	8dc080e7          	jalr	-1828(ra) # 80000540 <panic>
  release(&kmem.lock);
    80000c6c:	00010517          	auipc	a0,0x10
    80000c70:	fa450513          	addi	a0,a0,-92 # 80010c10 <kmem>
    80000c74:	00000097          	auipc	ra,0x0
    80000c78:	14e080e7          	jalr	334(ra) # 80000dc2 <release>
  if(r)
    80000c7c:	bfd1                	j	80000c50 <kalloc+0x6a>

0000000080000c7e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c7e:	1141                	addi	sp,sp,-16
    80000c80:	e422                	sd	s0,8(sp)
    80000c82:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c84:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c86:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c8a:	00053823          	sd	zero,16(a0)
}
    80000c8e:	6422                	ld	s0,8(sp)
    80000c90:	0141                	addi	sp,sp,16
    80000c92:	8082                	ret

0000000080000c94 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c94:	411c                	lw	a5,0(a0)
    80000c96:	e399                	bnez	a5,80000c9c <holding+0x8>
    80000c98:	4501                	li	a0,0
  return r;
}
    80000c9a:	8082                	ret
{
    80000c9c:	1101                	addi	sp,sp,-32
    80000c9e:	ec06                	sd	ra,24(sp)
    80000ca0:	e822                	sd	s0,16(sp)
    80000ca2:	e426                	sd	s1,8(sp)
    80000ca4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ca6:	6904                	ld	s1,16(a0)
    80000ca8:	00001097          	auipc	ra,0x1
    80000cac:	026080e7          	jalr	38(ra) # 80001cce <mycpu>
    80000cb0:	40a48533          	sub	a0,s1,a0
    80000cb4:	00153513          	seqz	a0,a0
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret

0000000080000cc2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cc2:	1101                	addi	sp,sp,-32
    80000cc4:	ec06                	sd	ra,24(sp)
    80000cc6:	e822                	sd	s0,16(sp)
    80000cc8:	e426                	sd	s1,8(sp)
    80000cca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ccc:	100024f3          	csrr	s1,sstatus
    80000cd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cda:	00001097          	auipc	ra,0x1
    80000cde:	ff4080e7          	jalr	-12(ra) # 80001cce <mycpu>
    80000ce2:	5d3c                	lw	a5,120(a0)
    80000ce4:	cf89                	beqz	a5,80000cfe <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ce6:	00001097          	auipc	ra,0x1
    80000cea:	fe8080e7          	jalr	-24(ra) # 80001cce <mycpu>
    80000cee:	5d3c                	lw	a5,120(a0)
    80000cf0:	2785                	addiw	a5,a5,1
    80000cf2:	dd3c                	sw	a5,120(a0)
}
    80000cf4:	60e2                	ld	ra,24(sp)
    80000cf6:	6442                	ld	s0,16(sp)
    80000cf8:	64a2                	ld	s1,8(sp)
    80000cfa:	6105                	addi	sp,sp,32
    80000cfc:	8082                	ret
    mycpu()->intena = old;
    80000cfe:	00001097          	auipc	ra,0x1
    80000d02:	fd0080e7          	jalr	-48(ra) # 80001cce <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d06:	8085                	srli	s1,s1,0x1
    80000d08:	8885                	andi	s1,s1,1
    80000d0a:	dd64                	sw	s1,124(a0)
    80000d0c:	bfe9                	j	80000ce6 <push_off+0x24>

0000000080000d0e <acquire>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	fa8080e7          	jalr	-88(ra) # 80000cc2 <push_off>
  if(holding(lk))
    80000d22:	8526                	mv	a0,s1
    80000d24:	00000097          	auipc	ra,0x0
    80000d28:	f70080e7          	jalr	-144(ra) # 80000c94 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2c:	4705                	li	a4,1
  if(holding(lk))
    80000d2e:	e115                	bnez	a0,80000d52 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d30:	87ba                	mv	a5,a4
    80000d32:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d36:	2781                	sext.w	a5,a5
    80000d38:	ffe5                	bnez	a5,80000d30 <acquire+0x22>
  __sync_synchronize();
    80000d3a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d3e:	00001097          	auipc	ra,0x1
    80000d42:	f90080e7          	jalr	-112(ra) # 80001cce <mycpu>
    80000d46:	e888                	sd	a0,16(s1)
}
    80000d48:	60e2                	ld	ra,24(sp)
    80000d4a:	6442                	ld	s0,16(sp)
    80000d4c:	64a2                	ld	s1,8(sp)
    80000d4e:	6105                	addi	sp,sp,32
    80000d50:	8082                	ret
    panic("acquire");
    80000d52:	00007517          	auipc	a0,0x7
    80000d56:	36e50513          	addi	a0,a0,878 # 800080c0 <digits+0x80>
    80000d5a:	fffff097          	auipc	ra,0xfffff
    80000d5e:	7e6080e7          	jalr	2022(ra) # 80000540 <panic>

0000000080000d62 <pop_off>:

void
pop_off(void)
{
    80000d62:	1141                	addi	sp,sp,-16
    80000d64:	e406                	sd	ra,8(sp)
    80000d66:	e022                	sd	s0,0(sp)
    80000d68:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d6a:	00001097          	auipc	ra,0x1
    80000d6e:	f64080e7          	jalr	-156(ra) # 80001cce <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d78:	e78d                	bnez	a5,80000da2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d7a:	5d3c                	lw	a5,120(a0)
    80000d7c:	02f05b63          	blez	a5,80000db2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d80:	37fd                	addiw	a5,a5,-1
    80000d82:	0007871b          	sext.w	a4,a5
    80000d86:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d88:	eb09                	bnez	a4,80000d9a <pop_off+0x38>
    80000d8a:	5d7c                	lw	a5,124(a0)
    80000d8c:	c799                	beqz	a5,80000d9a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d96:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    panic("pop_off - interruptible");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	32650513          	addi	a0,a0,806 # 800080c8 <digits+0x88>
    80000daa:	fffff097          	auipc	ra,0xfffff
    80000dae:	796080e7          	jalr	1942(ra) # 80000540 <panic>
    panic("pop_off");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	32e50513          	addi	a0,a0,814 # 800080e0 <digits+0xa0>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	786080e7          	jalr	1926(ra) # 80000540 <panic>

0000000080000dc2 <release>:
{
    80000dc2:	1101                	addi	sp,sp,-32
    80000dc4:	ec06                	sd	ra,24(sp)
    80000dc6:	e822                	sd	s0,16(sp)
    80000dc8:	e426                	sd	s1,8(sp)
    80000dca:	1000                	addi	s0,sp,32
    80000dcc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	ec6080e7          	jalr	-314(ra) # 80000c94 <holding>
    80000dd6:	c115                	beqz	a0,80000dfa <release+0x38>
  lk->cpu = 0;
    80000dd8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ddc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de0:	0f50000f          	fence	iorw,ow
    80000de4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de8:	00000097          	auipc	ra,0x0
    80000dec:	f7a080e7          	jalr	-134(ra) # 80000d62 <pop_off>
}
    80000df0:	60e2                	ld	ra,24(sp)
    80000df2:	6442                	ld	s0,16(sp)
    80000df4:	64a2                	ld	s1,8(sp)
    80000df6:	6105                	addi	sp,sp,32
    80000df8:	8082                	ret
    panic("release");
    80000dfa:	00007517          	auipc	a0,0x7
    80000dfe:	2ee50513          	addi	a0,a0,750 # 800080e8 <digits+0xa8>
    80000e02:	fffff097          	auipc	ra,0xfffff
    80000e06:	73e080e7          	jalr	1854(ra) # 80000540 <panic>

0000000080000e0a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e0a:	1141                	addi	sp,sp,-16
    80000e0c:	e422                	sd	s0,8(sp)
    80000e0e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e10:	ca19                	beqz	a2,80000e26 <memset+0x1c>
    80000e12:	87aa                	mv	a5,a0
    80000e14:	1602                	slli	a2,a2,0x20
    80000e16:	9201                	srli	a2,a2,0x20
    80000e18:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e1c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e20:	0785                	addi	a5,a5,1
    80000e22:	fee79de3          	bne	a5,a4,80000e1c <memset+0x12>
  }
  return dst;
}
    80000e26:	6422                	ld	s0,8(sp)
    80000e28:	0141                	addi	sp,sp,16
    80000e2a:	8082                	ret

0000000080000e2c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e2c:	1141                	addi	sp,sp,-16
    80000e2e:	e422                	sd	s0,8(sp)
    80000e30:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e32:	ca05                	beqz	a2,80000e62 <memcmp+0x36>
    80000e34:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e38:	1682                	slli	a3,a3,0x20
    80000e3a:	9281                	srli	a3,a3,0x20
    80000e3c:	0685                	addi	a3,a3,1
    80000e3e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e40:	00054783          	lbu	a5,0(a0)
    80000e44:	0005c703          	lbu	a4,0(a1)
    80000e48:	00e79863          	bne	a5,a4,80000e58 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e4c:	0505                	addi	a0,a0,1
    80000e4e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e50:	fed518e3          	bne	a0,a3,80000e40 <memcmp+0x14>
  }

  return 0;
    80000e54:	4501                	li	a0,0
    80000e56:	a019                	j	80000e5c <memcmp+0x30>
      return *s1 - *s2;
    80000e58:	40e7853b          	subw	a0,a5,a4
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret
  return 0;
    80000e62:	4501                	li	a0,0
    80000e64:	bfe5                	j	80000e5c <memcmp+0x30>

0000000080000e66 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e6c:	c205                	beqz	a2,80000e8c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e6e:	02a5e263          	bltu	a1,a0,80000e92 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e72:	1602                	slli	a2,a2,0x20
    80000e74:	9201                	srli	a2,a2,0x20
    80000e76:	00c587b3          	add	a5,a1,a2
{
    80000e7a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	fff5c683          	lbu	a3,-1(a1)
    80000e84:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e88:	fef59ae3          	bne	a1,a5,80000e7c <memmove+0x16>

  return dst;
}
    80000e8c:	6422                	ld	s0,8(sp)
    80000e8e:	0141                	addi	sp,sp,16
    80000e90:	8082                	ret
  if(s < d && s + n > d){
    80000e92:	02061693          	slli	a3,a2,0x20
    80000e96:	9281                	srli	a3,a3,0x20
    80000e98:	00d58733          	add	a4,a1,a3
    80000e9c:	fce57be3          	bgeu	a0,a4,80000e72 <memmove+0xc>
    d += n;
    80000ea0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ea2:	fff6079b          	addiw	a5,a2,-1
    80000ea6:	1782                	slli	a5,a5,0x20
    80000ea8:	9381                	srli	a5,a5,0x20
    80000eaa:	fff7c793          	not	a5,a5
    80000eae:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000eb0:	177d                	addi	a4,a4,-1
    80000eb2:	16fd                	addi	a3,a3,-1
    80000eb4:	00074603          	lbu	a2,0(a4)
    80000eb8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ebc:	fee79ae3          	bne	a5,a4,80000eb0 <memmove+0x4a>
    80000ec0:	b7f1                	j	80000e8c <memmove+0x26>

0000000080000ec2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ec2:	1141                	addi	sp,sp,-16
    80000ec4:	e406                	sd	ra,8(sp)
    80000ec6:	e022                	sd	s0,0(sp)
    80000ec8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000eca:	00000097          	auipc	ra,0x0
    80000ece:	f9c080e7          	jalr	-100(ra) # 80000e66 <memmove>
}
    80000ed2:	60a2                	ld	ra,8(sp)
    80000ed4:	6402                	ld	s0,0(sp)
    80000ed6:	0141                	addi	sp,sp,16
    80000ed8:	8082                	ret

0000000080000eda <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eda:	1141                	addi	sp,sp,-16
    80000edc:	e422                	sd	s0,8(sp)
    80000ede:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ee0:	ce11                	beqz	a2,80000efc <strncmp+0x22>
    80000ee2:	00054783          	lbu	a5,0(a0)
    80000ee6:	cf89                	beqz	a5,80000f00 <strncmp+0x26>
    80000ee8:	0005c703          	lbu	a4,0(a1)
    80000eec:	00f71a63          	bne	a4,a5,80000f00 <strncmp+0x26>
    n--, p++, q++;
    80000ef0:	367d                	addiw	a2,a2,-1
    80000ef2:	0505                	addi	a0,a0,1
    80000ef4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ef6:	f675                	bnez	a2,80000ee2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ef8:	4501                	li	a0,0
    80000efa:	a809                	j	80000f0c <strncmp+0x32>
    80000efc:	4501                	li	a0,0
    80000efe:	a039                	j	80000f0c <strncmp+0x32>
  if(n == 0)
    80000f00:	ca09                	beqz	a2,80000f12 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f02:	00054503          	lbu	a0,0(a0)
    80000f06:	0005c783          	lbu	a5,0(a1)
    80000f0a:	9d1d                	subw	a0,a0,a5
}
    80000f0c:	6422                	ld	s0,8(sp)
    80000f0e:	0141                	addi	sp,sp,16
    80000f10:	8082                	ret
    return 0;
    80000f12:	4501                	li	a0,0
    80000f14:	bfe5                	j	80000f0c <strncmp+0x32>

0000000080000f16 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f16:	1141                	addi	sp,sp,-16
    80000f18:	e422                	sd	s0,8(sp)
    80000f1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f1c:	872a                	mv	a4,a0
    80000f1e:	8832                	mv	a6,a2
    80000f20:	367d                	addiw	a2,a2,-1
    80000f22:	01005963          	blez	a6,80000f34 <strncpy+0x1e>
    80000f26:	0705                	addi	a4,a4,1
    80000f28:	0005c783          	lbu	a5,0(a1)
    80000f2c:	fef70fa3          	sb	a5,-1(a4)
    80000f30:	0585                	addi	a1,a1,1
    80000f32:	f7f5                	bnez	a5,80000f1e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f34:	86ba                	mv	a3,a4
    80000f36:	00c05c63          	blez	a2,80000f4e <strncpy+0x38>
    *s++ = 0;
    80000f3a:	0685                	addi	a3,a3,1
    80000f3c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f40:	40d707bb          	subw	a5,a4,a3
    80000f44:	37fd                	addiw	a5,a5,-1
    80000f46:	010787bb          	addw	a5,a5,a6
    80000f4a:	fef048e3          	bgtz	a5,80000f3a <strncpy+0x24>
  return os;
}
    80000f4e:	6422                	ld	s0,8(sp)
    80000f50:	0141                	addi	sp,sp,16
    80000f52:	8082                	ret

0000000080000f54 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f54:	1141                	addi	sp,sp,-16
    80000f56:	e422                	sd	s0,8(sp)
    80000f58:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f5a:	02c05363          	blez	a2,80000f80 <safestrcpy+0x2c>
    80000f5e:	fff6069b          	addiw	a3,a2,-1
    80000f62:	1682                	slli	a3,a3,0x20
    80000f64:	9281                	srli	a3,a3,0x20
    80000f66:	96ae                	add	a3,a3,a1
    80000f68:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f6a:	00d58963          	beq	a1,a3,80000f7c <safestrcpy+0x28>
    80000f6e:	0585                	addi	a1,a1,1
    80000f70:	0785                	addi	a5,a5,1
    80000f72:	fff5c703          	lbu	a4,-1(a1)
    80000f76:	fee78fa3          	sb	a4,-1(a5)
    80000f7a:	fb65                	bnez	a4,80000f6a <safestrcpy+0x16>
    ;
  *s = 0;
    80000f7c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f80:	6422                	ld	s0,8(sp)
    80000f82:	0141                	addi	sp,sp,16
    80000f84:	8082                	ret

0000000080000f86 <strlen>:

int
strlen(const char *s)
{
    80000f86:	1141                	addi	sp,sp,-16
    80000f88:	e422                	sd	s0,8(sp)
    80000f8a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f8c:	00054783          	lbu	a5,0(a0)
    80000f90:	cf91                	beqz	a5,80000fac <strlen+0x26>
    80000f92:	0505                	addi	a0,a0,1
    80000f94:	87aa                	mv	a5,a0
    80000f96:	4685                	li	a3,1
    80000f98:	9e89                	subw	a3,a3,a0
    80000f9a:	00f6853b          	addw	a0,a3,a5
    80000f9e:	0785                	addi	a5,a5,1
    80000fa0:	fff7c703          	lbu	a4,-1(a5)
    80000fa4:	fb7d                	bnez	a4,80000f9a <strlen+0x14>
    ;
  return n;
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fac:	4501                	li	a0,0
    80000fae:	bfe5                	j	80000fa6 <strlen+0x20>

0000000080000fb0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fb0:	1141                	addi	sp,sp,-16
    80000fb2:	e406                	sd	ra,8(sp)
    80000fb4:	e022                	sd	s0,0(sp)
    80000fb6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fb8:	00001097          	auipc	ra,0x1
    80000fbc:	d06080e7          	jalr	-762(ra) # 80001cbe <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fc0:	00008717          	auipc	a4,0x8
    80000fc4:	9e870713          	addi	a4,a4,-1560 # 800089a8 <started>
  if(cpuid() == 0){
    80000fc8:	c139                	beqz	a0,8000100e <main+0x5e>
    while(started == 0)
    80000fca:	431c                	lw	a5,0(a4)
    80000fcc:	2781                	sext.w	a5,a5
    80000fce:	dff5                	beqz	a5,80000fca <main+0x1a>
      ;
    __sync_synchronize();
    80000fd0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fd4:	00001097          	auipc	ra,0x1
    80000fd8:	cea080e7          	jalr	-790(ra) # 80001cbe <cpuid>
    80000fdc:	85aa                	mv	a1,a0
    80000fde:	00007517          	auipc	a0,0x7
    80000fe2:	12a50513          	addi	a0,a0,298 # 80008108 <digits+0xc8>
    80000fe6:	fffff097          	auipc	ra,0xfffff
    80000fea:	5a4080e7          	jalr	1444(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000fee:	00000097          	auipc	ra,0x0
    80000ff2:	0d8080e7          	jalr	216(ra) # 800010c6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ff6:	00002097          	auipc	ra,0x2
    80000ffa:	e3a080e7          	jalr	-454(ra) # 80002e30 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	692080e7          	jalr	1682(ra) # 80006690 <plicinithart>
  }

  scheduler();        
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	234080e7          	jalr	564(ra) # 8000223a <scheduler>
    consoleinit();
    8000100e:	fffff097          	auipc	ra,0xfffff
    80001012:	442080e7          	jalr	1090(ra) # 80000450 <consoleinit>
    printfinit();
    80001016:	fffff097          	auipc	ra,0xfffff
    8000101a:	754080e7          	jalr	1876(ra) # 8000076a <printfinit>
    printf("\n");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0fa50513          	addi	a0,a0,250 # 80008118 <digits+0xd8>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	564080e7          	jalr	1380(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    8000102e:	00007517          	auipc	a0,0x7
    80001032:	0c250513          	addi	a0,a0,194 # 800080f0 <digits+0xb0>
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	554080e7          	jalr	1364(ra) # 8000058a <printf>
    printf("\n");
    8000103e:	00007517          	auipc	a0,0x7
    80001042:	0da50513          	addi	a0,a0,218 # 80008118 <digits+0xd8>
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	544080e7          	jalr	1348(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    8000104e:	00000097          	auipc	ra,0x0
    80001052:	b5c080e7          	jalr	-1188(ra) # 80000baa <kinit>
    kvminit();       // create kernel page table
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	326080e7          	jalr	806(ra) # 8000137c <kvminit>
    kvminithart();   // turn on paging
    8000105e:	00000097          	auipc	ra,0x0
    80001062:	068080e7          	jalr	104(ra) # 800010c6 <kvminithart>
    procinit();      // process table
    80001066:	00001097          	auipc	ra,0x1
    8000106a:	ba4080e7          	jalr	-1116(ra) # 80001c0a <procinit>
    trapinit();      // trap vectors
    8000106e:	00002097          	auipc	ra,0x2
    80001072:	d0e080e7          	jalr	-754(ra) # 80002d7c <trapinit>
    trapinithart();  // install kernel trap vector
    80001076:	00002097          	auipc	ra,0x2
    8000107a:	dba080e7          	jalr	-582(ra) # 80002e30 <trapinithart>
    plicinit();      // set up interrupt controller
    8000107e:	00005097          	auipc	ra,0x5
    80001082:	5fc080e7          	jalr	1532(ra) # 8000667a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001086:	00005097          	auipc	ra,0x5
    8000108a:	60a080e7          	jalr	1546(ra) # 80006690 <plicinithart>
    binit();         // buffer cache
    8000108e:	00002097          	auipc	ra,0x2
    80001092:	7a0080e7          	jalr	1952(ra) # 8000382e <binit>
    iinit();         // inode table
    80001096:	00003097          	auipc	ra,0x3
    8000109a:	e40080e7          	jalr	-448(ra) # 80003ed6 <iinit>
    fileinit();      // file table
    8000109e:	00004097          	auipc	ra,0x4
    800010a2:	de6080e7          	jalr	-538(ra) # 80004e84 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a6:	00005097          	auipc	ra,0x5
    800010aa:	6f2080e7          	jalr	1778(ra) # 80006798 <virtio_disk_init>
    userinit();      // first user process
    800010ae:	00001097          	auipc	ra,0x1
    800010b2:	f6e080e7          	jalr	-146(ra) # 8000201c <userinit>
    __sync_synchronize();
    800010b6:	0ff0000f          	fence
    started = 1;
    800010ba:	4785                	li	a5,1
    800010bc:	00008717          	auipc	a4,0x8
    800010c0:	8ef72623          	sw	a5,-1812(a4) # 800089a8 <started>
    800010c4:	b789                	j	80001006 <main+0x56>

00000000800010c6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010c6:	1141                	addi	sp,sp,-16
    800010c8:	e422                	sd	s0,8(sp)
    800010ca:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010cc:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010d0:	00008797          	auipc	a5,0x8
    800010d4:	8e07b783          	ld	a5,-1824(a5) # 800089b0 <kernel_pagetable>
    800010d8:	83b1                	srli	a5,a5,0xc
    800010da:	577d                	li	a4,-1
    800010dc:	177e                	slli	a4,a4,0x3f
    800010de:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010e0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010e4:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010e8:	6422                	ld	s0,8(sp)
    800010ea:	0141                	addi	sp,sp,16
    800010ec:	8082                	ret

00000000800010ee <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010ee:	7139                	addi	sp,sp,-64
    800010f0:	fc06                	sd	ra,56(sp)
    800010f2:	f822                	sd	s0,48(sp)
    800010f4:	f426                	sd	s1,40(sp)
    800010f6:	f04a                	sd	s2,32(sp)
    800010f8:	ec4e                	sd	s3,24(sp)
    800010fa:	e852                	sd	s4,16(sp)
    800010fc:	e456                	sd	s5,8(sp)
    800010fe:	e05a                	sd	s6,0(sp)
    80001100:	0080                	addi	s0,sp,64
    80001102:	84aa                	mv	s1,a0
    80001104:	89ae                	mv	s3,a1
    80001106:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001108:	57fd                	li	a5,-1
    8000110a:	83e9                	srli	a5,a5,0x1a
    8000110c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000110e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001110:	04b7f263          	bgeu	a5,a1,80001154 <walk+0x66>
    panic("walk");
    80001114:	00007517          	auipc	a0,0x7
    80001118:	00c50513          	addi	a0,a0,12 # 80008120 <digits+0xe0>
    8000111c:	fffff097          	auipc	ra,0xfffff
    80001120:	424080e7          	jalr	1060(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001124:	060a8663          	beqz	s5,80001190 <walk+0xa2>
    80001128:	00000097          	auipc	ra,0x0
    8000112c:	abe080e7          	jalr	-1346(ra) # 80000be6 <kalloc>
    80001130:	84aa                	mv	s1,a0
    80001132:	c529                	beqz	a0,8000117c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001134:	6605                	lui	a2,0x1
    80001136:	4581                	li	a1,0
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	cd2080e7          	jalr	-814(ra) # 80000e0a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001140:	00c4d793          	srli	a5,s1,0xc
    80001144:	07aa                	slli	a5,a5,0xa
    80001146:	0017e793          	ori	a5,a5,1
    8000114a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000114e:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    80001150:	036a0063          	beq	s4,s6,80001170 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001154:	0149d933          	srl	s2,s3,s4
    80001158:	1ff97913          	andi	s2,s2,511
    8000115c:	090e                	slli	s2,s2,0x3
    8000115e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001160:	00093483          	ld	s1,0(s2)
    80001164:	0014f793          	andi	a5,s1,1
    80001168:	dfd5                	beqz	a5,80001124 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000116a:	80a9                	srli	s1,s1,0xa
    8000116c:	04b2                	slli	s1,s1,0xc
    8000116e:	b7c5                	j	8000114e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001170:	00c9d513          	srli	a0,s3,0xc
    80001174:	1ff57513          	andi	a0,a0,511
    80001178:	050e                	slli	a0,a0,0x3
    8000117a:	9526                	add	a0,a0,s1
}
    8000117c:	70e2                	ld	ra,56(sp)
    8000117e:	7442                	ld	s0,48(sp)
    80001180:	74a2                	ld	s1,40(sp)
    80001182:	7902                	ld	s2,32(sp)
    80001184:	69e2                	ld	s3,24(sp)
    80001186:	6a42                	ld	s4,16(sp)
    80001188:	6aa2                	ld	s5,8(sp)
    8000118a:	6b02                	ld	s6,0(sp)
    8000118c:	6121                	addi	sp,sp,64
    8000118e:	8082                	ret
        return 0;
    80001190:	4501                	li	a0,0
    80001192:	b7ed                	j	8000117c <walk+0x8e>

0000000080001194 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001194:	57fd                	li	a5,-1
    80001196:	83e9                	srli	a5,a5,0x1a
    80001198:	00b7f463          	bgeu	a5,a1,800011a0 <walkaddr+0xc>
    return 0;
    8000119c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000119e:	8082                	ret
{
    800011a0:	1141                	addi	sp,sp,-16
    800011a2:	e406                	sd	ra,8(sp)
    800011a4:	e022                	sd	s0,0(sp)
    800011a6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011a8:	4601                	li	a2,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f44080e7          	jalr	-188(ra) # 800010ee <walk>
  if(pte == 0)
    800011b2:	c105                	beqz	a0,800011d2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011b4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011b6:	0117f693          	andi	a3,a5,17
    800011ba:	4745                	li	a4,17
    return 0;
    800011bc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011be:	00e68663          	beq	a3,a4,800011ca <walkaddr+0x36>
}
    800011c2:	60a2                	ld	ra,8(sp)
    800011c4:	6402                	ld	s0,0(sp)
    800011c6:	0141                	addi	sp,sp,16
    800011c8:	8082                	ret
  pa = PTE2PA(*pte);
    800011ca:	83a9                	srli	a5,a5,0xa
    800011cc:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011d0:	bfcd                	j	800011c2 <walkaddr+0x2e>
    return 0;
    800011d2:	4501                	li	a0,0
    800011d4:	b7fd                	j	800011c2 <walkaddr+0x2e>

00000000800011d6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011d6:	715d                	addi	sp,sp,-80
    800011d8:	e486                	sd	ra,72(sp)
    800011da:	e0a2                	sd	s0,64(sp)
    800011dc:	fc26                	sd	s1,56(sp)
    800011de:	f84a                	sd	s2,48(sp)
    800011e0:	f44e                	sd	s3,40(sp)
    800011e2:	f052                	sd	s4,32(sp)
    800011e4:	ec56                	sd	s5,24(sp)
    800011e6:	e85a                	sd	s6,16(sp)
    800011e8:	e45e                	sd	s7,8(sp)
    800011ea:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011ec:	c639                	beqz	a2,8000123a <mappages+0x64>
    800011ee:	8aaa                	mv	s5,a0
    800011f0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011f2:	777d                	lui	a4,0xfffff
    800011f4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011f8:	fff58993          	addi	s3,a1,-1
    800011fc:	99b2                	add	s3,s3,a2
    800011fe:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001202:	893e                	mv	s2,a5
    80001204:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001208:	6b85                	lui	s7,0x1
    8000120a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000120e:	4605                	li	a2,1
    80001210:	85ca                	mv	a1,s2
    80001212:	8556                	mv	a0,s5
    80001214:	00000097          	auipc	ra,0x0
    80001218:	eda080e7          	jalr	-294(ra) # 800010ee <walk>
    8000121c:	cd1d                	beqz	a0,8000125a <mappages+0x84>
    if(*pte & PTE_V)
    8000121e:	611c                	ld	a5,0(a0)
    80001220:	8b85                	andi	a5,a5,1
    80001222:	e785                	bnez	a5,8000124a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001224:	80b1                	srli	s1,s1,0xc
    80001226:	04aa                	slli	s1,s1,0xa
    80001228:	0164e4b3          	or	s1,s1,s6
    8000122c:	0014e493          	ori	s1,s1,1
    80001230:	e104                	sd	s1,0(a0)
    if(a == last)
    80001232:	05390063          	beq	s2,s3,80001272 <mappages+0x9c>
    a += PGSIZE;
    80001236:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001238:	bfc9                	j	8000120a <mappages+0x34>
    panic("mappages: size");
    8000123a:	00007517          	auipc	a0,0x7
    8000123e:	eee50513          	addi	a0,a0,-274 # 80008128 <digits+0xe8>
    80001242:	fffff097          	auipc	ra,0xfffff
    80001246:	2fe080e7          	jalr	766(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000124a:	00007517          	auipc	a0,0x7
    8000124e:	eee50513          	addi	a0,a0,-274 # 80008138 <digits+0xf8>
    80001252:	fffff097          	auipc	ra,0xfffff
    80001256:	2ee080e7          	jalr	750(ra) # 80000540 <panic>
      return -1;
    8000125a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000125c:	60a6                	ld	ra,72(sp)
    8000125e:	6406                	ld	s0,64(sp)
    80001260:	74e2                	ld	s1,56(sp)
    80001262:	7942                	ld	s2,48(sp)
    80001264:	79a2                	ld	s3,40(sp)
    80001266:	7a02                	ld	s4,32(sp)
    80001268:	6ae2                	ld	s5,24(sp)
    8000126a:	6b42                	ld	s6,16(sp)
    8000126c:	6ba2                	ld	s7,8(sp)
    8000126e:	6161                	addi	sp,sp,80
    80001270:	8082                	ret
  return 0;
    80001272:	4501                	li	a0,0
    80001274:	b7e5                	j	8000125c <mappages+0x86>

0000000080001276 <kvmmap>:
{
    80001276:	1141                	addi	sp,sp,-16
    80001278:	e406                	sd	ra,8(sp)
    8000127a:	e022                	sd	s0,0(sp)
    8000127c:	0800                	addi	s0,sp,16
    8000127e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001280:	86b2                	mv	a3,a2
    80001282:	863e                	mv	a2,a5
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f52080e7          	jalr	-174(ra) # 800011d6 <mappages>
    8000128c:	e509                	bnez	a0,80001296 <kvmmap+0x20>
}
    8000128e:	60a2                	ld	ra,8(sp)
    80001290:	6402                	ld	s0,0(sp)
    80001292:	0141                	addi	sp,sp,16
    80001294:	8082                	ret
    panic("kvmmap");
    80001296:	00007517          	auipc	a0,0x7
    8000129a:	eb250513          	addi	a0,a0,-334 # 80008148 <digits+0x108>
    8000129e:	fffff097          	auipc	ra,0xfffff
    800012a2:	2a2080e7          	jalr	674(ra) # 80000540 <panic>

00000000800012a6 <kvmmake>:
{
    800012a6:	1101                	addi	sp,sp,-32
    800012a8:	ec06                	sd	ra,24(sp)
    800012aa:	e822                	sd	s0,16(sp)
    800012ac:	e426                	sd	s1,8(sp)
    800012ae:	e04a                	sd	s2,0(sp)
    800012b0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	934080e7          	jalr	-1740(ra) # 80000be6 <kalloc>
    800012ba:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012bc:	6605                	lui	a2,0x1
    800012be:	4581                	li	a1,0
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	b4a080e7          	jalr	-1206(ra) # 80000e0a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c8:	4719                	li	a4,6
    800012ca:	6685                	lui	a3,0x1
    800012cc:	10000637          	lui	a2,0x10000
    800012d0:	100005b7          	lui	a1,0x10000
    800012d4:	8526                	mv	a0,s1
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	fa0080e7          	jalr	-96(ra) # 80001276 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012de:	4719                	li	a4,6
    800012e0:	6685                	lui	a3,0x1
    800012e2:	10001637          	lui	a2,0x10001
    800012e6:	100015b7          	lui	a1,0x10001
    800012ea:	8526                	mv	a0,s1
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	f8a080e7          	jalr	-118(ra) # 80001276 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f4:	4719                	li	a4,6
    800012f6:	004006b7          	lui	a3,0x400
    800012fa:	0c000637          	lui	a2,0xc000
    800012fe:	0c0005b7          	lui	a1,0xc000
    80001302:	8526                	mv	a0,s1
    80001304:	00000097          	auipc	ra,0x0
    80001308:	f72080e7          	jalr	-142(ra) # 80001276 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000130c:	00007917          	auipc	s2,0x7
    80001310:	cf490913          	addi	s2,s2,-780 # 80008000 <etext>
    80001314:	4729                	li	a4,10
    80001316:	80007697          	auipc	a3,0x80007
    8000131a:	cea68693          	addi	a3,a3,-790 # 8000 <_entry-0x7fff8000>
    8000131e:	4605                	li	a2,1
    80001320:	067e                	slli	a2,a2,0x1f
    80001322:	85b2                	mv	a1,a2
    80001324:	8526                	mv	a0,s1
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	f50080e7          	jalr	-176(ra) # 80001276 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000132e:	4719                	li	a4,6
    80001330:	46c5                	li	a3,17
    80001332:	06ee                	slli	a3,a3,0x1b
    80001334:	412686b3          	sub	a3,a3,s2
    80001338:	864a                	mv	a2,s2
    8000133a:	85ca                	mv	a1,s2
    8000133c:	8526                	mv	a0,s1
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	f38080e7          	jalr	-200(ra) # 80001276 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001346:	4729                	li	a4,10
    80001348:	6685                	lui	a3,0x1
    8000134a:	00006617          	auipc	a2,0x6
    8000134e:	cb660613          	addi	a2,a2,-842 # 80007000 <_trampoline>
    80001352:	040005b7          	lui	a1,0x4000
    80001356:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001358:	05b2                	slli	a1,a1,0xc
    8000135a:	8526                	mv	a0,s1
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	f1a080e7          	jalr	-230(ra) # 80001276 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001364:	8526                	mv	a0,s1
    80001366:	00001097          	auipc	ra,0x1
    8000136a:	80e080e7          	jalr	-2034(ra) # 80001b74 <proc_mapstacks>
}
    8000136e:	8526                	mv	a0,s1
    80001370:	60e2                	ld	ra,24(sp)
    80001372:	6442                	ld	s0,16(sp)
    80001374:	64a2                	ld	s1,8(sp)
    80001376:	6902                	ld	s2,0(sp)
    80001378:	6105                	addi	sp,sp,32
    8000137a:	8082                	ret

000000008000137c <kvminit>:
{
    8000137c:	1141                	addi	sp,sp,-16
    8000137e:	e406                	sd	ra,8(sp)
    80001380:	e022                	sd	s0,0(sp)
    80001382:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001384:	00000097          	auipc	ra,0x0
    80001388:	f22080e7          	jalr	-222(ra) # 800012a6 <kvmmake>
    8000138c:	00007797          	auipc	a5,0x7
    80001390:	62a7b223          	sd	a0,1572(a5) # 800089b0 <kernel_pagetable>
}
    80001394:	60a2                	ld	ra,8(sp)
    80001396:	6402                	ld	s0,0(sp)
    80001398:	0141                	addi	sp,sp,16
    8000139a:	8082                	ret

000000008000139c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000139c:	715d                	addi	sp,sp,-80
    8000139e:	e486                	sd	ra,72(sp)
    800013a0:	e0a2                	sd	s0,64(sp)
    800013a2:	fc26                	sd	s1,56(sp)
    800013a4:	f84a                	sd	s2,48(sp)
    800013a6:	f44e                	sd	s3,40(sp)
    800013a8:	f052                	sd	s4,32(sp)
    800013aa:	ec56                	sd	s5,24(sp)
    800013ac:	e85a                	sd	s6,16(sp)
    800013ae:	e45e                	sd	s7,8(sp)
    800013b0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013b2:	03459793          	slli	a5,a1,0x34
    800013b6:	e795                	bnez	a5,800013e2 <uvmunmap+0x46>
    800013b8:	8a2a                	mv	s4,a0
    800013ba:	892e                	mv	s2,a1
    800013bc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013be:	0632                	slli	a2,a2,0xc
    800013c0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c6:	6b05                	lui	s6,0x1
    800013c8:	0735e263          	bltu	a1,s3,8000142c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013cc:	60a6                	ld	ra,72(sp)
    800013ce:	6406                	ld	s0,64(sp)
    800013d0:	74e2                	ld	s1,56(sp)
    800013d2:	7942                	ld	s2,48(sp)
    800013d4:	79a2                	ld	s3,40(sp)
    800013d6:	7a02                	ld	s4,32(sp)
    800013d8:	6ae2                	ld	s5,24(sp)
    800013da:	6b42                	ld	s6,16(sp)
    800013dc:	6ba2                	ld	s7,8(sp)
    800013de:	6161                	addi	sp,sp,80
    800013e0:	8082                	ret
    panic("uvmunmap: not aligned");
    800013e2:	00007517          	auipc	a0,0x7
    800013e6:	d6e50513          	addi	a0,a0,-658 # 80008150 <digits+0x110>
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	156080e7          	jalr	342(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800013f2:	00007517          	auipc	a0,0x7
    800013f6:	d7650513          	addi	a0,a0,-650 # 80008168 <digits+0x128>
    800013fa:	fffff097          	auipc	ra,0xfffff
    800013fe:	146080e7          	jalr	326(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d7650513          	addi	a0,a0,-650 # 80008178 <digits+0x138>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001412:	00007517          	auipc	a0,0x7
    80001416:	d7e50513          	addi	a0,a0,-642 # 80008190 <digits+0x150>
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	126080e7          	jalr	294(ra) # 80000540 <panic>
    *pte = 0;
    80001422:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001426:	995a                	add	s2,s2,s6
    80001428:	fb3972e3          	bgeu	s2,s3,800013cc <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000142c:	4601                	li	a2,0
    8000142e:	85ca                	mv	a1,s2
    80001430:	8552                	mv	a0,s4
    80001432:	00000097          	auipc	ra,0x0
    80001436:	cbc080e7          	jalr	-836(ra) # 800010ee <walk>
    8000143a:	84aa                	mv	s1,a0
    8000143c:	d95d                	beqz	a0,800013f2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000143e:	6108                	ld	a0,0(a0)
    80001440:	00157793          	andi	a5,a0,1
    80001444:	dfdd                	beqz	a5,80001402 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001446:	3ff57793          	andi	a5,a0,1023
    8000144a:	fd7784e3          	beq	a5,s7,80001412 <uvmunmap+0x76>
    if(do_free){
    8000144e:	fc0a8ae3          	beqz	s5,80001422 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001452:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001454:	0532                	slli	a0,a0,0xc
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	60a080e7          	jalr	1546(ra) # 80000a60 <kfree>
    8000145e:	b7d1                	j	80001422 <uvmunmap+0x86>

0000000080001460 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001460:	1101                	addi	sp,sp,-32
    80001462:	ec06                	sd	ra,24(sp)
    80001464:	e822                	sd	s0,16(sp)
    80001466:	e426                	sd	s1,8(sp)
    80001468:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	77c080e7          	jalr	1916(ra) # 80000be6 <kalloc>
    80001472:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001474:	c519                	beqz	a0,80001482 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001476:	6605                	lui	a2,0x1
    80001478:	4581                	li	a1,0
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	990080e7          	jalr	-1648(ra) # 80000e0a <memset>
  return pagetable;
}
    80001482:	8526                	mv	a0,s1
    80001484:	60e2                	ld	ra,24(sp)
    80001486:	6442                	ld	s0,16(sp)
    80001488:	64a2                	ld	s1,8(sp)
    8000148a:	6105                	addi	sp,sp,32
    8000148c:	8082                	ret

000000008000148e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000148e:	7179                	addi	sp,sp,-48
    80001490:	f406                	sd	ra,40(sp)
    80001492:	f022                	sd	s0,32(sp)
    80001494:	ec26                	sd	s1,24(sp)
    80001496:	e84a                	sd	s2,16(sp)
    80001498:	e44e                	sd	s3,8(sp)
    8000149a:	e052                	sd	s4,0(sp)
    8000149c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000149e:	6785                	lui	a5,0x1
    800014a0:	04f67863          	bgeu	a2,a5,800014f0 <uvmfirst+0x62>
    800014a4:	8a2a                	mv	s4,a0
    800014a6:	89ae                	mv	s3,a1
    800014a8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	73c080e7          	jalr	1852(ra) # 80000be6 <kalloc>
    800014b2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014b4:	6605                	lui	a2,0x1
    800014b6:	4581                	li	a1,0
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	952080e7          	jalr	-1710(ra) # 80000e0a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014c0:	4779                	li	a4,30
    800014c2:	86ca                	mv	a3,s2
    800014c4:	6605                	lui	a2,0x1
    800014c6:	4581                	li	a1,0
    800014c8:	8552                	mv	a0,s4
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	d0c080e7          	jalr	-756(ra) # 800011d6 <mappages>
  memmove(mem, src, sz);
    800014d2:	8626                	mv	a2,s1
    800014d4:	85ce                	mv	a1,s3
    800014d6:	854a                	mv	a0,s2
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	98e080e7          	jalr	-1650(ra) # 80000e66 <memmove>
}
    800014e0:	70a2                	ld	ra,40(sp)
    800014e2:	7402                	ld	s0,32(sp)
    800014e4:	64e2                	ld	s1,24(sp)
    800014e6:	6942                	ld	s2,16(sp)
    800014e8:	69a2                	ld	s3,8(sp)
    800014ea:	6a02                	ld	s4,0(sp)
    800014ec:	6145                	addi	sp,sp,48
    800014ee:	8082                	ret
    panic("uvmfirst: more than a page");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	cb850513          	addi	a0,a0,-840 # 800081a8 <digits+0x168>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	048080e7          	jalr	72(ra) # 80000540 <panic>

0000000080001500 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001500:	1101                	addi	sp,sp,-32
    80001502:	ec06                	sd	ra,24(sp)
    80001504:	e822                	sd	s0,16(sp)
    80001506:	e426                	sd	s1,8(sp)
    80001508:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000150a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000150c:	00b67d63          	bgeu	a2,a1,80001526 <uvmdealloc+0x26>
    80001510:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001512:	6785                	lui	a5,0x1
    80001514:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001516:	00f60733          	add	a4,a2,a5
    8000151a:	76fd                	lui	a3,0xfffff
    8000151c:	8f75                	and	a4,a4,a3
    8000151e:	97ae                	add	a5,a5,a1
    80001520:	8ff5                	and	a5,a5,a3
    80001522:	00f76863          	bltu	a4,a5,80001532 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001526:	8526                	mv	a0,s1
    80001528:	60e2                	ld	ra,24(sp)
    8000152a:	6442                	ld	s0,16(sp)
    8000152c:	64a2                	ld	s1,8(sp)
    8000152e:	6105                	addi	sp,sp,32
    80001530:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001532:	8f99                	sub	a5,a5,a4
    80001534:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001536:	4685                	li	a3,1
    80001538:	0007861b          	sext.w	a2,a5
    8000153c:	85ba                	mv	a1,a4
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	e5e080e7          	jalr	-418(ra) # 8000139c <uvmunmap>
    80001546:	b7c5                	j	80001526 <uvmdealloc+0x26>

0000000080001548 <uvmalloc>:
  if(newsz < oldsz)
    80001548:	0ab66563          	bltu	a2,a1,800015f2 <uvmalloc+0xaa>
{
    8000154c:	7139                	addi	sp,sp,-64
    8000154e:	fc06                	sd	ra,56(sp)
    80001550:	f822                	sd	s0,48(sp)
    80001552:	f426                	sd	s1,40(sp)
    80001554:	f04a                	sd	s2,32(sp)
    80001556:	ec4e                	sd	s3,24(sp)
    80001558:	e852                	sd	s4,16(sp)
    8000155a:	e456                	sd	s5,8(sp)
    8000155c:	e05a                	sd	s6,0(sp)
    8000155e:	0080                	addi	s0,sp,64
    80001560:	8aaa                	mv	s5,a0
    80001562:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001564:	6785                	lui	a5,0x1
    80001566:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001568:	95be                	add	a1,a1,a5
    8000156a:	77fd                	lui	a5,0xfffff
    8000156c:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001570:	08c9f363          	bgeu	s3,a2,800015f6 <uvmalloc+0xae>
    80001574:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001576:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000157a:	fffff097          	auipc	ra,0xfffff
    8000157e:	66c080e7          	jalr	1644(ra) # 80000be6 <kalloc>
    80001582:	84aa                	mv	s1,a0
    if(mem == 0){
    80001584:	c51d                	beqz	a0,800015b2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001586:	6605                	lui	a2,0x1
    80001588:	4581                	li	a1,0
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	880080e7          	jalr	-1920(ra) # 80000e0a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001592:	875a                	mv	a4,s6
    80001594:	86a6                	mv	a3,s1
    80001596:	6605                	lui	a2,0x1
    80001598:	85ca                	mv	a1,s2
    8000159a:	8556                	mv	a0,s5
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	c3a080e7          	jalr	-966(ra) # 800011d6 <mappages>
    800015a4:	e90d                	bnez	a0,800015d6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a6:	6785                	lui	a5,0x1
    800015a8:	993e                	add	s2,s2,a5
    800015aa:	fd4968e3          	bltu	s2,s4,8000157a <uvmalloc+0x32>
  return newsz;
    800015ae:	8552                	mv	a0,s4
    800015b0:	a809                	j	800015c2 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015b2:	864e                	mv	a2,s3
    800015b4:	85ca                	mv	a1,s2
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	f48080e7          	jalr	-184(ra) # 80001500 <uvmdealloc>
      return 0;
    800015c0:	4501                	li	a0,0
}
    800015c2:	70e2                	ld	ra,56(sp)
    800015c4:	7442                	ld	s0,48(sp)
    800015c6:	74a2                	ld	s1,40(sp)
    800015c8:	7902                	ld	s2,32(sp)
    800015ca:	69e2                	ld	s3,24(sp)
    800015cc:	6a42                	ld	s4,16(sp)
    800015ce:	6aa2                	ld	s5,8(sp)
    800015d0:	6b02                	ld	s6,0(sp)
    800015d2:	6121                	addi	sp,sp,64
    800015d4:	8082                	ret
      kfree(mem);
    800015d6:	8526                	mv	a0,s1
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	488080e7          	jalr	1160(ra) # 80000a60 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015e0:	864e                	mv	a2,s3
    800015e2:	85ca                	mv	a1,s2
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	f1a080e7          	jalr	-230(ra) # 80001500 <uvmdealloc>
      return 0;
    800015ee:	4501                	li	a0,0
    800015f0:	bfc9                	j	800015c2 <uvmalloc+0x7a>
    return oldsz;
    800015f2:	852e                	mv	a0,a1
}
    800015f4:	8082                	ret
  return newsz;
    800015f6:	8532                	mv	a0,a2
    800015f8:	b7e9                	j	800015c2 <uvmalloc+0x7a>

00000000800015fa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015fa:	7179                	addi	sp,sp,-48
    800015fc:	f406                	sd	ra,40(sp)
    800015fe:	f022                	sd	s0,32(sp)
    80001600:	ec26                	sd	s1,24(sp)
    80001602:	e84a                	sd	s2,16(sp)
    80001604:	e44e                	sd	s3,8(sp)
    80001606:	e052                	sd	s4,0(sp)
    80001608:	1800                	addi	s0,sp,48
    8000160a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000160c:	84aa                	mv	s1,a0
    8000160e:	6905                	lui	s2,0x1
    80001610:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001612:	4985                	li	s3,1
    80001614:	a829                	j	8000162e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001616:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001618:	00c79513          	slli	a0,a5,0xc
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	fde080e7          	jalr	-34(ra) # 800015fa <freewalk>
      pagetable[i] = 0;
    80001624:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001628:	04a1                	addi	s1,s1,8
    8000162a:	03248163          	beq	s1,s2,8000164c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000162e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001630:	00f7f713          	andi	a4,a5,15
    80001634:	ff3701e3          	beq	a4,s3,80001616 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001638:	8b85                	andi	a5,a5,1
    8000163a:	d7fd                	beqz	a5,80001628 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000163c:	00007517          	auipc	a0,0x7
    80001640:	b8c50513          	addi	a0,a0,-1140 # 800081c8 <digits+0x188>
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	efc080e7          	jalr	-260(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000164c:	8552                	mv	a0,s4
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	412080e7          	jalr	1042(ra) # 80000a60 <kfree>
}
    80001656:	70a2                	ld	ra,40(sp)
    80001658:	7402                	ld	s0,32(sp)
    8000165a:	64e2                	ld	s1,24(sp)
    8000165c:	6942                	ld	s2,16(sp)
    8000165e:	69a2                	ld	s3,8(sp)
    80001660:	6a02                	ld	s4,0(sp)
    80001662:	6145                	addi	sp,sp,48
    80001664:	8082                	ret

0000000080001666 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001666:	1101                	addi	sp,sp,-32
    80001668:	ec06                	sd	ra,24(sp)
    8000166a:	e822                	sd	s0,16(sp)
    8000166c:	e426                	sd	s1,8(sp)
    8000166e:	1000                	addi	s0,sp,32
    80001670:	84aa                	mv	s1,a0
  if(sz > 0)
    80001672:	e999                	bnez	a1,80001688 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001674:	8526                	mv	a0,s1
    80001676:	00000097          	auipc	ra,0x0
    8000167a:	f84080e7          	jalr	-124(ra) # 800015fa <freewalk>
}
    8000167e:	60e2                	ld	ra,24(sp)
    80001680:	6442                	ld	s0,16(sp)
    80001682:	64a2                	ld	s1,8(sp)
    80001684:	6105                	addi	sp,sp,32
    80001686:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001688:	6785                	lui	a5,0x1
    8000168a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000168c:	95be                	add	a1,a1,a5
    8000168e:	4685                	li	a3,1
    80001690:	00c5d613          	srli	a2,a1,0xc
    80001694:	4581                	li	a1,0
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	d06080e7          	jalr	-762(ra) # 8000139c <uvmunmap>
    8000169e:	bfd9                	j	80001674 <uvmfree+0xe>

00000000800016a0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016a0:	ca55                	beqz	a2,80001754 <uvmcopy+0xb4>
{
    800016a2:	7139                	addi	sp,sp,-64
    800016a4:	fc06                	sd	ra,56(sp)
    800016a6:	f822                	sd	s0,48(sp)
    800016a8:	f426                	sd	s1,40(sp)
    800016aa:	f04a                	sd	s2,32(sp)
    800016ac:	ec4e                	sd	s3,24(sp)
    800016ae:	e852                	sd	s4,16(sp)
    800016b0:	e456                	sd	s5,8(sp)
    800016b2:	e05a                	sd	s6,0(sp)
    800016b4:	0080                	addi	s0,sp,64
    800016b6:	8b2a                	mv	s6,a0
    800016b8:	8aae                	mv	s5,a1
    800016ba:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016bc:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    800016be:	4601                	li	a2,0
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	a2a080e7          	jalr	-1494(ra) # 800010ee <walk>
    800016cc:	c121                	beqz	a0,8000170c <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016ce:	6118                	ld	a4,0(a0)
    800016d0:	00177793          	andi	a5,a4,1
    800016d4:	c7a1                	beqz	a5,8000171c <uvmcopy+0x7c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016d6:	00a75993          	srli	s3,a4,0xa
    800016da:	09b2                	slli	s3,s3,0xc
    *pte&=~PTE_W;
    800016dc:	ffb77493          	andi	s1,a4,-5
    800016e0:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);
    increaseTheCount(pa);
    800016e2:	854e                	mv	a0,s3
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	304080e7          	jalr	772(ra) # 800009e8 <increaseTheCount>
    // if((mem = kalloc()) == 0)
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    800016ec:	3fb4f713          	andi	a4,s1,1019
    800016f0:	86ce                	mv	a3,s3
    800016f2:	6605                	lui	a2,0x1
    800016f4:	85ca                	mv	a1,s2
    800016f6:	8556                	mv	a0,s5
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	ade080e7          	jalr	-1314(ra) # 800011d6 <mappages>
    80001700:	e515                	bnez	a0,8000172c <uvmcopy+0x8c>
  for(i = 0; i < sz; i += PGSIZE){
    80001702:	6785                	lui	a5,0x1
    80001704:	993e                	add	s2,s2,a5
    80001706:	fb496ce3          	bltu	s2,s4,800016be <uvmcopy+0x1e>
    8000170a:	a81d                	j	80001740 <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	acc50513          	addi	a0,a0,-1332 # 800081d8 <digits+0x198>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e2c080e7          	jalr	-468(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000171c:	00007517          	auipc	a0,0x7
    80001720:	adc50513          	addi	a0,a0,-1316 # 800081f8 <digits+0x1b8>
    80001724:	fffff097          	auipc	ra,0xfffff
    80001728:	e1c080e7          	jalr	-484(ra) # 80000540 <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000172c:	4685                	li	a3,1
    8000172e:	00c95613          	srli	a2,s2,0xc
    80001732:	4581                	li	a1,0
    80001734:	8556                	mv	a0,s5
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	c66080e7          	jalr	-922(ra) # 8000139c <uvmunmap>
  return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	70e2                	ld	ra,56(sp)
    80001742:	7442                	ld	s0,48(sp)
    80001744:	74a2                	ld	s1,40(sp)
    80001746:	7902                	ld	s2,32(sp)
    80001748:	69e2                	ld	s3,24(sp)
    8000174a:	6a42                	ld	s4,16(sp)
    8000174c:	6aa2                	ld	s5,8(sp)
    8000174e:	6b02                	ld	s6,0(sp)
    80001750:	6121                	addi	sp,sp,64
    80001752:	8082                	ret
  return 0;
    80001754:	4501                	li	a0,0
}
    80001756:	8082                	ret

0000000080001758 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001758:	1141                	addi	sp,sp,-16
    8000175a:	e406                	sd	ra,8(sp)
    8000175c:	e022                	sd	s0,0(sp)
    8000175e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001760:	4601                	li	a2,0
    80001762:	00000097          	auipc	ra,0x0
    80001766:	98c080e7          	jalr	-1652(ra) # 800010ee <walk>
  if(pte == 0)
    8000176a:	c901                	beqz	a0,8000177a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000176c:	611c                	ld	a5,0(a0)
    8000176e:	9bbd                	andi	a5,a5,-17
    80001770:	e11c                	sd	a5,0(a0)
}
    80001772:	60a2                	ld	ra,8(sp)
    80001774:	6402                	ld	s0,0(sp)
    80001776:	0141                	addi	sp,sp,16
    80001778:	8082                	ret
    panic("uvmclear");
    8000177a:	00007517          	auipc	a0,0x7
    8000177e:	a9e50513          	addi	a0,a0,-1378 # 80008218 <digits+0x1d8>
    80001782:	fffff097          	auipc	ra,0xfffff
    80001786:	dbe080e7          	jalr	-578(ra) # 80000540 <panic>

000000008000178a <copyout>:
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  while(len > 0){
    8000178a:	c6d9                	beqz	a3,80001818 <copyout+0x8e>
{
    8000178c:	711d                	addi	sp,sp,-96
    8000178e:	ec86                	sd	ra,88(sp)
    80001790:	e8a2                	sd	s0,80(sp)
    80001792:	e4a6                	sd	s1,72(sp)
    80001794:	e0ca                	sd	s2,64(sp)
    80001796:	fc4e                	sd	s3,56(sp)
    80001798:	f852                	sd	s4,48(sp)
    8000179a:	f456                	sd	s5,40(sp)
    8000179c:	f05a                	sd	s6,32(sp)
    8000179e:	ec5e                	sd	s7,24(sp)
    800017a0:	e862                	sd	s8,16(sp)
    800017a2:	e466                	sd	s9,8(sp)
    800017a4:	1080                	addi	s0,sp,96
    800017a6:	8baa                	mv	s7,a0
    800017a8:	8aae                	mv	s5,a1
    800017aa:	8b32                	mv	s6,a2
    800017ac:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017ae:	74fd                	lui	s1,0xfffff
    800017b0:	8ced                	and	s1,s1,a1
    if(va0>=MAXVA){
    800017b2:	57fd                	li	a5,-1
    800017b4:	83e9                	srli	a5,a5,0x1a
    800017b6:	0697e363          	bltu	a5,s1,8000181c <copyout+0x92>
    800017ba:	6c85                	lui	s9,0x1
    800017bc:	8c3e                	mv	s8,a5
    800017be:	a025                	j	800017e6 <copyout+0x5c>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017c0:	409a84b3          	sub	s1,s5,s1
    800017c4:	0009061b          	sext.w	a2,s2
    800017c8:	85da                	mv	a1,s6
    800017ca:	9526                	add	a0,a0,s1
    800017cc:	fffff097          	auipc	ra,0xfffff
    800017d0:	69a080e7          	jalr	1690(ra) # 80000e66 <memmove>

    len -= n;
    800017d4:	412989b3          	sub	s3,s3,s2
    src += n;
    800017d8:	9b4a                	add	s6,s6,s2
  while(len > 0){
    800017da:	02098d63          	beqz	s3,80001814 <copyout+0x8a>
    if(va0>=MAXVA){
    800017de:	054c6163          	bltu	s8,s4,80001820 <copyout+0x96>
    va0 = PGROUNDDOWN(dstva);
    800017e2:	84d2                	mv	s1,s4
    dstva = va0 + PGSIZE;
    800017e4:	8ad2                	mv	s5,s4
    else if(copyOnWrite(pagetable,va0)<0){
    800017e6:	85a6                	mv	a1,s1
    800017e8:	855e                	mv	a0,s7
    800017ea:	00001097          	auipc	ra,0x1
    800017ee:	5ba080e7          	jalr	1466(ra) # 80002da4 <copyOnWrite>
    800017f2:	02054963          	bltz	a0,80001824 <copyout+0x9a>
    pa0 = walkaddr(pagetable, va0);
    800017f6:	85a6                	mv	a1,s1
    800017f8:	855e                	mv	a0,s7
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	99a080e7          	jalr	-1638(ra) # 80001194 <walkaddr>
    if(pa0 == 0)
    80001802:	cd1d                	beqz	a0,80001840 <copyout+0xb6>
    n = PGSIZE - (dstva - va0);
    80001804:	01948a33          	add	s4,s1,s9
    80001808:	415a0933          	sub	s2,s4,s5
    8000180c:	fb29fae3          	bgeu	s3,s2,800017c0 <copyout+0x36>
    80001810:	894e                	mv	s2,s3
    80001812:	b77d                	j	800017c0 <copyout+0x36>
  }
  return 0;
    80001814:	4501                	li	a0,0
    80001816:	a801                	j	80001826 <copyout+0x9c>
    80001818:	4501                	li	a0,0
}
    8000181a:	8082                	ret
      return -1;
    8000181c:	557d                	li	a0,-1
    8000181e:	a021                	j	80001826 <copyout+0x9c>
    80001820:	557d                	li	a0,-1
    80001822:	a011                	j	80001826 <copyout+0x9c>
      return -1;
    80001824:	557d                	li	a0,-1
}
    80001826:	60e6                	ld	ra,88(sp)
    80001828:	6446                	ld	s0,80(sp)
    8000182a:	64a6                	ld	s1,72(sp)
    8000182c:	6906                	ld	s2,64(sp)
    8000182e:	79e2                	ld	s3,56(sp)
    80001830:	7a42                	ld	s4,48(sp)
    80001832:	7aa2                	ld	s5,40(sp)
    80001834:	7b02                	ld	s6,32(sp)
    80001836:	6be2                	ld	s7,24(sp)
    80001838:	6c42                	ld	s8,16(sp)
    8000183a:	6ca2                	ld	s9,8(sp)
    8000183c:	6125                	addi	sp,sp,96
    8000183e:	8082                	ret
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b7d5                	j	80001826 <copyout+0x9c>

0000000080001844 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001844:	caa5                	beqz	a3,800018b4 <copyin+0x70>
{
    80001846:	715d                	addi	sp,sp,-80
    80001848:	e486                	sd	ra,72(sp)
    8000184a:	e0a2                	sd	s0,64(sp)
    8000184c:	fc26                	sd	s1,56(sp)
    8000184e:	f84a                	sd	s2,48(sp)
    80001850:	f44e                	sd	s3,40(sp)
    80001852:	f052                	sd	s4,32(sp)
    80001854:	ec56                	sd	s5,24(sp)
    80001856:	e85a                	sd	s6,16(sp)
    80001858:	e45e                	sd	s7,8(sp)
    8000185a:	e062                	sd	s8,0(sp)
    8000185c:	0880                	addi	s0,sp,80
    8000185e:	8b2a                	mv	s6,a0
    80001860:	8a2e                	mv	s4,a1
    80001862:	8c32                	mv	s8,a2
    80001864:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001866:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001868:	6a85                	lui	s5,0x1
    8000186a:	a01d                	j	80001890 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000186c:	018505b3          	add	a1,a0,s8
    80001870:	0004861b          	sext.w	a2,s1
    80001874:	412585b3          	sub	a1,a1,s2
    80001878:	8552                	mv	a0,s4
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	5ec080e7          	jalr	1516(ra) # 80000e66 <memmove>

    len -= n;
    80001882:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001886:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001888:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000188c:	02098263          	beqz	s3,800018b0 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001890:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001894:	85ca                	mv	a1,s2
    80001896:	855a                	mv	a0,s6
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8fc080e7          	jalr	-1796(ra) # 80001194 <walkaddr>
    if(pa0 == 0)
    800018a0:	cd01                	beqz	a0,800018b8 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a2:	418904b3          	sub	s1,s2,s8
    800018a6:	94d6                	add	s1,s1,s5
    800018a8:	fc99f2e3          	bgeu	s3,s1,8000186c <copyin+0x28>
    800018ac:	84ce                	mv	s1,s3
    800018ae:	bf7d                	j	8000186c <copyin+0x28>
  }
  return 0;
    800018b0:	4501                	li	a0,0
    800018b2:	a021                	j	800018ba <copyin+0x76>
    800018b4:	4501                	li	a0,0
}
    800018b6:	8082                	ret
      return -1;
    800018b8:	557d                	li	a0,-1
}
    800018ba:	60a6                	ld	ra,72(sp)
    800018bc:	6406                	ld	s0,64(sp)
    800018be:	74e2                	ld	s1,56(sp)
    800018c0:	7942                	ld	s2,48(sp)
    800018c2:	79a2                	ld	s3,40(sp)
    800018c4:	7a02                	ld	s4,32(sp)
    800018c6:	6ae2                	ld	s5,24(sp)
    800018c8:	6b42                	ld	s6,16(sp)
    800018ca:	6ba2                	ld	s7,8(sp)
    800018cc:	6c02                	ld	s8,0(sp)
    800018ce:	6161                	addi	sp,sp,80
    800018d0:	8082                	ret

00000000800018d2 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d2:	c2dd                	beqz	a3,80001978 <copyinstr+0xa6>
{
    800018d4:	715d                	addi	sp,sp,-80
    800018d6:	e486                	sd	ra,72(sp)
    800018d8:	e0a2                	sd	s0,64(sp)
    800018da:	fc26                	sd	s1,56(sp)
    800018dc:	f84a                	sd	s2,48(sp)
    800018de:	f44e                	sd	s3,40(sp)
    800018e0:	f052                	sd	s4,32(sp)
    800018e2:	ec56                	sd	s5,24(sp)
    800018e4:	e85a                	sd	s6,16(sp)
    800018e6:	e45e                	sd	s7,8(sp)
    800018e8:	0880                	addi	s0,sp,80
    800018ea:	8a2a                	mv	s4,a0
    800018ec:	8b2e                	mv	s6,a1
    800018ee:	8bb2                	mv	s7,a2
    800018f0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f4:	6985                	lui	s3,0x1
    800018f6:	a02d                	j	80001920 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018fc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018fe:	37fd                	addiw	a5,a5,-1
    80001900:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001904:	60a6                	ld	ra,72(sp)
    80001906:	6406                	ld	s0,64(sp)
    80001908:	74e2                	ld	s1,56(sp)
    8000190a:	7942                	ld	s2,48(sp)
    8000190c:	79a2                	ld	s3,40(sp)
    8000190e:	7a02                	ld	s4,32(sp)
    80001910:	6ae2                	ld	s5,24(sp)
    80001912:	6b42                	ld	s6,16(sp)
    80001914:	6ba2                	ld	s7,8(sp)
    80001916:	6161                	addi	sp,sp,80
    80001918:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000191e:	c8a9                	beqz	s1,80001970 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001920:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001924:	85ca                	mv	a1,s2
    80001926:	8552                	mv	a0,s4
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	86c080e7          	jalr	-1940(ra) # 80001194 <walkaddr>
    if(pa0 == 0)
    80001930:	c131                	beqz	a0,80001974 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001932:	417906b3          	sub	a3,s2,s7
    80001936:	96ce                	add	a3,a3,s3
    80001938:	00d4f363          	bgeu	s1,a3,8000193e <copyinstr+0x6c>
    8000193c:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000193e:	955e                	add	a0,a0,s7
    80001940:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001944:	daf9                	beqz	a3,8000191a <copyinstr+0x48>
    80001946:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001948:	41650633          	sub	a2,a0,s6
    8000194c:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdb9bbf>
    80001950:	95da                	add	a1,a1,s6
    while(n > 0){
    80001952:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001954:	00f60733          	add	a4,a2,a5
    80001958:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb9bc0>
    8000195c:	df51                	beqz	a4,800018f8 <copyinstr+0x26>
        *dst = *p;
    8000195e:	00e78023          	sb	a4,0(a5)
      --max;
    80001962:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001966:	0785                	addi	a5,a5,1
    while(n > 0){
    80001968:	fed796e3          	bne	a5,a3,80001954 <copyinstr+0x82>
      dst++;
    8000196c:	8b3e                	mv	s6,a5
    8000196e:	b775                	j	8000191a <copyinstr+0x48>
    80001970:	4781                	li	a5,0
    80001972:	b771                	j	800018fe <copyinstr+0x2c>
      return -1;
    80001974:	557d                	li	a0,-1
    80001976:	b779                	j	80001904 <copyinstr+0x32>
  int got_null = 0;
    80001978:	4781                	li	a5,0
  if(got_null){
    8000197a:	37fd                	addiw	a5,a5,-1
    8000197c:	0007851b          	sext.w	a0,a5
}
    80001980:	8082                	ret

0000000080001982 <helpticks>:
// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;
void helpticks(){
    80001982:	7139                	addi	sp,sp,-64
    80001984:	fc06                	sd	ra,56(sp)
    80001986:	f822                	sd	s0,48(sp)
    80001988:	f426                	sd	s1,40(sp)
    8000198a:	f04a                	sd	s2,32(sp)
    8000198c:	ec4e                	sd	s3,24(sp)
    8000198e:	e852                	sd	s4,16(sp)
    80001990:	e456                	sd	s5,8(sp)
    80001992:	0080                	addi	s0,sp,64
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80001994:	00230497          	auipc	s1,0x230
    80001998:	ecc48493          	addi	s1,s1,-308 # 80231860 <proc>
    acquire(&p->lock);
    if (p->state==RUNNING){
    8000199c:	4991                	li	s3,4
      p->rtime++;
    }
    if (p->state==SLEEPING){
    8000199e:	4a09                	li	s4,2
      p->wtime++;
      p->stime++;
    }
    if(p->state==RUNNABLE){
    800019a0:	4a8d                	li	s5,3
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800019a2:	00238917          	auipc	s2,0x238
    800019a6:	6be90913          	addi	s2,s2,1726 # 8023a060 <tickslock>
    800019aa:	a839                	j	800019c8 <helpticks+0x46>
      p->rtime++;
    800019ac:	1784b783          	ld	a5,376(s1)
    800019b0:	0785                	addi	a5,a5,1
    800019b2:	16f4bc23          	sd	a5,376(s1)
      p->watime++;
    }
    release(&p->lock);
    800019b6:	8526                	mv	a0,s1
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	40a080e7          	jalr	1034(ra) # 80000dc2 <release>
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800019c0:	22048493          	addi	s1,s1,544
    800019c4:	03248f63          	beq	s1,s2,80001a02 <helpticks+0x80>
    acquire(&p->lock);
    800019c8:	8526                	mv	a0,s1
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	344080e7          	jalr	836(ra) # 80000d0e <acquire>
    if (p->state==RUNNING){
    800019d2:	4c9c                	lw	a5,24(s1)
    800019d4:	fd378ce3          	beq	a5,s3,800019ac <helpticks+0x2a>
    if (p->state==SLEEPING){
    800019d8:	01479d63          	bne	a5,s4,800019f2 <helpticks+0x70>
      p->wtime++;
    800019dc:	1704b783          	ld	a5,368(s1)
    800019e0:	0785                	addi	a5,a5,1
    800019e2:	16f4b823          	sd	a5,368(s1)
      p->stime++;
    800019e6:	1804b783          	ld	a5,384(s1)
    800019ea:	0785                	addi	a5,a5,1
    800019ec:	18f4b023          	sd	a5,384(s1)
    if(p->state==RUNNABLE){
    800019f0:	b7d9                	j	800019b6 <helpticks+0x34>
    800019f2:	fd5792e3          	bne	a5,s5,800019b6 <helpticks+0x34>
      p->watime++;
    800019f6:	1884b783          	ld	a5,392(s1)
    800019fa:	0785                	addi	a5,a5,1
    800019fc:	18f4b423          	sd	a5,392(s1)
    80001a00:	bf5d                	j	800019b6 <helpticks+0x34>
}
}
    80001a02:	70e2                	ld	ra,56(sp)
    80001a04:	7442                	ld	s0,48(sp)
    80001a06:	74a2                	ld	s1,40(sp)
    80001a08:	7902                	ld	s2,32(sp)
    80001a0a:	69e2                	ld	s3,24(sp)
    80001a0c:	6a42                	ld	s4,16(sp)
    80001a0e:	6aa2                	ld	s5,8(sp)
    80001a10:	6121                	addi	sp,sp,64
    80001a12:	8082                	ret

0000000080001a14 <addQueue>:
int addQueue(int qno,struct proc *p){
    80001a14:	862a                	mv	a2,a0
    for(int i=0; i<q_t[qno];i++){
    80001a16:	00251713          	slli	a4,a0,0x2
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f0678793          	addi	a5,a5,-250 # 80008920 <q_t>
    80001a22:	97ba                	add	a5,a5,a4
    80001a24:	4388                	lw	a0,0(a5)
    80001a26:	02a05f63          	blez	a0,80001a64 <addQueue+0x50>
      if(p->pid==que[qno][i]->pid){
    80001a2a:	0305a803          	lw	a6,48(a1)
    80001a2e:	00961793          	slli	a5,a2,0x9
    80001a32:	0022f717          	auipc	a4,0x22f
    80001a36:	62e70713          	addi	a4,a4,1582 # 80231060 <que>
    80001a3a:	97ba                	add	a5,a5,a4
    80001a3c:	00661693          	slli	a3,a2,0x6
    80001a40:	fff5071b          	addiw	a4,a0,-1
    80001a44:	1702                	slli	a4,a4,0x20
    80001a46:	9301                	srli	a4,a4,0x20
    80001a48:	96ba                	add	a3,a3,a4
    80001a4a:	068e                	slli	a3,a3,0x3
    80001a4c:	0022f717          	auipc	a4,0x22f
    80001a50:	61c70713          	addi	a4,a4,1564 # 80231068 <que+0x8>
    80001a54:	96ba                	add	a3,a3,a4
    80001a56:	6398                	ld	a4,0(a5)
    80001a58:	5b18                	lw	a4,48(a4)
    80001a5a:	07070f63          	beq	a4,a6,80001ad8 <addQueue+0xc4>
    for(int i=0; i<q_t[qno];i++){
    80001a5e:	07a1                	addi	a5,a5,8
    80001a60:	fed79be3          	bne	a5,a3,80001a56 <addQueue+0x42>
          return 1;
      }
    }
    p->que=qno;
    80001a64:	1cc5b023          	sd	a2,448(a1)
    p->entry=ticks;
    80001a68:	00007697          	auipc	a3,0x7
    80001a6c:	f586a683          	lw	a3,-168(a3) # 800089c0 <ticks>
    80001a70:	02069793          	slli	a5,a3,0x20
    80001a74:	9381                	srli	a5,a5,0x20
    80001a76:	1ef5b023          	sd	a5,480(a1)
    q_t[qno]++;
    80001a7a:	2505                	addiw	a0,a0,1
    80001a7c:	0005071b          	sext.w	a4,a0
    80001a80:	00261813          	slli	a6,a2,0x2
    80001a84:	00007797          	auipc	a5,0x7
    80001a88:	e9c78793          	addi	a5,a5,-356 # 80008920 <q_t>
    80001a8c:	97c2                	add	a5,a5,a6
    80001a8e:	c388                	sw	a0,0(a5)
    que[qno][q_t[qno]]=p;
    80001a90:	00661793          	slli	a5,a2,0x6
    80001a94:	97ba                	add	a5,a5,a4
    80001a96:	078e                	slli	a5,a5,0x3
    80001a98:	0022f717          	auipc	a4,0x22f
    80001a9c:	5c870713          	addi	a4,a4,1480 # 80231060 <que>
    80001aa0:	97ba                	add	a5,a5,a4
    80001aa2:	e38c                	sd	a1,0(a5)
     if(p->pid>2 && p->pid<13)
    80001aa4:	598c                	lw	a1,48(a1)
    80001aa6:	ffd5871b          	addiw	a4,a1,-3
    80001aaa:	47a5                	li	a5,9
    printf("Process with PID %d added to Queue %d at %d\n", p->pid-2, qno,ticks);
    return 0;
    80001aac:	4501                	li	a0,0
     if(p->pid>2 && p->pid<13)
    80001aae:	00e7f363          	bgeu	a5,a4,80001ab4 <addQueue+0xa0>
}
    80001ab2:	8082                	ret
int addQueue(int qno,struct proc *p){
    80001ab4:	1141                	addi	sp,sp,-16
    80001ab6:	e406                	sd	ra,8(sp)
    80001ab8:	e022                	sd	s0,0(sp)
    80001aba:	0800                	addi	s0,sp,16
    printf("Process with PID %d added to Queue %d at %d\n", p->pid-2, qno,ticks);
    80001abc:	35f9                	addiw	a1,a1,-2
    80001abe:	00006517          	auipc	a0,0x6
    80001ac2:	76a50513          	addi	a0,a0,1898 # 80008228 <digits+0x1e8>
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	ac4080e7          	jalr	-1340(ra) # 8000058a <printf>
    return 0;
    80001ace:	4501                	li	a0,0
}
    80001ad0:	60a2                	ld	ra,8(sp)
    80001ad2:	6402                	ld	s0,0(sp)
    80001ad4:	0141                	addi	sp,sp,16
    80001ad6:	8082                	ret
          return 1;
    80001ad8:	4505                	li	a0,1
    80001ada:	8082                	ret

0000000080001adc <deleteQueue>:
int deleteQueue(int qno,struct proc *p){
    80001adc:	1141                	addi	sp,sp,-16
    80001ade:	e422                	sd	s0,8(sp)
    80001ae0:	0800                	addi	s0,sp,16
  int r=0;
  int foundProcess=-1;
  for(int i=0;i<=q_t[qno];i++){
    80001ae2:	00251713          	slli	a4,a0,0x2
    80001ae6:	00007797          	auipc	a5,0x7
    80001aea:	e3a78793          	addi	a5,a5,-454 # 80008920 <q_t>
    80001aee:	97ba                	add	a5,a5,a4
    80001af0:	4390                	lw	a2,0(a5)
    80001af2:	06064f63          	bltz	a2,80001b70 <deleteQueue+0x94>
    if(que[qno][i]->pid==p->pid){
    80001af6:	598c                	lw	a1,48(a1)
    80001af8:	00951793          	slli	a5,a0,0x9
    80001afc:	0022f717          	auipc	a4,0x22f
    80001b00:	56470713          	addi	a4,a4,1380 # 80231060 <que>
    80001b04:	97ba                	add	a5,a5,a4
  for(int i=0;i<=q_t[qno];i++){
    80001b06:	4701                	li	a4,0
    if(que[qno][i]->pid==p->pid){
    80001b08:	6394                	ld	a3,0(a5)
    80001b0a:	5a94                	lw	a3,48(a3)
    80001b0c:	00b68863          	beq	a3,a1,80001b1c <deleteQueue+0x40>
  for(int i=0;i<=q_t[qno];i++){
    80001b10:	2705                	addiw	a4,a4,1
    80001b12:	07a1                	addi	a5,a5,8
    80001b14:	fee65ae3          	bge	a2,a4,80001b08 <deleteQueue+0x2c>
      r=i;
      break;
    }
  }
  if(foundProcess==-1){
    return -1;
    80001b18:	557d                	li	a0,-1
    80001b1a:	a881                	j	80001b6a <deleteQueue+0x8e>
  }
  for(int i=r;i<q_t[qno];++i){
    80001b1c:	02c75e63          	bge	a4,a2,80001b58 <deleteQueue+0x7c>
    80001b20:	00651593          	slli	a1,a0,0x6
    80001b24:	95ba                	add	a1,a1,a4
    80001b26:	00359793          	slli	a5,a1,0x3
    80001b2a:	0022f697          	auipc	a3,0x22f
    80001b2e:	53668693          	addi	a3,a3,1334 # 80231060 <que>
    80001b32:	97b6                	add	a5,a5,a3
    80001b34:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80001b38:	40e6873b          	subw	a4,a3,a4
    80001b3c:	1702                	slli	a4,a4,0x20
    80001b3e:	9301                	srli	a4,a4,0x20
    80001b40:	972e                	add	a4,a4,a1
    80001b42:	070e                	slli	a4,a4,0x3
    80001b44:	0022f697          	auipc	a3,0x22f
    80001b48:	52468693          	addi	a3,a3,1316 # 80231068 <que+0x8>
    80001b4c:	9736                	add	a4,a4,a3
    que[qno][i]=que[qno][i+1];
    80001b4e:	6794                	ld	a3,8(a5)
    80001b50:	e394                	sd	a3,0(a5)
  for(int i=r;i<q_t[qno];++i){
    80001b52:	07a1                	addi	a5,a5,8
    80001b54:	fee79de3          	bne	a5,a4,80001b4e <deleteQueue+0x72>
  }
  q_t[qno]--;
    80001b58:	050a                	slli	a0,a0,0x2
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	dc678793          	addi	a5,a5,-570 # 80008920 <q_t>
    80001b62:	97aa                	add	a5,a5,a0
    80001b64:	367d                	addiw	a2,a2,-1
    80001b66:	c390                	sw	a2,0(a5)
  //printf("Process with PID %d is removed from Queue %d at %d\n", p->pid, qno,ticks);
  return 1;
    80001b68:	4505                	li	a0,1
}
    80001b6a:	6422                	ld	s0,8(sp)
    80001b6c:	0141                	addi	sp,sp,16
    80001b6e:	8082                	ret
    return -1;
    80001b70:	557d                	li	a0,-1
    80001b72:	bfe5                	j	80001b6a <deleteQueue+0x8e>

0000000080001b74 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001b74:	7139                	addi	sp,sp,-64
    80001b76:	fc06                	sd	ra,56(sp)
    80001b78:	f822                	sd	s0,48(sp)
    80001b7a:	f426                	sd	s1,40(sp)
    80001b7c:	f04a                	sd	s2,32(sp)
    80001b7e:	ec4e                	sd	s3,24(sp)
    80001b80:	e852                	sd	s4,16(sp)
    80001b82:	e456                	sd	s5,8(sp)
    80001b84:	e05a                	sd	s6,0(sp)
    80001b86:	0080                	addi	s0,sp,64
    80001b88:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001b8a:	00230497          	auipc	s1,0x230
    80001b8e:	cd648493          	addi	s1,s1,-810 # 80231860 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001b92:	8b26                	mv	s6,s1
    80001b94:	00006a97          	auipc	s5,0x6
    80001b98:	46ca8a93          	addi	s5,s5,1132 # 80008000 <etext>
    80001b9c:	04000937          	lui	s2,0x4000
    80001ba0:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ba2:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ba4:	00238a17          	auipc	s4,0x238
    80001ba8:	4bca0a13          	addi	s4,s4,1212 # 8023a060 <tickslock>
    char *pa = kalloc();
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	03a080e7          	jalr	58(ra) # 80000be6 <kalloc>
    80001bb4:	862a                	mv	a2,a0
    if (pa == 0)
    80001bb6:	c131                	beqz	a0,80001bfa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001bb8:	416485b3          	sub	a1,s1,s6
    80001bbc:	8595                	srai	a1,a1,0x5
    80001bbe:	000ab783          	ld	a5,0(s5)
    80001bc2:	02f585b3          	mul	a1,a1,a5
    80001bc6:	2585                	addiw	a1,a1,1
    80001bc8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bcc:	4719                	li	a4,6
    80001bce:	6685                	lui	a3,0x1
    80001bd0:	40b905b3          	sub	a1,s2,a1
    80001bd4:	854e                	mv	a0,s3
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	6a0080e7          	jalr	1696(ra) # 80001276 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bde:	22048493          	addi	s1,s1,544
    80001be2:	fd4495e3          	bne	s1,s4,80001bac <proc_mapstacks+0x38>
  }
}
    80001be6:	70e2                	ld	ra,56(sp)
    80001be8:	7442                	ld	s0,48(sp)
    80001bea:	74a2                	ld	s1,40(sp)
    80001bec:	7902                	ld	s2,32(sp)
    80001bee:	69e2                	ld	s3,24(sp)
    80001bf0:	6a42                	ld	s4,16(sp)
    80001bf2:	6aa2                	ld	s5,8(sp)
    80001bf4:	6b02                	ld	s6,0(sp)
    80001bf6:	6121                	addi	sp,sp,64
    80001bf8:	8082                	ret
      panic("kalloc");
    80001bfa:	00006517          	auipc	a0,0x6
    80001bfe:	65e50513          	addi	a0,a0,1630 # 80008258 <digits+0x218>
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	93e080e7          	jalr	-1730(ra) # 80000540 <panic>

0000000080001c0a <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001c0a:	7139                	addi	sp,sp,-64
    80001c0c:	fc06                	sd	ra,56(sp)
    80001c0e:	f822                	sd	s0,48(sp)
    80001c10:	f426                	sd	s1,40(sp)
    80001c12:	f04a                	sd	s2,32(sp)
    80001c14:	ec4e                	sd	s3,24(sp)
    80001c16:	e852                	sd	s4,16(sp)
    80001c18:	e456                	sd	s5,8(sp)
    80001c1a:	e05a                	sd	s6,0(sp)
    80001c1c:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001c1e:	00006597          	auipc	a1,0x6
    80001c22:	64258593          	addi	a1,a1,1602 # 80008260 <digits+0x220>
    80001c26:	0022f517          	auipc	a0,0x22f
    80001c2a:	00a50513          	addi	a0,a0,10 # 80230c30 <pid_lock>
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	050080e7          	jalr	80(ra) # 80000c7e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c36:	00006597          	auipc	a1,0x6
    80001c3a:	63258593          	addi	a1,a1,1586 # 80008268 <digits+0x228>
    80001c3e:	0022f517          	auipc	a0,0x22f
    80001c42:	00a50513          	addi	a0,a0,10 # 80230c48 <wait_lock>
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	038080e7          	jalr	56(ra) # 80000c7e <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c4e:	00230497          	auipc	s1,0x230
    80001c52:	c1248493          	addi	s1,s1,-1006 # 80231860 <proc>
  {
    initlock(&p->lock, "proc");
    80001c56:	00006b17          	auipc	s6,0x6
    80001c5a:	622b0b13          	addi	s6,s6,1570 # 80008278 <digits+0x238>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001c5e:	8aa6                	mv	s5,s1
    80001c60:	00006a17          	auipc	s4,0x6
    80001c64:	3a0a0a13          	addi	s4,s4,928 # 80008000 <etext>
    80001c68:	04000937          	lui	s2,0x4000
    80001c6c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c6e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001c70:	00238997          	auipc	s3,0x238
    80001c74:	3f098993          	addi	s3,s3,1008 # 8023a060 <tickslock>
    initlock(&p->lock, "proc");
    80001c78:	85da                	mv	a1,s6
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	002080e7          	jalr	2(ra) # 80000c7e <initlock>
    p->state = UNUSED;
    80001c84:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001c88:	415487b3          	sub	a5,s1,s5
    80001c8c:	8795                	srai	a5,a5,0x5
    80001c8e:	000a3703          	ld	a4,0(s4)
    80001c92:	02e787b3          	mul	a5,a5,a4
    80001c96:	2785                	addiw	a5,a5,1
    80001c98:	00d7979b          	slliw	a5,a5,0xd
    80001c9c:	40f907b3          	sub	a5,s2,a5
    80001ca0:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001ca2:	22048493          	addi	s1,s1,544
    80001ca6:	fd3499e3          	bne	s1,s3,80001c78 <procinit+0x6e>
  }
}
    80001caa:	70e2                	ld	ra,56(sp)
    80001cac:	7442                	ld	s0,48(sp)
    80001cae:	74a2                	ld	s1,40(sp)
    80001cb0:	7902                	ld	s2,32(sp)
    80001cb2:	69e2                	ld	s3,24(sp)
    80001cb4:	6a42                	ld	s4,16(sp)
    80001cb6:	6aa2                	ld	s5,8(sp)
    80001cb8:	6b02                	ld	s6,0(sp)
    80001cba:	6121                	addi	sp,sp,64
    80001cbc:	8082                	ret

0000000080001cbe <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001cbe:	1141                	addi	sp,sp,-16
    80001cc0:	e422                	sd	s0,8(sp)
    80001cc2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cc4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001cc6:	2501                	sext.w	a0,a0
    80001cc8:	6422                	ld	s0,8(sp)
    80001cca:	0141                	addi	sp,sp,16
    80001ccc:	8082                	ret

0000000080001cce <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001cce:	1141                	addi	sp,sp,-16
    80001cd0:	e422                	sd	s0,8(sp)
    80001cd2:	0800                	addi	s0,sp,16
    80001cd4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cd6:	2781                	sext.w	a5,a5
    80001cd8:	079e                	slli	a5,a5,0x7
  return c;
}
    80001cda:	0022f517          	auipc	a0,0x22f
    80001cde:	f8650513          	addi	a0,a0,-122 # 80230c60 <cpus>
    80001ce2:	953e                	add	a0,a0,a5
    80001ce4:	6422                	ld	s0,8(sp)
    80001ce6:	0141                	addi	sp,sp,16
    80001ce8:	8082                	ret

0000000080001cea <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	1000                	addi	s0,sp,32
  push_off();
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	fce080e7          	jalr	-50(ra) # 80000cc2 <push_off>
    80001cfc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001cfe:	2781                	sext.w	a5,a5
    80001d00:	079e                	slli	a5,a5,0x7
    80001d02:	0022f717          	auipc	a4,0x22f
    80001d06:	f2e70713          	addi	a4,a4,-210 # 80230c30 <pid_lock>
    80001d0a:	97ba                	add	a5,a5,a4
    80001d0c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	054080e7          	jalr	84(ra) # 80000d62 <pop_off>
  return p;
}
    80001d16:	8526                	mv	a0,s1
    80001d18:	60e2                	ld	ra,24(sp)
    80001d1a:	6442                	ld	s0,16(sp)
    80001d1c:	64a2                	ld	s1,8(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret

0000000080001d22 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d22:	1141                	addi	sp,sp,-16
    80001d24:	e406                	sd	ra,8(sp)
    80001d26:	e022                	sd	s0,0(sp)
    80001d28:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	fc0080e7          	jalr	-64(ra) # 80001cea <myproc>
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	090080e7          	jalr	144(ra) # 80000dc2 <release>

  if (first)
    80001d3a:	00007797          	auipc	a5,0x7
    80001d3e:	bd67a783          	lw	a5,-1066(a5) # 80008910 <first.1>
    80001d42:	eb89                	bnez	a5,80001d54 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d44:	00001097          	auipc	ra,0x1
    80001d48:	104080e7          	jalr	260(ra) # 80002e48 <usertrapret>
}
    80001d4c:	60a2                	ld	ra,8(sp)
    80001d4e:	6402                	ld	s0,0(sp)
    80001d50:	0141                	addi	sp,sp,16
    80001d52:	8082                	ret
    first = 0;
    80001d54:	00007797          	auipc	a5,0x7
    80001d58:	ba07ae23          	sw	zero,-1092(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001d5c:	4505                	li	a0,1
    80001d5e:	00002097          	auipc	ra,0x2
    80001d62:	0f8080e7          	jalr	248(ra) # 80003e56 <fsinit>
    80001d66:	bff9                	j	80001d44 <forkret+0x22>

0000000080001d68 <allocpid>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d74:	0022f917          	auipc	s2,0x22f
    80001d78:	ebc90913          	addi	s2,s2,-324 # 80230c30 <pid_lock>
    80001d7c:	854a                	mv	a0,s2
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	f90080e7          	jalr	-112(ra) # 80000d0e <acquire>
  pid = nextpid;
    80001d86:	00007797          	auipc	a5,0x7
    80001d8a:	b8e78793          	addi	a5,a5,-1138 # 80008914 <nextpid>
    80001d8e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d90:	0014871b          	addiw	a4,s1,1
    80001d94:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d96:	854a                	mv	a0,s2
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	02a080e7          	jalr	42(ra) # 80000dc2 <release>
}
    80001da0:	8526                	mv	a0,s1
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6902                	ld	s2,0(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret

0000000080001dae <proc_pagetable>:
{
    80001dae:	1101                	addi	sp,sp,-32
    80001db0:	ec06                	sd	ra,24(sp)
    80001db2:	e822                	sd	s0,16(sp)
    80001db4:	e426                	sd	s1,8(sp)
    80001db6:	e04a                	sd	s2,0(sp)
    80001db8:	1000                	addi	s0,sp,32
    80001dba:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	6a4080e7          	jalr	1700(ra) # 80001460 <uvmcreate>
    80001dc4:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001dc6:	c121                	beqz	a0,80001e06 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dc8:	4729                	li	a4,10
    80001dca:	00005697          	auipc	a3,0x5
    80001dce:	23668693          	addi	a3,a3,566 # 80007000 <_trampoline>
    80001dd2:	6605                	lui	a2,0x1
    80001dd4:	040005b7          	lui	a1,0x4000
    80001dd8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dda:	05b2                	slli	a1,a1,0xc
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	3fa080e7          	jalr	1018(ra) # 800011d6 <mappages>
    80001de4:	02054863          	bltz	a0,80001e14 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001de8:	4719                	li	a4,6
    80001dea:	05893683          	ld	a3,88(s2)
    80001dee:	6605                	lui	a2,0x1
    80001df0:	020005b7          	lui	a1,0x2000
    80001df4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001df6:	05b6                	slli	a1,a1,0xd
    80001df8:	8526                	mv	a0,s1
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	3dc080e7          	jalr	988(ra) # 800011d6 <mappages>
    80001e02:	02054163          	bltz	a0,80001e24 <proc_pagetable+0x76>
}
    80001e06:	8526                	mv	a0,s1
    80001e08:	60e2                	ld	ra,24(sp)
    80001e0a:	6442                	ld	s0,16(sp)
    80001e0c:	64a2                	ld	s1,8(sp)
    80001e0e:	6902                	ld	s2,0(sp)
    80001e10:	6105                	addi	sp,sp,32
    80001e12:	8082                	ret
    uvmfree(pagetable, 0);
    80001e14:	4581                	li	a1,0
    80001e16:	8526                	mv	a0,s1
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	84e080e7          	jalr	-1970(ra) # 80001666 <uvmfree>
    return 0;
    80001e20:	4481                	li	s1,0
    80001e22:	b7d5                	j	80001e06 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e24:	4681                	li	a3,0
    80001e26:	4605                	li	a2,1
    80001e28:	040005b7          	lui	a1,0x4000
    80001e2c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e2e:	05b2                	slli	a1,a1,0xc
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	56a080e7          	jalr	1386(ra) # 8000139c <uvmunmap>
    uvmfree(pagetable, 0);
    80001e3a:	4581                	li	a1,0
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	828080e7          	jalr	-2008(ra) # 80001666 <uvmfree>
    return 0;
    80001e46:	4481                	li	s1,0
    80001e48:	bf7d                	j	80001e06 <proc_pagetable+0x58>

0000000080001e4a <proc_freepagetable>:
{
    80001e4a:	1101                	addi	sp,sp,-32
    80001e4c:	ec06                	sd	ra,24(sp)
    80001e4e:	e822                	sd	s0,16(sp)
    80001e50:	e426                	sd	s1,8(sp)
    80001e52:	e04a                	sd	s2,0(sp)
    80001e54:	1000                	addi	s0,sp,32
    80001e56:	84aa                	mv	s1,a0
    80001e58:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e5a:	4681                	li	a3,0
    80001e5c:	4605                	li	a2,1
    80001e5e:	040005b7          	lui	a1,0x4000
    80001e62:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e64:	05b2                	slli	a1,a1,0xc
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	536080e7          	jalr	1334(ra) # 8000139c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e6e:	4681                	li	a3,0
    80001e70:	4605                	li	a2,1
    80001e72:	020005b7          	lui	a1,0x2000
    80001e76:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e78:	05b6                	slli	a1,a1,0xd
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	520080e7          	jalr	1312(ra) # 8000139c <uvmunmap>
  uvmfree(pagetable, sz);
    80001e84:	85ca                	mv	a1,s2
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	7de080e7          	jalr	2014(ra) # 80001666 <uvmfree>
}
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6902                	ld	s2,0(sp)
    80001e98:	6105                	addi	sp,sp,32
    80001e9a:	8082                	ret

0000000080001e9c <freeproc>:
{
    80001e9c:	1101                	addi	sp,sp,-32
    80001e9e:	ec06                	sd	ra,24(sp)
    80001ea0:	e822                	sd	s0,16(sp)
    80001ea2:	e426                	sd	s1,8(sp)
    80001ea4:	1000                	addi	s0,sp,32
    80001ea6:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001ea8:	6d28                	ld	a0,88(a0)
    80001eaa:	c509                	beqz	a0,80001eb4 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	bb4080e7          	jalr	-1100(ra) # 80000a60 <kfree>
  p->trapframe = 0;
    80001eb4:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001eb8:	68a8                	ld	a0,80(s1)
    80001eba:	c511                	beqz	a0,80001ec6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ebc:	64ac                	ld	a1,72(s1)
    80001ebe:	00000097          	auipc	ra,0x0
    80001ec2:	f8c080e7          	jalr	-116(ra) # 80001e4a <proc_freepagetable>
  p->pagetable = 0;
    80001ec6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001eca:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ece:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ed2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ed6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001eda:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ede:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ee2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ee6:	0004ac23          	sw	zero,24(s1)
}
    80001eea:	60e2                	ld	ra,24(sp)
    80001eec:	6442                	ld	s0,16(sp)
    80001eee:	64a2                	ld	s1,8(sp)
    80001ef0:	6105                	addi	sp,sp,32
    80001ef2:	8082                	ret

0000000080001ef4 <allocproc>:
{
    80001ef4:	1101                	addi	sp,sp,-32
    80001ef6:	ec06                	sd	ra,24(sp)
    80001ef8:	e822                	sd	s0,16(sp)
    80001efa:	e426                	sd	s1,8(sp)
    80001efc:	e04a                	sd	s2,0(sp)
    80001efe:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001f00:	00230497          	auipc	s1,0x230
    80001f04:	96048493          	addi	s1,s1,-1696 # 80231860 <proc>
    80001f08:	00238917          	auipc	s2,0x238
    80001f0c:	15890913          	addi	s2,s2,344 # 8023a060 <tickslock>
    acquire(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	dfc080e7          	jalr	-516(ra) # 80000d0e <acquire>
    if (p->state == UNUSED)
    80001f1a:	4c9c                	lw	a5,24(s1)
    80001f1c:	cf81                	beqz	a5,80001f34 <allocproc+0x40>
      release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	ea2080e7          	jalr	-350(ra) # 80000dc2 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f28:	22048493          	addi	s1,s1,544
    80001f2c:	ff2492e3          	bne	s1,s2,80001f10 <allocproc+0x1c>
  return 0;
    80001f30:	4481                	li	s1,0
    80001f32:	a075                	j	80001fde <allocproc+0xea>
  p->pid = allocpid();
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	e34080e7          	jalr	-460(ra) # 80001d68 <allocpid>
    80001f3c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001f3e:	4785                	li	a5,1
    80001f40:	cc9c                	sw	a5,24(s1)
  p->clktik=ticks;
    80001f42:	00007797          	auipc	a5,0x7
    80001f46:	a7e7e783          	lwu	a5,-1410(a5) # 800089c0 <ticks>
    80001f4a:	16f4b423          	sd	a5,360(s1)
  p->rtime=0;
    80001f4e:	1604bc23          	sd	zero,376(s1)
  p->wtime=0;
    80001f52:	1604b823          	sd	zero,368(s1)
  p->etime=0;
    80001f56:	1804b823          	sd	zero,400(s1)
  p->dyna_priority=0;
    80001f5a:	2004a823          	sw	zero,528(s1)
  p->stat_priority=50;
    80001f5e:	03200793          	li	a5,50
    80001f62:	20f4a623          	sw	a5,524(s1)
  p->watime=0;
    80001f66:	1804b423          	sd	zero,392(s1)
  p->stime=0;
    80001f6a:	1804b023          	sd	zero,384(s1)
    p->qticks[i]=0;
    80001f6e:	1a04b023          	sd	zero,416(s1)
    80001f72:	1a04b423          	sd	zero,424(s1)
    80001f76:	1a04b823          	sd	zero,432(s1)
    80001f7a:	1a04bc23          	sd	zero,440(s1)
  p->sched_times=0;
    80001f7e:	2004ac23          	sw	zero,536(s1)
  p->rbi=15;
    80001f82:	47bd                	li	a5,15
    80001f84:	20f4aa23          	sw	a5,532(s1)
  p->currticks=0;
    80001f88:	1c04b823          	sd	zero,464(s1)
  p->que=0;
    80001f8c:	1c04b023          	sd	zero,448(s1)
  p->wmlfq=0;
    80001f90:	1c04b423          	sd	zero,456(s1)
  p->runnum=0;
    80001f94:	1804bc23          	sd	zero,408(s1)
  p->entry=0;
    80001f98:	1e04b023          	sd	zero,480(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	c4a080e7          	jalr	-950(ra) # 80000be6 <kalloc>
    80001fa4:	892a                	mv	s2,a0
    80001fa6:	eca8                	sd	a0,88(s1)
    80001fa8:	c131                	beqz	a0,80001fec <allocproc+0xf8>
  p->pagetable = proc_pagetable(p);
    80001faa:	8526                	mv	a0,s1
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	e02080e7          	jalr	-510(ra) # 80001dae <proc_pagetable>
    80001fb4:	892a                	mv	s2,a0
    80001fb6:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001fb8:	c531                	beqz	a0,80002004 <allocproc+0x110>
  memset(&p->context, 0, sizeof(p->context));
    80001fba:	07000613          	li	a2,112
    80001fbe:	4581                	li	a1,0
    80001fc0:	06048513          	addi	a0,s1,96
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	e46080e7          	jalr	-442(ra) # 80000e0a <memset>
  p->context.ra = (uint64)forkret;
    80001fcc:	00000797          	auipc	a5,0x0
    80001fd0:	d5678793          	addi	a5,a5,-682 # 80001d22 <forkret>
    80001fd4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fd6:	60bc                	ld	a5,64(s1)
    80001fd8:	6705                	lui	a4,0x1
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	f4bc                	sd	a5,104(s1)
}
    80001fde:	8526                	mv	a0,s1
    80001fe0:	60e2                	ld	ra,24(sp)
    80001fe2:	6442                	ld	s0,16(sp)
    80001fe4:	64a2                	ld	s1,8(sp)
    80001fe6:	6902                	ld	s2,0(sp)
    80001fe8:	6105                	addi	sp,sp,32
    80001fea:	8082                	ret
    freeproc(p);
    80001fec:	8526                	mv	a0,s1
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	eae080e7          	jalr	-338(ra) # 80001e9c <freeproc>
    release(&p->lock);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	dca080e7          	jalr	-566(ra) # 80000dc2 <release>
    return 0;
    80002000:	84ca                	mv	s1,s2
    80002002:	bff1                	j	80001fde <allocproc+0xea>
    freeproc(p);
    80002004:	8526                	mv	a0,s1
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	e96080e7          	jalr	-362(ra) # 80001e9c <freeproc>
    release(&p->lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	db2080e7          	jalr	-590(ra) # 80000dc2 <release>
    return 0;
    80002018:	84ca                	mv	s1,s2
    8000201a:	b7d1                	j	80001fde <allocproc+0xea>

000000008000201c <userinit>:
{
    8000201c:	1101                	addi	sp,sp,-32
    8000201e:	ec06                	sd	ra,24(sp)
    80002020:	e822                	sd	s0,16(sp)
    80002022:	e426                	sd	s1,8(sp)
    80002024:	1000                	addi	s0,sp,32
  p = allocproc();
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	ece080e7          	jalr	-306(ra) # 80001ef4 <allocproc>
    8000202e:	84aa                	mv	s1,a0
  initproc = p;
    80002030:	00007797          	auipc	a5,0x7
    80002034:	98a7b423          	sd	a0,-1656(a5) # 800089b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80002038:	03400613          	li	a2,52
    8000203c:	00007597          	auipc	a1,0x7
    80002040:	8f458593          	addi	a1,a1,-1804 # 80008930 <initcode>
    80002044:	6928                	ld	a0,80(a0)
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	448080e7          	jalr	1096(ra) # 8000148e <uvmfirst>
  p->sz = PGSIZE;
    8000204e:	6785                	lui	a5,0x1
    80002050:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80002052:	6cb8                	ld	a4,88(s1)
    80002054:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80002058:	6cb8                	ld	a4,88(s1)
    8000205a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000205c:	4641                	li	a2,16
    8000205e:	00006597          	auipc	a1,0x6
    80002062:	22258593          	addi	a1,a1,546 # 80008280 <digits+0x240>
    80002066:	15848513          	addi	a0,s1,344
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	eea080e7          	jalr	-278(ra) # 80000f54 <safestrcpy>
  p->cwd = namei("/");
    80002072:	00006517          	auipc	a0,0x6
    80002076:	21e50513          	addi	a0,a0,542 # 80008290 <digits+0x250>
    8000207a:	00003097          	auipc	ra,0x3
    8000207e:	806080e7          	jalr	-2042(ra) # 80004880 <namei>
    80002082:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002086:	478d                	li	a5,3
    80002088:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	d36080e7          	jalr	-714(ra) # 80000dc2 <release>
}
    80002094:	60e2                	ld	ra,24(sp)
    80002096:	6442                	ld	s0,16(sp)
    80002098:	64a2                	ld	s1,8(sp)
    8000209a:	6105                	addi	sp,sp,32
    8000209c:	8082                	ret

000000008000209e <growproc>:
{
    8000209e:	1101                	addi	sp,sp,-32
    800020a0:	ec06                	sd	ra,24(sp)
    800020a2:	e822                	sd	s0,16(sp)
    800020a4:	e426                	sd	s1,8(sp)
    800020a6:	e04a                	sd	s2,0(sp)
    800020a8:	1000                	addi	s0,sp,32
    800020aa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	c3e080e7          	jalr	-962(ra) # 80001cea <myproc>
    800020b4:	84aa                	mv	s1,a0
  sz = p->sz;
    800020b6:	652c                	ld	a1,72(a0)
  if (n > 0)
    800020b8:	01204c63          	bgtz	s2,800020d0 <growproc+0x32>
  else if (n < 0)
    800020bc:	02094663          	bltz	s2,800020e8 <growproc+0x4a>
  p->sz = sz;
    800020c0:	e4ac                	sd	a1,72(s1)
  return 0;
    800020c2:	4501                	li	a0,0
}
    800020c4:	60e2                	ld	ra,24(sp)
    800020c6:	6442                	ld	s0,16(sp)
    800020c8:	64a2                	ld	s1,8(sp)
    800020ca:	6902                	ld	s2,0(sp)
    800020cc:	6105                	addi	sp,sp,32
    800020ce:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    800020d0:	4691                	li	a3,4
    800020d2:	00b90633          	add	a2,s2,a1
    800020d6:	6928                	ld	a0,80(a0)
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	470080e7          	jalr	1136(ra) # 80001548 <uvmalloc>
    800020e0:	85aa                	mv	a1,a0
    800020e2:	fd79                	bnez	a0,800020c0 <growproc+0x22>
      return -1;
    800020e4:	557d                	li	a0,-1
    800020e6:	bff9                	j	800020c4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020e8:	00b90633          	add	a2,s2,a1
    800020ec:	6928                	ld	a0,80(a0)
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	412080e7          	jalr	1042(ra) # 80001500 <uvmdealloc>
    800020f6:	85aa                	mv	a1,a0
    800020f8:	b7e1                	j	800020c0 <growproc+0x22>

00000000800020fa <fork>:
{
    800020fa:	7139                	addi	sp,sp,-64
    800020fc:	fc06                	sd	ra,56(sp)
    800020fe:	f822                	sd	s0,48(sp)
    80002100:	f426                	sd	s1,40(sp)
    80002102:	f04a                	sd	s2,32(sp)
    80002104:	ec4e                	sd	s3,24(sp)
    80002106:	e852                	sd	s4,16(sp)
    80002108:	e456                	sd	s5,8(sp)
    8000210a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	bde080e7          	jalr	-1058(ra) # 80001cea <myproc>
    80002114:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	dde080e7          	jalr	-546(ra) # 80001ef4 <allocproc>
    8000211e:	10050c63          	beqz	a0,80002236 <fork+0x13c>
    80002122:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002124:	048ab603          	ld	a2,72(s5)
    80002128:	692c                	ld	a1,80(a0)
    8000212a:	050ab503          	ld	a0,80(s5)
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	572080e7          	jalr	1394(ra) # 800016a0 <uvmcopy>
    80002136:	04054863          	bltz	a0,80002186 <fork+0x8c>
  np->sz = p->sz;
    8000213a:	048ab783          	ld	a5,72(s5)
    8000213e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002142:	058ab683          	ld	a3,88(s5)
    80002146:	87b6                	mv	a5,a3
    80002148:	058a3703          	ld	a4,88(s4)
    8000214c:	12068693          	addi	a3,a3,288
    80002150:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002154:	6788                	ld	a0,8(a5)
    80002156:	6b8c                	ld	a1,16(a5)
    80002158:	6f90                	ld	a2,24(a5)
    8000215a:	01073023          	sd	a6,0(a4)
    8000215e:	e708                	sd	a0,8(a4)
    80002160:	eb0c                	sd	a1,16(a4)
    80002162:	ef10                	sd	a2,24(a4)
    80002164:	02078793          	addi	a5,a5,32
    80002168:	02070713          	addi	a4,a4,32
    8000216c:	fed792e3          	bne	a5,a3,80002150 <fork+0x56>
  np->trapframe->a0 = 0;
    80002170:	058a3783          	ld	a5,88(s4)
    80002174:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002178:	0d0a8493          	addi	s1,s5,208
    8000217c:	0d0a0913          	addi	s2,s4,208
    80002180:	150a8993          	addi	s3,s5,336
    80002184:	a00d                	j	800021a6 <fork+0xac>
    freeproc(np);
    80002186:	8552                	mv	a0,s4
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	d14080e7          	jalr	-748(ra) # 80001e9c <freeproc>
    release(&np->lock);
    80002190:	8552                	mv	a0,s4
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	c30080e7          	jalr	-976(ra) # 80000dc2 <release>
    return -1;
    8000219a:	597d                	li	s2,-1
    8000219c:	a059                	j	80002222 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    8000219e:	04a1                	addi	s1,s1,8
    800021a0:	0921                	addi	s2,s2,8
    800021a2:	01348b63          	beq	s1,s3,800021b8 <fork+0xbe>
    if (p->ofile[i])
    800021a6:	6088                	ld	a0,0(s1)
    800021a8:	d97d                	beqz	a0,8000219e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800021aa:	00003097          	auipc	ra,0x3
    800021ae:	d6c080e7          	jalr	-660(ra) # 80004f16 <filedup>
    800021b2:	00a93023          	sd	a0,0(s2)
    800021b6:	b7e5                	j	8000219e <fork+0xa4>
  np->cwd = idup(p->cwd);
    800021b8:	150ab503          	ld	a0,336(s5)
    800021bc:	00002097          	auipc	ra,0x2
    800021c0:	eda080e7          	jalr	-294(ra) # 80004096 <idup>
    800021c4:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021c8:	4641                	li	a2,16
    800021ca:	158a8593          	addi	a1,s5,344
    800021ce:	158a0513          	addi	a0,s4,344
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	d82080e7          	jalr	-638(ra) # 80000f54 <safestrcpy>
  pid = np->pid;
    800021da:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800021de:	8552                	mv	a0,s4
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	be2080e7          	jalr	-1054(ra) # 80000dc2 <release>
  acquire(&wait_lock);
    800021e8:	0022f497          	auipc	s1,0x22f
    800021ec:	a6048493          	addi	s1,s1,-1440 # 80230c48 <wait_lock>
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	b1c080e7          	jalr	-1252(ra) # 80000d0e <acquire>
  np->parent = p;
    800021fa:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800021fe:	8526                	mv	a0,s1
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	bc2080e7          	jalr	-1086(ra) # 80000dc2 <release>
  acquire(&np->lock);
    80002208:	8552                	mv	a0,s4
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	b04080e7          	jalr	-1276(ra) # 80000d0e <acquire>
  np->state = RUNNABLE;
    80002212:	478d                	li	a5,3
    80002214:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002218:	8552                	mv	a0,s4
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	ba8080e7          	jalr	-1112(ra) # 80000dc2 <release>
}
    80002222:	854a                	mv	a0,s2
    80002224:	70e2                	ld	ra,56(sp)
    80002226:	7442                	ld	s0,48(sp)
    80002228:	74a2                	ld	s1,40(sp)
    8000222a:	7902                	ld	s2,32(sp)
    8000222c:	69e2                	ld	s3,24(sp)
    8000222e:	6a42                	ld	s4,16(sp)
    80002230:	6aa2                	ld	s5,8(sp)
    80002232:	6121                	addi	sp,sp,64
    80002234:	8082                	ret
    return -1;
    80002236:	597d                	li	s2,-1
    80002238:	b7ed                	j	80002222 <fork+0x128>

000000008000223a <scheduler>:
{
    8000223a:	7119                	addi	sp,sp,-128
    8000223c:	fc86                	sd	ra,120(sp)
    8000223e:	f8a2                	sd	s0,112(sp)
    80002240:	f4a6                	sd	s1,104(sp)
    80002242:	f0ca                	sd	s2,96(sp)
    80002244:	ecce                	sd	s3,88(sp)
    80002246:	e8d2                	sd	s4,80(sp)
    80002248:	e4d6                	sd	s5,72(sp)
    8000224a:	e0da                	sd	s6,64(sp)
    8000224c:	fc5e                	sd	s7,56(sp)
    8000224e:	f862                	sd	s8,48(sp)
    80002250:	f466                	sd	s9,40(sp)
    80002252:	f06a                	sd	s10,32(sp)
    80002254:	ec6e                	sd	s11,24(sp)
    80002256:	0100                	addi	s0,sp,128
    80002258:	8792                	mv	a5,tp
  int id = r_tp();
    8000225a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000225c:	00779693          	slli	a3,a5,0x7
    80002260:	0022f717          	auipc	a4,0x22f
    80002264:	9d070713          	addi	a4,a4,-1584 # 80230c30 <pid_lock>
    80002268:	9736                	add	a4,a4,a3
    8000226a:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &run_proc->context);
    8000226e:	0022f717          	auipc	a4,0x22f
    80002272:	9fa70713          	addi	a4,a4,-1542 # 80230c68 <cpus+0x8>
    80002276:	9736                	add	a4,a4,a3
    80002278:	f8e43423          	sd	a4,-120(s0)
  struct proc *run_proc = 0;
    8000227c:	4d81                	li	s11,0
      p->dyna_priority = (p->stat_priority + p->rbi > 100 ? 100 : p->stat_priority + p->rbi);
    8000227e:	06400c13          	li	s8,100
    80002282:	06400d13          	li	s10,100
  for (p = proc; p < &proc[NPROC]; p++) {
    80002286:	00238b17          	auipc	s6,0x238
    8000228a:	ddab0b13          	addi	s6,s6,-550 # 8023a060 <tickslock>
      c->proc = run_proc;
    8000228e:	0022f717          	auipc	a4,0x22f
    80002292:	9a270713          	addi	a4,a4,-1630 # 80230c30 <pid_lock>
    80002296:	00d707b3          	add	a5,a4,a3
    8000229a:	f8f43023          	sd	a5,-128(s0)
    8000229e:	a0f9                	j	8000236c <scheduler+0x132>
          (maxi_priority == p->dyna_priority && run_proc->sched_times > p->sched_times) ||
    800022a0:	218a2703          	lw	a4,536(s4)
    800022a4:	2184a783          	lw	a5,536(s1)
    800022a8:	00e7ca63          	blt	a5,a4,800022bc <scheduler+0x82>
          (maxi_priority == p->dyna_priority && run_proc->sched_times == p->sched_times && run_proc->clktik > p->clktik)) {
    800022ac:	0af71063          	bne	a4,a5,8000234c <scheduler+0x112>
    800022b0:	168a3703          	ld	a4,360(s4)
    800022b4:	1684b783          	ld	a5,360(s1)
    800022b8:	08e7fa63          	bgeu	a5,a4,8000234c <scheduler+0x112>
          release(&run_proc->lock);
    800022bc:	8552                	mv	a0,s4
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	b04080e7          	jalr	-1276(ra) # 80000dc2 <release>
    800022c6:	8a26                	mv	s4,s1
        maxi_priority = p->dyna_priority;
    800022c8:	8bce                	mv	s7,s3
    800022ca:	a031                	j	800022d6 <scheduler+0x9c>
      release(&p->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	af4080e7          	jalr	-1292(ra) # 80000dc2 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800022d6:	22048493          	addi	s1,s1,544
    800022da:	09648263          	beq	s1,s6,8000235e <scheduler+0x124>
    acquire(&p->lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	a2e080e7          	jalr	-1490(ra) # 80000d0e <acquire>
    if (p->state == RUNNABLE) {
    800022e8:	4c9c                	lw	a5,24(s1)
    800022ea:	ff5791e3          	bne	a5,s5,800022cc <scheduler+0x92>
      if (p->rtime + p->stime > 0) {
    800022ee:	1784b703          	ld	a4,376(s1)
    800022f2:	1804b603          	ld	a2,384(s1)
    800022f6:	00c706b3          	add	a3,a4,a2
    800022fa:	c285                	beqz	a3,8000231a <scheduler+0xe0>
        x = (int)(((3 * p->rtime - p->stime - p->watime) / (p->rtime + p->stime + p->watime + 1)) * 50);
    800022fc:	1884b783          	ld	a5,392(s1)
    80002300:	00171913          	slli	s2,a4,0x1
    80002304:	993a                	add	s2,s2,a4
    80002306:	40c90933          	sub	s2,s2,a2
    8000230a:	40f90933          	sub	s2,s2,a5
    8000230e:	0785                	addi	a5,a5,1
    80002310:	97b6                	add	a5,a5,a3
    80002312:	02f95933          	divu	s2,s2,a5
    80002316:	032c893b          	mulw	s2,s9,s2
      if (x > 0) {
    8000231a:	fff94793          	not	a5,s2
    8000231e:	97fd                	srai	a5,a5,0x3f
    80002320:	00f977b3          	and	a5,s2,a5
    80002324:	20f4aa23          	sw	a5,532(s1)
      p->dyna_priority = (p->stat_priority + p->rbi > 100 ? 100 : p->stat_priority + p->rbi);
    80002328:	20c4a703          	lw	a4,524(s1)
    8000232c:	9fb9                	addw	a5,a5,a4
    8000232e:	0007871b          	sext.w	a4,a5
    80002332:	00ec5363          	bge	s8,a4,80002338 <scheduler+0xfe>
    80002336:	87ea                	mv	a5,s10
    80002338:	0007899b          	sext.w	s3,a5
    8000233c:	20f4a823          	sw	a5,528(s1)
      if (run_proc == 0 || maxi_priority > p->dyna_priority ||
    80002340:	000a0c63          	beqz	s4,80002358 <scheduler+0x11e>
    80002344:	f779cce3          	blt	s3,s7,800022bc <scheduler+0x82>
    80002348:	f5798ce3          	beq	s3,s7,800022a0 <scheduler+0x66>
        release(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	a74080e7          	jalr	-1420(ra) # 80000dc2 <release>
    80002356:	b741                	j	800022d6 <scheduler+0x9c>
    80002358:	8a26                	mv	s4,s1
        maxi_priority = p->dyna_priority;
    8000235a:	8bce                	mv	s7,s3
    8000235c:	bfad                	j	800022d6 <scheduler+0x9c>
  if (run_proc != 0) {
    8000235e:	000a0763          	beqz	s4,8000236c <scheduler+0x132>
    if (run_proc->state == RUNNABLE) {
    80002362:	018a2703          	lw	a4,24(s4)
    80002366:	478d                	li	a5,3
    80002368:	02f70363          	beq	a4,a5,8000238e <scheduler+0x154>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000236c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002370:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002374:	10079073          	csrw	sstatus,a5
  struct proc *run_proc = 0;
    80002378:	8a6e                	mv	s4,s11
  int x = 0;
    8000237a:	896e                	mv	s2,s11
  for (p = proc; p < &proc[NPROC]; p++) {
    8000237c:	0022f497          	auipc	s1,0x22f
    80002380:	4e448493          	addi	s1,s1,1252 # 80231860 <proc>
  int maxi_priority = 0;
    80002384:	8bee                	mv	s7,s11
    if (p->state == RUNNABLE) {
    80002386:	4a8d                	li	s5,3
        x = (int)(((3 * p->rtime - p->stime - p->watime) / (p->rtime + p->stime + p->watime + 1)) * 50);
    80002388:	03200c93          	li	s9,50
    8000238c:	bf89                	j	800022de <scheduler+0xa4>
      run_proc->sched_times += 1;
    8000238e:	218a2783          	lw	a5,536(s4)
    80002392:	2785                	addiw	a5,a5,1
    80002394:	20fa2c23          	sw	a5,536(s4)
      run_proc->state = RUNNING;
    80002398:	4791                	li	a5,4
    8000239a:	00fa2c23          	sw	a5,24(s4)
      c->proc = run_proc;
    8000239e:	f8043483          	ld	s1,-128(s0)
    800023a2:	0344b823          	sd	s4,48(s1)
      swtch(&c->context, &run_proc->context);
    800023a6:	060a0593          	addi	a1,s4,96
    800023aa:	f8843503          	ld	a0,-120(s0)
    800023ae:	00001097          	auipc	ra,0x1
    800023b2:	964080e7          	jalr	-1692(ra) # 80002d12 <swtch>
      c->proc = 0;
    800023b6:	0204b823          	sd	zero,48(s1)
      release(&run_proc->lock);
    800023ba:	8552                	mv	a0,s4
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	a06080e7          	jalr	-1530(ra) # 80000dc2 <release>
    800023c4:	b765                	j	8000236c <scheduler+0x132>

00000000800023c6 <sched>:
{
    800023c6:	7179                	addi	sp,sp,-48
    800023c8:	f406                	sd	ra,40(sp)
    800023ca:	f022                	sd	s0,32(sp)
    800023cc:	ec26                	sd	s1,24(sp)
    800023ce:	e84a                	sd	s2,16(sp)
    800023d0:	e44e                	sd	s3,8(sp)
    800023d2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	916080e7          	jalr	-1770(ra) # 80001cea <myproc>
    800023dc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8b6080e7          	jalr	-1866(ra) # 80000c94 <holding>
    800023e6:	c93d                	beqz	a0,8000245c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023e8:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800023ea:	2781                	sext.w	a5,a5
    800023ec:	079e                	slli	a5,a5,0x7
    800023ee:	0022f717          	auipc	a4,0x22f
    800023f2:	84270713          	addi	a4,a4,-1982 # 80230c30 <pid_lock>
    800023f6:	97ba                	add	a5,a5,a4
    800023f8:	0a87a703          	lw	a4,168(a5)
    800023fc:	4785                	li	a5,1
    800023fe:	06f71763          	bne	a4,a5,8000246c <sched+0xa6>
  if (p->state == RUNNING)
    80002402:	4c98                	lw	a4,24(s1)
    80002404:	4791                	li	a5,4
    80002406:	06f70b63          	beq	a4,a5,8000247c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000240a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000240e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002410:	efb5                	bnez	a5,8000248c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002412:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002414:	0022f917          	auipc	s2,0x22f
    80002418:	81c90913          	addi	s2,s2,-2020 # 80230c30 <pid_lock>
    8000241c:	2781                	sext.w	a5,a5
    8000241e:	079e                	slli	a5,a5,0x7
    80002420:	97ca                	add	a5,a5,s2
    80002422:	0ac7a983          	lw	s3,172(a5)
    80002426:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002428:	2781                	sext.w	a5,a5
    8000242a:	079e                	slli	a5,a5,0x7
    8000242c:	0022f597          	auipc	a1,0x22f
    80002430:	83c58593          	addi	a1,a1,-1988 # 80230c68 <cpus+0x8>
    80002434:	95be                	add	a1,a1,a5
    80002436:	06048513          	addi	a0,s1,96
    8000243a:	00001097          	auipc	ra,0x1
    8000243e:	8d8080e7          	jalr	-1832(ra) # 80002d12 <swtch>
    80002442:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002444:	2781                	sext.w	a5,a5
    80002446:	079e                	slli	a5,a5,0x7
    80002448:	993e                	add	s2,s2,a5
    8000244a:	0b392623          	sw	s3,172(s2)
}
    8000244e:	70a2                	ld	ra,40(sp)
    80002450:	7402                	ld	s0,32(sp)
    80002452:	64e2                	ld	s1,24(sp)
    80002454:	6942                	ld	s2,16(sp)
    80002456:	69a2                	ld	s3,8(sp)
    80002458:	6145                	addi	sp,sp,48
    8000245a:	8082                	ret
    panic("sched p->lock");
    8000245c:	00006517          	auipc	a0,0x6
    80002460:	e3c50513          	addi	a0,a0,-452 # 80008298 <digits+0x258>
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	0dc080e7          	jalr	220(ra) # 80000540 <panic>
    panic("sched locks");
    8000246c:	00006517          	auipc	a0,0x6
    80002470:	e3c50513          	addi	a0,a0,-452 # 800082a8 <digits+0x268>
    80002474:	ffffe097          	auipc	ra,0xffffe
    80002478:	0cc080e7          	jalr	204(ra) # 80000540 <panic>
    panic("sched running");
    8000247c:	00006517          	auipc	a0,0x6
    80002480:	e3c50513          	addi	a0,a0,-452 # 800082b8 <digits+0x278>
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	0bc080e7          	jalr	188(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000248c:	00006517          	auipc	a0,0x6
    80002490:	e3c50513          	addi	a0,a0,-452 # 800082c8 <digits+0x288>
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	0ac080e7          	jalr	172(ra) # 80000540 <panic>

000000008000249c <yield>:
{
    8000249c:	1101                	addi	sp,sp,-32
    8000249e:	ec06                	sd	ra,24(sp)
    800024a0:	e822                	sd	s0,16(sp)
    800024a2:	e426                	sd	s1,8(sp)
    800024a4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	844080e7          	jalr	-1980(ra) # 80001cea <myproc>
    800024ae:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	85e080e7          	jalr	-1954(ra) # 80000d0e <acquire>
  p->state = RUNNABLE;
    800024b8:	478d                	li	a5,3
    800024ba:	cc9c                	sw	a5,24(s1)
  sched();
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	f0a080e7          	jalr	-246(ra) # 800023c6 <sched>
  release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	8fc080e7          	jalr	-1796(ra) # 80000dc2 <release>
}
    800024ce:	60e2                	ld	ra,24(sp)
    800024d0:	6442                	ld	s0,16(sp)
    800024d2:	64a2                	ld	s1,8(sp)
    800024d4:	6105                	addi	sp,sp,32
    800024d6:	8082                	ret

00000000800024d8 <set_priority>:
int set_priority(int pid , int priority){
    800024d8:	711d                	addi	sp,sp,-96
    800024da:	ec86                	sd	ra,88(sp)
    800024dc:	e8a2                	sd	s0,80(sp)
    800024de:	e4a6                	sd	s1,72(sp)
    800024e0:	e0ca                	sd	s2,64(sp)
    800024e2:	fc4e                	sd	s3,56(sp)
    800024e4:	f852                	sd	s4,48(sp)
    800024e6:	f456                	sd	s5,40(sp)
    800024e8:	f05a                	sd	s6,32(sp)
    800024ea:	ec5e                	sd	s7,24(sp)
    800024ec:	e862                	sd	s8,16(sp)
    800024ee:	e466                	sd	s9,8(sp)
    800024f0:	1080                	addi	s0,sp,96
    800024f2:	89aa                	mv	s3,a0
    800024f4:	892e                	mv	s2,a1
  for(struct proc *p=proc;p<&proc[NPROC];p++){
    800024f6:	0022f497          	auipc	s1,0x22f
    800024fa:	36a48493          	addi	s1,s1,874 # 80231860 <proc>
  int found=-1;
    800024fe:	5afd                	li	s5,-1
    80002500:	4bbd                	li	s7,15
      p->dyna_priority=(p->stat_priority+p->rbi>100?100:p->stat_priority+p->rbi);
    80002502:	06400b13          	li	s6,100
    80002506:	06400c93          	li	s9,100
        int x=(int)(((3*p->rtime-p->stime-p->watime)/(p->rtime+p->stime+p->watime+1))*50);
    8000250a:	03200c13          	li	s8,50
  for(struct proc *p=proc;p<&proc[NPROC];p++){
    8000250e:	00238a17          	auipc	s4,0x238
    80002512:	b52a0a13          	addi	s4,s4,-1198 # 8023a060 <tickslock>
    80002516:	a82d                	j	80002550 <set_priority+0x78>
      release(&p->lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	8a8080e7          	jalr	-1880(ra) # 80000dc2 <release>
}
    80002522:	8556                	mv	a0,s5
    80002524:	60e6                	ld	ra,88(sp)
    80002526:	6446                	ld	s0,80(sp)
    80002528:	64a6                	ld	s1,72(sp)
    8000252a:	6906                	ld	s2,64(sp)
    8000252c:	79e2                	ld	s3,56(sp)
    8000252e:	7a42                	ld	s4,48(sp)
    80002530:	7aa2                	ld	s5,40(sp)
    80002532:	7b02                	ld	s6,32(sp)
    80002534:	6be2                	ld	s7,24(sp)
    80002536:	6c42                	ld	s8,16(sp)
    80002538:	6ca2                	ld	s9,8(sp)
    8000253a:	6125                	addi	sp,sp,96
    8000253c:	8082                	ret
    release(&p->lock);
    8000253e:	8526                	mv	a0,s1
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	882080e7          	jalr	-1918(ra) # 80000dc2 <release>
  for(struct proc *p=proc;p<&proc[NPROC];p++){
    80002548:	22048493          	addi	s1,s1,544
    8000254c:	fd448be3          	beq	s1,s4,80002522 <set_priority+0x4a>
    acquire(&p->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	7bc080e7          	jalr	1980(ra) # 80000d0e <acquire>
    if(p->pid==pid){
    8000255a:	589c                	lw	a5,48(s1)
    8000255c:	ff3791e3          	bne	a5,s3,8000253e <set_priority+0x66>
      found=p->stat_priority;
    80002560:	20c4aa83          	lw	s5,524(s1)
      p->stat_priority=priority;
    80002564:	2124a623          	sw	s2,524(s1)
      if(p->rtime+p->stime==0){
    80002568:	1784b683          	ld	a3,376(s1)
    8000256c:	1804b583          	ld	a1,384(s1)
    80002570:	00b68633          	add	a2,a3,a1
    80002574:	87de                	mv	a5,s7
    80002576:	c60d                	beqz	a2,800025a0 <set_priority+0xc8>
        int x=(int)(((3*p->rtime-p->stime-p->watime)/(p->rtime+p->stime+p->watime+1))*50);
    80002578:	1884b703          	ld	a4,392(s1)
    8000257c:	00169793          	slli	a5,a3,0x1
    80002580:	97b6                	add	a5,a5,a3
    80002582:	8f8d                	sub	a5,a5,a1
    80002584:	8f99                	sub	a5,a5,a4
    80002586:	0705                	addi	a4,a4,1
    80002588:	9732                	add	a4,a4,a2
    8000258a:	02e7d7b3          	divu	a5,a5,a4
    8000258e:	02fc07bb          	mulw	a5,s8,a5
    80002592:	0007871b          	sext.w	a4,a5
    80002596:	fff74713          	not	a4,a4
    8000259a:	977d                	srai	a4,a4,0x3f
    8000259c:	8ff9                	and	a5,a5,a4
    8000259e:	2781                	sext.w	a5,a5
        p->rbi=15;
    800025a0:	20f4aa23          	sw	a5,532(s1)
        p->rtime=0;
    800025a4:	1604bc23          	sd	zero,376(s1)
        p->stime=0;
    800025a8:	1804b023          	sd	zero,384(s1)
      int old_dp=p->dyna_priority;
    800025ac:	2104a703          	lw	a4,528(s1)
      p->dyna_priority=(p->stat_priority+p->rbi>100?100:p->stat_priority+p->rbi);
    800025b0:	012787bb          	addw	a5,a5,s2
    800025b4:	0007869b          	sext.w	a3,a5
    800025b8:	00db5363          	bge	s6,a3,800025be <set_priority+0xe6>
    800025bc:	87e6                	mv	a5,s9
    800025be:	0007869b          	sext.w	a3,a5
    800025c2:	20f4a823          	sw	a5,528(s1)
      if(old_dp>p->dyna_priority){
    800025c6:	f4e6d9e3          	bge	a3,a4,80002518 <set_priority+0x40>
        release(&p->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	7f6080e7          	jalr	2038(ra) # 80000dc2 <release>
        yield();
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	ec8080e7          	jalr	-312(ra) # 8000249c <yield>
    800025dc:	b7b5                	j	80002548 <set_priority+0x70>

00000000800025de <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800025de:	7179                	addi	sp,sp,-48
    800025e0:	f406                	sd	ra,40(sp)
    800025e2:	f022                	sd	s0,32(sp)
    800025e4:	ec26                	sd	s1,24(sp)
    800025e6:	e84a                	sd	s2,16(sp)
    800025e8:	e44e                	sd	s3,8(sp)
    800025ea:	1800                	addi	s0,sp,48
    800025ec:	89aa                	mv	s3,a0
    800025ee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800025f0:	fffff097          	auipc	ra,0xfffff
    800025f4:	6fa080e7          	jalr	1786(ra) # 80001cea <myproc>
    800025f8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	714080e7          	jalr	1812(ra) # 80000d0e <acquire>
  release(lk);
    80002602:	854a                	mv	a0,s2
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	7be080e7          	jalr	1982(ra) # 80000dc2 <release>

  // Go to sleep.
  p->chan = chan;
    8000260c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002610:	4789                	li	a5,2
    80002612:	cc9c                	sw	a5,24(s1)

  sched();
    80002614:	00000097          	auipc	ra,0x0
    80002618:	db2080e7          	jalr	-590(ra) # 800023c6 <sched>

  // Tidy up.
  p->chan = 0;
    8000261c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	7a0080e7          	jalr	1952(ra) # 80000dc2 <release>
  acquire(lk);
    8000262a:	854a                	mv	a0,s2
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	6e2080e7          	jalr	1762(ra) # 80000d0e <acquire>
}
    80002634:	70a2                	ld	ra,40(sp)
    80002636:	7402                	ld	s0,32(sp)
    80002638:	64e2                	ld	s1,24(sp)
    8000263a:	6942                	ld	s2,16(sp)
    8000263c:	69a2                	ld	s3,8(sp)
    8000263e:	6145                	addi	sp,sp,48
    80002640:	8082                	ret

0000000080002642 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002642:	7139                	addi	sp,sp,-64
    80002644:	fc06                	sd	ra,56(sp)
    80002646:	f822                	sd	s0,48(sp)
    80002648:	f426                	sd	s1,40(sp)
    8000264a:	f04a                	sd	s2,32(sp)
    8000264c:	ec4e                	sd	s3,24(sp)
    8000264e:	e852                	sd	s4,16(sp)
    80002650:	e456                	sd	s5,8(sp)
    80002652:	0080                	addi	s0,sp,64
    80002654:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002656:	0022f497          	auipc	s1,0x22f
    8000265a:	20a48493          	addi	s1,s1,522 # 80231860 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000265e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002660:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002662:	00238917          	auipc	s2,0x238
    80002666:	9fe90913          	addi	s2,s2,-1538 # 8023a060 <tickslock>
    8000266a:	a811                	j	8000267e <wakeup+0x3c>
#ifdef MLFQ
    p->wmlfq=0;
    p->currticks=0;
#endif
      }
      release(&p->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	754080e7          	jalr	1876(ra) # 80000dc2 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002676:	22048493          	addi	s1,s1,544
    8000267a:	03248663          	beq	s1,s2,800026a6 <wakeup+0x64>
    if (p != myproc())
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	66c080e7          	jalr	1644(ra) # 80001cea <myproc>
    80002686:	fea488e3          	beq	s1,a0,80002676 <wakeup+0x34>
      acquire(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	682080e7          	jalr	1666(ra) # 80000d0e <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002694:	4c9c                	lw	a5,24(s1)
    80002696:	fd379be3          	bne	a5,s3,8000266c <wakeup+0x2a>
    8000269a:	709c                	ld	a5,32(s1)
    8000269c:	fd4798e3          	bne	a5,s4,8000266c <wakeup+0x2a>
        p->state = RUNNABLE;
    800026a0:	0154ac23          	sw	s5,24(s1)
    800026a4:	b7e1                	j	8000266c <wakeup+0x2a>
    }
  }
}
    800026a6:	70e2                	ld	ra,56(sp)
    800026a8:	7442                	ld	s0,48(sp)
    800026aa:	74a2                	ld	s1,40(sp)
    800026ac:	7902                	ld	s2,32(sp)
    800026ae:	69e2                	ld	s3,24(sp)
    800026b0:	6a42                	ld	s4,16(sp)
    800026b2:	6aa2                	ld	s5,8(sp)
    800026b4:	6121                	addi	sp,sp,64
    800026b6:	8082                	ret

00000000800026b8 <reparent>:
{
    800026b8:	7179                	addi	sp,sp,-48
    800026ba:	f406                	sd	ra,40(sp)
    800026bc:	f022                	sd	s0,32(sp)
    800026be:	ec26                	sd	s1,24(sp)
    800026c0:	e84a                	sd	s2,16(sp)
    800026c2:	e44e                	sd	s3,8(sp)
    800026c4:	e052                	sd	s4,0(sp)
    800026c6:	1800                	addi	s0,sp,48
    800026c8:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026ca:	0022f497          	auipc	s1,0x22f
    800026ce:	19648493          	addi	s1,s1,406 # 80231860 <proc>
      pp->parent = initproc;
    800026d2:	00006a17          	auipc	s4,0x6
    800026d6:	2e6a0a13          	addi	s4,s4,742 # 800089b8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026da:	00238997          	auipc	s3,0x238
    800026de:	98698993          	addi	s3,s3,-1658 # 8023a060 <tickslock>
    800026e2:	a029                	j	800026ec <reparent+0x34>
    800026e4:	22048493          	addi	s1,s1,544
    800026e8:	01348d63          	beq	s1,s3,80002702 <reparent+0x4a>
    if (pp->parent == p)
    800026ec:	7c9c                	ld	a5,56(s1)
    800026ee:	ff279be3          	bne	a5,s2,800026e4 <reparent+0x2c>
      pp->parent = initproc;
    800026f2:	000a3503          	ld	a0,0(s4)
    800026f6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	f4a080e7          	jalr	-182(ra) # 80002642 <wakeup>
    80002700:	b7d5                	j	800026e4 <reparent+0x2c>
}
    80002702:	70a2                	ld	ra,40(sp)
    80002704:	7402                	ld	s0,32(sp)
    80002706:	64e2                	ld	s1,24(sp)
    80002708:	6942                	ld	s2,16(sp)
    8000270a:	69a2                	ld	s3,8(sp)
    8000270c:	6a02                	ld	s4,0(sp)
    8000270e:	6145                	addi	sp,sp,48
    80002710:	8082                	ret

0000000080002712 <exit>:
{
    80002712:	7179                	addi	sp,sp,-48
    80002714:	f406                	sd	ra,40(sp)
    80002716:	f022                	sd	s0,32(sp)
    80002718:	ec26                	sd	s1,24(sp)
    8000271a:	e84a                	sd	s2,16(sp)
    8000271c:	e44e                	sd	s3,8(sp)
    8000271e:	e052                	sd	s4,0(sp)
    80002720:	1800                	addi	s0,sp,48
    80002722:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	5c6080e7          	jalr	1478(ra) # 80001cea <myproc>
    8000272c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000272e:	00006797          	auipc	a5,0x6
    80002732:	28a7b783          	ld	a5,650(a5) # 800089b8 <initproc>
    80002736:	0d050493          	addi	s1,a0,208
    8000273a:	15050913          	addi	s2,a0,336
    8000273e:	02a79363          	bne	a5,a0,80002764 <exit+0x52>
    panic("init exiting");
    80002742:	00006517          	auipc	a0,0x6
    80002746:	b9e50513          	addi	a0,a0,-1122 # 800082e0 <digits+0x2a0>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	df6080e7          	jalr	-522(ra) # 80000540 <panic>
      fileclose(f);
    80002752:	00003097          	auipc	ra,0x3
    80002756:	816080e7          	jalr	-2026(ra) # 80004f68 <fileclose>
      p->ofile[fd] = 0;
    8000275a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000275e:	04a1                	addi	s1,s1,8
    80002760:	01248563          	beq	s1,s2,8000276a <exit+0x58>
    if (p->ofile[fd])
    80002764:	6088                	ld	a0,0(s1)
    80002766:	f575                	bnez	a0,80002752 <exit+0x40>
    80002768:	bfdd                	j	8000275e <exit+0x4c>
  begin_op();
    8000276a:	00002097          	auipc	ra,0x2
    8000276e:	336080e7          	jalr	822(ra) # 80004aa0 <begin_op>
  iput(p->cwd);
    80002772:	1509b503          	ld	a0,336(s3)
    80002776:	00002097          	auipc	ra,0x2
    8000277a:	b18080e7          	jalr	-1256(ra) # 8000428e <iput>
  end_op();
    8000277e:	00002097          	auipc	ra,0x2
    80002782:	3a0080e7          	jalr	928(ra) # 80004b1e <end_op>
  p->cwd = 0;
    80002786:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000278a:	0022e497          	auipc	s1,0x22e
    8000278e:	4be48493          	addi	s1,s1,1214 # 80230c48 <wait_lock>
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	57a080e7          	jalr	1402(ra) # 80000d0e <acquire>
  reparent(p);
    8000279c:	854e                	mv	a0,s3
    8000279e:	00000097          	auipc	ra,0x0
    800027a2:	f1a080e7          	jalr	-230(ra) # 800026b8 <reparent>
  wakeup(p->parent);
    800027a6:	0389b503          	ld	a0,56(s3)
    800027aa:	00000097          	auipc	ra,0x0
    800027ae:	e98080e7          	jalr	-360(ra) # 80002642 <wakeup>
  acquire(&p->lock);
    800027b2:	854e                	mv	a0,s3
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	55a080e7          	jalr	1370(ra) # 80000d0e <acquire>
  p->xstate = status;
    800027bc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027c0:	4795                	li	a5,5
    800027c2:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800027c6:	00006797          	auipc	a5,0x6
    800027ca:	1fa7e783          	lwu	a5,506(a5) # 800089c0 <ticks>
    800027ce:	18f9b823          	sd	a5,400(s3)
  release(&wait_lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	5ee080e7          	jalr	1518(ra) # 80000dc2 <release>
  sched();
    800027dc:	00000097          	auipc	ra,0x0
    800027e0:	bea080e7          	jalr	-1046(ra) # 800023c6 <sched>
  panic("zombie exit");
    800027e4:	00006517          	auipc	a0,0x6
    800027e8:	b0c50513          	addi	a0,a0,-1268 # 800082f0 <digits+0x2b0>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	d54080e7          	jalr	-684(ra) # 80000540 <panic>

00000000800027f4 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800027f4:	7179                	addi	sp,sp,-48
    800027f6:	f406                	sd	ra,40(sp)
    800027f8:	f022                	sd	s0,32(sp)
    800027fa:	ec26                	sd	s1,24(sp)
    800027fc:	e84a                	sd	s2,16(sp)
    800027fe:	e44e                	sd	s3,8(sp)
    80002800:	1800                	addi	s0,sp,48
    80002802:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002804:	0022f497          	auipc	s1,0x22f
    80002808:	05c48493          	addi	s1,s1,92 # 80231860 <proc>
    8000280c:	00238997          	auipc	s3,0x238
    80002810:	85498993          	addi	s3,s3,-1964 # 8023a060 <tickslock>
  {
    acquire(&p->lock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	4f8080e7          	jalr	1272(ra) # 80000d0e <acquire>
    if (p->pid == pid)
    8000281e:	589c                	lw	a5,48(s1)
    80002820:	01278d63          	beq	a5,s2,8000283a <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002824:	8526                	mv	a0,s1
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	59c080e7          	jalr	1436(ra) # 80000dc2 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000282e:	22048493          	addi	s1,s1,544
    80002832:	ff3491e3          	bne	s1,s3,80002814 <kill+0x20>
  }
  return -1;
    80002836:	557d                	li	a0,-1
    80002838:	a829                	j	80002852 <kill+0x5e>
      p->killed = 1;
    8000283a:	4785                	li	a5,1
    8000283c:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000283e:	4c98                	lw	a4,24(s1)
    80002840:	4789                	li	a5,2
    80002842:	00f70f63          	beq	a4,a5,80002860 <kill+0x6c>
      release(&p->lock);
    80002846:	8526                	mv	a0,s1
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	57a080e7          	jalr	1402(ra) # 80000dc2 <release>
      return 0;
    80002850:	4501                	li	a0,0
}
    80002852:	70a2                	ld	ra,40(sp)
    80002854:	7402                	ld	s0,32(sp)
    80002856:	64e2                	ld	s1,24(sp)
    80002858:	6942                	ld	s2,16(sp)
    8000285a:	69a2                	ld	s3,8(sp)
    8000285c:	6145                	addi	sp,sp,48
    8000285e:	8082                	ret
        p->state = RUNNABLE;
    80002860:	478d                	li	a5,3
    80002862:	cc9c                	sw	a5,24(s1)
    80002864:	b7cd                	j	80002846 <kill+0x52>

0000000080002866 <setkilled>:

void setkilled(struct proc *p)
{
    80002866:	1101                	addi	sp,sp,-32
    80002868:	ec06                	sd	ra,24(sp)
    8000286a:	e822                	sd	s0,16(sp)
    8000286c:	e426                	sd	s1,8(sp)
    8000286e:	1000                	addi	s0,sp,32
    80002870:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	49c080e7          	jalr	1180(ra) # 80000d0e <acquire>
  p->killed = 1;
    8000287a:	4785                	li	a5,1
    8000287c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000287e:	8526                	mv	a0,s1
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	542080e7          	jalr	1346(ra) # 80000dc2 <release>
}
    80002888:	60e2                	ld	ra,24(sp)
    8000288a:	6442                	ld	s0,16(sp)
    8000288c:	64a2                	ld	s1,8(sp)
    8000288e:	6105                	addi	sp,sp,32
    80002890:	8082                	ret

0000000080002892 <killed>:

int killed(struct proc *p)
{
    80002892:	1101                	addi	sp,sp,-32
    80002894:	ec06                	sd	ra,24(sp)
    80002896:	e822                	sd	s0,16(sp)
    80002898:	e426                	sd	s1,8(sp)
    8000289a:	e04a                	sd	s2,0(sp)
    8000289c:	1000                	addi	s0,sp,32
    8000289e:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	46e080e7          	jalr	1134(ra) # 80000d0e <acquire>
  k = p->killed;
    800028a8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800028ac:	8526                	mv	a0,s1
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	514080e7          	jalr	1300(ra) # 80000dc2 <release>
  return k;
}
    800028b6:	854a                	mv	a0,s2
    800028b8:	60e2                	ld	ra,24(sp)
    800028ba:	6442                	ld	s0,16(sp)
    800028bc:	64a2                	ld	s1,8(sp)
    800028be:	6902                	ld	s2,0(sp)
    800028c0:	6105                	addi	sp,sp,32
    800028c2:	8082                	ret

00000000800028c4 <wait>:
{
    800028c4:	715d                	addi	sp,sp,-80
    800028c6:	e486                	sd	ra,72(sp)
    800028c8:	e0a2                	sd	s0,64(sp)
    800028ca:	fc26                	sd	s1,56(sp)
    800028cc:	f84a                	sd	s2,48(sp)
    800028ce:	f44e                	sd	s3,40(sp)
    800028d0:	f052                	sd	s4,32(sp)
    800028d2:	ec56                	sd	s5,24(sp)
    800028d4:	e85a                	sd	s6,16(sp)
    800028d6:	e45e                	sd	s7,8(sp)
    800028d8:	e062                	sd	s8,0(sp)
    800028da:	0880                	addi	s0,sp,80
    800028dc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	40c080e7          	jalr	1036(ra) # 80001cea <myproc>
    800028e6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028e8:	0022e517          	auipc	a0,0x22e
    800028ec:	36050513          	addi	a0,a0,864 # 80230c48 <wait_lock>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	41e080e7          	jalr	1054(ra) # 80000d0e <acquire>
    havekids = 0;
    800028f8:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800028fa:	4a15                	li	s4,5
        havekids = 1;
    800028fc:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028fe:	00237997          	auipc	s3,0x237
    80002902:	76298993          	addi	s3,s3,1890 # 8023a060 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002906:	0022ec17          	auipc	s8,0x22e
    8000290a:	342c0c13          	addi	s8,s8,834 # 80230c48 <wait_lock>
    havekids = 0;
    8000290e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002910:	0022f497          	auipc	s1,0x22f
    80002914:	f5048493          	addi	s1,s1,-176 # 80231860 <proc>
    80002918:	a0bd                	j	80002986 <wait+0xc2>
          pid = pp->pid;
    8000291a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000291e:	000b0e63          	beqz	s6,8000293a <wait+0x76>
    80002922:	4691                	li	a3,4
    80002924:	02c48613          	addi	a2,s1,44
    80002928:	85da                	mv	a1,s6
    8000292a:	05093503          	ld	a0,80(s2)
    8000292e:	fffff097          	auipc	ra,0xfffff
    80002932:	e5c080e7          	jalr	-420(ra) # 8000178a <copyout>
    80002936:	02054563          	bltz	a0,80002960 <wait+0x9c>
          freeproc(pp);
    8000293a:	8526                	mv	a0,s1
    8000293c:	fffff097          	auipc	ra,0xfffff
    80002940:	560080e7          	jalr	1376(ra) # 80001e9c <freeproc>
          release(&pp->lock);
    80002944:	8526                	mv	a0,s1
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	47c080e7          	jalr	1148(ra) # 80000dc2 <release>
          release(&wait_lock);
    8000294e:	0022e517          	auipc	a0,0x22e
    80002952:	2fa50513          	addi	a0,a0,762 # 80230c48 <wait_lock>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	46c080e7          	jalr	1132(ra) # 80000dc2 <release>
          return pid;
    8000295e:	a0b5                	j	800029ca <wait+0x106>
            release(&pp->lock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	460080e7          	jalr	1120(ra) # 80000dc2 <release>
            release(&wait_lock);
    8000296a:	0022e517          	auipc	a0,0x22e
    8000296e:	2de50513          	addi	a0,a0,734 # 80230c48 <wait_lock>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	450080e7          	jalr	1104(ra) # 80000dc2 <release>
            return -1;
    8000297a:	59fd                	li	s3,-1
    8000297c:	a0b9                	j	800029ca <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000297e:	22048493          	addi	s1,s1,544
    80002982:	03348463          	beq	s1,s3,800029aa <wait+0xe6>
      if (pp->parent == p)
    80002986:	7c9c                	ld	a5,56(s1)
    80002988:	ff279be3          	bne	a5,s2,8000297e <wait+0xba>
        acquire(&pp->lock);
    8000298c:	8526                	mv	a0,s1
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	380080e7          	jalr	896(ra) # 80000d0e <acquire>
        if (pp->state == ZOMBIE)
    80002996:	4c9c                	lw	a5,24(s1)
    80002998:	f94781e3          	beq	a5,s4,8000291a <wait+0x56>
        release(&pp->lock);
    8000299c:	8526                	mv	a0,s1
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	424080e7          	jalr	1060(ra) # 80000dc2 <release>
        havekids = 1;
    800029a6:	8756                	mv	a4,s5
    800029a8:	bfd9                	j	8000297e <wait+0xba>
    if (!havekids || killed(p))
    800029aa:	c719                	beqz	a4,800029b8 <wait+0xf4>
    800029ac:	854a                	mv	a0,s2
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	ee4080e7          	jalr	-284(ra) # 80002892 <killed>
    800029b6:	c51d                	beqz	a0,800029e4 <wait+0x120>
      release(&wait_lock);
    800029b8:	0022e517          	auipc	a0,0x22e
    800029bc:	29050513          	addi	a0,a0,656 # 80230c48 <wait_lock>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	402080e7          	jalr	1026(ra) # 80000dc2 <release>
      return -1;
    800029c8:	59fd                	li	s3,-1
}
    800029ca:	854e                	mv	a0,s3
    800029cc:	60a6                	ld	ra,72(sp)
    800029ce:	6406                	ld	s0,64(sp)
    800029d0:	74e2                	ld	s1,56(sp)
    800029d2:	7942                	ld	s2,48(sp)
    800029d4:	79a2                	ld	s3,40(sp)
    800029d6:	7a02                	ld	s4,32(sp)
    800029d8:	6ae2                	ld	s5,24(sp)
    800029da:	6b42                	ld	s6,16(sp)
    800029dc:	6ba2                	ld	s7,8(sp)
    800029de:	6c02                	ld	s8,0(sp)
    800029e0:	6161                	addi	sp,sp,80
    800029e2:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029e4:	85e2                	mv	a1,s8
    800029e6:	854a                	mv	a0,s2
    800029e8:	00000097          	auipc	ra,0x0
    800029ec:	bf6080e7          	jalr	-1034(ra) # 800025de <sleep>
    havekids = 0;
    800029f0:	bf39                	j	8000290e <wait+0x4a>

00000000800029f2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029f2:	7179                	addi	sp,sp,-48
    800029f4:	f406                	sd	ra,40(sp)
    800029f6:	f022                	sd	s0,32(sp)
    800029f8:	ec26                	sd	s1,24(sp)
    800029fa:	e84a                	sd	s2,16(sp)
    800029fc:	e44e                	sd	s3,8(sp)
    800029fe:	e052                	sd	s4,0(sp)
    80002a00:	1800                	addi	s0,sp,48
    80002a02:	84aa                	mv	s1,a0
    80002a04:	892e                	mv	s2,a1
    80002a06:	89b2                	mv	s3,a2
    80002a08:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	2e0080e7          	jalr	736(ra) # 80001cea <myproc>
  if (user_dst)
    80002a12:	c08d                	beqz	s1,80002a34 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002a14:	86d2                	mv	a3,s4
    80002a16:	864e                	mv	a2,s3
    80002a18:	85ca                	mv	a1,s2
    80002a1a:	6928                	ld	a0,80(a0)
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	d6e080e7          	jalr	-658(ra) # 8000178a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a24:	70a2                	ld	ra,40(sp)
    80002a26:	7402                	ld	s0,32(sp)
    80002a28:	64e2                	ld	s1,24(sp)
    80002a2a:	6942                	ld	s2,16(sp)
    80002a2c:	69a2                	ld	s3,8(sp)
    80002a2e:	6a02                	ld	s4,0(sp)
    80002a30:	6145                	addi	sp,sp,48
    80002a32:	8082                	ret
    memmove((char *)dst, src, len);
    80002a34:	000a061b          	sext.w	a2,s4
    80002a38:	85ce                	mv	a1,s3
    80002a3a:	854a                	mv	a0,s2
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	42a080e7          	jalr	1066(ra) # 80000e66 <memmove>
    return 0;
    80002a44:	8526                	mv	a0,s1
    80002a46:	bff9                	j	80002a24 <either_copyout+0x32>

0000000080002a48 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a48:	7179                	addi	sp,sp,-48
    80002a4a:	f406                	sd	ra,40(sp)
    80002a4c:	f022                	sd	s0,32(sp)
    80002a4e:	ec26                	sd	s1,24(sp)
    80002a50:	e84a                	sd	s2,16(sp)
    80002a52:	e44e                	sd	s3,8(sp)
    80002a54:	e052                	sd	s4,0(sp)
    80002a56:	1800                	addi	s0,sp,48
    80002a58:	892a                	mv	s2,a0
    80002a5a:	84ae                	mv	s1,a1
    80002a5c:	89b2                	mv	s3,a2
    80002a5e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	28a080e7          	jalr	650(ra) # 80001cea <myproc>
  if (user_src)
    80002a68:	c08d                	beqz	s1,80002a8a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a6a:	86d2                	mv	a3,s4
    80002a6c:	864e                	mv	a2,s3
    80002a6e:	85ca                	mv	a1,s2
    80002a70:	6928                	ld	a0,80(a0)
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	dd2080e7          	jalr	-558(ra) # 80001844 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a7a:	70a2                	ld	ra,40(sp)
    80002a7c:	7402                	ld	s0,32(sp)
    80002a7e:	64e2                	ld	s1,24(sp)
    80002a80:	6942                	ld	s2,16(sp)
    80002a82:	69a2                	ld	s3,8(sp)
    80002a84:	6a02                	ld	s4,0(sp)
    80002a86:	6145                	addi	sp,sp,48
    80002a88:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a8a:	000a061b          	sext.w	a2,s4
    80002a8e:	85ce                	mv	a1,s3
    80002a90:	854a                	mv	a0,s2
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	3d4080e7          	jalr	980(ra) # 80000e66 <memmove>
    return 0;
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	bff9                	j	80002a7a <either_copyin+0x32>

0000000080002a9e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a9e:	715d                	addi	sp,sp,-80
    80002aa0:	e486                	sd	ra,72(sp)
    80002aa2:	e0a2                	sd	s0,64(sp)
    80002aa4:	fc26                	sd	s1,56(sp)
    80002aa6:	f84a                	sd	s2,48(sp)
    80002aa8:	f44e                	sd	s3,40(sp)
    80002aaa:	f052                	sd	s4,32(sp)
    80002aac:	ec56                	sd	s5,24(sp)
    80002aae:	e85a                	sd	s6,16(sp)
    80002ab0:	e45e                	sd	s7,8(sp)
    80002ab2:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002ab4:	00005517          	auipc	a0,0x5
    80002ab8:	66450513          	addi	a0,a0,1636 # 80008118 <digits+0xd8>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	ace080e7          	jalr	-1330(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac4:	0022f497          	auipc	s1,0x22f
    80002ac8:	ef448493          	addi	s1,s1,-268 # 802319b8 <proc+0x158>
    80002acc:	00237917          	auipc	s2,0x237
    80002ad0:	6ec90913          	addi	s2,s2,1772 # 8023a1b8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ad4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002ad6:	00006997          	auipc	s3,0x6
    80002ada:	82a98993          	addi	s3,s3,-2006 # 80008300 <digits+0x2c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002ade:	00006a97          	auipc	s5,0x6
    80002ae2:	82aa8a93          	addi	s5,s5,-2006 # 80008308 <digits+0x2c8>
    printf("\n");
    80002ae6:	00005a17          	auipc	s4,0x5
    80002aea:	632a0a13          	addi	s4,s4,1586 # 80008118 <digits+0xd8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aee:	00006b97          	auipc	s7,0x6
    80002af2:	87ab8b93          	addi	s7,s7,-1926 # 80008368 <states.0>
    80002af6:	a00d                	j	80002b18 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002af8:	ed86a583          	lw	a1,-296(a3)
    80002afc:	8556                	mv	a0,s5
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a8c080e7          	jalr	-1396(ra) # 8000058a <printf>
    printf("\n");
    80002b06:	8552                	mv	a0,s4
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a82080e7          	jalr	-1406(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b10:	22048493          	addi	s1,s1,544
    80002b14:	03248263          	beq	s1,s2,80002b38 <procdump+0x9a>
    if (p->state == UNUSED)
    80002b18:	86a6                	mv	a3,s1
    80002b1a:	ec04a783          	lw	a5,-320(s1)
    80002b1e:	dbed                	beqz	a5,80002b10 <procdump+0x72>
      state = "???";
    80002b20:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b22:	fcfb6be3          	bltu	s6,a5,80002af8 <procdump+0x5a>
    80002b26:	02079713          	slli	a4,a5,0x20
    80002b2a:	01d75793          	srli	a5,a4,0x1d
    80002b2e:	97de                	add	a5,a5,s7
    80002b30:	6390                	ld	a2,0(a5)
    80002b32:	f279                	bnez	a2,80002af8 <procdump+0x5a>
      state = "???";
    80002b34:	864e                	mv	a2,s3
    80002b36:	b7c9                	j	80002af8 <procdump+0x5a>
  }
}
    80002b38:	60a6                	ld	ra,72(sp)
    80002b3a:	6406                	ld	s0,64(sp)
    80002b3c:	74e2                	ld	s1,56(sp)
    80002b3e:	7942                	ld	s2,48(sp)
    80002b40:	79a2                	ld	s3,40(sp)
    80002b42:	7a02                	ld	s4,32(sp)
    80002b44:	6ae2                	ld	s5,24(sp)
    80002b46:	6b42                	ld	s6,16(sp)
    80002b48:	6ba2                	ld	s7,8(sp)
    80002b4a:	6161                	addi	sp,sp,80
    80002b4c:	8082                	ret

0000000080002b4e <waitx>:
// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002b4e:	711d                	addi	sp,sp,-96
    80002b50:	ec86                	sd	ra,88(sp)
    80002b52:	e8a2                	sd	s0,80(sp)
    80002b54:	e4a6                	sd	s1,72(sp)
    80002b56:	e0ca                	sd	s2,64(sp)
    80002b58:	fc4e                	sd	s3,56(sp)
    80002b5a:	f852                	sd	s4,48(sp)
    80002b5c:	f456                	sd	s5,40(sp)
    80002b5e:	f05a                	sd	s6,32(sp)
    80002b60:	ec5e                	sd	s7,24(sp)
    80002b62:	e862                	sd	s8,16(sp)
    80002b64:	e466                	sd	s9,8(sp)
    80002b66:	e06a                	sd	s10,0(sp)
    80002b68:	1080                	addi	s0,sp,96
    80002b6a:	8b2a                	mv	s6,a0
    80002b6c:	8bae                	mv	s7,a1
    80002b6e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002b70:	fffff097          	auipc	ra,0xfffff
    80002b74:	17a080e7          	jalr	378(ra) # 80001cea <myproc>
    80002b78:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002b7a:	0022e517          	auipc	a0,0x22e
    80002b7e:	0ce50513          	addi	a0,a0,206 # 80230c48 <wait_lock>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	18c080e7          	jalr	396(ra) # 80000d0e <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002b8a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002b8c:	4a15                	li	s4,5
        havekids = 1;
    80002b8e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002b90:	00237997          	auipc	s3,0x237
    80002b94:	4d098993          	addi	s3,s3,1232 # 8023a060 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b98:	0022ed17          	auipc	s10,0x22e
    80002b9c:	0b0d0d13          	addi	s10,s10,176 # 80230c48 <wait_lock>
    havekids = 0;
    80002ba0:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002ba2:	0022f497          	auipc	s1,0x22f
    80002ba6:	cbe48493          	addi	s1,s1,-834 # 80231860 <proc>
    80002baa:	a069                	j	80002c34 <waitx+0xe6>
          pid = np->pid;
    80002bac:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002bb0:	1784b783          	ld	a5,376(s1)
    80002bb4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->clktik - np->rtime;
    80002bb8:	1904b783          	ld	a5,400(s1)
    80002bbc:	1684b703          	ld	a4,360(s1)
    80002bc0:	1784b683          	ld	a3,376(s1)
    80002bc4:	9f35                	addw	a4,a4,a3
    80002bc6:	9f99                	subw	a5,a5,a4
    80002bc8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002bcc:	000b0e63          	beqz	s6,80002be8 <waitx+0x9a>
    80002bd0:	4691                	li	a3,4
    80002bd2:	02c48613          	addi	a2,s1,44
    80002bd6:	85da                	mv	a1,s6
    80002bd8:	05093503          	ld	a0,80(s2)
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	bae080e7          	jalr	-1106(ra) # 8000178a <copyout>
    80002be4:	02054563          	bltz	a0,80002c0e <waitx+0xc0>
          freeproc(np);
    80002be8:	8526                	mv	a0,s1
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	2b2080e7          	jalr	690(ra) # 80001e9c <freeproc>
          release(&np->lock);
    80002bf2:	8526                	mv	a0,s1
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	1ce080e7          	jalr	462(ra) # 80000dc2 <release>
          release(&wait_lock);
    80002bfc:	0022e517          	auipc	a0,0x22e
    80002c00:	04c50513          	addi	a0,a0,76 # 80230c48 <wait_lock>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	1be080e7          	jalr	446(ra) # 80000dc2 <release>
          return pid;
    80002c0c:	a09d                	j	80002c72 <waitx+0x124>
            release(&np->lock);
    80002c0e:	8526                	mv	a0,s1
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	1b2080e7          	jalr	434(ra) # 80000dc2 <release>
            release(&wait_lock);
    80002c18:	0022e517          	auipc	a0,0x22e
    80002c1c:	03050513          	addi	a0,a0,48 # 80230c48 <wait_lock>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	1a2080e7          	jalr	418(ra) # 80000dc2 <release>
            return -1;
    80002c28:	59fd                	li	s3,-1
    80002c2a:	a0a1                	j	80002c72 <waitx+0x124>
    for (np = proc; np < &proc[NPROC]; np++)
    80002c2c:	22048493          	addi	s1,s1,544
    80002c30:	03348463          	beq	s1,s3,80002c58 <waitx+0x10a>
      if (np->parent == p)
    80002c34:	7c9c                	ld	a5,56(s1)
    80002c36:	ff279be3          	bne	a5,s2,80002c2c <waitx+0xde>
        acquire(&np->lock);
    80002c3a:	8526                	mv	a0,s1
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	0d2080e7          	jalr	210(ra) # 80000d0e <acquire>
        if (np->state == ZOMBIE)
    80002c44:	4c9c                	lw	a5,24(s1)
    80002c46:	f74783e3          	beq	a5,s4,80002bac <waitx+0x5e>
        release(&np->lock);
    80002c4a:	8526                	mv	a0,s1
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	176080e7          	jalr	374(ra) # 80000dc2 <release>
        havekids = 1;
    80002c54:	8756                	mv	a4,s5
    80002c56:	bfd9                	j	80002c2c <waitx+0xde>
    if (!havekids || p->killed)
    80002c58:	c701                	beqz	a4,80002c60 <waitx+0x112>
    80002c5a:	02892783          	lw	a5,40(s2)
    80002c5e:	cb8d                	beqz	a5,80002c90 <waitx+0x142>
      release(&wait_lock);
    80002c60:	0022e517          	auipc	a0,0x22e
    80002c64:	fe850513          	addi	a0,a0,-24 # 80230c48 <wait_lock>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	15a080e7          	jalr	346(ra) # 80000dc2 <release>
      return -1;
    80002c70:	59fd                	li	s3,-1
  }
}
    80002c72:	854e                	mv	a0,s3
    80002c74:	60e6                	ld	ra,88(sp)
    80002c76:	6446                	ld	s0,80(sp)
    80002c78:	64a6                	ld	s1,72(sp)
    80002c7a:	6906                	ld	s2,64(sp)
    80002c7c:	79e2                	ld	s3,56(sp)
    80002c7e:	7a42                	ld	s4,48(sp)
    80002c80:	7aa2                	ld	s5,40(sp)
    80002c82:	7b02                	ld	s6,32(sp)
    80002c84:	6be2                	ld	s7,24(sp)
    80002c86:	6c42                	ld	s8,16(sp)
    80002c88:	6ca2                	ld	s9,8(sp)
    80002c8a:	6d02                	ld	s10,0(sp)
    80002c8c:	6125                	addi	sp,sp,96
    80002c8e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002c90:	85ea                	mv	a1,s10
    80002c92:	854a                	mv	a0,s2
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	94a080e7          	jalr	-1718(ra) # 800025de <sleep>
    havekids = 0;
    80002c9c:	b711                	j	80002ba0 <waitx+0x52>

0000000080002c9e <getps>:
int
getps(void) 
{
    80002c9e:	7179                	addi	sp,sp,-48
    80002ca0:	f406                	sd	ra,40(sp)
    80002ca2:	f022                	sd	s0,32(sp)
    80002ca4:	ec26                	sd	s1,24(sp)
    80002ca6:	e84a                	sd	s2,16(sp)
    80002ca8:	e44e                	sd	s3,8(sp)
    80002caa:	1800                	addi	s0,sp,48
    struct proc *p;
    int ret = -1;
    printf("Name\ts_time\n");
    80002cac:	00005517          	auipc	a0,0x5
    80002cb0:	66c50513          	addi	a0,a0,1644 # 80008318 <digits+0x2d8>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	8d6080e7          	jalr	-1834(ra) # 8000058a <printf>
    for (p = proc; p < &proc[3]; p++)
    80002cbc:	0022f497          	auipc	s1,0x22f
    80002cc0:	ba448493          	addi	s1,s1,-1116 # 80231860 <proc>
    {
      acquire(&p->lock);
      printf("%s \t %d\n", p->name,p->wtime);
    80002cc4:	00005997          	auipc	s3,0x5
    80002cc8:	66498993          	addi	s3,s3,1636 # 80008328 <digits+0x2e8>
    for (p = proc; p < &proc[3]; p++)
    80002ccc:	0022f917          	auipc	s2,0x22f
    80002cd0:	1f490913          	addi	s2,s2,500 # 80231ec0 <proc+0x660>
      acquire(&p->lock);
    80002cd4:	8526                	mv	a0,s1
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	038080e7          	jalr	56(ra) # 80000d0e <acquire>
      printf("%s \t %d\n", p->name,p->wtime);
    80002cde:	1704b603          	ld	a2,368(s1)
    80002ce2:	15848593          	addi	a1,s1,344
    80002ce6:	854e                	mv	a0,s3
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	8a2080e7          	jalr	-1886(ra) # 8000058a <printf>
      release(&p->lock);
    80002cf0:	8526                	mv	a0,s1
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	0d0080e7          	jalr	208(ra) # 80000dc2 <release>
    for (p = proc; p < &proc[3]; p++)
    80002cfa:	22048493          	addi	s1,s1,544
    80002cfe:	fd249be3          	bne	s1,s2,80002cd4 <getps+0x36>
   }
    return ret;
}
    80002d02:	557d                	li	a0,-1
    80002d04:	70a2                	ld	ra,40(sp)
    80002d06:	7402                	ld	s0,32(sp)
    80002d08:	64e2                	ld	s1,24(sp)
    80002d0a:	6942                	ld	s2,16(sp)
    80002d0c:	69a2                	ld	s3,8(sp)
    80002d0e:	6145                	addi	sp,sp,48
    80002d10:	8082                	ret

0000000080002d12 <swtch>:
    80002d12:	00153023          	sd	ra,0(a0)
    80002d16:	00253423          	sd	sp,8(a0)
    80002d1a:	e900                	sd	s0,16(a0)
    80002d1c:	ed04                	sd	s1,24(a0)
    80002d1e:	03253023          	sd	s2,32(a0)
    80002d22:	03353423          	sd	s3,40(a0)
    80002d26:	03453823          	sd	s4,48(a0)
    80002d2a:	03553c23          	sd	s5,56(a0)
    80002d2e:	05653023          	sd	s6,64(a0)
    80002d32:	05753423          	sd	s7,72(a0)
    80002d36:	05853823          	sd	s8,80(a0)
    80002d3a:	05953c23          	sd	s9,88(a0)
    80002d3e:	07a53023          	sd	s10,96(a0)
    80002d42:	07b53423          	sd	s11,104(a0)
    80002d46:	0005b083          	ld	ra,0(a1)
    80002d4a:	0085b103          	ld	sp,8(a1)
    80002d4e:	6980                	ld	s0,16(a1)
    80002d50:	6d84                	ld	s1,24(a1)
    80002d52:	0205b903          	ld	s2,32(a1)
    80002d56:	0285b983          	ld	s3,40(a1)
    80002d5a:	0305ba03          	ld	s4,48(a1)
    80002d5e:	0385ba83          	ld	s5,56(a1)
    80002d62:	0405bb03          	ld	s6,64(a1)
    80002d66:	0485bb83          	ld	s7,72(a1)
    80002d6a:	0505bc03          	ld	s8,80(a1)
    80002d6e:	0585bc83          	ld	s9,88(a1)
    80002d72:	0605bd03          	ld	s10,96(a1)
    80002d76:	0685bd83          	ld	s11,104(a1)
    80002d7a:	8082                	ret

0000000080002d7c <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002d7c:	1141                	addi	sp,sp,-16
    80002d7e:	e406                	sd	ra,8(sp)
    80002d80:	e022                	sd	s0,0(sp)
    80002d82:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d84:	00005597          	auipc	a1,0x5
    80002d88:	61458593          	addi	a1,a1,1556 # 80008398 <states.0+0x30>
    80002d8c:	00237517          	auipc	a0,0x237
    80002d90:	2d450513          	addi	a0,a0,724 # 8023a060 <tickslock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	eea080e7          	jalr	-278(ra) # 80000c7e <initlock>
}
    80002d9c:	60a2                	ld	ra,8(sp)
    80002d9e:	6402                	ld	s0,0(sp)
    80002da0:	0141                	addi	sp,sp,16
    80002da2:	8082                	ret

0000000080002da4 <copyOnWrite>:

int copyOnWrite(pagetable_t pt,uint64 va){
  if(va>=MAXVA || !va)
    80002da4:	fff58713          	addi	a4,a1,-1
    80002da8:	f80007b7          	lui	a5,0xf8000
    80002dac:	83e9                	srli	a5,a5,0x1a
    80002dae:	06e7e963          	bltu	a5,a4,80002e20 <copyOnWrite+0x7c>
int copyOnWrite(pagetable_t pt,uint64 va){
    80002db2:	7179                	addi	sp,sp,-48
    80002db4:	f406                	sd	ra,40(sp)
    80002db6:	f022                	sd	s0,32(sp)
    80002db8:	ec26                	sd	s1,24(sp)
    80002dba:	e84a                	sd	s2,16(sp)
    80002dbc:	e44e                	sd	s3,8(sp)
    80002dbe:	1800                	addi	s0,sp,48
    return -1;

  pte_t *pte=walk(pt,va,0);
    80002dc0:	4601                	li	a2,0
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	32c080e7          	jalr	812(ra) # 800010ee <walk>
    80002dca:	892a                	mv	s2,a0
  if (!pte || ((*pte & PTE_U) == 0 || (*pte & PTE_V) == 0)) 
    80002dcc:	cd21                	beqz	a0,80002e24 <copyOnWrite+0x80>
    80002dce:	611c                	ld	a5,0(a0)
    80002dd0:	8bc5                	andi	a5,a5,17
    80002dd2:	4745                	li	a4,17
    80002dd4:	04e79a63          	bne	a5,a4,80002e28 <copyOnWrite+0x84>
    return -1;

  uint64 pan=(uint64)kalloc();
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	e0e080e7          	jalr	-498(ra) # 80000be6 <kalloc>
    80002de0:	84aa                	mv	s1,a0
  if(!pan){
    80002de2:	c529                	beqz	a0,80002e2c <copyOnWrite+0x88>
    return -1;
  }
  uint64 pao = PTE2PA(*pte);
    80002de4:	00093983          	ld	s3,0(s2)
    80002de8:	00a9d993          	srli	s3,s3,0xa
    80002dec:	09b2                	slli	s3,s3,0xc
  memmove((void *)pan, (void *)pao, PGSIZE);
    80002dee:	6605                	lui	a2,0x1
    80002df0:	85ce                	mv	a1,s3
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	074080e7          	jalr	116(ra) # 80000e66 <memmove>
  kfree((void *)pao);
    80002dfa:	854e                	mv	a0,s3
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	c64080e7          	jalr	-924(ra) # 80000a60 <kfree>

  *pte = PA2PTE(pan) | PTE_X | PTE_R | PTE_U | PTE_V | PTE_W;
    80002e04:	80b1                	srli	s1,s1,0xc
    80002e06:	04aa                	slli	s1,s1,0xa
    80002e08:	01f4e493          	ori	s1,s1,31
    80002e0c:	00993023          	sd	s1,0(s2)

return 0;
    80002e10:	4501                	li	a0,0

}
    80002e12:	70a2                	ld	ra,40(sp)
    80002e14:	7402                	ld	s0,32(sp)
    80002e16:	64e2                	ld	s1,24(sp)
    80002e18:	6942                	ld	s2,16(sp)
    80002e1a:	69a2                	ld	s3,8(sp)
    80002e1c:	6145                	addi	sp,sp,48
    80002e1e:	8082                	ret
    return -1;
    80002e20:	557d                	li	a0,-1
}
    80002e22:	8082                	ret
    return -1;
    80002e24:	557d                	li	a0,-1
    80002e26:	b7f5                	j	80002e12 <copyOnWrite+0x6e>
    80002e28:	557d                	li	a0,-1
    80002e2a:	b7e5                	j	80002e12 <copyOnWrite+0x6e>
    return -1;
    80002e2c:	557d                	li	a0,-1
    80002e2e:	b7d5                	j	80002e12 <copyOnWrite+0x6e>

0000000080002e30 <trapinithart>:
// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002e30:	1141                	addi	sp,sp,-16
    80002e32:	e422                	sd	s0,8(sp)
    80002e34:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e36:	00003797          	auipc	a5,0x3
    80002e3a:	78a78793          	addi	a5,a5,1930 # 800065c0 <kernelvec>
    80002e3e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e42:	6422                	ld	s0,8(sp)
    80002e44:	0141                	addi	sp,sp,16
    80002e46:	8082                	ret

0000000080002e48 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002e48:	1141                	addi	sp,sp,-16
    80002e4a:	e406                	sd	ra,8(sp)
    80002e4c:	e022                	sd	s0,0(sp)
    80002e4e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	e9a080e7          	jalr	-358(ra) # 80001cea <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e5e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002e62:	00004697          	auipc	a3,0x4
    80002e66:	19e68693          	addi	a3,a3,414 # 80007000 <_trampoline>
    80002e6a:	00004717          	auipc	a4,0x4
    80002e6e:	19670713          	addi	a4,a4,406 # 80007000 <_trampoline>
    80002e72:	8f15                	sub	a4,a4,a3
    80002e74:	040007b7          	lui	a5,0x4000
    80002e78:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002e7a:	07b2                	slli	a5,a5,0xc
    80002e7c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e7e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e82:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e84:	18002673          	csrr	a2,satp
    80002e88:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e8a:	6d30                	ld	a2,88(a0)
    80002e8c:	6138                	ld	a4,64(a0)
    80002e8e:	6585                	lui	a1,0x1
    80002e90:	972e                	add	a4,a4,a1
    80002e92:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e94:	6d38                	ld	a4,88(a0)
    80002e96:	00000617          	auipc	a2,0x0
    80002e9a:	13e60613          	addi	a2,a2,318 # 80002fd4 <usertrap>
    80002e9e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ea0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ea2:	8612                	mv	a2,tp
    80002ea4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002eaa:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002eae:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eb2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002eb6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eb8:	6f18                	ld	a4,24(a4)
    80002eba:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ebe:	6928                	ld	a0,80(a0)
    80002ec0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ec2:	00004717          	auipc	a4,0x4
    80002ec6:	1da70713          	addi	a4,a4,474 # 8000709c <userret>
    80002eca:	8f15                	sub	a4,a4,a3
    80002ecc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ece:	577d                	li	a4,-1
    80002ed0:	177e                	slli	a4,a4,0x3f
    80002ed2:	8d59                	or	a0,a0,a4
    80002ed4:	9782                	jalr	a5
}
    80002ed6:	60a2                	ld	ra,8(sp)
    80002ed8:	6402                	ld	s0,0(sp)
    80002eda:	0141                	addi	sp,sp,16
    80002edc:	8082                	ret

0000000080002ede <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	e426                	sd	s1,8(sp)
    80002ee6:	e04a                	sd	s2,0(sp)
    80002ee8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002eea:	00237917          	auipc	s2,0x237
    80002eee:	17690913          	addi	s2,s2,374 # 8023a060 <tickslock>
    80002ef2:	854a                	mv	a0,s2
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	e1a080e7          	jalr	-486(ra) # 80000d0e <acquire>
  ticks++;
    80002efc:	00006497          	auipc	s1,0x6
    80002f00:	ac448493          	addi	s1,s1,-1340 # 800089c0 <ticks>
    80002f04:	409c                	lw	a5,0(s1)
    80002f06:	2785                	addiw	a5,a5,1
    80002f08:	c09c                	sw	a5,0(s1)
  helpticks();
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	a78080e7          	jalr	-1416(ra) # 80001982 <helpticks>
  //   {
  //     p->wtime++;
  //   }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002f12:	8526                	mv	a0,s1
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	72e080e7          	jalr	1838(ra) # 80002642 <wakeup>
  release(&tickslock);
    80002f1c:	854a                	mv	a0,s2
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	ea4080e7          	jalr	-348(ra) # 80000dc2 <release>
}
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	64a2                	ld	s1,8(sp)
    80002f2c:	6902                	ld	s2,0(sp)
    80002f2e:	6105                	addi	sp,sp,32
    80002f30:	8082                	ret

0000000080002f32 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002f32:	1101                	addi	sp,sp,-32
    80002f34:	ec06                	sd	ra,24(sp)
    80002f36:	e822                	sd	s0,16(sp)
    80002f38:	e426                	sd	s1,8(sp)
    80002f3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f3c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002f40:	00074d63          	bltz	a4,80002f5a <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002f44:	57fd                	li	a5,-1
    80002f46:	17fe                	slli	a5,a5,0x3f
    80002f48:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002f4a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002f4c:	06f70363          	beq	a4,a5,80002fb2 <devintr+0x80>
  }
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	64a2                	ld	s1,8(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret
      (scause & 0xff) == 9)
    80002f5a:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002f5e:	46a5                	li	a3,9
    80002f60:	fed792e3          	bne	a5,a3,80002f44 <devintr+0x12>
    int irq = plic_claim();
    80002f64:	00003097          	auipc	ra,0x3
    80002f68:	764080e7          	jalr	1892(ra) # 800066c8 <plic_claim>
    80002f6c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002f6e:	47a9                	li	a5,10
    80002f70:	02f50763          	beq	a0,a5,80002f9e <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002f74:	4785                	li	a5,1
    80002f76:	02f50963          	beq	a0,a5,80002fa8 <devintr+0x76>
    return 1;
    80002f7a:	4505                	li	a0,1
    else if (irq)
    80002f7c:	d8f1                	beqz	s1,80002f50 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f7e:	85a6                	mv	a1,s1
    80002f80:	00005517          	auipc	a0,0x5
    80002f84:	42050513          	addi	a0,a0,1056 # 800083a0 <states.0+0x38>
    80002f88:	ffffd097          	auipc	ra,0xffffd
    80002f8c:	602080e7          	jalr	1538(ra) # 8000058a <printf>
      plic_complete(irq);
    80002f90:	8526                	mv	a0,s1
    80002f92:	00003097          	auipc	ra,0x3
    80002f96:	75a080e7          	jalr	1882(ra) # 800066ec <plic_complete>
    return 1;
    80002f9a:	4505                	li	a0,1
    80002f9c:	bf55                	j	80002f50 <devintr+0x1e>
      uartintr();
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	9fa080e7          	jalr	-1542(ra) # 80000998 <uartintr>
    80002fa6:	b7ed                	j	80002f90 <devintr+0x5e>
      virtio_disk_intr();
    80002fa8:	00004097          	auipc	ra,0x4
    80002fac:	c0c080e7          	jalr	-1012(ra) # 80006bb4 <virtio_disk_intr>
    80002fb0:	b7c5                	j	80002f90 <devintr+0x5e>
    if (cpuid() == 0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	d0c080e7          	jalr	-756(ra) # 80001cbe <cpuid>
    80002fba:	c901                	beqz	a0,80002fca <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002fbc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002fc0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fc2:	14479073          	csrw	sip,a5
    return 2;
    80002fc6:	4509                	li	a0,2
    80002fc8:	b761                	j	80002f50 <devintr+0x1e>
      clockintr();
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	f14080e7          	jalr	-236(ra) # 80002ede <clockintr>
    80002fd2:	b7ed                	j	80002fbc <devintr+0x8a>

0000000080002fd4 <usertrap>:
{
    80002fd4:	1101                	addi	sp,sp,-32
    80002fd6:	ec06                	sd	ra,24(sp)
    80002fd8:	e822                	sd	s0,16(sp)
    80002fda:	e426                	sd	s1,8(sp)
    80002fdc:	e04a                	sd	s2,0(sp)
    80002fde:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002fe4:	1007f793          	andi	a5,a5,256
    80002fe8:	e3ad                	bnez	a5,8000304a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fea:	00003797          	auipc	a5,0x3
    80002fee:	5d678793          	addi	a5,a5,1494 # 800065c0 <kernelvec>
    80002ff2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	cf4080e7          	jalr	-780(ra) # 80001cea <myproc>
    80002ffe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003000:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003002:	14102773          	csrr	a4,sepc
    80003006:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003008:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    8000300c:	47a1                	li	a5,8
    8000300e:	04f70663          	beq	a4,a5,8000305a <usertrap+0x86>
  else if ((which_dev = devintr()) != 0)
    80003012:	00000097          	auipc	ra,0x0
    80003016:	f20080e7          	jalr	-224(ra) # 80002f32 <devintr>
    8000301a:	892a                	mv	s2,a0
    8000301c:	c971                	beqz	a0,800030f0 <usertrap+0x11c>
    if(which_dev==2 && p->set==0 && p->called == 1){
    8000301e:	4789                	li	a5,2
    80003020:	06f51163          	bne	a0,a5,80003082 <usertrap+0xae>
    80003024:	2004b703          	ld	a4,512(s1)
    80003028:	4785                	li	a5,1
    8000302a:	1782                	slli	a5,a5,0x20
    8000302c:	08f70163          	beq	a4,a5,800030ae <usertrap+0xda>
  if (killed(p))
    80003030:	8526                	mv	a0,s1
    80003032:	00000097          	auipc	ra,0x0
    80003036:	860080e7          	jalr	-1952(ra) # 80002892 <killed>
    8000303a:	12050e63          	beqz	a0,80003176 <usertrap+0x1a2>
    exit(-1);
    8000303e:	557d                	li	a0,-1
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	6d2080e7          	jalr	1746(ra) # 80002712 <exit>
  if(which_dev == 2)
    80003048:	a23d                	j	80003176 <usertrap+0x1a2>
    panic("usertrap: not from user mode");
    8000304a:	00005517          	auipc	a0,0x5
    8000304e:	37650513          	addi	a0,a0,886 # 800083c0 <states.0+0x58>
    80003052:	ffffd097          	auipc	ra,0xffffd
    80003056:	4ee080e7          	jalr	1262(ra) # 80000540 <panic>
    if (killed(p))
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	838080e7          	jalr	-1992(ra) # 80002892 <killed>
    80003062:	e121                	bnez	a0,800030a2 <usertrap+0xce>
    p->trapframe->epc += 4;
    80003064:	6cb8                	ld	a4,88(s1)
    80003066:	6f1c                	ld	a5,24(a4)
    80003068:	0791                	addi	a5,a5,4
    8000306a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000306c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003070:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003074:	10079073          	csrw	sstatus,a5
    syscall();
    80003078:	00000097          	auipc	ra,0x0
    8000307c:	352080e7          	jalr	850(ra) # 800033ca <syscall>
  int which_dev = 0;
    80003080:	4901                	li	s2,0
  if (killed(p))
    80003082:	8526                	mv	a0,s1
    80003084:	00000097          	auipc	ra,0x0
    80003088:	80e080e7          	jalr	-2034(ra) # 80002892 <killed>
    8000308c:	ed69                	bnez	a0,80003166 <usertrap+0x192>
  usertrapret();
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	dba080e7          	jalr	-582(ra) # 80002e48 <usertrapret>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6902                	ld	s2,0(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret
      exit(-1);
    800030a2:	557d                	li	a0,-1
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	66e080e7          	jalr	1646(ra) # 80002712 <exit>
    800030ac:	bf65                	j	80003064 <usertrap+0x90>
    p->cur_ticks++;
    800030ae:	2084a783          	lw	a5,520(s1)
    800030b2:	2785                	addiw	a5,a5,1
    800030b4:	20f4a423          	sw	a5,520(s1)
    struct trapframe *tf=kalloc();
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	b2e080e7          	jalr	-1234(ra) # 80000be6 <kalloc>
    800030c0:	892a                	mv	s2,a0
    memmove(tf,p->trapframe,sizeof(struct trapframe));
    800030c2:	12000613          	li	a2,288
    800030c6:	6cac                	ld	a1,88(s1)
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	d9e080e7          	jalr	-610(ra) # 80000e66 <memmove>
    p->tfp=tf;
    800030d0:	1f24bc23          	sd	s2,504(s1)
    if(p->cur_ticks>=p->ticks)
    800030d4:	2084a703          	lw	a4,520(s1)
    800030d8:	1f04a783          	lw	a5,496(s1)
    800030dc:	f4f74ae3          	blt	a4,a5,80003030 <usertrap+0x5c>
      p->set=1;
    800030e0:	4785                	li	a5,1
    800030e2:	20f4a023          	sw	a5,512(s1)
      p->trapframe->epc=p->handler;
    800030e6:	6cbc                	ld	a5,88(s1)
    800030e8:	1e84b703          	ld	a4,488(s1)
    800030ec:	ef98                	sd	a4,24(a5)
    800030ee:	b789                	j	80003030 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030f0:	14202773          	csrr	a4,scause
  else if(r_scause()==15){
    800030f4:	47bd                	li	a5,15
    800030f6:	02f70f63          	beq	a4,a5,80003134 <usertrap+0x160>
    800030fa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800030fe:	5890                	lw	a2,48(s1)
    80003100:	00005517          	auipc	a0,0x5
    80003104:	2e050513          	addi	a0,a0,736 # 800083e0 <states.0+0x78>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	482080e7          	jalr	1154(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003110:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003114:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003118:	00005517          	auipc	a0,0x5
    8000311c:	2f850513          	addi	a0,a0,760 # 80008410 <states.0+0xa8>
    80003120:	ffffd097          	auipc	ra,0xffffd
    80003124:	46a080e7          	jalr	1130(ra) # 8000058a <printf>
    setkilled(p);
    80003128:	8526                	mv	a0,s1
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	73c080e7          	jalr	1852(ra) # 80002866 <setkilled>
    80003132:	bf81                	j	80003082 <usertrap+0xae>
    80003134:	143025f3          	csrr	a1,stval
    if((copyOnWrite(p->pagetable,r_stval()))<0)
    80003138:	68a8                	ld	a0,80(s1)
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	c6a080e7          	jalr	-918(ra) # 80002da4 <copyOnWrite>
    80003142:	f40550e3          	bgez	a0,80003082 <usertrap+0xae>
      p->killed=1;
    80003146:	4785                	li	a5,1
    80003148:	d49c                	sw	a5,40(s1)
      if (killed(p))
    8000314a:	8526                	mv	a0,s1
    8000314c:	fffff097          	auipc	ra,0xfffff
    80003150:	746080e7          	jalr	1862(ra) # 80002892 <killed>
    80003154:	e119                	bnez	a0,8000315a <usertrap+0x186>
  else if ((which_dev = devintr()) != 0)
    80003156:	892a                	mv	s2,a0
    80003158:	b72d                	j	80003082 <usertrap+0xae>
      exit(-1);
    8000315a:	557d                	li	a0,-1
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	5b6080e7          	jalr	1462(ra) # 80002712 <exit>
    80003164:	bf39                	j	80003082 <usertrap+0xae>
    exit(-1);
    80003166:	557d                	li	a0,-1
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	5aa080e7          	jalr	1450(ra) # 80002712 <exit>
  if(which_dev == 2)
    80003170:	4789                	li	a5,2
    80003172:	f0f91ee3          	bne	s2,a5,8000308e <usertrap+0xba>
    yield();
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	326080e7          	jalr	806(ra) # 8000249c <yield>
    8000317e:	bf01                	j	8000308e <usertrap+0xba>

0000000080003180 <kerneltrap>:
{
    80003180:	7179                	addi	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	e84a                	sd	s2,16(sp)
    8000318a:	e44e                	sd	s3,8(sp)
    8000318c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000318e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003192:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003196:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    8000319a:	1004f793          	andi	a5,s1,256
    8000319e:	cb85                	beqz	a5,800031ce <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031a0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031a4:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800031a6:	ef85                	bnez	a5,800031de <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	d8a080e7          	jalr	-630(ra) # 80002f32 <devintr>
    800031b0:	cd1d                	beqz	a0,800031ee <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031b2:	4789                	li	a5,2
    800031b4:	06f50a63          	beq	a0,a5,80003228 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031b8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031bc:	10049073          	csrw	sstatus,s1
}
    800031c0:	70a2                	ld	ra,40(sp)
    800031c2:	7402                	ld	s0,32(sp)
    800031c4:	64e2                	ld	s1,24(sp)
    800031c6:	6942                	ld	s2,16(sp)
    800031c8:	69a2                	ld	s3,8(sp)
    800031ca:	6145                	addi	sp,sp,48
    800031cc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031ce:	00005517          	auipc	a0,0x5
    800031d2:	26250513          	addi	a0,a0,610 # 80008430 <states.0+0xc8>
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	36a080e7          	jalr	874(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	27a50513          	addi	a0,a0,634 # 80008458 <states.0+0xf0>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	35a080e7          	jalr	858(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800031ee:	85ce                	mv	a1,s3
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	28850513          	addi	a0,a0,648 # 80008478 <states.0+0x110>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	392080e7          	jalr	914(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003200:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003204:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	28050513          	addi	a0,a0,640 # 80008488 <states.0+0x120>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	37a080e7          	jalr	890(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	28850513          	addi	a0,a0,648 # 800084a0 <states.0+0x138>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	320080e7          	jalr	800(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003228:	fffff097          	auipc	ra,0xfffff
    8000322c:	ac2080e7          	jalr	-1342(ra) # 80001cea <myproc>
    80003230:	d541                	beqz	a0,800031b8 <kerneltrap+0x38>
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	ab8080e7          	jalr	-1352(ra) # 80001cea <myproc>
    8000323a:	4d18                	lw	a4,24(a0)
    8000323c:	4791                	li	a5,4
    8000323e:	f6f71de3          	bne	a4,a5,800031b8 <kerneltrap+0x38>
    yield();
    80003242:	fffff097          	auipc	ra,0xfffff
    80003246:	25a080e7          	jalr	602(ra) # 8000249c <yield>
    8000324a:	b7bd                	j	800031b8 <kerneltrap+0x38>

000000008000324c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003258:	fffff097          	auipc	ra,0xfffff
    8000325c:	a92080e7          	jalr	-1390(ra) # 80001cea <myproc>
  switch (n) {
    80003260:	4795                	li	a5,5
    80003262:	0497e163          	bltu	a5,s1,800032a4 <argraw+0x58>
    80003266:	048a                	slli	s1,s1,0x2
    80003268:	00005717          	auipc	a4,0x5
    8000326c:	27070713          	addi	a4,a4,624 # 800084d8 <states.0+0x170>
    80003270:	94ba                	add	s1,s1,a4
    80003272:	409c                	lw	a5,0(s1)
    80003274:	97ba                	add	a5,a5,a4
    80003276:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003278:	6d3c                	ld	a5,88(a0)
    8000327a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000327c:	60e2                	ld	ra,24(sp)
    8000327e:	6442                	ld	s0,16(sp)
    80003280:	64a2                	ld	s1,8(sp)
    80003282:	6105                	addi	sp,sp,32
    80003284:	8082                	ret
    return p->trapframe->a1;
    80003286:	6d3c                	ld	a5,88(a0)
    80003288:	7fa8                	ld	a0,120(a5)
    8000328a:	bfcd                	j	8000327c <argraw+0x30>
    return p->trapframe->a2;
    8000328c:	6d3c                	ld	a5,88(a0)
    8000328e:	63c8                	ld	a0,128(a5)
    80003290:	b7f5                	j	8000327c <argraw+0x30>
    return p->trapframe->a3;
    80003292:	6d3c                	ld	a5,88(a0)
    80003294:	67c8                	ld	a0,136(a5)
    80003296:	b7dd                	j	8000327c <argraw+0x30>
    return p->trapframe->a4;
    80003298:	6d3c                	ld	a5,88(a0)
    8000329a:	6bc8                	ld	a0,144(a5)
    8000329c:	b7c5                	j	8000327c <argraw+0x30>
    return p->trapframe->a5;
    8000329e:	6d3c                	ld	a5,88(a0)
    800032a0:	6fc8                	ld	a0,152(a5)
    800032a2:	bfe9                	j	8000327c <argraw+0x30>
  panic("argraw");
    800032a4:	00005517          	auipc	a0,0x5
    800032a8:	20c50513          	addi	a0,a0,524 # 800084b0 <states.0+0x148>
    800032ac:	ffffd097          	auipc	ra,0xffffd
    800032b0:	294080e7          	jalr	660(ra) # 80000540 <panic>

00000000800032b4 <fetchaddr>:
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	e04a                	sd	s2,0(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84aa                	mv	s1,a0
    800032c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	a26080e7          	jalr	-1498(ra) # 80001cea <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800032cc:	653c                	ld	a5,72(a0)
    800032ce:	02f4f863          	bgeu	s1,a5,800032fe <fetchaddr+0x4a>
    800032d2:	00848713          	addi	a4,s1,8
    800032d6:	02e7e663          	bltu	a5,a4,80003302 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800032da:	46a1                	li	a3,8
    800032dc:	8626                	mv	a2,s1
    800032de:	85ca                	mv	a1,s2
    800032e0:	6928                	ld	a0,80(a0)
    800032e2:	ffffe097          	auipc	ra,0xffffe
    800032e6:	562080e7          	jalr	1378(ra) # 80001844 <copyin>
    800032ea:	00a03533          	snez	a0,a0
    800032ee:	40a00533          	neg	a0,a0
}
    800032f2:	60e2                	ld	ra,24(sp)
    800032f4:	6442                	ld	s0,16(sp)
    800032f6:	64a2                	ld	s1,8(sp)
    800032f8:	6902                	ld	s2,0(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret
    return -1;
    800032fe:	557d                	li	a0,-1
    80003300:	bfcd                	j	800032f2 <fetchaddr+0x3e>
    80003302:	557d                	li	a0,-1
    80003304:	b7fd                	j	800032f2 <fetchaddr+0x3e>

0000000080003306 <fetchstr>:
{
    80003306:	7179                	addi	sp,sp,-48
    80003308:	f406                	sd	ra,40(sp)
    8000330a:	f022                	sd	s0,32(sp)
    8000330c:	ec26                	sd	s1,24(sp)
    8000330e:	e84a                	sd	s2,16(sp)
    80003310:	e44e                	sd	s3,8(sp)
    80003312:	1800                	addi	s0,sp,48
    80003314:	892a                	mv	s2,a0
    80003316:	84ae                	mv	s1,a1
    80003318:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	9d0080e7          	jalr	-1584(ra) # 80001cea <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003322:	86ce                	mv	a3,s3
    80003324:	864a                	mv	a2,s2
    80003326:	85a6                	mv	a1,s1
    80003328:	6928                	ld	a0,80(a0)
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	5a8080e7          	jalr	1448(ra) # 800018d2 <copyinstr>
    80003332:	00054e63          	bltz	a0,8000334e <fetchstr+0x48>
  return strlen(buf);
    80003336:	8526                	mv	a0,s1
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	c4e080e7          	jalr	-946(ra) # 80000f86 <strlen>
}
    80003340:	70a2                	ld	ra,40(sp)
    80003342:	7402                	ld	s0,32(sp)
    80003344:	64e2                	ld	s1,24(sp)
    80003346:	6942                	ld	s2,16(sp)
    80003348:	69a2                	ld	s3,8(sp)
    8000334a:	6145                	addi	sp,sp,48
    8000334c:	8082                	ret
    return -1;
    8000334e:	557d                	li	a0,-1
    80003350:	bfc5                	j	80003340 <fetchstr+0x3a>

0000000080003352 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003352:	1101                	addi	sp,sp,-32
    80003354:	ec06                	sd	ra,24(sp)
    80003356:	e822                	sd	s0,16(sp)
    80003358:	e426                	sd	s1,8(sp)
    8000335a:	1000                	addi	s0,sp,32
    8000335c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	eee080e7          	jalr	-274(ra) # 8000324c <argraw>
    80003366:	c088                	sw	a0,0(s1)
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	ece080e7          	jalr	-306(ra) # 8000324c <argraw>
    80003386:	e088                	sd	a0,0(s1)
}
    80003388:	60e2                	ld	ra,24(sp)
    8000338a:	6442                	ld	s0,16(sp)
    8000338c:	64a2                	ld	s1,8(sp)
    8000338e:	6105                	addi	sp,sp,32
    80003390:	8082                	ret

0000000080003392 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003392:	7179                	addi	sp,sp,-48
    80003394:	f406                	sd	ra,40(sp)
    80003396:	f022                	sd	s0,32(sp)
    80003398:	ec26                	sd	s1,24(sp)
    8000339a:	e84a                	sd	s2,16(sp)
    8000339c:	1800                	addi	s0,sp,48
    8000339e:	84ae                	mv	s1,a1
    800033a0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800033a2:	fd840593          	addi	a1,s0,-40
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	fcc080e7          	jalr	-52(ra) # 80003372 <argaddr>
  return fetchstr(addr, buf, max);
    800033ae:	864a                	mv	a2,s2
    800033b0:	85a6                	mv	a1,s1
    800033b2:	fd843503          	ld	a0,-40(s0)
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	f50080e7          	jalr	-176(ra) # 80003306 <fetchstr>
}
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	6145                	addi	sp,sp,48
    800033c8:	8082                	ret

00000000800033ca <syscall>:
[SYS_set_priority]  sys_set_priority
};

void
syscall(void)
{
    800033ca:	1101                	addi	sp,sp,-32
    800033cc:	ec06                	sd	ra,24(sp)
    800033ce:	e822                	sd	s0,16(sp)
    800033d0:	e426                	sd	s1,8(sp)
    800033d2:	e04a                	sd	s2,0(sp)
    800033d4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800033d6:	fffff097          	auipc	ra,0xfffff
    800033da:	914080e7          	jalr	-1772(ra) # 80001cea <myproc>
    800033de:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800033e0:	05853903          	ld	s2,88(a0)
    800033e4:	0a893783          	ld	a5,168(s2)
    800033e8:	0007869b          	sext.w	a3,a5
  if(num==SYS_read){
    800033ec:	4715                	li	a4,5
    800033ee:	02e68763          	beq	a3,a4,8000341c <syscall+0x52>
    g_read++;
  }
  if(num==SYS_getreadcount){
    800033f2:	475d                	li	a4,23
    800033f4:	04e69763          	bne	a3,a4,80003442 <syscall+0x78>
    p->rc=g_read;
    800033f8:	00005717          	auipc	a4,0x5
    800033fc:	5cc72703          	lw	a4,1484(a4) # 800089c4 <g_read>
    80003400:	1ee52a23          	sw	a4,500(a0)
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003404:	37fd                	addiw	a5,a5,-1
    80003406:	4669                	li	a2,26
    80003408:	00000717          	auipc	a4,0x0
    8000340c:	3be70713          	addi	a4,a4,958 # 800037c6 <sys_getreadcount>
    80003410:	04f66663          	bltu	a2,a5,8000345c <syscall+0x92>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003414:	9702                	jalr	a4
    80003416:	06a93823          	sd	a0,112(s2)
    8000341a:	a8b9                	j	80003478 <syscall+0xae>
    g_read++;
    8000341c:	00005617          	auipc	a2,0x5
    80003420:	5a860613          	addi	a2,a2,1448 # 800089c4 <g_read>
    80003424:	4218                	lw	a4,0(a2)
    80003426:	2705                	addiw	a4,a4,1
    80003428:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000342a:	37fd                	addiw	a5,a5,-1
    8000342c:	4769                	li	a4,26
    8000342e:	02f76763          	bltu	a4,a5,8000345c <syscall+0x92>
    80003432:	068e                	slli	a3,a3,0x3
    80003434:	00005797          	auipc	a5,0x5
    80003438:	0bc78793          	addi	a5,a5,188 # 800084f0 <syscalls>
    8000343c:	97b6                	add	a5,a5,a3
    8000343e:	6398                	ld	a4,0(a5)
    80003440:	bfd1                	j	80003414 <syscall+0x4a>
    80003442:	37fd                	addiw	a5,a5,-1
    80003444:	4769                	li	a4,26
    80003446:	00f76b63          	bltu	a4,a5,8000345c <syscall+0x92>
    8000344a:	00369713          	slli	a4,a3,0x3
    8000344e:	00005797          	auipc	a5,0x5
    80003452:	0a278793          	addi	a5,a5,162 # 800084f0 <syscalls>
    80003456:	97ba                	add	a5,a5,a4
    80003458:	6398                	ld	a4,0(a5)
    8000345a:	ff4d                	bnez	a4,80003414 <syscall+0x4a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000345c:	15848613          	addi	a2,s1,344
    80003460:	588c                	lw	a1,48(s1)
    80003462:	00005517          	auipc	a0,0x5
    80003466:	05650513          	addi	a0,a0,86 # 800084b8 <states.0+0x150>
    8000346a:	ffffd097          	auipc	ra,0xffffd
    8000346e:	120080e7          	jalr	288(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003472:	6cbc                	ld	a5,88(s1)
    80003474:	577d                	li	a4,-1
    80003476:	fbb8                	sd	a4,112(a5)
  }
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6902                	ld	s2,0(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret

0000000080003484 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000348c:	fec40593          	addi	a1,s0,-20
    80003490:	4501                	li	a0,0
    80003492:	00000097          	auipc	ra,0x0
    80003496:	ec0080e7          	jalr	-320(ra) # 80003352 <argint>
  exit(n);
    8000349a:	fec42503          	lw	a0,-20(s0)
    8000349e:	fffff097          	auipc	ra,0xfffff
    800034a2:	274080e7          	jalr	628(ra) # 80002712 <exit>
  return 0; // not reached
}
    800034a6:	4501                	li	a0,0
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	6105                	addi	sp,sp,32
    800034ae:	8082                	ret

00000000800034b0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800034b0:	1141                	addi	sp,sp,-16
    800034b2:	e406                	sd	ra,8(sp)
    800034b4:	e022                	sd	s0,0(sp)
    800034b6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034b8:	fffff097          	auipc	ra,0xfffff
    800034bc:	832080e7          	jalr	-1998(ra) # 80001cea <myproc>
}
    800034c0:	5908                	lw	a0,48(a0)
    800034c2:	60a2                	ld	ra,8(sp)
    800034c4:	6402                	ld	s0,0(sp)
    800034c6:	0141                	addi	sp,sp,16
    800034c8:	8082                	ret

00000000800034ca <sys_fork>:

uint64
sys_fork(void)
{
    800034ca:	1141                	addi	sp,sp,-16
    800034cc:	e406                	sd	ra,8(sp)
    800034ce:	e022                	sd	s0,0(sp)
    800034d0:	0800                	addi	s0,sp,16
  return fork();
    800034d2:	fffff097          	auipc	ra,0xfffff
    800034d6:	c28080e7          	jalr	-984(ra) # 800020fa <fork>
}
    800034da:	60a2                	ld	ra,8(sp)
    800034dc:	6402                	ld	s0,0(sp)
    800034de:	0141                	addi	sp,sp,16
    800034e0:	8082                	ret

00000000800034e2 <sys_wait>:

uint64
sys_wait(void)
{
    800034e2:	1101                	addi	sp,sp,-32
    800034e4:	ec06                	sd	ra,24(sp)
    800034e6:	e822                	sd	s0,16(sp)
    800034e8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800034ea:	fe840593          	addi	a1,s0,-24
    800034ee:	4501                	li	a0,0
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	e82080e7          	jalr	-382(ra) # 80003372 <argaddr>
  return wait(p);
    800034f8:	fe843503          	ld	a0,-24(s0)
    800034fc:	fffff097          	auipc	ra,0xfffff
    80003500:	3c8080e7          	jalr	968(ra) # 800028c4 <wait>
}
    80003504:	60e2                	ld	ra,24(sp)
    80003506:	6442                	ld	s0,16(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret

000000008000350c <sys_set_priority>:
uint64
sys_set_priority(void)
{
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	1000                	addi	s0,sp,32
  int priority, pid;
  argint(0, &pid);
    80003514:	fe840593          	addi	a1,s0,-24
    80003518:	4501                	li	a0,0
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	e38080e7          	jalr	-456(ra) # 80003352 <argint>
  argint(1, &priority);
    80003522:	fec40593          	addi	a1,s0,-20
    80003526:	4505                	li	a0,1
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	e2a080e7          	jalr	-470(ra) # 80003352 <argint>
  return set_priority(pid, priority);
    80003530:	fec42583          	lw	a1,-20(s0)
    80003534:	fe842503          	lw	a0,-24(s0)
    80003538:	fffff097          	auipc	ra,0xfffff
    8000353c:	fa0080e7          	jalr	-96(ra) # 800024d8 <set_priority>
}
    80003540:	60e2                	ld	ra,24(sp)
    80003542:	6442                	ld	s0,16(sp)
    80003544:	6105                	addi	sp,sp,32
    80003546:	8082                	ret

0000000080003548 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003548:	7179                	addi	sp,sp,-48
    8000354a:	f406                	sd	ra,40(sp)
    8000354c:	f022                	sd	s0,32(sp)
    8000354e:	ec26                	sd	s1,24(sp)
    80003550:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003552:	fdc40593          	addi	a1,s0,-36
    80003556:	4501                	li	a0,0
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	dfa080e7          	jalr	-518(ra) # 80003352 <argint>
  addr = myproc()->sz;
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	78a080e7          	jalr	1930(ra) # 80001cea <myproc>
    80003568:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000356a:	fdc42503          	lw	a0,-36(s0)
    8000356e:	fffff097          	auipc	ra,0xfffff
    80003572:	b30080e7          	jalr	-1232(ra) # 8000209e <growproc>
    80003576:	00054863          	bltz	a0,80003586 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000357a:	8526                	mv	a0,s1
    8000357c:	70a2                	ld	ra,40(sp)
    8000357e:	7402                	ld	s0,32(sp)
    80003580:	64e2                	ld	s1,24(sp)
    80003582:	6145                	addi	sp,sp,48
    80003584:	8082                	ret
    return -1;
    80003586:	54fd                	li	s1,-1
    80003588:	bfcd                	j	8000357a <sys_sbrk+0x32>

000000008000358a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000358a:	7139                	addi	sp,sp,-64
    8000358c:	fc06                	sd	ra,56(sp)
    8000358e:	f822                	sd	s0,48(sp)
    80003590:	f426                	sd	s1,40(sp)
    80003592:	f04a                	sd	s2,32(sp)
    80003594:	ec4e                	sd	s3,24(sp)
    80003596:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003598:	fcc40593          	addi	a1,s0,-52
    8000359c:	4501                	li	a0,0
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	db4080e7          	jalr	-588(ra) # 80003352 <argint>
  acquire(&tickslock);
    800035a6:	00237517          	auipc	a0,0x237
    800035aa:	aba50513          	addi	a0,a0,-1350 # 8023a060 <tickslock>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	760080e7          	jalr	1888(ra) # 80000d0e <acquire>
  ticks0 = ticks;
    800035b6:	00005917          	auipc	s2,0x5
    800035ba:	40a92903          	lw	s2,1034(s2) # 800089c0 <ticks>
  while (ticks - ticks0 < n)
    800035be:	fcc42783          	lw	a5,-52(s0)
    800035c2:	cf9d                	beqz	a5,80003600 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035c4:	00237997          	auipc	s3,0x237
    800035c8:	a9c98993          	addi	s3,s3,-1380 # 8023a060 <tickslock>
    800035cc:	00005497          	auipc	s1,0x5
    800035d0:	3f448493          	addi	s1,s1,1012 # 800089c0 <ticks>
    if (killed(myproc()))
    800035d4:	ffffe097          	auipc	ra,0xffffe
    800035d8:	716080e7          	jalr	1814(ra) # 80001cea <myproc>
    800035dc:	fffff097          	auipc	ra,0xfffff
    800035e0:	2b6080e7          	jalr	694(ra) # 80002892 <killed>
    800035e4:	ed15                	bnez	a0,80003620 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800035e6:	85ce                	mv	a1,s3
    800035e8:	8526                	mv	a0,s1
    800035ea:	fffff097          	auipc	ra,0xfffff
    800035ee:	ff4080e7          	jalr	-12(ra) # 800025de <sleep>
  while (ticks - ticks0 < n)
    800035f2:	409c                	lw	a5,0(s1)
    800035f4:	412787bb          	subw	a5,a5,s2
    800035f8:	fcc42703          	lw	a4,-52(s0)
    800035fc:	fce7ece3          	bltu	a5,a4,800035d4 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003600:	00237517          	auipc	a0,0x237
    80003604:	a6050513          	addi	a0,a0,-1440 # 8023a060 <tickslock>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	7ba080e7          	jalr	1978(ra) # 80000dc2 <release>
  return 0;
    80003610:	4501                	li	a0,0
}
    80003612:	70e2                	ld	ra,56(sp)
    80003614:	7442                	ld	s0,48(sp)
    80003616:	74a2                	ld	s1,40(sp)
    80003618:	7902                	ld	s2,32(sp)
    8000361a:	69e2                	ld	s3,24(sp)
    8000361c:	6121                	addi	sp,sp,64
    8000361e:	8082                	ret
      release(&tickslock);
    80003620:	00237517          	auipc	a0,0x237
    80003624:	a4050513          	addi	a0,a0,-1472 # 8023a060 <tickslock>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	79a080e7          	jalr	1946(ra) # 80000dc2 <release>
      return -1;
    80003630:	557d                	li	a0,-1
    80003632:	b7c5                	j	80003612 <sys_sleep+0x88>

0000000080003634 <sys_kill>:

uint64
sys_kill(void)
{
    80003634:	1101                	addi	sp,sp,-32
    80003636:	ec06                	sd	ra,24(sp)
    80003638:	e822                	sd	s0,16(sp)
    8000363a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000363c:	fec40593          	addi	a1,s0,-20
    80003640:	4501                	li	a0,0
    80003642:	00000097          	auipc	ra,0x0
    80003646:	d10080e7          	jalr	-752(ra) # 80003352 <argint>
  return kill(pid);
    8000364a:	fec42503          	lw	a0,-20(s0)
    8000364e:	fffff097          	auipc	ra,0xfffff
    80003652:	1a6080e7          	jalr	422(ra) # 800027f4 <kill>
}
    80003656:	60e2                	ld	ra,24(sp)
    80003658:	6442                	ld	s0,16(sp)
    8000365a:	6105                	addi	sp,sp,32
    8000365c:	8082                	ret

000000008000365e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000365e:	1101                	addi	sp,sp,-32
    80003660:	ec06                	sd	ra,24(sp)
    80003662:	e822                	sd	s0,16(sp)
    80003664:	e426                	sd	s1,8(sp)
    80003666:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003668:	00237517          	auipc	a0,0x237
    8000366c:	9f850513          	addi	a0,a0,-1544 # 8023a060 <tickslock>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	69e080e7          	jalr	1694(ra) # 80000d0e <acquire>
  xticks = ticks;
    80003678:	00005497          	auipc	s1,0x5
    8000367c:	3484a483          	lw	s1,840(s1) # 800089c0 <ticks>
  release(&tickslock);
    80003680:	00237517          	auipc	a0,0x237
    80003684:	9e050513          	addi	a0,a0,-1568 # 8023a060 <tickslock>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	73a080e7          	jalr	1850(ra) # 80000dc2 <release>
  return xticks;
}
    80003690:	02049513          	slli	a0,s1,0x20
    80003694:	9101                	srli	a0,a0,0x20
    80003696:	60e2                	ld	ra,24(sp)
    80003698:	6442                	ld	s0,16(sp)
    8000369a:	64a2                	ld	s1,8(sp)
    8000369c:	6105                	addi	sp,sp,32
    8000369e:	8082                	ret

00000000800036a0 <sys_waitx>:

uint64
sys_waitx(void)
{
    800036a0:	7139                	addi	sp,sp,-64
    800036a2:	fc06                	sd	ra,56(sp)
    800036a4:	f822                	sd	s0,48(sp)
    800036a6:	f426                	sd	s1,40(sp)
    800036a8:	f04a                	sd	s2,32(sp)
    800036aa:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800036ac:	fd840593          	addi	a1,s0,-40
    800036b0:	4501                	li	a0,0
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	cc0080e7          	jalr	-832(ra) # 80003372 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800036ba:	fd040593          	addi	a1,s0,-48
    800036be:	4505                	li	a0,1
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	cb2080e7          	jalr	-846(ra) # 80003372 <argaddr>
  argaddr(2, &addr2);
    800036c8:	fc840593          	addi	a1,s0,-56
    800036cc:	4509                	li	a0,2
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	ca4080e7          	jalr	-860(ra) # 80003372 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800036d6:	fc040613          	addi	a2,s0,-64
    800036da:	fc440593          	addi	a1,s0,-60
    800036de:	fd843503          	ld	a0,-40(s0)
    800036e2:	fffff097          	auipc	ra,0xfffff
    800036e6:	46c080e7          	jalr	1132(ra) # 80002b4e <waitx>
    800036ea:	892a                	mv	s2,a0
  //getps();
  struct proc *p = myproc();
    800036ec:	ffffe097          	auipc	ra,0xffffe
    800036f0:	5fe080e7          	jalr	1534(ra) # 80001cea <myproc>
    800036f4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036f6:	4691                	li	a3,4
    800036f8:	fc440613          	addi	a2,s0,-60
    800036fc:	fd043583          	ld	a1,-48(s0)
    80003700:	6928                	ld	a0,80(a0)
    80003702:	ffffe097          	auipc	ra,0xffffe
    80003706:	088080e7          	jalr	136(ra) # 8000178a <copyout>
    return -1;
    8000370a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000370c:	00054f63          	bltz	a0,8000372a <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003710:	4691                	li	a3,4
    80003712:	fc040613          	addi	a2,s0,-64
    80003716:	fc843583          	ld	a1,-56(s0)
    8000371a:	68a8                	ld	a0,80(s1)
    8000371c:	ffffe097          	auipc	ra,0xffffe
    80003720:	06e080e7          	jalr	110(ra) # 8000178a <copyout>
    80003724:	00054a63          	bltz	a0,80003738 <sys_waitx+0x98>
    return -1;
  return ret;
    80003728:	87ca                	mv	a5,s2
}
    8000372a:	853e                	mv	a0,a5
    8000372c:	70e2                	ld	ra,56(sp)
    8000372e:	7442                	ld	s0,48(sp)
    80003730:	74a2                	ld	s1,40(sp)
    80003732:	7902                	ld	s2,32(sp)
    80003734:	6121                	addi	sp,sp,64
    80003736:	8082                	ret
    return -1;
    80003738:	57fd                	li	a5,-1
    8000373a:	bfc5                	j	8000372a <sys_waitx+0x8a>

000000008000373c <sys_getps>:
uint64
sys_getps(void)
{
    8000373c:	1141                	addi	sp,sp,-16
    8000373e:	e406                	sd	ra,8(sp)
    80003740:	e022                	sd	s0,0(sp)
    80003742:	0800                	addi	s0,sp,16
    return getps();
    80003744:	fffff097          	auipc	ra,0xfffff
    80003748:	55a080e7          	jalr	1370(ra) # 80002c9e <getps>
}
    8000374c:	60a2                	ld	ra,8(sp)
    8000374e:	6402                	ld	s0,0(sp)
    80003750:	0141                	addi	sp,sp,16
    80003752:	8082                	ret

0000000080003754 <sys_sigalarm>:
uint64 
sys_sigalarm(void)
{
    80003754:	1101                	addi	sp,sp,-32
    80003756:	ec06                	sd	ra,24(sp)
    80003758:	e822                	sd	s0,16(sp)
    8000375a:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handleradd;
  argint(0,&ticks);
    8000375c:	fec40593          	addi	a1,s0,-20
    80003760:	4501                	li	a0,0
    80003762:	00000097          	auipc	ra,0x0
    80003766:	bf0080e7          	jalr	-1040(ra) # 80003352 <argint>
  argaddr(1,&handleradd);
    8000376a:	fe040593          	addi	a1,s0,-32
    8000376e:	4505                	li	a0,1
    80003770:	00000097          	auipc	ra,0x0
    80003774:	c02080e7          	jalr	-1022(ra) # 80003372 <argaddr>
   if (ticks <= 0)
    80003778:	fec42783          	lw	a5,-20(s0)
    8000377c:	02f05e63          	blez	a5,800037b8 <sys_sigalarm+0x64>
  {
    myproc()->called = 0;
    return 0;
  }
  myproc()->ticks=ticks;
    80003780:	ffffe097          	auipc	ra,0xffffe
    80003784:	56a080e7          	jalr	1386(ra) # 80001cea <myproc>
    80003788:	fec42783          	lw	a5,-20(s0)
    8000378c:	1ef52823          	sw	a5,496(a0)
  myproc()->called = 1;
    80003790:	ffffe097          	auipc	ra,0xffffe
    80003794:	55a080e7          	jalr	1370(ra) # 80001cea <myproc>
    80003798:	4785                	li	a5,1
    8000379a:	20f52223          	sw	a5,516(a0)
  myproc()->handler=handleradd;
    8000379e:	ffffe097          	auipc	ra,0xffffe
    800037a2:	54c080e7          	jalr	1356(ra) # 80001cea <myproc>
    800037a6:	fe043783          	ld	a5,-32(s0)
    800037aa:	1ef53423          	sd	a5,488(a0)
  return 0;
}
    800037ae:	4501                	li	a0,0
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret
    myproc()->called = 0;
    800037b8:	ffffe097          	auipc	ra,0xffffe
    800037bc:	532080e7          	jalr	1330(ra) # 80001cea <myproc>
    800037c0:	20052223          	sw	zero,516(a0)
    return 0;
    800037c4:	b7ed                	j	800037ae <sys_sigalarm+0x5a>

00000000800037c6 <sys_getreadcount>:
uint64 
sys_getreadcount(void){
    800037c6:	1141                	addi	sp,sp,-16
    800037c8:	e406                	sd	ra,8(sp)
    800037ca:	e022                	sd	s0,0(sp)
    800037cc:	0800                	addi	s0,sp,16
  return myproc()->rc;
    800037ce:	ffffe097          	auipc	ra,0xffffe
    800037d2:	51c080e7          	jalr	1308(ra) # 80001cea <myproc>
}
    800037d6:	1f452503          	lw	a0,500(a0)
    800037da:	60a2                	ld	ra,8(sp)
    800037dc:	6402                	ld	s0,0(sp)
    800037de:	0141                	addi	sp,sp,16
    800037e0:	8082                	ret

00000000800037e2 <sys_sigreturn>:
uint64
sys_sigreturn(void)
{
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	1000                	addi	s0,sp,32
  struct proc *p=0;
  p=myproc();
    800037ec:	ffffe097          	auipc	ra,0xffffe
    800037f0:	4fe080e7          	jalr	1278(ra) # 80001cea <myproc>
    800037f4:	84aa                	mv	s1,a0
  memmove(p->trapframe,p->tfp,sizeof(struct trapframe));
    800037f6:	12000613          	li	a2,288
    800037fa:	1f853583          	ld	a1,504(a0)
    800037fe:	6d28                	ld	a0,88(a0)
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	666080e7          	jalr	1638(ra) # 80000e66 <memmove>
  kfree(p->tfp);
    80003808:	1f84b503          	ld	a0,504(s1)
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	254080e7          	jalr	596(ra) # 80000a60 <kfree>
  p->cur_ticks = 0;
    80003814:	2004a423          	sw	zero,520(s1)
  p->tfp=0;
    80003818:	1e04bc23          	sd	zero,504(s1)
  p->set = 0;
    8000381c:	2004a023          	sw	zero,512(s1)
  return p->trapframe->a0;
    80003820:	6cbc                	ld	a5,88(s1)
    80003822:	7ba8                	ld	a0,112(a5)
    80003824:	60e2                	ld	ra,24(sp)
    80003826:	6442                	ld	s0,16(sp)
    80003828:	64a2                	ld	s1,8(sp)
    8000382a:	6105                	addi	sp,sp,32
    8000382c:	8082                	ret

000000008000382e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000382e:	7179                	addi	sp,sp,-48
    80003830:	f406                	sd	ra,40(sp)
    80003832:	f022                	sd	s0,32(sp)
    80003834:	ec26                	sd	s1,24(sp)
    80003836:	e84a                	sd	s2,16(sp)
    80003838:	e44e                	sd	s3,8(sp)
    8000383a:	e052                	sd	s4,0(sp)
    8000383c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000383e:	00005597          	auipc	a1,0x5
    80003842:	d9258593          	addi	a1,a1,-622 # 800085d0 <syscalls+0xe0>
    80003846:	00237517          	auipc	a0,0x237
    8000384a:	83250513          	addi	a0,a0,-1998 # 8023a078 <bcache>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	430080e7          	jalr	1072(ra) # 80000c7e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003856:	0023f797          	auipc	a5,0x23f
    8000385a:	82278793          	addi	a5,a5,-2014 # 80242078 <bcache+0x8000>
    8000385e:	0023f717          	auipc	a4,0x23f
    80003862:	a8270713          	addi	a4,a4,-1406 # 802422e0 <bcache+0x8268>
    80003866:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000386a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000386e:	00237497          	auipc	s1,0x237
    80003872:	82248493          	addi	s1,s1,-2014 # 8023a090 <bcache+0x18>
    b->next = bcache.head.next;
    80003876:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003878:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000387a:	00005a17          	auipc	s4,0x5
    8000387e:	d5ea0a13          	addi	s4,s4,-674 # 800085d8 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003882:	2b893783          	ld	a5,696(s2)
    80003886:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003888:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000388c:	85d2                	mv	a1,s4
    8000388e:	01048513          	addi	a0,s1,16
    80003892:	00001097          	auipc	ra,0x1
    80003896:	4c8080e7          	jalr	1224(ra) # 80004d5a <initsleeplock>
    bcache.head.next->prev = b;
    8000389a:	2b893783          	ld	a5,696(s2)
    8000389e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800038a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038a4:	45848493          	addi	s1,s1,1112
    800038a8:	fd349de3          	bne	s1,s3,80003882 <binit+0x54>
  }
}
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6942                	ld	s2,16(sp)
    800038b4:	69a2                	ld	s3,8(sp)
    800038b6:	6a02                	ld	s4,0(sp)
    800038b8:	6145                	addi	sp,sp,48
    800038ba:	8082                	ret

00000000800038bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800038bc:	7179                	addi	sp,sp,-48
    800038be:	f406                	sd	ra,40(sp)
    800038c0:	f022                	sd	s0,32(sp)
    800038c2:	ec26                	sd	s1,24(sp)
    800038c4:	e84a                	sd	s2,16(sp)
    800038c6:	e44e                	sd	s3,8(sp)
    800038c8:	1800                	addi	s0,sp,48
    800038ca:	892a                	mv	s2,a0
    800038cc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800038ce:	00236517          	auipc	a0,0x236
    800038d2:	7aa50513          	addi	a0,a0,1962 # 8023a078 <bcache>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	438080e7          	jalr	1080(ra) # 80000d0e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800038de:	0023f497          	auipc	s1,0x23f
    800038e2:	a524b483          	ld	s1,-1454(s1) # 80242330 <bcache+0x82b8>
    800038e6:	0023f797          	auipc	a5,0x23f
    800038ea:	9fa78793          	addi	a5,a5,-1542 # 802422e0 <bcache+0x8268>
    800038ee:	02f48f63          	beq	s1,a5,8000392c <bread+0x70>
    800038f2:	873e                	mv	a4,a5
    800038f4:	a021                	j	800038fc <bread+0x40>
    800038f6:	68a4                	ld	s1,80(s1)
    800038f8:	02e48a63          	beq	s1,a4,8000392c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800038fc:	449c                	lw	a5,8(s1)
    800038fe:	ff279ce3          	bne	a5,s2,800038f6 <bread+0x3a>
    80003902:	44dc                	lw	a5,12(s1)
    80003904:	ff3799e3          	bne	a5,s3,800038f6 <bread+0x3a>
      b->referenceCount++;
    80003908:	40bc                	lw	a5,64(s1)
    8000390a:	2785                	addiw	a5,a5,1
    8000390c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000390e:	00236517          	auipc	a0,0x236
    80003912:	76a50513          	addi	a0,a0,1898 # 8023a078 <bcache>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	4ac080e7          	jalr	1196(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    8000391e:	01048513          	addi	a0,s1,16
    80003922:	00001097          	auipc	ra,0x1
    80003926:	472080e7          	jalr	1138(ra) # 80004d94 <acquiresleep>
      return b;
    8000392a:	a8b9                	j	80003988 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000392c:	0023f497          	auipc	s1,0x23f
    80003930:	9fc4b483          	ld	s1,-1540(s1) # 80242328 <bcache+0x82b0>
    80003934:	0023f797          	auipc	a5,0x23f
    80003938:	9ac78793          	addi	a5,a5,-1620 # 802422e0 <bcache+0x8268>
    8000393c:	00f48863          	beq	s1,a5,8000394c <bread+0x90>
    80003940:	873e                	mv	a4,a5
    if(b->referenceCount == 0) {
    80003942:	40bc                	lw	a5,64(s1)
    80003944:	cf81                	beqz	a5,8000395c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003946:	64a4                	ld	s1,72(s1)
    80003948:	fee49de3          	bne	s1,a4,80003942 <bread+0x86>
  panic("bget: no buffers");
    8000394c:	00005517          	auipc	a0,0x5
    80003950:	c9450513          	addi	a0,a0,-876 # 800085e0 <syscalls+0xf0>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	bec080e7          	jalr	-1044(ra) # 80000540 <panic>
      b->dev = dev;
    8000395c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003960:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003964:	0004a023          	sw	zero,0(s1)
      b->referenceCount = 1;
    80003968:	4785                	li	a5,1
    8000396a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000396c:	00236517          	auipc	a0,0x236
    80003970:	70c50513          	addi	a0,a0,1804 # 8023a078 <bcache>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	44e080e7          	jalr	1102(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    8000397c:	01048513          	addi	a0,s1,16
    80003980:	00001097          	auipc	ra,0x1
    80003984:	414080e7          	jalr	1044(ra) # 80004d94 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003988:	409c                	lw	a5,0(s1)
    8000398a:	cb89                	beqz	a5,8000399c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000398c:	8526                	mv	a0,s1
    8000398e:	70a2                	ld	ra,40(sp)
    80003990:	7402                	ld	s0,32(sp)
    80003992:	64e2                	ld	s1,24(sp)
    80003994:	6942                	ld	s2,16(sp)
    80003996:	69a2                	ld	s3,8(sp)
    80003998:	6145                	addi	sp,sp,48
    8000399a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000399c:	4581                	li	a1,0
    8000399e:	8526                	mv	a0,s1
    800039a0:	00003097          	auipc	ra,0x3
    800039a4:	fe2080e7          	jalr	-30(ra) # 80006982 <virtio_disk_rw>
    b->valid = 1;
    800039a8:	4785                	li	a5,1
    800039aa:	c09c                	sw	a5,0(s1)
  return b;
    800039ac:	b7c5                	j	8000398c <bread+0xd0>

00000000800039ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800039ae:	1101                	addi	sp,sp,-32
    800039b0:	ec06                	sd	ra,24(sp)
    800039b2:	e822                	sd	s0,16(sp)
    800039b4:	e426                	sd	s1,8(sp)
    800039b6:	1000                	addi	s0,sp,32
    800039b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039ba:	0541                	addi	a0,a0,16
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	472080e7          	jalr	1138(ra) # 80004e2e <holdingsleep>
    800039c4:	cd01                	beqz	a0,800039dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800039c6:	4585                	li	a1,1
    800039c8:	8526                	mv	a0,s1
    800039ca:	00003097          	auipc	ra,0x3
    800039ce:	fb8080e7          	jalr	-72(ra) # 80006982 <virtio_disk_rw>
}
    800039d2:	60e2                	ld	ra,24(sp)
    800039d4:	6442                	ld	s0,16(sp)
    800039d6:	64a2                	ld	s1,8(sp)
    800039d8:	6105                	addi	sp,sp,32
    800039da:	8082                	ret
    panic("bwrite");
    800039dc:	00005517          	auipc	a0,0x5
    800039e0:	c1c50513          	addi	a0,a0,-996 # 800085f8 <syscalls+0x108>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	b5c080e7          	jalr	-1188(ra) # 80000540 <panic>

00000000800039ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800039ec:	1101                	addi	sp,sp,-32
    800039ee:	ec06                	sd	ra,24(sp)
    800039f0:	e822                	sd	s0,16(sp)
    800039f2:	e426                	sd	s1,8(sp)
    800039f4:	e04a                	sd	s2,0(sp)
    800039f6:	1000                	addi	s0,sp,32
    800039f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039fa:	01050913          	addi	s2,a0,16
    800039fe:	854a                	mv	a0,s2
    80003a00:	00001097          	auipc	ra,0x1
    80003a04:	42e080e7          	jalr	1070(ra) # 80004e2e <holdingsleep>
    80003a08:	c92d                	beqz	a0,80003a7a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	3de080e7          	jalr	990(ra) # 80004dea <releasesleep>

  acquire(&bcache.lock);
    80003a14:	00236517          	auipc	a0,0x236
    80003a18:	66450513          	addi	a0,a0,1636 # 8023a078 <bcache>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	2f2080e7          	jalr	754(ra) # 80000d0e <acquire>
  b->referenceCount--;
    80003a24:	40bc                	lw	a5,64(s1)
    80003a26:	37fd                	addiw	a5,a5,-1
    80003a28:	0007871b          	sext.w	a4,a5
    80003a2c:	c0bc                	sw	a5,64(s1)
  if (b->referenceCount == 0) {
    80003a2e:	eb05                	bnez	a4,80003a5e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003a30:	68bc                	ld	a5,80(s1)
    80003a32:	64b8                	ld	a4,72(s1)
    80003a34:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003a36:	64bc                	ld	a5,72(s1)
    80003a38:	68b8                	ld	a4,80(s1)
    80003a3a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003a3c:	0023e797          	auipc	a5,0x23e
    80003a40:	63c78793          	addi	a5,a5,1596 # 80242078 <bcache+0x8000>
    80003a44:	2b87b703          	ld	a4,696(a5)
    80003a48:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003a4a:	0023f717          	auipc	a4,0x23f
    80003a4e:	89670713          	addi	a4,a4,-1898 # 802422e0 <bcache+0x8268>
    80003a52:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a54:	2b87b703          	ld	a4,696(a5)
    80003a58:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a5a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a5e:	00236517          	auipc	a0,0x236
    80003a62:	61a50513          	addi	a0,a0,1562 # 8023a078 <bcache>
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	35c080e7          	jalr	860(ra) # 80000dc2 <release>
}
    80003a6e:	60e2                	ld	ra,24(sp)
    80003a70:	6442                	ld	s0,16(sp)
    80003a72:	64a2                	ld	s1,8(sp)
    80003a74:	6902                	ld	s2,0(sp)
    80003a76:	6105                	addi	sp,sp,32
    80003a78:	8082                	ret
    panic("brelse");
    80003a7a:	00005517          	auipc	a0,0x5
    80003a7e:	b8650513          	addi	a0,a0,-1146 # 80008600 <syscalls+0x110>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	abe080e7          	jalr	-1346(ra) # 80000540 <panic>

0000000080003a8a <bpin>:

void
bpin(struct buf *b) {
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	1000                	addi	s0,sp,32
    80003a94:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a96:	00236517          	auipc	a0,0x236
    80003a9a:	5e250513          	addi	a0,a0,1506 # 8023a078 <bcache>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	270080e7          	jalr	624(ra) # 80000d0e <acquire>
  b->referenceCount++;
    80003aa6:	40bc                	lw	a5,64(s1)
    80003aa8:	2785                	addiw	a5,a5,1
    80003aaa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003aac:	00236517          	auipc	a0,0x236
    80003ab0:	5cc50513          	addi	a0,a0,1484 # 8023a078 <bcache>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	30e080e7          	jalr	782(ra) # 80000dc2 <release>
}
    80003abc:	60e2                	ld	ra,24(sp)
    80003abe:	6442                	ld	s0,16(sp)
    80003ac0:	64a2                	ld	s1,8(sp)
    80003ac2:	6105                	addi	sp,sp,32
    80003ac4:	8082                	ret

0000000080003ac6 <bunpin>:

void
bunpin(struct buf *b) {
    80003ac6:	1101                	addi	sp,sp,-32
    80003ac8:	ec06                	sd	ra,24(sp)
    80003aca:	e822                	sd	s0,16(sp)
    80003acc:	e426                	sd	s1,8(sp)
    80003ace:	1000                	addi	s0,sp,32
    80003ad0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ad2:	00236517          	auipc	a0,0x236
    80003ad6:	5a650513          	addi	a0,a0,1446 # 8023a078 <bcache>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	234080e7          	jalr	564(ra) # 80000d0e <acquire>
  b->referenceCount--;
    80003ae2:	40bc                	lw	a5,64(s1)
    80003ae4:	37fd                	addiw	a5,a5,-1
    80003ae6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ae8:	00236517          	auipc	a0,0x236
    80003aec:	59050513          	addi	a0,a0,1424 # 8023a078 <bcache>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	2d2080e7          	jalr	722(ra) # 80000dc2 <release>
}
    80003af8:	60e2                	ld	ra,24(sp)
    80003afa:	6442                	ld	s0,16(sp)
    80003afc:	64a2                	ld	s1,8(sp)
    80003afe:	6105                	addi	sp,sp,32
    80003b00:	8082                	ret

0000000080003b02 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003b02:	1101                	addi	sp,sp,-32
    80003b04:	ec06                	sd	ra,24(sp)
    80003b06:	e822                	sd	s0,16(sp)
    80003b08:	e426                	sd	s1,8(sp)
    80003b0a:	e04a                	sd	s2,0(sp)
    80003b0c:	1000                	addi	s0,sp,32
    80003b0e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003b10:	00d5d59b          	srliw	a1,a1,0xd
    80003b14:	0023f797          	auipc	a5,0x23f
    80003b18:	c407a783          	lw	a5,-960(a5) # 80242754 <sb+0x1c>
    80003b1c:	9dbd                	addw	a1,a1,a5
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	d9e080e7          	jalr	-610(ra) # 800038bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003b26:	0074f713          	andi	a4,s1,7
    80003b2a:	4785                	li	a5,1
    80003b2c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003b30:	14ce                	slli	s1,s1,0x33
    80003b32:	90d9                	srli	s1,s1,0x36
    80003b34:	00950733          	add	a4,a0,s1
    80003b38:	05874703          	lbu	a4,88(a4)
    80003b3c:	00e7f6b3          	and	a3,a5,a4
    80003b40:	c69d                	beqz	a3,80003b6e <bfree+0x6c>
    80003b42:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003b44:	94aa                	add	s1,s1,a0
    80003b46:	fff7c793          	not	a5,a5
    80003b4a:	8f7d                	and	a4,a4,a5
    80003b4c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003b50:	00001097          	auipc	ra,0x1
    80003b54:	126080e7          	jalr	294(ra) # 80004c76 <log_write>
  brelse(bp);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	e92080e7          	jalr	-366(ra) # 800039ec <brelse>
}
    80003b62:	60e2                	ld	ra,24(sp)
    80003b64:	6442                	ld	s0,16(sp)
    80003b66:	64a2                	ld	s1,8(sp)
    80003b68:	6902                	ld	s2,0(sp)
    80003b6a:	6105                	addi	sp,sp,32
    80003b6c:	8082                	ret
    panic("freeing free block");
    80003b6e:	00005517          	auipc	a0,0x5
    80003b72:	a9a50513          	addi	a0,a0,-1382 # 80008608 <syscalls+0x118>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>

0000000080003b7e <balloc>:
{
    80003b7e:	711d                	addi	sp,sp,-96
    80003b80:	ec86                	sd	ra,88(sp)
    80003b82:	e8a2                	sd	s0,80(sp)
    80003b84:	e4a6                	sd	s1,72(sp)
    80003b86:	e0ca                	sd	s2,64(sp)
    80003b88:	fc4e                	sd	s3,56(sp)
    80003b8a:	f852                	sd	s4,48(sp)
    80003b8c:	f456                	sd	s5,40(sp)
    80003b8e:	f05a                	sd	s6,32(sp)
    80003b90:	ec5e                	sd	s7,24(sp)
    80003b92:	e862                	sd	s8,16(sp)
    80003b94:	e466                	sd	s9,8(sp)
    80003b96:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b98:	0023f797          	auipc	a5,0x23f
    80003b9c:	ba47a783          	lw	a5,-1116(a5) # 8024273c <sb+0x4>
    80003ba0:	cff5                	beqz	a5,80003c9c <balloc+0x11e>
    80003ba2:	8baa                	mv	s7,a0
    80003ba4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003ba6:	0023fb17          	auipc	s6,0x23f
    80003baa:	b92b0b13          	addi	s6,s6,-1134 # 80242738 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003bb0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bb2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003bb4:	6c89                	lui	s9,0x2
    80003bb6:	a061                	j	80003c3e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bb8:	97ca                	add	a5,a5,s2
    80003bba:	8e55                	or	a2,a2,a3
    80003bbc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00001097          	auipc	ra,0x1
    80003bc6:	0b4080e7          	jalr	180(ra) # 80004c76 <log_write>
        brelse(bp);
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	e20080e7          	jalr	-480(ra) # 800039ec <brelse>
  bp = bread(dev, bno);
    80003bd4:	85a6                	mv	a1,s1
    80003bd6:	855e                	mv	a0,s7
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	ce4080e7          	jalr	-796(ra) # 800038bc <bread>
    80003be0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003be2:	40000613          	li	a2,1024
    80003be6:	4581                	li	a1,0
    80003be8:	05850513          	addi	a0,a0,88
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	21e080e7          	jalr	542(ra) # 80000e0a <memset>
  log_write(bp);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	080080e7          	jalr	128(ra) # 80004c76 <log_write>
  brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	dec080e7          	jalr	-532(ra) # 800039ec <brelse>
}
    80003c08:	8526                	mv	a0,s1
    80003c0a:	60e6                	ld	ra,88(sp)
    80003c0c:	6446                	ld	s0,80(sp)
    80003c0e:	64a6                	ld	s1,72(sp)
    80003c10:	6906                	ld	s2,64(sp)
    80003c12:	79e2                	ld	s3,56(sp)
    80003c14:	7a42                	ld	s4,48(sp)
    80003c16:	7aa2                	ld	s5,40(sp)
    80003c18:	7b02                	ld	s6,32(sp)
    80003c1a:	6be2                	ld	s7,24(sp)
    80003c1c:	6c42                	ld	s8,16(sp)
    80003c1e:	6ca2                	ld	s9,8(sp)
    80003c20:	6125                	addi	sp,sp,96
    80003c22:	8082                	ret
    brelse(bp);
    80003c24:	854a                	mv	a0,s2
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	dc6080e7          	jalr	-570(ra) # 800039ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003c2e:	015c87bb          	addw	a5,s9,s5
    80003c32:	00078a9b          	sext.w	s5,a5
    80003c36:	004b2703          	lw	a4,4(s6)
    80003c3a:	06eaf163          	bgeu	s5,a4,80003c9c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003c3e:	41fad79b          	sraiw	a5,s5,0x1f
    80003c42:	0137d79b          	srliw	a5,a5,0x13
    80003c46:	015787bb          	addw	a5,a5,s5
    80003c4a:	40d7d79b          	sraiw	a5,a5,0xd
    80003c4e:	01cb2583          	lw	a1,28(s6)
    80003c52:	9dbd                	addw	a1,a1,a5
    80003c54:	855e                	mv	a0,s7
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	c66080e7          	jalr	-922(ra) # 800038bc <bread>
    80003c5e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c60:	004b2503          	lw	a0,4(s6)
    80003c64:	000a849b          	sext.w	s1,s5
    80003c68:	8762                	mv	a4,s8
    80003c6a:	faa4fde3          	bgeu	s1,a0,80003c24 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003c6e:	00777693          	andi	a3,a4,7
    80003c72:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003c76:	41f7579b          	sraiw	a5,a4,0x1f
    80003c7a:	01d7d79b          	srliw	a5,a5,0x1d
    80003c7e:	9fb9                	addw	a5,a5,a4
    80003c80:	4037d79b          	sraiw	a5,a5,0x3
    80003c84:	00f90633          	add	a2,s2,a5
    80003c88:	05864603          	lbu	a2,88(a2)
    80003c8c:	00c6f5b3          	and	a1,a3,a2
    80003c90:	d585                	beqz	a1,80003bb8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c92:	2705                	addiw	a4,a4,1
    80003c94:	2485                	addiw	s1,s1,1
    80003c96:	fd471ae3          	bne	a4,s4,80003c6a <balloc+0xec>
    80003c9a:	b769                	j	80003c24 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003c9c:	00005517          	auipc	a0,0x5
    80003ca0:	98450513          	addi	a0,a0,-1660 # 80008620 <syscalls+0x130>
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	8e6080e7          	jalr	-1818(ra) # 8000058a <printf>
  return 0;
    80003cac:	4481                	li	s1,0
    80003cae:	bfa9                	j	80003c08 <balloc+0x8a>

0000000080003cb0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003cb0:	7179                	addi	sp,sp,-48
    80003cb2:	f406                	sd	ra,40(sp)
    80003cb4:	f022                	sd	s0,32(sp)
    80003cb6:	ec26                	sd	s1,24(sp)
    80003cb8:	e84a                	sd	s2,16(sp)
    80003cba:	e44e                	sd	s3,8(sp)
    80003cbc:	e052                	sd	s4,0(sp)
    80003cbe:	1800                	addi	s0,sp,48
    80003cc0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003cc2:	47ad                	li	a5,11
    80003cc4:	02b7e863          	bltu	a5,a1,80003cf4 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003cc8:	02059793          	slli	a5,a1,0x20
    80003ccc:	01e7d593          	srli	a1,a5,0x1e
    80003cd0:	00b504b3          	add	s1,a0,a1
    80003cd4:	0504a903          	lw	s2,80(s1)
    80003cd8:	06091e63          	bnez	s2,80003d54 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003cdc:	4108                	lw	a0,0(a0)
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	ea0080e7          	jalr	-352(ra) # 80003b7e <balloc>
    80003ce6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003cea:	06090563          	beqz	s2,80003d54 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003cee:	0524a823          	sw	s2,80(s1)
    80003cf2:	a08d                	j	80003d54 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003cf4:	ff45849b          	addiw	s1,a1,-12
    80003cf8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003cfc:	0ff00793          	li	a5,255
    80003d00:	08e7e563          	bltu	a5,a4,80003d8a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003d04:	08052903          	lw	s2,128(a0)
    80003d08:	00091d63          	bnez	s2,80003d22 <bmap+0x72>
      addr = balloc(ip->dev);
    80003d0c:	4108                	lw	a0,0(a0)
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	e70080e7          	jalr	-400(ra) # 80003b7e <balloc>
    80003d16:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d1a:	02090d63          	beqz	s2,80003d54 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003d1e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003d22:	85ca                	mv	a1,s2
    80003d24:	0009a503          	lw	a0,0(s3)
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	b94080e7          	jalr	-1132(ra) # 800038bc <bread>
    80003d30:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003d32:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003d36:	02049713          	slli	a4,s1,0x20
    80003d3a:	01e75593          	srli	a1,a4,0x1e
    80003d3e:	00b784b3          	add	s1,a5,a1
    80003d42:	0004a903          	lw	s2,0(s1)
    80003d46:	02090063          	beqz	s2,80003d66 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003d4a:	8552                	mv	a0,s4
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	ca0080e7          	jalr	-864(ra) # 800039ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003d54:	854a                	mv	a0,s2
    80003d56:	70a2                	ld	ra,40(sp)
    80003d58:	7402                	ld	s0,32(sp)
    80003d5a:	64e2                	ld	s1,24(sp)
    80003d5c:	6942                	ld	s2,16(sp)
    80003d5e:	69a2                	ld	s3,8(sp)
    80003d60:	6a02                	ld	s4,0(sp)
    80003d62:	6145                	addi	sp,sp,48
    80003d64:	8082                	ret
      addr = balloc(ip->dev);
    80003d66:	0009a503          	lw	a0,0(s3)
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	e14080e7          	jalr	-492(ra) # 80003b7e <balloc>
    80003d72:	0005091b          	sext.w	s2,a0
      if(addr){
    80003d76:	fc090ae3          	beqz	s2,80003d4a <bmap+0x9a>
        a[bn] = addr;
    80003d7a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003d7e:	8552                	mv	a0,s4
    80003d80:	00001097          	auipc	ra,0x1
    80003d84:	ef6080e7          	jalr	-266(ra) # 80004c76 <log_write>
    80003d88:	b7c9                	j	80003d4a <bmap+0x9a>
  panic("bmap: out of range");
    80003d8a:	00005517          	auipc	a0,0x5
    80003d8e:	8ae50513          	addi	a0,a0,-1874 # 80008638 <syscalls+0x148>
    80003d92:	ffffc097          	auipc	ra,0xffffc
    80003d96:	7ae080e7          	jalr	1966(ra) # 80000540 <panic>

0000000080003d9a <iget>:
{
    80003d9a:	7179                	addi	sp,sp,-48
    80003d9c:	f406                	sd	ra,40(sp)
    80003d9e:	f022                	sd	s0,32(sp)
    80003da0:	ec26                	sd	s1,24(sp)
    80003da2:	e84a                	sd	s2,16(sp)
    80003da4:	e44e                	sd	s3,8(sp)
    80003da6:	e052                	sd	s4,0(sp)
    80003da8:	1800                	addi	s0,sp,48
    80003daa:	89aa                	mv	s3,a0
    80003dac:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003dae:	0023f517          	auipc	a0,0x23f
    80003db2:	9aa50513          	addi	a0,a0,-1622 # 80242758 <itable>
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	f58080e7          	jalr	-168(ra) # 80000d0e <acquire>
  empty = 0;
    80003dbe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003dc0:	0023f497          	auipc	s1,0x23f
    80003dc4:	9b048493          	addi	s1,s1,-1616 # 80242770 <itable+0x18>
    80003dc8:	00240697          	auipc	a3,0x240
    80003dcc:	43868693          	addi	a3,a3,1080 # 80244200 <log>
    80003dd0:	a039                	j	80003dde <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003dd2:	02090b63          	beqz	s2,80003e08 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003dd6:	08848493          	addi	s1,s1,136
    80003dda:	02d48a63          	beq	s1,a3,80003e0e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003dde:	449c                	lw	a5,8(s1)
    80003de0:	fef059e3          	blez	a5,80003dd2 <iget+0x38>
    80003de4:	4098                	lw	a4,0(s1)
    80003de6:	ff3716e3          	bne	a4,s3,80003dd2 <iget+0x38>
    80003dea:	40d8                	lw	a4,4(s1)
    80003dec:	ff4713e3          	bne	a4,s4,80003dd2 <iget+0x38>
      ip->ref++;
    80003df0:	2785                	addiw	a5,a5,1
    80003df2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003df4:	0023f517          	auipc	a0,0x23f
    80003df8:	96450513          	addi	a0,a0,-1692 # 80242758 <itable>
    80003dfc:	ffffd097          	auipc	ra,0xffffd
    80003e00:	fc6080e7          	jalr	-58(ra) # 80000dc2 <release>
      return ip;
    80003e04:	8926                	mv	s2,s1
    80003e06:	a03d                	j	80003e34 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e08:	f7f9                	bnez	a5,80003dd6 <iget+0x3c>
    80003e0a:	8926                	mv	s2,s1
    80003e0c:	b7e9                	j	80003dd6 <iget+0x3c>
  if(empty == 0)
    80003e0e:	02090c63          	beqz	s2,80003e46 <iget+0xac>
  ip->dev = dev;
    80003e12:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003e16:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003e1a:	4785                	li	a5,1
    80003e1c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003e20:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003e24:	0023f517          	auipc	a0,0x23f
    80003e28:	93450513          	addi	a0,a0,-1740 # 80242758 <itable>
    80003e2c:	ffffd097          	auipc	ra,0xffffd
    80003e30:	f96080e7          	jalr	-106(ra) # 80000dc2 <release>
}
    80003e34:	854a                	mv	a0,s2
    80003e36:	70a2                	ld	ra,40(sp)
    80003e38:	7402                	ld	s0,32(sp)
    80003e3a:	64e2                	ld	s1,24(sp)
    80003e3c:	6942                	ld	s2,16(sp)
    80003e3e:	69a2                	ld	s3,8(sp)
    80003e40:	6a02                	ld	s4,0(sp)
    80003e42:	6145                	addi	sp,sp,48
    80003e44:	8082                	ret
    panic("iget: no inodes");
    80003e46:	00005517          	auipc	a0,0x5
    80003e4a:	80a50513          	addi	a0,a0,-2038 # 80008650 <syscalls+0x160>
    80003e4e:	ffffc097          	auipc	ra,0xffffc
    80003e52:	6f2080e7          	jalr	1778(ra) # 80000540 <panic>

0000000080003e56 <fsinit>:
fsinit(int dev) {
    80003e56:	7179                	addi	sp,sp,-48
    80003e58:	f406                	sd	ra,40(sp)
    80003e5a:	f022                	sd	s0,32(sp)
    80003e5c:	ec26                	sd	s1,24(sp)
    80003e5e:	e84a                	sd	s2,16(sp)
    80003e60:	e44e                	sd	s3,8(sp)
    80003e62:	1800                	addi	s0,sp,48
    80003e64:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e66:	4585                	li	a1,1
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	a54080e7          	jalr	-1452(ra) # 800038bc <bread>
    80003e70:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003e72:	0023f997          	auipc	s3,0x23f
    80003e76:	8c698993          	addi	s3,s3,-1850 # 80242738 <sb>
    80003e7a:	02000613          	li	a2,32
    80003e7e:	05850593          	addi	a1,a0,88
    80003e82:	854e                	mv	a0,s3
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	fe2080e7          	jalr	-30(ra) # 80000e66 <memmove>
  brelse(bp);
    80003e8c:	8526                	mv	a0,s1
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	b5e080e7          	jalr	-1186(ra) # 800039ec <brelse>
  if(sb.magic != FSMAGIC)
    80003e96:	0009a703          	lw	a4,0(s3)
    80003e9a:	102037b7          	lui	a5,0x10203
    80003e9e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ea2:	02f71263          	bne	a4,a5,80003ec6 <fsinit+0x70>
  initlog(dev, &sb);
    80003ea6:	0023f597          	auipc	a1,0x23f
    80003eaa:	89258593          	addi	a1,a1,-1902 # 80242738 <sb>
    80003eae:	854a                	mv	a0,s2
    80003eb0:	00001097          	auipc	ra,0x1
    80003eb4:	b4a080e7          	jalr	-1206(ra) # 800049fa <initlog>
}
    80003eb8:	70a2                	ld	ra,40(sp)
    80003eba:	7402                	ld	s0,32(sp)
    80003ebc:	64e2                	ld	s1,24(sp)
    80003ebe:	6942                	ld	s2,16(sp)
    80003ec0:	69a2                	ld	s3,8(sp)
    80003ec2:	6145                	addi	sp,sp,48
    80003ec4:	8082                	ret
    panic("invalid file system");
    80003ec6:	00004517          	auipc	a0,0x4
    80003eca:	79a50513          	addi	a0,a0,1946 # 80008660 <syscalls+0x170>
    80003ece:	ffffc097          	auipc	ra,0xffffc
    80003ed2:	672080e7          	jalr	1650(ra) # 80000540 <panic>

0000000080003ed6 <iinit>:
{
    80003ed6:	7179                	addi	sp,sp,-48
    80003ed8:	f406                	sd	ra,40(sp)
    80003eda:	f022                	sd	s0,32(sp)
    80003edc:	ec26                	sd	s1,24(sp)
    80003ede:	e84a                	sd	s2,16(sp)
    80003ee0:	e44e                	sd	s3,8(sp)
    80003ee2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ee4:	00004597          	auipc	a1,0x4
    80003ee8:	79458593          	addi	a1,a1,1940 # 80008678 <syscalls+0x188>
    80003eec:	0023f517          	auipc	a0,0x23f
    80003ef0:	86c50513          	addi	a0,a0,-1940 # 80242758 <itable>
    80003ef4:	ffffd097          	auipc	ra,0xffffd
    80003ef8:	d8a080e7          	jalr	-630(ra) # 80000c7e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003efc:	0023f497          	auipc	s1,0x23f
    80003f00:	88448493          	addi	s1,s1,-1916 # 80242780 <itable+0x28>
    80003f04:	00240997          	auipc	s3,0x240
    80003f08:	30c98993          	addi	s3,s3,780 # 80244210 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003f0c:	00004917          	auipc	s2,0x4
    80003f10:	77490913          	addi	s2,s2,1908 # 80008680 <syscalls+0x190>
    80003f14:	85ca                	mv	a1,s2
    80003f16:	8526                	mv	a0,s1
    80003f18:	00001097          	auipc	ra,0x1
    80003f1c:	e42080e7          	jalr	-446(ra) # 80004d5a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003f20:	08848493          	addi	s1,s1,136
    80003f24:	ff3498e3          	bne	s1,s3,80003f14 <iinit+0x3e>
}
    80003f28:	70a2                	ld	ra,40(sp)
    80003f2a:	7402                	ld	s0,32(sp)
    80003f2c:	64e2                	ld	s1,24(sp)
    80003f2e:	6942                	ld	s2,16(sp)
    80003f30:	69a2                	ld	s3,8(sp)
    80003f32:	6145                	addi	sp,sp,48
    80003f34:	8082                	ret

0000000080003f36 <ialloc>:
{
    80003f36:	715d                	addi	sp,sp,-80
    80003f38:	e486                	sd	ra,72(sp)
    80003f3a:	e0a2                	sd	s0,64(sp)
    80003f3c:	fc26                	sd	s1,56(sp)
    80003f3e:	f84a                	sd	s2,48(sp)
    80003f40:	f44e                	sd	s3,40(sp)
    80003f42:	f052                	sd	s4,32(sp)
    80003f44:	ec56                	sd	s5,24(sp)
    80003f46:	e85a                	sd	s6,16(sp)
    80003f48:	e45e                	sd	s7,8(sp)
    80003f4a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f4c:	0023e717          	auipc	a4,0x23e
    80003f50:	7f872703          	lw	a4,2040(a4) # 80242744 <sb+0xc>
    80003f54:	4785                	li	a5,1
    80003f56:	04e7fa63          	bgeu	a5,a4,80003faa <ialloc+0x74>
    80003f5a:	8aaa                	mv	s5,a0
    80003f5c:	8bae                	mv	s7,a1
    80003f5e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003f60:	0023ea17          	auipc	s4,0x23e
    80003f64:	7d8a0a13          	addi	s4,s4,2008 # 80242738 <sb>
    80003f68:	00048b1b          	sext.w	s6,s1
    80003f6c:	0044d593          	srli	a1,s1,0x4
    80003f70:	018a2783          	lw	a5,24(s4)
    80003f74:	9dbd                	addw	a1,a1,a5
    80003f76:	8556                	mv	a0,s5
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	944080e7          	jalr	-1724(ra) # 800038bc <bread>
    80003f80:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003f82:	05850993          	addi	s3,a0,88
    80003f86:	00f4f793          	andi	a5,s1,15
    80003f8a:	079a                	slli	a5,a5,0x6
    80003f8c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f8e:	00099783          	lh	a5,0(s3)
    80003f92:	c3a1                	beqz	a5,80003fd2 <ialloc+0x9c>
    brelse(bp);
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	a58080e7          	jalr	-1448(ra) # 800039ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f9c:	0485                	addi	s1,s1,1
    80003f9e:	00ca2703          	lw	a4,12(s4)
    80003fa2:	0004879b          	sext.w	a5,s1
    80003fa6:	fce7e1e3          	bltu	a5,a4,80003f68 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003faa:	00004517          	auipc	a0,0x4
    80003fae:	6de50513          	addi	a0,a0,1758 # 80008688 <syscalls+0x198>
    80003fb2:	ffffc097          	auipc	ra,0xffffc
    80003fb6:	5d8080e7          	jalr	1496(ra) # 8000058a <printf>
  return 0;
    80003fba:	4501                	li	a0,0
}
    80003fbc:	60a6                	ld	ra,72(sp)
    80003fbe:	6406                	ld	s0,64(sp)
    80003fc0:	74e2                	ld	s1,56(sp)
    80003fc2:	7942                	ld	s2,48(sp)
    80003fc4:	79a2                	ld	s3,40(sp)
    80003fc6:	7a02                	ld	s4,32(sp)
    80003fc8:	6ae2                	ld	s5,24(sp)
    80003fca:	6b42                	ld	s6,16(sp)
    80003fcc:	6ba2                	ld	s7,8(sp)
    80003fce:	6161                	addi	sp,sp,80
    80003fd0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003fd2:	04000613          	li	a2,64
    80003fd6:	4581                	li	a1,0
    80003fd8:	854e                	mv	a0,s3
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	e30080e7          	jalr	-464(ra) # 80000e0a <memset>
      dip->type = type;
    80003fe2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	00001097          	auipc	ra,0x1
    80003fec:	c8e080e7          	jalr	-882(ra) # 80004c76 <log_write>
      brelse(bp);
    80003ff0:	854a                	mv	a0,s2
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	9fa080e7          	jalr	-1542(ra) # 800039ec <brelse>
      return iget(dev, inum);
    80003ffa:	85da                	mv	a1,s6
    80003ffc:	8556                	mv	a0,s5
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	d9c080e7          	jalr	-612(ra) # 80003d9a <iget>
    80004006:	bf5d                	j	80003fbc <ialloc+0x86>

0000000080004008 <iupdate>:
{
    80004008:	1101                	addi	sp,sp,-32
    8000400a:	ec06                	sd	ra,24(sp)
    8000400c:	e822                	sd	s0,16(sp)
    8000400e:	e426                	sd	s1,8(sp)
    80004010:	e04a                	sd	s2,0(sp)
    80004012:	1000                	addi	s0,sp,32
    80004014:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004016:	415c                	lw	a5,4(a0)
    80004018:	0047d79b          	srliw	a5,a5,0x4
    8000401c:	0023e597          	auipc	a1,0x23e
    80004020:	7345a583          	lw	a1,1844(a1) # 80242750 <sb+0x18>
    80004024:	9dbd                	addw	a1,a1,a5
    80004026:	4108                	lw	a0,0(a0)
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	894080e7          	jalr	-1900(ra) # 800038bc <bread>
    80004030:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004032:	05850793          	addi	a5,a0,88
    80004036:	40d8                	lw	a4,4(s1)
    80004038:	8b3d                	andi	a4,a4,15
    8000403a:	071a                	slli	a4,a4,0x6
    8000403c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000403e:	04449703          	lh	a4,68(s1)
    80004042:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80004046:	04649703          	lh	a4,70(s1)
    8000404a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000404e:	04849703          	lh	a4,72(s1)
    80004052:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80004056:	04a49703          	lh	a4,74(s1)
    8000405a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000405e:	44f8                	lw	a4,76(s1)
    80004060:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004062:	03400613          	li	a2,52
    80004066:	05048593          	addi	a1,s1,80
    8000406a:	00c78513          	addi	a0,a5,12
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	df8080e7          	jalr	-520(ra) # 80000e66 <memmove>
  log_write(bp);
    80004076:	854a                	mv	a0,s2
    80004078:	00001097          	auipc	ra,0x1
    8000407c:	bfe080e7          	jalr	-1026(ra) # 80004c76 <log_write>
  brelse(bp);
    80004080:	854a                	mv	a0,s2
    80004082:	00000097          	auipc	ra,0x0
    80004086:	96a080e7          	jalr	-1686(ra) # 800039ec <brelse>
}
    8000408a:	60e2                	ld	ra,24(sp)
    8000408c:	6442                	ld	s0,16(sp)
    8000408e:	64a2                	ld	s1,8(sp)
    80004090:	6902                	ld	s2,0(sp)
    80004092:	6105                	addi	sp,sp,32
    80004094:	8082                	ret

0000000080004096 <idup>:
{
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	e426                	sd	s1,8(sp)
    8000409e:	1000                	addi	s0,sp,32
    800040a0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040a2:	0023e517          	auipc	a0,0x23e
    800040a6:	6b650513          	addi	a0,a0,1718 # 80242758 <itable>
    800040aa:	ffffd097          	auipc	ra,0xffffd
    800040ae:	c64080e7          	jalr	-924(ra) # 80000d0e <acquire>
  ip->ref++;
    800040b2:	449c                	lw	a5,8(s1)
    800040b4:	2785                	addiw	a5,a5,1
    800040b6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040b8:	0023e517          	auipc	a0,0x23e
    800040bc:	6a050513          	addi	a0,a0,1696 # 80242758 <itable>
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	d02080e7          	jalr	-766(ra) # 80000dc2 <release>
}
    800040c8:	8526                	mv	a0,s1
    800040ca:	60e2                	ld	ra,24(sp)
    800040cc:	6442                	ld	s0,16(sp)
    800040ce:	64a2                	ld	s1,8(sp)
    800040d0:	6105                	addi	sp,sp,32
    800040d2:	8082                	ret

00000000800040d4 <ilock>:
{
    800040d4:	1101                	addi	sp,sp,-32
    800040d6:	ec06                	sd	ra,24(sp)
    800040d8:	e822                	sd	s0,16(sp)
    800040da:	e426                	sd	s1,8(sp)
    800040dc:	e04a                	sd	s2,0(sp)
    800040de:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800040e0:	c115                	beqz	a0,80004104 <ilock+0x30>
    800040e2:	84aa                	mv	s1,a0
    800040e4:	451c                	lw	a5,8(a0)
    800040e6:	00f05f63          	blez	a5,80004104 <ilock+0x30>
  acquiresleep(&ip->lock);
    800040ea:	0541                	addi	a0,a0,16
    800040ec:	00001097          	auipc	ra,0x1
    800040f0:	ca8080e7          	jalr	-856(ra) # 80004d94 <acquiresleep>
  if(ip->valid == 0){
    800040f4:	40bc                	lw	a5,64(s1)
    800040f6:	cf99                	beqz	a5,80004114 <ilock+0x40>
}
    800040f8:	60e2                	ld	ra,24(sp)
    800040fa:	6442                	ld	s0,16(sp)
    800040fc:	64a2                	ld	s1,8(sp)
    800040fe:	6902                	ld	s2,0(sp)
    80004100:	6105                	addi	sp,sp,32
    80004102:	8082                	ret
    panic("ilock");
    80004104:	00004517          	auipc	a0,0x4
    80004108:	59c50513          	addi	a0,a0,1436 # 800086a0 <syscalls+0x1b0>
    8000410c:	ffffc097          	auipc	ra,0xffffc
    80004110:	434080e7          	jalr	1076(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004114:	40dc                	lw	a5,4(s1)
    80004116:	0047d79b          	srliw	a5,a5,0x4
    8000411a:	0023e597          	auipc	a1,0x23e
    8000411e:	6365a583          	lw	a1,1590(a1) # 80242750 <sb+0x18>
    80004122:	9dbd                	addw	a1,a1,a5
    80004124:	4088                	lw	a0,0(s1)
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	796080e7          	jalr	1942(ra) # 800038bc <bread>
    8000412e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004130:	05850593          	addi	a1,a0,88
    80004134:	40dc                	lw	a5,4(s1)
    80004136:	8bbd                	andi	a5,a5,15
    80004138:	079a                	slli	a5,a5,0x6
    8000413a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000413c:	00059783          	lh	a5,0(a1)
    80004140:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004144:	00259783          	lh	a5,2(a1)
    80004148:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000414c:	00459783          	lh	a5,4(a1)
    80004150:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004154:	00659783          	lh	a5,6(a1)
    80004158:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000415c:	459c                	lw	a5,8(a1)
    8000415e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004160:	03400613          	li	a2,52
    80004164:	05b1                	addi	a1,a1,12
    80004166:	05048513          	addi	a0,s1,80
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	cfc080e7          	jalr	-772(ra) # 80000e66 <memmove>
    brelse(bp);
    80004172:	854a                	mv	a0,s2
    80004174:	00000097          	auipc	ra,0x0
    80004178:	878080e7          	jalr	-1928(ra) # 800039ec <brelse>
    ip->valid = 1;
    8000417c:	4785                	li	a5,1
    8000417e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004180:	04449783          	lh	a5,68(s1)
    80004184:	fbb5                	bnez	a5,800040f8 <ilock+0x24>
      panic("ilock: no type");
    80004186:	00004517          	auipc	a0,0x4
    8000418a:	52250513          	addi	a0,a0,1314 # 800086a8 <syscalls+0x1b8>
    8000418e:	ffffc097          	auipc	ra,0xffffc
    80004192:	3b2080e7          	jalr	946(ra) # 80000540 <panic>

0000000080004196 <iunlock>:
{
    80004196:	1101                	addi	sp,sp,-32
    80004198:	ec06                	sd	ra,24(sp)
    8000419a:	e822                	sd	s0,16(sp)
    8000419c:	e426                	sd	s1,8(sp)
    8000419e:	e04a                	sd	s2,0(sp)
    800041a0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800041a2:	c905                	beqz	a0,800041d2 <iunlock+0x3c>
    800041a4:	84aa                	mv	s1,a0
    800041a6:	01050913          	addi	s2,a0,16
    800041aa:	854a                	mv	a0,s2
    800041ac:	00001097          	auipc	ra,0x1
    800041b0:	c82080e7          	jalr	-894(ra) # 80004e2e <holdingsleep>
    800041b4:	cd19                	beqz	a0,800041d2 <iunlock+0x3c>
    800041b6:	449c                	lw	a5,8(s1)
    800041b8:	00f05d63          	blez	a5,800041d2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800041bc:	854a                	mv	a0,s2
    800041be:	00001097          	auipc	ra,0x1
    800041c2:	c2c080e7          	jalr	-980(ra) # 80004dea <releasesleep>
}
    800041c6:	60e2                	ld	ra,24(sp)
    800041c8:	6442                	ld	s0,16(sp)
    800041ca:	64a2                	ld	s1,8(sp)
    800041cc:	6902                	ld	s2,0(sp)
    800041ce:	6105                	addi	sp,sp,32
    800041d0:	8082                	ret
    panic("iunlock");
    800041d2:	00004517          	auipc	a0,0x4
    800041d6:	4e650513          	addi	a0,a0,1254 # 800086b8 <syscalls+0x1c8>
    800041da:	ffffc097          	auipc	ra,0xffffc
    800041de:	366080e7          	jalr	870(ra) # 80000540 <panic>

00000000800041e2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800041e2:	7179                	addi	sp,sp,-48
    800041e4:	f406                	sd	ra,40(sp)
    800041e6:	f022                	sd	s0,32(sp)
    800041e8:	ec26                	sd	s1,24(sp)
    800041ea:	e84a                	sd	s2,16(sp)
    800041ec:	e44e                	sd	s3,8(sp)
    800041ee:	e052                	sd	s4,0(sp)
    800041f0:	1800                	addi	s0,sp,48
    800041f2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800041f4:	05050493          	addi	s1,a0,80
    800041f8:	08050913          	addi	s2,a0,128
    800041fc:	a021                	j	80004204 <itrunc+0x22>
    800041fe:	0491                	addi	s1,s1,4
    80004200:	01248d63          	beq	s1,s2,8000421a <itrunc+0x38>
    if(ip->addrs[i]){
    80004204:	408c                	lw	a1,0(s1)
    80004206:	dde5                	beqz	a1,800041fe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004208:	0009a503          	lw	a0,0(s3)
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	8f6080e7          	jalr	-1802(ra) # 80003b02 <bfree>
      ip->addrs[i] = 0;
    80004214:	0004a023          	sw	zero,0(s1)
    80004218:	b7dd                	j	800041fe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000421a:	0809a583          	lw	a1,128(s3)
    8000421e:	e185                	bnez	a1,8000423e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004220:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004224:	854e                	mv	a0,s3
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	de2080e7          	jalr	-542(ra) # 80004008 <iupdate>
}
    8000422e:	70a2                	ld	ra,40(sp)
    80004230:	7402                	ld	s0,32(sp)
    80004232:	64e2                	ld	s1,24(sp)
    80004234:	6942                	ld	s2,16(sp)
    80004236:	69a2                	ld	s3,8(sp)
    80004238:	6a02                	ld	s4,0(sp)
    8000423a:	6145                	addi	sp,sp,48
    8000423c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000423e:	0009a503          	lw	a0,0(s3)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	67a080e7          	jalr	1658(ra) # 800038bc <bread>
    8000424a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000424c:	05850493          	addi	s1,a0,88
    80004250:	45850913          	addi	s2,a0,1112
    80004254:	a021                	j	8000425c <itrunc+0x7a>
    80004256:	0491                	addi	s1,s1,4
    80004258:	01248b63          	beq	s1,s2,8000426e <itrunc+0x8c>
      if(a[j])
    8000425c:	408c                	lw	a1,0(s1)
    8000425e:	dde5                	beqz	a1,80004256 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004260:	0009a503          	lw	a0,0(s3)
    80004264:	00000097          	auipc	ra,0x0
    80004268:	89e080e7          	jalr	-1890(ra) # 80003b02 <bfree>
    8000426c:	b7ed                	j	80004256 <itrunc+0x74>
    brelse(bp);
    8000426e:	8552                	mv	a0,s4
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	77c080e7          	jalr	1916(ra) # 800039ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004278:	0809a583          	lw	a1,128(s3)
    8000427c:	0009a503          	lw	a0,0(s3)
    80004280:	00000097          	auipc	ra,0x0
    80004284:	882080e7          	jalr	-1918(ra) # 80003b02 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004288:	0809a023          	sw	zero,128(s3)
    8000428c:	bf51                	j	80004220 <itrunc+0x3e>

000000008000428e <iput>:
{
    8000428e:	1101                	addi	sp,sp,-32
    80004290:	ec06                	sd	ra,24(sp)
    80004292:	e822                	sd	s0,16(sp)
    80004294:	e426                	sd	s1,8(sp)
    80004296:	e04a                	sd	s2,0(sp)
    80004298:	1000                	addi	s0,sp,32
    8000429a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000429c:	0023e517          	auipc	a0,0x23e
    800042a0:	4bc50513          	addi	a0,a0,1212 # 80242758 <itable>
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	a6a080e7          	jalr	-1430(ra) # 80000d0e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042ac:	4498                	lw	a4,8(s1)
    800042ae:	4785                	li	a5,1
    800042b0:	02f70363          	beq	a4,a5,800042d6 <iput+0x48>
  ip->ref--;
    800042b4:	449c                	lw	a5,8(s1)
    800042b6:	37fd                	addiw	a5,a5,-1
    800042b8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042ba:	0023e517          	auipc	a0,0x23e
    800042be:	49e50513          	addi	a0,a0,1182 # 80242758 <itable>
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	b00080e7          	jalr	-1280(ra) # 80000dc2 <release>
}
    800042ca:	60e2                	ld	ra,24(sp)
    800042cc:	6442                	ld	s0,16(sp)
    800042ce:	64a2                	ld	s1,8(sp)
    800042d0:	6902                	ld	s2,0(sp)
    800042d2:	6105                	addi	sp,sp,32
    800042d4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042d6:	40bc                	lw	a5,64(s1)
    800042d8:	dff1                	beqz	a5,800042b4 <iput+0x26>
    800042da:	04a49783          	lh	a5,74(s1)
    800042de:	fbf9                	bnez	a5,800042b4 <iput+0x26>
    acquiresleep(&ip->lock);
    800042e0:	01048913          	addi	s2,s1,16
    800042e4:	854a                	mv	a0,s2
    800042e6:	00001097          	auipc	ra,0x1
    800042ea:	aae080e7          	jalr	-1362(ra) # 80004d94 <acquiresleep>
    release(&itable.lock);
    800042ee:	0023e517          	auipc	a0,0x23e
    800042f2:	46a50513          	addi	a0,a0,1130 # 80242758 <itable>
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	acc080e7          	jalr	-1332(ra) # 80000dc2 <release>
    itrunc(ip);
    800042fe:	8526                	mv	a0,s1
    80004300:	00000097          	auipc	ra,0x0
    80004304:	ee2080e7          	jalr	-286(ra) # 800041e2 <itrunc>
    ip->type = 0;
    80004308:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000430c:	8526                	mv	a0,s1
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	cfa080e7          	jalr	-774(ra) # 80004008 <iupdate>
    ip->valid = 0;
    80004316:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000431a:	854a                	mv	a0,s2
    8000431c:	00001097          	auipc	ra,0x1
    80004320:	ace080e7          	jalr	-1330(ra) # 80004dea <releasesleep>
    acquire(&itable.lock);
    80004324:	0023e517          	auipc	a0,0x23e
    80004328:	43450513          	addi	a0,a0,1076 # 80242758 <itable>
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	9e2080e7          	jalr	-1566(ra) # 80000d0e <acquire>
    80004334:	b741                	j	800042b4 <iput+0x26>

0000000080004336 <iunlockput>:
{
    80004336:	1101                	addi	sp,sp,-32
    80004338:	ec06                	sd	ra,24(sp)
    8000433a:	e822                	sd	s0,16(sp)
    8000433c:	e426                	sd	s1,8(sp)
    8000433e:	1000                	addi	s0,sp,32
    80004340:	84aa                	mv	s1,a0
  iunlock(ip);
    80004342:	00000097          	auipc	ra,0x0
    80004346:	e54080e7          	jalr	-428(ra) # 80004196 <iunlock>
  iput(ip);
    8000434a:	8526                	mv	a0,s1
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	f42080e7          	jalr	-190(ra) # 8000428e <iput>
}
    80004354:	60e2                	ld	ra,24(sp)
    80004356:	6442                	ld	s0,16(sp)
    80004358:	64a2                	ld	s1,8(sp)
    8000435a:	6105                	addi	sp,sp,32
    8000435c:	8082                	ret

000000008000435e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000435e:	1141                	addi	sp,sp,-16
    80004360:	e422                	sd	s0,8(sp)
    80004362:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004364:	411c                	lw	a5,0(a0)
    80004366:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004368:	415c                	lw	a5,4(a0)
    8000436a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000436c:	04451783          	lh	a5,68(a0)
    80004370:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004374:	04a51783          	lh	a5,74(a0)
    80004378:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000437c:	04c56783          	lwu	a5,76(a0)
    80004380:	e99c                	sd	a5,16(a1)
}
    80004382:	6422                	ld	s0,8(sp)
    80004384:	0141                	addi	sp,sp,16
    80004386:	8082                	ret

0000000080004388 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004388:	457c                	lw	a5,76(a0)
    8000438a:	0ed7e963          	bltu	a5,a3,8000447c <readi+0xf4>
{
    8000438e:	7159                	addi	sp,sp,-112
    80004390:	f486                	sd	ra,104(sp)
    80004392:	f0a2                	sd	s0,96(sp)
    80004394:	eca6                	sd	s1,88(sp)
    80004396:	e8ca                	sd	s2,80(sp)
    80004398:	e4ce                	sd	s3,72(sp)
    8000439a:	e0d2                	sd	s4,64(sp)
    8000439c:	fc56                	sd	s5,56(sp)
    8000439e:	f85a                	sd	s6,48(sp)
    800043a0:	f45e                	sd	s7,40(sp)
    800043a2:	f062                	sd	s8,32(sp)
    800043a4:	ec66                	sd	s9,24(sp)
    800043a6:	e86a                	sd	s10,16(sp)
    800043a8:	e46e                	sd	s11,8(sp)
    800043aa:	1880                	addi	s0,sp,112
    800043ac:	8b2a                	mv	s6,a0
    800043ae:	8bae                	mv	s7,a1
    800043b0:	8a32                	mv	s4,a2
    800043b2:	84b6                	mv	s1,a3
    800043b4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800043b6:	9f35                	addw	a4,a4,a3
    return 0;
    800043b8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800043ba:	0ad76063          	bltu	a4,a3,8000445a <readi+0xd2>
  if(off + n > ip->size)
    800043be:	00e7f463          	bgeu	a5,a4,800043c6 <readi+0x3e>
    n = ip->size - off;
    800043c2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043c6:	0a0a8963          	beqz	s5,80004478 <readi+0xf0>
    800043ca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800043cc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800043d0:	5c7d                	li	s8,-1
    800043d2:	a82d                	j	8000440c <readi+0x84>
    800043d4:	020d1d93          	slli	s11,s10,0x20
    800043d8:	020ddd93          	srli	s11,s11,0x20
    800043dc:	05890613          	addi	a2,s2,88
    800043e0:	86ee                	mv	a3,s11
    800043e2:	963a                	add	a2,a2,a4
    800043e4:	85d2                	mv	a1,s4
    800043e6:	855e                	mv	a0,s7
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	60a080e7          	jalr	1546(ra) # 800029f2 <either_copyout>
    800043f0:	05850d63          	beq	a0,s8,8000444a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800043f4:	854a                	mv	a0,s2
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	5f6080e7          	jalr	1526(ra) # 800039ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043fe:	013d09bb          	addw	s3,s10,s3
    80004402:	009d04bb          	addw	s1,s10,s1
    80004406:	9a6e                	add	s4,s4,s11
    80004408:	0559f763          	bgeu	s3,s5,80004456 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000440c:	00a4d59b          	srliw	a1,s1,0xa
    80004410:	855a                	mv	a0,s6
    80004412:	00000097          	auipc	ra,0x0
    80004416:	89e080e7          	jalr	-1890(ra) # 80003cb0 <bmap>
    8000441a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000441e:	cd85                	beqz	a1,80004456 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004420:	000b2503          	lw	a0,0(s6)
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	498080e7          	jalr	1176(ra) # 800038bc <bread>
    8000442c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000442e:	3ff4f713          	andi	a4,s1,1023
    80004432:	40ec87bb          	subw	a5,s9,a4
    80004436:	413a86bb          	subw	a3,s5,s3
    8000443a:	8d3e                	mv	s10,a5
    8000443c:	2781                	sext.w	a5,a5
    8000443e:	0006861b          	sext.w	a2,a3
    80004442:	f8f679e3          	bgeu	a2,a5,800043d4 <readi+0x4c>
    80004446:	8d36                	mv	s10,a3
    80004448:	b771                	j	800043d4 <readi+0x4c>
      brelse(bp);
    8000444a:	854a                	mv	a0,s2
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	5a0080e7          	jalr	1440(ra) # 800039ec <brelse>
      tot = -1;
    80004454:	59fd                	li	s3,-1
  }
  return tot;
    80004456:	0009851b          	sext.w	a0,s3
}
    8000445a:	70a6                	ld	ra,104(sp)
    8000445c:	7406                	ld	s0,96(sp)
    8000445e:	64e6                	ld	s1,88(sp)
    80004460:	6946                	ld	s2,80(sp)
    80004462:	69a6                	ld	s3,72(sp)
    80004464:	6a06                	ld	s4,64(sp)
    80004466:	7ae2                	ld	s5,56(sp)
    80004468:	7b42                	ld	s6,48(sp)
    8000446a:	7ba2                	ld	s7,40(sp)
    8000446c:	7c02                	ld	s8,32(sp)
    8000446e:	6ce2                	ld	s9,24(sp)
    80004470:	6d42                	ld	s10,16(sp)
    80004472:	6da2                	ld	s11,8(sp)
    80004474:	6165                	addi	sp,sp,112
    80004476:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004478:	89d6                	mv	s3,s5
    8000447a:	bff1                	j	80004456 <readi+0xce>
    return 0;
    8000447c:	4501                	li	a0,0
}
    8000447e:	8082                	ret

0000000080004480 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004480:	457c                	lw	a5,76(a0)
    80004482:	10d7e863          	bltu	a5,a3,80004592 <writei+0x112>
{
    80004486:	7159                	addi	sp,sp,-112
    80004488:	f486                	sd	ra,104(sp)
    8000448a:	f0a2                	sd	s0,96(sp)
    8000448c:	eca6                	sd	s1,88(sp)
    8000448e:	e8ca                	sd	s2,80(sp)
    80004490:	e4ce                	sd	s3,72(sp)
    80004492:	e0d2                	sd	s4,64(sp)
    80004494:	fc56                	sd	s5,56(sp)
    80004496:	f85a                	sd	s6,48(sp)
    80004498:	f45e                	sd	s7,40(sp)
    8000449a:	f062                	sd	s8,32(sp)
    8000449c:	ec66                	sd	s9,24(sp)
    8000449e:	e86a                	sd	s10,16(sp)
    800044a0:	e46e                	sd	s11,8(sp)
    800044a2:	1880                	addi	s0,sp,112
    800044a4:	8aaa                	mv	s5,a0
    800044a6:	8bae                	mv	s7,a1
    800044a8:	8a32                	mv	s4,a2
    800044aa:	8936                	mv	s2,a3
    800044ac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800044ae:	00e687bb          	addw	a5,a3,a4
    800044b2:	0ed7e263          	bltu	a5,a3,80004596 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800044b6:	00043737          	lui	a4,0x43
    800044ba:	0ef76063          	bltu	a4,a5,8000459a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044be:	0c0b0863          	beqz	s6,8000458e <writei+0x10e>
    800044c2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800044c4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800044c8:	5c7d                	li	s8,-1
    800044ca:	a091                	j	8000450e <writei+0x8e>
    800044cc:	020d1d93          	slli	s11,s10,0x20
    800044d0:	020ddd93          	srli	s11,s11,0x20
    800044d4:	05848513          	addi	a0,s1,88
    800044d8:	86ee                	mv	a3,s11
    800044da:	8652                	mv	a2,s4
    800044dc:	85de                	mv	a1,s7
    800044de:	953a                	add	a0,a0,a4
    800044e0:	ffffe097          	auipc	ra,0xffffe
    800044e4:	568080e7          	jalr	1384(ra) # 80002a48 <either_copyin>
    800044e8:	07850263          	beq	a0,s8,8000454c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800044ec:	8526                	mv	a0,s1
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	788080e7          	jalr	1928(ra) # 80004c76 <log_write>
    brelse(bp);
    800044f6:	8526                	mv	a0,s1
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	4f4080e7          	jalr	1268(ra) # 800039ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004500:	013d09bb          	addw	s3,s10,s3
    80004504:	012d093b          	addw	s2,s10,s2
    80004508:	9a6e                	add	s4,s4,s11
    8000450a:	0569f663          	bgeu	s3,s6,80004556 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000450e:	00a9559b          	srliw	a1,s2,0xa
    80004512:	8556                	mv	a0,s5
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	79c080e7          	jalr	1948(ra) # 80003cb0 <bmap>
    8000451c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004520:	c99d                	beqz	a1,80004556 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004522:	000aa503          	lw	a0,0(s5)
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	396080e7          	jalr	918(ra) # 800038bc <bread>
    8000452e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004530:	3ff97713          	andi	a4,s2,1023
    80004534:	40ec87bb          	subw	a5,s9,a4
    80004538:	413b06bb          	subw	a3,s6,s3
    8000453c:	8d3e                	mv	s10,a5
    8000453e:	2781                	sext.w	a5,a5
    80004540:	0006861b          	sext.w	a2,a3
    80004544:	f8f674e3          	bgeu	a2,a5,800044cc <writei+0x4c>
    80004548:	8d36                	mv	s10,a3
    8000454a:	b749                	j	800044cc <writei+0x4c>
      brelse(bp);
    8000454c:	8526                	mv	a0,s1
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	49e080e7          	jalr	1182(ra) # 800039ec <brelse>
  }

  if(off > ip->size)
    80004556:	04caa783          	lw	a5,76(s5)
    8000455a:	0127f463          	bgeu	a5,s2,80004562 <writei+0xe2>
    ip->size = off;
    8000455e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004562:	8556                	mv	a0,s5
    80004564:	00000097          	auipc	ra,0x0
    80004568:	aa4080e7          	jalr	-1372(ra) # 80004008 <iupdate>

  return tot;
    8000456c:	0009851b          	sext.w	a0,s3
}
    80004570:	70a6                	ld	ra,104(sp)
    80004572:	7406                	ld	s0,96(sp)
    80004574:	64e6                	ld	s1,88(sp)
    80004576:	6946                	ld	s2,80(sp)
    80004578:	69a6                	ld	s3,72(sp)
    8000457a:	6a06                	ld	s4,64(sp)
    8000457c:	7ae2                	ld	s5,56(sp)
    8000457e:	7b42                	ld	s6,48(sp)
    80004580:	7ba2                	ld	s7,40(sp)
    80004582:	7c02                	ld	s8,32(sp)
    80004584:	6ce2                	ld	s9,24(sp)
    80004586:	6d42                	ld	s10,16(sp)
    80004588:	6da2                	ld	s11,8(sp)
    8000458a:	6165                	addi	sp,sp,112
    8000458c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000458e:	89da                	mv	s3,s6
    80004590:	bfc9                	j	80004562 <writei+0xe2>
    return -1;
    80004592:	557d                	li	a0,-1
}
    80004594:	8082                	ret
    return -1;
    80004596:	557d                	li	a0,-1
    80004598:	bfe1                	j	80004570 <writei+0xf0>
    return -1;
    8000459a:	557d                	li	a0,-1
    8000459c:	bfd1                	j	80004570 <writei+0xf0>

000000008000459e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000459e:	1141                	addi	sp,sp,-16
    800045a0:	e406                	sd	ra,8(sp)
    800045a2:	e022                	sd	s0,0(sp)
    800045a4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800045a6:	4639                	li	a2,14
    800045a8:	ffffd097          	auipc	ra,0xffffd
    800045ac:	932080e7          	jalr	-1742(ra) # 80000eda <strncmp>
}
    800045b0:	60a2                	ld	ra,8(sp)
    800045b2:	6402                	ld	s0,0(sp)
    800045b4:	0141                	addi	sp,sp,16
    800045b6:	8082                	ret

00000000800045b8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800045b8:	7139                	addi	sp,sp,-64
    800045ba:	fc06                	sd	ra,56(sp)
    800045bc:	f822                	sd	s0,48(sp)
    800045be:	f426                	sd	s1,40(sp)
    800045c0:	f04a                	sd	s2,32(sp)
    800045c2:	ec4e                	sd	s3,24(sp)
    800045c4:	e852                	sd	s4,16(sp)
    800045c6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800045c8:	04451703          	lh	a4,68(a0)
    800045cc:	4785                	li	a5,1
    800045ce:	00f71a63          	bne	a4,a5,800045e2 <dirlookup+0x2a>
    800045d2:	892a                	mv	s2,a0
    800045d4:	89ae                	mv	s3,a1
    800045d6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800045d8:	457c                	lw	a5,76(a0)
    800045da:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800045dc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045de:	e79d                	bnez	a5,8000460c <dirlookup+0x54>
    800045e0:	a8a5                	j	80004658 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800045e2:	00004517          	auipc	a0,0x4
    800045e6:	0de50513          	addi	a0,a0,222 # 800086c0 <syscalls+0x1d0>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("dirlookup read");
    800045f2:	00004517          	auipc	a0,0x4
    800045f6:	0e650513          	addi	a0,a0,230 # 800086d8 <syscalls+0x1e8>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004602:	24c1                	addiw	s1,s1,16
    80004604:	04c92783          	lw	a5,76(s2)
    80004608:	04f4f763          	bgeu	s1,a5,80004656 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000460c:	4741                	li	a4,16
    8000460e:	86a6                	mv	a3,s1
    80004610:	fc040613          	addi	a2,s0,-64
    80004614:	4581                	li	a1,0
    80004616:	854a                	mv	a0,s2
    80004618:	00000097          	auipc	ra,0x0
    8000461c:	d70080e7          	jalr	-656(ra) # 80004388 <readi>
    80004620:	47c1                	li	a5,16
    80004622:	fcf518e3          	bne	a0,a5,800045f2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004626:	fc045783          	lhu	a5,-64(s0)
    8000462a:	dfe1                	beqz	a5,80004602 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000462c:	fc240593          	addi	a1,s0,-62
    80004630:	854e                	mv	a0,s3
    80004632:	00000097          	auipc	ra,0x0
    80004636:	f6c080e7          	jalr	-148(ra) # 8000459e <namecmp>
    8000463a:	f561                	bnez	a0,80004602 <dirlookup+0x4a>
      if(poff)
    8000463c:	000a0463          	beqz	s4,80004644 <dirlookup+0x8c>
        *poff = off;
    80004640:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004644:	fc045583          	lhu	a1,-64(s0)
    80004648:	00092503          	lw	a0,0(s2)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	74e080e7          	jalr	1870(ra) # 80003d9a <iget>
    80004654:	a011                	j	80004658 <dirlookup+0xa0>
  return 0;
    80004656:	4501                	li	a0,0
}
    80004658:	70e2                	ld	ra,56(sp)
    8000465a:	7442                	ld	s0,48(sp)
    8000465c:	74a2                	ld	s1,40(sp)
    8000465e:	7902                	ld	s2,32(sp)
    80004660:	69e2                	ld	s3,24(sp)
    80004662:	6a42                	ld	s4,16(sp)
    80004664:	6121                	addi	sp,sp,64
    80004666:	8082                	ret

0000000080004668 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004668:	711d                	addi	sp,sp,-96
    8000466a:	ec86                	sd	ra,88(sp)
    8000466c:	e8a2                	sd	s0,80(sp)
    8000466e:	e4a6                	sd	s1,72(sp)
    80004670:	e0ca                	sd	s2,64(sp)
    80004672:	fc4e                	sd	s3,56(sp)
    80004674:	f852                	sd	s4,48(sp)
    80004676:	f456                	sd	s5,40(sp)
    80004678:	f05a                	sd	s6,32(sp)
    8000467a:	ec5e                	sd	s7,24(sp)
    8000467c:	e862                	sd	s8,16(sp)
    8000467e:	e466                	sd	s9,8(sp)
    80004680:	e06a                	sd	s10,0(sp)
    80004682:	1080                	addi	s0,sp,96
    80004684:	84aa                	mv	s1,a0
    80004686:	8b2e                	mv	s6,a1
    80004688:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000468a:	00054703          	lbu	a4,0(a0)
    8000468e:	02f00793          	li	a5,47
    80004692:	02f70363          	beq	a4,a5,800046b8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004696:	ffffd097          	auipc	ra,0xffffd
    8000469a:	654080e7          	jalr	1620(ra) # 80001cea <myproc>
    8000469e:	15053503          	ld	a0,336(a0)
    800046a2:	00000097          	auipc	ra,0x0
    800046a6:	9f4080e7          	jalr	-1548(ra) # 80004096 <idup>
    800046aa:	8a2a                	mv	s4,a0
  while(*path == '/')
    800046ac:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800046b0:	4cb5                	li	s9,13
  len = path - s;
    800046b2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800046b4:	4c05                	li	s8,1
    800046b6:	a87d                	j	80004774 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800046b8:	4585                	li	a1,1
    800046ba:	4505                	li	a0,1
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	6de080e7          	jalr	1758(ra) # 80003d9a <iget>
    800046c4:	8a2a                	mv	s4,a0
    800046c6:	b7dd                	j	800046ac <namex+0x44>
      iunlockput(ip);
    800046c8:	8552                	mv	a0,s4
    800046ca:	00000097          	auipc	ra,0x0
    800046ce:	c6c080e7          	jalr	-916(ra) # 80004336 <iunlockput>
      return 0;
    800046d2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800046d4:	8552                	mv	a0,s4
    800046d6:	60e6                	ld	ra,88(sp)
    800046d8:	6446                	ld	s0,80(sp)
    800046da:	64a6                	ld	s1,72(sp)
    800046dc:	6906                	ld	s2,64(sp)
    800046de:	79e2                	ld	s3,56(sp)
    800046e0:	7a42                	ld	s4,48(sp)
    800046e2:	7aa2                	ld	s5,40(sp)
    800046e4:	7b02                	ld	s6,32(sp)
    800046e6:	6be2                	ld	s7,24(sp)
    800046e8:	6c42                	ld	s8,16(sp)
    800046ea:	6ca2                	ld	s9,8(sp)
    800046ec:	6d02                	ld	s10,0(sp)
    800046ee:	6125                	addi	sp,sp,96
    800046f0:	8082                	ret
      iunlock(ip);
    800046f2:	8552                	mv	a0,s4
    800046f4:	00000097          	auipc	ra,0x0
    800046f8:	aa2080e7          	jalr	-1374(ra) # 80004196 <iunlock>
      return ip;
    800046fc:	bfe1                	j	800046d4 <namex+0x6c>
      iunlockput(ip);
    800046fe:	8552                	mv	a0,s4
    80004700:	00000097          	auipc	ra,0x0
    80004704:	c36080e7          	jalr	-970(ra) # 80004336 <iunlockput>
      return 0;
    80004708:	8a4e                	mv	s4,s3
    8000470a:	b7e9                	j	800046d4 <namex+0x6c>
  len = path - s;
    8000470c:	40998633          	sub	a2,s3,s1
    80004710:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004714:	09acd863          	bge	s9,s10,800047a4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004718:	4639                	li	a2,14
    8000471a:	85a6                	mv	a1,s1
    8000471c:	8556                	mv	a0,s5
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	748080e7          	jalr	1864(ra) # 80000e66 <memmove>
    80004726:	84ce                	mv	s1,s3
  while(*path == '/')
    80004728:	0004c783          	lbu	a5,0(s1)
    8000472c:	01279763          	bne	a5,s2,8000473a <namex+0xd2>
    path++;
    80004730:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004732:	0004c783          	lbu	a5,0(s1)
    80004736:	ff278de3          	beq	a5,s2,80004730 <namex+0xc8>
    ilock(ip);
    8000473a:	8552                	mv	a0,s4
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	998080e7          	jalr	-1640(ra) # 800040d4 <ilock>
    if(ip->type != T_DIR){
    80004744:	044a1783          	lh	a5,68(s4)
    80004748:	f98790e3          	bne	a5,s8,800046c8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000474c:	000b0563          	beqz	s6,80004756 <namex+0xee>
    80004750:	0004c783          	lbu	a5,0(s1)
    80004754:	dfd9                	beqz	a5,800046f2 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004756:	865e                	mv	a2,s7
    80004758:	85d6                	mv	a1,s5
    8000475a:	8552                	mv	a0,s4
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	e5c080e7          	jalr	-420(ra) # 800045b8 <dirlookup>
    80004764:	89aa                	mv	s3,a0
    80004766:	dd41                	beqz	a0,800046fe <namex+0x96>
    iunlockput(ip);
    80004768:	8552                	mv	a0,s4
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	bcc080e7          	jalr	-1076(ra) # 80004336 <iunlockput>
    ip = next;
    80004772:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004774:	0004c783          	lbu	a5,0(s1)
    80004778:	01279763          	bne	a5,s2,80004786 <namex+0x11e>
    path++;
    8000477c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000477e:	0004c783          	lbu	a5,0(s1)
    80004782:	ff278de3          	beq	a5,s2,8000477c <namex+0x114>
  if(*path == 0)
    80004786:	cb9d                	beqz	a5,800047bc <namex+0x154>
  while(*path != '/' && *path != 0)
    80004788:	0004c783          	lbu	a5,0(s1)
    8000478c:	89a6                	mv	s3,s1
  len = path - s;
    8000478e:	8d5e                	mv	s10,s7
    80004790:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004792:	01278963          	beq	a5,s2,800047a4 <namex+0x13c>
    80004796:	dbbd                	beqz	a5,8000470c <namex+0xa4>
    path++;
    80004798:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000479a:	0009c783          	lbu	a5,0(s3)
    8000479e:	ff279ce3          	bne	a5,s2,80004796 <namex+0x12e>
    800047a2:	b7ad                	j	8000470c <namex+0xa4>
    memmove(name, s, len);
    800047a4:	2601                	sext.w	a2,a2
    800047a6:	85a6                	mv	a1,s1
    800047a8:	8556                	mv	a0,s5
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	6bc080e7          	jalr	1724(ra) # 80000e66 <memmove>
    name[len] = 0;
    800047b2:	9d56                	add	s10,s10,s5
    800047b4:	000d0023          	sb	zero,0(s10)
    800047b8:	84ce                	mv	s1,s3
    800047ba:	b7bd                	j	80004728 <namex+0xc0>
  if(nameiparent){
    800047bc:	f00b0ce3          	beqz	s6,800046d4 <namex+0x6c>
    iput(ip);
    800047c0:	8552                	mv	a0,s4
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	acc080e7          	jalr	-1332(ra) # 8000428e <iput>
    return 0;
    800047ca:	4a01                	li	s4,0
    800047cc:	b721                	j	800046d4 <namex+0x6c>

00000000800047ce <dirlink>:
{
    800047ce:	7139                	addi	sp,sp,-64
    800047d0:	fc06                	sd	ra,56(sp)
    800047d2:	f822                	sd	s0,48(sp)
    800047d4:	f426                	sd	s1,40(sp)
    800047d6:	f04a                	sd	s2,32(sp)
    800047d8:	ec4e                	sd	s3,24(sp)
    800047da:	e852                	sd	s4,16(sp)
    800047dc:	0080                	addi	s0,sp,64
    800047de:	892a                	mv	s2,a0
    800047e0:	8a2e                	mv	s4,a1
    800047e2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800047e4:	4601                	li	a2,0
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	dd2080e7          	jalr	-558(ra) # 800045b8 <dirlookup>
    800047ee:	e93d                	bnez	a0,80004864 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047f0:	04c92483          	lw	s1,76(s2)
    800047f4:	c49d                	beqz	s1,80004822 <dirlink+0x54>
    800047f6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047f8:	4741                	li	a4,16
    800047fa:	86a6                	mv	a3,s1
    800047fc:	fc040613          	addi	a2,s0,-64
    80004800:	4581                	li	a1,0
    80004802:	854a                	mv	a0,s2
    80004804:	00000097          	auipc	ra,0x0
    80004808:	b84080e7          	jalr	-1148(ra) # 80004388 <readi>
    8000480c:	47c1                	li	a5,16
    8000480e:	06f51163          	bne	a0,a5,80004870 <dirlink+0xa2>
    if(de.inum == 0)
    80004812:	fc045783          	lhu	a5,-64(s0)
    80004816:	c791                	beqz	a5,80004822 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004818:	24c1                	addiw	s1,s1,16
    8000481a:	04c92783          	lw	a5,76(s2)
    8000481e:	fcf4ede3          	bltu	s1,a5,800047f8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004822:	4639                	li	a2,14
    80004824:	85d2                	mv	a1,s4
    80004826:	fc240513          	addi	a0,s0,-62
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	6ec080e7          	jalr	1772(ra) # 80000f16 <strncpy>
  de.inum = inum;
    80004832:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004836:	4741                	li	a4,16
    80004838:	86a6                	mv	a3,s1
    8000483a:	fc040613          	addi	a2,s0,-64
    8000483e:	4581                	li	a1,0
    80004840:	854a                	mv	a0,s2
    80004842:	00000097          	auipc	ra,0x0
    80004846:	c3e080e7          	jalr	-962(ra) # 80004480 <writei>
    8000484a:	1541                	addi	a0,a0,-16
    8000484c:	00a03533          	snez	a0,a0
    80004850:	40a00533          	neg	a0,a0
}
    80004854:	70e2                	ld	ra,56(sp)
    80004856:	7442                	ld	s0,48(sp)
    80004858:	74a2                	ld	s1,40(sp)
    8000485a:	7902                	ld	s2,32(sp)
    8000485c:	69e2                	ld	s3,24(sp)
    8000485e:	6a42                	ld	s4,16(sp)
    80004860:	6121                	addi	sp,sp,64
    80004862:	8082                	ret
    iput(ip);
    80004864:	00000097          	auipc	ra,0x0
    80004868:	a2a080e7          	jalr	-1494(ra) # 8000428e <iput>
    return -1;
    8000486c:	557d                	li	a0,-1
    8000486e:	b7dd                	j	80004854 <dirlink+0x86>
      panic("dirlink read");
    80004870:	00004517          	auipc	a0,0x4
    80004874:	e7850513          	addi	a0,a0,-392 # 800086e8 <syscalls+0x1f8>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	cc8080e7          	jalr	-824(ra) # 80000540 <panic>

0000000080004880 <namei>:

struct inode*
namei(char *path)
{
    80004880:	1101                	addi	sp,sp,-32
    80004882:	ec06                	sd	ra,24(sp)
    80004884:	e822                	sd	s0,16(sp)
    80004886:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004888:	fe040613          	addi	a2,s0,-32
    8000488c:	4581                	li	a1,0
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	dda080e7          	jalr	-550(ra) # 80004668 <namex>
}
    80004896:	60e2                	ld	ra,24(sp)
    80004898:	6442                	ld	s0,16(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000489e:	1141                	addi	sp,sp,-16
    800048a0:	e406                	sd	ra,8(sp)
    800048a2:	e022                	sd	s0,0(sp)
    800048a4:	0800                	addi	s0,sp,16
    800048a6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800048a8:	4585                	li	a1,1
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	dbe080e7          	jalr	-578(ra) # 80004668 <namex>
}
    800048b2:	60a2                	ld	ra,8(sp)
    800048b4:	6402                	ld	s0,0(sp)
    800048b6:	0141                	addi	sp,sp,16
    800048b8:	8082                	ret

00000000800048ba <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800048ba:	1101                	addi	sp,sp,-32
    800048bc:	ec06                	sd	ra,24(sp)
    800048be:	e822                	sd	s0,16(sp)
    800048c0:	e426                	sd	s1,8(sp)
    800048c2:	e04a                	sd	s2,0(sp)
    800048c4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800048c6:	00240917          	auipc	s2,0x240
    800048ca:	93a90913          	addi	s2,s2,-1734 # 80244200 <log>
    800048ce:	01892583          	lw	a1,24(s2)
    800048d2:	02892503          	lw	a0,40(s2)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	fe6080e7          	jalr	-26(ra) # 800038bc <bread>
    800048de:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800048e0:	02c92683          	lw	a3,44(s2)
    800048e4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800048e6:	02d05863          	blez	a3,80004916 <write_head+0x5c>
    800048ea:	00240797          	auipc	a5,0x240
    800048ee:	94678793          	addi	a5,a5,-1722 # 80244230 <log+0x30>
    800048f2:	05c50713          	addi	a4,a0,92
    800048f6:	36fd                	addiw	a3,a3,-1
    800048f8:	02069613          	slli	a2,a3,0x20
    800048fc:	01e65693          	srli	a3,a2,0x1e
    80004900:	00240617          	auipc	a2,0x240
    80004904:	93460613          	addi	a2,a2,-1740 # 80244234 <log+0x34>
    80004908:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000490a:	4390                	lw	a2,0(a5)
    8000490c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000490e:	0791                	addi	a5,a5,4
    80004910:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004912:	fed79ce3          	bne	a5,a3,8000490a <write_head+0x50>
  }
  bwrite(buf);
    80004916:	8526                	mv	a0,s1
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	096080e7          	jalr	150(ra) # 800039ae <bwrite>
  brelse(buf);
    80004920:	8526                	mv	a0,s1
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	0ca080e7          	jalr	202(ra) # 800039ec <brelse>
}
    8000492a:	60e2                	ld	ra,24(sp)
    8000492c:	6442                	ld	s0,16(sp)
    8000492e:	64a2                	ld	s1,8(sp)
    80004930:	6902                	ld	s2,0(sp)
    80004932:	6105                	addi	sp,sp,32
    80004934:	8082                	ret

0000000080004936 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004936:	00240797          	auipc	a5,0x240
    8000493a:	8f67a783          	lw	a5,-1802(a5) # 8024422c <log+0x2c>
    8000493e:	0af05d63          	blez	a5,800049f8 <install_trans+0xc2>
{
    80004942:	7139                	addi	sp,sp,-64
    80004944:	fc06                	sd	ra,56(sp)
    80004946:	f822                	sd	s0,48(sp)
    80004948:	f426                	sd	s1,40(sp)
    8000494a:	f04a                	sd	s2,32(sp)
    8000494c:	ec4e                	sd	s3,24(sp)
    8000494e:	e852                	sd	s4,16(sp)
    80004950:	e456                	sd	s5,8(sp)
    80004952:	e05a                	sd	s6,0(sp)
    80004954:	0080                	addi	s0,sp,64
    80004956:	8b2a                	mv	s6,a0
    80004958:	00240a97          	auipc	s5,0x240
    8000495c:	8d8a8a93          	addi	s5,s5,-1832 # 80244230 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004960:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004962:	00240997          	auipc	s3,0x240
    80004966:	89e98993          	addi	s3,s3,-1890 # 80244200 <log>
    8000496a:	a00d                	j	8000498c <install_trans+0x56>
    brelse(lbuf);
    8000496c:	854a                	mv	a0,s2
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	07e080e7          	jalr	126(ra) # 800039ec <brelse>
    brelse(dbuf);
    80004976:	8526                	mv	a0,s1
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	074080e7          	jalr	116(ra) # 800039ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004980:	2a05                	addiw	s4,s4,1
    80004982:	0a91                	addi	s5,s5,4
    80004984:	02c9a783          	lw	a5,44(s3)
    80004988:	04fa5e63          	bge	s4,a5,800049e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000498c:	0189a583          	lw	a1,24(s3)
    80004990:	014585bb          	addw	a1,a1,s4
    80004994:	2585                	addiw	a1,a1,1
    80004996:	0289a503          	lw	a0,40(s3)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	f22080e7          	jalr	-222(ra) # 800038bc <bread>
    800049a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800049a4:	000aa583          	lw	a1,0(s5)
    800049a8:	0289a503          	lw	a0,40(s3)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	f10080e7          	jalr	-240(ra) # 800038bc <bread>
    800049b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800049b6:	40000613          	li	a2,1024
    800049ba:	05890593          	addi	a1,s2,88
    800049be:	05850513          	addi	a0,a0,88
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	4a4080e7          	jalr	1188(ra) # 80000e66 <memmove>
    bwrite(dbuf);  // write dst to disk
    800049ca:	8526                	mv	a0,s1
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	fe2080e7          	jalr	-30(ra) # 800039ae <bwrite>
    if(recovering == 0)
    800049d4:	f80b1ce3          	bnez	s6,8000496c <install_trans+0x36>
      bunpin(dbuf);
    800049d8:	8526                	mv	a0,s1
    800049da:	fffff097          	auipc	ra,0xfffff
    800049de:	0ec080e7          	jalr	236(ra) # 80003ac6 <bunpin>
    800049e2:	b769                	j	8000496c <install_trans+0x36>
}
    800049e4:	70e2                	ld	ra,56(sp)
    800049e6:	7442                	ld	s0,48(sp)
    800049e8:	74a2                	ld	s1,40(sp)
    800049ea:	7902                	ld	s2,32(sp)
    800049ec:	69e2                	ld	s3,24(sp)
    800049ee:	6a42                	ld	s4,16(sp)
    800049f0:	6aa2                	ld	s5,8(sp)
    800049f2:	6b02                	ld	s6,0(sp)
    800049f4:	6121                	addi	sp,sp,64
    800049f6:	8082                	ret
    800049f8:	8082                	ret

00000000800049fa <initlog>:
{
    800049fa:	7179                	addi	sp,sp,-48
    800049fc:	f406                	sd	ra,40(sp)
    800049fe:	f022                	sd	s0,32(sp)
    80004a00:	ec26                	sd	s1,24(sp)
    80004a02:	e84a                	sd	s2,16(sp)
    80004a04:	e44e                	sd	s3,8(sp)
    80004a06:	1800                	addi	s0,sp,48
    80004a08:	892a                	mv	s2,a0
    80004a0a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a0c:	0023f497          	auipc	s1,0x23f
    80004a10:	7f448493          	addi	s1,s1,2036 # 80244200 <log>
    80004a14:	00004597          	auipc	a1,0x4
    80004a18:	ce458593          	addi	a1,a1,-796 # 800086f8 <syscalls+0x208>
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	260080e7          	jalr	608(ra) # 80000c7e <initlock>
  log.start = sb->logstart;
    80004a26:	0149a583          	lw	a1,20(s3)
    80004a2a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004a2c:	0109a783          	lw	a5,16(s3)
    80004a30:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a32:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a36:	854a                	mv	a0,s2
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	e84080e7          	jalr	-380(ra) # 800038bc <bread>
  log.lh.n = lh->n;
    80004a40:	4d34                	lw	a3,88(a0)
    80004a42:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a44:	02d05663          	blez	a3,80004a70 <initlog+0x76>
    80004a48:	05c50793          	addi	a5,a0,92
    80004a4c:	0023f717          	auipc	a4,0x23f
    80004a50:	7e470713          	addi	a4,a4,2020 # 80244230 <log+0x30>
    80004a54:	36fd                	addiw	a3,a3,-1
    80004a56:	02069613          	slli	a2,a3,0x20
    80004a5a:	01e65693          	srli	a3,a2,0x1e
    80004a5e:	06050613          	addi	a2,a0,96
    80004a62:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004a64:	4390                	lw	a2,0(a5)
    80004a66:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a68:	0791                	addi	a5,a5,4
    80004a6a:	0711                	addi	a4,a4,4
    80004a6c:	fed79ce3          	bne	a5,a3,80004a64 <initlog+0x6a>
  brelse(buf);
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	f7c080e7          	jalr	-132(ra) # 800039ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004a78:	4505                	li	a0,1
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	ebc080e7          	jalr	-324(ra) # 80004936 <install_trans>
  log.lh.n = 0;
    80004a82:	0023f797          	auipc	a5,0x23f
    80004a86:	7a07a523          	sw	zero,1962(a5) # 8024422c <log+0x2c>
  write_head(); // clear the log
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	e30080e7          	jalr	-464(ra) # 800048ba <write_head>
}
    80004a92:	70a2                	ld	ra,40(sp)
    80004a94:	7402                	ld	s0,32(sp)
    80004a96:	64e2                	ld	s1,24(sp)
    80004a98:	6942                	ld	s2,16(sp)
    80004a9a:	69a2                	ld	s3,8(sp)
    80004a9c:	6145                	addi	sp,sp,48
    80004a9e:	8082                	ret

0000000080004aa0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004aa0:	1101                	addi	sp,sp,-32
    80004aa2:	ec06                	sd	ra,24(sp)
    80004aa4:	e822                	sd	s0,16(sp)
    80004aa6:	e426                	sd	s1,8(sp)
    80004aa8:	e04a                	sd	s2,0(sp)
    80004aaa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004aac:	0023f517          	auipc	a0,0x23f
    80004ab0:	75450513          	addi	a0,a0,1876 # 80244200 <log>
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	25a080e7          	jalr	602(ra) # 80000d0e <acquire>
  while(1){
    if(log.committing){
    80004abc:	0023f497          	auipc	s1,0x23f
    80004ac0:	74448493          	addi	s1,s1,1860 # 80244200 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ac4:	4979                	li	s2,30
    80004ac6:	a039                	j	80004ad4 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ac8:	85a6                	mv	a1,s1
    80004aca:	8526                	mv	a0,s1
    80004acc:	ffffe097          	auipc	ra,0xffffe
    80004ad0:	b12080e7          	jalr	-1262(ra) # 800025de <sleep>
    if(log.committing){
    80004ad4:	50dc                	lw	a5,36(s1)
    80004ad6:	fbed                	bnez	a5,80004ac8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ad8:	5098                	lw	a4,32(s1)
    80004ada:	2705                	addiw	a4,a4,1
    80004adc:	0007069b          	sext.w	a3,a4
    80004ae0:	0027179b          	slliw	a5,a4,0x2
    80004ae4:	9fb9                	addw	a5,a5,a4
    80004ae6:	0017979b          	slliw	a5,a5,0x1
    80004aea:	54d8                	lw	a4,44(s1)
    80004aec:	9fb9                	addw	a5,a5,a4
    80004aee:	00f95963          	bge	s2,a5,80004b00 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004af2:	85a6                	mv	a1,s1
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	ae8080e7          	jalr	-1304(ra) # 800025de <sleep>
    80004afe:	bfd9                	j	80004ad4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b00:	0023f517          	auipc	a0,0x23f
    80004b04:	70050513          	addi	a0,a0,1792 # 80244200 <log>
    80004b08:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	2b8080e7          	jalr	696(ra) # 80000dc2 <release>
      break;
    }
  }
}
    80004b12:	60e2                	ld	ra,24(sp)
    80004b14:	6442                	ld	s0,16(sp)
    80004b16:	64a2                	ld	s1,8(sp)
    80004b18:	6902                	ld	s2,0(sp)
    80004b1a:	6105                	addi	sp,sp,32
    80004b1c:	8082                	ret

0000000080004b1e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b1e:	7139                	addi	sp,sp,-64
    80004b20:	fc06                	sd	ra,56(sp)
    80004b22:	f822                	sd	s0,48(sp)
    80004b24:	f426                	sd	s1,40(sp)
    80004b26:	f04a                	sd	s2,32(sp)
    80004b28:	ec4e                	sd	s3,24(sp)
    80004b2a:	e852                	sd	s4,16(sp)
    80004b2c:	e456                	sd	s5,8(sp)
    80004b2e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b30:	0023f497          	auipc	s1,0x23f
    80004b34:	6d048493          	addi	s1,s1,1744 # 80244200 <log>
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	1d4080e7          	jalr	468(ra) # 80000d0e <acquire>
  log.outstanding -= 1;
    80004b42:	509c                	lw	a5,32(s1)
    80004b44:	37fd                	addiw	a5,a5,-1
    80004b46:	0007891b          	sext.w	s2,a5
    80004b4a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b4c:	50dc                	lw	a5,36(s1)
    80004b4e:	e7b9                	bnez	a5,80004b9c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b50:	04091e63          	bnez	s2,80004bac <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004b54:	0023f497          	auipc	s1,0x23f
    80004b58:	6ac48493          	addi	s1,s1,1708 # 80244200 <log>
    80004b5c:	4785                	li	a5,1
    80004b5e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	260080e7          	jalr	608(ra) # 80000dc2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b6a:	54dc                	lw	a5,44(s1)
    80004b6c:	06f04763          	bgtz	a5,80004bda <end_op+0xbc>
    acquire(&log.lock);
    80004b70:	0023f497          	auipc	s1,0x23f
    80004b74:	69048493          	addi	s1,s1,1680 # 80244200 <log>
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	194080e7          	jalr	404(ra) # 80000d0e <acquire>
    log.committing = 0;
    80004b82:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffe097          	auipc	ra,0xffffe
    80004b8c:	aba080e7          	jalr	-1350(ra) # 80002642 <wakeup>
    release(&log.lock);
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	230080e7          	jalr	560(ra) # 80000dc2 <release>
}
    80004b9a:	a03d                	j	80004bc8 <end_op+0xaa>
    panic("log.committing");
    80004b9c:	00004517          	auipc	a0,0x4
    80004ba0:	b6450513          	addi	a0,a0,-1180 # 80008700 <syscalls+0x210>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	99c080e7          	jalr	-1636(ra) # 80000540 <panic>
    wakeup(&log);
    80004bac:	0023f497          	auipc	s1,0x23f
    80004bb0:	65448493          	addi	s1,s1,1620 # 80244200 <log>
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffe097          	auipc	ra,0xffffe
    80004bba:	a8c080e7          	jalr	-1396(ra) # 80002642 <wakeup>
  release(&log.lock);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	202080e7          	jalr	514(ra) # 80000dc2 <release>
}
    80004bc8:	70e2                	ld	ra,56(sp)
    80004bca:	7442                	ld	s0,48(sp)
    80004bcc:	74a2                	ld	s1,40(sp)
    80004bce:	7902                	ld	s2,32(sp)
    80004bd0:	69e2                	ld	s3,24(sp)
    80004bd2:	6a42                	ld	s4,16(sp)
    80004bd4:	6aa2                	ld	s5,8(sp)
    80004bd6:	6121                	addi	sp,sp,64
    80004bd8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bda:	0023fa97          	auipc	s5,0x23f
    80004bde:	656a8a93          	addi	s5,s5,1622 # 80244230 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004be2:	0023fa17          	auipc	s4,0x23f
    80004be6:	61ea0a13          	addi	s4,s4,1566 # 80244200 <log>
    80004bea:	018a2583          	lw	a1,24(s4)
    80004bee:	012585bb          	addw	a1,a1,s2
    80004bf2:	2585                	addiw	a1,a1,1
    80004bf4:	028a2503          	lw	a0,40(s4)
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	cc4080e7          	jalr	-828(ra) # 800038bc <bread>
    80004c00:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c02:	000aa583          	lw	a1,0(s5)
    80004c06:	028a2503          	lw	a0,40(s4)
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	cb2080e7          	jalr	-846(ra) # 800038bc <bread>
    80004c12:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c14:	40000613          	li	a2,1024
    80004c18:	05850593          	addi	a1,a0,88
    80004c1c:	05848513          	addi	a0,s1,88
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	246080e7          	jalr	582(ra) # 80000e66 <memmove>
    bwrite(to);  // write the log
    80004c28:	8526                	mv	a0,s1
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	d84080e7          	jalr	-636(ra) # 800039ae <bwrite>
    brelse(from);
    80004c32:	854e                	mv	a0,s3
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	db8080e7          	jalr	-584(ra) # 800039ec <brelse>
    brelse(to);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	dae080e7          	jalr	-594(ra) # 800039ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c46:	2905                	addiw	s2,s2,1
    80004c48:	0a91                	addi	s5,s5,4
    80004c4a:	02ca2783          	lw	a5,44(s4)
    80004c4e:	f8f94ee3          	blt	s2,a5,80004bea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	c68080e7          	jalr	-920(ra) # 800048ba <write_head>
    install_trans(0); // Now install writes to home locations
    80004c5a:	4501                	li	a0,0
    80004c5c:	00000097          	auipc	ra,0x0
    80004c60:	cda080e7          	jalr	-806(ra) # 80004936 <install_trans>
    log.lh.n = 0;
    80004c64:	0023f797          	auipc	a5,0x23f
    80004c68:	5c07a423          	sw	zero,1480(a5) # 8024422c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c6c:	00000097          	auipc	ra,0x0
    80004c70:	c4e080e7          	jalr	-946(ra) # 800048ba <write_head>
    80004c74:	bdf5                	j	80004b70 <end_op+0x52>

0000000080004c76 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004c76:	1101                	addi	sp,sp,-32
    80004c78:	ec06                	sd	ra,24(sp)
    80004c7a:	e822                	sd	s0,16(sp)
    80004c7c:	e426                	sd	s1,8(sp)
    80004c7e:	e04a                	sd	s2,0(sp)
    80004c80:	1000                	addi	s0,sp,32
    80004c82:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004c84:	0023f917          	auipc	s2,0x23f
    80004c88:	57c90913          	addi	s2,s2,1404 # 80244200 <log>
    80004c8c:	854a                	mv	a0,s2
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	080080e7          	jalr	128(ra) # 80000d0e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c96:	02c92603          	lw	a2,44(s2)
    80004c9a:	47f5                	li	a5,29
    80004c9c:	06c7c563          	blt	a5,a2,80004d06 <log_write+0x90>
    80004ca0:	0023f797          	auipc	a5,0x23f
    80004ca4:	57c7a783          	lw	a5,1404(a5) # 8024421c <log+0x1c>
    80004ca8:	37fd                	addiw	a5,a5,-1
    80004caa:	04f65e63          	bge	a2,a5,80004d06 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004cae:	0023f797          	auipc	a5,0x23f
    80004cb2:	5727a783          	lw	a5,1394(a5) # 80244220 <log+0x20>
    80004cb6:	06f05063          	blez	a5,80004d16 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004cba:	4781                	li	a5,0
    80004cbc:	06c05563          	blez	a2,80004d26 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cc0:	44cc                	lw	a1,12(s1)
    80004cc2:	0023f717          	auipc	a4,0x23f
    80004cc6:	56e70713          	addi	a4,a4,1390 # 80244230 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004cca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ccc:	4314                	lw	a3,0(a4)
    80004cce:	04b68c63          	beq	a3,a1,80004d26 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004cd2:	2785                	addiw	a5,a5,1
    80004cd4:	0711                	addi	a4,a4,4
    80004cd6:	fef61be3          	bne	a2,a5,80004ccc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004cda:	0621                	addi	a2,a2,8
    80004cdc:	060a                	slli	a2,a2,0x2
    80004cde:	0023f797          	auipc	a5,0x23f
    80004ce2:	52278793          	addi	a5,a5,1314 # 80244200 <log>
    80004ce6:	97b2                	add	a5,a5,a2
    80004ce8:	44d8                	lw	a4,12(s1)
    80004cea:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004cec:	8526                	mv	a0,s1
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	d9c080e7          	jalr	-612(ra) # 80003a8a <bpin>
    log.lh.n++;
    80004cf6:	0023f717          	auipc	a4,0x23f
    80004cfa:	50a70713          	addi	a4,a4,1290 # 80244200 <log>
    80004cfe:	575c                	lw	a5,44(a4)
    80004d00:	2785                	addiw	a5,a5,1
    80004d02:	d75c                	sw	a5,44(a4)
    80004d04:	a82d                	j	80004d3e <log_write+0xc8>
    panic("too big a transaction");
    80004d06:	00004517          	auipc	a0,0x4
    80004d0a:	a0a50513          	addi	a0,a0,-1526 # 80008710 <syscalls+0x220>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	832080e7          	jalr	-1998(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004d16:	00004517          	auipc	a0,0x4
    80004d1a:	a1250513          	addi	a0,a0,-1518 # 80008728 <syscalls+0x238>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	822080e7          	jalr	-2014(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004d26:	00878693          	addi	a3,a5,8
    80004d2a:	068a                	slli	a3,a3,0x2
    80004d2c:	0023f717          	auipc	a4,0x23f
    80004d30:	4d470713          	addi	a4,a4,1236 # 80244200 <log>
    80004d34:	9736                	add	a4,a4,a3
    80004d36:	44d4                	lw	a3,12(s1)
    80004d38:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004d3a:	faf609e3          	beq	a2,a5,80004cec <log_write+0x76>
  }
  release(&log.lock);
    80004d3e:	0023f517          	auipc	a0,0x23f
    80004d42:	4c250513          	addi	a0,a0,1218 # 80244200 <log>
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	07c080e7          	jalr	124(ra) # 80000dc2 <release>
}
    80004d4e:	60e2                	ld	ra,24(sp)
    80004d50:	6442                	ld	s0,16(sp)
    80004d52:	64a2                	ld	s1,8(sp)
    80004d54:	6902                	ld	s2,0(sp)
    80004d56:	6105                	addi	sp,sp,32
    80004d58:	8082                	ret

0000000080004d5a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004d5a:	1101                	addi	sp,sp,-32
    80004d5c:	ec06                	sd	ra,24(sp)
    80004d5e:	e822                	sd	s0,16(sp)
    80004d60:	e426                	sd	s1,8(sp)
    80004d62:	e04a                	sd	s2,0(sp)
    80004d64:	1000                	addi	s0,sp,32
    80004d66:	84aa                	mv	s1,a0
    80004d68:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d6a:	00004597          	auipc	a1,0x4
    80004d6e:	9de58593          	addi	a1,a1,-1570 # 80008748 <syscalls+0x258>
    80004d72:	0521                	addi	a0,a0,8
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f0a080e7          	jalr	-246(ra) # 80000c7e <initlock>
  lk->name = name;
    80004d7c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004d80:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d84:	0204a423          	sw	zero,40(s1)
}
    80004d88:	60e2                	ld	ra,24(sp)
    80004d8a:	6442                	ld	s0,16(sp)
    80004d8c:	64a2                	ld	s1,8(sp)
    80004d8e:	6902                	ld	s2,0(sp)
    80004d90:	6105                	addi	sp,sp,32
    80004d92:	8082                	ret

0000000080004d94 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d94:	1101                	addi	sp,sp,-32
    80004d96:	ec06                	sd	ra,24(sp)
    80004d98:	e822                	sd	s0,16(sp)
    80004d9a:	e426                	sd	s1,8(sp)
    80004d9c:	e04a                	sd	s2,0(sp)
    80004d9e:	1000                	addi	s0,sp,32
    80004da0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004da2:	00850913          	addi	s2,a0,8
    80004da6:	854a                	mv	a0,s2
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	f66080e7          	jalr	-154(ra) # 80000d0e <acquire>
  while (lk->locked) {
    80004db0:	409c                	lw	a5,0(s1)
    80004db2:	cb89                	beqz	a5,80004dc4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004db4:	85ca                	mv	a1,s2
    80004db6:	8526                	mv	a0,s1
    80004db8:	ffffe097          	auipc	ra,0xffffe
    80004dbc:	826080e7          	jalr	-2010(ra) # 800025de <sleep>
  while (lk->locked) {
    80004dc0:	409c                	lw	a5,0(s1)
    80004dc2:	fbed                	bnez	a5,80004db4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004dc4:	4785                	li	a5,1
    80004dc6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	f22080e7          	jalr	-222(ra) # 80001cea <myproc>
    80004dd0:	591c                	lw	a5,48(a0)
    80004dd2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004dd4:	854a                	mv	a0,s2
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	fec080e7          	jalr	-20(ra) # 80000dc2 <release>
}
    80004dde:	60e2                	ld	ra,24(sp)
    80004de0:	6442                	ld	s0,16(sp)
    80004de2:	64a2                	ld	s1,8(sp)
    80004de4:	6902                	ld	s2,0(sp)
    80004de6:	6105                	addi	sp,sp,32
    80004de8:	8082                	ret

0000000080004dea <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004dea:	1101                	addi	sp,sp,-32
    80004dec:	ec06                	sd	ra,24(sp)
    80004dee:	e822                	sd	s0,16(sp)
    80004df0:	e426                	sd	s1,8(sp)
    80004df2:	e04a                	sd	s2,0(sp)
    80004df4:	1000                	addi	s0,sp,32
    80004df6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004df8:	00850913          	addi	s2,a0,8
    80004dfc:	854a                	mv	a0,s2
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	f10080e7          	jalr	-240(ra) # 80000d0e <acquire>
  lk->locked = 0;
    80004e06:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e0a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004e0e:	8526                	mv	a0,s1
    80004e10:	ffffe097          	auipc	ra,0xffffe
    80004e14:	832080e7          	jalr	-1998(ra) # 80002642 <wakeup>
  release(&lk->lk);
    80004e18:	854a                	mv	a0,s2
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	fa8080e7          	jalr	-88(ra) # 80000dc2 <release>
}
    80004e22:	60e2                	ld	ra,24(sp)
    80004e24:	6442                	ld	s0,16(sp)
    80004e26:	64a2                	ld	s1,8(sp)
    80004e28:	6902                	ld	s2,0(sp)
    80004e2a:	6105                	addi	sp,sp,32
    80004e2c:	8082                	ret

0000000080004e2e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e2e:	7179                	addi	sp,sp,-48
    80004e30:	f406                	sd	ra,40(sp)
    80004e32:	f022                	sd	s0,32(sp)
    80004e34:	ec26                	sd	s1,24(sp)
    80004e36:	e84a                	sd	s2,16(sp)
    80004e38:	e44e                	sd	s3,8(sp)
    80004e3a:	1800                	addi	s0,sp,48
    80004e3c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004e3e:	00850913          	addi	s2,a0,8
    80004e42:	854a                	mv	a0,s2
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	eca080e7          	jalr	-310(ra) # 80000d0e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e4c:	409c                	lw	a5,0(s1)
    80004e4e:	ef99                	bnez	a5,80004e6c <holdingsleep+0x3e>
    80004e50:	4481                	li	s1,0
  release(&lk->lk);
    80004e52:	854a                	mv	a0,s2
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	f6e080e7          	jalr	-146(ra) # 80000dc2 <release>
  return r;
}
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	70a2                	ld	ra,40(sp)
    80004e60:	7402                	ld	s0,32(sp)
    80004e62:	64e2                	ld	s1,24(sp)
    80004e64:	6942                	ld	s2,16(sp)
    80004e66:	69a2                	ld	s3,8(sp)
    80004e68:	6145                	addi	sp,sp,48
    80004e6a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e6c:	0284a983          	lw	s3,40(s1)
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	e7a080e7          	jalr	-390(ra) # 80001cea <myproc>
    80004e78:	5904                	lw	s1,48(a0)
    80004e7a:	413484b3          	sub	s1,s1,s3
    80004e7e:	0014b493          	seqz	s1,s1
    80004e82:	bfc1                	j	80004e52 <holdingsleep+0x24>

0000000080004e84 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004e84:	1141                	addi	sp,sp,-16
    80004e86:	e406                	sd	ra,8(sp)
    80004e88:	e022                	sd	s0,0(sp)
    80004e8a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e8c:	00004597          	auipc	a1,0x4
    80004e90:	8cc58593          	addi	a1,a1,-1844 # 80008758 <syscalls+0x268>
    80004e94:	0023f517          	auipc	a0,0x23f
    80004e98:	4b450513          	addi	a0,a0,1204 # 80244348 <ftable>
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	de2080e7          	jalr	-542(ra) # 80000c7e <initlock>
}
    80004ea4:	60a2                	ld	ra,8(sp)
    80004ea6:	6402                	ld	s0,0(sp)
    80004ea8:	0141                	addi	sp,sp,16
    80004eaa:	8082                	ret

0000000080004eac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004eac:	1101                	addi	sp,sp,-32
    80004eae:	ec06                	sd	ra,24(sp)
    80004eb0:	e822                	sd	s0,16(sp)
    80004eb2:	e426                	sd	s1,8(sp)
    80004eb4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004eb6:	0023f517          	auipc	a0,0x23f
    80004eba:	49250513          	addi	a0,a0,1170 # 80244348 <ftable>
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	e50080e7          	jalr	-432(ra) # 80000d0e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ec6:	0023f497          	auipc	s1,0x23f
    80004eca:	49a48493          	addi	s1,s1,1178 # 80244360 <ftable+0x18>
    80004ece:	00240717          	auipc	a4,0x240
    80004ed2:	43270713          	addi	a4,a4,1074 # 80245300 <disk>
    if(f->ref == 0){
    80004ed6:	40dc                	lw	a5,4(s1)
    80004ed8:	cf99                	beqz	a5,80004ef6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004eda:	02848493          	addi	s1,s1,40
    80004ede:	fee49ce3          	bne	s1,a4,80004ed6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ee2:	0023f517          	auipc	a0,0x23f
    80004ee6:	46650513          	addi	a0,a0,1126 # 80244348 <ftable>
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	ed8080e7          	jalr	-296(ra) # 80000dc2 <release>
  return 0;
    80004ef2:	4481                	li	s1,0
    80004ef4:	a819                	j	80004f0a <filealloc+0x5e>
      f->ref = 1;
    80004ef6:	4785                	li	a5,1
    80004ef8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004efa:	0023f517          	auipc	a0,0x23f
    80004efe:	44e50513          	addi	a0,a0,1102 # 80244348 <ftable>
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	ec0080e7          	jalr	-320(ra) # 80000dc2 <release>
}
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	60e2                	ld	ra,24(sp)
    80004f0e:	6442                	ld	s0,16(sp)
    80004f10:	64a2                	ld	s1,8(sp)
    80004f12:	6105                	addi	sp,sp,32
    80004f14:	8082                	ret

0000000080004f16 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f16:	1101                	addi	sp,sp,-32
    80004f18:	ec06                	sd	ra,24(sp)
    80004f1a:	e822                	sd	s0,16(sp)
    80004f1c:	e426                	sd	s1,8(sp)
    80004f1e:	1000                	addi	s0,sp,32
    80004f20:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f22:	0023f517          	auipc	a0,0x23f
    80004f26:	42650513          	addi	a0,a0,1062 # 80244348 <ftable>
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	de4080e7          	jalr	-540(ra) # 80000d0e <acquire>
  if(f->ref < 1)
    80004f32:	40dc                	lw	a5,4(s1)
    80004f34:	02f05263          	blez	a5,80004f58 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004f38:	2785                	addiw	a5,a5,1
    80004f3a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004f3c:	0023f517          	auipc	a0,0x23f
    80004f40:	40c50513          	addi	a0,a0,1036 # 80244348 <ftable>
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	e7e080e7          	jalr	-386(ra) # 80000dc2 <release>
  return f;
}
    80004f4c:	8526                	mv	a0,s1
    80004f4e:	60e2                	ld	ra,24(sp)
    80004f50:	6442                	ld	s0,16(sp)
    80004f52:	64a2                	ld	s1,8(sp)
    80004f54:	6105                	addi	sp,sp,32
    80004f56:	8082                	ret
    panic("filedup");
    80004f58:	00004517          	auipc	a0,0x4
    80004f5c:	80850513          	addi	a0,a0,-2040 # 80008760 <syscalls+0x270>
    80004f60:	ffffb097          	auipc	ra,0xffffb
    80004f64:	5e0080e7          	jalr	1504(ra) # 80000540 <panic>

0000000080004f68 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f68:	7139                	addi	sp,sp,-64
    80004f6a:	fc06                	sd	ra,56(sp)
    80004f6c:	f822                	sd	s0,48(sp)
    80004f6e:	f426                	sd	s1,40(sp)
    80004f70:	f04a                	sd	s2,32(sp)
    80004f72:	ec4e                	sd	s3,24(sp)
    80004f74:	e852                	sd	s4,16(sp)
    80004f76:	e456                	sd	s5,8(sp)
    80004f78:	0080                	addi	s0,sp,64
    80004f7a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004f7c:	0023f517          	auipc	a0,0x23f
    80004f80:	3cc50513          	addi	a0,a0,972 # 80244348 <ftable>
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	d8a080e7          	jalr	-630(ra) # 80000d0e <acquire>
  if(f->ref < 1)
    80004f8c:	40dc                	lw	a5,4(s1)
    80004f8e:	06f05163          	blez	a5,80004ff0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f92:	37fd                	addiw	a5,a5,-1
    80004f94:	0007871b          	sext.w	a4,a5
    80004f98:	c0dc                	sw	a5,4(s1)
    80004f9a:	06e04363          	bgtz	a4,80005000 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f9e:	0004a903          	lw	s2,0(s1)
    80004fa2:	0094ca83          	lbu	s5,9(s1)
    80004fa6:	0104ba03          	ld	s4,16(s1)
    80004faa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004fae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004fb2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004fb6:	0023f517          	auipc	a0,0x23f
    80004fba:	39250513          	addi	a0,a0,914 # 80244348 <ftable>
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	e04080e7          	jalr	-508(ra) # 80000dc2 <release>

  if(ff.type == FD_PIPE){
    80004fc6:	4785                	li	a5,1
    80004fc8:	04f90d63          	beq	s2,a5,80005022 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004fcc:	3979                	addiw	s2,s2,-2
    80004fce:	4785                	li	a5,1
    80004fd0:	0527e063          	bltu	a5,s2,80005010 <fileclose+0xa8>
    begin_op();
    80004fd4:	00000097          	auipc	ra,0x0
    80004fd8:	acc080e7          	jalr	-1332(ra) # 80004aa0 <begin_op>
    iput(ff.ip);
    80004fdc:	854e                	mv	a0,s3
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	2b0080e7          	jalr	688(ra) # 8000428e <iput>
    end_op();
    80004fe6:	00000097          	auipc	ra,0x0
    80004fea:	b38080e7          	jalr	-1224(ra) # 80004b1e <end_op>
    80004fee:	a00d                	j	80005010 <fileclose+0xa8>
    panic("fileclose");
    80004ff0:	00003517          	auipc	a0,0x3
    80004ff4:	77850513          	addi	a0,a0,1912 # 80008768 <syscalls+0x278>
    80004ff8:	ffffb097          	auipc	ra,0xffffb
    80004ffc:	548080e7          	jalr	1352(ra) # 80000540 <panic>
    release(&ftable.lock);
    80005000:	0023f517          	auipc	a0,0x23f
    80005004:	34850513          	addi	a0,a0,840 # 80244348 <ftable>
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	dba080e7          	jalr	-582(ra) # 80000dc2 <release>
  }
}
    80005010:	70e2                	ld	ra,56(sp)
    80005012:	7442                	ld	s0,48(sp)
    80005014:	74a2                	ld	s1,40(sp)
    80005016:	7902                	ld	s2,32(sp)
    80005018:	69e2                	ld	s3,24(sp)
    8000501a:	6a42                	ld	s4,16(sp)
    8000501c:	6aa2                	ld	s5,8(sp)
    8000501e:	6121                	addi	sp,sp,64
    80005020:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005022:	85d6                	mv	a1,s5
    80005024:	8552                	mv	a0,s4
    80005026:	00000097          	auipc	ra,0x0
    8000502a:	34c080e7          	jalr	844(ra) # 80005372 <pipeclose>
    8000502e:	b7cd                	j	80005010 <fileclose+0xa8>

0000000080005030 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005030:	715d                	addi	sp,sp,-80
    80005032:	e486                	sd	ra,72(sp)
    80005034:	e0a2                	sd	s0,64(sp)
    80005036:	fc26                	sd	s1,56(sp)
    80005038:	f84a                	sd	s2,48(sp)
    8000503a:	f44e                	sd	s3,40(sp)
    8000503c:	0880                	addi	s0,sp,80
    8000503e:	84aa                	mv	s1,a0
    80005040:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	ca8080e7          	jalr	-856(ra) # 80001cea <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000504a:	409c                	lw	a5,0(s1)
    8000504c:	37f9                	addiw	a5,a5,-2
    8000504e:	4705                	li	a4,1
    80005050:	04f76763          	bltu	a4,a5,8000509e <filestat+0x6e>
    80005054:	892a                	mv	s2,a0
    ilock(f->ip);
    80005056:	6c88                	ld	a0,24(s1)
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	07c080e7          	jalr	124(ra) # 800040d4 <ilock>
    stati(f->ip, &st);
    80005060:	fb840593          	addi	a1,s0,-72
    80005064:	6c88                	ld	a0,24(s1)
    80005066:	fffff097          	auipc	ra,0xfffff
    8000506a:	2f8080e7          	jalr	760(ra) # 8000435e <stati>
    iunlock(f->ip);
    8000506e:	6c88                	ld	a0,24(s1)
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	126080e7          	jalr	294(ra) # 80004196 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005078:	46e1                	li	a3,24
    8000507a:	fb840613          	addi	a2,s0,-72
    8000507e:	85ce                	mv	a1,s3
    80005080:	05093503          	ld	a0,80(s2)
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	706080e7          	jalr	1798(ra) # 8000178a <copyout>
    8000508c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005090:	60a6                	ld	ra,72(sp)
    80005092:	6406                	ld	s0,64(sp)
    80005094:	74e2                	ld	s1,56(sp)
    80005096:	7942                	ld	s2,48(sp)
    80005098:	79a2                	ld	s3,40(sp)
    8000509a:	6161                	addi	sp,sp,80
    8000509c:	8082                	ret
  return -1;
    8000509e:	557d                	li	a0,-1
    800050a0:	bfc5                	j	80005090 <filestat+0x60>

00000000800050a2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800050a2:	7179                	addi	sp,sp,-48
    800050a4:	f406                	sd	ra,40(sp)
    800050a6:	f022                	sd	s0,32(sp)
    800050a8:	ec26                	sd	s1,24(sp)
    800050aa:	e84a                	sd	s2,16(sp)
    800050ac:	e44e                	sd	s3,8(sp)
    800050ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800050b0:	00854783          	lbu	a5,8(a0)
    800050b4:	c3d5                	beqz	a5,80005158 <fileread+0xb6>
    800050b6:	84aa                	mv	s1,a0
    800050b8:	89ae                	mv	s3,a1
    800050ba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800050bc:	411c                	lw	a5,0(a0)
    800050be:	4705                	li	a4,1
    800050c0:	04e78963          	beq	a5,a4,80005112 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050c4:	470d                	li	a4,3
    800050c6:	04e78d63          	beq	a5,a4,80005120 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800050ca:	4709                	li	a4,2
    800050cc:	06e79e63          	bne	a5,a4,80005148 <fileread+0xa6>
    ilock(f->ip);
    800050d0:	6d08                	ld	a0,24(a0)
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	002080e7          	jalr	2(ra) # 800040d4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800050da:	874a                	mv	a4,s2
    800050dc:	5094                	lw	a3,32(s1)
    800050de:	864e                	mv	a2,s3
    800050e0:	4585                	li	a1,1
    800050e2:	6c88                	ld	a0,24(s1)
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	2a4080e7          	jalr	676(ra) # 80004388 <readi>
    800050ec:	892a                	mv	s2,a0
    800050ee:	00a05563          	blez	a0,800050f8 <fileread+0x56>
      f->off += r;
    800050f2:	509c                	lw	a5,32(s1)
    800050f4:	9fa9                	addw	a5,a5,a0
    800050f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800050f8:	6c88                	ld	a0,24(s1)
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	09c080e7          	jalr	156(ra) # 80004196 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005102:	854a                	mv	a0,s2
    80005104:	70a2                	ld	ra,40(sp)
    80005106:	7402                	ld	s0,32(sp)
    80005108:	64e2                	ld	s1,24(sp)
    8000510a:	6942                	ld	s2,16(sp)
    8000510c:	69a2                	ld	s3,8(sp)
    8000510e:	6145                	addi	sp,sp,48
    80005110:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005112:	6908                	ld	a0,16(a0)
    80005114:	00000097          	auipc	ra,0x0
    80005118:	3c6080e7          	jalr	966(ra) # 800054da <piperead>
    8000511c:	892a                	mv	s2,a0
    8000511e:	b7d5                	j	80005102 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005120:	02451783          	lh	a5,36(a0)
    80005124:	03079693          	slli	a3,a5,0x30
    80005128:	92c1                	srli	a3,a3,0x30
    8000512a:	4725                	li	a4,9
    8000512c:	02d76863          	bltu	a4,a3,8000515c <fileread+0xba>
    80005130:	0792                	slli	a5,a5,0x4
    80005132:	0023f717          	auipc	a4,0x23f
    80005136:	17670713          	addi	a4,a4,374 # 802442a8 <devsw>
    8000513a:	97ba                	add	a5,a5,a4
    8000513c:	639c                	ld	a5,0(a5)
    8000513e:	c38d                	beqz	a5,80005160 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005140:	4505                	li	a0,1
    80005142:	9782                	jalr	a5
    80005144:	892a                	mv	s2,a0
    80005146:	bf75                	j	80005102 <fileread+0x60>
    panic("fileread");
    80005148:	00003517          	auipc	a0,0x3
    8000514c:	63050513          	addi	a0,a0,1584 # 80008778 <syscalls+0x288>
    80005150:	ffffb097          	auipc	ra,0xffffb
    80005154:	3f0080e7          	jalr	1008(ra) # 80000540 <panic>
    return -1;
    80005158:	597d                	li	s2,-1
    8000515a:	b765                	j	80005102 <fileread+0x60>
      return -1;
    8000515c:	597d                	li	s2,-1
    8000515e:	b755                	j	80005102 <fileread+0x60>
    80005160:	597d                	li	s2,-1
    80005162:	b745                	j	80005102 <fileread+0x60>

0000000080005164 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005164:	715d                	addi	sp,sp,-80
    80005166:	e486                	sd	ra,72(sp)
    80005168:	e0a2                	sd	s0,64(sp)
    8000516a:	fc26                	sd	s1,56(sp)
    8000516c:	f84a                	sd	s2,48(sp)
    8000516e:	f44e                	sd	s3,40(sp)
    80005170:	f052                	sd	s4,32(sp)
    80005172:	ec56                	sd	s5,24(sp)
    80005174:	e85a                	sd	s6,16(sp)
    80005176:	e45e                	sd	s7,8(sp)
    80005178:	e062                	sd	s8,0(sp)
    8000517a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000517c:	00954783          	lbu	a5,9(a0)
    80005180:	10078663          	beqz	a5,8000528c <filewrite+0x128>
    80005184:	892a                	mv	s2,a0
    80005186:	8b2e                	mv	s6,a1
    80005188:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000518a:	411c                	lw	a5,0(a0)
    8000518c:	4705                	li	a4,1
    8000518e:	02e78263          	beq	a5,a4,800051b2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005192:	470d                	li	a4,3
    80005194:	02e78663          	beq	a5,a4,800051c0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005198:	4709                	li	a4,2
    8000519a:	0ee79163          	bne	a5,a4,8000527c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000519e:	0ac05d63          	blez	a2,80005258 <filewrite+0xf4>
    int i = 0;
    800051a2:	4981                	li	s3,0
    800051a4:	6b85                	lui	s7,0x1
    800051a6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800051aa:	6c05                	lui	s8,0x1
    800051ac:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800051b0:	a861                	j	80005248 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800051b2:	6908                	ld	a0,16(a0)
    800051b4:	00000097          	auipc	ra,0x0
    800051b8:	22e080e7          	jalr	558(ra) # 800053e2 <pipewrite>
    800051bc:	8a2a                	mv	s4,a0
    800051be:	a045                	j	8000525e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051c0:	02451783          	lh	a5,36(a0)
    800051c4:	03079693          	slli	a3,a5,0x30
    800051c8:	92c1                	srli	a3,a3,0x30
    800051ca:	4725                	li	a4,9
    800051cc:	0cd76263          	bltu	a4,a3,80005290 <filewrite+0x12c>
    800051d0:	0792                	slli	a5,a5,0x4
    800051d2:	0023f717          	auipc	a4,0x23f
    800051d6:	0d670713          	addi	a4,a4,214 # 802442a8 <devsw>
    800051da:	97ba                	add	a5,a5,a4
    800051dc:	679c                	ld	a5,8(a5)
    800051de:	cbdd                	beqz	a5,80005294 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800051e0:	4505                	li	a0,1
    800051e2:	9782                	jalr	a5
    800051e4:	8a2a                	mv	s4,a0
    800051e6:	a8a5                	j	8000525e <filewrite+0xfa>
    800051e8:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800051ec:	00000097          	auipc	ra,0x0
    800051f0:	8b4080e7          	jalr	-1868(ra) # 80004aa0 <begin_op>
      ilock(f->ip);
    800051f4:	01893503          	ld	a0,24(s2)
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	edc080e7          	jalr	-292(ra) # 800040d4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005200:	8756                	mv	a4,s5
    80005202:	02092683          	lw	a3,32(s2)
    80005206:	01698633          	add	a2,s3,s6
    8000520a:	4585                	li	a1,1
    8000520c:	01893503          	ld	a0,24(s2)
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	270080e7          	jalr	624(ra) # 80004480 <writei>
    80005218:	84aa                	mv	s1,a0
    8000521a:	00a05763          	blez	a0,80005228 <filewrite+0xc4>
        f->off += r;
    8000521e:	02092783          	lw	a5,32(s2)
    80005222:	9fa9                	addw	a5,a5,a0
    80005224:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005228:	01893503          	ld	a0,24(s2)
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	f6a080e7          	jalr	-150(ra) # 80004196 <iunlock>
      end_op();
    80005234:	00000097          	auipc	ra,0x0
    80005238:	8ea080e7          	jalr	-1814(ra) # 80004b1e <end_op>

      if(r != n1){
    8000523c:	009a9f63          	bne	s5,s1,8000525a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005240:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005244:	0149db63          	bge	s3,s4,8000525a <filewrite+0xf6>
      int n1 = n - i;
    80005248:	413a04bb          	subw	s1,s4,s3
    8000524c:	0004879b          	sext.w	a5,s1
    80005250:	f8fbdce3          	bge	s7,a5,800051e8 <filewrite+0x84>
    80005254:	84e2                	mv	s1,s8
    80005256:	bf49                	j	800051e8 <filewrite+0x84>
    int i = 0;
    80005258:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000525a:	013a1f63          	bne	s4,s3,80005278 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000525e:	8552                	mv	a0,s4
    80005260:	60a6                	ld	ra,72(sp)
    80005262:	6406                	ld	s0,64(sp)
    80005264:	74e2                	ld	s1,56(sp)
    80005266:	7942                	ld	s2,48(sp)
    80005268:	79a2                	ld	s3,40(sp)
    8000526a:	7a02                	ld	s4,32(sp)
    8000526c:	6ae2                	ld	s5,24(sp)
    8000526e:	6b42                	ld	s6,16(sp)
    80005270:	6ba2                	ld	s7,8(sp)
    80005272:	6c02                	ld	s8,0(sp)
    80005274:	6161                	addi	sp,sp,80
    80005276:	8082                	ret
    ret = (i == n ? n : -1);
    80005278:	5a7d                	li	s4,-1
    8000527a:	b7d5                	j	8000525e <filewrite+0xfa>
    panic("filewrite");
    8000527c:	00003517          	auipc	a0,0x3
    80005280:	50c50513          	addi	a0,a0,1292 # 80008788 <syscalls+0x298>
    80005284:	ffffb097          	auipc	ra,0xffffb
    80005288:	2bc080e7          	jalr	700(ra) # 80000540 <panic>
    return -1;
    8000528c:	5a7d                	li	s4,-1
    8000528e:	bfc1                	j	8000525e <filewrite+0xfa>
      return -1;
    80005290:	5a7d                	li	s4,-1
    80005292:	b7f1                	j	8000525e <filewrite+0xfa>
    80005294:	5a7d                	li	s4,-1
    80005296:	b7e1                	j	8000525e <filewrite+0xfa>

0000000080005298 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005298:	7179                	addi	sp,sp,-48
    8000529a:	f406                	sd	ra,40(sp)
    8000529c:	f022                	sd	s0,32(sp)
    8000529e:	ec26                	sd	s1,24(sp)
    800052a0:	e84a                	sd	s2,16(sp)
    800052a2:	e44e                	sd	s3,8(sp)
    800052a4:	e052                	sd	s4,0(sp)
    800052a6:	1800                	addi	s0,sp,48
    800052a8:	84aa                	mv	s1,a0
    800052aa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800052ac:	0005b023          	sd	zero,0(a1)
    800052b0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	bf8080e7          	jalr	-1032(ra) # 80004eac <filealloc>
    800052bc:	e088                	sd	a0,0(s1)
    800052be:	c551                	beqz	a0,8000534a <pipealloc+0xb2>
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	bec080e7          	jalr	-1044(ra) # 80004eac <filealloc>
    800052c8:	00aa3023          	sd	a0,0(s4)
    800052cc:	c92d                	beqz	a0,8000533e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800052ce:	ffffc097          	auipc	ra,0xffffc
    800052d2:	918080e7          	jalr	-1768(ra) # 80000be6 <kalloc>
    800052d6:	892a                	mv	s2,a0
    800052d8:	c125                	beqz	a0,80005338 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800052da:	4985                	li	s3,1
    800052dc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800052e0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800052e4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800052e8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800052ec:	00003597          	auipc	a1,0x3
    800052f0:	4ac58593          	addi	a1,a1,1196 # 80008798 <syscalls+0x2a8>
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	98a080e7          	jalr	-1654(ra) # 80000c7e <initlock>
  (*f0)->type = FD_PIPE;
    800052fc:	609c                	ld	a5,0(s1)
    800052fe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005302:	609c                	ld	a5,0(s1)
    80005304:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005308:	609c                	ld	a5,0(s1)
    8000530a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000530e:	609c                	ld	a5,0(s1)
    80005310:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005314:	000a3783          	ld	a5,0(s4)
    80005318:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000531c:	000a3783          	ld	a5,0(s4)
    80005320:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005324:	000a3783          	ld	a5,0(s4)
    80005328:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000532c:	000a3783          	ld	a5,0(s4)
    80005330:	0127b823          	sd	s2,16(a5)
  return 0;
    80005334:	4501                	li	a0,0
    80005336:	a025                	j	8000535e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005338:	6088                	ld	a0,0(s1)
    8000533a:	e501                	bnez	a0,80005342 <pipealloc+0xaa>
    8000533c:	a039                	j	8000534a <pipealloc+0xb2>
    8000533e:	6088                	ld	a0,0(s1)
    80005340:	c51d                	beqz	a0,8000536e <pipealloc+0xd6>
    fileclose(*f0);
    80005342:	00000097          	auipc	ra,0x0
    80005346:	c26080e7          	jalr	-986(ra) # 80004f68 <fileclose>
  if(*f1)
    8000534a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000534e:	557d                	li	a0,-1
  if(*f1)
    80005350:	c799                	beqz	a5,8000535e <pipealloc+0xc6>
    fileclose(*f1);
    80005352:	853e                	mv	a0,a5
    80005354:	00000097          	auipc	ra,0x0
    80005358:	c14080e7          	jalr	-1004(ra) # 80004f68 <fileclose>
  return -1;
    8000535c:	557d                	li	a0,-1
}
    8000535e:	70a2                	ld	ra,40(sp)
    80005360:	7402                	ld	s0,32(sp)
    80005362:	64e2                	ld	s1,24(sp)
    80005364:	6942                	ld	s2,16(sp)
    80005366:	69a2                	ld	s3,8(sp)
    80005368:	6a02                	ld	s4,0(sp)
    8000536a:	6145                	addi	sp,sp,48
    8000536c:	8082                	ret
  return -1;
    8000536e:	557d                	li	a0,-1
    80005370:	b7fd                	j	8000535e <pipealloc+0xc6>

0000000080005372 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005372:	1101                	addi	sp,sp,-32
    80005374:	ec06                	sd	ra,24(sp)
    80005376:	e822                	sd	s0,16(sp)
    80005378:	e426                	sd	s1,8(sp)
    8000537a:	e04a                	sd	s2,0(sp)
    8000537c:	1000                	addi	s0,sp,32
    8000537e:	84aa                	mv	s1,a0
    80005380:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	98c080e7          	jalr	-1652(ra) # 80000d0e <acquire>
  if(writable){
    8000538a:	02090d63          	beqz	s2,800053c4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000538e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005392:	21848513          	addi	a0,s1,536
    80005396:	ffffd097          	auipc	ra,0xffffd
    8000539a:	2ac080e7          	jalr	684(ra) # 80002642 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000539e:	2204b783          	ld	a5,544(s1)
    800053a2:	eb95                	bnez	a5,800053d6 <pipeclose+0x64>
    release(&pi->lock);
    800053a4:	8526                	mv	a0,s1
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	a1c080e7          	jalr	-1508(ra) # 80000dc2 <release>
    kfree((char*)pi);
    800053ae:	8526                	mv	a0,s1
    800053b0:	ffffb097          	auipc	ra,0xffffb
    800053b4:	6b0080e7          	jalr	1712(ra) # 80000a60 <kfree>
  } else
    release(&pi->lock);
}
    800053b8:	60e2                	ld	ra,24(sp)
    800053ba:	6442                	ld	s0,16(sp)
    800053bc:	64a2                	ld	s1,8(sp)
    800053be:	6902                	ld	s2,0(sp)
    800053c0:	6105                	addi	sp,sp,32
    800053c2:	8082                	ret
    pi->readopen = 0;
    800053c4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800053c8:	21c48513          	addi	a0,s1,540
    800053cc:	ffffd097          	auipc	ra,0xffffd
    800053d0:	276080e7          	jalr	630(ra) # 80002642 <wakeup>
    800053d4:	b7e9                	j	8000539e <pipeclose+0x2c>
    release(&pi->lock);
    800053d6:	8526                	mv	a0,s1
    800053d8:	ffffc097          	auipc	ra,0xffffc
    800053dc:	9ea080e7          	jalr	-1558(ra) # 80000dc2 <release>
}
    800053e0:	bfe1                	j	800053b8 <pipeclose+0x46>

00000000800053e2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800053e2:	711d                	addi	sp,sp,-96
    800053e4:	ec86                	sd	ra,88(sp)
    800053e6:	e8a2                	sd	s0,80(sp)
    800053e8:	e4a6                	sd	s1,72(sp)
    800053ea:	e0ca                	sd	s2,64(sp)
    800053ec:	fc4e                	sd	s3,56(sp)
    800053ee:	f852                	sd	s4,48(sp)
    800053f0:	f456                	sd	s5,40(sp)
    800053f2:	f05a                	sd	s6,32(sp)
    800053f4:	ec5e                	sd	s7,24(sp)
    800053f6:	e862                	sd	s8,16(sp)
    800053f8:	1080                	addi	s0,sp,96
    800053fa:	84aa                	mv	s1,a0
    800053fc:	8aae                	mv	s5,a1
    800053fe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005400:	ffffd097          	auipc	ra,0xffffd
    80005404:	8ea080e7          	jalr	-1814(ra) # 80001cea <myproc>
    80005408:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000540a:	8526                	mv	a0,s1
    8000540c:	ffffc097          	auipc	ra,0xffffc
    80005410:	902080e7          	jalr	-1790(ra) # 80000d0e <acquire>
  while(i < n){
    80005414:	0b405663          	blez	s4,800054c0 <pipewrite+0xde>
  int i = 0;
    80005418:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000541a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000541c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005420:	21c48b93          	addi	s7,s1,540
    80005424:	a089                	j	80005466 <pipewrite+0x84>
      release(&pi->lock);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	99a080e7          	jalr	-1638(ra) # 80000dc2 <release>
      return -1;
    80005430:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005432:	854a                	mv	a0,s2
    80005434:	60e6                	ld	ra,88(sp)
    80005436:	6446                	ld	s0,80(sp)
    80005438:	64a6                	ld	s1,72(sp)
    8000543a:	6906                	ld	s2,64(sp)
    8000543c:	79e2                	ld	s3,56(sp)
    8000543e:	7a42                	ld	s4,48(sp)
    80005440:	7aa2                	ld	s5,40(sp)
    80005442:	7b02                	ld	s6,32(sp)
    80005444:	6be2                	ld	s7,24(sp)
    80005446:	6c42                	ld	s8,16(sp)
    80005448:	6125                	addi	sp,sp,96
    8000544a:	8082                	ret
      wakeup(&pi->nread);
    8000544c:	8562                	mv	a0,s8
    8000544e:	ffffd097          	auipc	ra,0xffffd
    80005452:	1f4080e7          	jalr	500(ra) # 80002642 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005456:	85a6                	mv	a1,s1
    80005458:	855e                	mv	a0,s7
    8000545a:	ffffd097          	auipc	ra,0xffffd
    8000545e:	184080e7          	jalr	388(ra) # 800025de <sleep>
  while(i < n){
    80005462:	07495063          	bge	s2,s4,800054c2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005466:	2204a783          	lw	a5,544(s1)
    8000546a:	dfd5                	beqz	a5,80005426 <pipewrite+0x44>
    8000546c:	854e                	mv	a0,s3
    8000546e:	ffffd097          	auipc	ra,0xffffd
    80005472:	424080e7          	jalr	1060(ra) # 80002892 <killed>
    80005476:	f945                	bnez	a0,80005426 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005478:	2184a783          	lw	a5,536(s1)
    8000547c:	21c4a703          	lw	a4,540(s1)
    80005480:	2007879b          	addiw	a5,a5,512
    80005484:	fcf704e3          	beq	a4,a5,8000544c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005488:	4685                	li	a3,1
    8000548a:	01590633          	add	a2,s2,s5
    8000548e:	faf40593          	addi	a1,s0,-81
    80005492:	0509b503          	ld	a0,80(s3)
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	3ae080e7          	jalr	942(ra) # 80001844 <copyin>
    8000549e:	03650263          	beq	a0,s6,800054c2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800054a2:	21c4a783          	lw	a5,540(s1)
    800054a6:	0017871b          	addiw	a4,a5,1
    800054aa:	20e4ae23          	sw	a4,540(s1)
    800054ae:	1ff7f793          	andi	a5,a5,511
    800054b2:	97a6                	add	a5,a5,s1
    800054b4:	faf44703          	lbu	a4,-81(s0)
    800054b8:	00e78c23          	sb	a4,24(a5)
      i++;
    800054bc:	2905                	addiw	s2,s2,1
    800054be:	b755                	j	80005462 <pipewrite+0x80>
  int i = 0;
    800054c0:	4901                	li	s2,0
  wakeup(&pi->nread);
    800054c2:	21848513          	addi	a0,s1,536
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	17c080e7          	jalr	380(ra) # 80002642 <wakeup>
  release(&pi->lock);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	8f2080e7          	jalr	-1806(ra) # 80000dc2 <release>
  return i;
    800054d8:	bfa9                	j	80005432 <pipewrite+0x50>

00000000800054da <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800054da:	715d                	addi	sp,sp,-80
    800054dc:	e486                	sd	ra,72(sp)
    800054de:	e0a2                	sd	s0,64(sp)
    800054e0:	fc26                	sd	s1,56(sp)
    800054e2:	f84a                	sd	s2,48(sp)
    800054e4:	f44e                	sd	s3,40(sp)
    800054e6:	f052                	sd	s4,32(sp)
    800054e8:	ec56                	sd	s5,24(sp)
    800054ea:	e85a                	sd	s6,16(sp)
    800054ec:	0880                	addi	s0,sp,80
    800054ee:	84aa                	mv	s1,a0
    800054f0:	892e                	mv	s2,a1
    800054f2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800054f4:	ffffc097          	auipc	ra,0xffffc
    800054f8:	7f6080e7          	jalr	2038(ra) # 80001cea <myproc>
    800054fc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	80e080e7          	jalr	-2034(ra) # 80000d0e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005508:	2184a703          	lw	a4,536(s1)
    8000550c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005510:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005514:	02f71763          	bne	a4,a5,80005542 <piperead+0x68>
    80005518:	2244a783          	lw	a5,548(s1)
    8000551c:	c39d                	beqz	a5,80005542 <piperead+0x68>
    if(killed(pr)){
    8000551e:	8552                	mv	a0,s4
    80005520:	ffffd097          	auipc	ra,0xffffd
    80005524:	372080e7          	jalr	882(ra) # 80002892 <killed>
    80005528:	e949                	bnez	a0,800055ba <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000552a:	85a6                	mv	a1,s1
    8000552c:	854e                	mv	a0,s3
    8000552e:	ffffd097          	auipc	ra,0xffffd
    80005532:	0b0080e7          	jalr	176(ra) # 800025de <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005536:	2184a703          	lw	a4,536(s1)
    8000553a:	21c4a783          	lw	a5,540(s1)
    8000553e:	fcf70de3          	beq	a4,a5,80005518 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005542:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005544:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005546:	05505463          	blez	s5,8000558e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000554a:	2184a783          	lw	a5,536(s1)
    8000554e:	21c4a703          	lw	a4,540(s1)
    80005552:	02f70e63          	beq	a4,a5,8000558e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005556:	0017871b          	addiw	a4,a5,1
    8000555a:	20e4ac23          	sw	a4,536(s1)
    8000555e:	1ff7f793          	andi	a5,a5,511
    80005562:	97a6                	add	a5,a5,s1
    80005564:	0187c783          	lbu	a5,24(a5)
    80005568:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000556c:	4685                	li	a3,1
    8000556e:	fbf40613          	addi	a2,s0,-65
    80005572:	85ca                	mv	a1,s2
    80005574:	050a3503          	ld	a0,80(s4)
    80005578:	ffffc097          	auipc	ra,0xffffc
    8000557c:	212080e7          	jalr	530(ra) # 8000178a <copyout>
    80005580:	01650763          	beq	a0,s6,8000558e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005584:	2985                	addiw	s3,s3,1
    80005586:	0905                	addi	s2,s2,1
    80005588:	fd3a91e3          	bne	s5,s3,8000554a <piperead+0x70>
    8000558c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000558e:	21c48513          	addi	a0,s1,540
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	0b0080e7          	jalr	176(ra) # 80002642 <wakeup>
  release(&pi->lock);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	826080e7          	jalr	-2010(ra) # 80000dc2 <release>
  return i;
}
    800055a4:	854e                	mv	a0,s3
    800055a6:	60a6                	ld	ra,72(sp)
    800055a8:	6406                	ld	s0,64(sp)
    800055aa:	74e2                	ld	s1,56(sp)
    800055ac:	7942                	ld	s2,48(sp)
    800055ae:	79a2                	ld	s3,40(sp)
    800055b0:	7a02                	ld	s4,32(sp)
    800055b2:	6ae2                	ld	s5,24(sp)
    800055b4:	6b42                	ld	s6,16(sp)
    800055b6:	6161                	addi	sp,sp,80
    800055b8:	8082                	ret
      release(&pi->lock);
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	806080e7          	jalr	-2042(ra) # 80000dc2 <release>
      return -1;
    800055c4:	59fd                	li	s3,-1
    800055c6:	bff9                	j	800055a4 <piperead+0xca>

00000000800055c8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800055c8:	1141                	addi	sp,sp,-16
    800055ca:	e422                	sd	s0,8(sp)
    800055cc:	0800                	addi	s0,sp,16
    800055ce:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800055d0:	8905                	andi	a0,a0,1
    800055d2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800055d4:	8b89                	andi	a5,a5,2
    800055d6:	c399                	beqz	a5,800055dc <flags2perm+0x14>
      perm |= PTE_W;
    800055d8:	00456513          	ori	a0,a0,4
    return perm;
}
    800055dc:	6422                	ld	s0,8(sp)
    800055de:	0141                	addi	sp,sp,16
    800055e0:	8082                	ret

00000000800055e2 <exec>:

int
exec(char *path, char **argv)
{
    800055e2:	de010113          	addi	sp,sp,-544
    800055e6:	20113c23          	sd	ra,536(sp)
    800055ea:	20813823          	sd	s0,528(sp)
    800055ee:	20913423          	sd	s1,520(sp)
    800055f2:	21213023          	sd	s2,512(sp)
    800055f6:	ffce                	sd	s3,504(sp)
    800055f8:	fbd2                	sd	s4,496(sp)
    800055fa:	f7d6                	sd	s5,488(sp)
    800055fc:	f3da                	sd	s6,480(sp)
    800055fe:	efde                	sd	s7,472(sp)
    80005600:	ebe2                	sd	s8,464(sp)
    80005602:	e7e6                	sd	s9,456(sp)
    80005604:	e3ea                	sd	s10,448(sp)
    80005606:	ff6e                	sd	s11,440(sp)
    80005608:	1400                	addi	s0,sp,544
    8000560a:	892a                	mv	s2,a0
    8000560c:	dea43423          	sd	a0,-536(s0)
    80005610:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005614:	ffffc097          	auipc	ra,0xffffc
    80005618:	6d6080e7          	jalr	1750(ra) # 80001cea <myproc>
    8000561c:	84aa                	mv	s1,a0

  begin_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	482080e7          	jalr	1154(ra) # 80004aa0 <begin_op>

  if((ip = namei(path)) == 0){
    80005626:	854a                	mv	a0,s2
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	258080e7          	jalr	600(ra) # 80004880 <namei>
    80005630:	c93d                	beqz	a0,800056a6 <exec+0xc4>
    80005632:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	aa0080e7          	jalr	-1376(ra) # 800040d4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000563c:	04000713          	li	a4,64
    80005640:	4681                	li	a3,0
    80005642:	e5040613          	addi	a2,s0,-432
    80005646:	4581                	li	a1,0
    80005648:	8556                	mv	a0,s5
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	d3e080e7          	jalr	-706(ra) # 80004388 <readi>
    80005652:	04000793          	li	a5,64
    80005656:	00f51a63          	bne	a0,a5,8000566a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000565a:	e5042703          	lw	a4,-432(s0)
    8000565e:	464c47b7          	lui	a5,0x464c4
    80005662:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005666:	04f70663          	beq	a4,a5,800056b2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000566a:	8556                	mv	a0,s5
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	cca080e7          	jalr	-822(ra) # 80004336 <iunlockput>
    end_op();
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	4aa080e7          	jalr	1194(ra) # 80004b1e <end_op>
  }
  return -1;
    8000567c:	557d                	li	a0,-1
}
    8000567e:	21813083          	ld	ra,536(sp)
    80005682:	21013403          	ld	s0,528(sp)
    80005686:	20813483          	ld	s1,520(sp)
    8000568a:	20013903          	ld	s2,512(sp)
    8000568e:	79fe                	ld	s3,504(sp)
    80005690:	7a5e                	ld	s4,496(sp)
    80005692:	7abe                	ld	s5,488(sp)
    80005694:	7b1e                	ld	s6,480(sp)
    80005696:	6bfe                	ld	s7,472(sp)
    80005698:	6c5e                	ld	s8,464(sp)
    8000569a:	6cbe                	ld	s9,456(sp)
    8000569c:	6d1e                	ld	s10,448(sp)
    8000569e:	7dfa                	ld	s11,440(sp)
    800056a0:	22010113          	addi	sp,sp,544
    800056a4:	8082                	ret
    end_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	478080e7          	jalr	1144(ra) # 80004b1e <end_op>
    return -1;
    800056ae:	557d                	li	a0,-1
    800056b0:	b7f9                	j	8000567e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffc097          	auipc	ra,0xffffc
    800056b8:	6fa080e7          	jalr	1786(ra) # 80001dae <proc_pagetable>
    800056bc:	8b2a                	mv	s6,a0
    800056be:	d555                	beqz	a0,8000566a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056c0:	e7042783          	lw	a5,-400(s0)
    800056c4:	e8845703          	lhu	a4,-376(s0)
    800056c8:	c735                	beqz	a4,80005734 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056ca:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056cc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800056d0:	6a05                	lui	s4,0x1
    800056d2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800056d6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800056da:	6d85                	lui	s11,0x1
    800056dc:	7d7d                	lui	s10,0xfffff
    800056de:	ac3d                	j	8000591c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800056e0:	00003517          	auipc	a0,0x3
    800056e4:	0c050513          	addi	a0,a0,192 # 800087a0 <syscalls+0x2b0>
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	e58080e7          	jalr	-424(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800056f0:	874a                	mv	a4,s2
    800056f2:	009c86bb          	addw	a3,s9,s1
    800056f6:	4581                	li	a1,0
    800056f8:	8556                	mv	a0,s5
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	c8e080e7          	jalr	-882(ra) # 80004388 <readi>
    80005702:	2501                	sext.w	a0,a0
    80005704:	1aa91963          	bne	s2,a0,800058b6 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005708:	009d84bb          	addw	s1,s11,s1
    8000570c:	013d09bb          	addw	s3,s10,s3
    80005710:	1f74f663          	bgeu	s1,s7,800058fc <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005714:	02049593          	slli	a1,s1,0x20
    80005718:	9181                	srli	a1,a1,0x20
    8000571a:	95e2                	add	a1,a1,s8
    8000571c:	855a                	mv	a0,s6
    8000571e:	ffffc097          	auipc	ra,0xffffc
    80005722:	a76080e7          	jalr	-1418(ra) # 80001194 <walkaddr>
    80005726:	862a                	mv	a2,a0
    if(pa == 0)
    80005728:	dd45                	beqz	a0,800056e0 <exec+0xfe>
      n = PGSIZE;
    8000572a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000572c:	fd49f2e3          	bgeu	s3,s4,800056f0 <exec+0x10e>
      n = sz - i;
    80005730:	894e                	mv	s2,s3
    80005732:	bf7d                	j	800056f0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005734:	4901                	li	s2,0
  iunlockput(ip);
    80005736:	8556                	mv	a0,s5
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	bfe080e7          	jalr	-1026(ra) # 80004336 <iunlockput>
  end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	3de080e7          	jalr	990(ra) # 80004b1e <end_op>
  p = myproc();
    80005748:	ffffc097          	auipc	ra,0xffffc
    8000574c:	5a2080e7          	jalr	1442(ra) # 80001cea <myproc>
    80005750:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005752:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005756:	6785                	lui	a5,0x1
    80005758:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000575a:	97ca                	add	a5,a5,s2
    8000575c:	777d                	lui	a4,0xfffff
    8000575e:	8ff9                	and	a5,a5,a4
    80005760:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005764:	4691                	li	a3,4
    80005766:	6609                	lui	a2,0x2
    80005768:	963e                	add	a2,a2,a5
    8000576a:	85be                	mv	a1,a5
    8000576c:	855a                	mv	a0,s6
    8000576e:	ffffc097          	auipc	ra,0xffffc
    80005772:	dda080e7          	jalr	-550(ra) # 80001548 <uvmalloc>
    80005776:	8c2a                	mv	s8,a0
  ip = 0;
    80005778:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000577a:	12050e63          	beqz	a0,800058b6 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000577e:	75f9                	lui	a1,0xffffe
    80005780:	95aa                	add	a1,a1,a0
    80005782:	855a                	mv	a0,s6
    80005784:	ffffc097          	auipc	ra,0xffffc
    80005788:	fd4080e7          	jalr	-44(ra) # 80001758 <uvmclear>
  stackbase = sp - PGSIZE;
    8000578c:	7afd                	lui	s5,0xfffff
    8000578e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005790:	df043783          	ld	a5,-528(s0)
    80005794:	6388                	ld	a0,0(a5)
    80005796:	c925                	beqz	a0,80005806 <exec+0x224>
    80005798:	e9040993          	addi	s3,s0,-368
    8000579c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800057a0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800057a2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	7e2080e7          	jalr	2018(ra) # 80000f86 <strlen>
    800057ac:	0015079b          	addiw	a5,a0,1
    800057b0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800057b4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800057b8:	13596663          	bltu	s2,s5,800058e4 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800057bc:	df043d83          	ld	s11,-528(s0)
    800057c0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800057c4:	8552                	mv	a0,s4
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	7c0080e7          	jalr	1984(ra) # 80000f86 <strlen>
    800057ce:	0015069b          	addiw	a3,a0,1
    800057d2:	8652                	mv	a2,s4
    800057d4:	85ca                	mv	a1,s2
    800057d6:	855a                	mv	a0,s6
    800057d8:	ffffc097          	auipc	ra,0xffffc
    800057dc:	fb2080e7          	jalr	-78(ra) # 8000178a <copyout>
    800057e0:	10054663          	bltz	a0,800058ec <exec+0x30a>
    ustack[argc] = sp;
    800057e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800057e8:	0485                	addi	s1,s1,1
    800057ea:	008d8793          	addi	a5,s11,8
    800057ee:	def43823          	sd	a5,-528(s0)
    800057f2:	008db503          	ld	a0,8(s11)
    800057f6:	c911                	beqz	a0,8000580a <exec+0x228>
    if(argc >= MAXARG)
    800057f8:	09a1                	addi	s3,s3,8
    800057fa:	fb3c95e3          	bne	s9,s3,800057a4 <exec+0x1c2>
  sz = sz1;
    800057fe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005802:	4a81                	li	s5,0
    80005804:	a84d                	j	800058b6 <exec+0x2d4>
  sp = sz;
    80005806:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005808:	4481                	li	s1,0
  ustack[argc] = 0;
    8000580a:	00349793          	slli	a5,s1,0x3
    8000580e:	f9078793          	addi	a5,a5,-112
    80005812:	97a2                	add	a5,a5,s0
    80005814:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005818:	00148693          	addi	a3,s1,1
    8000581c:	068e                	slli	a3,a3,0x3
    8000581e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005822:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005826:	01597663          	bgeu	s2,s5,80005832 <exec+0x250>
  sz = sz1;
    8000582a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000582e:	4a81                	li	s5,0
    80005830:	a059                	j	800058b6 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005832:	e9040613          	addi	a2,s0,-368
    80005836:	85ca                	mv	a1,s2
    80005838:	855a                	mv	a0,s6
    8000583a:	ffffc097          	auipc	ra,0xffffc
    8000583e:	f50080e7          	jalr	-176(ra) # 8000178a <copyout>
    80005842:	0a054963          	bltz	a0,800058f4 <exec+0x312>
  p->trapframe->a1 = sp;
    80005846:	058bb783          	ld	a5,88(s7)
    8000584a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000584e:	de843783          	ld	a5,-536(s0)
    80005852:	0007c703          	lbu	a4,0(a5)
    80005856:	cf11                	beqz	a4,80005872 <exec+0x290>
    80005858:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000585a:	02f00693          	li	a3,47
    8000585e:	a039                	j	8000586c <exec+0x28a>
      last = s+1;
    80005860:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005864:	0785                	addi	a5,a5,1
    80005866:	fff7c703          	lbu	a4,-1(a5)
    8000586a:	c701                	beqz	a4,80005872 <exec+0x290>
    if(*s == '/')
    8000586c:	fed71ce3          	bne	a4,a3,80005864 <exec+0x282>
    80005870:	bfc5                	j	80005860 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005872:	4641                	li	a2,16
    80005874:	de843583          	ld	a1,-536(s0)
    80005878:	158b8513          	addi	a0,s7,344
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	6d8080e7          	jalr	1752(ra) # 80000f54 <safestrcpy>
  oldpagetable = p->pagetable;
    80005884:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005888:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000588c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005890:	058bb783          	ld	a5,88(s7)
    80005894:	e6843703          	ld	a4,-408(s0)
    80005898:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000589a:	058bb783          	ld	a5,88(s7)
    8000589e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800058a2:	85ea                	mv	a1,s10
    800058a4:	ffffc097          	auipc	ra,0xffffc
    800058a8:	5a6080e7          	jalr	1446(ra) # 80001e4a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800058ac:	0004851b          	sext.w	a0,s1
    800058b0:	b3f9                	j	8000567e <exec+0x9c>
    800058b2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800058b6:	df843583          	ld	a1,-520(s0)
    800058ba:	855a                	mv	a0,s6
    800058bc:	ffffc097          	auipc	ra,0xffffc
    800058c0:	58e080e7          	jalr	1422(ra) # 80001e4a <proc_freepagetable>
  if(ip){
    800058c4:	da0a93e3          	bnez	s5,8000566a <exec+0x88>
  return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	bb55                	j	8000567e <exec+0x9c>
    800058cc:	df243c23          	sd	s2,-520(s0)
    800058d0:	b7dd                	j	800058b6 <exec+0x2d4>
    800058d2:	df243c23          	sd	s2,-520(s0)
    800058d6:	b7c5                	j	800058b6 <exec+0x2d4>
    800058d8:	df243c23          	sd	s2,-520(s0)
    800058dc:	bfe9                	j	800058b6 <exec+0x2d4>
    800058de:	df243c23          	sd	s2,-520(s0)
    800058e2:	bfd1                	j	800058b6 <exec+0x2d4>
  sz = sz1;
    800058e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058e8:	4a81                	li	s5,0
    800058ea:	b7f1                	j	800058b6 <exec+0x2d4>
  sz = sz1;
    800058ec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058f0:	4a81                	li	s5,0
    800058f2:	b7d1                	j	800058b6 <exec+0x2d4>
  sz = sz1;
    800058f4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058f8:	4a81                	li	s5,0
    800058fa:	bf75                	j	800058b6 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800058fc:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005900:	e0843783          	ld	a5,-504(s0)
    80005904:	0017869b          	addiw	a3,a5,1
    80005908:	e0d43423          	sd	a3,-504(s0)
    8000590c:	e0043783          	ld	a5,-512(s0)
    80005910:	0387879b          	addiw	a5,a5,56
    80005914:	e8845703          	lhu	a4,-376(s0)
    80005918:	e0e6dfe3          	bge	a3,a4,80005736 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000591c:	2781                	sext.w	a5,a5
    8000591e:	e0f43023          	sd	a5,-512(s0)
    80005922:	03800713          	li	a4,56
    80005926:	86be                	mv	a3,a5
    80005928:	e1840613          	addi	a2,s0,-488
    8000592c:	4581                	li	a1,0
    8000592e:	8556                	mv	a0,s5
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	a58080e7          	jalr	-1448(ra) # 80004388 <readi>
    80005938:	03800793          	li	a5,56
    8000593c:	f6f51be3          	bne	a0,a5,800058b2 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005940:	e1842783          	lw	a5,-488(s0)
    80005944:	4705                	li	a4,1
    80005946:	fae79de3          	bne	a5,a4,80005900 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000594a:	e4043483          	ld	s1,-448(s0)
    8000594e:	e3843783          	ld	a5,-456(s0)
    80005952:	f6f4ede3          	bltu	s1,a5,800058cc <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005956:	e2843783          	ld	a5,-472(s0)
    8000595a:	94be                	add	s1,s1,a5
    8000595c:	f6f4ebe3          	bltu	s1,a5,800058d2 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005960:	de043703          	ld	a4,-544(s0)
    80005964:	8ff9                	and	a5,a5,a4
    80005966:	fbad                	bnez	a5,800058d8 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005968:	e1c42503          	lw	a0,-484(s0)
    8000596c:	00000097          	auipc	ra,0x0
    80005970:	c5c080e7          	jalr	-932(ra) # 800055c8 <flags2perm>
    80005974:	86aa                	mv	a3,a0
    80005976:	8626                	mv	a2,s1
    80005978:	85ca                	mv	a1,s2
    8000597a:	855a                	mv	a0,s6
    8000597c:	ffffc097          	auipc	ra,0xffffc
    80005980:	bcc080e7          	jalr	-1076(ra) # 80001548 <uvmalloc>
    80005984:	dea43c23          	sd	a0,-520(s0)
    80005988:	d939                	beqz	a0,800058de <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000598a:	e2843c03          	ld	s8,-472(s0)
    8000598e:	e2042c83          	lw	s9,-480(s0)
    80005992:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005996:	f60b83e3          	beqz	s7,800058fc <exec+0x31a>
    8000599a:	89de                	mv	s3,s7
    8000599c:	4481                	li	s1,0
    8000599e:	bb9d                	j	80005714 <exec+0x132>

00000000800059a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800059a0:	7179                	addi	sp,sp,-48
    800059a2:	f406                	sd	ra,40(sp)
    800059a4:	f022                	sd	s0,32(sp)
    800059a6:	ec26                	sd	s1,24(sp)
    800059a8:	e84a                	sd	s2,16(sp)
    800059aa:	1800                	addi	s0,sp,48
    800059ac:	892e                	mv	s2,a1
    800059ae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800059b0:	fdc40593          	addi	a1,s0,-36
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	99e080e7          	jalr	-1634(ra) # 80003352 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800059bc:	fdc42703          	lw	a4,-36(s0)
    800059c0:	47bd                	li	a5,15
    800059c2:	02e7eb63          	bltu	a5,a4,800059f8 <argfd+0x58>
    800059c6:	ffffc097          	auipc	ra,0xffffc
    800059ca:	324080e7          	jalr	804(ra) # 80001cea <myproc>
    800059ce:	fdc42703          	lw	a4,-36(s0)
    800059d2:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdb9bda>
    800059d6:	078e                	slli	a5,a5,0x3
    800059d8:	953e                	add	a0,a0,a5
    800059da:	611c                	ld	a5,0(a0)
    800059dc:	c385                	beqz	a5,800059fc <argfd+0x5c>
    return -1;
  if(pfd)
    800059de:	00090463          	beqz	s2,800059e6 <argfd+0x46>
    *pfd = fd;
    800059e2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800059e6:	4501                	li	a0,0
  if(pf)
    800059e8:	c091                	beqz	s1,800059ec <argfd+0x4c>
    *pf = f;
    800059ea:	e09c                	sd	a5,0(s1)
}
    800059ec:	70a2                	ld	ra,40(sp)
    800059ee:	7402                	ld	s0,32(sp)
    800059f0:	64e2                	ld	s1,24(sp)
    800059f2:	6942                	ld	s2,16(sp)
    800059f4:	6145                	addi	sp,sp,48
    800059f6:	8082                	ret
    return -1;
    800059f8:	557d                	li	a0,-1
    800059fa:	bfcd                	j	800059ec <argfd+0x4c>
    800059fc:	557d                	li	a0,-1
    800059fe:	b7fd                	j	800059ec <argfd+0x4c>

0000000080005a00 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a00:	1101                	addi	sp,sp,-32
    80005a02:	ec06                	sd	ra,24(sp)
    80005a04:	e822                	sd	s0,16(sp)
    80005a06:	e426                	sd	s1,8(sp)
    80005a08:	1000                	addi	s0,sp,32
    80005a0a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a0c:	ffffc097          	auipc	ra,0xffffc
    80005a10:	2de080e7          	jalr	734(ra) # 80001cea <myproc>
    80005a14:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005a16:	0d050793          	addi	a5,a0,208
    80005a1a:	4501                	li	a0,0
    80005a1c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a1e:	6398                	ld	a4,0(a5)
    80005a20:	cb19                	beqz	a4,80005a36 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a22:	2505                	addiw	a0,a0,1
    80005a24:	07a1                	addi	a5,a5,8
    80005a26:	fed51ce3          	bne	a0,a3,80005a1e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a2a:	557d                	li	a0,-1
}
    80005a2c:	60e2                	ld	ra,24(sp)
    80005a2e:	6442                	ld	s0,16(sp)
    80005a30:	64a2                	ld	s1,8(sp)
    80005a32:	6105                	addi	sp,sp,32
    80005a34:	8082                	ret
      p->ofile[fd] = f;
    80005a36:	01a50793          	addi	a5,a0,26
    80005a3a:	078e                	slli	a5,a5,0x3
    80005a3c:	963e                	add	a2,a2,a5
    80005a3e:	e204                	sd	s1,0(a2)
      return fd;
    80005a40:	b7f5                	j	80005a2c <fdalloc+0x2c>

0000000080005a42 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005a42:	715d                	addi	sp,sp,-80
    80005a44:	e486                	sd	ra,72(sp)
    80005a46:	e0a2                	sd	s0,64(sp)
    80005a48:	fc26                	sd	s1,56(sp)
    80005a4a:	f84a                	sd	s2,48(sp)
    80005a4c:	f44e                	sd	s3,40(sp)
    80005a4e:	f052                	sd	s4,32(sp)
    80005a50:	ec56                	sd	s5,24(sp)
    80005a52:	e85a                	sd	s6,16(sp)
    80005a54:	0880                	addi	s0,sp,80
    80005a56:	8b2e                	mv	s6,a1
    80005a58:	89b2                	mv	s3,a2
    80005a5a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005a5c:	fb040593          	addi	a1,s0,-80
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	e3e080e7          	jalr	-450(ra) # 8000489e <nameiparent>
    80005a68:	84aa                	mv	s1,a0
    80005a6a:	14050f63          	beqz	a0,80005bc8 <create+0x186>
    return 0;

  ilock(dp);
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	666080e7          	jalr	1638(ra) # 800040d4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005a76:	4601                	li	a2,0
    80005a78:	fb040593          	addi	a1,s0,-80
    80005a7c:	8526                	mv	a0,s1
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	b3a080e7          	jalr	-1222(ra) # 800045b8 <dirlookup>
    80005a86:	8aaa                	mv	s5,a0
    80005a88:	c931                	beqz	a0,80005adc <create+0x9a>
    iunlockput(dp);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	8aa080e7          	jalr	-1878(ra) # 80004336 <iunlockput>
    ilock(ip);
    80005a94:	8556                	mv	a0,s5
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	63e080e7          	jalr	1598(ra) # 800040d4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005a9e:	000b059b          	sext.w	a1,s6
    80005aa2:	4789                	li	a5,2
    80005aa4:	02f59563          	bne	a1,a5,80005ace <create+0x8c>
    80005aa8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdb9c04>
    80005aac:	37f9                	addiw	a5,a5,-2
    80005aae:	17c2                	slli	a5,a5,0x30
    80005ab0:	93c1                	srli	a5,a5,0x30
    80005ab2:	4705                	li	a4,1
    80005ab4:	00f76d63          	bltu	a4,a5,80005ace <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005ab8:	8556                	mv	a0,s5
    80005aba:	60a6                	ld	ra,72(sp)
    80005abc:	6406                	ld	s0,64(sp)
    80005abe:	74e2                	ld	s1,56(sp)
    80005ac0:	7942                	ld	s2,48(sp)
    80005ac2:	79a2                	ld	s3,40(sp)
    80005ac4:	7a02                	ld	s4,32(sp)
    80005ac6:	6ae2                	ld	s5,24(sp)
    80005ac8:	6b42                	ld	s6,16(sp)
    80005aca:	6161                	addi	sp,sp,80
    80005acc:	8082                	ret
    iunlockput(ip);
    80005ace:	8556                	mv	a0,s5
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	866080e7          	jalr	-1946(ra) # 80004336 <iunlockput>
    return 0;
    80005ad8:	4a81                	li	s5,0
    80005ada:	bff9                	j	80005ab8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005adc:	85da                	mv	a1,s6
    80005ade:	4088                	lw	a0,0(s1)
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	456080e7          	jalr	1110(ra) # 80003f36 <ialloc>
    80005ae8:	8a2a                	mv	s4,a0
    80005aea:	c539                	beqz	a0,80005b38 <create+0xf6>
  ilock(ip);
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	5e8080e7          	jalr	1512(ra) # 800040d4 <ilock>
  ip->major = major;
    80005af4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005af8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005afc:	4905                	li	s2,1
    80005afe:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005b02:	8552                	mv	a0,s4
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	504080e7          	jalr	1284(ra) # 80004008 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005b0c:	000b059b          	sext.w	a1,s6
    80005b10:	03258b63          	beq	a1,s2,80005b46 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005b14:	004a2603          	lw	a2,4(s4)
    80005b18:	fb040593          	addi	a1,s0,-80
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	cb0080e7          	jalr	-848(ra) # 800047ce <dirlink>
    80005b26:	06054f63          	bltz	a0,80005ba4 <create+0x162>
  iunlockput(dp);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	80a080e7          	jalr	-2038(ra) # 80004336 <iunlockput>
  return ip;
    80005b34:	8ad2                	mv	s5,s4
    80005b36:	b749                	j	80005ab8 <create+0x76>
    iunlockput(dp);
    80005b38:	8526                	mv	a0,s1
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	7fc080e7          	jalr	2044(ra) # 80004336 <iunlockput>
    return 0;
    80005b42:	8ad2                	mv	s5,s4
    80005b44:	bf95                	j	80005ab8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005b46:	004a2603          	lw	a2,4(s4)
    80005b4a:	00003597          	auipc	a1,0x3
    80005b4e:	c7658593          	addi	a1,a1,-906 # 800087c0 <syscalls+0x2d0>
    80005b52:	8552                	mv	a0,s4
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	c7a080e7          	jalr	-902(ra) # 800047ce <dirlink>
    80005b5c:	04054463          	bltz	a0,80005ba4 <create+0x162>
    80005b60:	40d0                	lw	a2,4(s1)
    80005b62:	00003597          	auipc	a1,0x3
    80005b66:	c6658593          	addi	a1,a1,-922 # 800087c8 <syscalls+0x2d8>
    80005b6a:	8552                	mv	a0,s4
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	c62080e7          	jalr	-926(ra) # 800047ce <dirlink>
    80005b74:	02054863          	bltz	a0,80005ba4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005b78:	004a2603          	lw	a2,4(s4)
    80005b7c:	fb040593          	addi	a1,s0,-80
    80005b80:	8526                	mv	a0,s1
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	c4c080e7          	jalr	-948(ra) # 800047ce <dirlink>
    80005b8a:	00054d63          	bltz	a0,80005ba4 <create+0x162>
    dp->nlink++;  // for ".."
    80005b8e:	04a4d783          	lhu	a5,74(s1)
    80005b92:	2785                	addiw	a5,a5,1
    80005b94:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b98:	8526                	mv	a0,s1
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	46e080e7          	jalr	1134(ra) # 80004008 <iupdate>
    80005ba2:	b761                	j	80005b2a <create+0xe8>
  ip->nlink = 0;
    80005ba4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005ba8:	8552                	mv	a0,s4
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	45e080e7          	jalr	1118(ra) # 80004008 <iupdate>
  iunlockput(ip);
    80005bb2:	8552                	mv	a0,s4
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	782080e7          	jalr	1922(ra) # 80004336 <iunlockput>
  iunlockput(dp);
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	778080e7          	jalr	1912(ra) # 80004336 <iunlockput>
  return 0;
    80005bc6:	bdcd                	j	80005ab8 <create+0x76>
    return 0;
    80005bc8:	8aaa                	mv	s5,a0
    80005bca:	b5fd                	j	80005ab8 <create+0x76>

0000000080005bcc <sys_dup>:
{
    80005bcc:	7179                	addi	sp,sp,-48
    80005bce:	f406                	sd	ra,40(sp)
    80005bd0:	f022                	sd	s0,32(sp)
    80005bd2:	ec26                	sd	s1,24(sp)
    80005bd4:	e84a                	sd	s2,16(sp)
    80005bd6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005bd8:	fd840613          	addi	a2,s0,-40
    80005bdc:	4581                	li	a1,0
    80005bde:	4501                	li	a0,0
    80005be0:	00000097          	auipc	ra,0x0
    80005be4:	dc0080e7          	jalr	-576(ra) # 800059a0 <argfd>
    return -1;
    80005be8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005bea:	02054363          	bltz	a0,80005c10 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005bee:	fd843903          	ld	s2,-40(s0)
    80005bf2:	854a                	mv	a0,s2
    80005bf4:	00000097          	auipc	ra,0x0
    80005bf8:	e0c080e7          	jalr	-500(ra) # 80005a00 <fdalloc>
    80005bfc:	84aa                	mv	s1,a0
    return -1;
    80005bfe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c00:	00054863          	bltz	a0,80005c10 <sys_dup+0x44>
  filedup(f);
    80005c04:	854a                	mv	a0,s2
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	310080e7          	jalr	784(ra) # 80004f16 <filedup>
  return fd;
    80005c0e:	87a6                	mv	a5,s1
}
    80005c10:	853e                	mv	a0,a5
    80005c12:	70a2                	ld	ra,40(sp)
    80005c14:	7402                	ld	s0,32(sp)
    80005c16:	64e2                	ld	s1,24(sp)
    80005c18:	6942                	ld	s2,16(sp)
    80005c1a:	6145                	addi	sp,sp,48
    80005c1c:	8082                	ret

0000000080005c1e <sys_read>:
{
    80005c1e:	7179                	addi	sp,sp,-48
    80005c20:	f406                	sd	ra,40(sp)
    80005c22:	f022                	sd	s0,32(sp)
    80005c24:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005c26:	fd840593          	addi	a1,s0,-40
    80005c2a:	4505                	li	a0,1
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	746080e7          	jalr	1862(ra) # 80003372 <argaddr>
  argint(2, &n);
    80005c34:	fe440593          	addi	a1,s0,-28
    80005c38:	4509                	li	a0,2
    80005c3a:	ffffd097          	auipc	ra,0xffffd
    80005c3e:	718080e7          	jalr	1816(ra) # 80003352 <argint>
  if(argfd(0, 0, &f) < 0)
    80005c42:	fe840613          	addi	a2,s0,-24
    80005c46:	4581                	li	a1,0
    80005c48:	4501                	li	a0,0
    80005c4a:	00000097          	auipc	ra,0x0
    80005c4e:	d56080e7          	jalr	-682(ra) # 800059a0 <argfd>
    80005c52:	87aa                	mv	a5,a0
    return -1;
    80005c54:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c56:	0007cc63          	bltz	a5,80005c6e <sys_read+0x50>
  return fileread(f, p, n);
    80005c5a:	fe442603          	lw	a2,-28(s0)
    80005c5e:	fd843583          	ld	a1,-40(s0)
    80005c62:	fe843503          	ld	a0,-24(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	43c080e7          	jalr	1084(ra) # 800050a2 <fileread>
}
    80005c6e:	70a2                	ld	ra,40(sp)
    80005c70:	7402                	ld	s0,32(sp)
    80005c72:	6145                	addi	sp,sp,48
    80005c74:	8082                	ret

0000000080005c76 <sys_write>:
{
    80005c76:	7179                	addi	sp,sp,-48
    80005c78:	f406                	sd	ra,40(sp)
    80005c7a:	f022                	sd	s0,32(sp)
    80005c7c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005c7e:	fd840593          	addi	a1,s0,-40
    80005c82:	4505                	li	a0,1
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	6ee080e7          	jalr	1774(ra) # 80003372 <argaddr>
  argint(2, &n);
    80005c8c:	fe440593          	addi	a1,s0,-28
    80005c90:	4509                	li	a0,2
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	6c0080e7          	jalr	1728(ra) # 80003352 <argint>
  if(argfd(0, 0, &f) < 0)
    80005c9a:	fe840613          	addi	a2,s0,-24
    80005c9e:	4581                	li	a1,0
    80005ca0:	4501                	li	a0,0
    80005ca2:	00000097          	auipc	ra,0x0
    80005ca6:	cfe080e7          	jalr	-770(ra) # 800059a0 <argfd>
    80005caa:	87aa                	mv	a5,a0
    return -1;
    80005cac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005cae:	0007cc63          	bltz	a5,80005cc6 <sys_write+0x50>
  return filewrite(f, p, n);
    80005cb2:	fe442603          	lw	a2,-28(s0)
    80005cb6:	fd843583          	ld	a1,-40(s0)
    80005cba:	fe843503          	ld	a0,-24(s0)
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	4a6080e7          	jalr	1190(ra) # 80005164 <filewrite>
}
    80005cc6:	70a2                	ld	ra,40(sp)
    80005cc8:	7402                	ld	s0,32(sp)
    80005cca:	6145                	addi	sp,sp,48
    80005ccc:	8082                	ret

0000000080005cce <sys_close>:
{
    80005cce:	1101                	addi	sp,sp,-32
    80005cd0:	ec06                	sd	ra,24(sp)
    80005cd2:	e822                	sd	s0,16(sp)
    80005cd4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005cd6:	fe040613          	addi	a2,s0,-32
    80005cda:	fec40593          	addi	a1,s0,-20
    80005cde:	4501                	li	a0,0
    80005ce0:	00000097          	auipc	ra,0x0
    80005ce4:	cc0080e7          	jalr	-832(ra) # 800059a0 <argfd>
    return -1;
    80005ce8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005cea:	02054463          	bltz	a0,80005d12 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005cee:	ffffc097          	auipc	ra,0xffffc
    80005cf2:	ffc080e7          	jalr	-4(ra) # 80001cea <myproc>
    80005cf6:	fec42783          	lw	a5,-20(s0)
    80005cfa:	07e9                	addi	a5,a5,26
    80005cfc:	078e                	slli	a5,a5,0x3
    80005cfe:	953e                	add	a0,a0,a5
    80005d00:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005d04:	fe043503          	ld	a0,-32(s0)
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	260080e7          	jalr	608(ra) # 80004f68 <fileclose>
  return 0;
    80005d10:	4781                	li	a5,0
}
    80005d12:	853e                	mv	a0,a5
    80005d14:	60e2                	ld	ra,24(sp)
    80005d16:	6442                	ld	s0,16(sp)
    80005d18:	6105                	addi	sp,sp,32
    80005d1a:	8082                	ret

0000000080005d1c <sys_fstat>:
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005d24:	fe040593          	addi	a1,s0,-32
    80005d28:	4505                	li	a0,1
    80005d2a:	ffffd097          	auipc	ra,0xffffd
    80005d2e:	648080e7          	jalr	1608(ra) # 80003372 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005d32:	fe840613          	addi	a2,s0,-24
    80005d36:	4581                	li	a1,0
    80005d38:	4501                	li	a0,0
    80005d3a:	00000097          	auipc	ra,0x0
    80005d3e:	c66080e7          	jalr	-922(ra) # 800059a0 <argfd>
    80005d42:	87aa                	mv	a5,a0
    return -1;
    80005d44:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d46:	0007ca63          	bltz	a5,80005d5a <sys_fstat+0x3e>
  return filestat(f, st);
    80005d4a:	fe043583          	ld	a1,-32(s0)
    80005d4e:	fe843503          	ld	a0,-24(s0)
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	2de080e7          	jalr	734(ra) # 80005030 <filestat>
}
    80005d5a:	60e2                	ld	ra,24(sp)
    80005d5c:	6442                	ld	s0,16(sp)
    80005d5e:	6105                	addi	sp,sp,32
    80005d60:	8082                	ret

0000000080005d62 <sys_link>:
{
    80005d62:	7169                	addi	sp,sp,-304
    80005d64:	f606                	sd	ra,296(sp)
    80005d66:	f222                	sd	s0,288(sp)
    80005d68:	ee26                	sd	s1,280(sp)
    80005d6a:	ea4a                	sd	s2,272(sp)
    80005d6c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d6e:	08000613          	li	a2,128
    80005d72:	ed040593          	addi	a1,s0,-304
    80005d76:	4501                	li	a0,0
    80005d78:	ffffd097          	auipc	ra,0xffffd
    80005d7c:	61a080e7          	jalr	1562(ra) # 80003392 <argstr>
    return -1;
    80005d80:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d82:	10054e63          	bltz	a0,80005e9e <sys_link+0x13c>
    80005d86:	08000613          	li	a2,128
    80005d8a:	f5040593          	addi	a1,s0,-176
    80005d8e:	4505                	li	a0,1
    80005d90:	ffffd097          	auipc	ra,0xffffd
    80005d94:	602080e7          	jalr	1538(ra) # 80003392 <argstr>
    return -1;
    80005d98:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d9a:	10054263          	bltz	a0,80005e9e <sys_link+0x13c>
  begin_op();
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	d02080e7          	jalr	-766(ra) # 80004aa0 <begin_op>
  if((ip = namei(old)) == 0){
    80005da6:	ed040513          	addi	a0,s0,-304
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	ad6080e7          	jalr	-1322(ra) # 80004880 <namei>
    80005db2:	84aa                	mv	s1,a0
    80005db4:	c551                	beqz	a0,80005e40 <sys_link+0xde>
  ilock(ip);
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	31e080e7          	jalr	798(ra) # 800040d4 <ilock>
  if(ip->type == T_DIR){
    80005dbe:	04449703          	lh	a4,68(s1)
    80005dc2:	4785                	li	a5,1
    80005dc4:	08f70463          	beq	a4,a5,80005e4c <sys_link+0xea>
  ip->nlink++;
    80005dc8:	04a4d783          	lhu	a5,74(s1)
    80005dcc:	2785                	addiw	a5,a5,1
    80005dce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dd2:	8526                	mv	a0,s1
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	234080e7          	jalr	564(ra) # 80004008 <iupdate>
  iunlock(ip);
    80005ddc:	8526                	mv	a0,s1
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	3b8080e7          	jalr	952(ra) # 80004196 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005de6:	fd040593          	addi	a1,s0,-48
    80005dea:	f5040513          	addi	a0,s0,-176
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	ab0080e7          	jalr	-1360(ra) # 8000489e <nameiparent>
    80005df6:	892a                	mv	s2,a0
    80005df8:	c935                	beqz	a0,80005e6c <sys_link+0x10a>
  ilock(dp);
    80005dfa:	ffffe097          	auipc	ra,0xffffe
    80005dfe:	2da080e7          	jalr	730(ra) # 800040d4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005e02:	00092703          	lw	a4,0(s2)
    80005e06:	409c                	lw	a5,0(s1)
    80005e08:	04f71d63          	bne	a4,a5,80005e62 <sys_link+0x100>
    80005e0c:	40d0                	lw	a2,4(s1)
    80005e0e:	fd040593          	addi	a1,s0,-48
    80005e12:	854a                	mv	a0,s2
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	9ba080e7          	jalr	-1606(ra) # 800047ce <dirlink>
    80005e1c:	04054363          	bltz	a0,80005e62 <sys_link+0x100>
  iunlockput(dp);
    80005e20:	854a                	mv	a0,s2
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	514080e7          	jalr	1300(ra) # 80004336 <iunlockput>
  iput(ip);
    80005e2a:	8526                	mv	a0,s1
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	462080e7          	jalr	1122(ra) # 8000428e <iput>
  end_op();
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	cea080e7          	jalr	-790(ra) # 80004b1e <end_op>
  return 0;
    80005e3c:	4781                	li	a5,0
    80005e3e:	a085                	j	80005e9e <sys_link+0x13c>
    end_op();
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	cde080e7          	jalr	-802(ra) # 80004b1e <end_op>
    return -1;
    80005e48:	57fd                	li	a5,-1
    80005e4a:	a891                	j	80005e9e <sys_link+0x13c>
    iunlockput(ip);
    80005e4c:	8526                	mv	a0,s1
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	4e8080e7          	jalr	1256(ra) # 80004336 <iunlockput>
    end_op();
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	cc8080e7          	jalr	-824(ra) # 80004b1e <end_op>
    return -1;
    80005e5e:	57fd                	li	a5,-1
    80005e60:	a83d                	j	80005e9e <sys_link+0x13c>
    iunlockput(dp);
    80005e62:	854a                	mv	a0,s2
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	4d2080e7          	jalr	1234(ra) # 80004336 <iunlockput>
  ilock(ip);
    80005e6c:	8526                	mv	a0,s1
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	266080e7          	jalr	614(ra) # 800040d4 <ilock>
  ip->nlink--;
    80005e76:	04a4d783          	lhu	a5,74(s1)
    80005e7a:	37fd                	addiw	a5,a5,-1
    80005e7c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e80:	8526                	mv	a0,s1
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	186080e7          	jalr	390(ra) # 80004008 <iupdate>
  iunlockput(ip);
    80005e8a:	8526                	mv	a0,s1
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	4aa080e7          	jalr	1194(ra) # 80004336 <iunlockput>
  end_op();
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	c8a080e7          	jalr	-886(ra) # 80004b1e <end_op>
  return -1;
    80005e9c:	57fd                	li	a5,-1
}
    80005e9e:	853e                	mv	a0,a5
    80005ea0:	70b2                	ld	ra,296(sp)
    80005ea2:	7412                	ld	s0,288(sp)
    80005ea4:	64f2                	ld	s1,280(sp)
    80005ea6:	6952                	ld	s2,272(sp)
    80005ea8:	6155                	addi	sp,sp,304
    80005eaa:	8082                	ret

0000000080005eac <sys_unlink>:
{
    80005eac:	7151                	addi	sp,sp,-240
    80005eae:	f586                	sd	ra,232(sp)
    80005eb0:	f1a2                	sd	s0,224(sp)
    80005eb2:	eda6                	sd	s1,216(sp)
    80005eb4:	e9ca                	sd	s2,208(sp)
    80005eb6:	e5ce                	sd	s3,200(sp)
    80005eb8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005eba:	08000613          	li	a2,128
    80005ebe:	f3040593          	addi	a1,s0,-208
    80005ec2:	4501                	li	a0,0
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	4ce080e7          	jalr	1230(ra) # 80003392 <argstr>
    80005ecc:	18054163          	bltz	a0,8000604e <sys_unlink+0x1a2>
  begin_op();
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	bd0080e7          	jalr	-1072(ra) # 80004aa0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ed8:	fb040593          	addi	a1,s0,-80
    80005edc:	f3040513          	addi	a0,s0,-208
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	9be080e7          	jalr	-1602(ra) # 8000489e <nameiparent>
    80005ee8:	84aa                	mv	s1,a0
    80005eea:	c979                	beqz	a0,80005fc0 <sys_unlink+0x114>
  ilock(dp);
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	1e8080e7          	jalr	488(ra) # 800040d4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ef4:	00003597          	auipc	a1,0x3
    80005ef8:	8cc58593          	addi	a1,a1,-1844 # 800087c0 <syscalls+0x2d0>
    80005efc:	fb040513          	addi	a0,s0,-80
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	69e080e7          	jalr	1694(ra) # 8000459e <namecmp>
    80005f08:	14050a63          	beqz	a0,8000605c <sys_unlink+0x1b0>
    80005f0c:	00003597          	auipc	a1,0x3
    80005f10:	8bc58593          	addi	a1,a1,-1860 # 800087c8 <syscalls+0x2d8>
    80005f14:	fb040513          	addi	a0,s0,-80
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	686080e7          	jalr	1670(ra) # 8000459e <namecmp>
    80005f20:	12050e63          	beqz	a0,8000605c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f24:	f2c40613          	addi	a2,s0,-212
    80005f28:	fb040593          	addi	a1,s0,-80
    80005f2c:	8526                	mv	a0,s1
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	68a080e7          	jalr	1674(ra) # 800045b8 <dirlookup>
    80005f36:	892a                	mv	s2,a0
    80005f38:	12050263          	beqz	a0,8000605c <sys_unlink+0x1b0>
  ilock(ip);
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	198080e7          	jalr	408(ra) # 800040d4 <ilock>
  if(ip->nlink < 1)
    80005f44:	04a91783          	lh	a5,74(s2)
    80005f48:	08f05263          	blez	a5,80005fcc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f4c:	04491703          	lh	a4,68(s2)
    80005f50:	4785                	li	a5,1
    80005f52:	08f70563          	beq	a4,a5,80005fdc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005f56:	4641                	li	a2,16
    80005f58:	4581                	li	a1,0
    80005f5a:	fc040513          	addi	a0,s0,-64
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	eac080e7          	jalr	-340(ra) # 80000e0a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f66:	4741                	li	a4,16
    80005f68:	f2c42683          	lw	a3,-212(s0)
    80005f6c:	fc040613          	addi	a2,s0,-64
    80005f70:	4581                	li	a1,0
    80005f72:	8526                	mv	a0,s1
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	50c080e7          	jalr	1292(ra) # 80004480 <writei>
    80005f7c:	47c1                	li	a5,16
    80005f7e:	0af51563          	bne	a0,a5,80006028 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005f82:	04491703          	lh	a4,68(s2)
    80005f86:	4785                	li	a5,1
    80005f88:	0af70863          	beq	a4,a5,80006038 <sys_unlink+0x18c>
  iunlockput(dp);
    80005f8c:	8526                	mv	a0,s1
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	3a8080e7          	jalr	936(ra) # 80004336 <iunlockput>
  ip->nlink--;
    80005f96:	04a95783          	lhu	a5,74(s2)
    80005f9a:	37fd                	addiw	a5,a5,-1
    80005f9c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fa0:	854a                	mv	a0,s2
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	066080e7          	jalr	102(ra) # 80004008 <iupdate>
  iunlockput(ip);
    80005faa:	854a                	mv	a0,s2
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	38a080e7          	jalr	906(ra) # 80004336 <iunlockput>
  end_op();
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	b6a080e7          	jalr	-1174(ra) # 80004b1e <end_op>
  return 0;
    80005fbc:	4501                	li	a0,0
    80005fbe:	a84d                	j	80006070 <sys_unlink+0x1c4>
    end_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	b5e080e7          	jalr	-1186(ra) # 80004b1e <end_op>
    return -1;
    80005fc8:	557d                	li	a0,-1
    80005fca:	a05d                	j	80006070 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005fcc:	00003517          	auipc	a0,0x3
    80005fd0:	80450513          	addi	a0,a0,-2044 # 800087d0 <syscalls+0x2e0>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	56c080e7          	jalr	1388(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005fdc:	04c92703          	lw	a4,76(s2)
    80005fe0:	02000793          	li	a5,32
    80005fe4:	f6e7f9e3          	bgeu	a5,a4,80005f56 <sys_unlink+0xaa>
    80005fe8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fec:	4741                	li	a4,16
    80005fee:	86ce                	mv	a3,s3
    80005ff0:	f1840613          	addi	a2,s0,-232
    80005ff4:	4581                	li	a1,0
    80005ff6:	854a                	mv	a0,s2
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	390080e7          	jalr	912(ra) # 80004388 <readi>
    80006000:	47c1                	li	a5,16
    80006002:	00f51b63          	bne	a0,a5,80006018 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006006:	f1845783          	lhu	a5,-232(s0)
    8000600a:	e7a1                	bnez	a5,80006052 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000600c:	29c1                	addiw	s3,s3,16
    8000600e:	04c92783          	lw	a5,76(s2)
    80006012:	fcf9ede3          	bltu	s3,a5,80005fec <sys_unlink+0x140>
    80006016:	b781                	j	80005f56 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006018:	00002517          	auipc	a0,0x2
    8000601c:	7d050513          	addi	a0,a0,2000 # 800087e8 <syscalls+0x2f8>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	520080e7          	jalr	1312(ra) # 80000540 <panic>
    panic("unlink: writei");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	7d850513          	addi	a0,a0,2008 # 80008800 <syscalls+0x310>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    dp->nlink--;
    80006038:	04a4d783          	lhu	a5,74(s1)
    8000603c:	37fd                	addiw	a5,a5,-1
    8000603e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006042:	8526                	mv	a0,s1
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	fc4080e7          	jalr	-60(ra) # 80004008 <iupdate>
    8000604c:	b781                	j	80005f8c <sys_unlink+0xe0>
    return -1;
    8000604e:	557d                	li	a0,-1
    80006050:	a005                	j	80006070 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006052:	854a                	mv	a0,s2
    80006054:	ffffe097          	auipc	ra,0xffffe
    80006058:	2e2080e7          	jalr	738(ra) # 80004336 <iunlockput>
  iunlockput(dp);
    8000605c:	8526                	mv	a0,s1
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	2d8080e7          	jalr	728(ra) # 80004336 <iunlockput>
  end_op();
    80006066:	fffff097          	auipc	ra,0xfffff
    8000606a:	ab8080e7          	jalr	-1352(ra) # 80004b1e <end_op>
  return -1;
    8000606e:	557d                	li	a0,-1
}
    80006070:	70ae                	ld	ra,232(sp)
    80006072:	740e                	ld	s0,224(sp)
    80006074:	64ee                	ld	s1,216(sp)
    80006076:	694e                	ld	s2,208(sp)
    80006078:	69ae                	ld	s3,200(sp)
    8000607a:	616d                	addi	sp,sp,240
    8000607c:	8082                	ret

000000008000607e <sys_open>:

uint64
sys_open(void)
{
    8000607e:	7131                	addi	sp,sp,-192
    80006080:	fd06                	sd	ra,184(sp)
    80006082:	f922                	sd	s0,176(sp)
    80006084:	f526                	sd	s1,168(sp)
    80006086:	f14a                	sd	s2,160(sp)
    80006088:	ed4e                	sd	s3,152(sp)
    8000608a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000608c:	f4c40593          	addi	a1,s0,-180
    80006090:	4505                	li	a0,1
    80006092:	ffffd097          	auipc	ra,0xffffd
    80006096:	2c0080e7          	jalr	704(ra) # 80003352 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000609a:	08000613          	li	a2,128
    8000609e:	f5040593          	addi	a1,s0,-176
    800060a2:	4501                	li	a0,0
    800060a4:	ffffd097          	auipc	ra,0xffffd
    800060a8:	2ee080e7          	jalr	750(ra) # 80003392 <argstr>
    800060ac:	87aa                	mv	a5,a0
    return -1;
    800060ae:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060b0:	0a07c963          	bltz	a5,80006162 <sys_open+0xe4>

  begin_op();
    800060b4:	fffff097          	auipc	ra,0xfffff
    800060b8:	9ec080e7          	jalr	-1556(ra) # 80004aa0 <begin_op>

  if(omode & O_CREATE){
    800060bc:	f4c42783          	lw	a5,-180(s0)
    800060c0:	2007f793          	andi	a5,a5,512
    800060c4:	cfc5                	beqz	a5,8000617c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800060c6:	4681                	li	a3,0
    800060c8:	4601                	li	a2,0
    800060ca:	4589                	li	a1,2
    800060cc:	f5040513          	addi	a0,s0,-176
    800060d0:	00000097          	auipc	ra,0x0
    800060d4:	972080e7          	jalr	-1678(ra) # 80005a42 <create>
    800060d8:	84aa                	mv	s1,a0
    if(ip == 0){
    800060da:	c959                	beqz	a0,80006170 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800060dc:	04449703          	lh	a4,68(s1)
    800060e0:	478d                	li	a5,3
    800060e2:	00f71763          	bne	a4,a5,800060f0 <sys_open+0x72>
    800060e6:	0464d703          	lhu	a4,70(s1)
    800060ea:	47a5                	li	a5,9
    800060ec:	0ce7ed63          	bltu	a5,a4,800061c6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	dbc080e7          	jalr	-580(ra) # 80004eac <filealloc>
    800060f8:	89aa                	mv	s3,a0
    800060fa:	10050363          	beqz	a0,80006200 <sys_open+0x182>
    800060fe:	00000097          	auipc	ra,0x0
    80006102:	902080e7          	jalr	-1790(ra) # 80005a00 <fdalloc>
    80006106:	892a                	mv	s2,a0
    80006108:	0e054763          	bltz	a0,800061f6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000610c:	04449703          	lh	a4,68(s1)
    80006110:	478d                	li	a5,3
    80006112:	0cf70563          	beq	a4,a5,800061dc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006116:	4789                	li	a5,2
    80006118:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000611c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006120:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006124:	f4c42783          	lw	a5,-180(s0)
    80006128:	0017c713          	xori	a4,a5,1
    8000612c:	8b05                	andi	a4,a4,1
    8000612e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006132:	0037f713          	andi	a4,a5,3
    80006136:	00e03733          	snez	a4,a4
    8000613a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000613e:	4007f793          	andi	a5,a5,1024
    80006142:	c791                	beqz	a5,8000614e <sys_open+0xd0>
    80006144:	04449703          	lh	a4,68(s1)
    80006148:	4789                	li	a5,2
    8000614a:	0af70063          	beq	a4,a5,800061ea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000614e:	8526                	mv	a0,s1
    80006150:	ffffe097          	auipc	ra,0xffffe
    80006154:	046080e7          	jalr	70(ra) # 80004196 <iunlock>
  end_op();
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	9c6080e7          	jalr	-1594(ra) # 80004b1e <end_op>

  return fd;
    80006160:	854a                	mv	a0,s2
}
    80006162:	70ea                	ld	ra,184(sp)
    80006164:	744a                	ld	s0,176(sp)
    80006166:	74aa                	ld	s1,168(sp)
    80006168:	790a                	ld	s2,160(sp)
    8000616a:	69ea                	ld	s3,152(sp)
    8000616c:	6129                	addi	sp,sp,192
    8000616e:	8082                	ret
      end_op();
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	9ae080e7          	jalr	-1618(ra) # 80004b1e <end_op>
      return -1;
    80006178:	557d                	li	a0,-1
    8000617a:	b7e5                	j	80006162 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000617c:	f5040513          	addi	a0,s0,-176
    80006180:	ffffe097          	auipc	ra,0xffffe
    80006184:	700080e7          	jalr	1792(ra) # 80004880 <namei>
    80006188:	84aa                	mv	s1,a0
    8000618a:	c905                	beqz	a0,800061ba <sys_open+0x13c>
    ilock(ip);
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	f48080e7          	jalr	-184(ra) # 800040d4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006194:	04449703          	lh	a4,68(s1)
    80006198:	4785                	li	a5,1
    8000619a:	f4f711e3          	bne	a4,a5,800060dc <sys_open+0x5e>
    8000619e:	f4c42783          	lw	a5,-180(s0)
    800061a2:	d7b9                	beqz	a5,800060f0 <sys_open+0x72>
      iunlockput(ip);
    800061a4:	8526                	mv	a0,s1
    800061a6:	ffffe097          	auipc	ra,0xffffe
    800061aa:	190080e7          	jalr	400(ra) # 80004336 <iunlockput>
      end_op();
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	970080e7          	jalr	-1680(ra) # 80004b1e <end_op>
      return -1;
    800061b6:	557d                	li	a0,-1
    800061b8:	b76d                	j	80006162 <sys_open+0xe4>
      end_op();
    800061ba:	fffff097          	auipc	ra,0xfffff
    800061be:	964080e7          	jalr	-1692(ra) # 80004b1e <end_op>
      return -1;
    800061c2:	557d                	li	a0,-1
    800061c4:	bf79                	j	80006162 <sys_open+0xe4>
    iunlockput(ip);
    800061c6:	8526                	mv	a0,s1
    800061c8:	ffffe097          	auipc	ra,0xffffe
    800061cc:	16e080e7          	jalr	366(ra) # 80004336 <iunlockput>
    end_op();
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	94e080e7          	jalr	-1714(ra) # 80004b1e <end_op>
    return -1;
    800061d8:	557d                	li	a0,-1
    800061da:	b761                	j	80006162 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800061dc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800061e0:	04649783          	lh	a5,70(s1)
    800061e4:	02f99223          	sh	a5,36(s3)
    800061e8:	bf25                	j	80006120 <sys_open+0xa2>
    itrunc(ip);
    800061ea:	8526                	mv	a0,s1
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	ff6080e7          	jalr	-10(ra) # 800041e2 <itrunc>
    800061f4:	bfa9                	j	8000614e <sys_open+0xd0>
      fileclose(f);
    800061f6:	854e                	mv	a0,s3
    800061f8:	fffff097          	auipc	ra,0xfffff
    800061fc:	d70080e7          	jalr	-656(ra) # 80004f68 <fileclose>
    iunlockput(ip);
    80006200:	8526                	mv	a0,s1
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	134080e7          	jalr	308(ra) # 80004336 <iunlockput>
    end_op();
    8000620a:	fffff097          	auipc	ra,0xfffff
    8000620e:	914080e7          	jalr	-1772(ra) # 80004b1e <end_op>
    return -1;
    80006212:	557d                	li	a0,-1
    80006214:	b7b9                	j	80006162 <sys_open+0xe4>

0000000080006216 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006216:	7175                	addi	sp,sp,-144
    80006218:	e506                	sd	ra,136(sp)
    8000621a:	e122                	sd	s0,128(sp)
    8000621c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000621e:	fffff097          	auipc	ra,0xfffff
    80006222:	882080e7          	jalr	-1918(ra) # 80004aa0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006226:	08000613          	li	a2,128
    8000622a:	f7040593          	addi	a1,s0,-144
    8000622e:	4501                	li	a0,0
    80006230:	ffffd097          	auipc	ra,0xffffd
    80006234:	162080e7          	jalr	354(ra) # 80003392 <argstr>
    80006238:	02054963          	bltz	a0,8000626a <sys_mkdir+0x54>
    8000623c:	4681                	li	a3,0
    8000623e:	4601                	li	a2,0
    80006240:	4585                	li	a1,1
    80006242:	f7040513          	addi	a0,s0,-144
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	7fc080e7          	jalr	2044(ra) # 80005a42 <create>
    8000624e:	cd11                	beqz	a0,8000626a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006250:	ffffe097          	auipc	ra,0xffffe
    80006254:	0e6080e7          	jalr	230(ra) # 80004336 <iunlockput>
  end_op();
    80006258:	fffff097          	auipc	ra,0xfffff
    8000625c:	8c6080e7          	jalr	-1850(ra) # 80004b1e <end_op>
  return 0;
    80006260:	4501                	li	a0,0
}
    80006262:	60aa                	ld	ra,136(sp)
    80006264:	640a                	ld	s0,128(sp)
    80006266:	6149                	addi	sp,sp,144
    80006268:	8082                	ret
    end_op();
    8000626a:	fffff097          	auipc	ra,0xfffff
    8000626e:	8b4080e7          	jalr	-1868(ra) # 80004b1e <end_op>
    return -1;
    80006272:	557d                	li	a0,-1
    80006274:	b7fd                	j	80006262 <sys_mkdir+0x4c>

0000000080006276 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006276:	7135                	addi	sp,sp,-160
    80006278:	ed06                	sd	ra,152(sp)
    8000627a:	e922                	sd	s0,144(sp)
    8000627c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000627e:	fffff097          	auipc	ra,0xfffff
    80006282:	822080e7          	jalr	-2014(ra) # 80004aa0 <begin_op>
  argint(1, &major);
    80006286:	f6c40593          	addi	a1,s0,-148
    8000628a:	4505                	li	a0,1
    8000628c:	ffffd097          	auipc	ra,0xffffd
    80006290:	0c6080e7          	jalr	198(ra) # 80003352 <argint>
  argint(2, &minor);
    80006294:	f6840593          	addi	a1,s0,-152
    80006298:	4509                	li	a0,2
    8000629a:	ffffd097          	auipc	ra,0xffffd
    8000629e:	0b8080e7          	jalr	184(ra) # 80003352 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062a2:	08000613          	li	a2,128
    800062a6:	f7040593          	addi	a1,s0,-144
    800062aa:	4501                	li	a0,0
    800062ac:	ffffd097          	auipc	ra,0xffffd
    800062b0:	0e6080e7          	jalr	230(ra) # 80003392 <argstr>
    800062b4:	02054b63          	bltz	a0,800062ea <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800062b8:	f6841683          	lh	a3,-152(s0)
    800062bc:	f6c41603          	lh	a2,-148(s0)
    800062c0:	458d                	li	a1,3
    800062c2:	f7040513          	addi	a0,s0,-144
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	77c080e7          	jalr	1916(ra) # 80005a42 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062ce:	cd11                	beqz	a0,800062ea <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062d0:	ffffe097          	auipc	ra,0xffffe
    800062d4:	066080e7          	jalr	102(ra) # 80004336 <iunlockput>
  end_op();
    800062d8:	fffff097          	auipc	ra,0xfffff
    800062dc:	846080e7          	jalr	-1978(ra) # 80004b1e <end_op>
  return 0;
    800062e0:	4501                	li	a0,0
}
    800062e2:	60ea                	ld	ra,152(sp)
    800062e4:	644a                	ld	s0,144(sp)
    800062e6:	610d                	addi	sp,sp,160
    800062e8:	8082                	ret
    end_op();
    800062ea:	fffff097          	auipc	ra,0xfffff
    800062ee:	834080e7          	jalr	-1996(ra) # 80004b1e <end_op>
    return -1;
    800062f2:	557d                	li	a0,-1
    800062f4:	b7fd                	j	800062e2 <sys_mknod+0x6c>

00000000800062f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800062f6:	7135                	addi	sp,sp,-160
    800062f8:	ed06                	sd	ra,152(sp)
    800062fa:	e922                	sd	s0,144(sp)
    800062fc:	e526                	sd	s1,136(sp)
    800062fe:	e14a                	sd	s2,128(sp)
    80006300:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	9e8080e7          	jalr	-1560(ra) # 80001cea <myproc>
    8000630a:	892a                	mv	s2,a0
  
  begin_op();
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	794080e7          	jalr	1940(ra) # 80004aa0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006314:	08000613          	li	a2,128
    80006318:	f6040593          	addi	a1,s0,-160
    8000631c:	4501                	li	a0,0
    8000631e:	ffffd097          	auipc	ra,0xffffd
    80006322:	074080e7          	jalr	116(ra) # 80003392 <argstr>
    80006326:	04054b63          	bltz	a0,8000637c <sys_chdir+0x86>
    8000632a:	f6040513          	addi	a0,s0,-160
    8000632e:	ffffe097          	auipc	ra,0xffffe
    80006332:	552080e7          	jalr	1362(ra) # 80004880 <namei>
    80006336:	84aa                	mv	s1,a0
    80006338:	c131                	beqz	a0,8000637c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000633a:	ffffe097          	auipc	ra,0xffffe
    8000633e:	d9a080e7          	jalr	-614(ra) # 800040d4 <ilock>
  if(ip->type != T_DIR){
    80006342:	04449703          	lh	a4,68(s1)
    80006346:	4785                	li	a5,1
    80006348:	04f71063          	bne	a4,a5,80006388 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000634c:	8526                	mv	a0,s1
    8000634e:	ffffe097          	auipc	ra,0xffffe
    80006352:	e48080e7          	jalr	-440(ra) # 80004196 <iunlock>
  iput(p->cwd);
    80006356:	15093503          	ld	a0,336(s2)
    8000635a:	ffffe097          	auipc	ra,0xffffe
    8000635e:	f34080e7          	jalr	-204(ra) # 8000428e <iput>
  end_op();
    80006362:	ffffe097          	auipc	ra,0xffffe
    80006366:	7bc080e7          	jalr	1980(ra) # 80004b1e <end_op>
  p->cwd = ip;
    8000636a:	14993823          	sd	s1,336(s2)
  return 0;
    8000636e:	4501                	li	a0,0
}
    80006370:	60ea                	ld	ra,152(sp)
    80006372:	644a                	ld	s0,144(sp)
    80006374:	64aa                	ld	s1,136(sp)
    80006376:	690a                	ld	s2,128(sp)
    80006378:	610d                	addi	sp,sp,160
    8000637a:	8082                	ret
    end_op();
    8000637c:	ffffe097          	auipc	ra,0xffffe
    80006380:	7a2080e7          	jalr	1954(ra) # 80004b1e <end_op>
    return -1;
    80006384:	557d                	li	a0,-1
    80006386:	b7ed                	j	80006370 <sys_chdir+0x7a>
    iunlockput(ip);
    80006388:	8526                	mv	a0,s1
    8000638a:	ffffe097          	auipc	ra,0xffffe
    8000638e:	fac080e7          	jalr	-84(ra) # 80004336 <iunlockput>
    end_op();
    80006392:	ffffe097          	auipc	ra,0xffffe
    80006396:	78c080e7          	jalr	1932(ra) # 80004b1e <end_op>
    return -1;
    8000639a:	557d                	li	a0,-1
    8000639c:	bfd1                	j	80006370 <sys_chdir+0x7a>

000000008000639e <sys_exec>:

uint64
sys_exec(void)
{
    8000639e:	7145                	addi	sp,sp,-464
    800063a0:	e786                	sd	ra,456(sp)
    800063a2:	e3a2                	sd	s0,448(sp)
    800063a4:	ff26                	sd	s1,440(sp)
    800063a6:	fb4a                	sd	s2,432(sp)
    800063a8:	f74e                	sd	s3,424(sp)
    800063aa:	f352                	sd	s4,416(sp)
    800063ac:	ef56                	sd	s5,408(sp)
    800063ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800063b0:	e3840593          	addi	a1,s0,-456
    800063b4:	4505                	li	a0,1
    800063b6:	ffffd097          	auipc	ra,0xffffd
    800063ba:	fbc080e7          	jalr	-68(ra) # 80003372 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800063be:	08000613          	li	a2,128
    800063c2:	f4040593          	addi	a1,s0,-192
    800063c6:	4501                	li	a0,0
    800063c8:	ffffd097          	auipc	ra,0xffffd
    800063cc:	fca080e7          	jalr	-54(ra) # 80003392 <argstr>
    800063d0:	87aa                	mv	a5,a0
    return -1;
    800063d2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800063d4:	0c07c363          	bltz	a5,8000649a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800063d8:	10000613          	li	a2,256
    800063dc:	4581                	li	a1,0
    800063de:	e4040513          	addi	a0,s0,-448
    800063e2:	ffffb097          	auipc	ra,0xffffb
    800063e6:	a28080e7          	jalr	-1496(ra) # 80000e0a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800063ea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800063ee:	89a6                	mv	s3,s1
    800063f0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800063f2:	02000a13          	li	s4,32
    800063f6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800063fa:	00391513          	slli	a0,s2,0x3
    800063fe:	e3040593          	addi	a1,s0,-464
    80006402:	e3843783          	ld	a5,-456(s0)
    80006406:	953e                	add	a0,a0,a5
    80006408:	ffffd097          	auipc	ra,0xffffd
    8000640c:	eac080e7          	jalr	-340(ra) # 800032b4 <fetchaddr>
    80006410:	02054a63          	bltz	a0,80006444 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006414:	e3043783          	ld	a5,-464(s0)
    80006418:	c3b9                	beqz	a5,8000645e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	7cc080e7          	jalr	1996(ra) # 80000be6 <kalloc>
    80006422:	85aa                	mv	a1,a0
    80006424:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006428:	cd11                	beqz	a0,80006444 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000642a:	6605                	lui	a2,0x1
    8000642c:	e3043503          	ld	a0,-464(s0)
    80006430:	ffffd097          	auipc	ra,0xffffd
    80006434:	ed6080e7          	jalr	-298(ra) # 80003306 <fetchstr>
    80006438:	00054663          	bltz	a0,80006444 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000643c:	0905                	addi	s2,s2,1
    8000643e:	09a1                	addi	s3,s3,8
    80006440:	fb491be3          	bne	s2,s4,800063f6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006444:	f4040913          	addi	s2,s0,-192
    80006448:	6088                	ld	a0,0(s1)
    8000644a:	c539                	beqz	a0,80006498 <sys_exec+0xfa>
    kfree(argv[i]);
    8000644c:	ffffa097          	auipc	ra,0xffffa
    80006450:	614080e7          	jalr	1556(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006454:	04a1                	addi	s1,s1,8
    80006456:	ff2499e3          	bne	s1,s2,80006448 <sys_exec+0xaa>
  return -1;
    8000645a:	557d                	li	a0,-1
    8000645c:	a83d                	j	8000649a <sys_exec+0xfc>
      argv[i] = 0;
    8000645e:	0a8e                	slli	s5,s5,0x3
    80006460:	fc0a8793          	addi	a5,s5,-64
    80006464:	00878ab3          	add	s5,a5,s0
    80006468:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000646c:	e4040593          	addi	a1,s0,-448
    80006470:	f4040513          	addi	a0,s0,-192
    80006474:	fffff097          	auipc	ra,0xfffff
    80006478:	16e080e7          	jalr	366(ra) # 800055e2 <exec>
    8000647c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000647e:	f4040993          	addi	s3,s0,-192
    80006482:	6088                	ld	a0,0(s1)
    80006484:	c901                	beqz	a0,80006494 <sys_exec+0xf6>
    kfree(argv[i]);
    80006486:	ffffa097          	auipc	ra,0xffffa
    8000648a:	5da080e7          	jalr	1498(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000648e:	04a1                	addi	s1,s1,8
    80006490:	ff3499e3          	bne	s1,s3,80006482 <sys_exec+0xe4>
  return ret;
    80006494:	854a                	mv	a0,s2
    80006496:	a011                	j	8000649a <sys_exec+0xfc>
  return -1;
    80006498:	557d                	li	a0,-1
}
    8000649a:	60be                	ld	ra,456(sp)
    8000649c:	641e                	ld	s0,448(sp)
    8000649e:	74fa                	ld	s1,440(sp)
    800064a0:	795a                	ld	s2,432(sp)
    800064a2:	79ba                	ld	s3,424(sp)
    800064a4:	7a1a                	ld	s4,416(sp)
    800064a6:	6afa                	ld	s5,408(sp)
    800064a8:	6179                	addi	sp,sp,464
    800064aa:	8082                	ret

00000000800064ac <sys_pipe>:

uint64
sys_pipe(void)
{
    800064ac:	7139                	addi	sp,sp,-64
    800064ae:	fc06                	sd	ra,56(sp)
    800064b0:	f822                	sd	s0,48(sp)
    800064b2:	f426                	sd	s1,40(sp)
    800064b4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800064b6:	ffffc097          	auipc	ra,0xffffc
    800064ba:	834080e7          	jalr	-1996(ra) # 80001cea <myproc>
    800064be:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800064c0:	fd840593          	addi	a1,s0,-40
    800064c4:	4501                	li	a0,0
    800064c6:	ffffd097          	auipc	ra,0xffffd
    800064ca:	eac080e7          	jalr	-340(ra) # 80003372 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800064ce:	fc840593          	addi	a1,s0,-56
    800064d2:	fd040513          	addi	a0,s0,-48
    800064d6:	fffff097          	auipc	ra,0xfffff
    800064da:	dc2080e7          	jalr	-574(ra) # 80005298 <pipealloc>
    return -1;
    800064de:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800064e0:	0c054463          	bltz	a0,800065a8 <sys_pipe+0xfc>
  fd0 = -1;
    800064e4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800064e8:	fd043503          	ld	a0,-48(s0)
    800064ec:	fffff097          	auipc	ra,0xfffff
    800064f0:	514080e7          	jalr	1300(ra) # 80005a00 <fdalloc>
    800064f4:	fca42223          	sw	a0,-60(s0)
    800064f8:	08054b63          	bltz	a0,8000658e <sys_pipe+0xe2>
    800064fc:	fc843503          	ld	a0,-56(s0)
    80006500:	fffff097          	auipc	ra,0xfffff
    80006504:	500080e7          	jalr	1280(ra) # 80005a00 <fdalloc>
    80006508:	fca42023          	sw	a0,-64(s0)
    8000650c:	06054863          	bltz	a0,8000657c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006510:	4691                	li	a3,4
    80006512:	fc440613          	addi	a2,s0,-60
    80006516:	fd843583          	ld	a1,-40(s0)
    8000651a:	68a8                	ld	a0,80(s1)
    8000651c:	ffffb097          	auipc	ra,0xffffb
    80006520:	26e080e7          	jalr	622(ra) # 8000178a <copyout>
    80006524:	02054063          	bltz	a0,80006544 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006528:	4691                	li	a3,4
    8000652a:	fc040613          	addi	a2,s0,-64
    8000652e:	fd843583          	ld	a1,-40(s0)
    80006532:	0591                	addi	a1,a1,4
    80006534:	68a8                	ld	a0,80(s1)
    80006536:	ffffb097          	auipc	ra,0xffffb
    8000653a:	254080e7          	jalr	596(ra) # 8000178a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000653e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006540:	06055463          	bgez	a0,800065a8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006544:	fc442783          	lw	a5,-60(s0)
    80006548:	07e9                	addi	a5,a5,26
    8000654a:	078e                	slli	a5,a5,0x3
    8000654c:	97a6                	add	a5,a5,s1
    8000654e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006552:	fc042783          	lw	a5,-64(s0)
    80006556:	07e9                	addi	a5,a5,26
    80006558:	078e                	slli	a5,a5,0x3
    8000655a:	94be                	add	s1,s1,a5
    8000655c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006560:	fd043503          	ld	a0,-48(s0)
    80006564:	fffff097          	auipc	ra,0xfffff
    80006568:	a04080e7          	jalr	-1532(ra) # 80004f68 <fileclose>
    fileclose(wf);
    8000656c:	fc843503          	ld	a0,-56(s0)
    80006570:	fffff097          	auipc	ra,0xfffff
    80006574:	9f8080e7          	jalr	-1544(ra) # 80004f68 <fileclose>
    return -1;
    80006578:	57fd                	li	a5,-1
    8000657a:	a03d                	j	800065a8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000657c:	fc442783          	lw	a5,-60(s0)
    80006580:	0007c763          	bltz	a5,8000658e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006584:	07e9                	addi	a5,a5,26
    80006586:	078e                	slli	a5,a5,0x3
    80006588:	97a6                	add	a5,a5,s1
    8000658a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000658e:	fd043503          	ld	a0,-48(s0)
    80006592:	fffff097          	auipc	ra,0xfffff
    80006596:	9d6080e7          	jalr	-1578(ra) # 80004f68 <fileclose>
    fileclose(wf);
    8000659a:	fc843503          	ld	a0,-56(s0)
    8000659e:	fffff097          	auipc	ra,0xfffff
    800065a2:	9ca080e7          	jalr	-1590(ra) # 80004f68 <fileclose>
    return -1;
    800065a6:	57fd                	li	a5,-1
}
    800065a8:	853e                	mv	a0,a5
    800065aa:	70e2                	ld	ra,56(sp)
    800065ac:	7442                	ld	s0,48(sp)
    800065ae:	74a2                	ld	s1,40(sp)
    800065b0:	6121                	addi	sp,sp,64
    800065b2:	8082                	ret
	...

00000000800065c0 <kernelvec>:
    800065c0:	7111                	addi	sp,sp,-256
    800065c2:	e006                	sd	ra,0(sp)
    800065c4:	e40a                	sd	sp,8(sp)
    800065c6:	e80e                	sd	gp,16(sp)
    800065c8:	ec12                	sd	tp,24(sp)
    800065ca:	f016                	sd	t0,32(sp)
    800065cc:	f41a                	sd	t1,40(sp)
    800065ce:	f81e                	sd	t2,48(sp)
    800065d0:	fc22                	sd	s0,56(sp)
    800065d2:	e0a6                	sd	s1,64(sp)
    800065d4:	e4aa                	sd	a0,72(sp)
    800065d6:	e8ae                	sd	a1,80(sp)
    800065d8:	ecb2                	sd	a2,88(sp)
    800065da:	f0b6                	sd	a3,96(sp)
    800065dc:	f4ba                	sd	a4,104(sp)
    800065de:	f8be                	sd	a5,112(sp)
    800065e0:	fcc2                	sd	a6,120(sp)
    800065e2:	e146                	sd	a7,128(sp)
    800065e4:	e54a                	sd	s2,136(sp)
    800065e6:	e94e                	sd	s3,144(sp)
    800065e8:	ed52                	sd	s4,152(sp)
    800065ea:	f156                	sd	s5,160(sp)
    800065ec:	f55a                	sd	s6,168(sp)
    800065ee:	f95e                	sd	s7,176(sp)
    800065f0:	fd62                	sd	s8,184(sp)
    800065f2:	e1e6                	sd	s9,192(sp)
    800065f4:	e5ea                	sd	s10,200(sp)
    800065f6:	e9ee                	sd	s11,208(sp)
    800065f8:	edf2                	sd	t3,216(sp)
    800065fa:	f1f6                	sd	t4,224(sp)
    800065fc:	f5fa                	sd	t5,232(sp)
    800065fe:	f9fe                	sd	t6,240(sp)
    80006600:	b81fc0ef          	jal	ra,80003180 <kerneltrap>
    80006604:	6082                	ld	ra,0(sp)
    80006606:	6122                	ld	sp,8(sp)
    80006608:	61c2                	ld	gp,16(sp)
    8000660a:	7282                	ld	t0,32(sp)
    8000660c:	7322                	ld	t1,40(sp)
    8000660e:	73c2                	ld	t2,48(sp)
    80006610:	7462                	ld	s0,56(sp)
    80006612:	6486                	ld	s1,64(sp)
    80006614:	6526                	ld	a0,72(sp)
    80006616:	65c6                	ld	a1,80(sp)
    80006618:	6666                	ld	a2,88(sp)
    8000661a:	7686                	ld	a3,96(sp)
    8000661c:	7726                	ld	a4,104(sp)
    8000661e:	77c6                	ld	a5,112(sp)
    80006620:	7866                	ld	a6,120(sp)
    80006622:	688a                	ld	a7,128(sp)
    80006624:	692a                	ld	s2,136(sp)
    80006626:	69ca                	ld	s3,144(sp)
    80006628:	6a6a                	ld	s4,152(sp)
    8000662a:	7a8a                	ld	s5,160(sp)
    8000662c:	7b2a                	ld	s6,168(sp)
    8000662e:	7bca                	ld	s7,176(sp)
    80006630:	7c6a                	ld	s8,184(sp)
    80006632:	6c8e                	ld	s9,192(sp)
    80006634:	6d2e                	ld	s10,200(sp)
    80006636:	6dce                	ld	s11,208(sp)
    80006638:	6e6e                	ld	t3,216(sp)
    8000663a:	7e8e                	ld	t4,224(sp)
    8000663c:	7f2e                	ld	t5,232(sp)
    8000663e:	7fce                	ld	t6,240(sp)
    80006640:	6111                	addi	sp,sp,256
    80006642:	10200073          	sret
    80006646:	00000013          	nop
    8000664a:	00000013          	nop
    8000664e:	0001                	nop

0000000080006650 <timervec>:
    80006650:	34051573          	csrrw	a0,mscratch,a0
    80006654:	e10c                	sd	a1,0(a0)
    80006656:	e510                	sd	a2,8(a0)
    80006658:	e914                	sd	a3,16(a0)
    8000665a:	6d0c                	ld	a1,24(a0)
    8000665c:	7110                	ld	a2,32(a0)
    8000665e:	6194                	ld	a3,0(a1)
    80006660:	96b2                	add	a3,a3,a2
    80006662:	e194                	sd	a3,0(a1)
    80006664:	4589                	li	a1,2
    80006666:	14459073          	csrw	sip,a1
    8000666a:	6914                	ld	a3,16(a0)
    8000666c:	6510                	ld	a2,8(a0)
    8000666e:	610c                	ld	a1,0(a0)
    80006670:	34051573          	csrrw	a0,mscratch,a0
    80006674:	30200073          	mret
	...

000000008000667a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000667a:	1141                	addi	sp,sp,-16
    8000667c:	e422                	sd	s0,8(sp)
    8000667e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006680:	0c0007b7          	lui	a5,0xc000
    80006684:	4705                	li	a4,1
    80006686:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006688:	c3d8                	sw	a4,4(a5)
}
    8000668a:	6422                	ld	s0,8(sp)
    8000668c:	0141                	addi	sp,sp,16
    8000668e:	8082                	ret

0000000080006690 <plicinithart>:

void
plicinithart(void)
{
    80006690:	1141                	addi	sp,sp,-16
    80006692:	e406                	sd	ra,8(sp)
    80006694:	e022                	sd	s0,0(sp)
    80006696:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006698:	ffffb097          	auipc	ra,0xffffb
    8000669c:	626080e7          	jalr	1574(ra) # 80001cbe <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800066a0:	0085171b          	slliw	a4,a0,0x8
    800066a4:	0c0027b7          	lui	a5,0xc002
    800066a8:	97ba                	add	a5,a5,a4
    800066aa:	40200713          	li	a4,1026
    800066ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066b2:	00d5151b          	slliw	a0,a0,0xd
    800066b6:	0c2017b7          	lui	a5,0xc201
    800066ba:	97aa                	add	a5,a5,a0
    800066bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800066c0:	60a2                	ld	ra,8(sp)
    800066c2:	6402                	ld	s0,0(sp)
    800066c4:	0141                	addi	sp,sp,16
    800066c6:	8082                	ret

00000000800066c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800066c8:	1141                	addi	sp,sp,-16
    800066ca:	e406                	sd	ra,8(sp)
    800066cc:	e022                	sd	s0,0(sp)
    800066ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066d0:	ffffb097          	auipc	ra,0xffffb
    800066d4:	5ee080e7          	jalr	1518(ra) # 80001cbe <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800066d8:	00d5151b          	slliw	a0,a0,0xd
    800066dc:	0c2017b7          	lui	a5,0xc201
    800066e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800066e2:	43c8                	lw	a0,4(a5)
    800066e4:	60a2                	ld	ra,8(sp)
    800066e6:	6402                	ld	s0,0(sp)
    800066e8:	0141                	addi	sp,sp,16
    800066ea:	8082                	ret

00000000800066ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800066ec:	1101                	addi	sp,sp,-32
    800066ee:	ec06                	sd	ra,24(sp)
    800066f0:	e822                	sd	s0,16(sp)
    800066f2:	e426                	sd	s1,8(sp)
    800066f4:	1000                	addi	s0,sp,32
    800066f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800066f8:	ffffb097          	auipc	ra,0xffffb
    800066fc:	5c6080e7          	jalr	1478(ra) # 80001cbe <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006700:	00d5151b          	slliw	a0,a0,0xd
    80006704:	0c2017b7          	lui	a5,0xc201
    80006708:	97aa                	add	a5,a5,a0
    8000670a:	c3c4                	sw	s1,4(a5)
}
    8000670c:	60e2                	ld	ra,24(sp)
    8000670e:	6442                	ld	s0,16(sp)
    80006710:	64a2                	ld	s1,8(sp)
    80006712:	6105                	addi	sp,sp,32
    80006714:	8082                	ret

0000000080006716 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006716:	1141                	addi	sp,sp,-16
    80006718:	e406                	sd	ra,8(sp)
    8000671a:	e022                	sd	s0,0(sp)
    8000671c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000671e:	479d                	li	a5,7
    80006720:	04a7cc63          	blt	a5,a0,80006778 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006724:	0023f797          	auipc	a5,0x23f
    80006728:	bdc78793          	addi	a5,a5,-1060 # 80245300 <disk>
    8000672c:	97aa                	add	a5,a5,a0
    8000672e:	0187c783          	lbu	a5,24(a5)
    80006732:	ebb9                	bnez	a5,80006788 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006734:	00451693          	slli	a3,a0,0x4
    80006738:	0023f797          	auipc	a5,0x23f
    8000673c:	bc878793          	addi	a5,a5,-1080 # 80245300 <disk>
    80006740:	6398                	ld	a4,0(a5)
    80006742:	9736                	add	a4,a4,a3
    80006744:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006748:	6398                	ld	a4,0(a5)
    8000674a:	9736                	add	a4,a4,a3
    8000674c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006750:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006754:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006758:	97aa                	add	a5,a5,a0
    8000675a:	4705                	li	a4,1
    8000675c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006760:	0023f517          	auipc	a0,0x23f
    80006764:	bb850513          	addi	a0,a0,-1096 # 80245318 <disk+0x18>
    80006768:	ffffc097          	auipc	ra,0xffffc
    8000676c:	eda080e7          	jalr	-294(ra) # 80002642 <wakeup>
}
    80006770:	60a2                	ld	ra,8(sp)
    80006772:	6402                	ld	s0,0(sp)
    80006774:	0141                	addi	sp,sp,16
    80006776:	8082                	ret
    panic("free_desc 1");
    80006778:	00002517          	auipc	a0,0x2
    8000677c:	09850513          	addi	a0,a0,152 # 80008810 <syscalls+0x320>
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006788:	00002517          	auipc	a0,0x2
    8000678c:	09850513          	addi	a0,a0,152 # 80008820 <syscalls+0x330>
    80006790:	ffffa097          	auipc	ra,0xffffa
    80006794:	db0080e7          	jalr	-592(ra) # 80000540 <panic>

0000000080006798 <virtio_disk_init>:
{
    80006798:	1101                	addi	sp,sp,-32
    8000679a:	ec06                	sd	ra,24(sp)
    8000679c:	e822                	sd	s0,16(sp)
    8000679e:	e426                	sd	s1,8(sp)
    800067a0:	e04a                	sd	s2,0(sp)
    800067a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067a4:	00002597          	auipc	a1,0x2
    800067a8:	08c58593          	addi	a1,a1,140 # 80008830 <syscalls+0x340>
    800067ac:	0023f517          	auipc	a0,0x23f
    800067b0:	c7c50513          	addi	a0,a0,-900 # 80245428 <disk+0x128>
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	4ca080e7          	jalr	1226(ra) # 80000c7e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067bc:	100017b7          	lui	a5,0x10001
    800067c0:	4398                	lw	a4,0(a5)
    800067c2:	2701                	sext.w	a4,a4
    800067c4:	747277b7          	lui	a5,0x74727
    800067c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067cc:	14f71b63          	bne	a4,a5,80006922 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800067d0:	100017b7          	lui	a5,0x10001
    800067d4:	43dc                	lw	a5,4(a5)
    800067d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067d8:	4709                	li	a4,2
    800067da:	14e79463          	bne	a5,a4,80006922 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067de:	100017b7          	lui	a5,0x10001
    800067e2:	479c                	lw	a5,8(a5)
    800067e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800067e6:	12e79e63          	bne	a5,a4,80006922 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800067ea:	100017b7          	lui	a5,0x10001
    800067ee:	47d8                	lw	a4,12(a5)
    800067f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067f2:	554d47b7          	lui	a5,0x554d4
    800067f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800067fa:	12f71463          	bne	a4,a5,80006922 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800067fe:	100017b7          	lui	a5,0x10001
    80006802:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006806:	4705                	li	a4,1
    80006808:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000680a:	470d                	li	a4,3
    8000680c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000680e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006810:	c7ffe6b7          	lui	a3,0xc7ffe
    80006814:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47db931f>
    80006818:	8f75                	and	a4,a4,a3
    8000681a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000681c:	472d                	li	a4,11
    8000681e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006820:	5bbc                	lw	a5,112(a5)
    80006822:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006826:	8ba1                	andi	a5,a5,8
    80006828:	10078563          	beqz	a5,80006932 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000682c:	100017b7          	lui	a5,0x10001
    80006830:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006834:	43fc                	lw	a5,68(a5)
    80006836:	2781                	sext.w	a5,a5
    80006838:	10079563          	bnez	a5,80006942 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000683c:	100017b7          	lui	a5,0x10001
    80006840:	5bdc                	lw	a5,52(a5)
    80006842:	2781                	sext.w	a5,a5
  if(max == 0)
    80006844:	10078763          	beqz	a5,80006952 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006848:	471d                	li	a4,7
    8000684a:	10f77c63          	bgeu	a4,a5,80006962 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	398080e7          	jalr	920(ra) # 80000be6 <kalloc>
    80006856:	0023f497          	auipc	s1,0x23f
    8000685a:	aaa48493          	addi	s1,s1,-1366 # 80245300 <disk>
    8000685e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006860:	ffffa097          	auipc	ra,0xffffa
    80006864:	386080e7          	jalr	902(ra) # 80000be6 <kalloc>
    80006868:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000686a:	ffffa097          	auipc	ra,0xffffa
    8000686e:	37c080e7          	jalr	892(ra) # 80000be6 <kalloc>
    80006872:	87aa                	mv	a5,a0
    80006874:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006876:	6088                	ld	a0,0(s1)
    80006878:	cd6d                	beqz	a0,80006972 <virtio_disk_init+0x1da>
    8000687a:	0023f717          	auipc	a4,0x23f
    8000687e:	a8e73703          	ld	a4,-1394(a4) # 80245308 <disk+0x8>
    80006882:	cb65                	beqz	a4,80006972 <virtio_disk_init+0x1da>
    80006884:	c7fd                	beqz	a5,80006972 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006886:	6605                	lui	a2,0x1
    80006888:	4581                	li	a1,0
    8000688a:	ffffa097          	auipc	ra,0xffffa
    8000688e:	580080e7          	jalr	1408(ra) # 80000e0a <memset>
  memset(disk.avail, 0, PGSIZE);
    80006892:	0023f497          	auipc	s1,0x23f
    80006896:	a6e48493          	addi	s1,s1,-1426 # 80245300 <disk>
    8000689a:	6605                	lui	a2,0x1
    8000689c:	4581                	li	a1,0
    8000689e:	6488                	ld	a0,8(s1)
    800068a0:	ffffa097          	auipc	ra,0xffffa
    800068a4:	56a080e7          	jalr	1386(ra) # 80000e0a <memset>
  memset(disk.used, 0, PGSIZE);
    800068a8:	6605                	lui	a2,0x1
    800068aa:	4581                	li	a1,0
    800068ac:	6888                	ld	a0,16(s1)
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	55c080e7          	jalr	1372(ra) # 80000e0a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800068b6:	100017b7          	lui	a5,0x10001
    800068ba:	4721                	li	a4,8
    800068bc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800068be:	4098                	lw	a4,0(s1)
    800068c0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800068c4:	40d8                	lw	a4,4(s1)
    800068c6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800068ca:	6498                	ld	a4,8(s1)
    800068cc:	0007069b          	sext.w	a3,a4
    800068d0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800068d4:	9701                	srai	a4,a4,0x20
    800068d6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800068da:	6898                	ld	a4,16(s1)
    800068dc:	0007069b          	sext.w	a3,a4
    800068e0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800068e4:	9701                	srai	a4,a4,0x20
    800068e6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800068ea:	4705                	li	a4,1
    800068ec:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800068ee:	00e48c23          	sb	a4,24(s1)
    800068f2:	00e48ca3          	sb	a4,25(s1)
    800068f6:	00e48d23          	sb	a4,26(s1)
    800068fa:	00e48da3          	sb	a4,27(s1)
    800068fe:	00e48e23          	sb	a4,28(s1)
    80006902:	00e48ea3          	sb	a4,29(s1)
    80006906:	00e48f23          	sb	a4,30(s1)
    8000690a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000690e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006912:	0727a823          	sw	s2,112(a5)
}
    80006916:	60e2                	ld	ra,24(sp)
    80006918:	6442                	ld	s0,16(sp)
    8000691a:	64a2                	ld	s1,8(sp)
    8000691c:	6902                	ld	s2,0(sp)
    8000691e:	6105                	addi	sp,sp,32
    80006920:	8082                	ret
    panic("could not find virtio disk");
    80006922:	00002517          	auipc	a0,0x2
    80006926:	f1e50513          	addi	a0,a0,-226 # 80008840 <syscalls+0x350>
    8000692a:	ffffa097          	auipc	ra,0xffffa
    8000692e:	c16080e7          	jalr	-1002(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006932:	00002517          	auipc	a0,0x2
    80006936:	f2e50513          	addi	a0,a0,-210 # 80008860 <syscalls+0x370>
    8000693a:	ffffa097          	auipc	ra,0xffffa
    8000693e:	c06080e7          	jalr	-1018(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006942:	00002517          	auipc	a0,0x2
    80006946:	f3e50513          	addi	a0,a0,-194 # 80008880 <syscalls+0x390>
    8000694a:	ffffa097          	auipc	ra,0xffffa
    8000694e:	bf6080e7          	jalr	-1034(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006952:	00002517          	auipc	a0,0x2
    80006956:	f4e50513          	addi	a0,a0,-178 # 800088a0 <syscalls+0x3b0>
    8000695a:	ffffa097          	auipc	ra,0xffffa
    8000695e:	be6080e7          	jalr	-1050(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006962:	00002517          	auipc	a0,0x2
    80006966:	f5e50513          	addi	a0,a0,-162 # 800088c0 <syscalls+0x3d0>
    8000696a:	ffffa097          	auipc	ra,0xffffa
    8000696e:	bd6080e7          	jalr	-1066(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006972:	00002517          	auipc	a0,0x2
    80006976:	f6e50513          	addi	a0,a0,-146 # 800088e0 <syscalls+0x3f0>
    8000697a:	ffffa097          	auipc	ra,0xffffa
    8000697e:	bc6080e7          	jalr	-1082(ra) # 80000540 <panic>

0000000080006982 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006982:	7119                	addi	sp,sp,-128
    80006984:	fc86                	sd	ra,120(sp)
    80006986:	f8a2                	sd	s0,112(sp)
    80006988:	f4a6                	sd	s1,104(sp)
    8000698a:	f0ca                	sd	s2,96(sp)
    8000698c:	ecce                	sd	s3,88(sp)
    8000698e:	e8d2                	sd	s4,80(sp)
    80006990:	e4d6                	sd	s5,72(sp)
    80006992:	e0da                	sd	s6,64(sp)
    80006994:	fc5e                	sd	s7,56(sp)
    80006996:	f862                	sd	s8,48(sp)
    80006998:	f466                	sd	s9,40(sp)
    8000699a:	f06a                	sd	s10,32(sp)
    8000699c:	ec6e                	sd	s11,24(sp)
    8000699e:	0100                	addi	s0,sp,128
    800069a0:	8aaa                	mv	s5,a0
    800069a2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800069a4:	00c52d03          	lw	s10,12(a0)
    800069a8:	001d1d1b          	slliw	s10,s10,0x1
    800069ac:	1d02                	slli	s10,s10,0x20
    800069ae:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800069b2:	0023f517          	auipc	a0,0x23f
    800069b6:	a7650513          	addi	a0,a0,-1418 # 80245428 <disk+0x128>
    800069ba:	ffffa097          	auipc	ra,0xffffa
    800069be:	354080e7          	jalr	852(ra) # 80000d0e <acquire>
  for(int i = 0; i < 3; i++){
    800069c2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800069c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800069c6:	0023fb97          	auipc	s7,0x23f
    800069ca:	93ab8b93          	addi	s7,s7,-1734 # 80245300 <disk>
  for(int i = 0; i < 3; i++){
    800069ce:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800069d0:	0023fc97          	auipc	s9,0x23f
    800069d4:	a58c8c93          	addi	s9,s9,-1448 # 80245428 <disk+0x128>
    800069d8:	a08d                	j	80006a3a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800069da:	00fb8733          	add	a4,s7,a5
    800069de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800069e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800069e4:	0207c563          	bltz	a5,80006a0e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800069e8:	2905                	addiw	s2,s2,1
    800069ea:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800069ec:	05690c63          	beq	s2,s6,80006a44 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800069f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800069f2:	0023f717          	auipc	a4,0x23f
    800069f6:	90e70713          	addi	a4,a4,-1778 # 80245300 <disk>
    800069fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800069fc:	01874683          	lbu	a3,24(a4)
    80006a00:	fee9                	bnez	a3,800069da <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006a02:	2785                	addiw	a5,a5,1
    80006a04:	0705                	addi	a4,a4,1
    80006a06:	fe979be3          	bne	a5,s1,800069fc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006a0a:	57fd                	li	a5,-1
    80006a0c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006a0e:	01205d63          	blez	s2,80006a28 <virtio_disk_rw+0xa6>
    80006a12:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006a14:	000a2503          	lw	a0,0(s4)
    80006a18:	00000097          	auipc	ra,0x0
    80006a1c:	cfe080e7          	jalr	-770(ra) # 80006716 <free_desc>
      for(int j = 0; j < i; j++)
    80006a20:	2d85                	addiw	s11,s11,1
    80006a22:	0a11                	addi	s4,s4,4
    80006a24:	ff2d98e3          	bne	s11,s2,80006a14 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a28:	85e6                	mv	a1,s9
    80006a2a:	0023f517          	auipc	a0,0x23f
    80006a2e:	8ee50513          	addi	a0,a0,-1810 # 80245318 <disk+0x18>
    80006a32:	ffffc097          	auipc	ra,0xffffc
    80006a36:	bac080e7          	jalr	-1108(ra) # 800025de <sleep>
  for(int i = 0; i < 3; i++){
    80006a3a:	f8040a13          	addi	s4,s0,-128
{
    80006a3e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006a40:	894e                	mv	s2,s3
    80006a42:	b77d                	j	800069f0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a44:	f8042503          	lw	a0,-128(s0)
    80006a48:	00a50713          	addi	a4,a0,10
    80006a4c:	0712                	slli	a4,a4,0x4

  if(write)
    80006a4e:	0023f797          	auipc	a5,0x23f
    80006a52:	8b278793          	addi	a5,a5,-1870 # 80245300 <disk>
    80006a56:	00e786b3          	add	a3,a5,a4
    80006a5a:	01803633          	snez	a2,s8
    80006a5e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006a60:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006a64:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a68:	f6070613          	addi	a2,a4,-160
    80006a6c:	6394                	ld	a3,0(a5)
    80006a6e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a70:	00870593          	addi	a1,a4,8
    80006a74:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a76:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a78:	0007b803          	ld	a6,0(a5)
    80006a7c:	9642                	add	a2,a2,a6
    80006a7e:	46c1                	li	a3,16
    80006a80:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006a82:	4585                	li	a1,1
    80006a84:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006a88:	f8442683          	lw	a3,-124(s0)
    80006a8c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006a90:	0692                	slli	a3,a3,0x4
    80006a92:	9836                	add	a6,a6,a3
    80006a94:	058a8613          	addi	a2,s5,88
    80006a98:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006a9c:	0007b803          	ld	a6,0(a5)
    80006aa0:	96c2                	add	a3,a3,a6
    80006aa2:	40000613          	li	a2,1024
    80006aa6:	c690                	sw	a2,8(a3)
  if(write)
    80006aa8:	001c3613          	seqz	a2,s8
    80006aac:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006ab0:	00166613          	ori	a2,a2,1
    80006ab4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006ab8:	f8842603          	lw	a2,-120(s0)
    80006abc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ac0:	00250693          	addi	a3,a0,2
    80006ac4:	0692                	slli	a3,a3,0x4
    80006ac6:	96be                	add	a3,a3,a5
    80006ac8:	58fd                	li	a7,-1
    80006aca:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006ace:	0612                	slli	a2,a2,0x4
    80006ad0:	9832                	add	a6,a6,a2
    80006ad2:	f9070713          	addi	a4,a4,-112
    80006ad6:	973e                	add	a4,a4,a5
    80006ad8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006adc:	6398                	ld	a4,0(a5)
    80006ade:	9732                	add	a4,a4,a2
    80006ae0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006ae2:	4609                	li	a2,2
    80006ae4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006ae8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006aec:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006af0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006af4:	6794                	ld	a3,8(a5)
    80006af6:	0026d703          	lhu	a4,2(a3)
    80006afa:	8b1d                	andi	a4,a4,7
    80006afc:	0706                	slli	a4,a4,0x1
    80006afe:	96ba                	add	a3,a3,a4
    80006b00:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006b04:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b08:	6798                	ld	a4,8(a5)
    80006b0a:	00275783          	lhu	a5,2(a4)
    80006b0e:	2785                	addiw	a5,a5,1
    80006b10:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b14:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b18:	100017b7          	lui	a5,0x10001
    80006b1c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b20:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006b24:	0023f917          	auipc	s2,0x23f
    80006b28:	90490913          	addi	s2,s2,-1788 # 80245428 <disk+0x128>
  while(b->disk == 1) {
    80006b2c:	4485                	li	s1,1
    80006b2e:	00b79c63          	bne	a5,a1,80006b46 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006b32:	85ca                	mv	a1,s2
    80006b34:	8556                	mv	a0,s5
    80006b36:	ffffc097          	auipc	ra,0xffffc
    80006b3a:	aa8080e7          	jalr	-1368(ra) # 800025de <sleep>
  while(b->disk == 1) {
    80006b3e:	004aa783          	lw	a5,4(s5)
    80006b42:	fe9788e3          	beq	a5,s1,80006b32 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006b46:	f8042903          	lw	s2,-128(s0)
    80006b4a:	00290713          	addi	a4,s2,2
    80006b4e:	0712                	slli	a4,a4,0x4
    80006b50:	0023e797          	auipc	a5,0x23e
    80006b54:	7b078793          	addi	a5,a5,1968 # 80245300 <disk>
    80006b58:	97ba                	add	a5,a5,a4
    80006b5a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006b5e:	0023e997          	auipc	s3,0x23e
    80006b62:	7a298993          	addi	s3,s3,1954 # 80245300 <disk>
    80006b66:	00491713          	slli	a4,s2,0x4
    80006b6a:	0009b783          	ld	a5,0(s3)
    80006b6e:	97ba                	add	a5,a5,a4
    80006b70:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b74:	854a                	mv	a0,s2
    80006b76:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b7a:	00000097          	auipc	ra,0x0
    80006b7e:	b9c080e7          	jalr	-1124(ra) # 80006716 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006b82:	8885                	andi	s1,s1,1
    80006b84:	f0ed                	bnez	s1,80006b66 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006b86:	0023f517          	auipc	a0,0x23f
    80006b8a:	8a250513          	addi	a0,a0,-1886 # 80245428 <disk+0x128>
    80006b8e:	ffffa097          	auipc	ra,0xffffa
    80006b92:	234080e7          	jalr	564(ra) # 80000dc2 <release>
}
    80006b96:	70e6                	ld	ra,120(sp)
    80006b98:	7446                	ld	s0,112(sp)
    80006b9a:	74a6                	ld	s1,104(sp)
    80006b9c:	7906                	ld	s2,96(sp)
    80006b9e:	69e6                	ld	s3,88(sp)
    80006ba0:	6a46                	ld	s4,80(sp)
    80006ba2:	6aa6                	ld	s5,72(sp)
    80006ba4:	6b06                	ld	s6,64(sp)
    80006ba6:	7be2                	ld	s7,56(sp)
    80006ba8:	7c42                	ld	s8,48(sp)
    80006baa:	7ca2                	ld	s9,40(sp)
    80006bac:	7d02                	ld	s10,32(sp)
    80006bae:	6de2                	ld	s11,24(sp)
    80006bb0:	6109                	addi	sp,sp,128
    80006bb2:	8082                	ret

0000000080006bb4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006bb4:	1101                	addi	sp,sp,-32
    80006bb6:	ec06                	sd	ra,24(sp)
    80006bb8:	e822                	sd	s0,16(sp)
    80006bba:	e426                	sd	s1,8(sp)
    80006bbc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006bbe:	0023e497          	auipc	s1,0x23e
    80006bc2:	74248493          	addi	s1,s1,1858 # 80245300 <disk>
    80006bc6:	0023f517          	auipc	a0,0x23f
    80006bca:	86250513          	addi	a0,a0,-1950 # 80245428 <disk+0x128>
    80006bce:	ffffa097          	auipc	ra,0xffffa
    80006bd2:	140080e7          	jalr	320(ra) # 80000d0e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006bd6:	10001737          	lui	a4,0x10001
    80006bda:	533c                	lw	a5,96(a4)
    80006bdc:	8b8d                	andi	a5,a5,3
    80006bde:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006be0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006be4:	689c                	ld	a5,16(s1)
    80006be6:	0204d703          	lhu	a4,32(s1)
    80006bea:	0027d783          	lhu	a5,2(a5)
    80006bee:	04f70863          	beq	a4,a5,80006c3e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006bf2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006bf6:	6898                	ld	a4,16(s1)
    80006bf8:	0204d783          	lhu	a5,32(s1)
    80006bfc:	8b9d                	andi	a5,a5,7
    80006bfe:	078e                	slli	a5,a5,0x3
    80006c00:	97ba                	add	a5,a5,a4
    80006c02:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c04:	00278713          	addi	a4,a5,2
    80006c08:	0712                	slli	a4,a4,0x4
    80006c0a:	9726                	add	a4,a4,s1
    80006c0c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006c10:	e721                	bnez	a4,80006c58 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c12:	0789                	addi	a5,a5,2
    80006c14:	0792                	slli	a5,a5,0x4
    80006c16:	97a6                	add	a5,a5,s1
    80006c18:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006c1a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c1e:	ffffc097          	auipc	ra,0xffffc
    80006c22:	a24080e7          	jalr	-1500(ra) # 80002642 <wakeup>

    disk.used_idx += 1;
    80006c26:	0204d783          	lhu	a5,32(s1)
    80006c2a:	2785                	addiw	a5,a5,1
    80006c2c:	17c2                	slli	a5,a5,0x30
    80006c2e:	93c1                	srli	a5,a5,0x30
    80006c30:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006c34:	6898                	ld	a4,16(s1)
    80006c36:	00275703          	lhu	a4,2(a4)
    80006c3a:	faf71ce3          	bne	a4,a5,80006bf2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006c3e:	0023e517          	auipc	a0,0x23e
    80006c42:	7ea50513          	addi	a0,a0,2026 # 80245428 <disk+0x128>
    80006c46:	ffffa097          	auipc	ra,0xffffa
    80006c4a:	17c080e7          	jalr	380(ra) # 80000dc2 <release>
}
    80006c4e:	60e2                	ld	ra,24(sp)
    80006c50:	6442                	ld	s0,16(sp)
    80006c52:	64a2                	ld	s1,8(sp)
    80006c54:	6105                	addi	sp,sp,32
    80006c56:	8082                	ret
      panic("virtio_disk_intr status");
    80006c58:	00002517          	auipc	a0,0x2
    80006c5c:	ca050513          	addi	a0,a0,-864 # 800088f8 <syscalls+0x408>
    80006c60:	ffffa097          	auipc	ra,0xffffa
    80006c64:	8e0080e7          	jalr	-1824(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
