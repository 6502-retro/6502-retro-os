; vim: ft=asm_ca65
.autoimport
.globalzp ptr1

.export bios_boot, sdcard_param
.export bios_wboot, bios_conin, bios_conout, bios_const, bios_setdma
.export bios_setlba, bios_sdread, bios_sdwrite, bios_puts

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
    jmp main

bios_wboot:
    jsr zerobss
    jmp zero_lba

bios_conin:
    jmp acia_getc

bios_conout:
    jmp acia_putc

bios_const:
    jmp acia_getc_nw

bios_setdma:
    sta bdma + 0
    stx bdma + 1
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
    jmp sdcard_read_sector

bios_sdwrite:
    jmp sdcard_write_sector

bios_puts:
    sta ptr1 + 0
    stx ptr1 + 1
    ldy #0
:   lda (ptr1),y
    beq @done
    jsr acia_putc
    iny
    beq @done
    bra :-
@done:
    rts

;---- Helper functions -------------------------------------------------------
set_sdbuf_ptr:
    lda bdma + 0
    sta ptr1 + 0
    lda bdma + 1
    sta ptr1 + 1
    rts

zero_lba:
    stz sdcard_param + 0 ; sector inside file
    stz sdcard_param + 1 ; file number
    stz sdcard_param + 2 ; drive number
    stz sdcard_param + 3 ; always zero
    rts

.bss
    bdma: .word 0
    sdcard_param: .res 5

.segment "SYSTEM"
.rodata
