; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

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
:   jsr d_parsefcb
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

    jsr debug_fcb_records

    lda FCB2+sfcb::SC
    sta temp
    jsr prbyte
    jsr newline

loop:
    ; read a block of the source
    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    jsr d_setdma
    lda #<FCB2
    ldx #>FCB2
    jsr d_readseqblock

    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    jsr d_setdma
    lda #<FCB
    ldx #>FCB
    jsr d_writeseqblock
    lda #'.'
    jsr c_write

    dec temp
    lda temp
    bne loop

    lda #<FCB
    ldx #>FCB
    jsr d_close


    jsr debug_fcb_records
    ;
    ; write a block of the destination
    ;
    jsr restore_active_drive
    jmp exit

; ---- HELPER FUNCTIONS ------------------------------------------------------
debug_fcb_records:
    lda FCB+sfcb::DD
    jsr prbyte
    lda #'-'
    jsr c_write
    lda FCB+sfcb::FN
    jsr prbyte
    lda #'-'
    jsr c_write
    lda FCB+sfcb::SC
    jsr prbyte
    lda #'-'
    jsr c_write
    lda FCB+sfcb::S2
    jsr prbyte
    lda FCB+sfcb::S1
    jsr prbyte
    lda FCB+sfcb::S0
    jsr prbyte

    jsr newline

    lda FCB2+sfcb::DD
    jsr prbyte
    lda #'-'
    jsr c_write
    lda FCB2+sfcb::FN
    jsr prbyte
    lda #'-'
    jsr c_write
    lda FCB2+sfcb::SC
    jsr prbyte
    lda #'-'
    jsr c_write
    lda FCB2+sfcb::S2
    jsr prbyte
    lda FCB2+sfcb::S1
    jsr prbyte
    lda FCB2+sfcb::S0
    jsr prbyte
    
    jsr newline
    rts


prbyte:
    pha             ;save a for lsd.
    lsr
    lsr
    lsr             ;msd to lsd position.
    lsr
    jsr @prhex      ;output hex digit.
    pla             ;restore a.
@prhex:
    and #$0f        ;mask lsd for hex print.
    ora #$b0        ;add "0".
    cmp #$ba        ;digit?
    bcc @echo       ;yes, output it.
    adc #$06        ;add offset for letter.
@echo:
    pha             ;*save a
    and #$7f        ;*change to "standard ascii"
    jsr c_write
    pla             ;*restore a
    rts             ;*done, over and out...
;
print_fcb:
    lda FCB + sfcb::DD
    jsr prbyte
    lda #':'
    jsr c_write
    ldx #sfcb::N1
:   lda FCB,x
    cmp #' '
    beq :+
    jsr c_write
    inx
    cpx #(sfcb::N8+1)
    bne :-
:   lda #'.'
    jsr c_write
    ldx #sfcb::T1
:   lda FCB,x
    jsr c_write
    inx
    cpx #(sfcb::T3+1)
    bne :-
    rts

newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

;
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
    jmp WBOOT

.include "../app.inc"

.bss
_fcb:               .res 32,0
active_drive:       .byte 0
saved_active_drive: .byte 0
temp:               .byte 0

.rodata
str_message:     .byte 10,13,"Copy file...",10,13,0
str_newline:     .byte 10,13,0

