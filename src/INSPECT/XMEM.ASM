;----------------------------------------------------------------------------
;           Advanced Phantoms' eXtended memory manager. For
;                               internal use.
;----------------------------------------------------------------------------

XMS_INSTALL_CHECK PROC
;----------------------------------------------------------------------------
;                       Check if XMS driver is present.
;----------------------------------------------------------------------------

;locals
            mov         ax, 4300h
            int         2Fh
            cmp         al, 80h
            jnz         @@no_xms

;           XMS is OK, get driver FAR address.

            push        es
            push        bx
            mov         ax, 4310h
            int         2Fh
            mov         XMS_ADDRESS, bx
            mov         XMS_ADDRESS[2], es
            pop         bx
            pop         es
            clc                     ;           Driver is preset, no carry.
            ret
@@no_xms:
            stc                     ;           No XMS driver, CARRY is set.
            ret
XMS_INSTALL_CHECK ENDP


XMS_ADDRESS DW          2 DUP (?)


XMS_ALLOC   PROC
;----------------------------------------------------------------------------
;                       Allocate eXtended memory block
;           PARAMETERS:
;                       [bp+4] -> N_KBytes
;----------------------------------------------------------------------------

            push        bp
            mov         bp, sp
            mov         ah, 9
            mov         dx, [bp+4]

DB          0FFH, 1EH
DW          offset XMS_ADDRESS

            pop         bp
            ret         2
XMS_ALLOC   ENDP



XMS_FREE    PROC
;                       Free previously allocated block
;           Parameters:
;                       [bp+4] -> handle

            push        bp
            mov         bp, sp
            mov         ah, 0Ah
            mov         dx, [bp+4]
DB          0FFH, 1EH
DW          offset XMS_ADDRESS
            pop         bp
            ret         2
XMS_FREE    ENDP



XMS_MOVE    PROC
;----------------------------------------------------------------------------
;                    Move DATA to/from eXtended memory.
;           PARAMETERS:
;                       [bp+4] (DWORD) -> Number of bytes to move (even)
;                       [bp+8] (WORD) -> Source handle
;                       [bp+10] (DWORD) -> Offset into Source block
;                       [bp+14] (WORD) -> Destination handle
;                       [bp+16] (DWORD) -> Offset into Destination block
;----------------------------------------------------------------------------

;locals
	push	ax
	push	bx
	push	cx
	push	dx
	push	si

            push        bp
            mov         bp, sp
	lea         si, [bp+14]
	pop         bp
	push        ds
	push        ss
	pop         ds
	mov         ah, 0Bh

DB          2EH
DB          0FFH, 1EH
DW          offset XMS_ADDRESS

	pop         ds

	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret         16
XMS_MOVE    ENDP

