; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"
.include "io.inc"


acia_putc = CONOUT
acia_getc_nw = CONST

.bss

oldnmi: .res 2

.zeropage

.code
    cli

    lda USERNMIVEC + 0
    sta oldnmi + 0
    lda USERNMIVEC + 1
    sta oldnmi + 1

    lda #<nmi
    sta USERNMIVEC + 0
    lda #>nmi
    sta USERNMIVEC + 1

    lda #<welcome
    ldx #>welcome
    jsr c_printstr

main:
    jsr CONST
    bcc main
    ;
    ; restore old nmi
    lda oldnmi + 0
    sta USERNMIVEC + 0
    lda oldnmi + 1
    sta USERNMIVEC + 1

    lda #<exitmessage
    ldx #>exitmessage
    jsr c_printstr

    jmp WBOOT

nmi:
    lda #'@'
    jsr acia_putc
    rts


.include "../app.inc"

.rodata
welcome: .byte 10,13,"Press the NMI button.  You should see an `@` symbol each time."
         .byte 10,13,"Press any key to exit.",0
exitmessage:
        .byte 10,13,"Now when you press NMI the default `n` will be displayd",0
