struc Process
	.tss:		        		resb Task_State_Segment_size
	.state:		        		resb 1
    .privilege_level:   		resb 1

; The address size is architecture dependent
	.page_directory_address:	resb 4
endstruc

%define PROCESS_STATE_DEAD					0
%define PROCESS_STATE_RUNNING				1
%define PROCESS_STATE_WAITING_TO_SEND_IPC	2

[section .text]
process_manager_init:
	xor eax, eax
	mov [last_pid], eax

	mov ecx, process_table.end - process_table
	xor al, al
	mov edi, process_table
	rep stosb

	ret

process_find_free_entry:
	mov ecx, PROCESS_COUNT

.find_free_slot:
; Check if the slot is free	
	mov [last_pid], eax
	mov ebx, Process_size
	mul ebx
	add eax, process_table + Process.state

	mov al, [eax]
	cmp al, PROCESS_STATE_DEAD
	je .found_free_slot

; Go to the next slot
	mov eax, [last_pid]
	inc eax
; We use the fact that PROCESS_COUNT is a power of 2
	and eax, (PROCESS_COUNT-1)
	mov [last_pid], eax

	loop .find_free_slot

	mov eax, -1
	ret

.found_free_slot:
	mov eax, [last_pid]

	inc eax
	mov [last_pid], eax
	dec eax
	ret

last_pid:
	dd 0

current_pid:
	dd 0

[section .bss]
process_table:
%assign i 0
%rep PROCESS_COUNT
;process_%[i]:
    istruc Process
        at Process.tss,                 	resb Task_State_Segment_size
        at Process.state,               	resb 1
        at Process.privilege_level,     	resb 1
		at Process.page_directory_address,	resb 4
    iend
%assign i (i+1)
%endrep
process_table.end:

[section .text]
