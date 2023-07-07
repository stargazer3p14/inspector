
;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

STO_SCREEN              PROC        
		push        bp
		mov         bp,sp
		push        ax
		push        cx
		push        dx
		push        si
		push        di

                        cmp	MOUSE_STAT, 0
                        jz	@@mouse_OK1
                        mov	ax, 2		; hide mouse
                        int	33h
@@mouse_OK1:
		mov         cl,[bp+7]
		sub         cl,[bp+9]
		xor         ch,ch                               ; Zero register
		inc         cx
		mov         al,[bp+4]
		cbw                                             ; Convrt byte to word
		mov         dx,1000h
		mul         dx                                  ; dx:ax = reg * ax
		mov         si,ax
		mov         al,[bp+9]
		cbw                                             ; Convrt byte to word
		mov         dx,0A0h
		mul         dx                                  ; dx:ax = reg * ax
		add         si,ax
		mov         al,[bp+8]
		shl         al,1                                ; Shift w/zeros fill
		cbw                                             ; Convrt byte to word
		add         si,ax
		push        ds
		mov         ds,VTEXT_BUFFER
		mov         al,[bp+8]
		xor         ah,ah                               ; Zero register
		add         al,50h                              ; 'P'
		sub         al,[bp+6]
		dec         ax
		shl         ax,1                                ; Shift w/zeros fill
		mov         di,[bp+0Ah]
		mov         dl,[bp+6]
		sub         dl,[bp+8]
		xor         dh,dh                               ; Zero register
		inc         dx
		shl         dx,1                                ; Shift w/zeros fill
		cld                                             ; Clear direction

locloop_129:
		push        cx
		mov         cx,dx
		rep         movsb                               ; Rep when cx >0 Mov [si] to es:[di]
		pop         cx
		add         si,ax
		loop        locloop_129             ; Loop if cx > 0

		pop         ds

                        cmp	MOUSE_STAT, 0
                        jz	@@mouse_OK2
                        mov	ax, 1                   ; display mouse
                        int	33h
@@mouse_OK2:
		pop         di
		pop         si
		pop         dx
		pop         cx
		pop         ax
		mov         sp,bp
		pop         bp
		retn        8
STO_SCREEN              ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

LOD_SCREEN              PROC
;locals
		push        bp
		mov         bp,sp
		push        ax
		push        cx
		push        dx
		push        si
		push        di
                        cmp	MOUSE_STAT, 0
                        jz	@@mouse_OK1
                        mov	ax, 2
                        int	33h
@@mouse_OK1:
		push        es
		cld                                             ; Clear direction
		mov         cl,[bp+7]
		sub         cl,[bp+9]
		xor         ch,ch                               ; Zero register
		inc         cx
		mov         al,[bp+4]
		cbw                                             ; Convrt byte to word
		mov         dx,1000h
		mul         dx                                  ; dx:ax = reg * ax
		mov         di,ax
		mov         al,[bp+9]
		cbw                                             ; Convrt byte to word
		mov         dx,0A0h
		mul         dx                                  ; dx:ax = reg * ax
		add         di,ax
		mov         al,[bp+8]
		cbw                                             ; Convrt byte to word
		shl         al,1                                ; Shift w/zeros fill
		add         di,ax
		mov         es,VTEXT_BUFFER
		mov         al,[bp+8]
		xor         ah,ah                               ; Zero register
		add         al,50h                              ; 'P'
		sub         al,[bp+6]
		dec         ax
		shl         ax,1                                ; Shift w/zeros fill
		mov         si,[bp+0Ah]
		mov         dl,[bp+6]
		sub         dl,[bp+8]
		xor         dh,dh                               ; Zero register
		inc         dx
		shl         dx,1                                ; Shift w/zeros fill

locloop_130:
		push        cx
		mov         cx,dx
		rep         movsb                               ; Rep when cx >0 Mov [si] to es:[di]
		pop         cx
		add         di,ax
		loop        locloop_130             ; Loop if cx > 0

		pop         es
		cmp	MOUSE_STAT, 0
                        jz	@@mouse_OK2
                        mov	ax, 1		; display mouse
                        int	33h
@@mouse_OK2:
		pop         di
		pop         si
		pop         dx
		pop         cx
		pop         ax
		mov         sp,bp
		pop         bp
		retn        8
LOD_SCREEN              ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CGETHEX4                PROC 
;jumps
		
		or          PROG_STATUS, 8000h
		push        cx
		push        si
		push        di
		push        bp
		mov         bp,sp
		sub         si,si                               ; Zero register
		mov         ax,3030h
		push        ax
		push        ax
		mov         di,0FFFFh
		WHEREXY
loc_131:
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		call	GETCH			; Keyboard i/o  ah=function 00h
						;  get keybd char in al, ah=scan
		cmp         al,0Dh
		jne         loc_134                             ; Jump if not equal
		cmp         di,0FFFFh
		jne         loc_132                             ; Jump if not equal
		stc                                             ; Set carry flag
		jmp         loc_133
loc_132:
		call        CG_CONV
		call        CG_NUM
		mov         sp,bp
		pop         bp
		pop         di
		pop         si
		pop         cx
		
		and         PROG_STATUS, 7FFFh
		clc                                             ; Clear carry flag
		retn
loc_133:
		mov         sp,bp
		pop         bp
		pop         di
		pop         si
		pop         cx
		
		and         PROG_STATUS, 7FFFh
		stc
		retn
loc_134:
		cmp         al,1Bh
		jne         loc_135                             ; Jump if not equal
		stc                                             ; Set carry flag
		jmp         loc_133
loc_135:
		cmp         al,8
		jne         loc_137                             ; Jump if not equal
		cmp         di,0FFFFh
		je          loc_136                             ; Jump if equal
		dec         dx
		inc         di
		mov         byte ptr [bp+di],30h    ; '0'
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		mov         al,20h                              ; ' '
		mov         cx,1
		mov         ah,9
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
loc_136:
		jmp         loc_131
loc_137:
		cmp         al,30h                              ; '0'
		jb          loc_131                             ; Jump if below
		cmp         al,39h                              ; '9'
		jbe         loc_138                             ; Jump if below or =
		cmp         al,41h                              ; 'A'
		jb          loc_131                             ; Jump if below
		cmp         al,47h                              ; 'G'
		jb          loc_138                             ; Jump if below
		cmp         al,61h                              ; 'a'
		jb          loc_131                             ; Jump if below
		cmp         al,66h                              ; 'f'
		ja          loc_131                             ; Jump if above
loc_138:
		cmp         di,0FFFCh
		jae         loc_139                             ; Jump if above or =
		jmp         loc_131
loc_139:
		mov         [bp+di],al
		mov         ah,9
		mov         cx,1
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
		dec         di
		inc         dx
		jmp         loc_131
CGETHEX4                ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CG_NUM                  PROC        
		mov         di,0FFFCh
		xor         cl,cl                               ; Zero register
loc_140:
		mov         ah,0
		mov         al,[bp+di]
		cmp         al,39h                              ; '9'
		ja          loc_141                             ; Jump if above
		sub         al,30h                              ; '0'
		jmp         loc_143
loc_141:
		cmp         al,46h                              ; 'F'
		ja          loc_142                             ; Jump if above
		sub         al,37h                              ; '7'
		jmp         loc_143
loc_142:
		sub         al,57h                              ; 'W'
loc_143:
		shl         ax,cl                               ; Shift w/zeros fill
		add         si,ax
		add         cl,4
		inc         di
		jnz         loc_140                             ; Jump if not zero
		mov         ax,si
		retn
CG_NUM                  ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CG_CONV                 PROC        
		push        es
		push        ss
		pop         es
		add         di,bp
		mov         si,di
		inc         si
		mov         di,bp
		add         di,0FFFCh
		xor         cx,cx                               ; Zero register
		sub         cx,si
		add         cx,bp
		cld                                             ; Clear direction
		rep         movs byte ptr es:[di],ss:[si]       ; Rep when cx >0 Mov [si] to es:[di]
		xor         cx,cx                               ; Zero register
		sub         cx,di
		add         cx,bp
		mov         al,30h                              ; '0'
		rep         stosb                               ; Rep when cx >0 Store al to es:[di]
		xor         si,si                               ; Zero register
		pop         es
		retn
CG_CONV                 ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CGETHEX2                PROC        
;jumps
		
		or          PROG_STATUS, 8000h
		push        cx
		push        si
		push        di
		push        bp
		mov         bp,sp
		xor         si,si                               ; Zero register
		mov         ax,3030h
		push        ax
		mov         di,0FFFFh
		WHEREXY
loc_144:
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		call	GETCH			; Keyboard i/o  ah=function 00h
						;  get keybd char in al, ah=scan
		cmp         al,0Dh
		jne         loc_147                             ; Jump if not equal
		cmp         di,0FFFFh
		jne         loc_145                             ; Jump if not equal
		stc                                             ; Set carry flag
		jmp         loc_146
