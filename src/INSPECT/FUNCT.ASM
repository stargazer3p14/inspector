LOAD        PROC
;locals
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 14
	mov         al, 45
	push        ax
	push        word ptr OUR_PAGE
	call        STO_SCREEN
	mov         ah, 14
	mov         al, 45
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         bl, MENU_ATTR
	call        LITTLE_FRAME
	lea         si, LOADF_TTL
	mov         cx, LOADF_TTL_L
	GOTOXY      32, 11
	call        CPUTSTR
	lea         si, FILE_PROMPT
	mov         cx, FILE_PROMPT_L
	GOTOXY      32, 12
	call        CPUTSTR
	mov         di, FILE_NAME
	mov         cx, 63
	xor         al, al
	cld
rep         stosb                               ;Set FILE_NAME Zero
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	GOTOXY      32, 13
	mov         ah, 32
	mov         al, 43
	push        ax
	mov         ax, FILE_NAME
	push        ax
	add         ax, 63
	push        ax
	call        CGETSTR
	jnc         @F
	jmp         @@fault_2
@@:
	test        cx, cx
	jnz         @F
	jmp         @@fault_2
@@:
	mov         ax, FILE_NAME
	push        ax
	push        cx
	call        UPCASE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 14
	mov         al, 45
	push        ax
	push        word ptr OUR_PAGE
	call        LOD_SCREEN

	push	es
	mov	es, WORK_AREA	; free work area
	mov	ah, 49h
	int	21h
	pop	es

	push        bx
	mov         ax, FILE_NAME
	push        ax
	call        LOAD_FILE
	pop         bx
	jnc         @@load_OK
	jmp         @@clear_1
@@load_OK:
	mov         ax, USER_SP
	add         ax, 12
	mov         STACK_OFFS, ax
	GOTOXY      64, 24
	lea         si, LD_MODULE
	mov         cx, 12
	mov         bl, TOP_ATTR
	call        CPUTSTR
	call	FILL_QUEUE
	ret

@@fault_2:
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 14
	mov         al, 45
	push        ax
	push        word ptr OUR_PAGE
	call        LOD_SCREEN
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret
LOAD        ENDP



VIEW_DUMP   PROC
;locals
;jumps
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, OUR_PAGE
	push        ax
	call        STO_SCREEN
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         bh, OUR_PAGE
	mov         bl, MENU_ATTR
	call        LITTLE_FRAME
	lea         si, DUMP_TTL
	mov         cx, 4
	GOTOXY      37, 11
	call        CPUTSTR
	lea         si, DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	GOTOXY      32, 12
	call        CPUTSTR
	GOTOXY      40
	mov         bh, OUR_PAGE
	mov         bl, MENU_ATTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc         dump_seg_got
	cmp         al, 27
	jz          @@exit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
dump_seg_got:
	mov         DUMP_SEG, ax
	lea         si, DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	GOTOXY      32, 13
	call        CPUTSTR
	GOTOXY      40
	mov         bh, OUR_PAGE
	mov         bl, MENU_ATTR
	call        CGETHEX4
	jc          @@exit
	mov         DUMP_OFFS, ax
	mov         DUMP_PTR, ax
            mov	al, DUMP_TOP
            mov	DPTR_LINE, al
@@exit:
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, OUR_PAGE
	push        ax
	call        LOD_SCREEN
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret
VIEW_DUMP   ENDP



VIEW_UNASS  PROC
;locals
;jumps
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, OUR_PAGE
	push        ax
	call        STO_SCREEN
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         bh, OUR_PAGE
	mov         bl, MENU_ATTR
	call        LITTLE_FRAME
	lea         si, UNASS_TTL
	mov         cx, UNASS_TTL_L
	GOTOXY      35, 11
	call        CPUTSTR
	lea         si, DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	GOTOXY      32, 12
	call        CPUTSTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	GOTOXY      40
	call        CGETHEX4
	jnc         unass_seg_got
	cmp         al, 27
	jz          @@exit
	mov         ax, UNASS_SEG
	call        CPUTHEX4
unass_seg_got:
	mov         UNASS_SEG, ax
	lea         si, DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	GOTOXY      32, 13
	call        CPUTSTR
	GOTOXY      40
	call        CGETHEX4
	jc          @@exit
	mov         UNASS_OFFS, ax
	mov         UNASS_PTR, ax
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, OUR_PAGE
	push        ax
	call        LOD_SCREEN
            mov	al, UNASS_TOP
            mov	UPTR_LINE, al
	jmp         @@exit_00
@@exit:
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	mov         al, 49
	mov         ah, 14
	push        ax
	mov         al, OUR_PAGE
	push        ax
	call        LOD_SCREEN
@@exit_00:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret
VIEW_UNASS  ENDP



IN_PORT     PROC
;locals
	$STO_SCREEN 30, 10, 44, 14, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 30, 10, 44, 14, MENU_ATTR
	lea         si, INPORT_TTL
	mov         cx, 7
	GOTOXY      32, 11
	call        CPUTSTR
	lea         si, PORT_PROMPT1
	mov         cx, 5
	GOTOXY      32, 12
	call        CPUTSTR
	lea         si, PORT_PROMPT2
	mov         cx, 6
	GOTOXY      32, 13
	call        CPUTSTR
	GOTOXY      38, 12
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jc	@@in_ret
	mov         PORT, ax
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	test        byte ptr PROG_STATUS, 01000000b
	mov         dx, PORT
	jnz         in_word
	in          al, dx
	push        ax
	GOTOXY      38, 13
	pop         ax
	call        CPUTHEX2
	jmp         short       in_loop
in_word:
	in          ax, dx
	push        ax
	GOTOXY      38, 13
	pop         ax
	call        CPUTHEX4
	wherexy
in_loop:
	sub	ah, ah
	int	16h
	and         ah, ah
	jz          in_loop
@@in_ret:
	WHEREXY
            or	ch, 00100000b
            mov	ah, 1
            int	10h
	$LOD_SCREEN 30, 10, 44, 14, SCREEN_BUF_1, OUR_PAGE
	ret

PORT        DW          ?

IN_PORT     ENDP



OUT_PORT    PROC
;locals
	$STO_SCREEN 30, 10, 44, 14, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 30, 10, 44, 14, MENU_ATTR
	lea         si, OUTPORT_TTL
	mov         cx, 8
	GOTOXY      32, 11
	call        CPUTSTR
	lea         si, PORT_PROMPT1
	mov         cx, 5
	GOTOXY      32, 12
	call        CPUTSTR
	GOTOXY      38
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jc	out_OK
	mov         PORT, ax
	lea         si, PORT_PROMPT2
	mov         cx, 6
	GOTOXY      32, 13
	call        CPUTSTR
	GOTOXY      38
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jc	out_OK
	test        byte ptr PROG_STATUS, 01000000b
	mov         dx, PORT
	jnz         out_word
	out         dx, al
	jmp         short       out_OK
out_word:
	out         dx, ax
out_OK:
	$LOD_SCREEN 30, 10, 44, 14, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret
OUT_PORT    ENDP



VIEW_SCREEN PROC
	or          PROG_STATUS, 8000h
	call        SAVE_MAIN_WIND          ;Yes, save main
	call        LOAD_USER_VIDEO
	GOTOXY      USER_CURSOR, USER_CURSOR[1]
	mov         cx, word ptr USER_CUR_FORM
	mov         ah, 1
	int         10h
wait_1:
	sub         ah, ah
	int         16h
	and         ah, ah
	jz          wait_1
	call        RESTORE_MAIN_WIND
	and         PROG_STATUS, 7FFFh
	ret
VIEW_SCREEN ENDP



MOVE        PROC
	mov         bl, MENU_ATTR
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 15
	mov         al, 49
	push        ax
	push        word ptr OUR_PAGE
	call        STO_SCREEN
	mov         al, 49
	mov         ah, 15
	push        ax
	mov         al, 30
	mov         ah, 10
	push        ax
	call        LITTLE_FRAME
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	GOTOXY      36, 11
	lea         si, MOVE_TTL
	mov         cx, MOVE_TTL_L
	call        CPUTSTR
	GOTOXY      32, 12
	lea         si, DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	call        CPUTSTR
	GOTOXY      40
	call        CGETHEX4
	jnc         move_on_1
	cmp         al, 0Dh
	jz          move_here
	jmp         move_off
move_here:
	mov         ax, DUMP_SEG
	call	CPUTHEX4
move_on_1:
	push        ax
	GOTOXY      32, 13
	lea         si, DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	call        CPUTSTR
	GOTOXY      40
	call        CGETHEX4
	pop         cx
	jnc         move_on_2
	jmp         move_off
move_on_2:
	push        cx
	push        ax
	GOTOXY      32, 14
	lea         si, PORT_PROMPT2
	mov         cx, 6
	call        CPUTSTR
	GOTOXY      40
	call        CGETHEX2
	pop         di
	pop         es
	jnc         move_on_3
	jmp         move_off
move_on_3:
	mov         es:[di], al
	call	FILL_QUEUE
move_off:
	push        ds
	pop         es
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 15
	mov         al, 49
	push        ax
	push        word ptr OUR_PAGE
	call        LOD_SCREEN
	ret
MOVE        ENDP



READ        PROC
	sub         al, al
	push        ax
	call        SECTORS
	call	REFRESH
	call	FILL_QUEUE
	ret
READ        ENDP



WRITE       PROC
	mov         al, 1
	push        ax
	call        SECTORS
	ret
WRITE       ENDP



ENTER_DATA  PROC
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 9
	mov         al, 30
	push        ax
	mov         ah, 15
	mov         al, 50
	push        ax
	push        word ptr OUR_PAGE
	call        STO_SCREEN
	mov         ah, 15
	mov         al, 50
	push        ax
	mov         ah, 9
	mov         al, 30
	push        ax
	mov         bl, MENU_ATTR
	call        LITTLE_FRAME
	lea         si, FILL_TTL
	mov         cx, FILL_TTL_L
	GOTOXY      35, 10
	call        CPUTSTR
	GOTOXY      32, 11
	lea         si, DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	call        CPUTSTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	GOTOXY      40
	call        CGETHEX4
	jnc         fill_seg_got
	cmp         al, 27
	jz          fill_off
	mov         ax, DUMP_SEG
	call        CPUTHEX4
