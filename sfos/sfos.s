; vim: ft=asm_ca65 ts=4 sw=4 et
.include "fcb.inc"
.autoimport

.globalzp ptr1

.zeropage
cmd:    .word 0

.code

; reset with warm boot and log into drive A
sfos_s_reset:
    jsr bios_wboot
    lda #0
    jmp sfos_d_getsetdrive

; read a char from the serial console
; echo it too
sfos_c_read:
    jsr bios_conin          ; read from serial terminal
    pha                     ; stash it
    jsr sfos_c_write        ; echo it to the terminal
    pla                     ; pop it
    rts

; send a char to the serial console and check for CTRL + C
sfos_c_write:
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
    sta ptr1 + 0
    stx ptr1 + 1
@L1:
    lda (ptr1)
    beq @exit               ; we use null termination 'round 'ere
    jsr sfos_c_write
    inc ptr1 + 0
    bne @skip
    inc ptr1 + 1
@skip:
    bra @L1
@exit:
    rts

sfos_c_readstr:
    jmp unimplimented

sfos_c_status:
    jmp unimplimented

; Gets or sets the current drive.  When the current drive changes, we set LBA
sfos_d_getsetdrive:
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
    lda #0
    ldx #0
    jmp bios_setdma
@exit:
    clc
    rts
@out_of_range:
    lda #$81
    sec
    rts

sfos_d_createfcb:
    jmp unimplimented

sfos_d_convertfcb:
    jmp unimplimented

sfos_d_find:
    jmp unimplimented

sfos_d_make:
    jmp unimplimented

sfos_d_open:
    jmp unimplimented

sfos_d_close:
    jmp unimplimented

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
    ldx #>str_unimplimented
    jmp sfos_c_printstr
    rts

.bss
    current_drive: .byte 0
    lba:    .res 4,0
.align $100
    sdbuf: .res 512

.segment "SYSTEM"
; dispatch function, will be relocated on boot into SYSRAM
dispatch:
    pha
    lda sfos_jmp_tbl_lo,y
    sta cmd + 0
    lda sfos_jmp_tbl_hi,y
    sta cmd + 1
    pla
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
    .hibytes sfos_d_readseqblock
    .hibytes sfos_d_writeseqblock
    .hibytes sfos_d_readseqbyte
    .hibytes sfos_d_writeseqbyte

banner: .byte "6502-Retro! (SFOS)",$0a, $0d, $0
str_unimplimented: .byte "!!!  UNIMPLIMENTED !!!", $a, $d, $0
