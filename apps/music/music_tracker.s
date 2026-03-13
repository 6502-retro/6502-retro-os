; vim: set ft=asm_ca65 ts=4 sw=4 et cc=80:
; 6502-Retro-Tetris Game
;
; Copyright (c) 2026 David Latham
;
; This code is licensed under the MIT license
;
; https://github.com/6502-retro/6502-retro-tetris
.include "bios.inc"

.autoimport

.export init_music_tracker, handle_note

.zeropage
    track_ptr: .res 2

.bss
    item_ctr: .word  0
    beat_ctr: .word  0
    music_tmp: .byte 0
    music_src: .word 0

.code

init_music_tracker:
    sta music_src+0
    stx music_src+1

init_music_loop:
    lda music_src+0
    sta track_ptr+0
    ldx music_src+1
    stx track_ptr+1
    stz item_ctr+0
    stz item_ctr+1
    stz beat_ctr+0
    stz beat_ctr+1
    rts

handle_note:
    ldy #0
nt_beat_loop:
    lda (track_ptr),y     ; if song beat is equal to beat counter then proceed
    cmp beat_ctr+0        ; else end loop
    beq :+
    jmp nt_beat_loop_end
:   iny
    lda (track_ptr),y
    cmp beat_ctr+1
    beq :+
    jmp nt_beat_loop_end
:   iny
    lda (track_ptr),y     ; load instruction (NT_NOTE_OFF, NT_NOTE_ON, NT_LOOP)
    cmp #NT_NOTE_ON
    bne :+
    jmp nt_note_on
:   cmp #NT_SET_ATTN
    bne :+
    jmp nt_set_vol
:   cmp #NT_NOTE_OFF
    bne :+
    jmp nt_note_off
:   cmp #NT_LOOP
    bne :+
    jmp nt_loop

    ; THIS IS AN ERROR CONDITION HERE.
:   lda #'E'
    jsr bios_conout
    jmp bios_wboot

nt_beat_loop_end:
    inc beat_ctr+0        ; increment beat counter
    bne :+
    inc beat_ctr+1
:   rts                   ; return from subroutine

nt_note_off:
    iny
    lda (track_ptr),y     ; channel
    jsr volume_off
    clc
    lda track_ptr+0
    adc #4
    sta track_ptr+0
    lda track_ptr+1
    adc #0
    sta track_ptr+1
    jmp handle_note

nt_note_on:
    iny
    lda (track_ptr),y     ; channel
    tax
    iny
    lda (track_ptr),y     ; note
    phy
    ; play note
    tay
    lda NOTES_COURSE,y    ; high 6  bits
    sta music_tmp
    lda NOTES_FINE,y      ; low 4 bits
    ldy music_tmp
    phx                   ; save channel
    jsr play_note
    plx                   ; restore channel
    ply
    iny
    lda (track_ptr),y     ; volume
    jsr set_volume
    clc
    lda track_ptr+0
    adc #6
    sta track_ptr+0
    lda track_ptr+1
    adc #0
    sta track_ptr+1

    jmp handle_note

nt_set_vol:
    iny
    lda (track_ptr),y     ; channel
    tax
    iny
    lda (track_ptr),y     ; volume
    phy
    jsr set_volume
    ply
    clc
    lda track_ptr+0
    adc #5
    sta track_ptr+0
    lda track_ptr+1
    adc #0
    sta track_ptr+1
    jmp handle_note

nt_loop:
    jsr init_music_loop
    rts                   ; return from handle_note

; A contains the channel index
volume_off:
    and #$03
    asl                   ; move channel index into bits 5 & 6
    asl
    asl
    asl
    asl
    ora #%10011111        ; Set Bit 7 (First Byte flag) and attenuation to  0xF
    jmp sn_send

; X is channel index, A is volume
set_volume:
    pha
    txa
    asl
    asl
    asl
    asl
    asl
    ora #%10010000        ; Set Bit 7 (First Byte flag) and attenuation to  0xF
    sta music_tmp
    pla
    ora music_tmp
    jmp sn_send

; A contains the Low 4 bits, Y contains the High 6 bits, and X contains the Channel Index (0, 1, or 2).
play_note:
    ; --- Handle First Byte (1 c c r d d d d) ---
    pha                   ; Save Low 4 bits (PARAM2)
    txa                   ; Get Channel (0, 1, or 2)
    asl                   ; Shift channel left to bits 5 & 6
    asl
    asl
    asl
    asl
    ora #%10000000        ; Set Bit 7 (First Byte flag)
    sta music_tmp         ; Store channel/command bits temporarily
    pla                   ; Pull Low 4 bits
    and #$0F              ; Safety mask
    ora music_tmp         ; Combine: 1cc0dddd
    jsr sn_send           ; Send First Byte

    ; --- Handle Second Byte (0 - d d d d d d) ---
    tya                   ; Get High 6 bits (PARAM3)
    and #$3F              ; Ensure Bit 7 is 0 (Second Byte flag)
    jsr sn_send           ; Send Second Byte
    rts

.include "music.s"
