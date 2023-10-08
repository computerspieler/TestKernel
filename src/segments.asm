%define GDT(base,limit,flags,access) \
    ((limit) & 0xFF), (((limit) >> 8) & 0xFF), ((base) & 0xFF), \
    (((base) >> 8) & 0xFF), (((base) >> 16) & 0xFF), access, \
    (flags << 3) | (((limit) >> 16) & 0xF), (((base) >> 24) & 0xFF)

%define IDT(segment_selector,offset,flags) \
    ((offset) & 0xFF), (((offset) >> 8) & 0xFF), ((segment_selector) & 0xFF), \
    (((segment_selector) >> 8) & 0xFF), 0, flags, \
    (((offset) >> 16) & 0xFF), (((offset) >> 24) & 0xFF)

struc Task_State_Segment
	.link:		resw 1
				resw 1
	
	.esp0:		resd 1
	.ss0:		resw 1
				resw 1
	
	.esp1:		resd 1
	.ss1:		resw 1
				resw 1

	.esp2:		resd 1
	.ss2:		resw 1
				resw 1

	.cr3:		resd 1
	.eip:		resd 1
	.eflags:	resd 1
	.eax:		resd 1
	.ecx:		resd 1
	.edx:		resd 1
	.ebx:		resd 1
	.esp:		resd 1
	.ebp:		resd 1
	.esi:		resd 1
	.edi:		resd 1

	.es:		resw 1
				resw 1
	.cs:		resw 1
				resw 1
	.ss:		resw 1
				resw 1
	.ds:		resw 1
				resw 1
	.fs:		resw 1
				resw 1
	.gs:		resw 1
				resw 1
	.ldtr:		resw 1
				resw 1
				resw 1
	.iopb:		resw 1
	.ssp:		resd 1
endstruc

