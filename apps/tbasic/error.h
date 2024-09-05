
;*********************************************************************************
;* error.h:
;*	Error messages
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

; Error codes

eSTMT	:=   0
eCHAR	:=   1
eSNTX	:=   2
eVALU	:=   3
eEND	:=   4
eNOGO	:=   5
eRTRN	:=   6
eNEST	:=   7
eNEXT	:=   8
eFOR	:=   9
eDIV0	:=  10
eBRK	:=  11
eUNTL	:=  12
eBAD	:=  13

; Function entry points

	.global	syntaxErr		; Shortcut to syntax error
	.global	progErr			; All other errors
