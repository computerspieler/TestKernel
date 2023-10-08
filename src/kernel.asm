%define BASE_ADDRESS  (0xFFC01000 + 3*4096)  ; The shift is due to the prekernel
[org BASE_ADDRESS]
[bits 32]

[section .text]
	jmp start

%define BREAK  xchg bx, bx
%define STACK_START	(0xFFC7FFFF)

%include "segments.asm"
%include "page.asm"
%include "interrupts.asm"
%include "task.asm"

start:
	shr ax, 2
	mov [extended_memory_page_count], ax
	mov esp, STACK_START
	
    lgdt [gdt_ptr]
    lidt [idt_ptr]

	call paging_init

	mov esi, test
	call print_string

	sti

loop:
	hlt
	jmp loop

print_string:
	mov edi, 0xB8000
.loop:
	lodsb
	cmp al, 0
	je .done

	stosb
	mov al, 0x0F
	stosb

	jmp .loop

.done:
	ret

; === Variables ===
test: db "Hello world !", 0

kernel_tss:
	istruc Task_State_Segment
	iend

gdt:
	db GDT(0, 0, 0, 0)	; Null descriptor
	db GDT(0, 0xFFFFF, 0b1100, 0b10011010)	; Kernel's code segment
	db GDT(0, 0xFFFFF, 0b1100, 0b10010010)	; Kernel's data segment
	db GDT(kernel_tss - $$, Task_State_Segment_size, 0, 0) ; Kernel's task state segment
	db GDT(0, 0xFFFFF, 0b1100, 0b11111010)	; Userland's code segment
	db GDT(0, 0xFFFFF, 0b1100, 0b11110010)	; Userland's data segment
.end:

gdt_ptr:
	dw gdt.end - gdt - 1
	dd gdt


