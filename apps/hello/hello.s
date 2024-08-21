; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

REBOOT  = $200
SOFS    = REBOOT + 3

main:
    ; Print hello, world and exit
    lda #<message
    ldx #>message
    ldy #esfos::sfos_c_printstr
    jsr SOFS
    jmp REBOOT

message: .byte "Hello, World!",0
