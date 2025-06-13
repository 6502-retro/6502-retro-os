; vim: ft=asm_ca65 sw=4 ts=4 et

.globalzp ptr1, ptr2
.autoimport

KB_QUIT = $FF

.zeropage
ptr1:   .res 2
ptr2:   .res 2
.code

main:

    lda #<str_message
    ldx #>str_message
    jsr c_printstr

    ldy #2              ; graphics mode 2
    jsr vdp_init
    jmp game_loop

input:
    jsr bios_const
    cmp #$1b
    bne :+
    jmp exit_game
:   rts

game_loop:
    jsr input
    jmp game_loop

exit_game:
    jmp bios_wboot


.include "../app.inc"

.bss

.rodata
str_message: .byte 10,13,"Hello, from SNAKE",10,13,0
