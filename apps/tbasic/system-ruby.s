
;********************************************************************************
;* start.s:
;*	System specific startup and library code for GIBL running under
;*	rubyOs
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

	.include	"../rubyOs816/osVectors.h"

	.include	"data.h"
	.include	"gibl.h"
	.include	"error.h"
	.include	"keys.h"
	.include	"release.h"

	.include	"system.h"

; Which getline call to use...

;USE_RUBYOS_GETLINE	:=	1

; Include code for getline to call back to the underlying OS?

GETLINE_SYSCALL		:=	1


;********************************************************************************
;* Note of the Ruby Memory Map:
;*	It follows the Acorn MOS one relatively closely in that some areas are
;*	reserved - briefly:
;*
;* $0000-$008F	- User ZP storage
;* $0090-$00FF	- Reserved for Ruby OS
;* $0100-$01FF	- 6502 Stack
;* $0200-$02FF	- OS Variables, indirection vectors, etc.
;* $0300-$03FF	- keyboardIn - Used as the getline input buffer.
;* $0400-$07FF	- Reserved for the current "Language"
;* $0800-$0DFF	- Reserved for Ruby OS (input history, other buffers, etc.)
;* $0E00-$7FFF	- Application/Language workspace
;* $8000-$BFFF	- Application/Language code
;* $C000-$FDFF	- RubyOS
;* $FE00-$FEFF	- 65c22 VIA
;* $FF00-$FFFF	- IO area with host MCU and hardware vectors.
;********************************************************************************

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
;* Acorn/Ruby MOSify the start...
;*	This MAY not work as-is in a real BBC Micro. It may need work to
;*	make it run correcly as a sideways ROM in a BBC Micro unless you
;*	remove the BASIC ROM first...
;********************************************************************************

rom:	jmp	rubyStart				; Language entry
	jmp	rubyStart				; Service entry
	.byte	$41					; ROM type (BASIC)
here:	.byte	<copyr-1
	.byte	release					; Version
	.asciiz	"GIBL"					; Name
copyr:	.byte	"(C) 2023 Gordon Henderson",13,10,0	; Copyright

;********************************************************************************
;* Start here.
;*	Note: RubyOS starts programs in 65C02 emulation mode.
;********************************************************************************

rubyStart:
	cld			; Paranoia

; We don't need much stack, so can use the start of page 1 as the keyboard
;	input buffer if needed.
;	This value is chosen more for debugging reasons than anything else.
;	but using this value suggests the RubyOS uses some 28 bytes in
;	normal use and running GIBL under RubyOS seems about the same...
;	Remember the keyboard input buffer is < 127 bytes at $0100 by default...

	ldx	#$DF
	txs

;********************************************************************************
;* Program text start location.
;*	Programs start here and grow up towards the end of RAM.
;*	There is (currently) no check that RAM is exceeded.
;*
;*	Strings start at the end of program text and the built-in
;*	variable TOP will return that address.
;*
;* On non-acorn-ish systems, fix as required. 
;********************************************************************************
;* Get PAGE and store in a known place so we can refer to it later in the code.
;*	We know it's $0E00 in RubyOS, but if someone ports it to a Beeb it may
;*	well be different so use osByte 131.
;********************************************************************************

	lda	#131
	jsr	osByte
	stx	osPageL
	sty	osPageH

; Local system setup is complete - lets jump to the main thing.

	jmp	gibl


;********************************************************************************
;* putChar:
;*	Print a single character in A. Preserve X & Y.
;********************************************************************************

putChar:	jmp	osWrch

;********************************************************************************
;* newLine:
;*	Output a newline to the terminal. Preserve X & Y.
;********************************************************************************

newLine:	jmp	osNewl

;********************************************************************************
;* getchar:
;*	Wait-for and read a single character back into A.
;********************************************************************************

getChar:	jmp	osRdch

;********************************************************************************
;* putStr:
;*	Print a zero-terminated string stored in-line with the program code.
;*	Standard in RubyOS, but a copy is included here anyway.
;*	Usage:
;*		jsr	putStr
;*		.byte	"Hello, world", 0
;********************************************************************************

.proc	putStr

; Pull return address off the stack to use to get the data from

	pla
	sta	pStrL
	pla
	sta	pStrH
	ldy	#0

strout1:
	inc	pStrL
	bne	strout2
	inc	pStrH
strout2:
	lda	(pStr),y
	beq	stroutEnd
	jsr	putChar			; Should preserve Y
	bne	strout1

; Push return address back onto the stack

stroutEnd:
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
	lda	$FF
	bne	gotInt
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

.ifdef	USE_OSWORD_GETLINE

;********************************************************************************
;* oswordGetLine.s:
;*	Read in a line of text.
;*	Here, we just called OSWORD 0.
;*	The RubyOS version handles editing and history recall.
;********************************************************************************

.proc	getLine

; Save prompt

	sta	temp0

getLine0:

; Output prompt:

	lda	temp0
	jsr	putChar

	ldx	#<getLineData
	ldy	#>getLineData
	lda	#0
	jsr	osWord

.ifdef	GETLINE_SYSCALL

; Check for some specific OS commands before we hand back to BASIC

	jsr	rubyCommandCheck
	beq	getLine0
.endif

	rts

getLineData:
	.word	lineInput		; Address of input buffer
	.byte	maxLen			; Max length
	.byte	32			; Smallest value to accept
	.byte	126			; largest...
.endproc

.else

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

.ifdef	GETLINE_SYSCALL

; Check for some specific OS commands before we hand back to BASIC

	jsr	rubyCommandCheck
	beq	getLine0
.endif

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

.endif


;********************************************************************************
;* rubyCommandCheck:
;*	See the input line is a Ruby command we know about. Return 0 if handled.
;********************************************************************************

.ifdef	GETLINE_SYSCALL

.proc	rubyCommandCheck
	lda	lineInput
	cmp	#'*'			; Star command
	bne	tryReload
	ldx	#<lineInput
	ldy	#>lineInput
	jsr	osCli
	lda	#0
:	rts

tryReload:
	cmp	#'#'			; Quick Get/Reload command
	bne	:-
	ldx	#<getGibl
	ldy	#>getGibl
	jsr	osCli
	ldx	#<runGibl
	ldy	#>runGibl
	jmp	osCli

getGibl:	.byte	"GET gibl",13
runGibl:	.byte	"/gibl",13

.endproc
.endif

.proc	doSv
	jsr	putStr
	.byte	"Unimp",13,10,0
	rts
.endproc

.proc	doLd
	jmp	doSv
.endproc

.proc	doDir
	jmp	doSv
.endproc
