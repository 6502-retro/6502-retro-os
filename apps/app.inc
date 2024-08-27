; vim: ft=asm_ca65 sw=4 ts=4 et
REBOOT  = $200
WBOOT   = REBOOT + 3
SFOS    = REBOOT + 6
RSTFAR  = REBOOT + 9

; hard coded addresses that SFCP uses
FCB          = $380
FCB2         = $3A0
CMDLINE      = $300
CMDOFFSET    = $3C0    ; pointer into CMDLINE
SFOS_BUF     = $400
SFOS_BUF_END = $600
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
    ldy #esfos::sfos_d_setmda
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

