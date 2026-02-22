; vim: set ft=asm_ca65:

.include "io.inc"

.autoimport

.export spi_read, spi_write, spi_rw_byte

.bss
spi_sr: .byte 0

.code

; read a byte over SPI - result in A
.proc spi_read
  phx
  phy
  lda #$ff
  jsr spi_rw_byte
  ply
  plx
  rts
.endproc

; write a byte (A) via SPI
.proc  spi_write
  phx
  phy
  jsr spi_rw_byte
  ply
  plx
  rts
.endproc

.proc spi_rw_byte
  sta spi_sr

  ldx #$08

  lda via_porta
  and #$fe

  asl
  tay

@l:
  rol spi_sr
  tya
  ror

  sta via_porta
  inc via_porta
  sta via_porta

  dex
  bne @l

  lda via_sr
  rts
.endproc
