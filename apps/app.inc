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
d_gettpa:
    ldy #esfos::sfos_s_gettpa
    jmp SFOS
d_settpa:
    ldy #esfos::sfos_s_settpa
    jmp SFOS
