; vim: ft=asm_ca65 sw=4 ts=4 et

.byte $00,$00,$00,$00,$00,$00,$00,$00   ; 0x00 - blank
.byte $00,$00,$00,$00,$0F,$0F,$0F,$0F   ; 0x01 - bottom_right
.byte $00,$00,$00,$00,$F0,$F0,$F0,$F0   ; 0x02 - bottom left
.byte $00,$00,$00,$00,$FF,$FF,$FF,$FF   ; 0x03 - bottom left + bottom right

.byte $0F,$0F,$0F,$0F,$00,$00,$00,$00   ; 0x04 - top right
.byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F   ; 0x05 - top right + bottom right
.byte $0F,$0F,$0F,$0F,$F0,$F0,$F0,$F0   ; 0x06 - top right + bottom left
.byte $0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF   ; 0x07 - top right + bottom left + bottom right

.byte $F0,$F0,$F0,$F0,$00,$00,$00,$00   ; 0x08 - top left
.byte $F0,$F0,$F0,$F0,$0F,$0F,$0F,$0F   ; 0x09 - top left + bottom right
.byte $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0   ; 0x0a - top left + bottom left
.byte $F0,$F0,$F0,$F0,$FF,$FF,$FF,$FF   ; 0x0b - top left + bottom left + bottom right

.byte $FF,$FF,$FF,$FF,$00,$00,$00,$00   ; 0x0c - top left + top right
.byte $FF,$FF,$FF,$FF,$0F,$0F,$0F,$0F   ; 0x0d - top left + top right + bottom right
.byte $FF,$FF,$FF,$FF,$F0,$F0,$F0,$F0   ; 0x0e - top left + top right + bottom left
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF   ; 0x0f - top left + top right + bottom left + bottom right

