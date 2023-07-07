	_1K         EQU         1024
            CONFIG	EQU	65

	INCLUDE STDIO.MCR
	INCLUDE PHANTOM.MCR

CODE        SEGMENT
ASSUME      CS:CODE, DS:CODE, SS:CODE, ES:CODE
MAIN        PROC
;locals
;jumps
_BEGIN_::
	ORG         100h
_START::
	call        CHK_SYS
	jnc         OK_1                    ;if no error
	mov         ERRORCODE, 1            ;error: DOS<2.00
	call        ERR_HANDLER
	mov         ax, 4CFFh
	int         21h
OK_1:
	
	mov         bx, (INSP_SIZE SHR 4) + 1
	mov         ah, 4Ah                 ;set block for program
	int         21h

	mov         bx, 100h                ;4K
	mov         ah, 48h                 ;for stack
	int         21h
	pop         bx                      ;get return address
	mov         OUR_SS, ax
	mov         ss, ax
	mov         sp, 4096
	push        bx                      ;put it to new stack

;---------------------------- Check XMS Presence ----------------------------
	call        XMS_INSTALL_CHECK
	jc          @@go_on_00
	or          byte ptr PROG_STATUS[1], 10h
	mov         ax, 4
	push        ax
	call        XMS_ALLOC               ; Allocate 4K for Main Window
	mov         MAIN_WIND_HANDLE, dx
	jmp         @@go_on_01

@@go_on_00:
	mov         bx, 100h
	mov         ah, 48h
	int         21h
	mov         MAIN_WINDOW, ax

@@go_on_01:
;------------------- Prepare for BreakPoint Management ----------------------
	cld
	mov         di, BP_OFFS
	mov         cx, 256
	sub         ax, ax
rep         stosw
	mov         di, BP_SEGS
	mov         cx, 256
rep         stosw
	mov         di, BP_SIGN
	mov         cx, 128
rep         stosw

	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@alloc_XMS

@@alloc_DOS:
	mov         bx, GRAPH_MODE_BUF      ;Allocate DOS memory
	mov         cl, 6
	shl         bx, cl
	mov         ah, 48h
	int         21h                     ;for video (graphic) buffer
	jnc	@F
	mov	ERRORCODE, 3
	call	ERR_HANDLER
	jmp	go_home
@@:
	mov         USER_V_GRAPH, ax
	mov         bx, TEXT_MODE_BUF
	shl         bx, cl
	mov         ah, 48h
	int         21h
	jnc	@F
	mov	ERRORCODE, 3
	call	ERR_HANDLER
	jmp	go_home
@@:
	mov         USER_V_TEXT, ax
	jmp         @@entry

@@alloc_XMS:
	push        GRAPH_MODE_BUF
	call        XMS_ALLOC
	and         ax, ax
	jz          @@alloc_DOS
	mov         VGRAPH_HANDLE, dx
	push        TEXT_MODE_BUF
	call        XMS_ALLOC
	and         ax, ax
	jz          @@alloc_DOS
	mov         VTEXT_HANDLE, dx
@@entry:
	call        SAVE_USER_VIDEO
	sub         ah, ah
	test        byte ptr VTEXT_BUFFER[1], 8
	jnz         _set_mode_3
	mov         al, 7
	jmp         short       _set_mode_OK
_set_mode_3:
	mov         al, 3
_set_mode_OK:
	int         10h                     ;set INSPECTOR mode (3 or 7)
	mov         word ptr ds:[COM_LINE], 0D00h
	Select_Page OUR_PAGE
            cmp	MOUSE_STAT, 0
            jz	@@no_mouse
            mov	ax, 1
            int	33h		; display mouse pointer

@@no_mouse:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	mov         ax, 1003h
	sub         bl, bl
	int         10h                     ;disable EGA/VGA blink
	wherexy                             ;get cursor
	or          ch, 40h
	mov         ah, 1                   ;make
	int         10h                     ;cursor invisible

	mov         bx, 1000h               ;64K for work area that was
	mov         ah, 48h                 ;freed - lend
	int         21h                     ;from DOS
	jnc	@F
	mov	ah, 48h		;if free mem < 64K,
	int	21h		; allocate the largest block
@@:
	mov         WORK_AREA, ax
	mov         USER_DS, ax
	mov         USER_CS, ax
	mov         USER_SS, ax
	mov         USER_ES, ax
	mov         DUMP_SEG, ax
	mov         UNASS_SEG, ax
	mov         dx, ax
	mov         ah, 26h
	int         21h                     ; create PSP
@@start_work:
	mov         bh, OUR_PAGE
	mov         bl, ATTRIB
            mov	al, UNASS_TOP
            mov	UPTR_LINE, al
            mov	al, DUMP_TOP
            mov	DPTR_LINE, al

	call	FILL_QUEUE		; Fill CPU queue emul. buffer

	call        FRAME
	call        SHOW_ACT_WINDOW
	call	REFRESH
	PRINT_CPU
	call        CHK_ARGS                ; command-line arguments
	call        INSTALL_VECTORS
	call        PRINT_HELLO
MAIN        ENDP

	

UNASS_WORK  PROC
;locals
;jumps
	call	CHK_FNC
	mov         bh, OUR_PAGE
	mov         bl, AC_WIND_ATTR
	mov         HELP_CODE, 1
	call	REFRESH
	call	GETCH
	cmp         ah, 45                  ;ALT+'X'->exit
	jz          @@go_home?
	jmp         @@esc?
@@go_home?:
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jnz         go_home
	jmp         @@esc?
;------------------------ Exitting PHANTOM INSPECTOR ------------------------
go_home::
	cmp	MOUSE_STAT, 0
            jz	@@no_mouse
            mov	ax, 2
	int	33h		; hide mouse pointer

	mov	ax, 0Ch
	sub	cx, cx                  ; uninstall mouse
	int	33h		; event handler

@@no_mouse:
	call        REINSTALL_VECTORS
	call        LOAD_USER_VIDEO
	mov         ax, 40h
	mov         es, ax
	mov         bl, USER_PAGE
	shl         bl, 1
	add         bl, 50h
	sub         bh, bh
	mov         ax, word ptr USER_CURSOR
	mov         es:[bx], ax
	mov         ax, word ptr USER_CUR_FORM
	mov         es:[60h], ax
	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@free_XMS
	mov         es, MAIN_WINDOW
	mov         ah, 49h
	int         21h
	cmp         USER_MODE, 3
 	jna         @@free_text
  	cmp         USER_MODE, 7
   	jz          @@free_text
	mov         es, USER_V_GRAPH
	mov         ah, 49h
	int         21h
	jmp         @@reinit_stack
@@free_text:
	mov         es, USER_V_TEXT
	mov         ah, 49h
	int         21h
	jmp         @@reinit_stack
@@free_XMS:
	push        MAIN_WIND_HANDLE
	call        XMS_FREE
	push        VTEXT_HANDLE
	call        XMS_FREE
	push        VGRAPH_HANDLE
	call        XMS_FREE
@@reinit_stack:

	mov	ah, 50h
	mov	bx, cs
	int	21h

	mov         es, OUR_SS           ; free stack area
	mov         ah, 49h
	int         21h

	mov	es, PROG_ENV
	mov	ah, 49h
	int	21h

	mov	es, WORK_AREA	; free work area
	mov         ah, 49h
	int         21h

	push        cs
	pop         es
	mov         ah, 49h
	int         21h

            mov	ax, 3301h		; Set original Ctrl-C
            mov	dl, CTRL_BREAK
            int	21h
	mov         ax, 4C00h
	int         21h
@@esc?:
	cmp         ah, 1
	jnz         @@up?
	call        MENU
	jmp	UNASS_WORK
@@up?:
	cmp         ah, 72                  ;Up arrow?
	jnz         @@home?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 3   ;Shift pressed?
	pop         ds
	jnz         @@dec_offs
	mov         bl, AC_WIND_ATTR
            mov	al, UPTR_LINE
            cmp	al, UNASS_TOP
	jz          @@go_up
            dec	UPTR_LINE
	jmp         @@up_01
@@go_up:
	call        UNASS_UP
@@up_01:
	jmp         UNASS_WORK
@@dec_offs:
	dec         UNASS_OFFS
	jmp         UNASS_WORK
@@home?:
	cmp	ah, 71
            jnz	@@end?
            mov	UNASS_OFFS, 0
            mov	al, UNASS_TOP
            mov	UPTR_LINE, al
            jmp	UNASS_WORK
@@end?:
	cmp	ah, 79
            jnz	@@tab?
            mov	al, UNASS_TOP
            mov	UPTR_LINE, al
            mov	UNASS_OFFS, 0
            mov	cl, UNASS_DOWN
            sub	cl, UNASS_TOP
            inc	cx
            sub	ch, ch
@@end_lp:
	push	cx
            call	UNASS_UP
            pop	cx
            loop	@@end_lp
            jmp	UNASS_WORK
            jnz	@@tab?
@@tab?:
	cmp         ah, 15                  ;tab ?
	jnz         @@down?
	push	ds
	sub	ax, ax
	mov	ds, ax
	test	byte ptr ds:[417h], 3	;shift?
	pop	ds
	jnz	@@sh_tab
	and         byte ptr PROG_STATUS[1], 11111100b
	inc         byte ptr PROG_STATUS[1]
	jmp         DUMP_WORK
@@sh_tab:
	or	byte ptr PROG_STATUS[1], 00000011b
	jmp	STACK_WORK
@@down?:
	cmp         ah, 80                  ;Down arrow?
	jnz         @@Ins?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 3   ;Shift pressed?
	pop         ds
	jnz         @@inc_off
            mov	al, UPTR_LINE
            cmp	al, UNASS_DOWN
            jz	@@add_offs
            inc	UPTR_LINE
            jmp	@@unass_add_OK
@@add_offs:
	push        UNASS_OFFS
	push        UNASS_SEG
	push        UNASS_OFFS
	mov         di, TEST_FIELD
	push        di
	sub         ax, ax
	mov         cx, 25
	cld
rep         stosw
	call        DASS
	mov         al, ds:[TEST_FIELD]
	cbw
	or          ax, ax
	jnz         $+3
	inc         ax
	add         UNASS_OFFS, ax
@@unass_add_OK:
	jmp         UNASS_WORK
@@inc_off:
	inc         UNASS_OFFS
	jmp         UNASS_WORK
@@Ins?:
	cmp         ah, 82                  ;Insert?
	jnz         @@Del?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 3   ;Shift?
	pop         ds
	jz          @F
	call        IMMEDIATE
	jmp         UNASS_WORK
@@:
	mov         cx, 256
	sub         di, di
@@cmp_loop:
	mov         ax, UNASS_PTR
	cmp         [di+BP_OFFS], ax
	jnz         @@cmp_next
	mov         ax, UNASS_SEG
	cmp         [di+BP_SEGS], ax
	jnz         @@cmp_next
	push        di
	shr         di, 1
	cmp         byte ptr [di+BP_SIGN], 0
	jnz         @@del_bp
	pop         di
@@cmp_next:
	inc         di
	inc         di
	loop        @@cmp_loop
	call        BREAK_HERE
	jmp         UNASS_WORK
@@del_bp:
	mov         byte ptr [di+BP_SIGN], 0
	shl         di, 1
	mov         word ptr [di+BP_SEGS], 0
	mov         word ptr [di+BP_OFFS], 0
	pop         di
	jmp         UNASS_WORK
@@Del?:
	cmp         ah, 83                  ;Delete-del all bkpts.
	jnz         @@Ctrl_left?
	call        DEL_BKPTS
	jmp         UNASS_WORK
@@Ctrl_left?:
	cmp         ah, 115                 ;Ctrl+left
	jnz         @@Ctrl_right?
	mov         si, USER_IP
	sub         si, 7
	mov         cx, 6
@@dec_IP_loop:
	inc         si
	push        si
	push        USER_CS
	push        si
	mov         di, TEST_FIELD
	push        di
	push        cx
	mov         cx, 25
	sub         ax, ax
	cld
rep         stosw
	pop         cx
	call        DASS
	mov         al, ds:[TEST_FIELD]
	cbw
	add         ax, si
	cmp         ax, USER_IP
	loopnz      @@dec_IP_loop
	jnz         @@sub_IP
	mov         USER_IP, si
	call	FILL_QUEUE		; Change IP register resets
				; CPU queue emulator
	jmp         UNASS_WORK
@@sub_IP:
	dec         USER_IP
	call	FILL_QUEUE		; Change IP register resets
				; CPU queue emulator
	jmp         UNASS_WORK
@@Ctrl_right?:
	cmp         ah, 116                 ;Ctrl+right
	jnz         @@PgUp?
	push        USER_IP
	push        USER_CS
	push        USER_IP
	mov         di, TEST_FIELD
	push        di
	mov         cx, 25
	sub         ax, ax
	cld
rep         stosw
	call        DASS
	mov         al, ds:[TEST_FIELD]
	cbw
	and         ax, ax
	jnz         $+3
	inc         ax
	add         USER_IP, ax
	call	FILL_QUEUE		; Change IP register resets
				; CPU queue emulator
	jmp         UNASS_WORK
@@PgUp?:
	cmp         ah, 73                  ;PgUp?
	jnz         @@PgDn?
	mov         cl, UNASS_DOWN
	sub         cl, UNASS_TOP
	sub         ch, ch
	inc         cx
	push        UNASS_OFFS
	pop         UNASS_PTR
@@PgUp_loop:
	push        cx
	call        UNASS_UP
	pop         cx
	loop        @@PgUp_loop
	jmp         UNASS_WORK
@@PgDn?:
	cmp         ah, 81                  ;PgDn?
	jnz         @@Space?
	mov         cl, UNASS_DOWN
	sub         cl, UNASS_TOP
	sub         ch, ch
	inc         cx
@@PgDn_loop:
	push        cx

	push        ax
	push        UNASS_SEG
	push        UNASS_OFFS
	mov         di, TEST_FIELD
	push        di
	mov         cx, 25
	sub         ax, ax
	cld
rep         stosw
	call        DASS
	mov         al, ds:[TEST_FIELD]
	cbw
	or          ax, ax
	jnz         $+3
	inc         ax
	add         UNASS_OFFS, ax
	pop         cx
	loop        @@PgDn_loop

	jmp         UNASS_WORK
@@Space?:
	cmp	ah, 57
            jnz	@@detect
            call	ASSM_HERE
	jmp	UNASS_WORK

@@detect:
	call	DETECT_KEY
	jmp	UNASS_WORK
UNASS_WORK  ENDP



DUMP_WORK   PROC
;locals
;jumps
	call	CHK_FNC
	mov         bh, OUR_PAGE
	mov         bl, AC_WIND_ATTR
	mov         HELP_CODE, 2
            call	REFRESH
	mov         al, -1
	push        ax
	call        SIGN_DUMP
	call	GETCH
	cmp         ah, 45                  ;ALT+'X'->exit
	jz          @@go_home?
	jmp         @@esc?
@@go_home?:
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@esc?
	jmp         go_home
@@esc?:
	cmp         ah, 1
	jnz         @@up?
	call        MENU
	jmp         DUMP_WORK
@@up?:
	cmp         ah, 72                  ;Up?
	jnz         @@down?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 3   ;Shift pressed?
	pop         ds
	jnz         @@dec_offs
	sub         al, al
	push        ax
	call        SIGN_DUMP
	sub         DUMP_PTR, 10h
            mov	al, DPTR_LINE
            cmp	al, DUMP_TOP
            jnz	@@dec_ptr
            sub	DUMP_OFFS, 10h
            jmp	@@up_OK
@@dec_ptr:
	dec	DPTR_LINE
@@up_OK:
	jmp         DUMP_WORK
@@dec_offs:
	dec         DUMP_OFFS
	dec         DUMP_PTR
	jmp         DUMP_WORK
@@down?:
	cmp         ah, 80                  ;down?
	jnz         @@home?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 3
	pop         ds
	jnz         @@inc_offs
	sub         al, al
	push        ax
	call        SIGN_DUMP
	add         DUMP_PTR, 10h
            mov	al, DPTR_LINE
            cmp	al, DUMP_BOTT
            jnz	@@inc_ptr
            add	DUMP_OFFS, 10h
            jmp	@@down_OK
@@inc_ptr:
	inc	DPTR_LINE
@@down_OK:
	jmp         DUMP_WORK
@@inc_offs:
	inc         DUMP_OFFS
	inc         DUMP_PTR
	jmp         DUMP_WORK
@@home?:
	cmp	ah, 71
            jnz	@@end?
            mov	DUMP_OFFS, 0
            mov	DUMP_PTR, 0
            mov	al, DUMP_TOP
            mov	DPTR_LINE, al
            jmp	DUMP_WORK
@@end?:
	cmp	ah, 79
            jnz	@@tab?
            mov	al, DUMP_TOP
            mov	DPTR_LINE, al
            mov	al, DUMP_BOTT
            sub	al, DUMP_TOP
            sub	ah, ah
            inc	ax
            shl	ax, 1
            shl	ax, 1
            shl	ax, 1
            shl	ax, 1
            neg	ax
            mov	DUMP_OFFS, ax
            mov	DUMP_PTR, ax
            jmp	DUMP_WORK
@@tab?:
	cmp         ah, 15                  ;tab?
	jnz         @@left?
	push	ds
	sub	ax, ax
	mov	ds, ax
	test	byte ptr ds:[417h], 3
	pop	ds
	jnz	@@sh_tab
	and         byte ptr PROG_STATUS[1], 11111100b
	add         byte ptr PROG_STATUS[1], 2
	jmp         REGS_WORK
@@sh_tab:
	and	byte ptr PROG_STATUS[1], 11111100b
	jmp	UNASS_WORK
@@left?:
	cmp         ah, 75                  ;Left?
	jnz         @@right?
	sub         al, al
	push        ax
	call        SIGN_DUMP
	mov         ax, DUMP_PTR
	cmp         ax, DUMP_OFFS
	jz          @@left_off
	mov	ax, DUMP_PTR
	sub	ax, DUMP_OFFS
	test	ax, 15
	jnz	@@stay_line01
	dec	DPTR_LINE
@@stay_line01:
	dec         DUMP_PTR
@@left_off:
	jmp         DUMP_WORK
@@right?:
	cmp         ah, 77                  ;Right?
	jnz         @@enter
	sub         al, al
	push        ax
	call        SIGN_DUMP
	mov         ax, DUMP_OFFS
	mov         cl, DUMP_BOTT
	sub         cl, DUMP_TOP
	sub         ch, ch
	inc         cx
@@right_loop:
	add         ax, 10h
	loop        @@right_loop
	dec         ax
	cmp         ax, DUMP_PTR
	jz          @@right_off
	inc         DUMP_PTR
            mov	ax, DUMP_PTR
            sub	ax, DUMP_OFFS
            test	ax, 15
            jnz	@@right_off
            inc	DPTR_LINE
@@right_off:
	jmp         DUMP_WORK
@@enter:
	cmp         ah, 1Ch
	jnz         @@PgUp?
;------------------------ Enter data at DUMP window -------------------------
	mov         dx, 010Ch
	mov	ax, DUMP_PTR
	sub	ax, DUMP_OFFS
	mov	si, ax
	and	ax, 0Fh		; AX=column
	mov	ah, al
	shl	ah, 1                   
	add	al, ah                  ; AL=AL*3
	add	dl, al		; DL=column
	mov	cl, 4
	shr	si, cl
	xchg	ax, si
	add	dh, al		; DL=row

	gotoxy
	mov         ax, 920h
	mov         cx, 2
	mov         bl, SELECT_ATTR
	int         10h
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX2
	jc          @@ent_off
	push        es
	push        di
	mov         di, DUMP_PTR
	mov         es, DUMP_SEG
	stosb
	pop         di
	pop         es
	call	FILL_QUEUE		; Fill CPU queue emul. buffer
@@ent_off:
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	jmp         DUMP_WORK
@@PgUp?:
	cmp         ah, 73                  ;PgUp?
	jnz         @@PgDn?
	mov         cl, DUMP_BOTT
	sub         cl, DUMP_TOP
	sub         ch, ch
	inc         cx
	shl         cx, 1
	shl         cx, 1
	shl         cx, 1
	shl         cx, 1
	sub         DUMP_OFFS, cx
	sub         DUMP_PTR, cx
	jmp         DUMP_WORK
@@PgDn?:
	cmp         ah, 81                  ;PgDn?
	jnz         @@detect
	mov         cl, DUMP_BOTT
	sub         cl, DUMP_TOP
	sub         ch, ch
	inc         cx
	shl         cx, 1
	shl         cx, 1
	shl         cx, 1
	shl         cx, 1
	add         DUMP_OFFS, cx
	add         DUMP_PTR, cx
	jmp         DUMP_WORK
@@detect:
	call	DETECT_KEY
            jmp	DUMP_WORK
DUMP_WORK   ENDP


SIGN_DUMP   PROC
;locals
;----------------------------------------------------------------------------
;                    Procedure signes DUMP_PTR location.
;                    [bp+4] - parameter: FF-sign, 0-unsign.
;----------------------------------------------------------------------------
	push        bp
	mov         bp, sp
            mov	al, DPTR_LINE
            sub	al, DUMP_TOP
	sub	ah, ah
            mov	cl, 4
            shl	ax, cl
            add	ax, DUMP_OFFS
@@chk_ptr:
         	cmp	ax, DUMP_PTR
            jz	@@proceed
            inc	ax
	jmp	@@chk_ptr
@@proceed:
	sub	ax, DUMP_OFFS
	and	ax, 0Fh
            mov	ah, 3
            mul	ah
            add	ax, 12
	mov	ah, DPTR_LINE
            push	ax
            inc	ax
	push	ax
            mov	ah, OUR_PAGE
            cmp	byte ptr [bp+4], 0
            jz	@@unsign
            mov	al, SELECT_ATTR
            jmp	@@do
@@unsign:
	mov	al, AC_WIND_ATTR
@@do:
	push	ax
            call	CHANGE_ATTRIBS
	pop         bp
	ret         2
SIGN_DUMP   ENDP


REGS_WORK   PROC
;locals
;jumps
	call	CHK_FNC
	mov         bh, OUR_PAGE
	mov         bl, AC_WIND_ATTR
	mov         HELP_CODE, 3
            call	REFRESH
	test	byte ptr PROG_STATUS, 4
	jnz	@@flags_work
	call	SEL_REG
	call	GETCH
	cmp         ah, 45                  ;ALT+'X'->exit
	jz          @@go_home?
	jmp         @@esc?
@@go_home?:
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@esc?
	jmp         go_home
@@esc?:
	cmp         ah, 1
	jnz         @@up?
	call        MENU
	jmp         REGS_WORK
@@up?:
	cmp         ah, 72                  ;Up?
	jnz         @@down?
	call        DESEL_REG
	cmp         REG_SELECTED, 0
	jz          @@AX_sel
	dec         REG_SELECTED
	jmp         REGS_WORK
@@AX_sel:
	mov         REG_SELECTED, 12
	jmp         REGS_WORK
@@down?:
	cmp         ah, 80                  ;Down?
	jnz         @@home?
	call        DESEL_REG
	cmp         REG_SELECTED, 12
	jz          @desel_IP
	inc         REG_SELECTED
	jmp         REGS_WORK
@desel_IP:
	mov         REG_SELECTED, 0
	jmp         REGS_WORK

@@flags_work:
	call        DESEL_REG
@@flags:
	test	byte ptr PROG_STATUS, 4
	jnz	@@fl_0
	sub         al, al
	push        ax
	call        SIGN_FLAG
	call	CHK_FNC
@@fl_0:
	mov         al, 1
	push        ax
	call        SIGN_FLAG
	call	GETCH
flags_entry:
	cmp         ah, 75                  ; Left?
	jnz         @@fl_X?
	sub         al, al
	push        ax
	call        SIGN_FLAG
	cmp         CURR_FL, 0
	jnz         @@fl_n0
	mov         CURR_FL, 7
	jmp         @@flags
@@fl_n0:
	dec         CURR_FL
	jmp         @@flags
@@fl_X?:
	cmp         ah, 45                  ;ALT+'X'->exit
	jz          @@fl_home?
	jmp         @@fl_esc?
@@fl_home?:
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@fl_esc?
	jmp         go_home
@@fl_esc?:
	cmp         ah, 1
	jnz         @@fl_right?
	call        MENU
	jmp         @@flags

@@fl_right?:
	cmp         ah, 77                  ; Right?
	jnz         @@fl_tab?
	sub         al, al
	push        ax
	call        SIGN_FLAG
	cmp         CURR_FL, 7
	jnz         @@fl_n7
	mov         CURR_FL, 0
	jmp         @@flags
@@fl_n7:
	inc         CURR_FL
	jmp         @@flags
@@fl_tab?:
	cmp         ah, 15                  ; tab?
	jnz	@@fl_up?
	push	ds
	sub	ax, ax
	mov	ds, ax
	test	byte ptr ds:[417h], 3
	pop	ds
	jnz	@@fl_sh_tab
	and	byte ptr PROG_STATUS[1], not 3
	or	byte ptr PROG_STATUS[1], 3
	and	byte ptr PROG_STATUS, not 4
	jmp	@@flags
@@fl_sh_tab:
	and	byte ptr PROG_STATUS, not 4
	jmp	@@flags
@@fl_up?:
	cmp	ah, 72		; up?
	jnz         @@fl_dn?
	sub         al, al
	push        ax
	call        SIGN_FLAG
	cmp         CURR_FL, 5
	jb          @@flags
	sub         CURR_FL, 5
	jmp         @@flags
@@fl_dn?:
	cmp         ah, 80                  ; Down?
	jnz         @@fl_spc?
	sub         al, al
	push        ax
	call        SIGN_FLAG
	cmp         CURR_FL, 2
	ja          @@flags
	add         CURR_FL, 5
	jmp         @@flags
@@fl_spc?:
	cmp         ah, 57
	jnz         @@fl_detect
	mov         cl, CURR_FL
	sub         ch, ch
	mov         ax, offset @@carry
	jcxz        @@jump
@@fl_loop:
	add         ax, @@one_l
	loop        @@fl_loop
@@jump:
	jmp         ax

@@carry:
	xor         USER_FL, 1
	nop
	jmp         @@fl_done

@@one_l     equ         $-@@carry

	xor         USER_FL, 4
	nop
	jmp         @@fl_done

	xor         USER_FL, 16
	nop
	jmp         @@fl_done

	xor         USER_FL, 64
	nop
	jmp         @@fl_done

	xor         USER_FL, 128
	jmp         @@fl_done

	xor         USER_FL, 512
	jmp         @@fl_done

	xor         USER_FL, 1024
	jmp         @@fl_done

	xor         USER_FL, 2048
	jmp         @@fl_done
	
@@fl_done:
	call        REGISTERS
	jmp         @@flags

@@fl_detect:
	call	DETECT_KEY
	jmp	@@flags

CURR_FL     DB          0



SIGN_FLAG   PROC
;locals
	push        bp
	mov         bp, sp
	mov         dl, 59
	mov         dh, 14
	mov         cx, 4
	mov         al, CURR_FL
	cmp         CURR_FL, 5
	jb          @@loop1
	inc         dh
	sub         al, 5
@@loop1:
	add         dl, al
	loop        @@loop1
	gotoxy      
	push        dx
	add         dl, 3
	push        dx
	cmp         byte ptr [bp+4], 0
	jnz         @@select
	mov         al, AC_WIND_ATTR
	jmp         @@do
@@select:
	mov         al, SELECT_ATTR
@@do:
	mov         ah, OUR_PAGE
	push        ax
	call        CHANGE_ATTRIBS
	pop         bp
	ret         2

SIGN_FLAG   ENDP



@@home?:
	cmp	ah, 71
            jnz	@@end?
            call	DESEL_REG
            mov	REG_SELECTED, 0
            jmp	REGS_WORK
@@end?:
	cmp	ah, 79
            jnz	@@tab?
            call	DESEL_REG
            mov	REG_SELECTED, 12
            jmp	REGS_WORK
@@tab?:
	cmp         ah, 15                  ;tab?
	jnz         @@enter?
	push	ds
	sub	ax, ax
	mov	ds, ax
	test	byte ptr ds:[417h], 3
	pop	ds
	jnz	@@sh_tab
	or	byte ptr PROG_STATUS, 4
	jmp         @@flags_work
@@sh_tab:
	and	byte ptr PROG_STATUS[1], 11111100b
	or	byte ptr PROG_STATUS[1], 00000001b
	jmp	DUMP_WORK
@@enter?:
	cmp         ah, 1Ch                 ;Enter?
	jnz         @@detect
	mov         al, REG_SELECTED
	cbw
	shl         ax, 1
	mov         @@ADDR, ax
	mov         si, ax
	mov         ax, word ptr REGISTS[si]
	mov         word ptr @@REG[1], ax
	$STO_SCREEN 25, 10, 55, 15, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 25, 10, 55, 15, MENU_ATTR
	mov         bl, MENU_ATTR
	gotoxy      35, 11
	mov         si, offset @@TTL
	mov         cx, @@TTL_L
	call        CPUTSTR
	gotoxy      27, 12
	mov         si, offset @@PROMPT
	mov         cx, @@PROMPT_L
	call        CPUTSTR
	gotoxy      27+@@PROMPT_L
	mov         si, offset @@REG
	mov         cx, 4
	mov         bl, SELECT_ATTR
	call        CPUTSTR
	gotoxy      40, 13
	mov         si, offset @@PR2
	mov         cx, @@PR2_L
	mov         bl, MENU_ATTR
	call        CPUTSTR
	gotoxy      38, 14
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jc          @@exit
	mov         si, @@ADDR

	lea	si, USER_AX[si]	; Changed register
	mov         [si], ax

	call	FILL_QUEUE
@@exit:
	$LOD_SCREEN 25, 10, 55, 15, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	jmp         REGS_WORK
@@detect:
	call	DETECT_KEY
            jmp	REGS_WORK


DESEL_REG   PROC
;locals
	cmp         REG_SELECTED, 6
	jnb         @@above_5
	mov         al, 59
	mov         ah, REG_SELECTED
	add         ah, 7
	jmp         short       @@desel_reg
@@above_5:
	cmp         REG_SELECTED, 12
	jz          @@IP_desel
	mov         al, 69
	mov         ah, REG_SELECTED
	inc         ah
	jmp         short       @@desel_reg
@@IP_desel:
	mov         ah, 13
	mov         al, 64
@@desel_reg:
	push        ax
	add         al, 9
	push        ax
	push        bx
	call        CHANGE_ATTRIBS
	ret
DESEL_REG   ENDP



SEL_REG     PROC
;locals
	cmp         REG_SELECTED, 6
	jnb         @@above_5a
	mov         al, 59
	mov         ah, REG_SELECTED
	add         ah, 7
	jmp         short       @@sel_reg
@@above_5a:
	cmp         REG_SELECTED, 12
	jz          @@IP_sel
	mov         al, 69
	mov         ah, REG_SELECTED
	inc         ah
	jmp         short       @@sel_reg
@@IP_sel:
	mov         ah, 13
	mov         al, 64
@@sel_reg:
	push        ax
	add         al, 9
	push        ax
	mov         al, SELECT_ATTR
	mov         ah, OUR_PAGE
	push        ax
	call        CHANGE_ATTRIBS
	ret
SEL_REG     ENDP



@@REG       DB          4 DUP (' ')
@@TTL       DB          'REGISTERS'
@@TTL_L     EQU         $-@@TTL
@@PROMPT    DB          'Input value for '
@@PROMPT_L  EQU         $-@@PROMPT
@@PR2       DB          ' register:'
@@PR2_L     EQU         $-@@PR2
@@ADDR      DW          ?

REGS_WORK   ENDP



STACK_WORK  PROC
;locals
;jumps
	call	CHK_FNC
	mov         bh, OUR_PAGE
	mov         bl, AC_WIND_ATTR
	mov         HELP_CODE, 4
            call	REFRESH
	call	GETCH
	cmp         ah, 45                  ;ALT+'X'->exit
	jz          @@go_home?
	jmp         @@esc?
@@go_home?:
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@esc?
	jmp         go_home
@@esc?:
	cmp         ah, 1
	jnz         @@up?
	call        MENU
	jmp         STACK_WORK
@@up?:
	cmp         ah, 72                  ;Up?
	jnz         @@down?
            mov	ax, STACK_PTR
            cmp	ax, STACK_OFFS
            jnz	@@add_ptr
	add         STACK_OFFS, 2
@@add_ptr:
	add	STACK_PTR, 2
	jmp         STACK_WORK
@@down?:
	cmp         ah, 80                  ;Down?
	jnz         @@home?
            mov	ax, STACK_PTR
            add	ax, 12
            cmp	ax, STACK_OFFS
            jnz	@@sub_ptr
	sub         STACK_OFFS, 2
@@sub_ptr:
	sub	STACK_PTR, 2
	jmp         STACK_WORK
@@home?:
	cmp	ah, 71
            jnz	@@end?
            mov	ax, USER_BP
            add	ax, 6
            mov	STACK_OFFS, ax
	mov	STACK_PTR, ax
            jmp	STACK_WORK
@@end?:
	cmp	ah, 79
            jnz	@@PgUp?
            mov	ax, USER_SP
            add	ax, 12
            mov	STACK_OFFS, ax
            mov	STACK_PTR, ax
            jmp	STACK_WORK
@@PgUp?:
	cmp	ah, 73
            jnz	@@PgDn?
            add	STACK_OFFS, 14
            add	STACK_PTR, 14
            jmp	STACK_WORK
@@PgDn?:
	cmp	ah, 81
            jnz	@@tab?
            sub	STACK_OFFS, 14
            sub	STACK_PTR, 14
            jmp	STACK_WORK
@@tab?:
	cmp         ah, 15                  ;tab?
	jnz         @@enter?
	push	ds
	sub	ax, ax
	mov	ds, ax
	test	byte ptr ds:[417h], 3
	pop	ds
	jnz	@@sh_tab
	and         byte ptr PROG_STATUS[1], 11111100b
	jmp         UNASS_WORK
@@sh_tab:
	and	byte ptr PROG_STATUS[1], 11111100b
	or	byte ptr PROG_STATUS[1], 00000010b
	or	byte ptr PROG_STATUS, 4
	jmp	REGS_WORK
@@enter?:
	cmp         ah, 28
	jnz         @@detect
	$STO_SCREEN 25, 10, 33+@@PROMPT_L, 14, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 25, 10, 33+@@PROMPT_L, 14, MENU_ATTR
	mov         bl, MENU_ATTR
	gotoxy      27, 11
	mov         si, offset @TTL
	mov         cx, @TTL_L
	call        CPUTSTR
	gotoxy      27, 12
	mov         si, offset @PROMPT
	mov         cx, @PROMPT_L
	call        CPUTSTR
            mov	ax, STACK_PTR
            call	CPUTHEX4
	gotoxy      47, 13
	wherexy
	and         ch, 10011111b
	mov         ah, 1
	int         10h
	call        CGETHEX4
	jc          @@exit
	push        es
	push        di
	mov         es, USER_SS
	mov         di, STACK_PTR
	stosw
	pop         di
	pop         es
	call	FILL_QUEUE		; Fill CPU queue emul. buffer
@@exit:
	$LOD_SCREEN 25, 10, 33+@@PROMPT_L, 14, SCREEN_BUF_1, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h
	jmp         STACK_WORK
@@detect:
	call	DETECT_KEY
            jmp	STACK_WORK


@TTL       	DB          'STACK MOVE'
@TTL_L     	EQU	$-@TTL
@PROMPT    	DB          'Input new value for SS:'
@PROMPT_L  	EQU         $-@PROMPT

STACK_WORK  ENDP



UNASS_UP    PROC
;locals
	push        bx
	mov         bx, UNASS_OFFS
	sub         bx, 7
	mov         cx, 6
@@loop:
	inc         bx
	push        cx
	mov         di, TEST_FIELD
	mov         cx, 50
	sub         al, al
	cld
rep         stosb
	pop         cx
	push        bx
	push        UNASS_SEG
	push        bx
	mov         ax, TEST_FIELD
	push        ax
	call        DASS
	push        bx
	add         bl, ds:[TEST_FIELD]
	adc         bh, 0
	cmp         bx, UNASS_OFFS
	pop         bx
	loopnz      @@loop
	jz          @@OK
            dec	bx
@@OK:
	mov         UNASS_OFFS, bx
	clc
	pop         bx
	ret
UNASS_UP    ENDP



CHK_SYS     PROC
;jumps
	mov         ah, 30h
	int         21h                     ;get DOS version
	mov         DOS_VER, ax
	cmp         al, 2
	jnb         _read_cfg
	ret
_read_cfg:
	call	Detect_CPU
	mov	ax, 3300h		; get Ctrl-C state
        int	21h
        mov	CTRL_BREAK, dl
        mov	al, 1		; disable Ctrl-C
        sub	dl, dl
        int	21h

	push	es
	mov	es, ds:[2Ch]	; Get enviroment string.
	sub	di, di
	sub	al, al
	cld
	mov	cx, -1
find_path:
		repne	scasb
	cmp	al, es:[di]
	jne	find_path
	add	di, 3
	mov	si, di
		repne	scasb
	std
	mov	al, '\'
		repne	scasb
	lea	cx, [di+2]
	sub	cx, si

	push	ds

	push	ds
	push	es
	pop	ds
	pop	es
	mov	di, offset INSP_PATH
	cld
		rep	movsb
	pop	ds
	mov	si, offset CFG_NAME
copy_cfg_name:
	lodsb
	stosb
	test	al, al
	jnz	copy_cfg_name
	pop	es

	QOPEN       INSP_PATH, 0
	jnc         _cfg_OK
	mov         dx, offset CFG_ERR
	mov         ah, 9
	int         21h
	mov         ax, 4CFFh
	int         21h
_cfg_OK:
	mov         CFG_NO, ax
	MOVE_PTR    CFG_NO, 0, CONFIG, 0
	QREAD       CFG_NO, TEXT_MODE_BUF, 4
	MOVE_PTR    CFG_NO, 0, 2, 1
	QREAD       CFG_NO, FLIP_STYLE, 1
_detect_video:
;	call	DETECT_CRT
;	mov	CRT_TYPE, al
	mov	ah, 0Fh
	int	10h
	cmp         al, 7
	jz          _mono
	cmp         al, 0Dh
	jb          _CGA
	jmp         _EGA
;------------------------- SetUp for Monochrome ----------------------------
_mono:
	mov         VTEXT_BUFFER, 0B000h
	mov         VGRAPH_BUFFER, 0B000h
	mov         OUR_PAGE, 0
	MOVE_PTR    CFG_NO, 0, 79, 0
	QREAD       CFG_NO, ATTRIB, 1
	QREAD       CFG_NO, SELECT_ATTR, 1
	QREAD       CFG_NO, AC_WIND_ATTR, 1
	QREAD       CFG_NO, TOP_ATTR, 1
	QREAD       CFG_NO, MENU_ATTR, 1
	QREAD       CFG_NO, ERR_ATTR, 1
	QREAD       CFG_NO, UNASS_PTR_ATTR, 1
	jmp         _machine
_CGA:
	mov         VTEXT_BUFFER, 0B800h
	mov         VGRAPH_BUFFER, 0B800h
	mov         OUR_PAGE, 3
	jmp         short       _read_clr
_EGA:
	mov         VTEXT_BUFFER, 0B800h
	mov         VGRAPH_BUFFER, 0A000h
	mov         OUR_PAGE, 3
_read_clr:
	MOVE_PTR    CFG_NO, 0, 72, 0
	QREAD       CFG_NO, ATTRIB, 1
	QREAD       CFG_NO, SELECT_ATTR, 1
	QREAD       CFG_NO, AC_WIND_ATTR, 1
	QREAD       CFG_NO, TOP_ATTR, 1
	QREAD       CFG_NO, MENU_ATTR, 1
	QREAD       CFG_NO, ERR_ATTR, 1
	QREAD       CFG_NO, UNASS_PTR_ATTR, 1
_machine:
	MOVE_PTR    CFG_NO, 0, 86, 0
	QREAD       CFG_NO, OUR_PAGE, 1
	QREAD       CFG_NO, UNASS_TOP, 1
	QREAD       CFG_NO, UNASS_DOWN, 1
	QREAD       CFG_NO, DUMP_TOP, 1
	QREAD       CFG_NO, DUMP_BOTT, 1
        QREAD	    CFG_NO, BREAK_INT, 1
	QCLOSE      CFG_NO
	push        es
	mov         ax, 0F000h
	mov         es, ax
	mov         al, es:[0FFFEh]
	mov         MACHINE, al
	pop         es
	mov         dx, offset RIGHT_MSG
	mov         ah, 9
	int         21h
            			; Get DOS memory state
            mov	ax, cs
            dec	ax
            mov	ds, ax
            sub	si, si
            mov	di, MCB
            mov	cx, 16
rep	movsb
	push	cs
            pop	ds

            sub	ax, ax
            int	33h		; MOUSE driver present?
            mov	MOUSE_STAT, al
	or	ax, ax
	jnz	@@set_mouse		; if present
	mov	MOUSE_EMUL, 0	; no kbd emulation avail.
            jmp	@@return
@@set_mouse:
            sub	cx, cx
            sub	dx, dx
            mov	ax, 4		; mouse pointer to top
            int	33h

            mov	ax, 1Dh
	mov	bl, OUR_PAGE	; set OUR_PAGE as mouse
	sub	bh, bh		; active page
	int	33h

	mov	ax, 0Ch		; set mouse event handler
	mov	cx, 7Fh		; all events
	mov	dx, offset MouseEvent	; ES:DX -> handler
	int	33h		; do

@@return:
            clc
	ret

CTRL_BREAK	DB	?
INSP_PATH	DB	64 DUP (0)
CFG_NAME    DB          'INSP.CFG', 0
CFG_ERR     DB          '  Cannot find configuration file.$'
CFG_NO      DW          ?
RIGHT_MSG   DB          '  White & Black Phantoms Executing INSPECTOR. Version 1.1', 0Dh, 0Ah
	DB          '  Copyright (c) Drubetsky VADIM, Voikhansky ARTEMY, 1993/1994', 13, 10
	DB	'  Middle East.', 0Dh, 0Ah, '$'

CHK_SYS     ENDP



INSTALL_VECTORS PROC
;----------------------------------------------------------------------------
;           This routine changes several interrupt vectors for
;                          internal purposes.
;----------------------------------------------------------------------------

	push        es
	push        bx
	push        dx
;------------------------------ INT 1 vector --------------------------------
	mov         ax, 3501h
	int         21h
	mov         ORIG_INT1, bx
	mov         ORIG_INT1[2], es
	mov         ax, 2501h
	mov         dx, offset int1entry
	int         21h
;------------------------------ INT 3 vector --------------------------------
	mov         ah, 35h
	mov	al, BREAK_INT
	int         21h
	mov         ORIG_INT3, bx
	mov         ORIG_INT3[2], es
	mov         dx, offset int3entry
	mov         ah, 25h
	mov	al, BREAK_INT
	int         21h
;------------------------------ INT 6 vector --------------------------------
	mov         ax, 3506h
	int         21h
	mov         ORIG_INT6, bx
	mov         ORIG_INT6[2], es
	mov         dx, offset INT_6
	mov         ax, 2506h
	int         21h
;------------------------------- INT 10 vector ------------------------------
	mov         ax, 3510h
	int         21h
	mov         ORIG_INT10, bx
	mov         ORIG_INT10[2], es
	mov         ax, 2510h
	mov         dx, offset INT_10
	int         21h
;------------------------------- INT 20 vector ------------------------------
	mov         ax, 3520h
	int         21h
	mov         ORIG_INT20, bx
	mov         ORIG_INT20[2], es
	mov         ax, 2520h
	mov         dx, offset int20entry
	int         21h
;------------------------------- INT 21 vector ------------------------------
	mov         ax, 3521h
	int         21h
	mov         INT_21, bx
	mov         INT_21[2], es
	mov         ax, 2521h
	mov         dx, offset END_PROG
	int         21h
;------------------------------ INT 24 vector -------------------------------
	mov         ax, 3524h
	int         21h
	mov         ORIG_INT24, bx
	mov         ORIG_INT24[2], es
	mov         dx, offset INT_24
	mov         ax, 2524h
	int         21h
;------------------------------ INT 27 vector -------------------------------
	mov         ax, 3527h
	int         21h
	mov         ORIG_INT27, bx
	mov         ORIG_INT27[2], es
	mov         dx, offset int27entry
	mov         ax, 2527h
	int         21h

	pop         dx
	pop         bx
	pop         es
	ret
INSTALL_VECTORS ENDP


ORIG_INT1   DW          2 DUP (?)
ORIG_INT3   DW          2 DUP (?)
ORIG_INT6	DW	2 DUP (?)
ORIG_INT20  DW          2 DUP (?)
ORIG_INT24  DW          2 DUP (?)


REINSTALL_VECTORS PROC
;----------------------------------------------------------------------------
;           This routine re-installs all interrupt vectors
;           set by the previous routine.
;----------------------------------------------------------------------------
	push        ds
	push        dx
;----------------------------- INT 1 vector ---------------------------------
	mov         ax, 2501h
	lds         dx, dword ptr cs:ORIG_INT1
	int         21h
;----------------------------- INT 3 vector ---------------------------------
	mov         ah, 25h
	mov	al, cs:BREAK_INT
	lds         dx, dword ptr cs:ORIG_INT3
	int         21h
;----------------------------- INT 6 vector ---------------------------------
	mov         ax, 2506h
	lds         dx, dword ptr cs:ORIG_INT6
	int         21h
;----------------------------- INT 10 vector --------------------------------
	mov         ax, 2510h
	lds         dx, dword ptr cs:ORIG_INT10
	int         21h
;----------------------------- INT 20 vector --------------------------------
	mov         ax, 2520h
	lds         dx, dword ptr cs:ORIG_INT20
	int         21h
;----------------------------- INT 21 vector --------------------------------
	mov         ax, 2521h
	lds         dx, dword ptr cs:INT_21
	int         21h
;----------------------------- INT 24 vector --------------------------------
	mov         ax, 2524h
	lds         dx, dword ptr cs:ORIG_INT24
	int         21h
;----------------------------- INT 27 vector --------------------------------
	mov         ax, 2527h
	lds         dx, dword ptr cs:ORIG_INT27
	int         21h

	pop         dx
	pop         ds
	ret
REINSTALL_VECTORS ENDP


PREPARE_VECTORS  PROC
	push        ds
	push        dx
;----------------------------- INT 10 vector --------------------------------
	lds         dx, dword ptr ORIG_INT10
	mov         ax, 2510h
	int         21h
;----------------------------- INT 24 vector --------------------------------
	mov         ax, 2524h
	lds         dx, dword ptr cs:ORIG_INT24
	int         21h

	pop         dx
	pop         ds
	ret
PREPARE_VECTORS  ENDP


LOAD_VECTORS  PROC
	push        dx
;------------------------------ INT 24 vector -------------------------------
	mov         dx, offset INT_24
	mov         ax, 2524h
	int         21h
;------------------------------ INT 10 vector -------------------------------
	mov         dx, offset INT_10
	mov         ax, 2510h
	int         21h

	pop         dx
	ret
LOAD_VECTORS  ENDP



CHK_ARGS    PROC
;----------------------------------------------------------------------------
;                       Check command-line arguments.
;----------------------------------------------------------------------------
;locals
;jumps
	cmp         byte ptr ds:[80h], 0
	jz          @@quit
	cld
	mov         si, 81h
	mov         di, FILE_NAME
	push        di
	sub         al, al
	mov         cx, 63
rep         stosb
	pop         di
@@chk_spc:
	lodsb			; skip spaces
	cmp	al, 0dh		; if Enter ->
	jz	@@quit		;  quit
	cmp         al, ' '
	jna         @@chk_spc
	call	CHK_SWITCH		; check if switch '*'
	dec         si
	cmp	al, 0dh
	jz          @@quit
@@move_loop:
	lodsb
	cmp         al, 0dh
	jz          @@exit_move
	cmp	al, ' '
	jna         @@chk_spc2
	stosb
	jmp         @@move_loop
@@chk_spc2:
	cmp         byte ptr [si], 0dh
	jz          @@exit_move
	cmp	byte ptr [si], ' '
	jna         @@st_got
	inc         si
	jmp         @@chk_spc2
@@st_got:
	mov         di, COM_LINE+2
	mov         word ptr ds:[COM_LINE], 2001h
@@args_loop:
	lodsb
	stosb
	cmp         al, 0dh
	jz          @@exit_move
	inc         byte ptr ds:[COM_LINE]
	jmp         @@args_loop
@@exit_move:

	mov	es, WORK_AREA
            mov	ah, 49h
	int	21h
            push	cs
            pop	es
	mov         ax, FILE_NAME
	push        ax
	mov         ax, 63
	push        ax
	call        UPCASE
            push	bx
	mov         ax, FILE_NAME
	push        ax
	call        LOAD_FILE
            pop	bx
	jc          @@exit
	mov         ax, USER_SP
	add         ax, 12
	mov         STACK_OFFS, ax
            call	REFRESH
	GOTOXY      64, 24
	mov         si, offset LD_MODULE
	mov         cx, 12
	mov         bl, TOP_ATTR
	call        CPUTSTR
	clc
	retn
@@exit:
	mov         ERRORCODE, ax
	add         ERRORCODE, 2
	call        ERR_HANDLER
            mov	ah, 48h
            mov	bx, 1000h
            int	21h
            mov	WORK_AREA, ax
            mov	UNASS_SEG, ax
            mov	DUMP_SEG, ax
            mov	USER_CS, ax
            mov	USER_DS, ax
            mov	USER_ES, ax
            mov	USER_SS, ax
@@quit:
	stc
	retn
CHK_ARGS    ENDP


CHK_SWITCH	PROC
	cmp	al, '*'		; switch char.
	jz	@F		; if not - return
loc_lp:
	cmp	al, 0dh
	jz	to_ret
	cmp	al, ' '
	ja	to_ret
	lodsb
	jmp	loc_lp
@@:
	lodsb
	cmp	al, 0dh
	jz	to_ret
	cmp	al, ' '
	jna	@B
	cmp	al, 'b'		; 'b'
	jz	@F
	cmp	al, 'B'		; or 'B' : user-specified
	jnz	next		; software bkpt.
@@:
	lodsb
	cmp	al, 0dh
	jz	to_ret
	cmp	al, ' '		; skip spaces
	jna	@B
	cmp	al, '0'		; switch usage:
	jb	to_ret		; b34 to set software
	cmp	al, '9'		; break at int 34
	mov	ah, '0'
	jna	@F
	cmp	al, 'A'
	jb	to_ret
	cmp	al, 'F'
	mov	ah, 'A'-10
	jna	@F
	cmp	al, 'a'
	jb	to_ret
	cmp	al, 'f'
	mov	ah, 'a'-10
	ja	to_ret
@@:
	sub	al, ah
	mov	cl, 4
	shl	al, cl
	mov	ch, al
	lodsb
	cmp	al, '0'
	jb	to_ret
	cmp	al, '9'
	mov	ah, '0'
	jna	@F
	cmp	al, 'A'
	jb	to_ret
	cmp	al, 'F'
	mov	ah, 'A'-10
	jna	@F
	cmp	al, 'a'
	jb	to_ret
	cmp	al, 'f'
	mov	ah, 'a'-10
	ja	to_ret
@@:
	sub	al, ah
	add	al, ch
	mov	BREAK_INT, al
@@:
	lodsb
	cmp	al, 0dh
	jz	to_ret
	cmp	al, ' '
	jna	@B
	jmp	to_ret
next:
to_ret:
	retn

CHK_SWITCH	ENDP


PRINT_HELLO  PROC
;locals
	mov	bh, OUR_PAGE
	$STO_SCREEN 5, 10, 70, 17, SCREEN_BUF_2, OUR_PAGE
	$LITTLE_FRAME 5, 10, 70, 17, MENU_ATTR
	mov         bl, MENU_ATTR
	mov	dh, 11
	mov         si, offset @@HELLO
@@:
	GOTOXY      7
	mov         cx, 100
	call        CPUTSTR
	add	si, cx
	inc	si
	inc	dh
	cmp	si, offset @@HELLO+@@HELLO_L
	jb	@B

	GOTOXY
	mov	si, offset BKPTSTR2
	mov	cx, 30
	call	CPUTSTR
@@loop:
	sub	ah, ah
	int	16h
            or	al, al
	jz	@@loop
	$LOD_SCREEN 5, 10, 70, 17, SCREEN_BUF_2, OUR_PAGE
	REPORT_BKPT
	retn

@@HELLO    	DB          'White & Black Phantoms Executing INSPECTOR. Version 1.1', 0
	DB	'Copyright (c) Drubetsky VADIM & Voikhansky ARTEMY, 1993/1994', 0
	DB	'                       Middle East', 0
	DB          'White & Black Phantoms wish You all the best in programming', 0
	DB          'to be optimist and believe in future just like we do.', 0

@@HELLO_l	equ	$-@@HELLO

BKPTSTR1	db	'Software BreakPoint installed'
BKPTSTRL	equ	$-BKPTSTR1
	db	'   at INT ', 0
BKPTSTR2	db	' Press any key . . .', 0
BKPTSTD	db	' (default)', 0

PRINT_HELLO  ENDP


DETECT_KEY	PROC
;locals
;
;	detects main INSPECTOR command keys.
;

@@L?:
	cmp         ah, 38                  ;'L' pressed ?
	jnz         @@S?
	call        LOAD
	retn
@@S?:
	cmp         ah, 31                  ;'S'?
	jnz         @@C?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 4
	jnz         @@rep_str
	test        byte ptr ds:[417h], 8
	pop         ds
	jnz         @@find_str
	call        SAVE
	retn
@@rep_str:
	pop         ds
	mov         al, 1
	push        ax
	call        FIND_STRING
	retn
@@find_str:
	sub         al, al
	push        ax
	call        FIND_STRING
	retn
@@C?:
	cmp         ah, 46                  ;'C'?
	jnz         @@D?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@cd
	call        COMPARE
	retn
@@cd:
	call        CHANGE_DIR
	retn
@@D?:
	cmp         ah, 32                  ;'D'?
	jnz         @@U?
	call        VIEW_DUMP
	retn
@@U?:
	cmp         ah, 22                  ;'U'?
	jnz         @@A?
	call        VIEW_UNASS
	retn
@@A?:
	cmp         ah, 30                  ;'A'?
	jnz         @@I?
	call        ASSM
	retn
@@I?:
	cmp         ah, 23                  ;'I'?
	jnz         @@O?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jnz         @@fill_fr_port
	call        IN_PORT
	retn
@@fill_fr_port:
	call        FILL_FR_PORT
	retn
@@O?:
	cmp         ah, 24                  ;'O'?
	jnz         @@V?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8
	pop         ds
	jnz         @@fill_port
	call        OUT_PORT
	retn
@@fill_port:
	call        FILL_PORT
	retn
@@V?:
	cmp         ah, 47                  ;'V'?
	jnz         @@M?
	call        VIEW_SCREEN
	retn
@@M?:
	cmp         ah, 50                  ;'M'?
	jnz         @@R?
	call        MOVE
	retn
@@R?:
	cmp         ah, 19                  ;'R'?
	jnz         @@W?
	call        READ
	retn
@@W?:
	cmp         ah, 17                  ;'W'?
	jnz         @@E?
	mov         al, 1
	push        ax
	call        SECTORS
	retn
@@E?:
	cmp         ah, 18                  ;'E'?
	jnz         @@B?
	call        ENTER_DATA
	retn
@@B?:
	cmp         ah, 48                  ;'B'?
	jnz         @@N?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 4
	jnz         @@rep_byte
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@next
	sub         al, al
	push        ax
	call        FIND_BYTE
	retn
@@rep_byte:
	pop         ds
	mov         al, 1
	push        ax
	call        FIND_BYTE
	retn
@@N?:
	cmp         ah, 49                  ;'N'?
	jnz         @@F1?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 4
	jnz         @@rep_instr
	test        byte ptr ds:[417h], 8
	pop         ds
	jz          @@next
	sub         al, al
	push        ax
	call        FIND_INSTR
	retn
@@rep_instr:
	pop         ds
	mov         al, 1
	push        ax
	call        FIND_INSTR
	retn
@@F1?:
	cmp         ah, 59                  ;F1?
	jb          @@P?
	cmp         ah, 63                  ;F5?
	ja          @@P?
	sub         ah, 58
	mov         MAIN_MENU, ah
            or	byte ptr PROG_STATUS, 1
	call        MENU
	retn
@@P?:
	cmp         ah, 25                  ; 'P'?
	jnz         @@F8?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 8   ; Alt?
	pop         ds
	jz          @@P_no
	call        COPY
@@P_no:
	retn
@@F8?:
	cmp         ah, 66                  ;F8?
	jnz         @@F9?
	call        SINGLE_STEP
	retn
@@F9?:
	cmp         ah, 67                  ;F9?
	jnz         @@G?
	call        TRACE
	retn
@@G?:
	cmp         ah, 34
	jnz         @@ins?
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 4   ; Ctrl?
	pop         ds
	jnz         @@until
	call        RUN
	retn
@@until:
	call        GO_UNTIL
	retn
@@ins?:
	cmp         ah, 82
	jnz         @@next
	push        ds
	sub         ax, ax
	mov         ds, ax
	test        byte ptr ds:[417h], 3   ; Shift?
	pop         ds
	jz          @@next
	call        IMMEDIATE
@@next:
	retn
DETECT_KEY	ENDP


CHK_FNC	PROC
;jumps
	pop	ax
	mov	al, byte ptr PROG_STATUS[1]
	and	al, 3
	or	al, al
	jz	UNASS_WORK+3
	cmp	al, 1
	jz	DUMP_WORK+3
	cmp	al, 2
	jz	REGS_WORK+3
	jmp	STACK_WORK+3
CHK_FNC	ENDP


DETECT_CRT	PROC
;locals
	sub	ax, ax
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 0
	jz	@@col
	mov	al, 1
	retn
@@col:
	mov	ax, 13h
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 13h
	jz	@@mcgavga
	mov	ax, 0Dh
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 0Dh
	jz	@@ega
	mov	al, 0
	retn
@@ega:
	mov	al, 2
	retn
@@mcgavga:
	mov	ax, 0Dh
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 0Dh
	mov	al, 3
	jnz	$+3
	inc	ax
	retn

DETECT_CRT	ENDP

	INCLUDE PHANT.PRC
	include frame.asm
	include dump.asm
	include regs.asm
	include stack.asm
	include dass.asm
	include unass.asm
	include chdir.asm
	include sectors.asm
	include menu.asm
	include funct.asm
	include asm1.goo
	include breaks.asm
	include xmem.asm
	include loadf.asm
	include ints.asm
	include errors.asm
	include int24.asm
	include keys.asm
	include mouse.asm
	include video.asm
	include vfile.asm
	include vdisk.asm
	include print.asm
	include savef.asm
	include queue.asm

; DATA      AREA

	DOS_VER     DW          ?
	TEXT_MODE_BUF DW        ?
	GRAPH_MODE_BUF DW       ?
	VTEXT_BUFFER  DW        ?
	VGRAPH_BUFFER  DW       ?
	MACHINE     DB          ?
	MAIN_WINDOW DW          ?

	CRT_TYPE	DB	?	;Inspector types: 0=CGA
				; 1=MDA, 2=EGA, 3=MCGA, 4=VGA
	USER_MODE   DB          ?
	USER_PAGE   DB          0
	USER_CURSOR  DB         2 DUP (?)
	USER_CUR_FORM  DB       2 DUP (?)
	USER_V_GRAPH  DW        ?
	USER_V_TEXT  DW         ?

	VGRAPH_HANDLE DW        ?
	VTEXT_HANDLE DW         ?
	MAIN_WIND_HANDLE DW     ?

            OUR_MODE	DB	?
	OUR_PAGE    DB          ?
	ATTRIB      DB          0Bh
	MENU_ATTR   DB          0B0h
	SELECT_ATTR  DB         0CBh
	AC_WIND_ATTR  DB        1Bh
	UNASS_PTR_ATTR DB       0B1h
	ERR_ATTR    DB          0Ch
	NO_MODULE   DB          'NONE', 9 DUP (' ')
	LD_MODULE   DB          13 DUP (' ')
	PROG_STATUS DW          0
	OPTIONS     DW          0
            MOUSE_STAT	DB	0
            MOUSE_EMUL	DB	?	; kbd emulation: 0=disabled
            MOUSE_LEFT	DW	?	; left button emulates scan
            MOUSE_RIGHT	DW	?	; right button emulates scan
	HELP_CODE   DB          ?
	ACT_PRN     DW          0
	FLIP_STYLE  DB          ?

	WORK_AREA   DW          0
            ENVIRON	DW	?
	N           DB          'Registers'
	NAMELEN     EQU         $-N
	N1          DB          'Stack'
	N1len       DB          $-N1
	Y           DB          ?
	STATUS      DW          ?           ; program status word
	SELECTED    DB          ?
	OUR_AX      DW          ?
	OUR_BX      DW          ?
	OUR_CX      DW          ?
	OUR_DX      DW          ?
	OUR_BP      DW          ?
	OUR_SP      DW          ?
	OUR_SI      DW          ?
	OUR_DI      DW          ?
	OUR_CS      DW          ?
	OUR_DS      DW          ?
	OUR_ES      DW          ?
	OUR_SS      DW          ?
	OUR_IP      DW          ?
	OUR_FL      DW          ?
	REG_SELECTED  DB        0
	BREAKS      DW          ?
	OUR_BREAK_SEG  DW       ?
	OUR_BREAK_OFF  DW       ?
	OUR_BREAK_BYTE  DB      ?

	DUMP_SEG    DW          ?           ; segment address for dump
	DUMP_OFFS   DW          0           ; offset for -"-
	DUMP_PTR    DW          0
	DUMP_TOP    DB          ?
	DUMP_BOTT   DB          ?
            DPTR_LINE	DB	?

	UNASS_SEG   DW          ?           ; segment address for dass
	UNASS_OFFS  DW          100h        ; offset for -"-
	UNASS_PTR   DW          100h
            UPTR_LINE	DB	?
	UNASS_PREV  DW          ?
	UNASS_BOTT  DW          ?           ; offset for next page
	UNASS_LEFT  DB          1
	UNASS_TOP   DB          ?
	UNASS_RIGHT DB          57
	UNASS_DOWN  DB          ?

	FILE_NO     DW          ?
	FILE_LEN    DW          2 DUP (0)

	DUMP_TTL    DB          'DUMP'
	DUMP_PROMPT1  DB        'Segment:'
	DUMP_PROMPT1_L  EQU     $-DUMP_PROMPT1
	DUMP_PROMPT2  DB        'Offset:'
	DUMP_PROMPT2_L  EQU     $-DUMP_PROMPT2
	UNASS_TTL   DB          'UNASSEMBLE'
	UNASS_TTL_L  EQU        $-UNASS_TTL
	INPORT_TTL  DB          'IN PORT'
	OUTPORT_TTL  DB         'OUT PORT'
	PORT_PROMPT1  DB        'Port:'
	PORT_PROMPT2  DB        'Value:'
	MOVE_TTL    DB          'MOVE'
	MOVE_TTL_L  EQU         $-MOVE_TTL
	READ_TTL    DB          'READ SECTOR'
	READ_TTL_L  EQU         $-READ_TTL
	WRITE_TTL   DB          'WRITE SECTOR'
	WRITE_TTL_L  EQU        $-WRITE_TTL
	SECT_PROMPT  DB         'Number:'
	SECT_PROMPT_L  EQU      $-SECT_PROMPT
	FILL_TTL    DB          'FILL MEMORY'
	FILL_TTL_L  EQU         $-FILL_TTL
	DEBUG_ERR	DB	"%s, Inspector is not for work under debuggers. . ."
	DB	0Dh, 0Ah, '$'


;DATA AREA-2            
	BP_BYTE     EQU         $-_BEGIN_		;256 b.
	BP_SEGS     EQU         BP_BYTE+256             ;512 b.
	BP_OFFS     EQU         BP_SEGS+512             ;512 b.
	BP_SIGN     equ         BP_OFFS+512		;256 b.
            MCB	EQU	BP_SIGN+256		;16 b.
	TEST_FIELD  EQU         MCB+16
	FILE_NAME   EQU         TEST_FIELD+100
	VFILE_NAME  EQU         FILE_NAME+63
	SCREEN_BUF_1  EQU       VFILE_NAME+63
	SCREEN_BUF_2  EQU       SCREEN_BUF_1+1024
	VIEW_FILE_BUF EQU       SCREEN_BUF_2+3072
	SCR_ERR_BUF  EQU        VIEW_FILE_BUF+16
	CURR_DIR    EQU         SCR_ERR_BUF+156
	DIR_BUF     EQU         CURR_DIR+64
	INSTR_BUF   EQU         DIR_BUF+64              ;for assm. 100 b.
	COM_LINE    EQU         INSTR_BUF+100
	INT_INFO    EQU         COM_LINE+128            ;for int. info
					;1024/2048 bytes
	HELP_BUF    EQU         INT_INFO+1024
	INSP_SIZE	EQU	HELP_BUF+1024	; 2048=ENVIRON. SIZE
	DSK_DUMP_BUF  EQU	INT_INFO
	DSK_UNASS_BUF EQU       DSK_DUMP_BUF+1024


CODE        ENDS
END         _START
