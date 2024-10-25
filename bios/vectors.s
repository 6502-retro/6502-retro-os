; vim: set ft=asm_ca65 sw=4 ts=4 et:
.include "io.inc"
.autoimport
.code
nmi:
    rti

irq_handler:
        pha
        phx
        phy
        cld
@vdp_irq:
        bit     vdp_reg
        bpl     @exit
        lda     vdp_reg
        sta     _vdp_status
        lda     #$80
        sta     _vdp_sync
        inc     _ticks+0
        bne     @exit
        inc     _ticks+1
        bne     @exit
        inc     _ticks+2
        bne     @exit
        inc     _ticks+3
@exit
    ply
    plx
    pla
    rti

.segment "VECTORS"
    .addr nmi
    .addr bios_boot
    .addr irq_handler

