BITS 16
ORG 0x0000

start:
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    mov si, msg1
    call print
    call nl

    mov si, msg2
    call print
    call nl
    call nl

main_prompt:
    mov si, prompt
    call print

    mov di, input_buffer

.read_loop:
    call get_key        ; AL = ASCII

    cmp al, 13
    je .handle_enter

    cmp al, 8
    je .handle_backspace

    cmp al, 32
    jb .read_loop

    mov [di], al
    inc di

    mov ah, 0x0E
    int 0x10
    jmp .read_loop

.handle_backspace:
    cmp di, input_buffer
    je .read_loop

    dec di

    mov al, 8
    mov ah, 0x0E
    int 0x10

    mov al, ' '
    mov ah, 0x0E
    int 0x10

    mov al, 8
    mov ah, 0x0E
    int 0x10
    jmp .read_loop

.handle_enter:
    mov byte [di], 0

    call nl

    mov si, input_buffer
    call print
    call nl
    call nl

    jmp main_prompt

; -------------------
; PRINT
; -------------------
print:
    pusha
.p_loop:
    lodsb
    or al, al
    jz .p_done
    mov ah, 0x0E
    int 0x10
    jmp .p_loop
.p_done:
    popa
    ret

nl:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    ret

; -------------------
; BIOS KEYBOARD INPUT
; -------------------
get_key:
    mov ah, 00h
    int 16h
    ret

; -------------------
; Data
; -------------------
msg1   db "Welcome to AcceleronOS CLI v1.0.2",0
msg2   db "(C) Asta Epsilon Group, 2025",0
prompt db "root@acceleron / > ",0

input_buffer times 128 db 0

times 512-($-$$) db 0
