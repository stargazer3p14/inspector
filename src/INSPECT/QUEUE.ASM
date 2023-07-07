Queue86	EQU	6
Queue186	EQU	6
QueueV20	EQU	6
Queue88	EQU	4
Queue188	EQU	4
QueueV30	EQU	4
Queue286	EQU	16
Queue386	EQU	32
Queue486	EQU	32
Queue586	EQU	64

QueueBuf	DB	Queue586 dup(?)
QueueLen	DW	0
CPU_Tag	DW	0		; 86h|88h|186h|188h|286h|386h
				; |486h|586h
SubType	DW	0
	DB	0
TestWord	DW	?

OFFS6	dw	?
SEGM6	dw	?

Detect_CPU	PROC	near
	mov	ax, 1
	mov	cl, 64
	shl	ax, cl
	or	ax, ax
	jz	i86_88

	push	sp
	pop	ax
	cmp	ax, sp
	jnz	i186_188_v

;
;	CPU is 80286+
;
.486
	push	es
	mov	ax, 3506h
	int	21h
	mov	OFFS6, bx
	mov	SEGM6, es
	pop	es
	mov	dx, offset Test_Int6
	mov	ax, 2506h
	int	21h
	push	offset i286
	xor	eax, eax
	inc	sp
	inc	sp
	push	offset i386
	xadd	ax, bx
	inc	sp
	inc	sp
	push	offset i486
;
;	PENTIUM	command
;
	mov	eax, 1
	db	00Fh, 0A2h

	inc	sp
	inc	sp
	jmp	i586
.8086
i86_88:
	call	Detect_QLen
	or	ax, ax
	jnz	@F
	mov	CPU_Tag, 86h
	mov	QueueLen, Queue86
	retn
@@:
	mov	CPU_TAg, 88h
	mov	QueueLen, Queue88
	retn

i186_188_v:
	sub	ax, ax
	mov	al, 1
	mov	ah, al
	mul	ah
	jz	v20_30

	call	Detect_QLen
	or	ax, ax
	jnz	@F
	mov	CPU_Tag, 186h
	mov	QueueLen, Queue186
	retn
@@:
	mov	CPU_Tag, 188h
	mov	QueueLen, Queue188
	retn
v20_30:
	call	Detect_QLen
	or	ax, ax
	jnz	@F
	mov	CPU_Tag, 20h
	mov	QueueLen, QueueV20
	retn
@@:
	mov	CPU_Tag, 30h
	mov	QueueLen, QueueV30
	retn
i286:
	mov	CPU_Tag, 286h
	mov	QueueLen, Queue286
	retn
i386:
	mov	CPU_Tag, 386h
	mov	QueueLen, Queue386
	retn
i486:
	mov	CPU_Tag, 486h
	mov	QueueLen, Queue486
	retn
i586:
.486
	mov	cl, al
	mov	al, 86h
	mov	CPU_Tag, ax
	shr	ax, 12
	cmp	ax, 4
	jnz	@F
	mov	QueueLen, Queue486
	shr	cl, 4
	cmp	cl, 1
	jnz	NOT486DX
	mov	SubType, 'XD'
	retn
NOT486DX:
	cmp	cl, 2
	jnz	NOT486SX
	mov	SubType, 'XS'
	retn
NOT486SX:
	cmp	cl, 3
	jnz	NOT486DX2
	mov	SubType, 'XD'
	mov	byte ptr SubType[2], '2'
	retn
NOT486DX2:
	retn
.8086
@@:
	mov	QueueLen, Queue586
	retn
Detect_CPU	ENDP


Detect_QLen	PROC	near
	mov	TestWord, 0
	mov	polygon[4], 1234h
polygon	label	word
	mov	TestWord, 3
	sub	ax, ax		; AX=0 -> x86, v20
	cmp	TestWord, 0
	jz	@F
	retn
@@:
	inc	ax		; AX=1 -> x88, v30
	retn

Detect_QLen	ENDP


Test_Int6	PROC	near
	add	sp, 6
	ret
Test_Int6	ENDP

Restore6	PROC	near
	push	ds
	mov	ax, 2506h
	mov	dx, OFFS6
	mov	ds, SEGM6
	int	21h
	pop	ds
	ret
Restore6	ENDP





