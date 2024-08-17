; vim: ft=asm_ca65 ts=4 sw=4 et
.include "fcb.inc"
.autoimport

.globalzp ptr1

.zeropage

cmd:        .word 0
param:      .word 0
user_dma:   .word 0
temp:       .res 4,0
.code

; reset with warm boot and log into drive A
sfos_s_reset:
    jsr bios_wboot
    lda #1
    sta current_drive
    dec
    ora #$80                ; on reset we want to set the lba to point
    sta lba + 0             ; to the sector containing indexes for drive
    stz lba + 1             ; A: which is 0x00_00_00_80
    stz lba + 2
    stz lba + 3
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
    jsr to_upper
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
internal_getsetdrive:
    cmp #$FF
    bne @L1
    lda current_drive       ; return the current_drive
    bra @exit
@L1:
    jsr bios_conout

    cmp #1
    bcc @out_of_range
    cmp #(8+1)
    bcs @out_of_range
    cmp current_drive
    beq @exit
    ; drive is different
    sta current_drive
    dec                     ; If A: drive then A=1, convert to 0 based drive
    ora #$80                ; set the most significant bit
    sta lba + 0             ; indexes begin at 0x80 for drive A
    stz lba + 1             ; all other bytes of the LBA are reset to 0
    stz lba + 2             ; as we have changed to another drive.
    stz lba + 3
@exit:
    clc
    rts
@out_of_range:
    sec
    rts

sfos_d_createfcb:
    jmp unimplimented

; the user_dma pointer points to the buffer containing the commandline
; param points to the FCB Read in the commandline and fill out the FCB
; BORROWED FROM CPM65 By David Given (https://github.com/davidgiven/cpm65)
sfos_d_parsefcb:
    ; param -> commandline (filename)
    ; dma -> FCB
    lda #0
    sta temp+1              ; failure flag

    ; check the drive

    ldy #0
    ldx #0
    lda (param),y           ; drive letter?
    beq @nodrive
    iny
    lda (param),y
    dey
    cmp #':'                ; colon?
    bne @nodrive
    lda (param),y
    jsr to_upper
    sec
    sbc #'A'-1              ; to 1 based drive
    cmp #1                  ; we only support 8 drives on sfs
    bcs :+                  ; carry is clear if drive is less than 8 (0-7)
    cmp #9
    bcc :+
    dec temp+1
:
    tax
    iny
    iny
@nodrive:
    txa
    pha                     ; drive letter pushed to stack

    ; Read the filename

    ldx #8
@L1:
    lda (param),y           ; get a character
    jsr to_upper
    jsr is_terminator_char
    bcc :+                  ; if carry set
    lda #' '
    dey
:   cmp #'*'
    bne :+                  ; if a star
    lda #'?'
    dey
:   pha
    iny
    dex
    bne @L1

    ; skip non-dot fiename characters.
    lda (param),y
@L2:
    cmp #'.'
    beq :++
    jsr is_terminator_char
    bcc :+                  ; if carry set do the below.
    lda #' '                ; filename has no extension
    pha
    pha
    pha
    bra @parse_filename_exit
:   iny
    lda (param),y
    bra @L2
    ; read the extension

:   iny
    ldx #3
@L3:
    lda (param),y           ; get a character
    jsr to_upper
    jsr is_terminator_char
    bcc :+                  ; if carry set do the below
    lda #' '
    dey
:   cmp #'*'
    bne :+
    lda #'?'
    dey
:   pha
    iny
    dex
    bne @L3

    ; discard remaining filename characters
    lda (param),y
@L4:
    jsr is_terminator_char
    bcs @parse_filename_exit
    iny
    lda (param),y
    bne @L4

@parse_filename_exit:
    ; push the 4 zeros for L1, L2, SC, FN
    lda #0
    pha
    pha
    pha
    pha

    ; copy the generated bytes from the stack into the destination

    tya
    tax
    ldy #15
@L5:
    pla
    sta (user_dma),y
    dey
    bpl @L5
    txa
    clc
    adc param+0
    ldx param+1
    bcc :+                  ; did we rollover on the adc above?
    inx
:   clc
    ldy temp+1              ; was there a failure?
    beq :+
    sec
:   rts

; searches the currently selelcted drive for a file matching the name in the provided FCB
; if one is found it returns it.
sfos_d_findfirst:
    jsr home_drive
    bcc :+
    lda #$01                ; TODO: CHECK ERROR CODES
    sec
    rts
:   jsr read_directory_entry
    ; fall through

; Find the next matching filename from the drive specified in the FCB or the
; current drive if the fcb drive value is 0.
; On entry XA points to an fcb containng the filename to find.
; any `?` chars in the filename or the extension will be skipped on char matching.
; keep track of the following details:
;   - sector lba
;   - current_directory_pos
sfos_d_findnext:
    ; check if drive matches current.  It won't if we went over the drive indexes.
    ; might be a better way to do this XXX: Is there a better way?
    lda current_drive
    dec
    cmp current_dirent + sfcb::DD
    beq :+
    lda #$02                ; end of directory
    sec
    rts
:   lda current_dirent + sfcb::FA
    cmp #$E5
    bne :+
    lda #$03
    sec
    rts
:   ldy #sfcb::N1
:   lda (param),y           ; load char from record we retreived from sector
    cmp #'?'
    beq :+                  ; skip comparing question marks
    cmp current_dirent,y    ; compare with the record sent to us.
    bne @nomatch
:   iny
    cpy #sfcb::T3 + 1
    bne :--
@matched:
    ldy #31
:   lda current_dirent,y
    sta (param),y
    dey
    bne :-
    jsr read_directory_entry    ; for next time (if there's a next time)
    clc
    rts
@nomatch:
    ; we have to check the next directory entry.
    jsr read_directory_entry
    bra sfos_d_findnext

; reads the directory entry, loads the next sector from disk if needed
read_directory_entry:
    lda current_dirpos      ; use the current dirpos to calculate the offset
    asl                     ; into the 512byte user_dma.
    asl
    asl
    asl
    asl                     ; x 32
    tay
    ldx #0                  ; index into current_dirent
:   lda (temp),y        ; copy the directory entry into current_dirent
    sta current_dirent,x
    iny
    inx
    cpx #32
    bne :-
    inc current_dirpos      ; increment the current_dirpos and check for end
    lda current_dirpos      ; the end of the current directory sector
    cmp #8                  ; XXX: NASTY SHIT>> Only when dirpos is 8 should
    beq :+                  ; XXX: temp + 1 be incremented.
    bra :++
:   inc temp + 1
:   cmp #16
    bne :+
    jsr sfos_d_readseqblock ; if it was the end of the sector, load the next
    stz current_dirpos      ; sector and reset current_dirpos.
    lda user_dma + 0
    sta temp + 0
    lda user_dma + 1
    sta temp + 1
:   rts

; Reset the dirpos and 
home_drive:
    lda current_drive       ; set the LBA to the begining of the drives indexes
    dec
    asl
    asl
    asl
    asl
    ora #$80
    sta lba + 0
    stz lba + 1
    stz lba + 2
    stz lba + 3
    lda #0
    sta current_filenum
    sta current_dirpos
    ; user_dma is already defined by the caller.
    jsr sfos_d_readseqblock ;read first block
    lda user_dma + 0
    sta temp + 0
    lda user_dma + 1
    sta temp + 1
    rts

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

; Writes a sector of data (512 bytes) into the previously set DMA.
; Post updates LBA to be ready for next block to read.
sfos_d_readseqblock:
    lda #<lba
    ldx #>lba
    jsr bios_setlba         ; update the bios LBA to current lba

    jsr bios_sdread
    bcs :+
    sec
    rts
:   jsr increment_lba
    clc
    rts

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

is_terminator_char:
    stx temp+2
    ldx #(terminators_end - terminators) - 1
:   cmp terminators, x          ; sets carry if equal
    beq :+
    dex
    bpl :-
    clc
:   ldx temp+2
    rts

increment_lba:
    clc
    lda lba + 0
    adc #1
    sta lba + 0
    lda lba + 1
    adc #0
    sta lba + 1
    lda lba + 2
    adc #0
    sta lba + 2
    lda lba + 3
    adc #0
    sta lba + 3
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    rts

; on entry y is pointing at the start of the dirent
copy_dma_to_current_dirent:
    ldx #0
:   lda (user_dma),y
    sta current_dirent,x
    iny
    inx
    cpx #32
    bne :-
    rts

.bss
    current_drive:  .byte 0
    current_filenum:.byte 0
    current_dirent: .res 32, 0
    current_dirpos: .byte 0
    lba:            .res 4, 0
    cmdlen:         .byte 0

.segment "SYSTEM"
; dispatch function, will be relocated on boot into SYSRAM
dispatch:
    sta param + 0
    stx param + 1
    lda sfos_jmp_tbl_hi,y
    sta cmd + 1
    lda sfos_jmp_tbl_lo,y
    sta cmd + 0
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
    .lobytes sfos_d_parsefcb
    .lobytes sfos_d_findfirst
    .lobytes sfos_d_findnext
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
    .hibytes sfos_d_parsefcb
    .hibytes sfos_d_findfirst
    .hibytes sfos_d_findnext
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
str_COM: .byte "COM"
terminators:
    .byte " =><.:,[]/|"
    .byte 10,13,127,9,0
terminators_end:
