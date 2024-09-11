; vim: set ft=asm_ca65 ts=4 sw=4 :
.export _vdp_80_col, _vdp_unlock, _vdp_lock, _vdp_print, _vdp_clear_screen
.export _vdp_init_textmode, _vdp_init_g2mode, _vdp_write_reg, _vdp_write_address, _vdp_load_font
.export _vdp_newline, _vdp_write_char, _vdp_console_out
.export _screenbuf, _vdp_flush

.global _vdp
.globalzp vdpptr1,vdpptr2,vdpptr3

.segment "VDPZP" : zeropage

vdpptr1:    .res 2
vdpptr2:    .res 2
vdpptr3:    .res 2

.segment "VDPRAM"
_vdp:       .tag sVdp
_screenbuf: .res $300

.code
; a utility function to print out a 16bit value in hex.
_debug16:
    pha
    txa
    jsr prbyte
    pla
    jsr prbyte
    rts

;==============================================
; sets up 80 column text mode
;==============================================
_vdp_80_col:
    lda #$04
    ldx #$00
    jsr _vdp_write_reg
    lda #80
    sta _vdp + sVdp::cols
    rts

;==============================================
; unlocks the F18A
;==============================================
_vdp_unlock:
    lda #$1c
    ldx #57
    jsr _vdp_write_reg
    lda #$1c
    ldx #57
    jsr _vdp_write_reg
    rts

;==============================================
; locks the F18A if already unlocked.
;==============================================
_vdp_lock:
    lda #$00
    ldx #57
    jsr _vdp_write_reg
    rts

;==============================================
; inerprets input keys and acts accordingly
; A contains char from terminal
;==============================================
_vdp_console_out:
    cmp #$0a
    beq @newline
    cmp #$0d
    beq @newline
    cmp #$08
    beq @backspace
    cmp #$09
    beq @tab
    jsr _vdp_write_char
    rts
@newline:
    jmp _vdp_newline
@backspace:
    jmp _vdp_backspace
@tab:
    lda _vdp + sVdp::vx
    and #%11111100
    clc
    adc #3
    sta _vdp + sVdp::vx
    jmp _vdp_xy_to_nametable

;==============================================
; Print a string to the screen
; AX points to string
;==============================================
_vdp_print:
    sta vdpptr1
    stx vdpptr1 + 1
    ldy #0
:
    lda (vdpptr1),y
    beq @done
    jsr _vdp_write_char
    iny
    bra :-
@done:
    rts

;==============================================
; Print a character to the screen at the cursor
; location.  Increment cursor location.
; A contains char to print.
;==============================================
_vdp_write_char:
    pha
    inc _vdp + sVdp::vx
    lda _vdp + sVdp::cols
    cmp _vdp + sVdp::vx
    bcs :+
    stz _vdp + sVdp::vx
    inc _vdp + sVdp::vy
    lda _vdp + sVdp::rows
    cmp _vdp + sVdp::vy
    bcs :+
    jsr _vdp_clear_screen
:   pla
    sta F18A_RAM
    rts

;==============================================
; move back, delete char, move back again.
;==============================================
_vdp_backspace:
    lda _vdp + sVdp::vx
    beq @nobackspace
    dec _vdp + sVdp::vx
    jsr _vdp_xy_to_nametable
    lda #' '
    jsr _vdp_write_char
    dec _vdp + sVdp::vx
    jmp _vdp_xy_to_nametable
@nobackspace:
    rts

;==============================================
; move the current cursor position to the start
; of the next line.
;==============================================
_vdp_newline:
    stz _vdp + sVdp::vx
    inc _vdp + sVdp::vy
    lda _vdp + sVdp::vy
    cmp _vdp + sVdp::rows
    bcc _vdp_xy_to_nametable
    jmp _vdp_clear_screen

    ;fall through

_vdp_xy_to_nametable:
    copyptr _vdp + sVdp::nametable, vdpptr1
    ;debug16 vdpptr1
    lda _vdp + sVdp::vy
    beq @addx
    tay
@loop:
    lda _vdp + sVdp::cols
    cmp #80
    bne :+
    add16 vdpptr1,80
    bra @decy
:   cmp #40
    bne :+
    add16 vdpptr1,40
    bra @decy
:   add16 vdpptr1,32
@decy:
    dey
    bne @loop
@addx:
    lda _vdp + sVdp::vx
    clc
    adc vdpptr1
    sta vdpptr1
    lda vdpptr1 +1
    adc #0
    sta vdpptr1 + 1
@set_write_address:
    ;debug16 vdpptr1
    lda vdpptr1
    ldx vdpptr1 + 1
    jmp _vdp_write_address

