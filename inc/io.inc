; vim: ft=asm_ca65
IOPAGE          = $BF00  ; Edit this if your IO page is someplace else.

rambankreg      = IOPAGE + $00
rombankreg      = IOPAGE + $01

acia_data       = IOPAGE + $10
acia_status     = IOPAGE + $11
acia_command    = IOPAGE + $12
acia_control    = IOPAGE + $13

via_portb       = IOPAGE + $20
via_porta       = IOPAGE + $21
via_ddrb        = IOPAGE + $22
via_ddra        = IOPAGE + $23
via_t1cl        = IOPAGE + $24
via_t1ch        = IOPAGE + $25
via_t1ll        = IOPAGE + $26
via_t1lh        = IOPAGE + $27
via_t2cl        = IOPAGE + $28
via_t2ch        = IOPAGE + $29
via_sr          = IOPAGE + $2A
via_acr         = IOPAGE + $2B
via_pcr         = IOPAGE + $2C
via_ifr         = IOPAGE + $2D
via_ier         = IOPAGE + $2E

vdp_ram         = IOPAGE + $30
vdp_reg         = IOPAGE + $31

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
