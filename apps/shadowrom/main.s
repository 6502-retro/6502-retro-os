; vim: ft=asm_ca65 ts=4 sw=4 et
.include "io.inc"

.macro pp  addr
    lda #<addr
    ldx #>addr
    jsr printl
.endmacro

ROM_BASE = $e000
HIGHRAM  = $c000

.zeropage

src: .word 0
dst: .word 0
ptr: .word 0

.code
main:
    sei

    pp msg1

    lda #<ROM_BASE
    sta src + 0
    lda #>ROM_BASE
    sta src + 1

    lda #<HIGHRAM
    sta dst + 0
    lda #>HIGHRAM
    sta dst + 1

lp1:
    lda (src)
    sta (dst)
    inc src+0
    inc dst+0
    bne lp1

    pp msg5

    inc dst+1
    inc src+1
    bne lp1

    pp msg2

    lda via_porta
    and #%10111111
    sta via_porta
    lda via_ddra
    ora #%01000000
    sta via_ddra

    pp msg3

    lda #<HIGHRAM
    sta src + 0
    lda #>HIGHRAM
    sta src + 1

    lda #<ROM_BASE
    sta dst + 0
    lda #>ROM_BASE
    sta dst + 1

lp2:
    lda (src)
    sta (dst)
    inc src+0
    inc dst+0
    bne lp2

    pp msg5

    inc src+1
    inc dst+1
    bne lp2

    cli

    pp msg4

    rts

printl:
    sta ptr+0
    stx ptr+1
    ldy #0
:   lda (ptr),y
    beq :+
    iny
    jsr putc
    bra :-
:   rts

putc:
    pha                         ; save char
@wait_txd_empty:
    lda acia_status
    and #$10
    beq @wait_txd_empty
    pla                     ; restore char
    sta acia_data
    rts

msg1: .byte 10,13,"copy rom to lowram ...", 10,13,0
msg2: .byte 10,13,"disable rom...",10,13,0
msg3: .byte 10,10,"copy from lowram to highram...",10,13,0
msg4: .byte 10,13,"done",10,13,0
msg5: .byte ".",0
