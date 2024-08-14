; vim: ft=asm_ca65 ts=4 sw=4 et
.include "fcb.inc"
.autoimport

.globalzp ptr1

.zeropage

cmd:        .word 0
param:      .word 0
user_dma:   .word 0

.code

; reset with warm boot and log into drive A
sfos_s_reset:
    jsr bios_wboot
    stz current_drive
    rts

; read a char from the serial console
; echo it too
sfos_c_read:
    jsr bios_conin          ; read from serial terminal
    pha                     ; stash it
    jsr internal_c_write    ; echo it to the terminal
    pla                     ; pop it
    rts

; send a char to the serial console and check for CTRL + C
sfos_c_write:
    lda param + 0
internal_c_write:
    jsr bios_conout
    jsr bios_const
    beq @exit
    cmp #$03                ; we do a quick ^C check here and perform a soft
    bne @exit               ; boot if we find one.
    jmp sfos_s_reset
@exit:
    rts

; print a null terminated string pointed to by XA to the serial console.
sfos_c_printstr:
@L1:
    lda (param)
    beq @exit               ; we use null termination 'round 'ere
    jsr internal_c_write
    inc param + 0
    bne @L1
    inc param + 1
    bra @L1
@exit:
    rts

; reads a line of text from the serial console into the commandline buffer
sfos_c_readstr:
    lda (param)
    cmp #$80
    bcc :+                  ; max commandline length is 128
    lda #$80
:   sta cmdlen
    ldy #1
@L1:
    jsr bios_conin
    cmp #3
    beq @done
    cmp #10
    beq @enter
    cmp #13
    beq @enter
    cmp #$08
    beq @backspace
    jsr to_upper
    sta (param),y
    jsr bios_conout
    iny
    cpy cmdlen
    bne @L1
@done:
    tya
    sta (param)             ; overwrite the commandline length with the
    rts                     ; actual commandline length entered.
@enter:
    lda #0
    sta (param),y
    bra @done
@backspace:
    cpy #1
    beq @L1
    dey
    jsr bios_conout
    lda #' '
    jsr bios_conout
    lda #$08
    jsr bios_conout
    bra @L1

sfos_c_status:
    jmp unimplimented

; Gets or sets the current drive.  When the current drive changes, we set LBA
sfos_d_getsetdrive:
    lda param + 0
    cmp #$FF
    bne @L1
    lda current_drive       ; return the current_drive
    bra @exit
@L1:
    cmp current_drive
    beq @exit
    ; drive is different
    cmp #7
    bcc @out_of_range
    sta current_drive
    sta lba + 3             ; drive number is the 3rd byte of the LBA
    stz lba + 0             ; all other bytes of the LBA are reset to 0
    stz lba + 1             ; as we have changed to another drive.
    stz lba + 4
    jsr bios_setlba
@exit:
    clc
    rts
@out_of_range:
    lda #$81
    sec
    rts

sfos_d_createfcb:
    jmp unimplimented

; the user_dma pointer points to the buffer containing the commandline
; param points to the FCB Read in the commandline and fill out the FCB
sfos_d_convertfcb:
    lda #10
    jsr bios_conout
    lda #13
    jsr bios_conout

    ; clear scratch
    ldx #32
:   stz scratch_fcb,x
    dex
    bne :-
    ; x is zero now and will be the index into scratch
    ; step over the dma length byte
    clc
    lda user_dma + 0
    adc #1
    sta user_dma + 0
    lda user_dma + 1
    adc #0
    sta user_dma + 1

    ; check for empty commandline
    ldy #0
    lda (user_dma),y
    beq @empty_cmd
    ; check if a drive was provided.
    iny
    lda (user_dma),y
    dey
    cmp #':'
    bne @default_drive
    ; a drive was provided
    lda (user_dma),y
    sec
    sbc #'A'
    sta scratch_fcb, x
    iny
    iny                     ; skip past drive into first letter of filename
    bra @filename_entry
@default_drive:             ; no drive provided, insert default into fcb
    lda current_drive
    sta scratch_fcb,x
    ; y is still at the beginning of filename (no drive given)
@filename_entry:
    inx
@filename:
    cpx #sfcb::T1
    beq @extension_entry
    lda (user_dma),y
    beq @fn_space
    cmp #'.'
    beq @fn_space           ; if it's a dot we want to fill with spaces
    cmp #' '
    beq @bad_filename
    cmp #'*'
    bne @fn_check_valid     ; not a ., space or a *
    ; it's a star
    lda #'?'
    dey                     ; replace rest of filename with ? when *
    bra @fn_save_to_scratch
@fn_space:
    dey
    lda #' '
    bra @fn_save_to_scratch
@fn_check_valid:
    jsr is_valid_filename_char
    bcs @bad_filename
    ;fall through
@fn_save_to_scratch:
    sta scratch_fcb,x
    iny
    inx
    bra @filename
