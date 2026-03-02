; vim: set ft=asm_ca65:
; #############################################################################
; This driver is based heavily on the work done by John Winans on the Z80-Retro!
; project - https://github.com/z80-retro/2063-z80-cpm/lib/sdcard.asm
;
; I have ported that code to here and optimised and changed it where appropriate
; for the 65C02. - David Latham - 02/2026
; #############################################################################
.include "io.inc"
.autoimport

.export sdcard_init, sdcard_read_sector, sdcard_write_sector, sector_lba

.enum sd_error
SD_OK                               ; 0
SD_NOT_IDLE                         ; 1
SD_R1_TIMEOUT                       ; 2
SD_CMD0_NOT_OK                      ; 3
SD_CMD8_NOT_OK                      ; 4
SD_ACMD41_NOT_OK                    ; 5
SD_CMD58_NOT_OK                     ; 6
SD_CMD17_R1_NOT_OK                  ; 7
SD_CMD17_DATA_TOKEN_TIMEOUT         ; 8
SD_CMD17_INVALID_RESP_TOKEN         ; 9
SD_CMD24_R1_NOT_OK                  ; 10
SD_CMD24_COMPLETION_STATUS_TIMEOUT  ; 11
SD_CMD24_COMPLETION_STATUS_NOT_5    ; 12
.endenum

; TODO: INCLUDE OTHER SPI CS LINES IN V4.3
.macro deselect
lda     via_porta
and     #(LED|SD_CS|SPI_CS2|SPI_CS3|SD_MOSI|SN_WE)      ; SD_CS is high
sta     via_porta
.endmacro

; TODO: INCLUDE OTHER SPI CS LINES IN V4.3
.macro select
  lda     via_porta
  and     #(LED|SPI_CS2|SPI_CS3|SD_MOSI|SN_WE)          ; SD_CS is low
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

sd_cmd_start:
  jsr spi_read  ; 8 clocks without selecting SDCS
  select
  ; wait in case busy
   ldx #$80
 @loop:
   jsr spi_read
   cmp #$ff
   beq @done
   dex
   bne @loop
   lda #sd_error::SD_NOT_IDLE
   sec           ; carry set on error.
   rts
 @done:
  clc           ; carry clear if OK
  rts

sd_cmd_stop:
  pha           ; we save A in case we need it after cmd_stop
  jsr spi_read  ; 8 clocks with SDCS selected
  deselect
  jsr spi_read  ; 16 clocks without SDCS selected
  jsr spi_read
  pla           ; restore A
  rts

sd_send_cmd:
  ; Send the 6 cmdbuf bytes.  CMD followed by the 32 bit paramater in 
  ; BIG ENDIAN format, followed by the CRC
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
  ldx #$f0    ; we will try 240 times
@loop:
  jsr spi_read
.if DEBUG=1
  pha
  lda #'R'
  jsr acia_putc
  pla
  pha
  jsr bios_prbyte
  pla
.endif
  bit #$80
  beq @done
  dex
  bne @loop
  lda #sd_error::SD_R1_TIMEOUT
  sec
  rts
@done:
  clc
  rts       ; r1 result in A

; sends a command and reads the r1 response
sd_cmd_r1:
  jsr sd_cmd_start    ; fail if sdcard not idle
  bcc :+
  jmp error
: jsr sd_send_cmd
  jsr sd_read_r1      ; fail if r1 timeout
  bcc :+
  jmp error
: jsr sd_cmd_stop     ; stop preserves A
  rts                 ; result of R1 in A

sd_read_r7:           ; similar to R1 except we read in 5 bytes response
  jsr sd_read_r1      ; and save it into the sd_cmd_result variable
  bcc :+
  jmp error           ; r1 timeout.
: sta sd_cmd_result + 0
  jsr spi_read
  sta sd_cmd_result + 1
  jsr spi_read
  sta sd_cmd_result + 2
  jsr spi_read
  sta sd_cmd_result + 3
  jsr spi_read
  sta sd_cmd_result + 4
  rts

; sends the command and reads the r7 response.
; r3 and r7 responses are the same format.
sd_cmd_r7:
  jsr sd_cmd_start    ; fail if not idle
  bcc :+
  jmp error
: jsr sd_send_cmd
  jsr sd_read_r7      ; fail if timeout on the R1 part of read_r7
  bcc :+
  jmp error
: jsr sd_cmd_stop     ; A is preserved.
  rts                 ; returns with result of last byte of R7 in A


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
  sec                 ; carry remains set on error and return to caller
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
.if DEBUG=1
  lda #'.'
  jsr acia_putc
  lda #0
  jsr bios_prbyte
.endif

  lda #(0|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$95
  sta cmd_crc
  jmp sd_cmd_r1   ; tail call result of R1 response in A

sd_cmd8:
.if DEBUG=1
  lda #'.'
  jsr acia_putc
  lda #$08
  jsr bios_prbyte
