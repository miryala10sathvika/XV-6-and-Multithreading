
user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

#define NFORK 10
#define IO 5

int main()
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	addi	s0,sp,64
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
   e:	4481                	li	s1,0
  10:	4929                	li	s2,10
  {
    pid = fork();
  12:	00000097          	auipc	ra,0x0
  16:	342080e7          	jalr	834(ra) # 354 <fork>
    if (pid < 0)
  1a:	00054963          	bltz	a0,2c <main+0x2c>
      break;
    if (pid == 0)
  1e:	c129                	beqz	a0,60 <main+0x60>
  for (n = 0; n < NFORK; n++)
  20:	2485                	addiw	s1,s1,1
  22:	ff2498e3          	bne	s1,s2,12 <main+0x12>
  26:	4901                	li	s2,0
  28:	4981                	li	s3,0
  2a:	a051                	j	ae <main+0xae>
      }
      //printf("Process %d with %d finished\n", n,getpid());
      exit(0);
    }
  }
  for (; n > 0; n--)
  2c:	fe904de3          	bgtz	s1,26 <main+0x26>
  30:	4901                	li	s2,0
  32:	4981                	li	s3,0
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  34:	45a9                	li	a1,10
  36:	02b9c63b          	divw	a2,s3,a1
  3a:	02b945bb          	divw	a1,s2,a1
  3e:	00001517          	auipc	a0,0x1
  42:	87250513          	addi	a0,a0,-1934 # 8b0 <malloc+0xf2>
  46:	00000097          	auipc	ra,0x0
  4a:	6c0080e7          	jalr	1728(ra) # 706 <printf>
  getps();
  4e:	00000097          	auipc	ra,0x0
  52:	3ce080e7          	jalr	974(ra) # 41c <getps>
  exit(0);
  56:	4501                	li	a0,0
  58:	00000097          	auipc	ra,0x0
  5c:	304080e7          	jalr	772(ra) # 35c <exit>
      if (n < IO)
  60:	4791                	li	a5,4
  62:	0297dd63          	bge	a5,s1,9c <main+0x9c>
        for (volatile int i = 0; i < 1000000000; i++)
  66:	fc042223          	sw	zero,-60(s0)
  6a:	fc442703          	lw	a4,-60(s0)
  6e:	2701                	sext.w	a4,a4
  70:	3b9ad7b7          	lui	a5,0x3b9ad
  74:	9ff78793          	addi	a5,a5,-1537 # 3b9ac9ff <base+0x3b9ab9ef>
  78:	00e7cd63          	blt	a5,a4,92 <main+0x92>
  7c:	873e                	mv	a4,a5
  7e:	fc442783          	lw	a5,-60(s0)
  82:	2785                	addiw	a5,a5,1
  84:	fcf42223          	sw	a5,-60(s0)
  88:	fc442783          	lw	a5,-60(s0)
  8c:	2781                	sext.w	a5,a5
  8e:	fef758e3          	bge	a4,a5,7e <main+0x7e>
      exit(0);
  92:	4501                	li	a0,0
  94:	00000097          	auipc	ra,0x0
  98:	2c8080e7          	jalr	712(ra) # 35c <exit>
        sleep(200); // IO bound processes
  9c:	0c800513          	li	a0,200
  a0:	00000097          	auipc	ra,0x0
  a4:	34c080e7          	jalr	844(ra) # 3ec <sleep>
  a8:	b7ed                	j	92 <main+0x92>
  for (; n > 0; n--)
  aa:	34fd                	addiw	s1,s1,-1
  ac:	d4c1                	beqz	s1,34 <main+0x34>
    if (waitx(0, &wtime, &rtime) >= 0)
  ae:	fc840613          	addi	a2,s0,-56
  b2:	fcc40593          	addi	a1,s0,-52
  b6:	4501                	li	a0,0
  b8:	00000097          	auipc	ra,0x0
  bc:	344080e7          	jalr	836(ra) # 3fc <waitx>
  c0:	fe0545e3          	bltz	a0,aa <main+0xaa>
      trtime += rtime;
  c4:	fc842783          	lw	a5,-56(s0)
  c8:	0127893b          	addw	s2,a5,s2
      twtime += wtime;
  cc:	fcc42783          	lw	a5,-52(s0)
  d0:	013789bb          	addw	s3,a5,s3
  d4:	bfd9                	j	aa <main+0xaa>

00000000000000d6 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  d6:	1141                	addi	sp,sp,-16
  d8:	e406                	sd	ra,8(sp)
  da:	e022                	sd	s0,0(sp)
  dc:	0800                	addi	s0,sp,16
  extern int main();
  main();
  de:	00000097          	auipc	ra,0x0
  e2:	f22080e7          	jalr	-222(ra) # 0 <main>
  exit(0);
  e6:	4501                	li	a0,0
  e8:	00000097          	auipc	ra,0x0
  ec:	274080e7          	jalr	628(ra) # 35c <exit>

00000000000000f0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  f0:	1141                	addi	sp,sp,-16
  f2:	e422                	sd	s0,8(sp)
  f4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  f6:	87aa                	mv	a5,a0
  f8:	0585                	addi	a1,a1,1
  fa:	0785                	addi	a5,a5,1
  fc:	fff5c703          	lbu	a4,-1(a1)
 100:	fee78fa3          	sb	a4,-1(a5)
 104:	fb75                	bnez	a4,f8 <strcpy+0x8>
    ;
  return os;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	addi	sp,sp,16
 10a:	8082                	ret

000000000000010c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 10c:	1141                	addi	sp,sp,-16
 10e:	e422                	sd	s0,8(sp)
 110:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 112:	00054783          	lbu	a5,0(a0)
 116:	cb91                	beqz	a5,12a <strcmp+0x1e>
 118:	0005c703          	lbu	a4,0(a1)
 11c:	00f71763          	bne	a4,a5,12a <strcmp+0x1e>
    p++, q++;
 120:	0505                	addi	a0,a0,1
 122:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 124:	00054783          	lbu	a5,0(a0)
 128:	fbe5                	bnez	a5,118 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 12a:	0005c503          	lbu	a0,0(a1)
}
 12e:	40a7853b          	subw	a0,a5,a0
 132:	6422                	ld	s0,8(sp)
 134:	0141                	addi	sp,sp,16
 136:	8082                	ret

0000000000000138 <strlen>:

uint
strlen(const char *s)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 13e:	00054783          	lbu	a5,0(a0)
 142:	cf91                	beqz	a5,15e <strlen+0x26>
 144:	0505                	addi	a0,a0,1
 146:	87aa                	mv	a5,a0
 148:	4685                	li	a3,1
 14a:	9e89                	subw	a3,a3,a0
 14c:	00f6853b          	addw	a0,a3,a5
 150:	0785                	addi	a5,a5,1
 152:	fff7c703          	lbu	a4,-1(a5)
 156:	fb7d                	bnez	a4,14c <strlen+0x14>
    ;
  return n;
}
 158:	6422                	ld	s0,8(sp)
 15a:	0141                	addi	sp,sp,16
 15c:	8082                	ret
  for(n = 0; s[n]; n++)
 15e:	4501                	li	a0,0
 160:	bfe5                	j	158 <strlen+0x20>

0000000000000162 <memset>:

void*
memset(void *dst, int c, uint n)
{
 162:	1141                	addi	sp,sp,-16
 164:	e422                	sd	s0,8(sp)
 166:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 168:	ca19                	beqz	a2,17e <memset+0x1c>
 16a:	87aa                	mv	a5,a0
 16c:	1602                	slli	a2,a2,0x20
 16e:	9201                	srli	a2,a2,0x20
 170:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 174:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 178:	0785                	addi	a5,a5,1
 17a:	fee79de3          	bne	a5,a4,174 <memset+0x12>
  }
  return dst;
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret

0000000000000184 <strchr>:

char*
strchr(const char *s, char c)
{
 184:	1141                	addi	sp,sp,-16
 186:	e422                	sd	s0,8(sp)
 188:	0800                	addi	s0,sp,16
  for(; *s; s++)
 18a:	00054783          	lbu	a5,0(a0)
 18e:	cb99                	beqz	a5,1a4 <strchr+0x20>
    if(*s == c)
 190:	00f58763          	beq	a1,a5,19e <strchr+0x1a>
  for(; *s; s++)
 194:	0505                	addi	a0,a0,1
 196:	00054783          	lbu	a5,0(a0)
 19a:	fbfd                	bnez	a5,190 <strchr+0xc>
      return (char*)s;
  return 0;
 19c:	4501                	li	a0,0
}
 19e:	6422                	ld	s0,8(sp)
 1a0:	0141                	addi	sp,sp,16
 1a2:	8082                	ret
  return 0;
 1a4:	4501                	li	a0,0
 1a6:	bfe5                	j	19e <strchr+0x1a>

00000000000001a8 <gets>:

char*
gets(char *buf, int max)
{
 1a8:	711d                	addi	sp,sp,-96
 1aa:	ec86                	sd	ra,88(sp)
 1ac:	e8a2                	sd	s0,80(sp)
 1ae:	e4a6                	sd	s1,72(sp)
 1b0:	e0ca                	sd	s2,64(sp)
 1b2:	fc4e                	sd	s3,56(sp)
 1b4:	f852                	sd	s4,48(sp)
 1b6:	f456                	sd	s5,40(sp)
 1b8:	f05a                	sd	s6,32(sp)
 1ba:	ec5e                	sd	s7,24(sp)
 1bc:	1080                	addi	s0,sp,96
 1be:	8baa                	mv	s7,a0
 1c0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1c2:	892a                	mv	s2,a0
 1c4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1c6:	4aa9                	li	s5,10
 1c8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ca:	89a6                	mv	s3,s1
 1cc:	2485                	addiw	s1,s1,1
 1ce:	0344d863          	bge	s1,s4,1fe <gets+0x56>
    cc = read(0, &c, 1);
 1d2:	4605                	li	a2,1
 1d4:	faf40593          	addi	a1,s0,-81
 1d8:	4501                	li	a0,0
 1da:	00000097          	auipc	ra,0x0
 1de:	19a080e7          	jalr	410(ra) # 374 <read>
    if(cc < 1)
 1e2:	00a05e63          	blez	a0,1fe <gets+0x56>
    buf[i++] = c;
 1e6:	faf44783          	lbu	a5,-81(s0)
 1ea:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ee:	01578763          	beq	a5,s5,1fc <gets+0x54>
 1f2:	0905                	addi	s2,s2,1
 1f4:	fd679be3          	bne	a5,s6,1ca <gets+0x22>
  for(i=0; i+1 < max; ){
 1f8:	89a6                	mv	s3,s1
 1fa:	a011                	j	1fe <gets+0x56>
 1fc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1fe:	99de                	add	s3,s3,s7
 200:	00098023          	sb	zero,0(s3)
  return buf;
}
 204:	855e                	mv	a0,s7
 206:	60e6                	ld	ra,88(sp)
 208:	6446                	ld	s0,80(sp)
 20a:	64a6                	ld	s1,72(sp)
 20c:	6906                	ld	s2,64(sp)
 20e:	79e2                	ld	s3,56(sp)
 210:	7a42                	ld	s4,48(sp)
 212:	7aa2                	ld	s5,40(sp)
 214:	7b02                	ld	s6,32(sp)
 216:	6be2                	ld	s7,24(sp)
 218:	6125                	addi	sp,sp,96
 21a:	8082                	ret

000000000000021c <stat>:

int
stat(const char *n, struct stat *st)
{
 21c:	1101                	addi	sp,sp,-32
 21e:	ec06                	sd	ra,24(sp)
 220:	e822                	sd	s0,16(sp)
 222:	e426                	sd	s1,8(sp)
 224:	e04a                	sd	s2,0(sp)
 226:	1000                	addi	s0,sp,32
 228:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 22a:	4581                	li	a1,0
 22c:	00000097          	auipc	ra,0x0
 230:	170080e7          	jalr	368(ra) # 39c <open>
  if(fd < 0)
 234:	02054563          	bltz	a0,25e <stat+0x42>
 238:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 23a:	85ca                	mv	a1,s2
 23c:	00000097          	auipc	ra,0x0
 240:	178080e7          	jalr	376(ra) # 3b4 <fstat>
 244:	892a                	mv	s2,a0
  close(fd);
 246:	8526                	mv	a0,s1
 248:	00000097          	auipc	ra,0x0
 24c:	13c080e7          	jalr	316(ra) # 384 <close>
  return r;
}
 250:	854a                	mv	a0,s2
 252:	60e2                	ld	ra,24(sp)
 254:	6442                	ld	s0,16(sp)
 256:	64a2                	ld	s1,8(sp)
 258:	6902                	ld	s2,0(sp)
 25a:	6105                	addi	sp,sp,32
 25c:	8082                	ret
    return -1;
 25e:	597d                	li	s2,-1
 260:	bfc5                	j	250 <stat+0x34>

0000000000000262 <atoi>:

int
atoi(const char *s)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 268:	00054683          	lbu	a3,0(a0)
 26c:	fd06879b          	addiw	a5,a3,-48
 270:	0ff7f793          	zext.b	a5,a5
 274:	4625                	li	a2,9
 276:	02f66863          	bltu	a2,a5,2a6 <atoi+0x44>
 27a:	872a                	mv	a4,a0
  n = 0;
 27c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 27e:	0705                	addi	a4,a4,1
 280:	0025179b          	slliw	a5,a0,0x2
 284:	9fa9                	addw	a5,a5,a0
 286:	0017979b          	slliw	a5,a5,0x1
 28a:	9fb5                	addw	a5,a5,a3
 28c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 290:	00074683          	lbu	a3,0(a4)
 294:	fd06879b          	addiw	a5,a3,-48
 298:	0ff7f793          	zext.b	a5,a5
 29c:	fef671e3          	bgeu	a2,a5,27e <atoi+0x1c>
  return n;
}
 2a0:	6422                	ld	s0,8(sp)
 2a2:	0141                	addi	sp,sp,16
 2a4:	8082                	ret
  n = 0;
 2a6:	4501                	li	a0,0
 2a8:	bfe5                	j	2a0 <atoi+0x3e>

