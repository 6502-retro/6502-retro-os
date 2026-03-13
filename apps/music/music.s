; vim: set ft=asm_ca65 ts=4 sw=4 et cc=80:
; 6502-Retro-Tetris Game
;
; Copyright (c) 2026 David Latham
;
; This code is licensed under the MIT license
;
; https://github.com/6502-retro/6502-retro-tetris


NT_NOTE_OFF = 1
NT_NOTE_ON  = 2
NT_SET_ATTN  = 3
NT_LOOP     = 4

.rodata

NOTES_FINE:
        .byte   $0B ; C2   0x00
        .byte   $05 ; C#2  0x02
        .byte   $03 ; D2   0x04
        .byte   $03 ; D#2  0x06
        .byte   $06 ; E2   0x08
        .byte   $0B ; F2   0x0a
        .byte   $03 ; F#2  0x0c
        .byte   $0D ; G2   0x0e
        .byte   $09 ; G#2  0x10
        .byte   $08 ; A3   0x12
        .byte   $08 ; A#3  0x14
        .byte   $0A ; B3   0x16
        .byte   $0D ; C3   0x18
        .byte   $02 ; C#3  0x1a
        .byte   $09 ; D3   0x1c
        .byte   $01 ; D#3  0x1e
        .byte   $0B ; E3   0x20
        .byte   $05 ; F3   0x22
        .byte   $01 ; F#3  0x24
        .byte   $0E ; G3   0x26
        .byte   $0C ; G#3  0x28
        .byte   $0C ; A4   0x2a
        .byte   $0C ; A#4  0x2c
        .byte   $0D ; B4   0x2e
        .byte   $0E ; C4   0x30
        .byte   $01 ; C#4  0x32
        .byte   $04 ; D4   0x34
        .byte   $08 ; D#4  0x36
        .byte   $0D ; E4   0x38
        .byte   $02 ; F4   0x3a
        .byte   $08 ; F#4  0x3c
        .byte   $0F ; G4   0x3e
        .byte   $06 ; G#4  0x40
        .byte   $0E ; A5   0x42
        .byte   $06 ; A#5  0x44
        .byte   $0E ; B5   0x46
        .byte   $07 ; C5   0x48
        .byte   $00 ; C#5  0x4a
        .byte   $0A ; D5   0x4c
        .byte   $04 ; D#5  0x4e
        .byte   $0E ; E5   0x50
        .byte   $09 ; F5   0x52
        .byte   $04 ; F#5  0x54
        .byte   $0F ; G5   0x56
        .byte   $0B ; G#5  0x58
        .byte   $07 ; A6   0x5a
        .byte   $03 ; A#6  0x5c
        .byte   $0F ; B6   0x5e
        .byte   $0B ; C6   0x60
        .byte   $08 ; C#6  0x62
        .byte   $05 ; D6   0x64
        .byte   $02 ; D#6  0x66
        .byte   $0F ; E6   0x68
        .byte   $0C ; F6   0x6a
        .byte   $0A ; F#6  0x6c
        .byte   $07 ; G6   0x6e
        .byte   $05 ; G#6  0x70
        .byte   $03 ; A7   0x72
        .byte   $01 ; A#7  0x74
        .byte   $0F ; B7   0x76
        .byte   $0D ; C7   0x78
        .byte   $0C ; C#7  0x7a
        .byte   $0A ; D7   0x7c
        .byte   $09 ; D#7  0x7e
        .byte   $07 ; E7   0x80
        .byte   $06 ; F7   0x82
        .byte   $05 ; F#7  0x84
        .byte   $03 ; G7   0x86
        .byte   $02 ; G#7  0x88
NOTES_COURSE:
        .byte   $3B ; C2   0x00
        .byte   $38 ; C#2  0x02
        .byte   $35 ; D2   0x04
        .byte   $32 ; D#2  0x06
        .byte   $2F ; E2   0x08
        .byte   $2C ; F2   0x0a
        .byte   $2A ; F#2  0x0c
        .byte   $27 ; G2   0x0e
        .byte   $25 ; G#2  0x10
        .byte   $23 ; A3   0x12
        .byte   $21 ; A#3  0x14
        .byte   $1F ; B3   0x16
        .byte   $1D ; C3   0x18
        .byte   $1C ; C#3  0x1a
        .byte   $1A ; D3   0x1c
        .byte   $19 ; D#3  0x1e
        .byte   $17 ; E3   0x20
        .byte   $16 ; F3   0x22
        .byte   $15 ; F#3  0x24
        .byte   $13 ; G3   0x26
        .byte   $12 ; G#3  0x28
        .byte   $11 ; A4   0x2a
        .byte   $10 ; A#4  0x2c
        .byte   $0F ; B4   0x2e
        .byte   $0E ; C4   0x30
        .byte   $0E ; C#4  0x32
        .byte   $0D ; D4   0x34
        .byte   $0C ; D#4  0x36
        .byte   $0B ; E4   0x38
        .byte   $0B ; F4   0x3a
        .byte   $0A ; F#4  0x3c
        .byte   $09 ; G4   0x3e
        .byte   $09 ; G#4  0x40
        .byte   $08 ; A5   0x42
        .byte   $08 ; A#5  0x44
        .byte   $07 ; B5   0x46
        .byte   $07 ; C5   0x48
        .byte   $07 ; C#5  0x4a
        .byte   $06 ; D5   0x4c
        .byte   $06 ; D#5  0x4e
        .byte   $05 ; E5   0x50
        .byte   $05 ; F5   0x52
        .byte   $05 ; F#5  0x54
        .byte   $04 ; G5   0x56
        .byte   $04 ; G#5  0x58
        .byte   $04 ; A6   0x5a
        .byte   $04 ; A#6  0x5c
        .byte   $03 ; B6   0x5e
        .byte   $03 ; C6   0x60
        .byte   $03 ; C#6  0x62
        .byte   $03 ; D6   0x64
        .byte   $03 ; D#6  0x66
        .byte   $02 ; E6   0x68
        .byte   $02 ; F6   0x6a
        .byte   $02 ; F#6  0x6c
        .byte   $02 ; G6   0x6e
        .byte   $02 ; G#6  0x70
        .byte   $02 ; A7   0x72
        .byte   $02 ; A#7  0x74
        .byte   $01 ; B7   0x76
        .byte   $01 ; C7   0x78
        .byte   $01 ; C#7  0x7a
        .byte   $01 ; D7   0x7c
        .byte   $01 ; D#7  0x7e
        .byte   $01 ; E7   0x80
        .byte   $01 ; F7   0x82
        .byte   $01 ; F#7  0x84
        .byte   $01 ; G7   0x86
        .byte   $01 ; G#7  0x88


