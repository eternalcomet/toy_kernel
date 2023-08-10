org 0x7c00 ; in legacy boot mode, the bootloader will be load to  0x7c00

main:
    ; init stack
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; print hello world
    call clear_screen
    mov  ax, msg
    mov  cx, len
    call print

    jmp exit

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

exit:
    hlt
    jmp exit
    
msg              db  "Hello World!"
len              equ $ - msg

; fill remain space with 0
; disk signature starts at offset 0x01b8(440), and partition table starts at offset 0x01be
times 440-($-$$) db  0