fill_seg_got:
	mov         es, ax
	lea         si, DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	GOTOXY      32, 12
	call        CPUTSTR
	GOTOXY      40
	call        CGETHEX4
	jc          fill_off
	mov         di, ax
	GOTOXY      32, 13
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      45
	call        CGETHEX4
	jc          fill_off
	mov         cx, ax
	GOTOXY      32, 14
	push        cx
	mov         si, offset PORT_PROMPT2
	mov         cx, 6
	call        CPUTSTR
	pop         cx
	GOTOXY      40
	call        CGETHEX2
	cld
rep         stosb
	call	FILL_QUEUE
fill_off:
	push        cs
	pop         es
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 9
	mov         al, 30
	push        ax
	mov         ah, 15
	mov         al, 50
	push        ax
	push        word ptr OUR_PAGE
	call        LOD_SCREEN
	ret
ENTER_DATA  ENDP



PERFORM     PROC
;locals
	push        bp
	mov         bp, sp
	mov         al, [bp+4]
	cmp         al, -1
	jz          @@to_print
	cbw
	mov         si, ax
	shl         si, 1
	cmp         si, 46
	jb          @@OK
	cmp         si, 50
	ja          @@OK
	sub         al, al
	push        ax
@@OK:
	call        [si+@@BASE_PROCS]
	pop         bp
	ret         2
@@to_print:
	call        PRINT_INST
	pop         bp
	ret         2


@@BASE_PROCS DW         offset LOAD, offset SAVE, offset CHANGE_DIR
	DW          offset DOS_SHELL, offset go_home, offset RESIDENT

	DW          offset VIEW_DUMP, offset VIEW_UNASS, offset ASSM
	DW          offset IMMEDIATE, offset IN_PORT, offset OUT_PORT
	DW          offset VIEW_SCREEN, offset INTERRUPTS, offset MOVE
	DW          offset READ, offset WRITE

	DW          offset VIEW_DISK, offset VIEW_FILE, offset ENTER_DATA
	DW          offset FILL_FR_PORT, offset FILL_PORT
	DW          offset COMPARE, offset FIND_BYTE, offset FIND_STRING
	DW          offset FIND_INSTR, offset COPY

	DW          offset BKPT_AT, offset GO_UNTIL, offset RUN
	DW          offset BREAK_HERE, offset SINGLE_STEP, offset DEL_BKPTS
	DW          offset TRACE, offset ARGUMENTS

	DW          offset HELP

PERFORM     ENDP


ASSM        PROC
;locals
;jumps
;----------------------------------------------------------------------------
;           ASSEMBLE    IN THE MAIN MENU
;----------------------------------------------------------------------------
	push        bp
	mov         bp, sp
	sub         sp, 4                   ;variables
	lea         di, INSTR_FLD
	mov         cx, 10
	sub         al, al
	cld
rep         stosb
	mov         di, INSTR_BUF
	mov         cx, 100
rep         stosb
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 16
	mov         al, 51
	push        ax
	push        word ptr OUR_PAGE
	call        STO_SCREEN
	mov         ah, 16
	mov         al, 51
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         bl, MENU_ATTR
	mov         bh, OUR_PAGE
	call        LITTLE_FRAME
	GOTOXY      36, 11
	lea         si, ASSM_TTL
	mov         cx, ASSM_TTL_L
	call        CPUTSTR
	GOTOXY      32, 12
	lea         si, DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	call        CPUTSTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	GOTOXY      40
	call        CGETHEX4
	jnc         assm_seg_OK
	cmp         ah, 1
	jz          @@assm_ret
	mov         ax, UNASS_SEG
	call        CPUTHEX4
assm_seg_OK:
	mov         [bp-2], ax              ;segment
	GOTOXY      32, 13
	lea         si, DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	call        CPUTSTR
	GOTOXY      40
	call        CGETHEX4
	jnc         assm_off_OK
	cmp         ah, 1
	jz          @@assm_ret
	mov         ax, UNASS_PTR
	call        CPUTHEX4
assm_off_OK:
	mov         [bp-4], ax              ;offset
	mov         UNASS_PTR, ax
	GOTOXY      32, 14
	lea         si, ASSM_PROMPT
	mov         cx, ASSM_PROMPT_L
	call        CPUTSTR
	GOTOXY      32, 15
	mov         ah, 32
	mov         al, 49
	push        ax
	mov         ax, INSTR_BUF
	push        ax
	add         ax, 99
	push        ax
	call        CGETSTR
	jnc         assm_in_OK
	jmp         @@assm_ret
assm_in_OK:
	mov         ax, INSTR_BUF
	push        ax
	mov         ax, 2
	push        ax
	call        UPCASE
	cmp         word ptr ds:[INSTR_BUF], 'BD'
	jnz         @@norm_instr
	mov         di, INSTR_BUF+2
	mov         al, "'"
	mov         cx, 97
	cld
repnz       scasb
	jnz         @@scan_next
	mov         si, di
	mov         cx, 97
	sub         cx, di
	add         cx, INSTR_BUF
repnz       scasb
	jnz         @@assm_err
	mov         cx, di
	sub         cx, si
	dec         cx
	les         di, [bp-4]
rep         movsb
	push        cs
	pop         es
	jmp         @@assm_ret
@@scan_next:
	mov         di, INSTR_BUF+2
	mov         al, '"'
	mov         cx, 97
	cld
repnz       scasb
	mov         si, di
	mov         cx, 97
	sub         cx, di
	add         cx, INSTR_BUF
repnz       scasb
	jnz         @@assm_err
	mov         cx, di
	sub         cx, si
	dec         cx
	les         di, [bp-4]
rep         movsb
	push        cs
	pop         es
	call	FILL_QUEUE		; assemble function
					; resets CPU queue
	jmp         @@assm_ret

@@norm_instr:
	mov         di, INSTR_BUF
	add         di, cx
	mov         al, 0Dh
	stosb
	push        bx
	mov         ax, INSTR_BUF
	push        ax
	mov         ax, offset INSTR_FLD
	push        ax
	push        [bp-4]
	call        ASSEMBLE
	pop         bx
	jnc         copy_instr
@@assm_err:
	mov         ERRORCODE, 8
	call        ERR_HANDLER
	jmp         @@assm_ret
copy_instr:
	push        es
	push        si
	push        di
	mov         es, [bp-2]
	mov         di, [bp-4]
	mov         si, offset INSTR_FLD[1]
	mov         cl, INSTR_FLD
	sub         ch, ch
	or          cx, cx
	jnz         $+3
	inc         cx
	add         UNASS_PTR, cx
	mov	ax, UNASS_PTR
	cmp	ax, UNASS_BOTT
	jb	@@move
	add	UNASS_OFFS, cx
@@move:
rep         movsb
	pop         di
	pop         si
	pop         es
	call	FILL_QUEUE		; assembly procedure
					; resets CPU queue
@@assm_ret:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         ax, SCREEN_BUF_1
	push        ax
	mov         ah, 10
	mov         al, 30
	push        ax
	mov         ah, 16
	mov         al, 51
	push        ax
	push        word ptr OUR_PAGE
	call        LOD_SCREEN
	mov         sp, bp
	pop         bp

	ret


ASSM_TTL    DB          'ASSEMBLE'
ASSM_TTL_L  EQU         $-ASSM_TTL
ASSM_PROMPT DB         'Input Instruction:'
ASSM_PROMPT_L  EQU      $-ASSM_PROMPT
INSTR_FLD   DB          100 DUP (0)
ASSM_ERR1   DB          'ERROR: Wrong instruction (operands). '
ASSM_ERR1_L EQU         $-ASSM_ERR1

ASSM        ENDP


INT_10	PROC
	pushf

	DB          09Ah
ORIG_INT10  DW          2 DUP (?)

	push        dx
	push        ax
	test        byte ptr cs:VTEXT_BUFFER[1], 8
	jnz         $+7
	mov         dx, 3B8h
	jmp         short       $+5
	mov         dx, 3D8h
	mov         al, 9
	out         dx, al
	pop         ax
	pop         dx
	iret
INT_10   	ENDP


HELP        PROC
	mov         HELP_CODE, 49
	pushf
	push        cs
	mov         ax, offset help_retp
	push        ax
	jmp         help_entry
help_retp:
	ret
HELP        ENDP



DOS_SHELL   PROC
;locals
;----------------------------------------------------------------------------
;           This procedure issues MS-DOS secondary command processor.
;----------------------------------------------------------------------------
	test        byte ptr PROG_STATUS, 00111000b
	jz          @@OK
	mov         ERRORCODE, 12
	call        ERR_HANDLER
	ret
@@OK:
;--------------------------- Run COMMAND.COM --------------------------------
	call        SAVE_MAIN_WIND
            Select_Page	0
	GOTOXY      0, 0
	mov         ah, 9
	mov         al, ' '
	mov         cx, 4096
	mov         bl, 7
	int         10h
	GOTOXY      12
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h

	mov         si, offset @@MSG
            mov	bl, 7
            mov	cx, 100
            call	CPUTSTR

	call        REINSTALL_VECTORS
            mov	ax, 3301h		; Set Ctrl-C
            mov	dl, CTRL_BREAK
            int	21h
	mov         @@KEEP_SS, ss
	mov         @@KEEP_SP, sp
	mov         @@KEEP_DS, ds
	mov         dx, 8                   ;DS:DX=COMSPEC:8
	mov         bx, offset @@PARAMS     ;ES:BX-> @@PARAMS
	mov         ds, ds:[2Ch]

	mov         es:[bx], ds
	mov         es:[bx+2], offset @@CMD_LINE
	mov         es:[bx+4], cs
	mov         word ptr es:[bx+6], 5Ch
	mov         es:[bx+8], es
	mov         word ptr es:[bx+0Ah], 6Ch
	mov         es:[bx+0Ch], cs

	mov         ax, 4B00h
	int         21h
	jc          @@fault

@@ret_entry:
;-------------------- Return from COMMAND.COM entry point -------------------
	mov         ds, cs:@@KEEP_DS
	mov         ss, @@KEEP_SS
	mov         sp, @@KEEP_SP
            mov	ax, 3301h		; Set Ctrl-C
            sub	dl, dl
            int	21h
	mov         bh, OUR_PAGE
	call        INSTALL_VECTORS
	call        RESTORE_MAIN_WIND
	wherexy
	or          ch, 00100000b           ;Set cursor
	mov         ah, 1                   ;invisible
	int         10h

	sub         bl, bl                  ;enable
	mov         ax, 1003h               ;intensity
	int         10h

@@fault:
;------------------------ COMMAND.COM load fault ----------------------------
	ret

@@PARAMS    DW          7 DUP (0)
@@MSG       DB          'Typing  EXIT  will  return  you  to  the  INSPECTOR.'
	DB	0DH, 0AH, 0
@@CMD_LINE  DB          0, 0Dh
@@KEEP_SS   DW          ?
@@KEEP_SP   DW          ?
@@KEEP_DS   DW          ?

DOS_SHELL   ENDP



RESIDENT    PROC
;locals
;----------------------------------------------------------------------------
;           This procedure performs the resident EXIT from INSPECTOR.
;----------------------------------------------------------------------------

	call	SAVE_MAIN_WIND
            STORE_OUR_REGS

	call        LOAD_USER_VIDEO
	GOTOXY      USER_CURSOR, USER_CURSOR[1]
	mov         cx, word ptr USER_CUR_FORM
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	mov         bl, USER_PAGE
	shl         bl, 1
	sub         bh, bh
	add         bx, 450h
	push        es
	sub         ax, ax
	mov         es, ax
	mov         ax, word ptr USER_CURSOR
	mov         es:[bx], ax
	mov         ax, word ptr USER_CUR_FORM
	mov         es:[460h], ax
	pop         es

	cli                                 ;No interrupts during vector
				;change
	call        REINSTALL_VECTORS
	mov         es, WORK_AREA
	mov         ah, 49h
	int         21h
	mov         ax, 3509h               ;Get orig. INT 9 address
	int         21h
	mov         ORIG_INT9, bx
	mov         ORIG_INT9[2], es

	mov         dx, offset INT_9        ;Install INT_9 to INT 9
	mov         ax, 2509h
	int         21h

	push        cs
	pop         es
            sti

	mov         dx, (INSP_SIZE SHL 4)+1
	mov         ax, 3100h
	int         21h
RESIDENT    ENDP



INT_9       PROC
;locals
;jumps
	cli
	jmp         @@go_on
@@KEEP_AX   DW          ?
@@go_on:
	mov         cs:@@KEEP_AX, ax
	in          al, 60h
	cmp         al, 83                  ;Del?
	jnz         @@normal
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 4   ;Ctrl?
	jz          @@to_norm
	test        byte ptr ds:[417h], 8   ;Alt?
	jz          @@to_norm
	pop         ds

            pop         cs:USER_IP
            pop	cs:USER_CS
            pop	cs:USER_FL
            STORE_USER_REGS
	    LOAD_OUR_REGS

	push        ds
	mov         ax, 2509h
	lds         dx, dword ptr ORIG_INT9
	int         21h
	pop         ds

            call	INSTALL_VECTORS

	mov         al, 20h
	out         20h, al
            sti

	push	bx
	mov	bx, cs
	mov	ah, 50h		; Own all resources for
	int	21h		; Inspector
	pop	bx

	jmp	int9entry
@@to_norm:
	pop         ds
@@normal:
            mov	ax, cs:@@KEEP_AX
	DB          0EAh                    ;far jump to original
ORIG_INT9   DW          2 DUP (?)               ;INT 9

INT_9       ENDP


IMMEDIATE   PROC
;locals
;jumps
	$STO_SCREEN 30, 10, 50, 15, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 30, 10, 50, 15, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      34, 11
	mov         si, offset @@IMMTTL
	mov         cx, @@IMMTTL_L
	call        CPUTSTR
	GOTOXY      32, 12
	mov         si, offset ASSM_PROMPT
	mov         cx, ASSM_PROMPT_L
	call        CPUTSTR
	wherexy
	and         ch, 0CFh
	mov         ah, 1
	int         10h
	GOTOXY      34, 14
	mov         ah, 34
	mov         al, 46
	push        ax
	mov         ax, TEST_FIELD
	push        ax
	add         ax, 49
	push        ax
	call        CGETSTR
	jc          @@IMMexit
	mov         ax, TEST_FIELD
	push        ax
	mov         ax, offset @@IMMpolygon
	push        ax
	push        USER_IP
	call        ASSEMBLE
	mov         bl, byte ptr @@IMMpolygon
	sub         bh, bh
	inc         bx
@@IMMloop:
	mov         byte ptr @@IMMpolygon[bx], 90h
	inc         bx
	cmp         bx, 12
	jb          @@IMMloop
	mov         byte ptr @@IMMpolygon, 90h

	call        SAVE_MAIN_WIND
	call        LOAD_USER_VIDEO
	call        PREPARE_VECTORS
	STORE_OUR_REGS
;------------------------- load user registers ------------------------------
	LOAD_USER_REGS
@@IMMpolygon:
	DB          12 DUP (?)
;-------------------- save user task ---------------------
	STORE_USER_REGS
	pushf
	pop         cs:USER_FL
;------------------------------- load our task -----------------------------
	LOAD_OUR_REGS
	call        LOAD_VECTORS
	call        SAVE_USER_VIDEO
	call        RESTORE_MAIN_WIND
@@IMMexit:
	$LOD_SCREEN 30, 10, 50, 15, SCREEN_BUF_1, OUR_PAGE
	mov         bh, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret

@@IMMTTL       DB          'IMMEDIATE'
@@IMMTTL_L     EQU         $-@@IMMTTL

IMMEDIATE   ENDP



FILL_PORT   PROC
;locals
;jumps
	$STO_SCREEN 30, 10, 53, 16, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 30, 10, 53, 16, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      36, 11
	mov         si, offset @@FPRTTL
	mov         cx, @@FPRTTL_L
	call        CPUTSTR
	GOTOXY      32, 12
	mov         si, offset DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	call        CPUTSTR
	wherexy
	and         ch, 0CFh
	mov         ah, 1
	int         10h
	GOTOXY      32+DUMP_PROMPT1_L
	call        CGETHEX4
	jnc         @@FPRseg_got
	cmp         ah, 1
	jz          @@FPRexit
	mov         ax, DUMP_SEG
@@FPRseg_got:
	mov         @@FPRSEG, ax
	GOTOXY      32, 13
	mov         si, offset DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	call        CPUTSTR
	GOTOXY      32+DUMP_PROMPT2_L
	call        CGETHEX4
	jc          @@FPRexit
	mov         @@FPROFF, ax
	GOTOXY      32, 14
	mov         si, offset PORT_PROMPT1
	mov         cx, 5
	call        CPUTSTR
	GOTOXY      37
	call        CGETHEX4
	jc          @@FPRexit
	mov         @@FPRPORT, ax
	GOTOXY      32, 15
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      32+RANGE_L
	call        CGETHEX4
	jc          @@FPRexit
	mov         cx, ax
	mov         dx, @@FPRPORT
	les         si, dword ptr @@FPROFF
	cld
@@FPRloop:
	lods        byte ptr es:[si]
	out         dx, al
	loop        @@FPRloop
@@FPRexit:
	push        cs
	pop         es
	$LOD_SCREEN 30, 10, 53, 16, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
            call	REFRESH
	ret

@@FPRTTL       DB          'FILL PORT'
@@FPRTTL_L     EQU         $-@@FPRTTL
@@FPROFF       DW          ?
@@FPRSEG       DW          ?
@@FPRPORT      DW          ?

FILL_PORT   ENDP



FILL_FR_PORT PROC
;locals
;jumps
	$STO_SCREEN 30, 10, 53, 16, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 30, 10, 53, 16, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      34, 11
	mov         si, offset @@FFRPTTL
	mov         cx, @@FFRPTTL_L
	call        CPUTSTR
	wherexy
	and         ch, 0CFh
	mov         ah, 1
	int         10h
	GOTOXY      32, 12
	mov         si, offset DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	call        CPUTSTR
	GOTOXY      32+DUMP_PROMPT1_L
	call        CGETHEX4
	jnc         @@FFRPseg_got
	cmp         ah, 1
	jz          @@FFRPexit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@FFRPseg_got:
	mov         @@FFRPSEG, ax
	GOTOXY      32, 13
	mov         si, offset DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	call        CPUTSTR
	GOTOXY      32+DUMP_PROMPT2_L
	call        CGETHEX4
	jc          @@FFRPexit
	mov         @@FFRPOFF, ax
	GOTOXY      32, 14
	mov         si, offset PORT_PROMPT1
	mov         cx, 5
	call        CPUTSTR
	GOTOXY      37
	call        CGETHEX4
	jc          @@FFRPexit
	mov         @@FFRPPORT, ax
	GOTOXY      32, 15
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      32+RANGE_L
	call        CGETHEX4
	jc          @@FFRPexit
	mov         cx, ax
	mov         dx, @@FFRPPORT
	les         di, dword ptr @@FFRPOFF
	cld
@@FFRPloop:
	in          al, dx
	stosb
	loop        @@FFRPloop
	call	FILL_QUEUE		; Fill CPU queue emul. buffer
@@FFRPexit:
	push        cs
	pop         es
	$LOD_SCREEN 30, 10, 53, 16, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret

@@FFRPTTL       DB          'FILL FROM PORT'
@@FFRPTTL_L     EQU         $-@@FFRPTTL
@@FFRPPORT      DW          ?
@@FFRPOFF       DW          ?
@@FFRPSEG       DW          ?

FILL_FR_PORT ENDP



