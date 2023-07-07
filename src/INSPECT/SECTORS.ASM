SECTORS     PROC
                        ;[bp+4] -> parameter: 0=read sector, 1=write sector
            push        bp
            mov         bp, sp
            push        bx
            push        dx
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
            mov         ah, 15
            mov         al, 49
            push        ax
            mov         ah, 10
            mov         al, 30
            push        ax
            mov         bl, MENU_ATTR
            call        LITTLE_FRAME
            gotoxy      34, 11
            cmp         byte ptr [bp+4], 0
            jnz         wr_ttl
            lea         si, READ_TTL
            mov         cx, READ_TTL_L
            jmp         short       sects_01
wr_ttl:
            lea         si, WRITE_TTL
            mov         cx, WRITE_TTL_L
sects_01:
            call        CPUTSTR
            gotoxy      32, 12
            lea         si, DUMP_PROMPT1
            mov         cx, DUMP_PROMPT1_L
            call        CPUTSTR
            wherexy
            and         ch, 10011111b
            mov         ah, 1
            int         10h
            gotoxy      40
            call        CGETHEX4                ;memory segment
            jc          sect_ret
            mov         DTA_FAR[2], ax
            gotoxy      32, 13
            lea         si, DUMP_PROMPT2
            mov         cx, DUMP_PROMPT2_L
            call        CPUTSTR
            gotoxy      40
            call        CGETHEX4                ;memory offset
            jc          sect_ret
            mov         DTA_FAR, ax
            gotoxy      32, 14
            lea         si, SECT_PROMPT
            mov         cx, SECT_PROMPT_L
            call        CPUTSTR
            gotoxy      40
            call        CGETLONG16                ;sector num
            jc          sect_ret
            mov         START_SECT, ax
            mov         START_SECT[2], dx
            mov         N_SECTORS, 1
            mov         ah, 19h
            int         21h                     ;get current disk
            mov         cx, -1
            push        bx
            mov         bx, offset START_SECT
            cmp         byte ptr [bp+4], 0
            jnz         wr_sect
            int         25h
            jmp         short       sect_done
wr_sect:
            int         26h
sect_done:
            popf
            pop         bx
sect_ret:
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
            pop         dx
            pop         bx
            pop         bp
            ret         2

            START_SECT  DW          2 DUP (?)
            N_SECTORS   DW          ?
            DTA_FAR     DW          2 DUP (?)

SECTORS     ENDP
