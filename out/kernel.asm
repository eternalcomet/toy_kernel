
out/kernel.elf:     file format elf64-x86-64


Disassembly of section .text:

ffffffff80100000 <begin>:
ffffffff80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%rax),%dh
ffffffff80100006:	01 00                	add    %eax,(%rax)
ffffffff80100008:	fe 4f 51             	decb   0x51(%rdi)
ffffffff8010000b:	e4 00                	in     $0x0,%al
ffffffff8010000d:	00 10                	add    %dl,(%rax)
ffffffff8010000f:	00 00                	add    %al,(%rax)
ffffffff80100011:	00 10                	add    %dl,(%rax)
ffffffff80100013:	00 00                	add    %al,(%rax)
ffffffff80100015:	30 10                	xor    %dl,(%rax)
ffffffff80100017:	00 00                	add    %al,(%rax)
ffffffff80100019:	40 10 00             	rex adc %al,(%rax)
ffffffff8010001c:	20 00                	and    %al,(%rax)
ffffffff8010001e:	10 00                	adc    %al,(%rax)

ffffffff80100020 <mboot_entry>:
  .long mboot_entry_addr

mboot_entry:

# zero 4 pages for our bootstrap page tables
  xor %eax, %eax
ffffffff80100020:	31 c0                	xor    %eax,%eax
  mov $0x1000, %edi
ffffffff80100022:	bf 00 10 00 00       	mov    $0x1000,%edi
  mov $0x5000, %ecx
ffffffff80100027:	b9 00 50 00 00       	mov    $0x5000,%ecx
  rep stosb
ffffffff8010002c:	f3 aa                	rep stos %al,%es:(%rdi)

# P4ML[0] -> 0x2000 (PDPT-A)
  mov $(0x2000 | 3), %eax
ffffffff8010002e:	b8 03 20 00 00       	mov    $0x2003,%eax
  mov %eax, 0x1000
ffffffff80100033:	a3 00 10 00 00 b8 03 	movabs %eax,0x3003b800001000
ffffffff8010003a:	30 00 

# P4ML[511] -> 0x3000 (PDPT-B)
  mov $(0x3000 | 3), %eax
ffffffff8010003c:	00 a3 f8 1f 00 00    	add    %ah,0x1ff8(%rbx)
  mov %eax, 0x1FF8

# PDPT-A[0] -> 0x4000 (PD)
  mov $(0x4000 | 3), %eax
ffffffff80100042:	b8 03 40 00 00       	mov    $0x4003,%eax
  mov %eax, 0x2000
ffffffff80100047:	a3 00 20 00 00 b8 03 	movabs %eax,0x4003b800002000
ffffffff8010004e:	40 00 

# PDPT-B[510] -> 0x4000 (PD)
  mov $(0x4000 | 3), %eax
ffffffff80100050:	00 a3 f0 3f 00 00    	add    %ah,0x3ff0(%rbx)
  mov %eax, 0x3FF0

# PD[0..511] -> 0..1022MB
  mov $0x83, %eax
ffffffff80100056:	b8 83 00 00 00       	mov    $0x83,%eax
  mov $0x4000, %ebx
ffffffff8010005b:	bb 00 40 00 00       	mov    $0x4000,%ebx
  mov $512, %ecx
ffffffff80100060:	b9 00 02 00 00       	mov    $0x200,%ecx

ffffffff80100065 <ptbl_loop>:
ptbl_loop:
  mov %eax, (%ebx)
ffffffff80100065:	89 03                	mov    %eax,(%rbx)
  add $0x200000, %eax
ffffffff80100067:	05 00 00 20 00       	add    $0x200000,%eax
  add $0x8, %ebx
ffffffff8010006c:	83 c3 08             	add    $0x8,%ebx
  dec %ecx
ffffffff8010006f:	49 75 f3             	rex.WB jne ffffffff80100065 <ptbl_loop>

# Clear ebx for initial processor boot.
# When secondary processors boot, they'll call through
# entry32mp (from entryother), but with a nonzero ebx.
# We'll reuse these bootstrap pagetables and GDT.
  xor %ebx, %ebx
ffffffff80100072:	31 db                	xor    %ebx,%ebx

ffffffff80100074 <entry32mp>:

.global entry32mp
entry32mp:
# CR3 -> 0x1000 (P4ML)
  mov $0x1000, %eax
ffffffff80100074:	b8 00 10 00 00       	mov    $0x1000,%eax
  mov %eax, %cr3
ffffffff80100079:	0f 22 d8             	mov    %rax,%cr3

  lgdt (gdtr64 - mboot_header + mboot_load_addr)
ffffffff8010007c:	0f 01 15 b0 00 10 00 	lgdt   0x1000b0(%rip)        # ffffffff80200133 <end+0xfc133>

# Enable PAE - CR4.PAE=1
  mov %cr4, %eax
ffffffff80100083:	0f 20 e0             	mov    %cr4,%rax
  bts $5, %eax
ffffffff80100086:	0f ba e8 05          	bts    $0x5,%eax
  mov %eax, %cr4
ffffffff8010008a:	0f 22 e0             	mov    %rax,%cr4

# enable long mode - EFER.LME=1
  mov $0xc0000080, %ecx
ffffffff8010008d:	b9 80 00 00 c0       	mov    $0xc0000080,%ecx
  rdmsr
ffffffff80100092:	0f 32                	rdmsr  
  bts $8, %eax
ffffffff80100094:	0f ba e8 08          	bts    $0x8,%eax
  wrmsr
ffffffff80100098:	0f 30                	wrmsr  

# enable paging
  mov %cr0, %eax
ffffffff8010009a:	0f 20 c0             	mov    %cr0,%rax
  bts $31, %eax
ffffffff8010009d:	0f ba e8 1f          	bts    $0x1f,%eax
  mov %eax, %cr0
ffffffff801000a1:	0f 22 c0             	mov    %rax,%cr0

# shift to 64bit segment
  ljmp $8,$(entry64low - mboot_header + mboot_load_addr)
ffffffff801000a4:	ea                   	(bad)  
ffffffff801000a5:	e0 00                	loopne ffffffff801000a7 <entry32mp+0x33>
ffffffff801000a7:	10 00                	adc    %al,(%rax)
ffffffff801000a9:	08 00                	or     %al,(%rax)
ffffffff801000ab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffffffff801000b0 <gdtr64>:
ffffffff801000b0:	17                   	(bad)  
ffffffff801000b1:	00 c0                	add    %al,%al
ffffffff801000b3:	00 10                	add    %dl,(%rax)
ffffffff801000b5:	00 00                	add    %al,(%rax)
ffffffff801000b7:	00 00                	add    %al,(%rax)
ffffffff801000b9:	00 66 0f             	add    %ah,0xf(%rsi)
ffffffff801000bc:	1f                   	(bad)  
ffffffff801000bd:	44 00 00             	add    %r8b,(%rax)

ffffffff801000c0 <gdt64_begin>:
	...
ffffffff801000cc:	00 98 20 00 00 00    	add    %bl,0x20(%rax)
ffffffff801000d2:	00 00                	add    %al,(%rax)
ffffffff801000d4:	00                   	.byte 0x0
ffffffff801000d5:	90                   	nop
	...

ffffffff801000d8 <gdt64_end>:
ffffffff801000d8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffffffff801000df:	00 

ffffffff801000e0 <entry64low>:
gdt64_end:

.align 16
.code64
entry64low:
  movq $entry64high, %rax
ffffffff801000e0:	48 c7 c0 e9 00 10 80 	mov    $0xffffffff801000e9,%rax
  jmp *%rax
ffffffff801000e7:	ff e0                	jmp    *%rax

ffffffff801000e9 <_start>:
.global _start
_start:
entry64high:

# ensure data segment registers are sane
  xor %rax, %rax
ffffffff801000e9:	48 31 c0             	xor    %rax,%rax
  mov %ax, %ss
ffffffff801000ec:	8e d0                	mov    %eax,%ss
  mov %ax, %ds
ffffffff801000ee:	8e d8                	mov    %eax,%ds
  mov %ax, %es
ffffffff801000f0:	8e c0                	mov    %eax,%es
  mov %ax, %fs
ffffffff801000f2:	8e e0                	mov    %eax,%fs
  mov %ax, %gs
ffffffff801000f4:	8e e8                	mov    %eax,%gs

# check to see if we're booting a secondary core
  test %ebx, %ebx
ffffffff801000f6:	85 db                	test   %ebx,%ebx
  jnz entry64mp
ffffffff801000f8:	75 11                	jne    ffffffff8010010b <entry64mp>

# setup initial stack
  mov $0xFFFFFFFF80010000, %rax
ffffffff801000fa:	48 c7 c0 00 00 01 80 	mov    $0xffffffff80010000,%rax
  mov %rax, %rsp
ffffffff80100101:	48 89 c4             	mov    %rax,%rsp

# enter main()
  jmp main
ffffffff80100104:	e9 b1 07 00 00       	jmp    ffffffff801008ba <main>

ffffffff80100109 <__deadloop>:

.global __deadloop
__deadloop:
# we should never return here...
  jmp .
ffffffff80100109:	eb fe                	jmp    ffffffff80100109 <__deadloop>

ffffffff8010010b <entry64mp>:

entry64mp:
# obtain kstack from data block before entryother
  mov $0x7000, %rax
ffffffff8010010b:	48 c7 c0 00 70 00 00 	mov    $0x7000,%rax
  mov -16(%rax), %rsp
ffffffff80100112:	48 8b 60 f0          	mov    -0x10(%rax),%rsp

ffffffff80100116 <wrmsr>:

.global wrmsr
wrmsr:
  mov %rdi, %rcx     # arg0 -> msrnum
ffffffff80100116:	48 89 f9             	mov    %rdi,%rcx
  mov %rsi, %rax     # val.low -> eax
ffffffff80100119:	48 89 f0             	mov    %rsi,%rax
  shr $32, %rsi
ffffffff8010011c:	48 c1 ee 20          	shr    $0x20,%rsi
  mov %rsi, %rdx     # val.high -> edx
ffffffff80100120:	48 89 f2             	mov    %rsi,%rdx
  wrmsr
ffffffff80100123:	0f 30                	wrmsr  
  retq
ffffffff80100125:	c3                   	ret    

ffffffff80100126 <inb>:
// Routines to let C code use special x86 instructions.

static inline u8
inb(u16 port)
{
ffffffff80100126:	55                   	push   %rbp
ffffffff80100127:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010012a:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff8010012e:	89 f8                	mov    %edi,%eax
ffffffff80100130:	66 89 45 ec          	mov    %ax,-0x14(%rbp)
  u8 data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
ffffffff80100134:	0f b7 45 ec          	movzwl -0x14(%rbp),%eax
ffffffff80100138:	89 c2                	mov    %eax,%edx
ffffffff8010013a:	ec                   	in     (%dx),%al
ffffffff8010013b:	88 45 ff             	mov    %al,-0x1(%rbp)
  return data;
ffffffff8010013e:	0f b6 45 ff          	movzbl -0x1(%rbp),%eax
}
ffffffff80100142:	c9                   	leave  
ffffffff80100143:	c3                   	ret    

ffffffff80100144 <outb>:
               "memory", "cc");
}

static inline void
outb(u16 port, u8 data)
{
ffffffff80100144:	55                   	push   %rbp
ffffffff80100145:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100148:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010014c:	89 f8                	mov    %edi,%eax
ffffffff8010014e:	89 f2                	mov    %esi,%edx
ffffffff80100150:	66 89 45 fc          	mov    %ax,-0x4(%rbp)
ffffffff80100154:	89 d0                	mov    %edx,%eax
ffffffff80100156:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff80100159:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff8010015d:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff80100161:	ee                   	out    %al,(%dx)
}
ffffffff80100162:	90                   	nop
ffffffff80100163:	c9                   	leave  
ffffffff80100164:	c3                   	ret    

ffffffff80100165 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
ffffffff80100165:	55                   	push   %rbp
ffffffff80100166:	48 89 e5             	mov    %rsp,%rbp
  asm volatile("cli");
ffffffff80100169:	fa                   	cli    
}
ffffffff8010016a:	90                   	nop
ffffffff8010016b:	5d                   	pop    %rbp
ffffffff8010016c:	c3                   	ret    

ffffffff8010016d <printptr>:
} cons;*/

static char digits[] = "0123456789abcdef";

static void
printptr(uintp x) {
ffffffff8010016d:	f3 0f 1e fa          	endbr64 
ffffffff80100171:	55                   	push   %rbp
ffffffff80100172:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100175:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80100179:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int i;
  for (i = 0; i < (sizeof(uintp) * 2); i++, x <<= 4)
ffffffff8010017d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80100184:	eb 22                	jmp    ffffffff801001a8 <printptr+0x3b>
    consputc(digits[x >> (sizeof(uintp) * 8 - 4)]);
ffffffff80100186:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010018a:	48 c1 e8 3c          	shr    $0x3c,%rax
ffffffff8010018e:	0f b6 80 00 20 10 80 	movzbl -0x7fefe000(%rax),%eax
ffffffff80100195:	0f be c0             	movsbl %al,%eax
ffffffff80100198:	89 c7                	mov    %eax,%edi
ffffffff8010019a:	e8 ff 06 00 00       	call   ffffffff8010089e <consputc>
  for (i = 0; i < (sizeof(uintp) * 2); i++, x <<= 4)
ffffffff8010019f:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801001a3:	48 c1 65 e8 04       	shlq   $0x4,-0x18(%rbp)
ffffffff801001a8:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801001ab:	83 f8 0f             	cmp    $0xf,%eax
ffffffff801001ae:	76 d6                	jbe    ffffffff80100186 <printptr+0x19>
}
ffffffff801001b0:	90                   	nop
ffffffff801001b1:	90                   	nop
ffffffff801001b2:	c9                   	leave  
ffffffff801001b3:	c3                   	ret    

ffffffff801001b4 <printint>:

static void
printint(int xx, int base, int sign)
{
ffffffff801001b4:	f3 0f 1e fa          	endbr64 
ffffffff801001b8:	55                   	push   %rbp
ffffffff801001b9:	48 89 e5             	mov    %rsp,%rbp
ffffffff801001bc:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff801001c0:	89 7d dc             	mov    %edi,-0x24(%rbp)
ffffffff801001c3:	89 75 d8             	mov    %esi,-0x28(%rbp)
ffffffff801001c6:	89 55 d4             	mov    %edx,-0x2c(%rbp)
  char buf[16];
  int i;
  u32 x;

  if(sign && (sign = xx < 0))
ffffffff801001c9:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff801001cd:	74 1c                	je     ffffffff801001eb <printint+0x37>
ffffffff801001cf:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff801001d2:	c1 e8 1f             	shr    $0x1f,%eax
ffffffff801001d5:	0f b6 c0             	movzbl %al,%eax
ffffffff801001d8:	89 45 d4             	mov    %eax,-0x2c(%rbp)
ffffffff801001db:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff801001df:	74 0a                	je     ffffffff801001eb <printint+0x37>
    x = -xx;
ffffffff801001e1:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff801001e4:	f7 d8                	neg    %eax
ffffffff801001e6:	89 45 f8             	mov    %eax,-0x8(%rbp)
ffffffff801001e9:	eb 06                	jmp    ffffffff801001f1 <printint+0x3d>
  else
    x = xx;
ffffffff801001eb:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff801001ee:	89 45 f8             	mov    %eax,-0x8(%rbp)

  i = 0;
ffffffff801001f1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  do{
    buf[i++] = digits[x % base];
ffffffff801001f8:	8b 4d d8             	mov    -0x28(%rbp),%ecx
ffffffff801001fb:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801001fe:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80100203:	f7 f1                	div    %ecx
ffffffff80100205:	89 d1                	mov    %edx,%ecx
ffffffff80100207:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010020a:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff8010020d:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff80100210:	89 ca                	mov    %ecx,%edx
ffffffff80100212:	0f b6 92 00 20 10 80 	movzbl -0x7fefe000(%rdx),%edx
ffffffff80100219:	48 98                	cltq   
ffffffff8010021b:	88 54 05 e0          	mov    %dl,-0x20(%rbp,%rax,1)
  }while((x /= base) != 0);
ffffffff8010021f:	8b 75 d8             	mov    -0x28(%rbp),%esi
ffffffff80100222:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80100225:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010022a:	f7 f6                	div    %esi
ffffffff8010022c:	89 45 f8             	mov    %eax,-0x8(%rbp)
ffffffff8010022f:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff80100233:	75 c3                	jne    ffffffff801001f8 <printint+0x44>

  if(sign)
ffffffff80100235:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff80100239:	74 26                	je     ffffffff80100261 <printint+0xad>
    buf[i++] = '-';
ffffffff8010023b:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010023e:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80100241:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff80100244:	48 98                	cltq   
ffffffff80100246:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%rbp,%rax,1)

  while(--i >= 0)
ffffffff8010024b:	eb 14                	jmp    ffffffff80100261 <printint+0xad>
    consputc(buf[i]);
ffffffff8010024d:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100250:	48 98                	cltq   
ffffffff80100252:	0f b6 44 05 e0       	movzbl -0x20(%rbp,%rax,1),%eax
ffffffff80100257:	0f be c0             	movsbl %al,%eax
ffffffff8010025a:	89 c7                	mov    %eax,%edi
ffffffff8010025c:	e8 3d 06 00 00       	call   ffffffff8010089e <consputc>
  while(--i >= 0)
