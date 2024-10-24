; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "asminc.inc"
.include "io.inc"

.export _led_on, _led_off

.code
_led_on:
        lda via_ddra
        ora #%00010000
        sta via_porta
        jmp LED_ON

_led_off:
        lda via_ddra
        ora #%00010000
        sta via_ddra
        jmp LED_OFF
