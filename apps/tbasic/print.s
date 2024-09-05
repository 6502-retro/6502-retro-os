
;*********************************************************************************
;* print.s:
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
	.include	"error.h"
	.include	"ilMacros.h"

	.include	"print.h"


;********************************************************************************
;* pDec:
;*	Print signed decimal number in regA
;*	See: Mike B's code at:
;*	   http://forum.6502.org/viewtopic.php?f=2&t=4894&start=15#p87300
;********************************************************************************

.proc	pDec

; Make +ve if it's -ve

	lda	regAH
	bpl	:+

	sec		; Subtract from 0. See flipSign in arith.s
	lda	#0
	sbc	regAL
	sta	regAL
	lda	#0
	sbc	regAH
	sta	regAH

	lda	#'-'
	jsr	putChar

:	lda	variablesL+0	; Get width from the @ variable
	and	#$7F		; Sanity/Stupidty
	sta	num

	lda	#0          	; stack sentinel
	pha			; push sentinel
pDec2:
	lda	#0		; init remainder
	clv			; init "not done" flag
	ldy	#16		; bit width of argument
pDec3:
	cmp	#10/2		; divide argument by 10
	bcc	pDec4
	sbc	#10/2+128	; set "not done" flag for
	sec			;   quotient > 0
pDec4:
	rol	regAL		; when inner loop is done,
	rol	regAH		;   argument /= 10 ...
	rol			;   ... and A = remainder
	dey
	bne	pDec3		; loop until done dividing
	ora	#'0'		; xlate remainder to ascii
	.byte	$CD		; naked cmp abs opcode
pDecPad:
	lda	#' '		; Pad character
	pha			; push digit or pad char
	dec	num		; update output char count
	bvs	pDec2		; loop until quotient == 0
	bpl	pDecPad		; pad any remaining width
	pla
pDecOut:
	jsr	putChar		; output reversed digits
	pla
	bne	pDecOut		; until sentinel is popped

 	rts
.endproc


;********************************************************************************
;* pHex:
;*	Print hex number in regA
;********************************************************************************

; The cunningPlan saves 13 bytes....

cunningPlan	:=	1

.proc	pHex
	lda	regAH
	jsr	_oHex8
	lda	regAL		; Fall into...
.endproc

.proc	_oHex8
	pha			; Temp. save
	lsr	a		; A := A >> 4
	lsr	a
	lsr	a
	lsr	a
	jsr	_oHex4		; Print top 4 bits as hex
	pla			; Restore A and fall into ...
.endproc

.proc	_oHex4
	and	#$0F

.ifdef	cunningPlan
	sed
	clc
	adc	#$90		; Yields $90-$99 or $00-$05
	adc	#$40		; Yields $30-$39 or $41-$46
	cld
	jmp	putChar
.else
	tay
	lda	hexTable,y
	jmp	putChar		; and return

hexTable:
	.byte	"0123456789ABCDEF"
.endif
.endproc


;********************************************************************************
;* pStringV:
;*	Print memory as a string.
;*	  PRINT $ factor
;*	Note: Strings are zero or CR terminated.
;********************************************************************************

.proc	pStringV
	ldy	#0
loop:	lda	(regA),y
	beq	done
	cmp	#$0D
	beq	done
	jsr	putChar
	iny
	bne	loop
done:
	rts
.endproc


;********************************************************************************
;* pStringP:
;*	Print string in program text
;*	  PRINT "string"
;********************************************************************************

.proc	pStringP
	ldy	#0
pStringP1:
	lda	(cursor),y	; Fetch the character
	cmp	#'"'		; Terminating quote?
	beq	:+
	cmp	#$0D		; CR is error - ran off the end of the line
	beq	error
	jsr	putChar
	incCursor		; Next character
	jmp	pStringP1

:	incCursor		; Skips the trailing "
	rts

error:
	lda	#eEND
	jmp	progErr
.endproc


;********************************************************************************
;* vdu:
;*	Output a character
;********************************************************************************

.proc	vdu
	lda	regAL
	jmp	putChar
.endproc
