
;*********************************************************************************
;* ilMacros.s:
;*	These are the IL macros.
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
; macro strTop:
;	Include a string but set the top-bit of the last character
;********************************************************************************

.macro strTop	str
	.repeat .strlen(str)-1,I			; All but the last
	  .byte    .strat(str,I)
	.endrep
	.byte   .strat(str,.strlen(str)-1) | $80	; The last character
.endmacro


;*********************************************************************************
;* incCursor
;*	Increment the Cursor pointer
;*********************************************************************************

.macro	incCursor
.local	over
	inc	cursorL
	bne	over
	inc	cursorH
over:
.endmacro


;*********************************************************************************
;* bumpCursor
;*	Add a value to the Cursor pointer
;*********************************************************************************

.macro	bumpCursor	N
.local	over
	clc
	lda	cursorL
	adc	#N
	sta	cursorL
	bcc	over
	inc	cursorH
over:
.endmacro

;*********************************************************************************
;* skipSpaces:
;*	Skips over any spaces at the cursor.
;*	Leaves first non-space character in Acc
;*********************************************************************************

.macro	skipSpaces
.local	loop
.local	done
	ldy	#0
loop:	lda	(cursor),y
	cmp	#' '
	bne	done
	incCursor
	bne	loop
done:
.endmacro

	
;*********************************************************************************
;* incPc2:
;*	Add 2 to the IL PC.
;*	May replace with jsr to save space if needed.
;*********************************************************************************

.macro	incPc2
.local	done
	clc
	lda	pcL
	adc	#2
	sta	pcL
	bcc	done
	inc	pcH
done:
.endmacro
