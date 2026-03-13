; vim: ft=asm_ca65 sw=4 ts=4 et:
.include "io.inc"
.include "bios.inc"

.autoimport

VDP_SYNC        = $65E
VDP_RAM         = vdp_ram
VDP_REG         = vdp_reg


.zeropage
music_frame_counter:.res 1

.code

main:
    sei
    jsr sn_start
    lda #<MUSIC_DATA
    ldx #>MUSIC_DATA
    jsr init_music_tracker
    stz music_frame_counter
    lda #$F0
    sta VDP_REG
    lda #$80
    sta VDP_REG

    cli
loop:
    jsr bios_const
    bne exit

    jsr vdp_wait

    inc music_frame_counter
    lda music_frame_counter
    cmp #5
    bne loop
    jsr handle_note
    stz music_frame_counter
    jmp loop
exit:
    jsr sn_stop
    jmp bios_wboot

vdp_wait:
    bit VDP_SYNC            ; vdp_sync is set by the interrupt handler to 0x80
    bpl vdp_wait
    stz VDP_SYNC            ; an interrupt was received so set the vdp_sync var
    rts                     ; to zero before exiting.

NT_NOTE_OFF = 1
NT_NOTE_ON  = 2
NT_SET_ATTN  = 3
NT_LOOP     = 4

.rodata

.include "tetris.inc"
