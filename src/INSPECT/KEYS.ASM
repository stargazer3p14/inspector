REFRESH_FL	DB	0		; set whether display
				; refresh is needed.

KEYS	PROC
;locals

@@HELP_TOPICS EQU       49
@@ERR_CODES EQU         14
	cmp	ah, 68		; F10?
	jnz	@@F6?
	call	help_entry
	retn

@@F6?:
	cmp	ah, 64		; F6?
	jnz	@@del?
	test	byte ptr PROG_STATUS, 8	; Module is loaded?
	jz	@@exit		; if no-exit
	push	bx
	call	CLEAR_PROG
	mov	ax, FILE_NAME
	push	ax
	call	LOAD_FILE
	jc	@@clear_1

	mov         ax, USER_SP
	add         ax, 6
	mov         STACK_OFFS, ax
	sub         ax, ax
	pop	bx
	jmp	@@exit
@@del?:
	cmp         ah, 83                  ;Del?
	jnz         @@exit
            push        ds
            push        ax
            sub         ax, ax
            mov         ds, ax
            test        byte ptr ds:[417h], 3   ;Shift?
	pop	ax
	pop	ds
	jz	@@exit

@@clear:

	call	CLEAR_PROG
@@clear_1::
            mov         ah, 48h
            mov         bx, 1000h
	int         21h
	jnc	@F
	mov	ah, 48h
	int	21h
@@:
            mov         WORK_AREA, ax
            mov         UNASS_SEG, ax
            mov         DUMP_SEG, ax
            mov         UNASS_PTR, 100h
            mov         UNASS_OFFS, 100h
            mov         DUMP_OFFS, 0
            mov         DUMP_PTR, 0

            mov         USER_CS, ax
            mov         USER_DS, ax
            mov         USER_ES, ax
            mov         USER_SS, ax
            mov         USER_IP, 100h
            mov         USER_AX, 0
            mov         USER_BX, 0
            mov         USER_CX, 0
            mov         USER_DX, 0
            mov         USER_SI, 0
            mov         USER_DI, 0
            mov         USER_SP, -2
            mov         USER_BP, 0
            mov         dx, WORK_AREA
            mov         ah, 26h
            int         21h
            mov         ds, WORK_AREA
            mov         word ptr ds:[-2], 0
            push        cs
            pop         ds
            mov         bh, OUR_PAGE
            gotoxy      64, 24
            mov         si, offset NO_MODULE
            mov         cx, 12
            mov         bl, TOP_ATTR
            call        CPUTSTR

            mov         ax, USER_SP
            add         ax, 6
            mov         STACK_OFFS, ax
            sub         ax, ax

@@exit:
	retn

help_entry::
	push	bx
            push	cx
            push	dx
            push	si
            push	di

            wherexy
            mov         @@CUR_LOC, dx
            mov         @@CUR_FORM, cx
            or          ch, 00100000b
            mov         ah, 1
            int         10h

	mov	di, offset INSP_PATH
	mov	cx, -1
	sub	al, al
	cld
		repne	scasb
	mov	al, '\'
	std
		repne	scasb
	add	di, 2
	mov	si, offset @@HELP_FILE
	mov	cx, @@HELP_FILE_L
	cld
		rep	movsb

	QOPEN       INSP_PATH, 0
            jc          @@help_fault
            mov         @@HELP_N, ax
            cmp         ERRORCODE, 0
            jz          @@help_do
            MOVE_PTR    @@HELP_N, 0, @@HELP_TOPICS*1024, 0
            mov         ax, ERRORCODE
            jmp         @@code_got
@@help_do:
            mov         al, HELP_CODE
            cbw
@@code_got:
            dec         ax
            shl         ax, 10
            MOVE_PTR    @@HELP_N, 0, ax, 1
            QREAD       @@HELP_N, HELP_BUF, 1024
            QCLOSE      @@HELP_N
            mov         di, HELP_BUF
            mov         cx, 1024
            cld
@@unsiph_loop:
            mov         al, [di]
            xor         al, 'S'
            neg         al
            cmp         al, 0Dh
            jnz         @@n_CR
            sub         al, al
            jmp         @@stos
@@n_CR:
            cmp         al, -2
            jnz         @@stos
            sub         al, al
@@stos:
            stosb
            loop        @@unsiph_loop

            $STO_SCREEN 10, 5, 70, 20, SCREEN_BUF_2, OUR_PAGE
            $LITTLE_FRAME 10, 5, 70, 20, MENU_ATTR
            mov         bl, MENU_ATTR
            gotoxy      38, 6
	mov         si, offset @@KEY_TTL
            mov         cx, 4
            call        CPUTSTR
            mov         HELP_START, HELP_BUF
            call        PRINT_HELP
