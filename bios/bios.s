; vim: ft=asm_ca65
.include "io.inc"

.autoimport
.globalzp ptr1, bdma_ptr, lba_ptr

.export bios_boot, bios_wboot, bios_conin, bios_conout, bios_const
.export bios_setdma, bios_setlba, bios_sdread, bios_sdwrite, bios_puts
.export bios_prbyte
.export _vdp_sync, _vdp_status
.export error_code, rega, regx, regy

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

.segment "SYSTEM"
; dispatch function, will be relocated on boot into SYSRAM
jmptables:
    jmp dispatch    ; 200
    jmp bios_boot   ; 203
    jmp bios_wboot  ; 206
    jmp bios_conout ; 209
    jmp bios_conin  ; 20B
    jmp bios_const  ; 20F
    jmp bios_puts   ; 212
    jmp bios_prbyte ; 215
    jmp sn_beep     ; 218
    jmp sn_start    ; 21B
    jmp sn_silence  ; 21E
    jmp sn_stop     ; 221
    jmp sn_send     ; 224
    jmp led_on      ; 227
    jmp led_off     ; 22A
    jmp get_button  ; 22D
error_code: .byte 0 ; 230

.assert * = $231, error, "rstfar should be at $231"
rstfar:
    lda via_porta   ; 231
    ora #%01000000  ; 234
    sta via_porta   ; 236
    sta rombankreg  ; 239
    jmp ($FFFC)     ; 23c

.assert * = $23F, error, "REG A should be at $23F"
rega:       .res 1
regx:       .res 1
regy:       .res 1
.assert * = $242, error, "end of system should be at $242"


.bss
bdma:       .word 0
_vdp_status:.res 1
_vdp_sync:  .res 1


.segment "SYSTEM"
.rodata
