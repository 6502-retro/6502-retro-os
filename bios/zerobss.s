; vim: ft=asm_ca65
.autoimport
.globalzp ptr1
.export zerobss

.zeropage

.code
zerobss:
    ; clear BSS
    lda #<__BSS_RUN__
    sta ptr1
    lda #>__BSS_RUN__
    sta ptr1+1
    lda #0
    tay
; Clear full pages
@L1:
    ldx #>__BSS_SIZE__
    beq @L3
@L2:
    sta (ptr1),y
    iny
    bne @L2
    inc ptr1+1
    dex
    bne @L2
; Clear remaining page (y is zero on entry)
@L3:
    cpy #<__BSS_SIZE__
    beq @L4
    sta (ptr1),y
    iny
    bne @L3
@L4:
    rts

.bss

.rodata
