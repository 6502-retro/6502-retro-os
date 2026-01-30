; vim: ft=asm_ca65
IOPAGE          = $BF00  ; Edit this if your IO page is someplace else.

IOBANK          = IOPAGE + $00
IOACIA          = IOPAGE + $10
IOVIA1          = IOPAGE + $20
IOVIA2          = IOPAGE + $30
IOVDP           = IOPAGE + $40


rambankreg      = IOBANK + $0
rombankreg      = IOBANK + $1

acia_data       = IOACIA + $0
acia_status     = IOACIA + $1
acia_command    = IOACIA + $2
acia_control    = IOACIA + $3

via_portb       = IOVIA1 + $0
via_porta       = IOVIA1 + $1
via_ddrb        = IOVIA1 + $2
via_ddra        = IOVIA1 + $3
via_t1cl        = IOVIA1 + $4
via_t1ch        = IOVIA1 + $5
via_t1ll        = IOVIA1 + $6
via_t1lh        = IOVIA1 + $7
via_t2cl        = IOVIA1 + $8
via_t2ch        = IOVIA1 + $9
via_sr          = IOVIA1 + $A
via_acr         = IOVIA1 + $B
via_pcr         = IOVIA1 + $C
via_ifr         = IOVIA1 + $D
via_ier         = IOVIA1 + $E

vdp_ram         = IOVDP  + $0
vdp_reg         = IOVDP  + $1

; VIA1 PORTA PINS
SD_SCK          = 1 << 0
SD_CS           = 1 << 1
SPI_CS2         = 1 << 2
SPI_CS3         = 1 << 3
LED             = 1 << 4
SN_WE           = 1 << 5
SN_READY        = 1 << 6
SD_MOSI         = 1 << 7

LED_ON          = LED
LED_OFF         = !LED

; RAM BANK LATCH PINS
ROM_SEL         = 1 << 6
ROMSW           = 1 << 7

ROM_SWITCH_ON   = ROMSW   ; ORA
ROM_SWITCH_OFF  = !ROMSW  ; AND