BKPT_AT     PROC
	$STO_SCREEN 30, 10, 50, 14, SCREEN_BUF_1, 3
	$LITTLE_FRAME 30, 10, 50, 14, MENU_ATTR
	GOTOXY      32, 11
	lea         si, @@BKPT
	mov         cx, @@BKPT_L
	call        CPUTSTR
	GOTOXY      32, 12
	lea         si, DUMP_PROMPT1
	mov         cx, DUMP_PROMPT1_L
	call        CPUTSTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc	@@seg_got
            cmp	ah, 1
            jz	@@to_retn
            GOTOXY	32+DUMP_PROMPT1_L, 12
            mov	ax, UNASS_SEG
            call	CPUTHEX4
@@seg_got:
	mov         BKPT_ADDR[2], ax
	GOTOXY      32, 13
	lea         si, DUMP_PROMPT2
	mov         cx, DUMP_PROMPT2_L
	call        CPUTSTR
	wherexy
	inc         dx
	call        CGETHEX4
	jc          @@to_retn
	mov         BKPT_ADDR, ax
	mov         ax, offset BKPT_ADDR
	push        ax
	call        PUTBREAK
@@to_retn:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	$LOD_SCREEN 30, 10, 50, 14, SCREEN_BUF_1, 3
	ret

@@BKPT      DB          'BreakPoint At:'
@@BKPT_L    EQU         $-@@BKPT
BKPT_ADDR   DW          2 DUP (?)

BKPT_AT     ENDP



GO_UNTIL    PROC
;locals
;jumps
	$STO_SCREEN 25, 10, 33+@@GUSEG_L, 14, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 25, 10, 33+@@GUSEG_L, 14, MENU_ATTR
	mov         bl, MENU_ATTR
	WHEREXY
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	GOTOXY      35, 11
	mov         si, offset @@GUTTL
	mov         cx, 10
	call        CPUTSTR
	GOTOXY      27, 12
	mov         si, offset @@GUSEG
	mov         cx, @@GUSEG_L
	call        CPUTSTR
	call        CGETHEX4
	jnc         @@GUseg_got
	cmp         ah, 1
	jz          @@GUexit
	mov         ax, USER_CS
	call        CPUTHEX4
@@GUseg_got:
	mov         @@GUADDR[2], ax
	GOTOXY      27, 13
	mov         si, offset @@GUOFF
	mov         cx, @@GUOFF_L
	call        CPUTSTR
	call        CGETHEX4
	jc          @@GUexit
	mov         @@GUADDR, ax
	$LOD_SCREEN 25, 10, 33+@@GUSEG_L, 14, SCREEN_BUF_1, OUR_PAGE

	mov         ax, offset @@GUADDR
	push        ax
	call        PUTBREAK
	call        RUN
	mov         ax, offset @@GUADDR
	push        ax
	call        DELBREAK
	jmp	@@GUquit
@@GUexit:
	$LOD_SCREEN 25, 10, 33+@@GUSEG_L, 14, SCREEN_BUF_1, OUR_PAGE
@@GUquit:
	WHEREXY
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret

@@GUTTL       DB          'GO UNTIL', 0
@@GUSEG       DB          'Input Segment for BreakPoint: '
@@GUSEG_L     EQU         $-@@GUSEG
@@GUOFF       DB          'Input Offset for BreakPoint:  '
@@GUOFF_L     EQU         @@GUSEG_L

@@GUADDR      DW          2 DUP (?)
GO_UNTIL    ENDP



BREAK_HERE  PROC
	mov         ax, UNASS_PTR
	mov         BKPT_ADDR, ax
	mov         ax, UNASS_SEG
	mov         BKPT_ADDR[2], ax
	mov         ax, offset BKPT_ADDR
	push        ax
	call        PUTBREAK
	ret
BREAK_HERE  ENDP



SINGLE_STEP PROC
;locals
;----------------------------------------------------------------------------
;           Executes one instruction at USER_CS:USER_IP
;----------------------------------------------------------------------------
;           Select codes: CD - int, CC - int 3, CE - into, 8C - mov seg_reg
;                       E0, E1, E2 - loops, FF 1x - call (far), E8, 9A - call
	push        es
	push        si
	mov         es, USER_CS
	mov         si, USER_IP
	mov         al, es:[si]
	call        SPECIAL_INSTRS
	jz          @@SSTbkpt
	pop         si
	pop         es
	jmp         TRACE
@@SSTbkpt:
	cmp         al, 0F2h
	jb          @@SSTn_rep
	cmp         al, 0F3h
	ja          @@SSTn_rep
	inc         si
@@SSTn_rep:
	push        USER_IP
	push        USER_CS
	push        USER_IP
	mov         di, TEST_FIELD
	push        di
	sub         ax, ax
	mov         cx, 25
	cld
rep         stosw
	call        DASS
	mov         al, ds:[TEST_FIELD]
	cbw
	add         si, ax

;	mov         word ptr ds:[BP_SEGS+510], es       ; use breakpoint
;	mov         word ptr ds:[BP_OFFS+510], si       ; 255
;	mov         byte ptr ds:[BP_SIGN+255], 0FFh
;	lods        es:byte ptr [si]
;	mov         ds:[BP_BYTE+255], al

	mov	@@SS_ADDR, si
	mov	@@SS_ADDR[2], es
	mov	ax, offset @@SS_ADDR
	push	ax
	call        PUTBREAK
	call        RUN
	mov         ax, offset @@SS_ADDR
	push        ax
	call        DELBREAK

	pop         si
	pop         es

;	call        RUN
;	push        es
;	push        di
;	mov         es, ds:[BP_SEGS+510]
;	mov         di, ds:[BP_OFFS+510]
;	mov         al, ds:[BP_BYTE+255]
;	stosb
;	pop         di
;	pop         es
;	mov         word ptr ds:[BP_SEGS+510], 0
;	mov         word ptr ds:[BP_OFFS+510], 0
;	mov         byte ptr ds:[BP_SIGN+255], 0
	or	OPTIONS, 1
	ret

@@SS_ADDR	DW	2 DUP (?)

SINGLE_STEP ENDP


SPECIAL_INSTRS  PROC
;locals
	push        es
	push        di
	push        cx

	push        cs
	pop         es
	mov         di, offset @@DATA
	mov         cx, 12
	cld
repnz       scasb
	pop         cx
	pop         di
	pop         es
	ret

@@DATA      DB          0CCH, 0CDH, 0CEH, 9AH, 0E0H, 0E1H, 0E2H, 0E8H
	DB          0F2H, 0F3H, 0FFH, 8EH
SPECIAL_INSTRS  ENDP




DEL_BKPTS   PROC
	mov         di, BP_SIGN
	mov         cx, 128
	sub         ax, ax
	cld
rep         stosw
	mov         di, BP_SEGS
	mov         cx, 256
rep         stosw
	mov         di, BP_OFFS
	mov         cx, 256
rep         stosw
	ret
DEL_BKPTS   ENDP



TRACE       PROC
;----------------------------------------------------------------------------
;           Sets Trap flag and returns control to USER_CS:USER_IP
;----------------------------------------------------------------------------
	cmp         FLIP_STYLE, 0
	jz          @@save
	push        es
	push        si
	mov         es, USER_CS
	mov         si, USER_IP
	mov         al, es:[si]
	mov         @@CODE, al
	pop         si
	pop         es
	call        SPECIAL_INSTRS
	jnz         @@saved
	cmp         @@CODE, 0CDh
	jnz         @@chk_CC
	push        es
	push        si
	mov         es, USER_SS
	mov         si, USER_SP
	sub         USER_SP, 6
	mov         ax, USER_FL
	mov         es:[si-2], ax
	mov         ax, USER_CS
	mov         es:[si-4], ax
	mov         ax, USER_IP
	inc         ax
	inc         ax
	mov         es:[si-6], ax
	mov         es, USER_CS
	mov         si, USER_IP
	mov         al, es:[si+1]
	sub         ah, ah
	mov         si, ax
	shl         si, 1
	shl         si, 1
	sub         ax, ax
	mov         es, ax
	mov         ax, es:[si]
	mov         USER_IP, ax
	mov         UNASS_OFFS, ax
	mov         UNASS_PTR, ax
	mov         ax, es:[si+2]
	mov         USER_CS, ax
	mov         UNASS_SEG, ax
	pop         si
	pop         es
	call	FILL_QUEUE
	jmp         @@OK
@@chk_CC:
	mov         si, USER_IP
	mov         ds, USER_CS
	cmp         byte ptr [si], 0CCh
	push        cs
	pop         ds
	jnz         @@save
	inc         USER_IP
	jmp         @@OK
@@save:
	call        SAVE_MAIN_WIND
      	call        LOAD_USER_VIDEO
@@saved:
	COPY_QUEUE
	GET_NEXT_INSTR
	STORE_OUR_REGS
	LOAD_USER_REGS
	or          cs:USER_FL, 100h        ;Set trap flag
	push        cs:USER_FL
	push        cs:USER_CS
	push        cs:USER_IP
	iret
int1entry::
	pop         cs:USER_IP
	pop         cs:USER_CS
	pop         cs:USER_FL
	STORE_USER_REGS
	LOAD_OUR_REGS
	and         cs:USER_FL, 0FEFFh
	cmp         FLIP_STYLE, 0
	jz          @@load
	mov         al, @@CODE
	call        SPECIAL_INSTRS
	jnz         @@loaded
@@load:
	call        SAVE_USER_VIDEO
	call        RESTORE_MAIN_WIND
@@loaded:
	mov	ax, USER_IP		; Check if there was a
	cmp         ax, NEXT_INSTR	; control transfer
	jnz	@F		
	call	SHIFT_QUEUE             ; if it was not
	jmp	queue_OK
@@:
	call	FILL_QUEUE		; if it was
queue_OK:
	push        USER_CS
	push        USER_IP
	pop         UNASS_PTR
	pop         UNASS_SEG
	mov         ax, UNASS_PTR
	cmp         ax, UNASS_OFFS
	jb          @@chg_off
	cmp         ax, UNASS_BOTT
	ja          @@chg_off
	jmp         @@OK
@@chg_off:
	mov         UNASS_OFFS, ax
