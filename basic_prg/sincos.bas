  100 REM SIN and COS wave draw for EhBASIC
110 REM (c) L.Davison 2003/4/5
120 REM leeedavison@lycos.co.uk

130 REM scale :  offset  : curve centre
140 SC = 18.5 : OF = 1.5 : CS = SC + OF
150 WIDTH 64 : REM makes POS() absolute

160 DO
170 FOR A = 0 TO TWOPI STEP PI / 10
180 S = INT(SIN(A)*SC)
190 C = INT(COS(A)*SC)
200 IF S<C THEN PRINT SPC(CS+S)"+";SPC(C-S)"x";
210 IF S>C THEN PRINT SPC(CS+C)"x";SPC(S-C)"+";
220 PRINT SPC(CS+CS-POS(0));"."
230 FOR D = 1 TO 400 : NEXT
240 NEXT
250 LOOP
