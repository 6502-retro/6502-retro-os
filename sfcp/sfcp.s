; vim: ft=asm_ca65 ts=4 sw=4 et
.include "sfos.inc"
.include "fcb.inc"
.include "errors.inc"

.export main, prompt
.autoimport

.globalzp ptr1

SFOS        = $200
REBOOT      = SFOS      + 3
WBOOT       = REBOOT    + 3
CONOUT      = WBOOT     + 3
CONIN       = CONOUT    + 3
CONST       = CONIN     + 3
CONPUTS     = CONST     + 3
CONBYTE     = CONPUTS   + 3
CONBEEP     = CONBYTE   + 3
SN_START    = CONBEEP   + 3
SN_SILENCE  = SN_START  + 3
SN_STOP     = SN_SILENCE + 3
SN_SEND     = SN_STOP   + 3
ERROR_CODE  = SN_SEND   + 3
RSTFAR      = $228
REGA        = $22E
REGX        = REGA   + 1
REGY        = REGX   + 1
;
.zeropage
debug_ptr:  .word 0
sfcpcmd:    .word 0

.code
; main user interface - First show a prompt.
main:
    lda #<str_banner
    ldx #>str_banner
    jsr c_printstr
    lda #1
    sta active_drive
    sta saved_active_drive

prompt:
    jsr newline
    jsr process_submit
    bcc process_command     ; Skip reading userinput if $$$.sub processed.
prompt_no_newline:
    jsr show_prompt

    jsr clear_commandline
    lda #128
    sta commandline
    lda #<commandline
    ldx #>commandline
    jsr c_readstr

process_command:
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
    ; XA points to command tail
    bcc @check_drive

    jsr printi
    .byte 10,13,"parse error: fcb2",10,13,0
    jmp prompt

@check_drive:
    inc                     ; skip over space
    bne :+
    inx
:   sta cmdoffset+0
    stx cmdoffset+1
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

process_submit:
    ; safe to use fcb here.
    ldx #31                     ; set up fcb for open
:   lda str_submit_fcb,x
    sta submit_fcb,x
    dex
    bpl :-

    lda #<submit_fcb
    ldx #>submit_fcb
    jsr d_open
    bcc @read_file              ; file was opened so read it.
    rts
@read_file:
    ; copy sector count into CR
    lda submit_fcb + sfcb::SC
    dec
    bpl :+                      ; if SC-1 < 0 then delete file
    jmp @delete_file
:   sta temp+0

    stz temp+3                  ; set up LBA to read last block of the file
    lda submit_fcb + sfcb::DD
    sta temp+2
    lda submit_fcb + sfcb::FN
    sta temp+1

    lda #<temp
    ldx #>temp
    jsr d_setlba

    lda #<sfos_buf
    ldx #>sfos_buf
    jsr d_setdma

    lda #<submit_fcb                   ; read the block, do not adjust CR
    ldx #>submit_fcb
    jsr d_readrawblock
    bcc @find_record
    rts
@find_record:
    lda submit_fcb + sfcb::Z1
    dec
    bpl :+
    jmp @delete_file
:   sta submit_fcb + sfcb::Z1          ; save updated Z1
    and #$03                    ; mod 4
    pha
    ; decide to decrement SC
    bne :+
    dec submit_fcb + sfcb::SC
:   pla
    sta ptr1 + 0
    stz ptr1 + 1

    ldx #7
:   asl ptr1
    rol ptr1+1
    dex
    bne :-
    clc
    lda ptr1+0
    adc #0
    sta ptr1+0
    lda ptr1+1
    adc #>sfos_buf
    sta ptr1+1

    ; ptr1 now points to start of command in buffer
    ; copy it to the commanline
    ldy #0
:   lda (ptr1),y
    sta commandline,y
    phy
    jsr c_write
    ply
    iny
    bpl :-
    ; save fcb back to disk
    lda submit_fcb + sfcb::Z1
    bne @save
@delete_file:
    lda #$E5
    sta submit_fcb + sfcb::FA
@save:
    lda #<submit_fcb
    ldx #>submit_fcb
    jsr d_close
    clc
    rts

load_transient:
    jsr set_user_drive
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
    jsr restore_active_drive
    lda #0
    jmp prompt

    ; now dma is set.
    ; get the sector count from the fcb
:   lda fcb + sfcb::SC
    sta sfcpcmd                 ; using cmd temporarily here.
    lda fcb + sfcb::L1
    sta temp+0
    lda fcb + sfcb::L2
    sta temp+1
@sector_loop:
    lda #<fcb
    ldx #>fcb
    jsr d_readseqblock          ; calculates DMA from FCB
    clc
    lda temp+1
    adc #2
    sta temp+1
    lda temp+1
    cmp #>TPA_END               ; leaves 256 bytes unused.
    bne :+
    lda #ERROR::OUT_OF_MEMORY
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
    jsr restore_active_drive
    jmp (sfcpcmd)

bank:
    lda commandline + 5
    beq @parse_error
    lda commandline + 6
    cmp #' '
    beq @parse_error
    cmp #'0'
    bcc @parse_error
    cmp #'3'+1
    bcs @parse_error
    sec
    sbc #'0'
    jmp RSTFAR
@parse_error:
    jsr printi
    .byte 10,13,"INVALID BANK",0
    lda #0
    jmp prompt

dir:
    jsr newline
    lda #5
    sta temp                    ; number of records per line
    jsr set_user_drive
    jsr print_drive_colon
    jsr clear_fcb
    jsr make_dir_fcb
    lda #<fcb
    ldx #>fcb
    jsr d_findfirst
    bcc @skip_first
    ; Error on find first can be DRIVE_ERROR or END_OF_DIR
    cmp #ERROR::FILE_NOT_FOUND  ; it's okay to have end of directory
    beq @exit                   ; on find first. (empty drive)
    sec
    rts
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
    jsr clear_fcb
    jsr make_dir_fcb
    lda #<fcb
    ldx #>fcb
    jsr d_findnext
    bra @next
@exit:                          ; this exit is normal, end of drive.
    jsr restore_active_drive
    lda #0
    clc
    jmp prompt

era:
    jsr set_user_drive
    lda #<fcb2
    ldx #>fcb2
    jsr d_findfirst
    bcc :+
    jsr printi
    .byte 10,13,"FILE NOT FOUND",10,13,0
    sec
    rts
:
    lda #$E5
    sta fcb2 + sfcb::FA
    lda #<fcb2
    ldx #>fcb2
    jsr d_close
    jsr restore_active_drive
    lda #0
    clc
    rts

free:
    jsr printi
    .byte 10,13,"\r\nTYPE: START-END SIZE"
    .byte 10,13,"\r\nZEROPAGE: ",0 

    lda #<__ZEROPAGE_LOAD__
    jsr bios_prbyte
    lda #'-'
    jsr c_write
    lda #<__ZEROPAGE_SIZE__
    clc
    adc #<__ZEROPAGE_LOAD__
    jsr bios_prbyte
    lda #' '
    jsr c_write
    lda #<__ZEROPAGE_SIZE__
    ldx #>__ZEROPAGE_SIZE__
    jsr print_word


    jsr printi
    .byte 10,13,"SYSTEM:   ",0
    lda #<__SYSTEM_RUN__
    ldx #>__SYSTEM_RUN__
    jsr print_word
    lda #'-'
    jsr c_write
    lda #<__SYSTEM_SIZE__
    sta temp+0
    lda #>__SYSTEM_SIZE__
    sta temp+1
    clc
    lda temp+0
    adc #<__SYSTEM_RUN__
    sta temp+0
    lda temp+1
    adc #>__SYSTEM_RUN__
    sta temp+1
    lda temp+0
    ldx temp+1
    jsr print_word
    lda #' '
    jsr c_write
    lda #<__SYSTEM_SIZE__
    ldx #>__SYSTEM_SIZE__
    jsr print_word

    jsr printi
    .byte 10,13,"BSS:      ",0
    lda #<__BSS_LOAD__
    ldx #>__BSS_LOAD__
    jsr print_word
    lda #'-'
    jsr c_write
    lda #<__BSS_SIZE__
    sta temp+0
    lda #>__BSS_SIZE__
    sta temp+1
    clc
    lda temp+0
    adc #<__BSS_LOAD__
    sta temp+0
    lda temp+1
    adc #>__BSS_LOAD__
    sta temp+1
    lda temp+0
    ldx temp+1
    jsr print_word
    lda #' '
    jsr c_write
    lda #<__BSS_SIZE__
    ldx #>__BSS_SIZE__
    jsr print_word

    jsr printi
    .byte 10,13,"TPA:      ",0
    lda #<TPA
    ldx #>TPA
    jsr print_word
    lda #'-'
    jsr c_write
    lda #<TPA_END
    ldx #>TPA_END
    jsr print_word
    lda #' '
    jsr c_write
    sec
    lda #<TPA_END
    sbc #<TPA
    sta temp+0
    lda #>TPA_END
    sbc #>TPA
    sta temp+1
    lda temp+0
    ldx temp+1
    jsr print_word

    jsr printi
    .byte 10,13,"SFM       ",0
    lda #<__CODE_LOAD__
    ldx #>__CODE_LOAD__
    jsr print_word
    lda #'-'
    jsr c_write
    lda #<__CODE_SIZE__
    sta temp+0
    lda #>__CODE_SIZE__
    sta temp+1
    clc
    lda temp+0
    adc #<__CODE_LOAD__
    adc #<__RODATA_SIZE__
    sta temp+0
    lda temp+1
    adc #>__CODE_LOAD__
    adc #>__RODATA_SIZE__
    sta temp+1
    lda temp+0
    ldx temp+1
    jsr print_word
    lda #' '
    jsr c_write
    lda #<__CODE_SIZE__
    sta temp+0
    lda #>__CODE_SIZE__
    sta temp+1
    clc
    lda temp+0
    adc #<__RODATA_SIZE__
    sta temp+0
    lda temp+1
    adc #>__RODATA_SIZE__
    sta temp+1
    lda temp+0
    ldx temp+1
    jsr print_word
    jmp prompt

