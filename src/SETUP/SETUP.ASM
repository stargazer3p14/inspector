;           This is a SetUp program for White & Black Phantoms
;                       Executing INSPECTOR.
;

;jumps
INCLUDE     STDIO.MCR

COL_ST_LINE EQU         12
CONFIG_ST	EQU	65

CODE        SEGMENT
ASSUME	CS:CODE, DS:CODE
ORG	100H
START:
	mov	ah, 30h		; Get DOS version
            int	21h
            cmp	al, 2
            jnb	DOS_OK
            mov	si, offset DOS_ERR
            mov	cx, 100
            mov	bx, 7
            call	CPUTSTR
            mov	ax, 4CFFh
            int	21h
DOS_OK:
	QOPEN	CFG_NAME, 0		; Open 'INSP.CFG' for read
            jnc	cfg_present
            mov	si, offset CFG_ERR	; Cannot open
            mov	cx, 100
            mov	bx, 7
            call	CPUTSTR
            mov	ax, 4CFEh
            int	21h
cfg_present:
	mov	CFG_NO, ax
            MOVE_PTR	CFG_NO, 0, CONFIG_ST, 0	; move to start of parameters
            QREAD	CFG_NO, TEXT_MODE_BUF, 31 ; read parameters
            QCLOSE	CFG_NO

            mov	ah, 0Fh
            int	10h		; AL=mode
	mov	CURR_MODE, al
            mov	VTEXT_BUFFER, 0B000h

;
; The following incorrect assignment was determined and corrected by
; Robert Riebisch, 17/08/99.
;
            ;mov	CRT_STATUS, 3B8h
	    mov	CRT_STATUS, 3BAh

            mov	si, offset BAR_BW
            cmp	al, 7
            jz	mode_got
            mov	al, 3
            mov	VTEXT_BUFFER, 0B800h

;
; The color modes fix.
;
            ;mov	CRT_STATUS, 3D8h
	    mov	CRT_STATUS, 3DAh
            mov	si, offset BAR_COL
mode_got:
	mov	di, offset BAR_ATTR
            mov	cx, 8
rep	movsb
	sub	ah, ah
            int	10h		; set respective mode
	mov	ax, 1003h
            sub	bl, bl
            int	10h		; disable EGA/VGA blink
            sub	bh, bh		; Page=0
	mov	ax, 920h		
            mov	bl, BACKGR_ATTR
            mov	cx, 2000
            int	10h                     ; blank whole window
            mov	bl, TOP_COL
            mov	cx, 80
            int	10h                     ; blank top line
	GOTOXY	10, 0
            mov	si, offset PROG_TTL
            mov	cx, 100
            call	CPUTSTR		; program title
	GOTOXY	30, 2
            mov	si, offset CURR_SET
            mov	cx, TTL_LEN
            mov	bl, BAR_ATTR
            call	CPUTSTR
            mov	ah, 9
            mov	al, 'Ü'
            mov	cx, 1
            mov	bl, SHADOW_ATTR
            int	10h
            GOTOXY	31, 3
            mov	cx, TTL_LEN
            mov	ah, 9
            mov	al, 'ß'		; shadow for prompt title
            int	10h

            mov	ah, 20
            mov	al, 73
            push	ax
            mov	ah, 4
            mov	al, 50
            push	ax
            mov	bl, TOP_ATTR
            call	LITTLE_FRAME	; draw help frame

            mov	ah, 5
            mov	al, 74
            push	ax
            mov	ah, 21
            inc	ax
            push	ax
            mov	bl, SHAD_BKGR
            push	bx
            call	CHANGE_ATTRIBS

            mov	ah, 21
            mov	al, 52
            push	ax
            mov	al, 74
            push	ax
            push	bx
            call	CHANGE_ATTRIBS	; shadow for help frame

            mov	dh, 4
            mov	cx, 6
            mov	si, offset OPTIONS
draw_bars:
	push	cx
	GOTOXY	5
	mov	cx, BAR_LEN
            mov	bl, BAR_ATTR
            call	CPUTSTR
            mov	ah, 9
            mov	al, 'Ü'
            mov	cx, 1
            mov	bl, SHADOW_ATTR
            int 	10h
            inc	dh
            GOTOXY	6
	mov	cx, BAR_LEN
            mov	ah, 9
            mov	al, 'ß'
            int	10h
            add	si, BAR_LEN
            add	dh, 2
            pop	cx
            loop	draw_bars
