; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

REBOOT  = $200
SFOS    = REBOOT + 3
FCB2    = $320

.zeropage

.code

main:
    ; Print hello, world and exit
    lda #<str_message
    ldx #>str_message
    jsr c_printstr

; scan the current directory and accumulate the filesizes of all the non
; empty files found.  Print each file with the size as you go.

    jsr set_user_drive

    ; initialize used space long to 0
    ldx #3
:   stz used_space,x
    dex
    bpl :-

    jsr make_fcb

    lda #<fcb
    ldx #>fcb
    jsr d_findfirst
    bcc @loop
    jmp exit

@loop:
    ; add the filesize to the total
    jsr accumlate_drive_total

    ; print file size (in hex)
    jsr newline
    jsr tab

    lda #<str_hexprefix
    ldx #>str_hexprefix
    jsr c_printstr

    lda fcb + sfcb::S2
    jsr prbyte
    lda fcb + sfcb::S1
    jsr prbyte
    lda fcb + sfcb::S0
    jsr prbyte

    lda #' '
    jsr c_write

    lda #<str_hexprefix
    ldx #>str_hexprefix
    jsr c_printstr

    lda fcb + sfcb::SC
    jsr prbyte

    lda #' '
    jsr c_write

    ;print file name 
    ldx #sfcb::N1
:   lda fcb,x
    cmp #' '
    beq :+
    jsr c_write
    inx
    cpx #sfcb::T1
    bne :-
:   lda #'.'
    jsr c_write
    ldx #sfcb::T1
:   lda fcb,x
    cmp #' '
    beq :+
    jsr c_write
    inx
    cpx #sfcb::T3+1
    bne :-
    
    ; get next directory entry
:   jsr make_fcb

    lda #<fcb
    ldx #>fcb
    jsr d_findnext

    bcc @loop

    jsr newline
    jsr newline
    jsr tab
    lda #<str_hexprefix
    ldx #>str_hexprefix
    jsr c_printstr

    lda used_space + 3
    jsr prbyte
    lda used_space + 2
    jsr prbyte
    lda used_space + 1
    jsr prbyte
    lda used_space + 0
    jsr prbyte

    lda #<str_total_space
    ldx #>str_total_space
    jsr c_printstr

    jsr restore_active_drive

    jmp exit

; ---- HELPER FUNCTIONS ------------------------------------------------------
;
accumlate_drive_total:
    clc
    lda fcb + sfcb::S0
    adc used_space + 0
    sta used_space + 0
    lda fcb + sfcb::S1
    adc used_space + 1
    sta used_space + 1
    lda fcb + sfcb::S2
    adc used_space + 2
    sta used_space + 2
    lda used_space + 3
    adc #0
    sta used_space + 3
    rts

make_fcb:
    ; make directory search fcb
    ldy #sfcb::N1
    lda #'?'
:
    sta fcb,y
    iny
    cpy #sfcb::T3 + 1
    bne :-
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

newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

tab:
    lda #<str_tab
    ldx #>str_tab
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

set_primary_drive:
    lda fcb
    bne set_drive
    rts
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
    jmp REBOOT

; ---- SFOS CALLS ------------------------------------------------------------
c_write:
    ldy #esfos::sfos_c_write
    jmp SFOS
c_printstr:
    ldy #esfos::sfos_c_printstr
    jmp SFOS
d_getsetdrive:
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS
d_findfirst:
    ldy #esfos::sfos_d_findfirst
    jmp SFOS
d_findnext:
    ldy #esfos::sfos_d_findnext
    jmp SFOS

.bss
fcb:        .res 32,0
used_space: .dword 0
active_drive: .byte 0
saved_active_drive: .byte 0
.rodata

str_message:     .byte "Stat",10,13,0
str_newline:     .byte 10,13,0
str_tab:         .byte "        ",0
str_hexprefix:   .byte "0x",0
str_total_space: .byte " of 0x2000000 bytes",10,13,0
