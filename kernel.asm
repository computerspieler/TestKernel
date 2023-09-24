[org 0x1000]
[bits 32]

	jmp short start

%define BREAK  xchg bx, bx
%define MAX_PROCS   4
%define STACK_START	0x7FFFF

%include "page.asm"

struc Task_State_Segment
	.link:		resw 1
				resw 1
	
	.esp0:		resd 1
	.ss0:		resw 1
				resw 1
	
	.esp1:		resd 1
	.ss1:		resw 1
				resw 1

	.esp2:		resd 1
	.ss2:		resw 1
				resw 1

	.cr3:		resd 1
	.eip:		resd 1
	.eflags:	resd 1
	.eax:		resd 1
	.ecx:		resd 1
	.edx:		resd 1
	.ebx:		resd 1
	.esp:		resd 1
	.ebp:		resd 1
	.esi:		resd 1
	.edi:		resd 1

	.es:		resw 1
				resw 1
	.cs:		resw 1
				resw 1
	.ss:		resw 1
				resw 1
	.ds:		resw 1
				resw 1
	.fs:		resw 1
				resw 1
	.gs:		resw 1
				resw 1
	.ldtr:		resw 1
				resw 1
				resw 1
	.iopb:		resw 1
	.ssp:		resd 1
endstruc

struc Process
	.tss:		resb Task_State_Segment_size
	.state:		resb 1
endstruc

%define GDT(base,limit,flags,access) ((limit) & 0xFF), (((limit) >> 8) & 0xFF), ((base) & 0xFF), (((base) >> 8) & 0xFF), (((base) >> 16) & 0xFF), access, (flags << 3) | (((limit) >> 16) & 0xF), (((base) >> 24) & 0xFF)

[section .text]
start:
	shr ax, 2
	mov [extended_memory_page_count], ax
	mov esp, STACK_START
	lgdt [gdt_ptr]

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
[section .data]
gdt:
	db GDT(0, 0, 0, 0)	; Null descriptor
	db GDT(0, 0xFFFFF, 0b1100, 0b10011010)	; Kernel's code segment
	db GDT(0, 0xFFFFF, 0b1100, 0b10010010)	; Kernel's data segment
	db GDT(kernel_tss - $$, Task_State_Segment_size, 0, 0) ; Kernel's task state segment

%assign i 0
%rep	MAX_PROCS
	db GDT(0, 0xFFFFF, 0b1100, 0b11111010)	; Process's code segment
	db GDT(0, 0xFFFFF, 0b1100, 0b11110010)	; Process's data segment
	db GDT(0, Task_State_Segment_size, 0, 0) ; Process's task state segment
%assign i i+1 
%endrep
.end:

gdt_ptr:
	dw gdt.end - gdt - 1
	dd gdt

test: db "Hello world !", 0
kernel_tss:
	istruc Task_State_Segment
	iend

[section .bss]
%assign i 0
%rep	MAX_PROCS
process_%[i]:
	resb Process_size
%assign i i+1 
%endrep

