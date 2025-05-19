; vim: ft=asm_ca65
rambankreg      = $BF00
rombankreg      = $BF01

acia_data       = $BF10
acia_status     = $BF11
acia_command    = $BF12
acia_control    = $BF13

via_portb       = $BF20
via_porta       = $BF21
via_ddrb        = $BF22
via_ddra        = $BF23
via_t1cl        = $BF24
via_t1ch        = $BF25
via_t1ll        = $BF26
via_t1lh        = $BF27
via_t2cl        = $BF28
via_t2ch        = $BF29
via_sr		= $BF2A
via_acr         = $BF2B
via_pcr         = $BF2C
via_ifr         = $BF2D
via_ier         = $BF2E

vdp_ram         = $BF30
vdp_reg         = $BF31

SD_SCK          = %00000001
SD_CS           = %00000010
SN_WE           = %00000100
SN_READY        = %00001000
ROMSW           = %01000000
SD_MOSI         = %10000000
LED_ON          = %00010000 ; ORA
LED_OFF         = %11101111 ; AND
BUTTON          = %00100000 ; MASK
ROM_SWITCH_ON   = %01000000 ; ORA
ROM_SWITCH_OFF  = %10111111 ; AND
