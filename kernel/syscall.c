#include "syscall.h"
#include "proc.h"
#include "defs.h"
#include "types.h"

extern int sys_test(void);

static int (*syscall[])(void) = {
  [SYS_test]  sys_test,
};

void syscall(void){
  int num;
  
  num = myproc()->tf->rax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]){
    proc->tf->rax = syscalls[num]();
  }
  else{

  }
}