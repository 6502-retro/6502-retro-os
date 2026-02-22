; vim: set ft=asm_ca65:

.include "io.inc"
.autoimport

.export sdcard_init, sdcard_read_sector, sdcard_write_sector, sector_lba

SD_CMD17_R1_NOTOK                 = 1
SD_CMD17_DATA_TOKEN_TIMEOUT       = 2
SD_CMD17_INVALID_RESP_TOKEN       = 3
SD_CMD24_R1_NOTOK                 = 4
SD_CMD24_COMPLETION_STATUS_TIMEOUT= 5
SD_CMD24_COMPLETION_STATUS_NOT_5  = 6

.macro deselect
lda     #(SD_CS|SPI_CS2|SPI_CS3|SD_MOSI|SN_WE)        ; deselect sdcard
sta     via_porta
.endmacro

.macro select
  lda     #(SPI_CS2|SPI_CS3|SD_MOSI|SN_WE)
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
  .res 1 ; crc

sd_cmd_result:  ; to hold multibyte responses from the sdcard.
  .res 6

timeout_cnt:
  .byte 0
spi_sr:
  .byte 0

.globalzp bdma_ptr

.code

; TODO: INCLUDE OTHER SPI CS LINES
sd_cmd_start:
  jsr spi_read  ; 8 clocks without selecting SDCS
  select
  ; wait in case busy
  ldx #0
  @loop:
  jsr spi_read
  cmp #$ff
  beq @done
  dex
  bne @loop
@done:
   rts

; TODO: INCLUDE OTHER SPI CS LINES
sd_cmd_stop:
  pha
  jsr spi_read  ; 8 clocks with SDCS selected
  deselect
  jsr spi_read  ; 16 clocks without SDCS selected
  jsr spi_read
  pla
  rts

sd_send_cmd:
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
  rts

sd_read_r1:
  ldx #$f0
@loop:
  jsr spi_read
  bit #$80  ; if MSB=0 then we have received our response.
  beq @done
  dex
  bne @loop
@done:
  rts       ; r1 result in A

sd_cmd_r1:
  jsr sd_cmd_start
  jsr sd_send_cmd
  jsr sd_read_r1
  jsr sd_cmd_stop
  rts

sd_read_r7:
  jsr sd_read_r1
  sta sd_cmd_result + 0
  jsr spi_read
  sta sd_cmd_result + 1
  jsr spi_read
  sta sd_cmd_result + 2
  jsr spi_read
  sta sd_cmd_result + 3
  jsr spi_read
  sta sd_cmd_result + 4
  rts

sd_cmd_r7:
  jsr sd_cmd_start
  jsr sd_send_cmd
  jsr sd_read_r7
  jsr sd_cmd_stop
  rts


error:
.if DEBUG=1
  pha
  lda #'E'
  jsr acia_putc
  pla
  pha
  jsr bios_prbyte
  pla
.endif
  pha
  jsr sd_cmd_stop
  deselect
  pla
  plp
  sec
  rts


; send 80 clock cycles with SDCS deselected
sd_boot:
  deselect
  ldx #0
@clockloop:
  eor #SD_SCK
  sta via_porta
  dex
  bne @clockloop
  rts

sd_cmd0:
  lda #(0|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$95
  sta cmd_crc
  jmp sd_cmd_r1

sd_cmd8:
  lda #(8|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  lda #$01
  sta cmd_arg+1
  lda #$aa
  sta cmd_arg+0
  lda #$87
  sta cmd_crc
  jmp sd_cmd_r7

sd_cmd58:
  lda #(58|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$01
  sta cmd_crc
  jmp sd_cmd_r7   ; same as sd_cmd_r3

sd_cmd55:
  lda #(55|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$01
  sta cmd_crc
  jmp sd_cmd_r1

sd_acmd41:
  jsr sd_cmd55    ; all "a" commands must follow a cmd55

  lda #(41|$40)
  sta cmd_idx
  lda #$40
  sta cmd_arg+3
  lda #0
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$01
  sta cmd_crc
  jmp sd_cmd_r1

; A hack to just supply clock for a while.
sd_clk_delay:
  ldx #$80
@loop:
  jsr spi_read
  dex
  bne @loop
  rts

sdcard_init:
  php
  sei
  ; init shift register and port b for SPI use
  ; SR shift in, External clock on CB1
  lda #%00001100
  sta via_acr
; Beginning of SDCARD INITIALISATION
  jsr sd_boot
  jsr sd_cmd0           ; CMD0
  cmp #$01
  beq boot_sd_1
  lda #1
  jmp error

boot_sd_1:
.if DEBUG=1
  lda #'a'
  jsr acia_putc
.endif

  jsr sd_cmd8           ; CMD8
  lda sd_cmd_result+0
  cmp #$01
  beq boot_sd_2
  lda #2
  jmp error
boot_sd_2:
.if DEBUG=1
  lda #'b'
  jsr acia_putc
.endif
  ldx #$80
ac41_loop:
  jsr sd_acmd41       ; ACMD41 (includes CMD55)
  beq ac41_done
  phx
  ldx #0
  ldy #16
ac41_dly_loop:
  dey
  bne ac41_dly_loop
  dex
  bne ac41_dly_loop
  plx
  dex
  bne ac41_loop
  lda #3
  jmp error
