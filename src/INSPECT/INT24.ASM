INT_24      PROC
;locals

;           This procedure will be overwritten onto INT 24
;           handler. The procedure detalizes only disk errors
;           and responds 'DEVICE ERROR' on any other error.

            push        bx
            push        cx
            push        dx
            push        si
            push        ds
            push        es

            push        cs
            push        cs
            pop         ds
            pop         es
	mov         @@i24KEEP_AX, ax
            sti
            $STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            mov         bh, OUR_PAGE
            mov         bl, ERR_ATTR
            WHEREXY
            or          ch, 00100000b
            mov         ah, 1
            int         10h
            GOTOXY      1, 23
            mov         ax, 920h
            mov         cx, 78
            int         10h
	test        byte ptr @@i24KEEP_AX[1], 80h
	jz          @@i24disk_err
	mov         si, offset @@i24DEVICE_ERR
            mov         cx, 20
            call        CPUTSTR
	mov         si, offset @@i24PROMPT
            mov         cx, 20
	jmp         @@i24respond
@@i24disk_err:
            mov         ax, di                  ; AL=error code
            cmp         al, 0
	jnz         @@i24al_2?
	mov         si, offset @@i24WP_DISK
	jmp         @@i24print_err
@@i24al_2?:
            cmp         al, 2
	jnz         @@i24al_4?
	mov         si, offset @@i24N_READY
	jmp         @@i24print_err
@@i24al_4?:
            cmp         al, 4
	jnz         @@i24al_6?
	mov         si, offset @@i24CRC_ERR
	jmp         @@i24print_err
@@i24al_6?:
            cmp         al, 6
	jnz         @@i24al_8?
	mov         si, offset @@i24SEEK_ERR
	jmp         @@i24print_err
@@i24al_8?:
            cmp         al, 8
	jnz         @@i24gen_err
	mov         si, offset @@i24N_FND
	jmp         @@i24print_err
@@i24gen_err:
	mov         si, offset @@i24GEN_FLT
@@i24print_err:
            mov         cx, 30
            call        CPUTSTR
	test        byte ptr @@i24KEEP_AX[1], 1
	jnz         @@i24wr
	mov         si, offset @@i24READ
	jmp         @@i24print_act
@@i24wr:
	mov         si, offset @@i24WRITE
@@i24print_act:
            mov         cx, 8
            call        CPUTSTR

	mov         al, byte ptr @@i24KEEP_AX[1]
            and         al, 00000110b
            cbw
            mov         si, ax
	mov         si, @@i24AREA_ADDR[si]
            mov         cx, 15
            call        CPUTSTR

	mov         al, byte ptr @@i24KEEP_AX
            add         al, 'A'            
	mov         @@i24DRV, al
	mov         si, offset @@i24DRIVE
            mov         cx, 9
            call        CPUTSTR
	mov         si, offset @@i24DRV
            mov         cx, 3
            call        CPUTSTR
@@i24respond:
	mov         si, offset @@i24PROMPT
            mov         cx, 25
            call        CPUTSTR
@@i24loop:
            sub         ah, ah
            int         16h
            cmp         ah, 19                  ;'R'
	jnz         @@i24F?
            mov         al, 1
	jmp         @@i24exit
@@i24F?:
            cmp         ah, 33                  ;'F'
	jnz         @@i24loop
            mov         al, 3
@@i24exit:
            push        ax
            $LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            pop         ax
            pop         es
            pop         ds
            pop         si
            pop         dx
            pop         cx
            pop         bx
            iret


@@i24DOS_AREA  DB          "DOS area ", 0
@@i24FAT_AREA  DB          "FAT ", 0
@@i24DIR_AREA  DB          "directory ", 0
@@i24DAT_AREA  DB          "data area "
@@i24AREA_ADDR DW          offset @@i24DOS_AREA, offset @@i24FAT_AREA
	DW          offset @@i24DIR_AREA, offset @@i24DAT_AREA

@@i24READ      DB          "reading ", 0
@@i24WRITE     DB          "writing ", 0

@@i24DRIVE     DB          "on drive ", 0
@@i24DRV       DB          "X. "

@@i24WP_DISK   DB          "Write-protected disk error ", 0
@@i24N_READY   DB          "Drive not ready ", 0
@@i24CRC_ERR   DB          "CRC error ", 0
@@i24SEEK_ERR  DB          "Seek error ", 0
@@i24N_FND     DB          "Sector not found ", 0
@@i24GEN_FLT   DB          "General failure ", 0

@@i24DEVICE_ERR  DB        "Device error. ", 0
@@i24PROMPT    DB          "Retry or Fail? (R/F)", 0

@@i24KEEP_AX   DW          ?

INT_24      ENDP


