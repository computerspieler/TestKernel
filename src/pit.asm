%define PIT_DATA(channel)       (0x40 + channel)
%define PIT_COMMAND             0x43

%define PIT_CMD_CHANNEL(i)      (i << 6)
%define PIT_CMD_READ_BACK       0xC0
%define PIT_ACCESS_LATCH_COUNT  0x0
%define PIT_ACCESS_LOBYTE       0x10
%define PIT_ACCESS_HIBYTE       0x20
%define PIT_ACCESS_HILOBYTE     (PIT_ACCESS_LOBYTE | PIT_ACCESS_HIBYTE)
%define PIT_OPERATING_MODE(i)   (i << 1)

pit_init:
; Channel 0 will be used for task switching
	mov al, PIT_CMD_CHANNEL(0) | PIT_ACCESS_HILOBYTE | PIT_OPERATING_MODE(2)
	out PIT_COMMAND, al

	mov ax, 1024
	out PIT_DATA(0), al
	mov al, ah
	out PIT_DATA(0), al

    ret
