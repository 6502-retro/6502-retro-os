\\
\ sfos bindings

\ Memory Addresses
SFOS = 512
FCB  = 896
FCB2 = 928
SFOS_BUF = 1024
TPA  = 2048
CMD  = 769

\ SFOS
SFOS_S_RESET            = 0
SFOS_C_READ             = 1
SFOS_C_WRITE            = 2
SFOS_C_PRINTSTR         = 3
SFOS_C_READSTR          = 4
SFOS_C_STATUS           = 5
SFOS_D_GETSETDRIVE      = 6
SFOS_D_CREATEFCB        = 7
SFOS_D_PARSEFCB         = 8
SFOS_D_FINDFIRST        = 9
SFOS_D_FINDNEXT         = 10
SFOS_D_MAKE             = 11
SFOS_D_OPEN             = 12
SFOS_D_CLOSE            = 13
SFOS_D_SETDMA           = 14
SFOS_D_READSEQBLOCK     = 15
SFOS_D_WRITESEQBLOCK    = 16
SFOS_D_READSEQBYTE      = 17
SFOS_D_WRITESEQBYTE     = 18
SFOS_D_SETLBA           = 19
SFOS_D_READRAWBLOCK     = 20
SFOS_D_WRITERAWBLOCK    = 21
SFOS_S_SETTPA           = 22
SFOS_S_GETTPA           = 23

\ FCB
DRIVE                   = 0
N1                      = 1
N2                      = 2
N3                      = 3
N4                      = 4
N5                      = 5
N6                      = 6
N7                      = 7
N8                      = 8
E1                      = 9
E2                      = 10
E3                      = 11
L1                      = 12
L2                      = 13
SC                      = 14
FN                      = 15
AT                      = 16
EX1                     = 17
EX2                     = 18
Z1                      = 19
Z2                      = 20
S1                      = 21
S2                      = 22
S3                      = 23
S4                      = 24
CR                      = 25
DS                      = 26

\ BIOS
DISPATCH                = 512
BIOS_BOOT               = DISPATCH + 3
BIOS_WBOOT              = BIOS_BOOT + 3
BIOS_CONOUT             = BIOS_WBOOT +3
BIOS_CONIN              = BIOS_CONOUT + 3
BIOS_CONST              = BIOS_CONIN + 3
BIOS_PUTS               = BIOS_CONST + 3
BIOS_PRBYTE             = BIOS_PUTS + 3
SN_BEEP                 = BIOS_PRBYTE + 3
SN_START                = SN_BEEP + 3
SN_SILENCE              = SN_START + 3
SN_STOP                 = SN_SILENCE + 3
SN_SEND                 = SN_STOP + 3
LED_ON                  = SN_SEND + 3
LED_OFF                 = LED_ON + 3
GET_BUTTON              = LED_OFF + 3


