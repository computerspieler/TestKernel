%include "globals.asm"
%include "pic.asm"
%include "pit.asm"

%macro SAVE_TASK_REGS 0
	; Put in EAX, the process' entry in the table
	mov eax, [current_pid]
	mov ebx, Process_size
	mul ebx
	mov edi, eax
	add edi, process_table + Process.regs + Process_Regs.eip
	; Load the old ESP into ESI, from before the pushad
	mov esi, [esp + 12]
	sub esi, 4
	mov eax, [esi - 4 - 2]
	mov [edi - Process_Regs.eip + Process_Regs.eflags], eax
	mov ecx, Process_Regs.eip/2
	rep movsw
%endmacro

%macro SET_TASK_REGS 0
	; Put in EAX, the process' entry in the table
	mov eax, [current_pid]
	mov ebx, Process_size
	mul ebx
	mov esi, eax
	add esi, process_table + Process.regs + Process_Regs.eip
	; Load the old ESP into ESI, from before the pushad
	mov edi, [esp + 12]
	sub edi, 4
	mov ebx, [edi - 4 - 2]
	mov [esi - Process_Regs.eip + Process_Regs.eflags], ebx
	mov ecx, Process_Regs.eip/2
	rep movsw

	mov esi, eax
	add esi, process_table + Process.io_map
	mov edi, kernel_tss + Task_State_Segment.io_map
	mov ecx, IO_MAP_SIZE/2
	rep movsw
%endmacro

%assign i 0
%rep 256
interrupt_gate_%[i]:
	BREAK
	pushad
%if i == PIC1_VECTOR_OFFSET
	SAVE_TASK_REGS
%endif

    mov al, %[i]

%if i >= PIC1_VECTOR_OFFSET && (i < PIC1_VECTOR_OFFSET+8)
	OUT_BYTE PIC1_COMMAND, PIC_EOI
%elif i >= PIC2_VECTOR_OFFSET && (i < PIC2_VECTOR_OFFSET+8)
	OUT_BYTE PIC2_COMMAND, PIC_EOI
%endif

%if i == PIC1_VECTOR_OFFSET
	call process_switch
	SET_TASK_REGS
%endif
	mov ax, USERLAND_DATA_SEGMENT
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	popad
	; Set the CS segment
	mov word [esp + 6], USERLAND_CODE_SEGMENT
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
