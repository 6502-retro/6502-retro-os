
;********************************************************************************
;* system-sxb-rom.s:
;*	System specific startup and library code for GIBL running under
;*	WDC 65c134 SXB - in ROM
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
	.include	"print.h"

	.include	"system.h"

	.include	"sxb-mon/regs-sxb.h"


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
;* Initialise the '134 SXB as much as we need to when running under the
;*	external EEPROM.
;********************************************************************************

	.include	"il.h"

; Vectors in my little hardware framework in the SXB:

	sxb_putChar	= $F003
	sxb_newLine	= $F006
;	sxb_putStr	= $F009
	sxb_getChar	= $F00C
;	sxb_getLine	= 0
	sxb_checkInt	= $F00F

;* We may be starting from the internal ROM, so we need to turn that off
;*	and enable the EEPROM to get things going.
;*
;* The JMP $F000 kick-starts our own monitor replacement and when it's
;*	setup and ready, it will jump back to $E010, so we need to
;*	count bytes.

sxBStart:			; Byte counts to "fix" the re-entry point
	sei			; $00
	lda	regBCR		; $01,$02
	ora	#$80		; $03,$04
	sta	regBCR		; $05,$06
	jmp	$F000		; $07,$08,$09

	.byte	"*GIBL",0	; Signature @ $0A,B,C,D,E,F

; SXB entry point which will be at $E010

sxbRealStart:
	cld			; Paranoia


;********************************************************************************
;* Program text start location.
;*	Programs start here and grow up towards the end of RAM.
;*	There is (currently) no check that RAM is exceeded.
;*
;*	Strings start at the end of program text and the built-in
;*	variable TOP will return that address.
;*
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

putChar	=	sxb_putChar

;********************************************************************************
;* newLine:
;*	Output a newline to the terminal. Preserve X & Y.
;********************************************************************************

newLine	=	sxb_newLine

;********************************************************************************
;* getChar:
;*	Wait-for and read a single character back into A.
;*	Saves X&Y.
;********************************************************************************

getChar	=	sxb_getChar

;********************************************************************************
;* putStr:
;*	Print a zero-terminated string stored in-line with the program code.
;*	Usage:
;*		jsr	putStr
;*		.byte	"Hello, world", 0
;*	Saves X&Y, but uses A.
;********************************************************************************

;********************************************************************************
;* putStr:
;*	Print a zero-terminated string stored in-line with the program code.
;*	Standard in RubyOS, but a copy is included here anyway.
;*	Usage:
;*		jsr	putstr
;*		.byte	"Hello, world", 0
;*	Uses A, saves X&Y
;********************************************************************************

.proc	putStr

; Pull return address off the stack to use to get the data from

	pla
	sta	pStrL
	pla
	sta	pStrH
	tya
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
	pla
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
	jsr	sxb_checkInt
	bne	gotInt
	rts
gotInt:
	pla			; Remove JSR
	pla
:	jsr	getChar		; Clear input utill the Ctrl-C
	cmp	#KEY_CTRL_C
	bne	:-
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

; Ordinary printable character

	ldy	iLen		; Buffer full?
	cpy	#maxLen-1
	beq	getLineLoop

; Print and store key

	sta	lineInput,y
	jsr	putChar
	inc	iLen
	jmp	getLineLoop

;* return:
;*	Ctrl-M, or Ctrl-J
;*	Terminate and return the line
;********************************************************************************

return:
	lda	#CR		; In-case we got here from a newline
	ldy	iLen		; Store CR
	sta	lineInput,y
	jmp	newLine		; Take a newline
.endproc


;********************************************************************************
;*		W65C134-SXB board Specific code
;********************************************************************************

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
;* Dir, Save, Load and Chain:
;*	SV n
;*	Filenames are simple numbers: 0-15. Each filename/number represents a
;*	different amount of storage from 4KB to 16KB. If your BASIC program is
;*	more than 16KB then you're really exceeding a "TinyBasic" system...
;*	Number is passed in in regA.
;********************************************************************************



;********************************************************************************
;* flashAddr:
;*	Table of addresses of the top byte in the EEPROM banks for each slot
;********************************************************************************

flashAddr:

	.byte	$80		; Bank 0, offset $0000	; 4K blocks
	.byte	$90		; Bank 0, offset $1000
	.byte	$A0		; Bank 0, offset $2000
	.byte	$B0		; Bank 0, offset $3000
	.byte	$C0		; Bank 0, offset $4000
	.byte	$D0		; Bank 0, offset $5000
	.byte	$E0		; Bank 0, offset $6000
	.byte	$F0		; Bank 0, offset $7000

	.byte	$80		; Bank 1, offset $0000	; 8K blocks
	.byte	$A0		; Bank 1, offset $2000
	.byte	$C0		; Bank 1, offset $4000
	.byte	$E0		; Bank 1, offset $6000

	.byte	$80		; Bank 2, offset $0000	; 16K blocks
	.byte	$C0		; Bank 2, offset $4000

	.byte	$A0		; Bank 3, offset $2000	; 16K Block - 8K up.  

	.byte	$90		; Bank 3, offset $1000	; Last 4K block