@@OK:
	
	mov         ax, USER_SP
	add         ax, 12
	mov         STACK_OFFS, ax
            or	OPTIONS, 1
	ret
@@CODE      DB          ?
TRACE       ENDP



COMPARE     PROC
;locals
;jumps
	$STO_SCREEN 20, 10, 28+STR2_SEG_L, 17, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 28+STR2_SEG_L, 17, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      35, 11
	mov         si, offset @@COMP_TTL
	mov         cx, 7
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset STR1_SEG
	mov         cx, STR1_SEG_L
	call        CPUTSTR
	GOTOXY      22+STR1_SEG_L
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc         @@seg1_got
	cmp         ah, 1
	jz          @@exit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@seg1_got:
	mov         @@SEG1, ax
	GOTOXY      22, 13
	mov         si, offset STR1_OFF
	mov         cx, STR1_OFF_L
	call        CPUTSTR
	GOTOXY      22+STR1_OFF_L
	call        CGETHEX4
	jc          @@exit
	mov         @@OFF1, ax
	GOTOXY      22, 14
	mov         si, offset STR2_SEG
	mov         cx, STR2_SEG_L
	call        CPUTSTR
	GOTOXY      22+STR2_SEG_L
	call        CGETHEX4
	jnc         @@seg2_got
	cmp         ah, 1
	jz          @@exit
	mov         ax,  DUMP_SEG
	call        CPUTHEX4
@@seg2_got:
	mov         @@SEG2, ax
	GOTOXY      22, 15
	mov         si, offset STR2_OFF
	mov         cx, STR2_OFF_L
	call        CPUTSTR
	GOTOXY      22+STR2_OFF_L
	call        CGETHEX4
	jc          @@exit
	mov         @@OFF2, ax
	GOTOXY      22, 16
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      22+RANGE_L
	call        CGETHEX4
	jc          @@exit
	mov         @@BYTES, ax
;----------------------------- Compare strings ------------------------------
	push        ds
	push        es
	push        si
	push        di
	mov         di, @@OFF2
	mov         si, @@OFF1
	mov         es, @@SEG2
	mov         ds, @@SEG1
	mov         cx, @@BYTES
	cld
repz        cmpsb
	pop         di
	pop         si
	pop         es
	pop         ds
	pushf
	$LITTLE_FRAME 20, 10, 28+STR2_SEG_L, 17, MENU_ATTR
	GOTOXY      22, 11
	mov         si, offset @@COMP_TTL
	mov         cx, 14
	call        CPUTSTR
	mov         ax, 12
	push        ax
	mov         ax, offset @@STRINGS
	push        ax
	mov         ax, @@SEG1
	call        INT_TO_STR
	mov         ax, 12
	push        ax
	mov         ax, offset @@STRINGS[5]
	push        ax
	mov         ax, @@OFF1
	call        INT_TO_STR
	mov         ax, 12
	push        ax
	mov         ax, offset @@STRINGS[14]
	push        ax
	mov         ax, @@SEG2
	call        INT_TO_STR
	mov         ax, 12
	push        ax
	mov         ax, offset @@STRINGS[19]
	push        ax
	mov         ax, @@OFF2
	call        INT_TO_STR

	GOTOXY      22, 12
	mov         si, offset @@RESULT
	mov         cx, 7
	call        CPUTSTR
	GOTOXY      22, 14
	mov         si, offset @@STRINGS
	mov         cx, @@STRINGS_L
	call        CPUTSTR
	GOTOXY      22, 16
	popf
	jnz         @@n_equal
	mov         si, offset @@POS_RESULT
	mov         cx, 7
@@out_res:
	mov         bl, SELECT_ATTR
	call        CPUTSTR
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
@@kbd:
	sub         ah, ah
	int         16h
	and         al, al
	jz          @@kbd
@@exit:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	$LOD_SCREEN 20, 10, 28+STR2_SEG_L, 17, SCREEN_BUF_1, OUR_PAGE
	ret
@@n_equal:
	mov         si, offset @@NEG_RESULT
	mov         cx, 11
	jmp         @@out_res

@@COMP_TTL  DB          'COMPARE '
@@REPORT    DB          'RESULT'
STR1_SEG  DB          'Input Segment for First String: '
STR1_SEG_L EQU        $-STR1_SEG
STR1_OFF  DB          'Input Offset for First String: '
STR1_OFF_L EQU        $-STR1_OFF
STR2_SEG  DB          'Input Segment for Second String: '
STR2_SEG_L EQU        $-STR2_SEG
STR2_OFF  DB          'Input Offset for Second String: '
STR2_OFF_L EQU        $-STR2_OFF
@@RESULT    DB          'Strings'
@@STRINGS   DB          'XXXX:XXXX and XXXX:XXXX are'
@@STRINGS_L EQU         $-@@STRINGS
@@POS_RESULT DB         ' EQUAL '
@@NEG_RESULT DB         ' NOT EQUAL '

@@SEG1      DW          ?
@@SEG2      DW          ?
@@OFF1      DW          ?
@@OFF2      DW          ?
@@BYTES     DW          ?

COMPARE     ENDP



FIND_BYTE   PROC
;locals
;jumps

;           Parameter:
;                       [bp+4] = flag:
;           0 - find, 1 - repead search

	push        bp
	mov         bp, sp
	cmp         byte ptr [bp+4], 0
	pop         bp
	jz          @@FBfind
	cmp         @@FBFLAG, 0
	jz          @@FBfind
	jmp         @@FBahead
@@FBfind:
	$STO_SCREEN 20, 10, 28+OFF_L, 17, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 28+OFF_L, 17, MENU_ATTR
	GOTOXY      29, 11
	mov         si, offset @@FBPROMPT
	mov         cx, @@FBPROMPT_L
	mov         bl, MENU_ATTR
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset SG_PROMPT
	mov         cx, SG_L
	call        CPUTSTR
	GOTOXY      22+SG_L
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc         @@FBseg_got
	cmp         ah, 1
	jz          @@FBexit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@FBseg_got:
	mov         @@FBSEG, ax
	GOTOXY      22, 13
	mov         si, offset OFF_PRMPT
	mov         cx, OFF_L
	call        CPUTSTR
	GOTOXY      22+OFF_L
	call        CGETHEX4
	jc          @@FBexit
	mov         @@FBOFF, ax
	GOTOXY      22, 14
	mov         si, offset @@FBDATA_PROMPT
	mov         cx, @@FBDATA_L
	call        CPUTSTR
	GOTOXY      22+@@FBDATA_L
	call        CGETHEX2
	jc          @@FBexit
	mov         @@FBDATA, al
	GOTOXY      22, 15
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      22+RANGE_L
	call        CGETHEX4
	jc          @@FBexit
	mov         @@FBRAN, ax
	GOTOXY      22, 16
	mov         si, offset DIRECT
	mov         cx, DIRECT_L
	call        CPUTSTR
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
@@FBkbd:
	sub         ah, ah
	int         16h
	cmp         ah, 33                  ;'F'
	jnz         @@FBdn?
	mov         @@FBDIR, 0
	cld
	jmp         @@FBahead
@@FBdn?:
	cmp         ah, 48                  ;'B'
	jnz         @@FBkbd
	mov         @@FBDIR, -1
	std
@@FBahead:
	$LOD_SCREEN 20, 10, 28+OFF_L, 17, SCREEN_BUF_1, OUR_PAGE
	push        es
	mov         di, @@FBOFF
	mov         es, @@FBSEG
	mov         al, @@FBDATA
	mov         cx, @@FBRAN
repnz       scasb
	pop         es
	cld
	jnz         @@FBn_found
	mov         @@FBOFF, di
	cmp         @@FBDIR, 0
	jnz         @@FBinc
	dec         di
	jmp         @@FBdone
@@FBinc:
	inc         di
@@FBdone:
	mov         ax, @@FBSEG
	mov         DUMP_SEG, ax
	mov         DUMP_OFFS, di
	mov         DUMP_PTR, di
	call        DUMP
	mov         al, -1
	push        ax
	call        SIGN_DUMP
	mov         @@FBFLAG, -1
	ret         2
@@FBn_found:
	$STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	GOTOXY      1, 23
	mov         si, offset N_FND
	mov         cx, N_FND_L
	mov         bl, ERR_ATTR
	call        CPUTSTR
	GOTOXY      1+N_FND_L
	mov         si, offset PR_ESC
	mov         cx, PR_ESC_L
	call        CPUTSTR
@@FBN_FND_LOOP:
	sub         ah, ah
	int         16h
	cmp         ah, 1
	jnz         @@FBN_FND_LOOP
	$LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
@@FBexit:
	$LOD_SCREEN 20, 10, 28+OFF_L, 17, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         @@FBFLAG, -1
	ret         2

@@FBPROMPT    DB          'SEARCH FOR DATA BYTE'
@@FBPROMPT_L  EQU         $-@@FBPROMPT
SG_PROMPT   DB          'Input Segment to Search in: '
SG_L        EQU         $-SG_PROMPT
OFF_PRMPT   DB          'Input Offset to Start Search: '
OFF_L       EQU         $-OFF_PRMPT
@@FBDATA_PROMPT DB        'Input Byte to Search for: '
@@FBDATA_L    EQU         $-@@FBDATA_PROMPT
RANGE       DB          'Input Range: '
RANGE_L     EQU         $-RANGE
DIRECT      DB          'Direction (F-ward/B-ward)'
DIRECT_L    EQU         $-DIRECT
N_FND       DB          'Search Argument NOT FOUND. '
N_FND_L     EQU         $-N_FND

@@FBSEG       DW          ?
@@FBOFF       DW          ?
@@FBDATA      DB          ?
@@FBRAN       DW          ?
@@FBDIR       DB          ?
@@FBFLAG      DB          0

FIND_BYTE ENDP



FIND_STRING PROC
;locals
;jumps

	push        bp
	mov         bp, sp
	cmp         byte ptr [bp+4], 0
	pop         bp
	jz          @@FSfind
	cmp         @@FSFLAG, 0
	jz          @@FSfind
	jmp         @@FSahead
@@FSfind:
	$STO_SCREEN 20, 10, 28+OFF_L, 18, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 28+OFF_L, 18, MENU_ATTR
	GOTOXY      27, 11
	mov         si, offset @@FSPROMPT
	mov         cx, @@FSPROMPT_L
	mov         bl, MENU_ATTR
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset SG_PROMPT
	mov         cx, SG_L
	call        CPUTSTR
	GOTOXY      22+SG_L
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc         @@FSseg_got
	cmp         ah, 1
	jz          @@FSexit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@FSseg_got:
	mov         @@FSSEG, ax
	GOTOXY      22, 13
	mov         si, offset OFF_PRMPT
	mov         cx, OFF_L
	call        CPUTSTR
	GOTOXY      22+OFF_L
	call        CGETHEX4
	jc          @@FSexit
	mov         @@FSOFF, ax
	GOTOXY      22, 14
	mov         si, offset @@FSSTR_PRMPT
	mov         cx, @@FSSTR_L
	call        CPUTSTR
	GOTOXY      22, 15
	mov         ah, 22
	mov         al, 40
	push        ax
	mov         ax, offset @@FSSTR
	push        ax
	add         ax, 99
	push        ax
	call        CGETSTR
	mov         @@FSN, cx
	GOTOXY      22, 16
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      22+RANGE_L
	call        CGETHEX4
	jc          @@FSexit
	mov         @@FSRANGE, ax
	GOTOXY      22, 17
	mov         si, offset DIRECT
	mov         cx, DIRECT_L
	call        CPUTSTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
@@FSkbd:
	sub         ah, ah
	int         16h
	cmp         ah, 33                  ;'F'
	jnz         @@FSback?
	mov         @@FSDIR, 1
	jmp         @@FSOK
@@FSback?:
	cmp         ah, 48                  ;'B'
	jnz         @@FSkbd
	mov         @@FSDIR, -1
@@FSOK:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	$LOD_SCREEN 20, 10, 28+OFF_L, 18, SCREEN_BUF_1, OUR_PAGE
;----------------------------- Search for string ----------------------------
@@FSahead:
	push        es
	
	mov         di, @@FSOFF
	mov         es, @@FSSEG
	mov         cx, @@FSRANGE
@@FSloop:
	push        cx
	mov         @@FSOFF, di
	mov         si, offset @@FSSTR
	mov         cx, @@FSN
	cld
repz        cmpsb
	pop         cx
	jz          @@FSfound
	mov         di, @@FSOFF
	add         di, @@FSDIR
	loop        @@FSloop

	pop         es
	$STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	GOTOXY      1, 23
	mov         si, offset N_FND
	mov         cx, N_FND_L
	mov         bl, ERR_ATTR
	call        CPUTSTR
	GOTOXY      1+N_FND_L
	mov         si, offset PR_ESC
	mov         cx, PR_ESC_L
	call        CPUTSTR
@@FSN_FND_LOOP:
	sub         ah, ah
	int         16h
	cmp         ah, 1
	jnz         @@FSN_FND_LOOP
	$LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	jmp         @@FSexit
@@FSfound:
	pop         es
	mov         ax, @@FSSEG
	mov         DUMP_SEG, ax
	mov         ax, @@FSOFF
	mov         DUMP_OFFS, ax
	mov         DUMP_PTR, ax
	call        DUMP
	mov         al, -1
	push        ax
	call        SIGN_DUMP
	mov         ax, @@FSDIR
	add         @@FSOFF, ax
	mov         @@FSFLAG, -1
	ret         2
@@FSexit:
	cld
	$LOD_SCREEN 20, 10, 28+OFF_L, 18, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         @@FSFLAG, -1
	ret         2

@@FSPROMPT    DB          'SEARCH FOR DATA STRING'
@@FSPROMPT_L  EQU         $-@@FSPROMPT
@@FSSTR_PRMPT DB          'Input Search String'
@@FSSTR_L     EQU         $-@@FSSTR_PRMPT
@@FSSEG       DW          ?
@@FSOFF       DW          ?
@@FSSTR       DB          100 DUP (?)
@@FSRANGE     DW          ?
@@FSN         DW          ?
@@FSDIR       DW          ?
@@FSFLAG      DB          0

FIND_STRING ENDP



FIND_INSTR  PROC
;locals
;jumps

	push        bp
	mov         bp, sp
	cmp         byte ptr [bp+4], 0
	pop         bp
	jz          @@FIfind
	cmp         @@FIFLAG, 0
	jz          @@FIfind
	jmp         @@FIahead
@@FIfind:
	$STO_SCREEN 20, 10, 28+OFF_L, 18, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 28+OFF_L, 18, MENU_ATTR
	GOTOXY      30, 11
	mov         si, offset @@FIPROMPT
	mov         cx, @@FIPROMPT_L
	mov         bl, MENU_ATTR
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset SG_PROMPT
	mov         cx, SG_L
	call        CPUTSTR
	GOTOXY      22+SG_L
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc         @@FIseg_got
	cmp         ah, 1
	jz          @@FIexit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@FIseg_got:
	mov         @@FISEG, ax
	GOTOXY      22, 13
	mov         si, offset OFF_PRMPT
	mov         cx, OFF_L
	call        CPUTSTR
	GOTOXY      22+OFF_L
	call        CGETHEX4
	jc          @@FIexit
	mov         @@FIOFF, ax
	GOTOXY      22, 14
	mov         si, offset ASSM_PROMPT
	mov         cx, ASSM_PROMPT_L
	call        CPUTSTR
	GOTOXY      22, 15
	mov         ah, 22
	mov         al, 40
	push        ax
	mov         di, TEST_FIELD
	push        di
	mov         cx, 25
	sub         ax, ax
rep         stosw
	dec         di
	push        di
	call        CGETSTR
	jc          @@FIexit
	push        bx
	mov         ax, TEST_FIELD
	push        ax
	mov         ax, offset @@FIINSTR
	push        ax
	push        @@FIOFF
	call        ASSEMBLE
	pop         bx
	mov         al, @@FIINSTR
	cbw
	mov         @@FILEN, ax
	GOTOXY      22, 16
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      22+RANGE_L
	call        CGETHEX4
	jc          @@FIexit
	mov         @@FIRANGE, ax
	GOTOXY      22, 17
	mov         si, offset DIRECT
	mov         cx, DIRECT_L
	call        CPUTSTR
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
@@FIkbd:
	sub         ah, ah
	int         16h
	cmp         ah, 33                  ;'F'
	jnz         @@FIback?
	mov         @@FIDIR, 1
	jmp         @@FIOK
@@FIback?:
	cmp         ah, 48                  ;'B'
	jnz         @@FIkbd
	mov         @@FIDIR, -1
@@FIOK:
	$LOD_SCREEN 20, 10, 28+OFF_L, 18, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
;-------------------------- Search for instruction --------------------------
@@FIahead:
	push        es
	mov         cx, @@FIRANGE
	mov         di, @@FIOFF
	mov         es, @@FISEG
@@FIloop:
	push        cx
	mov         @@FIOFF, di
	mov         si, offset @@FIINSTR[1]
	mov         cx, @@FILEN
	cld
repz        cmpsb
	pop         cx
	jz          @@FIfound
	mov         di, @@FIOFF
	mov	al, @@FIINSTR[1]
	call	CHK_JUMP
            or	ax, ax
	jz	@@FIjmp_done
	cmp	ax, 1
	jnz	@@FInear_jmp
	mov	al, byte ptr @@FIDIR
	sub	@@FIINSTR[2], al
	jmp	@@FIjmp_done
@@FInear_jmp:
	mov	ax, @@FIDIR
	sub	word ptr @@FIINSTR[2], ax
@@FIjmp_done:
	add         di, @@FIDIR
	loop        @@FIloop

	pop         es
	$STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	GOTOXY      1, 23
	mov         si, offset N_FND
	mov         cx, N_FND_L
	mov         bl, ERR_ATTR
	call        CPUTSTR
	GOTOXY      1+N_FND_L
	mov         si, offset PR_ESC
	mov         cx, PR_ESC_L
	call        CPUTSTR
@@FIN_FND_LOOP:
	sub         ah, ah
	int         16h
	cmp         ah, 1
	jnz         @@FIN_FND_LOOP
	$LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	jmp         @@FIexit

@@FIfound:
	pop         es
	mov         ax, @@FISEG
	mov         UNASS_SEG, ax
	mov         ax, @@FIOFF
	mov         UNASS_OFFS, ax
	mov         UNASS_PTR, ax
            mov	al, UNASS_TOP
            mov	UPTR_LINE, al
	call        UNASSEMBLE
	mov         ax, @@FIDIR
	add         @@FIOFF, ax
	mov         @@FIFLAG, -1
	ret         2
@@FIexit:
	$LOD_SCREEN 20, 10, 28+OFF_L, 18, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         @@FIFLAG, -1
	ret         2

@@FIPROMPT    DB          'SEARCH FOR INSTRUCTION'
@@FIPROMPT_L  EQU         $-@@FIPROMPT
@@FIINSTR     DB          9 DUP (?)
@@FILEN       DW          ?
@@FIRANGE     DW          ?
@@FISEG       DW          ?
@@FIOFF       DW          ?
@@FIDIR       DW          ?
@@FIFLAG      DB          0

FIND_INSTR  ENDP



END_PROG PROC
;locals
;jumps

;----------------------------------------------------------------------------
;           This routine is to be placed on INT 20, INT 21 (0, 4Ch)
;----------------------------------------------------------------------------
	cmp         ah, 4Bh
	jnz         @@EPRGtermin?
	cmp         al, 0
	jnz         @@EPRGcall_DOS
	inc         cs:@@EPRGPROCESS
	jmp         @@EPRGcall_DOS

@@EPRGtermin?:
	cmp         ah, 4Ch                 ; Terminate program
	jz          @@EPRGfunct_4c
	cmp         ah, 0                   ; Old terminate program
	jz          termin_entry
	cmp         ah, 31h                 ; Stay resident
	jz          @@EPRGresident

@@EPRGcall_DOS:
	DB          0EAh                    ; long JUMP to
INT_21      DW          2 DUP (?)               ; original INT 21

int20entry::
	sub         ah, ah
termin_entry:
	sub         al, al
@@EPRGfunct_4c:
	cmp         cs:@@EPRGPROCESS, 0
	jz          @@EPRGdo_termin
	dec         cs:@@EPRGPROCESS
	jmp         @@EPRGcall_DOS
@@EPRGdo_termin:
	sti
	mov         cs:@@EPRGCODE, al
	pop         cs:USER_IP
	pop         cs:USER_CS
	pop         cs:USER_FL
	STORE_USER_REGS
	LOAD_OUR_REGS

	call	UNSTORBRK

	push	bx
	mov	ah, 50h
	mov	bx, cs
	int	21h
	pop	bx

            mov	ax, 2508h
            lds	dx, dword ptr ORIG_INT8
            int	21h
            mov	ax, 251Bh
            lds	dx, dword ptr cs:ORIG_INT1B
            int	21h
            push	cs
            pop	ds
	call        LOAD_VECTORS
	call        SAVE_USER_VIDEO
	call        RESTORE_MAIN_WIND

	push	es
	mov	es, PROG_ENV
	mov	ah, 49h
	int	21h		; free program environment

	mov	es, WORK_AREA
	mov	ah, 49h
	int	21h		; free program area
	pop	es

@@EPRGinternal:
	$STO_SCREEN 20, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 60, 15, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      30, 11
	mov         si, offset @@EPRGTTL
	mov         cx, @@EPRGTTL_L
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset @@EPRGLINE
	mov         cx, @@EPRGLINE_L
	call        CPUTSTR
	GOTOXY      22+@@EPRGLINE_L
	mov         bl, SELECT_ATTR
	mov         al, @@EPRGCODE
	call        CPUTHEX2
	GOTOXY      30, 14
	mov         si, offset PR_KEY
	mov         cx, PR_KEY_L
	mov         bl, MENU_ATTR
	call        CPUTSTR
@@EPRGloop:
	sub         ah, ah
	int         16h
            or	al, al
	jz          @@EPRGloop

	$LOD_SCREEN 20, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
            call	REFRESH
	ret
int27entry::
	cmp         cs:@@EPRGPROCESS, 0
	jz          @@EPRGdo_int27
	dec         cs:@@EPRGPROCESS

	DB          0EAH
ORIG_INT27  DW          2 DUP (?)

@@EPRGdo_int27:
	shr         dx, 1
	shr         dx, 1
	shr         dx, 1
	shr         dx, 1
	inc         dx
	mov         cs:@@EPRGCODE, 0
	jmp         @@EPRGgo_on
@@EPRGresident:
	mov         cs:@@EPRGCODE, al
	cmp         cs:@@EPRGPROCESS, 0
	jz          @@EPRGgo_on
	dec         cs:@@EPRGPROCESS
	jmp         @@EPRGcall_DOS
@@EPRGgo_on:
	mov	cs:@@EPRGKEEP_DX, dx
	pop         cs:USER_IP
	pop         cs:USER_CS
	pop         cs:USER_FL
	STORE_USER_REGS
	LOAD_OUR_REGS
            mov	ax, 2508h
            lds	dx, dword ptr ORIG_INT8
            int	21h
            mov	ax, 251Bh
            lds	dx, dword ptr cs:ORIG_INT1B
            int	21h
            push	cs
            pop	ds
	sti
	call        LOAD_VECTORS
	call        SAVE_USER_VIDEO
	call        RESTORE_MAIN_WIND
	push        bx
	mov         bx, @@EPRGKEEP_DX
	mov         ax, WORK_AREA
	dec	ax
	mov	es, ax
	mov	es:[01h], cs
	inc	ax
	mov	es, ax
	mov         ah, 4Ah
	int         21h
            mov	ax, es
            dec	ax
            mov	es, ax
            inc	ax
	mov	es:[1], ax

	mov	ah, 50h
	mov	bx, cs
	int	21h
	pop         bx

	push        cs
	pop         es
	jc          @@EPRGfire_exit
	push        bx
	mov         ah, 48h
	mov         bx, 1000
	int         21h
	jnc         @@EPRGalloc_OK
	mov         ah, 48h
	int         21h
@@EPRGalloc_OK:
	pop         bx
	mov         WORK_AREA, ax
            mov	ENVIRON, 0FFFFh
	$STO_SCREEN 20, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 60, 15, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      30, 11
	mov         si, offset @@EPRGTTL
	mov         cx, @@EPRGTTL_L
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset @@EPRGRES_LINE
	mov         cx, @@EPRGRLINE_L
	call        CPUTSTR
	GOTOXY      22+@@EPRGRLINE_L
	mov         al, @@EPRGCODE
	call        CPUTHEX2
            mov	bl, SELECT_ATTR
	GOTOXY      30, 14
	mov         si, offset PR_KEY
	mov         cx, PR_KEY_L
            mov	bl, MENU_ATTR
	call        CPUTSTR
	jmp         @@EPRGloop
@@EPRGfire_exit:
	$LOD_SCREEN 20, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
	$STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	mov         bl, ERR_ATTR
	GOTOXY      1, 23
	mov         ax, 920h
	mov         cx, 78
	int         10h
	GOTOXY      3
	mov         si, offset @@EPRGRES_ERR
	mov         cx, @@EPRGRES_ERR_L
	call        CPUTSTR
	GOTOXY      3+@@EPRGRES_ERR_L
	mov         si, offset PR_ESC
	mov         cx, PR_ESC_L
	call        CPUTSTR
@@EPRGerr_loop:
	sub         ah, ah
	int         16h
	cmp         ah, 1
	jnz         @@EPRGerr_loop
	$LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
	jmp         @@EPRGinternal

@@EPRGCODE      DB          ?
@@EPRGTTL       DB          'TERMINATE PROGRAM'
@@EPRGTTL_L     EQU         $-@@EPRGTTL
@@EPRGLINE      DB          'Program terminated with exit code '
@@EPRGLINE_L    EQU         $-@@EPRGLINE
@@EPRGRES_LINE  DB          'Program resident with exit code '
@@EPRGRLINE_L   EQU         $-@@EPRGRES_LINE
@@EPRGRES_ERR   DB          'Memory error - cannot keep resident. Exitting. '
@@EPRGRES_ERR_L EQU         $-@@EPRGRES_ERR
@@EPRGPROCESS   DB          0
@@EPRGKEEP_DX   DW	?

PR_KEY    	DB          'Press any key . . .'
PR_KEY_L  	EQU         $-PR_KEY
PROG_ENV	DW	?
MCB_PTR	DW	2 dup (?)
PROG_MCB	DB	16 dup (?)

END_PROG    ENDP



COPY        PROC
;locals
;jumps
;----------------------------------------------------------------------------
;                       Copies one string to another
;----------------------------------------------------------------------------
	$STO_SCREEN 20, 10, 28+STR2_SEG_L, 17, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 28+STR2_SEG_L, 17, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      36, 11
	mov         si, offset @@CPYTTL
	mov         cx, @@CPYTTL_L
	call        CPUTSTR
	GOTOXY      22, 12
	mov         si, offset STR1_SEG
	mov         cx, STR1_SEG_L
	call        CPUTSTR
	GOTOXY      22+STR1_SEG_L
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jnc         @@CPYseg1_OK
	cmp         ah, 1
	jz          @@CPYexit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@CPYseg1_OK:
	mov         @@CPYSEG1, ax
	GOTOXY      22, 13
	mov         si, offset STR1_OFF
	mov         cx, STR1_OFF_L
	call        CPUTSTR
	GOTOXY      22+STR1_OFF_L
	call        CGETHEX4
	jc          @@CPYexit
	mov         @@CPYOFF1, ax
	GOTOXY      22, 14
	mov         si, offset STR2_SEG
	call        CPUTSTR
	GOTOXY      22+STR2_SEG_L
	call        CGETHEX4
	jnc         @@CPYseg2_OK
	cmp         ah, 1
	jz          @@CPYexit
	mov         ax, DUMP_SEG
	call        CPUTHEX4
@@CPYseg2_OK:
	mov         @@CPYSEG2, ax
	GOTOXY      22, 15
	mov         si, offset STR2_OFF
	mov         cx, STR2_OFF_L
	call        CPUTSTR
	GOTOXY      22+STR2_OFF_L
	call        CGETHEX4
	jc          @@CPYexit
	mov         @@CPYOFF2, ax
	GOTOXY      22, 16
	mov         si, offset RANGE
	mov         cx, RANGE_L
	call        CPUTSTR
	GOTOXY      22+RANGE_L
	call        CGETHEX4
	jc          @@CPYexit
	mov         @@CPYRANGE, ax

	push        ds
	push        es
	
	mov	ax, @@CPYSEG1
	mov	cl, 4
	rol	ax, cl
	mov	dx, ax
	and	ax, 0FFF0h
	and	dx, 000Fh		
	add	ax, @@CPYOFF1
	adc	dl, 0		; DX:AX -> source linear address

	mov	di, @@CPYSEG2
	rol	di, cl
	mov	si, di
	and	di, 0FFF0h
	and	si, 000Fh
	add	di, @@CPYOFF2
	adc	si, 0		; SI:DI -> dest linear address

	cmp	dx, si
	ja	@@CPYfwd
	jb	@@CPYbwd
	cmp	ax, di
	ja	@@CPYfwd
@@CPYbwd:
	mov         cx, @@CPYRANGE
	les         di, dword ptr @@CPYOFF2
	lds         si, dword ptr @@CPYOFF1
	add	si, cx
	add	di, cx
	dec	si
	dec	di
	std
	jmp	@@CPYdo

@@CPYfwd:
	mov         cx, @@CPYRANGE
	les         di, dword ptr @@CPYOFF2
	lds         si, dword ptr @@CPYOFF1
	cld
@@CPYdo:
rep	movsb
	cld
	pop         es
	pop         ds
	call	FILL_QUEUE		; Fill CPU queue emul. buffer

@@CPYexit:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	$LOD_SCREEN 20, 10, 28+STR2_SEG_L, 17, SCREEN_BUF_1, OUR_PAGE
           call	REFRESH
	ret

@@CPYOFF1      DW          ?
@@CPYSEG1      DW          ?
@@CPYOFF2      DW          ?
@@CPYSEG2      DW          ?
@@CPYRANGE     DW          ?
@@CPYTTL       DB          'COPY STRINGS'
@@CPYTTL_L     EQU         $-@@CPYTTL

COPY        ENDP



ARGUMENTS   PROC
;locals
;jumps
;----------------------------------------------------------------------------
;                       Get new command-line arguments
;----------------------------------------------------------------------------
	$STO_SCREEN 25, 10, 29+@@ARGPROMPT_L, 14, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 25, 10, 29+@@ARGPROMPT_L, 14, MENU_ATTR
	mov         bl, MENU_ATTR
	GOTOXY      35, 11
	mov         si, offset @@ARGTTL
	mov         cx, @@ARGTTL_L
	call        CPUTSTR
	GOTOXY      27, 12
	mov         si, offset @@ARGPROMPT
	mov         cx, @@ARGPROMPT_L
	call        CPUTSTR
	GOTOXY      30, 13
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	mov         ah, 30
	mov         al, 27+@@ARGPROMPT_L
	push        ax
	mov         di, COM_LINE+2
	push        di
	mov         cx, 125
	sub         al, al
rep         stosb
	dec         di
	push        di
	call        CGETSTR
	jc          @@ARGexit1
	inc         cx
	mov         ds:[COM_LINE], cl
	mov         byte ptr ds:[COM_LINE+1], ' '
	mov         di, cx
	mov         byte ptr ds:[di+COM_LINE+1], 0Dh
	mov         si, COM_LINE
	mov         di, 80h
	inc         cx
	inc         cx
	push        es
	mov         es, WORK_AREA
	inc         cx
	inc         cx
	cld
rep         movsb
	pop         es
            call	REFRESH
@@ARGexit1:
	$LOD_SCREEN 25, 10, 29+@@ARGPROMPT_L, 14, SCREEN_BUF_1, OUR_PAGE
@@ARGexit:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	ret

@@ARGTTL       DB          'ARGUMENTS'
@@ARGTTL_L     EQU         $-@@ARGTTL
@@ARGPROMPT    DB          'Input New Command Line: '
@@ARGPROMPT_L  EQU         $-@@ARGPROMPT

ARGUMENTS   ENDP


ASSM_HERE	PROC
;locals
	$STO_SCREEN	11, UPTR_LINE, 57, UPTR_LINE, SCREEN_BUF_1, OUR_PAGE
            GOTOXY 	11, UPTR_LINE
            mov	ax, 920h
            mov	cx, 47
            mov	bl, UNASS_PTR_ATTR
            int	10h
            WHEREXY
            and	ch, 10011111b
            mov	ah, 1
            int	10h
            mov	ah, 11
            mov	al, 57
            push	ax
            mov	ax, offset FIELD
            push	ax
            add	ax, 99
            push	ax
            call	CGETSTR
            jc	@@exit
	mov	ax, offset FIELD
            push	ax
            mov	ax, offset INSTR_FLD
            push	ax
            push	UNASS_PTR
            call	ASSEMBLE
            jnc	@@assm_OK
@@exit:
	$LOD_SCREEN 11, UPTR_LINE, 57, UPTR_LINE, SCREEN_BUF_1, OUR_PAGE
@@quit:
            WHEREXY
            or	ch, 00100000b
            mov	ah, 1
	int	10h
	call	FILL_QUEUE		; assembly procedure
				; resets CPU queue emul. buf
            retn
@@assm_OK:
	mov	cl, INSTR_FLD
            sub	ch, ch
            mov	si, offset INSTR_FLD[1]
            mov	es, UNASS_SEG
            mov	di, UNASS_PTR
rep	movsb
	push	cs
            pop	es
            mov	al, INSTR_FLD
            cbw
            add	UNASS_PTR, ax
            mov	ax, UNASS_PTR
            cmp	ax, UNASS_BOTT
            jnb	@@go_down
            inc	UPTR_LINE
            jmp	@@ending
@@go_down:
            push	UNASS_OFFS
	push	UNASS_SEG
            push	UNASS_OFFS
            mov	di, offset FIELD
            push	di
            mov	cx, 25
            cld
            sub	ax, ax
rep	stosw
	call	DASS
            mov	al, FIELD
            cbw
            add	UNASS_OFFS, ax
@@ending:
	call	REFRESH
            jmp	@@quit
ASSM_HERE	ENDP


INT_1B	PROC
	mov	cs:BREAK_FLAG, 1

	DB	0EAh
ORIG_INT1B	DW	2 DUP (?)

INT_1B	ENDP


INT_8	PROC
;locals
	cmp	cs:BREAK_FLAG, 0
	jz	@@call_timer
            pop	cs:USER_IP
            pop	cs:USER_CS
            pop	cs:USER_FL
            STORE_USER_REGS
	LOAD_OUR_REGS

	push	bx
	mov	bx, cs
	mov	ah, 50h
	int	21h
	pop	bx

            push	OUR_FL
            push	cs
            mov	ax, offset int8entry
            push	ax
@@call_timer:
	DB	0EAh
ORIG_INT8	DW	2 DUP (?)
BREAK_FLAG	DB	?

INT_8	ENDP


CHK_JUMP	PROC
;locals
;
;	Receives: AL=code
;	Returns AX=0 if instr. is not a relative jump, AX=1 if
;		short jump, AX=2 if near jump.
;
	cmp	al, 0EBh
            jz	@@short
            cmp	al, 0E0h
            jb	@@chk_condit
            cmp	al, 0E3h
            jna	@@short
            cmp	al, 0E8h
            jz	@@near
            cmp	al, 0E9h
            jz	@@near
            jmp	@@no_jump
@@chk_condit:
            cmp	al, 70h
            jb	@@no_jump
            cmp	al, 7Fh
            ja	@@no_jump
@@short:
	mov	ax, 1
            retn
@@near:
	mov	ax, 2
	retn
@@no_jump:
	sub	ax, ax
            retn
CHK_JUMP	ENDP


REFRESH	PROC
;locals
	cmp	OUR_MODE, 7
            jnz	@@color
            mov	dx, 3BAh
            jmp	@@wait_retrace
@@color:
	mov	dx, 3DAh
@@wait_retrace:
	in	al, dx
            test	al, 8
            jz	@@wait_retrace
            call	DUMP
            call	UNASSEMBLE
            call	REGISTERS
            call	__STACK__
            retn
REFRESH	ENDP


INT_6	PROC
;locals
	sti
	pop         cs:USER_IP
	pop         cs:USER_CS
	pop         cs:USER_FL
	STORE_USER_REGS
	LOAD_OUR_REGS

	push	bx
	mov	bx, cs
	mov	ah, 50h
	int	21h
	pop	bx

            mov	ax, 2508h
            lds	dx, dword ptr ORIG_INT8
            int	21h
            mov	ax, 251Bh
            lds	dx, dword ptr cs:ORIG_INT1B
            int	21h
            push	cs
            pop	ds
	    sti
;;
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
	call	FILL_QUEUE		; Fill CPU queue emul. buffer
	call	REFRESH
;;
	$STO_SCREEN	15, 10, 65, 15, SCREEN_BUF_1, OUR_PAGE
            $LITTLE_FRAME 15, 10, 65, 15, MENU_ATTR
            GOTOXY	27, 12
            mov	si, offset @@EXPLAIN
            mov	cx, @@EXPLAIN_L
            mov	bl, MENU_ATTR
            call	CPUTSTR
	push	ds
            push	si
            mov	si, USER_IP
            mov	ds, USER_CS
	lodsw
	pop	si
	pop	ds
            mov	bl, SELECT_ATTR
            call	CPUTHEX2
            mov	al, ah
            WHEREXY
            inc	dx
	GOTOXY
	call	CPUTHEX2
            GOTOXY      20, 13
            mov	si, offset @@EXPLAIN2
            mov	cx, @@EXPLAIN2_L
            mov	bl, MENU_ATTR
            call	CPUTSTR
            mov	si, offset PR_KEY
            mov	cx, PR_KEY_L
            call	CPUTSTR
@@kbd_lp:
	sub	ah, ah
            int	16h
            or	al, al
            jz	@@kbd_lp
            $LOD_SCREEN	15, 10, 65, 15, SCREEN_BUF_1, OUR_PAGE
            retn

@@EXPLAIN	DB	'Undefined opcode '
@@EXPLAIN_L	EQU	$-@@EXPLAIN
@@EXPLAIN2	DB	'tried to be executed. '
@@EXPLAIN2_L  EQU	$-@@EXPLAIN2

INT_6	ENDP


FILL_QUEUE	PROC

IFDEF	PREFETCH_EMUL
;
;	Resets the internal CPU queue emul. buffer
;
	push	ds
	mov	si, USER_IP
	mov	di, offset QueueBuf
	mov	cx, QueueLen
	mov	ds, USER_CS
	cld
rep	movsb
	pop	ds
ENDIF	;PREFETCH_EMUL

	retn

FILL_QUEUE	ENDP


SHIFT_QUEUE	PROC
IFDEF	PREFETCH_EMUL
;
;	Shifts internal CPU queue emul. buffer 1 instruction up
;
	push	USER_IP
	push	ds
	mov	ax, offset QueueBuf
	push	ax
	mov	ax, TEST_FIELD
	push	ax
	call	DASS
	mov	al, ds:[TEST_FIELD]     ; AX=length of last in-
	cbw 			; struction

	mov	di, offset QueueBuf
	mov	si, di
	add	si, ax
	mov	cx, QueueLen
	sub	cx, ax
	cld
rep	movsb			; shift queue one instr. up

	mov	si, USER_IP
	add	si, QueueLen
	sub	si, ax
	mov	cx, ax
	push	ds
	mov	ds, USER_CS
rep	movsb			; copy last bytes to queue
	pop	ds

ENDIF	; PREFETCH_EMUL
	retn
SHIFT_QUEUE	ENDP
