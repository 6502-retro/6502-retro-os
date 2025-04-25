; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "bios.inc"
.autoimport 
.export _sfos_d_writeseqbyte

.code
_sfos_d_writeseqbyte:
    sta bios_rega
    jsr popax
    ldy #esfos::sfos_d_writeseqbyte
    jmp sfos_entry

