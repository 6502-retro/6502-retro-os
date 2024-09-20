; vim: ft=asm_ca65
.export _go
.code
_go:
	sta $10
	stx $11
	jmp ($10)

