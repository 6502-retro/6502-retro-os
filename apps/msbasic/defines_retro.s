; configuration
CONFIG_2A := 1

CONFIG_SCRTCH_ORDER := 2
;
;; zero page
ZP_START1 = $10
ZP_START2 = $1A
ZP_START3 = $70
ZP_START4 = $7B
;
;; extra/override ZP variables
USR				:= GORESTART ; XXX
;
;
;; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP		:= $FA
WIDTH			:= 40
WIDTH2			:= 30
;
RAMSTART2		:= $3000
;
;; magic memory locations

SFOS        = $200
REBOOT      = SFOS      + 3
WBOOT       = REBOOT    + 3
CONOUT      = WBOOT     + 3
CONIN       = CONOUT    + 3
CONST       = CONIN     + 3
CONPUTS     = CONST     + 3
CONBYTE     = CONPUTS   + 3
CONBEEP     = CONBYTE   + 3
ERROR_CODE  = CONBEEP   + 3