;********************************************************************************
;* flashBank:
;*	The number to poke into the hardware bank select register for each
;*	Save/Load slot.
;*	Remember outout bits are inverted and 00 11 xxxx is default bank '0'
;********************************************************************************

flashBank:
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	; 8 x  4K Blocks: 00 00 xxxx in bank 3
	.byte	$10,$10,$10,$10			; 4 x  8K Blocks: 00 01 xxxx in bank 2
	.byte	$20,$20				; 2 x 16K Blocks: 00 10 xxxx in bank 1
	.byte	$30				; 1 x 16K Block:  00 11 xxxx in bank 0 - Boot Bank
	.byte	$30				; 1 x  4K Block:  00 11 xxxx in bank 0

;********************************************************************************
;* flashSize:
;*	The size of each save/load slot in KB.
;********************************************************************************

flashSize:
	.byte	4,4,4,4,4,4,4,4			; 8 x  4K Blocks
	.byte	8,8,8,8				; 4 x  8K Blocks
	.byte	16,16				; 2 x 16K Blocks
	.byte	16				; 1 x 16K Block
	.byte	4				; 1 x  4K Block


;********************************************************************************
;* setSvLdParams:
;*	Extract, check and set the basic parameters for a save/load operation
;********************************************************************************

.proc	setSvLdParams

; Check save slot: 0-15.

	lda	regAH
	beq	:+

badSlot:
	lda	#eVALU
	jmp	progErr
:
	lda	regAL
	cmp	#16
	bge	badSlot

; Set parameters
;	regA:   Length (TOP-PAGE)
;	regB:   Start address in RAM (from osPage)
;	regC:   Start address in EEPROM
;	num:    Bank number

	ldy	regAL			; Get save slot number
	lda	flashAddr,y
	sta	regCH
	lda	#0
	sta	regCL			; regC has EEPROM Start address

	lda	flashBank,y		; Get flash bank - already encoded for the hardware register
	sta	num

; Check bank size is big enough for code in RAM

	sec
	lda	topL			; regA = top - page
	sbc	osPageL
	lda	topH
	sbc	osPageH
	lsr				; Convert 0.25KBytes into KB...
	lsr
	cmp	flashSize,y
	bgt	badSlot

	lda	osPageL
	sta	regBL
	lda	osPageH
	sta	regBH			; regB has RAM Start address
	rts
.endproc


;********************************************************************************
;* copyCode:
;*	Copy Flash access code to page 3...
;*	To make life easy, we'll copy 256 bytes even if there are less.
;********************************************************************************

.proc	copyCode
	ldy	#0
:	lda	flashCode,y
	sta	$0300,y
	iny
	bne	:-
	rts
.endproc


;********************************************************************************
;* doDir:
;*	Output a directory of the flash/EEPROM contents.
;*	This only works if the programs obey a cenvention of having a line 0
;*	that start with REM then a space then the name.
;********************************************************************************

.proc	doDir
	jsr	copyCode
	jmp	flashDirCode
.endproc


;********************************************************************************
;* doSv:
;*	Save the current program into EEPROM...
;********************************************************************************

.proc	doSv
	jsr	setSvLdParams
	jsr	copyCode
	jmp	flashSvCode
.endproc


;********************************************************************************
;* doLd::
;*	Load a program from EEPROM...
;********************************************************************************

.proc	doLd
	jsr	setSvLdParams
	jsr	copyCode
	jmp	flashLdCode
.endproc


;********************************************************************************
;* autoStart:
;*	See if there is a program in slot 15 that we can load & run...
;*	The program has to start with the magic line:
;*		0REM!BOOT
;********************************************************************************

.proc	autoStart
	ldy	#0
:	lda	autoSignature,y
	bmi	loadIt			; Reached the end of the signature, so OK...
	cmp	$9000,y
	bne	done			; Mismatch, so end
	iny
	bne	:-

loadIt:
	lda	#15			; Force a load of slot 15.
	sta	regAL
	lda	#0
	sta	regAH
	jsr	doLd

; Auto-Run the program: set the I.L. PC to ilDoRun

	lda	#>ilDoRun
	sta	pcH
	lda	#<ilDoRun
	sta	pcL

done:	rts

autoSignature:
	.byte	$00,$00,$0C,"REM!BOOT",$0D,$FF
.endproc


;********************************************************************************
;* NOTE:
;*	Code below is assembled to start at $0300 so we can copy it to RAM
;*	and access all the flash banks in the eeprom.
;********************************************************************************

flashCode:

fileName	=	$0110
	.org	$0300


;********************************************************************************
;* flashDirCode:
;*	code to be copied to $0300 that does the DIR command.
;********************************************************************************

.proc	flashDirCode
	ldx	#0		; Bank in X
	stx	regBL
	lda	#1
	sta	variablesL	; Set @ variable for printing in field width of 2

dirLoop:
	lda	flashAddr,x	; Get EEPROM address for this bank
	sta	regBH

	sei
	lda	flashBank,x
	sta	regPD3		; Select Bank

	lda	#CR
	sta	fileName

; Check first few chars...

	ldy	#0
	lda	(regB),y	; First char (High byte of line no.)
	cmp	#$FF		; Empty?
	beq	printIt
	iny
	ora	(regB),y	; Check line number is 0?
	bne	printIt

; Copy first few characters...
;	... because we can't print right now as the Monitor Bank may be paged out

	ldy	#7		; NNLREMsNAME
copy:	lda	(regB),y
	sta	fileName-7,y
	cmp	#CR
	beq	printIt
	iny
	cpy	#31+7
	bne	copy
	lda	#CR		; CR terminate it
	sta	fileName-7,y

; Now, print

printIt:
	lda	#$3F		; Back to original bank
	sta	regPD3
	cli

; Print Bank No.

	txa
	sta	regAL
	lda	#0
	sta	regAH
	jsr	pDec

; Followed by the size:

	lda	#':'
	jsr	putChar
	lda	flashSize,x
	sta	regAL
	jsr	pDec
	jsr	putStr
	.byte	"K: ",0

; Then the name

	ldy	#0
:	lda	fileName,y
	cmp	#CR
	beq	nextOne
	jsr	putChar
	iny
	bne	:-

nextOne:
	jsr	newLine
	inx
	cpx	#16		; 16 save slots; 0-15
	bne	dirLoop

	rts
.endproc


;********************************************************************************
;* EEPROM Write control macros and utilities.
;*	Sector Erase sequence:
;*		5555 AA
;*		2AAA 55
;*		5555 80
;*		5555 AA
;*		2AAA 55
;*		addr 30
;*	Byte Write sequence:
;*		5555 AA
;*		2AAA 55
;*		5555 A0
;*		addr data
;********************************************************************************

.macro	flaCmd	addr,data
	lda	#data
	sta	$8000+addr
.endmacro

unlock1:
	flaCmd	$5555,$AA
unlock2:
	flaCmd	$2AAA,$55
	rts


;********************************************************************************
;* flashSvCode:
;*	Code to be copied to $0300 that does the actual EEPROM writing
;*	We have:
;*		regA:	Length in bytes to write
;*		regB:	RAM Address of start of code
;*		regC:	EEPROM Start Address to store code into
;*		num:	Bank number in format for regPD3
;*	Called with Y=0
;********************************************************************************

.proc	flashSvCode
	sei			; Need to stop interrupts for now
	lda	num
	sta	regPD3

; Erase EEPROM sectors as we go... So, start with the first bank:

eraseSector:
	jsr	unlock1			; Unlock preamble
	flaCmd	$5555,$80		; Unlock for sector erase
	flaCmd	$5555,$AA
	flaCmd	$2AAA,$55		; Sector erase command part 1...
	lda	#$30			; Actual Erase command
	sta	(regC),y

; Somewhat paranoid but we'll make sure the first 256 bytes are all $FF

wait:
	lda	(regC),y
	cmp	#$FF
	bne	wait
	iny
	bne	wait

; OK, Erased that sector, lets write the data:

writeLoop:
	jsr	unlock1			; Unlock preamble
	flaCmd	$5555,$A0

	lda	(regB),y
	sta     (regC),y
waitByte:
	cmp	(regC),y
	bne	waitByte

	cmp	#$FF			; Marks end of program
	bne	nextByte

; Reset EEPROM Bank

	lda	#$3F			; Bank 3, LEDs off
	sta	regPD3
	cli
	rts

; Inc From:

nextByte:
	inc	regBL
	bne	:+
	inc	regBH

; Inc To:

:	inc	regCL
	bne	writeLoop
	inc	regCH

; New 4K boundary?

	lda	regCH
	and	#$0F
	bne	writeLoop
	beq	eraseSector
.endproc


;********************************************************************************
;* flashLdCode:
;*	Code to be copied to $0300 that does the actual EEPROM reading
;*	We have:
;*		regA:	Length in bytes to read - not used
;*		regB:	RAM Address of start of code (osPage)
;*		regC:	EEPROM Start Address to read code from
;*		num:	Bank number in format for regPD3
;*	Called with Y=0
;********************************************************************************

.proc	flashLdCode
	sei			; Need to stop interrupts for now
	lda	num
	sta	regPD3

readLoop:
	lda	(regC),y
	sta     (regB),y
	cmp	#$FF			; End marker
	beq	doneRead

; Inc To:

	inc	regBL
	bne	:+
	inc	regBH

; Inc From:

:	inc	regCL
	bne	readLoop
	inc	regCH
	bne	readLoop

; Reset EEPROM Bank

doneRead:
	lda	#$3F			; Bank 3, LEDs off
	sta	regPD3
	cli
	rts
.endproc
	.reloc
