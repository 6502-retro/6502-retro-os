<!-- vim: set ft=markdown cc=80 tw=80 : -->
# 6502 RETRO MEMORY MAP

The memory map for the 6502 Retro! looks like this:

|ADDRESS|   SIZE |DESCRIPTION
|-------|-------:|------
| FFFF  |  7,936 | TOP OF ROM
| E100  |        | BOTTOM OF ROM
| .     | .      | .
| E0FF  |    256 | TOP OF IO
| E000  |        | BOTTOM OF IO
| .     | .      | .
| DFFF  |  8,192 | TOP OF HIGH RAM
| C000  |        | BOTTOM OF HIGH RAM
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
