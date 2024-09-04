; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "asminc.inc"

.export _sfos_s_warmboot, _sfos_s_reboot

.code
_sfos_s_warmboot:
    jmp WBOOT
_sfos_s_reboot:
    jmp REBOOT