ac41_done:
.if DEBUG=1
  lda #'c'
  jsr acia_putc
.endif

  jsr sd_cmd58        ; CMD58
  lda sd_cmd_result + 1
  and #$40
  bne boot_hcxc_ok
  lda #4
  jmp error
boot_hcxc_ok:
  ; END OF SDCARD INITIALISATION
.if DEBUG=1
  lda #'d'
  jsr acia_putc
.endif
  deselect
  lda #0
  plp
  sec
  rts


; CMD17 (READ_SINGLE_BLOCK)
;
; Read one block given by the 32-bit (little endian) number in
; sector_lba into the address at bdma_ptr
;
; - set SSEL = true
; - send command
; - read for CMD ACK
; - wait for 'data token'
; - read data block
; - read data CRC
; - set SSEL = false
sdcard_read_sector:
.if DEBUG=1
  lda cmd_arg+3
  jsr bios_prbyte
  lda cmd_arg+2
  jsr bios_prbyte
  lda cmd_arg+1
  jsr bios_prbyte
  lda cmd_arg+0
  jsr bios_prbyte
  lda #10
  jsr acia_putc
  lda #13
  jsr acia_putc
.endif
  lda #(17|$40)
  sta cmd_idx
  lda #$01
  sta cmd_crc
  jsr sd_cmd_start
  jsr sd_send_cmd
  jsr sd_read_r1
  beq @sd_cmd17_r1ok
  lda #SD_CMD17_R1_NOTOK
  jmp error
@sd_cmd17_r1ok:
  ; wait for data token
  ldy #$10
  ldx #$00
@wait_data_token_loop:
  jsr spi_read
  cmp #$ff
  bne @sd_cmd17_token
  dex
  bne @wait_data_token_loop
  dey
  bne @wait_data_token_loop
  lda #SD_CMD17_DATA_TOKEN_TIMEOUT
  jmp error
@sd_cmd17_token:
  cmp #$FE
  beq @sd_cmd17_tokok
  lda #SD_CMD17_INVALID_RESP_TOKEN
  jmp error
@sd_cmd17_tokok:
  ; read 512 bytes into buffer
  ldx #$FF
  ldy #0
@readloop1:
  jsr spi_read
  sta (bdma_ptr), y
  iny
  bne @readloop1
  inc bdma_ptr + 1
  ; Y already 0 at this point
@readloop2:
  jsr spi_read
  sta (bdma_ptr), y
  iny
  bne @readloop2
  dec bdma_ptr + 1
  ; read 16 bit crc - ignore it.
  jsr spi_read
  jsr spi_read
  jsr sd_cmd_stop
  lda #0; return 0 for success
  clc   ; with carry set in case someone wants that instead
  ; NOTE:: THIS IS DIFFERENT TO HOW THE BOOT LOADER VERSION WORKS
  rts

; CMD24 (READ_SINGLE_BLOCK)
;
; Write one block into the sd card at LBA given by the 32-bit
; (little endian) number in sector_lba into the address from bdma_ptr
;; - set SSEL = true
; - send command
; - read for CMD ACK
; - send 'data token'
; - write data block
; - wait while busy
; - read 'data response token' (must be 0bxxx00101 else errors) (see SD spec: 7.3.3.1, p281)
; - set SSEL = false
;
; - set SSEL = true
; - wait while busy     Wait for the write operation to complete.
; - set SSEL = false
sdcard_write_sector:
  lda #(24|$40)
  sta cmd_idx
  lda #$01
  sta cmd_crc
  jsr sd_cmd_start
  jsr sd_send_cmd
  jsr sd_read_r1
  beq @sd_cmd24_r1ok
  lda #SD_CMD24_R1_NOTOK
  jmp error
@sd_cmd24_r1ok:
  ; give the SD card an extra 8 clocks before we send the start token
  jsr spi_read  ; Ignore response
  lda #$fe      ; send start token 0xFE
  jsr spi_write
  ; ready to send 512 bytes of data
  ldy #0
@writeloop1:
  lda (bdma_ptr), y
  jsr spi_write
  iny
  bne @writeloop1
  inc bdma_ptr + 1
  ; Y already 0 at this point
@writeloop2:
  lda (bdma_ptr), y
  jsr spi_write
  iny
  bne @writeloop2
  dec bdma_ptr + 1
; wait a potentially long time for the write to complete
  ldx #$00
  ldy #$f0
@sd_cmd24_wdr:
  jsr spi_read
  cmp #$ff
  bne @sd_cmd24_drc
  dex
  bne @sd_cmd24_wdr
  dey
  bne @sd_cmd24_wdr
  lda #SD_CMD24_COMPLETION_STATUS_TIMEOUT
  jmp error
@sd_cmd24_drc:
  ; Make sure the response is 0bxxx00101 else is an error
  and #$1f
  cmp #$05
  beq @sd_cmd24_ok
  lda #SD_CMD24_COMPLETION_STATUS_NOT_5
  jmp error
@sd_cmd24_ok:
  jsr sd_cmd_stop
  lda #0; return 0 for success
  clc; with carry clear in case someone wants that instead
  ; NOTE:: THIS IS DIFFERENT TO HOW THE BOOT LOADER VERSION WORKS
  rts
