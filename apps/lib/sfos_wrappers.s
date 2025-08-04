; vim: ft=asm_ca65 ts=4 sw=4
.include "bios.inc"
.export _sfos_error_code    := bios_error_code
.export _sfos_cmdline       := $300
.export _sfos_cmdoffset     := $3C0
.export _sfos_buf           := $400
.export _sfos_buf_end       := $600

.export _sfos_entry         := sfos_entry
.export _bios_cboot         := bios_cboot
.export _bios_wboot         := bios_wboot
.export _bios_conout        := bios_conout
.export _bios_conin         := bios_conin
.export _bios_const         := bios_const
.export _bios_puts          := bios_puts
.export _bios_prbyte        := bios_prbyte

.export _bios_setdma        := bios_setdma
.export _bios_setlba        := bios_setlba
.export _bios_sdread        := bios_sdread
.export _bios_sdwrite       := bios_sdwrite

.export _bios_sn_beep       := bios_sn_beep
.export _bios_sn_start      := bios_sn_start
.export _bios_sn_silence    := bios_sn_silence
.export _bios_sn_stop       := bios_sn_stop
.export _bios_sn_send       := bios_sn_send
.export _bios_led_on        := bios_led_on
.export _bios_led_off       := bios_led_off
.export _bios_get_button    := bios_get_button
.export _notectr            := notectr
