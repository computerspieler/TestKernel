#!/bin/sh

nasm -f bin -o boot boot.asm &&
nasm -f bin -o KERNEL.BIN kernel.asm &&
(cat boot /dev/zero | dd of=floppy.img bs=512 count=2880) &&
mkdir -p mnt &&
sudo mount floppy.img mnt &&
sudo cp -fv KERNEL.BIN mnt &&
sudo umount mnt &&
bochs -f bochs.bxrc -q
