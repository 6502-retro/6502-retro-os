; vim: set ft=asm_ca65 sw=4 ts=4 et:
.autoimport

nmi:
irq:
    rti

.segment "VECTORS"
    .addr nmi
    .addr bios_boot
    .addr irq

