; vim: ft=asm_ca65 sw=4 ts=4 et
REBOOT  = $200
WBOOT   = REBOOT + 3
SFOS    = REBOOT + 6

; hard coded addresses that SFCP uses
FCB         = $380
FCB2        = $3A0
CMDLINE     = $300
CMDOFFSET   = $3C0    ; pointer into CMDLINE


