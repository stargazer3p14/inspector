;---------------------------------------------------------------------
;           This procedure receives offset ([bp+10] for effective
;           ADDRess, Segment ([bp+8]) & Offset([bp+6])
;           of the memory to unassemble, offset ([bp+4]) of the
;           50-byte unassemble field (set 0)
;---------------------------------------------------------------------
DASS        PROC
;locals
            jmp         __start@
            NO_OPER     DB          'AAA', 'AAD', 'AAM', 'AAS'          ;12
                        DB          'CBW', 'CLC', 'CLD', 'CLI'          ;24
                        DB          'CMC', 'CWD', 'DAA'                 ;33
                        DB          'DAS', 'HLT', 'IRET', 'LAHF'        ;47
                        DB          'LOCK', 'LODSB', 'LODSW', 'MOVSB'   ;66
                        DB          'MOVSW', 'NOP', 'SCASB', 'SCASW'    ;84
                        DB          'STOSB', 'STOSW', 'STC', 'STD'      ;100
                        DB          'STI', 'WAIT', 'XLAT', 'PUSHF'      ;116
                        DB          'POPF', 'RET', 'INTO', 'INT 3'      ;132
                        DB          'RETF', 'SAHF', 'CMPSB', 'CMPSW'    ;150
                        DB          'REPZ', 'REPNZ'
            ONE_OPER    DB          'INC', 'DEC', 'PUSH', 'POP', 0, 'INT' 
            ARITHS      DB          'ADD', 'OR', 0, 'ADC', 'SBB'        ;12
                        DB          'AND', 'SUB', 'XOR', 'CMP'          ;24
            ARITH1      DB          2 DUP ('TEST'), 'NOT', 0, 'NEG', 0
                        DB          'MUL', 0, 'IMUL', 'DIV', 0, 'IDIV'
            TWO_OPERS   DB          'TEST', 'XCHG', 'MOV'               ;11
                        DB          'LEA', 'LDS', 'LES'                 ;20
                        DB          'IN', 'OUT'                         ;25
            __JUMPS__   DB          'JMP', 'JCXZ', 'CALL', 'LOOPNZ', 'LOOPZ', 0 ;23
                        DB          'LOOP', 0, 0, 'JO', 0, 'JNO', 'JB', 0 ;38
                        DB          'JNB', 'JZ', 0, 'JNZ', 'JBE', 'JA', 0 ;46
                        DB          'JS', 0, 'JNS', 'JPE', 'JPO'        ;58
                        DB          'JL', 0, 'JGE', 'JLE', 'JG', 0      ;70
            LOGICS      DB          'ROL', 'ROR', 'RCL', 'RCR'          ;12
                        DB          'SHL', 'SHR', 'SAL', 'SAR'          ;24
            _ESC        DB          'ESC'
            INSTR_87_0  DB          'ADD', 0, 'MUL', 0, 'COM', 0 
                        DB          'COMP', 'SUB', 0, 'SUBR', 'DIV', 0, 'DIVR'
            INSTR_87_1  DB          'LD', 8 DUP (0), 'ST', 3 DUP (0), 'STP', 0, 0
                        DB          'LDENV', 'LDCW', 0, 'STENV', 'STCW', 0
            REGIST_87   DB          'ST( )'
            INSTR_186   DB          'INSB', 0, 'INSW', 0, 'OUTSB', 'OUTSW';20
                        DB          'PUSHA', 'POPA', 0
                        DB          'ENTER', 'LEAVE', 'BOUND'
            INSTR_286   DB          'SGDT', 'SIDT', 'LGDT', 'LIDT'      ;16
                        DB          'SMSW', 'LMSW'                      ;24
                        DB          'SLDT', 'STR', 0, 'LLDT', 'LTR', 0  ;40
                        DB          'VERR', 'VERW'                      ;48
                        DB          'LAR', 0, 'LSL', 0                  ;56
                        DB          'CTS'                               ;59
                        DB          'ARPL'
            REGIST_8    DB          'AL', 'CL', 'DL', 'BL', 'AH', 'CH'
                        DB          'DH', 'BH'
            REGIST_16   DB          'AX', 'CX', 'DX', 'BX', 'SP', 'BP'
                        DB          'SI', 'DI'
            SEG_REGS    DB          'ES', 'CS', 'SS', 'DS'
            STRANGE     DB          '???'
	_ADDR        DB          '[BX+SI]'
	_ADDR_L      EQU         $-_ADDR
		DB          '[BX+DI]', '[BP+SI]', '[BP+DI]'
                        DB          '[SI]', 0, 0, 0, '[DI]',0, 0, 0, '[    ]', 0,  '[BX]', 0, 0, 0
	_ADDR1       DB          '[BX+SI+    ]'
	_ADDR1_L     EQU         $-_ADDR1
		DB          '[BX+DI+    ]'
                        DB          '[BP+SI+    ]', '[BP+DI+    ]'
                        DB          '[SI+    ]', 0, 0, 0, '[DI+    ]', 0, 0, 0, '[BP+    ]', 0, 0, 0
                        DB          '[BX+    ]', 0, 0, 0
            LABELS      DB          'FAR', 'SHORT', 'BYTE PTR', 'WORD PTR'
            LABELS_87   DB          'DWORD PTR', 'QWORD PTR'
__start@:
            push        bp                      ; stack initialization
            mov         bp, sp                  ; for procedure
            push        es
            push        ax
            push        bx
            push        cx                      ; save destroyed registers
            push        si
            push        di
            mov         es, [bp+8]
            mov         bx, [bp+6]              ; ES:BX->source bytes
            mov         di, [bp+4]              ; DS:DI->destination table
	mov         VAR_FIELD, 0       	; Internal flag
            mov         al, es:[bx]             ; al=instruction code
            cmp         al, 37h                 ; aaa ?
            jnz         _aas
            lea         si, NO_OPER
            mov         cx, 3
no_operand_ret:
            mov         byte ptr [di], 1
return:
            cld
            push        ds
            pop         es
            push        di
            add         di, 7
            rep         movsb
            pop         di
            push        ds
            xor         ch, ch
            mov         cl, [di]
            mov         si, bx
            inc         di
            mov         ds, [bp+8]
            rep         movsb
            pop         ds
return_1:
            pop         di
            pop         si
            pop         cx
            pop         bx
            pop         ax
            pop         es
            mov         sp, bp
            pop         bp
            ret         8
_aas:
            cmp         al, 3Fh
            jnz         _cbw
            lea         si, NO_OPER[9]
            mov         cx, 3
            jmp         short       no_operand_ret
_cbw:
            cmp         al, 98h
            jnz         _clc
            lea         si, NO_OPER[12]
            mov         cx, 3
            jmp         short       no_operand_ret
_clc:
            cmp         al, 0F8h
            jnz         _cld
            lea         si, NO_OPER[15]
            mov         cx, 3
            jmp         short       no_operand_ret
_cld:
            cmp         al, 0FCh
            jnz         _cli
            lea         si, NO_OPER[18]
            mov         cx, 3
            jmp         short       no_operand_ret
_cli:
            cmp         al, 0FAh
            jnz         _cmc
            lea         si, NO_OPER[21]
            mov         cx, 3
            jmp         short       no_operand_ret
_cmc:
            cmp         al, 0F5h
            jnz         _cwd
            lea         si, NO_OPER[24]
            mov         cx, 3
            jmp         short       no_operand_ret
_cwd:
            cmp         al, 99h
            jnz         _daa
            lea         si, NO_OPER[27]
            mov         cx, 3
            jmp         no_operand_ret
_daa:
            cmp         al, 27h
            jnz         _das
            lea         si, NO_OPER[30]
            mov         cx, 3
            jmp         no_operand_ret
_das:
            cmp         al, 2Fh
            jnz         _hlt
            lea         si, NO_OPER[33]
            mov         cx, 3
            jmp         no_operand_ret
_hlt:
            cmp         al, 0F4h
            jnz         _iret
            lea         si, NO_OPER[36]
            mov         cx, 3
            jmp         no_operand_ret
_iret:
            cmp         al, 0CFh
            jnz         _lahf
            lea         si, NO_OPER[39]
            mov         cx, 4
            jmp         no_operand_ret
_lahf:
            cmp         al, 9Fh
            jnz         _lock_
            lea         si, NO_OPER[43]
            mov         cx, 4
            jmp         no_operand_ret
_lock_:
            cmp         al, 0F0h
            jnz         _lodsb
            lea         si, NO_OPER[47]
            mov         cx, 4
            jmp         no_operand_ret
_lodsb:
            cmp         al, 0ACh
            jnz         _lodsw
            lea         si, NO_OPER[51]
            mov         cx, 5
            jmp         no_operand_ret
_lodsw:
            cmp         al, 0ADh
            jnz         _movsb
            lea         si, NO_OPER[56]
            mov         cx, 5
            jmp         no_operand_ret
_movsb:
            cmp         al, 0A4h
            jnz         _movsw
            lea         si, NO_OPER[61]
            mov         cx, 5
            jmp         no_operand_ret
_movsw:
            cmp         al, 0A5h
            jnz         _nop
            lea         si, NO_OPER[66]
            mov         cx, 5
            jmp         no_operand_ret
_nop:
            cmp         al, 90h
            jnz         _scasb
            lea         si, NO_OPER[71]
            mov         cx, 3
            jmp         no_operand_ret
_scasb:
            cmp         al, 0AEh
            jnz         _scasw
            lea         si, NO_OPER[74]
            mov         cx, 5
            jmp         no_operand_ret
_scasw:
            cmp         al, 0AFh
            jnz         _stosb
            lea         si, NO_OPER[79]
            mov         cx, 5
            jmp         no_operand_ret
_stosb:
            cmp         al, 0AAh
            jnz         _stosw
            lea         si, NO_OPER[84]
            mov         cx, 5
            jmp         no_operand_ret
_stosw:
            cmp         al, 0ABh
            jnz         _stc
            lea         si, NO_OPER[89]
            mov         cx, 5
            jmp         no_operand_ret
_stc:
            cmp         al, 0F9h
            jnz         _std
            lea         si, NO_OPER[94]
            mov         cx, 3
            jmp         no_operand_ret
_std:
            cmp         al, 0FDh
            jnz         _sti
            lea         si, NO_OPER[97]
            mov         cx, 3
            jmp         no_operand_ret
_sti:
            cmp         al, 0FBh
            jnz         _wait
            lea         si, NO_OPER[100]
            mov         cx, 3
            jmp         no_operand_ret
_wait:
            cmp         al, 9Bh
            jnz         _xlat
            lea         si, NO_OPER[103]
            mov         cx, 4
            jmp         no_operand_ret
_xlat:
            cmp         al, 0D7h
            jnz         _pushf
            lea         si, NO_OPER[107]
            mov         cx, 4
            jmp         no_operand_ret
_pushf:
            cmp         al, 9Ch
            jnz         _popf
            lea         si, NO_OPER[111]
            mov         cx, 5
            jmp         no_operand_ret
_popf:
            cmp         al, 9Dh
            jnz         _ret
            lea         si, NO_OPER[116]
            mov         cx, 4
            jmp         no_operand_ret
_ret:
            cmp         al, 0C3h
            jnz         _into
            lea         si, NO_OPER[120]
            mov         cx, 3
            jmp         no_operand_ret
_into:
            cmp         al, 0CEh
            jnz         _int_3
            lea         si, NO_OPER[123]
            mov         cx, 4
            jmp         no_operand_ret
_int_3:
            cmp         al, 0CCh
            jnz         _retf
            lea         si, NO_OPER[127]
            mov         cx, 5
            jmp         no_operand_ret
_retf:
            cmp         al, 0CBh
            jnz         _sahf
            lea         si, NO_OPER[132]
            mov         cx, 4
            jmp         no_operand_ret
_sahf:
            cmp         al, 9Eh
            jnz         _cmpsb
            lea         si, NO_OPER[136]
            mov         cx, 4
            jmp         no_operand_ret
_cmpsb:
            cmp         al, 0A6h
            jnz         _cmpsw
            lea         si, NO_OPER[140]
            mov         cx, 5
            jmp         no_operand_ret
_cmpsw:
            cmp         al, 0A7h
            jnz         _repz
            lea         si, NO_OPER[145]
            mov         cx, 5
            jmp         no_operand_ret
_repz:
            cmp         al, 0F3h
            jnz         _repnz
            lea         si, NO_OPER[150]
            mov         cx, 4
            jmp         no_operand_ret
_repnz:
            cmp         al, 0F2h
            jnz         _aad
            lea         si, NO_OPER[154]
            mov         cx, 5
            jmp         no_operand_ret
_aad:
            cmp         al, 0D5h
            jnz         _aam
            lea         si, NO_OPER[3]
_aad_aam_ret:
            mov         byte ptr [di], 2
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 7
            push        ax
            mov         al, es:[bx+1]
            call        INT_TO_STR
            mov         cx, 3
            jmp         return
_aam:
            cmp         al, 0D4h
            jnz         _ret_n
            lea         si, NO_OPER[6]
            jmp         short       _aad_aam_ret
_ret_n:
            cmp         al, 0C2h
            jnz         _retf_n
            lea         si, NO_OPER[120]
            mov         cx, 3
_ret_n_ret:
            mov         byte ptr [di], 3
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            jmp         return
_retf_n:
            cmp         al, 0CAh
            jnz         _int
            lea         si, NO_OPER[132]
            mov         cx, 4
            jmp         short       _ret_n_ret
_int:
            cmp         al, 0CDh
            jnz         _xchg_AX
            mov         byte ptr [di], 2
            mov         [di+1], al
            mov         al, es:[bx+1]
            mov         [di+2], al
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         al, es:[bx+1]
            call        INT_TO_STR
            lea         si, ONE_OPER[14]
            mov         cx, 3
            jmp         return
_xchg_AX:
            cmp         al, 91h
            jb          _mov_immed
            cmp         al, 97h
            ja          _mov_immed
            mov         byte ptr [di], 1
            mov         byte ptr [di+1], al
            and         al, 7
            cbw
            shl         ax, 1
            mov         si, ax
            mov         ax, word ptr REGIST_16[si]
            mov         [di+13], ax
            mov         ax, word ptr REGIST_16
            mov         [di+25], ax
            lea         si, TWO_OPERS[4]
            mov         cx, 4
            jmp         return
_mov_immed:
            cmp         al, 0B0h
            jb          _mov_mem_value
            cmp         al, 0C0h
            jnb         _mov_mem_value
            mov         byte ptr [di], 2
            test        al, 8
            jnz         mi_1
            mov         ax, 4
            jmp         short       mi_2
mi_1:
            inc         byte ptr [di]
            mov         ax, 12
mi_2:       
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            mov         al, es:[bx]
            and         ax, 0Fh
            shl         ax, 1
            cbw
            lea         si, REGIST_8
            add         si, ax
            lodsw
            mov         [di+13], ax
mov_ret:
            lea         si, TWO_OPERS[8]
            mov         cx, 3
            jmp         return
_mov_mem_value:
            cmp         al, 0C6h
            jb          _mov_AX_mem
            cmp         al, 0C7h
            ja          _mov_AX_mem
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            cmp         byte ptr es:[bx+1], 0C0h
            jnb         @@@no_label
            test        byte ptr es:[bx], 1
            jnz         _mmv_1
            lea         si, LABELS[8]
            jmp         short       _mmv_2
_mmv_1:
            lea         si, LABELS[16]
_mmv_2:
            mov         cx, 8
            push        es
            push        ds
            pop         es
            push        di
            add         di, 41
            cld
            rep         movsb                   ; set labels
            pop         di
            pop         es
@@@no_label:
            test        byte ptr es:[bx], 1
            jnz         _mmv_3
            mov         ax, 4
            jmp         short       _mmv_4
_mmv_3:
            mov         ax, 12
_mmv_4:
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         al, [di]
            cbw
            mov         si, ax
            mov         ax, es:[bx+si]
            call        INT_TO_STR
            inc         byte ptr [di]
            test        byte ptr es:[bx], 1
            jz          _mmv_5
            inc         byte ptr [di]
_mmv_5:
            jmp         mov_ret
_mov_AX_mem:
            cmp         al, 0A0h
            jb          _mov_mod
            cmp         al, 0A3h
            ja          _mov_mod
            push	es:[bx+1]
	pop	word ptr VAR_ADDR[2]
            mov	VAR_FIELD, -1
            test	al, 1
            jnz	_is_set
            dec	VAR_FIELD
_is_set:
            mov         byte ptr [di], 3
            test        al, 2
            jnz         _to_mem
            test        al, 1
            jz          _to_AL
            mov         ax, word ptr REGIST_16  ;mov AX, []
            jmp         short       _m_AX_00
_to_AL:
            mov         ax, word ptr REGIST_8   ;mov AL, []
_m_AX_00:
            mov         [di+13], ax
            mov         byte ptr [di+25], '['
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 26
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
	mov         byte ptr [di+30], ']'
	mov	VAR_ADDR[1], 6
            jmp         mov_ret
_to_mem:
            test        al, 1
            jz          _from_AL
            mov         ax, word ptr REGIST_16  ;mov [], AX
            jmp         short       _m_AX_01
_from_AL:
            mov         ax, word ptr REGIST_8   ;mov [], AL
_m_AX_01:
            mov         [di+25], ax
            mov         byte ptr [di+13], '['
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 14
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            mov         byte ptr [di+18], ']'
            jmp         mov_ret
_mov_mod:
            cmp         al, 88h
            jb          _mov_seg
            cmp         al, 8Bh
            ja          _mov_seg
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            test        byte ptr es:[bx], 2
            jnz         _mm_1
            add         ax, 13
            jmp         short       _mm_2
_mm_1:
            add         ax, 25
_mm_2:
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            test        byte ptr es:[bx], 1
            jnz         _mm_3
            add         si, offset REGIST_8
            jmp         short       _mm_4
_mm_3:
            add         si, offset REGIST_16
_mm_4:
            lodsw
            test        byte ptr es:[bx], 2
            jnz         _mm_5
            mov         [di+25], ax
            jmp         short       _mm_6
_mm_5:
            mov         [di+13], ax
_mm_6:
            jmp         mov_ret
_mov_seg:
            cmp         al, 8Ch
            jz          _ms_00
            cmp         al, 8Eh
            jnz         _lea
_ms_00:
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            test        byte ptr es:[bx], 2
            jnz         _ms_10
            add         ax, 13
            push        ax
            or          byte ptr es:[bx], 1
            call        MEM_REG_MOD
            and         byte ptr es:[bx], 0FEh
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 3
            cbw
            mov         si, ax
            shl         si, 1
            add         si, offset SEG_REGS
            lodsw
            mov         [di+25], ax
            jmp         short       _ms_11
_ms_10:
            add         ax, 25
            push        ax
            or          byte ptr es:[bx], 1
            call        MEM_REG_MOD
            and         byte ptr es:[bx], 0FEh
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 3
            cbw
            mov         si, ax
            shl         si, 1
            add         si, offset SEG_REGS
            lodsw
            mov         [di+13], ax
_ms_11:
            jmp         mov_ret
_lea:
            cmp         al, 8Dh
            jnz         _pop_16
            mov         byte ptr [di], 2
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            add         si, offset REGIST_16
            lodsw
            mov         [di+13], ax
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            cmp         byte ptr es:[bx+1], 0C0h
            jb          _lea_ret
            lea         si, STRANGE
            cld
            lodsw
            mov         [di+25], ax
            lodsb
            mov         [di+27], al
_lea_ret:
            lea         si, TWO_OPERS[11]
            mov         cx, 3
            jmp         return
_pop_16:
            cmp         al, 8Fh
            jnz         _arith_immed
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            lea         si, ONE_OPER[10]
            mov         cx, 3
            jmp         return
_arith_immed:
            cmp         al, 80h
            jb          below_40
            cmp         al, 83h
            ja          below_40
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            mov         al, [di]
            cbw
            mov         si, ax
            inc         byte ptr [di]
            test        byte ptr es:[bx], 1
            jz          _am_1
            inc         byte ptr [di]
            mov         ax, 12
            jmp         short       _am_2
_am_1:
            mov         ax, 4
_am_2:
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         ax, es:[bx+si]
            cmp         byte ptr es:[bx], 83h
            jnz	_am_2a
            cbw
            dec	byte ptr [di]
_am_2a:
            call        INT_TO_STR
            cmp         byte ptr es:[bx+1], 0C0h
            jnb         _arith_OK
            test        byte ptr es:[bx], 1
            jnz         _am_3
            lea         si, LABELS[8]
            jmp         short       _arith_ret
_am_3:
            lea         si, LABELS[16]
_arith_ret:
            mov         cx, 8
            push        di
            add         di, 41
            cld
            push        es
            push        ds
            pop         es
            rep         movsb
            pop         es
            pop         di
_arith_OK:
            call        SAI
            jmp         return
below_40:
            cmp         al, 40h
            jb          b_40_0
            jmp         _push_pop
b_40_0:
            and         al, 7
            cmp         al, 6
            jb          b_40_00
            jmp         _segs
b_40_00:
            cmp         al, 4
            jnb         _arith_AX
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         al, es:[bx]
            test        al, 2
            jnz         _b40_1
            mov         ax, 13
            jmp         short       _b40_10
_b40_1:
            mov         ax, 25
_b40_10:
            add         ax, di
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            test        byte ptr es:[bx], 1
            jnz         _b40_2
            add         si, offset REGIST_8
            jmp         short       _b40_3
_b40_2:
            add         si, offset REGIST_16
_b40_3:
            lodsw
            test        byte ptr es:[bx], 2
            jnz         _b40_11
            mov         [di+25], ax
            jmp         short       _b40_12
_b40_11:
            mov         [di+13], ax
_b40_12:
            call        SAI
            jmp         return
_arith_AX:
            mov         byte ptr [di], 2
            test        byte ptr es:[bx], 1
            jnz         _aa_1
            mov         ax, 4
            push        ax
            mov         ax, word ptr REGIST_8
            jmp         short       _aa_2
_aa_1:
            inc         byte ptr [di]
            mov         ax, 12
            push        ax
            mov         ax, word ptr REGIST_16
_aa_2:
            mov         [di+13], ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            jmp         short       _b40_12
_segs:
            cmp         byte ptr es:[bx], 0Fh
            jz          _push_pop
            mov         byte ptr [di], 1
            mov         al, es:[bx]
            mov         cl, 3
            shr         al, cl
            and         al, 3
            cbw
            mov         si, ax
            shl         si, 1
            add         si, offset SEG_REGS
            lodsw
            test        byte ptr es:[bx], 20h
            jnz         _assume
            mov         [di+13], ax
            test        byte ptr es:[bx], 1
            jnz         _push
            lea         si, ONE_OPER[6]
            mov         cx, 4
            jmp         return
_push:
            lea         si, ONE_OPER[10]
            mov         cx, 4
            jmp         return
_assume:
            mov         [di+7], ax
            mov         al, es:[bx]
            mov         [di+1], al
            mov         byte ptr [di+9], ':'
            jmp         return_1
_push_pop:
            mov         al, es:[bx]
            cmp         al, 50h
            jb          _inc_dec@
            cmp         al, 5Fh
            ja          _inc_dec@
            mov         byte ptr [di], 1
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            add         si, offset REGIST_16
            lodsw
            mov         [di+13], ax
            test        byte ptr es:[bx], 8
            jnz         _pp_1
            lea         si, ONE_OPER[6]
            jmp         short       _pp_2
_pp_1:
            lea         si, ONE_OPER[10]
_pp_2:
            mov         cx, 4
            jmp         return
_inc_dec@:
            cmp         al, 4Fh
            ja          _test
            cmp         al, 0Fh
            jnz         _inc_dec
            jmp         _i286_0a
_inc_dec:
            mov         byte ptr [di], 1
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            add         si, offset REGIST_16
            lodsw
            mov         [di+13], ax
            test        byte ptr es:[bx], 8
            jnz         _id_1
            lea         si, ONE_OPER
            jmp         short       _id_2
_id_1:
            lea         si, ONE_OPER[3]
_id_2:
            mov         cx, 3
            jmp         return
_test:
            cmp         al, 84h
            jb          _xchg
            cmp         al, 85h
            ja          _xchg
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            test        byte ptr es:[bx], 1
            jnz         _test_1
            add         si, offset REGIST_8
            jmp         short       _test_2
_test_1:
            add         si, offset REGIST_16
_test_2:
            lodsw
            mov         [di+13], ax
            lea         si, TWO_OPERS
            mov         cx, 4
            jmp         return
_xchg:
            cmp         al, 86h
            jb          _test_AX
            cmp         al, 87h
            ja          _test_AX
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            test        byte ptr es:[bx], 1
            jnz         _xchg_1
            add         si, offset REGIST_8
            jmp         short       _xchg_2
_xchg_1:
            add         si, offset REGIST_16
_xchg_2:
            lodsw
            mov         [di+13], ax
            lea         si, TWO_OPERS[4]
            mov         cx, 4
            jmp         return
_test_AX:
            cmp         al, 0A8h
            jb          _arith2
            cmp         al, 0A9h
            ja          _arith2
            mov         byte ptr [di], 2
            test        byte ptr es:[bx], 1
            jnz         _tAX_1
            mov         ax, 4
            lea         si, REGIST_8
            jmp         short       _tAX_2
_tAX_1:
            inc         byte ptr [di]
            mov         ax, 12
            lea         si, REGIST_16
_tAX_2:
            push        ax
            lodsw
            mov         [di+13], ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            lea         si, TWO_OPERS
            mov         cx, 4
            jmp         return
_arith2:
            cmp         al, 0F6h
            jb          ___JUMPS__
            cmp         al, 0F7h
            ja          ___JUMPS__
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            cmp	byte ptr es:[bx+1], 0C0h
            jnb	_ar2_nolabel
            test	byte ptr es:[bx], 1
            jnz	_ar2_word
            mov	si, offset LABELS[8]
            jmp	_ar2_labcopy
_ar2_word:
	mov	si, offset LABELS[16]
_ar2_labcopy:
	push	es
	push	di
            push	ds
            pop	es
            add	di, 41
            mov	cx, 8
rep	movsb
	pop	di
            pop	es
_ar2_nolabel:
            mov         al, es:[bx+1]
            and         al, 3Fh
            cmp         al, 10h
            jnb         _ar2_10
            mov         al, [di]
            inc         byte ptr [di]
            cbw
            mov         si, ax
            test        byte ptr es:[bx], 1
            jnz         _ar2_1
            mov         ax, 4
            jmp         short       _ar2_2
_ar2_1:
            inc         byte ptr [di]
            mov         ax, 12
_ar2_2:
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         ax, es:[bx+si]
            call        INT_TO_STR
_ar2_10:
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            shl         si, 1
            add         si, offset ARITH1
            mov         cx, 4
            jmp         return
___JUMPS__:
            cmp         al, 70h
            jb          _jmp
            cmp         al, 7Fh
            jna         ___JUMPS___00
            cmp         al, 0E3h
            jz          ___JUMPS___00
            cmp         al, 0EBh
            jnz         _jmp
___JUMPS___00:
            mov         byte ptr [di], 2
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         al, es:[bx+1]
            cbw
            add         ax, [bp+10]
            inc         ax
            inc         ax
            call        INT_TO_STR
            cmp         byte ptr es:[bx], 0EBh
            jnz         ___JUMPS___01
            lea         si, LABELS[3]
            mov         cx, 5
            push        di
            add         di, 41
            cld
            push        es
            push        ds
            pop         es
            rep         movsb
            pop         es
            pop         di
            lea         si, __JUMPS__
            mov         cx, 3
            jmp         return
___JUMPS___01:
            cmp         byte ptr es:[bx], 0E3h
            jnz         ___JUMPS___02
            lea         si, __JUMPS__[3]
            mov         cx, 4
            jmp         return
___JUMPS___02:
            mov         al, es:[bx]
            and         al, 0Fh
            cbw
            mov         si, ax
            shl         si, 1
            add         si, ax
            add         si, offset __JUMPS__[29]
            mov         cx, 3
            jmp         return
_jmp:
            cmp         al, 0E9h
            jz          _jmp_00
            cmp         al, 0E8h
            jz          _call_00
            cmp         al, 0EAh
            jz          _far_
            cmp         al, 9Ah
            jz          _far_
            jmp         _loop
_jmp_00:
            lea         si, __JUMPS__
            mov         cx, 3
_jmp_call:
            mov         byte ptr [di], 3
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         ax, es:[bx+1]
            add         ax, [bp+10]
            add         ax, 3
            call        INT_TO_STR
            jmp         return
_call_00:
            lea         si, __JUMPS__[7]
            mov         cx, 4
            jmp         short       _jmp_call
_far_:
            mov         byte ptr [di], 5
            lea         si, LABELS
            mov         cx, 3
            push        di
            add         di, 41
            cld
            push        es
            push        ds
            pop         es
            rep         movsb
            pop         es
            pop         di
            cmp         byte ptr es:[bx], 9Ah
            jnz         _far_1
            lea         si, __JUMPS__[7]
            mov         cx, 4
            jmp         short       _far_2
_far_1:
            lea         si, __JUMPS__
            mov         cx, 3
_far_2:
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         ax, es:[bx+3]
            call        INT_TO_STR
            mov         byte ptr [di+17], ':'
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 18
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            jmp         return
_loop:
            cmp         al, 0E0h
            jb          _io
            cmp         al, 0E2h
            ja          _io
            mov         byte ptr [di], 2
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         al, es:[bx+1]
            cbw
            add         ax, 2
            add         ax, bx
            call        INT_TO_STR
            mov         al, es:[bx]
            and         al, 3
            cbw
            mov         cl, 6
            mul         cl
            mov         si, ax
            add         si, offset __JUMPS__[11]
            mov         cx, 6
            jmp         return
_io:
            cmp         al, 0E4h
            jnb         _io_0
            jmp         _logics
_io_0:
            cmp         al, 0E8h
            jb          _io_00
            cmp         al, 0ECh
            jb          _logics
            cmp         al, 0EFh
            ja          _logics
_io_00:
            mov         byte ptr [di], 1
            test        al, 2
            jnz         _out
            test        al, 1
            jnz         _in_AX
            mov         ax, word ptr REGIST_8
            jmp         short       _io_01
_in_AX:
            mov         ax, word ptr REGIST_16
_io_01:
            mov         [di+13], ax
            test        byte ptr es:[bx], 8
            jnz         _in__DX
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         al, es:[bx+1]
            call        INT_TO_STR
            inc         byte ptr [di]
_in_ret:
            lea         si, TWO_OPERS[20]
            mov         cx, 2
            jmp         return
_in__DX:
            mov         ax, word ptr REGIST_16[4]
            mov         [di+25], ax
            jmp         short       _in_ret
_out:
            test        byte ptr es:[bx], 1
            jnz         _out_AX
            mov         ax, word ptr REGIST_8
            jmp         short       _out_01
_out_AX:
            mov         ax, word ptr REGIST_16
_out_01:
            mov         [di+25], ax
            test        byte ptr es:[bx], 8
            jnz         _out__DX
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         al, es:[bx+1]
            call        INT_TO_STR
            inc         byte ptr [di]
_out_ret:
            lea         si, TWO_OPERS[22]
            mov         cx, 3
            jmp         return
_out__DX:
            mov         ax, word ptr REGIST_16[4]
            mov         [di+13], ax
            jmp         short       _out_ret
_logics:
            cmp         al, 0D0h
            jb          _ff_
            cmp         al, 0D3h
            ja          _ff_
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            test        byte ptr es:[bx], 2
            jnz         _logic_CL
            mov         al, '1'
            mov         [di+25], al
            jmp         short       _sel_logic
_logic_CL:
            mov         ax, word ptr REGIST_8[2]
            mov         [di+25], ax
_sel_logic:
            cmp         byte ptr es:[bx+1], 0C0h
            jnb         @@no_label
            test        byte ptr es:[bx], 1
            jz          @@byte
            lea         si, LABELS[8]
            jmp         short       @@lab
@@byte:
            lea         si, LABELS[16]
@@lab:
            mov         ax, di
            add         di, 41
            mov         cx, 8
            cld
rep         movsb
            mov         di, ax
@@no_label:
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         cl, al
            add         al, al
            add         al, cl
            mov         si, ax
            add         si, offset LOGICS
            mov         cx, 3
            jmp         return
_ff_:
            cmp         al, 0FEh
            jnb         $+5
            jmp         _lxs
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            test        byte ptr es:[bx], 1
            jnz         _ff_0
            jmp         _fe_
_ff_0:
            mov         al, es:[bx+1]
            cmp         al, 0D0h
            jb          _ff_01
            test        al, 8
            jnz         _ff_01
            lea         si, STRANGE
            mov         cx, 3
            jmp         return
_ff_01:
            cmp         al, 0C0h
            and         al, 3Fh
            cmp         al, 10h
            jnb         _ff_10
            cmp         byte ptr es:[bx+1], 0C0h
            jnb         _ff_01a
            lea         si, LABELS[16]
            mov         cx, 8
            push        di
            add         di, 41
            cld
            push        es
            push        ds
            pop         es
rep         movsb                               ; word ptr
            pop         es
            pop         di
_ff_01a:
            test        byte ptr es:[bx+1], 8
            jnz         _ff_dec
            lea         si, ONE_OPER
            jmp         short       _ff_02
_ff_dec:
            lea         si, ONE_OPER[3]
_ff_02:
            mov         cx, 3
            jmp         return
_ff_10:
            cmp         al, 30h
            jnb         _ff_30
            test        al, 8
            jz          _ff_11
            lea         si, LABELS
            mov         cx, 3
            push        di
            push        es
            push        ds
            pop         es
            add         di, 41
            rep         movsb                   ; far
            pop         es
            pop         di
            mov	VAR_FIELD, -3
_ff_11:
            test        al, 20h
            jnz         _ff_jmp
            lea         si, __JUMPS__[7]
            mov         cx, 4
            jmp         return
_ff_jmp:
            lea         si, __JUMPS__
            mov         cx, 3
            jmp         return
_ff_30:
            test        al, 8
            jz          _ff_30_n
            lea         si, STRANGE
            mov         cx, 3
            jmp         return
_ff_30_n:
            lea         si, LABELS[16]
            mov         cx, 8
            push        di
            add         di, 41
            push        es
            push        ds
            pop         es
            cld
            rep         movsb
            pop         es
            pop         di
            lea         si, ONE_OPER[6]
            mov         cx, 4
            jmp         return
_fe_:
            mov         al, es:[bx+1]
            and         al, 3Fh
            cmp         al, 10h
            jb          _fe_norm
            lea	si, STRANGE
            mov	cx, 3
            jmp	return
_fe_norm:
            cmp         byte ptr es:[bx+1], 0C0h
            jnb         _fe_ret
            lea         si, LABELS[8]
            mov         cx, 8
            push        di
            add         di, 41
            push        es
            push        ds
            pop         es
            cld
rep         movsb                               ; byte ptr
            pop         es
            pop         di
_fe_ret:
            test        al, 8
            jnz         _fe_dec
            lea         si, ONE_OPER
            jmp         short       _fe_@
_fe_dec:
            lea         si, ONE_OPER[3]
_fe_@:
            mov         cx, 3
            jmp         return
_lxs:
            cmp         al, 0C4h
            jb          _instr_87@
            cmp         al, 0C5h
            ja          _instr_87@
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         si, ax
            shl         si, 1
            mov         ax, word ptr REGIST_16[si]
            mov         [di+13], ax
            cmp         byte ptr es:[bx+1], 0C0h
            jb          _lxs_n
            lea         si, STRANGE
            mov         cx, 3                   ; LXS Reg, Reg - 
            jmp         return                  ; invalid
_lxs_n:
            test        byte ptr es:[bx], 1
            jnz         _lds
            lea         si, TWO_OPERS[17]
            jmp         short       _lxs_ret
_lds:
            lea         si, TWO_OPERS[14]
_lxs_ret:
            mov         cx, 3
            jmp         return
_instr_87@:
            cmp         al, 0D8h
            jnb         _i87_00
            jmp         _instr_186@
            cmp         al, 0C0h
_i87_00:
            jna         _i87_0
            jmp         _instr_186@
_i87_0:
            mov         byte ptr [di], 2
            cmp         byte ptr es:[bx+1], 8
            jnz         _87@
            test        al, 1
            jz          _87@
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            mov         al, es:[bx+1]
            call        INT_TO_STR
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            lea         si, _ESC
            mov         cx, 3
            jmp         return
_87@:
            cmp         byte ptr es:[bx+1], 0C0h
            jb          _i87_10
            mov         al, es:[bx+1]
            cmp         al, 10h
            jb          _i87_1
            cmp         al, 20h
            jnb         _i87_1
            lea         si, REGIST_87
            mov         cx, 5
            push        es
            push        di
            add         di, 13
            push        ds
            pop         es
            cld
            rep         movsb
            pop         di
            pop         es
            mov         al, es:[bx+1]
            and         al, 7
            add         al, '0'
            mov         [di+16], al
            jmp         short       _i87_20
_i87_1:
            mov         ax, 'ST'
            mov         [di+13], ax
            lea         si, REGIST_87
            mov         cx, 5
            push        es
            push        di
            add         di, 25
            push        ds
            pop         es
            cld
            rep         movsb
            pop         di
            pop         es
            mov         al, es:[bx+1]
            and         al, 7
            add         al, '0'
            mov         [di+28], al
            jmp         short       _i87_20
_i87_10:
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            test        byte ptr es:[bx], 4
            jnz         _qword
            lea         si, LABELS_87
            jmp         short       _lab_87
_qword:
            lea         si, LABELS_87[9]
_lab_87:
            mov         cx, 9
            push        es
            push        di
            push        ds
            pop         es
            add         di, 41
            cld
            rep         movsb
            pop         di
            pop         es
_i87_20:
            push        di
            xor         ch, ch
            mov         cl, [di]
            xor         si, si
            inc         di
_i87_loop:
            mov         al, es:[bx+si]
            mov         [di], al
            inc         si
            inc         di
            loop        _i87_loop
            pop         di
            add         di, 7
            cld
            test        byte ptr es:[bx], 2
            jnz         _i87_21
            mov         byte ptr [di], 'F'
            inc         di
            jmp         short       _i87_put_instr
_i87_21:
            mov         word ptr [di], 'FI'
            inc         di
            inc         di
_i87_put_instr:
            test        byte ptr es:[bx], 1
            jnz         _i87_22
            lea         si, INSTR_87_0
            jmp         short       _i87_23
_i87_22:
            lea         si, INSTR_87_1
_i87_23:
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         cl, 4
            mul         cl
            add         si, ax
            mov         cx, 4
            push        ds
            pop         es
            cld
rep         movsb
            jmp         return_1
_instr_186@:
            cmp         al, 6Ch
            jb          _push_pop_a
            cmp         al, 70h
            jnb         _push_pop_a
            lea         si, INSTR_186
_i186_1:
            and         al, 3
            mov         cl, 5
            mul         cl
            add         si, ax
            mov         byte ptr [di], 1
            mov         cx, 5
            jmp         return
_push_pop_a:
            cmp         al, 60h
            jb          _imul_186
            cmp         al, 61h
            ja          _imul_186
            mov         byte ptr [di], 1
            lea         si, INSTR_186[20]
            jmp         short       _i186_1
_imul_186:            
            cmp         al, 69h
            mov         byte ptr [di], 2
            jnz         _imul_186_byte
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            shl         ax, 1
            lea         si, REGIST_16
            add         si, ax
            lodsw
            mov         [di+13], ax
            mov         al, [di]
            cbw
            mov         si, ax
            mov         ax, 12
            push        ax
            mov         ax, di
            add         ax, 37
            push        ax
            mov         ax, es:[bx+si]
            call        INT_TO_STR
            lea         si, ARITH1[20]
            mov         cx, 4
            add         byte ptr [di], 2
            jmp         return
_imul_186_byte:
            cmp         al, 6Bh
            jnz         _logic_186
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            dec         byte ptr es:[bx]
            call        MEM_REG_MOD
            inc         byte ptr es:[bx]
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            lea         si, REGIST_8
            shl         ax, 1
            add         si, ax
            lodsw
            mov         [di+13], ax
            mov         al, [di]
            cbw
            mov         si, ax
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 37
            push        ax
            mov         al, es:[bx+si]
            call        INT_TO_STR
            lea         si, ARITH1[20]
            mov         cx, 4
            inc         byte ptr [di]
            jmp         return
_logic_186:
            cmp         al, 0C0h
            jb          __push
_l186_0:
            cmp         al, 0C1h
            ja          __push
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            cmp         byte ptr es:[bx+1], 0C0h
            jnb         _l186_2
            test        byte ptr es:[bx], 1
            jnz         _l186_wd
            lea         si, LABELS[8]
            jmp         short       _move_lab
_l186_wd:
            lea         si, LABELS[16]
_move_lab:
            mov         cx, 8
            push        di
            cld
_move_lab_l:
            lodsb
            mov         [di+41], al
            inc         di
            loop        _move_lab_l
            pop         di
_l186_2:
            mov         al, [di]
            cbw
            mov         si, ax
            mov         ax, 4
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            mov         al, es:[bx+si]
            call        INT_TO_STR
            inc         byte ptr [di]
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            mov         cl, al
            shl         al, 1
	add         al, cl
	cbw
	lea         si, LOGICS
	add         si, ax
	mov         cx, 3
	jmp         return
__push:
	cmp	al, 6Ah
	jnz	__push_wo?
	mov	byte ptr [di], 2
	mov	ax, 12
	push	ax
	mov	ax, di
	add	ax, 13
	push	ax
	mov	al, es:[bx+1]
	sub	ah, ah
	jmp	__workout_push
__push_wo?:
	cmp         al, 68h
	jnz         _enter
	mov         byte ptr [di], 3
	mov         ax, 12
	push        ax
	mov         ax, di
	add         ax, 13
	push        ax
	mov         ax, es:[bx+1]
__workout_push:
	call        INT_TO_STR
	lea         si, ONE_OPER[6]
	mov         cx, 4
	jmp         return
_enter:
	cmp         al, 0C8h
	jnz         _leave
	mov         byte ptr [di], 4
	mov         ax, 12
	push        ax
	mov         ax, di
	add         ax, 13
	push        ax
	mov         ax, es:[bx+1]
	call        INT_TO_STR
	mov         ax, 4
	push        ax
	mov         ax, di
	add         ax, 25
	push        ax
	mov         ax, es:[bx+3]
	call        INT_TO_STR
	lea         si, INSTR_186[30]
	mov         cx, 5
	jmp         return
_leave:
	cmp         al, 0C9h
	jnz         _bound
	mov         byte ptr [di], 1
	lea         si, INSTR_186[35]
	mov         cx, 5
	jmp         return
_bound:
            cmp         al, 62h
            jnz         _instr_286@
            mov         byte ptr [di], 2
            cmp         byte ptr es:[bx+1], 0C0h
            jb          _bound_n
            lea         si, STRANGE
            cld
            lodsw
            mov         [di+25], ax
            lodsb
            mov         [di+27], al
            jmp         short       _bound_01
_bound_n:
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
_bound_01:
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            shl         ax, 1
            mov         si, ax
            mov         ax, word ptr REGIST_16[si]
            mov         [di+13], ax
            lea         si, INSTR_186[40]
            mov         cx, 5
            jmp         return
_instr_286@:
            cmp         al, 63h
            jnz         _instr_286
            mov         byte ptr [di], 2
            mov         ax, 1
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+1]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            shl         ax, 1
            mov         si, ax
            mov         ax, word ptr REGIST_16[si]
            mov         [di+25], ax
            lea         si, INSTR_286[59]
            mov         cx, 4
            jmp         return
