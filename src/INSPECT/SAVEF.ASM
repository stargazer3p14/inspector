SAVE        PROC
;locals
;jumps
;----------------------------------------------------------------------------
;           Gets (if n. got) file name and saves file
;----------------------------------------------------------------------------
@@sfOK:
	$STO_SCREEN 20, 10, 28+@@sfOFFS_L, 15, SCREEN_BUF_1, OUR_PAGE
	$LITTLE_FRAME 20, 10, 28+@@sfOFFS_L, 15, MENU_ATTR
            mov         bl, MENU_ATTR
            gotoxy      29, 11
	mov         si, offset @@sfTTL
	mov         cx, @@sfTTL_L
            call        CPUTSTR
            gotoxy      22, 12
	mov         si, offset @@sfNAME
	mov         cx, @@sfNAME_L
            call        CPUTSTR
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
	gotoxy      22+@@sfNAME_L
            test        byte ptr PROG_STATUS, 8
	jz          @@sfget_name
            mov         si, offset LD_MODULE
            mov         cx, 12
            call        CPUTSTR
	jmp         @@sfname_OK
@@sfget_name:
	mov         ah, 22+@@sfNAME_L
	mov         al, 22+@@sfOFFS_L
            push        ax
            mov         di, FILE_NAME
            push        di
            sub         al, al
            mov         cx, 63
            cld
rep         stosb
            dec         di
            push        di
            call        CGETSTR
	jc          @@sfexit
	jcxz        @@sfexit
	jmp         @@sfname_OK
@@sfexit:
            and         PROG_STATUS, 7FFFh
	$LOD_SCREEN 20, 10, 28+@@sfOFFS_L, 15, SCREEN_BUF_1, OUR_PAGE
            wherexy
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            ret
@@sfname_OK:
            gotoxy      22, 13
	mov         si, offset @@sfLEN
	mov         cx, @@sfLEN_L
            call        CPUTSTR
	gotoxy      22+@@sfLEN_L
            call        CGETHEX4
	jc          @@sfexit
	mov         @@sfFILE_LEN, ax
            gotoxy      22, 14
	mov         si, offset @@sfOFFS
	mov         cx, @@sfOFFS_L
            call        CPUTSTR
	gotoxy      22+@@sfOFFS_L
            call        CGETHEX4
	jnc         @@sfoff_OK
            cmp         ah, 1
	jz          @@sfexit
            mov         ax, 100h
            call        CPUTHEX4
@@sfoff_OK:
	mov         @@sfFILE_OFF, ax
            QCREATE     [FILE_NAME], 0
	jc          @@sferror
            mov         bx, ax
	mov         cx, @@sfFILE_LEN
	mov         dx, @@sfFILE_OFF
            mov         ds, UNASS_SEG
            mov         ah, 40h
            int         21h
            push        cs
            pop         ds
            mov	ah, 3Eh			; Close file
            int	21h
            test        byte ptr PROG_STATUS, 8             ; Program loaded?
	jnz         @@sfexit                              ; Yes - cancel
            mov         bh, OUR_PAGE
            mov         di, FILE_NAME
            mov         al, '\'
            mov         cx, 63
            cld
repnz       scasb
	jz          @@sfhere
            mov         di, FILE_NAME
            cmp         byte ptr ds:[FILE_NAME+1], ':'
	jnz         @@sfhere
            inc         di
            inc         di
@@sfhere:
            mov         cx, 12
            mov         si, di
            mov         di, offset LD_MODULE
            cld
@@sfloop:
            lodsb
            and         al, al
	jnz         @@sfwell
            mov         al, ' '
@@sfwell:
            stosb
	loop        @@sfloop
            or          byte ptr PROG_STATUS, 00111000b
            gotoxy      64, 24
            mov         si, offset LD_MODULE
            mov         cx, 12
            mov         bl, TOP_ATTR
            call        CPUTSTR
	jmp         @@sfexit
@@sferror:
            mov         ERRORCODE, 7
            call        ERR_HANDLER
	jmp         @@sfexit
            


@@sfTTL       DB          'SAVE FILE'
@@sfTTL_L     EQU         $-@@sfTTL
@@sfNAME      DB          'Input Name: '
@@sfNAME_L    EQU         $-@@sfNAME
@@sfLEN       DB          'Input File Length: '
@@sfLEN_L     EQU         $-@@sfLEN
@@sfOFFS      DB          'Input Start Offset: '
@@sfOFFS_L    EQU         $-@@sfOFFS

@@sfFILE_LEN  DW          ?
@@sfFILE_OFF  DW          ?

SAVE        ENDP
