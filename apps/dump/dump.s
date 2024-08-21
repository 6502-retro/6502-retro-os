; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

REBOOT  = $200
SOFS    = REBOOT + 3

.zeropage

.code

main:
    ; Print hello, world and exit
    lda #<message
    ldx #>message
    jsr printstr


@exit:
    jmp REBOOT

printstr:
    ldy #esfos::sfos_c_printstr
    jmp SOFS

.bss

.rodata

message: .byte "Dump",10,13,0