@@kbd_loop:
	or	PROG_STATUS, 8000h
            sub         ah, ah
            int         16h
            cmp         ah, 72                  ;Up
            jnz         @@down?
            mov         di, HELP_START
            cmp         di, HELP_BUF
            jz          @@end_st_loop
            lea         di, [di-2]
            sub         al, al
            std
@@chk_st_loop:
            cmp         di, HELP_BUF
            jz          @@end_st_loop
            scasb
            jnz         @@chk_st_loop
            inc         di
            inc         di
@@end_st_loop:
            mov         HELP_START, di
            call        PRINT_HELP
            jmp         @@kbd_loop
@@down?:
            cmp         ah, 80
            jnz         @@esc?
            call        CHK_LAST
            jc          @@kbd_loop
            mov         di, HELP_START
            sub         al, al
            mov         cx, 60         
repnz       scasb
            mov         HELP_START, di
            call        PRINT_HELP
            jmp         @@kbd_loop
@@esc?:
            cmp         ah, 1
            jz          @@exitten
            cmp         ah, 28
            jz          @@exitten
            cmp         ah, 57
            jnz         @@kbd_loop
@@exitten:
	and	PROG_STATUS, 7FFFh
	push	cs
            pop	ds
            $LOD_SCREEN 10, 5, 70, 20, SCREEN_BUF_2, OUR_PAGE
            mov         dx, @@CUR_LOC
            gotoxy
            mov         cx, @@CUR_FORM
            mov         ah, 1
            int         10h
            sub         ax, ax
@@help_fault:
	pop	di
            pop	si
            pop	dx
            pop	cx
	pop	bx
	sub	ax, ax
	retn

@@KEY_TTL   DB          'HELP'
@@OUT_STR   DB          60 DUP (?)
@@HELP_FILE DB          'INSP.HLP', 0
@@HELP_FILE_L	EQU	$ - @@HELP_FILE
@@HELP_N    DW          ?
@@CUR_LOC   DW          ?
@@CUR_FORM  DW          ?
@@MOUSE_X	DB	?
@@MOUSE_Y	DB	?

KEYS	ENDP

HELP_START  DW          ?

PRINT_HELP  PROC
;locals
            mov         dh, 8
            mov         cx, 12
            mov         si, HELP_START
            mov         di, si
@@main_loop:
            push        cx
            gotoxy      13
            mov         cx, 56
            mov         ax, 920h
            int         10h
            call        CPUTSTR
            sub         al, al
            cld
            mov         cx, 60
repnz       scasb
            mov         si, di
            inc         dh
            pop         cx
            dec         cx
            jcxz        @@OK
            jmp         @@main_loop
@@OK:
            ret
PRINT_HELP  ENDP


CHK_LAST    PROC
;locals

;           Checks if the current help window is the last
;           available on this topic

            cld
            mov         di, HELP_START
            mov         cx, 12
            sub         al, al
@@loop_1:
            push        cx
            mov         cx, 60
repnz       scasb
            pop         cx
            loop        @@loop_1
            scasb
            jnz         @@avail
            stc
            ret
@@avail:
            clc
            ret

CHK_LAST    ENDP


GETCH	PROC
;locals
	cmp	REFRESH_FL, 0
	jz	@@getch
	call	REFRESH
	mov	REFRESH_FL, 0
	sub	ax, ax
	retn
@@getch:
	mov	ah, 1
	int	16h
	jz	GETCH
	cli
	push	ds
	push	ax
	mov	ax, 40h
	mov	ds, ax
	mov         ax, ds:[80h]
	mov	ds:[1Ah], ax
	mov	ds:[1Ch], ax
	pop	ax
	pop	ds
	sti
	call	KEYS
	retn
GETCH	ENDP


CLEAR_PROG	PROC
;
;	Clears currently loaded program
;
	push	es
	push	bx
	push	cx
	push	dx
	push	si
	push	di

;--------------------------- Reload program ---------------------------------
	and         byte ptr PROG_STATUS, 11000111b
	mov	ah, 50h
	mov	bx, cs		; set INSPECTOR's current
	int	21h		; process's ID

	mov	ax, PROG_ENV
	dec	ax
	mov	es, ax
	mov	es:[01h], cs
	inc	ax
	mov	es, ax
	mov	ah, 49h
	int	21h

	mov         ax, WORK_AREA
	dec	ax
	mov	es, ax
	mov	es:[01h], cs
	inc	ax
	mov	es, ax
	mov         ah, 49h
	int         21h

	push        ds
            pop         es
            mov         di, BP_SEGS
            sub         ax, ax
            mov         cx, 640
            cld
rep         stosw

	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx

	pop	es
	retn
CLEAR_PROG	ENDP
