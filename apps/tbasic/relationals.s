
;*********************************************************************************
;* relationals.s:
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
	.include	"ilExec.h"

	.include	"relationals.h"


;********************************************************************************
;* Relational operators.
;*	EQ, NEQ, LSS, LEQ, GTR, GEQ
;********************************************************************************

; Some local flag bits..

fEQ	:=	$01
fLT	:=	$02
fGT	:=	$04		; Not used at present


;********************************************************************************
;* This optimises the = and <> tests at the expensse of 7 bytes of RAM.
;*	Is it worth those 7 bytes? Hm...
;********************************************************************************

OPTIMISE_EQ_TEST	:=	1

.ifdef	OPTIMISE_EQ_TEST
.proc	testEq

	ldx	arithPtr		; Get arith stack pointer

	lda	arithStack-4,x
	cmp	arithStack-2,x
	bne	ret
	lda	arithStack-3,x
	cmp	arithStack-1,x
ret:	rts
.endproc
.endif


;********************************************************************************
;* NEQ:
;*	Not equal
;********************************************************************************

.proc	NEQ

.ifdef	OPTIMISE_EQ_TEST
	jsr	testEq
	bne	true
	beq	false
.else
	jsr	multiCmp
	and	#fEQ
	beq	true
	bne	false
.endif

.endproc

;********************************************************************************
;* EQ:
;*	Equal to
;********************************************************************************

.proc	EQ

.ifdef	OPTIMISE_EQ_TEST
	jsr	testEq
	beq	true
;	bne	false			; Fall into false
.else
	jsr	multiCmp
	and	#fEQ
	bne	true			; Zero flag is set
	beq	false
.endif

.endproc


;********************************************************************************
;* The return shenanigans.
;********************************************************************************

false:	lda	#0
	beq	pushResult

true:	lda	#1

pushResult:
	sta	arithStack-4,x		; low byte
	lda	#0
	sta	arithStack-3,x		; High

	dex				; Adjust arith stack pointer
	dex
	stx	arithPtr

; Return via ilReturn

	jmp	ilReturn


;********************************************************************************
;* LSS:
;*	Less than
;********************************************************************************

.proc	LSS
	jsr	multiCmp
	and	#fLT | fEQ
	cmp	#fLT
	beq	true
	bne	false
.endproc


;********************************************************************************
;* LEQ:
;*	Less than or equal to.
;********************************************************************************

.proc	LEQ
	jsr	multiCmp
	and	#fLT | fEQ
	bne	true
	beq	false
.endproc


;********************************************************************************
;* GTR:
;*	Greater than
;********************************************************************************

.proc	GTR
	jsr	multiCmp
	and	#fLT | fEQ
	beq	true
	bne	false
.endproc


;********************************************************************************
;* GEQ:
;*	Greater than or equal
;********************************************************************************

.proc	GEQ
	jsr	multiCmp
	and	#fLT
	beq	true
	bne	false
.endproc


;********************************************************************************
;* multiCmp:
;*	Routime to do all the tests at once and set bits in
;*	a register.
;*	Return the result in A.
;********************************************************************************

.proc	multiCmp

	ldx	arithPtr		; Get arith stack pointer

; Now, run a series of compares to set various flags...

	lda	#0
	sta	num

;  Start by subtracting

	sec
	lda	arithStack-4,x
	sbc	arithStack-2,x
	sta	regAL
	lda	arithStack-3,x
	sbc	arithStack-1,x
	sta	regAH

; Test for zero

	ora	regAL
	bne	notZero
	lda	#fEQ
	sta	num
notZero:

; Test for <

	lda	num
	ldy	regAH
	bpl	notLt

; The result was negative, so LT, ...

	ora	#fLT
	sta	num
notLt:	
	rts
.endproc
