; vim: ft=asm_ca65 ts=4 sw=4 et
.include "sfos.inc"
.include "fcb.inc"
.export main
.autoimport

SFOS = $800

.zeropage
debug_ptr: .word 0

.code
; main user interface - First show a prompt.
main:
    jsr s_reset
    lda #<str_banner
    ldx #>str_banner
    jsr c_printstr
prompt:
    jsr newline
    jsr show_prompt

    lda #128
    sta commandline
    lda #<commandline
    ldx #>commandline
    jsr c_readstr

    jsr clear_fcb
    lda #<fcb
    ldx #>fcb
    jsr d_setdma

    ldx #>commandline       ; set XA to the second byte of the commandline
    lda #<commandline       ; the first contains the length from readstr
    inc                     ; if the incrementing the low byte of the address
    bne :+                  ; results in zero then increment the high byte
    inx
:   jsr d_parsefcb          ; XA -> param is the start of the filename.
    ; XA -> Points to new command offset
    bcs prompt

    ; check if we are dealing with a change drive command
    ; byte N1 of the fcb will be a space
    ldx #sfcb::N1
    lda fcb,x
    cmp #' '
    beq @changedrive
    cmp #'Q'
    bne prompt
    jmp $CF4D
@changedrive:
    lda fcb
    ldx #0
    jsr d_getsetdrive
    jmp prompt
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
d_parsefcb:
    ldy #esfos::sfos_d_parsefcb
    jmp SFOS

clear_fcb:
    ldx #32
    lda #0
:   sta fcb-1,x
    dex
    bne :-
    rts

show_prompt:
    lda #$ff
    jsr d_getsetdrive
    clc
    adc #'A' - 1
    jsr c_write
    lda #'>'
    jmp c_write

newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

; debug helper
debug:
    pla
    sta debug_ptr
    pla
    sta debug_ptr+1
    bra @primm3
@primm2:
    jsr acia_putc
@primm3:
    inc debug_ptr
    bne @primm4
    inc debug_ptr+1
@primm4:
    lda (debug_ptr)
    bne @primm2
    lda debug_ptr+1
    pha
    lda debug_ptr
    pha
    rts
str_newline:    .byte 13, 10, 0
str_banner:     .byte "6502-Retro! (SFOS)", $0

.bss
fcb:            .res 32
commandline:    .res 128

.rodata

