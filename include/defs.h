struct list_head;
struct proc;
u64 kernelHasMappedEnd;
u64 kernelSize;

// console.c
void            cprintf(char* fmt, ...);
void            panic(char* s);

// loadplugin.c
int load_plugin(char*** argv);

// memblock.c

void            memblock_init(void);
u64             memblock_alloc(u64 size, u64 align);
u64             memblock_alloc_kernel(u64 size, u64 align);

// proc.c
//void            test(void);

// string.c
int             memcmp(const void*, const void*, u32);
void* memmove(void*, const void*, u32);
void* memset(void*, int, u32);
char* safestrcpy(char*, const char*, int);
int             strlen(const char*);
int             strncmp(const char*, const char*, u32);
char* strncpy(char*, const char*, int);

// vm.c
void vm_init(void);
int alloc_uvm(u64* pml4, u64 oldSize, u64 newSize);
u64* setup_user_memory_pages(void);
int copy_uvm(u64* pml4, u64 va, void* dst, u64 len);
void clear_pteu(u64* pml4, char* va);