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
ERROR_CODE  = SN_SEND   + 3

RSTFAR      = $228

REGA        = $22E
REGX        = REGA   + 1
REGY        = REGX   + 1
;
; hard coded addresses that SFCP uses
FCB          = $380
FCB2         = $3A0
CMDLINE      = $300
CMDOFFSET    = $3C0    ; pointer into CMDLINE
SFOS_BUF     = $400
SFOS_BUF_END = $600

