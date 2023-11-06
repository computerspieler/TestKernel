%define PID_MASK	0x00FFFFFF

struc IPCNotification
	.first_qword:

; The size is in pages
	.size:			resb 1

	.pid_sender:	resb 3

; The address size is architecture dependent
	.address:		resb 4
endstruc
