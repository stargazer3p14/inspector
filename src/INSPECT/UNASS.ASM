
UNASSEMBLE  PROC
;locals
                        ;UNASS_LEFT -> Left
                        ;UNASS_TOP -> Top
                        ;UNASS_RIGHT -> Right
                        ;UNASS_DOWN -> Bottom
                        ;Procedure outputs DASS

            push        bp
            mov         bp, sp
            push        bx
            push        cx
            push        dx
            push        si
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2
            int	33h
@@mouse_OK1:
	REBUILD_FRAME

IFDEF	PREFETCH_EMUL
	push	USER_IP
	push	ds
	mov	ax, offset QueueBuf
	push	ax
	mov	di, TEST_FIELD
	push	di
	mov	cx, 50
	sub	al, al
rep	stosb
	call	DASS
	GOTOXY	20, 6
	mov	si, TEST_FIELD+7      	; SI -> instruction mnemo
	cmp	byte ptr [si], 0
	jnz	@F
	mov	ax, 4
	push	ax
	mov	ax, TEST_FIELD+13
	push	ax
	mov	al, QueueBuf
	call	INT_TO_STR
@@:
	mov	bl, SELECT_ATTR
	mov	cx, 6
	call	CPUTSTR
	WHEREXY
	GOTOXY
	mov	al, ' '
	call	CPUTCHAR
	inc	dx
	GOTOXY
	mov	si, TEST_FIELD+41
	mov	cx, 9
	call	CPUTSTR
	mov	si, TEST_FIELD+13
	mov	cx, 12
	call	CPUTSTR
	mov	si, TEST_FIELD+25
	cmp	byte ptr [si], 0
	jz	@F
	WHEREXY
	GOTOXY
	mov	al, ','
	call	CPUTCHAR
	inc	dx
	GOTOXY
	call	CPUTSTR
	mov	si, TEST_FIELD+37
	cmp	byte ptr [si], 0
	jz	@F
	WHEREXY
	GOTOXY
	mov	al, ','
	call	CPUTCHAR
	inc	dx
	GOTOXY
	call	CPUTSTR
@@:
ENDIF

u_wind_output:
            mov         dh, UNASS_TOP
            mov         bx, UNASS_OFFS
dass_loop:
            mov         word ptr VAR_ADDR[2], 9090h         ; Internal var
            push        bx
            push        UNASS_SEG
            push        bx
            mov         di, offset FIELD
            push        di
            mov         cx, 25
            cld
            sub         ax, ax
rep         stosw
            call        DASS

            mov         di, offset @@UNASS_STR
            mov         ax, '  '
            mov         cx, 39
            cld
rep         stosw
            mov         ax, 12
            push        ax
            mov         ax, offset @@UNASS_STR
            push        ax
            mov         ax, UNASS_SEG
            call        INT_TO_STR
            mov         @@UNASS_STR[4], ':'
            mov         ax, 12
            push        ax
            mov         ax, offset @@UNASS_STR[5]
            push        ax
            mov         ax, bx
            call        INT_TO_STR
            mov         si, offset FIELD[1]
            mov         di, offset @@UNASS_STR[10]
            cld
            mov         cl, FIELD
            sub         ch, ch
            or          cx, cx
            jnz         @@loop0
            inc         cx
@@loop0:
            mov         ax, 4
            push        ax
            push        di
            lodsb
            call        INT_TO_STR
            inc         di
            inc         di
            loop        @@loop0
            cmp         FIELD[7], 0
            jnz         @@opers
            mov         word ptr FIELD[7], 'BD'
            mov         ax, 4
            push        ax
            mov         ax, offset FIELD[13]
            push        ax
            mov         al, FIELD[1]
            call        INT_TO_STR
@@opers:
            mov         si, offset FIELD[7]
            mov         di, offset @@UNASS_STR[23]
            mov         cx, 6
@@loop1:
            lodsb
            and         al, al
            jz          @@end_loop1
            stosb
            loop        @@loop1
@@end_loop1:
            mov         di, offset @@UNASS_STR[30]
            cmp         FIELD[41], 0
            jz          @@no_lab
            mov         si, offset FIELD[41]
            mov         cx, 9
@@loop2:
            lodsb
            and         al, al
            jz          @@end_loop2
            stosb
            loop        @@loop2
@@end_loop2:
            inc         di
@@no_lab:
            mov         si, offset FIELD[13]
            mov         cx, 12
@@loop3:
            lodsb
            and         al, al
            jz          @@end_loop3
            stosb
            loop        @@loop3
@@end_loop3:
            cmp         FIELD[25], 0
            jz          @@output
            mov         word ptr [di], ' ,'
            inc         di
            inc         di
            mov         si, offset FIELD[25]
            mov         cx, 12
@@loop4:
            lodsb
            and         al, al
            jz          @@end_loop4
            stosb
            loop        @@loop4
@@end_loop4:
            cmp         FIELD[37], 0
            jz          @@output
            mov         word ptr [di], ' ,'
            inc         di
            inc         di
            mov         si, offset FIELD[37]
            mov         cx, 4
@@loop5:
            lodsb
            and         al, al
            jz          @@output
            stosb
            loop        @@loop5
@@output:
            push        bx
            mov         bh, OUR_PAGE
            mov         bl, byte ptr PROG_STATUS[1]
            and         bl, 3
            jnz         @@n_act
            mov         bl, AC_WIND_ATTR
            mov         UNASS_PTR_ATTR, 0B1h
            jmp         short       @@ahead
@@n_act:
            mov         bl, ATTRIB
            mov         UNASS_PTR_ATTR, 0B0h
@@ahead:
            gotoxy      1
            mov         si, offset @@UNASS_STR
            mov         cl, UNASS_RIGHT
            sub         cl, UNASS_LEFT
            sub         ch, ch
            inc         cx
            call        CPUTSTR
            pop         bx

            call        CHK_BKPT
            call        CHK_PTR
            call        CHK_IP
            call        CHK_PREV
            inc         dh
            cmp         dh, UNASS_DOWN
            ja          unass_ret
            mov         al, FIELD
            sub         ah, ah
            and         ax, ax
            jnz         @@ax_nz
            inc         ax
@@ax_nz:
            add         bx, ax
            jmp         dass_loop
unass_ret:
            mov         UNASS_BOTT, bx
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1
            int	33h
@@mouse_OK2:
            pop         si
            pop         dx
            pop         cx
            pop         bx
            mov         sp, bp
            pop         bp
            and	OPTIONS, not 1
            ret

put_space:
            wherexy
            mov         al, ','
            mov         cx, 1
            mov         ah, 9
            int         10h
            inc         dx
            gotoxy
            mov         al, ' '
            mov         ah, 9
            int         10h
            inc         dx
            gotoxy
            ret

FIELD       DB          50 DUP (?)
DEF_B       DB          'DB'
@@UNASS_STR DB          78 DUP (?)

UNASSEMBLE  ENDP


CHK_BKPT    PROC
;locals
;----------------------------------------------------------------------------
;           Checks if address signed by ds:[si] has breakpoint.
;----------------------------------------------------------------------------
            push        ax
            push        cx
            push        di
            sub         di, di
            mov         cx, 256
@@loop:
            mov         ax, UNASS_SEG
            cmp         bx, BP_OFFS[di]
            jnz         @@next
            cmp         ax, BP_SEGS[di]
            jnz         @@next
            push        di
            shr         di, 1
            cmp         byte ptr BP_SIGN[di], 0
            pop         di
            jz          @@next
            mov         dl, 1
            push        dx
            mov         dl, 57
            push        dx
            mov         ah, OUR_PAGE
            mov         al, SELECT_ATTR
            push        ax
            call        CHANGE_ATTRIBS
@@next:
            inc         di
            inc         di
            loop        @@loop
            pop         di
            pop         cx
            pop         ax
            ret
CHK_BKPT    ENDP



CHK_PTR     PROC
;locals
;----------------------------------------------------------------------------
;           checks if si is equal to UNASS_PTR
;----------------------------------------------------------------------------
	test	OPTIONS, 1
            jz	@@chk_uptr
            cmp	bx, USER_IP
            jnz	@@exit
            mov	UPTR_LINE, dh
            jmp	@@sign_line
@@chk_uptr:
	cmp	UPTR_LINE, dh
            jnz         @@exit
@@sign_line:
            mov	UNASS_PTR, bx
            mov         dl, 1
            push        dx
            mov         dl, 57
            push        dx
            mov         ah, OUR_PAGE
            mov         al, UNASS_PTR_ATTR
            push        ax
            call        CHANGE_ATTRIBS
            call        CHK_VAR
@@exit:
            ret
CHK_PTR     ENDP



CHK_IP      PROC
;locals
            cmp         bx, USER_IP
            jnz         @@exit
            push        bx
            mov         bh, OUR_PAGE
            gotoxy      10
            mov         al, ''
            push        cx
            mov         cx, 1
            mov         ah, 0Ah
            int         10h
            pop         cx
            pop         bx
@@exit:
            ret
CHK_IP      ENDP



CHK_PREV    PROC
;locals
            mov         al, FIELD
            or          al, al
            jnz         $+3
            inc         ax
            cbw
            add         ax, bx
            cmp         ax, UNASS_PTR
            jnz         @@exit
            mov         UNASS_PREV, bx
@@exit:
            ret
CHK_PREV    ENDP



CHK_VAR     PROC
;locals
;jumps
            push        ax
            push        bx
            push        cx
            push        dx
            push        si
            push        di

            cmp         VAR_FIELD, 0
            jnz         @@go_on
            jmp         @@ret
@@go_on:
	mov	al, VAR_FIELD
            mov	@@FLAG, al
	and         VAR_ADDR[1], 11000111b              ; for AX reg.
	mov	ax, UNASS_PTR
	dec	ax
	push        ax
	push        UNASS_SEG
	push	ax
	mov         di, TEST_FIELD
            push        di
            mov         cx, 25
            sub         ax, ax
            cld
rep         stosw
            mov         si, word ptr VAR_ADDR[1]
            mov         al, VAR_ADDR[3]
            call        DASS
            mov         word ptr VAR_ADDR[1], si
            mov         VAR_ADDR[3], al
            cmp         byte ptr ds:[TEST_FIELD], 1
            jnz         @@dflt
            cmp         byte ptr ds:[TEST_FIELD+1], 26h
            jnz         @@cs?
            mov         ax, 'SE'
            push        USER_ES
            pop         @@REG_OVER
            jmp         @@defnd
@@cs?:
            cmp         byte ptr ds:[TEST_FIELD+1], 2Eh
            jnz         @@ss?
            mov         ax, 'SC'
            push        USER_CS
            pop         @@REG_OVER
            jmp         @@defnd
@@ss?:
	cmp         byte ptr ds:[TEST_FIELD+1], 36h
	jnz         @@ds?
	mov         ax, 'SS'
	push        USER_SS
	pop         @@REG_OVER
	jmp         @@defnd
@@ds?:
	cmp         byte ptr ds:[TEST_FIELD+1], 3Eh
            jnz         @@dflt
            mov         ax, 'SD'
            push        USER_DS
            pop         @@REG_OVER
            jmp         @@defnd
@@dflt:
            mov         al, VAR_ADDR[1]
            mov         di, offset SS_DEFAULT
            mov         cx, 8
            cld
repnz       scasb
            jz          @@ss
            mov         ax, 'SD'
            push        USER_DS
            pop         @@REG_OVER
            jmp         @@defnd
@@ss:
            push        USER_SS
            pop         @@REG_OVER
            mov         ax, 'SS'
@@defnd:
            mov         word ptr VAR_FIELD[2], ax
            mov         ax, 12
            push        ax
            mov         ax, offset VAR_FIELD[6]
            push        ax

            mov         OUR_BX, bx
            mov         OUR_BP, bp
            mov         OUR_SI, si
            mov         OUR_DI, di
            mov         bx, USER_BX
            mov         bp, USER_BP
            mov         si, USER_SI
            mov         di, USER_DI
            jmp         @@polygon
@@back:
            mov         bx, OUR_BX
            mov         bp, OUR_BP
            mov         si, OUR_SI
            mov         di, OUR_DI
            call        INT_TO_STR
            mov         di, ax
	cmp	@@FLAG, -3
            jnz	@@get_ndword
@@dword_lp:               		; get dword
	push	di
	mov	ax, 12
            push	ax
            mov	ax, offset VECT_FIELD[18]
            push	ax
            push	ds
            mov	ds, @@REG_OVER
	mov	ax, [di]
            pop	ds
            call	INT_TO_STR
            pop	di
            add	di, 2
            mov	ax, 12
            push	ax
	mov	ax, offset VECT_FIELD[13]
            push	ax
            push	ds
            mov	ds, @@REG_OVER
            mov	ax, [di]
	pop	ds
            call	INT_TO_STR
            mov         bh, OUR_PAGE
            mov         bl, TOP_FRAME_ATTR
	GOTOXY      40, 6
	mov         si, offset VAR_FIELD[1]
	mov	di, offset VECT_FIELD
	mov	cx, 13
rep	movsb
	mov	si, offset VECT_FIELD
            mov         cx, 25
            call        CPUTSTR
	jmp	@@ret

@@get_ndword:
            test        FIELD[1], 1
            jnz         @@get_word
                                                ; get byte
            mov         ax, 4
            push        ax
            mov         ax, offset VAR_FIELD[14]
            push        ax
            push        ds
            mov         ds, @@REG_OVER
            mov         al, [di]
            pop         ds
            call        INT_TO_STR
            mov         word ptr VAR_FIELD[16], 0020h
            jmp         @@print
@@get_word:
            mov         ax, 12
            push        ax
            mov         ax, offset VAR_FIELD[14]
            push        ax
            push        ds
            mov         ds, @@REG_OVER
            mov         ax, [di]
            pop         ds
            call        INT_TO_STR
@@print:
            mov         bh, OUR_PAGE
            mov         bl, TOP_FRAME_ATTR
	GOTOXY      41, 6
            mov         si, offset VAR_FIELD[1]
            mov         cx, 20
            call        CPUTSTR

@@ret:
            pop         di
            pop         si
            pop         dx
            pop         cx
            pop         bx
            pop         ax
            ret

VAR_FIELD   DB          ?           ; Flag: 0-no, -1=>WORD, -2=>BYTE,
			; -3=>vector
            DB          ' XX:'                  ;5
            DB          '[XXXX]'                ;11
            DB          ' = XXXX ', 0
@@FLAG	DB	?	; double VAR_FIELD
VECT_FIELD	DB	' XX:[XXXX] = XXXX:XXXX ', 0
		; 1   5       13   18
@@polygon:
VAR_ADDR    DB          8Dh         ; Lea AX, [. . .]
            DB          3 DUP (?)
            jmp         @@back
SS_DEFAULT  DB          00000010b, 00000011b, 01000010b, 01000011b
            DB          01000110b, 10000010b, 10000011b, 10000110b

@@REG_OVER  DW          ?
CHK_VAR     ENDP
