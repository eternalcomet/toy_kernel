%include "boot/gdt.inc" ; GDT descriptor structure
%define pos(x,y) (80*(x)+(y))*2 ; 80x25 screen position

; In legacy boot mode, the bootloader will be load to 0x7c00, so we need `org 0x7c00`
; Now we will compile our code into a relocatable file, the offset `0x7c00` should be specified to the linker `ld` but not here.
; org 0x7c00

extern main      ; external c main function
global boot_main ; asm entry point for the linker

; strip most of the debug output to minimize the binary size

[BITS 16]
boot_main:
    ; init stack
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7c00

    ; clear screen
    mov ah, 0x00 ; new video mode
    mov al, 0x03 ; 80x25 color text mode
    int 0x10     ; modify video mode will clear the screen

    ; enable_A20
    cli
    in  al,   0x92
    or  al,   0010b
    out 0x92, al

    ; protected mode
    lgdt [gdt_reg]
    mov  eax, cr0
    or   eax, 0x00000001
    mov  cr0, eax
    jmp  dword (DESC_CODE - GDT) : protected_main

[BITS 32]
protected_main:
    ; prepare segments for c codes
    mov  ax,  DESC_DATA - GDT
    mov  ds,  ax
    mov  es,  ax
    mov  ss,  ax
    mov  esp, 0x7c00
    mov  ax,  0
    mov  fs,  ax
    mov  gs,  ax
    call main                 ; should never return

    jmp $

GDT:
DESC_NULL:  descriptor          0,          0, 0
DESC_CODE:  descriptor          0, 0xffffffff, GDT_TYPE_EXECUTABLE | GDT_TYPE_EXEC_READABLE | GDT_TYPE_NON_SYSTEM | GDT_PROTECTED_MODE | GDT_PRESENT
DESC_DATA:  descriptor          0, 0xffffffff, GDT_TYPE_DATA_WRITABLE | GDT_TYPE_NON_SYSTEM | GDT_PROTECTED_MODE | GDT_PRESENT

gdt_len equ $ - GDT
gdt_reg dw  gdt_len - 1 ; the length of gdt minus 1
        dd GDT ; the address of gdt