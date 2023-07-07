LOADF_TTL   db          'INPUT FILE'
LOADF_TTL_L equ         $-LOADF_TTL
FILE_PROMPT     db          'Input Name:'
FILE_PROMPT_L   equ         $-FILE_PROMPT

;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

UPCASE                  PROC        
		push        bp
		mov         bp,sp
		push        ax
		push        cx
		push        di
		mov         cx,[bp+4]
		mov         di,[bp+6]
locloop_478:
		mov         al,[di]
		cmp         al,61h                              ; 'a'
		jb          loc_479                             ; Jump if below
		cmp         al,7Ah                              ; 'z'
		ja          loc_479                             ; Jump if above
		sub         al,32                              ; ' '
		mov         [di],al
loc_479:
		inc         di
		loop        locloop_478             ; Loop if cx > 0
		pop         di
		pop         cx
		pop         ax
		pop         bp
		retn        4
UPCASE                  ENDP



;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CHANGE_DIR              PROC
;jumps
;jumps
		mov         di,DIR_BUF
		nop
		mov         cx,64
		xor         al,al                               ; Zero register
		cld                                             ; Clear direction
	rep         stosb                                           ; Rep when cx >0 Store al to es:[di]
		$STO_SCREEN 30, 10, 45, 14, SCREEN_BUF_1, OUR_PAGE
		$LITTLE_FRAME 30, 10, 45, 14, MENU_ATTR
		$STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
		GOTOXY      1, 23
		mov         ax, 920h
		mov         cx, 78
		int         10h
		mov         si, offset @@TELL
		mov         cx, @@TELL_L
		call        CPUTSTR
		mov         di, DIR_BUF
		mov         cx, 63
		sub         al, al
	rep         stosb
		mov         ah, 19h
		int         21h
		push        ax
		GOTOXY      2+@@TELL_L
		add         al, 'A'
		mov         cx, 1
		mov         ah, 9
		int         10h
		GOTOXY      3+@@TELL_L
		mov         ah, 9
		mov         al, ':'
		int         10h
		GOTOXY      4+@@TELL_L
		mov         ah, 9
		mov         al, '\'
		int         10h
		pop         dx
		inc         dx
		GET_CURR_DIR [DIR_BUF]
		mov         si, DIR_BUF
		mov         cx, 64
		GOTOXY      5+@@TELL_L, 23
		call        CPUTSTR
		mov         dh,11
		mov         dl,32                               ; ' '
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		lea         si,DIR_TTL
		mov         cx,DIR_TTL_L
		call        CPUTSTR
		mov         dh,12
		mov         dl,32                               ; ' '
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		lea         si,FILE_PROMPT                      ; ('Input Name:') Load effective addr
		mov         cx,FILE_PROMPT_L
		call        CPUTSTR
		mov         dh,13
		mov         dl,32                              ; ' '
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		mov         ah,32                               ; ' '
		mov         al,43                               ; '+'
		push        ax
		mov         ax,DIR_BUF
		push        ax
		add         ax,3Eh
		push        ax
		mov         ah,3
		int         10h                                 ; Video display   ah=functn 03h
						;  get cursor loc in dx, mode cx
		and         ch,10011111b
		mov         ah,1
		int         10h                                 ; Video display   ah=functn 01h
						;  set cursor mode in cx
		call        CGETSTR
		jc          @@exit
		$LOD_SCREEN 30, 10, 45, 14, SCREEN_BUF_1, OUR_PAGE
		$LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
		mov         ah,3
		int         10h                                 ; Video display   ah=functn 03h
						;  get cursor loc in dx, mode cx
		or          ch,00100000b
		mov         ah,1
		int         10h                                 ; Video display   ah=functn 01h
						;  set cursor mode in cx
		CH_DIR      [DIR_BUF]
		jc          @@fault
		mov         di, DIR_BUF+63
		mov         al, ':'
		mov         cx, 63
		std
	repnz       scasb
		jnz         @@OK
		mov         dl, [di]
		cmp         dl, 'Z'
		ja          $+7
		sub         dl, 'A'
		jmp         short       $+5
		sub         dl, 'a'
		mov         ah, 0Eh
		int         21h                     ;Select disk
@@OK:
		retn
@@fault:
		cmp         ax, 2
		jnz         @@path
		mov         ERRORCODE, 10
		call        ERR_HANDLER
		retn
@@path:
		mov         ERRORCODE, 5
		call        ERR_HANDLER
		retn
@@exit:
		$LOD_SCREEN 30, 10, 45, 14, SCREEN_BUF_1, OUR_PAGE
                        $LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
		WHEREXY
		or          ch, 00100000b
		mov         ah, 1
		int         10h
		retn

DIR_TTL     db          "CHANGE DIR"
DIR_TTL_L   equ         $-DIR_TTL
@@TELL      DB          "Current dir is: "
@@TELL_L    EQU         $-@@TELL
CHANGE_DIR              ENDP


