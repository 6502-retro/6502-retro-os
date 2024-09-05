
;*********************************************************************************
;* goto.s:
;*	Code for GOTO, GOSUB, DO...UNTIL and FOR...NEXT, IF
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

	.include	"il.h"
	.include	"ilMacros.h"
	.include	"flow.h"

	.include	"goto.h"


;********************************************************************************
;* doGoto:
;*	Is GOTO. also used for GOSUB.
;*    We enter here with the cursor pointing at the start of the stored
;*    line-number of the target - high byte first.
;********************************************************************************

.proc	doGoto
	jsr	checkInt

	lda	findlFlag		; Did we find the line?
	bmi	noGo

; Emulate a bit of stmtNext here - move the line number into hiLine and loLine
;	and bump the cursor

	ldy	#0
	lda	(cursor),y
	sta	hiLine
	iny
	sty	runMod			; Set runMod to 1 -> running
	lda	(cursor),y
	sta	loLine

	bumpCursor	3		; Line number + length byte

; Point I.L. to the next ilStatement handler

	lda	#>ilStatement
	sta	pcH
	lda	#<ilStatement
	sta	pcL

	rts

noGo:
	lda	#eNOGO
	jmp	progErr
.endproc


;********************************************************************************
;* saveDo:
;*	Save the cursor into the DO stack
;********************************************************************************

.proc	saveDo
	ldx	doPtr
	cpx	#doStackSize
	beq	tooDeep

	lda	cursorL		; Push low first
	sta	doStack,x
	inx
	lda	cursorH
	sta	doStack,x
	inx
	stx	doPtr
	rts

tooDeep:
	lda	#eNEST
	jmp	progErr
.endproc


;********************************************************************************
;* until:
;*	The working part of the DO loop construct
;********************************************************************************

.proc	until
	jsr	checkInt

	ldx	doPtr		; Get and check the do stack pointer
	beq	noUntil

	lda	regAL		; Check expression for zero.
	ora	regAH
	beq	continue	; 0 = FALSE => Re-Do the loop

	dex			; Not zero - pop the stack and return
	dex
	stx	doPtr
	rts

continue:
	lda	doStack-1,x	; Get top of stack into Cursor, but don't pop it
	sta	cursorH
	lda	doStack-2,x
	sta	cursorL
	rts

noUntil:
	lda	#eUNTL
	jmp	progErr
.endproc


;********************************************************************************
;* saveSub:
;*	Save return address for GOSUB
;********************************************************************************

.proc	saveSub
	ldx	sbrPtr
	cpx	#sbrStackSize	; Don't overflow...
	beq	tooDeep

	lda	cursorL		; Push low first
	sta	sbrStack,x
	inx

	lda	runMod		; Check run/edit
	beq	intSub

	lda	cursorH
saveSub3:
	sta	sbrStack,x
	inx
	stx	sbrPtr
	rts

intSub:
	lda	#$FF		; Push $FF if in immediate mode for return can cater for it
	bne	saveSub3

tooDeep:
	lda	#eNEST
	jmp	progErr
.endproc


;********************************************************************************
;* returnSub:
;*	Return from subrutine
;********************************************************************************

.proc	returnSub
	ldx	sbrPtr		; Get and check the gosub stack pointer
	beq	noSub

	dex
	lda	sbrStack,x	; Get top of stack into Cursor
	sta	cursorH
	dex
	lda	sbrStack,x
	sta	cursorL
	stx	sbrPtr

; Test for negative

	lda	cursorH
	bmi	retInt		; Return in interactive mode...
	rts

retInt:
	lda	#0
	sta	runMod		; Make sure we're in interactive mode
	rts

noSub:
	lda	#eRTRN
	jmp	progErr

.endproc


;********************************************************************************
;* saveFor:
;*	Save a new FOR instance
;********************************************************************************

.proc	saveFor
	ldx	forPtr
	cpx	#forStackSize	; Don't overflow...
	beq	tooDeep

