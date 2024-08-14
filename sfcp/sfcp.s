; vim: ft=asm_ca65 ts=4 sw=4 et
.include "sfos.inc"
.export main
.autoimport

SFOS = $800

.zeropage

.code
; main user interface - First show a prompt.
main:
    jsr s_reset
    lda #<str_banner
    ldx #>str_banner
    jsr c_printstr
    jsr newline
    jsr show_prompt

    lda #128
    sta commandline
    lda #<commandline
    ldx #>commandline
    jsr c_readstr

    lda #<commandline
    ldx #>commandline
    jsr d_setdma

    lda #<fcb
    ldx #>fcb
    jsr d_convertfcb

; TODO: Remove this when done with debugging.
    jsr c_read
    jmp $CF4D

; ---- Helper functions ------------------------------------------------------
s_reset:
    ldy #esfos::sfos_s_reset
    jmp SFOS
d_getsetdrive:
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS
c_write:
    ldy #esfos::sfos_c_write
    jmp SFOS
c_read:
    ldy #esfos::sfos_c_read
    jmp SFOS
c_printstr:
    ldy #esfos::sfos_c_printstr
    jmp SFOS
c_readstr:
    ldy #esfos::sfos_c_readstr
    jmp SFOS
d_setdma:
    ldy #esfos::sfos_d_setmda
    jmp SFOS
d_convertfcb:
    ldy #esfos::sfos_d_convertfcb
    jmp SFOS

show_prompt:
    lda #$ff
    jsr d_getsetdrive
    clc
    adc #'A'
    jsr c_write
    lda #'>'
    jmp c_write

newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

str_newline:    .byte $13, $10, $0
str_banner:     .byte "6502-Retro! (SFOS)", $0

.bss
fcb:            .res 32
commandline:    .res 128

.rodata

