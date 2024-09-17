; vim: ft=asm_ca65
.enum sfcb
        DD  ;drive
        N1  ;filename char 1
        N2  ;filename char 2
        N3  ;filename char 3
        N4  ;filename char 4
        N5  ;filename char 5
        N6  ;filename char 6
        N7  ;filename char 7
        N8  ;filename char 8
        T1  ;extension char 1
        T2  ;extension char 2
        T3  ;extension char 3
        L1  ;load low byte
        L2  ;load high byte
        SC  ;sector count
        FN  ;file number
        FA  ;file attribute
        E1  ;execute low
        E2  ;execute high
        Z1  ;last byte offset low
        Z2  ;last byte offset hight
        S0  ;filesize low
        S1  ;filesize middle
        S2  ;filesize high
        S3  ;filesize unused
        CR  ;current record
        DS  ;dirty sector
.endenum

.struct drvalloc
    is_logged_in    .byte   ; boolean flag to indicate if a drive is logged in
    maxdrv          .byte   ; the count of used dirents for the drive
.endstruct


