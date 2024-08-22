; vim: ft=asm_ca65 ts=4 sw=4 et
.include "sfos.inc"
.include "fcb.inc"
.export main
.autoimport

.globalzp ptr1

BOOT    = $200
WBOOT   = BOOT + 3
SFOS    = BOOT + 6

.zeropage
debug_ptr:  .word 0
sfcpcmd:    .word 0

.code
; main user interface - First show a prompt.
main:
    jsr s_reset
    lda #<str_banner
    ldx #>str_banner
    jsr c_printstr
    lda #1
    sta active_drive
    sta saved_active_drive
    ldx #0
    jsr d_getsetdrive

prompt:
    jsr newline
prompt_no_newline:
    jsr show_prompt

    jsr clear_commandline
    lda #128
    sta commandline
    lda #<commandline
    ldx #>commandline
    jsr c_readstr

    jsr clear_fcb
    jsr clear_fcb2
    lda #<fcb
    ldx #>fcb
    jsr d_setdma

    ldx #>commandline       ; set XA to the second byte of the commandline
    lda #<commandline       ; the first contains the length from readstr
    inc                     ; if the incrementing the low byte of the address
    bne :+                  ; results in zero then increment the high byte
    inx
:   jsr d_parsefcb          ; XA -> param is the start of the filename.
    ; XA -> Points to new command offset
    bcc :+
    jsr printi
    .byte 10,13,"parse error: fcb1",10,13,0
    jmp prompt
:
    ; parse any parameters
    ; XA points to start of rest of command line.
    sta debug_ptr + 0
    stx debug_ptr + 1
    ldy #0
    lda (debug_ptr),y
    beq @check_drive        ; no parameters go on to checkdrive
    ; else setup and parse the parameter
    lda #<fcb2
    ldx #>fcb2
    jsr d_setdma

    ldx debug_ptr + 1
    lda debug_ptr + 0
    inc                     ; skip over space
    bne :+
    inx
:   jsr d_parsefcb
    bcc @check_drive

    jsr printi
    .byte 10,13,"parse error: fcb2",10,13,0
    jmp prompt

@check_drive:
    ; check if we are dealing with a change drive command
    ; byte N1 of the fcb will be a space
    lda fcb+sfcb::N1
    cmp #' '
    beq @changedrive
    bra @decode_command
@changedrive:
    lda fcb + sfcb::DD
    ldx #0
    sta active_drive
    jsr d_getsetdrive
    jmp prompt

@decode_command:
    jsr decode_command
    bcs @load_transient
    cmp #1
    bne :+
    jsr printi
    .byte 10,13,"SYNTAX ERROR",10,13,0
:   jmp prompt
@load_transient:
    jsr load_transient
    jmp prompt

decode_command:
    ldx #0
    ldy #0
    stx temp + 0            ; temp + 0 holds the start position of words in the commands table.
@L1:
    lda commands_tbl,y
    bmi @found_match        ; if we get to the $80 marker, without dropping, we found a match
    beq @no_match           ; if we get to the end of the table we did not match at all
    cmp fcb + sfcb::N1,x
    bne @next_word
    inx                     ; prepare to check next letter
    iny
    bra @L1
@next_word:
    ldx #0                  ; reset fcb index to 0
    inc temp + 0            ; next word
    lda temp + 0            ; times temp + 0 by 7
    asl                     ; x2
    asl                     ; x4
    asl                     ; x8
    sec
    sbc temp + 0            ; subtract value to make it x 7
    tay                     ; update pointer
    bra @L1
@found_match:
    ; reached the end of work marker.
    ; grab the function pointer, return in XA
    iny
    lda commands_tbl,y
    sta sfcpcmd + 0
    iny
    lda commands_tbl,y
    sta sfcpcmd + 1
    clc
    jmp (sfcpcmd)               ; return from command
@no_match:
    sec
    rts

load_transient:
    ; check if FCB has extension.  if not, then add .COM
    lda fcb+sfcb::T1
    cmp #' '
    bne :++

    ldx #2
:   lda str_COM,x
    sta fcb+sfcb::T1,x
    dex
    bpl :-

:   lda #<fcb
    ldx #>fcb
    jsr d_open
    bcc :+
    jsr newline
    lda #'?'
    jsr c_write
    jmp prompt

    ; now dma and the lba are set.
    ; get the sector count from the fcb
