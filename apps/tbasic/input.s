
;*********************************************************************************
;* input.s:
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

	.include	"input.h"

;********************************************************************************
;* doGetChar:
;*	Get a single character from the keyboard and push it into the stack
;*	... GET A
;********************************************************************************

.proc	doGetChar
	jsr	getChar

	ldx	arithPtr
	sta	arithStack,x		; Low byte
	inx
	lda	#0
	sta	arithStack,x		; High
	inx
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* doGetLine:
;*	Prompt and read in a line of text.
;*	Returns with the cursor set to the start address.
;********************************************************************************

.proc	doGetLine
	lda	runMod		; Check run/interactive mode:
	beq	interactive
	lda	#'?'		; Running, so INPUT statement, so ? prompt
	bne	:+
interactive:
	lda	#'>'		; Interactive prompt
:	jsr	getLine		; Call system getLine with prompt

	lda	#<lineInput	; Set cursor to start of input buffer
	sta	cursorL
	lda	#>lineInput
	sta	cursorH

	rts
.endproc
