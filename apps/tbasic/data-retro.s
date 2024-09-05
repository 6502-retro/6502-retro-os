
;********************************************************************************
;* data-retro.s:
;*	System specific data for GIBL running in RAM on the SXB.
;*
;*	See PORTING.TXT
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

	.include	"data.h"

;********************************************************************************
;* This data MUST be in Zero Page. You have no choice. It's used for
;*	pointers, and other variables that need to be quickly
;*	accessed.
;*	So if you don't have 35 bytes of ZP available, then you're not
;*	going to be able to run GIBL...
;********************************************************************************

		.segment	"ZEROPAGE":zeropage

doPtr:		.res	1		; DO stack pointer
forPtr:		.res	1		; FOR stack pointer
arithPtr:	.res	1		; Arithmetic stack pointer
sbrPtr:		.res	1		; GOSUB stack pointer
pcPtr:		.res	1		; I.L. Call stack pointer
pc		=	pcL		; I.L. Program counter
 pcL:		.res	1
 pcH:		.res	1
loLine:		.res	1		; Current line number
hiLine:		.res	1
runMod:		.res	1		; Run/Edit flag
pStr		=	pStrL		; Print String pointer
 pStrL:		.res	1
 pStrH:		.res	1
findlFlag:	.res	1		; Flag used in findLine

cursor		=	cursorL
  cursorL:	.res	1
  cursorH:	.res	1

svCursor	=	svCursorL
 svCursorL:	.res	1
 svCursorH:	.res	1

regA		=	regAL
 regAL:		.res	1
 regAH:		.res	1

regB		=	regBL		; GP - Also used to hold target/fail in the IL
  regBL:	.res	1
  regBH:	.res	1

regC		=	regCL		; GP - Also used to hold target/fail in the IL
  regCL:	.res	1
  regCH:	.res	1

top		=	topL		; Keeps track of the 'top' or end of the program text
 topL:		.res	1
 topH:		.res	1

num:		.res	1		; Used in ERR and compares
temp0:		.res	1		; Temporary byte store
rndX:		.res	1		; Used in the PRNG
rndY:		.res	1

osPageL:	.res	1		; Value of the start of usable program RAM.
osPageH:	.res	1

iLen:		.res	1		; Current input line length and...
cPos:		.res	1		; ... position of input line cursor

saveX:		.res	1
saveY:		.res	1


;********************************************************************************
;* This data can live in ZP or in other RAM.
;*	Obviously the more you can pack into Zero Page the faster and
;*	(slightly) smaller GIBL will be.
;********************************************************************************

		.segment	"DATA"

variables	=	variablesL	; Variables; A-Z
 variablesL:	.res	varSize/2
 variablesH:	.res	varSize/2

arithStack:	.res	arithStackSize	; Arithmetic stack for variable evaluation
pcStack:	.res	pcStackSize	; The I.L. program counter stack.
sbrStack:	.res	sbrStackSize
doStack:	.res	doStackSize

forStack:	.res	forStackSize
