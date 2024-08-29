; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.export _sfos_d_writeseqblock

.code
_sfos_d_writeseqblock:
    ldy #esfos::sfos_d_writeseqblock
    jsr SFOS
    bcc :+
    lda #0
    ldx #0
    rts
:
    lda #1
    tax
    rts

