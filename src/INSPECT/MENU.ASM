MENU        PROC
;jumps
;jumps
;----------------------------------------------------------------------------
;                       Draw & issue menu
;----------------------------------------------------------------------------
	mov	CHOISE, 0
            mov	al, MAIN_MENU
            dec	ax
            mov	ah, 12
            mul	ah
            mov	si, ax
            add	si, offset FILE_MENU	;SI->base menu address
;
;		menu is closed.
;
	mov	al, [si+6]
	mov	HELP_CODE, al
            $CHANGE_ATTRIBS [si], 0, [si+1], 0, SELECT_ATTR
            cmp	byte ptr [si+4], 1
            jz	@@nopen_kbd
	test	byte ptr PROG_STATUS, 1
            jnz	@@menu_open
@@nopen_kbd:
	call	GETCH
            cmp	ah, 1
            jnz	@@F1?
@@exit:
	$CHANGE_ATTRIBS 3, 0, 71, 0, TOP_ATTR
@@quit:
	and         byte ptr PROG_STATUS, 11111110b
            mov	CHOISE, 0
	mov         MAIN_MENU, 1
	ret
@@F1?:
	cmp	ah, 59
            jb	@@left?
            cmp	ah, 63
            ja	@@left?
            cmp	ah, 62
            jz	@@F4
            sub	ah, 58
	mov	MAIN_MENU, ah
            jmp	@@sycle
@@F4:
	mov	si, offset PRINT_MENU
            jmp	nowindow_entry
@@left?:
	cmp	ah, 75
            jnz	@@right?
@@left:
            cmp	MAIN_MENU, 1
            jnz	@@dec_menu
            mov	MAIN_MENU, 6
@@sycle:
            $CHANGE_ATTRIBS [si], 0, [si+1], 0, TOP_ATTR
            jmp	MENU
@@dec_menu:
	dec	MAIN_MENU
            jmp	@@sycle
@@right?:
	cmp	ah, 77
            jnz	@@open?
@@right:
            cmp	MAIN_MENU, 6
            jnz	@@inc_menu
            mov	MAIN_MENU, 1
	jmp	@@sycle
@@inc_menu:
	inc	MAIN_MENU
            jmp	@@sycle
@@open?:
	cmp	ah, 28
            jnz	@@up?
            cmp	byte ptr [si+4], 1
            jnz	@@menu_open
nowindow_entry:
            $CHANGE_ATTRIBS 3, 0, 71, 0, TOP_ATTR
            mov	al, [si+5]
            push	ax
            call	PERFORM
            jmp	@@quit
@@up?:
            cmp	ah, 72
            jz	@@menu_open
            cmp	ah, 80
            jnz	@@nopen_kbd
@@menu_open:
	cmp	byte ptr [si+4], 1
            jz	@@nopen_kbd
            or	byte ptr PROG_STATUS, 1
	mov	dl, [si+4]
            add	dl, 2
            $STO_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
            $DRAW_MENU	[si+2], 1, [si+3], dl, [si+8], [si+10], MENU_ATTR
@@open_kbd:
	mov	ah, CHOISE
            add	ah, [si+7]
            mov	HELP_CODE, ah
            sub	ah, [si+7]
            add	ah, 2
            mov	dl, [si+2]
            mov	dh, [si+3]
            inc	dx
            dec	dh
            $CHANGE_ATTRIBS dl, ah, dh, ah, SELECT_ATTR
	call	GETCH
            cmp	ah, 1
            jnz	@@op_F4?
	mov	dl, [si+4]
            add	dl, 2
            $LOD_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
            jmp	@@exit
@@op_F4?:
	cmp	ah, 62
            jnz	@@Fx?
	mov	dl, [si+4]
            add	dl, 2
            $LOD_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
	jmp	@@F4
@@op_Fx_sycle:
	mov	dl, [si+4]
            add	dl, 2
            $LOD_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
            $CHANGE_ATTRIBS 3, 0, 71, 0, TOP_ATTR
            jmp	MENU
@@Fx?:
	cmp	ah, 59
            jb	@@op_left?
            cmp	ah, 63
            ja	@@op_left?
            sub	ah, 58
            mov	MAIN_MENU, ah
            jmp	@@op_Fx_sycle
@@op_left?:
	cmp	ah, 75
            jnz	@@op_right?
	mov	dl, [si+4]
            add	dl, 2
            $LOD_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
            jmp	@@left
@@op_right?:
	cmp	ah, 77
            jnz         @@op_up?
	mov	dl, [si+4]
            add	dl, 2
	$LOD_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
            jmp	@@right
@@op_up?:
            cmp	ah, 72
            jnz	@@op_down?
            mov	ah, CHOISE
            add	ah, 2
            mov	dl, [si+2]
            mov	dh, [si+3]
            inc	dx
            dec	dh
            $CHANGE_ATTRIBS dl, ah, dh, ah, MENU_ATTR
            cmp	CHOISE, 0
            jnz	@@dec_choise
            mov	al, [si+4]
            dec	ax
            mov	CHOISE, al
            jmp         @@open_kbd
@@dec_choise:
	dec	CHOISE
            jmp	@@open_kbd
@@op_down?:
	cmp	ah, 80
            jnz	@@op_enter?
            mov	ah, CHOISE
            add	ah, 2
            mov	dl, [si+2]
            mov	dh, [si+3]
            inc	dx
            dec	dh
            $CHANGE_ATTRIBS dl, ah, dh, ah, MENU_ATTR
	mov	al, [si+4]
            dec	ax
            cmp	CHOISE, al
            jnz	@@inc_choise
            mov	CHOISE, 0
            jmp	@@open_kbd
@@inc_choise:
	inc	CHOISE
            jmp	@@open_kbd
@@op_enter?:
	cmp	ah, 28
            jnz	@@open_kbd
menu_entry:
	mov	dl, [si+4]
            add	dl, 2
            $LOD_SCREEN	[si+2], 1, [si+3], dl, SCREEN_BUF_1, OUR_PAGE
            $CHANGE_ATTRIBS 3, 0, 71, 0, TOP_ATTR
	mov	al, CHOISE
            add	al, [si+5]
            push	ax
            call	PERFORM
            jmp	@@quit

MAIN_MENU   DB          1

FILE_MENU	DB	3, 12	  	; Highlighted left, right
	DB	1, 18		; Left, right of menu bar
            DB	6		; number or items
            DB	0		; Base choise code
            DB	9, 14		; Base help codes
            DW	FILE_CHOISE		; start addr. for items
            DW	FILE_CHOISE_L	; length of items

TOOLS_MENU	DB	13, 23, 12, 16+TOOLS_CHOISE_L, 11, 6, 10, 20
	DW	TOOLS_CHOISE, TOOLS_CHOISE_L

SPEC_MENU	DB	24, 37, 23, 50, 10, 17, 11, 31
	DW	SPECIAL_CHOISE, SPECIAL_CHOISE_L

PRINT_MENU 	DB	38, 48, 0, 0, 1, -1, 12, 0
	DW	0, 0

DEBUG_MENU	DB	49, 59, 37, 62, 8, 27, 13, 41
	DW	DEBUG_CHOISE, DEBUG_CHOISE_L

HELP_MENU   DB	60, 71, 0, 0, 1, 35, 49, 0
	DW	0, 0

MENU        ENDP



DRAW_MENU   PROC
		; Parameters for this procedure:
		;           [bp+4] -> Left Border
		;           [bp+5] -> Top Line
		;           [bp+6] -> Right Border
		;           [bp+7] -> Bottom Line
		;           [bp+8] -> Start Address of the Menu
		;           elements array (strings)
		;           [bp+10] -> Length of each element
		;           [bp+12] -> Frame Attributes Byte
	push        bp
	mov         bp, sp
	push        bx
	push        cx
	push        dx
	push        si
	mov         bl, [bp+12]
	mov         cx, 1
	gotoxy      [bp+4], [bp+5]
	mov         al, 'Ú'
	mov         ah, 9
	int         10h
	gotoxy      [bp+6], [bp+5]
	mov         al, '¿'
	mov         ah, 9
	int         10h
	gotoxy      [bp+4], [bp+7]
	mov         al, 'À'
	mov         ah, 9
	int         10h
	gotoxy      [bp+6], [bp+7]
	mov         al, 'Ù'
	mov         ah, 9
	int         10h
	mov         cl, [bp+6]
	sub         cl, [bp+4]
	dec         cx
	mov         dx, [bp+4]
	inc         dx
	gotoxy
	mov         al, 'Ä'
	mov         ah, 9
	int         10h
	inc         dh
menu_lab_1:
	gotoxy      [bp+4]
	mov         al, '³'
	mov         ah, 9
	push        cx
	mov         cx, 1
	int         10h
	pop         cx
	inc         dx
	gotoxy
	mov         al, ' '
	mov         ah, 9
	int         10h
	gotoxy      [bp+6]
	mov         al, '³'
	mov         ah, 9
	push        cx
	mov         cx, 1
	int         10h
	pop         cx
	inc         dh
	cmp         dh, [bp+7]
	jnz         menu_lab_1
	mov         dl, [bp+4]
	inc         dx
	gotoxy
	mov         al, 'Ä'
	mov         ah, 9
	int         10h
	mov         dx, [bp+4]
	inc         dx
	inc         dx
	mov         si, [bp+8]
	mov         cx, [bp+10]
menu_lab_2:
	inc         dh
	cmp         dh, [bp+7]
	jz          menu_lab_3
	gotoxy
	call        CPUTSTR
	add         si, cx
	jmp         menu_lab_2
menu_lab_3:
	gotoxy      0FFh, 0FFh
	pop         si
	pop         dx
	pop         cx
	pop         bx
	mov         sp, bp
	pop         bp
	ret         10

	FILE_CHOISE DB          'Load       <L>'
	FILE_CHOISE_L EQU       $-FILE_CHOISE
		DB          'Save       <S>'
		DB          'Change Dir <C>'
		DB          'DOS Shell     '
		DB          'Exit   <ALT+X>'
		DB          'Resident      '

	TOOLS_CHOISE DB         'Dump              <D>'
	TOOLS_CHOISE_L EQU      $-TOOLS_CHOISE
		DB          'Unassemble        <U>'
		DB          'Assemble          <A>'
		DB          'Immediate <Shift+INS>'
		DB          'In Port           <I>'
		DB          'Out Port          <O>'
		DB          'View Screen       <V>'
		DB          'Interrupts           '
		DB          'Move              <M>'
		DB          'Read              <R>'
		DB          'Write             <W>'

	SPECIAL_CHOISE DB       'View Disk               '
	SPECIAL_CHOISE_L EQU    $-SPECIAL_CHOISE
		DB          'View File               '
		DB          'Enter            <Alt+E>'
		DB          'In Port          <Alt+I>'
		DB          'Out Port         <Alt+O>'
		DB          'Compare Strings  <Alt+C>'
		DB          'Find Byte        <Alt+B>'
		DB          'Find String      <Alt+S>'
		DB          'Find Instruction <Alt+N>'
		DB          'Copy Strings     <Alt+P>'

	DEBUG_CHOISE DB         'BreakPoint At         '
	DEBUG_CHOISE_L EQU      $-DEBUG_CHOISE
		DB          'Go Until      <Ctrl+G>'
		DB          'Run                <G>'
		DB          'Break Here       <INS>'
		DB          'Single Step       <F8>'
		DB          'Delete All Bkpts <DEL>'
		DB          'Trace             <F9>'
		DB          'Arguments             '

	CHOISE      DB          0
	ESC_EXIT    DB          0

DRAW_MENU   ENDP