_instr_286:
            cmp         al, 0Fh
            jz          _i286_0a
            jmp         _db
_i286_0a:
            mov         byte ptr [di], 3
            mov         al, es:[bx+1]
            cmp         al, 0
            jnz         _i286_10
            mov         al, es:[bx+2]
            and         al, 3Fh
            cmp         al, 30h
            jb          _i286_0b
            jmp         _db
_i286_0b:
            cmp         al, 8
            jb          _i286_0c
            cmp         al, 20h
            jnb         _i286_0c
            cmp         al, 10h
            jb          _i286_02
            cmp         al, 18h
            jnb         _i286_02
_i286_0c:
            cmp         byte ptr es:[bx+2], 0C0h
            jb          _i286_02
_i286_01:
            lea         si, STRANGE
            cld
            lodsw
            mov         [di+13], ax
            lodsb
            mov         [di+15], al
            jmp         _i286_05
_i286_02:
            cmp         byte ptr es:[bx+2], 0C0h
            jb          _i286_04
            mov         al, es:[bx+2]
            and         al, 7
            cbw
            shl         ax, 1
            mov         si, ax
            add         si, offset REGIST_16
            lodsw
            mov         [di+13], ax
            jmp         short       _i286_05
_i286_04:
            mov         ax, 2
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
_i286_05:
            mov         al, es:[bx+2]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            shl         ax, 1
            shl         ax, 1
            lea         si, INSTR_286[24]
            add         si, ax
            mov         cx, 4
            jmp         return
