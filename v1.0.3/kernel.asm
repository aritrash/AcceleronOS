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

    ; Clear the input buffer pointer (DI is currently used as the buffer index/pointer)
    mov di, input_buffer

.read_loop:
    call get_key        ; AL = ASCII

    cmp al, 13
    je .handle_enter    ; Enter key pressed

    cmp al, 8
    je .handle_backspace ; Backspace key pressed

    cmp al, 32
    jb .read_loop       ; Ignore non-printable control characters below ASCII 32

    ; Save character to buffer (make sure we don't overflow, though we won't check that here)
    mov [di], al
    inc di

    ; Echo character to screen
    mov ah, 0x0E
    int 0x10
    jmp .read_loop

.handle_backspace:
    cmp di, input_buffer
    je .read_loop       ; Do nothing if buffer is empty

    dec di              ; Move buffer pointer back

    ; Print backspace (8), space (' '), then backspace (8) to erase character
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
    ; Terminate the input string in the buffer
    mov byte [di], 0

    call nl ; Print newline after the input line

    ; ---------------------------------
    ; COMMAND PARSING LOGIC for v1.0.3
    ; ---------------------------------
    
    ; 1. Check for 'clr' command
    mov si, input_buffer
    mov di, cmd_clr         ; DS:SI = user input, ES:DI = 'clr' string
    call strequ             ; Calls strequ. ZF=1 if strings match.
    
    cmp al, 1               ; Check if strequ returned 1 (true)
    je .execute_clr
    
    ; 2. (Default) If command not found, echo input and print error
    
    ; Echo the user input (for debugging or simple commands)
    mov si, input_buffer
    call print
    call nl
    
    mov si, err_cmd
    call print
    call nl
    
    jmp main_prompt         ; Loop back to prompt

.execute_clr:
    call clear_screen       ; Execute the clear routine
    jmp main_prompt         ; Loop back to prompt

; -------------------
; COMMAND IMPLEMENTATION
; -------------------

clear_screen:
    pusha
    ; INT 10h, AH=06h (Scroll up window)
    ; AL=0 (Scroll entire window)
    ; CH=0, CL=0 (Row/Col start)
    ; DH=24, DL=79 (Row/Col end - full 80x25 screen)
    ; BH=07h (Attribute: White on Black)
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x07
    mov cx, 0x0000  ; Top-left corner (0,0)
    mov dx, 0x184F  ; Bottom-right corner (24,79)
    int 0x10
    
    ; Set cursor back to home position (0,0)
    ; INT 10h, AH=02h (Set Cursor Position)
    ; BH=0 (Page 0)
    ; DH=0 (Row 0)
    ; DL=0 (Col 0)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
    
    popa
    ret

; -------------------
; UTILITY ROUTINES
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
    mov es, ax          ; Set ES = DS for easier string operations (ES:DI and DS:SI)
    
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

; -------------------
; PRINT: BIOS teletype print of NUL-terminated string at DS:SI
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
; Data for v1.0.3
; -------------------
msg1    db "Welcome to AcceleronOS CLI v1.0.3",0
msg2    db "(C) Asta Epsilon Group, 2025",0
prompt  db "root@acceleron / > ",0

cmd_clr db "clr", 0     ; The command we are checking against
err_cmd db "Command not found.", 0

input_buffer times 128 db 0

times 512-($-$$) db 0