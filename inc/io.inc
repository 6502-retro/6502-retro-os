; vim: ft=asm_ca65
IOPAGE          = $BF00  ; Edit this if your IO page is someplace else.

IOBANK          = IOPAGE + $00
IOACIA          = IOPAGE + $10
IOVIA           = IOPAGE + $20
IOVDP           = IOPAGE + $30


rambankreg      = IOBANK + $0
rombankreg      = IOBANK + $1

acia_data       = IOACIA + $0
acia_status     = IOACIA + $1
acia_command    = IOACIA + $2
acia_control    = IOACIA + $3

via_portb       = IOVIA + $0
via_porta       = IOVIA + $1
via_ddrb        = IOVIA + $2
via_ddra        = IOVIA + $3
via_t1cl        = IOVIA + $4
via_t1ch        = IOVIA + $5
via_t1ll        = IOVIA + $6
via_t1lh        = IOVIA + $7
via_t2cl        = IOVIA + $8
via_t2ch        = IOVIA + $9
via_sr          = IOVIA + $A
via_acr         = IOVIA + $B
via_pcr         = IOVIA + $C
via_ifr         = IOVIA + $D
via_ier         = IOVIA + $E

vdp_ram         = IOVDP + $0
vdp_reg         = IOVDP + $1

SD_SCK          = 1 << 0  ;%00000001
SD_CS           = 1 << 1  ;%00000010
SN_WE           = 1 << 2  ;%00000100
SN_READY        = 1 << 3  ;%00001000
ROMSW           = 1 << 6  ;%01000000
SD_MOSI         = 1 << 7  ;%10000000

LED_ON          = 1 << 4  ; %00010000 ; ORA
LED_OFF         = !LED_ON ; %11101111 ; AND
BUTTON          = 1 << 5  ; %00100000 ; MASK
ROM_SWITCH_ON   = ROMSW   ; %01000000 ; ORA
ROM_SWITCH_OFF  = !ROMSW  ; %10111111 ; AND
