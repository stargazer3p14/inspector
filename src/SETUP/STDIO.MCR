QOPEN       MACRO       F_NAME, MODE
ifnb        <F_NAME>
            mov         dx, offset F_NAME
endif
            mov         ah, 3Dh
            mov         al, MODE
            int         21h
ENDM


QCREATE     MACRO       F_NAME, ATTR
            mov         dx, offset F_NAME
            mov         cx, ATTR
            mov         ah, 3Ch
            int         21h
ENDM


QCLOSE      MACRO       HANDLE
            push        bx
            mov         bx, HANDLE
            mov         ah, 3Eh
            int         21h
            pop         bx
ENDM


QREAD       MACRO       HANDLE, BUFFER, BYTES
            push        bx
            push        cx
            push        dx
            mov         bx, HANDLE
            mov         dx, offset BUFFER
            mov         cx, BYTES
            mov         ah, 3Fh
            int         21h
            pop         dx
            pop         cx
            pop         bx
ENDM


QWRITE      MACRO       HANDLE, BUFFER, BYTES
            push        bx
            push        cx
            push        dx
            mov         bx, HANDLE
            mov         dx, offset BUFFER
            mov         cx, BYTES
            mov         ah, 40h
            int         21h
            pop         dx
            pop         cx
            pop         bx
ENDM


MOVE_PTR    MACRO       HANDLE, HIGH_OFF, LOW_OFF, METH
            push        bx
            push        cx
            mov         bx, HANDLE
            mov         cx, HIGH_OFF
            mov         dx, LOW_OFF
            mov         ah, 42h
            mov         al, METH
            int         21h
            pop         cx
            pop         bx
ENDM


CH_DIR      MACRO       NEW_DIR
            mov         dx, offset NEW_DIR
            mov         ah, 3Bh
            int         21h
ENDM


SET_BLOCK   MACRO       LAST_B
            mov         bx, offset LAST_B
            mov         cl, 4
            shr         bx, cl
            inc         bx
            mov         ah, 4Ah
            int         21h
ENDM


FREE        MACRO       SEG_ADDR
            mov         es, SEG_ADDR
            mov         ah, 49h
            int         21h
ENDM


ALLOC       MACRO       BYTES
            mov         bx, BYTES
            mov         cl, 4
            shr         bx, cl
            inc         bx
            mov         ah, 48h
            int         21h
ENDM


GOTOXY      MACRO       X, Y
ifnb        <X>
            mov         dl, X
endif
ifnb        <Y>
            mov         dh, Y
endif
	push	ax
	push	dx
	mov         ah, 2
	int         10h
	pop	dx
	pop	ax
ENDM


WHEREXY     MACRO
	push	ax
	mov         ah, 3
	int         10h
	pop	ax
ENDM


SELECT_PAGE MACRO       PAGE
            mov         ah, 5h
            mov         al, PAGE
            int         10h
ENDM



GET_VECTOR  MACRO       INTR
            mov         ah, 35h
            mov         al, INTR
            int         21h
ENDM



SET_VECTOR  MACRO       INTR
            mov         ah, 25h
            mov         al, INTR
            int         21h
ENDM



GET_CURR_DIR MACRO      BUFFER
            mov         si, offset BUFFER
            mov         ah, 47h
            int         21h
ENDM

