; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.export _sfos_d_setdma

.code
_sfos_d_setdma:
    ldy #esfos::sfos_d_setdma
    jmp SFOS

