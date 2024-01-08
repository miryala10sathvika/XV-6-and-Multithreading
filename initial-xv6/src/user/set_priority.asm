
user/_set_priority:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"
int main(int argc , char *args[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    if(argc<3){
   c:	4789                	li	a5,2
   e:	00a7cf63          	blt	a5,a0,2c <main+0x2c>
        printf("Please give complete data\n");
  12:	00001517          	auipc	a0,0x1
  16:	85e50513          	addi	a0,a0,-1954 # 870 <malloc+0xe8>
  1a:	00000097          	auipc	ra,0x0
  1e:	6b6080e7          	jalr	1718(ra) # 6d0 <printf>
        exit(1);
  22:	4505                	li	a0,1
  24:	00000097          	auipc	ra,0x0
  28:	302080e7          	jalr	770(ra) # 326 <exit>
  2c:	84ae                	mv	s1,a1
        return -1;
    }
    int pid=atoi(args[1]);
  2e:	6588                	ld	a0,8(a1)
  30:	00000097          	auipc	ra,0x0
  34:	1fc080e7          	jalr	508(ra) # 22c <atoi>
  38:	892a                	mv	s2,a0
    int priority=atoi(args[2]);
  3a:	6888                	ld	a0,16(s1)
  3c:	00000097          	auipc	ra,0x0
  40:	1f0080e7          	jalr	496(ra) # 22c <atoi>
  44:	85aa                	mv	a1,a0
    if(priority<=100 && priority>=0)
  46:	0005071b          	sext.w	a4,a0
  4a:	06400793          	li	a5,100
  4e:	02e7ec63          	bltu	a5,a4,86 <main+0x86>
    {
        int old_sp = set_priority(pid, priority);
  52:	854a                	mv	a0,s2
  54:	00000097          	auipc	ra,0x0
  58:	39a080e7          	jalr	922(ra) # 3ee <set_priority>
        if (old_sp == -1) {
  5c:	57fd                	li	a5,-1
  5e:	00f50763          	beq	a0,a5,6c <main+0x6c>
    {
        printf("Please give priority between 1 and 100\n");
        exit(1);
        return -1;
    }
    exit(0);
  62:	4501                	li	a0,0
  64:	00000097          	auipc	ra,0x0
  68:	2c2080e7          	jalr	706(ra) # 326 <exit>
            printf("Process with given pid does not exists.\n");
  6c:	00001517          	auipc	a0,0x1
  70:	82450513          	addi	a0,a0,-2012 # 890 <malloc+0x108>
  74:	00000097          	auipc	ra,0x0
  78:	65c080e7          	jalr	1628(ra) # 6d0 <printf>
            exit(1);
  7c:	4505                	li	a0,1
  7e:	00000097          	auipc	ra,0x0
  82:	2a8080e7          	jalr	680(ra) # 326 <exit>
        printf("Please give priority between 1 and 100\n");
  86:	00001517          	auipc	a0,0x1
  8a:	83a50513          	addi	a0,a0,-1990 # 8c0 <malloc+0x138>
  8e:	00000097          	auipc	ra,0x0
  92:	642080e7          	jalr	1602(ra) # 6d0 <printf>
        exit(1);
  96:	4505                	li	a0,1
  98:	00000097          	auipc	ra,0x0
  9c:	28e080e7          	jalr	654(ra) # 326 <exit>

00000000000000a0 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  a0:	1141                	addi	sp,sp,-16
  a2:	e406                	sd	ra,8(sp)
  a4:	e022                	sd	s0,0(sp)
  a6:	0800                	addi	s0,sp,16
  extern int main();
  main();
  a8:	00000097          	auipc	ra,0x0
  ac:	f58080e7          	jalr	-168(ra) # 0 <main>
  exit(0);
  b0:	4501                	li	a0,0
  b2:	00000097          	auipc	ra,0x0
  b6:	274080e7          	jalr	628(ra) # 326 <exit>

00000000000000ba <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  ba:	1141                	addi	sp,sp,-16
  bc:	e422                	sd	s0,8(sp)
  be:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  c0:	87aa                	mv	a5,a0
  c2:	0585                	addi	a1,a1,1
  c4:	0785                	addi	a5,a5,1
  c6:	fff5c703          	lbu	a4,-1(a1)
  ca:	fee78fa3          	sb	a4,-1(a5)
  ce:	fb75                	bnez	a4,c2 <strcpy+0x8>
    ;
  return os;
}
  d0:	6422                	ld	s0,8(sp)
  d2:	0141                	addi	sp,sp,16
  d4:	8082                	ret

00000000000000d6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  d6:	1141                	addi	sp,sp,-16
  d8:	e422                	sd	s0,8(sp)
  da:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  dc:	00054783          	lbu	a5,0(a0)
  e0:	cb91                	beqz	a5,f4 <strcmp+0x1e>
  e2:	0005c703          	lbu	a4,0(a1)
  e6:	00f71763          	bne	a4,a5,f4 <strcmp+0x1e>
    p++, q++;
  ea:	0505                	addi	a0,a0,1
  ec:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  ee:	00054783          	lbu	a5,0(a0)
  f2:	fbe5                	bnez	a5,e2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  f4:	0005c503          	lbu	a0,0(a1)
}
  f8:	40a7853b          	subw	a0,a5,a0
  fc:	6422                	ld	s0,8(sp)
  fe:	0141                	addi	sp,sp,16
 100:	8082                	ret

0000000000000102 <strlen>:

uint
strlen(const char *s)
{
 102:	1141                	addi	sp,sp,-16
 104:	e422                	sd	s0,8(sp)
 106:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 108:	00054783          	lbu	a5,0(a0)
 10c:	cf91                	beqz	a5,128 <strlen+0x26>
 10e:	0505                	addi	a0,a0,1
 110:	87aa                	mv	a5,a0
 112:	4685                	li	a3,1
 114:	9e89                	subw	a3,a3,a0
 116:	00f6853b          	addw	a0,a3,a5
 11a:	0785                	addi	a5,a5,1
 11c:	fff7c703          	lbu	a4,-1(a5)
 120:	fb7d                	bnez	a4,116 <strlen+0x14>
    ;
  return n;
}
 122:	6422                	ld	s0,8(sp)
 124:	0141                	addi	sp,sp,16
 126:	8082                	ret
  for(n = 0; s[n]; n++)
 128:	4501                	li	a0,0
 12a:	bfe5                	j	122 <strlen+0x20>

000000000000012c <memset>:

void*
memset(void *dst, int c, uint n)
{
 12c:	1141                	addi	sp,sp,-16
 12e:	e422                	sd	s0,8(sp)
 130:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 132:	ca19                	beqz	a2,148 <memset+0x1c>
 134:	87aa                	mv	a5,a0
 136:	1602                	slli	a2,a2,0x20
 138:	9201                	srli	a2,a2,0x20
 13a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 13e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 142:	0785                	addi	a5,a5,1
 144:	fee79de3          	bne	a5,a4,13e <memset+0x12>
  }
  return dst;
}
 148:	6422                	ld	s0,8(sp)
 14a:	0141                	addi	sp,sp,16
 14c:	8082                	ret

000000000000014e <strchr>:

char*
strchr(const char *s, char c)
{
 14e:	1141                	addi	sp,sp,-16
 150:	e422                	sd	s0,8(sp)
 152:	0800                	addi	s0,sp,16
  for(; *s; s++)
 154:	00054783          	lbu	a5,0(a0)
 158:	cb99                	beqz	a5,16e <strchr+0x20>
    if(*s == c)
 15a:	00f58763          	beq	a1,a5,168 <strchr+0x1a>
  for(; *s; s++)
 15e:	0505                	addi	a0,a0,1
 160:	00054783          	lbu	a5,0(a0)
 164:	fbfd                	bnez	a5,15a <strchr+0xc>
      return (char*)s;
  return 0;
 166:	4501                	li	a0,0
}
 168:	6422                	ld	s0,8(sp)
 16a:	0141                	addi	sp,sp,16
 16c:	8082                	ret
  return 0;
 16e:	4501                	li	a0,0
 170:	bfe5                	j	168 <strchr+0x1a>

0000000000000172 <gets>:

char*
gets(char *buf, int max)
{
 172:	711d                	addi	sp,sp,-96
 174:	ec86                	sd	ra,88(sp)
 176:	e8a2                	sd	s0,80(sp)
 178:	e4a6                	sd	s1,72(sp)
 17a:	e0ca                	sd	s2,64(sp)
 17c:	fc4e                	sd	s3,56(sp)
 17e:	f852                	sd	s4,48(sp)
 180:	f456                	sd	s5,40(sp)
 182:	f05a                	sd	s6,32(sp)
 184:	ec5e                	sd	s7,24(sp)
 186:	1080                	addi	s0,sp,96
 188:	8baa                	mv	s7,a0
 18a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 18c:	892a                	mv	s2,a0
 18e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 190:	4aa9                	li	s5,10
 192:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 194:	89a6                	mv	s3,s1
 196:	2485                	addiw	s1,s1,1
 198:	0344d863          	bge	s1,s4,1c8 <gets+0x56>
    cc = read(0, &c, 1);
 19c:	4605                	li	a2,1
 19e:	faf40593          	addi	a1,s0,-81
 1a2:	4501                	li	a0,0
 1a4:	00000097          	auipc	ra,0x0
 1a8:	19a080e7          	jalr	410(ra) # 33e <read>
    if(cc < 1)
 1ac:	00a05e63          	blez	a0,1c8 <gets+0x56>
    buf[i++] = c;
 1b0:	faf44783          	lbu	a5,-81(s0)
 1b4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1b8:	01578763          	beq	a5,s5,1c6 <gets+0x54>
 1bc:	0905                	addi	s2,s2,1
 1be:	fd679be3          	bne	a5,s6,194 <gets+0x22>
  for(i=0; i+1 < max; ){
 1c2:	89a6                	mv	s3,s1
 1c4:	a011                	j	1c8 <gets+0x56>
 1c6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1c8:	99de                	add	s3,s3,s7
 1ca:	00098023          	sb	zero,0(s3)
  return buf;
}
 1ce:	855e                	mv	a0,s7
 1d0:	60e6                	ld	ra,88(sp)
 1d2:	6446                	ld	s0,80(sp)
 1d4:	64a6                	ld	s1,72(sp)
 1d6:	6906                	ld	s2,64(sp)
 1d8:	79e2                	ld	s3,56(sp)
 1da:	7a42                	ld	s4,48(sp)
 1dc:	7aa2                	ld	s5,40(sp)
 1de:	7b02                	ld	s6,32(sp)
 1e0:	6be2                	ld	s7,24(sp)
 1e2:	6125                	addi	sp,sp,96
 1e4:	8082                	ret

00000000000001e6 <stat>:

int
stat(const char *n, struct stat *st)
{
 1e6:	1101                	addi	sp,sp,-32
 1e8:	ec06                	sd	ra,24(sp)
 1ea:	e822                	sd	s0,16(sp)
 1ec:	e426                	sd	s1,8(sp)
 1ee:	e04a                	sd	s2,0(sp)
 1f0:	1000                	addi	s0,sp,32
 1f2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1f4:	4581                	li	a1,0
 1f6:	00000097          	auipc	ra,0x0
 1fa:	170080e7          	jalr	368(ra) # 366 <open>
  if(fd < 0)
 1fe:	02054563          	bltz	a0,228 <stat+0x42>
 202:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 204:	85ca                	mv	a1,s2
 206:	00000097          	auipc	ra,0x0
 20a:	178080e7          	jalr	376(ra) # 37e <fstat>
 20e:	892a                	mv	s2,a0
  close(fd);
 210:	8526                	mv	a0,s1
 212:	00000097          	auipc	ra,0x0
 216:	13c080e7          	jalr	316(ra) # 34e <close>
  return r;
}
 21a:	854a                	mv	a0,s2
 21c:	60e2                	ld	ra,24(sp)
 21e:	6442                	ld	s0,16(sp)
 220:	64a2                	ld	s1,8(sp)
 222:	6902                	ld	s2,0(sp)
 224:	6105                	addi	sp,sp,32
 226:	8082                	ret
    return -1;
 228:	597d                	li	s2,-1
 22a:	bfc5                	j	21a <stat+0x34>

000000000000022c <atoi>:

int
atoi(const char *s)
{
 22c:	1141                	addi	sp,sp,-16
 22e:	e422                	sd	s0,8(sp)
 230:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 232:	00054683          	lbu	a3,0(a0)
 236:	fd06879b          	addiw	a5,a3,-48
 23a:	0ff7f793          	zext.b	a5,a5
 23e:	4625                	li	a2,9
 240:	02f66863          	bltu	a2,a5,270 <atoi+0x44>
 244:	872a                	mv	a4,a0
  n = 0;
 246:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 248:	0705                	addi	a4,a4,1
 24a:	0025179b          	slliw	a5,a0,0x2
 24e:	9fa9                	addw	a5,a5,a0
 250:	0017979b          	slliw	a5,a5,0x1
 254:	9fb5                	addw	a5,a5,a3
 256:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 25a:	00074683          	lbu	a3,0(a4)
 25e:	fd06879b          	addiw	a5,a3,-48
 262:	0ff7f793          	zext.b	a5,a5
 266:	fef671e3          	bgeu	a2,a5,248 <atoi+0x1c>
  return n;
}
 26a:	6422                	ld	s0,8(sp)
 26c:	0141                	addi	sp,sp,16
 26e:	8082                	ret
  n = 0;
 270:	4501                	li	a0,0
 272:	bfe5                	j	26a <atoi+0x3e>

0000000000000274 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 274:	1141                	addi	sp,sp,-16
 276:	e422                	sd	s0,8(sp)
 278:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 27a:	02b57463          	bgeu	a0,a1,2a2 <memmove+0x2e>
    while(n-- > 0)
 27e:	00c05f63          	blez	a2,29c <memmove+0x28>
 282:	1602                	slli	a2,a2,0x20
 284:	9201                	srli	a2,a2,0x20
 286:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 28a:	872a                	mv	a4,a0
      *dst++ = *src++;
 28c:	0585                	addi	a1,a1,1
 28e:	0705                	addi	a4,a4,1
 290:	fff5c683          	lbu	a3,-1(a1)
 294:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 298:	fee79ae3          	bne	a5,a4,28c <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 29c:	6422                	ld	s0,8(sp)
 29e:	0141                	addi	sp,sp,16
 2a0:	8082                	ret
    dst += n;
 2a2:	00c50733          	add	a4,a0,a2
    src += n;
 2a6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2a8:	fec05ae3          	blez	a2,29c <memmove+0x28>
 2ac:	fff6079b          	addiw	a5,a2,-1
 2b0:	1782                	slli	a5,a5,0x20
 2b2:	9381                	srli	a5,a5,0x20
 2b4:	fff7c793          	not	a5,a5
 2b8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2ba:	15fd                	addi	a1,a1,-1
 2bc:	177d                	addi	a4,a4,-1
 2be:	0005c683          	lbu	a3,0(a1)
 2c2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2c6:	fee79ae3          	bne	a5,a4,2ba <memmove+0x46>
 2ca:	bfc9                	j	29c <memmove+0x28>

00000000000002cc <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2cc:	1141                	addi	sp,sp,-16
 2ce:	e422                	sd	s0,8(sp)
 2d0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d2:	ca05                	beqz	a2,302 <memcmp+0x36>
 2d4:	fff6069b          	addiw	a3,a2,-1
 2d8:	1682                	slli	a3,a3,0x20
 2da:	9281                	srli	a3,a3,0x20
 2dc:	0685                	addi	a3,a3,1
 2de:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e0:	00054783          	lbu	a5,0(a0)
 2e4:	0005c703          	lbu	a4,0(a1)
 2e8:	00e79863          	bne	a5,a4,2f8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2ec:	0505                	addi	a0,a0,1
    p2++;
 2ee:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f0:	fed518e3          	bne	a0,a3,2e0 <memcmp+0x14>
  }
  return 0;
 2f4:	4501                	li	a0,0
 2f6:	a019                	j	2fc <memcmp+0x30>
      return *p1 - *p2;
 2f8:	40e7853b          	subw	a0,a5,a4
}
 2fc:	6422                	ld	s0,8(sp)
 2fe:	0141                	addi	sp,sp,16
 300:	8082                	ret
  return 0;
 302:	4501                	li	a0,0
 304:	bfe5                	j	2fc <memcmp+0x30>

0000000000000306 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 306:	1141                	addi	sp,sp,-16
 308:	e406                	sd	ra,8(sp)
 30a:	e022                	sd	s0,0(sp)
 30c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 30e:	00000097          	auipc	ra,0x0
 312:	f66080e7          	jalr	-154(ra) # 274 <memmove>
}
 316:	60a2                	ld	ra,8(sp)
 318:	6402                	ld	s0,0(sp)
 31a:	0141                	addi	sp,sp,16
 31c:	8082                	ret

000000000000031e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 31e:	4885                	li	a7,1
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <exit>:
.global exit
exit:
 li a7, SYS_exit
 326:	4889                	li	a7,2
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <wait>:
.global wait
wait:
 li a7, SYS_wait
 32e:	488d                	li	a7,3
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 336:	4891                	li	a7,4
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <read>:
.global read
read:
 li a7, SYS_read
 33e:	4895                	li	a7,5
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <write>:
.global write
write:
 li a7, SYS_write
 346:	48c1                	li	a7,16
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <close>:
.global close
close:
 li a7, SYS_close
 34e:	48d5                	li	a7,21
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <kill>:
.global kill
kill:
 li a7, SYS_kill
 356:	4899                	li	a7,6
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <exec>:
.global exec
exec:
 li a7, SYS_exec
 35e:	489d                	li	a7,7
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <open>:
.global open
open:
 li a7, SYS_open
 366:	48bd                	li	a7,15
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 36e:	48c5                	li	a7,17
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 376:	48c9                	li	a7,18
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 37e:	48a1                	li	a7,8
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <link>:
.global link
link:
 li a7, SYS_link
 386:	48cd                	li	a7,19
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 38e:	48d1                	li	a7,20
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 396:	48a5                	li	a7,9
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <dup>:
.global dup
dup:
 li a7, SYS_dup
 39e:	48a9                	li	a7,10
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3a6:	48ad                	li	a7,11
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ae:	48b1                	li	a7,12
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3b6:	48b5                	li	a7,13
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3be:	48b9                	li	a7,14
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3c6:	48d9                	li	a7,22
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 3ce:	48dd                	li	a7,23
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 3d6:	48e1                	li	a7,24
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 3de:	48e5                	li	a7,25
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <getps>:
.global getps
getps:
 li a7, SYS_getps
 3e6:	48e9                	li	a7,26
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3ee:	48ed                	li	a7,27
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f6:	1101                	addi	sp,sp,-32
 3f8:	ec06                	sd	ra,24(sp)
 3fa:	e822                	sd	s0,16(sp)
 3fc:	1000                	addi	s0,sp,32
 3fe:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 402:	4605                	li	a2,1
 404:	fef40593          	addi	a1,s0,-17
 408:	00000097          	auipc	ra,0x0
 40c:	f3e080e7          	jalr	-194(ra) # 346 <write>
}
 410:	60e2                	ld	ra,24(sp)
 412:	6442                	ld	s0,16(sp)
 414:	6105                	addi	sp,sp,32
 416:	8082                	ret

0000000000000418 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 418:	7139                	addi	sp,sp,-64
 41a:	fc06                	sd	ra,56(sp)
 41c:	f822                	sd	s0,48(sp)
 41e:	f426                	sd	s1,40(sp)
 420:	f04a                	sd	s2,32(sp)
 422:	ec4e                	sd	s3,24(sp)
 424:	0080                	addi	s0,sp,64
 426:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 428:	c299                	beqz	a3,42e <printint+0x16>
 42a:	0805c963          	bltz	a1,4bc <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42e:	2581                	sext.w	a1,a1
  neg = 0;
 430:	4881                	li	a7,0
 432:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 436:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 438:	2601                	sext.w	a2,a2
 43a:	00000517          	auipc	a0,0x0
 43e:	50e50513          	addi	a0,a0,1294 # 948 <digits>
 442:	883a                	mv	a6,a4
 444:	2705                	addiw	a4,a4,1
 446:	02c5f7bb          	remuw	a5,a1,a2
 44a:	1782                	slli	a5,a5,0x20
 44c:	9381                	srli	a5,a5,0x20
 44e:	97aa                	add	a5,a5,a0
 450:	0007c783          	lbu	a5,0(a5)
 454:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 458:	0005879b          	sext.w	a5,a1
 45c:	02c5d5bb          	divuw	a1,a1,a2
 460:	0685                	addi	a3,a3,1
 462:	fec7f0e3          	bgeu	a5,a2,442 <printint+0x2a>
  if(neg)
 466:	00088c63          	beqz	a7,47e <printint+0x66>
    buf[i++] = '-';
 46a:	fd070793          	addi	a5,a4,-48
 46e:	00878733          	add	a4,a5,s0
 472:	02d00793          	li	a5,45
 476:	fef70823          	sb	a5,-16(a4)
 47a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 47e:	02e05863          	blez	a4,4ae <printint+0x96>
 482:	fc040793          	addi	a5,s0,-64
 486:	00e78933          	add	s2,a5,a4
 48a:	fff78993          	addi	s3,a5,-1
 48e:	99ba                	add	s3,s3,a4
 490:	377d                	addiw	a4,a4,-1
 492:	1702                	slli	a4,a4,0x20
 494:	9301                	srli	a4,a4,0x20
 496:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 49a:	fff94583          	lbu	a1,-1(s2)
 49e:	8526                	mv	a0,s1
 4a0:	00000097          	auipc	ra,0x0
 4a4:	f56080e7          	jalr	-170(ra) # 3f6 <putc>
  while(--i >= 0)
 4a8:	197d                	addi	s2,s2,-1
 4aa:	ff3918e3          	bne	s2,s3,49a <printint+0x82>
}
 4ae:	70e2                	ld	ra,56(sp)
 4b0:	7442                	ld	s0,48(sp)
 4b2:	74a2                	ld	s1,40(sp)
 4b4:	7902                	ld	s2,32(sp)
 4b6:	69e2                	ld	s3,24(sp)
 4b8:	6121                	addi	sp,sp,64
 4ba:	8082                	ret
    x = -xx;
 4bc:	40b005bb          	negw	a1,a1
    neg = 1;
 4c0:	4885                	li	a7,1
    x = -xx;
 4c2:	bf85                	j	432 <printint+0x1a>

00000000000004c4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4c4:	7119                	addi	sp,sp,-128
 4c6:	fc86                	sd	ra,120(sp)
 4c8:	f8a2                	sd	s0,112(sp)
 4ca:	f4a6                	sd	s1,104(sp)
 4cc:	f0ca                	sd	s2,96(sp)
 4ce:	ecce                	sd	s3,88(sp)
 4d0:	e8d2                	sd	s4,80(sp)
 4d2:	e4d6                	sd	s5,72(sp)
 4d4:	e0da                	sd	s6,64(sp)
 4d6:	fc5e                	sd	s7,56(sp)
 4d8:	f862                	sd	s8,48(sp)
 4da:	f466                	sd	s9,40(sp)
 4dc:	f06a                	sd	s10,32(sp)
 4de:	ec6e                	sd	s11,24(sp)
 4e0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4e2:	0005c903          	lbu	s2,0(a1)
 4e6:	18090f63          	beqz	s2,684 <vprintf+0x1c0>
 4ea:	8aaa                	mv	s5,a0
 4ec:	8b32                	mv	s6,a2
 4ee:	00158493          	addi	s1,a1,1
  state = 0;
 4f2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4f4:	02500a13          	li	s4,37
 4f8:	4c55                	li	s8,21
 4fa:	00000c97          	auipc	s9,0x0
 4fe:	3f6c8c93          	addi	s9,s9,1014 # 8f0 <malloc+0x168>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 502:	02800d93          	li	s11,40
  putc(fd, 'x');
 506:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 508:	00000b97          	auipc	s7,0x0
 50c:	440b8b93          	addi	s7,s7,1088 # 948 <digits>
 510:	a839                	j	52e <vprintf+0x6a>
        putc(fd, c);
 512:	85ca                	mv	a1,s2
 514:	8556                	mv	a0,s5
 516:	00000097          	auipc	ra,0x0
 51a:	ee0080e7          	jalr	-288(ra) # 3f6 <putc>
 51e:	a019                	j	524 <vprintf+0x60>
    } else if(state == '%'){
 520:	01498d63          	beq	s3,s4,53a <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 524:	0485                	addi	s1,s1,1
 526:	fff4c903          	lbu	s2,-1(s1)
 52a:	14090d63          	beqz	s2,684 <vprintf+0x1c0>
    if(state == 0){
 52e:	fe0999e3          	bnez	s3,520 <vprintf+0x5c>
      if(c == '%'){
 532:	ff4910e3          	bne	s2,s4,512 <vprintf+0x4e>
        state = '%';
 536:	89d2                	mv	s3,s4
 538:	b7f5                	j	524 <vprintf+0x60>
      if(c == 'd'){
 53a:	11490c63          	beq	s2,s4,652 <vprintf+0x18e>
 53e:	f9d9079b          	addiw	a5,s2,-99
 542:	0ff7f793          	zext.b	a5,a5
 546:	10fc6e63          	bltu	s8,a5,662 <vprintf+0x19e>
 54a:	f9d9079b          	addiw	a5,s2,-99
 54e:	0ff7f713          	zext.b	a4,a5
 552:	10ec6863          	bltu	s8,a4,662 <vprintf+0x19e>
 556:	00271793          	slli	a5,a4,0x2
 55a:	97e6                	add	a5,a5,s9
 55c:	439c                	lw	a5,0(a5)
 55e:	97e6                	add	a5,a5,s9
 560:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 562:	008b0913          	addi	s2,s6,8
 566:	4685                	li	a3,1
 568:	4629                	li	a2,10
 56a:	000b2583          	lw	a1,0(s6)
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	ea8080e7          	jalr	-344(ra) # 418 <printint>
 578:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 57a:	4981                	li	s3,0
 57c:	b765                	j	524 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 57e:	008b0913          	addi	s2,s6,8
 582:	4681                	li	a3,0
 584:	4629                	li	a2,10
 586:	000b2583          	lw	a1,0(s6)
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	e8c080e7          	jalr	-372(ra) # 418 <printint>
 594:	8b4a                	mv	s6,s2
      state = 0;
 596:	4981                	li	s3,0
 598:	b771                	j	524 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 59a:	008b0913          	addi	s2,s6,8
 59e:	4681                	li	a3,0
 5a0:	866a                	mv	a2,s10
 5a2:	000b2583          	lw	a1,0(s6)
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	e70080e7          	jalr	-400(ra) # 418 <printint>
 5b0:	8b4a                	mv	s6,s2
      state = 0;
 5b2:	4981                	li	s3,0
 5b4:	bf85                	j	524 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5b6:	008b0793          	addi	a5,s6,8
 5ba:	f8f43423          	sd	a5,-120(s0)
 5be:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5c2:	03000593          	li	a1,48
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	e2e080e7          	jalr	-466(ra) # 3f6 <putc>
  putc(fd, 'x');
 5d0:	07800593          	li	a1,120
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e20080e7          	jalr	-480(ra) # 3f6 <putc>
 5de:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5e0:	03c9d793          	srli	a5,s3,0x3c
 5e4:	97de                	add	a5,a5,s7
 5e6:	0007c583          	lbu	a1,0(a5)
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e0a080e7          	jalr	-502(ra) # 3f6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5f4:	0992                	slli	s3,s3,0x4
 5f6:	397d                	addiw	s2,s2,-1
 5f8:	fe0914e3          	bnez	s2,5e0 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5fc:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 600:	4981                	li	s3,0
 602:	b70d                	j	524 <vprintf+0x60>
        s = va_arg(ap, char*);
 604:	008b0913          	addi	s2,s6,8
 608:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 60c:	02098163          	beqz	s3,62e <vprintf+0x16a>
        while(*s != 0){
 610:	0009c583          	lbu	a1,0(s3)
 614:	c5ad                	beqz	a1,67e <vprintf+0x1ba>
          putc(fd, *s);
 616:	8556                	mv	a0,s5
 618:	00000097          	auipc	ra,0x0
 61c:	dde080e7          	jalr	-546(ra) # 3f6 <putc>
          s++;
 620:	0985                	addi	s3,s3,1
        while(*s != 0){
 622:	0009c583          	lbu	a1,0(s3)
 626:	f9e5                	bnez	a1,616 <vprintf+0x152>
        s = va_arg(ap, char*);
 628:	8b4a                	mv	s6,s2
      state = 0;
 62a:	4981                	li	s3,0
 62c:	bde5                	j	524 <vprintf+0x60>
          s = "(null)";
 62e:	00000997          	auipc	s3,0x0
 632:	2ba98993          	addi	s3,s3,698 # 8e8 <malloc+0x160>
        while(*s != 0){
 636:	85ee                	mv	a1,s11
 638:	bff9                	j	616 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 63a:	008b0913          	addi	s2,s6,8
 63e:	000b4583          	lbu	a1,0(s6)
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	db2080e7          	jalr	-590(ra) # 3f6 <putc>
 64c:	8b4a                	mv	s6,s2
      state = 0;
 64e:	4981                	li	s3,0
 650:	bdd1                	j	524 <vprintf+0x60>
        putc(fd, c);
 652:	85d2                	mv	a1,s4
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	da0080e7          	jalr	-608(ra) # 3f6 <putc>
      state = 0;
 65e:	4981                	li	s3,0
 660:	b5d1                	j	524 <vprintf+0x60>
        putc(fd, '%');
 662:	85d2                	mv	a1,s4
 664:	8556                	mv	a0,s5
 666:	00000097          	auipc	ra,0x0
 66a:	d90080e7          	jalr	-624(ra) # 3f6 <putc>
        putc(fd, c);
 66e:	85ca                	mv	a1,s2
 670:	8556                	mv	a0,s5
 672:	00000097          	auipc	ra,0x0
 676:	d84080e7          	jalr	-636(ra) # 3f6 <putc>
      state = 0;
 67a:	4981                	li	s3,0
 67c:	b565                	j	524 <vprintf+0x60>
        s = va_arg(ap, char*);
 67e:	8b4a                	mv	s6,s2
      state = 0;
 680:	4981                	li	s3,0
 682:	b54d                	j	524 <vprintf+0x60>
    }
  }
}
 684:	70e6                	ld	ra,120(sp)
 686:	7446                	ld	s0,112(sp)
 688:	74a6                	ld	s1,104(sp)
 68a:	7906                	ld	s2,96(sp)
 68c:	69e6                	ld	s3,88(sp)
 68e:	6a46                	ld	s4,80(sp)
 690:	6aa6                	ld	s5,72(sp)
 692:	6b06                	ld	s6,64(sp)
 694:	7be2                	ld	s7,56(sp)
 696:	7c42                	ld	s8,48(sp)
 698:	7ca2                	ld	s9,40(sp)
 69a:	7d02                	ld	s10,32(sp)
 69c:	6de2                	ld	s11,24(sp)
 69e:	6109                	addi	sp,sp,128
 6a0:	8082                	ret

00000000000006a2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6a2:	715d                	addi	sp,sp,-80
 6a4:	ec06                	sd	ra,24(sp)
 6a6:	e822                	sd	s0,16(sp)
 6a8:	1000                	addi	s0,sp,32
 6aa:	e010                	sd	a2,0(s0)
 6ac:	e414                	sd	a3,8(s0)
 6ae:	e818                	sd	a4,16(s0)
 6b0:	ec1c                	sd	a5,24(s0)
 6b2:	03043023          	sd	a6,32(s0)
 6b6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6ba:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6be:	8622                	mv	a2,s0
 6c0:	00000097          	auipc	ra,0x0
 6c4:	e04080e7          	jalr	-508(ra) # 4c4 <vprintf>
}
 6c8:	60e2                	ld	ra,24(sp)
 6ca:	6442                	ld	s0,16(sp)
 6cc:	6161                	addi	sp,sp,80
 6ce:	8082                	ret

00000000000006d0 <printf>:

void
printf(const char *fmt, ...)
{
 6d0:	711d                	addi	sp,sp,-96
 6d2:	ec06                	sd	ra,24(sp)
 6d4:	e822                	sd	s0,16(sp)
 6d6:	1000                	addi	s0,sp,32
 6d8:	e40c                	sd	a1,8(s0)
 6da:	e810                	sd	a2,16(s0)
 6dc:	ec14                	sd	a3,24(s0)
 6de:	f018                	sd	a4,32(s0)
 6e0:	f41c                	sd	a5,40(s0)
 6e2:	03043823          	sd	a6,48(s0)
 6e6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6ea:	00840613          	addi	a2,s0,8
 6ee:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6f2:	85aa                	mv	a1,a0
 6f4:	4505                	li	a0,1
 6f6:	00000097          	auipc	ra,0x0
 6fa:	dce080e7          	jalr	-562(ra) # 4c4 <vprintf>
}
 6fe:	60e2                	ld	ra,24(sp)
 700:	6442                	ld	s0,16(sp)
 702:	6125                	addi	sp,sp,96
 704:	8082                	ret

0000000000000706 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 706:	1141                	addi	sp,sp,-16
 708:	e422                	sd	s0,8(sp)
 70a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 70c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 710:	00001797          	auipc	a5,0x1
 714:	8f07b783          	ld	a5,-1808(a5) # 1000 <freep>
 718:	a02d                	j	742 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 71a:	4618                	lw	a4,8(a2)
 71c:	9f2d                	addw	a4,a4,a1
 71e:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 722:	6398                	ld	a4,0(a5)
 724:	6310                	ld	a2,0(a4)
 726:	a83d                	j	764 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 728:	ff852703          	lw	a4,-8(a0)
 72c:	9f31                	addw	a4,a4,a2
 72e:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 730:	ff053683          	ld	a3,-16(a0)
 734:	a091                	j	778 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 736:	6398                	ld	a4,0(a5)
 738:	00e7e463          	bltu	a5,a4,740 <free+0x3a>
 73c:	00e6ea63          	bltu	a3,a4,750 <free+0x4a>
{
 740:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 742:	fed7fae3          	bgeu	a5,a3,736 <free+0x30>
 746:	6398                	ld	a4,0(a5)
 748:	00e6e463          	bltu	a3,a4,750 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74c:	fee7eae3          	bltu	a5,a4,740 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 750:	ff852583          	lw	a1,-8(a0)
 754:	6390                	ld	a2,0(a5)
 756:	02059813          	slli	a6,a1,0x20
 75a:	01c85713          	srli	a4,a6,0x1c
 75e:	9736                	add	a4,a4,a3
 760:	fae60de3          	beq	a2,a4,71a <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 764:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 768:	4790                	lw	a2,8(a5)
 76a:	02061593          	slli	a1,a2,0x20
 76e:	01c5d713          	srli	a4,a1,0x1c
 772:	973e                	add	a4,a4,a5
 774:	fae68ae3          	beq	a3,a4,728 <free+0x22>
    p->s.ptr = bp->s.ptr;
 778:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 77a:	00001717          	auipc	a4,0x1
 77e:	88f73323          	sd	a5,-1914(a4) # 1000 <freep>
}
 782:	6422                	ld	s0,8(sp)
 784:	0141                	addi	sp,sp,16
 786:	8082                	ret

0000000000000788 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 788:	7139                	addi	sp,sp,-64
 78a:	fc06                	sd	ra,56(sp)
 78c:	f822                	sd	s0,48(sp)
 78e:	f426                	sd	s1,40(sp)
 790:	f04a                	sd	s2,32(sp)
 792:	ec4e                	sd	s3,24(sp)
 794:	e852                	sd	s4,16(sp)
 796:	e456                	sd	s5,8(sp)
 798:	e05a                	sd	s6,0(sp)
 79a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 79c:	02051493          	slli	s1,a0,0x20
 7a0:	9081                	srli	s1,s1,0x20
 7a2:	04bd                	addi	s1,s1,15
 7a4:	8091                	srli	s1,s1,0x4
 7a6:	0014899b          	addiw	s3,s1,1
 7aa:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ac:	00001517          	auipc	a0,0x1
 7b0:	85453503          	ld	a0,-1964(a0) # 1000 <freep>
 7b4:	c515                	beqz	a0,7e0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b8:	4798                	lw	a4,8(a5)
 7ba:	02977f63          	bgeu	a4,s1,7f8 <malloc+0x70>
 7be:	8a4e                	mv	s4,s3
 7c0:	0009871b          	sext.w	a4,s3
 7c4:	6685                	lui	a3,0x1
 7c6:	00d77363          	bgeu	a4,a3,7cc <malloc+0x44>
 7ca:	6a05                	lui	s4,0x1
 7cc:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d4:	00001917          	auipc	s2,0x1
 7d8:	82c90913          	addi	s2,s2,-2004 # 1000 <freep>
  if(p == (char*)-1)
 7dc:	5afd                	li	s5,-1
 7de:	a895                	j	852 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7e0:	00001797          	auipc	a5,0x1
 7e4:	83078793          	addi	a5,a5,-2000 # 1010 <base>
 7e8:	00001717          	auipc	a4,0x1
 7ec:	80f73c23          	sd	a5,-2024(a4) # 1000 <freep>
 7f0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7f6:	b7e1                	j	7be <malloc+0x36>
      if(p->s.size == nunits)
 7f8:	02e48c63          	beq	s1,a4,830 <malloc+0xa8>
        p->s.size -= nunits;
 7fc:	4137073b          	subw	a4,a4,s3
 800:	c798                	sw	a4,8(a5)
        p += p->s.size;
 802:	02071693          	slli	a3,a4,0x20
 806:	01c6d713          	srli	a4,a3,0x1c
 80a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 80c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 810:	00000717          	auipc	a4,0x0
 814:	7ea73823          	sd	a0,2032(a4) # 1000 <freep>
      return (void*)(p + 1);
 818:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 81c:	70e2                	ld	ra,56(sp)
 81e:	7442                	ld	s0,48(sp)
 820:	74a2                	ld	s1,40(sp)
 822:	7902                	ld	s2,32(sp)
 824:	69e2                	ld	s3,24(sp)
 826:	6a42                	ld	s4,16(sp)
 828:	6aa2                	ld	s5,8(sp)
 82a:	6b02                	ld	s6,0(sp)
 82c:	6121                	addi	sp,sp,64
 82e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 830:	6398                	ld	a4,0(a5)
 832:	e118                	sd	a4,0(a0)
 834:	bff1                	j	810 <malloc+0x88>
  hp->s.size = nu;
 836:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 83a:	0541                	addi	a0,a0,16
 83c:	00000097          	auipc	ra,0x0
 840:	eca080e7          	jalr	-310(ra) # 706 <free>
  return freep;
 844:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 848:	d971                	beqz	a0,81c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 84a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84c:	4798                	lw	a4,8(a5)
 84e:	fa9775e3          	bgeu	a4,s1,7f8 <malloc+0x70>
    if(p == freep)
 852:	00093703          	ld	a4,0(s2)
 856:	853e                	mv	a0,a5
 858:	fef719e3          	bne	a4,a5,84a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 85c:	8552                	mv	a0,s4
 85e:	00000097          	auipc	ra,0x0
 862:	b50080e7          	jalr	-1200(ra) # 3ae <sbrk>
  if(p == (char*)-1)
 866:	fd5518e3          	bne	a0,s5,836 <malloc+0xae>
        return 0;
 86a:	4501                	li	a0,0
 86c:	bf45                	j	81c <malloc+0x94>
