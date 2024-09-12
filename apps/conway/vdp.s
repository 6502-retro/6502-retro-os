; vim: set ft=asm_ca65 ts=4 sw=4 :

;extern void vdp_init();
;extern void vdp_init_g2();
;extern void __fastcall__ vdp_set_write_address(unsigned int addr);
;extern void __fastcall__ vdp_set_read_address(unsigned int addr);
;extern void vdp_wait();
;extern void vdp_flush();
;extern void __fastcall__ vdp_write_to_screen_xy(unsigned char x, unsigned char y, unsigned char c);
;extern unsigned char __fastcall__ vdp_read_from_screen_xy(unsigned char x, unsigned char y);
;extern void vdp_clear_screen_buf();
;extern unsigned char screen_buf[0x400];
;
;extern unsigned char vdp_con_mode;
;extern unsigned char vdp_con_width;

.autoimport

; C Level exports
.export _vdp_init
.export _vdp_init_g2
.export _vdp_set_write_address
.export _vdp_set_read_address
.export _vdp_wait
.export _vdp_flush
.export _vdp_write_to_screen_xy
.export _vdp_read_from_screen_xy
.export _vdp_clear_screen_buf
.export _screen_buf

; ASM only exports
.export vdp_write_to_screen_xy
.export vdp_read_from_screen_xy

VDP_RAM         = $9F30
VDP_REG         = $9F31

VDP_SPRITE_PATTERN_TABLE    = 0
VDP_PATTERN_TABLE           = $800
VDP_G2_PATTERN_TABLE        = 0
VDP_SPRITE_ATTRIBUTE_TABLE  = $1000
VDP_NAME_TABLE              = $1400
VDP_G2_NAME_TABLE           = $3800
VDP_COLOR_TABLE             = $2000
_vdp_sync                   = $660
.macro vdp_delay_slow
    jsr delay_slow
.endmacro

.macro vdp_delay_fast
    jsr delay_fast
.endmacro

.macro div8
    .repeat 3
        lsr
    .endrepeat
.endmacro
.macro mul8
    .repeat 3
        asl
    .endrepeat
.endmacro
.macro mul32
    .repeat 5
        asl
    .endrepeat
.endmacro

.zeropage
ptr1: .word 0
sp:   .byte 0
tmp4: .byte 0
scr_ptr: .word 0

.code

delay_fast:
    phy
    ldy #16
:   dey
    bne :-
    ply
    rts
delay_slow:
    phy
    ldy #8
:   dey
    bne :-
    ply
    rts

_vdp_init:
        jsr     vdp_clear_vram
        lda     #<vdp_inits
        ldx     #>vdp_inits
        jsr     vdp_init_registers

        lda     #<VDP_PATTERN_TABLE
        ldx     #>VDP_PATTERN_TABLE
        jsr     vdp_load_font

        jsr     _vdp_clear_screen_buf

        stz     scrx
        stz     scry
        stz     _vdp_con_mode
        lda     #40
        sta     _vdp_con_width

        rts

_vdp_init_g2:
        jsr     vdp_clear_vram
        lda     #<vdp_g2_inits
        ldx     #>vdp_g2_inits
        jsr     vdp_init_registers

        lda     #<VDP_G2_PATTERN_TABLE
        ldx     #>VDP_G2_PATTERN_TABLE
        jsr     vdp_load_font

        jsr     _vdp_clear_screen_buf

        stz     scrx
        stz     scry
        lda     #1
        sta     _vdp_con_mode
        lda     #32
        sta     _vdp_con_width

        rts

; Zero out all 16K of the VRAM
vdp_clear_vram:
        lda     #$00
        ldx     #$00
        jsr     _vdp_set_write_address

        lda     #$FF
        sta     ptr1
        lda     #$3F
        sta     ptr1 + 1
:
        lda     #$00
        sta     VDP_RAM
        vdp_delay_slow
        dec     ptr1
        lda     ptr1
        bne     :-
        dec     ptr1 + 1
        lda     ptr1 + 1
        bne     :-
        rts

; Iniitialise the VDP into textmode with interrupts enabled.
; XA points to registers table
vdp_init_registers:
        sta     ptr1
        stx     ptr1+1
        ldy     #$00
:
        lda     (ptr1),y
        sta     VDP_REG
        vdp_delay_slow
        tya
        ora     #$80
        sta     VDP_REG
        vdp_delay_slow
        iny
        cpy     #8
        bne     :-
        rts

; XA points to NAME TABLE ADDRESS
vdp_load_font:
        jsr     _vdp_set_write_address

        lda     #<font_start
        sta     ptr1
        lda     #>font_start
        sta     ptr1 + 1

        ldy     #0
:
        lda     (ptr1),y
        sta     VDP_RAM
        vdp_delay_slow
        lda     ptr1
        clc
        adc     #1
        sta     ptr1
        lda     #0
        adc     ptr1 + 1
        sta     ptr1 + 1
        cmp     #>font_end
        bne     :-
        lda     ptr1
        cmp     #<font_end
        bne     :-
        rts

