$LOD_SCREEN MACRO       Left, Top, Right, Bottom, Buffer, Page
	mov         ax, Buffer
	push        ax
	mov         ah, Top
	mov         al, Left
	push        ax
	mov         ah, Bottom
	mov         al, Right
	push        ax
	mov         al, Page
	push        ax
	call        LOD_SCREEN
ENDM



$STO_SCREEN MACRO       Left, Top, Right, Bottom, Buffer, Page
	mov         ax, Buffer
	push        ax
	mov         ah, Top
	mov         al, Left
	push        ax
	mov         ah, Bottom
	mov         al, Right
	push        ax
	mov         al, Page
	push        ax
	call        STO_SCREEN
ENDM



$LITTLE_FRAME MACRO      Left, Top, Right, Bottom, Color
	mov         ah, Bottom
	mov         al, Right
	push        ax
	mov         ah, Top
	mov         al, Left
	push        ax
	mov         bl, Color
	call        LITTLE_FRAME
ENDM


$DRAW_MENU  MACRO       Left, Top, Right, Bottom, Start, Len, Attr
	push        ax

	mov         al, Attr
	push        ax
	mov         ax, Len
	push        ax
	mov         ax, Start
	push        ax
	mov         ah, Bottom
	mov         al, Right
	push        ax
	mov         ah, Top
	mov         al, Left
	push        ax
	call        DRAW_MENU

	pop         ax
ENDM



$CHANGE_ATTRIBS MACRO   Left, Top, Right, Bottom, Color
	mov         ah, Top
	mov         al, Left
	push        ax
	mov         ah, Bottom
	mov         al, Right
	push        ax
	mov         ah, OUR_PAGE
	mov         al, Color
	push        ax
	call        CHANGE_ATTRIBS
ENDM



STORE_OUR_REGS MACRO
	mov         OUR_AX, ax
	mov         OUR_BX, bx
	mov         OUR_CX, cx
	mov         OUR_DX, dx
	mov         OUR_SP, sp
	mov         OUR_BP, bp
	mov         OUR_SI, si
	mov         OUR_DI, di
	mov         OUR_CS, cs
	mov         OUR_DS, ds
	mov         OUR_ES, es
	mov         OUR_SS, ss
	pushf
	pop         OUR_FL
ENDM



LOAD_OUR_REGS MACRO
	mov         ax, OUR_AX
	mov         bx, OUR_BX
	mov         cx, OUR_CX
	mov         dx, OUR_DX
	mov         sp, OUR_SP
	mov         bp, OUR_BP
	mov         si, OUR_SI
	mov         di, OUR_DI
	mov         ss, OUR_SS
	mov         es, OUR_ES
	push        OUR_FL
	popf
ENDM



STORE_USER_REGS MACRO
	mov         cs:USER_DS, ds
	mov         ds, cs:OUR_DS
	mov         USER_AX, ax
	mov         USER_BX, bx
	mov         USER_CX, cx
	mov         USER_DX, dx
	mov         USER_SP, sp
	mov         USER_BP, bp
	mov         USER_SI, si
	mov         USER_DI, di
	mov         USER_SS, ss
	mov         USER_ES, es
ENDM



LOAD_USER_REGS MACRO
	mov         ax, USER_AX
	mov         bx, USER_BX
	mov         cx, USER_CX
	mov         dx, USER_DX
	mov         sp, USER_SP
	mov         bp, USER_BP
	mov         si, USER_SI
	mov         di, USER_DI
	mov         ss, USER_SS
	mov         es, USER_ES
	mov         ds, USER_DS
ENDM


PRINT_CPU	MACRO
local	go_on1
;
;	Prints report about the CPU
;
	GOTOXY	2, 6
	mov	al, 80h
	mov	bl, 7
	mov	bh, OUR_PAGE
	call	CPUTHEX2
	mov	ax, CPU_Tag
	or	ah, ah
	jz	@F
	GOTOXY	3
	call        CPUTHEX4
	jmp	go_on1
@@:
	call	CPUTHEX2
go_on1:
	cmp	SubType, 0
	jz	@F
	mov	si, offset SubType
	mov	cx, 3
	call	CPUTSTR
@@:
ENDM


REPORT_BKPT	MACRO
;
;	Prints report of the Software BreakPoint installation
;
	$STO_SCREEN	24, 8, 60, 13, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 24, 8, 60, 13, MENU_ATTR
	GOTOXY	26, 9
	mov	si, offset BKPTSTR1
	mov	cx, BKPTSTRL
	call	CPUTSTR
	add	si, cx
	mov	cx, BKPTSTRL
	GOTOXY	26, 10
	call	CPUTSTR
	mov	al, BREAK_INT
	call	CPUTHEX2
	cmp	BREAK_INT, 3
	jnz	@F
	mov	si, offset BKPTSTD
	mov	cx, 20
	call	CPUTSTR
@@:
	GOTOXY	29, 12
	mov	si, offset BKPTSTR2
	mov	cx, 30
	call	CPUTSTR
@@:
	sub	ah, ah
	int	16h
	or	ah, ah
	jz	@B
	$LOD_SCREEN	24, 8, 60, 13, SCREEN_BUF_1, OUR_PAGE

ENDM


GET_NEXT_INSTR	MACRO
;
;	Get offset of the next instruction for CPU queue emul.
;
	push	USER_IP
	push	USER_CS
	push	USER_IP
	mov	ax, TEST_FIELD
	push	ax
	call	DASS
	mov	al, ds:[TEST_FIELD]
	cbw
	add	ax, USER_IP
	mov	NEXT_INSTR, ax	; get next instruction
				; address for CPU queue emul.
	mov	ax, USER_CS
	mov	NEXT_INSTR[2], ax

ENDM


COPY_QUEUE	MACRO
;
;	Copy CPU queue emulator buffer to work area
;
IFDEF	PREFETCH_EMUL
	mov	si, offset QueueBuf
	mov	di, USER_IP
	mov	cx, QueueLen
	push	es
	mov	es, USER_CS
	cld
rep	movsb
	pop	es
ENDIF	;PREFETCH_EMUL

ENDM


REBUILD_FRAME	MACRO
            mov         bh, OUR_PAGE
            mov         bl, TOP_FRAME_ATTR
	GOTOXY      20, 6
	mov         ah, 9
	mov         al, 'Í'
	mov         cx, 41

	int         10h
	GOTOXY	58
	mov	al, 'Ñ'
	call	CPUTCHAR

ENDM
