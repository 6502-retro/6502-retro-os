
;*********************************************************************************
;* ilUtils.s:
;*********************************************************************************

;********************************************************************************
;* This file is part of gibl:							*
;*	Gordons Interactive Basic Language                                      *
;********************************************************************************
;*    A Tiny Basic for the 6502 inspired by the NIBL Tiny Basic interpreter;	*
;*    "National Industrial Basic Language" originally for the INS8060 SC/MP	*
;*    system.									*
;*										*
;*    gibl is distributed under a "Source Available" license.			*
;*	It is NOT Open source and must not be treated as such.			*
;*										*
;*    See the file LICENSE for details.						*
;*										*
;*    gibl is Copyright (c) 2023 by Gordon Henderson				*
;********************************************************************************

	.macpack	generic

	.include	"data.h"
	.include	"error.h"
	.include	"system.h"

	.include	"il.h"
	.include	"ilMacros.h"
	.include	"ilExec.h"
	.include	"findLine.h"

	.include	"ilUtils.h"


;********************************************************************************
;* clear:
;*	clear all variables to zero and initialise the stacks
;********************************************************************************

.proc	clear
	lda	#0
	ldx	#varSize-1
:
	sta	variables,x
	dex
	bpl	:-

	sta	arithPtr	; Arithmetic stack
	sta	doPtr		; DO stack
	sta	sbrPtr		; GOSUB stack
	sta	forPtr		; FOR stack
	sta	runMod		; Running or not.
	sta	pcPtr		; I.L. call stack
	rts
.endproc


;********************************************************************************
;* storeV:
;*	Store variable from stack to RAM.
;********************************************************************************

.proc	storeV
	ldx	arithPtr
	ldy	arithStack-3,x	; Get variable index
	lda	arithStack-2,x	; Low byte
	sta	variablesL,y
	lda	arithStack-1,x	; High byte
	sta	variablesH,y
	dex			; Fix arith. stack pointer
	dex
	dex
	stx	arithPtr	; ... as it's the new stack pointer
	rts
.endproc


;********************************************************************************
;* loadV:
;*	Pops variable name (index) off stack, then fetches that variable and
;*	puts it on the stack.
;********************************************************************************

.proc	loadV
	ldx	arithPtr
	ldy	arithStack-1,x		; Get variable index
	lda	variablesL,y
	sta	arithStack-1,x
	lda	variablesH,y
	sta	arithStack-0,x
	inc	arithPtr
	rts
.endproc


;********************************************************************************
;* resetCursor:
;*	Move cursor (text pointer) to the start of the stored program
;********************************************************************************

.proc	resetCursor
	lda	osPageL
	sta	cursorL
	lda	osPageH
	sta	cursorH
	rts
.endproc


;********************************************************************************
;* saveCursor: restoreCursor:
;*	Save the cursor (text pointer) and restore it.
;********************************************************************************

.proc	saveCursor
	lda	cursorL
	sta	svCursorL
	lda	cursorH
	sta	svCursorH
	rts
.endproc

.proc	restoreCursor
	lda	svCursorL
	sta	cursorL
	lda	svCursorH
	sta	cursorH
	rts
.endproc
	

;********************************************************************************
;* popAE:
;*	Pop arithmetic expression stack into lo, hi
;********************************************************************************

.proc	popAE
	ldx	arithPtr
	dex			; Points to hi
	lda	arithStack,x
	sta	regAH
	dex
	lda	arithStack,x
	sta	regAL
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* push1:
;*	Push 1 into the arithmetic stack
;*	(Used in FOR without a step)
;********************************************************************************

.proc	push1
	ldx	arithPtr
	lda	#1	;ldy	#1
	sta	arithStack,x	; Push low byte first
	inx
	lda	#0	;dey			; To zero - high byte
	sta	arithStack,x
	inx
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* newProg:
;*	Clear current program
;*	Reset cursor and store $FF at the start of the program area
;********************************************************************************

.proc	newProg
	jsr	resetCursor

	lda	#$FF
	ldy	#0
	sta	(cursor),y

; Set TOP to cursor

	lda	cursorL
	sta	topL
	lda	cursorH
	sta	topH

	rts
.endproc


;********************************************************************************
;* oldProg
;*	See if we can recover an old program in RAM
;********************************************************************************

.proc	oldProg

; See if first line is vaguely valid:

	jsr	resetCursor
	ldy	#2			; Length byte offset
	lda	(cursor),y		; Get line length
	tay
	dey				; to get end of first line
	lda	(cursor),y
	cmp	#$0D			; Should be a CR
	beq	:+

	lda	#eBAD
	jmp	progErr

; OK. At this point, it's as good a check for a valid program as it'll get...

:	lda	#0
	tay
	sta	(cursor),y		; Zero first byte - high byte of line number

