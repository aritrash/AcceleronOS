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
    ; --- Start of prompt logic ---
    mov si, prompt
    call print
    mov di, input_buffer

.read_loop:
    call get_key        ; AL = ASCII

    cmp al, 13
    je .handle_enter    ; Enter key pressed

    cmp al, 8
    je .handle_backspace ; Backspace key pressed

    cmp al, 32
    jb .read_loop       ; Ignore control characters

    ; Check for buffer overflow if implementing production code
    mov [di], al
    inc di

    ; Echo character to screen
    mov ah, 0x0E
    int 0x10
    jmp .read_loop

.handle_backspace:
    cmp di, input_buffer
    je .read_loop

    dec di
    
    ; Erase character by printing BS, Space, BS
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
    mov byte [di], 0    ; Null-terminate the input string
    call nl             ; Print newline after the input line

    ; ---------------------------------
    ; COMMAND PARSING LOGIC for v1.0.3
    ; ---------------------------------
    mov si, input_buffer    ; DS:SI = user input

    ; 1. Check for 'clr' command
    mov di, cmd_clr
    call strequ
    cmp al, 1
    je .execute_clr

    ; 2. Check for 'ver' command
    mov si, input_buffer    ; Reset SI for next comparison
    mov di, cmd_ver
    call strequ
    cmp al, 1
    je .execute_ver

    ; 3. Check for 'help' command
    mov si, input_buffer    ; Reset SI for next comparison
    mov di, cmd_help
    call strequ
    cmp al, 1
    je .execute_help
    
    ; 4. Default: Command not found
    mov si, err_cmd
    call print
    call nl
    jmp main_prompt

.execute_clr:
    call clear_screen
    jmp main_prompt

.execute_ver:
    mov si, msg_ver
    call print
    call nl
    jmp main_prompt

.execute_help:
    mov si, msg_help
    call print
    call nl
    jmp main_prompt


; -------------------
; COMMAND IMPLEMENTATION ROUTINES
; -------------------

clear_screen:
    pusha
    ; INT 10h, AH=06h (Scroll up window)
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x07
    mov cx, 0x0000  ; Top-left corner (0,0)
    mov dx, 0x184F  ; Bottom-right corner (24,79)
    int 0x10
    
    ; Set cursor back to home position (0,0)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
    
    popa
    ret

; -------------------
; UTILITY ROUTINES (strequ, print, nl, get_key)
; -------------------

; strequ: Compare two NUL-terminated strings pointed to by DS:SI and ES:DI
; Returns: AL = 1 if equal, 0 if not equal
strequ:
    push si
    push di
    push cx
    push ds
    push es
    
    mov ax, ds
    mov es, ax          ; Set ES = DS
    
    mov al, 1           ; Default return value: 1 (equal)

.cmp_loop:
    mov cl, byte [si]   ; Get char from string 1
    mov ch, byte [di]   ; Get char from string 2
    
    cmp cl, ch
    jne .not_equal
    
    or cl, cl           ; Check for null terminator
    jz .equal
    
    inc si
    inc di
    jmp .cmp_loop
    
.not_equal:
    mov al, 0           ; Strings are not equal
    jmp .s_done
    
.equal:
    mov al, 1           ; Strings are equal

.s_done:
    pop es
    pop ds
    pop cx
    pop di
    pop si
    ret

; PRINT
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

; BIOS KEYBOARD INPUT
get_key:
    mov ah, 00h
    int 16h
    ret

; -------------------
; Data for v1.0.3
; -------------------
msg1    db "Welcome to AcceleronOS CLI v1.0.4",0
msg2    db "(C) Asta Epsilon Group, 2025",0
prompt  db "root@acceleron / > ",0

cmd_clr db "clr", 0
cmd_ver db "ver", 0
cmd_help db "help", 0

CR EQU 13
LF EQU 10

msg_ver db "AcceleronOS CLI v1.0.4 (Stable Release)", CR, LF 
        db "GitHub: https://github.com/aritrash/AcceleronOS", CR, LF, 0

msg_help db "AcceleronOS Help", CR, LF
         db "________________", CR, LF
         db "Thank you for choosing AcceleronOS for your server! We wish to continue serving you!", CR, LF
         db "________________", CR, LF
         db "clr  - Clears the terminal screen.", CR, LF
         db "ver  - Displays the kernel version.", CR, LF
         db "help - Displays this help message.", CR, LF, 0

err_cmd db "Command not found. Type 'help' for available commands.", 0

input_buffer times 128 db 0
