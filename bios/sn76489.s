; vim: ft=asm_ca65 ts=4 sw=4 :
; Library functions for basic control of the SN76489 attached to the VIA

.include "io.inc"
.export sn_start, sn_stop, sn_silence, sn_beep, sn_play_note, sn_send
.export sn_irq_handler
.import _notectr
FIRST   = %10000000
SECOND  = %00000000
CHAN_1  = %00000000
CHAN_2  = %00100000
CHAN_3  = %01000000
CHAN_N  = %01100000
TONE    = %00000000
VOL     = %00010000
VOL_OFF = %00001111
VOL_MAX = %00000000

.bss
reverse_tmp:  .res 1

.code

sn_start:
    lda #$ff
    sta via_ddrb
    jsr sn_silence
    rts

sn_stop:
    jsr sn_silence
    rts

sn_silence:
    lda #(FIRST|CHAN_1|VOL|VOL_OFF)
    jsr sn_send
    lda #(FIRST|CHAN_2|VOL|VOL_OFF)
    jsr sn_send
    lda #(FIRST|CHAN_3|VOL|VOL_OFF)
    jsr sn_send
    lda #(FIRST|CHAN_N|VOL|VOL_OFF)
    jsr sn_send
    rts

sn_beep:
    lda #$07
    ldy #$04
    jsr sn_play_note 
    ldy #$40
@d1:
    ldx #$00
@d2:
    dex
    bne @d2
    dey
    bne @d1

    jsr sn_silence
    rts

sn_play_note:
    ora #(FIRST|CHAN_1|TONE)
    jsr sn_send
    tya
    ora #(SECOND|CHAN_1|TONE)
    jsr sn_send
    lda #(FIRST|CHAN_1|VOL|$04)
    jsr sn_send
    rts

; Byte to send in A
sn_send:
    tax
    lda reverse_tbl,x
    sta via_portb
    ldx #(SD_SCK|SD_CS|SPI_CS2|SPI_CS3|SD_MOSI|SN_WE)
    stx via_porta
    ldx #(SD_SCK|SD_CS|SPI_CS2|SPI_CS3|SD_MOSI)
    stx via_porta
    jsr sn_wait
    ldx #(SD_SCK|SD_CS|SD_MOSI|SPI_CS2|SPI_CS3|SN_WE)
    stx via_porta
    rts

sn_wait:
    lda via_porta
    and #SN_READY
    bne sn_wait
    rts

sn_irq_handler:
    dec _notectr
    bne @exit
    lda #(FIRST|CHAN_1|VOL|15)
    jsr sn_send
@exit:
    rts


.rodata
reverse_tbl:
    .byte $00, $80, $40, $c0, $20, $a0, $60, $e0
    .byte $10, $90, $50, $d0, $30, $b0, $70, $f0
    .byte $08, $88, $48, $c8, $28, $a8, $68, $e8
    .byte $18, $98, $58, $d8, $38, $b8, $78, $f8
    .byte $04, $84, $44, $c4, $24, $a4, $64, $e4
    .byte $14, $94, $54, $d4, $34, $b4, $74, $f4
    .byte $0c, $8c, $4c, $cc, $2c, $ac, $6c, $ec
    .byte $1c, $9c, $5c, $dc, $3c, $bc, $7c, $fc
    .byte $02, $82, $42, $c2, $22, $a2, $62, $e2
    .byte $12, $92, $52, $d2, $32, $b2, $72, $f2
    .byte $0a, $8a, $4a, $ca, $2a, $aa, $6a, $ea
    .byte $1a, $9a, $5a, $da, $3a, $ba, $7a, $fa
    .byte $06, $86, $46, $c6, $26, $a6, $66, $e6
    .byte $16, $96, $56, $d6, $36, $b6, $76, $f6
    .byte $0e, $8e, $4e, $ce, $2e, $ae, $6e, $ee
    .byte $1e, $9e, $5e, $de, $3e, $be, $7e, $fe
    .byte $01, $81, $41, $c1, $21, $a1, $61, $e1
    .byte $11, $91, $51, $d1, $31, $b1, $71, $f1
    .byte $09, $89, $49, $c9, $29, $a9, $69, $e9
    .byte $19, $99, $59, $d9, $39, $b9, $79, $f9
    .byte $05, $85, $45, $c5, $25, $a5, $65, $e5
    .byte $15, $95, $55, $d5, $35, $b5, $75, $f5
    .byte $0d, $8d, $4d, $cd, $2d, $ad, $6d, $ed
    .byte $1d, $9d, $5d, $dd, $3d, $bd, $7d, $fd
    .byte $03, $83, $43, $c3, $23, $a3, $63, $e3
    .byte $13, $93, $53, $d3, $33, $b3, $73, $f3
    .byte $0b, $8b, $4b, $cb, $2b, $ab, $6b, $eb
    .byte $1b, $9b, $5b, $db, $3b, $bb, $7b, $fb
    .byte $07, $87, $47, $c7, $27, $a7, $67, $e7
    .byte $17, $97, $57, $d7, $37, $b7, $77, $f7
    .byte $0f, $8f, $4f, $cf, $2f, $af, $6f, $ef
    .byte $1f, $9f, $5f, $df, $3f, $bf, $7f, $ff
