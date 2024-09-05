
;*********************************************************************************
;* findLine.s:
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
	.include	"ilUtils.h"

	.include	"findLine.h"


;********************************************************************************
;* findLine:
;*	Search the program space for a line number stored in regA.
;*	Set the cursor to the address in the program whos line is > or = to
;*	the one we're searching for.
;*	Set the top-bit of findFlag if exact line is NOT found.
;*
;* Note: Program line numbers are stored High byte first!
;********************************************************************************

.proc	findLine

; Set cursor to start of text

	jsr	resetCursor

findLineLoop:
	ldy	#0
	lda	(cursor),y		; Check high byte of line number...
	bmi	inexact			; Line numbers are positive and last byte of program is $FF

; Test for exact

	cmp	regAH
	bne	testGT
	iny
	lda	(cursor),y		; Low
	cmp	regAL
	bne	testGT

; We have an exact match, 
;	Set exact match flag and return

	lda	#0

saveFlag:
	sta	findlFlag
	rts

testGT:
	lda	regAH		; Get high byte
	ldy	#0
	cmp	(cursor),y
	bcc	inexact
	bne	lower
	lda	regAL		; Get low byte
	iny
	cmp	(cursor),y
	bcc	inexact		; if >=

; Lower - move to the next line

lower:
	ldy	#2
	lda	(cursor),y		; Get line length byte
	clc
	adc	cursorL
	sta	cursorL
	bcc	findLineLoop
	inc	cursorH
	jmp	findLineLoop

; Inexact match:
;	Set flag bit and return

inexact:
	lda	#$80
	jmp	saveFlag

.endproc
