; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.export _sfos_d_make

.code
_sfos_d_make:
    ldy #esfos::sfos_d_make
    jsr SFOS
    bcs :+
    lda #0
    ldx #0
    rts
:   lda #1
    ldx #0
    rts

