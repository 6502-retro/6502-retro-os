
;*********************************************************************************
;* ilExec.s:
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

	.macpack	generic

	.include	"data.h"
	.include	"error.h"
	.include	"print.h"

	.include	"il.h"
	.include	"ilUtils.h"
	.include	"ilMacros.h"

	.include	"ilExec.h"

;********************************************************************************
;* ilExec:
;*	This is the heart of the I.L. execution interpreter thingy.
;*
;* The IL reads in a word at the PC, then decodes it. The Word is a 16-bit
;*	value with the top 3 bits representing the op-code (as such it is).
;*	That gives us just 4 instructions - each instruction is a single bit,
;*	with the bottom 12 bits representing an address.
;*
;* TEST: This is a string compare. The word is the fail address and immediately
;*		after the word is the string to compare against, top-bit set
;*		on the last character.
;*
;* regC always contains the decoded word, changed back into a 16-bit word in
;*	the address map of the 6502.
;*
;* JUMP: The word is the address of the next IL instruction.
;*
;* CALL: The word is the address of the next IL instruction, the routine
;*	can 'return' 
;*
;* Otherwise (top 3 bits zero) it's a machine language subroutine (CALLML)
;*	which can return by RTS.
;*
;* PC is incremented by 2 for the next IL word - for string tests, the test
;*	code needs to re-adjust PC for the length of the string.
;*
;********************************************************************************
;* NOTE: See the PORTING section in the README.TXT file for some important
;*	information regarding adjustment of regC in the lines below.
;********************************************************************************

	.include	"system.h"

ilExec:

; Fetch instruction @ PC into regC
;	Adjust regC to be a proper 6502 address, saving the flags in X.

	ldy	#0
	lda	(pc),y		; Fetch low
	sta	regCL
	iny
	lda	(pc),y		; Fetch high
	tax			; Temp save for later to get flags/opcode.
	and	#>codeMask	; See PORTING.TXT
	ora	#>addrBits	; See PORTING.TXT
	sta	regCH		; regC now has 16-bit address

	incPc2

; Test for various "opcodes". Test order based on their
;	frequency in the IL:
;	  -> ML Call -> String Cmp -> IL Call -> IL Jump

;	Call Machine Language?
;		Which is the default with none of the 3 test bits set.

	txa
	and	#(jmpBit | testBit | callBit)
	beq	mlCall

;	String compare?

	txa
	and	#testBit
	bne	testStr

;	Call another IL routine

	txa
	and	#callBit
	bne	ilCall

; Default must be an IL jump...

ilJump:
	lda	regCL
	sta	pcL
	lda	regCH
	sta	pcH
	jmp	ilExec


;********************************************************************************
; mlCall:
;	Call machine code instruction at regC
;********************************************************************************

mlCall:
	jsr	:+
	jmp	ilExec
:	jmp	(regC)



;********************************************************************************
;* ilCall:
;*	Call an IL subroutine which can return via ilReturn
;********************************************************************************

.proc	ilCall
	ldx	pcPtr		; Check for stack overflow
	cpx	#pcStackSize
	beq	tooDeep

; Get PC and push it into the stack, low byte first

	lda	pcL
	sta	pcStack,x
	inx
	lda	pcH
	sta	pcStack,x
	inx
	stx	pcPtr

	jmp	ilJump

tooDeep:
	lda	#eNEST
	jmp	progErr
.endproc


;********************************************************************************
;* ilReturn:
;*	Return from an IL subroutine
;********************************************************************************

.proc	ilReturn
	ldx	pcPtr		; Get index
	dex
	lda	pcStack,x	; Recover high byte
	sta	pcH
	dex
	lda	pcStack,x	; Low byte
	sta	pcL
	stx	pcPtr
	rts
.endproc


;********************************************************************************
;* testStr:
;*	Does a string compare. String to be compared against is in-line
;*	with the IL code and the cursor ...
;*	It's the text FAIL address with test flag followed by a high-bit
;*	terminated string.
;*	regC has the Fail address, (pc) points to the string.
;********************************************************************************

.proc	testStr
	skipSpaces

; Now do the compare

	ldy	#0