select_loop:
	WHEREXY
            and	ch, 10011111b
            mov	ah, 1
            int	10h

	GOTOXY	0, 23
            mov	ax, 920h
            mov	bl, BOTT_ATTR2
	mov	cx, 80
	int	10h
	GOTOXY	4
            mov	si, offset HELP_LINE
            mov	cx, 3
help_lp:
	push	cx
            mov	cx, -1
            mov	bl, BOTT_ATTR1
            call	CPUTSTR
            add	si, cx
            inc	si
            mov	cx, -1
            mov	bl, BOTT_ATTR2
            call	CPUTSTR
            add	si, cx
            inc	si
            pop	cx
            loop	help_lp

	mov	al, ITEM
            mov	ah, 3
            mul	ah
            add	al, 4
            mov	dh, al
            mov	ah, al
            mov         al, 5
            push	ax
            mov	al, 4+BAR_LEN
            push 	ax
            mov	bl, ACTBAR_ATTR
            push	bx
            call	CHANGE_ATTRIBS
            mov	ah, dh
            inc	ah
            mov	al, 6
            push	ax
            mov	al, 5+BAR_LEN
            push	ax
            mov	bl, SHADOW_ATTR
            push	bx
            call	CHANGE_ATTRIBS
            GOTOXY	5
            mov	ah, 9
            mov	al, ''
            mov	cx, 1
            mov	bl, ACTBAR_ATTR
            int	10h
            GOTOXY	4+BAR_LEN
            mov	ah, 9
            mov	al, ''
            int	10h
            GOTOXY      5+BAR_LEN
            mov	ah, 9
            mov	al, 'Ü'
            mov	bl, SHADOW_ATTR
            mov	cx, 1
            int	10h
            GOTOXY	0, 24
            mov	ax, 920h
            mov	bl, 0
            mov	cx, 80
            int	10h
            GOTOXY	5
            mov	al, ITEM
            mov	ah, PROMPT_LEN
	mul	ah
            xchg	ax, si
            add	si, offset OPT_PROMPT
            mov	cx, PROMPT_LEN
            mov	bl, TOP_ATTR
            call	CPUTSTR

            mov	ax, 600h
            mov	ch, 5
            mov	cl, 51
            mov	dh, 19
            mov	dl, 72
	int	10h		; clear help window

            mov	al, ITEM
            shl	al, 1
            shl	al, 1
            mov	cl, al
            sub	ch, ch
            mov	di, offset OPT_INQ
            sub	al, al
            jcxz	inq_found
find_inq:
	push	cx
            mov	cx, -1
repnz	scasb
	pop	cx
            loop	find_inq
inq_found:
	mov	cx, 4
            mov	si, di
            mov	bl, TOP_ATTR
            mov	dh, 6
write_inq:
	push	cx
            GOTOXY      52
            mov	cx, -1
	call	CPUTSTR
            add	si, cx
            inc	si
            inc	dh
            pop	cx
            loop	write_inq
            GOTOXY	0, 25

            mov	al, ITEM
            cbw
            shl	ax, 1
            mov	si, ax
            add	si, offset PROCS
            sub	ax, ax
            call word ptr[si]
read_kbd:
            sub	ah, ah
            int	16h
	cmp	ah, 80		; down?
            jnz	up?
	cmp	ITEM, 5
	jz          read_kbd
            call	UNSELECT
            inc	ITEM
            jmp	select_loop
up?:
	cmp	ah, 72
            jnz	enter?
            cmp	ITEM, 0
            jz	read_kbd
            call	UNSELECT
            dec	ITEM
            jmp	select_loop
