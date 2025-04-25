; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "bios.inc"

.export _sfos_s_settpa

.code
_sfos_s_settpa:
    ldy #esfos::sfos_s_settpa
    jmp sfos_entry

