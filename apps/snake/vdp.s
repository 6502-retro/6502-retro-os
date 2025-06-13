; vim: set ft=asm_ca65 ts=4 sw=4 et:
.include "io.inc"
.include "header.inc"
.include "macro.inc"

.export vdp_init, vdp_clear_screenbuf, vdp_wait, vdp_flush
.export vdp_screenbuf, vdp_xy_to_ptr, vdp_print_xy, vdp_char_xy
.export vdp_read_char_xy, vdp_color_char, vdp_set_write_address
.export vdp_load_font_patterns, vdp_load_sprite_patterns
.export vdp_setup_colortable_g2, vdp_flush_sprite_attributes

.autoimport

.globalzp ptr1, ptr2    ; these ZP 16 bit variables should be declared
                        ; elsewhere.

.zeropage
; no zeropage variables defined by this library.  They are imported as globals

.bss
; This is the framebuffer region in uninitialised BSS memory. It must be page
; aligned to support more efficient memory transfer into the VDP IO port.
.align $100
vdp_screenbuf: .res $300

.code

; =============================================================================
;               FRAMEBUFFER ROUTINES
; =============================================================================

; set the value of every location in the framebuffer to " " 0x20 (SPACE)
; INPUT: VOID
; OUTPUT: VOID
vdp_clear_screenbuf:
    stz ptr1                ; The low byte of the pointer will be zero due to
    lda #>vdp_screenbuf     ; page alignment. Set ptr1+1 to high byte of
    sta ptr1 + 1            ; framebuffer address.
    ldy #0                  ; X is a counter used to track how many pages of the
    ldx #4                  ; the frame buffer will be copied.
    lda #' '
:   sta (ptr1),y            ; Write 0x20 into every address in a page of the
    iny                     ; framebuffer.  Repeat 3 times.
    bne :-
    inc ptr1+1
    dex
    bne :-
    rts

; Convert XY tile addresses into a pointer into the corrosponding framebuffer
; address.
;
; INPUT: X = Horizontal tile position 0-31
;        Y = Vertical tile positition 0-23
; OUTPUT: ptr1 is set to the memory address within the framebuffer that
;         represents the tile location.
vdp_xy_to_ptr:
    pha                     ; Save A
    stz ptr1                ; The low byte of the pointer will be zero due to
    lda #>vdp_screenbuf     ; page alignment. Set ptr1+1 to high byte of
    sta ptr1+1              ; framebuffer address.

    tya                     ; Transfer Y to A for div8 macro
    div8                    ; divide A / 8 (lsr, lsr, lsr)
    clc                     ; prepare carry for add with carry.
    adc ptr1+1              ; Add to Y/8 to high byte of pointer
    sta ptr1+1
    tya                     ; Transfer Y to A for remainder of Y/8
    and  #$07               ; Find the remainder of Y/8
    mul32                   ; Multiply by 32 (asl, asl, asl, asl, asl) and save
    sta ptr1                ; to ptr1.
    ; add X to pointer
    clc                     ; Prepare carry for add with carry.
    txa                     ; Add X to the current value of ptr1 and then add
    adc ptr1                ; the value of the carry bit to ptr1+1 thus
    sta ptr1                ; the addition.
    lda #0
    adc ptr1+1
    sta ptr1+1
@return:
    pla                     ; restore A
    rts

; Set the value in A to the address in the framebuffer given by XY tilemap
; coordinates.
;
; INPUT: A = Value to save into the framebuffer.
;        X = Horizontal tile position 0-31
;        Y = Vertical tile positition 0-23
; OUTPUT: VOID
vdp_char_xy:
    jsr vdp_xy_to_ptr       ; find the framebuffer pointer.
    sta (ptr1)              ; save to pointer address.
    rts

; Read the value of the address in the framebuffer given by XY tilemap
; coordinates.
;
; INPUT: X = Horizontal tile position 0-31
;        Y = Vertical tile positition 0-23
; OUTPUT: A = Value from framebuffer at XY tilemap coordinates
vdp_read_char_xy:
    jsr vdp_xy_to_ptr       ; find the framebuffer pointer.
    lda (ptr1)              ; load from pointer address
    rts

