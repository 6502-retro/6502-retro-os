; vim: ft=asm_ca65
.include "io.inc"

.autoimport

.export via_init, led_on, led_off, get_button
.code

via_init:
    lda #%11000111          ; LED OFF, ROM SWITCH ON - other active lows are disabled
    sta via_porta
    lda #%11010111          ; PA5 and PA3 are inputs
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

; returns 1 when pressed.
get_button:
    lda via_porta
    and #BUTTON
    beq :+
    lda #0
    rts
:   lda #1
    rts