_i286_10:
            cmp         al, 1
            jnz         _lar
            mov	al, es:[bx+2]
            and         al, 3Fh
            cmp         al, 20h
            jnb         _msw
            cmp         byte ptr es:[bx+2], 0C0h
            jb          _i286_1c
            jmp         _db
_i286_1c:
            mov         ax, 2
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+2]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            shl         ax, 1
            shl         ax, 1
            lea         si, INSTR_286
            add         si, ax
            mov         cx, 4
            jmp         return
_msw:
            test        al, 8
            jnz         _db
            mov         ax, 2
            push        ax
            mov         ax, di
            add         ax, 13
            push        ax
            call        MEM_REG_MOD
            mov         al, es:[bx+2]
            mov         cl, 4
            shr         al, cl
            and         al, 1
            cbw
            shl         ax, 1
            shl         ax, 1
            lea         si, INSTR_286[16]
            add         si, ax
            mov         cx, 4
            jmp         return
_lar:
            cmp         al, 3
            ja          _db
            mov         ax, 2
            push        ax
            mov         ax, di
            add         ax, 25
            push        ax
            call        MEM_REG_MOD
            lea         si, REGIST_16
            mov         al, es:[bx+2]
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            shl         ax, 1
            add         si, ax
            lodsw
            mov         [di+13], ax
            test        byte ptr es:[bx], 1
            jnz         _lsl
            lea         si, INSTR_286[48]
            jmp         short       _i286_ret
_lsl:
            lea         si, INSTR_286[52]
_i286_ret:
            mov         cx, 3
            jmp         return
_db:
            mov         byte ptr [di], 0
            mov         al, es:[bx]
            mov         [di+1], al
            jmp         return_1
DASS        ENDP




;-------------------------------------------------
;           This subroutine converts the value of
;           AX or AL to string got in parameters
;-------------------------------------------------
INT_TO_STR PROC
            push        bp
            mov         bp, sp
            push        ax
            push        bx
            push        cx
            push        si
            mov         bx, [bp+4]
            mov         si, [bp+6]
            shr         si, 1
            shr         si, 1
            xor         cx, cx
sts_0:
            shr         ax, cl
            and         al, 0Fh
            cmp         al, 10
            jnb         sts_1
            add         al, '0'
            jmp         short       sts_2
sts_1:
            add         al, ('A'-10)
sts_2:
            mov         [bx+si], al
            mov         ax, [bp-2]
            dec         si
            add         cl, 4
            cmp         cl, [bp+6]
            jna         sts_0
            pop         si
            pop         cx
            pop         bx
            pop         ax
            mov         sp, bp
            pop         bp
            ret         4
INT_TO_STR ENDP



;----------------------------------------------------
;           This subroutine is to consider a correct 
;           register/memory mode according to INTEL
;           _ADDRessing system
;----------------------------------------------------
MEM_REG_MOD PROC
            push        bp
            mov         bp, sp
            push        ax
            push        bx
            push        si
            push        di
            cld
            clc
            mov         VAR_FIELD, -1               ; Internal flag
            add         bx, [bp+6]
            mov         al, es:[bx]
            cmp         al, 40h
            jnb         above_40
	mov         VAR_ADDR[1], al             ; Internal buffer
	lea         si, _ADDR
            mov         di, [bp+4]
	mov         cx, _ADDR_L
            and         al, 7
            mul         cl
            add         si, ax
            push        es
            push        ds
            pop         es
            rep         movsb
            pop         es
            pop         di
            mov         al, es:[bx]
            and         al, 7
            cmp         al, 6
            jnz         mrm_ret

            push        es:[bx+1]
	pop         word ptr VAR_ADDR[2]        ; Internal var

            mov         ax, 12
            push        ax
            mov         ax, [bp+4]
            inc         ax
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            add         byte ptr [di], 2
mrm_ret:
            pop         si
            pop         bx
            pop         ax
            mov         sp, bp
            pop         bp
            ret         4