help:
    lda #<str_help
    ldx #>str_help
    jsr c_printstr
    jmp prompt

ren:
    ldx #0
    lda #0
:   sta fcb,x
    inx
    cpx #32
    bne :-
    ; parse fcb
    lda #<fcb
    ldx #>fcb
    jsr d_setdma

    lda cmdoffset+0
    ldx cmdoffset+1
    jsr d_parsefcb
    jsr newline
    ; FCB contains the destination copy:
    ; open the source
    lda #<fcb
    ldx #>fcb
    jsr d_findfirst
    bcs :+
    lda #'?'
    jsr c_write
    jmp @exit
:   lda #<fcb2
    ldx #>fcb2
    jsr d_findfirst
    bcc :+
    lda #'?'
    jsr c_write
    jmp @exit
:   ldy #sfcb::N1
:   lda fcb,y
    sta fcb2,y
    iny
    cpy #sfcb::T3 + 1
    bne :-
@close:
    stz fcb2 + sfcb::DS
    lda #<fcb2
    ldx #>fcb2
    jsr d_close
@exit:
    jsr restore_active_drive
    lda #0          ; make sure that we don't trigger a syntax error.
    clc
    rts

type:
    jsr set_user_drive
    jsr newline
    lda fcb2+sfcb::DD
    beq @error

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

    lda #<fcb2
    ldx #>fcb2
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
    lda #0          ; make sure that we don't trigger a syntax error.
    clc
    rts

save:
    ; copy fcb2 filename into fcb
    jsr clear_fcb
    ldx #sfcb::N1
:   lda fcb2,x
    sta fcb,x
    inx
    cpx #sfcb::T3+1
    bne :-

    jsr newline
    lda #<fcb
    ldx #>fcb
    jsr d_make

    bcc :+
    jsr printi
    .byte 10,13,"MAKE FAILED",10,13,0
    lda #1
    clc
    rts
:
    ; convert command tail which is the number of pages to save to a byte
    jsr parse_number
    bcc :+
    jsr printi
    .byte 10,13,"NOT A NUMBER",10,13,0
    lda #1
    clc
    rts             ; parse fail
:
    ; temp+0 has the number of pages to save
    lda #<TPA
    ldx #>TPA
    stx temp+3
    jsr d_setdma

    stz temp+2      ; number of sectors written
@lp:
    lda temp+0
    beq @exit       ; have we hit zero pages?

    lda #'.'
    jsr c_write

    lda #<fcb
    ldx #>fcb
    jsr d_writeseqblock
    bcs @error
    inc temp+2

    dec temp+0      ; save two pages per writeblock
    lda temp+0
    beq :+          ; make sure we don't dec page count below zero
    dec temp+0
:
    clc             ; advance the dma
    lda temp+3
    adc #2
    sta temp+3
    tax
    lda #0
    jsr d_setdma

    bra @lp         ; write next 2 pages
@error:
    jsr printi
    .byte 10,13,"ERROR WRITING DATA TO DISK",10,13,0
    lda #1
    clc
    rts
