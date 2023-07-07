__STACK__   PROC
                        ; output stack
            push        es
            push        ax
            push        bx
            push        cx
            push        dx
            push        si
            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2
            int	33h
@@mouse_OK1:
            mov         bl, byte ptr PROG_STATUS[1]
            and         bl, 3
            cmp         bl, 3
            jnz         $+8
            mov         bl, AC_WIND_ATTR
            jmp         short       $+6
            mov         bl, ATTRIB
            mov         bh, OUR_PAGE
            mov         ch, 17
            mov         cl, 59
            mov         dh, 23
            mov         dl, 78
            push        bx
            mov         bh, bl
            mov         ax, 600h
            int         10h
            pop         bx
            mov         cx, 7
            mov         si, STACK_OFFS
            mov         es, USER_SS
            mov         dh, 17
_st_loop_1:
            cmp         si, USER_BP
            jnz         _st_01
            push        si
            push        cx
            gotoxy      74
            lea         si, STACK_BASE
            mov         cx, 3
            call        cputstr
            pop         cx
            pop         si
_st_01:
            gotoxy      60
            mov         al, 'S'
            push        cx
            mov         cx, 2
            mov         ah, 9
            int         10h
            inc         dx
            inc         dx
            gotoxy
            mov         al, ':'
            dec         cx
            mov         ah, 9
            int         10h
            pop         cx
            inc         dx
            gotoxy
            mov         ax, si
            call        cputhex4
            add         dl, 6
            gotoxy
            std
            lods        word ptr es:[si]
            call        CPUTHEX4
            inc         si
            inc         si
            cmp         si, USER_SP
            jnz         _st_02
            mov         dl, 59
            push        dx
            mov         dl, 78
            push        dx
            mov         al, SELECT_ATTR
            mov         ah, OUR_PAGE
            push        ax
            call        CHANGE_ATTRIBS
_st_02:
	cmp	si, STACK_PTR
            jnz	_st_03
            mov         dl, 59
            push        dx
            mov         dl, 78
            push        dx
            mov         al, UNASS_PTR_ATTR
            mov         ah, OUR_PAGE
            push        ax
            call        CHANGE_ATTRIBS
_st_03:
            dec         si
            dec         si
            inc         dh
            dec         cx
            jcxz        _st_100
            jmp         _st_loop_1
_st_100:
	cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1
	int	33h
@@mouse_OK2:
            pop         si
            pop         dx
            pop         cx
            pop         bx
            pop         ax
            pop         es
            ret
STACK_OFFS  DW          0FFFEh
STACK_BASE  DB          '<--'
STACK_PTR	DW	0FFFEh
__STACK__   ENDP
