  10 REM blinky
20 pta=$bf21
30 p0=$ae
40 p1=$be
100 POKE pta,p0
110 GOSUB 200
120 POKE pta,p1
130 GOSUB 200
140 GET k
150 IF k > 0 THEN GOTO 199
160 GOTO 100
199 END
200 FOR i = 1 TO 1500 : NEXT i
210 RETURN

