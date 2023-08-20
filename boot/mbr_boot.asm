%include "boot/gdt.inc"
%define pos(x,y) (80*(x)+(y))*2 ; 

org 0x7c00 ; in legacy boot mode, the bootloader will be load to  0x7c00

[BITS 16]
main:
    ; init stack
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7c00

    ; print hello world
    call clear_screen
    mov  ax, msg
    mov  cx, len
    call print

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

    jmp $

clear_screen:
    mov ah, 0x00 ; modify video mode
    mov al, 0x03 ; 80x25 color text mode
    int 0x10
    ret

print: 
    ;; @param ax: string address (es:ax)
    ;; @param cx: string length
    mov bp, ax     ; es:bp = string address
    mov ax, 0x1301 ; ah = 0x13 : display string
    mov bx, 0x000c ; bh = page number, bl = tty color
    mov dl, 0
    int 0x10       ; call BIOS function
    ret


[BITS 32]
protected_main:
    mov ax,       DESC_VIDEO - GDT
    mov gs,       ax
    mov ah,       00001100b        ; black bg, red fg
    mov al,       'P'
    mov edi,      pos(5, 5)
    mov [gs:edi], ax
    jmp $

    
%define endl 0x0d,0x0a
msg     db  "Hello World!",endl
len     equ $ - msg

GDT:
DESC_NULL:  descriptor          0,          0, 0
DESC_CODE:  descriptor          0, 0xffffffff, GDT_TYPE_EXECUTABLE | GDT_TYPE_EXEC_READABLE | GDT_TYPE_NON_SYSTEM | GDT_PROTECTED_MODE | GDT_PRESENT
DESC_DATA:  descriptor          0, 0xffffffff, GDT_TYPE_DATA_WRITABLE | GDT_TYPE_NON_SYSTEM | GDT_PROTECTED_MODE | GDT_PRESENT
DESC_VIDEO: descriptor    0xb8000, 0xffffffff, GDT_TYPE_DATA_WRITABLE | GDT_TYPE_NON_SYSTEM | GDT_PROTECTED_MODE | GDT_PRESENT

gdt_len equ $ - GDT
gdt_reg dw  gdt_len - 1         ; the length of gdt minus 1
        dd GDT ; the address of gdt

; fill remain space with 0
; disk signature starts at offset 0x01b8(440), and partition table starts at offset 0x01be
times 440-($-$$) db 0