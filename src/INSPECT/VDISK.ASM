            DTA@        EQU         WORD PTR [BP-4]
            N_SECTORS@  EQU         WORD PTR [BP-6]
            START_SECT@ EQU         WORD PTR [BP-10]
            DUMP_SECT@  EQU         WORD PTR [BP-14]
            DUMP_OFF@   EQU         WORD PTR [BP-16]
            UNASS_SECT@ EQU         WORD PTR [BP-20]
            UNASS_OFF@  EQU         WORD PTR [BP-22]
            VAR$        EQU         BYTE PTR [BP-24]
            DRIVE@      EQU         BYTE PTR [BP-26]


;----------------------------------------------------------------------------
;                            INSP. buffers:
;                       DSK_DUMP_BUF       (1024 b.)
;                       DSK_UNASS_BUF      (1024 b.)
;----------------------------------------------------------------------------




VIEW_DISK   PROC
;locals
;jumps
;----------------------------------------------------------------------------
;                                  Performs
;                    Disk View/Edit Service (Dump, Unassemble,
;                       assemble, etc.)
;----------------------------------------------------------------------------
            mov         HELP_CODE, 5
            cmp         MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2
            int	33h
@@mouse_OK1:
            push        bp
            mov         bp, sp
            sub         sp, 26
            call        SAVE_MAIN_WIND
            $LITTLE_FRAME 1, 1, 78, 23, TOP_FRAME_ATTR
            gotoxy      1, 8
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
            gotoxy      30, 1
            lea         si, VDISK_TOP
            mov         cx, VDISK_TOP_L
            call        CPUTSTR

            $STO_SCREEN 25, 10, 55, 14, SCREEN_BUF_1, 3
            $LITTLE_FRAME 25, 10, 55, 14, MENU_ATTR
            gotoxy      36, 11
            lea         si, VDISK_TTL
            mov         cx, VDISK_TTL_L
            call        CPUTSTR
            gotoxy      27, 12
            lea         si, DRIVE_PROMPT
            mov         cx, DRIVE_PROMPT_L
            call        CPUTSTR
            gotoxy      40, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
@@drv_loop:
	sub        	ah, ah
	int	16h
	cmp         ah, 1
            jnz         @@go_on
            $LOD_SCREEN 25, 10, 55, 14, SCREEN_BUF_1, 3
            jmp         @@retn
@@go_on:
            cmp         al, 'A'
            jb          @@drv_loop
            cmp         al, 'z'
            ja          @@drv_loop
            cmp         al, 'Z'
            jna         @@drv_grt
            cmp         al, 'a'
            jb          @@drv_loop
            sub         al, 'a'
            jmp         short       @@drv_OK
@@drv_grt:
            sub         al, 'A'
@@drv_OK:
            mov         DRIVE@, al
            $LOD_SCREEN 25, 10, 55, 14, SCREEN_BUF_1, 3
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h

;--------------------------Now the frame is drawn----------------------------
;--------------------------Set sectors parameters----------------------------
	push	ds
            push	ax
            push	bx
            push	cx
            push	dx
	mov	ah, 1Ch
            mov	dl, DRIVE@
            inc	dx
            int	21h
            cmp	al, -1
            jnz         @@valid
            pop	dx
            pop	cx
            pop	bx
            pop	ax
            pop	ds
            jmp	@@retn
@@valid:
            sub	ah, ah
            mul	dx
            mov	cs:TOTAL_SECT, ax
            mov	cs:TOTAL_SECT[2], dx
            pop	dx
            pop	cx
            pop	bx
            pop	ax
            pop	ds

            mov         N_SECTORS@, 2
            mov         DUMP_SECT@, 0
            mov         DUMP_SECT@[2], 0
            mov         DUMP_OFF@, 0
            mov         UNASS_SECT@, 0
            mov         UNASS_SECT@[2], 0
            mov         UNASS_OFF@, 0
            mov         ax, DUMP_SECT@
            mov         START_SECT@, ax
            mov         ax, DUMP_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_DUMP_BUF
            push        ax
            call        LOAD_SECT
            jc          @@retn
            call        DISK_DUMP
            mov         ax, UNASS_SECT@
            mov         START_SECT@, ax
            mov         ax, UNASS_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            push        ax
            call        LOAD_SECT
            call        DISK_UNASS
;-------------------------------Main loop------------------------------------
@@main_loop:

	call	GETCH
;----------------------------------------------------------------------------
;                       Recognizable symbols:
;           Up, Down, PgUp, PgDn, Home, End, 'U', 'D', 'M', 'A', TAB, Esc.
;----------------------------------------------------------------------------
@@ESC       EQU         1
@@UP        EQU         72
@@DOWN      EQU         80
@@TAB       EQU         15
@@W         EQU         17
@@U         EQU         22
@@D         EQU         32
@@A         EQU         30
@@M         EQU         50
@@PG_UP     EQU         73
@@PG_DN     EQU         81


            cmp         ah, @@ESC
            jnz         @@Up@
@@retn:
            call        RESTORE_MAIN_WIND
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1
            int	33h
@@mouse_OK2:
            mov         sp, bp
            pop         bp
            ret
@@Up@:
            cmp         ah, @@UP
            jnz         @@dn@
            call	DISK_UP
            call	DISK_UNASS
            call	DISK_DUMP
            jmp	@@main_loop
@@dn@:
            cmp         ah, @@DOWN
            jnz         @@tab@
            call	DISK_DOWN
            call	DISK_UNASS
            call	DISK_DUMP
            jmp	@@main_loop
@@tab@:
            cmp         ah, @@TAB
            jnz         @@U@
            xor         byte ptr PROG_STATUS[1], 1
            cmp         HELP_CODE, 5
            jnz         @@dec_hlp
            inc         HELP_CODE
            jmp         @@hlp_OK
@@dec_hlp:
            dec         HELP_CODE
@@hlp_OK:
            call        DISK_DUMP
            call        DISK_UNASS
            jmp         @@main_loop
@@U@:
            cmp         ah, @@U
	jz          @F
	jmp         @@D@
@@:
	$STO_SCREEN 20, 10, 67, 16, SCREEN_BUF_1, 3
	$LITTLE_FRAME 20, 10, 67, 16, MENU_ATTR
            gotoxy      38, 11
            lea         si, UNASS_TTL
            mov         cx, UNASS_TTL_L
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, @@UNASS_PROMPT
            mov         cx, @@UNASS_PROMPT_L
            call        CPUTSTR
            gotoxy      40, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETLONG16
            jnc         @@u_OK1
            cmp	ah, 1
            jz	@@u_put
            GOTOXY	40, 13
            mov	ax, UNASS_SECT@
            mov	dx, UNASS_SECT@[2]
            call	CPUTLONG16
	jmp	@@u_off
@@u_OK1:
            mov         UNASS_SECT@, ax
            mov         UNASS_SECT@[2], dx
@@u_off:
            gotoxy      22, 14
            lea         si, @@UNASS_OFF
            mov         cx, @@UNASS_OFF_L
            call        CPUTSTR
            gotoxy      40, 15
            call        CGETHEX4
            jc          @@u_put
            mov         UNASS_OFF@, ax
@@u_put:
            $LOD_SCREEN 20, 10, 67, 16, SCREEN_BUF_1, 3
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
@@load_unass:
	mov	ax, UNASS_SECT@[2]
            cmp	ax, TOTAL_SECT[2]
            jb	@@u_sect_OK
	ja	@@u_sect_repl
            mov	ax, TOTAL_SECT
            cmp	ax, UNASS_SECT@
            ja	@@u_sect_OK
@@u_sect_repl:
	jmp	end_key
@@u_sect_OK:
            mov         ax, UNASS_SECT@
            mov         START_SECT@, ax
            mov         ax, UNASS_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            push        ax
            call        LOAD_SECT
            jnc         @@ld_unass_OK
            jmp	@@home
@@ld_unass_OK:
            call        DISK_UNASS
            jmp         @@main_loop
@@D@:
            cmp         ah, @@D
	jz          @F
	jmp         @@A@
@@:
	$STO_SCREEN 25, 10, 56, 16, SCREEN_BUF_1, 3
	$LITTLE_FRAME 25, 10, 56, 16, MENU_ATTR
            gotoxy      38, 11
            lea         si, DUMP_TTL
            mov         cx, 4
            call        CPUTSTR
            gotoxy      27, 12
            lea         si, @@DUMP_PROMPT
            mov         cx, @@DUMP_PROMPT_L
            call        CPUTSTR
            gotoxy      38, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETLONG16
            jnc         @@d_OK1
            cmp	ah, 1
            jz	@@d_out
            GOTOXY	38, 13
            mov	ax, DUMP_SECT@
            mov	dx, DUMP_SECT@[2]
            call	CPUTLONG16
            jmp	@@d_off
@@d_OK1:
            mov         DUMP_SECT@, ax
            mov         DUMP_SECT@[2], dx
@@d_off:
            gotoxy      27, 14
            lea         si, @@DUMP_OFF
            mov         cx, @@DUMP_OFF_L
            call        CPUTSTR
            gotoxy      38, 15
            call        CGETHEX4
            jc          @@d_out
            mov         DUMP_OFF@, ax
