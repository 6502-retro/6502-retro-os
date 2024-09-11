; vim: set ft=asm_ca65 ts=4 sw=4 :
;
F18A                            = $9F30
F18A_RAM                        = F18A + 0
F18A_REG                        = F18A + 1

; structure containing data that's used throughout.
; vdp init functions set this data
.struct sVdp
    nametable               .word
    colortable              .word
    patterntable            .word
    spriteattributetable    .word
    spritepatterntable      .word
    cols                    .byte
    rows                    .byte
    vx                      .byte
    vy                      .byte
    tick                    .byte
    status                  .byte
.endstruct

.macro debug16 addr
    lda addr
    ldx addr + 1
    jsr _debug16
.endmacro

.macro vdp_set_write_address addr
    lda addr
    ldx addr + 1
    jsr _vdp_write_address
.endmacro

.macro set16 ptr, addr
    lda #<addr
    sta ptr
    lda #>addr
    sta ptr + 1
.endmacro

.macro copyptr p1, p2
    lda p1
    sta p2
    lda p1+1
    sta p2+1
.endmacro

.macro inc16 lbl
    inc lbl
    bne :+
    inc lbl+1
:
.endmacro

.macro add16 base, value
    lda base
    clc
    adc #value
    sta base
    lda base + 1
    adc #0
    sta base + 1
.endmacro