cmpLoop:
	lda	(pc),y
	tax			; For temp. store
	and	#$7F		; Clear any top-bit
	cmp	(cursor),y
	bne	ilJump		; Match failed - copy regC to PC and return
	iny
	txa			; Last char?
	bpl	cmpLoop		; No - check the next one

; Match!
;	Means we fall-through to the next instruction which
;	is after the string @ PC.

; Adjust cursor

	clc
	tya
	adc	cursorL
	sta	cursorL
	bcc	:+
	inc	cursorH
:

; And the PC

	clc
	tya
	adc	pcL
	sta	pcL
	bcc	:+
	inc	pcH
:

	jmp	ilExec
.endproc


;********************************************************************************
;* testVar:
;*	Test for a variable in the text @ the cursor.
;*	If found, then put the index (0-25) on the arith stack,
;*	else change PC to the next word. (fail).
;********************************************************************************

.proc	testVar
	skipSpaces			; Leaves last char in A
	tax				; Temp. store in X

; Test for a Letter @-Z:

	cmp	#'@'
	blt	testFail
	cmp	#'Z'+1
	bge	testFail

; OK, we may have a variable...
;	but the next character must not be a letter, else it might be a keyword...

	ldy	#1
	lda	(cursor),y
	cmp	#'@'
	blt	tvOK
	cmp	#'Z'
	bge	tvOK
	jmp	testFail

; We have a variable.

tvOK:
	incCursor			; Skip over the variable letter

	txa				; Recover saved variable letter
	and	#$1F			; We know the range so this is fine.
;	sec
;	sbc	#'A'			; To yield 0-25.

; Store in the stack
;	and increment stack pointer

	ldx	arithPtr
	sta	arithStack,x
	inc	arithPtr

; Add 2 to IL PC to jump over fail address
;	and return

	incPc2
	rts
.endproc


;********************************************************************************
;* testFail:
;*	Common code for testNum and testVar ML subroutines
;********************************************************************************

.proc	testFail

; Copy the word at the PC to the PC..
;	(It's the FAIL go-to)

	ldy	#0
	lda	(pc),y			; Low
	tax				; Temp. save
	iny
	lda	(pc),y			; High
	sta	pcH
;	txa
	stx	pcL

	rts
.endproc


;********************************************************************************
;* testNum:
;*	ML Subroutine.
;*	This routine tests for a number in the text @ the cursor.
;*	If  no number is found, I.L. control passes to the fail address.
;*	Otherwise, the number is scanned and put on the arithmetic
;*	stack, with I.L. control passing to the next instruction.
;********************************************************************************

.proc	testNum
	skipSpaces			; Leaves last char in A

; Test for a digit 0-9

	cmp	#'0'
	blt	testFail
	cmp	#'9'+1
	bge	testFail

; OK, we have a leading digit...

	ldx	#0
	stx	regAH
	stx	regAL

nextDigit:
	and	#$0F		; We know it's ASCII digit

; Multiply regA by 10 and add it in:

	tax			; Temp. save

; Copy original to regC

	lda	regAL
	sta	regCL
	lda	regAH
	sta	regCH

; Multiply by 10

	asl	regAL
	rol	regAH		; * 2
	bmi	overflow
	asl	regAL
	rol	regAH		; * 4
	bmi	overflow

	clc			; Add original back in
	lda	regAL
	adc	regCL
	sta	regAL
	lda	regAH
	adc	regCH
	sta	regAH		; * 5
	bmi	overflow

	asl	regAL		; Then double again to get ...
	rol	regAH		; * 10
	bmi	overflow

; Add new number in:

	clc
	txa
	adc	regAL
	sta	regAL
	bcc	:+
	inc	regAH
	bmi	overflow

:	incCursor		; Skip over digit just processed
	ldy	#0
	lda	(cursor),y
	cmp	#'0'
	blt	tnDone
	cmp	#'9'+1
	blt	nextDigit

; Store in stack

tnDone:
	ldx	arithPtr
	lda	regAL
	sta	arithStack,x
	inx
	lda	regAH
	sta	arithStack,x
	inx
	stx	arithPtr

; Add 2 to the IL PC to skip the 'fail' code...

	incPc2
	rts

overflow:
	lda	#eVALU		; Overflow
	jmp	progErr
	
.endproc
