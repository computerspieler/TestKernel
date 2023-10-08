[BITS 16]
[ORG 0x7c00]

%define buffer 0x7E00
%define output_buffer 0x1000

%define directory_entry_size 32
%define OEM_name "CYBOS0.1"
%define bytes_per_sector 512
%define sector_per_cluster 1
%define reserved_sector_count 1
%define FAT_copies_count 2
%define root_directory_entries_count 224
%define sector_count_in_fs 2880
%define media_descriptor_type 0xF0
%define sector_per_FAT 9
%define sector_per_cylinder 18
%define head_count 2
%define hidden_sector_count 0

%define BREAK  xchg bx, bx

%define first_data_sector (reserved_sector_count + FAT_copies_count * sector_per_FAT + (directory_entry_size * root_directory_entries_count) / bytes_per_sector)

	jmp short start

	nop
	
	db "CYBOS0.1"
	dw bytes_per_sector
	db sector_per_cluster
	dw reserved_sector_count
	db FAT_copies_count
	dw root_directory_entries_count
	dw sector_count_in_fs
	db media_descriptor_type
	dw sector_per_FAT
	dw sector_per_cylinder
	dw head_count
	dd hidden_sector_count
	dd 0				; Large sector count
	db 0				; Drive number
	db 0				; Windows NT's flags
	db 0x29				; Signature
	dd 0				; The volume's id
	db "CYBERDISK  "	; The volume's label
	db "FAT12   "		; The file system's name

start:
	cli

	xor ax, ax
	mov ds, ax
	mov es, ax

	mov ax, 0x8000
	mov ss, ax
	mov sp, 0xF000

	mov [boot_drive], dl

; Put the screen in 80x25
	mov ax, 3
	int 10h

; Get the extended memory size
detect_extended_memory:
	clc
	mov ah, 0x88
	int 0x15
	jc short .done

	mov [extended_memory_size], ax

.done:
	cld
; Enable the A20 if not done
	push es 
	xor ax, ax ; AX <- 0x0
	mov es, ax

	mov di, 0x7DFE
	mov bx, [es:di]

	not ax ; AX <- 0xFFFF
	mov es, ax
	mov di, 0x7E0E
	mov cx, [es:di]

	cmp bx, cx

	pop es

	je a20_already_enable

; This code derived from the wiki.osdev's source code
	call wait_a20.main

	mov al, 0xAD
	out	0x64, al
	call wait_a20.main

	mov al, 0xD0
	out	0x64, al
	call wait_a20.secondary

	in	al, 0x60
	push eax
	call wait_a20.main

	mov al, 0xD1
	out	0x64, al
	call wait_a20.main

	pop eax
	or al, 2
	out	0x60, al
	call wait_a20.main

	mov al, 0xAE
	out	0x64, al
	call wait_a20.main

a20_already_enable:

; Read the root directory's entries
	mov ax, FAT_copies_count * sector_per_FAT + reserved_sector_count

	call lba_to_chs
	mov bx, buffer
	mov al, (directory_entry_size * root_directory_entries_count) / bytes_per_sector
	call read_sector

	mov cx, root_directory_entries_count
	mov di, buffer

search_for_file:
	push cx

	mov ecx, 11
	mov si, file_name
	repe cmpsb
	je file_found
	
	pop cx
	
	add di, directory_entry_size-11

	loop search_for_file
	
; If the file wasn't found
	jmp $

file_found:
	sub di, 11
	mov edx, [di + 28]
	mov [file_size], edx

	mov dx, [di + 20]	; Read the file's first cluster in EDX
	shr edx, 16
	mov dx, [di + 26]
	mov [file_cluster], edx

; Read the FAT
	mov ax, reserved_sector_count
	call lba_to_chs
	mov bx, buffer
	mov al, sector_per_FAT
	call read_sector

	mov bx, output_buffer

; Read the clusters
read_file:
	mov eax, [file_cluster]
	cmp eax, 0xFF8
	jge move_to_protected_mode

	; Retrieve the sector associated with the cluster
	sub eax, 2
	mov ecx, sector_per_cluster
	mul ecx
	add eax, first_data_sector

	push bx
	
	call lba_to_chs
	mov al, sector_per_cluster
	call read_sector

	; Get the next cluster
	mov eax, [file_cluster]
	shr eax, 1
	add eax, [file_cluster]
	
	mov bx, [eax + buffer]
	mov eax, [file_cluster]
	and eax, 1
	jnz .odd
.even:
	and bh, 0x0F
	jmp .next
.odd:
	shr bx, 4
.next:
	mov [file_cluster], ebx

	pop bx
	add bx, bytes_per_sector * sector_per_cluster

	jmp read_file

;===============
;|| Fonctions ||
;===============
lba_to_chs:
	; CH = (AL ÷ SPT) ÷ HPC
	; DH = (AL ÷ SPT) mod HPC
	; CL = (AL mod SPT) + 1
	
	mov dl, sector_per_cylinder
	div dl

	inc ah
	mov cl, ah

	xor ah, ah
	mov dl, head_count
	div dl

	mov ch, al
	mov dh, ah

	ret
	
read_sector:
	mov ah, 0x02
	mov dl, [boot_drive]
	
	int 13h

	ret

wait_a20:
.main:
	in al, 0x64
	test al, 2
	jnz .main
	ret
.secondary:
	in al, 0x64
	test al, 1
	jz .secondary
	ret

; It has to be the last function declared
move_to_protected_mode:
	lgdt [gdt_ptr]
	
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp 0x8:.next

[bits 32]
.next:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov ax, [extended_memory_size]

	jmp output_buffer

;===============
;|| Variables ||
;===============
boot_drive:
	db 0

extended_memory_size:
	dw 0

file_size:
	dd 0
file_cluster:
	dd 0
file_name:
	db "KERNEL  BIN"

gdt:
	dd 0, 0		; Null descriptor
	db 0xFF, 0xFF, 0x0, 0x0, 0x0, 0b10011010, 0b11001111, 0x0	; Kernel code's segment
	db 0xFF, 0xFF, 0x0, 0x0, 0x0, 0b10010010, 0b11001111, 0x0	; Kernel data's segment
.end:

gdt_ptr:
	dw gdt.end - gdt - 1
	dd gdt

times 510-($ - $$) db 0
dw 0xAA55
