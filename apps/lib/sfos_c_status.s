; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "bios.inc"

.export _sfos_c_status

.code
_sfos_c_status:
    ldy #esfos::sfos_c_status
    jsr sfos_entry
    ldx #0
    rts
