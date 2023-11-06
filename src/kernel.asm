%include "globals.asm"

[cpu 386]
[org BASE_ADDRESS]
[bits 32]

[section .text]
	jmp start

%include "segments.asm"
%include "page.asm"
%include "interrupts.asm"
%include "task.asm"

[section .text]
start:
	shr ax, 2
	mov [extended_memory_page_count], ax
	mov esp, STACK_START

    ; Copy the basic gdt to the real gdt
    mov cx, (gdt_base.end - gdt_base) / 4
    mov esi, gdt_base
    mov edi, gdt
    rep movsd

    lgdt [gdt_ptr]
    lidt [idt_ptr]

	call paging_init
    call pic_init
    call pit_init

	call process_manager_init

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
	mov al, 0x70
	stosb

	jmp .loop

.done:
	ret

; === Variables ===
test: db "Hello world !", 0

kernel_tss:
	istruc Task_State_Segment
		at Task_State_Segment.iopb, dw Task_State_Segment.io_map
		at Task_State_Segment.io_map, dd \
			0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF
	iend

gdt_base:
	db GDT(0, 0, 0, 0)	; Null descriptor
	db GDT(0, 0xFFFFF, 0b1100, 0b10011010)	; Kernel's code segment
	db GDT(0, 0xFFFFF, 0b1100, 0b10010010)	; Kernel's data segment
	db GDT(kernel_tss - $$ + BASE_ADDRESS, Task_State_Segment_size, 0b0100, 0b10001001) ; Kernel's task state segment
	db GDT(0, 0xFFFFF, 0b1100, 0b11111010)	; Userland's code segment
	db GDT(0, 0xFFFFF, 0b1100, 0b11110010)	; Userland's data segment
.end:

gdt_ptr:
	dw gdt.end - gdt - 1
	dd gdt

[section .bss]
gdt:
    resb (gdt_base.end - gdt_base)
    resq PROCESS_COUNT
.end:

