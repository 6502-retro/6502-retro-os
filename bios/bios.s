; vim: ft=asm_ca65
.autoimport
.globalzp ptr1

.export bios_boot, sdcard_param
.export bios_wboot, bios_conin, bios_conout, bios_const, bios_setdma
.export bios_setlba, bios_sdread, bios_sdwrite 

.zeropage

ptr1:   .word 0

.code

bios_boot:
    ldx #$ff
    txs
    cld
    cli

    jsr acia_init
    ldx #3
@L1:
    phx
    jsr sdcard_init
    plx
    dex
    bne @L1

    ; copy SYSTEM code into RUN area
    ldx #<__SYSTEM_SIZE__
@L2:
    lda __SYSTEM_LOAD__ - 1,x
    sta __SYSTEM_RUN__ -1,x
    dex
    bne @L2

bios_wboot:
    jsr zerobss
    jsr zero_lba
    
bios_conin:
    jsr acia_getc
    rts

bios_conout:
    jsr acia_putc
    rts

bios_const:
    jsr acia_getc_nw
    rts

bios_setdma:
    sta dma + 0
    stx dma + 1
    clc
    rts

bios_setlba:
    sta ptr1 + 0
    stx ptr1 + 1
    ldy #4
@L1:
    lda (ptr1),y
    sta sdcard_param,y
    clc
    rts

bios_sdread:
    jsr set_sdbuf_ptr
    jsr sdcard_read_sector
    rts

bios_sdwrite:
    jsr sdcard_write_sector
    rts

;---- Helper functions -------------------------------------------------------
set_sdbuf_ptr:
    lda dma + 0
    sta ptr1 + 0
    lda dma + 1
    sta ptr1 + 1
    rts

zero_lba:
    stz sdcard_param + 0 ; sector inside file
    stz sdcard_param + 1 ; file number
    stz sdcard_param + 2 ; drive number
    stz sdcard_param + 3 ; always zero
    rts

.bss
    dma: .word 0
    sdcard_param: .res 5

.segment "SYSTEM"
.rodata
