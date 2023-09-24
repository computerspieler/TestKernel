[section .text]
paging_init:
	mov edi, 0x00100000
	mov [pages_bitmap_ptr], edi
	mov cx, [extended_memory_page_count]
	shr cx, 3	; cx /= (8 = 2^3)
	mov al, 0xFF
	rep stosb
	
	mov bx, [extended_memory_page_count]
	and bx, 7	; ax %= 8
	jz .done

	mov cl, 8
	sub cl, bl

	mov al, 1
	shl al, cl
	dec al
	not al

	stosb

.done:
	ret

; Input:
;	AX = the number of pages to retrieve
paging_retrieve_page:
	xor dx, dx
	mov cx, [extended_memory_page_count]

.loop:
	push cx
	mov bx, 1
	shr bx, cl
	pop cx

	push cx
	shl cx, 3
	add ecx, 0x00100000
	mov cl, [ecx]
	and bl, cl
	pop ecx
	jnz .reset_count
	inc dx
	cmp dx, ax
	je .found
	loop .loop

.reset_count:
	xor dx, dx
	loop .loop

.found:
	ret

[section .data]


[section .bss]
extended_memory_page_count:		resw 1
pages_bitmap_ptr:				resd 1
first_page_ptr:					resd 1
