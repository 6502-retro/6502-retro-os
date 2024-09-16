ISCNTC:
        jsr     CONST
        bcc     @not_cnt_c
        cmp     #3
        bne     @not_cnt_c
        jmp     @is_cnt_c

@not_cnt_c:
        rts
@is_cnt_c:

        ;; fall through