above_40:
            cmp         al, 80h
            jnb         above_80
            push        es:[bx]
	pop         word ptr VAR_ADDR[1]        ; Internal var
	lea         si, _ADDR1
            mov         di, [bp+4]
	mov         cx, _ADDR1_L
            and         al, 7
            mul         cl
            add         si, ax
            push        es
            push        ds
            pop         es
            rep         movsb
            pop         es
            mov         ax, 12
            push        ax
            mov         al, es:[bx]
            and         al, 7
            cmp         al, 4
            jnb         mrm_1
            mov         ax, 7
            jmp         short       mrm_2
mrm_1:
            mov         ax, 4
mrm_2:
            add         ax, [bp+4]
            push        ax
            mov         al, es:[bx+1]
            cbw
            call        INT_TO_STR
            pop         di
            inc         byte ptr [di]
            jmp         short       mrm_ret
above_80:
            cmp         al, 0C0h
            jnb         above_C0
	mov         VAR_ADDR[1], al             ; Internal var
            push        es:[bx+1]
	pop         word ptr VAR_ADDR[2]        ; Internal var
	lea         si, _ADDR1
            mov         di, [bp+4]
	mov         cx, _ADDR1_L
            and         al, 7
            mul         cl
            add         si, ax
            push        es
            push        ds
            pop         es
            rep         movsb
            pop         es
            mov         ax, 12
            push        ax
            mov         al, es:[bx]
            and         al, 7
            cmp         al, 4
            jnb         mrm_3
            mov         ax, 7
            jmp         short       mrm_4
