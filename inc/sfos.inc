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
    sfos_d_find             = 9
    sfos_d_make             = 10
    sfos_d_open             = 11
    sfos_d_close            = 12
    sfos_d_setmda           = 13
    sfos_d_readseqblock     = 14
    sfos_d_writeseqblock    = 15
    sfos_d_readseqbyte      = 16
    sfos_d_writeseqbyte     = 17
.endenum
