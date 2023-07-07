;
;           BreakPoint Management
;
MAXBREAKS	equ	128
STDBREAK	equ	0CCh
SPECBREAK	equ	0CDh

BREAK_INT	db	3
NEXT_INSTR	DW	?, ?		; address of next instruction
				; without a control transfer

PUTBREAK    PROC        NEAR
;;jumps
	cld
	push        bp
	mov         bp, sp
	mov         bx, [bp+4]
	pop         bp

	mov         ax, [bx]
	push        es
	push        cs
	pop         es
	mov         di, BP_OFFS
	mov         cx, MAXBREAKS
find_bp:
repne       scasw
	jne	@F
	mov	dx, [bx+2]
	cmp	dx, [di+offset BP_SEGS-offset BP_OFFS-2]
	jne	find_bp
@@:
	pop         es
	jne         @@process

;	mov         di, BP_SEGS
;	mov         ax, [bx+2]
;	push        es
;	push        cs
;	pop         es
;	mov         cx, MAXBREAKS
;repne       scasw
;	pop         es
;	jne         @@process

	mov         ax, 1		; BreakPoint already exists
	stc
	ret         2
@@process:

	sub         al, al
	mov         cx, MAXBREAKS
	mov         di, BP_SIGN
repne       scasb
	je          @@continue1
	mov         ax, 2		; No BreakPoints available
	stc
	ret         2
@@continue1:
	push        ds
	inc         cx
	mov         di, MAXBREAKS
	sub         di, cx
	lds         si, [bx]		; DS:SI -> BreakPoint address
	mov         ax, [si]
	mov         cx, ds
	pop         ds
	shl         di, 1
	mov         word ptr[di+ BP_OFFS], si
	mov         word ptr[di+ BP_SEGS], cx
	mov         [di+ BP_BYTE], ax
	shr         di, 1
	not         byte ptr[di+ BP_SIGN]	; sign BreakPoint put
	clc
	ret         2
PUTBREAK    ENDP


DELBREAK    PROC        NEAR
;;jumps
	cld
	push        bp
	mov         bp, sp
	mov         bx, [bp+4]
	pop         bp

	mov         ax, [bx]
	push        es
	push        cs
	pop         es
	mov         di, BP_OFFS
	mov         cx, MAXBREAKS
find_bp:
repne       scasw
	jne         @@no_break
	mov	dx, [bx+2]
	cmp	dx, [di+offset BP_SEGS-offset BP_OFFS-2]
	jne	find_bp
	jmp	@@process

;repne       scasw
;	mov         di, BP_SEGS
;	pop         es
;	mov         ax, [bx+2]
;	push        es
;	push        cs
;	pop         es
;	mov         cx, MAXBREAKS
;repne       scasw
;	jne         @@no_break
;	jmp         @@process
@@no_break:
	pop         es
	mov         ax,1
	stc
	ret         2
@@process:
	mov         di, MAXBREAKS
	inc         cx
	sub         di, cx
	pop         es
	mov         byte ptr [di+BP_SIGN], 0
	shl         di, 1
	mov         word ptr [di+BP_OFFS], 0
	mov         word ptr [di+BP_SEGS], 0
	xor         ax, ax
	clc
	ret         2
DELBREAK    ENDP


STOREBRK    PROC        NEAR
;;jumps
	mov         cx, MAXBREAKS
@@loop1:
	mov         di, MAXBREAKS
	sub         di, cx
	cmp         byte ptr [di+BP_SIGN], 0
	je          @@end_loop
	push        es
	shl         di, 1
	mov         es, [di+BP_SEGS]
	mov         si, [di+BP_OFFS]
	mov         ax, es
	cmp         ax, USER_CS
	jnz         @@OK
	cmp         si, USER_IP
	jz          @F
@@OK:
	mov         byte ptr es:[si], STDBREAK
	cmp	BREAK_INT, 3
	jz	@F
	mov	byte ptr es:[si], SPECBREAK
	mov	al, BREAK_INT
	mov	byte ptr es:[si+1], al
