; vim: ft=asm_ca65 sw=4 ts=4 et
;
; void __fastcall__ setbank(int bank);
;

.include "io.inc"
.export         _setbank
.export         _bank = $C000

.proc           _setbank

    and $3F       ; 6502-retro! supports only 64 banks.
    sta rambankreg
    nop
    nop

.endproc

