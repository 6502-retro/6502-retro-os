; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"

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

    ; to dump a file contents, we want to:
    ; - open the file
    ; - while read sequential block == TRUE:
    ;   - print the bytes and ascii chars
    ; - exit

    ; FCB2 contains the file
    jsr set_user_drive

    lda #<FCB2
    ldx #>FCB2
    jsr d_open      ; sets DMA, but we need to change the DMA for this.
    bcc :+
    lda #<str_notfound
    ldx #>str_notfound
    jsr c_printstr
    jmp exit
:
    stz addr+0
    stz addr+1
    stz fileaddr+0
    stz fileaddr+1

    lda FCB2 + sfcb::SC ; If there is no data then exit immediately.
    bne sector_loop
    jmp exit

sector_loop:
    lda #<SFOS_BUF
    ldx #>SFOS_BUF
    jsr d_setdma
    lda #<FCB2
    ldx #>FCB2
    jsr d_readseqblock

    lda #<SFOS_BUF
    sta addr+0
    sta line+0      ; so that we can repoint addr at the line for the
    lda #>SFOS_BUF
    sta addr+1      ; ascii component.
    sta line+1


lines_loop:
    jsr newline
    lda fileaddr+1
    jsr prbyte
    lda fileaddr+0
    jsr prbyte
    lda #' '
    jsr c_write
    lda #<str_sep
    ldx #>str_sep
    jsr c_printstr

    lda line+0
    sta addr+0
    lda line+1
    sta addr+1

    ldx #16
line_bytes_loop:
    lda (addr)
    jsr prbyte
    lda #' '
    jsr c_write
    inc addr+0
    bne :+
    inc addr+1
:   dex
    bne line_bytes_loop

    lda #<str_sep
    ldx #>str_sep
    jsr c_printstr

    lda line+0
    sta addr+0
    lda line+1
    sta addr+1
    ldx #16
line_ascii_loop:
    lda (addr)
    cmp #' '
    bcc :+
    cmp #'z' + 1
    bcs :+
    jsr c_write
    bra :++
:   lda #'.'
    jsr c_write
:   inc addr+0
    bne :+
    inc addr+1
:   dex
    bne line_ascii_loop

    jsr line_add_16
    jsr fileaddr_add_16
    lda line+1
    cmp #>SFOS_BUF + 2
    bne lines_loop

    dec FCB2 + sfcb::SC
    lda FCB2 + sfcb::SC
    beq exit
    jmp sector_loop
exit:
    jsr restore_active_drive
    jmp bios_wboot


line_add_16:
    clc
    lda line+0
    adc #16
    sta line+0
    lda line+1
    adc #0
    sta line+1
    rts

fileaddr_add_16:
    clc
    lda fileaddr+0
    adc #16
    sta fileaddr+0
    lda fileaddr+1
    adc #0
    sta fileaddr+1
    rts


print_8_bytes:
    sta ptr+0
    stx ptr+1

    rts

print_16_bytes:
    jsr print_8_bytes
    jsr print_8_bytes
    rts

print_16_ascii:
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
used_space: .dword 0
active_drive: .byte 0
saved_active_drive: .byte 0
sector_count: .byte 0

.rodata

message: .byte 10,13,"Dump",10,13,0
str_sep:    .byte "| ",0
str_newline: .byte 10,13,0
str_notfound:  .byte 10,13,"File not found",0
