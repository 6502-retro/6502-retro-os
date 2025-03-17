; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "asminc.inc"
.include "io.inc"

.export _led_on, _led_off

.code
_led_on:
    jmp LED_ON

_led_off:
    jmp LED_OFF