@@d_out:
            $LOD_SCREEN 25, 10, 56, 16, SCREEN_BUF_1, 3
@@load_dump:
	mov	ax, DUMP_SECT@[2]
            cmp	ax, TOTAL_SECT[2]
            jb	@@d_sect_OK
            ja	@@d_sect_repl
            mov	ax, DUMP_SECT@
            cmp	ax, TOTAL_SECT
            jb	@@d_sect_OK
@@d_sect_repl:
	jmp	end_key
@@d_sect_OK:
            mov         ax, DUMP_SECT@
            mov         START_SECT@, ax
            mov         ax, DUMP_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_DUMP_BUF
            push        ax
            call        LOAD_SECT
            jnc	@@ld_dump_OK
            jmp	@@home
@@ld_dump_OK:
            call        DISK_DUMP
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            jmp         @@main_loop
@@A@:
            cmp         ah, @@A
	jz          @F
	jmp         @@M@
@@:
	$STO_SCREEN 20, 10, 53, 16, SCREEN_BUF_1, 3
	$LITTLE_FRAME 20, 10, 53, 16, MENU_ATTR
            gotoxy      28, 11
            lea         si, ASSM_TTL
            mov         cx, ASSM_TTL_L
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, @@ASSM_OFF
            mov         cx, @@ASSM_OFF_L
            call        CPUTSTR
            gotoxy      35, 13
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            call        CGETHEX4
            mov         di, 0
            jnc         @@a_OK1
            cmp	ah, 1
            jz	@@a_retn
            GOTOXY	35, 13
            mov	ax, di
            call	CPUTHEX4
@@a_OK1:
            mov         di, ax
@@a_instr:
            gotoxy      22, 14
            lea         si, ASSM_PROMPT
            mov         cx, ASSM_PROMPT_L
            call        CPUTSTR

            push        di
            lea         di, INSTR_FLD
            sub         al, al
            mov         cx, 100
            cld
rep         stosb
            pop         di

            gotoxy      24, 15
            mov         ah, 24
            mov         al, 49
            push        ax
            lea         ax, INSTR_FLD
            push        ax
            add         ax, 99
            push        ax
            call        CGETSTR
            jc          @@a_retn

            push        di
            mov         di, TEST_FIELD
            sub         al, al
            mov         cx, 50
            cld
rep         stosb
            pop         di

            push        bx
            push        di
            lea         ax, INSTR_FLD
            push        ax
            mov         ax, TEST_FIELD
            push        ax
            push        di
            call        ASSEMBLE
            pop         di
            pop         bx

            mov         cl, ds:[TEST_FIELD]
            sub         ch, ch
            test        cx, cx
	jnz         @F
	inc         cx
@@:
            mov         si, TEST_FIELD+1
            add         di, DSK_UNASS_BUF
            cld
rep         movsb

@@a_retn:
            $LOD_SCREEN 20, 10, 53, 16, SCREEN_BUF_1, 3
            call        DISK_DUMP
            call        DISK_UNASS
            wherexy
            or          ch, 0010000b
            mov         ah, 1
            int         10h
            jmp         @@main_loop
@@M@:
            cmp         ah, @@M
	jz          @F
	jmp         @@W@
@@:
	$STO_SCREEN 20, 10, 54, 16, SCREEN_BUF_1, 3
	$LITTLE_FRAME 20, 10, 54, 16, MENU_ATTR
            gotoxy      38, 11
            lea         si, MOVE_TTL
            mov         cx, MOVE_TTL_L
            call        CPUTSTR
            gotoxy      22, 12
            lea         si, @@MOVE_OFF
            mov         cx, @@MOVE_OFF_L
            call        CPUTSTR
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            gotoxy      36, 13
            call        CGETHEX4
            mov         di, 0
            jnc         @@m_OK1
            cmp	ah, 1
            jz	@@m_retn
	GOTOXY	36, 13
            mov	ax, di
            call	CPUTHEX4
@@m_OK1:
            mov         di, ax
@@m_data:
            gotoxy      22, 14
            lea         si, PORT_PROMPT2
            mov         cx, 6
            call        CPUTSTR
            gotoxy      38, 15
            call        CGETHEX2
            jc          @@m_retn
            mov         [di+DSK_DUMP_BUF], al
@@m_retn:
            $LOD_SCREEN 20, 10, 54, 16, SCREEN_BUF_1, 3
            call        DISK_DUMP
            call        DISK_UNASS
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            jmp         @@main_loop

