; vim: ft=asm_ca65 ts=4 sw=4 etsfos
.include "fcb.inc"
.include "io.inc"
.autoimport
.export sfos_buf, lba, sfos_s_reset

.globalzp ptr1

.zeropage

ram_bank:   .byte 0
rom_bank:   .byte 0
cmd:        .word 0
param:      .word 0
user_dma:   .word 0
zptemp0:    .word 0
zptemp1:    .word 0
zptemp2:    .word 0

.code

; reset with warm boot and log into drive A
sfos_s_reset:
    lda #1
    jsr internal_getsetdrive
    jmp main

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
    ;jsr to_upper
    jsr bios_conout
    jsr bios_const
    beq @exit
    cmp #$03                ; we do a quick ^C check here and perform a soft
    bne @exit               ; boot if we find one.
    jmp sfos_s_reset
@exit:
    rts

; check if there is a character waiting in the bios.  If there is return it
; else return 0 in A
sfos_c_status:
    jmp bios_const


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
    iny
    lda #0
    sta (param),y
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

; ----------------------------------------------------------------------------
; ---- DRIVE ACTIVITIES ------------------------------------------------------
; ----------------------------------------------------------------------------
get_drvtbl_idx:
    lda drive
    dec
    asl
    rts

get_drvmax:
    jsr get_drvtbl_idx
    tax
    lda drvtbl + drvalloc::maxdrv
    rts

login_drive:
    cmp #$FF
    beq :+
    jsr get_drvtbl_idx
    tax
    stx cmd                 ; using cmd temporarily for this
    lda drvtbl + drvalloc::is_logged_in,x
    bne @exit
:
    lda #<str_scanning
    ldx #>str_scanning
    jsr bios_puts
    jsr compute_drive_index_lba
@sector_lp:
    jsr internal_setdma
    jsr internal_readblock ; read 1 index block
    lda user_dma+0
    sta zptemp0+0
    lda user_dma+1
    sta zptemp0+1
@dirent_loop:
    ldy #sfcb::FA
    lda (zptemp0),y
    cmp #$E5
    beq @next_dirent
    ldx cmd
    inc drvtbl + drvalloc::maxdrv,x
@next_dirent:
    clc
    lda zptemp0+0
    adc #32
    sta zptemp0+0
    lda zptemp0+1
    adc #0
    sta zptemp0+1
    cmp #>sfos_buf + 2
    bne @dirent_loop
    lda lba+0
    and #$0F
    bne @sector_lp
    ldx cmd
    lda #1
    sta drvtbl + drvalloc::is_logged_in,x
@exit:
    rts

; Gets or sets the current drive.  When the current drive changes, we set LBA
sfos_d_getsetdrive:
    lda param + 0
internal_getsetdrive:
    cmp #$FF
    bne @L1
    lda drive       ; return the drive
    bra @exit
@L1:
    cmp #1
    bcc @out_of_range
    cmp #(8+1)
    bcs @out_of_range
    cmp drive
    beq @exit
    ; drive is different
    sta drive
    lda #$00        ; don't force scan
    jsr login_drive
@exit:
    clc
    rts
@out_of_range:
    sec
    rts

compute_drive_index_lba:
    lda drive       ; set the LBA to the begining of the drives indexes
    dec
    asl
    asl
    asl
    asl
    ora #$80
    sta lba+0
    stz lba+1
    stz lba+2
    stz lba+3
    rts

; Reset the dirpos and ztemp ptr into user_dma
home_drive:
    jsr compute_drive_index_lba
    lda #0
    sta current_filenum
    sta current_dirpos
    ; user_dma is already defined by the caller.
    jsr internal_readblock ;read first block
    lda user_dma+0
    sta zptemp1+0
    lda user_dma+1
    sta zptemp1+1
    rts


; ----------------------------------------------------------------------------
; ---- FCB ACTIVITIES --------------------------------------------------------
; ----------------------------------------------------------------------------

; the user_dma pointer points to the fcb memory
; param points to the commandline
; returns with the fcb filled out and XA pointing at the updated location
; in the commandline.
; BORROWED FROM CPM65 By David Given (https://github.com/davidgiven/cpm65)
sfos_d_parsefcb:
    ; param -> commandline (filename)
    ; dma -> FCB
    lda #0
    sta zptemp0             ; failure flag

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
    cmp #1
    bcs :+
    cmp #9
    bcc :+
    dec zptemp0
:
    tax
    iny
    iny
@nodrive:
    txa
    bne :+
    lda drive               ; pop in the current drive if one was not given.
:   pha                     ; drive letter pushed to stack

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
    sta (user_dma),y        ; user_dma -> fcb
    dey
    bpl @L5
    txa
    clc
    adc param+0             ; param -> commandline
    ldx param+1
    bcc :+                  ; did we rollover on the adc above?
    inx                     ; XA points to first char after space
:   clc                     ; TODO: should call skipsapces here.
    ldy zptemp0             ; was there a failure?
    beq :+
    sec
:   rts

is_terminator_char:
    stx zptemp2
    ldx #(terminators_end - terminators) - 1
:   cmp terminators, x          ; sets carry if equal
    beq :+
    dex
    bpl :-
    clc
:   ldx zptemp2
    rts

; ----------------------------------------------------------------------------
; ---- DIRECTORY ACTIVITIES --------------------------------------------------
; ----------------------------------------------------------------------------

; searches the currently selelcted drive for a file matching the name in the provided FCB
; if one is found it returns it.
; on entry: Param points to FCB
sfos_d_findfirst:
    jsr internal_setdma
    jsr home_drive
    bcc :+
    lda #$01                ; TODO: CHECK ERROR CODES
    sec
    rts
:   jsr read_directory_entry
    ; fall through

; On entry, param points to an FCB.
; On entry a directory has been read by a previous call to findnext or findfirst.
; current_dirent contains the current directory entry being checked against the FCB
; pointed to by the param.
; any `?` chars in the filename or the extension will be skipped on char matching.
; keep track of the following details:
;   - sector lba
;   - current_directory_pos
sfos_d_findnext:
    ; check if drive matches current.  It won't if we went over the drive indexes.
    ; might be a better way to do this XXX: Is there a better way?
    lda drive
    cmp current_dirent + sfcb::DD
    beq :+
    lda #$02                ; end of directory
    sec
    rts
:   lda current_dirent + sfcb::FA
    cmp #$E5
    bne :+
    ; first, is the caller looking for deleted files?
    ldy #sfcb::DD
    lda (param),y
    cmp #$E5
    beq @matched
    ; next, is the filenum of this deleted file more than maxdrv
    jsr get_drvtbl_idx
    tax
    lda drvtbl + drvalloc::maxdrv,x
    cmp current_dirent + sfcb::FN
    bcs @nomatch
    lda #2
    sec
    rts
:   ldy #sfcb::N1
:   lda (param),y           ; load char from record we retreived from user
    cmp #'?'
    beq :+                  ; skip comparing question marks
    cmp current_dirent,y    ; compare with the record from the sector on disk
    bne @nomatch
:   iny
    cpy #sfcb::T3 + 1
    bne :--
@matched:
    ldy #31
:   lda current_dirent,y
    sta (param),y
    dey
    bpl:-
    jsr read_directory_entry    ; for next time (if there's a next time)
    lda #$FF
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
:   lda (zptemp1),y         ; copy the directory entry into current_dirent
    sta current_dirent,x
    iny
    inx
    cpx #32
    bne :-
    inc current_dirpos      ; increment the current_dirpos and check for end
    lda current_dirpos      ; the end of the current directory sector
    cmp #8
    beq :+
    bra :++
:   inc zptemp1+1
:   cmp #16
    bne :+
    jsr internal_readblock  ; if it was the end of the sector, load the next
    stz current_dirpos      ; sector and reset current_dirpos.
    lda user_dma+0
    sta zptemp1+0
    lda user_dma+1
    sta zptemp1+1
:   rts

; given an fcb pointed by param, find the file and set the LBA and DMA address.
sfos_d_open:
    ldy #sfcb::DD
    lda (param),y
    beq :+
    jsr internal_getsetdrive
:
    jsr sfos_d_findfirst    ; sets internal dma already
    bcs @notfound
    ; set the dma address
    ldy #sfcb::L1
    lda (param),y
    sta user_dma+0
    pha
    ldy #sfcb::L2
    lda (param),y
    sta user_dma+1
    tax
    pla
    jsr bios_setdma         ; sets the bios dma for sdcard ops.
    ; compute LBA
    ;;;stz lba + 3
    ;;;lda drive
    ;;;sta lba + 2
    ;;;ldy #sfcb::FN
    ;;;lda (param),y
    ;;;sta lba + 1
    ;;;stz lba + 0
    ;;;jsr bios_setlba         ; sets the bios lba for sdcard ops.and the lba are set.
    ; initialize the Current Record to 0.
    ldy #sfcb::CR
    lda #0
    sta (param),y

    clc
    rts
@notfound:
    sec
    rts

; param points to FCB that needs to be closed.
sfos_d_close:
    jsr compute_drive_index_lba ; lba is set
    ldy #sfcb::FN
    lda (param),y
    lsr     ;/2
    lsr     ;/4
    lsr     ;/8
    lsr     ;/16
    clc                     ; add to lba+0 for sector conaining drive
    adc lba+0
    sta lba+0
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    ; now read the index sector into the sfos_buf
    lda #<sfos_buf
    ldx #>sfos_buf
    jsr bios_setdma
    jsr bios_sdread
    bcc @error
    ; now insert the fcb into the sector
    ldy #sfcb::FN
    lda (param),y

    and #$0F                ; mod 16
    ldx #5                  ; x 32
:   asl
    dex
    bne :-

    tax                     ; x holds position in the buffer.
    ldy #sfcb::FN
    lda (param),y
    ldy #0
    cmp #$80                ; when the dirpos is > 80 we must insert the fcb into the
    bcs @upper              ; second half of the 512byte sector.
:   lda (param),y           ; copy fcb to lower half of sector
    sta sfos_buf,x
    inx
    iny
    cpy #32
    bne :-
    bra @flush
@upper:                     ; copy fcb to upper half of sector.
:   lda (param),y           ; copy fcb to lower half of sector
    sta sfos_buf+256,x
    inx
    iny
    cpy #32
    bne :-
@flush:
    lda #<sfos_buf
    ldx #>sfos_buf
    jsr bios_setdma
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    jsr bios_sdwrite
    bcs @exit
@error:
    sec
    rts
@exit:
    lda #$FF                ; force drive scan
    jsr login_drive
    lda #0
    clc
    rts

; param points to FCB containing filename to create.
; Returns updated FCB containing Drive, FN and CR
sfos_d_make:
    jsr sfos_d_findfirst
    bcs :+
    lda #3
    bra @error
:   ; file does not exist.
    ldy #sfcb::DD           ; tell find first to return an empty slot
    lda #$E5
    sta (param),y
    jsr sfos_d_findfirst
    bcc @exit
    lda 1
    bra @error
@exit:
    ; allocate dirent by setting file attribute to 0x40
    lda #$40
    ldy #sfcb::FA
    sta (param),y
    ; zero out L1, L2, E1, E2, S0, S1, S2, Z1, Z2, SC
    lda #0
    ldy #sfcb::SC
    sta (param),y
    ldy #sfcb::L1
    sta (param),y
    iny
    sta (param),y

    ldy #sfcb::E1
:
    sta (param),y
    iny
    cpy #sfcb::S2 + 1
    bne :-

    ldy #sfcb::CR
    sta (param),y

    ; set the lba here so that next write operation has it.
    stz lba + 3
    ldy #sfcb::DD
    lda (param),y
    sta lba + 2
    ldy #sfcb::FN
    lda (param),y
    sta lba + 1
    stz lba + 0
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    lda #0
    clc
    rts
@error:
    sec
    rts

; ----------------------------------------------------------------------------
; ---- SYSTEM / DISK FUNCTIONS -----------------------------------------------
; ----------------------------------------------------------------------------

sfos_d_setdma:
    lda param + 0
    sta user_dma + 0
    ldx param + 1
    stx user_dma + 1
    jmp bios_setdma

; These internal read and write block functions assume a previously set LBA and DMA
; and do not update the LBA on completion.
internal_readblock:
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    jsr bios_sdread
    bcs :+
    lda #1
    sec
    rts
:   inc lba + 0
    clc
    rts

; Given the FCB passed in param, the LBA is determined from the DRIVE + CR
; fields and the block is read into the current DMA address.
; On completion, the FCB CR field is updated to the next record.
sfos_d_readseqblock:
    jsr set_fcb_lba
    jsr bios_sdread
    bra _sdresponse

sfos_d_writeseqblock:
    jsr set_fcb_lba
    jsr bios_sdwrite
    ; fall through

_sdresponse:
    bcs :+
    sec
    rts
:   jmp increment_fcb_lba   ; carry is set if rollover

set_fcb_lba:
    stz lba + 3
    ldy #sfcb::DD
    lda (param),y
    sta lba + 2
    ldy #sfcb::FN
    lda (param),y
    sta lba + 1
    ldy #sfcb::CR
    lda (param),y
    sta lba + 0
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    rts

increment_fcb_lba:
    ldy #sfcb::CR
    lda (param),y
    clc
    adc #1
    sta (param),y
    beq :+          ; rolled over - a problem.
    clc
    rts
:   sec
    rts
;
; sets the dma to the sfos_buf
internal_setdma:
    lda #<sfos_buf
    sta user_dma + 0
    ldx #>sfos_buf
    stx user_dma + 1
    jmp bios_setdma

dispatch:
    sta param + 0
    stx param + 1
    lda sfos_jmp_tbl_hi,y
    sta cmd + 1
    lda sfos_jmp_tbl_lo,y
    sta cmd + 0
    jmp (cmd)

; ----------------------------------------------------------------------------
; ---- UNIMPLIMENTED FUNCTIONS -----------------------------------------------
; ----------------------------------------------------------------------------
sfos_d_createfcb:
    jmp unimplimented

sfos_d_readseqbyte:
    jmp unimplimented

sfos_d_writeseqbyte:
    jmp unimplimented


; ----------------------------------------------------------------------------
; ---- HELPER FUNCTIONS ------------------------------------------------------
; ----------------------------------------------------------------------------

unimplimented:
    lda #<str_unimplimented
    ldx #>str_unimplimented
    jsr bios_puts
    sec
    rts

; converts a characater to upper case
to_upper:
    cmp #'a'
    bcc @done
    cmp #'z' + 1
    bcs @done
    and #$DF
@done:
    rts

.bss
.align $100
    sfos_buf:       .res 512
    drive:          .byte 0
    current_filenum:.byte 0
    current_dirent: .res 32, 0
    current_dirpos: .byte 0
    drvtbl:         .res 16
    lba:            .res 4, 0
    cmdlen:         .byte 0

.segment "SYSTEM"
; dispatch function, will be relocated on boot into SYSRAM
jmptables:
    jmp bios_boot
    jmp bios_wboot
    jmp dispatch

rstfar:
    sta rom_bank
    sta rombankreg
    jmp ($FFFC)

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
str_COM:            .byte "COM"
str_scanning:       .byte 10,13,"Scanning drive...",10,13,0
terminators:
                    .byte " =><.:,[]/|"
                    .byte 10,13,127,9,0
terminators_end:
