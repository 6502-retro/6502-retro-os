  10 CLS
20 PRINT "uninit banks"
30 GOSUB 100
40 FOR a = 0 TO 63
50 POKE $bf00,a
60 POKE $c000,a
70 NEXT a
80 PRINT "init banks"
90 GOSUB 100
95 POKE $bf00,0 : REM RESET RAM BANK
99 END
100 FOR a = 0 TO 63
110 POKE $bf00,a
120 PRINT "[";a;"] ";PEEK($c000)
130 NEXT a
140 RETURN
