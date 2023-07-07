FRAME       PROC
;LOCALS
		; Builds the main program frame
	push        bx
	push        cx
	push        si
	mov         bl, TOP_FRAME_ATTR
	mov         cx, 1
	gotoxy      0, 0
	mov         al, 'Õ'
	mov         ah, 9
	int         10h
	gotoxy      79
	mov         al, '¸'
	mov         ah, 9
	int         10h
	gotoxy      0, 24
	mov         al, 'Ô'
	mov         ah, 9
	int         10h
	gotoxy      79
	mov         al, '¾'
	mov         ah, 9
	int         10h
	mov         dh, 1
	mov         al, '³'
frame_loop_1:
	gotoxy      0
	mov         ah, 9
	int         10h
	gotoxy      79
	mov         ah, 9
	int         10h
	inc         dh
	cmp         dh, 24
	jb          frame_loop_1
	gotoxy      1, 0
	mov         al, 'Í'
	mov         cx, 3
	mov         ah, 9
	int         10h
	dec         cx
	gotoxy      71
	mov         cx, 8
	mov         ah, 9
	int         10h
	gotoxy      1, 6
	mov         cx, 78
	mov         ah, 9
	int         10h
	gotoxy      1, 24
	mov         cx, 3
	mov         ah, 9
	int         10h
	gotoxy      76
	mov         ah, 9
	int         10h
	gotoxy      59, 16
	mov         cx, 20
	mov         ah, 9
	int         10h
	gotoxy      59, 13
	mov         al, 'Ä'
	mov         ah, 9
	int         10h
	mov         dh, 7
	mov         al, '³'
frame_loop_2:
	mov         cx, 1
	gotoxy      58
	mov         ah, 9
	int         10h
	inc         dh
	cmp         dh, 24
	jb          frame_loop_2
	gotoxy      0, 6
	mov         al, 'Æ'
	mov         ah, 9
	int         10h
	gotoxy      58
	mov         al, 'Ñ'
	mov         ah, 9
	int         10h
	gotoxy      79
	mov         al, 'µ'
	mov         ah, 9
	int         10h
	gotoxy      58, 13
	mov         al,'Ã'
	mov         ah, 9
	int         10h
	gotoxy      79
	mov         al, '´'
	mov         ah, 9
	int         10h
	gotoxy      58, 16
	mov         al, 'Æ'
	mov         ah, 9
	int         10h
	gotoxy      79
	mov         al, 'µ'
	mov         ah, 9
	int         10h
			;now lines of the frame are drawn
	mov         bl, TOP_ATTR
	lea         si, TOP_LINE
	mov         cx, 6
	gotoxy      3, 0
frame_loop_3:
	push        cx
	mov         cx, TOP_LINE_L
	call        cputstr
	cmp         cx, 1
	jz          frame_exit_1
	push        si
	lea         si, SPACES
	mov         cx, 2
	call        cputstr
	pop         si
	add         si, TOP_LINE_L
	pop         cx
	loop        frame_loop_3
frame_exit_1:
	gotoxy      63, 6
	lea         si, ___REGS
	mov         cx, 11
	call        cputstr
	gotoxy      65, 16
	lea         si, ___STACK
	mov         cx, 7
	call        cputstr
	gotoxy      3, 24
	lea         si, ___RIGHTS
	mov         cx, ___RIGHTS_L
	call        cputstr
	lea         si, ___MODULE
	mov         cx, ___MODULE_L
	call        cputstr
	test        byte ptr PROG_STATUS, 8
	jnz         @@module
	mov         si, offset NO_MODULE
	mov         cx, 13
	call        CPUTSTR
	jmp         @@queue
@@module:
	mov         si, offset LD_MODULE
	mov         cx, 13
	call        CPUTSTR
@@queue:
IFDEF	PREFETCH_EMUL
	GOTOXY	11, 6
	mov	si, offset ___QUEUE
	mov	cx, ___QUEUE_L
	mov	bl, SELECT_ATTR
	call	CPUTSTR
ENDIF
@@ret:
	pop         si
	pop         cx
	pop         bx
	ret

___REGS     DB          ' REGISTERS '
___STACK    DB          ' STACK '
___RIGHTS   DB          ' WHITE & BLACK PHANTOMS EXECUTING INSPECTOR'
	DB          4 DUP (26)
___RIGHTS_L EQU         $-___RIGHTS
___MODULE   DB          'LOADED MODULE:'
___MODULE_L EQU         $-___MODULE
___QUEUE	DB	' CS:PC  '
___QUEUE_L	EQU	$-___QUEUE

SPACES      DB          2 DUP (' ')
TOP_FRAME_ATTR  DB      7
TOP_ATTR    DB          0F0h
TOP_LINE    DB          ' File(F1)', 3 DUP (0)
TOP_LINE_L  EQU         $-TOP_LINE
	DB          'Tools(F2)', 3 DUP (0) 
	DB          'Specials(F3)'
	DB          'Print(F4)', 3 DUP (0)
	DB          'Debug(F5)', 3 DUP (0)
	DB          'Help(F10)', 2 DUP (0)

FRAME       ENDP