@@W@:
            cmp         ah, @@W
            jnz         @@PgDn@
            test        byte ptr PROG_STATUS[1], 1
            jnz         @@write_dump
            mov         ax, UNASS_SECT@
            mov         START_SECT@, ax
            mov         ax, UNASS_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            push        ax
            call        SAVE_SECT
            jmp         @@main_loop
@@write_dump:
            mov         ax, DUMP_SECT@
            mov         START_SECT@, ax
            mov         ax, DUMP_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_DUMP_BUF
            push        ax
            call        SAVE_SECT
            jmp         @@main_loop

@@PgDn@:
	cmp	ah, @@PG_DN
            jnz	@@PgUp@
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_down
            mov	cx, 16
            jmp	@@PgDn_proceed
@@dump_down:
	mov	cx, 5
@@PgDn_proceed:
	push	cx
            call	DISK_DOWN
            pop	cx
            loop	@@PgDn_proceed
            call	DISK_DUMP
            call	DISK_UNASS
            jmp         @@main_loop
@@PgUp@:
	cmp	ah, @@PG_UP
            jnz	@@home?
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_up
            mov	cx, 16
            jmp	@@PgUp_proceed
@@dump_up:
            mov	cx, 5
@@PgUp_proceed:
	push	cx
            call	DISK_UP
            pop	cx
            loop	@@PgUp_proceed
            call	DISK_DUMP
            call	DISK_UNASS
            jmp	@@main_loop
@@home?:
	cmp	ah, 71
            jnz	end_key?
@@home:
            test	byte ptr PROG_STATUS[1], 1
            jz	@@unass_home
            mov	DUMP_SECT@, 0
            mov	DUMP_SECT@[2], 0
            mov	DUMP_OFF@, 0
	jmp	@@load_dump
@@unass_home:
	mov	UNASS_SECT@, 0
            mov	UNASS_SECT@[2], 0
            mov	UNASS_OFF@, 0
            jmp	@@load_unass
end_key?:
	cmp	ah, 79
            jnz	@@main_loop
end_key::
            test	byte ptr PROG_STATUS[1], 1
            jnz	@@dump_end
            mov	ax, TOTAL_SECT
            sub	ax, 1
            mov	UNASS_SECT@, ax
            mov	ax, TOTAL_SECT[2]
            sbb	ax, 0
            mov	UNASS_SECT@[2], ax
            jmp	@@load_unass
@@dump_end:
	mov	ax, TOTAL_SECT
            sub	ax, 1
            mov	DUMP_SECT@, ax
            mov	ax, TOTAL_SECT[2]
            sbb	ax, 0
            mov	DUMP_SECT@[2], ax
            jmp	@@load_dump

TOTAL_SECT  DW	2 DUP (?)
@@UNASS_PROMPT DB       'Input New Sector for Unassemble:'
@@UNASS_PROMPT_L EQU    $-@@UNASS_PROMPT
@@UNASS_OFF DB          'Input New Offset for Unassemble:'
@@UNASS_OFF_L EQU       $-@@UNASS_OFF
@@DUMP_PROMPT DB        'Input New Sector for Dump:'
@@DUMP_PROMPT_L EQU     $-@@DUMP_PROMPT
@@DUMP_OFF  DB          'Input New Offset for Dump:'
@@DUMP_OFF_L EQU        $-@@DUMP_OFF
@@ASSM_OFF  DB          'Input Offset to Assemble to:'
@@ASSM_OFF_L EQU        $-@@ASSM_OFF
@@MOVE_OFF  DB          'Input Offset to Move Data to:'
@@MOVE_OFF_L EQU        $-@@MOVE_OFF

VIEW_DISK   ENDP




LOAD_SECT   PROC
;locals

;----------------------------------------------------------------------------
;                       loads sector from disk
;                       ss:[si+4] -> offset
;                       ss:[si+6] -> segment (memory to load to)
;----------------------------------------------------------------------------

            push        si
            mov         si, sp
            mov         al, DRIVE@
            cmp         byte ptr DOS_VER, 4
            jnb         @@to_packet
            push        ds
            push        bx
            push        cx
            push        dx
            mov         ds, ss:[si+6]
            mov         bx, ss:[si+4]
            mov         cx, N_SECTORS@
            mov         dx, START_SECT@
            int         25h
            pop         si
            pop         dx
            pop         cx
            pop         bx
            pop         ds
            jc          @@fault
            pop         si
            ret         4
@@to_packet:
            push        ds
            push        bx
            push        cx
            mov         cx, -1
            mov         bx, ss:[si+4]
            mov         DTA@, bx
            mov         bx, ss:[si+6]
            mov         DTA@[2], bx
            lea         bx, START_SECT@
            push        ss
            pop         ds
            int         25h
            pop         si
            pop         cx
            pop         bx
            pop         ds
            jc          @@fault
            pop         si
            ret         4

@@fault:
            pushf
            cmp         ah, 4
            jnz         @@err_2
            lea         si, SECT_N_FOUND
            mov         cx, SECT_N_FOUND_L
            jmp         short       @@put_err
@@err_2:
            cmp         ah, 8
            jnz         @@err_3
            lea         si, DMA_FAILURE
            mov         cx, DMA_FAILURE_L
            jmp         short       @@put_err
@@err_3:
            cmp         ah, 10h
            jnz         @@err_4
            lea         si, BAD_CRC
            mov         cx, BAD_CRC_L
            jmp         short       @@put_err
@@err_4:
            cmp         ah, 20h
            jnz         @@err_5
            lea         si, CONTR_FAULT
            mov         cx, CONTR_FAULT_L
            jmp         short       @@put_err
@@err_5:
            cmp         ah, 80h
            jnz         @@err_6
            lea         si, DRV_N_READY
            mov         cx, DRV_N_READY_L
            jmp         short       @@put_err
@@err_6:
            lea         si, DSK_ERR
            mov         cx, DSK_ERR_L
@@put_err:
            $STO_SCREEN 2, 22, 77, 22, SCR_ERR_BUF, 3
            gotoxy      4, 22
            mov         bl, ERR_ATTR
            mov         bh, OUR_PAGE
            call        CPUTSTR
            lea         si, PR_ESC
            mov         cx, PR_ESC_L
            call        CPUTSTR
@@err_loop:
            sub         ah, ah
            int         16h
            cmp         ah, 1
            jnz         @@err_loop
            $LOD_SCREEN 2, 22, 77, 22, SCR_ERR_BUF, 3
            popf
            pop         si
            ret         4
            
;----------------------------------------------------------------------------
;                       ERRORS possibly occur upon ABSOLUTE
;                                   DISK read.
;----------------------------------------------------------------------------

DISK_PROTECT_ERR DB     'Cannot access the write protected disk. '
DISK_PROTECT_ERR_L EQU  $-DISK_PROTECT_ERR
SECT_N_FOUND DB         'Cannot find sector. '
SECT_N_FOUND_L EQU      $-SECT_N_FOUND
DMA_FAILURE DB          'DMA fault. '
DMA_FAILURE_L EQU       $-DMA_FAILURE
BAD_CRC     DB          'Data error (bad CRC). '
BAD_CRC_L   EQU         $-BAD_CRC
CONTR_FAULT DB          'Controller fault. '
CONTR_FAULT_L EQU       $-CONTR_FAULT
DSK_ERR     DB          'Uncommon disk error. '
DSK_ERR_L   EQU         $-DSK_ERR
DRV_N_READY DB          'Drive not ready. '
DRV_N_READY_L EQU       $-DRV_N_READY

LOAD_SECT   ENDP



SAVE_SECT   PROC
;locals

;----------------------------------------------------------------------------
;                       saves sector to disk
;                       ss:[si+4] -> offset
;                       ss:[si+6] -> segment (memory to load to)
;----------------------------------------------------------------------------

            push        si
            mov         si, sp
            mov         al, DRIVE@
            cmp         byte ptr DOS_VER, 4
            jnb         @@to_packet
            push        ds
            push        bx
            push        cx
            push        dx
            mov         ds, ss:[si+6]
            mov         bx, ss:[si+4]
            mov         cx, N_SECTORS@
            mov         dx, START_SECT@
            int         26h
            pop         si
            pop         dx
            pop         cx
            pop         bx
            pop         ds
            jc          @@fault
            pop         si
            ret         4
@@to_packet:
            push        ds
            push        bx
            push        cx
            mov         cx, -1
            mov         bx, ss:[si+4]
            mov         DTA@, bx
            mov         bx, ss:[si+6]
            mov         DTA@[2], bx
            lea         bx, START_SECT@
            push        ss
            pop         ds
            int         26h
            pop         si
            pop         cx
            pop         bx
            pop         ds
            jc          @@fault
            pop         si
            ret         4
@@fault:
            pushf
            cmp         ah, 3
            jnz         @@err_2
            lea         si, DISK_PROTECT_ERR
            mov         cx, DISK_PROTECT_ERR_L
            jmp         short       @@put_err
@@err_2:
            cmp         ah, 8
            jnz         @@err_3
            lea         si, DMA_FAILURE
            mov         cx, DMA_FAILURE_L
            jmp         short       @@put_err
@@err_3:
            cmp         ah, 10h
            jnz         @@err_4
            lea         si, BAD_CRC
            mov         cx, BAD_CRC_L
            jmp         short       @@put_err
@@err_4:
            cmp         ah, 20h
            jnz         @@err_5
            lea         si, CONTR_FAULT
            mov         cx, CONTR_FAULT_L
            jmp         short       @@put_err
@@err_5:
            cmp         ah, 80h
            jnz         @@err_6
            lea         si, DRV_N_READY
            mov         cx, DRV_N_READY_L
            jmp         short       @@put_err
@@err_6:
            lea         si, DSK_ERR
            mov         cx, DSK_ERR_L
@@put_err:
            $STO_SCREEN 2, 22, 77, 22, SCR_ERR_BUF, 3
            gotoxy      4, 22
            mov         bl, ERR_ATTR
            mov         bh, OUR_PAGE
            call        CPUTSTR
            lea         si, PR_ESC
            mov         cx, PR_ESC_L
            call        CPUTSTR
@@err_loop:
            sub         ah, ah
            int         16h
            cmp         ah, 1
            jnz         @@err_loop
            $LOD_SCREEN 2, 22, 77, 22, SCR_ERR_BUF, 3
            popf
            pop         si
            ret         4

SAVE_SECT   ENDP



DISK_DUMP   PROC
;locals
            gotoxy      30, 2
            lea         si, SECT_ID
            mov         cx, SECT_ID_L
            mov         bl, TOP_ATTR
            call        CPUTSTR
            lea         si, DUMP_SECT@[3]
            mov         cx, 4
@@addr_loop:
            std
            lods        byte ptr ss:[si]
            call        CPUTHEX2
            loop        @@addr_loop
            test        byte ptr PROG_STATUS[1], 1
            jz          @@n_act
            mov         bl, AC_WIND_ATTR
            jmp         @@go_on
@@n_act:
            mov         bl, ATTRIB
@@go_on:
            mov         dh, 3
            mov         dl, 2
            mov         si, DSK_DUMP_BUF
            add         si, DUMP_OFF@
            mov         cx, 5
@@d_d_loop:
            push        cx
            push        bx
            push        dx

            mov         di, offset LINE_BUFFER
            mov         cx, 38
            mov         ax, '  '
            cld
rep         stosw

            mov         di, offset LINE_BUFFER[1]
            mov         ax, si
            sub         ax, DSK_DUMP_BUF
            and         ax, 511
            mov         cx, 12
            push        cx
            push        di
            call        INT_TO_STR

            mov         bx, offset LINE_BUFFER[6]
            mov         di, offset LINE_BUFFER[59]
            mov         cx, 16
            cld
@@loop_1:
            lodsb
            mov         dx, 4
            push        dx
            push        bx
            call        INT_TO_STR
            or          al, al
            jnz         @@al_nz
            mov         al, ' '
@@al_nz:
            stosb
            inc         bx
            inc         bx
            inc         bx
            
            loop        @@loop_1

            pop         dx
            pop         bx
            GOTOXY      2
            push        si
            mov         si, offset LINE_BUFFER
            mov         cx, 76
            call        CPUTSTR
            pop         si
            pop         cx

            inc         dh
	loop        @@d_d_loop
            ret
DISK_DUMP   ENDP



DISK_UNASS  PROC
;locals
            gotoxy      30, 9
            lea         si, SECT_ID
            mov         cx, SECT_ID_L
            mov         bl, TOP_ATTR
            call        CPUTSTR
            lea         si, UNASS_SECT@[3]
            mov         cx, 4
@@addr_loop:
            std
            lods        byte ptr ss:[si]
            call        CPUTHEX2
            loop        @@addr_loop
            test        byte ptr PROG_STATUS[1], 1
            jnz         @@n_act
            mov         bl, AC_WIND_ATTR
            jmp         short       @@go_on
@@n_act:
            mov         bl, ATTRIB
@@go_on:
            mov         di, DSK_UNASS_BUF
            add         di, UNASS_OFF@
            mov         cx, 13
            mov         dh, 10
@@du_loop:
            push        cx
            push        di

            mov         di, offset LINE_BUFFER
            mov         cx, 76
            mov         al, ' '
            cld
rep         stosb
            mov         di, sp
            mov         di, ss:[di]
            mov         ax, di

            sub         ax, DSK_UNASS_BUF
            and         ax, 511
            mov         cx, 12
            push        cx
            mov         cx, offset LINE_BUFFER[1]
            push        cx
            call        INT_TO_STR

            push        ax
            push        ds
            push        di
            mov         di, TEST_FIELD
            push        di
            sub         al, al
            cld
            mov         cx, 63
