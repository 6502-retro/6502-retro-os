<!-- vim: set ft=markdown cc=80 tw=80 : -->
# 6502 RETRO MEMORY MAP

## High Level Block Memory

The memory map for the 6502 Retro! looks like this:

|ADDRESS|   SIZE |DESCRIPTION
|-------|-------:|------
| FFFF  |  7,936 | TOP OF ROM
| E000  |        | BOTTOM OF ROM
| .     | .      | .
| DFFF  |  8,192 | TOP OF EXTENDED / BANKED RAM
| C000  |        | BOTTOM OF EXTENDED / BANKED RAM
| .     | .      | .
| BFFF  |    256 | TOP OF IO
| BF00  |        | BOTTOM OF IO
| .     | .      | .
| BEFF  | 47,104 | TOP OF USER RAM (TPA)
| 0800  |        | BOTTOM OF USER RAM (TPA)
| 07FF  |    256 | TOP OF USER EXTRA RAM
| 0700  |        | BOTTOM OF USER EXTRA RAM
| 06FF  |  1,024 | TOP OF SFM SYSTEM RAM
| 0300  |        | BOTTOM OF SFM SYSTEM RAM
| 02FF  |    256 | TOP OF JMP TABLES AND BANK ROUTINES
| 0200  |        | BOTTOM OF JMP TABLES AND BANK ROUTIENS
| 01FF  |    256 | TOP OF H/W STACK
| 0100  |        | BOTTOM OF H/W STACK
| 00FF  |    256 | TOP OF ZEROPAGE
| 0000  |        | BOTTOM OF ZEROPAGE

## System Memory Usage

### Zeropage Usage

The BIOS, SFOS and SFCP reserve zeropage addresses E0-FF.  The rest is available
for Transient Applications.

|ADDRESS| DESCRIPTION
|-------|-------------
| 00    | BOTTOM OF USER ZEROPAGE
| DF    | TOP OF USER ZEROPAGE
| E0    | BOTTOM OF SYSTEM ZEROPAGE
| FF    | TOP OF SYSTEM ZEROPAGE

### System Memory Map

There are various variables, buffers and routines stored in the system memory
region that are reserved.  Some of these are available for use by user
applications too. This table is subject to change occasionally.  The best
source for up to date addresss is the symbol table in `build/rom/rom.sym` which
is created by the build scripts.

|ADDRESS    | DESCRIPTION                  | AVAILABLE FOR USE IN TRANSIENT APP
|-----------|------------------------------|-----------------------------------
|**BIOS**   |                              |.
| 200       | JUMP TABLE                   | NO
| 227       | ERROR_CODE                   | READ ONLY
| 228       | RSTFAR (Reset into rom bank) | EXEC ONLY
| 22E       | REG A                        | YES (USED BY BASIC)
| 22F       | REG X                        | YES
| 230       | REG Y                        | YES
| 231 - 2FF | RESERVED                     | YES
|**SFCP**   |                              |.
| 300       | COMMANDLINE                  | YES
| 380       | FCB                          | YES COMMAND (CAN BE REUSED IN TPA)
| 3A0       | FCB2                         | YES FIRST ARGUMENT TO COMMAND
| 3C0       | COMMAND OFFSET               | READONLY
| 3C2       | TEMP                         | YES
| 3C6       | ACTIVE DRIVE                 | READONLY
| 3C7       | SAVED ACTIVE DRIVE           | READONLY
| 3C8-3FF   | RESERVED                     | YES
|**SFOS**   |                              |.
| 400       | SFOS_BUF                     | YES
| 600       | SFOS_BUF_END (WASTED BYTE)   | READONLY
| 601       | CURRENT FILENUM              | NO
| 602       | CURRENT DIRENT               | NO
| 622       | CURENT DIRPOS                | NO
| 623       | DRIVE TABLE                  | NO
| 633       | LBA (32 BIT)                 | NO
| 637       | COMMAND LENGTH               | READONLY
| 638       | TEMP FCB                     | YES
| 658       | DIRTY SECTOR                 | NO
| 659       | FILE SIZE                    | NO
|**BIOS**   |                              |.
| 65D       | BDMA                         | NO
| 65F       | VDP STATUS                   | READONLY
| 660       | VDP SYNC                     | READONLY
| 661       | SDCARD PARAM                 | NO
| 662       | SECTOR LBA                   | NO
| 667       | TIMEOUT COUNT                | NO
| 668       | SPI SHIFT RESULT             | NO
|**USER**   |                              |.
| 800       | TPA                          | YES
| BEFF      | TPA END                      | YES
| BF00      | IO BLOCK                     | YES - MEMORY MAPPED IO
| C000      | EXTENDED / BANKED RAM        | YES
|**ROM**    |                              |.
| E000      | ROM                          | READONLY
| FFFF      | END OF ROM                   | READONLY
