; vim: ft=asm_ca65 sw=4 ts=4 et
.include "fcb.inc"
.include "sfos.inc"

REBOOT  = $200
WBOOT   = REBOOT + 3
SOFS    = REBOOT + 6

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

message: .byte 10,13,"Dump",10,13,0

