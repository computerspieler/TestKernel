%include "globals.asm"
%include "pic.asm"
%include "pit.asm"

%assign i 0
%rep 256
interrupt_gate_%[i]:
    pusha
    mov al, %[i]

%if i >= PIC1_VECTOR_OFFSET && (i < PIC1_VECTOR_OFFSET+8)
	mov al, PIC_EOI
	out PIC1_COMMAND, al
%elif i >= PIC2_VECTOR_OFFSET && (i < PIC2_VECTOR_OFFSET+8)
	mov al, PIC_EOI
	out PIC2_COMMAND, al
%endif
    popa
    iret

%assign i (i+1)
%endrep

idt:
%assign i 0
%rep 256
    db IDT(0x8, interrupt_gate_%[i] - $$ + BASE_ADDRESS, 0b11101110)
%assign i (i+1)
%endrep
.end:

idt_ptr:
	dw idt.end - idt - 1
	dd idt
