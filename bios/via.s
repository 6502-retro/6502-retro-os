; vim: ft=asm_ca65
.include "io.inc"

.autoimport

.export via_init, led_on, led_off
.code

via_init:
    lda #%10101111          ; LED OFF
    sta via_porta
    lda #%10111111          ; PA6 is input
    sta via_ddra
    rts

led_on:
    lda via_porta
    ora #LED_ON
    sta via_porta
    rts

led_off:
    lda via_porta
    and #LED_OFF
    sta via_porta
    rts

