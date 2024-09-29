; vim: ft=asm_ca65 sw=4 ts=4 et:
.include "fcb.inc"
.include "sfos.inc"

.zeropage
src_ptr:    .word 0
dst_ptr:    .word 0

.code

main:
    jsr set_user_drive

    ; init dst pointer
    stz dst_ptr+0
    stz dst_ptr+1

    ; FCB2 contains the name of the submit file to process
    lda #<FCB2
    ldx #>FCB2
    jsr d_open
    bcc make_sub

    lda #<str_open_error
    ldx #>str_open_error
    jsr c_printstr
    jmp exit

make_sub:
    ldx #31
:   lda str_sub,x
    sta sub_fcb,x
    dex
    bpl :-

    lda #<sub_fcb
    ldx #>sub_fcb
    jsr d_make
    bcc read_source_block

    lda #<str_make_error
    ldx #>str_make_error
    jsr c_printstr
    jmp exit

read_source_block:
    lda #<src_buf
    ldx #>src_buf
    jsr d_setdma

    lda #<FCB2
    ldx #>FCB2
    jsr d_readseqblock
    bcc process_lines

    lda #<str_block_error
    ldx #>str_block_error
    jsr c_printstr
    jmp exit

process_lines:
    ; actually start by clearing the destination buffer
    jsr clear_dst_buf

    ; start by setting src pointer to start of src_buf
    ; and the pointer to dst_buf
    lda #<src_buf
    sta src_ptr+0
    lda #>src_buf
    sta src_ptr+1

    lda #<dst_buf
    inc
    sta dst_ptr+0
    lda #>dst_buf
    sta dst_ptr+1

    stz line_count

readline:
    ldy #0
    lda (src_ptr),y
    cmp #'.'                ; a . on a line by itself ends the file
    beq end_of_file
readline_lp:
    lda (src_ptr),y
    cmp #$0A                ; END OF LINE?
    beq end_of_line
    sta (dst_ptr),y
    iny
    cpy #$80                ; commands can not be longer than 128 bytes
    bne readline_lp         ;
    lda #<str_cmd_error
    ldx #>str_cmd_error
    jsr c_printstr
    jmp exit
end_of_line:
    sty temp                ; save y
    ; src_ptr is start of line
    tya
    dec dst_ptr+0
    sta (dst_ptr)           ; save length of command into start of line in dest
    inc dst_ptr+0

    ; move dst pointer to end of line
    lda #0
:   sta (dst_ptr),y         ; fill rest of dst buffer with 0's until 128 bytes filled.
    iny
    cpy #$7F
    bne :-
    ; move pointer to next block
    clc
    lda dst_ptr+0
    adc #$80
    sta dst_ptr+0
    lda dst_ptr+1
    adc #0
    sta dst_ptr+1
    ; move src_ptr to end of line
    ldy temp                ; restore y
    iny                     ; skip over \n
    tya
    clc
    adc src_ptr+0
    sta src_ptr+0
    lda src_ptr+1
    adc #0
    sta src_ptr+1
    cmp #>dst_buf           ; dst_buf starts immediately after src_buf
    bne :+
    jmp read_source_block

:   inc line_count
    lda line_count
    cmp #4
    bne readline
    jsr flush_dst_buf
    jmp readline
end_of_file:
    lda #$1A
    ldy #0
    sta (dst_ptr),y
    jsr flush_dst_buf

    ; save the size (sector count * 512)
    lda sub_fcb+sfcb::CR
    sta sub_fcb+sfcb::SC

    sta sub_fcb+sfcb::S0
    ; x 512 This works because S0, S1 and S2 are all initialised to zero by make.
    ldx #9
    clc
:   asl sub_fcb+sfcb::S0    ;x512
    rol sub_fcb+sfcb::S1
    rol sub_fcb+sfcb::S2
    dex
    bne :-

    lda #<sub_fcb
    ldx #>sub_fcb
    jsr d_close

    jmp exit

flush_dst_buf:
    lda #<dst_buf
    ldx #>dst_buf
    jsr d_setdma

    lda #<sub_fcb
    ldx #>sub_fcb
    jsr d_writeseqblock
    bcc :+

    lda #<str_block_error
    ldx #>str_block_error
    jsr c_printstr
    jmp exit

:   jsr clear_dst_buf
    lda #<dst_buf
    sta dst_ptr+0
    lda #>dst_buf
    sta dst_ptr+1
    rts

clear_dst_buf:
    lda #<dst_buf
    sta dst_ptr+0
    lda #>dst_buf
    sta dst_ptr+1
    ldy #0
    lda #0
:   sta (dst_ptr),y
    iny
    bne :-
    inc dst_ptr+1
:   sta (dst_ptr),y
    iny
    bne :-
    rts

; ---- HELPER FUNCTIONS ------------------------------------------------------

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

exit:
    jsr restore_active_drive
    jmp WBOOT

.include "../app.inc"

.bss
sub_fcb:            .res 32,0
src_buf:            .res 512
dst_buf:            .res 512
active_drive:       .byte 0
saved_active_drive: .byte 0
temp:               .byte 0
line_count:         .byte 0

.rodata
str_sub:        .byte 1,"$$$     SUB"
                .res 20,0
str_newline:    .byte 10,13,0
str_open_error: .byte 10,13,"Error opening .sub file",10,13,0
str_make_error: .byte 10,13,"Error creating $$$.sub file",10,13,0
str_block_error:.byte 10,13,"Error reading .sub file",10,13,0
str_cmd_error:  .byte 10,13,"Error with commandline",10,13,0
