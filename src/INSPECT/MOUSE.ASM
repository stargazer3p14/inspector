MouseEvent	PROC
;locals
;jumps
;
;	Mouse event handler. Functions:
;	Left button - select function
;	Right button - cancel (esc. emulation)
;	Center button - help (F10 emulation)
;
	push	cs
	pop	ds

	test	ax, 20h		; center button pressed?
	jz	@@right?
	mov	bh, OUR_PAGE
	call	help_entry
	retf

@@right?:
	test	ax, 8h		; right button pressed?
	jz	@@left?
	push	ds
	mov	ax, 40h
	mov	ds, ax
	mov	word ptr ds:[1Ah], 1Eh
	mov	word ptr ds:[1Ch], 20h
	mov 	word ptr ds:[1Eh], 11Bh
	pop	ds
	retf

@@left?:
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1		; set CX:DX == X:Y
	shr	dx, 1		; in symbols 8 by 8
	shr	dx, 1
	shr	dx, 1

	test	ax, 2		; left button pressed?
	jz	@@l_pressed?
	cmp	cx, 79
	jz	@@quit
	test	byte ptr PROG_STATUS, 1		; menu opened?
	jnz	@@menu
	or 	dx, dx		; top line?
	jnz	@@not_top
	cmp	cx, 3
	jb	@@quit
	cmp	cx, 71
	ja	@@quit
	mov	ah, 59		; 'F1'
	cmp	cx, 13
	jb	@@set_kbdbuf
	inc	ah
	cmp	cx, 24
	jb	@@set_kbdbuf
	inc	ah
	cmp	cx, 38
	jb	@@set_kbdbuf
	inc	ah
	cmp	cx, 49
	jb	@@set_kbdbuf
	inc	ah
	cmp	cx, 61
	jb	@@set_kbdbuf
	mov	ah, 68
@@set_kbdbuf:
	push	ds
	mov	cx, 40h
	mov	ds, cx
	mov	word ptr ds:[1Ah], 1Eh
	mov	word ptr ds:[1Ch], 20h
	mov	ds:[1Eh], ax
	pop	ds
@@quit:
	retf
@@not_top:
	cmp	dx, 6		; <6 = DUMP window
	jz	@@quit
	jnb	@@unass?
	cmp         cx, 62
	jb	@@num_fld
	mov	DPTR_LINE, dl
	dec	dx
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1
	add	dx, DUMP_OFFS
	mov	DUMP_PTR, dx
	sub	cx, 62
	add	DUMP_PTR, cx
	and	byte ptr PROG_STATUS, not 4
	inc	REFRESH_FL
	retf
@@num_fld:
	cmp	cx, 12
	jb	@@quit
	cmp	cx, 59
	ja	@@quit
	mov	DPTR_LINE, dl
	dec	dx
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1
	add	dx, DUMP_OFFS
	mov	DUMP_PTR, dx
	sub	cx, 12
	xchg	ax, cx
	mov	cl, 3
	div	cl
	sub	ah, ah
	add	DUMP_PTR, ax
	and	byte ptr PROG_STATUS[1], not 3
	or	byte ptr PROG_STATUS[1], 1
	and	byte ptr PROG_STATUS, not 4
	inc	REFRESH_FL
	retf

@@unass?:
	cmp	dx, 24
	jz	@@quit
	cmp	cx, 58		; <58 == UNASSEMBLE window
	jz	@@quit
	ja	@@regs?
	mov	UPTR_LINE, dl
	and 	byte ptr PROG_STATUS[1], not 3
	and	byte ptr PROG_STATUS, not 4
	inc	REFRESH_FL
	retf
@@regs?:
	cmp	dx, 13
	ja	@@flags?
	jz	@@ip?
	mov	REG_SELECTED, 0
	cmp	cx, 68
	jb	@@reg_added
	mov	REG_SELECTED, 6
@@reg_added:
	sub	dx, 7
	add	REG_SELECTED, dl
	and	byte ptr PROG_STATUS[1], not 3
	or 	byte ptr PROG_STATUS[1], 2
	inc	REFRESH_FL
	and	byte ptr PROG_STATUS, not 4
	retf
@@ip?:
	cmp	cx, 64
	jb	@@quit
	cmp	cx, 72
	ja	@@quit
	mov	REG_SELECTED, 12
	and	byte ptr PROG_STATUS[1], not 3
	or	byte ptr PROG_STATUS[1], 2
	inc	REFRESH_FL
	and 	byte ptr PROG_STATUS, not 4
	retf
@@flags?:
	cmp	dx, 16
	jz	@@quit
	ja	@@stack
	mov	CURR_FL, 0
	cmp	dx, 14
	jz	@@fl_added
	cmp	dx, 71
	jnb	@@quit
	mov	CURR_FL, 5
@@fl_added:
	sub	cx, 59
	shr	cx, 1
	shr	cx, 1
	add	CURR_FL, cl
	and	byte ptr PROG_STATUS[1], not 3
	or	byte ptr PROG_STATUS[1], 2
	inc	REFRESH_FL
	or	byte ptr PROG_STATUS, 4
	retf

@@stack:
	sub	dx, 17
	shl	dx, 1
	neg	dx
	add	dx, STACK_OFFS
	mov	STACK_PTR, dx
	and	byte ptr PROG_STATUS[1], not 3
	or	byte ptr PROG_STATUS[1], 3
	and	byte ptr PROG_STATUS, not 4
	inc	REFRESH_FL
	retf

@@menu:
	mov	al, MAIN_MENU
	dec	ax
	mov	ah, 12
	mul	ah
	mov	si, offset FILE_MENU
	add	si, ax
	cmp	cl, [si+2]
	jb	@@quit
	cmp	cl, [si+3]
	ja	@@quit
	cmp	dl, 2
	jb	@@quit
	mov	al, [si+4]
	add	al, 2
	cmp	dl, al
	ja	@@quit
	sub	dl, 2
	mov	CHOISE, dl
	push	ds
	mov	ax, 40h
	mov	ds, ax
	mov	word ptr ds:[1Ah], 1Eh
	mov	word ptr ds:[1Ch], 20h
	mov	word ptr ds:[1Eh], 1C0Dh
	pop	ds
	retf
@@l_pressed?:
	retf

MouseEvent	ENDP
