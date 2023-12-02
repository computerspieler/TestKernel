%ifndef __MACROS__
%define __MACROS__

; OUT_BYTE(short address, byte data)
%macro OUT_BYTE 2 
    mov al, %2
    out %1, al
%endmacro

; BZERO(void* dst, int n)
%macro BZERO 2
	xor al, al
	mov edi, %1
	mov ecx, %2
	rep stosb
%endmacro


; MEMCPY(void* dst, void* src, int n)
%macro MEMCPY 3
	mov edi, %1
	mov esi, %2
	mov ecx, %3
	rep movsd
%endmacro

; Debugging macros
%define BREAK  xchg bx, bx

%endif
