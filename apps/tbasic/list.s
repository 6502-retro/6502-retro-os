
;*********************************************************************************
;* list.s:
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

	.include	"data.h"
	.include	"system.h"
	.include	"ilUtils.h"
	.include	"print.h"

	.include	"list.h"


;********************************************************************************
;* listProg:
;*	List a program.
;*	Lists the entire program - no way to just list a line or 2 yet.
;********************************************************************************

.proc	listProg
	jsr	resetCursor

; Force print width to 5 (Store 4 in the @ variable)

	lda	#4
	sta	variablesL+0

; Check for end..

listLoop:
	ldy	#0
	lda	(cursor),y		; Get high byte of line number
	bpl	:+			; Top bit set is probably $FF which is end of text market

	rts

; Store line number in regA and call pDec directly

:	sta	regAH
	iny
	lda	(cursor),y		; Get low byte
	sta	regAL

	jsr	pDec
	lda	#' '			; Followed by a space
	jsr	putChar

	ldy	#3			; pDec corrupts X & Y. This takes to first byte of line.

printLine:
	lda	(cursor),y
	cmp	#$0D			; CR, end of line?
	beq	eol
	jsr	putChar
	iny
	bne	printLine

eol:
	jsr	newLine
	iny				; Jump over the CR

; Set the cursor to the current (cursor),y location:

	clc
	tya
	adc	cursorL
	sta	cursorL
	bcc	:+
	inc	cursorH
:

	jmp	listLoop
.endproc
