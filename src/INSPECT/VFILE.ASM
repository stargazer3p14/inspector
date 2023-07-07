
;F_NAME@     EQU         BYTE PTR [BP-64]

F_NAME@     DB	64 DUP (?)
F_NO@       EQU         WORD PTR [BP-66]
UF_PTR@     EQU         WORD PTR [BP-70]
DF_PTR@     EQU         WORD PTR [BP-74]
VF_XY       EQU         BYTE PTR [BP-76]


;jumps
VIEW_FILE   PROC
;locals

@@TAB       EQU         15
@@UP        EQU         72
@@DN        EQU         80
@@D         EQU         32
@@M         EQU         50
@@U         EQU         22
@@A         EQU         30
@@ESC       EQU         1

;----------------------------------------------------------------------------
;                       performes file view
;----------------------------------------------------------------------------
            mov         HELP_CODE, 7
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2
            int	33h
@@mouse_OK1:
            push        bp
            mov         bp, sp
            sub         sp, 76
            $STO_SCREEN 30, 10, 45, 14, SCREEN_BUF_1, 3
            $LITTLE_FRAME 30, 10, 45, 14, MENU_ATTR
            gotoxy      32, 11
            lea         si, VF_TTL
            mov         cx, VF_TTL_L
            call        CPUTSTR
            gotoxy      32, 12
            lea         si, FILE_PROMPT
            mov         cx, FILE_PROMPT_L
            call        CPUTSTR
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            gotoxy      32, 13
            push        ds
            push        es

;            push        ss
;            push        ss
;            pop         ds
;            pop         es
            mov         ah, 32
            mov         al, 43
            push        ax
            lea         di, F_NAME@
            push        di
            sub         al, al
            mov         cx, 63
            cld
rep         stosb
            push        di
            call        CGETSTR
            pop         es
            pop         ds
            pushf
            push        cx
            $LOD_SCREEN 30, 10, 45, 14, SCREEN_BUF_1, OUR_PAGE
            pop         cx
            popf
            jcxz        @@norm_retn
            jnc         @@name_OK
@@norm_retn:
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            mov         sp, bp
            pop         bp
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1
            int	33h
@@mouse_OK2:
            ret
@@name_OK:
            lea         dx, F_NAME@
	push	ds
;	push        ss
;	pop         ds
	mov         ah, 3Dh                 ; Open file
	mov	al, 2		; For read/write
	int         21h
	pop         ds
            jnc	@@open_OK
            cmp	ax, 5
            jnz	@@handle
            mov 	ax, 2
@@handle:
            add	ax, 2
            mov         ERRORCODE, ax
            call        ERR_HANDLER
            jmp         @@norm_retn
@@open_OK:
            mov         F_NO@, ax
            mov         DF_PTR@, 0
            mov         DF_PTR@[2], 0
            mov         UF_PTR@, 0
            mov         UF_PTR@[2], 0
            and         byte ptr PROG_STATUS[1], 11111100b
            call        SAVE_MAIN_WIND
            $LITTLE_FRAME 1, 1, 78, 23, TOP_FRAME_ATTR
            mov         dh, 8
            gotoxy      1
            mov         al, 'Ç'
            mov         ah, 9
            mov         cx, 1
            int         10h
            gotoxy      78
            mov         al, '¶'
            mov         ah, 9
            int         10h
            gotoxy      2
            mov         al, 'Ä'
            mov         ah, 9
            mov         cx, 76
            int         10h
            gotoxy      33, 1
            lea         si, VF_TOP
            mov         cx, VF_TOP_L
            call        CPUTSTR
            call        FILE_DUMP
            call        FILE_UNASS
@@main_loop:
	WHEREXY
            or	ch, 00100000b
            mov	ah, 1
            int	10h
	call	GETCH
;----------------------------------------------------------------------------
;                                   read KBD.
;                             Recognizable keys:
;           1)          TAB - window switch
;           2)          Up - active window UP
;           3)          Down - active window DOWN
;           4)          PgUp/PgDn - -"-
;           5)          'D' - get offset (from file start) to DUMP
;           6)          'U' - -"- to unassemble
;           7)          'M' - move data to specified offset
;           8)          'A' - assemble immediately to file
;           9)          Esc. - OUT'A View File Service
;----------------------------------------------------------------------------
            cmp         ah, @@ESC
            jnz         @@tab@
            call        RESTORE_MAIN_WIND
            QCLOSE      F_NO@
            mov         sp, bp
            pop         bp
            ret
@@tab@:
            cmp         ah, @@TAB
            jnz         @@up@
            xor         byte ptr PROG_STATUS[1], 00000001b
            cmp         HELP_CODE, 7
            jnz         @@dec_hlp
            inc         HELP_CODE
            jmp         @@help_OK
@@dec_hlp:
            dec         HELP_CODE
@@help_OK:
            call        FILE_DUMP
            call        FILE_UNASS
            jmp         short       @@main_loop
@@up@:
            cmp         ah, @@UP
            jnz         @@dn@
	call	FILE_UP
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_up
            call	FILE_UNASS
            jmp	@@main_loop
@@dump_up:
	call	FILE_DUMP
            jmp	@@main_loop
@@dn@:
            cmp         ah, @@DN
            jnz         @@PgUp@
            call	FILE_DOWN
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_dn
	call	FILE_UNASS
            jmp	@@main_loop
@@dump_dn:
	call	FILE_DUMP
            jmp	@@main_loop
@@PgUp@:
	cmp	ah, 73
            jnz	@@PgDn@
	test	byte ptr PROG_STATUS[1], 1
            jnz	@@scroll_dump
            mov	cx, 14
            jmp	@@PgUp_proceed
@@scroll_dump:
	mov	cx, 5
@@PgUp_proceed:
	push	cx
	call	FILE_UP
            pop	cx
            loop	@@PgUp_proceed
            test	byte ptr PROG_STATUS[1], 1
            jz	@@unass_up
            call	FILE_DUMP
            jmp	@@main_loop
@@unass_up:
	call	FILE_UNASS
            jmp	@@main_loop
@@PgDn@:
	cmp	ah, 81
            jnz	@@D@
            test	byte ptr PROG_STATUS[1], 1
            jz	@@scroll_unass
            mov	cx, 5
            jmp	@@PgDn_proceed
@@scroll_unass:
	mov	cx, 14
@@PgDn_proceed:
	push	cx
	call	FILE_DOWN
            pop	cx
            loop	@@PgDn_proceed
            test	byte ptr PROG_STATUS[1], 1
            jz	@@unass_dn
            call	FILE_DUMP
            jmp	@@main_loop
@@unass_dn:
	call	FILE_UNASS
            jmp	@@main_loop
@@D@:
            cmp         ah, @@D
            jnz         @@U@
            $STO_SCREEN 20, 10, 59, 14, SCREEN_BUF_1, OUR_PAGE
            $LITTLE_FRAME 20, 10, 59, 14, MENU_ATTR
            gotoxy      38, 11
            lea         si, DUMP_TTL
            mov         cx, 4
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, VF_PROMPT
            mov         cx, VF_PROMPT_L
            call        CPUTSTR
            gotoxy      35, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETLONG16
            jc          @@end_dump
            mov         DF_PTR@, ax
            mov         DF_PTR@[2], dx
@@end_dump:
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            $LOD_SCREEN 20, 10, 59, 14, SCREEN_BUF_1, OUR_PAGE
            call        FILE_DUMP
            jmp         @@main_loop
@@U@:
            cmp         ah, @@U
            jnz         @@M@
            $STO_SCREEN 20, 10, 59, 14, SCREEN_BUF_1, OUR_PAGE
            $LITTLE_FRAME 20, 10, 59, 14, MENU_ATTR
            gotoxy      34, 11
            lea         si, UNASS_TTL
            mov         cx, UNASS_TTL_L
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, VF_PROMPT
            mov         cx, VF_PROMPT_L
            call        CPUTSTR
            gotoxy      35, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETLONG16
            jc          @@end_unass
            mov         UF_PTR@, ax
            mov         UF_PTR@[2], dx
