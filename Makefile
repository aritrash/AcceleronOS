NASM = nasm
DD   = dd
QEMU = qemu-system-i386

all: floppy.img

boot.bin: boot.asm
	$(NASM) -f bin boot.asm -o boot.bin

kernel.bin: kernel.asm
	$(NASM) -f bin kernel.asm -o kernel.bin

floppy.img: boot.bin kernel.bin
	$(DD) if=/dev/zero of=floppy.img bs=512 count=2880
	$(DD) if=boot.bin of=floppy.img conv=notrunc bs=512 count=1
	$(DD) if=kernel.bin of=floppy.img conv=notrunc bs=512 seek=1

run:
	qemu-system-i386 -fda floppy.img -boot a

clean:
	rm -f boot.bin kernel.bin floppy.img
