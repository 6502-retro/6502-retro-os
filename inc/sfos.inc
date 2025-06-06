; vim: ft=asm_ca65
.enum esfos
    sfos_s_reset            = 0
    sfos_c_read             = 1
    sfos_c_write            = 2
    sfos_c_printstr         = 3
    sfos_c_readstr          = 4
    sfos_c_status           = 5
    sfos_d_getsetdrive      = 6
    sfos_d_createfcb        = 7
    sfos_d_parsefcb         = 8
    sfos_d_findfirst        = 9
    sfos_d_findnext         = 10
    sfos_d_make             = 11
    sfos_d_open             = 12
    sfos_d_close            = 13
    sfos_d_setdma           = 14
    sfos_d_readseqblock     = 15
    sfos_d_writeseqblock    = 16
    sfos_d_readseqbyte      = 17
    sfos_d_writeseqbyte     = 18
    sfos_d_setlba           = 19
    sfos_d_readrawblock     = 20
    sfos_d_writerawblock    = 21
    sfos_s_settpa           = 22
    sfos_s_gettpa           = 23
.endenum

; hard coded addresses that SFCP uses
FCB             = $380
FCB2            = $3A0
CMDLINE         = $300
CMDOFFSET       = $3C0    ; pointer into CMDLINE
SFOS_BUF        = $400
SFOS_BUF_END    = $600

