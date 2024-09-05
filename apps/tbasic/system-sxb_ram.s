
;********************************************************************************
;* start.s:
;*	System specific startup and library code for GIBL running under
;*	WDC 65c134 SXB
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

	.macpack	generic

	.include	"data.h"
	.include	"gibl.h"
	.include	"error.h"
	.include	"keys.h"
	.include	"release.h"

	.include	"system.h"

;********************************************************************************
;* External symbols you need to define:
;*	lineInput
;*     This is where the line if text is stored on keyboard input.
;*
;* External routines you need to define/re-define:
;*	putChar  - Print character in A.
;*	newLine  - Output a CR+LF
;*	putStr	 - Output a string in-line with progam code.
;*	getChar	 - Return character in A.
;*	getLine	 - Read in a line of text
;*			Line is CR terminated and located at lineInput.
;*	checkInt - Check for Ctrl-C or whatever. Set carry if Ctrl-C
;*
;*	In-General you need to preserve X and Y with data passed in/out in A.
;*
;* Other things to do:
;*	Make sure the 6502 is in the right mode (binary, not decimal),
;*	Set the stack appropriately - GIBL only uses a few JSRs, but the
;*		called IO routines may use more, and note that the keyboard
;*		input buffer is at $0100 by defualt.
;*	Work out the start of RAM and store this in osPageL and osPageH.
;*	Initialise IO, UARTs, whatever - if needed.
;*	Finally:
;*
;*		jmp gibl
;*
;*	to get things going.
;*
;********************************************************************************

; Create/Define lineInput:
;	We're using the botton of the stack page, so we must make sure we
;	initialise the stack high and leave plenty of space.

lineInput	= $0100


;********************************************************************************
;*	 ____ _____  _    ____ _____   _   _ _____ ____  _____                  *
;*	/ ___|_   _|/ \  |  _ \_   _| | | | | ____|  _ \| ____|                 *
;*	\___ \ | | / _ \ | |_) || |   | |_| |  _| | |_) |  _|                   *
;*	 ___) || |/ ___ \|  _ < | |   |  _  | |___|  _ <| |___                  *
;*	|____/ |_/_/   \_\_| \_\|_|   |_| |_|_____|_| \_\_____|                 *
;*										*
;********************************************************************************
;*   This is the ROM etry point. It must be the first thing called and linked	*
;*	in the Makefile.							*
;********************************************************************************

;********************************************************************************
;* Initialise the '134 SXB as much as we need to when running under its
;*	internal ROM. In particular, we should not southc the stack but
;*	we do need to disable echo on the serial line.
;********************************************************************************

	.include	"il.h"
	.include	"sxb-mon/regs-sxb.h"

;* Externals in the SXB Internal ROM
;*	The ROM source code seems to indicate that they preserve all
;*	registers... Let's hope so...

	rdCh	= $F00C
        wrCh	= $F00F

sxBStart:
	cld			; Paranoia

; Turn echo off.

	lda	$72
	ora	#32
	sta	$72

;********************************************************************************
;* Program text start location.
;*	Programs start here and grow up towards the end of RAM.
;*	There is (currently) no check that RAM is exceeded.
;*
;*	Strings start at the end of program text and the built-in
;*	variable TOP will return that address.
;********************************************************************************

	.import	__PAGESTART__		; Set in sxb.cfg

	lda	#<__PAGESTART__
	sta	osPageL
	lda	#>__PAGESTART__
	sta	osPageH

; Local system setup is complete - lets jump to the main thing.

	jmp	gibl


;********************************************************************************
;* putChar:
;*	Print a single character in A. Preserve X & Y.
;********************************************************************************

putChar:	jmp	wrCh

;********************************************************************************
;* newLine:
;*	Output a newline to the terminal. Preserve X & Y.
;********************************************************************************

newLine:	jsr	putStr
		.byte	13,10,0
		rts

;********************************************************************************
;* getchar:
;*	Wait-for and read a single character back into A.
;*	Saves X&Y.
;********************************************************************************

getChar:	jmp	rdCh

;********************************************************************************
;* putStr:
;*	Print a zero-terminated string stored in-line with the program code.
;*	Standard in RubyOS, but a copy is included here anyway.
;*	Usage:
;*		jsr	putStr
;*		.byte	"Hello, world", 0
;*	Saves X&Y, but uses A.
;********************************************************************************

.proc	putStr

; Pull return address off the stack to use to get the data from

	pla
	sta	pStrL
	pla
	sta	pStrH
	tya				; Save Y
	pha

	ldy	#0
