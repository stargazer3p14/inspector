SAVE_MAIN_WIND  PROC
;locals
	sub         si, si                  
	mov         cl, OUR_PAGE
	sub         ch, ch
	jcxz        @@main_got
@@add_loop:
	add         si, 1000h
	loop        @@add_loop
@@main_got:
	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@save_in_XMS
	sub         di, di
	push        ds
	push        es
	mov         es, MAIN_WINDOW
	mov         ds, VTEXT_BUFFER
	mov         cx, 4096
	cld
rep         movsb
	pop         es
	pop         ds
	ret
@@save_in_XMS:
	sub         ax, ax
	push        ax                      ; Destination
	push        ax                      ; offset
	push        MAIN_WIND_HANDLE        ; Destination handle
	push        VTEXT_BUFFER            ; Source
	push        si                      ; offset
	push        ax                      ; Source handle
	push        ax                      ; Number of
	mov         ax, 4096
	push        ax                      ; bytes
	call        XMS_MOVE
	ret

SAVE_MAIN_WIND  ENDP



LOAD_USER_VIDEO  PROC
;locals
;jumps

	mov         al, USER_MODE           ; Set
	sub         ah, ah                  ; user
	int         10h                     ; video mode

	mov	ax, 1002h             	; Set palette registers
	mov	dx, offset PALETTE_BUF
	int	10h

	mov	ax, 1012h		; Set DAC registers
	mov	dx, offset DAC_BUF
	mov	bx, 0
	mov	cx, 256
	int	10h

	Select_Page USER_PAGE
	mov         bh, USER_PAGE

	mov         cx, word ptr USER_CUR_FORM
	mov         ah, 1                   ; Set user cursor
	int         10h                     ; parameters

	gotoxy      USER_CURSOR, USER_CURSOR[1]
	cmp         USER_MODE, 7
	jz          @@load_text
	cmp         USER_MODE, 3
	jna         @@load_text
;--------------------------- Load graphic screen ----------------------------
	cmp         GRAPH_MODE_BUF, 0
	jz          @@exit
	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@graph_from_XMS
;--------------------------- Load from low memory ---------------------------
	push        ds
	push        es

	mov         ax, GRAPH_MODE_BUF      ; AX=buffer size in Kbytes
	sub         dx, dx                  ; AX:DX=buffer size (Kb)
	mov         cx, 6
@@shr_loop1:
	shr         dx, 1
	shr         ax, 1
	jnc         @@shr_on1
	or          dx, 8000h
@@shr_on1:
	loop        @@shr_loop1
				; AX:DX=byffer size (bytes)
	mov         ds, USER_V_GRAPH        ; DS:SI -> buffer
	sub         di, di                  ; DI=0
	mov         si, di                  ; SI=0
	mov         es, cs:VGRAPH_BUFFER    ; ES:DI -> video memory
	cmp	cs:USER_MODE, 0Dh
	jb	@@mcga_modes
	cmp	cs:USER_MODE, 13h
	jb	@@ega
	ja	@@vga
@@mcga_modes:
	cld
	mov         cx, ax
	jcxz	@@end_mcga
@@save_loop1:
	push        cx
	sub         cx, cx                  ; CX=64K times
rep         movsb
	pop         cx
	mov         ax, ds
	add         ax, 4096
	mov         ds, ax
	mov         ax, es
	add         ax, 4096
	mov         es, ax
	loop        @@save_loop1
@@end_mcga:
	mov         cx, dx
rep         movsb

	pop         es
	pop         ds
	ret
@@ega:
;
;	Load EGA gfx. in modes D-10
;
	push	bx

	mov	cx, 4
	div	cx

	xchg	ax, bx
	mov	cx, dx		; BX:CX=buffer size/4
@@load_ega:
	mov	dx, 3C4h
	mov	ah, 1		; value for card mask reg.
	mov	al, 2
@@load_ega_lp:
	out	dx, ax
	push	cx
	push	cx
rep	movsb
	pop	cx
	mov	si, ds
	add	si, cx
	mov	ds, si
	pop	cx
	sub	si, si
	sub	di, di
	shl	ah, 1
	cmp	ah, 8
	jna	@@load_ega_lp

	pop	bx
	pop	es
	pop	ds
	retn

@@vga:
;
;          Load gfx. from VGA (eXtended VGA) modes 13+
;
	push	bx

	mov	bx, ax
	mov	cx, dx
	mov	ax, 9
	mov	dx, 3CEh
@@load_vga_lp:
	or	bx, bx
	jz	@@end_vga

	push	cx
	mov	cx, -1
rep	movsb
	pop	cx

	inc	ah
	out	dx, ax
	dec	bx
	mov	si, ds
	add	si, 1000h
	mov	ds, si
	jmp	@@load_vga_lp

@@end_vga:
rep	movsb
	pop	bx
	pop	es
	pop	ds
	retn

@@graph_from_XMS:
	cmp	USER_MODE, 0Dh
	jb	@@mcga_XMS
	cmp	USER_MODE, 13h
	jb	@@XMS_ega
	ja	@@XMS_vga
@@mcga_XMS:
	sub         ax, ax
	push        VGRAPH_BUFFER           ; 0=offset in dest
	push        ax                      ; block
	push        ax                      ; dest handle
	push        ax                      ; 0=offset in source
	push        ax                      ; block
	push        VGRAPH_HANDLE           ; source handle
	
	sub         dx, dx
	mov         ax, GRAPH_MODE_BUF
	mov         cx, 6
@@shr_loop2:
	shr         dx, 1
	shr         ax, 1
	jnc         @@shr_on2
	or          dx, 8000h
@@shr_on2:
	loop        @@shr_loop2

	push        ax                      ; Number of bytes
	push        dx                      ; to move
	call        XMS_MOVE
@@exit:
	ret

@@XMS_ega:
	push	bx
	push	bp

	mov	ax, GRAPH_MODE_BUF
	mov	dx, 256
	mul	dx
	xchg	ax, bp
	mov	bx, dx		; BX:BP=buffer size/4 (bytes)

	sub	si, si
	sub 	di, di		; SI:DI=offset in src.

	mov	dx, 3C4h
	mov	ah, 1
	mov	al, 2		; plane mask reg.

	mov	cx, 4

@@XMS_ega_lp:
	out	dx, ax

	push	ax

	push	VGRAPH_BUFFER
	sub	ax, ax
	push	ax
	push	ax

	push	si
	push	di
	push	VGRAPH_HANDLE

	push        bx
	push	bp

	call	XMS_MOVE

	pop	ax

	add	di, bp
	adc	si, bx
	shl	ah, 1
	cmp	ah, 8
	jna	@@XMS_ega_lp

	pop	bp
	pop	bx
	retn

@@XMS_vga:
	push	bx

	mov	ax, GRAPH_MODE_BUF
	mov	dx, 1024
	mul	dx
	xchg	ax, cx
	mov	bx, dx		; BX:CX=buffer size (bytes)

	sub	si, si
	sub	di, di		; offset in src.

	mov	dx, 3CEh
	mov	ax, 9
@@XMS_vga_lp:
	or	bx, bx
	jz	@@XMS_vga_last
	out	dx, ax

	push	ax

	push	VGRAPH_BUFFER
	sub 	ax, ax
	push	ax
	push	ax

	push	si
	push	di
	push	VGRAPH_HANDLE

	inc	ax
	push	ax
	dec	ax
	push	ax

	call	XMS_MOVE

	pop	ax

	add	ah, 10h
	dec	bx
	inc	si
	jmp	@@XMS_vga_lp
@@XMS_vga_last:
	jcxz	@@load_text-2
	out	dx, ax
	push	VGRAPH_BUFFER
	sub	ax, ax
	push	ax
	push	ax

	push	si
	push	di
	push	VGRAPH_HANDLE

	push	ax
	push	cx

	call	XMS_MOVE
;@@load_text-2:
	pop	bx
	retn

@@load_text:
	cmp         TEXT_MODE_BUF, 0
	jz          @@exit
	sub         di, di                  ; SI=0
	mov         cl, USER_PAGE
	sub         ch, ch                  ; CX=user page
	jcxz        @@end_add
@@add_loop:
	add         di, 4096
	loop        @@add_loop
@@end_add:
	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@text_from_XMS
;-------------------------- Text from low memory ----------------------------
	push        ds
	push        es

	mov         ds, USER_V_TEXT
	mov         es, cs:VTEXT_BUFFER
	mov         cx, 4096
	sub         si, si                  ; di=0
rep         movsb

	pop         es
	pop         ds
	ret

