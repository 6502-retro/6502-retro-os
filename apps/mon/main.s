; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"
.include "io.inc"


IN      = wozmon_buf
acia_putc = CONOUT
acia_getc_nw = CONST

.bss
wozmon_buf:     .res $7F

.zeropage
rambank:        .res 1
rombank:        .res 1
XAML:           .res 1
XAMH:           .res 1
STL:            .res 1
STH:            .res 1
L:              .res 1
H:              .res 1
YSAV:           .res 1
MODE:           .res 1
MSGL:           .res 1
MSGH:           .res 1

.code
wozmon:
RESET:
        CLD             ;Clear decimal arithmetic mode.
        CLI
        LDA #$0D
        JSR ECHO        ;* New line.
        LDA #$0A
        JSR ECHO
        LDA #<MSG1
        STA MSGL
        LDA #>MSG1
        STA MSGH
        JSR SHWMSG      ;* Show Welcome.
        LDA #$0D
        JSR ECHO        ;* New line.
        LDA #$0A
        JSR ECHO
SOFTRESET:
        LDA #$9B        ;* Auto escape.
NOTCR:
        CMP #$88        ;"<-"? * Note this was chaged to $88 which is the back space key.
        BEQ BACKSPACE   ;Yes.
        CMP #$9B        ;ESC?
        BEQ ESCAPE      ;Yes.
        INY             ;Advance text index.
        BPL NEXTCHAR    ;Auto ESC if >127.
ESCAPE:
        LDA #$DC        ;"\"
        JSR ECHO        ;Output it.
GETLINE:
        LDA #$8D        ;CR.
        JSR ECHO        ;Output it.
        LDA #$8A
        JSR ECHO
        LDY #$01        ;Initiallize text index.
BACKSPACE:
        DEY             ;Backup text index.
        BMI GETLINE     ;Beyond start of line, reinitialize.
        LDA #$A0        ;*Space, overwrite the backspaced char.
        JSR ECHO
        LDA #$88        ;*Backspace again to get to correct pos.
        JSR ECHO
NEXTCHAR:
        JSR acia_getc_nw
        BCC NEXTCHAR
        CMP #$60        ;*Is it Lower case
        BMI CONVERT     ;*Nope, just convert it
        AND #$5F        ;*If lower case, convert to Upper case
CONVERT:
        ORA #$80        ;*Convert it to "ASCII Keyboard" Input
        STA IN,Y        ;Add to text buffer.
        JSR ECHO        ;Display character.
        CMP #$8D        ;CR?
        BNE NOTCR       ;No.
        LDY #$FF        ;Reset text index.
        LDA #$00        ;For XAM mode.
        TAX             ;0->X.
SETSTOR:
        ASL             ;Leaves $7B if setting STOR mode.
SETMODE:
        STA MODE        ;$00 = XAM, $7B = STOR, $AE = BLOK XAM.
BLSKIP:
        INY             ;Advance text index.
NEXTITEM:
        LDA IN,Y        ;Get character.
        CMP #$8D        ;CR?
        BEQ GETLINE     ;Yes, done this line.
        CMP #$AE        ;"."?
        BCC BLSKIP      ;Skip delimiter.
        BEQ SETMODE     ;Set BLOCK XAM mode.
        CMP #$BA        ;":"?
        BEQ SETSTOR     ;Yes, set STOR mode.
        CMP #$D1        ;"Q"?
        BEQ EXIT
        CMP #$D2        ;"R"?
        BEQ RUN         ;Yes, run user program.
        STX L           ;$00->L.
        STX H           ; and H.
        STY YSAV        ;Save Y for comparison.
NEXTHEX:
        LDA IN,Y        ;Get character for hex test.
        EOR #$B0        ;Map digits to $0-9.
        CMP #$0A        ;Digit?
        BCC DIG         ;Yes.
        ADC #$88        ;Map letter "A"-"F" to $FA-FF.
        CMP #$FA        ;Hex letter?
        BCC NOTHEX      ;No, character not hex.
DIG:
        ASL
        ASL             ;Hex digit to MSD of A.
        ASL
        ASL
        LDX #$04        ;Shift count.