;==============================================
; Write to vdp register
; A = value to write, x = register to write to
;==============================================
_vdp_write_reg:
    sta F18A_REG
    txa
    ora #$80
    sta F18A_REG
    rts

;==============================================
; Set up the vdp for writing at vram address
; A = low byte of vram address, x = high byte
;==============================================
_vdp_write_address:
    sta F18A_REG
    txa
    ora #$40
    sta F18A_REG
    rts

;==============================================
; Fills nametable with spaces
;==============================================
_vdp_clear_screen:
    vdp_set_write_address _vdp + sVdp::nametable
    ldy #8
    lda _vdp + sVdp::cols
    cmp #80
    beq :+
    ldy #4
:
    lda #' '
:
    ldx #0
:
    sta F18A_RAM
    dex 
    bne :-
    dey 
    bne :--
    stz _vdp + sVdp::vx
    stz _vdp + sVdp::vy
    vdp_set_write_address _vdp + sVdp::nametable
    rts

;==============================================
; Init vdp into standard 40x24 text mode
;==============================================
_vdp_init_textmode:
    set16 vdpptr1, textmode_registers
    jsr vdp_loadregisters
    ; set up vdp struct data
    lda #$00
    sta _vdp + sVdp::nametable
    lda #$08
    sta _vdp + sVdp::nametable + 1
    stz _vdp + sVdp::patterntable
    stz _vdp + sVdp::patterntable + 1
    lda #40
    sta _vdp + sVdp::cols
    lda #24
    sta _vdp + sVdp::rows
    rts

;==============================================
; Init g2 mode 32x24
;==============================================
_vdp_init_g2mode:
    set16 vdpptr1, g2mode_registers
    jsr vdp_loadregisters
    stz _vdp + sVdp::nametable
    lda #$38
    sta _vdp + sVdp::nametable + 1

    stz _vdp + sVdp::patterntable
    stz _vdp + sVdp::patterntable + 1

    stz _vdp + sVdp::colortable
    lda #$20
    sta _vdp + sVdp::colortable + 1

    stz _vdp + sVdp::spritepatterntable
    lda #$18
    sta _vdp + sVdp::spritepatterntable + 1

    stz _vdp + sVdp::spriteattributetable
    lda #$3B
    sta _vdp + sVdp::spriteattributetable + 1

    lda #32
    sta _vdp + sVdp::cols
    lda #$24
    sta _vdp + sVdp::rows
    rts

;==============================================
; loads the registers from a 0xff terminated data table pointed to
; by vdpptr1
;==============================================
vdp_loadregisters:
    ldy #0
:   lda (vdpptr1),y
    cmp #$ff
    beq :+
    sta F18A_REG
    iny
    lda (vdpptr1),y
    ora #$80
    sta F18A_REG
    iny
    bra :-
:   rts


;==============================================
; set up font data
; font data is pointed to by vdpptr1
; size of font stored in vdpptr2
;==============================================
_vdp_load_font:
    vdp_set_write_address _vdp + sVdp::patterntable
@loop:
    lda (vdpptr1)
    sta F18A_RAM
    ; decrement vdpptr2; break if 0
    lda vdpptr2
    bne :+
    dec vdpptr2 + 1
:   dec vdpptr2
    lda vdpptr2
    ora vdpptr2 + 1
    beq @done
    inc16 vdpptr1
    bra @loop
@done:
    rts

_vdp_flush:
    vdp_set_write_address _vdp + sVdp::nametable
    set16 vdpptr1, _screenbuf
    ldx #4
@loop:
    lda (vdpptr1)
    sta F18A_RAM
    inc vdpptr1
    bne @loop
    inc vdpptr1+1
    dex
    bne @loop
    rts

.rodata
str_tab: .byte "    ",0
textmode_registers:
    .byte $00, $00  ; textmode, no external video
    .byte $d0, $01  ; 16K, enable display, disable interrupt
    .byte $02, $02  ; name table at 0x0800
    .byte $00, $04  ; pattern table at 0x0000
    .byte $f4, $07  ; white text on dark blue background
    .byte $ff       ; end of data table

g2mode_registers:
    .byte $02, $00  ; Graphics II Mode,No External Video
    .byte $e0, $01  ; 16K,Enable Disp.,Enable int., 8x8 Sprites,Mag.Off
    .byte $0e, $02  ; Address of Name Table in VRAM = Hex 3800
    .byte $9f, $03  ; Color Table Address = Hex 2000 to Hex 2800
    .byte $00, $04  ; Pattern Table Address = Hex 0000 to Hex 0800
    .byte $76, $05  ; Address of Sprite Attribute Table in VRAM = Hex 3BOO
    .byte $03, $06  ; Address of Sprite Pattern Table in VRAM = 1800
    .byte $2b, $07  ; white on black
    .byte $ff

