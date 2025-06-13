; vim: set ft=asm_ca65 sw=4 ts=4 et:
.include "io.inc"
.include "bios.inc"

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
@via_ifr:
    lda #$20
    bit via_ifr
    beq @vdp_irq
    dec notectr
    lda notectr
    bne :+
    jsr sn_silence
:   lda #$4e
    sta via_t2cl
    lda #$c3
    sta via_t2ch
@vdp_irq:
    bit vdp_reg
    bpl @user_irq
    lda vdp_reg
    sta _vdp_status
    lda #$80
    sta _vdp_sync
@user_irq:
    jsr user_irq_jumper
@exit
    ply
    plx
    pla
    rti

.segment "VECTORS"
    .addr nmi_handler
    .addr cboot 
    .addr irq_handler