@extension_entry:           ; now process the same logic for the 2 ext chars
    iny                     ; skip over the dot
    lda (user_dma),y
    cmp #'.'
    bne @extension
    iny                     ; if we get a dot because of wildcard, skip it.
    ; X is already xfcb.t1
@extension:
    cpx #sfcb::T3 + 1        ; have we reached the end of the extension part of the fcb
    beq @okay               ; if yes, we are done.
    lda (user_dma),y
    beq @ex_space
    cmp #'.'
    beq @ex_space
    cmp #' '
    beq @bad_filename
    cmp #'*'
    bne @ex_check_valid
    lda #'?'
    dey
    bra @ex_save_to_scratch
@ex_space:
    dey
    lda #' '
    bra @ex_save_to_scratch
@ex_check_valid:
    jsr is_valid_filename_char
    bcs @bad_filename
    ; fall through
@ex_save_to_scratch:
    sta scratch_fcb,x
    iny
    inx
    bra @extension
@empty_cmd:
    sec
    rts
@bad_filename:
    jsr bios_conout
    lda #<str_badfilename
    ldx #>str_badfilename
    jsr bios_puts
    bra @empty_cmd
@okay:
    ldy #31
:   lda scratch_fcb,y
    sta (param),y
    dey
    bpl :-
    clc
    rts

sfos_d_find:
    jmp unimplimented

sfos_d_make:
    jmp unimplimented

sfos_d_open:
    jmp unimplimented

sfos_d_close:
    jmp unimplimented

sfos_d_setdma:
    lda param + 0
    sta user_dma + 0
    ldx param + 1
    stx user_dma + 1
    jmp bios_setdma

sfos_d_readseqblock:
    jmp unimplimented

sfos_d_writeseqblock:
    jmp unimplimented

sfos_d_readseqbyte:
    jmp unimplimented

sfos_d_writeseqbyte:
    jmp unimplimented

;---- HELPER FUNCTIONS -------------------------------------------------------
unimplimented:
    lda #<str_unimplimented
    lda #>str_unimplimented
    jmp bios_puts

; converts a characater to upper case
to_upper:
    cmp #'a'
    bcc @done
    cmp #'z' + 1
    bcs @done
    and #$DF
@done:
    rts

; checks if a character in A is a valid filename char
is_valid_filename_char:
    beq @bad
    cmp #' '                    ; no spaces
    beq @bad                    ; only allows letters
    cmp #':'
    beq @bad
    cmp #'Z' + 1
    bcs @bad
@okay:
    clc
    rts
@bad:
    sec
    rts

.bss
    current_drive:  .byte 0
    lba:            .res 4,0
    cmdlen:         .byte 0
    scratch_fcb:    .res 32,0
    temp:           .res 4

.segment "SYSTEM"
; dispatch function, will be relocated on boot into SYSRAM
dispatch:
    sta param + 0
    stx param + 1
    lda sfos_jmp_tbl_lo,y
    sta cmd + 0
    lda sfos_jmp_tbl_hi,y
    sta cmd + 1
    jmp (cmd)

.rodata

sfos_jmp_tbl_lo:
    .lobytes sfos_s_reset
    .lobytes sfos_c_read
    .lobytes sfos_c_write
    .lobytes sfos_c_printstr
    .lobytes sfos_c_readstr
    .lobytes sfos_c_status
    .lobytes sfos_d_getsetdrive
    .lobytes sfos_d_createfcb
    .lobytes sfos_d_convertfcb
    .lobytes sfos_d_find
    .lobytes sfos_d_make
    .lobytes sfos_d_open
    .lobytes sfos_d_close
    .lobytes sfos_d_setdma
    .lobytes sfos_d_readseqblock
    .lobytes sfos_d_writeseqblock
    .lobytes sfos_d_readseqbyte
    .lobytes sfos_d_writeseqbyte
sfos_jmp_tbl_hi:
    .hibytes sfos_s_reset
    .hibytes sfos_c_read
    .hibytes sfos_c_write
    .hibytes sfos_c_printstr
    .hibytes sfos_c_readstr
    .hibytes sfos_c_status
    .hibytes sfos_d_getsetdrive
    .hibytes sfos_d_createfcb
    .hibytes sfos_d_convertfcb
    .hibytes sfos_d_find
    .hibytes sfos_d_make
    .hibytes sfos_d_open
    .hibytes sfos_d_close
    .hibytes sfos_d_setdma
    .hibytes sfos_d_readseqblock
    .hibytes sfos_d_writeseqblock
    .hibytes sfos_d_readseqbyte
    .hibytes sfos_d_writeseqbyte

banner:             .byte "6502-Retro! (SFOS)", 13, 10, 0
str_unimplimented:  .byte 13, 10, "!!! UNIMPLIMENTED !!!", 13, 10, 0 
str_badfilename:    .byte 13, 10, "BAD FILENAME", 13,10,0