:   lda fcb + sfcb::SC
    sta sfcpcmd                 ; using cmd temporarily here.
    lda fcb + sfcb::L1
    sta temp+0
    lda fcb + sfcb::L2
    sta temp+1
@sector_loop:
    jsr d_readseqblock
    clc
    lda temp+1
    adc #2
    sta temp+1
    lda temp+1
    cmp #$9E                    ; hard stop at start of IO
    bne :+
    lda #3
    sec
    rts
:   lda temp+0
    ldx temp+1
    jsr d_setdma
    dec sfcpcmd
    bne @sector_loop
    ; now set up the command pointer
    lda fcb + sfcb::E1
    sta sfcpcmd+0
    lda fcb + sfcb::E2
    sta sfcpcmd+1

call:
    jmp (sfcpcmd)

dir:
    jsr newline
    lda #5
    sta temp                    ; number of records per line
    jsr set_user_drive
    jsr print_drive_colon
    jsr make_dir_fcb
    lda #<fcb
    ldx #>fcb
    jsr d_findfirst
    bcs @exit
    bra @skip_first
@next:
    bcs @exit

    lda temp
    cmp #1
    beq @skip_first
    lda #<str_sep
    ldx #>str_sep
    jsr c_printstr
@skip_first:
    jsr print_fcb
    jsr make_dir_fcb
    lda #<fcb
    ldx #>fcb
    jsr d_findnext
    bra @next
@exit:
    jsr restore_active_drive
    lda #0
    clc
    jmp prompt

era:
    jsr printi
    .byte 10,13,"===> ERA",10,13,0
    lda #1  ; syntax error for now
    clc
    rts

ren:
    jsr printi
    .byte 10,13,"===> REN",10,13,0
    lda #1  ; syntax error for now
    clc
    rts

type:
    jsr set_user_drive
    jsr newline
    lda fcb2+sfcb::DD
    beq @error
    lda #<fcb2
    ldx #>fcb2
    jsr d_findfirst
    bcs @notfound
    lda #<fcb2
    ldx #>fcb2
    jsr d_open
    bcs @notopen
    ; file is found - set up lba
    ; rather than assume the dma for a non exec file, we just set our own
    ; use the sfos_buf here.
@sector_loop:
    lda #<sfos_buf
    ldx #>sfos_buf
    jsr d_setdma

    jsr d_readseqblock

    lda #<sfos_buf
    sta debug_ptr + 0
    lda #>sfos_buf
    sta debug_ptr + 1
@byte_loop:
    lda (debug_ptr)
    pha
    jsr c_write
    pla
    cmp #$0a
    bne :+
    lda #$0d
    jsr c_write
:
    ; decrement the remaining size
    lda fcb2 + sfcb::S0
    bne @dec_ones
    lda fcb2 + sfcb::S1
    bne @dec_tens
    lda fcb2 + sfcb::S2
    beq @exit
@dec_hundreds:
    dec fcb2 + sfcb::S2
@dec_tens:
    dec fcb2 + sfcb::S1
@dec_ones:
    dec fcb2 + sfcb::S0
    ;
    ; move pointer along
    clc 
    lda debug_ptr+0
    adc #1
    sta debug_ptr+0
    lda debug_ptr+1
    adc #0
    sta debug_ptr+1
    cmp #>sfos_buf + 2
    bne @byte_loop

    bra @sector_loop
@notfound:
    lda #'/'
    bra @error
@notopen:
    lda #'?'
@error:
    jsr c_write
    jsr restore_active_drive
    sec
    rts
@exit:
    jsr restore_active_drive
    clc
    rts

save:
    jsr printi
    .byte 10,13,"===> SAVE",10,13,0
    lda #1  ; syntax error for now
    clc
    rts

quit:
    jmp $CF4D

; ---- Helper functions ------------------------------------------------------
s_reset:
    ldy #esfos::sfos_s_reset
    jmp SFOS
d_getsetdrive:
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS
c_write:
    ldy #esfos::sfos_c_write
    jmp SFOS
c_read:
    ldy #esfos::sfos_c_read
    jmp SFOS
c_printstr:
    ldy #esfos::sfos_c_printstr
    jmp SFOS
c_readstr:
    ldy #esfos::sfos_c_readstr
    jmp SFOS
d_setdma:
    ldy #esfos::sfos_d_setmda
    jmp SFOS
d_parsefcb:
    ldy #esfos::sfos_d_parsefcb
    jmp SFOS
d_findfirst:
    ldy #esfos::sfos_d_findfirst
    jmp SFOS
d_findnext:
    ldy #esfos::sfos_d_findnext
    jmp SFOS
d_open:
    ldy #esfos::sfos_d_open
    jmp SFOS
d_readseqblock:
    ldy #esfos::sfos_d_readseqblock
    jmp SFOS

; ---- local helper functions ------------------------------------------------

; restore old drive after disk activity
restore_active_drive:
    lda fcb2
    bne :+
    rts
:   lda saved_active_drive
    sta active_drive
    ldx #0
    jmp d_getsetdrive

set_user_drive:
    lda fcb2
    bne :+
    rts
:   pha
    lda active_drive
    sta saved_active_drive
    pla
    sta active_drive
    ldx #0
    jmp d_getsetdrive

debug_fcb:
    jsr printi
    .byte 13,10,"FCB1: ",0
    lda fcb
    clc
    adc #'A'-1
    jsr acia_putc
    lda #':'
    jsr acia_putc
    ldx #1
:   lda fcb,x
    jsr acia_putc
    inx
    cpx #sfcb::T3+1
    bne :-

    jsr printi
    .byte 13,10,"FCB2: ",0
    lda fcb2
    clc
    adc #'A'-1
    jsr acia_putc
    lda #':'
    jsr acia_putc
    ldx #1
:   lda fcb2,x
    jsr acia_putc
    inx
    cpx #sfcb::T3+1
    bne :-
    rts

clear_commandline:
    ldx #0
    lda #0
:   sta commandline,x
    inx
    bpl :-
    rts

clear_fcb:
    ldx #31
    lda #0
:   sta fcb,x
    dex
    bpl :-
    rts

clear_fcb2:
    ldx #31
    lda #0
:   sta fcb2,x
    dex
    bpl :-
    rts

make_dir_fcb:
    ldx #sfcb::N1
    lda #'?'
:
    sta fcb, x
    inx
    cpx #(sfcb::T3 + 1)
    bne :-
    lda fcb2
    beq :+
    sta fcb
:   rts

print_drive_colon:
    lda #<str_tab
    ldx #>str_tab
    jsr c_printstr
    lda active_drive
    clc
    adc #'A'-1
    jsr c_write
    lda #':'
    jsr c_write
    lda #' '
    jsr c_write
    rts

; used by DIR
print_fcb:
    lda fcb+sfcb::N1
    cmp #' '
    bne :+
    rts
:   dec temp
    lda temp
    bne :+
    jsr newline
    lda #4
    sta temp
    jsr print_drive_colon
:   ldx #sfcb::N1
:   lda fcb,x
    jsr c_write
    inx
    cpx #(sfcb::N8+1)
    bne :-
    lda #' '
    jsr c_write
:   lda fcb,x
    jsr c_write
    inx
    cpx #(sfcb::T3+1)
    bne :-
:   rts

show_prompt:
    lda #$ff
    jsr d_getsetdrive
    clc
    adc #'A' - 1
    jsr c_write
    lda #'>'
    jmp c_write

newline:
    lda #<str_newline
    ldx #>str_newline
    jmp c_printstr

; debug helper
printi:
    pla
    sta debug_ptr
    pla
    sta debug_ptr+1
    bra @primm3
@primm2:
    jsr acia_putc
@primm3:
    inc debug_ptr
    bne @primm4
    inc debug_ptr+1
@primm4:
    lda (debug_ptr)
    bne @primm2
    lda debug_ptr+1
    pha
    lda debug_ptr
    pha
    rts

.bss
commandline:        .res 512
fcb:                .res 32
fcb2:               .res 32
temp:               .res 2
active_drive:       .byte 0
saved_active_drive: .byte 0

.rodata

str_newline:    .byte 13, 10, 0
str_banner:     .byte 13,10, "6502-Retro! (SFCP)",0
str_COM:        .byte "COM"
str_tab:        .byte "    ",0
str_sep:        .byte " : ",0
commands_tbl:
    .byte "DIR ",$80
    .lobytes dir
    .hibytes dir
    .byte "ERA ",$80
    .lobytes era
    .hibytes era
    .byte "QUIT",$80
    .lobytes quit
    .hibytes quit
    .byte "REN ",$80
    .lobytes ren
    .hibytes ren
    .byte "TYPE",$80
    .lobytes type
    .hibytes type
    .byte "SAVE",$80
    .lobytes save
    .hibytes save
    .byte 0