enter?:
	cmp	ah, 1Ch
            jnz	esc?

            GOTOXY	0, 23
            mov	ax, 920h
            mov	cx, 80
            mov	bl, BACKGR
            int	10h

            mov	ax, offset SCR_BUFFER
            push	ax
            mov	al, ITEM
            mov	ah, 3
            mul	ah
            add	al, 4
            mov	dh, al
            mov	ah, al
            mov	al, 5
            push	ax
            inc	ah
            mov	al, 5+BAR_LEN
            push	ax
            sub	al, al
            push	ax
            call	STO_SCREEN
            mov	ax, offset SCR_BUFFER
            push	ax
            mov	ah, dh
            mov	al, 6
            push	ax
            mov	al, 5+BAR_LEN
            push	ax
            sub	al, al
            push	ax
            call	LOD_SCREEN

            GOTOXY	5
            mov	ax, 920h
            mov	bl, BACKGR
            mov	cx, 1
            int	10h

            inc	dh
            GOTOXY
            mov	cx, 4+BAR_LEN
	mov	ax, 920h
            int	10h

            WHEREXY
            or	ch, 00100000b
            mov	ah, 1
            int	10h

            call	SOUND

            mov	al, ITEM
            sub	ah, ah
            shl	ax, 1
            mov	si, ax
            add	si, offset PROCS
            mov	ax, 1
            call word ptr[si]

            mov	ax, offset SCR_BUFFER
            push	ax
            mov	al, ITEM
            mov	ah, 3
            mul	ah
            add	al, 4
            mov	ah, al
	mov	al, 5
            push	ax
            inc	ah
            mov	al, 5+BAR_LEN
            push	ax
            sub	al, al
            push	ax
            call	LOD_SCREEN

            jmp	select_loop
esc?:
	cmp	ah, 1
            jnz	F1?
quit:
	GOTOXY	0, 0
            mov	ax, 920h
            mov	bl, 7
            mov	cx, 2000
            int	10h
            mov	ax, 4C00h
            int	21h
F1?:
	cmp	ah, 59
            jnz	select_loop
            QOPEN	CFG_NAME, 1
            mov	CFG_NO, ax
            MOVE_PTR	CFG_NO, 0, CONFIG_ST, 0
            QWRITE	CFG_NO, TEXT_MODE_BUF, 31
            QCLOSE	CFG_NO
            jmp	select_loop


UNSELECT	PROC	NEAR
	mov	al, ITEM
            mov	ah, 3
            mul	ah
            add	al, 4
            mov	dh, al
            mov	ah, al
            mov         al, 5
            push	ax
            mov	al, 4+BAR_LEN
            push 	ax
            mov	bl, BAR_ATTR
            push	bx
            call	CHANGE_ATTRIBS
            mov	ah, dh
            inc	ah
            mov	al, 6
            push	ax
            mov	al, 5+BAR_LEN
            push	ax
            mov	bl, SHADOW_ATTR
            push	bx
            call	CHANGE_ATTRIBS
            GOTOXY	5
            mov	ah, 9
            mov	al, ' '
            mov	cx, 1
            mov	bl, BAR_ATTR
            int	10h
            GOTOXY	4+BAR_LEN
            mov	ah, 9
            mov	al, ' '
            int	10h
            inc	dx
            GOTOXY
            mov	ah, 9
            mov	al, 'Ü'
	mov	bl, SHADOW_ATTR
            mov	cx, 1
            int 	10h
	retn
UNSELECT	ENDP


CNV_INT_STR PROC
;locals
;jumps
;
;                       Parameters: AX=integer
;           return:AX=string address, CX=number of bytes to output
;
            push        bx
            push	cx
            push	dx
            push        si

            mov         word ptr CNV_FIELD, 0
            mov         word ptr CNV_FIELD[2], 0
            mov         word ptr CNV_FIELD[4], 0
            mov         si, 4
            mov         cx, 5
            mov         bx, 10
cnv_loop:
            sub         dx, dx
            div         bx
            add         dl, '0'
            mov         CNV_FIELD[si], dl
            dec         si
            loop        cnv_loop
            mov         cx, 5
            inc         si
cnv_chk:
            cmp         CNV_FIELD[si], '0'
            jnz         chk_quit
            inc         si
            loop        cnv_chk
chk_quit:
            or          cx, cx
            jnz         @@ret
            dec         si
            inc         cx
@@ret:
            lea         ax, CNV_FIELD[si]

            pop         si
            pop	dx
            pop	cx
            pop         bx
            ret

CNV_INT_STR ENDP


CNV_STR_INT PROC
;locals @@
;
;           Parameters: AX=string address (dec) - terminated by CR
;                 return: AX=integer. CY if unable to convert.
;
            mov         di, ax
            mov         @@VAR, ax
            mov         cx, 6
            mov         al, 0Dh
            cld
repnz       scasb
            jz          @@OK
@@quit:
            stc
            ret
@@OK:
            lea         si, [di-2]
            lea         cx, [di-1]
            sub         cx, @@VAR
            mov         dl, 0
            mov         dh, 10
            sub         ax, ax
            mov         di, ax
            std
@@mul_loop:
            lodsb
            cmp         al, '0'
            jb          @@quit
            cmp         al, '9'
            ja          @@quit
            sub         al, '0'
            push        cx
            mov         cl, dl
            sub         ch, ch
            jcxz        @@mul_loop_do
@@mul_loop2:
            mul         dh
            loop        @@mul_loop2
@@mul_loop_do:
            pop         cx
            inc         dx
            add         di, ax
            loop        @@mul_loop
            mov         ax, di
            ret
@@VAR       DW          ?
CNV_STR_INT ENDP

;
;	All the following routines receive AX=0 to display info
;		        AX=1 to change.
;


SETPAGE	PROC	NEAR
;locals
	or	ax, ax
            jnz	@@work
            GOTOXY	60, 11
            mov	ah, 9
            mov	al, '#'
            mov	cx, 1
            mov	bl, TOP_ATTR
            int	10h
            GOTOXY	61
            mov	al, OUR_PAGE
            sub	ah, ah
            call	CNV_INT_STR
            mov	si, ax
            mov	cx, -1
            call	CPUTSTR
            retn
@@work:
	GOTOXY	52, 13
            mov	si, offset @@PROMPT1
            mov	cx, -1
            mov	bl, TOP_ATTR
            call 	CPUTSTR
            GOTOXY	60, 14
            mov	ax, 920h
            mov	bl, TOP_ATTR
            mov	cx, 3
            int	10h
            WHEREXY
            and	ch, not 01100000b
            mov	ah, 1
            int	10h
            mov	ah, 60
            mov	al, 61
            push	ax
            mov	ax, offset CNV_FIELD
            push	ax
            add	ax, 5
            push	ax
            call	CGETSTR
            jc	@@quit
            jcxz	@@quit
            mov	si, cx
            mov	CNV_FIELD[si], 0Dh
            mov	ax, offset CNV_FIELD
            call	CNV_STR_INT
            jc	@@quit
            mov	OUR_PAGE, al
@@quit:
	retn

@@PROMPT1	DB	'Input New Page:', 0

SETPAGE	ENDP


TEXTBUF	PROC	NEAR
;locals
	or	ax, ax
            jnz	@@work
            GOTOXY      58, 11
            mov	ax, TEXT_MODE_BUF
            call	CNV_INT_STR
            mov         si, ax
            mov	bl, TOP_ATTR
            call	CPUTSTR
            add	dl, cl
	inc	dx
            GOTOXY	, 11
            mov	si, offset KB
            mov	cx, 6
	call	CPUTSTR
            retn
@@work:
	GOTOXY	52, 13
            mov	si, offset @@PROMPT2
            mov	cx, -1
            mov	bl, TOP_ATTR
            call	CPUTSTR
            add	si, cx
            inc	si
            GOTOXY	52, 14
            mov	cx, -1
            call	CPUTSTR
            GOTOXY	60, 15
            mov	ax, 920h
            mov	bl, TOP_ATTR
            mov	cx, 5
            int	10h
            WHEREXY
            and	ch, not 01100000b
            mov	ah, 1
            int	10h
            mov	ah, 60
            mov	al, 62
            push	ax
            mov	ax, offset CNV_FIELD
            push	ax
            add	ax, 5
            push	ax
	call	CGETSTR
            jc	@@quit
            jcxz	@@quit
            mov	si, cx
            mov	CNV_FIELD[si], 0Dh
            mov         ax, offset CNV_FIELD
            call	CNV_STR_INT
            jc	@@quit
            mov	TEXT_MODE_BUF, ax
@@quit:
            retn

@@PROMPT2	DB	'Input New Text-', 0
	DB	'mode buffer size', 0

TEXTBUF	ENDP


GRAPHBUF	PROC	NEAR
;locals
	or	ax, ax
	jnz	@@work
            GOTOXY	58, 11
            mov	ax, GRAPH_MODE_BUF
            call	CNV_INT_STR
            mov         si, ax
            mov	bl, TOP_ATTR
            call	CPUTSTR
            add	dl, cl
	inc	dx
            GOTOXY	, 11
            mov	si, offset KB
            mov	cx, 6
	call	CPUTSTR
            retn
