
;********************************************************************************
;* sxb-mon.s:
;*	A trivial 'monitor' to bootstrap GIBL on an W65C134-SXB board.
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

	.include	"regs-sxb.h"

	.define	CTRL_C	3
	.define	F_CPU	36864

; Baud rates for the 3.6864Mhz xtal...

baud	:=	b9600

b75	:=	$0BFF		;    75
b110	:=	$082E		;   110
b150	:=	$05FF		;   150
b300	:=	$02FF		;   300
b600	:=	$017F		;   600
b1200	:=	$00BF		;  1200
b1800	:=	$007F		;  1800
b2400	:=	$005F		;  2400
b4800	:=	$002F		;  4800
b9600	:=	$0017		;  9600
b19200	:=	$000B		; 19200
b38400	:=	$0005		; 38400


; Buffer sizes *must* be powers of 2

	.define	TX_BUFFER_SIZE	128
	.define	RX_BUFFER_SIZE	128

TX_BUFFER_MASK	:=	TX_BUFFER_SIZE-1
RX_BUFFER_MASK	:=	RX_BUFFER_SIZE-1

;* Zero page data
;*	We have a generous 16 bytes

	.org	$40
	.segment        "ZEROPAGE":zeropage

txHead:		.res	1
txTail:		.res	1
rxHead:		.res	1
rxTail:		.res	1

pStr		=	pStrL
pStrL:		.res	1
pStrH:		.res	1

ccFlag:		.res	1		; Ctrl-C flag

spare0:		.res	1
spare1:		.res	1
spare2:		.res	1
spare3:		.res	1

cents:		.res	1	; $4B - 0-99 @ 100Hz
secs0:		.res	1	; $4C - 100Hz ticker
secs1:		.res	1
secs2:		.res	1
secs3:		.res	1


;* Main RAM data

	.org	$200
	.segment	"DATA"

txBuffer:	.res	TX_BUFFER_SIZE
rxBuffer:	.res	RX_BUFFER_SIZE

;********************************************************************************
;* reset:
;*	Sort of. We get here by using the ROM monitor to
;*		G E000
;*	which is inside the GIBL area - Code there disables interrupts
;*	and the internal ROM and enables the top bank of the EEPROM (me!)
;*	then does a JMP $F000 and we're here.
;*
;*	All we need here is to disable all interrupts and interrupt sources
;*	(re) setup the serial port and engage our own drivers for the serial
;*	port so we can escape the on-board ROM and free-up all the Zero Page
;*	RAM, etc.
;*
;*	When done we'll jump back to $E010 and let GIBL take over.
;********************************************************************************

	.org	$F000
	.segment	"CODE"


reset:	jmp	doReset		; $F000
	jmp	putchar		; $F003
	jmp	newline		; $F006
	jmp	putstr		; $F009
	jmp	getchar		; $F00C
	jmp	checkInt	; $F00F

	jmp	turnKeyOn	; $F012
	jmp	turnKeyOff	; $F015

doReset:
	sei
	ldx	#$FF		; The usual
	txs
	cld

	jsr	hardwareInit
	jsr	aciaInit
	jsr	timerInit

	cli

	lda	#0
	jsr	putchar
	jsr	putchar
	jsr	putchar
	jsr	putchar

	jsr	putstr
	.byte	13,10,10,"W65C134-SXB: 32K",13,10,10,0

; Make sure there is a GIBL...

	ldy	#0
:	lda	$E00A,y
	beq	gotGibl
	cmp	signature,y
	bne	noGibl
	iny
	bra	:-

gotGibl:
	jmp	$E010

noGibl:
	jsr	putstr
	.byte	"* No GIBL ",0

loop:	bra	loop

; Must match that in system-sxb_rom.s

signature:
	.byte	"*GIBL", 0


;********************************************************************************
;* putstr:
;*	Print a zero-terminated string stored in-line with the program code.
;*	Standard in RubyOS, but a copy is included here anyway.
;*	Usage:
;*		jsr	putstr
;*		.byte	"Hello, world", 0
;*	Saves X&Y, but uses A.
;********************************************************************************

