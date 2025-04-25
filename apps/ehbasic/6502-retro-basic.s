.include "sfos.inc"
.include "bios.inc"
; vim: ft=asm_ca65 ts=4 sw=4 :
; contains additional commands for EH Basic
basptr = $FA

.code
; BYE - Quits EHBASIC
; CLS - CLEAR Screen by issuing Ansi escape sequence "ESC [J2"
; LOAD "FILENAME.BAS" - Loads a FILENAME
; SAVE "FILENAME.BAS" - Saves current program into FILENAME.
retro_cls:
    lda     #<strAnsiCLSHome
    ldy     #>strAnsiCLSHome
    jmp     LAB_18C3                ; print null terminated string

retro_bye:
    jmp     bios_wboot

retro_beep:
    jmp     bios_sn_beep

save:
    jsr create_fcb
    jsr set_drive

    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_findfirst
    jsr sfos_entry
    bcs @make
    ldx #$1E
    jmp LAB_XERR

@make:
    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_make
    jsr sfos_entry
    bcc @save
    ldx #$26
    jmp LAB_XERR

@save:
    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    ldy #esfos::sfos_d_setdma
    jsr sfos_entry

    jsr clear_buf

    ; redirect stdout to file
    lda #<fwrite
    sta VEC_OUT + 0
    lda #>fwrite
    sta VEC_OUT + 1

    sec
    jsr LAB_14BD            ; LIST

    lda #$1A
    jsr fwrite

    lda #<ACIAout
    sta VEC_OUT + 0
    lda #>ACIAout
    sta VEC_OUT + 1

    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_close
    jmp sfos_entry

fwrite:
    phx
    phy
    sta bios_rega
    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_writeseqbyte
    jsr sfos_entry
    ply
    plx
    rts

clear_buf:
    lda #0
    ldy #0
:   sta SFOS_BUF+0,y
    iny
    bne :-
:   sta SFOS_BUF+256,y
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
    jsr search_fcb
    jsr set_drive
    jsr open_file

    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    ldy #esfos::sfos_d_setdma
    jsr sfos_entry
    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_readseqblock
    jsr sfos_entry

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

    jmp LAB_1319

fread:
    phx
    phy
    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_readseqbyte
    jsr sfos_entry
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
    lda bios_error_code
    cmp #ERROR::FILE_EOF
    bne :+
    jsr reset_redirects
    jmp file_exit
:   ldx #$2A
    jmp LAB_XERR

clear_fcb:
    ldx #0
    lda #0
:   sta FCB,x
    inx
    cpx #32
    bne :-
    rts

create_fcb:
    jsr clear_fcb
    ; parse FCB
    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_setdma
    jsr sfos_entry

    lda #4              ; ALL FILES ON D DRIVE ALLWAYS
    sta FCB

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
    jmp sfos_entry

open_file:
    jsr create_fcb

    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_open
    jmp sfos_entry

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

    lda #<strReady
    ldy #>strReady
    jsr LAB_18C3

    jsr LAB_1477
    jmp LAB_1319

exit:
    jmp bios_wboot

search_fcb:
    jsr clear_fcb
    ldx #0
:   lda strSearch,x
    sta FCB,x
    inx
    cpx #sfcb::L1
    bne :-
    rts

print_fcb:
    stz FCB + sfcb::L1
    ldx #1
:   lda FCB,x
    beq :+
    jsr bios_conout
    inx
    bra :-
:   jmp LAB_CRLF

retro_dir:
    ; search FCB *.bas
    ; find first
    ; find next until none found
    jsr search_fcb
    jsr set_drive

    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_findfirst
    jsr sfos_entry
    bcs @exit
    jsr print_fcb
@loop:
    jsr search_fcb
    lda #<FCB
    ldx #>FCB
    ldy #esfos::sfos_d_findnext
    jsr sfos_entry
    bcs @exit
    jsr print_fcb
    bra @loop
@exit:
    rts

set_drive:
    lda FCB
    ldy #esfos::sfos_d_getsetdrive
    jmp sfos_entry

.bss
active_drive:       .byte 0
saved_active_drive: .byte 0
temp:               .word 0

.rodata
strAnsiCLSHome: .byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
strReady:       .byte $0D,$0A,"Ready",$0A,$0D,$0
strSearch:      .byte 4,"????????BAS"
