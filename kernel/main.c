#include "types.h"
#include "defs.h"
#include "mmu.h"
#include "memlayout.h"
#include "proc.h"

int main(void){
  memblock_init();
  panic("ok");
}
