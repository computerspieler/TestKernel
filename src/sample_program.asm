%include "globals.asm"

[section .text]
; It will loop
align 4096
sample_program:
.code_start:
    jmp PROGRAM_CODE_START

.code_page_address:
    dd .code_start
.code_page_count:
    dd 1
.stack_page_count:
    dd 3