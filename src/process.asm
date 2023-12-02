%include "macros.asm"

struc Process_Regs
	; Do NOT CHANGE the order of the registers
	; It is based on how the stack is arranged by pushad
	.edi:		resq 1
	.esi:		resq 1
	.ebp:		resq 1
	.esp:		resq 1
	.ebx:		resq 1
	.edx:		resq 1
	.ecx:		resq 1
	.eax:		resq 1
	.eip:		resq 1

	.eflags:	resq 1
endstruc

struc Process
	.regs:		        		resb Process_Regs_size
	.io_map:					resb IO_MAP_SIZE
	.state:		        		resb 1

; The address size is architecture dependent
	.page_directory_address:	resb 4
endstruc

%define PROCESS_STATE_DEAD					0
%define PROCESS_STATE_RUNNING				1
%define PROCESS_STATE_WAITING_TO_SEND_IPC	2
%define PROCESS_STATE_IN_CONFIGURATION		3

; Let's get the page table from the pre-kernel
%define kernel_page_table	 (BASE_ADDRESS - 0x1000)

[section .text]
process_init:
	mov dword [current_pid], 0
	BZERO process_table, (process_table.end - process_table)

	ret

process_find_free_entry:
	push ebx
	push ecx

	mov ecx, PROCESS_COUNT
.find_slot:
; Retrieve process's slot offset from his ID	
	mov eax, ecx
	dec eax
	mov ebx, Process_size
	mul ebx

; Retrieve the process's state
	add eax, process_table + Process.state
	mov al, [eax]
	cmp al, PROCESS_STATE_DEAD
	je .found_slot

	loop .find_slot

	mov ecx, 0
.found_slot:
	mov eax, ecx
	dec eax

	pop ecx
	pop ebx
	ret

process_find_next_running_slot:
	mov ecx, PROCESS_COUNT
.find_slot:
; Retrieve process's slot offset from his ID	
	mov eax, [current_pid]
	add eax, ecx
	dec eax
	; This is the reason why PROCESS_COUNT has to be a power of 2
	; It's just to avoid doing division
	and eax, (PROCESS_COUNT - 1)
	mov ebx, Process_size
	mul ebx

; Retrieve the process's state
	add eax, process_table + Process.state
	mov al, [eax]
	cmp al, PROCESS_STATE_RUNNING
	je .found_slot

	loop .find_slot

	mov eax, -1
	ret

.found_slot:
	mov eax, [current_pid]
	add eax, ecx
	dec eax
	ret

process_switch:
	call process_find_next_running_slot
	mov [current_pid], eax
	ret

; EBX => Address of the code pages
; EDX => Page count
; ECX => Stack page count
; EAX <= PID
process_create:
	call process_find_free_entry
	push eax

	mov ebx, Process_size
	mul ebx
	add eax, process_table
	mov byte [eax + Process.state], PROCESS_STATE_IN_CONFIGURATION

	; Now EAX contains the address of the process structure

	cmp edx, 1024
	jl .next
	BREAK
.next:
	push ecx
	push eax
	mov eax, 1
	call paging_allocate_pages
	pop eax
	cmp ecx, -1
	jne .set_pd
	BREAK
.set_pd:
	mov [eax + Process.page_directory_address], ecx
	mov edi, ecx
	BZERO edi, 4096

; Add the kernel's pages
	push ebx
	mov ebx, kernel_page_table 
	and ebx, 0xFFFFF000 
	or bl, 3
	mov [edi + 4096-4], ebx
	pop ebx

	push eax
	mov eax, 1
	call paging_allocate_pages
	pop eax

	cmp ecx, -1
	jne .set_pt
	BREAK
.set_pt:
	mov esi, ecx
	BZERO esi, 4096
	and esi, 0xFFFFF000
	or esi, 3
	mov [edi + (PROGRAM_CODE_START / (4096 * 4 * 1024))], esi
	mov esi, ecx
	mov ecx, edx

	push eax
.add_code_pages:
	push ecx
	
	dec ecx
	shl ecx, 2
	mov eax, [ebx+ecx]
	mov [esi+ecx], eax

	pop ecx
	loop .add_code_pages
	pop eax

	pop ecx
.add_stack_pages:



	mov byte [eax + Process.state], PROCESS_STATE_RUNNING

	pop eax
	BREAK
	ret

current_pid:
	dd 0

[section .bss]
process_table:
    resb (Process_size * PROCESS_COUNT)
.end:

[section .text]