.endif

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
  jmp sd_cmd_r7   ; tail call - result of last byte of R7 response in A

sd_cmd58:
.if DEBUG=1
  lda #'.'
  jsr acia_putc
  lda #$58
  jsr bios_prbyte
.endif

  lda #(58|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$01
  sta cmd_crc     ; sd_cmd_r7 is same as r3 so we use it instead.
  jmp sd_cmd_r7   ; tail call - result of last byte of R7 response in A

sd_cmd55:
.if DEBUG=1
  lda #'.'
  jsr acia_putc
  lda #$55
  jsr bios_prbyte
.endif

  lda #(55|$40)
  sta cmd_idx
  lda #0
  sta cmd_arg+3
  sta cmd_arg+2
  sta cmd_arg+1
  sta cmd_arg+0
  lda #$01
  sta cmd_crc
  jmp sd_cmd_r1   ; tail call - result of R1 response in A

sd_acmd41:        ; application command ("a" command)
  jsr sd_cmd55    ; all "a" commands must follow a cmd55

.if DEBUG=1
  lda #'.'
  jsr acia_putc
  lda #$41
  jsr bios_prbyte
.endif

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
  jmp sd_cmd_r1   ; tail call - result of R1 response in A

; external function to initialise the SDCard using the above low level
; routnes.
sdcard_init:
  php
  sei
  ; init shift register and port b for SPI use
  ; SR shift in, External clock on CB1
  lda #%00001100
  sta via_acr

.if DEBUG=1
  lda #'B'
  jsr acia_putc
.endif
  jsr sd_boot           ; at least 74 clock cycles with SD_CS HIGH
  jsr sd_cmd0           ; CMD0
  cmp #$01              ; CMD0 must return a 0x01.
  beq boot_cmd8
  lda #sd_error::SD_CMD0_NOT_OK
  jmp error

boot_cmd8:
  jsr sd_cmd8
  lda sd_cmd_result+0
  cmp #$01
  beq boot_acmd41
  lda #sd_error::SD_CMD8_NOT_OK
  jmp error

boot_acmd41:
  ldx #$80            ; attempt 128 times.
ac41_loop:
  jsr sd_acmd41       ; ACMD41 (includes CMD55)
  ; If the R1 response for acmd41 was TIMEOUT, then we already in error.
  beq ac41_done       ; received $00 from ACMD41 - OKAY

  phx                 ; else save the loop counter
  ldx #$00            ; delay for 0x1000 loops
  ldy #$01
ac41_dly_loop:
  dex
  bne ac41_dly_loop
  dey
  bne ac41_dly_loop
  plx                 ; restore the loop counter
  dex                 ; decrement loop counter
  bne ac41_loop       ; if not zero - try ACMD41 again
  lda #sd_error::SD_ACMD41_NOT_OK
  jmp error

ac41_done:
  jsr sd_cmd58        ; CMD58
  lda sd_cmd_result + 1
  and #$40
  bne boot_hcxc_ok
  lda #sd_error::SD_CMD58_NOT_OK
  jmp error
boot_hcxc_ok:
.if DEBUG=1
  lda #'/'            ; something to show it worked.
  jsr acia_putc
.endif
  deselect
  lda #sd_error::SD_OK
  plp
  clc                 ; CLEAR CARRY MEANS SUCCESS
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
  lda #(17|$40)
  sta cmd_idx
  lda #$01
  sta cmd_crc
  jsr sd_cmd_start
  bcc :+
  jmp error
: jsr sd_send_cmd
  jsr sd_read_r1
  bcc :+
  jmp error
: beq @sd_cmd17_r1ok
  lda #sd_error::SD_CMD17_R1_NOT_OK
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
  lda #sd_error::SD_CMD17_DATA_TOKEN_TIMEOUT
  jmp error
@sd_cmd17_token:
  cmp #$FE
  beq @sd_cmd17_tokok
  lda #sd_error::SD_CMD17_INVALID_RESP_TOKEN
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
  lda #0  ; return 0 for success
  clc     ; with carry set in case someone wants that instead
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
  bcc :+
  jmp error
: jsr sd_send_cmd
  jsr sd_read_r1
  bcc :+
  jmp error
: beq @sd_cmd24_r1ok
  lda #sd_error::SD_CMD24_R1_NOT_OK
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
  lda #sd_error::SD_CMD24_COMPLETION_STATUS_TIMEOUT
  jmp error
@sd_cmd24_drc:
  ; Make sure the response is 0bxxx00101 else is an error
  and #$1f
  cmp #$05
  beq @sd_cmd24_ok
  lda #sd_error::SD_CMD24_COMPLETION_STATUS_NOT_5
  jmp error
@sd_cmd24_ok:
  jsr sd_cmd_stop
  lda #0; return 0 for success
  clc   ; with carry clear in case someone wants that instead
  rts
