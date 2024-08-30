; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.export _sfos_d_getsetdrive

.code
_sfos_d_getsetdrive:
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS

