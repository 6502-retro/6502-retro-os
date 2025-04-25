; vim: ft=asm_ca65 ts=4 sw=4

.include "fcb.inc"
.include "io.inc"
.include "errors.inc"
.include "bios.inc"

.autoimport
.export sfos_buf, sfos_s_reset, dispatch

.zeropage

cmd:        .word 0
param:      .word 0
user_dma:   .word 0
zptemp0:    .word 0
zptemp1:    .word 0
zptemp2:    .word 0
zpbufptr:   .word 0

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

; A=0xFF forces new scan of drive, else check if already logged in
; if yes, then return else scan drive.
login_drive:
    cmp #$FF
    beq :+
    jsr get_drvtbl_idx
    tax
    stx cmd                 ; using cmd temporarily for this
    lda drvtbl + drvalloc::is_logged_in,x
    bne @exit
:
    ;lda #<str_scanning
    ;ldx #>str_scanning
    ;jsr bios_puts
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
    sta error_code
    clc
    rts
@out_of_range:
    lda #ERROR::DRIVE_ERROR
    sta error_code
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
    stz zptemp0             ; failure flag

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
:   clc                     ; 
    ldy zptemp0             ; was there a failure?
    beq :+
    lda #ERROR::PARSE_ERROR ; return parse error or XA.
    sta error_code
    ldx #0
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
    lda #ERROR::DRIVE_ERROR
    sta error_code
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
    lda drive
    cmp current_dirent + sfcb::DD
    beq :+
    lda #ERROR::FILE_NOT_FOUND
    sta error_code
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
    lda #ERROR::FILE_NOT_FOUND
    sta error_code
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
    bcc :+
    rts
:   lda #$FF
    clc
    lda #ERROR::OK
    sta error_code
    rts
@nomatch:
    ; we have to check the next directory entry.
    jsr read_directory_entry
    bcc sfos_d_findnext
    rts

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
    beq @second_half
    cmp #16                 ; do we need to load a new block into the buffer
    beq @next_block
    clc
    rts
@second_half:               ; Once we get to 8 dirents, we need to increment
    inc zptemp1+1           ; the high byte of the pointer into the buffer.
    clc
    rts

@next_block:
    jsr internal_readblock  ; if it was the end of the sector, load the next
    bcc :+
    lda #ERROR::DRIVE_ERROR
    sta error_code
    sec
    rts
:   stz current_dirpos      ; sector and reset current_dirpos.
    lda user_dma+0
    sta zptemp1+0
    lda user_dma+1
    sta zptemp1+1
    rts

; given an fcb pointed by param, find the file and set the DMA address.
sfos_d_open:
    ldy #sfcb::DD
    lda (param),y
    beq :+                  ; if the drive is provided, then switch to that drive
    jsr internal_getsetdrive
    bcc :+                  ; allow for drive error from internal getsetdrive.
    rts
:
    jsr sfos_d_findfirst    ; sets internal dma already
    bcc :+
    rts
    ; set the dma address
:   ldy #sfcb::L1
    lda (param),y
    sta user_dma+0
    pha
    ldy #sfcb::L2
    lda (param),y
    sta user_dma+1
    tax
    pla
    jsr bios_setdma         ; sets the bios dma for sdcard ops.
    ; initialize the Current Record to 0.
    ldy #sfcb::CR
    lda #0
    sta (param),y

    ; save the filesize in fsize 
    ldy #sfcb::S0
    lda (param),y
    sta fsize+0
    ldy #sfcb::S1
    lda (param),y
    sta fsize+1
    ldy #sfcb::S2
    lda (param),y
    sta fsize+2
    lda #ERROR::OK
    sta error_code
    clc
    rts

; param points to FCB that needs to be closed.
sfos_d_close:
    ; do we have a dirty sector to write before we close?
    ldy #sfcb::DS
    lda (param),y
    beq @close

    lda user_dma+0
    ldx user_dma+1
    jsr bios_setdma
    jsr sfos_d_writeseqblock
    bcc @update_fcb
    rts                     ; return with error from write sequential block
@update_fcb:
    ldy #sfcb::SC
    lda (param),y
    inc
    sta (param),y

    ldy #sfcb::S0           ; update the FCB filesize
    lda fsize+0
    sta (param),y
    iny
    lda fsize+1
    sta (param),y
    iny
    lda fsize+2
    sta (param),y

@close:
    jsr compute_drive_index_lba ; lba is set
    ldy #sfcb::FN
    lda (param),y
    lsr     ;/2
    lsr     ;/4
    lsr     ;/8
    lsr     ;/16
    clc                     ; add to lba+0 for sector conaining file dirent
    adc lba+0
    sta lba+0
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    ; now read the index sector into the sfos_buf
    lda #<sfos_buf
    ldx #>sfos_buf
    jsr bios_setdma
    jsr bios_sdread         ; not calling internal_readblock because we don't
    bcs @error              ; want the LBA incremented here.
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
    and #$0F
    cmp #$8                 ; when the filenum is > 80 we must insert
    bcs @upper              ; the fcb into thesecond half of the 512byte sector.
:   lda (param),y           ; copy fcb to lower half of sector
    sta sfos_buf,x
    inx
    iny
    cpy #32
    bne :-
    bra @flush
@upper:                     ; copy fcb to upper half of sector.
:   lda (param),y
    sta sfos_buf+256,x
    inx
    iny
    cpy #32
    bne :-
@flush:
    lda #<sfos_buf          ; there is no internal writeblock like there is an
    ldx #>sfos_buf          ; internal readlbock.  Because this is the only time
    jsr bios_setdma         ; that function is needed.  So it's inlined here.
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    jsr bios_sdwrite
    bcc @exit
@error:
    lda #ERROR::DRIVE_ERROR
    sta error_code
    rts
@exit:
    lda #$FF                ; force drive scan
    jsr login_drive
    lda #ERROR::OK
    sta error_code
    clc
    rts

; param points to FCB containing filename to create.
; Returns updated FCB containing Drive, FN and CR
; Reuses current_dirent to stash the incomming fcb so the filename can be
; extracted and restored over the new FCB found.
sfos_d_make:
    ; stash dirent.
    ldy #31
:
    lda (param),y
    sta temp_fcb,y
    dey
    bpl :-

    jsr sfos_d_findfirst
    bcs :+
    lda #ERROR::FILE_EXISTS
    sta error_code
    sec
    rts
:   ; file does not exist or drive error
    cmp #ERROR::DRIVE_ERROR
    sta error_code
    bne :+
    sec
    rts
:   ldy #sfcb::DD           ; tell find first to return an empty slot
    lda #$E5
    sta (param),y
    jsr sfos_d_findfirst
    bcc @allocate
    cmp #ERROR::END_OF_DIR
    ; BUG: We do nothing with this comparrison.
    sta error_code
    bne :+
    lda #ERROR::DRIVE_FULL
    sta error_code
    sec
    rts
:   lda #ERROR::DRIVE_ERROR
    sta error_code
    sec
    rts
@allocate:
    ; allocate dirent by setting file attribute to 0x40
    lda #$40
    ldy #sfcb::FA
    sta (param),y

    ldy #sfcb::CR
    lda #0
    sta (param),y

    ; fill in details from the current dirent.
    ldy #sfcb::SC
    lda temp_fcb,y
    sta (param),y

    ldy #sfcb::L1
    lda temp_fcb,y
    sta (param),y
    iny
    lda temp_fcb,y
    sta (param),y

    ldy #sfcb::E1
:
    lda temp_fcb,y
    sta (param),y
    iny
    cpy #sfcb::S2 + 1
    bne :-

    ldy #12
:   lda temp_fcb,y
    sta (param),y
    dey
    bne :-
    ldy #sfcb::DS
    lda #0
    sta (param),y
    stz fsize+0
    stz fsize+1
    stz fsize+2
    stz fsize+3
    lda #ERROR::OK
    sta error_code
    clc
    rts

