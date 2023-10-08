%define emm_start       0x00100000
%define max_page_count  262144      ; = 4GiB / (4Kib * 4)

paging_init:
	ret

; Input:
;	AX = the number of pages to retrieve
; Output:
;   ECX = The address
paging_retrieve_page:
	xor dx, dx
	mov cx, [extended_memory_page_count]

.loop:
    ; Prepare the mask
	push ecx
	mov bx, 3
    and cl, 3
    shl cl, 1
	shl bx, cl  ; bx = 0b11 << ((selected page % 4) * 2)
	pop ecx

    ; Apply the mask and check if the current page is free
	push ecx
	shl ecx, 2
	add ecx, pages
	mov cl, [ecx]
	and bl, cl
	pop ecx
	jnz .reset_count
	inc dx
	cmp dx, ax
	je .found
	loop .loop

.not_found:
    xor ecx, ecx
    ret

.reset_count:
	xor dx, dx
	loop .loop

.found:
    xor edx, edx
    mov dx, ax
    sub ecx, edx
    shl ecx, 12 ; <=> ecx *= 4096 = 2^12
    add ecx, emm_start
    
	ret

extended_memory_page_count:		dw 0

[section .bss]
pages:
    resb max_page_count


