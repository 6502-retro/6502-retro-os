; vim: ft=asm_ca65
; contains additional commands for EH Basic
basptr = $FA

.code
; BYE - Quits EHBASIC
; CLS - CLEAR Screen by issuing Ansi escape sequence "ESC [J2"
; LOAD "FILENAME.BAS" - Loads a FILENAME
; SAVE "FILENAME.BAS" - Saves current program into FILENAME.
retro_cls:
        PHA
        PHY
        lda     #<strAnsiCLSHome
        ldy     #>strAnsiCLSHome
        jsr     LAB_18C3                ; print null terminated string
        PLY
        PLA
        rts

retro_bye:
        lda     #<strByeMessage
        ldy     #>strByeMessage
        jsr     LAB_18C3                ; print null terminated string
        jmp     WBOOT

retro_beep:
        jmp     CONBEEP

save:

        stz FSIZE + 0
        stz FSIZE + 1
        stz FSIZE + 2
        stz FSIZE + 3

        lda #'C'
        jsr CONOUT

        jsr create_fcb
        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_findfirst
        jsr SFOS

        bcc @open
        ; make
        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_make
        jsr SFOS

        lda #'M'
        jsr CONOUT
        jmp @save
@open:
        jsr open_file
        stz FCB + sfcb::SC

        lda #'O'
        jsr CONOUT

@save:
        lda #<SFOS_BUF
        ldx #>SFOS_BUF
        ldy #esfos::sfos_d_setdma
        jsr SFOS

        jsr clear_buf
        stz DIRTY_SECTOR

        ; redirect stdout to file
        lda #<fwrite
        sta VEC_OUT + 0
        lda #>fwrite
        sta VEC_OUT + 1

        sec
        jsr LAB_14BD            ; LIST

        lda #<ACIAout
        sta VEC_OUT + 0
        lda #>ACIAout
        sta VEC_OUT + 1

        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_close
        jsr SFOS

        jsr restore_active_drive
        rts

fwrite:
        pha
        phx
        phy
        sta (basptr)
        inc DIRTY_SECTOR
        inc basptr+0
        bne :+
        inc basptr+1
        lda basptr+1
        cmp #>SFOS_BUF_END
        bne :+

        lda #<SFOS_BUF
        ldx #>SFOS_BUF
        ldy #esfos::sfos_d_setdma
        jsr SFOS

        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_writeseqblock
        jsr SFOS

        inc FCB + sfcb::SC
        stz DIRTY_SECTOR

        jsr clear_buf

:       clc
        lda FSIZE + 0
        adc #1
        sta FSIZE + 0
        lda FSIZE + 1
        adc #0
        sta FSIZE + 1
        lda FSIZE + 2
        adc #0
        sta FSIZE + 2

        ply
        plx
        pla
        clc
        rts

clear_buf:
        lda #0
        ldy #0
:       sta SFOS_BUF+0,y
        iny
        bne :-
:       sta SFOS_BUF+256,y
        iny
        bne :-
        lda #<SFOS_BUF
        sta basptr+0
        lda #>SFOS_BUF
        sta basptr+1
        rts


load:
        ; open file
        ; read file into memory one character at a time
        ; when read fails, then done.
        jsr open_file

        lda #<SFOS_BUF
        ldx #>SFOS_BUF
        ldy #esfos::sfos_d_setdma
        jsr SFOS
        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_readseqblock
        jsr SFOS

        ; redirect STDIN
         ; save stack as NEW destroys it
        tsx
        inx
        lda $100,x
        sta basptr
        inx
        lda $100,x
        sta basptr + 1

        jsr LAB_1463                    ; NEW

        ; restore stack
        lda basptr+ 1
        pha
        lda basptr
        pha

        ; redirect input
        lda #<fread
        sta VEC_IN + 0
        lda #>fread
        sta VEC_IN + 1

        ; redirect output to null
        lda #<nullout
        sta VEC_OUT + 0
        lda #>nullout
        sta VEC_OUT + 1

        jsr LAB_1319
        rts

fread:
        phx
        phy
        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_readseqbyte
        jsr SFOS
        ply
        plx
        bcs fread_error
        cmp #$0a
        bne nullout
        lda #$0d
nullout:
        sec
        rts

fread_error:
        lda ERROR_CODE
        cmp #ERROR::FILE_EOF
        bne :+
        jsr reset_redirects
        jmp file_exit
:       ldx #$2A
        jmp LAB_XERR

create_fcb:
        ; clear out FCB
        ldx #0
        lda #0
:       sta FCB,x
        inx
        cpx #32
        bne :-

        ; parse FCB
        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_setdma
        jsr SFOS
        jsr set_user_drive

        jsr LAB_EVEX
        lda Dtypef
        bne :+
        ldx #$02
        jmp LAB_XERR            ; syntax error
:
        jsr LAB_22B6
        ; filename is pointed to by X/Y
        stx basptr + 0
        sty basptr + 1
        tay                     ; length in A
        lda #0
        sta (basptr),Y          ; zeroterminate the filename string

        lda basptr + 0
        ldx basptr + 1
        ldy #esfos::sfos_d_parsefcb
        jmp SFOS

open_file:
        jsr create_fcb
        lda #<FCB
        ldx #>FCB
        ldy #esfos::sfos_d_open
        jsr SFOS
        rts

reset_redirects:

        lda #<ACIAout
        sta VEC_OUT + 0
        lda #>ACIAout
        sta VEC_OUT + 1

        lda #<ACIAin
        sta VEC_IN + 0
        lda #>ACIAin
        sta VEC_IN + 1
        rts

file_exit:
        jsr restore_active_drive

        lda #<strReady
        ldy #>strReady
        jsr LAB_18C3

        jsr LAB_1477
        jmp LAB_1319
        rts

restore_active_drive:
    lda FCB
    bne :+
    rts
:   lda saved_active_drive
    sta active_drive
    ldx #0
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS

set_user_drive:
    lda #$FF
    ldx #$00
    ldy #esfos::sfos_d_getsetdrive
    jsr SFOS
    sta active_drive

    lda FCB
    bne set_drive
    rts

set_drive:
    pha
    lda active_drive
    sta saved_active_drive
    pla
    sta active_drive
    ldx #0
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS


exit:
    jsr restore_active_drive
    jmp WBOOT


retro_dir:
    rts

.bss
active_drive:       .byte 0
saved_active_drive: .byte 0
temp:               .word 0

.rodata
strAnsiCLSHome: .byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
strByeMessage:  .byte $0D,$0A,"Exiting ehBasic now...", $0
strReady:       .byte $0D,$0A,"Ready",$0A,$0D,$0