; but we also need to find the end of the program to set TOP...

	dey				; Set regA to $FFFF which is a line number
	sty	regAL			; ... we can never have
	sty	regAH

	jsr	findLine		; ... then try to find it

	lda	cursorL			; Copy end address into TOP
	sta	topL
	lda	cursorH
	sta	topH

	rts
.endproc


;********************************************************************************
;* pokeByte: pokeWord:
;*	Move a byte to RAM/IO/etc. used in the ? and ! commands
;*	@stack [1] := stack [0]
;********************************************************************************

.proc	pokeCommon
	ldx	arithPtr
	lda	arithStack-1,x		; High byte of value
	sta	regBH
	lda	arithStack-2,x		; Low byte
	sta	regBL
	lda	arithStack-3,x		; High byte of address
	sta	regCH
	lda	arithStack-4,x		; Low byte
	sta	regCL
	dex				; Fix arith stack
	dex
	dex
	dex
	stx	arithPtr

	ldy	#0			; Poke low byte
	lda	regBL
	sta	(regC),y
	rts
.endproc

pokeByte	=	pokeCommon

.proc	pokeWord
	jsr	pokeCommon
	iny
	lda	regBH
	sta	(regC),y
	rts
.endproc


;********************************************************************************
;* peekByte: peekWord:
;*	Peek RAM - used in the ? and ! commands
;*	stack [0] := @ stack [0]
;********************************************************************************

.proc	peekCommon
	ldx	arithPtr
	lda	arithStack-1,x		; Get H
	sta	regCH
	lda	arithStack-2,x		; Get L
	sta	regCL
	ldy	#0
	lda	(regC),y
	sta	arithStack-2,x		; Store L
	rts
.endproc

.proc	peekByte
	jsr	peekCommon
	lda	#0
	sta	arithStack-1,x
	rts
.endproc

.proc	peekWord
	jsr	peekCommon
	iny
	lda	(regC),y
	sta	arithStack-1,x
	rts
.endproc


;********************************************************************************
;* comment:
;*	REMarkable
;*	Note: Leave cursor at char immediately before the CR as DONE/NXT will
;*	cater for that.
;********************************************************************************

.proc	comment
	ldy	#0
rem0:
	lda	(cursor),y
	cmp	#$0D
	beq	:+
	incCursor
	bne	rem0
:	rts
.endproc


;********************************************************************************
;* getTop:
;*	Return TOP of RAM for the TOP keyword.
;*	However, the system TOP represents the last byte of the program, a $FF
;*	so we'll add 1 to it for BASIC programs so storing strings won't
;*	overwrite the $FF marker...
;********************************************************************************

.proc	getTop
	ldx	arithPtr
	clc
	lda	topL
	adc	#1
	sta	arithStack,x
	inx
	lda	topH
	adc	#0
	sta	arithStack,x
	inx
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* getPage:
;*	Return PAGE - the start of program memory
;********************************************************************************

.proc	getPage
	ldx	arithPtr
	lda	osPageL
	sta	arithStack,x
	inx
	lda	osPageH
	sta	arithStack,x
	inx
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* getHex:
;*	Get hexadecimal number
;********************************************************************************

.proc	getHex
	lda	#0
	tay
	sta	regBL
	sta	regBH
	sta	num			; Count number of digits
	beq	nextDigit0

; Get digit

nextHex:
	incCursor

nextDigit0:
	lda	(cursor),y

	cmp	#'A'
	blt	notLetter
	cmp	#'F'+1
	blt	doLetter

notLetter:
	cmp	#'0'
	blt	notDigit
	cmp	#'9'+1
	blt	doDigit

notDigit:
	lda	num			; See how many digits
	beq	hexErr

pushHex:
	ldx	arithPtr
	lda	regBL
	sta	arithStack,x
	inx
	lda	regBH
	sta	arithStack,x
	inx
	stx	arithPtr
	rts

hexErr:	
	lda	#eSNTX
	jmp	progErr

doDigit:
	and	#$0F

shiftIn:
	ldy	#4
:	asl	regBL
	rol	regBH
	dey
	bne	:-

	ora	regBL
	sta	regBL
	
	inc	num
	bne	nextHex			; Note: Leaves Y at 0 for sta above.

doLetter:
	sec
	sbc	#55
	bne	shiftIn
.endproc


;********************************************************************************
;* runMode:
;*	Cause an error if not in RUN mode
;********************************************************************************

.proc	runMode
	lda	runMod
	beq	notRunning
	rts
notRunning:
	lda	#eSTMT
	jmp	progErr
.endproc



;********************************************************************************
;* callML:
;*	CALL factor
;*	Calls a machine language routine - address in hi/lo
;********************************************************************************

.proc	callML
	jsr	doCall		; And hope we return...
	rts
doCall:	jmp	(regA)
.endproc
