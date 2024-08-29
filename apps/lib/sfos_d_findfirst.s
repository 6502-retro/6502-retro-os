; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.export _sfos_d_findfirst

.code
_sfos_d_findfirst:
    ldy #esfos::sfos_d_findfirst
    jsr SFOS
    bcc :+
    lda #1
    ldx #0
    rts
:   lda #0
    ldx #0
    rts