@@work:
	GOTOXY	52, 13
            mov	si, offset @@PROMPT3
            mov	cx, -1
            mov	bl, TOP_ATTR
            call	CPUTSTR
            add	si, cx
            inc	si
            GOTOXY	52, 14
            mov	cx, -1
            call	CPUTSTR
            GOTOXY	60, 15
            mov	ax, 920h
            mov	bl, TOP_ATTR
            mov	cx, 5
            int	10h
            WHEREXY
	and	ch, not 01100000b
            mov	ah, 1
            int	10h
            mov	ah, 60
            mov	al, 62
            push	ax
            mov	ax, offset CNV_FIELD
            push	ax
            add	ax, 5
            push	ax
	call	CGETSTR
            jc	@@quit
            jcxz	@@quit
            mov	si, cx
            mov	CNV_FIELD[si], 0Dh
            mov         ax, offset CNV_FIELD
            call	CNV_STR_INT
            jc	@@quit
            mov	GRAPH_MODE_BUF, ax
@@quit:
            retn

@@PROMPT3	DB	'Input New Graphics-', 0
	DB	'mode buffer size', 0


GRAPHBUF	ENDP


SWAPSTYLE	PROC	NEAR
;locals
	or	ax, ax
            jnz	@@work
            GOTOXY	60, 11
            mov	si, offset @@STYLES
            mov	cx, 6
            cmp	FLIP_STYLE, 0
            jz	@@print_style
            add	si, cx
@@print_style:
	mov	bl, TOP_ATTR
	call	CPUTSTR
            retn
@@work:
	not	FLIP_STYLE
            retn

@@STYLES	DB	'Always'
	DB	'Smart '

SWAPSTYLE	ENDP


EMULKBD	PROC	NEAR
;locals
	or	ax, ax
            jnz	@@work
            GOTOXY	60, 11
            mov	ah, 9
            mov	al, '#'
            mov	cx, 1
            mov	bl, TOP_ATTR
            int	10h
            GOTOXY	61
            mov	al, BKPT_INT
            call	CPUTHEX2
            retn
@@work:
	GOTOXY	52, 13
            mov	si, offset @@PROMPT4
            mov	cx, -1
            mov	bl, TOP_ATTR
            call 	CPUTSTR
            GOTOXY	60, 14
            mov	ax, 920h
            mov	bl, TOP_ATTR
            mov	cx, 3
            int	10h
            WHEREXY
            and	ch, not 01100000b
            mov	ah, 1
            int	10h

	    call	CGETHEX2
            jc	@@quit
	    mov		BKPT_INT, al
@@quit:
	retn

@@PROMPT4	DB	'Input New Int#:', 0

EMULKBD	ENDP


SETCOL	PROC	NEAR
;locals
	or	ax, ax
            jnz	@@chg_col
@@draw:
            mov	cx, 7
            mov	di, offset COLOR_ATTRS
            cmp	VTEXT_BUFFER, 0B800H
            jz	@@draw_attrs
            mov	di, offset MONO_ATTRS
@@draw_attrs:
	mov	dx, CRT_STATUS
@@vr_wait:
            in	al, dx
            test	al, 8
            jz	@@vr_wait
	mov	si, offset @@COLORS
	mov	dh, 12
@@draw_lp:
	push	cx
            mov	cx, @@COL_LEN
            mov	bl, [di]
            GOTOXY	51
            call	CPUTSTR
            add	si, cx
            inc	di
            inc	dh
            pop	cx
            loop	@@draw_lp
            GOTOXY	51
            retn
@@chg_col:
	mov	si, offset @@PROMPT5
	mov	cx, 5
            mov	dh, 6
            mov	bl, TOP_ATTR
@@prompt_lp:
	push	cx
	GOTOXY	52
            mov	ax, 920h
            mov	cx, 21
            int	10h
            mov	cx, -1
            call	CPUTSTR
            add	si, cx
            inc	si
            inc	dh
            pop	cx
            loop	@@prompt_lp
@@work:
	WHEREXY
            or	ch, 00100000b
            mov	ah, 1
	int	10h
	mov	dh, 12
            add	dh, byte ptr @@ITEM
            GOTOXY	48
            mov	ah, 9
            mov	al, ''
            mov	cx, 1
            mov	bl, BACKGR
            int	10h
	sub	ah, ah
            int	16h
            cmp	ah, 80		; down?
            jnz	@@up?
	inc	byte ptr @@ITEM
            cmp	byte ptr @@ITEM, 6
            jna	@@dec_OK
            mov	byte ptr @@ITEM, 0
@@dec_OK:
	mov	ax, 920h
            int	10h
            jmp         @@work
@@up?:
	cmp	ah, 72		; up?
            jnz	@@min?
            dec	byte ptr @@ITEM
            jnl	@@dec_OK
            mov	byte ptr @@ITEM, 6
	jmp	@@dec_OK
@@min?:
	cmp	ah, 74		; minus?
            jnz	@@pl?
            mov	ah, -1		; ah=value to change colors
            mov	cl, 0F0h		; CL=bits to preserve
            push	ds
            mov	di, 40h
            mov	ds, di
	test	byte ptr ds:[17h], 3	; shift?
            pop	ds
            jz	@@change
            mov	ah, -10h
            mov	cl, 0		; CL=no bits to preserve
@@change:
            mov	di, offset COLOR_ATTRS
	cmp	VTEXT_BUFFER, 0B800h
            jz	@@chg_clr
            mov	di, offset MONO_ATTRS
@@chg_clr:
	add	di, @@ITEM
	mov	al, [di]
            mov	ch, cl
            not	ch                      ; CH=not preserved bits
            and	cl, al		; CL=bits to preserve
            add	al, ah
            and	al, ch
            or	al, cl
            stosb
            call	@@draw
            jmp	@@work
@@pl?:
	cmp	ah, 78		; plus?
            jnz	@@enter?
            mov	ah, 1		; AH=value to change attr.
            mov	cl, 0F0h		; CL=bits to preserve
            push	ds
            mov	di, 40h
            mov	ds, di
            test	byte ptr ds:[17h], 3	; shift?
            pop	ds
            jz	@@change
            mov	ah, 10h
            mov	cl, 0		; CL=no bits to preserve
	jmp	@@change
@@enter?:
	cmp	ah, 1Ch
            jz	@@exit
            cmp	ah, 1
            jnz	@@work
@@exit:
	GOTOXY      48
            mov	ax, 920h
	mov	cx, 1
            int	10h
            retn

@@ITEM	DW	0
@@COLORS	DB	' Normal colors        '
@@COL_LEN	EQU	$-@@COLORS
            DB	' Selecting colors     '
	DB	' Active window colors '
            DB	' Top line colors      '
            DB	' Menu bar colors      '
            DB	' Error colors         '
            DB	' Pointing bar colors  '

@@PROMPT5	DB	'Use +/- on extended', 0
	DB	'keyboard to change', 0
            DB	'foreground colord and', 0
            DB	'Shift^+/- to change', 0
            DB	'background colors', 0
SETCOL	ENDP


SOUND	PROC	NEAR
;locals
            mov	ax, 351Ch
            int	21h
            mov	@@int1c, bx
            mov	@@int1c[2], es
            push	cs
            pop	es
            sub	bh, bh
            mov	al, 10110110b
            out	43h, al
            mov	ax, 43280
            out	42h, al
            mov	al, ah
            out	42h, al
            in	al, 61h
            or	al, 3
            out	61h, al
            cli
            mov	TIMER, 0
            mov	@@ret_flag, 0
            mov	dx, offset @@count
	mov	ax, 251Ch
            int	21h
            sti
@@wait_snd:
            cmp	@@ret_flag, 0
	jz	@@wait_snd
            retn

@@count:
	inc	cs:TIMER
	cmp	cs:TIMER, 1
	ja	$+3
	iret
	in	al, 61h
            and	al, not 3
            out	61h, al
            cli
            mov	ax, 251Ch
	lds	dx, dword ptr cs:@@int1c
            int	21h
            push	cs
            pop	ds
            sti
	mov	@@ret_flag, 1
	iret

@@int1c	DW	2 DUP (?)
@@ret_flag	DB	?

SOUND	ENDP

GETCH	PROC
	sub	ah, ah
	int	16h
	retn
GETCH	ENDP


INCLUDE	PHANT.PRC

CFG_NAME	DB	'INSP.CFG', 0
CFG_NO	DW	?

