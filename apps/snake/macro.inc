; vim: set ft=asm_ca65 ts=4 sw=4 et:vdp
.macro div8
    .repeat 3
        lsr
    .endrepeat
.endmacro

.macro mul32
    .repeat 5
        asl
    .endrepeat
.endmacro

.macro store16 addr,val16
    lda #val16
    sta addr
    lda #val16
    sta addr + 1
.endmacro

.macro memcpy dst, src, cnt
.if cnt <= 0
    .error "memcpy: ivalid count: ", cnt
.elseif cnt <= 8
    .repeat  cnt - 1, i
        lda src + i
        sta dst + i
    .endrepeat
.elseif cnt <= 256
    ldx #0
:
    lda src, x
    sta dst, x
    inx
    cpx #(cnt & $ff)    
    bne :- 
.else
    store16 MEM_SRC, src
    store16 MEM_DST, dst
    store16 MEM_LEN, cnt

    jsr memcpyMultiPage
.endif

.macro setMemCpySrc src
    store16 MEM_SRC, src
.endmacro

.macro setMemCpyDst dst
    store16 MEM_DST, dst
.endmacro

.macro setMemCpySrcInd srcRef
    lda srcRef
    sta MEM_SRC
    lda srcRef + 1
    sta MEM_SRC + 1
.endmacro

.macro setMemCpyDstInd dstRef
    lda dstRef
    sta MEM_DST
    lda dstRef + 1
    sta MEM_DST + 1
.endmacro

.macro memcpySinglePage bytes

    .if bytes <= 0
        !error "memcpySinglePage: ivalid count: ", byte
    .endif

    ldy #bytes
    jsr memcpySinglePage
.endmacro

.macro memset dst,val, cnt
.if cnt <= 0
    .error "memset: ivalid count: ", cnt
.elseif cnt <= 8
    lda val
    .repeat cnt-1, i
        sta dst + i
    .endrepeat
.elseif cnt <= 256
    ldx #<cnt
    lda val
:
    dex
    sta dst, x
    cpx #0
    bne :-
.else
    store16 MEM_DST, dst
    store16 MEM_LEN, cnt
    lda val
    jsr memsetMultiPage
.endif
.endmacro

