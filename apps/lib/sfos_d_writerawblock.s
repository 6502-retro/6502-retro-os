; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "bios.inc"

.export _sfos_d_writerawblock

.code
_sfos_d_writerawblock:
    ldy #esfos::sfos_d_writerawblock
    jmp sfos_entry