.proc	putstr

; Pull return address off the stack to use to get the data from

	pla
	sta	pStrL
	pla
	sta	pStrH

strout1:
	inc	pStrL
	bne	strout2
	inc	pStrH
strout2:
	lda	(pStr)
	beq	stroutEnd
	jsr	putchar			; Should preserve Y
	bra	strout1

; Push return address back onto the stack

stroutEnd:
	lda	pStrH
	pha
	lda	pStrL
	pha

	rts
.endproc


;********************************************************************************
;* hardwareInit:
;*	Message from the SXB ROM:
;*
;*	Reset all regs to reset values (in case we had a JMP reset rather
;*	than a hard reset. Exception is TCR1 because the chip will die if
;*	we switch to slow clock and shut off fast clock simultaniously,
;*		nice ...
;********************************************************************************

.proc	hardwareInit
	stz	regIFR1		; Disable interupts and clear any pending flags
	stz	regIFR2
	stz	regIER1
	stz	regIER2

	stz	regPDD4		; Make ports 4,5 and 6 input mode
	stz	regPDD5
	stz	regPDD6

	stz	regPD4		; Set outputs low if they're ever changed to output mode
	stz	regPD5
	stz	regPD6

	stz	regTCR2		; Disable T1 and T2 clocks

	lda	#$FF		; RAM/EEPROM Enabled, LEDs off
	sta	regPD3

	lda	#$F9		; Disable TA and TM outputs, leave system clocks as-is.
	trb	regTCR1
	rts
.endproc


;********************************************************************************
;* aciaInit:
;*	Initialise the ACIA on the '134
;*
;*	Port P6 has the IO pins connected to the ACIA, as well as some
;*	of the bits in Port 4. (Sheesh!)
;*
;*	Port 6.0: Rx
;*	Port 6.1: Tx
;*	Port 6.2: DTRb
;*	Port 4.7: DSRb - FFS! Why not a spare bit in P6!!!
;********************************************************************************

aciaInit:
	lda	#0		; Turns it all off.
	sta	regACSR

	lda	#<baud
	sta	regTALL
	lda	#>baud
	sta	regTALH

	stz	txHead
	stz	txTail
	stz	rxHead
	stz	rxTail
	stz	ccFlag

	lda	#$24		; See data sheet pg 14/15.
	sta	regACSR

; Setup IO ports and timer control

	lda	#%00000110	; Port 6: Bits 1 and 2 - Tx and DTRb
	tsb	regPDD6
	lda	#%00000001	; Bit 0 - Rx
	trb	regPDD6
	lda	#%00000010	; Tx high
	tsb	regPD6
	lda	#%00000100	; DTRb output Low, so remote can send us stuff
	trb	regPD6

; We'll set the DSR pin to input mode, but are not going to use it.

	lda	#%10000000	; Port 4: Bit 7 - DSRb
	trb	regPDD4

	lda	#$0E		; Set TCR1 - Enable Timer A and make sure fast clocks are GO
	sta	regTCR1

	stz	regARTD		; Send a NUL through the ACIA to kick it off.
	lda	regARTD		; ... to clear any pending input

	rts


;********************************************************************************
;* timerInit:
;*	Setup T1 for a 100Hz interrupt
;********************************************************************************

timerInit:
	stz	cents
	stz	secs0
	stz	secs1
	stz	secs2
	stz	secs3

	lda	#<F_CPU
	sta	regT1LL
	lda	#>F_CPU
	sta	regT1LH

	lda	#$10
	sta	regIER2		; Interrupt enable T1

	lda	#$01
	sta	regTCR2

	rts



;********************************************************************************
;* putchar:
;*	Output a single character. 
;*	Preserve A, X & Y.
;********************************************************************************

.proc	putchar
	phy
	pha

; Check for space - head+1 must not = tail

wait:	ldy	txHead
	iny
	tya
	and	#TX_BUFFER_MASK		; Buffer wrap
	cmp	txTail
	beq	wait

; Insert char at the head

	ldy	txHead
	pla
	sta	txBuffer,y

; Bump head pointer

	iny
	tya
	and	#TX_BUFFER_MASK
	sta	txHead

; Check serial Tx interrupt
;	Basically, force it no matter what.

	lda	#$03
	tsb	regACSR
	ply
	rts
.endproc


;********************************************************************************
;* txInt:
;*	Handle an interupt from the ACIA Transmitter -
;*	Essentially the "buffer empty" interrupt, so we fetch another byte and
;*	throw it out...
;********************************************************************************

.proc	txInt
	phy
	ldy	txTail			; Fetch from the tail
	cpy	txHead			; Tail = head? Nothing to do..
	beq	shutdown

	pha
	lda	txBuffer,y		; Fetch
	sta	regARTD			; Write to output register
	iny				; Bump/wrap tail pointer
	tya
	and	#TX_BUFFER_MASK
	sta	txTail
done:
	pla
	ply
	rti

; Disable the transmitter

shutdown:
	pha
	lda	#$03
	trb	regACSR
	bra	done
.endproc


;********************************************************************************
;* getchar:
;*	Wait for, then return the next character recieved
;********************************************************************************

.proc	getchar
	lda	rxHead			; Wait until we have something
	cmp	rxTail
	beq	getchar

	phy				; Save Y
	ldy	rxTail			; Use it to get the byte out of the buffer
	lda	rxBuffer,y
	pha				; tmp. save
	iny				; bump/wrap the buffer pointer
	tya
	and	#RX_BUFFER_MASK
	sta	rxTail

	pla				; Restore and return
	ply
	rts
.endproc



;********************************************************************************
;* rxInt:
;*	ACIA Recieve Interrupt handler
;********************************************************************************

.proc	rxInt
	phx
	phy
	pha

	ldx	regARTD			; Read character / Resets the interrupt flags

; Check for space - head+1 must not = tail

	ldy	rxHead
	iny
	tya
	and	#RX_BUFFER_MASK		; Buffer wrap
	cmp	rxTail
	beq	processed		; Head+1 == tail, so buffer full, so ignore

; Insert char at the head

	dey				; Back to oiginal head pointer
	txa
	sta	rxBuffer,y

	cmp	#CTRL_C
	bne	:+

	sta	ccFlag			; just has to be non-zero

; Bump head pointer

:	iny
	tya
	and	#RX_BUFFER_MASK
	sta	rxHead

processed:
	pla
	ply
	plx
	rti
.endproc


;********************************************************************************
;* checkInt:
;*	Return non-zero if a Ctrl-C has happened
;********************************************************************************

.proc	checkInt
	lda	ccFlag
	stz	ccFlag			; Always clear it
	rts
.endproc


;********************************************************************************
;* newline:
;*	Output a newline to the terminal
;********************************************************************************

.proc	newline
	jsr	putstr
	.byte	13,10,0
	rts
.endproc


;********************************************************************************
;* t1IRQ:
;*	Handle the T1 IRQ - hopefully running at 100/sec ...
;********************************************************************************

t1IRQ:
	pha
	lda	#$10
	tsb	regIFR2

	inc	cents
	lda	cents
	cmp	#100
	beq	doSecs
	pla
	rti

doSecs:
	pla
	stz	cents
	inc	secs0
	beq	:+
	rti

:	inc	secs1
	beq	:+
	rti

:	inc	secs2
	beq	:+
	rti

:	inc	secs3
	rti

;********************************************************************************
;* Debug?
;********************************************************************************

.proc	oHex8
	pha			; Temp. save
	lsr	a		; A := A >> 4
	lsr	a
	lsr	a
	lsr	a
	jsr	oHex4		; Print top 4 bits as hex
	pla			; Restore A and fall into ...
.endproc

.proc	oHex4
	and	#$0F
	sed
	clc
	adc	#$90		; Yields $90-$99 or $00-$05
	adc	#$40		; Yields $30-$39 or $41-$46
	cld
	jmp	putchar
.endproc


.proc	turnKeyOn
	jsr	putstr
	.byte	"Boot to GIBL: Enabled",13,10,0

	ldy	#0
:	lda	tkOn,y
	sta	$300,y
	iny
	bne	:-

	jmp	$300
.endproc


.proc	turnKeyOff
	jsr	putstr
	.byte	"Boot to GIBL: Disabled",13,10,0

	ldy	#0
:	lda	tkOff,y
	sta	$300,y
	iny
	bne	:-

	jmp	$300
.endproc


.macro	flaCmd	addr,data
	lda	#data
	sta	$8000+addr
.endmacro

;********************************************************************************

.proc	tkOn
	sei			; Need to stop interrupts for now

; Erase the EEPROM sector

	flaCmd	$5555,$AA		; Unlock for sector erase
	flaCmd	$2AAA,$55
	flaCmd	$5555,$80
	flaCmd	$5555,$AA

	flaCmd	$2AAA,$55		; Sector erase command part 1...

	lda	#$30			; Actual Erase command
	sta	$8000

; Somewhat paranoid but we'll make sure the first 256 bytes are all $FF

	ldy	#0
wait:
	lda	$8000,y
	cmp	#$FF
	bne	wait
	iny
	bne	wait

; OK, Erased the sector, lets write the data:

writeLoop:
	flaCmd	$5555,$AA		; Unlock
	flaCmd	$2AAA,$55
	flaCmd	$5555,$A0		; Byte write

	lda	turnKeyData,y
	cmp	#$FF
	beq	done
	sta     $8000,y
waitByte:
	cmp	$8000,y
	bne	waitByte
	iny
	bne	writeLoop

done:
	cli
	rts
.endproc

turnKeyData:
	.byte	"WDC "
	jmp	$E000
	.byte	$FF

;********************************************************************************

.proc	tkOff
	sei			; Need to stop interrupts for now

; Erase the EEPROM sector

	flaCmd	$5555,$AA		; Unlock for sector erase
	flaCmd	$2AAA,$55
	flaCmd	$5555,$80
	flaCmd	$5555,$AA

	flaCmd	$2AAA,$55		; Sector erase command part 1...

	lda	#$30			; Actual Erase command
	sta	$8000

; Somewhat paranoid but we'll make sure the first 256 bytes are all $FF

	ldy	#0
wait:
	lda	$8000,y
	cmp	#$FF
	bne	wait
	iny
	bne	wait

	cli
	rts
.endproc


	.res	$FFD0-*,$FF
vectors:

pe44:	.word	0		; +ve Edge, Port 4, bit 4
pe45:	.word	0		; +ve Edge, Port 4, bit 5
ne46:	.word	0
ne47:	.word	0
pe50:	.word	0		; +ve Edge, Port 5, bit 0
pe51:	.word	0		; +ve Edge, Port 5, bit 1
ne52:	.word	0		; -ve Edge, Port 5, bit 2
ne53:	.word	0		; -ve Edge, Port 5, bit 3
res1:	.word	0		; Reserved
res2:	.word	0		; Reserved
irqAt:	.word	txInt		; ACIA Tx
irqAr:	.word	rxInt		; ACIA Rx
irqSIB:	.word	0		; Serial InterfaceBus
pe54:	.word	0		; +ve Edge, Port 4, bit 4
pe55:	.word	0		; +ve Edge, Port 4, bit 4
pe56:	.word	0		; +ve Edge, Port 4, bit 4
ne57:	.word	0		; -ve Edge, Port 5, bit 7
irqT1:	.word	t1IRQ		; Timer 1
irqT2:	.word	0		; Timer 2
irq1:	.word	0		; IRQ 1 (P41)
irq2:	.word	0		; IRQ 2 (P42)
NMIv:	.word	0		; Non maskable Interrupt, P40
RESv:	.word	reset		; Reset
BRKv:	.word	0		; BRK Instruction
