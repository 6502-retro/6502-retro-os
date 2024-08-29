; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.export _sfos_c_read

.code
_sfos_c_read:
    ldy #esfos::sfos_c_read
    jsr SFOS
    ldx #0
    rts
