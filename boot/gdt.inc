; structure of gdt descriptor

; @signature: descriptor base, limit, attr
; @param u32 base : Base address of the segment.
; @param u32 limit : Only low 20 bits are in use. The length of the segment - 1, because the max size is 2^20, and the max value of u20 is 2^20-1.
; @param u16 attr : Only the high 4 bits and low 8 bits are in use.
%macro descriptor 3
    dw %2 & 0xffff                           ; limit low 16 bits
    dw %1 & 0xffff                           ; base low 16 bits
    db (%1 >> 16) & 0xff                     ; base 16-23 bits
    dw ( (%2 >> 8) & 0x0f00) | (%3 & 0xf0ff) ; attribute and limit high 8 bits
    db (%1 >> 24) & 0xff                     ; base 24-31 bits
%endmacro

; attribute

; 0 bit: accessed
GDT_ACCESSED             equ 0000_0001b           ; best left clear (0), the CPU will set it when the segment is accessed.

; 1-4 bits: type
; for data segment
GDT_TYPE_DATA_WRITABLE   equ 0000_0010b           ; read-only if clear (0) 
GDT_TYPE_DATA_GROW_DOWN  equ 0000_0100b           ; Direction bit. If clear (0) the segment grows up. If set (1) the segment grows down, ie. the Offset has to be greater than the Limit, like stack.
; for code segment
GDT_TYPE_EXEC_READABLE   equ 0000_0010b           ; execute-only if clear (0)
GDT_TYPE_EXEC_CONFORMING equ 0000_0100b           ; if set (1), code in this segment can be executed from an equal or lower privilege level; if clear (0), code in this segment can only be executed from the ring set in DPL.
; for system segment
GDT_TYPE_SYS_LDT         equ 0x2
GDT_TYPE_SYS_TSS         equ 0x9                  ; 32-bit TSS (Task State Segment)
GDT_TYPE_SYS_TSS_BUSY    equ 0xb

GDT_TYPE_EXECUTABLE      equ 0000_1000b           ; if clear (0) the descriptor defines a data segment.
GDT_TYPE_NON_SYSTEM      equ 0001_0000b           ; if clear (0) the descriptor defines a system segment; if set (1) the descriptor defines a data or code segment.

; 5-6 bits: discriptor privilege level (DPL)
GDT_DPL_0                equ 0x0 << 5
GDT_DPL_1                equ 0x1 << 5
GDT_DPL_2                equ 0x2 << 5
GDT_DPL_3                equ 0x3 << 5

; 7 bit: present
GDT_PRESENT              equ 1000_0000b           ; set (1) for any valid segment.

; 13 bit: Long-mode
GDT_LONG_MODE            equ 0010_0000_0000_0000b ; If set (1), the descriptor defines a 64-bit code segment and `DB` should always be clear (0).

; 14 bit:
GDT_PROTECTED_MODE       equ 0100_0000_0000_0000b ; If set (1), 32-bit segment, for stack segment use ESP rather than SP and the limit is 4GB rather than 64KB. If clear (0), 16-bit segment.

; 15 bit:
GDT_PAGE_GRANULARITY     equ 1000_0000_0000_0000b ; If set (1), the unit for the limit field is 4 KiB (just the size of a page). If clear (0), the unit is byte.