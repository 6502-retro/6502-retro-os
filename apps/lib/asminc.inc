; vim: set ft=asm_ca65 et ts=4 sw=4
SFOS            = $200
REBOOT          = $203
WBOOT           = $206
CONOUT          = $209
CONIN           = $20c
CONST           = $20f
CONPUTS         = $212
CONBYTE         = $215
SETDMA          = $218
SETLBA          = $21b
SDREAD          = $21e
SDWRITE         = $221
CONBEEP         = $224
SN_START        = $227
SN_SILENCE      = $22a
SN_STOP         = $22d
SN_SEND         = $230
LED_ON          = $233
LED_OFF         = $236
GET_BUTTON      = $239
ERROR_CODE      = $23c

RSTFAR          = $23d

REGA            = $24d
REGX            = $24e
REGY            = $24f

USERIRQVEC      = $250
USERNMIVEC      = $252

; hard coded addresses that SFCP uses
FCB             = $380
FCB2            = $3A0
CMDLINE         = $300
CMDOFFSET       = $3C0    ; pointer into CMDLINE
SFOS_BUF        = $400
SFOS_BUF_END    = $600

TICKS           = $65F    ; 32bit value holding number of 60hz periods since boot
