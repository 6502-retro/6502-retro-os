
;*********************************************************************************
;* flow.s:
;*	Statement flow.
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
	.include	"error.h"

	.include	"il.h"
	.include	"ilMacros.h"
	.include	"ilUtils.h"
	.include	"system.h"
	.include	"print.h"

	.include	"flow.h"



;********************************************************************************
;* stmtDone:
;*	Check current statement finished.
;*	Moves the cursor over any trailing spaces and stops at a colon or CR.
;*	Error if no colon or CR.
;********************************************************************************

.proc	stmtDone
	skipSpaces
	cmp	#$0D		; CR?
	beq	doneCR
	cmp	#':'		; Colon?
	beq	doneCLN

;	pha
;	jsr	putStr
;	.byte	"Really char error",13,10,0
;	pla
;	jsr	_oHex8
;	jsr	newLine

	lda	#eCHAR
	jmp	progErr


doneCLN:
	incCursor		; Skip over the colon
doneCR:
	rts			; ... but we leave the cursor on the CR for stmtNext
.endproc


;********************************************************************************
;* stmtNext:
;*	Next statement
;*	(Not FOR/NEXT)
;********************************************************************************

.proc	stmtNext
	lda	runMod
	beq	progFin

; See if we've landed on a CR

	ldy	#0
	lda	(cursor),y
	cmp	#$0D
	bne	:+

	iny			; Skip over the CR
	lda	(cursor),y	; Get next byte from the program - Line number High
	bmi	progFin		; Top bit set - end

; Store in the line number

	sta	hiLine
	iny
	lda	(cursor),y	; Get line number low
	sta	loLine

; Add 4 to the cursor - skips over the CR/lineNum/Len

	bumpCursor	4

:	lda	#>ilStatement	; Point I.L. to the next statement handler
	sta	pcH
	lda	#<ilStatement
	sta	pcL

	rts
.endproc


;********************************************************************************
;* progFin:
;*	Finish execution
;********************************************************************************

.proc	progFin
	lda	#0
	sta	runMod		; Not running

	lda	#<ilStart	; Set I.L. PC to ilStart
	sta	pcL
	lda	#>ilStart
	sta	pcH
	rts
.endproc


;********************************************************************************
;* progStart:
;*	Start execution
;********************************************************************************

.proc	progStart
	jsr	resetCursor

; Store first line number
;	Remember, it's stored high byte first as the top-bit set indicates
;	end of program text.

	ldy	#0
	lda	(cursor),y	; Get first byte of program
	bmi	progFin		; Top bit set is end, so no program
	sta	hiLine
	iny
	lda	(cursor),y
	sta	loLine

	bumpCursor	3	; Line number + length byte

	iny
	sty	runMod		; Run mode = 1

	rts
.endproc
