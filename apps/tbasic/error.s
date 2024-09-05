
;*********************************************************************************
;* error.s:
;*	Error messages
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
	.include	"ilMacros.h"
	.include	"flow.h"
	.include	"print.h"

	.include	"error.h"

;********************************************************************************
;* errorMsgs:
;********************************************************************************

errorMsgs:
	strTop	"STMT"		;   0
	strTop	"CHAR"		;   1
	strTop	"SNTX"		;   2
	strTop	"VALU"		;   3
	strTop	"END"		;   4
	strTop	"NOGO"		;   5
	strTop	"RTRN"		;   6
	strTop	"NEST"		;   7
	strTop	"NEXT"		;   8
	strTop	"FOR"		;   9
	strTop	"DIV0"		;  10
	strTop	"BRK"		;  11
	strTop	"UNTL"		;  12
	strTop	"BAD"		;  13 - Bad program


;********************************************************************************
;* Error routine - first entry point is for syntax error.
;*	else enter at progErr with code in A
;*	Note: Error numbers are 0 through 13.
;********************************************************************************

syntaxErr:
	lda	#eSNTX

progErr:
	pha			; Temp. save
	tay
	jsr	newLine

; Search the messages

	ldx	#0
next0:	dey
	bmi	prError

; Scan to the next one

:	lda	errorMsgs,x
	bmi	next1
	inx
	bne	:-
next1:	inx			; Skip over the last char of the last message
	bne	next0

; Print

prError:
	lda	errorMsgs,x
	bmi	done
	jsr	putChar
	inx
	bne	prError
done:
	and	#$7F		; Strip top bit on last character
	jsr	putChar

; Print " ERROR" unless BRK...

	pla
	cmp	#eBRK
	beq	skipErr

	jsr	putStr
	.asciiz	" ERROR"

; Test run/immediate mode

skipErr:
	lda	runMod
	beq	:+		; If immediate mode we end here.

	jsr	putStr
	.asciiz	" AT "

	lda	loLine
	sta	regAL
	lda	hiLine
	sta	regAH
	jsr	pDec

; Jump to progFin to tidy up

:	jmp	progFin
