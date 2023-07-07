;           This file contains non-critical White & Black
;                       phantoms executing inspector errors
;           and routine that outputs messages.

ERRORCODE   DW          0           ;ERRORCODE=0 -> no error

;                       Here are the messages:

;                       Code 1
EARLY_DOS   DB          "Can't work under DOS earlier that 2.00. "
ERR1_L      EQU         $-EARLY_DOS

;                       Code 2
MEM_ERROR   DB          "Not enough memory. "
ERR2_L      EQU         $-MEM_ERROR

;                       Code 3
VIDEO_MEM_ERR DB        "Not enough memory for video buffer. "
ERR3_L      EQU         $-VIDEO_MEM_ERR

;                       Code 4
FILE_N_FND  DB          "Can't find the file. "
ERR4_L      EQU         $-FILE_N_FND

;                       Code 5
PATH_N_FND  DB          "The path is invalid. "
ERR5_L      EQU         $-PATH_N_FND

;                       Code 6
MANY_FILES  DB          "Too many files currently opened. "
ERR6_L      EQU         $-MANY_FILES

;                       Code 7
NO_CREATE   DB          "Can't create file. "
ERR7_L      EQU         $-NO_CREATE

;                       Code 8
ASSM_ERR    DB          "Illegal instruction (operands). "
ERR8_L      EQU         $-ASSM_ERR

;                       Code 9
ROM_MEMORY  DB          "Cannot access read-only memory. "
ERR9_L      EQU         $-ROM_MEMORY

;                       Code 10
DIR_ERR     DB          "Can't find directory. "
ERR10_L     EQU         $-DIR_ERR

;                       Code 11
WRONG_DRIVE DB          "The drive letter is illegal. "
ERR11_L     EQU         $-WRONG_DRIVE

;                       Code 12
COMMAND_ERR DB          "Cannot execute DOS Shell while program is loaded. "
ERR12_L     EQU         $-COMMAND_ERR

;                       Code 13
PRINT_ERR   DB          "The printer is off-line. "
ERR13_L     EQU         $-PRINT_ERR

;                       Code 14
NO_PAPER    DB          "The printer is out of paper. "
ERR14_L     EQU         $-NO_PAPER

;		Code 15
BAD_FORMAT	DB	"Bad format for .EXE module. "
ERR15_L	EQU	$-BAD_FORMAT


PR_ESC      DB          "Press ESC. "
PR_ESC_L    EQU         $-PR_ESC

ERR_ADDRS   DW          offset EARLY_DOS, offset MEM_ERROR, offset VIDEO_MEM_ERR
            DW          offset FILE_N_FND, offset PATH_N_FND, offset MANY_FILES
            DW          offset NO_CREATE, offset ASSM_ERR, offset ROM_MEMORY
            DW          offset DIR_ERR, offset WRONG_DRIVE, offset COMMAND_ERR
	DW          offset PRINT_ERR, offset NO_PAPER, BAD_FORMAT
ERR_LENS    DW          ERR1_L, ERR2_L, ERR3_L, ERR4_L, ERR5_L, ERR6_L
            DW          ERR7_L, ERR8_L, ERR9_L, ERR10_L, ERR11_L, ERR12_L
	DW          ERR13_L, ERR14_L, ERR15_L


ERR_HANDLER PROC
;LOCALS
;----------------------------------------------------------------------------
;                       ERRORCODE = error code
;----------------------------------------------------------------------------
            $STO_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            mov         bh, OUR_PAGE
            mov         bl, ERR_ATTR
            gotoxy      1, 23
            mov         al, ' '
            mov         ah, 9
            mov         cx, 78
            int         10h
            mov         si, ERRORCODE
            dec         si
            shl         si, 1
            mov         cx, ERR_LENS[si]
            mov         si, ERR_ADDRS[si]
            call        CPUTSTR
            mov         si, offset PR_ESC
            mov         cx, PR_ESC_L
            call        CPUTSTR
            and         PROG_STATUS, 7FFFh
            WHEREXY
            or	ch, 00100000b
            mov	ah, 1
            int	10h
@@loop:
	call	GETCH	         	; Here F10 gives help
				; about error that occur
            cmp         ah, 1
            jnz         @@loop
            mov         ERRORCODE, 0
            $LOD_SCREEN 1, 23, 78, 23, SCR_ERR_BUF, OUR_PAGE
            retn
ERR_HANDLER ENDP
