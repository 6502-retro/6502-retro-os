; vim: ft=asm_ca65 sw=4 ts=4 et
.include "io.inc"

.code

main:

    lda #<str_message
    ldx #>str_message
    jsr c_printstr

loop:
    jsr c_status
    bne exit

    lda IOJOY
    eor #$FF
    cmp joystate
    beq loop

    sta joystate

    jsr bios_prbyte
    lda #'-'
    jsr c_write

    lda joystate
    and #JOY_MAP_FIRE
    beq :+
    lda #<str_fire
    ldx #>str_fire
    jsr c_printstr
    bra pressed
:   lda joystate
    and #JOY_MAP_UP
    beq :+
    lda #<str_up
    ldx #>str_up
    jsr c_printstr
    bra pressed
:   lda joystate
    and #JOY_MAP_DOWN
    beq :+
    lda #<str_down
    ldx #>str_down
    jsr c_printstr
    bra pressed
:   lda joystate
    and #JOY_MAP_LEFT
    beq :+
    lda #<str_left
    ldx #>str_left
    jsr c_printstr
    bra pressed
:   lda joystate
    and #JOY_MAP_RIGHT
    beq released
    lda #<str_right
    ldx #>str_right
    jsr c_printstr
    bra pressed

released:
    lda #<str_released
    ldx #>str_released
    jsr c_printstr
    jmp loop

pressed:
    lda #<str_pressed
    ldx #>str_pressed
    jsr c_printstr
    jmp loop

exit:
    jmp bios_wboot

crlf:
    lda #<str_crlf
    ldx #>str_crlf
    jsr c_printstr
    rts

.include "../app.inc"

joystate: .byte 0

.rodata
str_message: .byte 10,13,"Joystick Tester (v0.1)",10,13,0
str_up:   .byte  "UP    ",0
str_down: .byte  "DOWN  ",0
str_left: .byte  "LEFT  ",0
str_right: .byte "RIGHT ",0
str_fire: .byte  "FIRE  ",0
str_pressed: .byte "PRESSED",10,13,0
str_released: .byte "RELEASED",10,13,0

str_crlf: .byte 10, 13,0
