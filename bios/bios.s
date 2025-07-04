; vim: ft=asm_ca65
.include "io.inc"
.include "bios.inc"

.autoimport
.globalzp ptr1, bdma_ptr

.export cboot
.export _vdp_sync, _vdp_status, _notectr
.export error_code, rega, regx, regy
.export user_nmi_vector, user_irq_vector

.if DEBUG=1
.export bios_printlba
.endif

.zeropage

ptr1:       .word 0
bdma_ptr:   .word 0
blba_ptr:   .word 0

.code

cboot:
    ldx #$ff
    txs
    cld
    sei

    ;jsr via_init
    jsr acia_init
    jsr sn_start

    lda #%11010111
    sta via_ddra

cboot_emu:
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

    ; enable VDP interrupts (gives us a 60hz clock)
    lda #$F0    ; r1 16kb ram + M1, interrupts enabled, text mode
    sta vdp_reg
    lda #$81
    sta vdp_reg

    cli
    jmp sfos_s_reset
   ;

wboot:
    ; usually this is where we need to check if the SFCP needs to be
    ; reloaded.
    jmp prompt

conin:
    jmp acia_getc

conout:
    jmp acia_putc

const:
    jmp acia_getc_nw

setdma:
    sta bdma_ptr + 0
    sta bdma + 0
    stx bdma_ptr + 1
    stx bdma + 1
    clc
    rts

setlba:
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

sdread:
    jsr set_sdbuf_ptr
    jmp sdcard_read_sector

sdwrite:
    jsr set_sdbuf_ptr
    jmp sdcard_write_sector

puts:
    sta ptr1 + 0
    stx ptr1 + 1
    ldy #0
:   lda (ptr1),y
    beq @done
    jsr bios_conout
    iny
    beq @done
    bra :-
@done:
    rts

prbyte:
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
    jsr bios_conout
    pla             ;*Restore A
    rts             ;*Done, over and out...

; a is number of ms to delay
delay_ms:
    phx
    phy
    sta ptr1
@l1:
    ldy #16
@l2:
    ldx #250    ; 16 * 250 = 4000 = 1ms give or take
@l3:
    dex
    bne @l3
    dey
    bne @l2
    dec ptr1
    lda ptr1
    bne @l1
@done:
    ply
    plx
    rts

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

;---- STUB IRQ / NMI Handlers ------------------------------------------------
stub_user_irq_handler:
    rts
stub_user_nmi_handler:
    jmp bios_wboot

.segment "SYSTEM"
; dispatch function, will be relocated on boot into SYSRAM
jmptable:
    jmp dispatch    ; 200
    jmp cboot       ; 203
    jmp wboot       ; 206
    jmp conout      ; 209
    jmp conin       ; 20c
    jmp const       ; 20f
    jmp puts        ; 212
    jmp prbyte      ; 215

    jmp setdma      ; 218
    jmp setlba      ; 21b
    jmp sdread      ; 21e
    jmp sdwrite     ; 221

    jmp sn_beep     ; 224
    jmp sn_start    ; 227
    jmp sn_silence  ; 22a
    jmp sn_stop     ; 22d
    jmp sn_send     ; 230
    jmp led_on      ; 233
    jmp led_off     ; 236
    jmp get_button  ; 239
error_code: .byte 0 ; 23c

.assert * = $23d, error, "rstfar should be at $23d"
rstfar:
    pha
    lda via_ddra
    and #%10111111
    sta via_ddra
    pla
    sta rombankreg
    jmp ($FFFC)

.assert * = $24d, error, "REG A should be at $24d"
rega:       .res 1
regx:       .res 1
regy:       .res 1
.assert * = $250, error, "end of system should be at $250"

user_irq_vector:
    .lobytes stub_user_irq_handler
    .hibytes stub_user_irq_handler
user_nmi_vector:
    .lobytes stub_user_nmi_handler
    .hibytes stub_user_nmi_handler
.assert * = $254, error, "via_irq_handler at 244"

    jmp delay_ms    ; 254

.bss
bdma:       .word 0
_vdp_status:.res 1
_vdp_sync:  .res 1
_notectr:   .res 1

.segment "SYSTEM"
.rodata