@exit:
    ; update FCB with number of sectors written
    lda temp+2
    sta fcb+sfcb::SC
    ; save the TPA address to LOAD and EXECUTE
    lda #<TPA
    sta fcb+sfcb::L1
    sta fcb+sfcb::E1
    lda #>TPA
    sta fcb+sfcb::L2
    sta fcb+sfcb::E2

    ; save the size (sector count * 512)
    lda temp+2
    sta fcb+sfcb::S0
    ; x 512 This works because S0, S1 and S2 are all initialised to zero by make.
    ldx #9
    clc
:   asl fcb+sfcb::S0    ;x512
    rol fcb+sfcb::S1
    rol fcb+sfcb::S2
    dex
    bne :-

    ; set attribute 
    ;jsr debug_fcb
    lda #<fcb
    ldx #>fcb
    jsr d_close
    bcc :+
    jsr printi
    .byte 10,13,"ERROR CLOSING FILE",10,13,0
    lda #1
    clc
    rts
:   jsr printi
    .byte 10,13,"SAVED ",0
    lda fcb + sfcb::SC
    jsr bios_prbyte
    jsr printi
    .byte " SECTORS",10,13,0
    rts

quit:
    jmp $CF4D

;
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
    ldy #esfos::sfos_d_setdma
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
d_close:
    ldy #esfos::sfos_d_close
    jmp SFOS
d_readseqblock:
    ldy #esfos::sfos_d_readseqblock
    jmp SFOS
d_writeseqblock:
    ldy #esfos::sfos_d_writeseqblock
    jmp SFOS
d_make:
    ldy #esfos::sfos_d_make
    jmp SFOS
d_setlba:
    ldy #esfos::sfos_d_setlba
    jmp SFOS
d_readrawblock:
    ldy #esfos::sfos_d_readrawblock
    jmp SFOS
d_writerawblock:
    ldy #esfos::sfos_d_writerawblock
    jmp SFOS

; ---- local helper functions ------------------------------------------------

; parse an 8-bit decimal number from the command line.  David Given - cpm65
parse_number:
    ; we use the current commandoffset
    stz temp+0
    lda cmdoffset+0
    sta debug_ptr+0
    lda cmdoffset+1
    sta debug_ptr+1
    ldy #0
@loop:
    lda (debug_ptr),y
    beq @exit
    cmp #' '
    beq @exit
    cmp #'0'
    bcc @parse_error
    cmp #'9'+1
    bcs @parse_error
    sec
    sbc #'0'
    tax
    lda temp+0
    asl
    sta temp+0
    asl
    asl
    clc
    adc temp+0
    sta temp+0
    txa
    clc
    adc temp+0
    sta temp+0
    iny
    bra @loop
@parse_error:
    sec
    rts
@exit:
    lda temp+0
    clc
    rts

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
    rts

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

print_word:
    pha
    txa
    jsr bios_prbyte
    pla
    jsr bios_prbyte
    rts

.bss

commandline:        .res 128
fcb:                .res 32
fcb2:               .res 32
cmdoffset:          .word 0
temp:               .res 4,0
active_drive:       .byte 0
saved_active_drive: .byte 0
submit_fcb:         .res 32,0

.rodata

str_newline:    .byte 13, 10, 0
str_banner:     .byte 13,10, "6502-Retro! (SFCP)",0
str_COM:        .byte "COM"
str_tab:        .byte "    ",0
str_sep:        .byte " : ",0
str_submit_fcb: .byte 0, "$$$     SUB"
                .res 20,0

str_help: .byte 10,13
    .byte 10,13,"BANK <#> Enter a rom bank number from 1 to 3"
    .byte 10,13,"DIR [A:] Enter a drive number to list files"
    .byte 10,13,"ERA [A:]FILENAME Delete a file"
    .byte 10,13,"FREE Display memory information"
    .byte 10,13,"REN SRC DST Rename a file from SRC to DST in current drive"
    .byte 10,13,"SAVE FILENAME ## Save ## pages of memory starting at TPA to a file"
    .byte 10,13,"TYPE [A:]FILENAME Display ascii contents of a file"
    .byte 10,13,0
commands_tbl:
    .byte "BANK",$80
    .lobytes bank
    .hibytes bank
    .byte "DIR ",$80
    .lobytes dir
    .hibytes dir
    .byte "ERA ",$80
    .lobytes era
    .hibytes era
    .byte "FREE",$80
    .lobytes free
    .hibytes free
    .byte "HELP",$80
    .lobytes help
    .hibytes help
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
