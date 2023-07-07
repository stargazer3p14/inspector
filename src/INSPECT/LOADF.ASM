LOAD_FILE	PROC
;
;	[bp+4] -> filename
;
	push	bp
	mov	bp, sp
	mov	dx, [bp+4]		; DS:DX -> name
	pop	bp

	push	bx
	mov	ah, 50h
	mov	bx, cs
	int	21h
	pop	bx

	mov	es, WORK_AREA	; free work area
	mov	ah, 49h
	int	21h
	test	byte ptr PROG_STATUS, 8	; program is in progress?
	jz	@F

	mov	es, PROG_ENV
	mov	ah, 49h
	int	21h
@@:
	push	cs
	pop	es

	mov	bx, offset @@L_FPARAMS
	mov	word ptr [bx], 0	; copy INSPECTOR's environment
	mov	word ptr [bx+2], COM_LINE  ; command-line arguments
	mov	[bx+4], cs
	mov	word ptr [bx+6], 5Ch		; 1st FCB
	mov	[bx+8], cs
	mov	word ptr [bx+0Ah], 6Ch	; 2nd FCB
	mov	[bx+0Ch], cs

	mov	@@L_FINSP_STK, sp
	mov	@@L_FINSP_STK[2], ss
	mov	ax, 4B01h		; Load & don't execute
	int	21h
	jnc	loadOK

	cmp	ax, 8
	jnz	@F
	mov	ax, 0
@@:
	cmp	ax, 11
	jnz	@F
	mov	ax, 13
@@:
	add	ax, 2
	mov	ERRORCODE, ax
	call	ERR_HANDLER
	stc
	retn	2
loadOK:
	mov	ah, 51h		; Get current process ID (PSP)
	int	21h		; bx=process's PSP

	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	WORK_AREA, bx
	mov	USER_DS, bx		; USER's DS & ES -> PSP
	mov	USER_ES, bx
	mov	DUMP_SEG, bx

	push	es
	mov	es, bx
	mov	ax, es:[2Ch]
	mov	PROG_ENV, ax
	pop	es

	mov	ax, @@L_FPARAMS[0Eh]	; Init. SP
	mov	USER_SP, ax
	mov	ax, @@L_FPARAMS[10h]	; Init. SS
	mov	USER_SS, ax
	mov	ax, @@L_FPARAMS[12h]	; Init. IP
	mov	USER_IP, ax
	mov	UNASS_OFFS, ax
	mov	UNASS_PTR, ax
	mov	ax, @@L_FPARAMS[14h]	; init. CS
	mov	USER_CS, ax
	mov	UNASS_SEG, ax

	mov	DUMP_OFFS, 0
	mov	DUMP_PTR, 0
	and         byte ptr PROG_STATUS, 11000111b
	or          byte ptr PROG_STATUS, 00011000b
				; copy file name
	mov         di, FILE_NAME+62
	mov         al, '\'
	mov         cx, 63
	std
repnz       scasb
	jnz         @@L_Fchk_02
	inc         di
	inc         di
	jmp         short       @@L_Fhere
@@L_Fchk_02:
	mov         di, FILE_NAME
	mov         cx, 63
	mov         al, ':'
	cld
repnz       scasb
	jz          @@L_Fhere
	mov         di, FILE_NAME
@@L_Fhere:
	mov         si, di
	mov         cx, si
	mov         ax, WORK_AREA
	dec         ax
	mov         es, ax
	mov         di, 8
	cld
@@L_Fprocess:
	movsb
	cmp         byte ptr [si-1], '.'
	jnz         @@L_Fprocess
	mov         byte ptr es:[di-1], 0
	push        cs
	pop         es
	mov         si, cx
	mov         di, offset LD_MODULE
	mov         cx, 12
@@L_Floop_here:
	lodsb
	and         al, al
	jnz         @@L_Fhere_OK
	mov         al, ' '
@@L_Fhere_OK:
	stosb
	loop        @@L_Floop_here

	mov	bh, OUR_PAGE
	or          byte ptr PROG_STATUS, 8
	clc
	retn    2

@@L_FPARAMS	DW	10 dup (0)
@@L_FINSP_STK	DW	2 dup (?)

LOAD_FILE       ENDP
