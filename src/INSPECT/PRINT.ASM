;----------------------------------------------------------------------------
;           This file includes procedures for printing MEMORY,
;           DISK and FILE in DUMP and DISASSEMBLER format.
;----------------------------------------------------------------------------

PRINT_STR   DB          80 DUP (?)  ;field to be set by all printing routines.

PRINT_MEM   PROC
;locals
;----------------------------------------------------------------------------
;           This procedure prints memory. It should be installed
;           as INT 1Ch handler & requires PRN_ST_SEG, PRN_ST_OFF,
;           PRN_END_SEG, PRN_END_OFF to be set during installation.
;           Segments must be 4 high bits.
;----------------------------------------------------------------------------
;int 3
            sti
            test        byte ptr PROG_STATUS, 80h           ;print unass/dump
            jnz         @@prn_unass
            jmp         @@print_dump
;---------------------------- print disassembler ----------------------------
@@prn_unass:
            cmp         OUT_COUNTER, 0
            jnz         @@go_on
            mov         ax, PRN_ST_SEG
            cmp         ax, PRN_END_SEG
            jb          @@st_seg_OK_01
            mov         ax, PRN_ST_OFF
            cmp         ax, PRN_END_OFF
            jb          @@st_seg_OK_01
            jmp         @@exit
@@st_seg_OK_01:
            push        PRN_ST_OFF
            push        PRN_ST_SEG
            push        PRN_ST_OFF
            mov         di, TEST_FIELD
            push        di
            sub         ax, ax
            mov         cx, 25
            cld
rep         stosw
            call        DASS
            mov         al, ds:[TEST_FIELD]
            or          al, al
            jnz         @F
            inc         ax
@@:
            cbw
            add         PRN_ST_OFF, ax
            jnc         @@in_seg_01
            add         PRN_ST_SEG, 1000h
@@in_seg_01:
            call        DO_UNASS_STR
            clc
            ret
@@go_on:
            push        dx
            mov         si, PRN_PTR
            mov         al, [si+PRINT_STR]
            sub         ah, ah
            mov         dx, ACT_PRN
            push        cx
            mov         cx, 1
            int         17h
            pop         cx
            pop         dx
            test        ah, 8
            jnz         @@pr_err
            inc         PRN_PTR
            dec         OUT_COUNTER
            clc
            ret
@@pr_err:
            test        ah, 20h                 ; out of paper?
            jnz         @@no_paper
            mov         ERRORCODE, 13
            call        ERR_HANDLER
            jmp         @@handle
@@no_paper:
            mov         ERRORCODE, 14
            call        ERR_HANDLER
@@handle:
            $STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            $CHANGE_ATTRIBS 1, 23, 78, 23, ERR_ATTR
            GOTOXY      1, 23
            mov         ax, 920h
            mov         cx, 78
            mov         bl, ERR_ATTR
            int         10h
            GOTOXY      3
            mov         si, offset @@ERR_CHOISE
            mov         cx, @@LEN
            call        CPUTSTR
@@err_loop:
            sub         ah, ah
            int         16h
            cmp         ah, 16
            jnz         @@R?
            $LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            stc
            ret
@@R?:
            cmp         ah, 19
            jnz         @@err_loop
            $LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            clc
            ret
@@print_dump:
            cmp         OUT_COUNTER, 0
            jnz         @@go_on
            mov         ax, PRN_ST_SEG
            cmp         ax, PRN_END_SEG
            jb          @@st_seg_OK_01
            mov         ax, PRN_ST_OFF
            cmp         ax, PRN_END_OFF
            jb          @@st_seg_OK_02
            jmp         @@exit
@@st_seg_OK_02:
;--------------------------- Prepare print string ---------------------------
            add         PRN_ST_OFF, 10h
            jnc         @@in_seg_02
            add         PRN_ST_SEG, 1000h
@@in_seg_02:
            call        DO_DUMP_STR
            clc
            ret
@@exit:
;-------------------------- Clear printer buffer ----------------------------
            mov         dx, ACT_PRN
            mov         al, 24
            sub         ah, ah
            int         17h
            stc
            ret


PRN_ST_SEG  DW          ?
PRN_ST_OFF  DW          ?
PRN_END_SEG DW          ?
PRN_END_OFF DW          ?
PRN_PTR     DW          ?
OUT_COUNTER DB          ?           ;must be set 80 during installation
ACT_PRINTER DW          ?
@@ERR_CHOISE  DB        "Press 'Q' to quit printing or 'R' to retry."
@@LEN       EQU         $-@@ERR_CHOISE

PRINT_MEM   ENDP



PRINT_INST  PROC
;locals
;jumps
;int 3
;----------------------------------------------------------------------------
;           This procedure installs print routine to 1Ch vector.
;           Should be called & make print menu.
;----------------------------------------------------------------------------
            $STO_SCREEN 37, 1, 41+@@PM_L, 4, SCREEN_BUF_1, OUR_PAGE
            mov         ah, OUR_PAGE
	$DRAW_MENU  37, 1, 41+@@PM_L, 4, offset @@PRN_MENU, @@PM_L, MENU_ATTR
            mov         @@CHOISE, 0
            call        @@draw
@@chk_kbd:
            sub         ah, ah
            int         16h
            cmp         ah, 1
            jnz         @@up?
            $LOD_SCREEN 37, 1, 41+@@PM_L, 4, SCREEN_BUF_1, OUR_PAGE
            ret
@@up?:
            cmp         ah, 72                  ;Up?
            jnz         @@down?
            call        @@del
            xor         @@CHOISE, 1
            call        @@draw
            jmp         short       @@chk_kbd
@@down?:
            cmp         ah, 80                  ;Down?
            jnz         @@enter?
            call        @@del
            xor         @@CHOISE, 1
            call        @@draw
            jmp         short       @@chk_kbd
@@enter?:
            cmp         ah, 28
            jnz         @@chk_kbd
            $LOD_SCREEN 37, 1, 41+@@PM_L, 4, SCREEN_BUF_1, OUR_PAGE
            mov         al, @@CHOISE
            ror         al, 1
            and         byte ptr PROG_STATUS, 7Fh
            or          byte ptr PROG_STATUS, al

;---------------------------- Install PRINT_MEM -----------------------------
            $STO_SCREEN 30, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
            $LITTLE_FRAME 30, 10, 60, 15, MENU_ATTR
            gotoxy      32, 11
            lea         si, @@ST_SEG
            mov         cx, @@ST_L
            call        CPUTSTR
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETHEX4
            jnc         @@st_seg_got
            jmp         @@mem_fault
@@st_seg_got:
            mov         PRN_ST_SEG, ax
            gotoxy      32, 12
            lea         si, @@ST_OFF
            mov         cx, @@ST_L
            call        CPUTSTR
            wherexy
            call        CGETHEX4
            jnc         @@st_off_got
            jmp         @@mem_fault
@@st_off_got:
            mov         PRN_ST_OFF, ax
            gotoxy      32, 13
            lea         si, @@END_SEG
            mov         cx, @@END_L
            call        CPUTSTR
            wherexy
            call        CGETHEX4
            jnc         @@end_seg_got
            jmp         @@mem_fault
@@end_seg_got:
            mov         PRN_END_SEG, ax
            gotoxy      32, 14
            lea         si, @@END_OFF
            mov         cx, @@END_L
            call        CPUTSTR
            wherexy
            call        CGETHEX4
            jnc         @@o_kay
            jmp         @@mem_fault
@@o_kay:
            mov         PRN_END_OFF, ax
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            $LOD_SCREEN 30, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
            mov         cl, 4
            mov         ax, PRN_ST_SEG
            shl         ax, cl
            add         PRN_ST_OFF, ax
            jnc         @@go_on1
            add         PRN_ST_SEG, 1000h