; Copy a null terminated string into the framebuffer at the given XY tilemap
; coordinates.
;
; INPUT: ptr2 - A pointer to the null terminated string
;        X = Horizontal tile position 0-31
;        Y = Vertical tile positition 0-23
; OUTPUT: VOID
vdp_print_xy:
    jsr vdp_xy_to_ptr       ; initialize the framebuffer pointer.
    ldy #0                  ; zero the y index registerj
:   lda (ptr2),y            ; read from the given string pointer at Y offset.
    beq :+                  ; if null then branch to RTS
    sta (ptr1),y            ; save the byte to the framebuffer pointer at Y
    iny                     ; offset.  Increment Y offset.
    bra :-                  ; Loop.
:   rts

; =============================================================================
;               VDP LOW LEVEL ROUTINES
; =============================================================================

; First clear all VRAM then read from the registers table in the RODATA segment
; and writes them to the VDP registers by calling `init_regs`.  Then clear the
; framebuffer and initialise the sprite attributes.
; INPUT: Y=mode, 0=text, 1=GI, 2=GII
; OUTPUT: VOID
vdp_init:
    phy
    jsr clear_vram  
    ply
    jsr init_regs
    jsr vdp_clear_screenbuf
    jsr init_sprite_attributes
    rts

; Zero out all 16KB of VRAM.
; INPUT: VOID
; OUTPUT: VOID
clear_vram:
    lda #0                  ; A is low byte of vram write address
    ldx #0                  ; X is high byte of vram write address
    jsr vdp_set_write_address ; set the starting address to zero.
    lda #0                  ; A has the value being written to VRAM
    ldy #0                  ; Y is the byte counter
    ldx #$3F                ; X is the page counter
:   sta vdp_ram             ; save A into vram
    iny                     ; increment Y and loop until a whole page is written
    bne :-
    dex                     ; decement page counter and loop until all 0x3F
    bne :-                  ; pages are written.
    rts

; The graphics mode used means that every unique tile pattern has it's own
; color.  This routine allows to set the color of a specific pattern.  When that
; pattern is placed the screen, it will always have this color regardless of
; where on the screen the pattern is drawn.
; INPUT: A is the pattern name 0-255
;        X is the color to assign to that pattern.
; OUTPUT: VOID
vdp_color_char:
    phx                     ; Save color value
    asl                     ; Each pattern is made up of 8 bytes.  So multiply
    asl                     ; A (pattern name) by 8.  Preserve the carry.
    asl
    sta ptr1+0              ; save to ptr1 and preserve the carry.
    lda #<COLORTABLE        ; A has the low byte of the color table address
    ;clc                    ; *** TEST THAT THIS CLC IS NOT NEEDED. ***
    adc ptr1+0              ; add the low byte of the color table to the pointer
    sta ptr1+0              ; add with carry the high byte of the color table to
    lda #>COLORTABLE        ; the pointer
    adc #0
    sta ptr1+1
    lda ptr1+0              ; prep XA for the call to vdp_set_write_address
    ldx ptr1+1              ; and then call vdp_set_write_address
    jsr vdp_set_write_address
    plx                     ; Restore the color value
    .repeat 8               ; save the same color value to the 8 records in the
        stx vdp_ram         ; the color table that represent the pattern.
    .endrepeat
    rts

; Waits for veritical sync interrupt.  This function should be called prior to
; calling `vdp_flush`.  This is how a game loop can sync itself to the 60hz
; refresh rate.
; INPUT: VOID
; OUTPUT: VOID
vdp_wait:
    lda VDP_SYNC            ; vdp_sync is set by the interrupt handler to 0x80
    and #$80                ; whenever there is an interrupt.
    beq vdp_wait            ; if vdp_sync is zero then loop
    stz VDP_SYNC            ; an interrupt was received so set the vdp_sync var
    rts                     ; to zero before exiting.

