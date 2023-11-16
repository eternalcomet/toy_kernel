// Format of an ELF executable file
#include <types.h>

#define ELF_MAGIC 0x7F454C46U  // "\x7FELF" in little endian

// File header
typedef struct _ElfHdr {
  u32 magic;  // must equal ELF_MAGIC
  u8 elf[12];
  u16 type;
  u16 machine;
  u32 version;
  u64 entry;
  u64 phoff;
  u64 shoff;
  u32 flags;
  u16 ehsize;
  u16 phentsize;
  u16 phnum;
  u16 shentsize;
  u16 shnum;
  u16 shstrndx;
}ElfHdr;

// Program section header
#if X64
struct ProgHdr {
  u32 type;
  u32 flags;
  u64 off;
  u64 vaddr;
  u64 paddr;
  u64 filesz;
  u64 memsz;
  u64 align;
};
#else
typedef struct _ProgHdr {
  u32 type;
  u32 off;
  u32 vaddr;
  u32 paddr;
  u32 filesz;
  u32 memsz;
  u32 flags;
  u32 align;
}ProgHdr;
#endif

// Values for Proghdr type
#define ELF_PROG_LOAD           1

// Flag bits for Proghdr flags
#define ELF_PROG_FLAG_EXEC      1
#define ELF_PROG_FLAG_WRITE     2
#define ELF_PROG_FLAG_READ      4
