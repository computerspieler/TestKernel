%ifndef __GLOBALS_ASM__
%define __GLOBALS_ASM__

; Make sure that PROCESS_COUNT is a power of 2
%define PROCESS_COUNT	1024

; These shouldn't be changed
%define BASE_ADDRESS  (0xFFC01000 + 3*4096)  ; The shift is due to the prekernel
%define STACK_START		0xFFC7FFFF

; 16777216 = 2^12
%define MAX_PID			16777216

; Debugging macros
%define BREAK  xchg bx, bx

%endif
