
;*********************************************************************************
;* il.h:
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


;********************************************************************************
; The bits defined here allow for a 12-bit or 4KB address space, although
;	we can got to 8KB if needed.
;********************************************************************************

testBit		:=	$20		; String test
jmpBit		:=	$40		; Do an IL jump
callBit		:=	$80		; Do an IL call

; Convert to 16-bit values used in the macros

testBitH	:=	testBit << 8
jmpBitH		:=	jmpBit  << 8
callBitH	:=	callBit << 8

		.global	__CODESTART__		; From platform.cfg file

codeMask	=	$1FFF			; Mask for 12-bit I.L. code in an 8K system
addrBits	=	(__CODESTART__ & $E000)	; $F000 For 4K. If you want 8K, then it's $E000)


;********************************************************************************
; tStr:
;	Test the string at the pointer against the one supplied.
;	1st word, address of 'fail', string data after.
;********************************************************************************

.macro	tStr 	fail,test
	.word	(fail & codeMask) | testBitH
	strTop	test
.endmacro


;********************************************************************************
;* testCR:
;*	Test the character at the pointer against a CR.
;*	... by calling the generic test routine...
;********************************************************************************

.macro	testCR	fail
	.word	(fail & codeMask) | testBitH
	.byte	$8D				; Set top bit
.endmacro


;********************************************************************************
; tVar:
;	Test for a variable in the program text
;	Code, then FAIL.
;********************************************************************************

.macro	tVar	fail
	.word	testVar & codeMask
	.word	fail
.endmacro


;********************************************************************************
; tNum:
;	Test for a number in the program text
;	Code, then FAIL.
;********************************************************************************

.macro	tNum	fail
	.word	testNum & codeMask
	.word	fail
.endmacro


;********************************************************************************
; jump:
;	Jumps to a new IL command
;********************************************************************************

.macro	jump	addr
	.word	(addr & codeMask) | jmpBitH
.endmacro


;********************************************************************************
; call:
;	Calls an IL subroutine
;********************************************************************************

.macro	call	addr
	.word	(addr & codeMask) | callBitH
.endmacro


;********************************************************************************
; do:
;	Calls a sequence of ML subroutines one after the other
;********************************************************************************

.macro	do	a1,a2,a3,a4,a5,a6,a7
	.word	a1 & codeMask
	.ifnblank	a2
		do	a2,a3,a4,a5,a6,a7
	.endif
.endmacro


; Exports

	.global	ilBegin
	.global	ilStart
	.global	ilStatement
	.global	ilDoRun
