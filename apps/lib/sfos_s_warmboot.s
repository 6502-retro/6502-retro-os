; vim: set ft=asm_ca65 et ts=4 sw=4
;
.include "bios.inc"

.export _sfos_s_warmboot, _sfos_s_reboot

.code
_sfos_s_warmboot:
    jmp bios_wboot
_sfos_s_reboot:
    jmp bios_cboot

