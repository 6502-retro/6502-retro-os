; vim: ft=asm_ca65 et ts=4 sw=4:

.include "sfos.inc"
.include "bios.inc"

.export _sfos_s_gettpa

.code
_sfos_s_gettpa:
    ldy #esfos::sfos_s_gettpa
    jsr sfos_entry
    tax
    lda #0
    rts

