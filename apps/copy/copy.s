; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

.zeropage
ptr:    .word 0
addr:   .word 0
line:   .word 0
fileaddr: .word 0

.code

main:
    ; Print hello, world and exit
    lda #<message
    ldx #>message
    jsr c_printstr

newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

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

.include "../app.inc"

.bss

_fcb:        .res 32,0
active_drive: .byte 0
saved_active_drive: .byte 0

.rodata

message: .byte 10,13,"Copy",10,13,0
str_newline: .byte 10,13,0
str_notfound:  .byte 10,13,"File not found",0