@@end_unass:
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            $LOD_SCREEN 20, 10, 59, 14, SCREEN_BUF_1, OUR_PAGE
            call        FILE_UNASS
            jmp         @@main_loop
@@M@:
            cmp         ah, @@M
            jnz         @@A@
            $STO_SCREEN 20, 10, 59, 15, SCREEN_BUF_1, OUR_PAGE
            $LITTLE_FRAME 20, 10, 59, 15, MENU_ATTR
            gotoxy      38, 11
            lea         si, MOVE_TTL
            mov         cx, 4
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, VF_PROMPT
            mov         cx, VF_PROMPT_L
            call        CPUTSTR
            gotoxy      35, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETLONG16
            jc          @@end_move
            MOVE_PTR    F_NO@, dx, ax, 0
            gotoxy      22, 14
            lea         si, @@VALUE
            mov         cx, @@VALUE_L
            call        CPUTSTR
            wherexy
            call        CGETHEX2
            jc          @@end_move
            mov         ds:[VIEW_FILE_BUF], al
            QWRITE      F_NO@, [VIEW_FILE_BUF], 1
            push        bx
            mov         ah, 68h
            mov         bx, F_NO@
            int         21h
            pop         bx
@@end_move:
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            $LOD_SCREEN 20, 10, 59, 15, SCREEN_BUF_1, OUR_PAGE
            call        FILE_DUMP
            call        FILE_UNASS
            jmp         @@main_loop
@@A@:
            cmp         ah, @@A
            jnz         @@home?
            $STO_SCREEN 20, 10, 59, 15, SCREEN_BUF_1, OUR_PAGE
            $LITTLE_FRAME 20, 10, 59, 15, MENU_ATTR
            gotoxy      35, 11
            lea         si, ASSM_TTL
            mov         cx, ASSM_TTL_L
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, VF_PROMPT
            mov         cx, VF_PROMPT_L
            call        CPUTSTR
            gotoxy      35, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETLONG16
            jc          @@end_assm
            MOVE_PTR    F_NO@, dx, ax, 0
            gotoxy      22, 14
            lea         si, @@INSTR
            mov         cx, @@INSTR_L
            call        CPUTSTR
            wherexy
            mov         ah, dl
            mov         al, 57
            push        ax
            lea         di, INSTR_FLD
            push        di
            mov         cx, 100
            sub         al, al
            cld
rep         stosb
            push        di
            gotoxy
            call        CGETSTR
            jc          @@end_assm
            jcxz        @@end_assm
            lea         di, INSTR_FLD
            push        di
            mov         cx, 10
            push        cx
            call        UPCASE
            cmp         INSTR_FLD, 'J'
            jz          @@end_assm
            lea         si, @@LOOP
            mov         cx, 4
            cld
repz        cmpsb
            jz          @@end_assm
            lea         ax, INSTR_FLD
            push        ax
            mov         ax, VIEW_FILE_BUF
            push        ax
            push        ax
            call        ASSEMBLE
            jc          @@end_assm
            mov         al, ds:[VIEW_FILE_BUF]
            cbw
            QWRITE      F_NO@, [VIEW_FILE_BUF+1], ax
            mov         ah, 68h
            mov         bx, F_NO@
            int         21h
            mov         bh, OUR_PAGE
@@end_assm:
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            $LOD_SCREEN 20, 10, 59, 15, SCREEN_BUF_1, OUR_PAGE
            call        FILE_UNASS
            call        FILE_DUMP
            jmp         @@main_loop
@@home?:
	cmp	ah, 71
            jnz	@@end?
            jnz	@@dump_home
            MOVE_PTR    F_NO@, 0, 0, 0
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_home
            mov	UF_PTR@, ax
            mov	UF_PTR@[2], dx
            jmp	@@end_home
