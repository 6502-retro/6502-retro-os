; vim: ft=asm_ca65
.export _bios_getc	:= $EEDD
.export _bios_getc_nw	:= $EEE8
.export _bios_putc	:= $EEF6
.export _bios_puts

.autoimport

ptr1 := $F2

.code

.proc _bios_puts
	sta ptr1
	stx ptr1+1
charloop:
	lda (ptr1)
	beq charloopend
	jsr _bios_putc
	inc ptr1
	bne charloop
	inc ptr1+1
	bra charloop
charloopend:
	rts
.endproc
