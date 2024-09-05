
;*********************************************************************************
;* logic.s:
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

	.include	"logic.h"


;********************************************************************************
;* Logical operators.
;*	AND, OR and NOT
;********************************************************************************


;********************************************************************************
;* AND:
;*	Also has all the return shenanigans.
;********************************************************************************

.proc	andOP
	ldx	arithPtr
	lda	arithStack-2,x		; Low
	and	arithStack-4,x		; Low
	sta	arithStack-4,x

	lda	arithStack-1,x		; Low
	and	arithStack-2,x		; Low
	sta	arithStack-2,x		; ... and fall into
.endproc

.proc	aoRet
	dex
	dex
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* OR:
;********************************************************************************

.proc	orOP
	ldx	arithPtr
	lda	arithStack-2,x		; Low
	ora	arithStack-4,x		; Low
	sta	arithStack-4,x

	lda	arithStack-1,x		; Low
	ora	arithStack-2,x		; Low
	sta	arithStack-2,x

	jmp	aoRet
.endproc


;********************************************************************************
;* EOR:
;********************************************************************************

.proc	eorOP
	ldx	arithPtr
	lda	arithStack-2,x		; Low
	eor	arithStack-4,x		; Low
	sta	arithStack-4,x

	lda	arithStack-1,x		; Low
	eor	arithStack-2,x		; Low
	sta	arithStack-2,x

	jmp	aoRet
.endproc


;********************************************************************************
;* NOT:
;*	Logical NOT - 0 -> 1 and anything non-zero -> 0
;* NOTE:
;*	This used to be a Ones compliment operation...
;********************************************************************************

.proc	notOP
	ldx	arithPtr

	lda	arithStack-2,x		; Low
	ora	arithStack-1,x		; High
	beq	ret1

; Non-zero (true), so return 0 (false)

	lda	#0
	sta	arithStack-1,x		; High
notOP1:
	sta	arithStack-2,x		; Low
	rts

; Zero (false), so return 1 (true)

ret1:
	sta	arithStack-1,x		; High
	lda	#1
	bne	notOP1
.endproc