rep         stosb
            call        DASS

            mov         cl, ds:[TEST_FIELD]
            sub         ch, ch
            and         cl, cl
	jnz         @F
	inc         cx
@@:
            mov         si, TEST_FIELD+1
            mov         di, offset LINE_BUFFER[8]
            cld
@@loop_1:
            mov         ax, 4
            push        ax
            push        di
            lodsb
            call        INT_TO_STR
            inc         di
            inc         di
            loop        @@loop_1
            
            mov         di, offset LINE_BUFFER[24]
            cmp         byte ptr ds:[TEST_FIELD], 0
            jnz         @@one_op

            mov         ax, word ptr DEF_B
            stosw

            mov         di, offset LINE_BUFFER[33]
            mov         cx, 4
            push        cx
            push        di
            call        INT_TO_STR
            inc         byte ptr ds:[TEST_FIELD]
@@loop_ret:
            GOTOXY      2
            mov         si, offset LINE_BUFFER
            mov         cx, 76
            call        CPUTSTR
            mov         al, ds:[TEST_FIELD]
            cbw
            pop         di
            add         di, ax
            inc         dh
            pop         cx
	loop        @F
	jmp	to__ret
@@:
	jmp	@@du_loop
to__ret:
            ret
;----------------------------------------------------------------------------

@@one_op:
            mov         si, TEST_FIELD+7
            mov         cx, 6
@@loop_2:
            lodsb
            or          al, al
            jz          end_key_loop_2
            stosb
            loop        @@loop_2
end_key_loop_2:
            mov         di, offset LINE_BUFFER[33]
            cmp         byte ptr ds:[TEST_FIELD+41], 0
            jz          @@no_lab
            mov         si, TEST_FIELD+41
            mov         cx, 9
@@loop_3:
            lodsb
            or          al, al
            jz          end_key_loop_3
            stosb
            loop        @@loop_3
end_key_loop_3:
            inc         di
@@no_lab:
            cmp         byte ptr ds:[TEST_FIELD+13], 0
            jz          @@loop_ret
            mov         si, TEST_FIELD+13
            mov         cx, 12
@@loop_4:
            lodsb
            or          al, al
            jz          end_key_loop_4
            stosb
            loop        @@loop_4
end_key_loop_4:

            cmp         byte ptr ds:[TEST_FIELD+25], 0
            jz          @@loop_ret
            mov         ax, ' ,'
            stosw
            mov         si, TEST_FIELD+25
            mov         cx, 12
@@loop_5:
            lodsb
            or          al, al
            jz          end_key_loop_5
            stosb
            loop        @@loop_5
end_key_loop_5:
            cmp         byte ptr ds:[TEST_FIELD+37], 0
            jz          @@loop_ret
            mov         ax, ' ,'
            stosw
            mov         si, TEST_FIELD+37
            mov         cx, 4
@@loop_6:
            lodsb
            or          al, al
            jz          end_key_loop_6
            stosb
            loop        @@loop_6
end_key_loop_6:
            jmp         @@loop_ret

DISK_UNASS  ENDP



SECT_ID     DB          'Sector No. '
SECT_ID_L   EQU         $-SECT_ID
VDISK_TOP   DB          'View/Edit Disk Service'
VDISK_TOP_L EQU         $-VDISK_TOP
VDISK_TTL   DB          'VIEW DISK'
VDISK_TTL_L EQU         $-VDISK_TTL
DRIVE_PROMPT DB         'Input Drive Letter Below:'
DRIVE_PROMPT_L EQU      $-DRIVE_PROMPT
LINE_BUFFER DB          76 DUP (?)

DISK_UP	PROC
;locals
            test        byte ptr PROG_STATUS[1], 1
            jnz         @@dump_up

            mov         si, DSK_UNASS_BUF
            add         si, UNASS_OFF@
            mov         di, si
            sub         si, 7
            mov         ax, si
            sub         ax, DSK_UNASS_BUF
@@chk_sign:
            jns         @@fine
            inc         si
            inc         ax
            jmp         short       @@chk_sign
@@fine:
            mov         cx, 6
@@up_loop:
            push        cx
            cmp         si, DSK_UNASS_BUF
            ja          @@OK
            cmp         UNASS_SECT@, 0
            jnz         @@n_zero
            cmp         UNASS_SECT@[2], 0
            jnz         @@n_zero
            pop         cx
            jmp         short       @@instr_got