; Pull data off the arithmetic stack and push it into the FOR stack.
;	Var index, Limit-L, Linit-H, Step-L, Step-H, Cursor-L, Cursor-H

	ldy	arithPtr

	lda	arithStack-7,y		; Variable index
	sta	forStack,x
	inx

	lda	arithStack-4,y		; Limit L
	sta	forStack,x
	inx

	lda	arithStack-3,y		; Limit H
	sta	forStack,x
	inx

	lda	arithStack-2,y		; Step L
	sta	forStack,x
	inx

	lda	arithStack-1,y		; Step H
	sta	forStack,x
	inx

	lda	cursorL			; Cursor location
	sta	forStack,x
	inx
	lda	cursorH
	sta	forStack,x
	inx

	stx	forPtr

; We leave the variable index and value on the ArithStack so it can be used by the > op.

	tya
	sec
	sbc	#4
	sta	arithPtr

	rts

tooDeep:
	lda	#eNEST
	jmp	progErr
.endproc


;********************************************************************************
;* nextV:
;*	Update the variable in RAM and on the forStack with the step value
;*	and push the variable and end value onto the arithStack for a later
;*	test ...
;********************************************************************************

.proc	nextV
	ldx	forPtr
	beq	noNext

	ldy	arithPtr
	lda	arithStack-1,y		; Get variable index
	cmp	forStack-7,x		; Make sure the same as in the forStack
	bne	noFor

	dec	arithPtr

; Add step to variable and store back into variable

	tay				; Variable index into Y
	clc

	lda	forStack-4,x		; Low byte of step
	adc	variablesL,y		; Add to variable
	sta	variablesL,y		; And back in the variable

	lda	forStack-3,x		; High
	pha				; ... tmp. store
	adc	variablesH,y		; Add to variable
	sta	variablesH,y

; Push variable then limit into arith stack for a subsequent call to GTR

	ldx	arithPtr

; Push Variable

	lda	variablesL,y
	sta	arithStack,x
	inx

	lda	variablesH,y
	sta	arithStack,x
	inx

; Push Limit

	ldy	forPtr
	lda	forStack-6,y
	sta	arithStack,x
	inx
	lda	forStack-5,y
	sta	arithStack,x
	inx

	stx	arithPtr

; If the step is negative then invert the items on the stack

	pla				; Recover high byte of step
	bpl	done

	ldy	#4
:	dex
	lda	arithStack,x
	eor	#$FF
	sta	arithStack,x
	dey
	bne	:-

done:
	rts

noNext:
	lda	#eNEXT
	jmp	progErr

noFor:
	lda	#eFOR
	jmp	progErr
.endproc


;********************************************************************************
;* nextV1:
;*	Update the variable in RAM and on the forStack with the step value
;*	and push the variable and end value onto the arithStack for a later
;*	test ...
;********************************************************************************

.proc	nextV1
	jsr	checkInt

	lda	regAL			; Get result of cmp...
	beq	nextRedo		; Not zero - look again.
	lda	forPtr
	sec
	sbc	#7			; Pop FOR stack
	sta	forPtr

	rts

nextRedo:
	ldx	forPtr			; Get old Cursor off FOR stack

	lda	forStack-1,x
	sta	cursorH
	lda	forStack-2,x
	sta	cursorL
	rts
.endproc


;********************************************************************************
;* doIF:
;*	The test part of the IF statement - test for zero
;********************************************************************************

.proc	doIF
	lda	regAL
	ora	regAH
	tay
	beq	fail		; Zero is false...
	rts

; Fail: Skip to the end of the line, but ...
;	... note that we stop short and leave the CR to
;	    stmtDone/stmtNext to deal with

fail0:
	incCursor
fail:
	lda	(cursor),y
	cmp	#$0D
	bne	fail0

	jmp	stmtNext	; return via stmtNxt
.endproc
