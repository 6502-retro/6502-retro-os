; vim: ft=asm_ca65
.autoimport
.globalzp ptr1, bdma_ptr, lba_ptr

.export bios_boot, bios_wboot, bios_conin, bios_conout, bios_const
.export bios_setdma, bios_setlba, bios_sdread, bios_sdwrite, bios_puts
.export bios_prbyte, bios_printlba

.zeropage

ptr1:       .word 0
bdma_ptr:   .word 0
blba_ptr:   .word 0

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
    ;
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
    sta bdma_ptr + 0
    sta bdma + 0
    stx bdma_ptr + 1
    stx bdma + 1
    clc
    rts

bios_setlba:
    sta blba_ptr + 0
    stx blba_ptr + 1
    ldy #3
@L1:
    lda (blba_ptr),y
    sta sector_lba,y
    dey
    bpl @L1
    clc
    rts

bios_sdread:
    jsr set_sdbuf_ptr
    jsr sdcard_read_sector
    rts

bios_sdwrite:
    jsr set_sdbuf_ptr
    jsr sdcard_write_sector
    rts

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

bios_printlba:
    pha
    phx
    phy

    lda #13
    jsr acia_putc
    lda #10
    jsr acia_putc
    lda sector_lba + 3
    jsr bios_prbyte
    lda sector_lba + 2
    jsr bios_prbyte
    lda sector_lba + 1
    jsr bios_prbyte
    lda sector_lba + 0
    jsr bios_prbyte

    ply
    plx
    pla
    rts

bios_prbyte:
    PHA             ;Save A for LSD.
    LSR
    LSR
    LSR             ;MSD to LSD position.
    LSR
    JSR PRHEX       ;Output hex digit.
    PLA             ;Restore A.
PRHEX:
    AND #$0F        ;Mask LSD for hex print.
    ORA #$B0        ;Add "0".
    CMP #$BA        ;Digit?
    BCC ECHO        ;Yes, output it.
    ADC #$06        ;Add offset for letter.
ECHO:
    PHA             ;*Save A
    AND #$7F        ;*Change to "standard ASCII"
    JSR acia_putc
    PLA             ;*Restore A
    RTS             ;*Done, over and out...

;---- Helper functions -------------------------------------------------------
set_sdbuf_ptr:
    lda bdma + 1
    sta bdma_ptr + 1
    ;jsr bios_prbyte
    lda bdma + 0
    sta bdma_ptr + 0
    ;jsr bios_prbyte
    rts

zero_lba:
    stz sector_lba + 0 ; sector inside file
    stz sector_lba + 1 ; file number
    stz sector_lba + 2 ; drive number
    stz sector_lba + 3 ; always zero
    rts

.bss
    bdma: .word 0

.segment "SYSTEM"
.rodata
