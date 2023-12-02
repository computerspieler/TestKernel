.PHONY: all clean mrproper run build image
	
all: build

image: floppy.img
build: bin bin/boot bin/kernel

run: image
	bochs -f bochs.bxrc -q

clean:
	rm -rf bin mnt

mrproper: clean
	rm -rf floppy.img


floppy.img: build
	cat bin/boot /dev/zero | dd of=floppy.img bs=512 count=2880
	mkdir -p mnt
	sudo mount floppy.img mnt/
	sudo cp -fv bin/kernel mnt/KERNEL.BIN
	sync
	sudo umount mnt

bin:
	mkdir -p bin

bin/boot: src/boot.asm
	(cd src; nasm -f bin -O0 -o ../bin/boot boot.asm)

bin/kernel.bin: $(wildcard src/*.asm)
	(cd src; nasm -f bin -O0 -l ../bin/kernel.lst -o ../$@ kernel.asm)

bin/prekernel.bin: src/prekernel.asm
	nasm -f bin -O0 -o $@ src/prekernel.asm

bin/kernel: bin/prekernel.bin bin/kernel.bin
	cat bin/prekernel.bin bin/kernel.bin > $@