@@go_on1:
            and         PRN_ST_SEG, 0F000h
            mov         ax, PRN_END_SEG
            shl         ax, cl
            add         PRN_END_OFF, ax
            jnc         @@go_on2
            add         PRN_END_SEG, 1000h
@@go_on2:
            and         PRN_END_SEG, 0F000h
;-------------------------- Printer initialization --------------------------
            mov         dx, ACT_PRN
            mov         ah, 1
            int         17h
	    test	ah, 20h
	    jz		@F
	    mov		ERRORCODE, 13
	    call	ERR_HANDLER
	    stc
	    jmp		@@exitten
@@:
	    test	ah, 8
	    jz		@F
	    mov		ERRORCODE, 14
	    call	ERR_HANDLER
	    stc
	    jmp		@@exitten
@@:
            test        byte ptr PROG_STATUS, 80h
            jnz         @@unass_go
            call        DO_DUMP_STR
            jmp         @@temp_loop
@@unass_go:
            call        DO_UNASS_STR
@@temp_loop:
            call        PRINT_MEM
            jc          @@exitten
            jmp         @@temp_loop
@@exitten:
            mov         bh, OUR_PAGE
            ret


@@draw:
            mov         ah, @@CHOISE
            add         ah, 2
            mov         al, 38
            push        ax
            mov         al, 49
            push        ax
            mov         ah, OUR_PAGE
            mov         al, SELECT_ATTR
            push        ax
            call        CHANGE_ATTRIBS
            ret
@@del:
            mov         ah, @@CHOISE
            add         ah, 2
            mov         al, 38
            push        ax
            mov         al, 49
            push        ax
            mov         ah, OUR_PAGE
            mov         al, MENU_ATTR
            push        ax
            call        CHANGE_ATTRIBS
            ret
@@mem_fault:
            $LOD_SCREEN 30, 10, 60, 15, SCREEN_BUF_1, OUR_PAGE
            ret

@@PRN_MENU  DB          'Dump      '
@@PM_L      EQU         $-@@PRN_MENU
            DB          'Unassemble'
@@CHOISE    DB          ?

@@ST_SEG    DB          'Input Start Segment: '
@@ST_L      EQU         $-@@ST_SEG
@@ST_OFF    DB          'Input Start Offset:  '
@@END_SEG   DB          'Input End Segment: '
@@END_L     EQU         $-@@END_SEG
@@END_OFF   DB          'Input End Offset:  '

PRINT_INST  ENDP



DO_UNASS_STR PROC
;locals
;----------------------------------------------------------------------------
;           Makes unassemble strings for printing
;----------------------------------------------------------------------------
            mov         ax, 13
            mov         cx, 1
            mov         dx, ACT_PRN
            int         17h
            push        PRN_ST_OFF
            push        PRN_ST_SEG
            push        PRN_ST_OFF
            mov         di, TEST_FIELD
            push        di
            sub         ax, ax
            mov         cx, 25
            cld
rep         stosw
            call        DASS
            mov         ax, 12
            push        ax
            mov         di, offset PRINT_STR
            push        di
            mov         ax, '  '
            mov         cx, 40
            cld
rep         stosw
            mov         ax, PRN_ST_SEG
            call        INT_TO_STR
            mov         PRINT_STR[4], ':'
            mov         ax, 12
            push        ax
            mov         ax, offset PRINT_STR[5]
            push        ax
            mov         ax, PRN_ST_OFF
            call        INT_TO_STR
            mov         cl, ds:[TEST_FIELD]
            and         cl, cl
            jnz         $+3
            inc         cx
            sub         ch, ch
            mov         si, TEST_FIELD+1
            mov         di, offset PRINT_STR[12]
            cld
@@cnv_loop:
            lodsb
            mov         dx, 4
            push        dx
            push        di
            call        INT_TO_STR
            inc         di
            inc         di
            loop        @@cnv_loop
            cmp         byte ptr ds:[TEST_FIELD], 0
            jnz         @@get_instr
            mov         ax, word ptr DEF_B
            mov         word ptr PRINT_STR[26], ax
            mov         ax, 4
            push        ax
            mov         ax, offset PRINT_STR[35]
            push        ax
            mov         al, ds:[TEST_FIELD]
            call        INT_TO_STR
            jmp         @@str_made
