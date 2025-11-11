; boot.asm - Minimal 16-bit boot sector
; - Loads 1 sector (kernel) from floppy into physical 0x10000 (segment 0x1000)
; - Sets DS/ES to 0x1000 before jumping so kernel string ops read correct data
; - Uses BIOS int 13h CHS: reads sector 2 (first sector after boot)
; Assemble: nasm -f bin boot.asm -o boot.bin

BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax         ; DS = 0 (where boot sector data lives)
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Save boot drive (DL) passed by BIOS
    mov [bootdrv], dl

    ; Print a small debug message
    mov si, bootmsg
    call print

    ; Prepare to load kernel into physical 0x10000 (ES:BX = 0x1000:0x0000)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    ; Read kernel via BIOS INT 13h (CHS)
    mov ah, 0x02          ; read sectors
    mov al, 0x01          ; read exactly 1 sector (kernel fits in 1 sector)
    mov ch, 0x00          ; cylinder 0
    mov cl, 0x02          ; sector 2 (first after boot sector)
    mov dh, 0x00          ; head 0
    mov dl, [bootdrv]     ; boot drive (from BIOS)
    int 0x13
    jc diskerr

    ; Set DS and ES to kernel segment so kernel's data/string ops work
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    ; Far jump to kernel entry (CS:IP = 0x1000:0x0000)
    jmp 0x1000:0x0000

diskerr:
    mov si, err_msg
    call print
    jmp $     ; halt here

; ------------------------
; print: BIOS teletype print of NUL-terminated string at DS:SI
; uses INT 10h AH=0x0E
; ------------------------
print:
    pusha
.print_loop:
    lodsb
    or al, al
    jz .print_done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp .print_loop
.print_done:
    popa
    ret

; ------------------------
; Data
; ------------------------
bootmsg db "Boot: loading kernel...", 0
err_msg db "Disk reading error", 0

bootdrv db 0

; ------------------------
; Boot signature (pad to 512 bytes)
; ------------------------
times 510-($-$$) db 0
dw 0xAA55