strout1:
	inc	pStrL
	bne	strout2
	inc	pStrH
strout2:
	lda	(pStr),y
	beq	stroutEnd
	jsr	putChar			; Should preserve Y
	jmp	strout1

; Push return address back onto the stack

stroutEnd:
	pla				; Restore Y
	tay

	lda	pStrH
	pha
	lda	pStrL
	pha

	rts
.endproc


;********************************************************************************
;* checkInt:
;*	Check for a keyboard interrupt. This routine will be called
;*	regularly during program execution and listing. 
;********************************************************************************

.proc	checkInt
;	lda	$FF
;	bne	gotInt
	rts

gotInt:
	lda	#0
	sta	$FF
	pla			; Remove JSR
	pla
	lda	#eBRK
	jmp	progErr
.endproc


;********************************************************************************
;* getLine:
;*	Read in a line of text.
;*	Input line must be terminated by a CR (decimal 13) code and be under 127
;*	bytes long including the CR.
;********************************************************************************

;********************************************************************************
;* cheapGetLine:
;*	Read in a line of text with simple editing
;*
;* (Simple) Editing:
;*	Backspace or DEL: Delete char to left of cursor
;*	Ctrl-C:           Delete whole line
;*
;* Entry:
;*	Acc has the prompt character.
;*
;* Exit:
;*	Data stored at lineInput with a terminating CR.
;********************************************************************************

.proc	getLine
	sta	temp0		; Save prompt

getLine0:
	lda	temp0		; Output prompt:
	jsr	putChar
	lda	#0		; Zero length
	sta	iLen

getLineLoop:
	jsr	getChar
	cmp	#KEY_CTRL_C		; Or Ctrl-C
	bne	:+

; Cancel the line

	jsr	putStr
	.byte	"\",13,10,0
	jmp	getLine0

; Other control character?

:	cmp	#KEY_BS			; Backspace?
	bne	notBackSp

doBackSp:
	lda	iLen
	beq	getLineLoop		; Already at the start?
	jsr	putStr
	.byte	KEY_BS,' ',KEY_BS,0	; Backspace, space, backspace..
	dec	iLen
	jmp	getLineLoop

notBackSp:
	cmp	#KEY_DEL		; DELete?
	beq	doBackSp
	bge	getLineLoop		; Ignore characters > 127

	cmp	#CR
	beq	return

	cmp	#LF
	beq	return

	cmp	#KEY_SPACE
	blt	getLineLoop		; Ignore all other control characters

	jmp	printable


;********************************************************************************
;* return:
;*	Ctrl-M, or Ctrl-J
;*	Terminate and return the line
;********************************************************************************

return:
	ldy	iLen		; Store CR
	lda	#CR		; In-case we got here from a newline
	sta	lineInput,y
	jsr	newLine		; Take a newline

	rts


;********************************************************************************
; Ordinary printable character
;********************************************************************************

printable:

	ldy	iLen		; Buffer full?
	cpy	#maxLen-1
	bne	:+
	beq	getLineLoop
:

; Print and store key

	sta	lineInput,y
	jsr	putChar
	inc	iLen
	jmp	getLineLoop

.endproc


;********************************************************************************
;*		W65C134-SXB board Specific code
;********************************************************************************

.proc	doDir
	lda	#0
	jmp	progErr
.endproc

.proc	doLd
	jmp	doDir
.endproc

.proc	doSv
	jmp	doDir
.endproc


;********************************************************************************
;* doSetLED: doGetLED:
;*	Set the LEDs on the SXB board
;********************************************************************************

.proc	doSetLED
	lda	regAL
	and	#$0F
	eor	#$0F		; They're inverted
	sta	regAL
	lda	regPD3
	and	#$F0
	ora	regAL
	sta	regPD3
	rts
.endproc

.proc	doGetLED
	ldx	arithPtr
	clc
	lda	regPD3
	and	#$0F
	eor	#$0F
	sta	arithStack,x
	inx
	lda	#0
	sta	arithStack,x
	inx
	stx	arithPtr
	rts
.endproc

;********************************************************************************
;* The on-board EEPROM has 4 banks of 32KB controlled by PD3.4 and PD3.5.
;*	The default is The upper bank with both high address line at logic
;*	1/high (via pull-up resistors).
;*	The monitor ROM writes $FF into PD3 at reset time to additionally force
;* 	those bits High, and the LEDs (PD3.0-3) off (inverted outputs). Also
;*	bits PD3.6 and PD3.7 are the enables for the RAM and EEPROM controlled
;*	by the PCS3 register.
;********************************************************************************