ffffffff80100261:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff80100265:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80100269:	79 e2                	jns    ffffffff8010024d <printint+0x99>
}
ffffffff8010026b:	90                   	nop
ffffffff8010026c:	90                   	nop
ffffffff8010026d:	c9                   	leave  
ffffffff8010026e:	c3                   	ret    

ffffffff8010026f <printlong>:
//PAGEBREAK: 50

static void printlong(u64 xx, int base, int sign){
ffffffff8010026f:	f3 0f 1e fa          	endbr64 
ffffffff80100273:	55                   	push   %rbp
ffffffff80100274:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100277:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff8010027b:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff8010027f:	89 75 d4             	mov    %esi,-0x2c(%rbp)
ffffffff80100282:	89 55 d0             	mov    %edx,-0x30(%rbp)
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  u64 x;

  if(sign && (sign = xx < 0))
ffffffff80100285:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
ffffffff80100289:	74 1a                	je     ffffffff801002a5 <printlong+0x36>
ffffffff8010028b:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%rbp)
ffffffff80100292:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
ffffffff80100296:	74 0d                	je     ffffffff801002a5 <printlong+0x36>
    x = -xx;
ffffffff80100298:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010029c:	48 f7 d8             	neg    %rax
ffffffff8010029f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff801002a3:	eb 08                	jmp    ffffffff801002ad <printlong+0x3e>
  else
    x = xx;
ffffffff801002a5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801002a9:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

  i = 0;
ffffffff801002ad:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  do{
    buf[i++] = digits[x % base];
ffffffff801002b4:	8b 45 d4             	mov    -0x2c(%rbp),%eax
ffffffff801002b7:	48 63 c8             	movslq %eax,%rcx
ffffffff801002ba:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801002be:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff801002c3:	48 f7 f1             	div    %rcx
ffffffff801002c6:	48 89 d1             	mov    %rdx,%rcx
ffffffff801002c9:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801002cc:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff801002cf:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff801002d2:	0f b6 91 20 20 10 80 	movzbl -0x7fefdfe0(%rcx),%edx
ffffffff801002d9:	48 98                	cltq   
ffffffff801002db:	88 54 05 e0          	mov    %dl,-0x20(%rbp,%rax,1)
  }while((x /= base) != 0);
ffffffff801002df:	8b 45 d4             	mov    -0x2c(%rbp),%eax
ffffffff801002e2:	48 63 f0             	movslq %eax,%rsi
ffffffff801002e5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801002e9:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff801002ee:	48 f7 f6             	div    %rsi
ffffffff801002f1:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff801002f5:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff801002fa:	75 b8                	jne    ffffffff801002b4 <printlong+0x45>

  if(sign)
ffffffff801002fc:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
ffffffff80100300:	74 26                	je     ffffffff80100328 <printlong+0xb9>
    buf[i++] = '-';
ffffffff80100302:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100305:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80100308:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff8010030b:	48 98                	cltq   
ffffffff8010030d:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%rbp,%rax,1)

  while(--i >= 0)
ffffffff80100312:	eb 14                	jmp    ffffffff80100328 <printlong+0xb9>
    consputc(buf[i]);
ffffffff80100314:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100317:	48 98                	cltq   
ffffffff80100319:	0f b6 44 05 e0       	movzbl -0x20(%rbp,%rax,1),%eax
ffffffff8010031e:	0f be c0             	movsbl %al,%eax
ffffffff80100321:	89 c7                	mov    %eax,%edi
ffffffff80100323:	e8 76 05 00 00       	call   ffffffff8010089e <consputc>
  while(--i >= 0)
ffffffff80100328:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff8010032c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80100330:	79 e2                	jns    ffffffff80100314 <printlong+0xa5>
}
ffffffff80100332:	90                   	nop
ffffffff80100333:	90                   	nop
ffffffff80100334:	c9                   	leave  
ffffffff80100335:	c3                   	ret    

ffffffff80100336 <cprintf>:

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
ffffffff80100336:	f3 0f 1e fa          	endbr64 
ffffffff8010033a:	55                   	push   %rbp
ffffffff8010033b:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010033e:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
ffffffff80100345:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
ffffffff8010034c:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
ffffffff80100353:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
ffffffff8010035a:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
ffffffff80100361:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
ffffffff80100368:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
ffffffff8010036f:	84 c0                	test   %al,%al
ffffffff80100371:	74 20                	je     ffffffff80100393 <cprintf+0x5d>
ffffffff80100373:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
ffffffff80100377:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
ffffffff8010037b:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
ffffffff8010037f:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
ffffffff80100383:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
ffffffff80100387:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
ffffffff8010038b:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
ffffffff8010038f:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  va_list ap;
  int i, c; //locking;
  char *s;

  va_start(ap, fmt);
ffffffff80100393:	c7 85 20 ff ff ff 08 	movl   $0x8,-0xe0(%rbp)
ffffffff8010039a:	00 00 00 
ffffffff8010039d:	c7 85 24 ff ff ff 30 	movl   $0x30,-0xdc(%rbp)
ffffffff801003a4:	00 00 00 
ffffffff801003a7:	48 8d 45 10          	lea    0x10(%rbp),%rax
ffffffff801003ab:	48 89 85 28 ff ff ff 	mov    %rax,-0xd8(%rbp)
ffffffff801003b2:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
ffffffff801003b9:	48 89 85 30 ff ff ff 	mov    %rax,-0xd0(%rbp)

  //locking = cons.locking;
  //if(locking)
  //  acquire(&cons.lock);

  if (fmt == 0)
ffffffff801003c0:	48 83 bd 18 ff ff ff 	cmpq   $0x0,-0xe8(%rbp)
ffffffff801003c7:	00 
ffffffff801003c8:	75 0c                	jne    ffffffff801003d6 <cprintf+0xa0>
    panic("null fmt");
ffffffff801003ca:	48 c7 c7 28 1d 10 80 	mov    $0xffffffff80101d28,%rdi
ffffffff801003d1:	e8 fe 02 00 00       	call   ffffffff801006d4 <panic>

  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
ffffffff801003d6:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%rbp)
ffffffff801003dd:	00 00 00 
ffffffff801003e0:	e9 b8 02 00 00       	jmp    ffffffff8010069d <cprintf+0x367>
    if(c != '%'){
ffffffff801003e5:	83 bd 3c ff ff ff 25 	cmpl   $0x25,-0xc4(%rbp)
ffffffff801003ec:	74 12                	je     ffffffff80100400 <cprintf+0xca>
      consputc(c);
ffffffff801003ee:	8b 85 3c ff ff ff    	mov    -0xc4(%rbp),%eax
ffffffff801003f4:	89 c7                	mov    %eax,%edi
ffffffff801003f6:	e8 a3 04 00 00       	call   ffffffff8010089e <consputc>
      continue;
ffffffff801003fb:	e9 96 02 00 00       	jmp    ffffffff80100696 <cprintf+0x360>
    }
    c = fmt[++i] & 0xff;
ffffffff80100400:	83 85 4c ff ff ff 01 	addl   $0x1,-0xb4(%rbp)
ffffffff80100407:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
ffffffff8010040d:	48 63 d0             	movslq %eax,%rdx
ffffffff80100410:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
ffffffff80100417:	48 01 d0             	add    %rdx,%rax
ffffffff8010041a:	0f b6 00             	movzbl (%rax),%eax
ffffffff8010041d:	0f be c0             	movsbl %al,%eax
ffffffff80100420:	25 ff 00 00 00       	and    $0xff,%eax
ffffffff80100425:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%rbp)
    if(c == 0)
ffffffff8010042b:	83 bd 3c ff ff ff 00 	cmpl   $0x0,-0xc4(%rbp)
ffffffff80100432:	0f 84 98 02 00 00    	je     ffffffff801006d0 <cprintf+0x39a>
      break;
    switch(c){
ffffffff80100438:	83 bd 3c ff ff ff 25 	cmpl   $0x25,-0xc4(%rbp)
ffffffff8010043f:	0f 84 2d 02 00 00    	je     ffffffff80100672 <cprintf+0x33c>
ffffffff80100445:	83 bd 3c ff ff ff 25 	cmpl   $0x25,-0xc4(%rbp)
ffffffff8010044c:	0f 8c 2c 02 00 00    	jl     ffffffff8010067e <cprintf+0x348>
ffffffff80100452:	83 bd 3c ff ff ff 78 	cmpl   $0x78,-0xc4(%rbp)
ffffffff80100459:	0f 8f 1f 02 00 00    	jg     ffffffff8010067e <cprintf+0x348>
ffffffff8010045f:	83 bd 3c ff ff ff 64 	cmpl   $0x64,-0xc4(%rbp)
ffffffff80100466:	0f 8c 12 02 00 00    	jl     ffffffff8010067e <cprintf+0x348>
ffffffff8010046c:	8b 85 3c ff ff ff    	mov    -0xc4(%rbp),%eax
ffffffff80100472:	83 e8 64             	sub    $0x64,%eax
ffffffff80100475:	83 f8 14             	cmp    $0x14,%eax
ffffffff80100478:	0f 87 00 02 00 00    	ja     ffffffff8010067e <cprintf+0x348>
ffffffff8010047e:	89 c0                	mov    %eax,%eax
ffffffff80100480:	48 8b 04 c5 38 1d 10 	mov    -0x7fefe2c8(,%rax,8),%rax
ffffffff80100487:	80 
ffffffff80100488:	3e ff e0             	notrack jmp *%rax
    case 'd':
      printint(va_arg(ap, int), 10, 1);
ffffffff8010048b:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff80100491:	83 f8 2f             	cmp    $0x2f,%eax
ffffffff80100494:	77 23                	ja     ffffffff801004b9 <cprintf+0x183>
ffffffff80100496:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff8010049d:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801004a3:	89 d2                	mov    %edx,%edx
ffffffff801004a5:	48 01 d0             	add    %rdx,%rax
ffffffff801004a8:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801004ae:	83 c2 08             	add    $0x8,%edx
ffffffff801004b1:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff801004b7:	eb 12                	jmp    ffffffff801004cb <cprintf+0x195>
ffffffff801004b9:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff801004c0:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff801004c4:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff801004cb:	8b 00                	mov    (%rax),%eax
ffffffff801004cd:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff801004d2:	be 0a 00 00 00       	mov    $0xa,%esi
ffffffff801004d7:	89 c7                	mov    %eax,%edi
ffffffff801004d9:	e8 d6 fc ff ff       	call   ffffffff801001b4 <printint>
      break;
ffffffff801004de:	e9 b3 01 00 00       	jmp    ffffffff80100696 <cprintf+0x360>
    case 'x':
      printint(va_arg(ap, int), 16, 0);
ffffffff801004e3:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff801004e9:	83 f8 2f             	cmp    $0x2f,%eax
ffffffff801004ec:	77 23                	ja     ffffffff80100511 <cprintf+0x1db>
ffffffff801004ee:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff801004f5:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801004fb:	89 d2                	mov    %edx,%edx
ffffffff801004fd:	48 01 d0             	add    %rdx,%rax
ffffffff80100500:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff80100506:	83 c2 08             	add    $0x8,%edx
ffffffff80100509:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff8010050f:	eb 12                	jmp    ffffffff80100523 <cprintf+0x1ed>
ffffffff80100511:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff80100518:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff8010051c:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff80100523:	8b 00                	mov    (%rax),%eax
ffffffff80100525:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010052a:	be 10 00 00 00       	mov    $0x10,%esi
ffffffff8010052f:	89 c7                	mov    %eax,%edi
ffffffff80100531:	e8 7e fc ff ff       	call   ffffffff801001b4 <printint>
      break;
ffffffff80100536:	e9 5b 01 00 00       	jmp    ffffffff80100696 <cprintf+0x360>
    case 'l':
      printlong(va_arg(ap, u64), 16, 0);
ffffffff8010053b:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff80100541:	83 f8 2f             	cmp    $0x2f,%eax
ffffffff80100544:	77 23                	ja     ffffffff80100569 <cprintf+0x233>
ffffffff80100546:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff8010054d:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff80100553:	89 d2                	mov    %edx,%edx
ffffffff80100555:	48 01 d0             	add    %rdx,%rax
ffffffff80100558:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff8010055e:	83 c2 08             	add    $0x8,%edx
ffffffff80100561:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff80100567:	eb 12                	jmp    ffffffff8010057b <cprintf+0x245>
ffffffff80100569:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff80100570:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff80100574:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff8010057b:	48 8b 00             	mov    (%rax),%rax
ffffffff8010057e:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80100583:	be 10 00 00 00       	mov    $0x10,%esi
ffffffff80100588:	48 89 c7             	mov    %rax,%rdi
ffffffff8010058b:	e8 df fc ff ff       	call   ffffffff8010026f <printlong>
      break;
ffffffff80100590:	e9 01 01 00 00       	jmp    ffffffff80100696 <cprintf+0x360>
    case 'p':
      printptr(va_arg(ap, uintp));
ffffffff80100595:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff8010059b:	83 f8 2f             	cmp    $0x2f,%eax
ffffffff8010059e:	77 23                	ja     ffffffff801005c3 <cprintf+0x28d>
ffffffff801005a0:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff801005a7:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801005ad:	89 d2                	mov    %edx,%edx
ffffffff801005af:	48 01 d0             	add    %rdx,%rax
ffffffff801005b2:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801005b8:	83 c2 08             	add    $0x8,%edx
ffffffff801005bb:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff801005c1:	eb 12                	jmp    ffffffff801005d5 <cprintf+0x29f>
ffffffff801005c3:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff801005ca:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff801005ce:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff801005d5:	48 8b 00             	mov    (%rax),%rax
ffffffff801005d8:	48 89 c7             	mov    %rax,%rdi
ffffffff801005db:	e8 8d fb ff ff       	call   ffffffff8010016d <printptr>
      break;
ffffffff801005e0:	e9 b1 00 00 00       	jmp    ffffffff80100696 <cprintf+0x360>
    case 's':
      if((s = va_arg(ap, char*)) == 0)
ffffffff801005e5:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff801005eb:	83 f8 2f             	cmp    $0x2f,%eax
ffffffff801005ee:	77 23                	ja     ffffffff80100613 <cprintf+0x2dd>
ffffffff801005f0:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff801005f7:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801005fd:	89 d2                	mov    %edx,%edx
ffffffff801005ff:	48 01 d0             	add    %rdx,%rax
ffffffff80100602:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff80100608:	83 c2 08             	add    $0x8,%edx
ffffffff8010060b:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff80100611:	eb 12                	jmp    ffffffff80100625 <cprintf+0x2ef>
ffffffff80100613:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff8010061a:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff8010061e:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff80100625:	48 8b 00             	mov    (%rax),%rax
ffffffff80100628:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
ffffffff8010062f:	48 83 bd 40 ff ff ff 	cmpq   $0x0,-0xc0(%rbp)
ffffffff80100636:	00 
ffffffff80100637:	75 29                	jne    ffffffff80100662 <cprintf+0x32c>
        s = "(null)";
ffffffff80100639:	48 c7 85 40 ff ff ff 	movq   $0xffffffff80101d31,-0xc0(%rbp)
ffffffff80100640:	31 1d 10 80 
      for(; *s; s++)
ffffffff80100644:	eb 1c                	jmp    ffffffff80100662 <cprintf+0x32c>
        consputc(*s);
ffffffff80100646:	48 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%rax
ffffffff8010064d:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100650:	0f be c0             	movsbl %al,%eax
ffffffff80100653:	89 c7                	mov    %eax,%edi
ffffffff80100655:	e8 44 02 00 00       	call   ffffffff8010089e <consputc>
      for(; *s; s++)
ffffffff8010065a:	48 83 85 40 ff ff ff 	addq   $0x1,-0xc0(%rbp)
ffffffff80100661:	01 
ffffffff80100662:	48 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%rax
ffffffff80100669:	0f b6 00             	movzbl (%rax),%eax
ffffffff8010066c:	84 c0                	test   %al,%al
ffffffff8010066e:	75 d6                	jne    ffffffff80100646 <cprintf+0x310>
      break;
ffffffff80100670:	eb 24                	jmp    ffffffff80100696 <cprintf+0x360>
    case '%':
      consputc('%');
ffffffff80100672:	bf 25 00 00 00       	mov    $0x25,%edi
ffffffff80100677:	e8 22 02 00 00       	call   ffffffff8010089e <consputc>
      break;
ffffffff8010067c:	eb 18                	jmp    ffffffff80100696 <cprintf+0x360>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
ffffffff8010067e:	bf 25 00 00 00       	mov    $0x25,%edi
ffffffff80100683:	e8 16 02 00 00       	call   ffffffff8010089e <consputc>
      consputc(c);
ffffffff80100688:	8b 85 3c ff ff ff    	mov    -0xc4(%rbp),%eax
ffffffff8010068e:	89 c7                	mov    %eax,%edi
ffffffff80100690:	e8 09 02 00 00       	call   ffffffff8010089e <consputc>
      break;
ffffffff80100695:	90                   	nop
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
ffffffff80100696:	83 85 4c ff ff ff 01 	addl   $0x1,-0xb4(%rbp)
ffffffff8010069d:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
ffffffff801006a3:	48 63 d0             	movslq %eax,%rdx
ffffffff801006a6:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
ffffffff801006ad:	48 01 d0             	add    %rdx,%rax
ffffffff801006b0:	0f b6 00             	movzbl (%rax),%eax
ffffffff801006b3:	0f be c0             	movsbl %al,%eax
ffffffff801006b6:	25 ff 00 00 00       	and    $0xff,%eax
ffffffff801006bb:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%rbp)
ffffffff801006c1:	83 bd 3c ff ff ff 00 	cmpl   $0x0,-0xc4(%rbp)
ffffffff801006c8:	0f 85 17 fd ff ff    	jne    ffffffff801003e5 <cprintf+0xaf>
    }
  }

  //if(locking)
  //  release(&cons.lock);
}
ffffffff801006ce:	eb 01                	jmp    ffffffff801006d1 <cprintf+0x39b>
      break;