@@n_zero:
            sub         UNASS_SECT@, 1
            sbb         UNASS_SECT@[2], 0
            mov         ax, UNASS_SECT@
            mov         START_SECT@, ax
            mov         ax, UNASS_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            push        ax
            call        LOAD_SECT
	jnc         @F
	retn
@@:
            add         si, 512
            add         di, 512
@@OK:
            inc         si
            mov         ax, si
            sub         ax, DSK_UNASS_BUF
            and         ax, 511
            push        di

            push        ax
            push        ds
            push        si
            mov         di, TEST_FIELD
            push        di
            mov         cx, 25
            sub         ax, ax
            cld
rep         stosw
            call        DASS

            pop         di
            mov         al, ds:[TEST_FIELD]
            cbw
            and         ax, ax
	jnz         @F
	inc         ax
@@:
            add         ax, si
            cmp         ax, di
            pop         cx
            jz          @@instr_got
            loop        @@up_loop
            mov         si, di
            dec         si
@@instr_got:
            cmp         si, DSK_UNASS_BUF+512
            jb          @@OK_01
            add         UNASS_SECT@, 1
            adc         UNASS_SECT@[2], 0
            mov         ax, UNASS_SECT@
            mov         START_SECT@, ax
            mov         ax, UNASS_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            push        ax
            call        LOAD_SECT
	jnc         @F
	retn
@@:
            sub         si, 512
@@OK_01:
            sub         si, DSK_UNASS_BUF
            mov         UNASS_OFF@, si
            retn
@@dump_up:
            cmp         DUMP_OFF@, 0
            jnz         @@OK_1
            cmp         DUMP_SECT@, 0
            jnz         @@off_zero
            cmp         DUMP_SECT@[2], 0
            jnz         @@off_zero
            retn
@@off_zero:
            sub         DUMP_SECT@, 1
            sbb         DUMP_SECT@[2], 0
            mov         DUMP_OFF@, 512
            mov         ax, DUMP_SECT@
            mov         START_SECT@, ax
            mov         ax, DUMP_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_DUMP_BUF
            push        ax
            call        LOAD_SECT
            jnc         @@OK_1
            retn
@@OK_1:
            sub         DUMP_OFF@, 10h
	retn
DISK_UP	ENDP


DISK_DOWN	PROC
            test        byte ptr PROG_STATUS[1], 1
            jnz         @@dump_dn
            cmp         UNASS_OFF@, 512
            jb          @@OK_2
            add         UNASS_SECT@, 1
            adc         UNASS_SECT@[2], 0
	mov	ax, UNASS_SECT@[2]
            cmp	ax, TOTAL_SECT[2]
            jb	@@u_sect_OK
	ja	@@u_sect_repl
            mov	ax, TOTAL_SECT
            cmp	ax, UNASS_SECT@
            ja	@@u_sect_OK
@@u_sect_repl:
	jmp	end_key
@@u_sect_OK:
            and         UNASS_OFF@, 511
            mov         ax, UNASS_SECT@
            mov         START_SECT@, ax
            mov         ax, UNASS_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            push        ax
            call        LOAD_SECT
            jnc         @@OK_2
	retn
@@OK_2:
            push        ax
            push        ds
            mov         ax, DSK_UNASS_BUF
            add         ax, UNASS_OFF@
            push        ax
            mov         di, TEST_FIELD
            push        di
            mov         cx, 50
            sub         al, al
            cld
rep         stosb
            call        DASS
            mov         al, ds:[TEST_FIELD]
            and         al, al
	jnz         @F
	inc         ax
@@:
            cbw
            add         UNASS_OFF@, ax
	retn
@@dump_dn:
            cmp         DUMP_OFF@, 512
            jb          @@OK_3

            add         DUMP_SECT@, 1
            adc         DUMP_SECT@[2], 0
	mov	ax, DUMP_SECT@[2]
            cmp	ax, TOTAL_SECT[2]
            jb	@@d_sect_OK
            ja	@@d_sect_repl
            mov	ax, DUMP_SECT@
            cmp	ax, TOTAL_SECT
            jb	@@d_sect_OK
@@d_sect_repl:
	jmp	end_key
@@d_sect_OK:
            sub         DUMP_OFF@, 512
            mov         ax, DUMP_SECT@
            mov         START_SECT@, ax
            mov         ax, DUMP_SECT@[2]
            mov         START_SECT@[2], ax
            push        ds
            mov         ax, DSK_DUMP_BUF
            push        ax
            call        LOAD_SECT
	jnc         @F
	retn
@@:
            jmp         short       @@do_dump
@@OK_3:
            add         DUMP_OFF@, 10h
@@do_dump:
            retn
DISK_DOWN	ENDP