;********************************************************************************
;* doEra:
;*	Erase a single 4K sector of the EEPROM
;*	Uses TinyBasic Variables:
;*		A has the EEPROM base address.
;*		D has the EEPROM bank (0-3)
;********************************************************************************

.macro	flaCmd	addr,data
	lda	#data
	sta	$8000+addr
.endmacro

.proc	doEra
	jsr	extractVars
	jsr	flashSetup

	flaCmd	$5555,$AA		; Unlock
	flaCmd	$2AAA,$55
	flaCmd	$5555,$80
	flaCmd	$5555,$AA

	flaCmd	$2AAA,$55		; Sector erase

	lda	#$30			; Erase command
	ldy	#$00
	sta	(regA),y
wait:
	lda	(regA),y
	cmp	#$FF
	bne	wait
					; Fall into...
.endproc


;********************************************************************************
;* resume:
;*	Restore the hardware to the state where the on-board ROM is enabled
;*	and bank 0 is active.
;********************************************************************************

.proc	resume
	lda	regBCR
	and	#<~$80
	sta	regBCR

; Reset EEPROM Bank

	lda	regPD3
	ora	#$30			; Set to 11 which is bank 0
	sta	regPD3

	cli
	rts
.endproc


;********************************************************************************
;* doFla:
;*	Flash data into the device
;*	Variables:
;*		A has the FROM address (RAM)
;*		B has the TO address   (Flash)
;*		C has the length.
;*		D has the ROM page (0-3)
;*	On exit the variables, A, B and C are updated.
;********************************************************************************

.proc	doFla

	jsr	extractVars
	jsr	flashSetup

	ldy	#0
loop:
	flaCmd	$5555,$AA		; Unlock
	flaCmd	$2AAA,$55
	flaCmd	$5555,$A0		; Byte write

	lda	(regA),y
	sta     (regB),y
wait:
	cmp	(regB),y
	bne	wait

; Inc To:

	inc	regAL
	bne	:+
	inc	regAH

; Inc From:

:	inc	regBL
	bne	:+
	inc	regBH

; Dec. count

:	lda     regCL
        bne     :+
        dec     regCH
:       dec     regCL

; If not zero, then go back for more...

	lda	regCL
	ora	regCH
	bne	loop

; Save data back in A, B and C

;	lda	regAL
;	sta	variablesL+1
;	lda	regAH
;	sta	variablesH+1
;
;	lda	regBL
;	sta	variablesL+2
;	lda	regBH
;	sta	variablesH+2
;
;	lda	regCL
;	sta	variablesL+3
;	lda	regCH
;	sta	variablesH+3
;
;	lda	regPD3
;	sta	variablesL+4

; And we're done

	jmp	resume
.endproc


;********************************************************************************
;* doMon:
;*	Jump to the new monitor thing in EEPROM
;********************************************************************************

.proc	doMon
	sei			; Need to stop interrupts for now
	lda	regBCR		; Disable the internal ROM and allow the EEPROM full range
	ora	#$80
	sta	regBCR
	jmp	$F000
.endproc


;********************************************************************************
;* extractVars:
;*	Extract data from TinyBasic variables A,B and C into regA,
;*	regB and regC and from variable D into 'num' shifted up 4 bits.
;********************************************************************************

.proc	extractVars
	lda	variablesL+1		; Low of A
	sta	regAL
	lda	variablesH+1		; High of A
	sta	regAH

	lda	variablesL+2		; Low of B
	sta	regBL
	lda	variablesH+2		; High of B
	sta	regBH

	lda	variablesL+3		; Low of C
	sta	regCL
	lda	variablesH+3		; High of C
	sta	regCH

; Bank in D

	lda	variablesL+4		; Low of D into bits 6:7
	and	#$3
	eor	#$3			; Inverted
	asl
	asl
	asl
	asl
	sta	num

	rts
.endproc


;********************************************************************************
;* flashSetup:
;*	Get the SXB into the right state for accessing the EEPROM
;********************************************************************************

.proc	flashSetup
	sei			; Need to stop interrupts for now
	lda	regBCR		; Disable the internal ROM and allow the EEPROM full range
	ora	#$80
	sta	regBCR

; The EEPROM 'bank' is encoded as bits 6:7
;	This also lights the 4 LEDs

	lda	num
	sta	regPD3

	rts
.endproc