mrm_3:
            mov         ax, 4
mrm_4:
            add         ax, [bp+4]
            push        ax
            mov         ax, es:[bx+1]
            call        INT_TO_STR
            pop         di
            add         byte ptr [di], 2
            jmp         mrm_ret
above_C0:
            mov         VAR_FIELD, 0
            and         al, 7
            cbw
            shl         ax, 1
            mov         si, ax
            test        byte ptr es:[bx-1], 1
            jnz         mrm_5
            add         si, offset REGIST_8
            jmp         short       mrm_6
mrm_5:
            add         si, offset REGIST_16
mrm_6:
            lodsw
            mov         di, [bp+4]
            mov         [di], ax
            stc
            pop         di
            jmp         mrm_ret
MEM_REG_MOD ENDP




;---------------------------------------------------------------
;           Selects Arithmetic Instruction                     
;---------------------------------------------------------------
SAI         PROC
            lea         si, ARITHS
            cmp         byte ptr es:[bx], 40h
            jnb         _SAI_1
            mov         al, es:[bx]
            jmp         short       _SAI_2
_SAI_1:
            mov         al, es:[bx+1]
_SAI_2:
            mov         cl, 3
            shr         al, cl
            and         al, 7
            cbw
            mov         cx, ax
            shl         ax, 1
            add         ax, cx
            add         si, ax
            mov         cx, 3
            ret
SAI         ENDP


DASS_LEN    EQU         $-DASS
