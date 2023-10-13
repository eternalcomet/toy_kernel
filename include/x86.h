// Routines to let C code use special x86 instructions.

static inline u8
inb(u16 port)
{
  u8 data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
  return data;
}

static inline void
insl(int port, void *addr, int cnt)
{
  asm volatile("cld; rep insl" :
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}

static inline void
outb(u16 port, u8 data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outw(u16 port, u16 data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
  asm volatile("cld; rep outsl" :
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}

static inline void
stosl(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosl" :
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
  volatile u16 pd[5];

  pd[0] = size-1;
  pd[1] = (u64)p;
  pd[2] = (u64)p >> 16;
  pd[3] = (u64)p >> 32;
  pd[4] = (u64)p >> 48;
  asm volatile("lgdt (%0)" : : "r" (pd));
}

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
  volatile u16 pd[5];

  pd[0] = size-1;
  pd[1] = (u64)p;
  pd[2] = (u64)p >> 16;
  pd[3] = (u64)p >> 32;
  pd[4] = (u64)p >> 48;
}

static inline void
ltr(u16 sel)
{
  asm volatile("ltr %0" : : "r" (sel));
}

static inline u64
readeflags(void)
{
  u64 eflags;
  asm volatile("pushf; pop %0" : "=r" (eflags));
  return eflags;
}

static inline void
loadgs(u16 v)
{
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
  asm volatile("cli");
}

static inline void
sti(void)
{
  asm volatile("sti");
}

static inline void
hlt(void)
{
  asm volatile("hlt");
}

static inline u32
xchg(volatile u32 *addr, u64 newval)
{
  u64 result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgq %0, %1" :
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
}

static inline u64
rcr2(void)
{
  u64 val;
  asm volatile("mov %%cr2,%0" : "=r" (val));
  return val;
}

static inline void
lcr3(u64 val) 
{
  asm volatile("mov %0,%%cr3" : : "r" (val));
}

//PAGEBREAK: 36
// Layout of the trap frame built on the stack by the
// hardware and by trapasm.S, and passed to trap().
// lie about some register names in 64bit mode to avoid
// clunky ifdefs in proc.c and trap.c.
struct trapframe {
  u64 eax;      // rax
  u64 rbx;
  u64 rcx;
  u64 rdx;
  u64 rbp;
  u64 rsi;
  u64 rdi;
  u64 r8;
  u64 r9;
  u64 r10;
  u64 r11;
  u64 r12;
  u64 r13;
  u64 r14;
  u64 r15;

  u64 trapno;
  u64 err;

  u64 rip;     // rip
  u64 cs;
  u64 eflags;  // rflags
  u64 rsp;     // rsp
  u64 ds;      // ss
};
