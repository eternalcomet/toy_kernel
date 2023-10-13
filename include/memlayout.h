
#define EXTMEM  0x100000            // Start of extended memory

#define KERNBASE      0xFFFFFFFF80000000         // First kernel address
#define DEVBASE       0xFFFFFFFF40000000 // First device virtual address
#define ARDSOFFSET    0x8000                     // ARDS offset

#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline u64 v2p(void *a) { return ((u64) (a)) - ((u64)KERNBASE); }
static inline void *p2v(u64 a) { return (void *) ((a) + ((u64)KERNBASE)); }

#endif

#define V2P(a) (((uintp) (a)) - KERNBASE)
#define P2V(a) (((void *) (a)) + KERNBASE)
#define IO2V(a) (((void *) (a)) + DEVBASE - DEVSPACE)

#define V2P_WO(x) ((x) - KERNBASE)    // same as V2P, but without casts
#define P2V_WO(x) ((x) + KERNBASE)    // same as V2P, but without casts
