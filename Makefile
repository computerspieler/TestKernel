.PHONY: all clean mrproper run


floppy.img: boot kernel
	cat boot /dev/zero | dd of=floppy.img bs=512 count=2880
	mkdir -p mnt
	sudo mount floppy.img mnt/
	sudo cp -fv kernel mnt/KERNEL.BIN
	sync
	sudo umount mnt
	
run: floppy.img
	bochs -f bochs.bxrc -q

all: floppy.img 

clean:
	rm -rf boot kernel kernel.bin prekernel.bin mnt

mrproper: clean
	rm -rf floppy.img


boot: src/boot.asm
	nasm -f bin -O0 -o $@ $^

kernel.bin: src/kernel.asm src/interrupts.asm src/page.asm	\
	src/segments.asm src/task.asm
	(cd src; nasm -f bin -O0 -o ../$@ kernel.asm)

prekernel.bin: src/prekernel.asm
	nasm -f bin -O0 -o $@ src/prekernel.asm

kernel: prekernel.bin kernel.bin
	cat prekernel.bin kernel.bin > $@