@@text_from_XMS:
	sub         ax, ax
	push        VTEXT_BUFFER            ; offset in
	push        di                      ; dest
	push        ax                      ; dest handle=0
	push        ax                      ; offset in
	push        ax                      ; source
	push        VTEXT_HANDLE            ; source_handle
	push        ax                      ; Number
	mov         ax, 4096
	push        ax                      ; of bytes
	call        XMS_MOVE
	ret
LOAD_USER_VIDEO  ENDP



SAVE_USER_VIDEO  PROC
;locals
;jumps

				; Save palette registers
	mov	dx, offset PALETTE_BUF
	mov	ax, 1009h
	int         10h
				; Save DAC registers
	mov	dx, offset DAC_BUF
	mov	ax, 1017h
	mov	bx, 0
	mov	cx, 256
	int	10h

	mov         ah, 0Fh
	int         10h                     ; Get video state
	mov         USER_MODE, al           ; Save user mode
	mov         USER_PAGE, bh           ; and page
	wherexy                             ; Save cursor
	mov         word ptr USER_CURSOR, dx            ; location
	mov         word ptr USER_CUR_FORM, cx          ; and form
	cmp         USER_MODE, 7
	jz          @@save_text
	cmp         USER_MODE, 3
	jna         @@save_text
;--------------------------- Save graphics screen ---------------------------
	cmp         GRAPH_MODE_BUF, 0
	jz          @@exit
	cmp         USER_MODE, 7
	ja          @@EVGA
	mov         VGRAPH_BUFFER, 0B800h
	jmp         @@test_XMS
@@EVGA:
	mov         VGRAPH_BUFFER, 0A000h
@@test_XMS:
	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@graphics_in_XMS
;----------------------------- Save in low memory ---------------------------
	push        ds
	push        es

	mov         ax, GRAPH_MODE_BUF      ; AX=buffer size in Kbytes
	sub         dx, dx                  ; AX:DX=buffer size (Kb)
	mov         cx, 6
@@shr_loop1:
	shr         dx, 1
	shr         ax, 1
	jnc         @@shr_on1
	or          dx, 8000h
@@shr_on1:
	loop        @@shr_loop1
				; AX:DX=buffer size (bytes)
	mov         es, USER_V_GRAPH        ; ES:DI -> buffer
	sub         di, di                  ; DI=0
	mov         si, di                  ; SI=0
	mov         ds, VGRAPH_BUFFER       ; DS:SI -> video memory
	cmp	cs:USER_MODE, 0Dh
	jb	@@mcga_mode
	cmp	cs:USER_MODE, 13h	; EGA
	jb	@@ega
	ja	@@vga
@@mcga_mode:
	cld
	mov         cx, ax
	jcxz	@@l64k		; if buffer < 64K
@@save_loop1:
	push        cx
	sub         cx, cx                  ; CX=64K times
rep         movsb
	pop         cx
	mov         ax, ds
	add         ax, 4096
	mov         ds, ax
	mov         ax, es
	add         ax, 4096
	mov         es, ax
	loop        @@save_loop1
@@l64k:
	mov         cx, dx
rep         movsb

	pop         es
	pop         ds
	ret
@@ega:
;
;	Save graphics screen in EGA modes D-10
;
	push	bx

	mov	bx, 4
	div	bx

	xchg	ax, bx
	mov	cx, dx		; BX:CX=buffer size/4 (bytes)
				; really only CX contains
				; buffer size

	mov	dx, 3CEh
	mov	al, 5		; Mode register
	mov	ah, 0		; 0 reading mode
	out	dx, ax

	mov	ah, 0		; card 0
	mov	al, 4		; card select reg.

@@ega_mode_lp:
	out	dx, ax

	push	cx
	push	cx
	cli
rep	movsb
	pop	cx
	shr	cx, 1
	shr	cx, 1
	mov	di, es
	add	di, cx
	mov	es, di
	pop	cx
	sub	si, si
	sub	di, di
	inc	ah
	cmp	ah, 4
	jb	@@ega_mode_lp

	pop	bx

	pop	es
	pop	ds
	retn

@@vga:
;
;	Save graphics in VGA/eXtended VGA modes (13h+)
;
	push	bx
	xchg	ax, bx
	mov	cx, dx
	mov	ax, 9
	mov	dx, 3CEh
@@save64lp:
	or	bx, bx
	jz	@@end_vga_modes

	push	cx
	mov	cx, -1
rep	movsb
	pop	cx

	inc	ah
	out	dx, ax
	mov	di, es
	add	di, 1000h
	mov	es, di
	sub	si, si
	sub	di, di
	dec	bx
	jmp	@@save64lp
@@end_vga_modes:
rep	movsb
	pop	bx
	pop	es
	pop	ds
	retn

@@graphics_in_XMS:

	cmp	USER_MODE, 0Dh
	jb	@@mcga_XMS
	cmp	USER_MODE, 13h
	jb	@@ega_XMS
	ja	@@vga_XMS
@@mcga_XMS:
	sub         ax, ax
	push        ax                      ; 0=offset in dest
	push        ax                      ; block
	push        VGRAPH_HANDLE           ; dest handle
	push        VGRAPH_BUFFER           ; 0=offset in source
	push        ax                      ; block
	push        ax                      ; 0=source handle (low mem)
	sub         dx, dx
	mov         ax, GRAPH_MODE_BUF
	mov         cx, 6
@@shr_loop2:
	shr         dx, 1
	shr         ax, 1
	jnc         @@shr_on2
	or          dx, 8000h
@@shr_on2:
	loop        @@shr_loop2

	push        ax                      ; Number of bytes
	push        dx                      ; to move
	call        XMS_MOVE
@@exit:
	ret

@@ega_XMS:
;
;	Save EGA modes D-10 in eX. mem.
;


	push	bx
	push	bp

	mov	ax, GRAPH_MODE_BUF
	mov	dx, 256
	mul	dx		; DX:AX=buffer size (bytes)
				; of 1 bit plaane to save

	xchg	ax, di
	mov	si, dx		; SI:DI=buffer size/4 (bytes)

	sub	bx, bx
	sub	bp, bp		; BX:BP=offset in dest block

	mov	dx, 3CEh
	mov	al, 5		; mode control reg.
	mov	ah, 0		; reading mode 0
	out	dx, ax

	mov	cx, 4
	mov	ah, 0
	mov	al, 4		; card select reg.

@@ega_XMS_lp:
	out	dx, ax

	push	ax

	push	bx
	push	bp
	push        VGRAPH_HANDLE

	push	VGRAPH_BUFFER
	sub 	ax, ax
	push	ax
	push	ax

	push	si
	push	di

	call        XMS_MOVE

	pop	ax

	add	bp, di
	adc	bx, si
	inc	ah
	cmp	ah, 4
	jb	@@ega_XMS_lp

	pop	bp
	pop	bx
	retn

@@vga_XMS:
	push	bx

	mov	ax, GRAPH_MODE_BUF
	mov	dx, 1024
	mul	dx		; DX:AX=buffer size (bytes)

	xchg	ax, cx
	mov	bx, dx		; BX:CX=buffer size (bytes)

	sub	si, si
	sub	di, di		; SI:DI=offset in dest

	mov	dx, 3CEh
	mov	ax, 9
@@vga_XMS_lp:
	or	bx, bx
	jz	@@vga_XMS_last

	out	dx, ax

	push	ax

	push	si
	push	di
	push	VGRAPH_HANDLE

	push	VGRAPH_BUFFER
	sub	ax, ax
	push	ax
	push      	ax

	inc	ax
	push	ax
	dec	ax
	push	ax

	call	XMS_MOVE

	pop	ax

	add	ah, 10h
	inc	si
	dec	bx
	jmp	@@vga_XMS_lp
@@vga_XMS_last:
	jcxz	@@save_text-2

	out	dx, ax

	push	si
	push	di
	push	VGRAPH_HANDLE

	push	VGRAPH_BUFFER
	sub	ax, ax
	push	ax
	push	ax

	push	ax
	push	cx

	call	XMS_MOVE
;@@save_text-2:
	pop	bx

	retn
@@save_text:
	cmp         TEXT_MODE_BUF, 0
	jz          @@exit
	sub         si, si                  ; SI=0
	mov         cl, USER_PAGE
	sub         ch, ch                  ; CX=user page
	jcxz        @@end_add
@@add_loop:
	add         si, 4096
	loop        @@add_loop
@@end_add:

	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@text_in_XMS
