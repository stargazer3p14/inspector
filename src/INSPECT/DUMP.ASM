DUMP        PROC
;locals
		; for DUMP proc. must be set:
		; DUMP_SEG -> seg (dump)
		; DUMP_OFFS -> offset (dump)
		; DUMP_BOTT -> bottom (window)
		; DUMP_TOP -> top (window)
	push        bp
	mov         bp, sp
	push        es
	push        ax
	push        bx
	push        cx
	push        dx
	push        si
	push        di

            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2		;hide mouse pointer
            int	33h
@@mouse_OK1:
	mov         bl, byte ptr PROG_STATUS[1]
	and         bl, 3
	cmp         bl, 1
	jnz         @@n_act
	mov         bl, AC_WIND_ATTR
	jmp         short       @@save_bl
@@n_act:
	mov         bl, ATTRIB
@@save_bl:
	mov         @@ATTR, bl
	mov         dh, DUMP_TOP
	mov         cl, DUMP_BOTT
	sub         cl, DUMP_TOP
	sub         ch, ch
	inc         cx
	mov         bx, DUMP_OFFS
	mov         es, DUMP_SEG
@@loop:
	push        cx
	mov         di, offset @@DUMP_STR
	mov         cx, 39
	mov         ax, '  '
@@store_loop:
	mov         [di], ax
	inc         di
	inc         di
	loop        @@store_loop
	mov         si, offset @@DUMP_STR[11]
	mov         di, offset @@DUMP_STR[61]
	mov         ax, 12
	push        ax
	mov         ax, offset @@DUMP_STR
	push        ax
	mov         ax, es
	call        INT_TO_STR
	mov         @@DUMP_STR[4], ':'
	mov         ax, 12
	push        ax
	mov         ax, offset @@DUMP_STR[5]
	push        ax
	mov         ax, bx
	call        INT_TO_STR
	mov         cx, 16
@@loop1:
	mov         ax, 4
	push        ax
	push        si
	mov         al, es:[bx]
	and         al, al
	jz          @@al_0
	mov         [di], al
	jmp         short       @@al_OK
@@al_0:
	mov         byte ptr [di], ' '
@@al_OK:
	call        INT_TO_STR
	inc         bx
	inc         di
	add         si, 3
	loop        @@loop1
	
	push        bx
	mov         bh, OUR_PAGE
	mov         bl, @@ATTR
	gotoxy      1
	mov         si, offset @@DUMP_STR
	mov         cx, 78
	call        CPUTSTR
	pop         bx
	pop         cx
	inc         dh
	loop        @@loop
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1
            int	33h
@@mouse_OK2:

	pop         di
	pop         si
	pop         dx
	pop         cx
	pop         bx
	pop         ax
	pop         es
	pop         bp
	ret
@@DUMP_STR  DB          78 DUP (?)
@@ATTR      DB          ?
DUMP        ENDP
