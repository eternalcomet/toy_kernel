enum procstate { UNUSED, EMBRYO, SLEEPING, RUNNING, ZOMBIE };

extern __thread struct proc* proc;
struct proc {
  u64 size;
  u64* pml4;
  u8* kstack;
  enum procstate state;
  volatile int pid;
  struct proc* parent;
  struct trapframe* tf;
  struct context* context;
  int killed;
  char name[16];
};

