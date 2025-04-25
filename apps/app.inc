; vim: ft=asm_ca65
.include "../inc/sfos.inc"
.include "../inc/bios.inc"

.code
;
; ---- sfos_entry functions ------------------------------------------------------
s_reset:
    ldy #esfos::sfos_s_reset
    jmp sfos_entry
d_getsetdrive:
    ldy #esfos::sfos_d_getsetdrive
    jmp sfos_entry
c_status:
    ldy #esfos::sfos_c_status
    jmp sfos_entry
c_write:
    ldy #esfos::sfos_c_write
    jmp sfos_entry
c_read:
    ldy #esfos::sfos_c_read
    jmp sfos_entry
c_printstr:
    ldy #esfos::sfos_c_printstr
    jmp sfos_entry
c_readstr:
    ldy #esfos::sfos_c_readstr
    jmp sfos_entry
d_setdma:
    ldy #esfos::sfos_d_setdma
    jmp sfos_entry
d_parsefcb:
    ldy #esfos::sfos_d_parsefcb
    jmp sfos_entry
d_findfirst:
    ldy #esfos::sfos_d_findfirst
    jmp sfos_entry
d_findnext:
    ldy #esfos::sfos_d_findnext
    jmp sfos_entry
d_open:
    ldy #esfos::sfos_d_open
    jmp sfos_entry
d_close:
    ldy #esfos::sfos_d_close
    jmp sfos_entry
d_readseqblock:
    ldy #esfos::sfos_d_readseqblock
    jmp sfos_entry
d_writeseqblock:
    ldy #esfos::sfos_d_writeseqblock
    jmp sfos_entry
d_make:
    ldy #esfos::sfos_d_make
    jmp sfos_entry
d_readrawblock:
    ldy #esfos::sfos_d_readrawblock
    jmp sfos_entry
d_writerawblock:
    ldy #esfos::sfos_d_writerawblock
    jmp sfos_entry
d_setlba:
    ldy #esfos::sfos_d_setlba
    jmp sfos_entry
d_gettpa:
    ldy #esfos::sfos_s_gettpa
    jmp sfos_entry
d_settpa:
    ldy #esfos::sfos_s_settpa
    jmp sfos_entry
