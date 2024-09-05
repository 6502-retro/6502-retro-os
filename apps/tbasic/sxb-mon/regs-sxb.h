
;********************************************************************************
;* regs-sxb.h:
;*	Registers in the W65C134-SXB SoC
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

regPD0		:=	$00	; Port data 0
regPD1		:=	$01	; Port data 1
regPD2		:=	$02	; Port data 2
regPD3		:=	$03	; Port data 3

regPDD0		:=	$04	; Port Data Direction 0
regPDD1		:=	$05	; Port Data Direction 1
regPDD2		:=	$06	; Port Data Direction 2
regPCS3		:=	$07	; Port Chip Select Register

regIFR2		:=	$08	; Interrupt Flags 2
regIER2		:=	$09	; Interrupt Enable Register 2

regTCR1		:=	$0A	; Timer Control 1
regTCR2		:=	$0B	; Timer Control 2

regT1LL		:=	$0C	; Timer 1 Latch Low
regT1LH		:=	$0D	; Timer 1 Latch High

regT2LL		:=	$0E	; Timer 2 Latch Low
regT2LH		:=	$0F	; Timer 2 Latch High

regT1CL		:=	$10	; Timer 1 Counter Low
regT1CH		:=	$11	; Timer 1 Counter High

regT2CL		:=	$12	; Timer 2 Counter Low
regT2CH		:=	$13	; Timer 2 Counter High

regSTATE	:=	$14	; SIB Bus State Register
regSR0		:=	$15	; SIB Register 0
regSR1		:=	$16	; SIB Register 1
regSR2		:=	$17	; SIB Register 2
regSR3		:=	$18	; SIB Register 3
regSCSR		:=	$19	; SIB Control & Status Register
regBAR		:=	$1A	; SIB Address Register

regBCR		:=	$1B	; Bus control Register

regPD4		:=	$1C	; Port data 4
regPD5		:=	$1D	; Port data 5

regPDD4		:=	$1E	; Port Data Direction 4
regPDD5		:=	$1F	; Port Data Direction 5

regPD6		:=	$20	; Port Data 6
regPDD6		:=	$21	; Port Data direction 6

regACSR		:=	$22	; Async. Control & Status Register (UART)
regARTD		:=	$23	; Async. Rec/Trans data registre (UART)

regTALL		:=	$24	; Timer A Latch Low
regTALH		:=	$25	; Timer A Latch High
regTACL		:=	$26	; Timer A Counter Low
regTACH		:=	$27	; Timer A Counter High
regTMLL		:=	$28	; Timer M Latch Low
regTMLH		:=	$29	; Timer M Latch High
regTMCL		:=	$2A	; Timer M Counter Low
regTMCH		:=	$2B	; Timer M Counter High

regIFR1		:=	$2C	; Interrupt Flags 1
regIER1		:=	$2D	; Interrupt Enable Register 1

regRES1		:=	$2E	; Reserved
regRES2		:=	$2F	; Reserved
