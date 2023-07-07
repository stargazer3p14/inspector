REGISTERS   PROC
;locals
                        ; output user registers
            push        bp
            mov         bp, sp
            dec         sp
            push        ax
            push        bx
            push        cx
            push        dx
            push        si
            push        di
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2
            int	33h
@@mouse_OK1:
            mov         bl, byte ptr PROG_STATUS[1]
            and         bl, 3
            cmp         bl, 2
            jnz         @@n_act
            mov         ah, 7
            mov         al, 59
            push        ax
            mov         ah, 15
            mov         al, 78
            push        ax
            mov         ah, OUR_PAGE
            mov         al, AC_WIND_ATTR
            push        ax
            call        CHANGE_ATTRIBS
            mov         bl, AC_WIND_ATTR
            jmp         short       _regs_00
@@n_act:
            mov         bl, ATTRIB
            mov         ah, 7
            mov         al, 59
            push        ax
            mov         ah, 15
            mov         al, 78
            push        ax
            mov         ah, OUR_PAGE
            mov         al, ATTRIB
            push        ax
            call        CHANGE_ATTRIBS
_regs_00:
            mov         bh, OUR_PAGE
            cld
            lea         si, REGISTS
            mov         cx, N_REGS
            mov         dh, 7
            mov         dl, 60
            mov         byte ptr [bp-1], 60
regs_loop_1:
            push        cx
            mov         cx, 2
            gotoxy      [bp-1]
            call        cputstr
            inc         si
            inc         si
            push        cx
            mov         al, '='
            mov         cx, 1
            mov         ah, 9
            int         10h
            pop         cx
            cmp         dh, 12
            jz          regs_01
            inc         dh
            mov         dl, 60
            jmp         short       regs_02
regs_01:
            mov         byte ptr [bp-1], 70
            mov         dh, 7
regs_02:
            pop         cx
            loop        regs_loop_1
            lea         si, USER_REGS
            mov         dh, 7
            mov         dl, 63
            mov         cx, N_REGS
            mov         byte ptr [bp-1], 63
regs_loop_2:
            push        cx
            gotoxy      [bp-1]
            lodsw
            call        cputhex4
            cmp         dh, 12
            jz          regs_03
            inc         dh
            jmp         short       regs_04
regs_03:
            mov         dh, 7
            mov         byte ptr [bp-1], 73
regs_04:
            pop         cx
            loop        regs_loop_2
            gotoxy      65, 13                  ; output IP
            lea         si, REGISTS[(N_REGS) SHL 1]
            mov         cx, 2
            call        cputstr
            mov         al, '='
            mov         cx, 1
            mov         ah, 9
            int         10h
            wherexy
            inc         dx
            gotoxy
            mov         ax, USER_IP
            call        cputhex4
            mov         ax, 1
            xor         di, di            
            mov         dh, 14
            mov         dl, 60
            call        OUTPUT_FLAGS
            shl         ax, 1
            shl         ax, 1
            call        OUTPUT_FLAGS
            shl         ax, 1
            shl         ax, 1
            call        OUTPUT_FLAGS
            shl         ax, 1
            shl         ax, 1
            call        OUTPUT_FLAGS
            shl         ax, 1
            call        OUTPUT_FLAGS
            shl         ax, 1
            shl         ax, 1
            call        OUTPUT_FLAGS
            shl         ax, 1
            call        OUTPUT_FLAGS
            shl         ax, 1
            call        OUTPUT_FLAGS
	cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1
            int	33h
@@mouse_OK2:
            pop         di
            pop         si
            pop         dx
            pop         cx
            pop         bx
            pop         ax
            inc         sp
            mov         bp, sp
            pop         bp
            ret


OUTPUT_FLAGS  PROC
            push        ax
            push        cx
            test        ax, USER_FL
            jnz         fl_set
            lea         si, FLAG_N_SET[di]
            jmp         short       out_fl_01
fl_set:
            lea         si, FLAG_SET[di]
out_fl_01:
            mov         cx, 2
            gotoxy
            call        cputstr
            inc         di
            inc         di
            cmp         dl, 76
            jnb         out_fl_02
            inc         dx
            inc         dx
            inc         dx
            inc         dx
            jmp         short       out_fl_03
out_fl_02:
            inc         dh
            mov         dl, 60
out_fl_03:
            pop         cx
            pop         ax
            ret
OUTPUT_FLAGS  ENDP


REGISTS     DB          'AX', 'BX', 'CX', 'DX', 'BP', 'SP', 'SI', 'DI'
            DB          'CS', 'DS', 'ES', 'SS', 'IP'
FLAG_SET    DB          'CY', 'PE', 'AC', 'ZR', 'NG', 'EI', 'DN', 'OV'
FLAG_N_SET  DB          'NC', 'PO', 'NA', 'NZ', 'PL', 'DI', 'UP', 'NV'
USER_REGS   EQU         $
USER_AX     DW          0
USER_BX     DW          0
USER_CX     DW          0
USER_DX     DW          0
USER_BP     DW          0
USER_SP     DW          0FFFEh
USER_SI     DW          0
USER_DI     DW          0
USER_CS     DW          0
USER_DS     DW          0
USER_ES     DW          0
USER_SS     DW          0
N_REGS      EQU         ($-USER_REGS) SHR 1
USER_IP     DW          100h
USER_FL     DW          7202h

REGISTERS   ENDP
