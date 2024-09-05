
;********************************************************************************
;* data-sxb_rom.h:
;*	System specific data.
;*
;*	To port gibl to another 6502 system you may need to change stuff
;*	in this file. It should be fairly obvious ...
;********************************************************************************

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
;* maxLen
;*	Maximum size of input line.
;*	This is determined by where you can find some spare RAM - the bottom
;*	of the stack at $0100 is often handy. It mus be < 127 bytes though.
;********************************************************************************

maxLen		=	120

;********************************************************************************
;* Sizes of the various static data areas
;********************************************************************************

varSize0	=	27		; 27 variables - @ - Z
varSize		=	27 * 2		; 27 x 2-byte variables
arithStackSize	=	13 * 2
sbrStackSize	=	 8 * 2		; 8 nested GOSUBs, DO and FORs
doStackSize	=	 8 * 2		; should be enough ...
forStackSize	=	 8 * 7		; Each FOR loop  needs 7 bytes.
pcStackSize	=	14 * 2		; The I.L. progam stack


;********************************************************************************
;* Zero page data
;********************************************************************************

	.globalzp	doPtr
	.globalzp	forPtr
	.globalzp	arithPtr
	.globalzp	sbrPtr
	.globalzp	pc
	.globalzp	 pcL
	.globalzp	 pcH
	.globalzp	pcPtr
	.globalzp	loLine
	.globalzp	hiLine
	.globalzp	runMod
	.globalzp	pStr
	.globalzp	 pStrL
	.globalzp	 pStrH
	.globalzp	findlFlag
	.globalzp	svCursor
	.globalzp	 svCursorL
	.globalzp	 svCursorH
	.globalzp	regA
	.globalzp	 regAL
	.globalzp	 regAH
	.globalzp	regB
	.globalzp	 regBL
	.globalzp	 regBH
	.globalzp	regC
	.globalzp	 regCL
	.globalzp	 regCH
	.globalzp	num
	.globalzp	top
	.globalzp	 topL
	.globalzp	 topH
	.globalzp	temp0
	.globalzp	rndX
	.globalzp	rndY
	.globalzp	cursor
	.globalzp	  cursorL
	.globalzp	  cursorH
	.globalzp	osPageL
	.globalzp	osPageH
	.globalzp	iLen
	.globalzp	cPos
	.globalzp	saveX
	.globalzp	saveY

	.globalzp	variables
	.globalzp	variablesL
	.globalzp	variablesH
	.globalzp	arithStack
	.globalzp	pcStack	
	.globalzp	sbrStack
	.globalzp	doStack

;********************************************************************************
;* Main RAM data
;********************************************************************************

	.global		forStack
