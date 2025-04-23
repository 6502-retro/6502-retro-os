; vim: ft=asm_ca65 ts=4 sw=4
.include "asminc.inc"
.export _sfos_error_code    := ERROR_CODE
.export _sfos_cmdline       := $300
.export _sfos_cmdoffset     := $3C0
.export _sfos_buf           := $400
.export _sfos_buf_end       := $600
.export _ticks              := TICKS

.export _dispatch           := $200
.export _bios_boot          := $203
.export _bios_wboot         := $206
.export _bios_conout        := $209
.export _bios_conin         := $20c
.export _bios_const         := $20f
.export _bios_puts          := $212
.export _bios_prbyte        := $215

.export _bios_setdma        := $218
.export _bios_setlba        := $21b
.export _bios_sdread        := $21e
.export _bios_sdwrite       := $221

.export _sn_beep            := $224
.export _sn_start           := $227
.export _sn_silence         := $22a
.export _sn_stop            := $22d
.export _sn_send            := $230
.export _led_on             := $233
.export _led_off            := $236
.export _get_button         := $239
