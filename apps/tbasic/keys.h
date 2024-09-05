
;********************************************************************************
;* keys.h:
;*	Some key/character definitions
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


KEY_CTRL_A	=	  1	; Line edit: Start of line
KEY_CTRL_C	=	  3	; Abandon line
KEY_CTRL_D	=	  4	; Delete char under the cursor
KEY_CTRL_E	=	  5	; Line edit: End of line

KEY_CTRL_K	=	 11	; Line kill
KEY_CTRL_U	=	 21	; Line kill

KEY_START	=	KEY_CTRL_A
KEY_END		=	KEY_CTRL_E
KEY_DEL_UNDER	=	KEY_CTRL_D
KEY_BS		=	  8	; Ctrl-H
KEY_LEFT	=	  8	;   Alias
KEY_FF		=	 12	; Ctrl-L
KEY_RIGHT	=	 12	;   Alias
KEY_LF		=	 10	
KEY_ESC		=	 27
KEY_SPACE	=	 32
KEY_TAB		=	  9
KEY_DEL		=	127

VDU_LEFT	=	  8
VDU_HOME	=	 12

LF		=	10	; Aliases
CR		=	13
