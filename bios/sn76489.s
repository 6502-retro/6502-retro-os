; vim: ft=asm_ca65 ts=4 sw=4 :
; Library functions for basic control of the SN76489 attached to the VIA

.include "io.inc"
.export sn_start, sn_stop, sn_silence, sn_beep, sn_play_note, sn_send

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

.zeropage

.code

sn_start:
    ;lda #(SD_SCK | SD_CS | SD_MOSI | SN_WE)
    ;sta via_ddra
    lda #$ff
    sta via_ddrb

    ; enable T1 Interupts
    lda #%10100000
    sta via_ier
    lda #%00000000
    sta via_acr
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
    sta via_portb
    ldx #(SD_SCK|SD_CS|SD_MOSI|SN_WE)
    stx via_porta
    ldx #(SD_SCK|SD_CS|SD_MOSI)
    stx via_porta
    jsr sn_wait
    ldx #(SD_SCK|SD_CS|SD_MOSI|SN_WE)
    stx via_porta
    rts

sn_wait:
    lda via_porta
    and #SN_READY
    bne sn_wait
    rts

