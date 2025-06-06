  100 REM A BASIC, ASCII MANDELBROT
110 REM
120 REM This implementation copyright (c) 2019, Gordon Henderson
130 REM
140 REM Permission to use/abuse anywhere for any purpose granted, but
150 REM it comes with no warranty whatsoever. Good luck!
160 REM
170 C$ = ".,'~=+:;[/<&?oxOX# " : REM 'Pallet' Lightest to darkest...
180 SO = 1 : REM Set to 0 if your MID$() indexes from 0.
190 MI = LEN(C$)
200 MX = 4
210 LS = -2.0
220 TP = 1.25
230 XS = 2.5
240 YS = -2.5
250 W = 12
260 H = 8
270 SX = XS / W
280 SY = YS / H
290 Q = TIME
300 FOR Y = 0 TO H
310 CY = Y * SY + TP
320 FOR X = 0 TO W
330 CX = X * SX + LS
340 ZX = 0
350 ZY = 0
360 CC = SO
370 X2 = ZX * ZX
380 Y2 = ZY * ZY
390 IF CC > MI THEN GOTO 460
400 IF (X2 + Y2) > MX THEN GOTO 460
410 T = X2 - Y2 + CX
420 ZY = 2 * ZX * ZY + CY
430 ZX = T
440 CC = CC + 1
450 GOTO 370
460 PRINT MID$(C$, CC - SO, 1);
470 NEXT
480 PRINT
490 NEXT
500 PRINT W " Width" H " Height"
510 IF W > 74 THEN GOTO 580
520 W = W + 8
530 H = H + 6
540 PRINT
570 GOTO 270
580 END
