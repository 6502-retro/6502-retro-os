; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "bios.inc"

.export _sfos_c_printstr

.code
_sfos_c_printstr:
    ldy #esfos::sfos_c_printstr
    jmp sfos_entry

