
;********************************************************************************
;* system.h:
;*	System specific startup and library code for simple IO.
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
;* These are the symbols and routines you need to define in
;*	your own system specific startup code.
;********************************************************************************

	.global	lineInput		; Line input buffer

	.global	putChar
	.global	newLine
	.global	getChar
	.global	putStr
	.global	getLine
	.global	checkInt		; Checks for a keyboard interrupt


;********************************************************************************
;* Platform specifics
;*	Not always defined or used...
;********************************************************************************

	.global	doDir
	.global	doSv
	.global	doLd

	.global	doGetLED
	.global	doSetLED

	.global	doDigitalRead
	.global	doDigitalWrite
	.global	doPinMode

; SXB-RAM:
;	Specialised version to let me copy stuff up to the EEPROM

.ifdef	sxb_ram
	.global	doFla
	.global	doEra
.endif
	.global	doMon

; SXB-ROM:
;	Run from the EEPROM in the SXB board.

.ifdef	sxb_rom
	.global	autoStart
.endif
