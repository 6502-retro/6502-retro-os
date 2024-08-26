; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

.zeropage
ptr:    .word 0
addr:   .word 0
line:   .word 0
fileaddr: .word 0

.code

main:

    lda #<str_message
    ldx #>str_message
    jsr c_printstr
    jmp WBOOT

.include "../app.inc"

.bss

.rodata
str_message: .byte 10,13,"Hello, from TPA",10,13,0
