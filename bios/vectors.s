; vim: set ft=asm_ca65 sw=4 ts=4 et:
.include "io.inc"
.autoimport
.code

user_irq_jumper:
    jmp (user_irq_vector)

user_nmi_jumper:
    jmp (user_nmi_vector)

nmi_handler:
    pha
    phx
    phy
    cld
    jsr user_nmi_jumper
    ply
    plx
    pla
    rti

irq_handler:
    pha
    phx
    phy
    cld
@vdp_irq:
    bit vdp_reg
    bpl @user_irq
    lda vdp_reg
    sta _vdp_status
    lda #$80
    sta _vdp_sync
    inc _ticks+0
    bne @exit
    inc _ticks+1
    bne @exit
    inc _ticks+2
    bne @exit
    inc _ticks+3
@user_irq:
    jsr user_irq_jumper
@exit
    ply
    plx
    pla
    rti

.segment "VECTORS"
    .addr nmi_handler
    .addr bios_boot
    .addr irq_handler