@@dump_home:
            mov	DF_PTR@, ax
            mov	DF_PTR@, dx
@@end_home:
            call	FILE_UNASS
            call	FILE_DUMP
            jmp	@@main_loop
@@end?:
	cmp	ah, 79
            jnz	@@main_loop
            MOVE_PTR	F_NO@, 0, 0, 2
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_end
            mov	UF_PTR@, ax
            mov	UF_PTR@[2], dx
            jmp	@@end_end
@@dump_end:
	mov	DF_PTR@, ax
            mov	DF_PTR@[2], dx
@@end_end:
	call	FILE_UNASS
            call	FILE_DUMP
            jmp	@@main_loop



VF_TTL      DB          'VIEW FILE'
VF_TTL_L    EQU         $-VF_TTL
VF_TOP      DB          'View File Service'
VF_TOP_L    EQU         $-VF_TOP
VF_PROMPT   DB          "Input Offset from the Start of File:"
VF_PROMPT_L EQU         $-VF_PROMPT
@@VALUE     DB          'Input Value: '
@@VALUE_L   EQU         $-@@VALUE
@@INSTR     DB          'Input Instruction: '
@@INSTR_L   EQU         $-@@INSTR
@@LOOP      DB          'LOOP'

VIEW_FILE   ENDP



READ_FILE   PROC

;----------------------------------------------------------------------------
;                       reads from spec. file
;                       parameters:
;                       SS:[si+8] -> ADDRESS (DS:)
;                       SS:[si+6] -> Nø BYTES
;                       SS:[si+4] -> HANDLER
;----------------------------------------------------------------------------

            push        si
            mov         si, sp
            push        bx
            push        cx
            push        dx
            mov         bx, ss:[si+4]
            mov         cx, ss:[si+6]
            mov         dx, ss:[si+8]
            mov         ah, 3Fh
            int         21h
            pop         dx
            pop         cx
            pop         bx
            pop         si
            ret         6
READ_FILE   ENDP



FILE_DUMP   PROC
;locals
            push        DF_PTR@
            push        DF_PTR@[2]
            test        byte ptr PROG_STATUS[1], 1
	jz          @F
	mov         bl, AC_WIND_ATTR
	jmp         nxt
@@:
	mov         bl, ATTRIB
nxt:
            gotoxy      35, 2
            lea         di, F_NAME@[63]
            mov         cx, 63
;            push        ss
;            pop         es
            mov         al, '\'
            std
repnz       scasb
	jnz         @F
	inc         di
	inc         di
@@:
            mov         si, di
;            push        ss
;            pop         ds
            mov         cx, 12
            call        CPUTSTR
            push        cs
            push        cs
            pop         ds
            pop         es
            mov         dh, 3
            mov         cx, 5
@@fd_loop:
            push        cx
            gotoxy      2
            mov         al, ' '
            mov         cx, 76
            mov         ah, 9
            int         10h
            
            MOVE_PTR    F_NO@, DF_PTR@[2], DF_PTR@, 0
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, 16
            push        ax
            push        F_NO@
            call        READ_FILE
            or          ax, ax
            jnz         @@lab_1
            MOVE_PTR    F_NO@, 0, 0, 2
            mov         DF_PTR@, ax
            mov         DF_PTR@[2], dx
            wherexy
            jmp         short       @@ret_loop
@@lab_1:
            mov         @@VAR, ax
            lea         si, DF_PTR@[3]
            mov         cx, 4
@@off_loop:
            std
            lods        byte ptr ss:[si]
            call        CPUTHEX2
            loop        @@off_loop

            mov         VF_XY, 12
            mov         VF_XY[1], 62
            wherexy
            mov         si, VIEW_FILE_BUF
            mov         cx, @@VAR
            cld
