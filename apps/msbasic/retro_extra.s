.segment "EXTRA"
MONRDKEY:
        jsr     CONST
        bcc :+
        jsr     MONCOUT
        sec
:       rts
MONCOUT:
        pha
        jsr     CONOUT
        pla
        rts
LOAD:
        rts
SAVE:
        rts

BYE:
        jmp WBOOT