BAR_COL	DB	09FH
ACTBAR_COL	DB	0F9H
SHADOW	DB	071H
BACKGR	DB	070H
TOP_COL	DB 	00FH
SHADOW_BKGR	DB	080H
BOTT_COL1	DB	0FCH
BOTT_COL2	DB	0F3H

BAR_BW	DB	007H
ACTBAR_BW	DB	00FH
SHADOW_BW	DB	070H
BACKGR_BW	DB	070H
TOP_BW	DB	00FH
SHAD_BKGR_BW DB	070H
BOTT_BW1	DB	00FH
BOTT_BW2	DB	070H

PROCS	DW          SETPAGE, TEXTBUF, GRAPHBUF, SWAPSTYLE, EMULKBD, SETCOL

HELP_LINE	DB	" F1 - ", 0
	DB	" save configuration  ", 0
	DB	"  - ", 0
	DB	" switch between options  ", 0
            DB	" Escape - ", 0
            DB	" quit ", 0

DOS_ERR   	DB          "Can't work with DOS earlier than 2.00", 0
CFG_ERR     DB          "Configuration file not found. Can't proceed SetUp.",0
PROG_TTL	DB	"White & Black Phantoms Executing Inspector SetUp "
	DB	"program", 0
CURR_SET	DB	" Current SetUp: "
TTL_LEN	EQU	$-CURR_SET
KB	DB	"KBytes"
OPTIONS	DB	"   Active working page               "
BAR_LEN	EQU	$-OPTIONS
	DB	"   Text-mode video buffer size       "
            DB	"   Graphics-mode video buffer size   "
            DB	"   Display swapping style            "
	DB	"   Default BreakPoint Interrupt      "
            DB	"   Display colors                    "

OPT_PROMPT	DB	"Set active text-mode page for Inspector               "
PROMPT_LEN	EQU	$-OPT_PROMPT
	DB	"Set buffer size for display swapping in text modes    "
            DB	"Set buffer size for display swapping in graphics modes"
            DB	"Set display swapping style                            "
            DB	"Set Interrupt number for software breakpoints         "
            DB	"Set display colors for Inspector                      "

OPT_INQ     DB	"Press Enter to input", 0
	DB	"new text-mode page", 0
	DB	"The current text-mo-", 0
	DB	"de page is ", 0

            DB	"Press Enter to input", 0
            DB	"new text-mode buffer", 0
	DB	"size. Current size", 0
	DB	"is ", 0

            DB	"Press Enter to input", 0
	DB	"new graphics-mode", 0
	DB	"buffer size. Current", 0
	DB	"size is ", 0

            DB	"Press Enter to", 0
	DB	"switch between alwa-", 0
	DB	"ys and smart styles.", 0
	DB	"Now the style is ", 0

            DB	"Press Enter to set", 0
	    DB	"new interrupt num-", 0
	    DB	"ber. Current inter-", 0
	    DB	"rupt is", 0

            DB	"Press Enter to set", 0
	DB	"new display colors", 0
	DB	"for Inspector. The", 0
	DB	"current colors are", 0

ITEM	DB	0
CURR_CLR    DB          ?
CURR_MODE   DB          ?
VTEXT_BUFFER DW         ?
CRT_STATUS	DW	?
PROG_STATUS DW          ?
MOUSE_STAT	DB	?
TIMER	DB	?

BAR_ATTR	DB	?
ACTBAR_ATTR	DB	?
SHADOW_ATTR DB	?
BACKGR_ATTR	DB	?
TOP_ATTR	DB	?
SHAD_BKGR	DB	?
BOTT_ATTR1	DB	?
BOTT_ATTR2	DB	?

TEXT_MODE_BUF DW        ?		; Parameters
GRAPH_MODE_BUF DW       ?		; stored in INSP.CFG
RESIDENT_SIZE DW        ?		; Used to Inspector's work
FLIP_STYLE  DB          ?
COLOR_ATTRS DB          7 DUP (?)
MONO_ATTRS  DB          7 DUP (?)
OUR_PAGE    DB          ?
UNASS_TOP   DB          ?
UNASS_BOTT  DB          ?
DUMP_TOP    DB          ?
DUMP_BOTT   DB          ?
BKPT_INT	DB	?
LEFT_MOUSE	DW	?
RIGHT_MOUSE	DW	?

CNV_FIELD	DB	6 DUP (?)
SCR_BUFFER	DB	?

CODE	ENDS
END         START
