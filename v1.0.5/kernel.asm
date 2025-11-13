BITS 16
ORG 0x0000

start:
    ; The bootloader (boot.asm) loads this kernel starting at 0x1000:0x0000.
    ; This ensures DS/ES/SS point to the correct 64KB segment (0x1000).
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    ; --- FILESYSTEM INITIALIZATION (NEW in v1.0.5) ---
    ; Store the boot drive number (DL) into a known variable for INT 13h calls.
    ; NOTE: The bootloader MUST have passed the drive number in DL.
    ; We assume a global variable at the beginning of the kernel data segment holds this.
    ; The bootloader should be updated to save the original DL value to [boot_drive]
    ; or you must manually pass it/save it here. For safety, we rely on the
    ; bootloader's initial state here.
    ; The boot drive number is usually the same as the drive used to load the kernel.
    mov [boot_drive], dl
    
    ; Display initial messages
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
    call get_key         ; AL = ASCII

    cmp al, 13
    je .handle_enter     ; Enter key pressed

    cmp al, 8
    je .handle_backspace ; Backspace key pressed

    cmp al, 32
    jb .read_loop        ; Ignore control characters

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
    mov byte [di], 0     ; Null-terminate the input string
    call nl              ; Print newline after the input line

    ; ---------------------------------
    ; COMMAND PARSING LOGIC
    ; ---------------------------------
    mov si, input_buffer ; DS:SI = user input

    ; 1. Check for 'clr' command
    mov di, cmd_clr
    call strequ
    cmp al, 1
    je .execute_clr

    ; 2. Check for 'ver' command
    mov si, input_buffer 
    mov di, cmd_ver
    call strequ
    cmp al, 1
    je .execute_ver

    ; 3. Check for 'help' command
    mov si, input_buffer
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


; -----------------------------------------------------------------
; DISK I/O UTILITY (New in v1.0.5)
; -----------------------------------------------------------------
; read_sector: Reads a single sector from the disk using LBA.
; Input:
;   AX = LBA (Logical Block Address / Sector Number, 0-based)
;   ES:BX = Destination Memory Address (where to load the 512 bytes)
; Returns:
;   Carry Flag (CF) clear on success.
read_sector:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Save LBA for translation
    mov [disk_lba], ax
    
    ; --- LBA to CHS Translation ---
    ; Uses: LBA / SPT / HPC
    
    ; 1. Calculate Sector (CL)
    ; Sector = (LBA MOD SectorsPerTrack) + 1
    mov bx, SectorsPerTrack
    xor dx, dx       ; DX:AX = LBA
    div bx           ; AX = LBA / SPT, DX = LBA MOD SPT
    inc dl           ; DL = Sector Number (1-based)
    mov cl, dl       ; CL = Sector (bits 0-5)
    
    ; 2. Calculate Head (DH)
    ; Head = (LBA / SPT) MOD HeadsPerCylinder
    xor dx, dx       ; DX:AX = (LBA / SPT)
    mov bx, HeadsPerCylinder
    div bx           ; AX = Cylinder, DX = Head Number
    mov dh, dl       ; DH = Head
    
    ; 3. Calculate Cylinder (CH)
    ; Cylinder = (LBA / SPT) / HPC
    mov ch, al       ; CH = Cylinder (bits 0-7)
    
    ; Combine Cylinder High bits (bits 8-9) with Sector bits (bits 6-7)
    ; Note: For standard floppy/hard disk, this step is often omitted 
    ; for cylinders 0-255, but we ensure CL only holds the LBA 
    ; remainder + 1. For a small floppy image, CH=AL is enough.
    
    ; --- BIOS Read Command (INT 13h) ---
    mov ah, 0x02     ; Read sectors
    mov al, 0x01     ; Read 1 sector
    mov dl, [boot_drive] ; Set boot drive
    
    int 0x13
    jc .disk_error   ; Jump if Carry Flag is set (read failed)
    
    ; Success path
    clc              ; Clear Carry Flag
    jmp .rs_done
    
.disk_error:
    mov si, err_disk
    call print
    call nl
    stc              ; Set Carry Flag
    
.rs_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


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
; Data for v1.0.5 (Kernel data MUST be placed at the end)
; -------------------
msg1    db "Welcome to AcceleronOS CLI v1.0.5",0
msg2    db "(C) Asta Epsilon Group, 2025",0
prompt  db "root@acceleron / > ",0

cmd_clr db "clr", 0
cmd_ver db "ver", 0
cmd_help db "help", 0

CR EQU 13
LF EQU 10

msg_ver db "AcceleronOS CLI v1.0.5 (Disk I/O Foundation)", CR, LF 
        db "GitHub: https://github.com/aritrash/AcceleronOS", CR, LF, 0

msg_help db "AcceleronOS Help", CR, LF
         db "________________", CR, LF
         db "Thank you for choosing AcceleronOS for your server! We wish to continue serving you!", CR, LF
         db "________________", CR, LF
         db "clr  - Clears the terminal screen.", CR, LF
         db "ver  - Displays the kernel version.", CR, LF
         db "help - Displays this help message.", CR, LF, 0

err_cmd db "Command not found. Type 'help' for available commands.", CR, LF, 0
err_disk db "Disk I/O Error!", CR, LF, 0

; --- Disk Geometry (FAT12/16 Standard for Floppy) ---
SectorsPerTrack EQU 18
HeadsPerCylinder EQU 2

; --- Variables and Buffers ---
boot_drive db 0 
disk_lba dw 0

input_buffer times 128 db 0

; Pad to 1024 bytes (2 sectors)
times 1024-($-$$) db 0