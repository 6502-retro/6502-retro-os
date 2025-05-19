; vim: ft=asm_ca65
;-----------------------------------------------------------------------------
; SDCARD Routines adapted from: 
;       https://github.com/X16Community/x16-rom/blob/master/fat32/sdcard.s
;       Copyright (C) 2020 Frank van den Hoef
;
; SPI Routines from: 
;       https://github.com/Steckschwein/code/blob/master/steckos/libsrc/spi/spi_rw_byte.s
;       Copyright (c) 2018 Thomas Woinke, Marko Lauke, www.steckschwein.de
;-----------------------------------------------------------------------------
.include "io.inc"
.autoimport
.globalzp bdma_ptr
.export sector_lba, sdcard_read_sector, sdcard_write_sector

.macro deselect
        lda     #(SD_CS|SD_MOSI|SN_WE)        ; deselect sdcard
        sta     via_porta
.endmacro

.macro select
        lda     #(SD_MOSI|SN_WE)
        sta     via_porta
.endmacro

cmd_idx = sdcard_param
cmd_arg = sdcard_param + 1
cmd_crc = sdcard_param + 5


        .bss
sdcard_param:
        .res 1
sector_lba:
        .res 4 ; dword (part of sdcard_param) - LBA of sector to read/write
        .res 1

timeout_cnt:    .byte 0
spi_sr:         .byte 0
        .code

;-----------------------------------------------------------------------------
; wait ready
;
; clobbers: A,X,Y
;-----------------------------------------------------------------------------
wait_ready:
        lda #$F0
        sta timeout_cnt

@1:     ldx #0          ; 2
@2:     ldy #0          ; 2
@3:     jsr spi_read    ; 22
        cmp #$FF        ; 2
        beq @done       ; 2 + 1
        dey             ; 2
        bne @3          ; 2 + 1
        dex             ; 2
        bne @2          ; 2 + 1
        dec timeout_cnt
        bne @1

        ; Total timeout: ~508 ms @ 8MHz

        ; Timeout error
        sec 
        rts

@done:  clc
        rts

; waits for sdcard to return anything other than FF
wait_result:
        jsr spi_read
        cmp #$FF
        beq wait_result
        rts

; read a byte over SPI - result in A
spi_read:
        pha
        select
        pla
        lda #$ff
        phx
        phy
        jsr spi_rw_byte
        ply
        plx
        pha
        deselect
        pla
        rts


; write a byte (A) via SPI
spi_write:
        pha
        select
        pla
        phx
        phy
        jsr spi_rw_byte
        ply
        plx
        pha
        deselect
        pla
        rts

spi_rw_byte:
        sta spi_sr

        ldx #$08

        lda via_porta
        and #$fe

        asl
        tay

@l:     rol spi_sr
        tya
        ror

        sta via_porta
        inc via_porta
        sta via_porta

        dex
        bne @l

        lda via_sr
        rts
;-----------------------------------------------------------------------------
; send_cmd - Send cmdbuf
;
; first byte of result in A, clobbers: Y
;-----------------------------------------------------------------------------
send_cmd:
        jsr sdcmd_start
        ; Send the 6 cmdbuf bytes
        lda cmd_idx
        jsr spi_write
        lda cmd_arg + 3
        jsr spi_write
        lda cmd_arg + 2
        jsr spi_write
        lda cmd_arg + 1
        jsr spi_write
        lda cmd_arg + 0
        jsr spi_write
        lda cmd_crc
        jsr spi_write

        ; Wait for response
        ldy #(10 + 1)
@1:     dey
        beq @error      ; Out of retries
        jsr spi_read
        cmp #$ff
        beq @1

        ; Success
        jsr sdcmd_end
        clc
        rts

@error: ; Error
        jsr sdcmd_end
        sec
        rts

sdcmd_start:
        php
        pha
        phx
        jsr sdcmd_nothingbyte
        jsr sdcmd_nothingbyte
        lda #$ff
        jsr spi_write
        plx
        pla
        plp
        rts

sdcmd_nothingbyte:
        ldx     #8
@loop:
        lda #(SD_MOSI|SD_CS|SN_WE)
        sta via_porta
        lda #(SD_SCK|SD_MOSI|SD_CS|SN_WE)
        sta via_porta
        dex
        bne @loop
        rts

sdcmd_end:
        php
        pha
        phx
        lda #$ff
        jsr spi_write
        jsr sdcmd_nothingbyte
        jsr sdcmd_nothingbyte
        lda #(SD_CS|SD_MOSI|SN_WE)
        sta via_porta
        plx
        pla
        plp
        rts

;-----------------------------------------------------------------------------
; sdcard_read_sector
; Set sector_lba prior to calling this function.
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_read_sector:
        jsr sdcmd_start
        ; Send READ_SINGLE_BLOCK command
        lda #($40 | 17)
        sta cmd_idx
        lda #1
        sta cmd_crc
        jsr sdcmd_start
        jsr send_cmd

        ; Wait for start of data packet
        ldx #0
@1:     ldy #0
@2:     jsr spi_read
        cmp #$FE
        beq @start
        dey
        bne @2
        dex
        bne @1

        ; Timeout error
        jsr sdcmd_end
        deselect
        sec
        rts

@start: ; Read 512 bytes of sector data
        ldx #$FF
        ldy #0
@3:     jsr spi_read
        sta (bdma_ptr), y
        iny
        bne @3
        inc bdma_ptr + 1
        ; Y already 0 at this point
@5:     jsr spi_read
        sta (bdma_ptr), y
        iny
        bne @5
        dec bdma_ptr + 1

        ; Read CRC bytes
        jsr spi_read
        jsr spi_read

        jsr sdcmd_end
        ; Success
        deselect
        clc
        rts

;-----------------------------------------------------------------------------
; sdcard_write_sector
; Set sector_lba prior to calling this function.
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_write_sector:
        jsr sdcmd_start
        ; Send WRITE_BLOCK command
        lda #($40 | 24)
        sta cmd_idx
        lda #1
        sta cmd_crc
        jsr send_cmd
        cmp #00
        bne @error

        ; Wait for card to be ready
        jsr wait_ready
        bcs @error

        ; Send start of data token
        lda #$FE
        jsr spi_write


        ; Send 512 bytes of sector data
        ldy #0
@1:     lda (bdma_ptr), y            ; 4
        jsr spi_write
        iny                             ; 2
        bne @1                          ; 2 + 1
        inc bdma_ptr + 1
        ; Y already 0 at this point
@2:     lda (bdma_ptr), y      ; 4
        jsr spi_write
        iny                             ; 2
        bne @2                          ; 2 + 1

        dec bdma_ptr + 1
        ; Dummy CRC
        lda #0
        jsr spi_write
        jsr spi_write

        ; wait for data response
        jsr wait_result
        and #$1f
        cmp #$05
        bne @error

        ; wait for it to be idle
        jsr wait_ready
        bcs @error

        ; Success
        jsr sdcmd_end
        deselect
        clc
        rts

@error: ; Error
        jsr sdcmd_end
        deselect
        sec
        rts

