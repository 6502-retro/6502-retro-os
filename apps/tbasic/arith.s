
;*********************************************************************************
;* arith.s:
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
	.include	"gibl.h"
	.include	"error.h"
	.include	"system.h"

	.include	"il.h"
	.include	"ilMacros.h"
	.include	"ilExec.h"
	.include	"ilUtils.h"

	.include	"arith.h"

; Tuning?

; Makes MUL fractionally faster at the expense of code space.
;	Adds 8 bytes.

; FASTER_MUL	:= 1

; Makes DIV fractionally faster at the expense of code space
;	Adds 24 bytes.

; FASTER_DIV	:= 1


;********************************************************************************
;* ADD:
;*	Take top 2 items off the stack, add them, put the result back. Simples
;*		s[1] := s[1] + s[0] ; sp--
;********************************************************************************

.proc	ADD
	ldx	arithPtr

	clc
	lda	arithStack-4,x
	adc	arithStack-2,x
	sta	arithStack-4,x

	lda	arithStack-3,x
	adc	arithStack-1,x
	sta	arithStack-3,x
	bvs	overflow

	dex
	dex
	stx	arithPtr

	rts
.endproc

.proc	overflow
	lda	#eVALU
	jmp	progErr
.endproc


;********************************************************************************
;* SUB:
;*	Take top 2 items off the stack, subtract them, put the result back.
;*		s[1] := s[1] - s[0] ; sp--
;********************************************************************************

.proc	SUB
	ldx	arithPtr

	sec
	lda	arithStack-4,x		; s[1] low
	sbc	arithStack-2,x		; s[0] low
	sta	arithStack-4,x

	lda	arithStack-3,x		; s[1] high
	sbc	arithStack-1,x		; s[0] high
	sta	arithStack-3,x
	bvs	overflow

	dex
	dex
	stx	arithPtr
	
	rts
.endproc

	
;********************************************************************************
;* fixSigns:
;*	Record and fix (make positive) the signs of the top 2 numbers
;*	on the arith stack.
;*	This is used in MUL and DIV/REM to (hopefully) make their code
;*	easier to work as they then only have to work with positive numbers.
;********************************************************************************

.proc	fixSigns
	ldy	#0		; Negative counter

	ldx	arithPtr
	lda	arithStack-1,x	; High
	bpl	:+		; ... is positive
	jsr	flipSign
	iny

:	dex
	dex
	lda	arithStack-1,x	; High
	bpl	:+
	jsr	flipSign
	iny

:	sty	num

	ldx	arithPtr	; Restore
	rts
.endproc


;********************************************************************************
;* MUL
;*	Take top 2 items off the stack, multiply them, put the result back.
;*		s[1] := s[1] * s[0] ; sp--
;********************************************************************************

;* MUL_MB is an adaption of the multiply code written by Michael T. Barry
;*	for his porting of VTL from the original 6800 version.

USE_MUL_MB	:=	1

.ifdef	USE_MUL_MB

.proc	MUL

	jsr	fixSigns

; Copy stack items into regB and regC
;	We do: TopOfStack := regB * regC

	lda	arithStack-4,x		; Low
	sta	regBL
	lda	arithStack-3,x		; High
	sta	regBH

	lda	arithStack-2,x		; Low
	sta	regCL
	lda	arithStack-1,x		; High
	sta	regCH

	lda	#0			; Zero the Product accumulator
.ifdef	FASTER_MUL
	sta	regAL
	sta	regAH
.else
	sta	arithStack-4,x
	sta	arithStack-3,x
.endif

mulLoop:
	lda	regCL			; Exit early if regC = 0
	ora	regCH
	beq	mulDone

	lsr	regCH
	ror	regCL			; regC /= 2
	bcc	mul3

.ifdef	FASTER_MUL
	clc
	lda	regAL			; product += regB
	adc	regBL
	sta	regAL
	lda	regAH
	adc	regBH
	sta	regAH
.else
	clc
	lda	arithStack-4,x		; product += regB
	adc	regBL
	sta	arithStack-4,x
	lda	arithStack-3,x
	adc	regBH
	sta	arithStack-3,x
.endif

	bcs	overflow		; Overflow?

mul3:
	asl	regBL			; regB *= 2
	rol	regBH
	bne	mulLoop
	lda	regBL			; Loop until done
	bne	mulLoop
mulDone:

	dex				; Drop old top of stack
	dex
	stx	arithPtr

.ifdef	FASTER_MUL
	lda	regAL
	sta	arithStack-2,x
	lda	regAH
	sta	arithStack-1,x
.endif

	lda	num
	and	#1
	bne	flipSign
	rts
.endproc

.else


;********************************************************************************
;* MUL
;*	Take top 2 items off the stack, multiply them, put the result back.
;*		s[1] := s[1] * s[0] ; sp--
;*
;* Notes:
;*	Assumes regB and regC are consecutive in RAM. These are used to hold the
;*	32-bit result.
;*	Result is calculated directly on the stack.
;*	Algorithm is naive, but works well. Faster ones are out there...
;********************************************************************************

.proc	MUL

; Check signs and make positive if needed

	jsr	fixSigns

; Zero the 32-bit result in regB, regC:
;	Note: regB, regC must be consecutive in zero page.

	lda	#0		; Holds high byte of result
	sta	regB+0
	sta	regB+1
	sta	regB+2
	sta	regB+3

	ldy	#15		; Loop counter

mulLoop:
	lsr	arithStack-1,x	; regB+1		; 7	Rotate right from the top byte down
	ror	arithStack-2,x	; regB+0		; 7	Bottom bit now in Carry
	bcc	mul2		; 2.5	No carry
				; 	... else add regA into the result
	pha			; 2	Temp save
	clc			; 2
	lda	arithStack-4,x	; regA+0		; 4
	adc	regB+2		; 4
	sta	regB+2		; 4

	pla			; 2	Restore top byte
	adc	arithStack-3,x	; regA+1		; 4

; Ripple A (top word) and regB/2,1,0 down to the right

mul2:	ror	a		; 2
	ror	regB+2		; 7
	ror	regB+1		; 7
	ror	regB+0		; 7

; Multply step...

	dey
	bne	mulLoop

; Last iteration

	ror	a		; 2
	ror	regB+2		; 7
	ror	regB+1		; 7
	ror	regB+0		; 7
	sta	regB+3		; Store top byte

; 32-bit result now in regB,regC
; .... copy bottom 16-bits to top of stack, discarding overflow
;	fixup the sign of the result and we're done.

	lda	regB+0		; Low byte
	sta	arithStack-4,x
	lda	regB+1		; High byte
	sta	arithStack-3,x

; Lets check for overflow ...

	lda	regB+2
	ora	regB+3
	bne	overflow

	dex
	dex
	stx	arithPtr

	lda	num
	and	#1
	bne	flipSign
	rts
.endproc
.endif


;********************************************************************************
;* NEG:
;*	Negate the top item on the stack
;*		s[0] := - s[0]
;********************************************************************************

.proc	NEG
	ldx	arithPtr	; And simply fall into ...
.endproc


;********************************************************************************
;* flipSign:
;*	change the sign of the value at the top of the stack from positive
;*	to negative or vice versa.
;********************************************************************************

.proc	flipSign

; 6502 Optimised way:
;	= 2^N - X
;	Where N is the number of bits we're using and X is the input number
;	So we need 17 bits - which in the 6502 world the carry flag efectively
;	gives us while subtract is defned as invert and add, so ...

	sec
	lda	#0
	sbc	arithStack-2,x	; Low
	sta	arithStack-2,x

	lda	#0
	sbc	arithStack-1,x	; High
	sta	arithStack-1,x

; Classic way:
;	= Flip the bits and add 1:

;	clc
;	lda	arithStack-2,x	; s[0] low
;	eor	#$FF		; ... invert
;	adc	#1		; ... add 1
;	sta	arithStack-2,x
;
;	lda	arithStack-1,x	; s[0] high
;	eor	#$FF		; ... Invert
;	adc	#0		; ... add carry
;	sta	arithStack-1,x

	rts
.endproc



;********************************************************************************
;* DIV
;*	Take top 2 items off the stack, divide them, put the result back.
;*		s[1] := s[1] / s[0] ; sp--
;*
;* Notes:
;*	Assumes regB and regC are consecutive in RAM. These are used to hold the
;*	32-bit result.
;*	Result is calculated directly on the stack.
;*	Algorithm is naive, but works well. Faster ones are out there...
;********************************************************************************

.proc	div0
	lda	#eDIV0
	jmp	progErr
.endproc


;********************************************************************************
; remDiv:
;	Common code for both the REM and DIV opcodes
;********************************************************************************

.macro	divStep
	.local	div2

.ifdef	FASTER_DIV
	asl	regB+0	; arithStack-4,x	; regB+0		; Shift high bit of B into remainder
	rol	regB+1	; arithStack-3,x	; regB+1
	rol	regC+0
	rol	regC+1

	lda	regC+0
	sec
	sbc	regA+0	; arithStack-2,x	; regA+0
	sta	temp0
	lda	regC+1
	sbc	regA+1	; arithStack-1,x	; regA+1
	bcc	div2
	sta	regC+1
	lda	temp0
	sta	regC+0
	inc	regB+0	; arithStack-4,x	; regB+0
.else
	asl	arithStack-4,x	; regB+0		; Shift high bit of B into remainder
	rol	arithStack-3,x	; regB+1
	rol	regC+0
	rol	regC+1

	lda	regC+0
	sec
	sbc	arithStack-2,x	; regA+0
	sta	temp0
	lda	regC+1
	sbc	arithStack-1,x	; regA+1
	bcc	div2
	sta	regC+1
	lda	temp0
	sta	regC+0
	inc	arithStack-4,x	; regB+0
.endif

div2:
.endmacro

.proc	remDiv

; Check signs and make positive if needed

	jsr	fixSigns

; Check for div0

	lda	arithStack-2,x
	ora	arithStack-1,x
	beq	div0

; regC is used to hold the remainder

	lda	#0
	sta	regC+0
	sta	regC+1

; Move stack into regA and regB for speed

.ifdef	FASTER_DIV
	lda	arithStack-4,x
	sta	regB+0
	lda	arithStack-3,x
	sta	regB+1
	lda	arithStack-2,x
	sta	regA+0
	lda	arithStack-1,x
	sta	regA+1
.endif

; Perform the division steps

	ldy	#16
:	  divStep
	dey
	bne	:-

; Result of division is in regB, the remainder in regC

	dex
	dex
	stx	arithPtr

	rts
.endproc


;********************************************************************************
; DIV
;	A := B / A
;********************************************************************************


.proc	DIV
	jsr	remDiv

; Result in regB, so ...

.ifdef	FASTER_DIV
	lda	regBL
	sta	arithStack-2,x
	lda	regBH
	sta	arithStack-1,x
.endif

; Check/Fix sign

	lda	num
	and	#1
	bne	flipSign
	rts
.endproc


;********************************************************************************
; MOD:
;	A := B % A (remainder)
;********************************************************************************

.proc	MOD
	jsr	remDiv

; Remainder in regC, so

	lda	regCL
	sta	arithStack-2,x
	lda	regCH
	sta	arithStack-1,x

; Check/Fix sign

	lda	num
	and	#1
	bne	flipSign
	rts
.endproc


;********************************************************************************
;* getRnd
;*	Return the next pseudo random number
;********************************************************************************

.proc	getRnd
	clc
	lda	#17		; Any odd value
	adc	rndX
	sta	rndX
	adc	rndY
	sta	rndY
	asl	a
	adc	rndX
	tay
	eor	rndX

; Push into stack

	ldx	arithPtr
	sta	arithStack+0,x
	tya
	and	#$7F
	sta	arithStack+1,x
	inx
	inx
	stx	arithPtr
	rts
.endproc


;********************************************************************************
;* seedRnd
;*	Seed the PRNG..
;********************************************************************************

.proc	seedRnd
	lda	regAL
	sta	rndX
	lda	regAH
	sta	rndY
	rts
.endproc
