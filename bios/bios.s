; vim: ft=asm_ca65

.autoimport
.globalzp ptr1, bdma_ptr, lba_ptr

.export bios_boot, bios_wboot, bios_conin, bios_conout, bios_const
.export bios_setdma, bios_setlba, bios_sdread, bios_sdwrite, bios_puts
.export bios_prbyte
.export _vdp_sync, _vdp_status

.if DEBUG=1
.export bios_printlba
.endif

.zeropage

ptr1:       .word 0
bdma_ptr:   .word 0
blba_ptr:   .word 0

.code

bios_boot:
    ldx #$ff
    txs
    cld
    sei

    jsr acia_init
    jsr sn_start

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
    jsr zerobss
    jsr zero_lba
    jsr sn_beep

    cli
    jmp sfos_s_reset
   ;

bios_wboot:
    ; usually this is where we need to check if the SFCP needs to be
    ; reloaded, but as our sfcp will be residing in rom, we don't care.
    jmp prompt 

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

.if DEBUG=1
bios_printlba:
    pha
    phx
    phy

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
.endif

bios_prbyte:
    pha             ;Save A for LSD.
    lsr
    lsr
    lsr             ;MSD to LSD position.
    lsr
    jsr prhex       ;Output hex digit.
    pla             ;Restore A.
prhex:
    and #$0F        ;Mask LSD for hex print.
    ora #$B0        ;Add "0".
    cmp #$BA        ;Digit?
    bcc echo        ;Yes, output it.
    adc #$06        ;Add offset for letter.
echo:
    pha             ;*Save A
    and #$7F        ;*Change to "standard ASCII"
    jsr acia_putc
    pla             ;*Restore A
    rts             ;*Done, over and out...

;---- Helper functions -------------------------------------------------------
set_sdbuf_ptr:
    lda bdma + 1
    sta bdma_ptr + 1
    lda bdma + 0
    sta bdma_ptr + 0
    rts

zero_lba:
    stz sector_lba + 0 ; sector inside file
    stz sector_lba + 1 ; file number
    stz sector_lba + 2 ; drive number
    stz sector_lba + 3 ; always zero
    rts

.bss
bdma:       .word 0
_vdp_status:.res 1
_vdp_sync:  .res 1


.segment "SYSTEM"
.rodata