@@get_instr:
            mov         si, TEST_FIELD+7
            mov         di, offset PRINT_STR[26]
            mov         cx, 6
            cld
@@loop1:
            lodsb
            and         al, al
            jz          @@end_loop1
            stosb
            loop        @@loop1
@@end_loop1:
            mov         di, offset PRINT_STR[36]
            cmp         byte ptr ds:[TEST_FIELD+41], 0
            jz          @@no_label
            mov         si, TEST_FIELD+41
            mov         cx, 9
            cld
@@loop1a:
            lodsb
            and         al, al
            jz          @@end_loop1a
            stosb
            loop        @@loop1a
@@end_loop1a:
            inc         di
@@no_label:
            cmp         byte ptr ds:[TEST_FIELD+13], 0
            jz          @@str_made
            mov         si, TEST_FIELD+13
            mov         cx, 12
            cld
@@loop2:
            lodsb
            and         al, al
            jz          @@end_loop2
            stosb
            loop        @@loop2
@@end_loop2:
            cmp         byte ptr ds:[TEST_FIELD+25], 0
            jz          @@str_made
            mov         si, TEST_FIELD+25
            mov         ax, ' ,'
            stosw
            mov         cx, 12
            cld
@@loop3:
            lodsb
            and         al, al
            jz          @@end_loop3
            stosb
            loop        @@loop3
@@end_loop3:
            cmp         byte ptr ds:[TEST_FIELD+37], 0
            jz          @@str_made
            mov         si, TEST_FIELD+37
            mov         ax, ' ,'
            stosw
            mov         cx, 4
            cld
@@loop4:
            lodsb
            and         al, al
            jz          @@str_made
            stosb
            loop        @@loop4
@@str_made:
            mov         word ptr PRINT_STR[78], 0A0Dh
            mov         OUT_COUNTER, 80
            mov         PRN_PTR, 0

            ret
DO_UNASS_STR ENDP



DO_DUMP_STR PROC
;locals
;----------------------------------------------------------------------------
;           Makes strings for printing in dump format
;----------------------------------------------------------------------------

            push        es
            push        bx
            push        dx
            push        di
            mov         ax, 13
            mov         cx, 1
            mov         dx, ACT_PRN
            int         17h
            lea         di, PRINT_STR
            mov         cx, 40
            mov         ax, '  '
            cld
rep         stosw
            mov         ax, 12
            push        ax
            lea         ax, PRINT_STR
            push        ax
            mov         ax, PRN_ST_SEG
            call        INT_TO_STR
            mov         PRINT_STR[4], ':'
            mov         ax, 12
            push        ax
            lea         ax, PRINT_STR[5]
            push        ax
            mov         ax, PRN_ST_OFF
            call        INT_TO_STR
            mov         es, PRN_ST_SEG
            mov         si, PRN_ST_OFF
            mov         bx, 11
            mov         di, 61
            mov         cx, 10h
            cld
@@conv_loop:
            lods        byte ptr es:[si]
            cmp         al, ' '
            jb          @@below_sp
            mov         PRINT_STR[di], al
            jmp         short       @@char_OK
@@below_sp:
            mov         PRINT_STR[di], '.'
@@char_OK:
            mov         dx, 4
            push        dx
            lea         dx, PRINT_STR[bx]
            push        dx
            push        ds
            pop         es
            call        INT_TO_STR
            mov         es, PRN_ST_SEG
            add         bx, 3
            inc         di
            loop        @@conv_loop
            mov         word ptr PRINT_STR[78], 0A0Dh
            pop         di
            pop         dx
            pop         bx
            pop         es
            mov         OUT_COUNTER, 80
            mov         PRN_PTR, 0
            ret
DO_DUMP_STR ENDP


