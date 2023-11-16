#include "types.h"
#include "defs.h"
#include "mmu.h"
#include "memlayout.h"
#include "proc.h"

int main(void) {
  memblock_init();
  lapic_init();
  vm_init();
  ioapic_init();
  console_init();

  panic("ok");
}