@@loop_1:
            lodsb
            gotoxy      VF_XY
            call        CPUTHEX2
            gotoxy      VF_XY[1]
            push        cx
            mov         ah, 9
            mov         cx, 1
            int         10h
            pop         cx
            add         VF_XY, 3
            inc         VF_XY[1]
            loop        @@loop_1
@@ret_loop:
            pop         cx
            inc         dh
            add         DF_PTR@, 10h
            adc         DF_PTR@[2], 0
	loop        @F
	jmp	@@retrn
@@:
	jmp	@@fd_loop
@@retrn:
            pop         DF_PTR@[2]
            pop         DF_PTR@
            ret

@@VAR       DW          ?

FILE_DUMP   ENDP



FILE_UNASS  PROC
;locals
            push        cx
            push        si
            push        di
            push        UF_PTR@
            push        UF_PTR@[2]
            test        byte ptr PROG_STATUS[1], 1
            jnz         @@n_act
            mov         bl, AC_WIND_ATTR
            jmp         @@go_on
@@n_act:
            mov         bl, ATTRIB
@@go_on:
            mov         dh, 9
@@fu_loop:
            gotoxy      2
            mov         al, ' '
            mov         cx, 76
            mov         ah, 9
            int         10h
            push        dx
            MOVE_PTR    F_NO@, UF_PTR@[2], UF_PTR@, 0
            pop         dx
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, 6
            push        ax
            push        F_NO@
            call        READ_FILE
            or          ax, ax
            jnz         @@lab_1
            MOVE_PTR    F_NO@, 0, 0, 2
            mov         UF_PTR@, ax
            mov         UF_PTR@[2], dx
            jmp         short       @@loop_ret
@@lab_1:
            push        UF_PTR@
            push        ds
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         di, TEST_FIELD
            push        di
            mov         cx, 50
            sub         al, al
            cld
rep         stosb
            call        DASS
            lea         si, UF_PTR@[3]
            mov         cx, 4
@@loop_1:
            std
            lods        byte ptr ss:[si]
            call        CPUTHEX2
            loop        @@loop_1
            gotoxy      12
            cmp         byte ptr ds:[TEST_FIELD], 0
            jnz         @@non_db
            mov         al, ds:[TEST_FIELD+1]
            inc         byte ptr ds:[TEST_FIELD]
            call        CPUTHEX2
            gotoxy      35
            call        CPUTHEX2
            gotoxy      26
            lea         si, DEF_B
            mov         cx, 2
            call        CPUTSTR
@@loop_ret:
            wherexy
            inc         dh
            cmp         dh, 23
            jnb         @@to_retn
            mov         al, ds:[TEST_FIELD]
            cbw
            add         UF_PTR@, ax
            adc         UF_PTR@[2], 0
	jmp         @@fu_loop
@@to_retn:
            pop         UF_PTR@[2]
            pop         UF_PTR@
            pop         di
            pop         si
            pop         cx
            ret
@@non_db:
            mov         cl, ds:[TEST_FIELD]
            sub         ch, ch
            mov         si, TEST_FIELD+1
            cld
@@loop_2:
            lodsb
            call        CPUTHEX2
            loop        @@loop_2
            gotoxy      26
            mov         si, TEST_FIELD+7
            mov         cx, 6
            call        CPUTSTR
            gotoxy      35
            cmp         byte ptr ds:[TEST_FIELD+41], 0
            jz          @@no_lab
            mov         si, TEST_FIELD+41
            mov         cx, 9
            call        CPUTSTR
            wherexy
            inc         dx
            gotoxy
@@no_lab:
            cmp         byte ptr ds:[TEST_FIELD+13], 0
            jz          @@loop_ret
            mov         si, TEST_FIELD+13
            mov         cx, 12
            call        CPUTSTR
            cmp         byte ptr ds:[TEST_FIELD+25], 0
            jz          @@loop_ret
            call        PUT_SPACE
            mov         si, TEST_FIELD+25
            mov         cx, 12
            call        CPUTSTR
            cmp         byte ptr ds:[TEST_FIELD+37], 0
            jz          @@loop_ret
            call        PUT_SPACE
            mov         si, TEST_FIELD+37
            mov         cx, 4
            call        CPUTSTR
            jmp         @@loop_ret
FILE_UNASS  ENDP


FILE_UP	PROC
;locals
            test        byte ptr PROG_STATUS[1], 00000001b
            jnz         @@dump_act
;----------------------------- Unassemble Up --------------------------------

            cmp         UF_PTR@[2], 0
            jnz         @@not_start
            cmp         UF_PTR@, 0
            jnz         @@not_start
            retn
@@not_start:
            mov         cx, 6
            mov         di, UF_PTR@
            mov         si, UF_PTR@[2]
            sub         di, 6
            sbb         si, 0
            jnc         @@loop_2
            mov         cx, UF_PTR@
@@loop_2:
            push        cx
            add         di, 1
            adc         si, 0
            MOVE_PTR    F_NO@, si, di, 0
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, 6
            push        ax
            push        F_NO@
            call        READ_FILE

            push        di
            mov         di, TEST_FIELD
            mov         cx, 50
            sub         al, al
            cld
rep         stosb
            pop         di

            push        ax
            push        ds
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, TEST_FIELD
            push        ax
            call        DASS
            mov         al, ds:[TEST_FIELD]
            cbw
            add         ax, di
            pop         cx
            cmp         ax, UF_PTR@
            jnz         @@to_loop
            cmp         byte ptr ds:[TEST_FIELD], 0
            jz          @@to_loop
            jmp         short       @@to_output
@@to_loop:
            cmp         si, 0
            jnz         @@loop_ret00
            cmp         di, 0
            jz          @@to_db
@@loop_ret00:
            loop        @@loop_2
@@to_db:
            sub         UF_PTR@, 1
            sbb         UF_PTR@[2], 0
            jmp         short       @@output
@@to_output:
            mov         UF_PTR@, di
            mov         UF_PTR@[2], si
@@output:
	retn
@@dump_act:
            cmp         DF_PTR@[2], 0
            jnz         @@dump_OK
            cmp         DF_PTR@, 10h
            jnb         @@dump_OK
            mov         DF_PTR@, 0
            jmp         short       @@lab_00
@@dump_OK:
            sub         DF_PTR@, 10h
            sbb         DF_PTR@[2], 0
@@lab_00:
            retn
FILE_UP	ENDP


FILE_DOWN	PROC
;locals
            test        byte ptr PROG_STATUS[1], 00000001b
            jnz         @@dump_dn
            MOVE_PTR    F_NO@, UF_PTR@[2], UF_PTR@, 0
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, 6
            push        ax
            push        F_NO@
            call        READ_FILE
            and         ax, ax
            jnz         @@go_on
	retn
@@go_on:
            mov         di, TEST_FIELD
            mov         cx, 50
            sub         al, al
            cld
rep         stosb

            push        ax
            push        ds
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, TEST_FIELD
            push        ax
            call        DASS
            cmp         byte ptr ds:[TEST_FIELD], 0
            jnz         @@label_01
            inc         byte ptr ds:[TEST_FIELD]
@@label_01:
            mov         al, ds:[TEST_FIELD]
            cbw
            add         UF_PTR@, ax
            adc         UF_PTR@[2], 0
	retn
@@dump_dn:
	MOVE_PTR    F_NO@, DF_PTR@[2], DF_PTR@, 0
            mov         ax, VIEW_FILE_BUF
            push        ax
            mov         ax, 1
            push        ax
            push        F_NO@
            call        READ_FILE
            and         ax, ax
	jnz         @F
	retn
@@:
            add         DF_PTR@, 10h
            adc         DF_PTR@[2], 0
	retn
FILE_DOWN	ENDP


PUT_SPACE	PROC	near
	mov	si, offset coma_space
	mov	cx, 2
	call	CPUTSTR
	retn

coma_space	db	", "

PUT_SPACE	ENDP
