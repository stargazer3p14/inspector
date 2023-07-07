cnv         proc        near
	push        di
	push        cx
	push        bp
	mov         bp,sp
	mov         di,[bp+8]
	mov         cx,[bp+10]
	pop         bp
cnv1:
	cmp         byte ptr[di],97
	jb          cont
	cmp         byte ptr[di],122
	ja          cont
	sub         byte ptr[di],32
cont:
	inc         di
	loop        cnv1
	pop         cx
	pop         di
	ret         4
cnv         endp

str2hex     proc        near
	push        bx
	push        cx
	push        dx
	push        si
	push        bp
	mov         bp,sp
	mov         bx,[bp+12]
	mov         cx,[bp+14]
	pop         bp
	xor         ax,ax
	mov         si,ax

cmp_:
	mov         dx,0
	mov         dl,[bx+si]
	cmp         dl,3ah
	jb          it_num
	sub         dl,7

it_num:
	sub         dl,30h
	add         ax,dx
	cmp         cx,1
	je          lst_loop
	push        cx
	mov         cl,4
	rol         ax,cl
	pop         cx
	inc         si
	loop        cmp_

lst_loop:
	pop         si
	pop         dx
	pop         cx
	pop         bx
	ret         4
str2hex     endp

hex2str     proc        near
	push        ax
	push        bx
	push        bp
	mov         bp,sp
	mov         bx,[bp+8]
	mov         ax,[bp+10]
	pop         bp
	push        si
	push        cx
	mov         si,4
	mov         cl,4
	dec         bx
loop_1:
	push        ax
	and         al,0fh
	cmp         al,9
	jbe         itnum
	add         al,7
itnum:
	add         al,48
	mov         [bx+si],al
	pop         ax
	ror         ax,cl
	dec         si
	cmp         si,0
	jne         loop_1

	pop         cx
	pop         si
	pop         bx
	pop         ax
	ret         4
hex2str     endp

strcmp      proc        near
	push        cx
	push        si
	push        di

	push        bp
	mov         bp,sp
	mov         cx,[bp+10]
	mov         di,[bp+12]
	mov         si,[bp+14]
	pop         bp
	
	cld
	clc
repe        cmpsb
	je          lll
	stc
lll:
	pop         di
	pop         si
	pop         cx
	ret         6
strcmp      endp

cnvtab      proc        near
	push        bx
	push        cx
	push        bp
	mov         bp,sp
	mov         bx,[bp+8]
	mov         cx,[bp+10]
	pop         bp
	
lb:
	cmp         byte ptr[bx],9
	jne         lbb
	mov         byte ptr[bx],20h
lbb:
	inc         bx
	loop        lb
	
	pop         cx
	pop         bx
	ret         4
cnvtab      endp

spacebar    proc        near
	push        cx
	push        si
	push        di
	push        bp
	mov         bp,sp
	mov         si,[bp+10]
	mov         cx,[bp+12]
	pop         bp
	
	push        ax
	push        bx          
	mov         di,si
	mov         bx,cx
lp1:        
	mov         al,byte ptr[di]
	cmp         al,' '
	je          spc
	mov         byte ptr[si],al
	inc         di
	inc         si
lp2:
	loop        lp1
	jmp         ll_1
spc:
	cmp         bx,cx
	je          ll_2
	mov         byte ptr[si],al
repe        scasb
	dec         di
	inc         si
	jmp         lp2
ll_2:
repe        scasb
	dec         di
	jmp         lp2
ll_1:
	pop         bx
	pop         ax
	pop         di
	pop         si
	pop         cx
	ret         4
spacebar    endp

isxdigit    proc        near
	
	cmp         al,'0'
	jb          notxdigit
	cmp         al,'9'
	ja          xletter
	clc
	ret

xletter:
	cmp         al,'A'
	jb          notxdigit
	cmp         al,'F'
	ja          notxdigit
	clc
	ret

notxdigit:
	stc
	ret
isxdigit    endp        
	
movaxnum    proc        near
		push        si
		mov         al,[di]
		call        isxdigit
		jc          fff
		mov         si,di
loop_2:
		mov         al,[di]
		inc         di
		call        isxdigit
		jnc         loop_2
		dec         di
		dec         di
		mov         ax,di
		sub         ax,si
		inc         ax
		cmp         ax,4
		jbe         okk
		mov         ax,4
		inc         di
		sub         di,ax
		xchg        di,si
okk:
		push        ax
		push        si
		call        str2hex
fff:
		pop         si
		ret
movaxnum    endp

cnvspc2	proc	near
	push	di
	push	si
	push	cx
	push	ax
@@:
	lodsb
	cmp	al, ' '
	je	spc
	loop	@B
	pop	ax
	pop	cx
	pop	si
	pop	di
	ret
spc:
	dec	cx
	cmp	byte ptr[si], ','
	je	no_need
	cmp	byte ptr[si-2], ','
	je	no_need
	cmp	byte ptr[si], ']'
	je	no_need
	cmp	byte ptr[si-2], '['
	je	no_need
	cmp	byte ptr[si], '+'
	je	no_need
	cmp	byte ptr[si-2], '+'
	je	no_need
	jmp	@B
no_need:
	push	cx
	mov	di, si
	dec	di
	push	si
rep	movsb
	pop	si
	pop	cx
	jmp	@B
cnvspc2	endp