;--------------------------- Text in real memory ----------------------------
	push        ds
	push        es

	mov         es, USER_V_TEXT
	mov         ds, VTEXT_BUFFER
	mov         cx, 4096
	sub         di, di                  ; di=0
rep         movsb

	pop         es
	pop         ds
	mov         bh, OUR_PAGE
	ret

@@text_in_XMS:
	sub         ax, ax                  ; AX=0
	push        ax                      ; offset in
	push        ax                      ; dest
	push        VTEXT_HANDLE            ; dest handle
	push        VTEXT_BUFFER            ; offset in
	push        si                      ; src
	push        ax                      ; 0=source handle
	push        ax                      ; Number of
	mov         ax, 4096
	push        ax                      ; bytes
	call        XMS_MOVE
	mov         bh, OUR_PAGE
	ret

PALETTE_BUF	DB	17 dup (?)
DAC_BUF	DB	3*256 dup (?)

SAVE_USER_VIDEO  ENDP



RESTORE_MAIN_WIND  PROC
;locals
	cmp         VTEXT_BUFFER, 0B800h
	jz          @@color_mode
	mov         al, 7                   ; INSPECT mode
            mov	OUR_MODE, al
	sub         ah, ah
	int         10h
	jmp         @@go_on
@@color_mode:
	sub         ah, ah
	mov         al, 3                   ; INSPECT mode
            mov	OUR_MODE, al
	int         10h
	mov         ax, 1003h
	sub         bl, bl
	int         10h                     ; disable blink
@@go_on:
	mov         bh, OUR_PAGE
	wherexy
	or          ch, 00100000b
	mov         ah, 1
	int         10h                     ; make cursor invisible
	sub         di, di                  ; restore our page
	mov         cl, OUR_PAGE
	sub         ch, ch
	jcxz        @@main_got
@@add_loop:
	add         di, 1000h
	loop        @@add_loop
@@main_got:
	test        byte ptr PROG_STATUS[1], 10h
	jnz         @@load_from_XMS
	sub         si, si
	push        ds
	push        es
	mov         es, VTEXT_BUFFER
	mov         ds, MAIN_WINDOW
	mov         cx, 4096
	cld
rep         movsb
	pop         es
	pop         ds
	Select_Page OUR_PAGE
	ret
@@load_from_XMS:
	sub         ax, ax
	push        VTEXT_BUFFER            ; Dest
	push        di                      ; offset
	push        ax                      ; Dest handle
	push        ax                      ; Source
	push        ax                      ; offset
	push        MAIN_WIND_HANDLE        ; Source handle
	push        ax                      ; Number of
	mov         ax, 4096
	push        ax                      ; bytes
	call        XMS_MOVE
	Select_Page OUR_PAGE
	ret

RESTORE_MAIN_WIND  ENDP



SHOW_ACT_WINDOW  PROC
	push        ax
	mov         al, byte ptr PROG_STATUS[1]
	and         al, 00000110b
	shr         al, 1
	test        al, al                  ;Prog. status=0?
	jnz         stat_1@
	mov         ah, 7
	mov         al, 1
	push        ax
	mov         ah, 23
	mov         al, 57
	push        ax
	mov         al, AC_WIND_ATTR
	mov         ah, OUR_PAGE
	push        ax
	call        CHANGE_ATTRIBS
	pop         ax
	ret
stat_1@:
	cmp         al, 1
	jnz         stat_2@
	mov         ah, 1
	mov         al, 1
	push        ax
	mov         ah, 5
	mov         al, 78
	push        ax
	mov         al, AC_WIND_ATTR
	mov         ah, OUR_PAGE
	push        ax
	call        CHANGE_ATTRIBS
	pop         ax
	ret
stat_2@:
	cmp         al, 2
	jnz         stat_3
	mov         ah, 7
	mov         al, 59
	push        ax
	mov         ah, 15
	mov         al, 78
	push        ax
	mov         al, AC_WIND_ATTR
	mov         ah, OUR_PAGE
	push        ax
	call        CHANGE_ATTRIBS
	pop         ax
	ret
stat_3:
	mov         ah, 17
	mov         al, 59
	push        ax
	mov         ah, 23
	mov         al, 78
	push        ax
	mov         al, AC_WIND_ATTR
	mov         ah, OUR_PAGE
	push        ax
	call        CHANGE_ATTRIBS
	pop         ax
	ret
SHOW_ACT_WINDOW  ENDP