; ----------------------------------------------------------------------------
; ---- SYSTEM / DISK FUNCTIONS -----------------------------------------------
; ----------------------------------------------------------------------------

; also sets zpbufptr for read and write byte operations
sfos_d_setdma:
    lda param + 0
    sta user_dma + 0
    sta zpbufptr + 0
    ldx param + 1
    stx user_dma + 1
    stx zpbufptr + 1
    jmp bios_setdma

; XA is a pointer to the 32bit word containing the LBA address
sfos_d_setlba:
    lda param + 0
    ldx param + 1
    jmp bios_setlba

; These internal read and write block functions assume a previously set LBA and DMA
; and do update the LBA on completion.
internal_readblock:
    lda #<lba
    ldx #>lba
    jsr bios_setlba
    jsr bios_sdread
    bcc :+
    lda #ERROR::DRIVE_ERROR
    sta error_code
    rts
:   inc lba + 0
    rts

; Given the FCB passed in param, the LBA is determined from the DRIVE + CR
; fields and the block is read into the current DMA address.
; On completion, the FCB CR field is updated to the next record.
sfos_d_readseqblock:
    jsr set_fcb_lba
    jsr bios_sdread
    bcs sd_op_fail

    jmp increment_fcb_cr

sd_op_fail:
    lda #ERROR::DRIVE_ERROR
    sta error_code
    rts

sfos_d_writeseqblock:
    jsr set_fcb_lba
    jsr bios_sdwrite
    bcs sd_op_fail
    jmp increment_fcb_cr   ; carry is set if rollover

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

increment_fcb_cr:
    ldy #sfcb::CR
    lda (param),y
    inc
    beq :+                  ; have we gone past the end of MAX FILESIZE
    sta (param),y
    clc
    lda #ERROR::OK
    sta error_code
    rts
:   lda #ERROR::FILE_MAX_REACHED
    sta error_code
    sec
    rts

; input param = FCB
; The first block must have already been read in by the caller.
; Returns the next byte from the buffer.
; When the last buffer is read, stash it, load the next sector into the buffer
; and return the stashed byte.
; Buffer is at the current DMA address.
; pointer to current byte is in zpbufptr
; we need to know if we have read the final byte of the file.
; do this by decrementing the size inside the FCB. When that gets to zero we
; are done.
sfos_d_readseqbyte:
    lda (zpbufptr)          ; get the byte pointed to by zpbufptr
    pha                     ; stash it
    inc zpbufptr+0          ; increment buffer pointer
    bne :+
    inc zpbufptr+1
:   ldx user_dma+1
    inx
    inx
    cpx zpbufptr+1
    bne @return

    lda user_dma+0          ; reset the buffer pointer.  Ready for the next
    sta zpbufptr+0          ; byte
    ldx user_dma+1
    stx zpbufptr+1
    jsr bios_setdma         ; set dma pointer in bios

    jsr sfos_d_readseqblock ; read the new sector
    bcc @return             ; if OKAY carry on, otherwise return with carry set.
    ; reutrn the error from readseqblock - error_code already populated.
    rts
@return:
    ; decrement the remaining size  (24 bit decrement)
    lda fsize+0
    bne @dec_ones
    lda fsize+1
    bne @dec_tens
    lda fsize+2
@dec_hundreds:
    dec fsize+2
@dec_tens:
    dec fsize+1
@dec_ones:
    dec fsize+0
    lda fsize+0             ; 24bit check for zero
    ora fsize+1
    ora fsize+2
    beq @exit
@ok:                        ; Return the value not the ERROR CODE.
    pla                     ; retreive the stashed byte
    clc                     ; return okay.
    rts
@exit:                      ; we have reached zero bytes in the FCB
    sec
    lda #ERROR::FILE_EOF    ; it's not an error so populate error_code with OK
    sta error_code
    pla                     ; We still return the stashed byte.
    rts                     ; caller has to check error_code

; input param = FCB requires buffer DMA to be pre-assigned.
; wirtes to the buffer, fills up and when full, writes the buffer to disk.
; errors out when file max is reached.
sfos_d_writeseqbyte:
    lda rega
    sta (zpbufptr)
    ldy #sfcb::DS
    lda #1
    sta (param),y
    inc zpbufptr + 0
    bne @incsize
    inc zpbufptr + 1
    lda zpbufptr + 1
    cmp #>sfos_buf_end      ; XXX: this is NOT what was implied by the call to setdma!!!!
    bne @incsize

    lda user_dma+0          ; reset the buffer pointer.  Ready for the next
    sta zpbufptr+0          ; byte
    ldx user_dma+1
    stx zpbufptr+1
    jsr bios_setdma         ; set dma pointer in bios

    jsr sfos_d_writeseqblock

    ldy #sfcb::SC
    lda (param),y
    inc
    sta (param),y
    ldy #sfcb::DS
    lda #0
    sta (param),y 
    jsr clear_internal_buffer   ; XXX : also NOT what was implied by the call to setdma!!!
@incsize:
    clc
    lda fsize + 0
    adc #1
    sta fsize + 0  
    lda fsize + 1
    adc #0
    sta fsize + 1
    lda fsize + 2
    adc #0
    sta fsize + 2
@exit:
    lda $FF
    clc
    rts

; DMA is set already, LBA is set already, do not increment LBA
; Convert carry to clear on success, set on failure
sfos_d_writerawblock:
    jmp bios_sdwrite

sfos_d_readrawblock:
    jmp bios_sdread

; given the number of pages in A, set tpa to first free block
; of ram.  - this will be called by sfcp when it's done loading
; an application into the TPA.  It will pass in the pages used.
sfos_s_settpa:
    lda param+0
    sta tpa
    clc
    rts

; return the tpa in pages.
sfos_s_gettpa:
    lda tpa
    ldx #0
    clc
    rts

; sets the dma to the sfos_buf
internal_setdma:
    lda #<sfos_buf
    sta user_dma + 0
    sta zpbufptr + 0
    ldx #>sfos_buf
    stx user_dma + 1
    stx zpbufptr + 1
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
; ----------------------------------------------------------------------------
; ---- HELPER FUNCTIONS ------------------------------------------------------
; ----------------------------------------------------------------------------

clear_internal_buffer:
    lda #0
    ldy #0
:   sta sfos_buf+0,y
    iny
    bne :-
:   sta sfos_buf+256,y
    iny
    bne :-
    rts

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
    sfos_buf_end:
    drive:          .res 1
    current_filenum:.res 1
    current_dirent: .res 32
    current_dirpos: .res 1
    drvtbl:         .res 16
    lba:            .res 4
    cmdlen:         .res 1
    temp_fcb:       .res 32
    fsize:          .res 2
    tpa:            .res 1

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
    .lobytes sfos_d_setlba
    .lobytes sfos_d_readrawblock
    .lobytes sfos_d_writerawblock
    .lobytes sfos_s_settpa
    .lobytes sfos_s_gettpa
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
    .hibytes sfos_d_setlba
    .hibytes sfos_d_readrawblock
    .hibytes sfos_d_writerawblock
    .hibytes sfos_s_settpa
    .hibytes sfos_s_gettpa

banner:             .byte "6502-Retro! (SFOS)", 13, 10, 0
str_unimplimented:  .byte 13, 10, "!!! UNIMPLIMENTED !!!", 13, 10, 0
str_badfilename:    .byte 13, 10, "BAD FILENAME", 13,10,0
str_COM:            .byte "COM"
str_scanning:       .byte 10,13,"Scanning drive...",10,13,  0
terminators:
                    .byte " =><.:,[]/|"
                    .byte 10,13,127,9,0
terminators_end:
