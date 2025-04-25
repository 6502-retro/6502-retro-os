; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"

.zeropage

.code

main:
    lda #<str_message
    ldx #>str_message
    jsr c_printstr

    jsr set_user_drive

    ; gather arguments
    ; FCB2 contains source
    ; CMDOFFSET points to file name of destination.  Parse it.

    ; clear out FCB
    ldx #0
    lda #0
:   sta FCB,x
    inx
    cpx #32
    bne :-

    ; parse fcb
    lda #<FCB
    ldx #>FCB
    jsr d_setdma

    lda CMDOFFSET+0
    ldx CMDOFFSET+1
    jsr d_parsefcb
    jsr newline

    ; FCB contains the destination copy:
    ; open the source
    lda #<FCB2
    ldx #>FCB2
    jsr d_open

    ; copy meta from FCB2 into FCB
    lda FCB2+sfcb::L1
    sta FCB+sfcb::L1
    lda FCB2+sfcb::L2
    sta FCB+sfcb::L2

    lda FCB2+sfcb::SC
    sta FCB+sfcb::SC

    lda FCB2+sfcb::E1
    sta FCB+sfcb::E1
    lda FCB2+sfcb::E2
    sta FCB+sfcb::E2

    lda FCB2+sfcb::S0
    sta FCB+sfcb::S0
    lda FCB2+sfcb::S1
    sta FCB+sfcb::S1
    lda FCB2+sfcb::S2
    sta FCB+sfcb::S2

    lda FCB+sfcb::DD
    jsr d_getsetdrive

    ; make the destination
    lda #<FCB
    ldx #>FCB
    jsr d_make

    lda FCB2+sfcb::SC
    sta temp

    ; if the source file is empty, we just close and complete the copy.
    lda FCB2 + sfcb::SC
    beq close

loop:
    ; read a block of the source
    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    jsr d_setdma
    lda #<FCB2
    ldx #>FCB2
    jsr d_readseqblock

    lda #'r'
    jsr c_write

    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    jsr d_setdma
    lda #<FCB
    ldx #>FCB
    jsr d_writeseqblock

    lda #'w'
    jsr c_write

    dec temp
    lda temp
    bne loop
close:
    lda #<FCB
    ldx #>FCB
    jsr d_close

    ; all done
    jmp exit

; ---- HELPER FUNCTIONS ------------------------------------------------------
newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

restore_active_drive:
    lda FCB2
    bne :+
    rts
:   lda saved_active_drive
    sta active_drive
    ldx #0
    jmp d_getsetdrive

set_user_drive:
    lda #$FF
    ldx #$00
    jsr d_getsetdrive
    sta active_drive

    lda FCB2
    bne set_drive
    rts
set_drive:
    pha
    lda active_drive
    sta saved_active_drive
    pla
    sta active_drive
    ldx #0
    jmp d_getsetdrive

exit:
    jsr restore_active_drive
    jmp bios_wboot

.include "../app.inc"

.bss
_fcb:               .res 32,0
active_drive:       .byte 0
saved_active_drive: .byte 0
temp:               .byte 0

.rodata
str_message:    .byte 10,13,"Copy file...",10,13,0
str_newline:    .byte 10,13,0
str_error:      .byte 10,13,"Error copying file...",10,13,0
