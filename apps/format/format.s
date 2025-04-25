; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"

.zeropage
bufptr: .word 0
.code

main:
    lda #<str_message
    ldx #>str_message
    jsr c_printstr

    jsr c_read
    and #$DF
    sta temp
    sec
    sbc #'A'-1
    sta selected_drive

    jsr newline

    lda #<str_chose
    ldx #>str_chose
    jsr c_printstr

    lda temp
    jsr c_write

    jsr newline

    lda #<str_confirm
    ldx #>str_confirm
    jsr c_printstr

    jsr c_read
    cmp #'Y'
    beq format
    jmp exit
format:
    lda #<str_format_start
    ldx #>str_format_start
    jsr c_printstr

    ; write empty dirents to the buffer each time incrementing the FN
    ; when the buffer is full, flush it to disk.  Stop when all 256
    ; dirents have been written.

    stz file_num
    stz sector_num

new_buffer:
    lda #<SFOS_BUF
    sta bufptr+0
    lda #>SFOS_BUF
    sta bufptr+1

buffer_loop:
    jsr copy_empty_dirent_to_bufptr

    ldy #sfcb::DD
    lda selected_drive
    sta (bufptr),y

    ldy #sfcb::FN
    lda file_num
    sta (bufptr),y

    inc file_num

    jsr bufptr_to_next_dirent
    bcc buffer_loop

    ; full buffer - need to flush to disk
    stz lba+1
    stz lba+2
    stz lba+3

    lda selected_drive
    dec
    clc
    asl     ;x2
    asl     ;x4
    asl     ;x8
    asl     ;x16
    clc
    adc #$80
    adc sector_num
    sta lba+0

    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    jsr d_setdma

    lda #<lba
    ldx #>lba
    jsr d_setlba

    jsr d_writerawblock

    lda #'.'
    jsr c_write

    inc sector_num
    lda sector_num
    cmp #$10
    bne new_buffer

    jsr set_user_drive
    jmp exit

; ---- HELPER FUNCTIONS ------------------------------------------------------

copy_empty_dirent_to_bufptr:
    ldy #31
:   lda empty_dirent,y
    sta (bufptr),y
    dey
    bpl :-
    rts

; CARRY SET When buffer overflows, else carry clear.
bufptr_to_next_dirent:
    clc
    lda bufptr+0
    adc #32
    sta bufptr+0
    lda bufptr+1
    adc #0
    sta bufptr+1
    cmp #>SFOS_BUF_END
    beq :+
    clc
    rts
:   sec
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
;
newline:
    lda #<str_newline
    ldx #>str_newline
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
    jsr restore_active_drive
    jmp bios_wboot

.include "../app.inc"

.bss
_fcb:               .res 32,0
active_drive:       .byte 0
saved_active_drive: .byte 0
temp:               .byte 0
selected_drive:     .byte 0
dirpos:             .byte 0
file_num:           .byte 0
lba:                .res 4,0
sector_num:         .byte 0

.rodata
str_message:     .byte 10,13,"Which drive would you like to format [A-H]? > ",0
str_chose:       .byte 10,13,"You have selected drive: ",0
str_confirm:     .byte 10,13,"Are you sure? (Y/n) > ",0
str_format_start:.byte 10,13,"Formatting ",0
str_format_end:  .byte " OK",0
str_error:       .byte 10,13,"ERROR",10,13,0
str_newline:     .byte 10,13,0
                    ;  0    1    2    3    4    5    6    7    8    9    A    B  C  D  E, F
empty_dirent:    .byte 0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, 0, 0, 0, 0 ; 00
                 .byte $E5, 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0, 0, 0, 0 ; 10