_vdp_clear_screen_buf:
        lda     #<_screen_buf
        sta     ptr1
        lda     #>_screen_buf
        sta     ptr1+1

        ldx     #4
        lda     #$20
        ldy     #0
:
        sta     (ptr1),y
        iny
        bne     :-
        inc     ptr1+1
        dex
        bne     :-
        stz     scrx
        stz     scry
        rts

_vdp_set_write_address:
        sta     VDP_REG
        vdp_delay_slow
        txa
        ora     #$40
        sta     VDP_REG
        vdp_delay_slow
        rts

_vdp_set_read_address:
        sta     VDP_REG
        vdp_delay_slow
        txa
        sta     VDP_REG
        vdp_delay_slow
        rts

_vdp_wait:
        lda     _vdp_sync
        cmp     #$80
        bne     _vdp_wait
        stz     _vdp_sync
        rts

_vdp_flush:
        lda     _vdp_con_mode
        bne     :+
        lda     #<VDP_NAME_TABLE
        ldx     #>VDP_NAME_TABLE
        bra     :++
:
        lda     #<VDP_G2_NAME_TABLE
        ldx     #>VDP_G2_NAME_TABLE
:
        jsr     _vdp_set_write_address
        lda     #<_screen_buf
        sta     ptr1
        lda     #>_screen_buf
        sta     ptr1+1

        ldx     #4
        ldy     #0
:       lda     (ptr1),y
        sta     VDP_RAM
        vdp_delay_slow
        inc     ptr1
        bne     :-
        inc     ptr1+1
        dex
        bne     :-
        rts

; Assembly version.
; A char to write
; XY location to write to
vdp_xy_to_screen_ptr:
        pha
        lda     #<_screen_buf
        sta     scr_ptr
        lda     #>_screen_buf
        sta     scr_ptr+1

        tya
        div8
        clc
        adc     scr_ptr+1
        sta     scr_ptr+1
        tya
        and      #$07
        mul32
        sta     scr_ptr
        lda     _vdp_con_mode
        bne     @add_x
        tya
        mul8
        clc
        adc     scr_ptr
        sta     scr_ptr
        lda     #0
        adc     scr_ptr+1
        sta     scr_ptr+1
@add_x:
        clc
        txa
        adc     scr_ptr
        sta     scr_ptr
        lda     #0
        adc     scr_ptr+1
        sta     scr_ptr+1
@return:
        pla
        rts

; XY is location
; A is char to write
vdp_write_to_screen_xy:
        jsr     vdp_xy_to_screen_ptr
        sta     (scr_ptr)
        rts

; C Wrapper for write to screen buffer at XY
; void vdp_write_to_screen_xy(unsigned char x, unsigned char y, unsigned char c);
_vdp_write_to_screen_xy:
        sta tmp4;      ; c
        ldy #1
        lda (sp),y
        tax     ;      ; x
        lda (sp)
        tay     ;      ; y
        lda tmp4
        jmp vdp_write_to_screen_xy

; XY is location
; A contains returned character
vdp_read_from_screen_xy:
        jsr     vdp_xy_to_screen_ptr
        lda     (scr_ptr)
        rts

; C Wrapper for write to screen buffer at XY
; unsigned char vdp_read_from_screen_xy(unsigned char x, unsigned char y);
_vdp_read_from_screen_xy:
        tay
        lda (sp)
        tax
        jmp vdp_read_from_screen_xy

; ==============================================================================
; VDP TERMINAL ROUTINES
; ==============================================================================
.bss
_screen_buf:    .res $400
_vdp_con_mode:  .res 1
_vdp_con_width: .res 1
scrx:           .res 1
scry:           .res 1

.rodata
vdp_inits:
        .byte $00        ; r0
        .byte $F0        ; r1 16kb ram + M1, interrupts enabled, text mode
        .byte $05        ; r2 name table at 0x1400
        .byte $80        ; r3 color start 0x2000
        .byte $01        ; r4 pattern generator start at 0x800
        .byte $20        ; r5 Sprite attriutes start at 0x1000
        .byte $00        ; r6 Sprite pattern table at 0x0000
        .byte $E1        ; r7 Set forground and background color (grey on black)

vdp_g2_inits:
        .byte $02        ; Graphics II Mode,No External Video
        .byte $e0        ; 16K,Enable Disp.,Enable int., 8x8 Sprites,Mag.Off
        .byte $0e        ; Address of Name Table in VRAM = Hex 3800
        .byte $9f        ; Color Table Address = Hex 2000 to Hex 280
        .byte $00        ; Pattern Table Address = Hex 0000 to Hex 0800
        .byte $76        ; Address of Sprite Attribute Table in VRAM = Hex 3BOO
        .byte $03        ; Address of Sprite Pattern Table in VRAM = 1800
        .byte $2b        ; white on black

font_start:
        .include "font.s"
font_end:


