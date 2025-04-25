; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "io.inc"


acia_putc = bios_conout
acia_getc_nw = bios_const

.bss

oldnmi: .res 2

.zeropage

.code
    cli

    lda bios_usernmi_vec + 0
    sta oldnmi + 0
    lda bios_usernmi_vec + 1
    sta oldnmi + 1

    lda #<nmi
    sta bios_usernmi_vec + 0
    lda #>nmi
    sta bios_usernmi_vec + 1

    lda #<welcome
    ldx #>welcome
    jsr c_printstr

main:
    jsr bios_const
    bcc main
    ;
    ; restore old nmi
    lda oldnmi + 0
    sta bios_usernmi_vec + 0
    lda oldnmi + 1
    sta bios_usernmi_vec+ 1

    lda #<exitmessage
    ldx #>exitmessage
    jsr c_printstr

    jmp bios_wboot

nmi:
    lda #'@'
    jsr bios_conout
    rts


.include "../app.inc"

.rodata
welcome: .byte 10,13,"Press the NMI button.  You should see an `@` symbol each time."
         .byte 10,13,"Press any key to exit.",0
exitmessage:
        .byte 10,13,"Now when you press NMI the default `n` will be displayd",0
