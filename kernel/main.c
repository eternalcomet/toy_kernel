#include "types.h"
#include "defs.h"
#include "mmu.h"
#include "memlayout.h"
#include "proc.h"

int main(void) {
  vm_init();
  memblock_init();
  lapic_init();
  ioapic_init();
  console_init();

  panic("ok");
}
