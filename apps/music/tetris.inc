; vim: ft=asm_ca65 sw=4 ts=4 et:

MUSIC_DATA:
    .word 0
    .byte NT_NOTE_ON, 0, 40, 8 ; E5
    .word 0
    .byte NT_NOTE_ON, 1, 16, 12  ; E3
    .word 2
    .byte NT_NOTE_OFF, 0
    .word 2
    .byte NT_NOTE_ON, 0, 28, 8 ; E4
    .word 4
    .byte NT_NOTE_OFF, 0
    .word 4
    .byte NT_NOTE_OFF, 1
    .word 4
    .byte NT_NOTE_ON, 0, 35, 8 ; B4
    .word 4
    .byte NT_NOTE_ON, 1, 16, 12  ; E3
    .word 5
    .byte NT_NOTE_OFF, 0
    .word 6
    .byte NT_NOTE_OFF, 1
    .word 6
    .byte NT_NOTE_ON, 0, 36, 8 ; C5
    .word 6
    .byte NT_NOTE_ON, 1, 28, 12  ; E4
    .word 7
    .byte NT_NOTE_OFF, 0
    .word 8
    .byte NT_NOTE_OFF, 1
    .word 8
    .byte NT_NOTE_ON, 0, 38, 8 ; D5
    .word 8
    .byte NT_NOTE_ON, 1, 16, 12  ; E3
    .word 10
    .byte NT_NOTE_OFF, 0
    .word 10
    .byte NT_NOTE_ON, 0, 28, 8 ; E4
    .word 12
    .byte NT_NOTE_OFF, 0
    .word 12
    .byte NT_NOTE_OFF, 1
    .word 12
    .byte NT_NOTE_ON, 0, 36, 8 ; C5
    .word 12
    .byte NT_NOTE_ON, 1, 16, 12  ; E3
    .word 13
    .byte NT_NOTE_OFF, 0
    .word 14
    .byte NT_NOTE_OFF, 1
    .word 14
    .byte NT_NOTE_ON, 0, 35, 8 ; B4
    .word 14
    .byte NT_NOTE_ON, 1, 28, 12  ; E4
    .word 15
    .byte NT_NOTE_OFF, 0
    .word 16
    .byte NT_NOTE_OFF, 1
    .word 16
    .byte NT_NOTE_ON, 0, 33, 8 ; A4
    .word 16
    .byte NT_NOTE_ON, 1, 9, 12   ; A2
    .word 18
    .byte NT_NOTE_OFF, 0
    .word 18
    .byte NT_NOTE_ON, 0, 21, 8 ; A3
    .word 20
    .byte NT_NOTE_OFF, 0
    .word 20
    .byte NT_NOTE_OFF, 1
    .word 20
    .byte NT_NOTE_ON, 0, 33, 8 ; A4
    .word 20
    .byte NT_NOTE_ON, 1, 9, 12   ; A2
    .word 21
    .byte NT_NOTE_OFF, 0
    .word 22
    .byte NT_NOTE_OFF, 1
    .word 22
    .byte NT_NOTE_ON, 0, 36, 8 ; C5
    .word 22
    .byte NT_NOTE_ON, 1, 21, 12  ; A3
    .word 23
    .byte NT_NOTE_OFF, 0
    .word 24
    .byte NT_NOTE_OFF, 1
    .word 24
    .byte NT_NOTE_ON, 0, 40, 8 ; E5
    .word 24
    .byte NT_NOTE_ON, 1, 9, 12   ; A2
    .word 26
    .byte NT_NOTE_OFF, 0
    .word 26
    .byte NT_NOTE_ON, 0, 21, 8 ; A3
    .word 28
    .byte NT_NOTE_OFF, 0
    .word 28
    .byte NT_NOTE_OFF, 1
    .word 28
    .byte NT_NOTE_ON, 0, 38, 8 ; D5
    .word 28
    .byte NT_NOTE_ON, 1, 9, 12   ; A2
    .word 29
    .byte NT_NOTE_OFF, 0
    .word 30
    .byte NT_NOTE_OFF, 1
    .word 30
    .byte NT_NOTE_ON, 0, 36, 8 ; C5
    .word 30
    .byte NT_NOTE_ON, 1, 21, 12  ; A3
    .word 31
    .byte NT_NOTE_OFF, 0
    .word 32
    .byte NT_NOTE_OFF, 1
    .word 32
    .byte NT_NOTE_ON, 0, 35, 8 ; B4
    .word 32
    .byte NT_NOTE_ON, 1, 8, 12   ; G#2
    .word 34
    .byte NT_NOTE_OFF, 0
    .word 34
    .byte NT_NOTE_ON, 0, 20, 8 
    .word 36
    .byte NT_NOTE_OFF, 0
    .word 36
    .byte NT_NOTE_OFF, 1
    .word 36
    .byte NT_NOTE_ON, 0, 35, 8 
    .word 36
    .byte NT_NOTE_ON, 1, 8, 12
    .word 37
    .byte NT_NOTE_OFF, 0
    .word 38
    .byte NT_NOTE_OFF, 1
    .word 38
    .byte NT_NOTE_ON, 0, 36, 8 
    .word 38
    .byte NT_NOTE_ON, 1, 20, 12
    .word 39
    .byte NT_NOTE_OFF, 0
    .word 40
    .byte NT_NOTE_OFF, 1
    .word 40
    .byte NT_NOTE_ON, 0, 38, 8
    .word 40
    .byte NT_NOTE_ON, 1, 8, 12
    .word 42
    .byte NT_NOTE_OFF, 0
    .word 42
    .byte NT_NOTE_ON, 0, 20, 8 
    .word 44
    .byte NT_NOTE_OFF, 0
    .word 44
    .byte NT_NOTE_OFF, 1
    .word 44
    .byte NT_NOTE_ON, 0, 40, 8
    .word 44
    .byte NT_NOTE_ON, 1, 8, 12 
    .word 46
    .byte NT_NOTE_OFF, 0
    .word 46
    .byte NT_NOTE_ON, 0, 20, 8
    .word 47
    .byte NT_NOTE_OFF, 0
    .word 48
    .byte NT_NOTE_OFF, 1
    .word 48
    .byte NT_NOTE_ON, 0, 36, 8
    .word 48
    .byte NT_NOTE_ON, 1, 9, 12
    .word 50
    .byte NT_NOTE_OFF, 0
    .word 50
    .byte NT_NOTE_ON, 0, 21, 8
    .word 52
    .byte NT_NOTE_OFF, 0
    .word 52
    .byte NT_NOTE_OFF, 1
    .word 52
    .byte NT_NOTE_ON, 0, 33, 8
    .word 52
    .byte NT_NOTE_ON, 1, 9, 12
    .word 54
    .byte NT_NOTE_OFF, 0
    .word 54
    .byte NT_NOTE_ON, 0, 21, 8
    .word 56
    .byte NT_NOTE_OFF, 0
    .word 56
    .byte NT_NOTE_OFF, 1
    .word 56
    .byte NT_NOTE_ON, 0, 33, 8
    .word 56
    .byte NT_NOTE_ON, 1, 9, 12
    .word 58
    .byte NT_NOTE_OFF, 0
    .word 58
    .byte NT_NOTE_ON, 0, 21, 8
    .word 60
    .byte NT_NOTE_OFF, 0
    .word 60
    .byte NT_NOTE_OFF, 1
    .word 60
    .byte NT_NOTE_ON, 0, 11, 8
    .word 60
    .byte NT_NOTE_ON, 1, 23, 12
    .word 61
    .byte NT_NOTE_OFF, 0
    .word 62
    .byte NT_NOTE_OFF, 1
    .word 62
    .byte NT_NOTE_ON, 0, 12, 8
    .word 62
    .byte NT_NOTE_ON, 1, 24, 12
    .word 63
    .byte NT_NOTE_OFF, 0
    .word 64
    .byte NT_NOTE_OFF, 1
    .word 64
    .byte NT_NOTE_ON, 0, 14, 8
    .word 66
    .byte NT_NOTE_OFF, 0
    .word 66
    .byte NT_NOTE_ON, 0, 26, 8
    .word 68
    .byte NT_NOTE_OFF, 0
    .word 68
    .byte NT_NOTE_ON, 0, 38, 8
    .word 68
    .byte NT_NOTE_ON, 1, 14, 12
    .word 70
    .byte NT_NOTE_OFF, 0
    .word 70
    .byte NT_NOTE_ON, 0, 26, 8
    .word 72
    .byte NT_NOTE_OFF, 0
    .word 72
    .byte NT_NOTE_OFF, 1
    .word 72
    .byte NT_NOTE_ON, 0, 41, 8
    .word 72
    .byte NT_NOTE_ON, 1, 14, 12
    .word 73
    .byte NT_NOTE_OFF, 0
    .word 74
    .byte NT_NOTE_OFF, 1
    .word 74
    .byte NT_NOTE_ON, 0, 45, 8
    .word 74
    .byte NT_NOTE_ON, 1, 26, 12
    .word 76
    .byte NT_NOTE_OFF, 0
    .word 76
    .byte NT_NOTE_ON, 0, 14, 8
    .word 77
    .byte NT_NOTE_OFF, 0
    .word 78
    .byte NT_NOTE_OFF, 1
    .word 78
    .byte NT_NOTE_ON, 0, 26, 8
    .word 80
    .byte NT_NOTE_OFF, 0
    .word 80
    .byte NT_NOTE_ON, 0, 43, 8
    .word 80
    .byte NT_NOTE_ON, 1, 14, 12
    .word 82
    .byte NT_NOTE_OFF, 0
    .word 82
    .byte NT_NOTE_OFF, 1
    .word 82
    .byte NT_NOTE_ON, 0, 41, 8
    .word 82
    .byte NT_NOTE_ON, 1, 26, 12
    .word 83
    .byte NT_NOTE_OFF, 0
    .word 84
    .byte NT_NOTE_OFF, 1
    .word 84
    .byte NT_NOTE_ON, 0, 40, 8
    .word 84
    .byte NT_NOTE_ON, 1, 12, 12
    .word 86
    .byte NT_NOTE_OFF, 0
    .word 86
    .byte NT_NOTE_ON, 0, 24, 8
    .word 88
    .byte NT_NOTE_OFF, 0
    .word 88
    .byte NT_NOTE_ON, 0, 12, 8
    .word 90
    .byte NT_NOTE_OFF, 0
    .word 90
    .byte NT_NOTE_ON, 0, 24, 8
    .word 92
    .byte NT_NOTE_OFF, 0
    .word 92
    .byte NT_NOTE_OFF, 1
    .word 92
    .byte NT_NOTE_ON, 0, 36, 8
    .word 92
    .byte NT_NOTE_ON, 1, 12, 12
    .word 93
    .byte NT_NOTE_OFF, 0
    .word 94
    .byte NT_NOTE_OFF, 1
    .word 94
    .byte NT_NOTE_ON, 0, 40, 8
    .word 94
    .byte NT_NOTE_ON, 1, 24, 12
    .word 96
    .byte NT_NOTE_OFF, 0
    .word 96
    .byte NT_NOTE_ON, 0, 12, 8
    .word 98
    .byte NT_NOTE_OFF, 0
    .word 98
    .byte NT_NOTE_ON, 0, 24, 8
    .word 100
    .byte NT_NOTE_OFF, 0
    .word 100
    .byte NT_NOTE_OFF, 1
    .word 100
    .byte NT_NOTE_ON, 0, 38, 8
    .word 100
    .byte NT_NOTE_ON, 1, 12, 12
    .word 102
    .byte NT_NOTE_OFF, 0
    .word 102
    .byte NT_NOTE_OFF, 1
    .word 102
    .byte NT_NOTE_ON, 0, 36, 8
    .word 102
    .byte NT_NOTE_ON, 1, 24, 12
    .word 103
    .byte NT_NOTE_OFF, 0
    .word 104
    .byte NT_NOTE_OFF, 1
    .word 104
    .byte NT_NOTE_ON, 0, 35, 8
    .word 104
    .byte NT_NOTE_ON, 1, 8, 12
    .word 106
    .byte NT_NOTE_OFF, 0
    .word 106
    .byte NT_NOTE_ON, 0, 20, 8
    .word 108
    .byte NT_NOTE_OFF, 0
    .word 108
    .byte NT_NOTE_ON, 0, 8, 8
    .word 110
    .byte NT_NOTE_OFF, 0
    .word 110
    .byte NT_NOTE_OFF, 1
    .word 110
    .byte NT_NOTE_ON, 0, 36, 8
    .word 110
    .byte NT_NOTE_ON, 1, 20, 12
    .word 111
    .byte NT_NOTE_OFF, 0
    .word 112
    .byte NT_NOTE_OFF, 1
    .word 112
    .byte NT_NOTE_ON, 0, 38, 8
    .word 112
    .byte NT_NOTE_ON, 1, 8, 12
    .word 114
    .byte NT_NOTE_OFF, 0
    .word 114
    .byte NT_NOTE_ON, 0, 20, 8
    .word 115
    .byte NT_NOTE_OFF, 0
    .word 116
    .byte NT_NOTE_OFF, 1
    .word 116
    .byte NT_NOTE_ON, 0, 40, 8
    .word 116
    .byte NT_NOTE_ON, 1, 8, 12
    .word 118
    .byte NT_NOTE_OFF, 0
    .word 118
    .byte NT_NOTE_ON, 0, 20, 8
    .word 120
    .byte NT_NOTE_OFF, 0
    .word 120
    .byte NT_NOTE_OFF, 1
    .word 120
    .byte NT_NOTE_ON, 0, 36, 8
    .word 120
    .byte NT_NOTE_ON, 1, 9, 12
    .word 122
    .byte NT_NOTE_OFF, 0
    .word 122
    .byte NT_NOTE_ON, 0, 21, 8
    .word 124
    .byte NT_NOTE_OFF, 0
    .word 124
    .byte NT_NOTE_OFF, 1
    .word 124
    .byte NT_NOTE_ON, 0, 33, 8
    .word 124
    .byte NT_NOTE_ON, 1, 9, 12
    .word 126
    .byte NT_NOTE_OFF, 0
    .word 126
    .byte NT_NOTE_ON, 0, 21, 8
    .word 127
    .byte NT_NOTE_OFF, 0
    .word 128
    .byte NT_NOTE_OFF, 1
    .word 128
    .byte NT_NOTE_ON, 0, 33, 8
    .word 128
    .byte NT_NOTE_ON, 1, 9, 12
    .word 130
    .byte NT_NOTE_OFF, 0
    .word 130
    .byte NT_NOTE_ON, 0, 21, 8
    .word 132
    .byte NT_NOTE_OFF, 0
    .word 132
    .byte NT_NOTE_OFF, 1
    .word 132
    .byte NT_NOTE_ON, 0, 9, 8
    .word 134
    .byte NT_NOTE_OFF, 0
    .word 134
    .byte NT_NOTE_ON, 0, 21, 8
    .word 136
    .byte NT_NOTE_OFF, 0
    .word 144
    .byte NT_NOTE_ON, 0, 40, 8
    .word 144
    .byte NT_NOTE_ON, 1, 9, 12
    .word 146
    .byte NT_NOTE_OFF, 0
    .word 146
    .byte NT_NOTE_ON, 0, 21, 8
    .word 148
    .byte NT_NOTE_OFF, 0
    .word 148
    .byte NT_NOTE_ON, 0, 9, 8
    .word 150
    .byte NT_NOTE_OFF, 0
    .word 150
    .byte NT_NOTE_ON, 0, 21, 8
    .word 152
    .byte NT_NOTE_OFF, 0
    .word 152
    .byte NT_NOTE_OFF, 1
    .word 152
    .byte NT_NOTE_ON, 0, 36, 8
    .word 152
    .byte NT_NOTE_ON, 1, 9, 12
    .word 154
    .byte NT_NOTE_OFF, 0
    .word 154
    .byte NT_NOTE_ON, 0, 21, 8
    .word 156
    .byte NT_NOTE_OFF, 0
    .word 156
    .byte NT_NOTE_ON, 0, 9, 8
    .word 158
    .byte NT_NOTE_OFF, 0
    .word 158
    .byte NT_NOTE_ON, 0, 21, 8
    .word 159
    .byte NT_NOTE_OFF, 0
    .word 160
    .byte NT_NOTE_OFF, 1
    .word 160
    .byte NT_NOTE_ON, 0, 38, 8
    .word 160
    .byte NT_NOTE_ON, 1, 8, 12
    .word 162
    .byte NT_NOTE_OFF, 0
    .word 162
    .byte NT_NOTE_ON, 0, 20, 8
    .word 164
    .byte NT_NOTE_OFF, 0
    .word 164
    .byte NT_NOTE_ON, 0, 8, 8
    .word 166
    .byte NT_NOTE_OFF, 0
    .word 166
    .byte NT_NOTE_ON, 0, 20, 8
    .word 168
    .byte NT_NOTE_OFF, 0
    .word 168
    .byte NT_NOTE_OFF, 1
    .word 168
    .byte NT_NOTE_ON, 0, 35, 8
    .word 168
    .byte NT_NOTE_ON, 1, 8, 12
    .word 170
    .byte NT_NOTE_OFF, 0
    .word 170
    .byte NT_NOTE_ON, 0, 20, 8
    .word 172
    .byte NT_NOTE_OFF, 0
    .word 172
    .byte NT_NOTE_ON, 0, 8, 8
    .word 174
    .byte NT_NOTE_OFF, 0
    .word 174
    .byte NT_NOTE_ON, 0, 20, 8
    .word 175
    .byte NT_NOTE_OFF, 0
    .word 176
    .byte NT_NOTE_OFF, 1
    .word 176
    .byte NT_NOTE_ON, 0, 36, 8
    .word 176
    .byte NT_NOTE_ON, 1, 9, 12
    .word 178
    .byte NT_NOTE_OFF, 0
    .word 178
    .byte NT_NOTE_ON, 0, 21, 8
    .word 180
    .byte NT_NOTE_OFF, 0
    .word 180
    .byte NT_NOTE_ON, 0, 9, 8
    .word 182
    .byte NT_NOTE_OFF, 0
    .word 182
    .byte NT_NOTE_ON, 0, 21, 8
    .word 184
    .byte NT_NOTE_OFF, 0
    .word 184
    .byte NT_NOTE_OFF, 1
    .word 184
    .byte NT_NOTE_ON, 0, 33, 8
    .word 184
    .byte NT_NOTE_ON, 1, 9, 12
    .word 186
    .byte NT_NOTE_OFF, 0
    .word 186
    .byte NT_NOTE_ON, 0, 21, 8
    .word 188
    .byte NT_NOTE_OFF, 0
    .word 188
    .byte NT_NOTE_ON, 0, 9, 8
    .word 190
    .byte NT_NOTE_OFF, 0
    .word 190
    .byte NT_NOTE_ON, 0, 21, 8
    .word 191
    .byte NT_NOTE_OFF, 0
    .word 192
    .byte NT_NOTE_OFF, 1
    .word 192
    .byte NT_NOTE_ON, 0, 32, 8
    .word 192
    .byte NT_NOTE_ON, 1, 8, 12
    .word 194
    .byte NT_NOTE_OFF, 0
    .word 194
    .byte NT_NOTE_ON, 0, 20, 8
    .word 196
    .byte NT_NOTE_OFF, 0
    .word 196
    .byte NT_NOTE_ON, 0, 8, 8
    .word 198
    .byte NT_NOTE_OFF, 0
    .word 198
    .byte NT_NOTE_ON, 0, 20, 8
    .word 200
    .byte NT_NOTE_OFF, 0
    .word 200
    .byte NT_NOTE_OFF, 1
    .word 200
    .byte NT_NOTE_ON, 0, 35, 8
    .word 200
    .byte NT_NOTE_ON, 1, 8, 12
    .word 202
    .byte NT_NOTE_OFF, 0
    .word 202
    .byte NT_NOTE_ON, 0, 20, 8
    .word 204
    .byte NT_NOTE_OFF, 0
    .word 204
    .byte NT_NOTE_ON, 0, 8, 8
    .word 206
    .byte NT_NOTE_OFF, 0
    .word 206
    .byte NT_NOTE_ON, 0, 20, 8
    .word 207
    .byte NT_NOTE_OFF, 0
    .word 208
    .byte NT_NOTE_OFF, 1
    .word 208
    .byte NT_NOTE_ON, 0, 40, 8
    .word 208
    .byte NT_NOTE_ON, 1, 9, 12
    .word 210
    .byte NT_NOTE_OFF, 0
    .word 210
    .byte NT_NOTE_ON, 0, 21, 8
    .word 212
    .byte NT_NOTE_OFF, 0
    .word 212
    .byte NT_NOTE_ON, 0, 9, 8
    .word 214
    .byte NT_NOTE_OFF, 0
    .word 214
    .byte NT_NOTE_ON, 0, 21, 8
    .word 216
    .byte NT_NOTE_OFF, 0
    .word 216
    .byte NT_NOTE_OFF, 1
    .word 216
    .byte NT_NOTE_ON, 0, 36, 8
    .word 216
    .byte NT_NOTE_ON, 1, 9, 12
    .word 218
    .byte NT_NOTE_OFF, 0
    .word 218
    .byte NT_NOTE_ON, 0, 21, 8
    .word 220
    .byte NT_NOTE_OFF, 0
    .word 220
    .byte NT_NOTE_ON, 0, 9, 8
    .word 222
    .byte NT_NOTE_OFF, 0
    .word 222
    .byte NT_NOTE_ON, 0, 21, 8
    .word 223
    .byte NT_NOTE_OFF, 0
    .word 224
    .byte NT_NOTE_OFF, 1
    .word 224
    .byte NT_NOTE_ON, 0, 38, 8
    .word 224
    .byte NT_NOTE_ON, 1, 8, 12
    .word 226
    .byte NT_NOTE_OFF, 0
    .word 226
    .byte NT_NOTE_ON, 0, 20, 8
    .word 228
    .byte NT_NOTE_OFF, 0
    .word 228
    .byte NT_NOTE_ON, 0, 8, 8
    .word 230
    .byte NT_NOTE_OFF, 0
    .word 230
    .byte NT_NOTE_ON, 0, 20, 8
    .word 232
    .byte NT_NOTE_OFF, 0
    .word 232
    .byte NT_NOTE_OFF, 1
    .word 232
    .byte NT_NOTE_ON, 0, 35, 8
    .word 232
    .byte NT_NOTE_ON, 1, 8, 12
    .word 234
    .byte NT_NOTE_OFF, 0
    .word 234
    .byte NT_NOTE_ON, 0, 20, 8
    .word 236
    .byte NT_NOTE_OFF, 0
    .word 236
    .byte NT_NOTE_ON, 0, 8, 8
    .word 238
    .byte NT_NOTE_OFF, 0
    .word 238
    .byte NT_NOTE_ON, 0, 20, 8
    .word 239
    .byte NT_NOTE_OFF, 0
    .word 240
    .byte NT_NOTE_OFF, 1
    .word 240
    .byte NT_NOTE_ON, 0, 36, 8
    .word 240
    .byte NT_NOTE_ON, 1, 9, 12
    .word 242
    .byte NT_NOTE_OFF, 0
    .word 242
    .byte NT_NOTE_ON, 0, 21, 8
    .word 244
    .byte NT_NOTE_OFF, 0
    .word 244
    .byte NT_NOTE_OFF, 0
    .word 244
    .byte NT_NOTE_ON, 0, 40, 8
    .word 244
    .byte NT_NOTE_ON, 1, 9, 12
    .word 246
    .byte NT_NOTE_OFF, 0
    .word 246
    .byte NT_NOTE_ON, 0, 21, 8
    .word 248
    .byte NT_NOTE_OFF, 0
    .word 248
    .byte NT_NOTE_OFF, 1
    .word 248
    .byte NT_NOTE_ON, 0, 45, 8
    .word 248
    .byte NT_NOTE_ON, 1, 9, 12
    .word 250
    .byte NT_NOTE_OFF, 0
    .word 250
    .byte NT_NOTE_ON, 0, 21, 8
    .word 252
    .byte NT_NOTE_OFF, 0
    .word 252
    .byte NT_NOTE_ON, 0, 9, 8
    .word 254
    .byte NT_NOTE_OFF, 0
    .word 254
    .byte NT_NOTE_OFF, 1
    .word 254
    .byte NT_NOTE_ON, 0, 21, 8
    .word 255
    .byte NT_NOTE_OFF, 0
    .word 256
    .byte NT_NOTE_OFF, 1
    .word 256
    .byte NT_NOTE_ON, 0, 44, 8
    .word 256
    .byte NT_NOTE_ON, 1, 8, 12
    .word 258
    .byte NT_NOTE_OFF, 0
    .word 258
    .byte NT_NOTE_ON, 0, 20, 8
    .word 260
    .byte NT_NOTE_OFF, 0
    .word 260
    .byte NT_NOTE_ON, 0, 8, 8
    .word 262
    .byte NT_NOTE_OFF, 0
    .word 262
    .byte NT_NOTE_ON, 0, 20, 8
    .word 264
    .byte NT_NOTE_OFF, 0
    .word 264
    .byte NT_NOTE_ON, 0, 8, 8
    .word 266
    .byte NT_NOTE_OFF, 0
    .word 266
    .byte NT_NOTE_ON, 0, 20, 8
    .word 268
    .byte NT_NOTE_OFF, 0
    .word 268
    .byte NT_NOTE_ON, 0, 8, 8
    .word 270
    .byte NT_NOTE_OFF, 0
    .word 270
    .byte NT_NOTE_ON, 0, 20, 8
    .word 271
    .byte NT_NOTE_OFF, 0
    .word 272
    .byte NT_NOTE_OFF, 1
    .word 272
    .byte NT_LOOP
