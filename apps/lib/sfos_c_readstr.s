; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "sfos.inc"
.include "asminc.inc"

.autoimport
.globalzp ptr1
.export _sfos_c_readstr

.code

_sfos_c_readstr:
    sta ptr1+0
    stx ptr1+1
    jsr popa
    sta (ptr1)
    lda ptr1+0
    ldx ptr1+1
    ldy #esfos::sfos_c_readstr
    jmp SFOS
