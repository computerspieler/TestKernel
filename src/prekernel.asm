; This file's purpose is just to prepare for pagination
%define BASE_ADDRESS 0x1000
[cpu 386]
[org BASE_ADDRESS]
[bits 32]

%define ADDR_TO_SCALAR(addr) (((addr) - $$) + BASE_ADDRESS)

    mov eax, page_directory     ; Load the page directory
    mov cr3, eax

    mov eax, cr0                ; Enable paging
    or eax, 0x80000000
    mov cr0, eax

    jmp (higher_kernel + 0xFFC00000)

    times (4096 - ($ - $$)) db 0

page_directory:
    dd (ADDR_TO_SCALAR(page_table) | 3)
    times 1022 dd 2
    dd (ADDR_TO_SCALAR(page_table) | 3)

    ; Not necessary since the page directory is aligned and 4k long
    ; But it doesn't cost much to add it
    times (2*4096 - ($ - $$)) db 0

page_table:
%assign i 0
%rep 1024
    dd (%[i] * 0x1000) | 3
%assign i (i+1)
%endrep
    
times (3*4096 - ($-$$)) db 0    ; It will help maintain the offset in kernel
                                ; valid
higher_kernel:
