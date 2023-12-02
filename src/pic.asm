; This part is stolen from wiki.osdev.org
; https://wiki.osdev.org/8259_PIC
%include "macros.asm"

%define PIC1_VECTOR_OFFSET  0x20
%define PIC2_VECTOR_OFFSET  0x28

%define PIC1_COMMAND    0x20
%define PIC1_DATA       0x21
%define PIC2_COMMAND    0xA0
%define PIC2_DATA       0xA1

%define PIC_EOI         0x20

%define ICW1_ICW4	    0x01
%define ICW1_SINGLE	    0x02
%define ICW1_INTERVAL4	0x04
%define ICW1_LEVEL	    0x08
%define ICW1_INIT	    0x10
 
%define ICW4_8086	    0x01
%define ICW4_AUTO	    0x02
%define ICW4_BUF_SLAVE	0x08
%define ICW4_BUF_MASTER	0x0C
%define ICW4_SFNM	    0x10

%define IO_WAIT     OUT_BYTE 0x80, 0

pic_init:
; Remap the PIC to more appropriate IRQs
    in al, PIC1_DATA
    mov ah, al
    in al, PIC2_DATA
    mov dx, ax

	OUT_BYTE PIC1_COMMAND, ICW1_INIT | ICW1_ICW4
	IO_WAIT
	OUT_BYTE PIC2_COMMAND, ICW1_INIT | ICW1_ICW4
	IO_WAIT
	OUT_BYTE PIC1_DATA, PIC1_VECTOR_OFFSET
	IO_WAIT
	OUT_BYTE PIC2_DATA, PIC2_VECTOR_OFFSET
	IO_WAIT
	OUT_BYTE PIC1_DATA, 4
	IO_WAIT
	OUT_BYTE PIC2_DATA, 2
	IO_WAIT
 
	OUT_BYTE PIC1_DATA, ICW4_8086
	IO_WAIT
	OUT_BYTE PIC2_DATA, ICW4_8086
	IO_WAIT

    mov ax, dx
    out PIC2_DATA, al
    mov al, ah
    out PIC1_DATA, al

    ret
