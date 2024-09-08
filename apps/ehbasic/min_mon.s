; vim: ft=asm_ca65
;
; minimal monitor for EhBASIC and 6502 simulator V1.05
; tabs converted to space, tabwidth=6

; To run EhBASIC on the simulator load and assemble [F7] this file, start the simulator
; running [F6] then start the code with the RESET [CTRL][SHIFT]R. Just selecting RUN
; will do nothing, you'll still have to do a reset to run the code.

acia_getc     = $8D48
acia_getc_nw  = $8D53
acia_putc     = $8D61
WBOOT         = $8C96
PROG_TOP      = $020A


.include "../../inc/sfos.inc"
.include "../../inc/fcb.inc"
.include "../../inc/errors.inc"
.include "basic.s"
;
; put the IRQ and MNI code in RAM so that it can be changed

IRQ_vec     = VEC_SV+2        ; IRQ code vector
NMI_vec     = IRQ_vec+$0A     ; NMI code vector

; now the code. all this does is set up the vectors and interrupt code
; and wait for the user to select [C]old or [W]arm start. nothing else
; fits in less than 128 bytes

      .code
; reset vector points here
RES_vec
; set up vectors and interrupt code, copy them to page 2

      LDY   #END_CODE-LAB_vec ; set index/count
LAB_stlp
      LDA   LAB_vec-1,Y       ; get byte from interrupt code
      STA   VEC_IN-1,Y        ; save to RAM
      DEY                     ; decrement index/count
      BNE   LAB_stlp          ; loop if more to do

; now do the signon message, Y = $00 here

LAB_signon
      LDA   LAB_mess,Y        ; get byte from sign on message
      BEQ   :+                ; exit loop if done

      JSR   V_OUTP            ; output character
      INY                     ; increment index
      BNE   LAB_signon        ; loop, branch always

:
      JMP   LAB_COLD          ; do EhBASIC cold start

; using acai routines from rom bank 0

ACIAout
        jmp acia_putc

ACIAin
        jmp acia_getc_nw
;
; vector tables

LAB_vec
      .word ACIAin            ; byte in from simulated ACIA
      .word ACIAout           ; byte out to simulated ACIA
      .word load              ; null load vector for EhBASIC
      .word save              ; null save vector for EhBASIC
      .word RES_vec

; EhBASIC IRQ support

IRQ_CODE
      PHA                     ; save A
      LDA   IrqBase           ; get the IRQ flag byte
      LSR                     ; shift the set b7 to b6, and on down ...
      ORA   IrqBase           ; OR the original back in
      STA   IrqBase           ; save the new IRQ flag byte
      PLA                     ; restore A
      RTI

; EhBASIC NMI support

NMI_CODE
      PHA                     ; save A
      LDA   NmiBase           ; get the NMI flag byte
      LSR                     ; shift the set b7 to b6, and on down ...
      ORA   NmiBase           ; OR the original back in
      STA   NmiBase           ; save the new NMI flag byte
      PLA                     ; restore A
      RTI

END_CODE

LAB_mess
      .byte $0D,$0A,"6502 EhBASIC",$00
                              ; sign on string

.include "6502-retro-basic.s"

