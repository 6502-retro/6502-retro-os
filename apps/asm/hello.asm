\ Sample program
\ compile with a:asm hello.asm hello.com

sfos = 512
start:
        lda #<msg
        ldx #>msg
        ldy #3
        jsr sfos
        rts
msg:
        .byte 13,10,"Hello, World!",13,10,0
