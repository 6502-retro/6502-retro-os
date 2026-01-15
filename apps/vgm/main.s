; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "io.inc"

.globalzp ptr1

.zeropage
vgmptr:            .byte 0
vgmptrh:           .byte 0
vgmwaitl:          .byte 0
vgmwaith:          .byte 0

rambank:           .byte 0
gd3bank:           .byte 0
gd3offset_in_bank: .word 0

page:              .byte 0
record:            .byte 0
bigint:            .dword 0   ; variable to hold 32 bit integers.

.code

main:
    sei
    jsr bios_sn_start

    lda #<str_message
    ldx #>str_message
    jsr c_printstr

    lda #<str_loading
    ldx #>str_loading
    jsr c_printstr

    jsr vgm_load
    jsr vgm_display_tags
    jsr vgm_setup
    jsr vgm_play
    jmp exit

print_32bit:
    ldy #3
:   lda bigint,y
    jsr bios_prbyte
    dey
    bpl :-
    rts

print_ptr1_hex:
    ldy #1
:   lda ptr1,y
    jsr bios_prbyte
    dey
    bpl :-
    rts

vgm_display_tags:

    ; set up ptr1 to point to GD3 offset in header
    lda #$14
    sta ptr1+0
    lda #$c0
    sta ptr1+1

    ; collect 32 bit bigint
    ldy #3
    clc
:   lda (ptr1),y
    sta bigint,y
    dey
    bpl :-

    clc
    lda #$14
    adc bigint+0
    sta bigint+0
    lda bigint+1
    adc #0
    sta bigint+1
    lda bigint+2
    adc #0
    sta bigint+2
    lda bigint+3
    adc #0
    sta bigint+3

    lda #<str_offset
    ldx #>str_offset
    jsr c_printstr
    jsr print_32bit
    jsr c_printstr

    ; bigint now contains the offset into the whole file where the GD3 data
    ; starts Find which bank thats in. shift bigint right by 13 bits. BUT I
    ; never have to worry about the most significant byte because largest file
    ; we can load is 128kb (0x2_00_00)

    lda bigint+1
    and #$1F
    sta gd3offset_in_bank+1
    lda bigint+0
    sta gd3offset_in_bank+0

    ldx #13
:   lsr bigint+3
    ror bigint+2
    ror bigint+1
    ror bigint+0
    dex
    bne :-

    lda bigint+0
    inc

    pha
    lda #<str_banknum
    ldx #>str_banknum
    jsr c_printstr
    pla
    pha
    jsr bios_prbyte
    jsr c_printstr
    pla

    sta rambankreg
    sta rambank
    nop
    nop

    lda gd3offset_in_bank + 0
    sta ptr1+0
    clc
    lda gd3offset_in_bank + 1
    adc #$C0
    sta ptr1+1

    lda #<str_offset_in_bank
    ldx #>str_offset_in_bank
    jsr c_printstr
    jsr print_ptr1_hex
    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr
    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr


    ; ptr1 is now pointing at the GD3 data.
    ; "Gd3 "
    ; 0x00,0x01,0x00,0x00  - Version number
    ; 32-bit length of gd3 data in bytes
    ;   ascii + 0x00, ascii + 0x00, ..., 0x00 + 0x00 (null terminator)

    ; skip Gd3 header and the version number (ptr1 + 8)
    clc
    lda ptr1+0
    adc #8
    sta ptr1+0
    lda ptr1+1
    adc #0
    sta ptr1+1

    ; read in size of header data.  Re-use bigint.
    ldy #3
:   lda (ptr1),y
    sta bigint,y
    dey
    bpl :-

    ; to be fair, I think the gd3 data probably is never going to be more than
    ; 65535 chars long. 16 bits aught to be enough.
@tagloop:
    lda (ptr1)
    bne :+

    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr
    bra :++ ; don't write the 00
:
    jsr c_write ; emit the characater
:
    ; add 2 to ptr1 (skip 0 that follows every ascii)
    clc
    lda ptr1+0
    adc #2
    sta ptr1+0
    lda ptr1+1
    adc #0
    sta ptr1+1
    cmp #$E0
    bne :+

    inc rambank
    lda rambank
    sta rambankreg
    nop
    nop
    lda #$C0
    sta ptr1+1
:
    ; now decrement size of data by 2
    sec
    lda bigint+0
    sbc #2
    sta bigint+0
    lda bigint+1
    sbc #0
    sta bigint+1

    ; have we reached zero?
    lda bigint+0
    ora bigint+1
    bne @tagloop  ; no ? loop

    lda #<str_newline
    ldx #>str_newline
    jsr c_write

    rts

vgm_setup:
    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr
    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr

    lda #1
    sta rambank
    sta rambankreg
    nop
    nop

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

    jsr bios_prbyte
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
    jsr bios_prbyte

    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr

    lda #$C0            ; reset the vgmptr to the start of the ram
    sta vgmptr + 1      ; bank
    ldy #0              ; reset y to 0.
:   rts

command:
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    jsr bios_sn_send
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

    lda #<FCB2
    sta ptr1+0
    lda #>FCB2
    sta ptr1+1
    ldy #sfcb::SC
    lda (ptr1),y
    inc
    sta record
    lda #<str_newline
    ldx #>str_newline
    jsr c_printstr


@loop:
    lda #'R'
    jsr c_write

    dec record
    lda record
    beq :++

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
:
    lda #<str_loaded
    ldx #>str_loaded
    jsr c_printstr

    lda FCB2 + sfcb::SC
    jsr bios_prbyte

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

    jsr bios_sn_stop
    cli
    jmp bios_wboot


.include "../app.inc"

.bss

.rodata
str_message: .byte 10,13,"6502-Retro! VGM Player",0
str_loading: .byte 10,13,"Loading file...",0
str_loaded:  .byte 10,13,"Loaded 0x",0
str_sectors: .byte " sectors",10,13,10,13,0
str_newline: .byte 10,13,0
str_offset:  .byte 10,13,"GD3 offset: 0x",0
str_banknum: .byte 10,13,"GD3 bank number: 0x",0
str_offset_in_bank: .byte 10,13,"GD3 offset in bank: 0x",0
