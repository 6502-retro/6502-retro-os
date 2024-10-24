; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "asminc.inc"
.include "io.inc"

.export _get_button

.code
_get_button:
        lda via_ddra
        and #%11010111
        sta via_ddra
        jsr GET_BUTTON
        ldx #0
        rts