00000000000002aa <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2aa:	1141                	addi	sp,sp,-16
 2ac:	e422                	sd	s0,8(sp)
 2ae:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2b0:	02b57463          	bgeu	a0,a1,2d8 <memmove+0x2e>
    while(n-- > 0)
 2b4:	00c05f63          	blez	a2,2d2 <memmove+0x28>
 2b8:	1602                	slli	a2,a2,0x20
 2ba:	9201                	srli	a2,a2,0x20
 2bc:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2c0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2c2:	0585                	addi	a1,a1,1
 2c4:	0705                	addi	a4,a4,1
 2c6:	fff5c683          	lbu	a3,-1(a1)
 2ca:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2ce:	fee79ae3          	bne	a5,a4,2c2 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2d2:	6422                	ld	s0,8(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret
    dst += n;
 2d8:	00c50733          	add	a4,a0,a2
    src += n;
 2dc:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2de:	fec05ae3          	blez	a2,2d2 <memmove+0x28>
 2e2:	fff6079b          	addiw	a5,a2,-1
 2e6:	1782                	slli	a5,a5,0x20
 2e8:	9381                	srli	a5,a5,0x20
 2ea:	fff7c793          	not	a5,a5
 2ee:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2f0:	15fd                	addi	a1,a1,-1
 2f2:	177d                	addi	a4,a4,-1
 2f4:	0005c683          	lbu	a3,0(a1)
 2f8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2fc:	fee79ae3          	bne	a5,a4,2f0 <memmove+0x46>
 300:	bfc9                	j	2d2 <memmove+0x28>

0000000000000302 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 302:	1141                	addi	sp,sp,-16
 304:	e422                	sd	s0,8(sp)
 306:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 308:	ca05                	beqz	a2,338 <memcmp+0x36>
 30a:	fff6069b          	addiw	a3,a2,-1
 30e:	1682                	slli	a3,a3,0x20
 310:	9281                	srli	a3,a3,0x20
 312:	0685                	addi	a3,a3,1
 314:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 316:	00054783          	lbu	a5,0(a0)
 31a:	0005c703          	lbu	a4,0(a1)
 31e:	00e79863          	bne	a5,a4,32e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 322:	0505                	addi	a0,a0,1
    p2++;
 324:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 326:	fed518e3          	bne	a0,a3,316 <memcmp+0x14>
  }
  return 0;
 32a:	4501                	li	a0,0
 32c:	a019                	j	332 <memcmp+0x30>
      return *p1 - *p2;
 32e:	40e7853b          	subw	a0,a5,a4
}
 332:	6422                	ld	s0,8(sp)
 334:	0141                	addi	sp,sp,16
 336:	8082                	ret
  return 0;
 338:	4501                	li	a0,0
 33a:	bfe5                	j	332 <memcmp+0x30>

000000000000033c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 33c:	1141                	addi	sp,sp,-16
 33e:	e406                	sd	ra,8(sp)
 340:	e022                	sd	s0,0(sp)
 342:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 344:	00000097          	auipc	ra,0x0
 348:	f66080e7          	jalr	-154(ra) # 2aa <memmove>
}
 34c:	60a2                	ld	ra,8(sp)
 34e:	6402                	ld	s0,0(sp)
 350:	0141                	addi	sp,sp,16
 352:	8082                	ret

0000000000000354 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 354:	4885                	li	a7,1
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <exit>:
.global exit
exit:
 li a7, SYS_exit
 35c:	4889                	li	a7,2
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <wait>:
.global wait
wait:
 li a7, SYS_wait
 364:	488d                	li	a7,3
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 36c:	4891                	li	a7,4
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <read>:
.global read
read:
 li a7, SYS_read
 374:	4895                	li	a7,5
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <write>:
.global write
write:
 li a7, SYS_write
 37c:	48c1                	li	a7,16
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <close>:
.global close
close:
 li a7, SYS_close
 384:	48d5                	li	a7,21
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <kill>:
.global kill
kill:
 li a7, SYS_kill
 38c:	4899                	li	a7,6
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <exec>:
.global exec
exec:
 li a7, SYS_exec
 394:	489d                	li	a7,7
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <open>:
.global open
open:
 li a7, SYS_open
 39c:	48bd                	li	a7,15
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3a4:	48c5                	li	a7,17
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3ac:	48c9                	li	a7,18
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3b4:	48a1                	li	a7,8
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <link>:
.global link
link:
 li a7, SYS_link
 3bc:	48cd                	li	a7,19
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3c4:	48d1                	li	a7,20
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3cc:	48a5                	li	a7,9
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3d4:	48a9                	li	a7,10
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3dc:	48ad                	li	a7,11
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3e4:	48b1                	li	a7,12
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3ec:	48b5                	li	a7,13
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3f4:	48b9                	li	a7,14
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3fc:	48d9                	li	a7,22
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 404:	48dd                	li	a7,23
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 40c:	48e1                	li	a7,24
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 414:	48e5                	li	a7,25
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <getps>:
.global getps
getps:
 li a7, SYS_getps
 41c:	48e9                	li	a7,26
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 424:	48ed                	li	a7,27
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 42c:	1101                	addi	sp,sp,-32
 42e:	ec06                	sd	ra,24(sp)
 430:	e822                	sd	s0,16(sp)
 432:	1000                	addi	s0,sp,32
 434:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 438:	4605                	li	a2,1
 43a:	fef40593          	addi	a1,s0,-17
 43e:	00000097          	auipc	ra,0x0
 442:	f3e080e7          	jalr	-194(ra) # 37c <write>
}
 446:	60e2                	ld	ra,24(sp)
 448:	6442                	ld	s0,16(sp)
 44a:	6105                	addi	sp,sp,32
 44c:	8082                	ret

