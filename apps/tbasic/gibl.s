
;*********************************************************************************
;* gibl.s:
;*	Generic startup after doing all the system specific stuff.
;*********************************************************************************


; Un-comment 1, 2 or all 3 ...

;VERBOSE_BANNER	:=	1
;BRIEF_BANNER	:=	1
 TINY_BANNER	:=	1


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
	.include	"il.h"
	.include	"ilExec.h"
	.include	"system.h"
	.include	"release.h"

	.include	"gibl.h"


;********************************************************************************
;* gibl:
;*	Main GIBL entry point - announce and start the IL.
;********************************************************************************

gibl:

; Setup screen and say hello.
;	... possibly a bit too verbose when the aim
;	 is under 4K but we're well on-track there. For now.

	jsr	putStr

.ifdef	VERBOSE_BANNER
	.byte						12,10	; Clears most screens...
	.byte	"  ____ ___ ____  _",			13,10
	.byte	" / ___|_ _| __ )| |",			13,10
	.byte	"| |  _ | ||  _ \| |",			13,10
	.byte	"| |_| || || |_) | |___",		13,10
 	.byte	" \____|___|____/|_____|",		13,10,10
.endif

.ifdef	sxb_ram
	.byte	13,10,10,"W65C134-SXB: RAM: Flash Utility",13,10
.endif

.ifdef	BRIEF_BANNER
	.byte	"Gordons Interactive BASIC Language: "
	.byte	.sprintf ("[v%02d]", release),		13,10
.endif

.ifdef	TINY_BANNER
	.byte	"GIBL: "
	.byte	.sprintf ("[v%02d]", release),		13,10
.endif

	.byte	0

; Initialise the IL PC so it can take over from here:

	lda	#<ilBegin
	sta	pcL
	lda	#>ilBegin
	sta	pcH

	jmp	ilExec