ffffffff801006d0:	90                   	nop
}
ffffffff801006d1:	90                   	nop
ffffffff801006d2:	c9                   	leave  
ffffffff801006d3:	c3                   	ret    

ffffffff801006d4 <panic>:

void
panic(char *s)
{
ffffffff801006d4:	f3 0f 1e fa          	endbr64 
ffffffff801006d8:	55                   	push   %rbp
ffffffff801006d9:	48 89 e5             	mov    %rsp,%rbp
ffffffff801006dc:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff801006e0:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  //int i;
  //u64 pcs[10];
  
  cli();
ffffffff801006e4:	e8 7c fa ff ff       	call   ffffffff80100165 <cli>
  //cons.locking = 0;
  //cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
ffffffff801006e9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801006ed:	48 89 c7             	mov    %rax,%rdi
ffffffff801006f0:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801006f5:	e8 3c fc ff ff       	call   ffffffff80100336 <cprintf>
  cprintf("\n");
ffffffff801006fa:	48 c7 c7 e0 1d 10 80 	mov    $0xffffffff80101de0,%rdi
ffffffff80100701:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100706:	e8 2b fc ff ff       	call   ffffffff80100336 <cprintf>
  //getcallerpcs(&s, pcs);
  //for(i=0; i<10; i++)
  //  cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
ffffffff8010070b:	c7 05 eb 28 00 00 01 	movl   $0x1,0x28eb(%rip)        # ffffffff80103000 <panicked>
ffffffff80100712:	00 00 00 
  for(;;)
ffffffff80100715:	eb fe                	jmp    ffffffff80100715 <panic+0x41>

ffffffff80100717 <cgaputc>:
#define CRTPORT 0x3d4
static u16 *crt = (u16*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
ffffffff80100717:	f3 0f 1e fa          	endbr64 
ffffffff8010071b:	55                   	push   %rbp
ffffffff8010071c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010071f:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80100723:	89 7d ec             	mov    %edi,-0x14(%rbp)
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
ffffffff80100726:	be 0e 00 00 00       	mov    $0xe,%esi
ffffffff8010072b:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff80100730:	e8 0f fa ff ff       	call   ffffffff80100144 <outb>
  pos = inb(CRTPORT+1) << 8;
ffffffff80100735:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff8010073a:	e8 e7 f9 ff ff       	call   ffffffff80100126 <inb>
ffffffff8010073f:	0f b6 c0             	movzbl %al,%eax
ffffffff80100742:	c1 e0 08             	shl    $0x8,%eax
ffffffff80100745:	89 45 fc             	mov    %eax,-0x4(%rbp)
  outb(CRTPORT, 15);
ffffffff80100748:	be 0f 00 00 00       	mov    $0xf,%esi
ffffffff8010074d:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff80100752:	e8 ed f9 ff ff       	call   ffffffff80100144 <outb>
  pos |= inb(CRTPORT+1);
ffffffff80100757:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff8010075c:	e8 c5 f9 ff ff       	call   ffffffff80100126 <inb>
ffffffff80100761:	0f b6 c0             	movzbl %al,%eax
ffffffff80100764:	09 45 fc             	or     %eax,-0x4(%rbp)

  if(c == '\n')
ffffffff80100767:	83 7d ec 0a          	cmpl   $0xa,-0x14(%rbp)
ffffffff8010076b:	75 37                	jne    ffffffff801007a4 <cgaputc+0x8d>
    pos += 80 - pos%80;
ffffffff8010076d:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80100770:	48 63 c2             	movslq %edx,%rax
ffffffff80100773:	48 69 c0 67 66 66 66 	imul   $0x66666667,%rax,%rax
ffffffff8010077a:	48 c1 e8 20          	shr    $0x20,%rax
ffffffff8010077e:	c1 f8 05             	sar    $0x5,%eax
ffffffff80100781:	89 d6                	mov    %edx,%esi
ffffffff80100783:	c1 fe 1f             	sar    $0x1f,%esi
ffffffff80100786:	29 f0                	sub    %esi,%eax
ffffffff80100788:	89 c1                	mov    %eax,%ecx
ffffffff8010078a:	89 c8                	mov    %ecx,%eax
ffffffff8010078c:	c1 e0 02             	shl    $0x2,%eax
ffffffff8010078f:	01 c8                	add    %ecx,%eax
ffffffff80100791:	c1 e0 04             	shl    $0x4,%eax
ffffffff80100794:	89 d1                	mov    %edx,%ecx
ffffffff80100796:	29 c1                	sub    %eax,%ecx
ffffffff80100798:	b8 50 00 00 00       	mov    $0x50,%eax
ffffffff8010079d:	29 c8                	sub    %ecx,%eax
ffffffff8010079f:	01 45 fc             	add    %eax,-0x4(%rbp)
ffffffff801007a2:	eb 3d                	jmp    ffffffff801007e1 <cgaputc+0xca>
  else if(c == BACKSPACE){
ffffffff801007a4:	81 7d ec 00 01 00 00 	cmpl   $0x100,-0x14(%rbp)
ffffffff801007ab:	75 0c                	jne    ffffffff801007b9 <cgaputc+0xa2>
    if(pos > 0) --pos;
ffffffff801007ad:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801007b1:	7e 2e                	jle    ffffffff801007e1 <cgaputc+0xca>
ffffffff801007b3:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff801007b7:	eb 28                	jmp    ffffffff801007e1 <cgaputc+0xca>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
ffffffff801007b9:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801007bc:	0f b6 c0             	movzbl %al,%eax
ffffffff801007bf:	80 cc 07             	or     $0x7,%ah
ffffffff801007c2:	89 c1                	mov    %eax,%ecx
ffffffff801007c4:	48 8b 35 4d 18 00 00 	mov    0x184d(%rip),%rsi        # ffffffff80102018 <crt>
ffffffff801007cb:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801007ce:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff801007d1:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff801007d4:	48 98                	cltq   
ffffffff801007d6:	48 01 c0             	add    %rax,%rax
ffffffff801007d9:	48 01 f0             	add    %rsi,%rax
ffffffff801007dc:	89 ca                	mov    %ecx,%edx
ffffffff801007de:	66 89 10             	mov    %dx,(%rax)
  
  if((pos/80) >= 24){  // Scroll up.
ffffffff801007e1:	81 7d fc 7f 07 00 00 	cmpl   $0x77f,-0x4(%rbp)
ffffffff801007e8:	7e 55                	jle    ffffffff8010083f <cgaputc+0x128>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
ffffffff801007ea:	48 8b 05 27 18 00 00 	mov    0x1827(%rip),%rax        # ffffffff80102018 <crt>
ffffffff801007f1:	48 8d 88 a0 00 00 00 	lea    0xa0(%rax),%rcx
ffffffff801007f8:	48 8b 05 19 18 00 00 	mov    0x1819(%rip),%rax        # ffffffff80102018 <crt>
ffffffff801007ff:	ba 60 0e 00 00       	mov    $0xe60,%edx
ffffffff80100804:	48 89 ce             	mov    %rcx,%rsi
ffffffff80100807:	48 89 c7             	mov    %rax,%rdi
ffffffff8010080a:	e8 28 02 00 00       	call   ffffffff80100a37 <memmove>
    pos -= 80;
ffffffff8010080f:	83 6d fc 50          	subl   $0x50,-0x4(%rbp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
ffffffff80100813:	b8 80 07 00 00       	mov    $0x780,%eax
ffffffff80100818:	2b 45 fc             	sub    -0x4(%rbp),%eax
ffffffff8010081b:	48 98                	cltq   
ffffffff8010081d:	8d 14 00             	lea    (%rax,%rax,1),%edx
ffffffff80100820:	48 8b 0d f1 17 00 00 	mov    0x17f1(%rip),%rcx        # ffffffff80102018 <crt>
ffffffff80100827:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010082a:	48 98                	cltq   
ffffffff8010082c:	48 01 c0             	add    %rax,%rax
ffffffff8010082f:	48 01 c8             	add    %rcx,%rax
ffffffff80100832:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100837:	48 89 c7             	mov    %rax,%rdi
ffffffff8010083a:	e8 03 01 00 00       	call   ffffffff80100942 <memset>
  }
  
  outb(CRTPORT, 14);
ffffffff8010083f:	be 0e 00 00 00       	mov    $0xe,%esi
ffffffff80100844:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff80100849:	e8 f6 f8 ff ff       	call   ffffffff80100144 <outb>
  outb(CRTPORT+1, pos>>8);
ffffffff8010084e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100851:	c1 f8 08             	sar    $0x8,%eax
ffffffff80100854:	0f b6 c0             	movzbl %al,%eax
ffffffff80100857:	89 c6                	mov    %eax,%esi
ffffffff80100859:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff8010085e:	e8 e1 f8 ff ff       	call   ffffffff80100144 <outb>
  outb(CRTPORT, 15);
ffffffff80100863:	be 0f 00 00 00       	mov    $0xf,%esi
ffffffff80100868:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff8010086d:	e8 d2 f8 ff ff       	call   ffffffff80100144 <outb>
  outb(CRTPORT+1, pos);
ffffffff80100872:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100875:	0f b6 c0             	movzbl %al,%eax
ffffffff80100878:	89 c6                	mov    %eax,%esi
ffffffff8010087a:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff8010087f:	e8 c0 f8 ff ff       	call   ffffffff80100144 <outb>
  crt[pos] = ' ' | 0x0700;
ffffffff80100884:	48 8b 15 8d 17 00 00 	mov    0x178d(%rip),%rdx        # ffffffff80102018 <crt>
ffffffff8010088b:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010088e:	48 98                	cltq   
ffffffff80100890:	48 01 c0             	add    %rax,%rax
ffffffff80100893:	48 01 d0             	add    %rdx,%rax
ffffffff80100896:	66 c7 00 20 07       	movw   $0x720,(%rax)
}
ffffffff8010089b:	90                   	nop
ffffffff8010089c:	c9                   	leave  
ffffffff8010089d:	c3                   	ret    

ffffffff8010089e <consputc>:

void
consputc(int c)
{
ffffffff8010089e:	f3 0f 1e fa          	endbr64 
ffffffff801008a2:	55                   	push   %rbp
ffffffff801008a3:	48 89 e5             	mov    %rsp,%rbp
ffffffff801008a6:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff801008aa:	89 7d fc             	mov    %edi,-0x4(%rbp)
  cgaputc(c);
ffffffff801008ad:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801008b0:	89 c7                	mov    %eax,%edi
ffffffff801008b2:	e8 60 fe ff ff       	call   ffffffff80100717 <cgaputc>
}
ffffffff801008b7:	90                   	nop
ffffffff801008b8:	c9                   	leave  
ffffffff801008b9:	c3                   	ret    

ffffffff801008ba <main>:
#include "defs.h"
#include "mmu.h"
#include "memlayout.h"
#include "proc.h"

int main(void){
ffffffff801008ba:	f3 0f 1e fa          	endbr64 
ffffffff801008be:	55                   	push   %rbp
ffffffff801008bf:	48 89 e5             	mov    %rsp,%rbp
  memblock_init();
ffffffff801008c2:	e8 8d 12 00 00       	call   ffffffff80101b54 <memblock_init>
  panic("ok");
ffffffff801008c7:	48 c7 c7 e2 1d 10 80 	mov    $0xffffffff80101de2,%rdi
ffffffff801008ce:	e8 01 fe ff ff       	call   ffffffff801006d4 <panic>
}
ffffffff801008d3:	90                   	nop
ffffffff801008d4:	5d                   	pop    %rbp
ffffffff801008d5:	c3                   	ret    

ffffffff801008d6 <stosb>:
{
ffffffff801008d6:	55                   	push   %rbp
ffffffff801008d7:	48 89 e5             	mov    %rsp,%rbp
ffffffff801008da:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff801008de:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff801008e2:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff801008e5:	89 55 f0             	mov    %edx,-0x10(%rbp)
  asm volatile("cld; rep stosb" :
ffffffff801008e8:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff801008ec:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff801008ef:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff801008f2:	48 89 ce             	mov    %rcx,%rsi
ffffffff801008f5:	48 89 f7             	mov    %rsi,%rdi
ffffffff801008f8:	89 d1                	mov    %edx,%ecx
ffffffff801008fa:	fc                   	cld    
ffffffff801008fb:	f3 aa                	rep stos %al,%es:(%rdi)
ffffffff801008fd:	89 ca                	mov    %ecx,%edx
ffffffff801008ff:	48 89 fe             	mov    %rdi,%rsi
ffffffff80100902:	48 89 75 f8          	mov    %rsi,-0x8(%rbp)
ffffffff80100906:	89 55 f0             	mov    %edx,-0x10(%rbp)
}
ffffffff80100909:	90                   	nop
ffffffff8010090a:	c9                   	leave  
ffffffff8010090b:	c3                   	ret    

ffffffff8010090c <stosl>:
{
ffffffff8010090c:	55                   	push   %rbp
ffffffff8010090d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100910:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80100914:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80100918:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff8010091b:	89 55 f0             	mov    %edx,-0x10(%rbp)
  asm volatile("cld; rep stosl" :
ffffffff8010091e:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff80100922:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff80100925:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80100928:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010092b:	48 89 f7             	mov    %rsi,%rdi
ffffffff8010092e:	89 d1                	mov    %edx,%ecx
ffffffff80100930:	fc                   	cld    
ffffffff80100931:	f3 ab                	rep stos %eax,%es:(%rdi)
ffffffff80100933:	89 ca                	mov    %ecx,%edx
ffffffff80100935:	48 89 fe             	mov    %rdi,%rsi
ffffffff80100938:	48 89 75 f8          	mov    %rsi,-0x8(%rbp)
ffffffff8010093c:	89 55 f0             	mov    %edx,-0x10(%rbp)
}
ffffffff8010093f:	90                   	nop
ffffffff80100940:	c9                   	leave  
ffffffff80100941:	c3                   	ret    

ffffffff80100942 <memset>:
#include "types.h"
#include "x86.h"

//assign c to dst - dst+n  
void* memset(void *dst, i32 c, u32 n){
ffffffff80100942:	f3 0f 1e fa          	endbr64 
ffffffff80100946:	55                   	push   %rbp
ffffffff80100947:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010094a:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010094e:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80100952:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff80100955:	89 55 f0             	mov    %edx,-0x10(%rbp)
  if ((u64)dst%4 == 0 && n%4 == 0){
ffffffff80100958:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010095c:	83 e0 03             	and    $0x3,%eax
ffffffff8010095f:	48 85 c0             	test   %rax,%rax
ffffffff80100962:	75 46                	jne    ffffffff801009aa <memset+0x68>
ffffffff80100964:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80100967:	83 e0 03             	and    $0x3,%eax
ffffffff8010096a:	85 c0                	test   %eax,%eax
ffffffff8010096c:	75 3c                	jne    ffffffff801009aa <memset+0x68>
    c &= 0xFF;
ffffffff8010096e:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
ffffffff80100975:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80100978:	c1 e8 02             	shr    $0x2,%eax
ffffffff8010097b:	89 c2                	mov    %eax,%edx
ffffffff8010097d:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80100980:	c1 e0 18             	shl    $0x18,%eax
ffffffff80100983:	89 c1                	mov    %eax,%ecx
ffffffff80100985:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80100988:	c1 e0 10             	shl    $0x10,%eax
ffffffff8010098b:	09 c1                	or     %eax,%ecx
ffffffff8010098d:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80100990:	c1 e0 08             	shl    $0x8,%eax
ffffffff80100993:	09 c8                	or     %ecx,%eax
ffffffff80100995:	0b 45 f4             	or     -0xc(%rbp),%eax
ffffffff80100998:	89 c1                	mov    %eax,%ecx
ffffffff8010099a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010099e:	89 ce                	mov    %ecx,%esi
ffffffff801009a0:	48 89 c7             	mov    %rax,%rdi
ffffffff801009a3:	e8 64 ff ff ff       	call   ffffffff8010090c <stosl>
ffffffff801009a8:	eb 14                	jmp    ffffffff801009be <memset+0x7c>
  }else
    stosb(dst, c, n);
ffffffff801009aa:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff801009ad:	8b 4d f4             	mov    -0xc(%rbp),%ecx
ffffffff801009b0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801009b4:	89 ce                	mov    %ecx,%esi
ffffffff801009b6:	48 89 c7             	mov    %rax,%rdi
ffffffff801009b9:	e8 18 ff ff ff       	call   ffffffff801008d6 <stosb>
  return dst;
ffffffff801009be:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff801009c2:	c9                   	leave  
ffffffff801009c3:	c3                   	ret    

ffffffff801009c4 <memcmp>:

//compare v1 with v2 return v1 - v2
int memcmp(const void* v1, const void* v2, u32 n){
ffffffff801009c4:	f3 0f 1e fa          	endbr64 
ffffffff801009c8:	55                   	push   %rbp
ffffffff801009c9:	48 89 e5             	mov    %rsp,%rbp
ffffffff801009cc:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff801009d0:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff801009d4:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff801009d8:	89 55 dc             	mov    %edx,-0x24(%rbp)
  const u8 *s1, *s2;

  s1 = v1;
ffffffff801009db:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801009df:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  s2 = v2;
ffffffff801009e3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801009e7:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  while(n-- > 0){
ffffffff801009eb:	eb 36                	jmp    ffffffff80100a23 <memcmp+0x5f>
    if(*s1 != *s2)
ffffffff801009ed:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801009f1:	0f b6 10             	movzbl (%rax),%edx
ffffffff801009f4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801009f8:	0f b6 00             	movzbl (%rax),%eax
ffffffff801009fb:	38 c2                	cmp    %al,%dl
ffffffff801009fd:	74 1a                	je     ffffffff80100a19 <memcmp+0x55>
      return *s1 - *s2;
ffffffff801009ff:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100a03:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100a06:	0f b6 d0             	movzbl %al,%edx
ffffffff80100a09:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100a0d:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100a10:	0f b6 c8             	movzbl %al,%ecx
ffffffff80100a13:	89 d0                	mov    %edx,%eax
ffffffff80100a15:	29 c8                	sub    %ecx,%eax
ffffffff80100a17:	eb 1c                	jmp    ffffffff80100a35 <memcmp+0x71>
    s1++, s2++;
ffffffff80100a19:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff80100a1e:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  while(n-- > 0){
ffffffff80100a23:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100a26:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80100a29:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80100a2c:	85 c0                	test   %eax,%eax
ffffffff80100a2e:	75 bd                	jne    ffffffff801009ed <memcmp+0x29>
  }

  return 0;
ffffffff80100a30:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80100a35:	c9                   	leave  
ffffffff80100a36:	c3                   	ret    

ffffffff80100a37 <memmove>:

//copy n chars from src to dst
void* memmove(void* dst, const void* src, u32 n){
ffffffff80100a37:	f3 0f 1e fa          	endbr64 
ffffffff80100a3b:	55                   	push   %rbp
ffffffff80100a3c:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100a3f:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80100a43:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80100a47:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80100a4b:	89 55 dc             	mov    %edx,-0x24(%rbp)
  const char* s;
  char* d;

  s = src;
ffffffff80100a4e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80100a52:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  d = dst;
ffffffff80100a56:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100a5a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  if(s<d && s + n > d){
ffffffff80100a5e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100a62:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff80100a66:	73 46                	jae    ffffffff80100aae <memmove+0x77>
ffffffff80100a68:	8b 55 dc             	mov    -0x24(%rbp),%edx
ffffffff80100a6b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100a6f:	48 01 d0             	add    %rdx,%rax
ffffffff80100a72:	48 39 45 f0          	cmp    %rax,-0x10(%rbp)
ffffffff80100a76:	73 36                	jae    ffffffff80100aae <memmove+0x77>
    s+=n;
ffffffff80100a78:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100a7b:	48 01 45 f8          	add    %rax,-0x8(%rbp)
    d+=n;
ffffffff80100a7f:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100a82:	48 01 45 f0          	add    %rax,-0x10(%rbp)
    while(n-- > 0)
ffffffff80100a86:	eb 17                	jmp    ffffffff80100a9f <memmove+0x68>
      *--d = * --s;
ffffffff80100a88:	48 83 6d f8 01       	subq   $0x1,-0x8(%rbp)
ffffffff80100a8d:	48 83 6d f0 01       	subq   $0x1,-0x10(%rbp)
ffffffff80100a92:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100a96:	0f b6 10             	movzbl (%rax),%edx
ffffffff80100a99:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100a9d:	88 10                	mov    %dl,(%rax)
    while(n-- > 0)
ffffffff80100a9f:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100aa2:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80100aa5:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80100aa8:	85 c0                	test   %eax,%eax
ffffffff80100aaa:	75 dc                	jne    ffffffff80100a88 <memmove+0x51>
  if(s<d && s + n > d){
ffffffff80100aac:	eb 05                	jmp    ffffffff80100ab3 <memmove+0x7c>
  }
  else
    while(n-- < 0)
ffffffff80100aae:	90                   	nop
ffffffff80100aaf:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
      *d++ = *s++;
}
ffffffff80100ab3:	90                   	nop
ffffffff80100ab4:	c9                   	leave  
ffffffff80100ab5:	c3                   	ret    

ffffffff80100ab6 <strncmp>:
//compare string
int strncmp(const char* p, const char* q, u32 n){
ffffffff80100ab6:	f3 0f 1e fa          	endbr64 
ffffffff80100aba:	55                   	push   %rbp
ffffffff80100abb:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100abe:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80100ac2:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80100ac6:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
ffffffff80100aca:	89 55 ec             	mov    %edx,-0x14(%rbp)
  while(n > 0 && *p && *p == *q)
ffffffff80100acd:	eb 0e                	jmp    ffffffff80100add <strncmp+0x27>
    n--, p++, q++;
ffffffff80100acf:	83 6d ec 01          	subl   $0x1,-0x14(%rbp)
ffffffff80100ad3:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff80100ad8:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  while(n > 0 && *p && *p == *q)
ffffffff80100add:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80100ae1:	74 1d                	je     ffffffff80100b00 <strncmp+0x4a>
ffffffff80100ae3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100ae7:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100aea:	84 c0                	test   %al,%al
ffffffff80100aec:	74 12                	je     ffffffff80100b00 <strncmp+0x4a>
ffffffff80100aee:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100af2:	0f b6 10             	movzbl (%rax),%edx
ffffffff80100af5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100af9:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100afc:	38 c2                	cmp    %al,%dl
ffffffff80100afe:	74 cf                	je     ffffffff80100acf <strncmp+0x19>
  if(n == 0)
ffffffff80100b00:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80100b04:	75 07                	jne    ffffffff80100b0d <strncmp+0x57>
    return 0;
ffffffff80100b06:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100b0b:	eb 18                	jmp    ffffffff80100b25 <strncmp+0x6f>
  return (u8)*p - (u8)*q;
ffffffff80100b0d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100b11:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100b14:	0f b6 d0             	movzbl %al,%edx
ffffffff80100b17:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100b1b:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100b1e:	0f b6 c8             	movzbl %al,%ecx
ffffffff80100b21:	89 d0                	mov    %edx,%eax
ffffffff80100b23:	29 c8                	sub    %ecx,%eax
}
ffffffff80100b25:	c9                   	leave  
ffffffff80100b26:	c3                   	ret    

ffffffff80100b27 <strncpy>:

//copy string most n char
char* strncpy(char* s, const char* t, i32 n){
ffffffff80100b27:	f3 0f 1e fa          	endbr64 
ffffffff80100b2b:	55                   	push   %rbp
ffffffff80100b2c:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100b2f:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80100b33:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80100b37:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80100b3b:	89 55 dc             	mov    %edx,-0x24(%rbp)
  char* os;

  os = s;
ffffffff80100b3e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100b42:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  while(n-- > 0 && (*s++ = *t++) != 0)
ffffffff80100b46:	90                   	nop
ffffffff80100b47:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100b4a:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80100b4d:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80100b50:	85 c0                	test   %eax,%eax
ffffffff80100b52:	7e 35                	jle    ffffffff80100b89 <strncpy+0x62>
ffffffff80100b54:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80100b58:	48 8d 42 01          	lea    0x1(%rdx),%rax
ffffffff80100b5c:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
ffffffff80100b60:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100b64:	48 8d 48 01          	lea    0x1(%rax),%rcx
ffffffff80100b68:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
ffffffff80100b6c:	0f b6 12             	movzbl (%rdx),%edx
ffffffff80100b6f:	88 10                	mov    %dl,(%rax)
ffffffff80100b71:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100b74:	84 c0                	test   %al,%al
ffffffff80100b76:	75 cf                	jne    ffffffff80100b47 <strncpy+0x20>
    ;
  while(n-- > 0)
ffffffff80100b78:	eb 0f                	jmp    ffffffff80100b89 <strncpy+0x62>
    *s++ = 0;
ffffffff80100b7a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100b7e:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80100b82:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
ffffffff80100b86:	c6 00 00             	movb   $0x0,(%rax)
  while(n-- > 0)
ffffffff80100b89:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100b8c:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80100b8f:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80100b92:	85 c0                	test   %eax,%eax
ffffffff80100b94:	7f e4                	jg     ffffffff80100b7a <strncpy+0x53>
  return os;
ffffffff80100b96:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80100b9a:	c9                   	leave  
ffffffff80100b9b:	c3                   	ret    

ffffffff80100b9c <strlen>:

//get the length of string
int strlen(const char* s){
ffffffff80100b9c:	f3 0f 1e fa          	endbr64 
ffffffff80100ba0:	55                   	push   %rbp
ffffffff80100ba1:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100ba4:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80100ba8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int n;
  for(n = 0; s[n]; n++)
ffffffff80100bac:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80100bb3:	eb 04                	jmp    ffffffff80100bb9 <strlen+0x1d>
ffffffff80100bb5:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80100bb9:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100bbc:	48 63 d0             	movslq %eax,%rdx
ffffffff80100bbf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100bc3:	48 01 d0             	add    %rdx,%rax
ffffffff80100bc6:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100bc9:	84 c0                	test   %al,%al
ffffffff80100bcb:	75 e8                	jne    ffffffff80100bb5 <strlen+0x19>
    ;
  return n;
ffffffff80100bcd:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff80100bd0:	c9                   	leave  
ffffffff80100bd1:	c3                   	ret    

ffffffff80100bd2 <safestrcpy>:

char* safestrcpy(char* s, const char* t, i32 n){
ffffffff80100bd2:	f3 0f 1e fa          	endbr64 
ffffffff80100bd6:	55                   	push   %rbp
ffffffff80100bd7:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100bda:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80100bde:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80100be2:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80100be6:	89 55 dc             	mov    %edx,-0x24(%rbp)
  char *os;
  
  os = s;
ffffffff80100be9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100bed:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(n <= 0)
ffffffff80100bf1:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
ffffffff80100bf5:	7f 06                	jg     ffffffff80100bfd <safestrcpy+0x2b>
    return os;
ffffffff80100bf7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100bfb:	eb 3a                	jmp    ffffffff80100c37 <safestrcpy+0x65>
  while(--n > 0 && (*s++ = *t++) != 0)
ffffffff80100bfd:	90                   	nop
ffffffff80100bfe:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
ffffffff80100c02:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
ffffffff80100c06:	7e 24                	jle    ffffffff80100c2c <safestrcpy+0x5a>
ffffffff80100c08:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80100c0c:	48 8d 42 01          	lea    0x1(%rdx),%rax
ffffffff80100c10:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
ffffffff80100c14:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100c18:	48 8d 48 01          	lea    0x1(%rax),%rcx
ffffffff80100c1c:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
ffffffff80100c20:	0f b6 12             	movzbl (%rdx),%edx
ffffffff80100c23:	88 10                	mov    %dl,(%rax)
ffffffff80100c25:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100c28:	84 c0                	test   %al,%al
ffffffff80100c2a:	75 d2                	jne    ffffffff80100bfe <safestrcpy+0x2c>
    ;
  *s = 0;
ffffffff80100c2c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100c30:	c6 00 00             	movb   $0x0,(%rax)
  return os;
ffffffff80100c33:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80100c37:	c9                   	leave  
ffffffff80100c38:	c3                   	ret    

ffffffff80100c39 <v2p>:

#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline u64 v2p(void *a) { return ((u64) (a)) - ((u64)KERNBASE); }
ffffffff80100c39:	55                   	push   %rbp
ffffffff80100c3a:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100c3d:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80100c41:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80100c45:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100c49:	ba 00 00 00 80       	mov    $0x80000000,%edx
ffffffff80100c4e:	48 01 d0             	add    %rdx,%rax
ffffffff80100c51:	c9                   	leave  
ffffffff80100c52:	c3                   	ret    

ffffffff80100c53 <page_walk>:
#include "memlayout.h"

// Return the address of the PTE in pml4
// that corresponds to virtual address va. If alloc!=0,
// create any required page table pages.
static u64* page_walk(u64* root,const void* va,int alloc){
ffffffff80100c53:	f3 0f 1e fa          	endbr64 
ffffffff80100c57:	55                   	push   %rbp
ffffffff80100c58:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100c5b:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80100c5f:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff80100c63:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff80100c67:	89 55 cc             	mov    %edx,-0x34(%rbp)
  
  u64 *pml4e, *pdpte, *pde, *pte;

  // Page map level 4 index
  pml4e = &root[PML4X(va)];
ffffffff80100c6a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80100c6e:	48 c1 e8 27          	shr    $0x27,%rax
ffffffff80100c72:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80100c77:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80100c7e:	00 
ffffffff80100c7f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80100c83:	48 01 d0             	add    %rdx,%rax
ffffffff80100c86:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

  if(!(*pml4e & PTE_P)){
ffffffff80100c8a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100c8e:	48 8b 00             	mov    (%rax),%rax
ffffffff80100c91:	83 e0 01             	and    $0x1,%eax
ffffffff80100c94:	48 85 c0             	test   %rax,%rax
ffffffff80100c97:	75 70                	jne    ffffffff80100d09 <page_walk+0xb6>
    if(!alloc || (pml4e = (u64*)memblock_alloc(PGSIZE, PGSIZE)) == 0)
ffffffff80100c99:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
ffffffff80100c9d:	74 1a                	je     ffffffff80100cb9 <page_walk+0x66>
ffffffff80100c9f:	be 00 10 00 00       	mov    $0x1000,%esi
ffffffff80100ca4:	bf 00 10 00 00       	mov    $0x1000,%edi
ffffffff80100ca9:	e8 e6 0b 00 00       	call   ffffffff80101894 <memblock_alloc>
ffffffff80100cae:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80100cb2:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80100cb7:	75 0a                	jne    ffffffff80100cc3 <page_walk+0x70>
      return 0;
ffffffff80100cb9:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100cbe:	e9 03 02 00 00       	jmp    ffffffff80100ec6 <page_walk+0x273>
    memset(pml4e, 0, PGSIZE);
ffffffff80100cc3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100cc7:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80100ccc:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100cd1:	48 89 c7             	mov    %rax,%rdi
ffffffff80100cd4:	e8 69 fc ff ff       	call   ffffffff80100942 <memset>
    root[PML4X(va)] = v2p(pml4e) | PTE_P | PTE_W | PTE_U;  
ffffffff80100cd9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100cdd:	48 89 c7             	mov    %rax,%rdi
ffffffff80100ce0:	e8 54 ff ff ff       	call   ffffffff80100c39 <v2p>
ffffffff80100ce5:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80100ce9:	48 c1 ea 27          	shr    $0x27,%rdx
ffffffff80100ced:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
ffffffff80100cf3:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
ffffffff80100cfa:	00 
ffffffff80100cfb:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80100cff:	48 01 ca             	add    %rcx,%rdx
ffffffff80100d02:	48 83 c8 07          	or     $0x7,%rax
ffffffff80100d06:	48 89 02             	mov    %rax,(%rdx)
  }

  // Page directory pointer index
  pdpte = &pdpte[PDPTX(va)];
ffffffff80100d09:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80100d0d:	48 c1 e8 1e          	shr    $0x1e,%rax
ffffffff80100d11:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80100d16:	48 c1 e0 03          	shl    $0x3,%rax
ffffffff80100d1a:	48 01 45 f0          	add    %rax,-0x10(%rbp)

  if(!(*pdpte & PTE_P)){
ffffffff80100d1e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100d22:	48 8b 00             	mov    (%rax),%rax
ffffffff80100d25:	83 e0 01             	and    $0x1,%eax
ffffffff80100d28:	48 85 c0             	test   %rax,%rax
ffffffff80100d2b:	75 70                	jne    ffffffff80100d9d <page_walk+0x14a>
    if(!alloc || (pdpte = (u64*)memblock_alloc(PGSIZE, PGSIZE)) == 0)
ffffffff80100d2d:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
ffffffff80100d31:	74 1a                	je     ffffffff80100d4d <page_walk+0xfa>
ffffffff80100d33:	be 00 10 00 00       	mov    $0x1000,%esi
ffffffff80100d38:	bf 00 10 00 00       	mov    $0x1000,%edi
ffffffff80100d3d:	e8 52 0b 00 00       	call   ffffffff80101894 <memblock_alloc>
ffffffff80100d42:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80100d46:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80100d4b:	75 0a                	jne    ffffffff80100d57 <page_walk+0x104>
      return 0;
ffffffff80100d4d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100d52:	e9 6f 01 00 00       	jmp    ffffffff80100ec6 <page_walk+0x273>
    memset(pdpte, 0, PGSIZE);
ffffffff80100d57:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100d5b:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80100d60:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100d65:	48 89 c7             	mov    %rax,%rdi
ffffffff80100d68:	e8 d5 fb ff ff       	call   ffffffff80100942 <memset>
    pml4e[PDPTX(va)] = v2p(pdpte) | PTE_P | PTE_W | PTE_U;  
ffffffff80100d6d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80100d71:	48 89 c7             	mov    %rax,%rdi
ffffffff80100d74:	e8 c0 fe ff ff       	call   ffffffff80100c39 <v2p>
ffffffff80100d79:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80100d7d:	48 c1 ea 1e          	shr    $0x1e,%rdx
ffffffff80100d81:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
ffffffff80100d87:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
ffffffff80100d8e:	00 
ffffffff80100d8f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80100d93:	48 01 ca             	add    %rcx,%rdx
ffffffff80100d96:	48 83 c8 07          	or     $0x7,%rax
ffffffff80100d9a:	48 89 02             	mov    %rax,(%rdx)
  }

  // Page directory index
  pde = &pde[PDX(va)];
ffffffff80100d9d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80100da1:	48 c1 e8 15          	shr    $0x15,%rax
ffffffff80100da5:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80100daa:	48 c1 e0 03          	shl    $0x3,%rax
ffffffff80100dae:	48 01 45 e8          	add    %rax,-0x18(%rbp)

  if(!(*pde & PTE_P)){
ffffffff80100db2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100db6:	48 8b 00             	mov    (%rax),%rax
ffffffff80100db9:	83 e0 01             	and    $0x1,%eax
ffffffff80100dbc:	48 85 c0             	test   %rax,%rax
ffffffff80100dbf:	75 70                	jne    ffffffff80100e31 <page_walk+0x1de>
    if(!alloc || (pde = (u64*)memblock_alloc(PGSIZE, PGSIZE)) == 0)
ffffffff80100dc1:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
ffffffff80100dc5:	74 1a                	je     ffffffff80100de1 <page_walk+0x18e>
ffffffff80100dc7:	be 00 10 00 00       	mov    $0x1000,%esi
ffffffff80100dcc:	bf 00 10 00 00       	mov    $0x1000,%edi
ffffffff80100dd1:	e8 be 0a 00 00       	call   ffffffff80101894 <memblock_alloc>
ffffffff80100dd6:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80100dda:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80100ddf:	75 0a                	jne    ffffffff80100deb <page_walk+0x198>
      return 0;
ffffffff80100de1:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100de6:	e9 db 00 00 00       	jmp    ffffffff80100ec6 <page_walk+0x273>
    memset(pde, 0, PGSIZE);
ffffffff80100deb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100def:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80100df4:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100df9:	48 89 c7             	mov    %rax,%rdi
ffffffff80100dfc:	e8 41 fb ff ff       	call   ffffffff80100942 <memset>
    pdpte[PDX(va)] = v2p(pde) | PTE_P | PTE_W | PTE_U;  
ffffffff80100e01:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100e05:	48 89 c7             	mov    %rax,%rdi
ffffffff80100e08:	e8 2c fe ff ff       	call   ffffffff80100c39 <v2p>
ffffffff80100e0d:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80100e11:	48 c1 ea 15          	shr    $0x15,%rdx
ffffffff80100e15:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
ffffffff80100e1b:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
ffffffff80100e22:	00 
ffffffff80100e23:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80100e27:	48 01 ca             	add    %rcx,%rdx
ffffffff80100e2a:	48 83 c8 07          	or     $0x7,%rax
ffffffff80100e2e:	48 89 02             	mov    %rax,(%rdx)
  }

  // Page table index
  pte = &pte[PTX(va)];
ffffffff80100e31:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80100e35:	48 c1 e8 0c          	shr    $0xc,%rax
ffffffff80100e39:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80100e3e:	48 c1 e0 03          	shl    $0x3,%rax
ffffffff80100e42:	48 01 45 e0          	add    %rax,-0x20(%rbp)

  if(!(*pte & PTE_P)){
ffffffff80100e46:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80100e4a:	48 8b 00             	mov    (%rax),%rax
ffffffff80100e4d:	83 e0 01             	and    $0x1,%eax
ffffffff80100e50:	48 85 c0             	test   %rax,%rax
ffffffff80100e53:	75 6d                	jne    ffffffff80100ec2 <page_walk+0x26f>
    if(!alloc || (pte = (u64*)memblock_alloc(PGSIZE, PGSIZE)) == 0)
ffffffff80100e55:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
ffffffff80100e59:	74 1a                	je     ffffffff80100e75 <page_walk+0x222>
ffffffff80100e5b:	be 00 10 00 00       	mov    $0x1000,%esi
ffffffff80100e60:	bf 00 10 00 00       	mov    $0x1000,%edi
ffffffff80100e65:	e8 2a 0a 00 00       	call   ffffffff80101894 <memblock_alloc>
ffffffff80100e6a:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
ffffffff80100e6e:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
ffffffff80100e73:	75 07                	jne    ffffffff80100e7c <page_walk+0x229>
      return 0;
ffffffff80100e75:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100e7a:	eb 4a                	jmp    ffffffff80100ec6 <page_walk+0x273>
    memset(pte, 0, PGSIZE);
ffffffff80100e7c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80100e80:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80100e85:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100e8a:	48 89 c7             	mov    %rax,%rdi
ffffffff80100e8d:	e8 b0 fa ff ff       	call   ffffffff80100942 <memset>
    pde[PTX(va)] = v2p(pte) | PTE_P | PTE_W | PTE_U;  
ffffffff80100e92:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80100e96:	48 89 c7             	mov    %rax,%rdi
ffffffff80100e99:	e8 9b fd ff ff       	call   ffffffff80100c39 <v2p>
ffffffff80100e9e:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80100ea2:	48 c1 ea 0c          	shr    $0xc,%rdx
ffffffff80100ea6:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
ffffffff80100eac:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
ffffffff80100eb3:	00 
ffffffff80100eb4:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80100eb8:	48 01 ca             	add    %rcx,%rdx
ffffffff80100ebb:	48 83 c8 07          	or     $0x7,%rax
ffffffff80100ebf:	48 89 02             	mov    %rax,(%rdx)
  }

  return pte;
ffffffff80100ec2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
}
ffffffff80100ec6:	c9                   	leave  
ffffffff80100ec7:	c3                   	ret    

ffffffff80100ec8 <mamppages>:

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int mamppages(u64* pml4, void* va, u64 size, u64 pa, int perm){
ffffffff80100ec8:	f3 0f 1e fa          	endbr64 
ffffffff80100ecc:	55                   	push   %rbp
ffffffff80100ecd:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100ed0:	48 83 ec 50          	sub    $0x50,%rsp
ffffffff80100ed4:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff80100ed8:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff80100edc:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
ffffffff80100ee0:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
ffffffff80100ee4:	44 89 45 bc          	mov    %r8d,-0x44(%rbp)
  char *first, *last;
  u64* pte;

  first = (char*)ALIGN_DOWN(((u64)va), ((u64)PGSIZE));
ffffffff80100ee8:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80100eec:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff80100ef2:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  last = (char*)ALIGN_DOWN(((u64)va), ((u64)PGSIZE));
ffffffff80100ef6:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80100efa:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff80100f00:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  while(1){
    if(pte = page_walk(pml4, first, 1) == 0)
ffffffff80100f04:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff80100f08:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80100f0c:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff80100f11:	48 89 ce             	mov    %rcx,%rsi
ffffffff80100f14:	48 89 c7             	mov    %rax,%rdi
ffffffff80100f17:	e8 37 fd ff ff       	call   ffffffff80100c53 <page_walk>
ffffffff80100f1c:	48 85 c0             	test   %rax,%rax
ffffffff80100f1f:	0f 94 c0             	sete   %al
ffffffff80100f22:	0f b6 c0             	movzbl %al,%eax
ffffffff80100f25:	48 98                	cltq   
ffffffff80100f27:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80100f2b:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80100f30:	74 07                	je     ffffffff80100f39 <mamppages+0x71>
      return -1;
ffffffff80100f32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80100f37:	eb 57                	jmp    ffffffff80100f90 <mamppages+0xc8>
    if(*pte & PTE_P)
ffffffff80100f39:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100f3d:	48 8b 00             	mov    (%rax),%rax
ffffffff80100f40:	83 e0 01             	and    $0x1,%eax
ffffffff80100f43:	48 85 c0             	test   %rax,%rax
ffffffff80100f46:	74 0c                	je     ffffffff80100f54 <mamppages+0x8c>
      panic("remap");
ffffffff80100f48:	48 c7 c7 e5 1d 10 80 	mov    $0xffffffff80101de5,%rdi
ffffffff80100f4f:	e8 80 f7 ff ff       	call   ffffffff801006d4 <panic>
    *pte = pa | perm | PTE_P;
ffffffff80100f54:	8b 45 bc             	mov    -0x44(%rbp),%eax
ffffffff80100f57:	48 98                	cltq   
ffffffff80100f59:	48 0b 45 c0          	or     -0x40(%rbp),%rax
ffffffff80100f5d:	48 83 c8 01          	or     $0x1,%rax
ffffffff80100f61:	48 89 c2             	mov    %rax,%rdx
ffffffff80100f64:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100f68:	48 89 10             	mov    %rdx,(%rax)
    if(first == last)
ffffffff80100f6b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100f6f:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff80100f73:	74 15                	je     ffffffff80100f8a <mamppages+0xc2>
      break;
    first += PGSIZE;
ffffffff80100f75:	48 81 45 f8 00 10 00 	addq   $0x1000,-0x8(%rbp)
ffffffff80100f7c:	00 
    pa += PGSIZE;
ffffffff80100f7d:	48 81 45 c0 00 10 00 	addq   $0x1000,-0x40(%rbp)
ffffffff80100f84:	00 
    if(pte = page_walk(pml4, first, 1) == 0)
ffffffff80100f85:	e9 7a ff ff ff       	jmp    ffffffff80100f04 <mamppages+0x3c>
      break;
ffffffff80100f8a:	90                   	nop
  }
  return 0;
ffffffff80100f8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80100f90:	c9                   	leave  
ffffffff80100f91:	c3                   	ret    

ffffffff80100f92 <memblock_insert_region>:
#include "defs.h"

#define clamp(val, lo, hi) min( (typeof(val))(max(val, lo)),hi)  

// Insert a region to the regions list
int memblock_insert_region(struct memblock_type *type, int idx, u64 base, u64 size){
ffffffff80100f92:	f3 0f 1e fa          	endbr64 
ffffffff80100f96:	55                   	push   %rbp
ffffffff80100f97:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100f9a:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80100f9e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80100fa2:	89 75 e4             	mov    %esi,-0x1c(%rbp)
ffffffff80100fa5:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
ffffffff80100fa9:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  struct memblock_region* rgn = &type->regions[idx];
ffffffff80100fad:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100fb1:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff80100fb5:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80100fb8:	48 98                	cltq   
ffffffff80100fba:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80100fbe:	48 01 d0             	add    %rdx,%rax
ffffffff80100fc1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  memmove(rgn + 1, rgn, (type->cnt -idx)* sizeof(*rgn));
ffffffff80100fc5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100fc9:	48 8b 00             	mov    (%rax),%rax
ffffffff80100fcc:	8b 55 e4             	mov    -0x1c(%rbp),%edx
ffffffff80100fcf:	48 63 d2             	movslq %edx,%rdx
ffffffff80100fd2:	48 29 d0             	sub    %rdx,%rax
ffffffff80100fd5:	c1 e0 04             	shl    $0x4,%eax
ffffffff80100fd8:	89 c2                	mov    %eax,%edx
ffffffff80100fda:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100fde:	48 8d 48 10          	lea    0x10(%rax),%rcx
ffffffff80100fe2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100fe6:	48 89 c6             	mov    %rax,%rsi
ffffffff80100fe9:	48 89 cf             	mov    %rcx,%rdi
ffffffff80100fec:	e8 46 fa ff ff       	call   ffffffff80100a37 <memmove>
  rgn->base = base;
ffffffff80100ff1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100ff5:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80100ff9:	48 89 10             	mov    %rdx,(%rax)
  rgn->size = size;
ffffffff80100ffc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101000:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80101004:	48 89 50 08          	mov    %rdx,0x8(%rax)
  
  type->cnt++;
ffffffff80101008:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010100c:	48 8b 00             	mov    (%rax),%rax
ffffffff8010100f:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80101013:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101017:	48 89 10             	mov    %rdx,(%rax)
  type->total_size+=size;
ffffffff8010101a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010101e:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffffffff80101022:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80101026:	48 01 c2             	add    %rax,%rdx
ffffffff80101029:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010102d:	48 89 50 10          	mov    %rdx,0x10(%rax)
}
ffffffff80101031:	90                   	nop
ffffffff80101032:	c9                   	leave  
ffffffff80101033:	c3                   	ret    

ffffffff80101034 <memblock_merge_regions>:

// Merge the adjacent and continuous regions
int memblock_merge_regions(struct memblock_type *type){
ffffffff80101034:	f3 0f 1e fa          	endbr64 
ffffffff80101038:	55                   	push   %rbp
ffffffff80101039:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010103c:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80101040:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  int i = 0;
ffffffff80101044:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)

  while(i < type->cnt -1){
ffffffff8010104b:	e9 a0 00 00 00       	jmp    ffffffff801010f0 <memblock_merge_regions+0xbc>
    struct memblock_region* this = &type->regions[i];
ffffffff80101050:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101054:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff80101058:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010105b:	48 98                	cltq   
ffffffff8010105d:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80101061:	48 01 d0             	add    %rdx,%rax
ffffffff80101064:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    struct memblock_region* next = &type->regions[i+1];
ffffffff80101068:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010106c:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff80101070:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101073:	48 98                	cltq   
ffffffff80101075:	48 83 c0 01          	add    $0x1,%rax
ffffffff80101079:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff8010107d:	48 01 d0             	add    %rdx,%rax
ffffffff80101080:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

    if(this->base + this->size != next->base){
ffffffff80101084:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101088:	48 8b 10             	mov    (%rax),%rdx
ffffffff8010108b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010108f:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80101093:	48 01 c2             	add    %rax,%rdx
ffffffff80101096:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010109a:	48 8b 00             	mov    (%rax),%rax
ffffffff8010109d:	48 39 c2             	cmp    %rax,%rdx
ffffffff801010a0:	74 06                	je     ffffffff801010a8 <memblock_merge_regions+0x74>
      i++;
ffffffff801010a2:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
      continue;
ffffffff801010a6:	eb 48                	jmp    ffffffff801010f0 <memblock_merge_regions+0xbc>
    }
    
    this->size += next->size;
ffffffff801010a8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801010ac:	48 8b 50 08          	mov    0x8(%rax),%rdx
ffffffff801010b0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801010b4:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff801010b8:	48 01 c2             	add    %rax,%rdx
ffffffff801010bb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801010bf:	48 89 50 08          	mov    %rdx,0x8(%rax)
    memmove(next, next + 1, (type->cnt -(i+2) * sizeof(*next)));
ffffffff801010c3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801010c7:	48 8b 00             	mov    (%rax),%rax
ffffffff801010ca:	89 c2                	mov    %eax,%edx
ffffffff801010cc:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801010cf:	83 c0 02             	add    $0x2,%eax
ffffffff801010d2:	48 98                	cltq   
ffffffff801010d4:	c1 e0 04             	shl    $0x4,%eax
ffffffff801010d7:	29 c2                	sub    %eax,%edx
ffffffff801010d9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801010dd:	48 8d 48 10          	lea    0x10(%rax),%rcx
ffffffff801010e1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801010e5:	48 89 ce             	mov    %rcx,%rsi
ffffffff801010e8:	48 89 c7             	mov    %rax,%rdi
ffffffff801010eb:	e8 47 f9 ff ff       	call   ffffffff80100a37 <memmove>
  while(i < type->cnt -1){
ffffffff801010f0:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801010f3:	48 63 d0             	movslq %eax,%rdx
ffffffff801010f6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801010fa:	48 8b 00             	mov    (%rax),%rax
ffffffff801010fd:	48 83 e8 01          	sub    $0x1,%rax
ffffffff80101101:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101104:	0f 82 46 ff ff ff    	jb     ffffffff80101050 <memblock_merge_regions+0x1c>
  }
}
ffffffff8010110a:	90                   	nop
ffffffff8010110b:	c9                   	leave  
ffffffff8010110c:	c3                   	ret    

ffffffff8010110d <memblock_remove_region>:

void memblock_remove_region(struct memblock_type* type, u64 i){
ffffffff8010110d:	f3 0f 1e fa          	endbr64 
ffffffff80101111:	55                   	push   %rbp
ffffffff80101112:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101115:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80101119:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010111d:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  type->total_size -= type->regions[i].size;
ffffffff80101121:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101125:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffffffff80101129:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010112d:	48 8b 48 18          	mov    0x18(%rax),%rcx
ffffffff80101131:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101135:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80101139:	48 01 c8             	add    %rcx,%rax
ffffffff8010113c:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80101140:	48 29 c2             	sub    %rax,%rdx
ffffffff80101143:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101147:	48 89 50 10          	mov    %rdx,0x10(%rax)
  memmove(&type->regions[i], &type->regions[i+1],
     type->cnt - (i + 1) * sizeof( type->regions[i] ));
ffffffff8010114b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010114f:	48 8b 00             	mov    (%rax),%rax
  memmove(&type->regions[i], &type->regions[i+1],
ffffffff80101152:	89 c2                	mov    %eax,%edx
     type->cnt - (i + 1) * sizeof( type->regions[i] ));
ffffffff80101154:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101158:	48 83 c0 01          	add    $0x1,%rax
  memmove(&type->regions[i], &type->regions[i+1],
ffffffff8010115c:	c1 e0 04             	shl    $0x4,%eax
ffffffff8010115f:	29 c2                	sub    %eax,%edx
ffffffff80101161:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101165:	48 8b 48 18          	mov    0x18(%rax),%rcx
ffffffff80101169:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010116d:	48 83 c0 01          	add    $0x1,%rax
ffffffff80101171:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80101175:	48 01 c1             	add    %rax,%rcx
ffffffff80101178:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010117c:	48 8b 70 18          	mov    0x18(%rax),%rsi
ffffffff80101180:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101184:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80101188:	48 01 f0             	add    %rsi,%rax
ffffffff8010118b:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010118e:	48 89 c7             	mov    %rax,%rdi
ffffffff80101191:	e8 a1 f8 ff ff       	call   ffffffff80100a37 <memmove>
  type->cnt--;
ffffffff80101196:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010119a:	48 8b 00             	mov    (%rax),%rax
ffffffff8010119d:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
ffffffff801011a1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801011a5:	48 89 10             	mov    %rdx,(%rax)

  if(type->cnt == 0){
ffffffff801011a8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801011ac:	48 8b 00             	mov    (%rax),%rax
ffffffff801011af:	48 85 c0             	test   %rax,%rax
ffffffff801011b2:	75 2a                	jne    ffffffff801011de <memblock_remove_region+0xd1>
    type->cnt = 1;
ffffffff801011b4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801011b8:	48 c7 00 01 00 00 00 	movq   $0x1,(%rax)
    type->regions[0].base = 0;
ffffffff801011bf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801011c3:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801011c7:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    type->regions[0].size = 0;
ffffffff801011ce:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801011d2:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801011d6:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
ffffffff801011dd:	00 
  }
}
ffffffff801011de:	90                   	nop
ffffffff801011df:	c9                   	leave  
ffffffff801011e0:	c3                   	ret    

ffffffff801011e1 <memblock_add_regions>:

// The entry is sorted in default
int memblock_add_regions(struct memblock_type *type,u64 base,u64 size){
ffffffff801011e1:	f3 0f 1e fa          	endbr64 
ffffffff801011e5:	55                   	push   %rbp
ffffffff801011e6:	48 89 e5             	mov    %rsp,%rbp
ffffffff801011e9:	48 83 ec 70          	sub    $0x70,%rsp
ffffffff801011ed:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
ffffffff801011f1:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
ffffffff801011f5:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  int insert = 0;
ffffffff801011f9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  u64 obase = base;
ffffffff80101200:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
ffffffff80101204:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  u64 end = base + size;
ffffffff80101208:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
ffffffff8010120c:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff80101210:	48 01 d0             	add    %rdx,%rax
ffffffff80101213:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  int idx, nr_new;
  struct memblock_region* rgn;

  if(!size)return 0;
ffffffff80101217:	48 83 7d 98 00       	cmpq   $0x0,-0x68(%rbp)
ffffffff8010121c:	75 0a                	jne    ffffffff80101228 <memblock_add_regions+0x47>
ffffffff8010121e:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101223:	e9 b8 01 00 00       	jmp    ffffffff801013e0 <memblock_add_regions+0x1ff>

  if(type->regions[0].size == 0){
ffffffff80101228:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff8010122c:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80101230:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80101234:	48 85 c0             	test   %rax,%rax
ffffffff80101237:	75 35                	jne    ffffffff8010126e <memblock_add_regions+0x8d>
    type->regions[0].base = base;
ffffffff80101239:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff8010123d:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80101241:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
ffffffff80101245:	48 89 10             	mov    %rdx,(%rax)
    type->regions[0].size = size;
ffffffff80101248:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff8010124c:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80101250:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
ffffffff80101254:	48 89 50 08          	mov    %rdx,0x8(%rax)
    type->total_size = size;
ffffffff80101258:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff8010125c:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
ffffffff80101260:	48 89 50 10          	mov    %rdx,0x10(%rax)
    return 0;
ffffffff80101264:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101269:	e9 72 01 00 00       	jmp    ffffffff801013e0 <memblock_add_regions+0x1ff>
  }
  repeat:
ffffffff8010126e:	90                   	nop
    base = obase;
ffffffff8010126f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101273:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
    nr_new = 0;
ffffffff80101277:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
    for_each_memblock_type(idx, type, rgn){
ffffffff8010127e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
ffffffff80101285:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff80101289:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff8010128d:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80101291:	e9 af 00 00 00       	jmp    ffffffff80101345 <memblock_add_regions+0x164>
      u64 rbase = rgn->base;
ffffffff80101296:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010129a:	48 8b 00             	mov    (%rax),%rax
ffffffff8010129d:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
      u64 rend = rbase + rgn->size;
ffffffff801012a1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801012a5:	48 8b 50 08          	mov    0x8(%rax),%rdx
ffffffff801012a9:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801012ad:	48 01 d0             	add    %rdx,%rax
ffffffff801012b0:	48 89 45 c8          	mov    %rax,-0x38(%rbp)

      if(rbase >= end)
ffffffff801012b4:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801012b8:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
ffffffff801012bc:	0f 83 9b 00 00 00    	jae    ffffffff8010135d <memblock_add_regions+0x17c>
        break;
      if(rend <= base)
ffffffff801012c2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801012c6:	48 3b 45 a0          	cmp    -0x60(%rbp),%rax
ffffffff801012ca:	76 5c                	jbe    ffffffff80101328 <memblock_add_regions+0x147>
        continue;
      if(rbase > base){
ffffffff801012cc:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801012d0:	48 3b 45 a0          	cmp    -0x60(%rbp),%rax
ffffffff801012d4:	76 2d                	jbe    ffffffff80101303 <memblock_add_regions+0x122>
        nr_new++;
ffffffff801012d6:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
        if(insert)
ffffffff801012da:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801012de:	74 23                	je     ffffffff80101303 <memblock_add_regions+0x122>
          memblock_insert_region(type, idx++, base, rbase-base);
ffffffff801012e0:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801012e4:	48 2b 45 a0          	sub    -0x60(%rbp),%rax
ffffffff801012e8:	48 89 c1             	mov    %rax,%rcx
ffffffff801012eb:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801012ee:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff801012f1:	89 55 f8             	mov    %edx,-0x8(%rbp)
ffffffff801012f4:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
ffffffff801012f8:	48 8b 7d a8          	mov    -0x58(%rbp),%rdi
ffffffff801012fc:	89 c6                	mov    %eax,%esi
ffffffff801012fe:	e8 8f fc ff ff       	call   ffffffff80100f92 <memblock_insert_region>
      }
      base = min(rend, end);
ffffffff80101303:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101307:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
ffffffff8010130b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010130f:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
ffffffff80101313:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
ffffffff80101317:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff8010131b:	48 39 c2             	cmp    %rax,%rdx
ffffffff8010131e:	48 0f 46 c2          	cmovbe %rdx,%rax
ffffffff80101322:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
ffffffff80101326:	eb 01                	jmp    ffffffff80101329 <memblock_add_regions+0x148>
        continue;
ffffffff80101328:	90                   	nop
    for_each_memblock_type(idx, type, rgn){
ffffffff80101329:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
ffffffff8010132d:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff80101331:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff80101335:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101338:	48 98                	cltq   
ffffffff8010133a:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff8010133e:	48 01 d0             	add    %rdx,%rax
ffffffff80101341:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80101345:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101348:	48 63 d0             	movslq %eax,%rdx
ffffffff8010134b:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff8010134f:	48 8b 00             	mov    (%rax),%rax
ffffffff80101352:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101355:	0f 82 3b ff ff ff    	jb     ffffffff80101296 <memblock_add_regions+0xb5>
ffffffff8010135b:	eb 01                	jmp    ffffffff8010135e <memblock_add_regions+0x17d>
        break;
ffffffff8010135d:	90                   	nop
    }
    
    if(base < end){
ffffffff8010135e:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
ffffffff80101362:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
ffffffff80101366:	73 28                	jae    ffffffff80101390 <memblock_add_regions+0x1af>
      nr_new++;
ffffffff80101368:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
      if(insert)
ffffffff8010136c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80101370:	74 1e                	je     ffffffff80101390 <memblock_add_regions+0x1af>
        memblock_insert_region(type, idx, base, end-base);
ffffffff80101372:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101376:	48 2b 45 a0          	sub    -0x60(%rbp),%rax
ffffffff8010137a:	48 89 c1             	mov    %rax,%rcx
ffffffff8010137d:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
ffffffff80101381:	8b 75 f8             	mov    -0x8(%rbp),%esi
ffffffff80101384:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff80101388:	48 89 c7             	mov    %rax,%rdi
ffffffff8010138b:	e8 02 fc ff ff       	call   ffffffff80100f92 <memblock_insert_region>
    }

    if(!nr_new)
ffffffff80101390:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
ffffffff80101394:	75 07                	jne    ffffffff8010139d <memblock_add_regions+0x1bc>
      return 0;
ffffffff80101396:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010139b:	eb 43                	jmp    ffffffff801013e0 <memblock_add_regions+0x1ff>

    if(!insert){
ffffffff8010139d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801013a1:	75 2c                	jne    ffffffff801013cf <memblock_add_regions+0x1ee>
      if(type->cnt + nr_new > type->max)
ffffffff801013a3:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff801013a7:	48 8b 10             	mov    (%rax),%rdx
ffffffff801013aa:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff801013ad:	48 98                	cltq   
ffffffff801013af:	48 01 c2             	add    %rax,%rdx
ffffffff801013b2:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff801013b6:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff801013ba:	48 39 c2             	cmp    %rax,%rdx
ffffffff801013bd:	0f 86 ac fe ff ff    	jbe    ffffffff8010126f <memblock_add_regions+0x8e>
        //panic();
      insert = 1;
ffffffff801013c3:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
      goto repeat;
ffffffff801013ca:	e9 a0 fe ff ff       	jmp    ffffffff8010126f <memblock_add_regions+0x8e>
    }
    else{
      memblock_merge_regions(type);
ffffffff801013cf:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff801013d3:	48 89 c7             	mov    %rax,%rdi
ffffffff801013d6:	e8 59 fc ff ff       	call   ffffffff80101034 <memblock_merge_regions>
      return 0;
ffffffff801013db:	b8 00 00 00 00       	mov    $0x0,%eax
    }
}
ffffffff801013e0:	c9                   	leave  
ffffffff801013e1:	c3                   	ret    

ffffffff801013e2 <memblock_add>:

int memblock_add(u64 base, u64 size){
ffffffff801013e2:	f3 0f 1e fa          	endbr64 
ffffffff801013e6:	55                   	push   %rbp
ffffffff801013e7:	48 89 e5             	mov    %rsp,%rbp
ffffffff801013ea:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff801013ee:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff801013f2:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  return memblock_add_regions(&memblock.memory, base, size);
ffffffff801013f6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff801013fa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801013fe:	48 89 c6             	mov    %rax,%rsi
ffffffff80101401:	48 c7 c7 20 30 10 80 	mov    $0xffffffff80103020,%rdi
ffffffff80101408:	e8 d4 fd ff ff       	call   ffffffff801011e1 <memblock_add_regions>
}
ffffffff8010140d:	c9                   	leave  
ffffffff8010140e:	c3                   	ret    

ffffffff8010140f <memblock_reserve>:

int memblock_reserve(u64 base, u64 size){
ffffffff8010140f:	f3 0f 1e fa          	endbr64 
ffffffff80101413:	55                   	push   %rbp
ffffffff80101414:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101417:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010141b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010141f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  return memblock_add_regions(&memblock.reserved, base, size);
ffffffff80101423:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80101427:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010142b:	48 89 c6             	mov    %rax,%rsi
ffffffff8010142e:	48 c7 c7 48 30 10 80 	mov    $0xffffffff80103048,%rdi
ffffffff80101435:	e8 a7 fd ff ff       	call   ffffffff801011e1 <memblock_add_regions>
}
ffffffff8010143a:	c9                   	leave  
ffffffff8010143b:	c3                   	ret    

ffffffff8010143c <__next_mem_range_rev>:

void __next_mem_range_rev(u64* idx, struct memblock_type* type_a, struct memblock_type* type_b, u64 *out_start, u64 *out_end){
ffffffff8010143c:	f3 0f 1e fa          	endbr64 
ffffffff80101440:	55                   	push   %rbp
ffffffff80101441:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101444:	48 81 ec 88 00 00 00 	sub    $0x88,%rsp
ffffffff8010144b:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
ffffffff8010144f:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
ffffffff80101453:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
ffffffff80101457:	48 89 4d 80          	mov    %rcx,-0x80(%rbp)
ffffffff8010145b:	4c 89 85 78 ff ff ff 	mov    %r8,-0x88(%rbp)
  int idx_a = *idx & 0xffffffff;
ffffffff80101462:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff80101466:	48 8b 00             	mov    (%rax),%rax
ffffffff80101469:	89 45 fc             	mov    %eax,-0x4(%rbp)
  int idx_b = *idx >> 32;
ffffffff8010146c:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff80101470:	48 8b 00             	mov    (%rax),%rax
ffffffff80101473:	48 c1 e8 20          	shr    $0x20,%rax
ffffffff80101477:	89 45 f8             	mov    %eax,-0x8(%rbp)

  if (*idx == (u64)ULLONG_MAX){
ffffffff8010147a:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff8010147e:	48 8b 00             	mov    (%rax),%rax
ffffffff80101481:	48 83 f8 ff          	cmp    $0xffffffffffffffff,%rax
ffffffff80101485:	0f 85 6d 01 00 00    	jne    ffffffff801015f8 <__next_mem_range_rev+0x1bc>
    idx_a = type_a->cnt-1;
ffffffff8010148b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
ffffffff8010148f:	48 8b 00             	mov    (%rax),%rax
ffffffff80101492:	83 e8 01             	sub    $0x1,%eax
ffffffff80101495:	89 45 fc             	mov    %eax,-0x4(%rbp)
    idx_b = type_b->cnt;
ffffffff80101498:	48 8b 45 88          	mov    -0x78(%rbp),%rax
ffffffff8010149c:	48 8b 00             	mov    (%rax),%rax
ffffffff8010149f:	89 45 f8             	mov    %eax,-0x8(%rbp)
  }

  for(; idx_a >= 0; idx_a--){
ffffffff801014a2:	e9 51 01 00 00       	jmp    ffffffff801015f8 <__next_mem_range_rev+0x1bc>
    struct memblock_region* m = &type_a->regions[idx_a];
ffffffff801014a7:	48 8b 45 90          	mov    -0x70(%rbp),%rax
ffffffff801014ab:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff801014af:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801014b2:	48 98                	cltq   
ffffffff801014b4:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff801014b8:	48 01 d0             	add    %rdx,%rax
ffffffff801014bb:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

    u64 m_start = m->base;
ffffffff801014bf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801014c3:	48 8b 00             	mov    (%rax),%rax
ffffffff801014c6:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    u64 m_end = m->base + m->size;
ffffffff801014ca:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801014ce:	48 8b 10             	mov    (%rax),%rdx
ffffffff801014d1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801014d5:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff801014d9:	48 01 d0             	add    %rdx,%rax
ffffffff801014dc:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

    for(; idx_b >= 0; idx_b--){
ffffffff801014e0:	e9 02 01 00 00       	jmp    ffffffff801015e7 <__next_mem_range_rev+0x1ab>
      struct memblock_region* r;
      u64 r_start;
      u64 r_end;

      r = &type_b->regions[idx_b];
ffffffff801014e5:	48 8b 45 88          	mov    -0x78(%rbp),%rax
ffffffff801014e9:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff801014ed:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801014f0:	48 98                	cltq   
ffffffff801014f2:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff801014f6:	48 01 d0             	add    %rdx,%rax
ffffffff801014f9:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
      r_start = idx_b ? r[-1].base + r[-1].size : 0;
ffffffff801014fd:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff80101501:	74 1c                	je     ffffffff8010151f <__next_mem_range_rev+0xe3>
ffffffff80101503:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101507:	48 83 e8 10          	sub    $0x10,%rax
ffffffff8010150b:	48 8b 10             	mov    (%rax),%rdx
ffffffff8010150e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101512:	48 83 e8 10          	sub    $0x10,%rax
ffffffff80101516:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff8010151a:	48 01 d0             	add    %rdx,%rax
ffffffff8010151d:	eb 05                	jmp    ffffffff80101524 <__next_mem_range_rev+0xe8>
ffffffff8010151f:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101524:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
      r_end = idx_b < type_b->cnt ? r->base : ULLONG_MAX;
ffffffff80101528:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff8010152b:	48 63 d0             	movslq %eax,%rdx
ffffffff8010152e:	48 8b 45 88          	mov    -0x78(%rbp),%rax
ffffffff80101532:	48 8b 00             	mov    (%rax),%rax
ffffffff80101535:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101538:	73 09                	jae    ffffffff80101543 <__next_mem_range_rev+0x107>
ffffffff8010153a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010153e:	48 8b 00             	mov    (%rax),%rax
ffffffff80101541:	eb 07                	jmp    ffffffff8010154a <__next_mem_range_rev+0x10e>
ffffffff80101543:	48 c7 c0 ff ff ff ff 	mov    $0xffffffffffffffff,%rax
ffffffff8010154a:	48 89 45 c8          	mov    %rax,-0x38(%rbp)

      if(r_end <= m_start)
ffffffff8010154e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101552:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80101556:	0f 86 97 00 00 00    	jbe    ffffffff801015f3 <__next_mem_range_rev+0x1b7>
        break;
      if(m_end > r_start){
ffffffff8010155c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101560:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
ffffffff80101564:	76 7d                	jbe    ffffffff801015e3 <__next_mem_range_rev+0x1a7>
        *out_start = max(m_start, r_start);
ffffffff80101566:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010156a:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
ffffffff8010156e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80101572:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
ffffffff80101576:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
ffffffff8010157a:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff8010157e:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101581:	48 0f 42 d0          	cmovb  %rax,%rdx
ffffffff80101585:	48 8b 45 80          	mov    -0x80(%rbp),%rax
ffffffff80101589:	48 89 10             	mov    %rdx,(%rax)
        *out_end = min(m_end, r_end);
ffffffff8010158c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101590:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
ffffffff80101594:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101598:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
ffffffff8010159c:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
ffffffff801015a0:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
ffffffff801015a4:	48 39 c2             	cmp    %rax,%rdx
ffffffff801015a7:	48 0f 47 d0          	cmova  %rax,%rdx
ffffffff801015ab:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
ffffffff801015b2:	48 89 10             	mov    %rdx,(%rax)
        
        if(m_start >= r_start)
ffffffff801015b5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801015b9:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
ffffffff801015bd:	72 06                	jb     ffffffff801015c5 <__next_mem_range_rev+0x189>
          idx_a--;
ffffffff801015bf:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff801015c3:	eb 04                	jmp    ffffffff801015c9 <__next_mem_range_rev+0x18d>
        else
          idx_b--;
ffffffff801015c5:	83 6d f8 01          	subl   $0x1,-0x8(%rbp)
        *idx = (u32)idx_a | (u64)idx_b << 32;
ffffffff801015c9:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801015cc:	89 c2                	mov    %eax,%edx
ffffffff801015ce:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801015d1:	48 98                	cltq   
ffffffff801015d3:	48 c1 e0 20          	shl    $0x20,%rax
ffffffff801015d7:	48 09 c2             	or     %rax,%rdx
ffffffff801015da:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff801015de:	48 89 10             	mov    %rdx,(%rax)
        return;
ffffffff801015e1:	eb 2a                	jmp    ffffffff8010160d <__next_mem_range_rev+0x1d1>
    for(; idx_b >= 0; idx_b--){
ffffffff801015e3:	83 6d f8 01          	subl   $0x1,-0x8(%rbp)
ffffffff801015e7:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff801015eb:	0f 89 f4 fe ff ff    	jns    ffffffff801014e5 <__next_mem_range_rev+0xa9>
ffffffff801015f1:	eb 01                	jmp    ffffffff801015f4 <__next_mem_range_rev+0x1b8>
        break;
ffffffff801015f3:	90                   	nop
  for(; idx_a >= 0; idx_a--){
ffffffff801015f4:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff801015f8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801015fc:	0f 89 a5 fe ff ff    	jns    ffffffff801014a7 <__next_mem_range_rev+0x6b>
      }    
    }
  }
  *idx = ULLONG_MAX;
ffffffff80101602:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff80101606:	48 c7 00 ff ff ff ff 	movq   $0xffffffffffffffff,(%rax)
}
ffffffff8010160d:	c9                   	leave  
ffffffff8010160e:	c3                   	ret    

ffffffff8010160f <__memblock_find_range_top_down>:

u64 __memblock_find_range_top_down(u64 start, u64 end, u64 size, u64 align){
ffffffff8010160f:	f3 0f 1e fa          	endbr64 
ffffffff80101613:	55                   	push   %rbp
ffffffff80101614:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101617:	48 83 c4 80          	add    $0xffffffffffffff80,%rsp
ffffffff8010161b:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
ffffffff8010161f:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
ffffffff80101623:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
ffffffff80101627:	48 89 4d 80          	mov    %rcx,-0x80(%rbp)
  u64 this_start, this_end, cand;
  u64 i;

  for_each_free_mem_range_reserve(i, &this_start, &this_end){
ffffffff8010162b:	48 c7 45 e0 ff ff ff 	movq   $0xffffffffffffffff,-0x20(%rbp)
ffffffff80101632:	ff 
ffffffff80101633:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
ffffffff80101637:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
ffffffff8010163b:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff8010163f:	49 89 c8             	mov    %rcx,%r8
ffffffff80101642:	48 89 d1             	mov    %rdx,%rcx
ffffffff80101645:	48 c7 c2 48 30 10 80 	mov    $0xffffffff80103048,%rdx
ffffffff8010164c:	48 c7 c6 20 30 10 80 	mov    $0xffffffff80103020,%rsi
ffffffff80101653:	48 89 c7             	mov    %rax,%rdi
ffffffff80101656:	e8 e1 fd ff ff       	call   ffffffff8010143c <__next_mem_range_rev>
ffffffff8010165b:	e9 c7 00 00 00       	jmp    ffffffff80101727 <__memblock_find_range_top_down+0x118>
    this_start = clamp(this_start, start, end);
ffffffff80101660:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101664:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
ffffffff80101668:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff8010166c:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
ffffffff80101670:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
ffffffff80101674:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101678:	48 39 c2             	cmp    %rax,%rdx
ffffffff8010167b:	48 0f 43 c2          	cmovae %rdx,%rax
ffffffff8010167f:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
ffffffff80101683:	48 8b 45 90          	mov    -0x70(%rbp),%rax
ffffffff80101687:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
ffffffff8010168b:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff8010168f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101693:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101696:	48 0f 46 c2          	cmovbe %rdx,%rax
ffffffff8010169a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    this_end = clamp(this_end, start, end);
ffffffff8010169e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801016a2:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
ffffffff801016a6:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff801016aa:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
ffffffff801016ae:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
ffffffff801016b2:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff801016b6:	48 39 c2             	cmp    %rax,%rdx
ffffffff801016b9:	48 0f 43 c2          	cmovae %rdx,%rax
ffffffff801016bd:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
ffffffff801016c1:	48 8b 45 90          	mov    -0x70(%rbp),%rax
ffffffff801016c5:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
ffffffff801016c9:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
ffffffff801016cd:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff801016d1:	48 39 c2             	cmp    %rax,%rdx
ffffffff801016d4:	48 0f 46 c2          	cmovbe %rdx,%rax
ffffffff801016d8:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

    // The data is unsigned, so need to judge
    if(this_end < size)
ffffffff801016dc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801016e0:	48 39 45 88          	cmp    %rax,-0x78(%rbp)
ffffffff801016e4:	77 18                	ja     ffffffff801016fe <__memblock_find_range_top_down+0xef>
      continue;

    //cand = round_down(this_end - size, align);
    cand = 1;
ffffffff801016e6:	48 c7 45 f8 01 00 00 	movq   $0x1,-0x8(%rbp)
ffffffff801016ed:	00 
    if(cand >= this_start)
ffffffff801016ee:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801016f2:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
ffffffff801016f6:	72 07                	jb     ffffffff801016ff <__memblock_find_range_top_down+0xf0>
      return cand;
ffffffff801016f8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801016fc:	eb 3c                	jmp    ffffffff8010173a <__memblock_find_range_top_down+0x12b>
      continue;
ffffffff801016fe:	90                   	nop
  for_each_free_mem_range_reserve(i, &this_start, &this_end){
ffffffff801016ff:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
ffffffff80101703:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
ffffffff80101707:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff8010170b:	49 89 c8             	mov    %rcx,%r8
ffffffff8010170e:	48 89 d1             	mov    %rdx,%rcx
ffffffff80101711:	48 c7 c2 48 30 10 80 	mov    $0xffffffff80103048,%rdx
ffffffff80101718:	48 c7 c6 20 30 10 80 	mov    $0xffffffff80103020,%rsi
ffffffff8010171f:	48 89 c7             	mov    %rax,%rdi
ffffffff80101722:	e8 15 fd ff ff       	call   ffffffff8010143c <__next_mem_range_rev>
ffffffff80101727:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010172b:	48 83 f8 ff          	cmp    $0xffffffffffffffff,%rax
ffffffff8010172f:	0f 85 2b ff ff ff    	jne    ffffffff80101660 <__memblock_find_range_top_down+0x51>
  }

  return 0;       
ffffffff80101735:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010173a:	c9                   	leave  
ffffffff8010173b:	c3                   	ret    

ffffffff8010173c <memblock_find_in_range>:

u64 memblock_find_in_range(u64 size, u64 align, u64 start, u64 end){
ffffffff8010173c:	f3 0f 1e fa          	endbr64 
ffffffff80101740:	55                   	push   %rbp
ffffffff80101741:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101744:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80101748:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff8010174c:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff80101750:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
ffffffff80101754:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
  start = max(start, PGSIZE);
ffffffff80101758:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff8010175c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80101760:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%rbp)
ffffffff80101767:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff8010176a:	48 63 d0             	movslq %eax,%rdx
ffffffff8010176d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101771:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101774:	48 0f 43 c2          	cmovae %rdx,%rax
ffffffff80101778:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
  end = max(start, end);
ffffffff8010177c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101780:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80101784:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101788:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
ffffffff8010178c:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80101790:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101794:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101797:	48 0f 43 c2          	cmovae %rdx,%rax
ffffffff8010179b:	48 89 45 c0          	mov    %rax,-0x40(%rbp)

  return __memblock_find_range_top_down(start, end, size, align);
ffffffff8010179f:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
ffffffff801017a3:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff801017a7:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
ffffffff801017ab:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801017af:	48 89 c7             	mov    %rax,%rdi
ffffffff801017b2:	e8 58 fe ff ff       	call   ffffffff8010160f <__memblock_find_range_top_down>
}
ffffffff801017b7:	c9                   	leave  
ffffffff801017b8:	c3                   	ret    

ffffffff801017b9 <memblock_alloc_range>:

static u64 memblock_alloc_range(u64 size, u64 align, u64 start, u64 end){
ffffffff801017b9:	f3 0f 1e fa          	endbr64 
ffffffff801017bd:	55                   	push   %rbp
ffffffff801017be:	48 89 e5             	mov    %rsp,%rbp
ffffffff801017c1:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff801017c5:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff801017c9:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff801017cd:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
ffffffff801017d1:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  u64 found;

  found = memblock_find_in_range(size, align, start, end);
ffffffff801017d5:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
ffffffff801017d9:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff801017dd:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
ffffffff801017e1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801017e5:	48 89 c7             	mov    %rax,%rdi
ffffffff801017e8:	e8 4f ff ff ff       	call   ffffffff8010173c <memblock_find_in_range>
ffffffff801017ed:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(found && !memblock_reserve(found,size)){
ffffffff801017f1:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff801017f6:	74 1d                	je     ffffffff80101815 <memblock_alloc_range+0x5c>
ffffffff801017f8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff801017fc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101800:	48 89 d6             	mov    %rdx,%rsi
ffffffff80101803:	48 89 c7             	mov    %rax,%rdi
ffffffff80101806:	e8 04 fc ff ff       	call   ffffffff8010140f <memblock_reserve>
ffffffff8010180b:	85 c0                	test   %eax,%eax
ffffffff8010180d:	75 06                	jne    ffffffff80101815 <memblock_alloc_range+0x5c>
    //kmemleak_alloc_phys(found, size, 0, 0);
    return found;
ffffffff8010180f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101813:	eb 05                	jmp    ffffffff8010181a <memblock_alloc_range+0x61>
  }
  return 0;
ffffffff80101815:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010181a:	c9                   	leave  
ffffffff8010181b:	c3                   	ret    

ffffffff8010181c <__memblock_alloc_base>:

u64 __memblock_alloc_base(u64 size, u64 align, u64 max_addr){
ffffffff8010181c:	f3 0f 1e fa          	endbr64 
ffffffff80101820:	55                   	push   %rbp
ffffffff80101821:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101824:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80101828:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010182c:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
ffffffff80101830:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  return memblock_alloc_range(size, align, 0, max_addr);
ffffffff80101834:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80101838:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
ffffffff8010183c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101840:	48 89 d1             	mov    %rdx,%rcx
ffffffff80101843:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80101848:	48 89 c7             	mov    %rax,%rdi
ffffffff8010184b:	e8 69 ff ff ff       	call   ffffffff801017b9 <memblock_alloc_range>
}
ffffffff80101850:	c9                   	leave  
ffffffff80101851:	c3                   	ret    

ffffffff80101852 <memblock_alloc_base>:

u64 memblock_alloc_base(u64 size, u64 align, u64 max_addr){
ffffffff80101852:	f3 0f 1e fa          	endbr64 
ffffffff80101856:	55                   	push   %rbp
ffffffff80101857:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010185a:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff8010185e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80101862:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80101866:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  u64 alloc;

  alloc = __memblock_alloc_base(size, align, max_addr);
ffffffff8010186a:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff8010186e:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
ffffffff80101872:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101876:	48 89 ce             	mov    %rcx,%rsi
ffffffff80101879:	48 89 c7             	mov    %rax,%rdi
ffffffff8010187c:	e8 9b ff ff ff       	call   ffffffff8010181c <__memblock_alloc_base>
ffffffff80101881:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

  if (alloc == 0)
ffffffff80101885:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff8010188a:	75 06                	jne    ffffffff80101892 <memblock_alloc_base+0x40>
    //panic();
  return alloc;
ffffffff8010188c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101890:	eb 00                	jmp    ffffffff80101892 <memblock_alloc_base+0x40>
}
ffffffff80101892:	c9                   	leave  
ffffffff80101893:	c3                   	ret    

ffffffff80101894 <memblock_alloc>:

u64 memblock_alloc(u64 size, u64 align){
ffffffff80101894:	f3 0f 1e fa          	endbr64 
ffffffff80101898:	55                   	push   %rbp
ffffffff80101899:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010189c:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff801018a0:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff801018a4:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  return memblock_alloc_base(size, align, MEMBLOCK_ALLOC_ACCESSIBLE);
ffffffff801018a8:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff801018ac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801018b0:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff801018b5:	48 89 ce             	mov    %rcx,%rsi
ffffffff801018b8:	48 89 c7             	mov    %rax,%rdi
ffffffff801018bb:	e8 92 ff ff ff       	call   ffffffff80101852 <memblock_alloc_base>
}
ffffffff801018c0:	c9                   	leave  
ffffffff801018c1:	c3                   	ret    

ffffffff801018c2 <memblock_isolate_range>:

int memblock_isolate_range(struct memblock_type* type, u64 base, u64 size, int *start_rgn, int *end_rgn){
ffffffff801018c2:	f3 0f 1e fa          	endbr64 
ffffffff801018c6:	55                   	push   %rbp
ffffffff801018c7:	48 89 e5             	mov    %rsp,%rbp
ffffffff801018ca:	48 83 ec 60          	sub    $0x60,%rsp
ffffffff801018ce:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
ffffffff801018d2:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
ffffffff801018d6:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
ffffffff801018da:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
ffffffff801018de:	4c 89 45 a8          	mov    %r8,-0x58(%rbp)
  u64 end = base + size;
ffffffff801018e2:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
ffffffff801018e6:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff801018ea:	48 01 d0             	add    %rdx,%rax
ffffffff801018ed:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  int idx;
  struct memblock_region* rgn;

  *start_rgn = *end_rgn = 0;
ffffffff801018f1:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff801018f5:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffffffff801018fb:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff801018ff:	8b 10                	mov    (%rax),%edx
ffffffff80101901:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
ffffffff80101905:	89 10                	mov    %edx,(%rax)

  if(!size)
ffffffff80101907:	48 83 7d b8 00       	cmpq   $0x0,-0x48(%rbp)
ffffffff8010190c:	75 0a                	jne    ffffffff80101918 <memblock_isolate_range+0x56>
    return 0;
ffffffff8010190e:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101913:	e9 87 01 00 00       	jmp    ffffffff80101a9f <memblock_isolate_range+0x1dd>

  for_each_memblock_type(idx, type, rgn){
ffffffff80101918:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010191f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101923:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80101927:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff8010192b:	e9 56 01 00 00       	jmp    ffffffff80101a86 <memblock_isolate_range+0x1c4>

    u64 rbase = rgn->base;
ffffffff80101930:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101934:	48 8b 00             	mov    (%rax),%rax
ffffffff80101937:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    u64 rend = rbase + rgn->size;
ffffffff8010193b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010193f:	48 8b 50 08          	mov    0x8(%rax),%rdx
ffffffff80101943:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101947:	48 01 d0             	add    %rdx,%rax
ffffffff8010194a:	48 89 45 d8          	mov    %rax,-0x28(%rbp)

    if(rbase >= end)
ffffffff8010194e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101952:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80101956:	0f 83 42 01 00 00    	jae    ffffffff80101a9e <memblock_isolate_range+0x1dc>
      break;
    if(rend <= base)
ffffffff8010195c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101960:	48 3b 45 c0          	cmp    -0x40(%rbp),%rax
ffffffff80101964:	0f 86 ff 00 00 00    	jbe    ffffffff80101a69 <memblock_isolate_range+0x1a7>
      continue;

    if (rbase < base){
ffffffff8010196a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010196e:	48 3b 45 c0          	cmp    -0x40(%rbp),%rax
ffffffff80101972:	73 64                	jae    ffffffff801019d8 <memblock_isolate_range+0x116>
			rgn->base = base;
ffffffff80101974:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101978:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
ffffffff8010197c:	48 89 10             	mov    %rdx,(%rax)
			rgn->size -= base - rbase;
ffffffff8010197f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101983:	48 8b 50 08          	mov    0x8(%rax),%rdx
ffffffff80101987:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010198b:	48 2b 45 c0          	sub    -0x40(%rbp),%rax
ffffffff8010198f:	48 01 c2             	add    %rax,%rdx
ffffffff80101992:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101996:	48 89 50 08          	mov    %rdx,0x8(%rax)
			type->total_size -= base - rbase;
ffffffff8010199a:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff8010199e:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffffffff801019a2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801019a6:	48 2b 45 c0          	sub    -0x40(%rbp),%rax
ffffffff801019aa:	48 01 c2             	add    %rax,%rdx
ffffffff801019ad:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801019b1:	48 89 50 10          	mov    %rdx,0x10(%rax)
			memblock_insert_region(type, idx, rbase, base - rbase);
ffffffff801019b5:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff801019b9:	48 2b 45 e0          	sub    -0x20(%rbp),%rax
ffffffff801019bd:	48 89 c1             	mov    %rax,%rcx
ffffffff801019c0:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff801019c4:	8b 75 fc             	mov    -0x4(%rbp),%esi
ffffffff801019c7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801019cb:	48 89 c7             	mov    %rax,%rdi
ffffffff801019ce:	e8 bf f5 ff ff       	call   ffffffff80100f92 <memblock_insert_region>
ffffffff801019d3:	e9 92 00 00 00       	jmp    ffffffff80101a6a <memblock_isolate_range+0x1a8>
		} 
    else if(rend > end){
ffffffff801019d8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801019dc:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff801019e0:	76 66                	jbe    ffffffff80101a48 <memblock_isolate_range+0x186>
			rgn->base = end;
ffffffff801019e2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801019e6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff801019ea:	48 89 10             	mov    %rdx,(%rax)
			rgn->size -= end - rbase;
ffffffff801019ed:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801019f1:	48 8b 50 08          	mov    0x8(%rax),%rdx
ffffffff801019f5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801019f9:	48 2b 45 e8          	sub    -0x18(%rbp),%rax
ffffffff801019fd:	48 01 c2             	add    %rax,%rdx
ffffffff80101a00:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101a04:	48 89 50 08          	mov    %rdx,0x8(%rax)
			type->total_size -= end - rbase;
ffffffff80101a08:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101a0c:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffffffff80101a10:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101a14:	48 2b 45 e8          	sub    -0x18(%rbp),%rax
ffffffff80101a18:	48 01 c2             	add    %rax,%rdx
ffffffff80101a1b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101a1f:	48 89 50 10          	mov    %rdx,0x10(%rax)
			memblock_insert_region(type, idx--, rbase, end - rbase);
ffffffff80101a23:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101a27:	48 2b 45 e0          	sub    -0x20(%rbp),%rax
ffffffff80101a2b:	48 89 c1             	mov    %rax,%rcx
ffffffff80101a2e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101a31:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80101a34:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff80101a37:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80101a3b:	48 8b 7d c8          	mov    -0x38(%rbp),%rdi
ffffffff80101a3f:	89 c6                	mov    %eax,%esi
ffffffff80101a41:	e8 4c f5 ff ff       	call   ffffffff80100f92 <memblock_insert_region>
ffffffff80101a46:	eb 22                	jmp    ffffffff80101a6a <memblock_isolate_range+0x1a8>
		} else{
			if (!*end_rgn)
ffffffff80101a48:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff80101a4c:	8b 00                	mov    (%rax),%eax
ffffffff80101a4e:	85 c0                	test   %eax,%eax
ffffffff80101a50:	75 09                	jne    ffffffff80101a5b <memblock_isolate_range+0x199>
				*start_rgn = idx;
ffffffff80101a52:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
ffffffff80101a56:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80101a59:	89 10                	mov    %edx,(%rax)
			*end_rgn = idx + 1;
ffffffff80101a5b:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101a5e:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80101a61:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
ffffffff80101a65:	89 10                	mov    %edx,(%rax)
ffffffff80101a67:	eb 01                	jmp    ffffffff80101a6a <memblock_isolate_range+0x1a8>
      continue;
ffffffff80101a69:	90                   	nop
  for_each_memblock_type(idx, type, rgn){
ffffffff80101a6a:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80101a6e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101a72:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff80101a76:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101a79:	48 98                	cltq   
ffffffff80101a7b:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80101a7f:	48 01 d0             	add    %rdx,%rax
ffffffff80101a82:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80101a86:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101a89:	48 63 d0             	movslq %eax,%rdx
ffffffff80101a8c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101a90:	48 8b 00             	mov    (%rax),%rax
ffffffff80101a93:	48 39 c2             	cmp    %rax,%rdx
ffffffff80101a96:	0f 82 94 fe ff ff    	jb     ffffffff80101930 <memblock_isolate_range+0x6e>
ffffffff80101a9c:	eb 01                	jmp    ffffffff80101a9f <memblock_isolate_range+0x1dd>
      break;
ffffffff80101a9e:	90                   	nop
		}
  }
}
ffffffff80101a9f:	c9                   	leave  
ffffffff80101aa0:	c3                   	ret    

ffffffff80101aa1 <memblock_remove_range>:

int memblock_remove_range(struct memblock_type* type, u64 base, u64 size){
ffffffff80101aa1:	f3 0f 1e fa          	endbr64 
ffffffff80101aa5:	55                   	push   %rbp
ffffffff80101aa6:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101aa9:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80101aad:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80101ab1:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80101ab5:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  int start_rgn, end_rgn;
  int i,ret;

  ret = memblock_isolate_range(type, base, size, &start_rgn, &end_rgn);
ffffffff80101ab9:	48 8d 7d f0          	lea    -0x10(%rbp),%rdi
ffffffff80101abd:	48 8d 4d f4          	lea    -0xc(%rbp),%rcx
ffffffff80101ac1:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80101ac5:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
ffffffff80101ac9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101acd:	49 89 f8             	mov    %rdi,%r8
ffffffff80101ad0:	48 89 c7             	mov    %rax,%rdi
ffffffff80101ad3:	e8 ea fd ff ff       	call   ffffffff801018c2 <memblock_isolate_range>
ffffffff80101ad8:	89 45 f8             	mov    %eax,-0x8(%rbp)
  if(ret)
ffffffff80101adb:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff80101adf:	74 05                	je     ffffffff80101ae6 <memblock_remove_range+0x45>
    return ret;
ffffffff80101ae1:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101ae4:	eb 2c                	jmp    ffffffff80101b12 <memblock_remove_range+0x71>

  for(i = end_rgn - 1; i >= start_rgn; i--)
ffffffff80101ae6:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80101ae9:	83 e8 01             	sub    $0x1,%eax
ffffffff80101aec:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80101aef:	eb 19                	jmp    ffffffff80101b0a <memblock_remove_range+0x69>
    memblock_remove_region(type, i);
ffffffff80101af1:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101af4:	48 63 d0             	movslq %eax,%rdx
ffffffff80101af7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101afb:	48 89 d6             	mov    %rdx,%rsi
ffffffff80101afe:	48 89 c7             	mov    %rax,%rdi
ffffffff80101b01:	e8 07 f6 ff ff       	call   ffffffff8010110d <memblock_remove_region>
  for(i = end_rgn - 1; i >= start_rgn; i--)
ffffffff80101b06:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff80101b0a:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80101b0d:	39 45 fc             	cmp    %eax,-0x4(%rbp)
ffffffff80101b10:	7d df                	jge    ffffffff80101af1 <memblock_remove_range+0x50>
}
ffffffff80101b12:	c9                   	leave  
ffffffff80101b13:	c3                   	ret    

ffffffff80101b14 <memblock_free>:

int memblock_free(u64 base, u64 size){
ffffffff80101b14:	f3 0f 1e fa          	endbr64 
ffffffff80101b18:	55                   	push   %rbp
ffffffff80101b19:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101b1c:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80101b20:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80101b24:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  u64 end = base + size -1;
ffffffff80101b28:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80101b2c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101b30:	48 01 d0             	add    %rdx,%rax
ffffffff80101b33:	48 83 e8 01          	sub    $0x1,%rax
ffffffff80101b37:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

  //kmemleak_free_part_phys(base, size);
  return memblock_remove_range(&memblock.reserved, base, size);
ffffffff80101b3b:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80101b3f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101b43:	48 89 c6             	mov    %rax,%rsi
ffffffff80101b46:	48 c7 c7 48 30 10 80 	mov    $0xffffffff80103048,%rdi
ffffffff80101b4d:	e8 4f ff ff ff       	call   ffffffff80101aa1 <memblock_remove_range>
}
ffffffff80101b52:	c9                   	leave  
ffffffff80101b53:	c3                   	ret    

ffffffff80101b54 <memblock_init>:

void memblock_init(){
ffffffff80101b54:	f3 0f 1e fa          	endbr64 
ffffffff80101b58:	55                   	push   %rbp
ffffffff80101b59:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101b5c:	48 83 ec 10          	sub    $0x10,%rsp
  struct MEMORY_E820* ARDS = (struct MEMORY_E820*)(KERNBASE+ARDSOFFSET);
ffffffff80101b60:	48 c7 45 f0 00 80 00 	movq   $0xffffffff80008000,-0x10(%rbp)
ffffffff80101b67:	80 
  u32 mem_tot = 0;
ffffffff80101b68:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  for(int i=0; i < 32; i++){
ffffffff80101b6f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
ffffffff80101b76:	e9 82 01 00 00       	jmp    ffffffff80101cfd <memblock_init+0x1a9>
    if(ARDS->map[i].type < 1 || ARDS->map[i].type > 4) break;
ffffffff80101b7b:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80101b7f:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101b82:	48 63 d0             	movslq %eax,%rdx
ffffffff80101b85:	48 89 d0             	mov    %rdx,%rax
ffffffff80101b88:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101b8c:	48 01 d0             	add    %rdx,%rax
ffffffff80101b8f:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101b93:	48 01 c8             	add    %rcx,%rax
ffffffff80101b96:	48 83 c0 14          	add    $0x14,%rax
ffffffff80101b9a:	8b 00                	mov    (%rax),%eax
ffffffff80101b9c:	85 c0                	test   %eax,%eax
ffffffff80101b9e:	0f 84 63 01 00 00    	je     ffffffff80101d07 <memblock_init+0x1b3>
ffffffff80101ba4:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80101ba8:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101bab:	48 63 d0             	movslq %eax,%rdx
ffffffff80101bae:	48 89 d0             	mov    %rdx,%rax
ffffffff80101bb1:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101bb5:	48 01 d0             	add    %rdx,%rax
ffffffff80101bb8:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101bbc:	48 01 c8             	add    %rcx,%rax
ffffffff80101bbf:	48 83 c0 14          	add    $0x14,%rax
ffffffff80101bc3:	8b 00                	mov    (%rax),%eax
ffffffff80101bc5:	83 f8 04             	cmp    $0x4,%eax
ffffffff80101bc8:	0f 87 39 01 00 00    	ja     ffffffff80101d07 <memblock_init+0x1b3>
    mem_tot += ARDS->map[i].len;
ffffffff80101bce:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80101bd2:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101bd5:	48 63 d0             	movslq %eax,%rdx
ffffffff80101bd8:	48 89 d0             	mov    %rdx,%rax
ffffffff80101bdb:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101bdf:	48 01 d0             	add    %rdx,%rax
ffffffff80101be2:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101be6:	48 01 c8             	add    %rcx,%rax
ffffffff80101be9:	48 8b 40 0c          	mov    0xc(%rax),%rax
ffffffff80101bed:	01 45 fc             	add    %eax,-0x4(%rbp)
    cprintf("%l %l %x\n", ARDS->map[i].addr, ARDS->map[i].addr+ARDS->map[i].len, ARDS->map[i].type);
ffffffff80101bf0:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80101bf4:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101bf7:	48 63 d0             	movslq %eax,%rdx
ffffffff80101bfa:	48 89 d0             	mov    %rdx,%rax
ffffffff80101bfd:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c01:	48 01 d0             	add    %rdx,%rax
ffffffff80101c04:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c08:	48 01 c8             	add    %rcx,%rax
ffffffff80101c0b:	48 83 c0 14          	add    $0x14,%rax
ffffffff80101c0f:	8b 10                	mov    (%rax),%edx
ffffffff80101c11:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
ffffffff80101c15:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101c18:	48 63 c8             	movslq %eax,%rcx
ffffffff80101c1b:	48 89 c8             	mov    %rcx,%rax
ffffffff80101c1e:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c22:	48 01 c8             	add    %rcx,%rax
ffffffff80101c25:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c29:	48 01 f0             	add    %rsi,%rax
ffffffff80101c2c:	48 8b 70 04          	mov    0x4(%rax),%rsi
ffffffff80101c30:	48 8b 7d f0          	mov    -0x10(%rbp),%rdi
ffffffff80101c34:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101c37:	48 63 c8             	movslq %eax,%rcx
ffffffff80101c3a:	48 89 c8             	mov    %rcx,%rax
ffffffff80101c3d:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c41:	48 01 c8             	add    %rcx,%rax
ffffffff80101c44:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c48:	48 01 f8             	add    %rdi,%rax
ffffffff80101c4b:	48 8b 40 0c          	mov    0xc(%rax),%rax
ffffffff80101c4f:	48 01 c6             	add    %rax,%rsi
ffffffff80101c52:	48 8b 7d f0          	mov    -0x10(%rbp),%rdi
ffffffff80101c56:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101c59:	48 63 c8             	movslq %eax,%rcx
ffffffff80101c5c:	48 89 c8             	mov    %rcx,%rax
ffffffff80101c5f:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c63:	48 01 c8             	add    %rcx,%rax
ffffffff80101c66:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c6a:	48 01 f8             	add    %rdi,%rax
ffffffff80101c6d:	48 8b 40 04          	mov    0x4(%rax),%rax
ffffffff80101c71:	89 d1                	mov    %edx,%ecx
ffffffff80101c73:	48 89 f2             	mov    %rsi,%rdx
ffffffff80101c76:	48 89 c6             	mov    %rax,%rsi
ffffffff80101c79:	48 c7 c7 eb 1d 10 80 	mov    $0xffffffff80101deb,%rdi
ffffffff80101c80:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101c85:	e8 ac e6 ff ff       	call   ffffffff80100336 <cprintf>
    if(ARDS->map[i].type == 1){
ffffffff80101c8a:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80101c8e:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101c91:	48 63 d0             	movslq %eax,%rdx
ffffffff80101c94:	48 89 d0             	mov    %rdx,%rax
ffffffff80101c97:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101c9b:	48 01 d0             	add    %rdx,%rax
ffffffff80101c9e:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101ca2:	48 01 c8             	add    %rcx,%rax
ffffffff80101ca5:	48 83 c0 14          	add    $0x14,%rax
ffffffff80101ca9:	8b 00                	mov    (%rax),%eax
ffffffff80101cab:	83 f8 01             	cmp    $0x1,%eax
ffffffff80101cae:	75 49                	jne    ffffffff80101cf9 <memblock_init+0x1a5>
      memblock_add(ARDS->map[i].addr, ARDS->map[i].len);
ffffffff80101cb0:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80101cb4:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101cb7:	48 63 d0             	movslq %eax,%rdx
ffffffff80101cba:	48 89 d0             	mov    %rdx,%rax
ffffffff80101cbd:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101cc1:	48 01 d0             	add    %rdx,%rax
ffffffff80101cc4:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101cc8:	48 01 c8             	add    %rcx,%rax
ffffffff80101ccb:	48 8b 50 0c          	mov    0xc(%rax),%rdx
ffffffff80101ccf:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
ffffffff80101cd3:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80101cd6:	48 63 c8             	movslq %eax,%rcx
ffffffff80101cd9:	48 89 c8             	mov    %rcx,%rax
ffffffff80101cdc:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101ce0:	48 01 c8             	add    %rcx,%rax
ffffffff80101ce3:	48 c1 e0 02          	shl    $0x2,%rax
ffffffff80101ce7:	48 01 f0             	add    %rsi,%rax
ffffffff80101cea:	48 8b 40 04          	mov    0x4(%rax),%rax
ffffffff80101cee:	48 89 d6             	mov    %rdx,%rsi
ffffffff80101cf1:	48 89 c7             	mov    %rax,%rdi
ffffffff80101cf4:	e8 e9 f6 ff ff       	call   ffffffff801013e2 <memblock_add>
  for(int i=0; i < 32; i++){
ffffffff80101cf9:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
ffffffff80101cfd:	83 7d f8 1f          	cmpl   $0x1f,-0x8(%rbp)
ffffffff80101d01:	0f 8e 74 fe ff ff    	jle    ffffffff80101b7b <memblock_init+0x27>
      //cprintf("%x %x\n", ARDS->map[i].addr, ARDS->map[i].len);
    }
  }
  cprintf("%dMB\n",mem_tot/1048576 + 1);
ffffffff80101d07:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80101d0a:	c1 e8 14             	shr    $0x14,%eax
ffffffff80101d0d:	83 c0 01             	add    $0x1,%eax
ffffffff80101d10:	89 c6                	mov    %eax,%esi
ffffffff80101d12:	48 c7 c7 f5 1d 10 80 	mov    $0xffffffff80101df5,%rdi
ffffffff80101d19:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101d1e:	e8 13 e6 ff ff       	call   ffffffff80100336 <cprintf>
}
ffffffff80101d23:	90                   	nop
ffffffff80101d24:	c9                   	leave  
ffffffff80101d25:	c3                   	ret    