000000000000044e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 44e:	7139                	addi	sp,sp,-64
 450:	fc06                	sd	ra,56(sp)
 452:	f822                	sd	s0,48(sp)
 454:	f426                	sd	s1,40(sp)
 456:	f04a                	sd	s2,32(sp)
 458:	ec4e                	sd	s3,24(sp)
 45a:	0080                	addi	s0,sp,64
 45c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 45e:	c299                	beqz	a3,464 <printint+0x16>
 460:	0805c963          	bltz	a1,4f2 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 464:	2581                	sext.w	a1,a1
  neg = 0;
 466:	4881                	li	a7,0
 468:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 46c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 46e:	2601                	sext.w	a2,a2
 470:	00000517          	auipc	a0,0x0
 474:	4c050513          	addi	a0,a0,1216 # 930 <digits>
 478:	883a                	mv	a6,a4
 47a:	2705                	addiw	a4,a4,1
 47c:	02c5f7bb          	remuw	a5,a1,a2
 480:	1782                	slli	a5,a5,0x20
 482:	9381                	srli	a5,a5,0x20
 484:	97aa                	add	a5,a5,a0
 486:	0007c783          	lbu	a5,0(a5)
 48a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 48e:	0005879b          	sext.w	a5,a1
 492:	02c5d5bb          	divuw	a1,a1,a2
 496:	0685                	addi	a3,a3,1
 498:	fec7f0e3          	bgeu	a5,a2,478 <printint+0x2a>
  if(neg)
 49c:	00088c63          	beqz	a7,4b4 <printint+0x66>
    buf[i++] = '-';
 4a0:	fd070793          	addi	a5,a4,-48
 4a4:	00878733          	add	a4,a5,s0
 4a8:	02d00793          	li	a5,45
 4ac:	fef70823          	sb	a5,-16(a4)
 4b0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4b4:	02e05863          	blez	a4,4e4 <printint+0x96>
 4b8:	fc040793          	addi	a5,s0,-64
 4bc:	00e78933          	add	s2,a5,a4
 4c0:	fff78993          	addi	s3,a5,-1
 4c4:	99ba                	add	s3,s3,a4
 4c6:	377d                	addiw	a4,a4,-1
 4c8:	1702                	slli	a4,a4,0x20
 4ca:	9301                	srli	a4,a4,0x20
 4cc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4d0:	fff94583          	lbu	a1,-1(s2)
 4d4:	8526                	mv	a0,s1
 4d6:	00000097          	auipc	ra,0x0
 4da:	f56080e7          	jalr	-170(ra) # 42c <putc>
  while(--i >= 0)
 4de:	197d                	addi	s2,s2,-1
 4e0:	ff3918e3          	bne	s2,s3,4d0 <printint+0x82>
}
 4e4:	70e2                	ld	ra,56(sp)
 4e6:	7442                	ld	s0,48(sp)
 4e8:	74a2                	ld	s1,40(sp)
 4ea:	7902                	ld	s2,32(sp)
 4ec:	69e2                	ld	s3,24(sp)
 4ee:	6121                	addi	sp,sp,64
 4f0:	8082                	ret
    x = -xx;
 4f2:	40b005bb          	negw	a1,a1
    neg = 1;
 4f6:	4885                	li	a7,1
    x = -xx;
 4f8:	bf85                	j	468 <printint+0x1a>

00000000000004fa <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4fa:	7119                	addi	sp,sp,-128
 4fc:	fc86                	sd	ra,120(sp)
 4fe:	f8a2                	sd	s0,112(sp)
 500:	f4a6                	sd	s1,104(sp)
 502:	f0ca                	sd	s2,96(sp)
 504:	ecce                	sd	s3,88(sp)
 506:	e8d2                	sd	s4,80(sp)
 508:	e4d6                	sd	s5,72(sp)
 50a:	e0da                	sd	s6,64(sp)
 50c:	fc5e                	sd	s7,56(sp)
 50e:	f862                	sd	s8,48(sp)
 510:	f466                	sd	s9,40(sp)
 512:	f06a                	sd	s10,32(sp)
 514:	ec6e                	sd	s11,24(sp)
 516:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 518:	0005c903          	lbu	s2,0(a1)
 51c:	18090f63          	beqz	s2,6ba <vprintf+0x1c0>
 520:	8aaa                	mv	s5,a0
 522:	8b32                	mv	s6,a2
 524:	00158493          	addi	s1,a1,1
  state = 0;
 528:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 52a:	02500a13          	li	s4,37
 52e:	4c55                	li	s8,21
 530:	00000c97          	auipc	s9,0x0
 534:	3a8c8c93          	addi	s9,s9,936 # 8d8 <malloc+0x11a>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 538:	02800d93          	li	s11,40
  putc(fd, 'x');
 53c:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 53e:	00000b97          	auipc	s7,0x0
 542:	3f2b8b93          	addi	s7,s7,1010 # 930 <digits>
 546:	a839                	j	564 <vprintf+0x6a>
        putc(fd, c);
 548:	85ca                	mv	a1,s2
 54a:	8556                	mv	a0,s5
 54c:	00000097          	auipc	ra,0x0
 550:	ee0080e7          	jalr	-288(ra) # 42c <putc>
 554:	a019                	j	55a <vprintf+0x60>
    } else if(state == '%'){
 556:	01498d63          	beq	s3,s4,570 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 55a:	0485                	addi	s1,s1,1
 55c:	fff4c903          	lbu	s2,-1(s1)
 560:	14090d63          	beqz	s2,6ba <vprintf+0x1c0>
    if(state == 0){
 564:	fe0999e3          	bnez	s3,556 <vprintf+0x5c>
      if(c == '%'){
 568:	ff4910e3          	bne	s2,s4,548 <vprintf+0x4e>
        state = '%';
 56c:	89d2                	mv	s3,s4
 56e:	b7f5                	j	55a <vprintf+0x60>
      if(c == 'd'){
 570:	11490c63          	beq	s2,s4,688 <vprintf+0x18e>
 574:	f9d9079b          	addiw	a5,s2,-99
 578:	0ff7f793          	zext.b	a5,a5
 57c:	10fc6e63          	bltu	s8,a5,698 <vprintf+0x19e>
 580:	f9d9079b          	addiw	a5,s2,-99
 584:	0ff7f713          	zext.b	a4,a5
 588:	10ec6863          	bltu	s8,a4,698 <vprintf+0x19e>
 58c:	00271793          	slli	a5,a4,0x2
 590:	97e6                	add	a5,a5,s9
 592:	439c                	lw	a5,0(a5)
 594:	97e6                	add	a5,a5,s9
 596:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 598:	008b0913          	addi	s2,s6,8
 59c:	4685                	li	a3,1
 59e:	4629                	li	a2,10
 5a0:	000b2583          	lw	a1,0(s6)
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	ea8080e7          	jalr	-344(ra) # 44e <printint>
 5ae:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 5b0:	4981                	li	s3,0
 5b2:	b765                	j	55a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5b4:	008b0913          	addi	s2,s6,8
 5b8:	4681                	li	a3,0
 5ba:	4629                	li	a2,10
 5bc:	000b2583          	lw	a1,0(s6)
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	e8c080e7          	jalr	-372(ra) # 44e <printint>
 5ca:	8b4a                	mv	s6,s2
      state = 0;
 5cc:	4981                	li	s3,0
 5ce:	b771                	j	55a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5d0:	008b0913          	addi	s2,s6,8
 5d4:	4681                	li	a3,0
 5d6:	866a                	mv	a2,s10
 5d8:	000b2583          	lw	a1,0(s6)
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	e70080e7          	jalr	-400(ra) # 44e <printint>
 5e6:	8b4a                	mv	s6,s2
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	bf85                	j	55a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5ec:	008b0793          	addi	a5,s6,8
 5f0:	f8f43423          	sd	a5,-120(s0)
 5f4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5f8:	03000593          	li	a1,48
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	e2e080e7          	jalr	-466(ra) # 42c <putc>
  putc(fd, 'x');
 606:	07800593          	li	a1,120
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	e20080e7          	jalr	-480(ra) # 42c <putc>
 614:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 616:	03c9d793          	srli	a5,s3,0x3c
 61a:	97de                	add	a5,a5,s7
 61c:	0007c583          	lbu	a1,0(a5)
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	e0a080e7          	jalr	-502(ra) # 42c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 62a:	0992                	slli	s3,s3,0x4
 62c:	397d                	addiw	s2,s2,-1
 62e:	fe0914e3          	bnez	s2,616 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 632:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 636:	4981                	li	s3,0
 638:	b70d                	j	55a <vprintf+0x60>
        s = va_arg(ap, char*);
 63a:	008b0913          	addi	s2,s6,8
 63e:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 642:	02098163          	beqz	s3,664 <vprintf+0x16a>
        while(*s != 0){
 646:	0009c583          	lbu	a1,0(s3)
 64a:	c5ad                	beqz	a1,6b4 <vprintf+0x1ba>
          putc(fd, *s);
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	dde080e7          	jalr	-546(ra) # 42c <putc>
          s++;
 656:	0985                	addi	s3,s3,1
        while(*s != 0){
 658:	0009c583          	lbu	a1,0(s3)
 65c:	f9e5                	bnez	a1,64c <vprintf+0x152>
        s = va_arg(ap, char*);
 65e:	8b4a                	mv	s6,s2
      state = 0;
 660:	4981                	li	s3,0
 662:	bde5                	j	55a <vprintf+0x60>
          s = "(null)";
 664:	00000997          	auipc	s3,0x0
 668:	26c98993          	addi	s3,s3,620 # 8d0 <malloc+0x112>
        while(*s != 0){
 66c:	85ee                	mv	a1,s11
 66e:	bff9                	j	64c <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 670:	008b0913          	addi	s2,s6,8
 674:	000b4583          	lbu	a1,0(s6)
 678:	8556                	mv	a0,s5
 67a:	00000097          	auipc	ra,0x0
 67e:	db2080e7          	jalr	-590(ra) # 42c <putc>
 682:	8b4a                	mv	s6,s2
      state = 0;
 684:	4981                	li	s3,0
 686:	bdd1                	j	55a <vprintf+0x60>
        putc(fd, c);
 688:	85d2                	mv	a1,s4
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	da0080e7          	jalr	-608(ra) # 42c <putc>
      state = 0;
 694:	4981                	li	s3,0
 696:	b5d1                	j	55a <vprintf+0x60>
        putc(fd, '%');
 698:	85d2                	mv	a1,s4
 69a:	8556                	mv	a0,s5
 69c:	00000097          	auipc	ra,0x0
 6a0:	d90080e7          	jalr	-624(ra) # 42c <putc>
        putc(fd, c);
 6a4:	85ca                	mv	a1,s2
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	d84080e7          	jalr	-636(ra) # 42c <putc>
      state = 0;
 6b0:	4981                	li	s3,0
 6b2:	b565                	j	55a <vprintf+0x60>
        s = va_arg(ap, char*);
 6b4:	8b4a                	mv	s6,s2
      state = 0;
 6b6:	4981                	li	s3,0
 6b8:	b54d                	j	55a <vprintf+0x60>
    }
  }
}
 6ba:	70e6                	ld	ra,120(sp)
 6bc:	7446                	ld	s0,112(sp)
 6be:	74a6                	ld	s1,104(sp)
 6c0:	7906                	ld	s2,96(sp)
 6c2:	69e6                	ld	s3,88(sp)
 6c4:	6a46                	ld	s4,80(sp)
 6c6:	6aa6                	ld	s5,72(sp)
 6c8:	6b06                	ld	s6,64(sp)
 6ca:	7be2                	ld	s7,56(sp)
 6cc:	7c42                	ld	s8,48(sp)
 6ce:	7ca2                	ld	s9,40(sp)
 6d0:	7d02                	ld	s10,32(sp)
 6d2:	6de2                	ld	s11,24(sp)
 6d4:	6109                	addi	sp,sp,128
 6d6:	8082                	ret

00000000000006d8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6d8:	715d                	addi	sp,sp,-80
 6da:	ec06                	sd	ra,24(sp)
 6dc:	e822                	sd	s0,16(sp)
 6de:	1000                	addi	s0,sp,32
 6e0:	e010                	sd	a2,0(s0)
 6e2:	e414                	sd	a3,8(s0)
 6e4:	e818                	sd	a4,16(s0)
 6e6:	ec1c                	sd	a5,24(s0)
 6e8:	03043023          	sd	a6,32(s0)
 6ec:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6f0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6f4:	8622                	mv	a2,s0
 6f6:	00000097          	auipc	ra,0x0
 6fa:	e04080e7          	jalr	-508(ra) # 4fa <vprintf>
}
 6fe:	60e2                	ld	ra,24(sp)
 700:	6442                	ld	s0,16(sp)
 702:	6161                	addi	sp,sp,80
 704:	8082                	ret

0000000000000706 <printf>:

void
printf(const char *fmt, ...)
{
 706:	711d                	addi	sp,sp,-96
 708:	ec06                	sd	ra,24(sp)
 70a:	e822                	sd	s0,16(sp)
 70c:	1000                	addi	s0,sp,32
 70e:	e40c                	sd	a1,8(s0)
 710:	e810                	sd	a2,16(s0)
 712:	ec14                	sd	a3,24(s0)
 714:	f018                	sd	a4,32(s0)
 716:	f41c                	sd	a5,40(s0)
 718:	03043823          	sd	a6,48(s0)
 71c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 720:	00840613          	addi	a2,s0,8
 724:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 728:	85aa                	mv	a1,a0
 72a:	4505                	li	a0,1
 72c:	00000097          	auipc	ra,0x0
 730:	dce080e7          	jalr	-562(ra) # 4fa <vprintf>
}
 734:	60e2                	ld	ra,24(sp)
 736:	6442                	ld	s0,16(sp)
 738:	6125                	addi	sp,sp,96
 73a:	8082                	ret

000000000000073c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 73c:	1141                	addi	sp,sp,-16
 73e:	e422                	sd	s0,8(sp)
 740:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 742:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 746:	00001797          	auipc	a5,0x1
 74a:	8ba7b783          	ld	a5,-1862(a5) # 1000 <freep>
 74e:	a02d                	j	778 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 750:	4618                	lw	a4,8(a2)
 752:	9f2d                	addw	a4,a4,a1
 754:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 758:	6398                	ld	a4,0(a5)
 75a:	6310                	ld	a2,0(a4)
 75c:	a83d                	j	79a <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 75e:	ff852703          	lw	a4,-8(a0)
 762:	9f31                	addw	a4,a4,a2
 764:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 766:	ff053683          	ld	a3,-16(a0)
 76a:	a091                	j	7ae <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 76c:	6398                	ld	a4,0(a5)
 76e:	00e7e463          	bltu	a5,a4,776 <free+0x3a>
 772:	00e6ea63          	bltu	a3,a4,786 <free+0x4a>
{
 776:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 778:	fed7fae3          	bgeu	a5,a3,76c <free+0x30>
 77c:	6398                	ld	a4,0(a5)
 77e:	00e6e463          	bltu	a3,a4,786 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 782:	fee7eae3          	bltu	a5,a4,776 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 786:	ff852583          	lw	a1,-8(a0)
 78a:	6390                	ld	a2,0(a5)
 78c:	02059813          	slli	a6,a1,0x20
 790:	01c85713          	srli	a4,a6,0x1c
 794:	9736                	add	a4,a4,a3
 796:	fae60de3          	beq	a2,a4,750 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 79a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 79e:	4790                	lw	a2,8(a5)
 7a0:	02061593          	slli	a1,a2,0x20
 7a4:	01c5d713          	srli	a4,a1,0x1c
 7a8:	973e                	add	a4,a4,a5
 7aa:	fae68ae3          	beq	a3,a4,75e <free+0x22>
    p->s.ptr = bp->s.ptr;
 7ae:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7b0:	00001717          	auipc	a4,0x1
 7b4:	84f73823          	sd	a5,-1968(a4) # 1000 <freep>
}
 7b8:	6422                	ld	s0,8(sp)
 7ba:	0141                	addi	sp,sp,16
 7bc:	8082                	ret

00000000000007be <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7be:	7139                	addi	sp,sp,-64
 7c0:	fc06                	sd	ra,56(sp)
 7c2:	f822                	sd	s0,48(sp)
 7c4:	f426                	sd	s1,40(sp)
 7c6:	f04a                	sd	s2,32(sp)
 7c8:	ec4e                	sd	s3,24(sp)
 7ca:	e852                	sd	s4,16(sp)
 7cc:	e456                	sd	s5,8(sp)
 7ce:	e05a                	sd	s6,0(sp)
 7d0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7d2:	02051493          	slli	s1,a0,0x20
 7d6:	9081                	srli	s1,s1,0x20
 7d8:	04bd                	addi	s1,s1,15
 7da:	8091                	srli	s1,s1,0x4
 7dc:	0014899b          	addiw	s3,s1,1
 7e0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7e2:	00001517          	auipc	a0,0x1
 7e6:	81e53503          	ld	a0,-2018(a0) # 1000 <freep>
 7ea:	c515                	beqz	a0,816 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ec:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ee:	4798                	lw	a4,8(a5)
 7f0:	02977f63          	bgeu	a4,s1,82e <malloc+0x70>
 7f4:	8a4e                	mv	s4,s3
 7f6:	0009871b          	sext.w	a4,s3
 7fa:	6685                	lui	a3,0x1
 7fc:	00d77363          	bgeu	a4,a3,802 <malloc+0x44>
 800:	6a05                	lui	s4,0x1
 802:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 806:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 80a:	00000917          	auipc	s2,0x0
 80e:	7f690913          	addi	s2,s2,2038 # 1000 <freep>
  if(p == (char*)-1)
 812:	5afd                	li	s5,-1
 814:	a895                	j	888 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 816:	00000797          	auipc	a5,0x0
 81a:	7fa78793          	addi	a5,a5,2042 # 1010 <base>
 81e:	00000717          	auipc	a4,0x0
 822:	7ef73123          	sd	a5,2018(a4) # 1000 <freep>
 826:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 828:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 82c:	b7e1                	j	7f4 <malloc+0x36>
      if(p->s.size == nunits)
 82e:	02e48c63          	beq	s1,a4,866 <malloc+0xa8>
        p->s.size -= nunits;
 832:	4137073b          	subw	a4,a4,s3
 836:	c798                	sw	a4,8(a5)
        p += p->s.size;
 838:	02071693          	slli	a3,a4,0x20
 83c:	01c6d713          	srli	a4,a3,0x1c
 840:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 842:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 846:	00000717          	auipc	a4,0x0
 84a:	7aa73d23          	sd	a0,1978(a4) # 1000 <freep>
      return (void*)(p + 1);
 84e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 852:	70e2                	ld	ra,56(sp)
 854:	7442                	ld	s0,48(sp)
 856:	74a2                	ld	s1,40(sp)
 858:	7902                	ld	s2,32(sp)
 85a:	69e2                	ld	s3,24(sp)
 85c:	6a42                	ld	s4,16(sp)
 85e:	6aa2                	ld	s5,8(sp)
 860:	6b02                	ld	s6,0(sp)
 862:	6121                	addi	sp,sp,64
 864:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 866:	6398                	ld	a4,0(a5)
 868:	e118                	sd	a4,0(a0)
 86a:	bff1                	j	846 <malloc+0x88>
  hp->s.size = nu;
 86c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 870:	0541                	addi	a0,a0,16
 872:	00000097          	auipc	ra,0x0
 876:	eca080e7          	jalr	-310(ra) # 73c <free>
  return freep;
 87a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 87e:	d971                	beqz	a0,852 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 880:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 882:	4798                	lw	a4,8(a5)
 884:	fa9775e3          	bgeu	a4,s1,82e <malloc+0x70>
    if(p == freep)
 888:	00093703          	ld	a4,0(s2)
 88c:	853e                	mv	a0,a5
 88e:	fef719e3          	bne	a4,a5,880 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 892:	8552                	mv	a0,s4
 894:	00000097          	auipc	ra,0x0
 898:	b50080e7          	jalr	-1200(ra) # 3e4 <sbrk>
  if(p == (char*)-1)
 89c:	fd5518e3          	bne	a0,s5,86c <malloc+0xae>
        return 0;
 8a0:	4501                	li	a0,0
 8a2:	bf45                	j	852 <malloc+0x94>