loc_145:
		call        @CG_CONV
		call        @CG_NUM
		mov         sp,bp
		pop         bp
		pop         di
		pop         si
		pop         cx
		
		and         PROG_STATUS, 7FFFh
		clc                                             ; Clear carry flag
		retn
loc_146:
		mov         sp,bp
		pop         bp
		pop         di
		pop         si
		pop         cx
		
		and         PROG_STATUS, 7FFFh
		stc
		retn
loc_147:
		cmp         al,1Bh
		jne         loc_148                             ; Jump if not equal
		stc                                             ; Set carry flag
		jmp         loc_146
loc_148:
		cmp         al,8
		jne         loc_150                             ; Jump if not equal
		cmp         di,0FFFFh
		je          loc_149                             ; Jump if equal
		dec         dx
		inc         di
		mov         byte ptr [bp+di],30h    ; '0'
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		mov         al,20h                              ; ' '
		mov         cx,1
		mov         ah,9
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
loc_149:
		jmp         loc_144
loc_150:
		cmp         al,30h                              ; '0'
		jb          loc_144                             ; Jump if below
		cmp         al,39h                              ; '9'
		jbe         loc_151                             ; Jump if below or =
		cmp         al,41h                              ; 'A'
		jb          loc_144                             ; Jump if below
		cmp         al,47h                              ; 'G'
		jb          loc_151                             ; Jump if below
		cmp         al,61h                              ; 'a'
		jb          loc_144                             ; Jump if below
		cmp         al,66h                              ; 'f'
		ja          loc_144                             ; Jump if above
loc_151:
		cmp         di,0FFFEh
		jae         loc_152                             ; Jump if above or =
		jmp         loc_144
loc_152:
		mov         [bp+di],al
		mov         ah,9
		mov         cx,1
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
		dec         di
		inc         dx
		jmp         loc_144
CGETHEX2                ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

@CG_NUM                 PROC        
		mov         di,0FFFEh
		xor         cl,cl                               ; Zero register
loc_153:
		mov         ah,0
		mov         al,[bp+di]
		cmp         al,39h                              ; '9'
		ja          loc_154                             ; Jump if above
		sub         al,30h                              ; '0'
		jmp         loc_156
loc_154:
		cmp         al,46h                              ; 'F'
		ja          loc_155                             ; Jump if above
		sub         al,37h                              ; '7'
		jmp          loc_156
loc_155:
		sub         al,57h                              ; 'W'
loc_156:
		shl         ax,cl                               ; Shift w/zeros fill
		add         si,ax
		add         cl,4
		inc         di
		jnz         loc_153                             ; Jump if not zero
		mov         ax,si
		retn
@CG_NUM                 ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

@CG_CONV                PROC        
		push        es
		push        ss
		pop         es
		add         di,bp
		mov         si,di
		inc         si
		mov         di,bp
		add         di,0FFFEh
		xor         cx,cx                               ; Zero register
		sub         cx,si
		add         cx,bp
		cld                                             ; Clear direction
		rep         movs byte ptr es:[di],ss:[si]       ; Rep when cx >0 Mov [si] to es:[di]
		xor         cx,cx                               ; Zero register
		sub         cx,di
		add         cx,bp
		mov         al,30h                              ; '0'
		rep         stosb                               ; Rep when cx >0 Store al to es:[di]
		xor         si,si                               ; Zero register
		pop         es
		retn
@CG_CONV                ENDP



;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

sub_19                  PROC        
		cmp         al,9
		ja          loc_158                             ; Jump if above
		add         al,30h                              ; '0'
		jmp          loc_159
loc_158:
		add         al,37h                              ; '7'
loc_159:
		mov         cx,1
		mov         ah,9
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
		retn
sub_19                  ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CGETLONG16              PROC        
;jumps
		
		or          PROG_STATUS, 8000h
		push        cx
		push        si
		push        di
		push        bp
		mov         bp,sp
		sub         si,si                               ; Zero register
		mov         ax,3030h
		push        ax
		push        ax
		push        ax
		push        ax
		mov         di,0FFFFh
		WHEREXY
loc_160:
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		call	GETCH                               ; Keyboard i/o  ah=function 00h
						;  get keybd char in al, ah=scan
		cmp         al,0Dh
		jne         loc_163                             ; Jump if not equal
		cmp         di,0FFFFh
		jne         loc_161                             ; Jump if not equal
		stc                                             ; Set carry flag
		jmp          loc_162
loc_161:
		call        @CG_CONV@
		call        @CG_NUM@
		mov         sp,bp
		pop         bp
		pop         di
		pop         si
		pop         cx
		
		and         PROG_STATUS, 7FFFh
		clc                                             ; Clear carry flag
		retn
loc_162:
		mov         sp,bp
		pop         bp
		pop         di
		pop         si
		pop         cx
		
		and         PROG_STATUS, 7FFFh
		stc
		retn
loc_163:
		cmp         al,1Bh
		jne         loc_164                             ; Jump if not equal
		stc                                             ; Set carry flag
		jmp          loc_162
loc_164:
		cmp         al,8
		jne         loc_166                             ; Jump if not equal
		cmp         di,0FFFFh
		je          loc_165                             ; Jump if equal
		dec         dx
		inc         di
		mov         byte ptr [bp+di],30h    ; '0'
		mov         ah,2
		int         10h                                 ; Video display   ah=functn 02h
						;  set cursor location in dx
		mov         al,20h                              ; ' '
		mov         cx,1
		mov         ah,9
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
loc_165:
		jmp          loc_160
loc_166:
		cmp         al,30h                              ; '0'
		jb          loc_160                             ; Jump if below
		cmp         al,39h                              ; '9'
		jbe         loc_167                             ; Jump if below or =
		cmp         al,41h                              ; 'A'
		jb          loc_160                             ; Jump if below
		cmp         al,47h                              ; 'H'
		jb          loc_167                             ; Jump if below
		cmp         al,61h                              ; 'a'
		jb          loc_160                             ; Jump if below
		cmp         al,66h                              ; 'f'
		ja          loc_160                             ; Jump if above
loc_167:
		cmp         di,0FFF8h
		jae         loc_168                             ; Jump if above or =
		jmp          loc_160
loc_168:
		mov         [bp+di],al
		mov         ah,9
		mov         cx,1
		int         10h                                 ; Video display   ah=functn 09h
						;  set char al & attrib bl @curs
						;   cx=# of chars to replicate
		dec         di
		inc         dx
		jmp         loc_160
CGETLONG16              ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

@CG_NUM@                PROC        
		mov         di,0FFF8h
		mov         cx,400h
		call        SUB_22
		push        si
		xor         si,si                               ; Zero register
		mov         cx,400h
		call        SUB_22
		mov         dx,si
		pop         ax
		retn
@CG_NUM@                ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

SUB_22                  PROC        
		mov         ah,0
		mov         al,[bp+di]
		cmp         al,39h                              ; '9'
		ja          loc_170                             ; Jump if above
		sub         al,30h                              ; '0'
		jmp          loc_172
loc_170:
		cmp         al,46h                              ; 'F'
		ja          loc_171                             ; Jump if above
		sub         al,37h                              ; '7'
		jmp          loc_172
loc_171:
		sub         al,57h                              ; 'W'
loc_172:
		shl         ax,cl                               ; Shift w/zeros fill
		add         si,ax
		add         cl,4
		inc         di
		dec         ch
		jnz         SUB_22                             ; Jump if not zero
		retn
SUB_22                  ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

@CG_CONV@               PROC        
		push        es
		push        ss
		pop         es
		add         di,bp
		mov         si,di
		inc         si
		mov         di,bp
		add         di,0FFF8h
		xor         cx,cx                               ; Zero register
		sub         cx,si
		add         cx,bp
		cld                                             ; Clear direction
		rep         movs byte ptr es:[di],ss:[si]       ; Rep when cx >0 Mov [si] to es:[di]
		xor         cx,cx                               ; Zero register
		sub         cx,di
		add         cx,bp
		mov         al,30h                              ; '0'
		rep         stosb                               ; Rep when cx >0 Store al to es:[di]
		xor         si,si                               ; Zero register
		pop         es
		retn
@CG_CONV@               ENDP



;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

CGETSTR 	PROC
;locals
	or          cs:PROG_STATUS, 8000h 	;No help available
	push        bp
	mov         bp,sp

	push        si
	push        di
	mov         si,[bp+6]	; SI -> buffer
	mov         di,si
	sub         cx,cx       ; Zero register
	mov         cx, [bp+4]
	sub         cx, [bp+6]
	inc         cx		; CX=string MaxLen
	sub         al, al
rep         stosb	        ; Zero string buffer
	mov         di, si	; DI=SI -> buffer
	sub         cx, cx	; CX=char. counter
@@kbd_loop:
	mov         ah,2
	int         10h         ; Video display   ah=functn 02h
			;  set cursor location in dx
	call	GETCH       ; Keyboard i/o  ah=function 00h
			;  get keybd char in al, ah=scan
	cmp         al,0        ; AL contains char. ?
	jnz         loc_177     ; Jump if contains ASCII
	cmp         ah,4Bh      ; Left Arrow?
	jne         loc_175     ; Jump if not equal
	cmp         dl,[bp+9]	; DL = cursor start loc?
	je          loc_174     ; Jump if equal
	dec         dx
	dec         di
	jmp         @@kbd_loop
loc_174:
	cmp         di,[bp+6]	; DI -> start?
	je          @@kbd_loop  ; Jump if equal
	call        sub_26	; move right
	dec         di
	mov         al,[di]	; display suitable char.
	mov         ah,9
	push        cx
	mov         cx,1
	int         10h         ; Video display   ah=functn 09h
			;  set char al & attrib bl @curs
			;   cx=# of chars to replicate
	pop         cx
	jmp          @@kbd_loop
loc_175:
	cmp         ah,4Dh      ; Right Arrow?
	jne         @@delete?   ; Jump if not equal
	cmp         di,[bp+4]	; DI -> end of string
	je          @@kbd_loop  ; Jump if equal
	cmp         dl,[bp+8]	; DL=rightmost cursor loc.
	je          loc_176     ; Jump if equal
	inc         dx
	inc         di
	jmp         @@kbd_loop
loc_176:
	call        sub_25      ; move left
	inc         di
	mov         al,[di]	; display suitable char.
	push        cx
	mov         cx,1
	mov         ah,9
	int         10h	; Video display   ah=functn 09h
			;  set char al & attrib bl @curs
			;   cx=# of chars to replicate
	pop         cx
	jmp         @@kbd_loop
@@delete?:
	cmp	ah, 83
        jnz	@@home?
    cmp	si, [bp+6]	; End==Start?
    jz	@@kbd_loop
        jmp	@@del_char
@@home?:
	cmp	ah, 71
        jnz	@@end?
        push	si
        push	cx
        mov	dl, [bp+9]
        GOTOXY
        mov	si, [bp+6]
        mov	cl, [bp+8]
        sub	cl, [bp+9]
        inc	cx
        sub	ch, ch
        call	CPUTSTR
        pop	cx
        pop	si
        mov	dl, [bp+9]
        mov	di, [bp+6]
        jmp	@@kbd_loop
@@end?:
	cmp	ah, 79
            jnz	loc_177
            push	si
            push	cx
            GOTOXY	[bp+9]
            mov	cx, si
            sub	cx, [bp+6]
            mov	ch, [bp+8]
            sub	ch, [bp+9]
            cmp	cl, ch
            jnb	@@from_end
            mov	si, [bp+6]
            jmp	@@end_output
@@from_end:
	mov	cl, ch
	sub	ch, ch
            sub	si, cx
            mov	cl, [bp+8]
            sub	cl, [bp+9]
@@end_output:
            sub	ch, ch
            call	CPUTSTR
            WHEREXY
            mov	ax, 920h
            mov	cx, 1
            int	10h
            pop	cx
            pop	si
            mov	di, si
	jmp	@@kbd_loop
loc_177:
	cmp         al,8	; BackSpace?
	jne         loc_180     ; Jump if not equal
	cmp         di,[bp+6]	; DI -> start offset?
	jz          @@kbd_loop  ; Jump if equal
        dec	di
	cmp         dl,[bp+9]	; DL=leftmost cursor pos.?
	je          @@del_char	; Jump if equal
	dec         dx
@@del_char:
	push        cx		; Delete character
	push        si
        push        di
	mov         cx,si
	sub         cx,di
        mov         si,di
        inc	si
	

	cld                     ; Clear direction
rep     movsb       		; Rep when cx >0 Mov [si] to es:[di]
	sub         al,al       ; AL=0
	stosb                   ; Store al to es:[di]
	pop         di
	pop         si
	dec         si
	pop         cx
            GOTOXY
            push	si
            push	cx
            push	dx
            mov	si, di
            mov	cl, [bp+8]
            sub	cl, dl
            sub	ch, ch
	call	CPUTSTR
        WHEREXY
        mov	ax, 920h
        mov	cl, [bp+8]
        sub	cl, dl
        sub	ch, ch
        inc	cx
        int	10h
            pop	dx
            pop	cx
            pop	si
            jmp	@@kbd_loop
loc_180:
	cmp         al,0Dh	; Enter?
	jne         loc_181     ; Jump if not equal
	mov         cx,si
	sub         cx,[bp+6]
	pop         di
	pop         si

	mov         sp,bp
	pop         bp
	and         cs:PROG_STATUS, 7FFFh
            clc
	retn        6
loc_181:
	cmp         al,1Bh	; Esc.?
	jne         loc_182     ; Jump if not equal
	pop         di
	pop         si

	mov         sp,bp
	pop         bp
            and	cs:PROG_STATUS, 7FFFh
            stc
	retn        6
loc_182:
	cmp         al,20h      ; ' '
	jae         loc_183     ; Jump if above or =
	jmp         @@kbd_loop
loc_183:
	cmp         di,si
	jb          loc_184     ; Jump if below
	jmp         loc_185
            nop
loc_184:
	push        cx
	push        si
	push        di
	mov         cx,[bp+4]
	sub         cx,di
	add         di,cx
	mov         si,di
	dec         si
	std               	; Set direction flag
	rep         movsb       ; Rep when cx >0 Mov [si] to es:[di]
	pop         di
	pop         si
	pop         cx
	cld                     ; Clear direction
	stosb                   ; Store al to es:[di]
	call        sub_26	; go right
	dec         di
	mov         al,[di]
	inc         di
	mov         ah,9
	push        cx
	mov         cx,1
	int         10h         ; Video display   ah=functn 09h
			;  set char al & attrib bl @curs
			;   cx=# of chars to replicate
	pop         cx
	inc         si
	cmp         dl,[bp+8]
	je          loc_187 	; Jump if equal
	inc         dx
	inc         cx
	jcxz        loc_190     ; Jump if cx=0
	jmp         @@kbd_loop
loc_185:
	cmp         si,[bp+4]   ; SI=end offset of the string?
	jbe         loc_186     ; Jump if below or =
	jmp         @@kbd_loop
loc_186:
	cld                     ; Clear direction
	stosb                   ; Store al to es:[di]
	mov         ah,9
	push        cx
	mov         cx,1
	int         10h         ; Video display   ah=functn 09h
			;  set char al & attrib bl @curs
			;   cx=# of chars to replicate
	pop         cx
	cmp         dl,[bp+8]
	jne         loc_188     ; Jump if not equal
loc_187:
	call        sub_25
	push        cx
	mov         ah,9
	mov         al,20h                              ; ' '
	mov         cx,1
	int         10h         ; Video display   ah=functn 09h
			;  set char al & attrib bl @curs
			;   cx=# of chars to replicate
	pop         cx
	jmp         loc_189
loc_188:
	inc         dx
loc_189:
	inc         si
	inc         cx
	jmp         @@kbd_loop
loc_190:
	pop         di
	pop         si
	mov         sp,bp
	pop         bp
	and         cs:PROG_STATUS, 7FFFh
            stc
	retn        6
CGETSTR                 ENDP


;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

sub_25                  PROC        
		push        ds
		push        es
		push        si
		push        di
		push        cx
		mov         al,dh
		mov         cl,50h                              ; 'P'
		mul         cl                                  ; ax = reg * al
		add         al,dl
		adc         ah,0
		mov         cl,[bp+8]
		sub         cl,[bp+9]
		xor         ch,ch                               ; Zero register
		sub         ax,cx
		shl         ax,1                                ; Shift w/zeros fill
		cmp         bh,0
		je          loc_192                             ; Jump if equal
		push        cx
		xor         ch,ch                               ; Zero register
		mov         cl,bh

locloop_191:
		add         ax,1000h
		loop        locloop_191             ; Loop if cx > 0

		pop         cx
loc_192:
		mov         di,ax
		mov         si,ax
		inc         si
		inc         si
		mov         ax,cs:VTEXT_BUFFER
		mov         ds,ax
		mov         es,ax
		cld                                             ; Clear direction
		rep         movsw                               ; Rep when cx >0 Mov [si] to es:[di]
		pop         cx
		pop         di
		pop         si
		pop         es
		pop         ds
		retn
sub_25                  ENDP

;ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
;                                          SUBROUTINE
;ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

sub_26                  PROC        
		push        ds
		push        es
		push        si
		push        di
		push        cx
		mov         al,dh
		mov         cl,50h                              ; 'P'
		mul         cl                                  ; ax = reg * al
		add         al,dl
		adc         ah,0
		mov         cl,[bp+8]
		sub         cl,dl
		xor         ch,ch                               ; Zero register
		add         ax,cx
		shl         ax,1                                ; Shift w/zeros fill
		cmp         bh,0
		je          loc_194                             ; Jump if equal
		push        cx
		mov         cl,bh

locloop_193:
		add         ax,1000h
		loop        locloop_193             ; Loop if cx > 0

		pop         cx
loc_194:
		mov         si,ax
		mov         di,ax
		dec         si
		dec         si
		mov         ax,cs:VTEXT_BUFFER
		mov         ds,ax
		mov         es,ax
		std                                             ; Set direction flag
		rep         movsw                               ; Rep when cx >0 Mov [si] to es:[di]
		pop         cx
		pop         di
		pop         si
		pop         es
		pop         ds
		retn
sub_26                  ENDP


CPUTSTR     PROC
;locals
;----------------------------------------------------------------------------
;                       DS:SI -> source string     RETURN:
;                       CX -> nbytes                        CX=nbytes printed
;                       BL = color
;----------------------------------------------------------------------------
	push        bp
	mov         bp, sp
	push        es
	push        ax
	push        cx
	push        dx
	push        si
	push        di

                        cmp	MOUSE_STAT, 0
                        jz	@@mouse_OK1
                        mov	ax, 2		; hide mouse
                        int	33h

@@mouse_OK1:
	push        cx
	wherexy                             ;DX=cursor
	sub         di, di                  ;DI=0
	mov         cl, bh
	sub         ch, ch
	jcxz        @@end_add
@@add_loop:
	add         di, 1000h               ;DI=page+0
	loop        @@add_loop
@@end_add:
	mov         cl, dh
	sub         ch, ch
	jcxz        @@end_add_line
@@add_line:
	add         di, 160                 ;DI=page+line+0
	loop        @@add_line
@@end_add_line:
	mov         al, dl
	cbw
	shl         ax, 1
	add         di, ax                  ;DI=page+line+column
	pop         cx
	mov         es, cs:VTEXT_BUFFER     ;ES:DI -> locatoin for output.
	mov         ah, bl                  ;AH=attribute
	cld                                 ;Up
@@main_loop:
	lodsb
	or          al, al
	jz          @@end_main
	stosw
	loop        @@main_loop
@@end_main:
	sub         [bp-6], cx
	add         dx, [bp-6]
	gotoxy

                        cmp	MOUSE_STAT, 0
                        jz	@@mouse_OK2
                        mov	ax, 1                   ; display mouse
                        int	33h

@@mouse_OK2:
	pop         di
	pop         si
	pop         dx
	pop         cx
	pop         ax
	pop         es

	pop         bp
	ret


CPUTSTR     ENDP


CPUTHEX2    PROC
;----------------------------------------------------------------------------
;                       output value got in AL
;                       BX = page:color
;----------------------------------------------------------------------------
	
	push        ax
	push        cx
	push        dx
	push        si
	push        bp
	mov         bp, sp
	sub         cx, cx
	push        cx                      ;[bp-1], [bp-2] set 0
	mov         si, -1
@@_loop:
	push        ax
	shr         al, cl
	mov         [bp+si], al
	and         byte ptr [bp+si], 00001111b
	cmp         byte ptr [bp+si], 9
	ja          @@above_9         
	add         byte ptr [bp+si], '0'
	jmp                @@OK
@@above_9:
	add         byte ptr [bp+si], 'A'-10
@@OK:
	add         cl, 4
	pop         ax
	dec         si
	cmp         si, -3
	jnz         @@_loop
	add         si, bp
	inc         si
	push        ds
	push        ss
	pop         ds
	mov         cx, 2
	call        CPUTSTR
	pop         ds
	mov         sp, bp
	pop         bp
	pop         si
	pop         dx
	pop         cx
	pop         ax
	ret
	
CPUTHEX2    ENDP


CPUTHEX4    PROC
;----------------------------------------------------------------------------
;                       output number got in AX
;                       BX = page:attributes
;----------------------------------------------------------------------------
	push        bp
	mov         bp, sp
	push        ax
	mov         al, [bp-1]
	call        CPUTHEX2
	mov         al, [bp-2]
	call        CPUTHEX2
	pop         bp
	pop         bp
	ret
CPUTHEX4    ENDP


CPUTLONG16  PROC
;locals
;----------------------------------------------------------------------------
;                       outputs value got in DX:AX
;                       BH:BL -> page:attr
;----------------------------------------------------------------------------
	
	push        bp
	mov         bp, sp
	push        dx
	push        ax
	push        si
	lea         si, [bp-1]
	mov         cx, 4
	std
@@loop:
	lods        byte ptr ss:[si]
	call        CPUTHEX2
	loop        @@loop
	pop         si
	pop         dx
	pop         ax
	pop         bp
	
	ret
CPUTLONG16  ENDP



CPUTCHAR    PROC
;locals
;----------------------------------------------------------------------------
;           Parameters to get: AL-symbol, BX-page:attribute,
;                           GOTOXY required.
;----------------------------------------------------------------------------
	push        es
	push        ax            
	push        cx
	push        dx
	push        di

	sub         di, di
	mov         cl, bh
	sub         ch, ch
	jcxz        @@end_loop1
@@loop1:
	add         di, 1000h
	loop        @@loop1
@@end_loop1:
	wherexy
	mov         cl, dh
	sub         ch, ch
	jcxz        @@end_loop2
@@loop2:
	add         di, 160
	loop        @@loop2
@@end_loop2:
	sub         dh, dh
	shl         dx, 1
	add         di, dx
	mov         es, cs:VTEXT_BUFFER
	mov         ah, bl
	stosw

	pop         di
	pop         dx
	pop         cx
	pop         ax
	pop         es
	ret
CPUTCHAR    ENDP


CHANGE_ATTRIBS  PROC
;locals
		;[bp+4] = page:attr (new)
		;[bp+6] = right
		;[bp+7] = bottom
		;[bp+8] = left
		;[bp+9] = top
	push        bp
	mov         bp, sp
	push        es
	push        ax
	push        cx
	push        di

            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK1
            mov	ax, 2		; hide mouse pointer
            int	33h
@@mouse_OK1:
	mov         cl, [bp+5]
	sub         ch, ch
	mov         ax, VTEXT_BUFFER
	jcxz        @@page_0
@@add_loop:
	add         ax, 100h
	loop        @@add_loop
@@page_0:
	mov         es, ax

	sub         di, di
	mov         cl, [bp+9]
	sub         ch, ch
	jcxz        @@line_0
@@add_loop_2:
	add         di, 160
	loop        @@add_loop_2
@@line_0:

	mov         al, [bp+8]
	cbw
	shl         ax, 1
	add         di, ax
	inc         di
	mov         cl, [bp+7]
	sub         cl, [bp+9]
	sub         ch, ch
	inc         cx
	mov         al, [bp+4]
	cld
@@loop1:
	push        cx
	push        di
	mov         cl, [bp+6]
	sub         cl, [bp+8]
	sub         ch, ch
	inc         cx
@@loop2:
	stosb
	inc         di
	loop        @@loop2
	pop         di
	add         di, 160
	pop         cx
	loop        @@loop1

            cmp	MOUSE_STAT, 0
            jz	@@mouse_OK2
            mov	ax, 1		; show mouse pointer
            int	33h
@@mouse_OK2:
	pop         di
	pop         cx
	pop         ax
	pop         es
	pop         bp
	ret         6
CHANGE_ATTRIBS  ENDP


LITTLE_FRAME  PROC
		; [bp+4] -> Left:Top
		; [bp+6] -> Right:Bottom
                        ; BH:BL = Page:Attribs
	push        bp
	mov         bp, sp
	push        cx
	push        dx
	mov         cx, 1
	gotoxy      [bp+4], [bp+5]
	mov         al, 'É'
	mov         ah, 9
	int         10h
	gotoxy      [bp+6], [bp+5]
	mov         al, '»'
	mov         ah, 9
	int         10h
	gotoxy      [bp+4], [bp+7]
	mov         al, 'È'
	mov         ah, 9
	int         10h
	gotoxy      [bp+6], [bp+7]
	mov         al, '¼'
	mov         ah, 9
	int         10h
	mov         cl, [bp+6]
	sub         cl, [bp+4]
	xor         ch, ch
	dec         cx
	mov         dx, [bp+4]
	inc         dx
	gotoxy
	mov         al, 'Í'
	mov         ah, 9
	int         10h
	gotoxy      , [bp+7]
	mov         ah, 9
	int         10h
	mov         dh, [bp+5]
	inc         dh
Lit_fr_00:
	mov         dl, [bp+4]
	gotoxy
	mov         al, 'º'
	mov         ah, 9
	push        cx
	mov         cx, 1
	int         10h
	pop         cx
	inc         dx
	gotoxy
	mov         al, ' '
	mov         ah, 9
	int         10h
	gotoxy      [bp+6]
	mov         al, 'º'
	mov         ah, 9
	push        cx
	mov         cx, 1
	int         10h
	pop         cx
	inc         dh
	cmp         dh, [bp+7]
	jb          Lit_fr_00
	pop         cx
	pop         ax
	mov         sp, bp
	pop         bp
	ret         4
LITTLE_FRAME  ENDP
