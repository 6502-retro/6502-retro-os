; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"
.include "io.inc"

.zeropage
vgmptr: .byte 0
vgmptrh: .byte 0
vgmwaitl: .byte 0
vgmwaith: .byte 0

rambank: .byte 0
page:   .byte 0

.code

main:
    jsr SN_START

    lda #<str_message
    ldx #>str_message
    jsr c_printstr

    lda #<str_loading
    ldx #>str_loading
    jsr c_printstr

    jsr vgm_load
    jsr vgm_setup
    jsr vgm_play
    jmp exit

vgm_setup:
    stz vgmptr+0
    lda #$C0
    sta vgmptr+1
    ldy #$34
    lda (vgmptr),y
    clc
    adc #$34
    tay
    rts

vgm_play:
    lda (vgmptr),y
    cmp #$50
    beq @command
    cmp #$66
    beq @end
    cmp #$61
    beq @wait
    cmp #$63
    beq @fiftieth
    cmp #$62
    beq @sixtieth
    and #$F0
    cmp #$70
    beq @n1

    jsr CONBYTE
    lda #'!'
    jsr c_write
    jmp exit

@command:
    jmp command
@wait:
    jmp wait
@n1:
    jmp n1
@sixtieth:
    jmp sixtieth
@fiftieth:
    jmp fiftieth
@end:
    jmp exit

vgm_next:
    iny                 ; increment the y index into the data pointed to by
    bne :+              ; vgmptr and ensure that ram bank boundaries are managed
    jsr incvgmptrh
:   jmp vgm_play

incvgmptrh:
    lda #'.'            ; print a '.' every 256 bytes
    phy
    jsr c_write
    ply

    inc vgmptr + 1
    lda vgmptr + 1
    cmp #$E0            ; have we crossed into ROM?
    bne :+              ; no - return

    inc rambank        ; move to next ram bank.
    lda rambank
    sta rambankreg
    nop                 ; the 74LS273 registers I am using appear to
    nop                 ; need these extra cycles.

    lda rambank        ; show the new rambank to the user.
    jsr CONBYTE

    lda #$C0            ; reset the vgmptr to the start of the ram
    sta vgmptr + 1      ; bank
    ldy #0              ; reset y to 0.
:   rts

command:
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    jsr SN_SEND
    jmp vgm_next

wait:                   ; get the next two bytes taking care to account
    iny                 ; for crossing to the next ram bank.  These form
    bne :+              ; the 16 bit wide number of samples to wait for.
    jsr incvgmptrh
:   lda (vgmptr),y
    sta vgmwaitl
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    sta vgmwaith        ; once the vgmwait word has the number of samples
    jsr vgmwait         ; to wait for, go ahead and perform the wait.
    jmp vgm_next

n1:                     ; this special case, meand wait for up to 15 sample
    lda (vgmptr),y      ; periods
    cmp #$70
    beq :+
    and #$0f
    sta vgmwaitl
    stz vgmwaith
    jsr vgmwait
:
    jmp vgm_next

fiftieth:
    lda #$72
    sta vgmwaitl
    lda #$03
    sta vgmwaith
    jsr vgmwait
    jmp vgm_next
sixtieth:               ; as given by the datasheet wait for exactly 1/60
    lda #$df            ; of a second.
    sta vgmwaitl
    lda #$02
    sta vgmwaith
    jsr vgmwait
    jmp vgm_next

; at 4mhz we want 91 clocks for a single sample.
; this works out to 90 clock cycles. which is ~22uS
vgmwait:                    ; (6) Cycles to prep and execute the jsr
    lda vgmwaitl            ; (3)
    bne @wait_samples_1     ; (2)   (could be 3 if branching across page)
    lda vgmwaith            ; (3)
    beq @return             ; (2)   (could be 3 if branching across page)
    dec vgmwaith            ; (5) zeropage decrement
@wait_samples_1:
    dec vgmwaitl            ; (5) zeropage decrement
    ; kill some cycles between loops.  Adjust as required.
    .repeat 30
        nop                 ; (2 * 30 = 60)
    .endrepeat
    jmp vgmwait             ; (3)   loop = 29 cycles
@return:
    rts                     ; (6)   6 cycles to return


vgm_load:
    ; the file to play is in FCB2
    ; so open it and load it into C000->DFFF incrementing bank as you go.
    ; Once loaded, reset the bank to bank 1
    ; and return
    lda #1
    sta rambankreg
    sta rambank
    lda #$BE        ; $C0 -1 because we pre-increment it
    sta page

    lda #<FCB2
    ldx #>FCB2
    jsr d_open


@loop:
    inc page
    inc page

    lda page
    cmp #$E0
    bne :+

    inc rambank
    lda rambank
    sta rambankreg
    lda #$C0
    sta page

:   lda #0
    ldx page
    jsr d_setdma

    lda #<FCB2
    ldx #>FCB2
    jsr d_readseqblock

    bcc @loop

    lda #<str_loaded
    ldx #>str_loaded
    jsr c_printstr

    lda FCB2 + sfcb::SC
    jsr CONBYTE

    lda #<str_sectors
    ldx #>str_sectors
    jsr c_printstr

    lda #1
    sta rambankreg
    sta rambank

    rts

exit:
    lda #0
    sta rambankreg
    sta rambank

    jsr SN_STOP
    jmp WBOOT

.include "../app.inc"

.bss

.rodata
str_message: .byte 10,13,"6502-Retro! VGM Player",0
str_loading: .byte 10,13,"Loading file...",0
str_loaded:  .byte 10,13,"Loaded 0x",0
str_sectors: .byte " sectors",10,13,0
str_newline: .byte 10,13,0
