  10 VRAM=$BF30
20 VREG=$BF31
200 REM *********************************
201 REM unlock vdp
202 REM *********************************
210 REG=57 : VAL=$1C
220 GOSUB 2000 : GOSUB 2000
300 GOSUB 3000
310 GOSUB 3100
320 GOSUB 3200
330 GOSUB 3300
340 GOSUB 3400
350 INPUT "Turn off diag panels <yes|no>"; k$
360 IF k$="yes" THEN GOTO 400
370 END
400 GOSUB 1000
410 GOSUB 1000
999 END
1000 REM *******************************
1001 REM turn off all diags
1002 REM *******************************
1010 REG=58:VAL=16:GOSUB 2000:REG=59:VAL=0:GOSUB 2000
1020 REG=58:VAL=17:GOSUB 2000:REG=59:VAL=0:GOSUB 2000
1030 REG=58:VAL=18:GOSUB 2000:REG=59:VAL=0:GOSUB 2000
1040 REG=58:VAL=19:GOSUB 2000:REG=59:VAL=0:GOSUB 2000
1050 REG=58:VAL=20:GOSUB 2000:REG=59:VAL=0:GOSUB 2000
1060 RETURN
2000 REM *********************************
2001 REM SET REGISTER
2002 REM *********************************
2010 POKE VREG,VAL
2020 POKE VREG,REG OR $80
2030 FOR j = 1 TO 500 : NEXT j
2040 RETURN
3000 REM *********************************
3001 REM turn on diag
3002 REM *********************************
3010 REG=58:VAL=16:GOSUB 2000
3020 REG=59:VAL=1:GOSUB 2000
3030 RETURN
3100 REM ********************************
3101 REM turn on registers
3102 REM ********************************
3110 REG=58:VAL=17:GOSUB 2000
3120 REG=59:VAL=1:GOSUB 2000
3130 RETURN
3200 REM ********************************
3201 REM turn on performance
3202 REM ********************************
3210 REG=58:VAL=18:GOSUB 2000
3220 REG=59:VAL=1:GOSUB 2000
3230 RETURN
3300 REM *******************************
3301 REM turn on pallette
3302 REM *******************************
3310 REG=58:VAL=19:GOSUB 2000
3320 REG=59:VAL=1:GOSUB 2000
3330 RETURN
3400 REM ******************************
3401 REM turn on address
3402 REM ******************************
3410 REG=58:VAL=20:GOSUB 2000
3420 REG=59:VAL=1:GOSUB 2000
3430 RETURN
4000 reg=58:val=16:GOSUB 2000
4010 reg=59:val=0:GOSUB 2000
