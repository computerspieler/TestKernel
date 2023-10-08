[section .text]
%assign i 0
%rep 256
interrupt_gate_%[i]:
    pusha
    mov al, %[i]
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


