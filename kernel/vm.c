#include "types.h"
#include "defs.h"
#include "mmu.h"
#include "memlayout.h"
#include "vm.h"

#define kernelFirstSize
#define KernelFirstHasMappedEnd

// Return the address of the PTE in pml4
// that corresponds to virtual address va. If alloc!=0,
// create any required page table pages.
static u64* page_walk(u64* root, const void* va, int alloc) {

  u64* pml4e, * pdpte, * pde, * pte;

  // Page map level 4 index
  pml4e = &root[PML4X(va)];

  if (!(*pml4e & PTE_P)) {
    if (!alloc || (pml4e = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE)) == 0)
      return 0;
    memset(pml4e, 0, PGSIZE);
    root[PML4X(va)] = v2p(pml4e) | PTE_P | PTE_W | PTE_U;
  }

  // Page directory pointer index
  pdpte = &pdpte[PDPTX(va)];

  if (!(*pdpte & PTE_P)) {
    if (!alloc || (pdpte = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE)) == 0)
      return 0;
    memset(pdpte, 0, PGSIZE);
    pml4e[PDPTX(va)] = v2p(pdpte) | PTE_P | PTE_W | PTE_U;
  }

  // Page directory index
  pde = &pde[PDX(va)];

  if (!(*pde & PTE_P)) {
    if (!alloc || (pde = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE)) == 0)
      return 0;
    memset(pde, 0, PGSIZE);
    pdpte[PDX(va)] = v2p(pde) | PTE_P | PTE_W | PTE_U;
  }

  // Page table index
  pte = &pte[PTX(va)];

  if (!(*pte & PTE_P)) {
    if (!alloc || (pte = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE)) == 0)
      return 0;
    memset(pte, 0, PGSIZE);
    pde[PTX(va)] = v2p(pte) | PTE_P | PTE_W | PTE_U;
  }

  return pte;
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int map_pages(u64* pml4, void* va, u64 size, u64 pa, int perm) {
  char* first, * last;
  u64* pte;

  first = (char*)ALIGN_DOWN(((u64)va), ((u64)PGSIZE));
  last = (char*)ALIGN_DOWN(((u64)va), ((u64)PGSIZE));
  while (1) {
    if (pte = page_walk(pml4, first, 1) == 0)
      return -1;
    if (*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if (first == last)
      break;
    first += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

u64* setup_user_memory_pages(void) {
  u64* pml4 = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE);
  u64* pdpt = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE);
  u64* pgdir = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE);
  u64* pte = (u64*)memblock_alloc_kernel(PGSIZE, PGSIZE);

  memset(pml4, 0, PGSIZE);
  memset(pdpt, 0, PGSIZE);
  memset(pgdir, 0, PGSIZE);
  memset(pte, 0, PGSIZE);

  pml4[0] = v2p(pdpt) | PTE_P | PTE_W | PTE_U;
  pdpt[0] = v2p(pgdir) | PTE_P | PTE_W | PTE_U;
  pgdir[0] = v2p(pte) | PTE_P | PTE_W | PTE_U;

  return pml4;
}

int alloc_uvm(u64* pml4, u64 oldSize, u64 newSize) {
  char* mem;

  if (newSize < oldSize)
    return oldSize;

  u64 oldSizeAlign = PGROUNDUP(oldSize);
  mem = memblock_alloc(newSize - oldSize, PGSIZE);

  // Dealloc has memset zero.
  for (;oldSizeAlign < newSize;oldSizeAlign += PGSIZE, mem += PGSIZE) {
    map_pages(pml4, (char*)oldSizeAlign, PGSIZE, v2p(mem), PTE_W | PTE_U);
  }
  return newSize;
}

// Copy len bytes from p to user address va in pml4.
// Most useful when pgdir is not the current page table.
int copy_uvm(u64* pml4, u64 va, void* src, u64 len) {
  u64 vaAlign, size;
  char* buf, * ka;

  buf = (char*)src;
  while (len > 0) {
    vaAlign = (u64)PGROUNDDOWN(va);
    ka = (char*)p2v((PTE_ADDR(*(page_walk(pml4, (char*)vaAlign, 0)))));

    size = PGSIZE - (va - vaAlign);
    if (size > len)
      size = len;
    memmove(ka + (va - vaAlign), buf, size);
    len -= size;
    buf += size;
    va = vaAlign + PGSIZE;
  }
  return 0;
}

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void clear_pteu(u64* pml4, char* va) {
  u64* pte;

  pte = page_walk(pml4, va, 0);
  if (pte == 0)
    panic("clear_pteu");
  *pte &= ~PTE_U;
}

void vm_init(void) {
  kernelHasMappedEnd = ;
  kernelSize = ;
  // Set the new kernel page frame.
}