; Copy every byte in the framebuffer to the the VDP NAMETABLE VRAM area as fast
; as possible.
; INPUT: VOID
; OUTPUT: VOID
vdp_flush:
    lda #<NAMETABLE         ; prep XA fo the call to vpd_set_write address.
    ldx #>NAMETABLE
    jsr vdp_set_write_address
    stz ptr1                ; initialize the framebuffer pointer to start of FB.
    lda #>vdp_screenbuf     ; set ptr1+1 to the high byte of the framebuffer
    sta ptr1 + 1            ; address.
    ldy #0                  ; Y offset for byte copy.
    ldx #3                  ; X is the page counter.
:   lda (ptr1),y            ; fetch the byte at ptr1 + Y
    sta vdp_ram             ; save to VRAM
    iny                     ; increment and loop until Y rolls over.
    bne :-
    inc ptr1+1              ; increment the high byte of the framebuffer
    dex                     ; pointer.
    bne :-                  ; decement the page counter and loop until 0.
    rts

; Wrtite the value in A to every colortable address in VRAM.
; INPUT: A is the color data to write.
; OUTPUT: VOID
vdp_setup_colortable_g1:
    tay                     ; save A
    lda #<COLORTABLE        ; set up write address of color table
    ldx #>COLORTABLE
    jsr vdp_set_write_address
    tya                     ; restore A
    ldy #32                 ; Y offset for byte copy.
:   sta vdp_ram             ; ssave to VRAM
    iny                     ; increment and loop until Y rolls over.
    bne :-
    rts


; Wrtite the value in A to every colortable address in VRAM.
; INPUT: A is the color data to write.
; OUTPUT: VOID
vdp_setup_colortable_g2:
    tay                     ; save A
    lda #<COLORTABLE        ; set up write address of color table
    ldx #>COLORTABLE
    jsr vdp_set_write_address
    tya                     ; restore A
    ldy #0                  ; Y offset for byte copy.
    ldx #4                  ; X is the page counter.
:   sta vdp_ram             ; ssave to VRAM
    iny                     ; increment and loop until Y rolls over.
    bne :-
    dex                     ; decrement page counter and loop until 0.
    bne :-
    rts

; Copy a table of register values to the VDP.  The table is arranged in order
; from REG-0 to REG-7.  Each value is set to the register of its position in the
; table.
; INPUT: A is the low byte of register table address.
;        X is the high byte of register table address.
; OUTPUT: VOID
init_regs:
    cpy #0                  ; text mode
    bne :+
    rts                     ; text mode unimpliemented
:   cpy #1                  ; GI mode
    bne :+
    lda #<g1_regs
    ldx #>g1_regs
    jmp @l1
:   cpy #2                  ; GII mode
    bne :+
    lda #<g2_regs
    ldx #>g2_regs
    jmp @l1
:   rts
@l1:
    sta ptr1                ; set up a pointer to the register table.
    stx ptr1+1
    ldy #0                  ; Y is the offset in the register table.
:   lda (ptr1),y            ; load the first byte
    sta vdp_reg             ; save to VRAM
    tya                     ; use the pointer offset to set the VDP register
    ora #$80                ; As per the TI Programmers manual.
    sta vdp_reg
    iny
    cpy #8                  ; there are 8 registers altogether 0-7
    bne :-                  ; loop until complete.
    rts

; Sets the VDP internal VRAM pointer for writing.
; INPUT: A is the low byte of the VRAM address.
;        X is the high byte of the VRAM address.
; OUTPUT: VOID
vdp_set_write_address:
    sta vdp_reg             ; As per the TI Programmers Guide.
    txa
    ora #$40
    sta vdp_reg
    rts

; Sets the VDP internal VRAM pointer for reading.
; INPUT: A is the low byte of the VRAM address.
;        X is the high byte of the VRAM address.
; OUTPUT: VOID
vdp_set_read_address:
    sta vdp_reg             ; As per the TI Programmers Guide.
    stx vdp_reg
    rts

; Load the pattern table (font) into VRAM at the pattern table address defined
; by the init registers.
; INPUT: ptr1 points to the start of the font data.
; OUTPUT: void
vdp_load_font_patterns:
    lda #<PATTERNTABLE      ; set up the VDP write pointer to the start of the
    ldx #>PATTERNTABLE      ; pattern table.
    jsr vdp_set_write_address
    ; fall through

; Internal routine that copies data from pointer 1, incrementing ptr1 until ptr1
; equals the value in ptr2.
; INPUT: ptr1 is the start address of data to copy.
;        ptr2 is the end address of data to copy.
; OUTPUT: VOID
copy_ptr1_to_ptr2:
    ldy #0
:   lda (ptr1),y
    sta vdp_ram
    lda ptr1
    clc
    adc #1
    sta ptr1
    lda #0
    adc ptr1+1
    sta ptr1+1
    cmp ptr2+1
    bne :-
    lda ptr1
    cmp ptr2
    bne :-
    rts

; Load the sprite patterns
; INPUT: ptr1 ptr to start of sprite pattern data
;        ptr2 ptr to end of sprite pattern data
; OUTPUT: VOID
vdp_load_sprite_patterns:
    lda #<SPRITEPATTERNTABLE    ; set up VDP write pointer to start of pattern
    ldx #>SPRITEPATTERNTABLE    ; table
    jsr vdp_set_write_address
    jmp copy_ptr1_to_ptr2       ; copy all the data into VRAM

; Init all sprites to disabled.
init_sprite_attributes:
    lda #<SPRITEATTRIBUTETABLE  ; set up VDP write pointer to start of sprite
    ldx #>SPRITEATTRIBUTETABLE  ; attribute table.
    jsr vdp_set_write_address
    ldx #32                     ; there are maximum of 32 sprites.
@L1:
    lda #$D0                    ; set the first attribute to 0xD0 and the other
    sta vdp_ram                 ; three attributes to zero.
    stz vdp_ram
    stz vdp_ram
    stz vdp_ram
    dex                         ; loop until all sprite attributes are set.
    bne @L1
    rts

; Flush the data pointed to by ptr1 into VDPRAM at the sprites attribute region.
; INPUT: ptr1 is a pointer to the sprite attributes data in regular RAM.
; OUTPUT: VOID
vdp_flush_sprite_attributes:
    lda #<SPRITEATTRIBUTETABLE
    ldx #>SPRITEATTRIBUTETABLE
    jsr vdp_set_write_address

    ldy #0
@L1:
    lda (ptr1),y
    cmp #$D0
    beq @EXIT
    sta vdp_ram
    iny
    bpl @L1
@EXIT:
    rts


.rodata

g1_regs:
    .byte $00                   ; Graphics mode I, no external video
    .byte $e2                   ; 16Kb VRAM, enable display, enable interrupts, 16x16 sprites, magnification off.
    .byte $05                   ; Name table address = 0x1400
    .byte $80                   ; Color table address = 0x2000
    .byte $01                   ; Pattern table address = 0x0800
    .byte $20                   ; Sprite attribute table = 0x1000
    .byte $00                   ; Sprite pattern table = 0x0000
    .byte $0a                   ; backdrop color = light yellow; These are the registers for the G2 mode with G1 like nametable arrangement as
; described at the beginning of this library.
g2_regs:
    .byte $02                   ; Graphics mode II, no external video
    .byte $e2                   ; 16Kb VRAM, enable display, enable interrupts, 16x16 sprites, magnification off.
    .byte $0e                   ; Name table address = 0x3800
    .byte $9f                   ; Color table address = 0x2000
    .byte $00                   ; Pattern table address = 0x0000
    .byte $76                   ; Sprite attribute table = 0x3B00
    .byte $03                   ; Sprite pattern table = 0x1800
    .byte $0a                   ; backdrop color = light yellow
