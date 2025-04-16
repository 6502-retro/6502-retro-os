; vim: set ft=asm_ca65 et ts=4 sw=4
SFOS        = $200
REBOOT      = SFOS      + 3
WBOOT       = REBOOT    + 3
CONOUT      = WBOOT     + 3
CONIN       = CONOUT    + 3
CONST       = CONIN     + 3
CONPUTS     = CONST     + 3
CONBYTE     = CONPUTS   + 3
CONBEEP     = CONBYTE   + 3
SN_START    = CONBEEP   + 3
SN_SILENCE  = SN_START  + 3
SN_STOP     = SN_SILENCE + 3
SN_SEND     = SN_STOP   + 3
LED_ON      = SN_SEND   + 3
LED_OFF     = LED_ON    + 3
GET_BUTTON  = LED_OFF   + 3
ERROR_CODE  = GET_BUTTON + 3

RSTFAR      = $231

REGA        = $241
REGX        = REGA   + 1
REGY        = REGX   + 1

USERIRQVEC  = $244
USERNMIVEC  = $246
;
; hard coded addresses that SFCP uses
FCB          = $380
FCB2         = $3A0
CMDLINE      = $300
CMDOFFSET    = $3C0    ; pointer into CMDLINE
SFOS_BUF     = $400
SFOS_BUF_END = $600

TICKS        = $65F    ; 32bit value holding number of 60hz periods since boot
