%define emm_start       0x00100000
%define max_page_count  262144      ; = 4GiB / (4Kib * 4)

paging_init:
	ret

; Input:
;	EAX = the number of pages to retrieve
; Output:
;   ECX = The first page's id
paging_retrieve_pages:
BREAK
	push ebx
	push edx
	xor edx, edx
	mov ecx, [extended_memory_page_count]

.loop:
    ; Prepare the mask
	push ecx
	dec ecx
    and cl, 3
    shl cl, 1
	mov bl, 3
	shl bl, cl  ; bl = 0b11 << ((selected page % 4) * 2)
	pop ecx

    ; Apply the mask and check if the current page is free
	push ecx
	dec ecx
	shr ecx, 2
	mov cl, [ecx+pages]
	and bl, cl
	pop ecx
	jnz .reset_count
	inc edx
	cmp edx, eax
	je .found
	loop .loop

.not_found:
    mov ecx, -1
	pop edx
	pop ebx
    ret

.reset_count:
	xor edx, edx
	loop .loop

.found:
	dec ecx
	pop edx
	pop ebx
	ret

; Input:
;	EAX = the number of pages to retrieve
; Output:
;   ECX = The page's address
paging_allocate_pages:
	push edx
	push ebx

	call paging_retrieve_pages
	cmp ecx, -1
	je .done

; Mark the pages as allocated
	xchg eax, ecx
.mark_page:
	push ecx
	cmp ecx, 1
	je .last_page_to_mark
	mov bl, 2
	jmp .next
.last_page_to_mark:
	mov bl, 3
.next:
	add ecx, eax
	dec ecx
    and cl, 3
    shl cl, 1
	shl bl, cl  ; bl = 0b11 << ((selected page % 4) * 2)
	pop ecx

	push ecx
	add ecx, eax
	dec ecx
	shr ecx, 2
	mov dl, [ecx+pages]
	or dl, bl
	mov [ecx+pages], dl
	pop ecx

	loop .mark_page

	mov ecx, eax
    shl ecx, 12 ; ecx *= 4096 = 2^12
    add ecx, emm_start
.done:
	pop ebx
	pop edx
	ret

; Input:
;	EAX = First page address
; Output:
;   None
paging_free_pages:
	ret

extended_memory_page_count:		dd 0

[section .bss]
pages:
    resb max_page_count

[section .text]