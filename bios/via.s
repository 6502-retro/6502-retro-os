; vim: ft=asm_ca65
.include "io.inc"

.autoimport

.export via_init, led_on, led_off, get_button

LED_ON          = %00010000 ; ORA
LED_OFF         = %11101111 ; AND
BUTTON          = %00100000 ; MASK
ROM_SWITCH_ON   = %01000000 ; ORA
ROM_SWITCH_OFF  = %10111111 ; AND

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

