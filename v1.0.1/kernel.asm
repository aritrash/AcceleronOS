BITS 16
ORG 0x0000

start:
    mov si, msg1
    call print
    call nl

    mov si, msg2
    call print
    call nl
    call nl

    mov si, prompt
    call print

    mov al, '_'
    call putc

hang:
    jmp hang

print:
    lodsb
    or al, al
    jz .done
    mov ah,0x0E
    int 0x10
    jmp print
.done:
    ret

nl:
    mov al,13
    mov ah,0x0E
    int 0x10
    mov al,10
    mov ah,0x0E
    int 0x10
    ret

putc:
    mov ah,0x0E
    int 0x10
    ret

msg1   db "Welcome to AcceleronOS CLI v1.0.1",0
msg2   db "(C) Asta Epsilon Group, 2025",0
prompt db "root@acceleron / > ",0

times 512-($-$$) db 0
