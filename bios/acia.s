; vim: ft=asm_ca65
.include "io.inc"
.include "bios.inc"
.autoimport
.globalzp ptr1
.export acia_init, acia_getc, acia_getc_nw, acia_putc

; vim: set ft=asm_ca65 sw=4 ts=4 et:
ACIA_PARITY_DISABLE          = %00000000
ACIA_ECHO_DISABLE            = %00000000
ACIA_TX_INT_DISABLE_RTS_LOW  = %00001000
ACIA_RX_INT_ENABLE           = %00000000
ACIA_RX_INT_DISABLE          = %00000010
ACIA_DTR_LOW                 = %00000001


.zeropage

.code
acia_init:
    lda #$00
    sta acia_status
    lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_DISABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
    sta acia_command
    lda #$10
    sta acia_control
    rts

; changed this to use bios_const so that the emulator
; doesn't hang while waiting for user input.
acia_getc:
    jsr bios_const
    beq acia_getc
    rts

acia_getc_nw:
    lda acia_status
    and #$08
    beq @done
    lda acia_data
    cmp #$7F
    bne :+
    lda #$08
:   sec
    rts
@done:
    clc
    rts

acia_putc:
    pha                         ; save char
@wait_txd_empty:
    lda acia_status
    and #$10
    beq @wait_txd_empty
    pla                     ; restore char
    sta acia_data
    rts

.bss

.rodata