@@:
	pop         es
@@end_loop:
	loop        @@loop1
	ret
STOREBRK    ENDP


UNSTORBRK   PROC        NEAR
;;jumps
	mov         cx, MAXBREAKS
@@loop1:
	mov         di, MAXBREAKS
	sub         di, cx
	cmp         byte ptr[di+BP_SIGN], 0
	je          @@end_loop
	push        es
	shl         di, 1
	mov         es, [di+BP_SEGS]
	mov         si, [di+BP_OFFS]
@@OK:
	mov         ax, [di+BP_BYTE]
	mov         es:[si], ax
	pop         es
@@end_loop:
	loop        @@loop1
	ret
UNSTORBRK   ENDP


RUN         PROC        NEAR
;;jumps
	push        es
	push        di
	mov         es, USER_CS
	mov         di, USER_IP
	cmp	BREAK_INT, 3
	jnz	@F
	cmp         byte ptr es:[di], STDBREAK
	jz          no_run
@@:
	mov	al, SPECBREAK
	mov	ah, BREAK_INT
	cmp	es:[di], ax
	jnz	@@OKay
	inc	USER_IP
no_run:
	pop         di
	pop         es
	inc         USER_IP
	call	FILL_QUEUE
	ret
@@OKay:
	pop	di
	pop	es
	COPY_QUEUE
	GET_NEXT_INSTR
	call        SAVE_MAIN_WIND
	call        LOAD_USER_VIDEO
	call        PREPARE_VECTORS
	call        STOREBRK

            mov	ax, 351Bh
            int	21h
            mov	ORIG_INT1B, bx
            mov	ORIG_INT1B[2], es
            mov	ax, 251Bh
            mov	dx, offset INT_1B
            int	21h

            mov	ax, 3508h
            int	21h
            mov	ORIG_INT8, bx
	mov	ORIG_INT8[2], es
            mov	ax, 2508h
            mov	dx, offset INT_8
	int	21h

            push	cs
            pop	es

	STORE_OUR_REGS
	LOAD_USER_REGS
	push        cs:USER_FL
	push        cs:USER_CS
	push        cs:USER_IP
	iret
int3entry::
	pop         cs:USER_IP
	pop         cs:USER_CS
	pop         cs:USER_FL
	STORE_USER_REGS
	LOAD_OUR_REGS
	dec         USER_IP
	cmp	BREAK_INT, 3
	jz	@F
	dec	USER_IP
@@:
	mov	ax, USER_IP
	cmp	ax, NEXT_INSTR	; if a single instr. executed
				; shift queue
	jnz	int8entry
	mov	ax, USER_CS
	cmp	ax, NEXT_INSTR[2]
	jnz         int8entry

	call	SHIFT_QUEUE
	jmp	short	@F
int8entry::
	call	FILL_QUEUE		; if several instructions exe-
				; cuted or control transfer
				; or interrupt 8 entered
				; reset queue
@@:
	mov	BREAK_FLAG, 0
	mov	ax, 251Bh
	lds	dx, dword ptr ORIG_INT1B
	int	21h
	mov	ax, 2508h
	lds	dx, dword ptr cs:ORIG_INT8
	int	21h
	push	cs
	pop	ds
int9entry::
	push        USER_CS
	push        USER_IP
	pop         UNASS_PTR
	pop         UNASS_SEG
	mov         ax, UNASS_PTR
	cmp         ax, UNASS_BOTT
	ja          @@chg_off
	cmp         ax, UNASS_OFFS
	jb          @@chg_off
	jmp         @@OK
@@chg_off:
	mov         UNASS_OFFS, ax
            mov	al, UNASS_TOP
            mov	UPTR_LINE, al
@@OK:
	call        UNSTORBRK
	call        LOAD_VECTORS
	call        SAVE_USER_VIDEO
	call        RESTORE_MAIN_WIND
	ret
RUN         ENDP
