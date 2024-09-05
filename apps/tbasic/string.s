
;*********************************************************************************
;* string.s:
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
	.include	"error.h"
	.include	"ilMacros.h"

	.include	"string.h"


;********************************************************************************
;* putString:
;*	String constant assignment.
;*	Handles:
;*	  $ factor = "string"
;********************************************************************************

.proc	putString
	ldy	#0
putLoop:
	lda	(cursor),y	; Get character from program text
	incCursor
	cmp	#'"'		; end?
	beq	stringEnd
	cmp	#$0D		; Make sure it's not a CR (end of prog. line)
	beq	strOops

	sta	(regA),y
	inc	regAL
	bne	putLoop
	inc	regAH
	bne	putLoop

stringEnd:
	lda	#$0D		; Append CR to string and return
	sta	(regA),y
	rts

strOops:
	lda	#eEND
	jmp	progErr
.endproc


;********************************************************************************
;* moveString:
;*	Move String
;*	Handles:
;*	  $ factor = $ factor
;*	Uses regB and regC.
;********************************************************************************

.proc	moveString
	ldx	arithPtr
	lda	arithStack-4,x
	sta	regBL
	lda	arithStack-3,x
	sta	regBH
	lda	arithStack-2,x
	sta	regCL
	lda	arithStack-1,x
	sta	regCH

	ldy	#0
loop:	lda	(regC),y
	sta	(regB),y
	cmp	#$0D
	beq	done
	iny
	bne	loop

done:
	dex
	dex
	dex
	dex
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* iString:
;*	Input a string
;*	Handles:
;*	  INPUT $ factor
;*	Input buffer in Cursor, destination in regA, CR terminated.
;********************************************************************************


.proc	iString
	ldy	#$FF
loop:
	iny
	lda	(cursor),y
	sta	(regA),y
	cmp	#$0D
	bne	loop
	rts
.endproc
