; vim: ft=asm_ca65
.enum ERROR
        OK                      ; 0
        FILE_NOT_FOUND          ; 1
        FILE_EXISTS             ; 2
        FILE_MAX_REACHED        ; 3
        FILE_EOF                ; 4
        END_OF_DIR              ; 5
        DRIVE_ERROR             ; 6
        DRIVE_FULL              ; 7
        PARSE_ERROR             ; 8
        OUT_OF_MEMORY           ; 9
.endenum

