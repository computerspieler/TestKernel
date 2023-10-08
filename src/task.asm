struc Process
	.tss:		resb Task_State_Segment_size
	.state:		resb 1
endstruc

