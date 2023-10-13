#include "types.h"
#include "x86.h"
#include "trap.h"
#include "proc.h"

void trap(struct trapframe* tf){
  if(tf->trapno == T_SYSCALL){
    if(myproc()->killed)
      exit();
    myproc()->tf = tf;
    syscall();
    if(myproc()->killed)
      exit();
    return;
  }
}