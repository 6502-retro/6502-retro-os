
;********************************************************************************
;* data.h:
;*	System specific data.
;*
;*	To port gibl to another 6502 system you need to change stuff
;*	in this file. It should be fairly obvious ... See PORTING.TXT
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

.if	.defined (ruby)
		.include	"data-ruby.h"
.elseif .defined (sxb_ram)
		.include	"data-sxb_ram.h"
.elseif .defined (retro)
		.include	"data-retro.h"
.elseif .defined (sxb_rom)
		.include	"data-sxb_rom.h"
.else
		.error		"No Platform Defined"
.endif
