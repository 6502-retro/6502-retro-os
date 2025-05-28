; vim: ft=asm_ca65
sfos_entry      = $200
bios_cboot      = $203
bios_wboot      = $206
bios_conout     = $209
bios_conin      = $20c
bios_const      = $20f
bios_puts       = $212
bios_prbyte     = $215

bios_setdma     = $218
bios_setlba     = $21b
bios_sdread     = $21e
bios_sdwrite    = $221

bios_sn_beep    = $224
bios_sn_start   = $227
bios_sn_silence = $22a
bios_sn_stop    = $22d
bios_sn_send    = $230
bios_led_on     = $233
bios_led_off    = $236
bios_get_button = $239

bios_error_code = $23c

bios_rstfar     = $23d

bios_rega       = $24d
bios_regx       = bios_rega   + 1
bios_regy       = bios_regx   + 1

bios_userirq_vec = $250
bios_usernmi_vec = $252
bios_delay_ms   = $254

