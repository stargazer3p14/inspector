INTERRUPTS  PROC
;locals
;jumps

TOP_INFO       EQU         5
            mov         di, INT_INFO
            mov         cx, 1024
            mov         ax, -1
            cld
rep         stosw
            clc

	mov	di, offset INSP_PATH
	mov	cx, -1
	sub	al, al
	cld
		repne	scasb
	mov	al, '\'
	std
		repne	scasb
	add	di, 2
	mov	si, offset @@INTRDATA_FILE1
	mov	cx, @@INTRDATA_FILE1_L
	cld
		rep	movsb

	QOPEN       INSP_PATH, 0
	jc          @@INTRexit1
	mov         @@INTRDATA1_N, ax
            $STO_SCREEN 15, TOP_INFO, 70, 20, SCREEN_BUF_2, OUR_PAGE
            $LITTLE_FRAME 15, TOP_INFO, 70, 20, MENU_ATTR
            mov         bl, MENU_ATTR
            gotoxy      36, TOP_INFO+1
	mov         si, offset @@INTRTTL
	mov         cx, @@INTRTTL_L
            call        CPUTSTR
            gotoxy      17, TOP_INFO+3
	mov         si, offset @@INTRNUM
	mov         cx, @@INTRNUM_L
            call        CPUTSTR
            gotoxy      40
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETHEX2
	jc          @@INTRexit0
	mov         @@INTRINT_N, al
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            gotoxy      17, TOP_INFO+4
	mov         si, offset @@INTRLOC
	mov         cx, @@INTRLOC_L
            call        CPUTSTR

            push        es
            push        bx
            mov         ah, 35h
	mov         al, @@INTRINT_N
            int         21h
	mov         @@INTRINT_LOC, bx
	mov         @@INTRINT_LOC[2], es
            pop         bx
            pop         es

            gotoxy      40
	mov         ax, @@INTRINT_LOC[2]
            call        CPUTHEX4
            gotoxy      44
            mov         ah, 9
            mov         al, ':'
            mov         cx, 1
            int         10h
            gotoxy      45
	mov         ax, @@INTRINT_LOC
            call        CPUTHEX4
            gotoxy      17, TOP_INFO+5
	mov         si, offset @@INTRINFO
	mov         cx, @@INTRINFO_L
            call        CPUTSTR
            push        bx
	mov         bx, @@INTRDATA1_N
	mov         al, @@INTRINT_N
            cmp	al, 67h
	jna	@@INTRna_67
            mov	al, 66h
@@INTRna_67:
            sub         ah, ah                  ; DX=int. number
            mov         cx, 1024                ; CX=bytes in record
            mul         cx
            mov         cx, dx
            mov         dx, ax
	cmp	@@INTRINT_N, 21h
	jna	@@INTRto_record
            add	dx, 1024
            adc	cx, 0
@@INTRto_record:
            mov         ax, 4200h               ; move file pointer
            int         21h
	mov	ah, 3Fh
            mov	cx, 1024
            mov        	dx, INT_INFO
	cmp	@@INTRINT_N, 21h
	jnz	@@INTRread
            shl	cx, 1
@@INTRread:
	int	21h
            pop	bx
	QCLOSE      @@INTRDATA1_N
            mov         di, INT_INFO
            mov	CURR_INFO, INT_INFO
            mov	al, -1
            mov	cx, 2048
repnz	scasb
            mov	byte ptr [di-1], 0
@@INTRmain_loop:
	call	OUTPUT_INFO
@@INTRto_end:
            sub         ah, ah
            int         16h
            cmp         ah, 1
	jz          @@INTRexit0
            cmp	ah, 80
	jnz	@@INTRup?
            cmp	LAST_INFO, 0
	jnz	@@INTRto_end
	mov	di, CURR_INFO
            mov	cx, -1
            sub	al, al
repnz	scasb
            mov	CURR_INFO, di
	jmp	@@INTRmain_loop
@@INTRup?:
	cmp	ah, 72
	jnz	@@INTRto_end
            cmp	CURR_INFO, INT_INFO+2
	jb	@@INTRto_end
            mov	di, CURR_INFO
            sub	di, 2
            sub	al, al
            std
@@INTRup_lp:
	cmp	di, INT_INFO
	jz	@@INTRset_info
	scasb
	jnz	@@INTRup_lp
            add	di, 2
@@INTRset_info:
	cld
            mov	CURR_INFO, di
	jmp	@@INTRmain_loop
@@INTRexit0:
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            $LOD_SCREEN 15, TOP_INFO, 70, 20, SCREEN_BUF_2, OUR_PAGE
            ret

@@INTRexit1:
            $STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            gotoxy      1, 23
	mov         si, offset @@INTRFILE_ERR1
	mov         cx, @@INTRF_ERR1_L
            call        CPUTSTR
            mov         si, offset PR_ESC
            mov         cx, PR_ESC_L
            call        CPUTSTR
            $CHANGE_ATTRIBS 1, 23, 78, 23, ERR_ATTR
@@INTRerr_loop:
            sub         ah, ah
            int         16h
            cmp         ah, 1
	jnz         @@INTRerr_loop
            $LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            ret

            
@@INTRTTL       DB          'INTERRUPTS'
@@INTRTTL_L     EQU         $-@@INTRTTL
@@INTRNUM       DB          'Interrupt number:'
@@INTRNUM_L     EQU         $-@@INTRNUM
@@INTRLOC       DB          'Located at:'
@@INTRLOC_L     EQU         $-@@INTRLOC
@@INTRINFO      DB          'Short Information About:'
@@INTRINFO_L    EQU         $-@@INTRINFO
@@INTRDATA_FILE1 DB         'INTS.DAT', 0
@@INTRDATA_FILE1_L EQU	$ - @@INTRDATA_FILE1
@@INTRDATA1_N   DW          ?
@@INTRFILE_ERR1 DB          "Data File 'INTS.DAT' not found. "
@@INTRF_ERR1_L  EQU         $-@@INTRFILE_ERR1
@@INTRINT_N     DB          ?
@@INTRINT_LOC   DW          2 DUP (?)
LAST_INFO	DB	0       	;not 0: last line
START_INFO	DW	?
CURR_INFO	DW	?

INTERRUPTS  ENDP


OUTPUT_INFO	 PROC
;locals
	mov	LAST_INFO, 0
            mov	si, CURR_INFO
            mov	dh, TOP_INFO+7
@@start:
            gotoxy      17
            mov	ax, 920h
            mov 	cx, 52
            int	10h
            mov	di, si
            mov	cx, -1
            sub	al, al
repnz	scasb
	push	cx
	mov	cx, di
            sub	cx, si
            call        CPUTSTR
            pop	cx
            not	cx
            add         si, cx
            cmp         byte ptr [si], -1
            jz          @@to_end
            inc         dh
            cmp         dh, TOP_INFO+14
            ja          @@end
            jmp	@@start
@@to_end:
	not	LAST_INFO
@@end:
	ret
OUTPUT_INFO	 ENDP
