#include <types.h>
#include <ctypes.h>
#include "cnode.h"
#include "failures.h"

exception_t decode_cnode_invocation() {

}

exception_t invoke_cnode_revoke() {

}

exception_t invoke_cnode_delete() {

}

exception_t invoke_cnode_cancel_badged_sends() {

}

exception_t invoke_cnode_insert() {

}

exception_t invoke_cnode_move() {

}

exception_t invoke_cnode_rorate() {

}

exception_t invoke_cnode_save_caller() {

}

static void set_untyped_cap_as_full() {

}

void cte_insert() {

}
// This implementation is specialised to the (current) limit
// of one cap receive slot. 
Cte* get_receive_slots(Tcb* thread, u64* buffer) {
    CapTransfer ct;
    Cptr cptr;
    LookupCapRet lucRet;
    LookupSlotRet lusRet;
    Cte* slot;
    Cap cnode;

    if(!buffer) {
        return NULL;
    }


}