HEXSHIFT:
        ASL             ;Hex digit left MSB to carry.
        ROL L           ;Rotate into LSD.
        ROL H           ;Rotate into MSD's.
        DEX             ;Done 4 shifts?
        BNE HEXSHIFT    ;No, loop.
        INY             ;Advance text index.
        BNE NEXTHEX     ;Always taken. Check next character for hex.
NOTHEX:
        CPY YSAV        ;Check if L, H empty (no hex digits).
        BNE NOESCAPE    ;* Branch out of range, had to improvise...
        JMP ESCAPE      ;Yes, generate ESC sequence.

EXIT:
        JMP WBOOT

RUN:
        JSR ACTRUN      ;* JSR to the Address we want to run.
        JMP SOFTRESET   ;* When returned for the program, reset EWOZ.
ACTRUN:
        JMP (XAML)      ;Run at current XAM index.

NOESCAPE:
        BIT MODE        ;Test MODE byte.
        BVC NOTSTOR     ;B6=0 for STOR, 1 for XAM and BLOCK XAM
        LDA L           ;LSD's of hex data.
        STA (STL, X)    ;Store at current "store index".
        INC STL         ;Increment store index.
        BNE NEXTITEM    ;Get next item. (no carry).
        INC STH         ;Add carry to 'store index' high order.
TONEXTITEM:
        JMP NEXTITEM    ;Get next command item.
NOTSTOR:
        BMI XAMNEXT     ;B7=0 for XAM, 1 for BLOCK XAM.
        LDX #$02        ;Byte count.
SETADR:
        LDA L-1,X       ;Copy hex data to
        STA STL-1,X     ;"store index".
        STA XAML-1,X    ;And to "XAM index'.
        DEX             ;Next of 2 bytes.
        BNE SETADR      ;Loop unless X = 0.
NXTPRNT:
        BNE PRDATA      ;NE means no address to print.
        LDA #$8D        ;CR.
        JSR ECHO        ;Output it.
        LDA #$8A
        JSR ECHO
        LDA XAMH        ;'Examine index' high-order byte.
        JSR PRBYTE      ;Output it in hex format.
        LDA XAML        ;Low-order "examine index" byte.
        JSR PRBYTE      ;Output it in hex format.
        LDA #$BA        ;":".
        JSR ECHO        ;Output it.
PRDATA:
        LDA #$A0        ;Blank.
        JSR ECHO        ;Output it.
        LDA (XAML,X)    ;Get data byte at 'examine index".
        JSR PRBYTE      ;Output it in hex format.
XAMNEXT:
        STX MODE        ;0-> MODE (XAM mode).
        LDA XAML
        CMP L           ;Compare 'examine index" to hex data.
        LDA XAMH
        SBC H
        BCS TONEXTITEM  ;Not less, so no more data to output.
        INC XAML
        BNE MOD8CHK     ;Increment 'examine index".
        INC XAMH
MOD8CHK:
        LDA XAML        ;Check low-order 'exainine index' byte
        AND #$0F        ;For MOD 8=0 ** changed to $0F to get 16 values per row **
        BPL NXTPRNT     ;Always taken.
PRBYTE:
        PHA             ;Save A for LSD.
        LSR
        LSR
        LSR             ;MSD to LSD position.
        LSR
        JSR PRHEX       ;Output hex digit.
        PLA             ;Restore A.
PRHEX:
        AND #$0F        ;Mask LSD for hex print.
        ORA #$B0        ;Add "0".
        CMP #$BA        ;Digit?
        BCC ECHO        ;Yes, output it.
        ADC #$06        ;Add offset for letter.
ECHO:
        PHA             ;*Save A
        AND #$7F        ;*Change to "standard ASCII"
        JSR acia_putc
        PLA             ;*Restore A
        RTS             ;*Done, over and out...

SHWMSG:
        LDY #$0
@PRINT:
        LDA (MSGL),Y
        BEQ @DONE
        JSR ECHO
        INY
        BNE @PRINT
@DONE:
        RTS

MSG1:      .BYTE "Welcome to EWOZ 1.0.",0
.include "../app.inc"
