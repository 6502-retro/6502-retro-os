; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "bios.inc"

.export _sfos_d_close

.code
_sfos_d_close:
    ldy #esfos::sfos_d_close
    jsr sfos_entry
    bcs :+
    lda #0
    ldx #0
    rts
:
    lda #1
    tax
    rts

