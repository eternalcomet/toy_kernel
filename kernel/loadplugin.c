#include <types.h>
#include <elf.h>
#include <param.h>
#include <x86.h>
#include <defs.h>
#include <mmu.h>
#include <proc.h>

u32 pluginSector;

#define pluginStartSection 15
#define pluginNum 2
#define SECTSIZE 512
#define MAXPLUGINS 25

void load_plugin_init() {
    pluginSector = pluginStartSection;
}

void wait_disk(void) {
    // Wait for disk ready.
    while ((inb(0x1F7) & 0xC0) != 0x40)
        ;
}

// Read a single sector at offset into dst.
void read_sect(void* dst, u32 offset) {
    // Issue command.
    waitdisk();
    outb(0x1F2, 1);   // count = 1
    outb(0x1F3, offset);
    outb(0x1F4, offset >> 8);
    outb(0x1F5, offset >> 16);
    outb(0x1F6, (offset >> 24) | 0xE0);
    outb(0x1F7, 0x20);  // cmd 0x20 - read sectors

    // Read data.
    waitdisk();
    insl(0x1F0, dst, SECTSIZE / 4);
}

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked.
void
read_seg(u8* pa, u32 count, u32 offset) {
    u8* epa;

    epa = pa + count;

    // Round down to sector boundary.
    pa -= offset % SECTSIZE;

    // Translate from bytes to sectors; kernel starts at sector 1.
    offset = (offset / SECTSIZE) + 1;

    // If this is too slow, we could read lots of sectors at a time.
    // We'd write more to memory than asked, but it doesn't matter --
    // we load in increasing order.
    for (; pa < epa; pa += SECTSIZE, offset++)
        read_sect(pa, offset);
}

int load_plugin(char*** argv) {

    load_plugin_init();
    ElfHdr elf;
    // ??? 3+MAXARG+1
    u64 argc, uStack[3 + MAXARG + 1];
    u32* pluginElf;
    ProgHdr progHdr;
    int cnt, off;
    u64 size, stackPoint;
    u64 argc;

    for (int i = 0;i < pluginNum;++i) {
        size = 0;

        // Get ElfHdr
        read_seg((u8*)pluginElf, 512, pluginSector);
        elf = *(ElfHdr*)(pluginElf);

        // setup kvm
        u64* pml4 = setup_user_memory_pages();

        // Load program into memory.
        read_seg((u8*)pluginElf, (elf.phoff + elf.phnum * sizeof(progHdr)), pluginSector);
        for (cnt = 0, off = elf.phoff; cnt < elf.phnum;i++, off += sizeof(progHdr)) {
            progHdr = *(ProgHdr*)(pluginElf + off / 4);
            if (progHdr.type != ELF_PROG_LOAD)
                continue;

            size = alloc_uvm(pml4, size, progHdr.vaddr + progHdr.memsz);

            // copy_uvm
            copy_uvm(pml4, progHdr.vaddr, pluginElf + progHdr.off, progHdr.memsz);

        }
        size = PGROUNDUP(size);
        size = alloc_uvm(pml4, size, size + 2 * PGSIZE);
        clear_pteu(pml4, size - 2 * PGSIZE);
        stackPoint = size;

        // Push argument strings, prepare rest of stack in userstack.
        for (argc = 0;argv[cnt][argc];argc++) {
            stackPoint = (stackPoint - (strlen(argv[cnt][argc]) + 1)) & ~(sizeof(u64) - 1);
            copy_uvm(pml4, stackPoint, argv[cnt][argc], strlen(argv[cnt][argc] + 1));
            uStack[3 + argc] = stackPoint;
        }
        uStack[3 + argc] = 0;

        uStack[0] = 0xffffffff; // fake return pc
        uStack[1] = argc;
        uStack[2] = stackPoint - (argc + 1) * sizeof(u64); //argv pointer

        proc->tf->rdi = argc;
        proc->tf->rsi = ;

        stackPoint -= (3 + argc + 1) * sizeof(u64);
        copy_uvm(pml4, stackPoint, uStack, (3 + argc + 1) * sizeof(u64));

        proc->pml4 = pml4;
        proc->size = size;
        proc->tf->rip = elf.entry;
        proc->tf->rsp = stackPoint;
    }
}