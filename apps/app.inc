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
;
; hard coded addresses that SFCP uses
FCB          = $380
FCB2         = $3A0
CMDLINE      = $300
CMDOFFSET    = $3C0    ; pointer into CMDLINE
SFOS_BUF     = $400
SFOS_BUF_END = $600

TICKS        = $660    ; 32bit value holding number of 60hz periods since boot

.code
;
; ---- SFOS functions ------------------------------------------------------
s_reset:
    ldy #esfos::sfos_s_reset
    jmp SFOS
d_getsetdrive:
    ldy #esfos::sfos_d_getsetdrive
    jmp SFOS
c_status:
    ldy #esfos::sfos_c_status
    jmp SFOS
c_write:
    ldy #esfos::sfos_c_write
    jmp SFOS
c_read:
    ldy #esfos::sfos_c_read
    jmp SFOS
c_printstr:
    ldy #esfos::sfos_c_printstr
    jmp SFOS
c_readstr:
    ldy #esfos::sfos_c_readstr
    jmp SFOS
d_setdma:
    ldy #esfos::sfos_d_setdma
    jmp SFOS
d_parsefcb:
    ldy #esfos::sfos_d_parsefcb
    jmp SFOS
d_findfirst:
    ldy #esfos::sfos_d_findfirst
    jmp SFOS
d_findnext:
    ldy #esfos::sfos_d_findnext
    jmp SFOS
d_open:
    ldy #esfos::sfos_d_open
    jmp SFOS
d_close:
    ldy #esfos::sfos_d_close
    jmp SFOS
d_readseqblock:
    ldy #esfos::sfos_d_readseqblock
    jmp SFOS
d_writeseqblock:
    ldy #esfos::sfos_d_writeseqblock
    jmp SFOS
d_make:
    ldy #esfos::sfos_d_make
    jmp SFOS
d_readrawblock:
    ldy #esfos::sfos_d_readrawblock
    jmp SFOS
d_writerawblock:
    ldy #esfos::sfos_d_writerawblock
    jmp SFOS
d_setlba:
    ldy #esfos::sfos_d_setlba
    jmp SFOS
