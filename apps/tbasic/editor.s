
;*********************************************************************************
;* editor.s:
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

	.include	"editor.h"


;********************************************************************************
;* editor:
;*	Insert/Replace/Delete a line in the program text.
;********************************************************************************
;* Pointer to line buffer is in svCursor.
;* Cursor points to the insertion point in the text.
;*
;* Each line is stored in the following format:
;*    Two bytes containing the line number (in binary, high byte first)
;*    One byte containing the length.
;*    The line text itself terminated by a CR.
;*    The last line is followed by $FF
;********************************************************************************

.proc	editor

; Copy line number out of regA into hiLine/loLine

	lda	regAL
	sta	loLine
	lda	regAH
	sta	hiLine

; Get line length

	ldx	#4			; Start at 4 - line number, len, CR
	ldy	#0
:	lda	(svCursor),y
	cmp	#$0D
	beq	:+
	inx
	iny
	bne	:-
:

; If length is 4 and not an exact match from FLBL above, then we can return
;	(Trying to delete a non-existant line)

	cpx	#4
	bne	notEmptyLine

; OK. Length is 4. Was it an exact match?

	lda	findlFlag
	bpl	exact4

; Not an exact match, so trying to delete a non-existant line, so...

	rts		

; It's a zero length line that exists, so ...

exact4:
	jsr	deleteLine
	rts

; Line length not 4, so...

notEmptyLine:
	lda	findlFlag		; If line does not exists then we insert new, else ...
	bmi	insertNew
	jsr	deleteLine		; ... and fall into insert
.endproc


;********************************************************************************
;* insertNew:
;*	Insert a new line
;********************************************************************************

.proc	insertNew

; Make space for the new line

; cursor points to the first byte of RAM to use,
;	'top' is stored in topL/topH

; Copy top to regB

	lda	topL
	sta	regBL
	lda	topH
	sta	regBH

; regC = Line length + regB

	clc
	txa
	adc	regBL
	sta	regCL
	lda	regBH
	adc	#0
	sta	regCH

; New Top is regC

	lda	regCL
	sta	topL
	lda	regCH
	sta	topH

; Move upwards in reverse from regB to regC until regB = the cursor position.

	ldy	#0
nextByte:
	lda	(regB),y
	sta	(regC),y

	lda	regBL
	cmp	cursorL
	beq	testHi
decs:
	lda	regBL
	bne	:+
	dec	regBH
:	dec	regBL

	lda	regCL
	bne	:+
	dec	regCH
:	dec	regCL

	jmp	nextByte

testHi:
	lda	regBH
	cmp	cursorH
	bne	decs

; Now, copy the line into @cursor ...
; Copy line number and length
;	Remember - line number is stored HIGH byte first.

	ldy	#0
	lda	hiLine
	sta	(cursor),y
	iny
	lda	loLine
	sta	(cursor),y
	iny
	txa			; Length
	sta	(cursor),y

;; Optimise - copy until CR?
	dex			; Remove the +4 we started with
	dex
	dex
	dex

; Adjust cursor so we have a zero index

	clc
	lda	cursorL
	adc	#3
	sta	cursorL
	bcc	:+
	inc	cursorH
:

	ldy	#0
:	lda	(svCursor),y	; Input
	sta	(cursor),y	; Store
	iny
	dex
	bpl	:-

	rts
.endproc


;********************************************************************************
; deleteLine:
;	Delete the line at the cursor...
;********************************************************************************

.proc	deleteLine

; Move from cursor+len to cursor until we hit the FF
;	subract len from top

	ldy	#2
	lda	(cursor),y		; Get len
	tay

; Copy cursor to regB and cursor+len into regC

	lda	cursorL
	sta	regBL
	lda	cursorH
	sta	regBH

	tya
	clc
	adc	cursorL
	sta	regCL
	lda	cursorH
	adc	#0
	sta	regCH

	ldy	#0
copyLoop:
	lda	(regC),y
	sta	(regB),y
	cmp	#$FF
	beq	copyDone

	inc	regCL
	bne	:+
	inc	regCH
:
	inc	regBL
	bne	:+
	inc	regBH
:
	bne	copyLoop

; regB is the new top

copyDone:
	lda	regBL
	sta	topL
	lda	regBH
	sta	topH

; and we're done

	rts
.endproc
