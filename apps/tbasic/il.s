
;*********************************************************************************
;* il.s:
;*	The IL - Intemediate Language is a sort of virtual machine that enabled
;*	the original Tiny Basic to save a lot of space. It's implemented by a
;*	small execution module and a set of macros to define the actual commands.
;*********************************************************************************

;********************************************************************************
;* This file is part of gibl:							*
;*	Gordons Interactive Basic Language                                      *
;********************************************************************************
;*    A Tiny Basic for the 6502 inspired by the NIBL Tiny Basic interpreter;	*
;*    "National Industrial Basic Language" originally for the INS8060 SC/MP	*
;*    system.									*
;*										*
;*    gibl is distributed under a "Source Available" license.			*
;*	It is NOT Open source and must not be treated as such.			*
;*										*
;*    See the file LICENSE for details.						*
;*										*
;*    gibl is Copyright (c) 2023 by Gordon Henderson				*
;********************************************************************************

	.feature	string_escapes 

	.include	"arith.h"
	.include	"data.h"
	.include	"editor.h"
	.include	"error.h"
	.include	"findLine.h"
	.include	"flow.h"
	.include	"goto.h"
	.include	"input.h"
	.include	"list.h"
	.include	"logic.h"
	.include	"print.h"
	.include	"relationals.h"
	.include	"string.h"
	.include	"system.h"

	.include	"ilMacros.h"
	.include	"ilExec.h"
	.include	"ilUtils.h"

	.include	"il.h"


;********************************************************************************
;* The I.L. program.
;*	Based on the NIBL one with many tweaks by me.
;********************************************************************************

ilBegin:	do	clear,newProg			; And fall into ...

 
; Start of the interpreter loop. This is interactive mode

ilStart:	do	newLine
prompt:		do	doGetLine
		testCR	prmpt1				; Empty line?
		jump	prompt				; ... loop back if-so.

prmpt1:		tNum	tryList				; Start with a number?
		do	saveCursor,popAE,findLine,editor	; ... Insert the line
		jump	prompt

; Now check for interactive commands

tryList:	tStr	tryRun,		"LIST"		; List entire program.
		do	resetCursor
		do	listProg
		jump	ilStart

tryClear:	tStr	tryNew,		"CLEAR"		; Clear variables, etc.
		do	stmtDone,clear,stmtNext

tryNew:		tStr	tryOld,		"NEW"		; Newk it all
		do	newProg,stmtNext

tryOld:		tStr	tryDir,		"OLD"		; What's old is new again...
		do	oldProg,stmtNext

tryDir:		tStr	tryLoad,	"DIR"		; Directory
		do      doDir,stmtNext

tryLoad:	tStr	trySave,	"LD"		; LoaD
		tNum	synErr
		do      doLd,stmtDone,oldProg,stmtNext

trySave:	tStr	ilStatement,	"SV"		; SaVe
		tNum	synErr
		do      doSv,stmtDone,stmtNext

tryRun:		tStr	tryClear,	"RUN"		; Run a program
		do	clear,progStart
		;jump	ilStatement			; Fall into ...

; ilStatement:
;	Program statements - interactive or command

ilStatement:	tStr	tryLet,		"LET"		; Optional LET
tryLet:		tVar	tryPokeByte			; If not a variable then carry on
		tStr	synErr,		"="		; ... else variable assignment.
		call	relExp
		do	storeV,stmtDone,stmtNext

tryPokeByte:	tStr	tryPokeWord,	"?"
		call	factor
		tStr	synErr,		"="
		call	relExp
		do	pokeByte,stmtDone,stmtNext

tryPokeWord:	tStr	tryIF,		"!"
		call	factor
		tStr	synErr,		"="
		call	relExp
		do	pokeWord,stmtDone,stmtNext

tryIF:		tStr	tryUntil,	"IF"
		call	relExp
		tStr	tryIf1,		"THEN"			; Optional THEN
tryIf1:		do	popAE,doIF
		jump	ilStatement

tryUntil:	tStr	tryDo,		"UNTIL"
		do	runMode					; Run-time only
		call	relExp
		do	stmtDone,popAE,until,stmtNext

tryDo:		tStr	tryGoto,	"DO"
		do	runMode,stmtDone,saveDo,stmtNext

tryGoto:	tStr	tryReturn,	"GO"			; Start looking for GO
		tStr	tryGosub,	"TO"			; ... then TO or 
		call	relExp
		do	stmtDone
		jump	gosCmn

tryGosub:	tStr	synErr,		"SUB"			; ... SUB
		call	relExp
		do	stmtDone,saveSub

gosCmn:		do	popAE,findLine,doGoto,stmtNext		; Common code for GOTO and GOSUB

tryReturn:	tStr	tryNext,	"RETURN"		; Return from subroutine
		do	stmtDone,returnSub,stmtNext

tryNext:	tStr	tryFor,		"NEXT"			; Setup NEXT statement
		do	runMode					; ... Only when running
		tVar	synErr					; Need a variable: NEXT I
		do	stmtDone,nextV				; First part of NEXT
		call	gtrOP					; Test greater than
		do	popAE, nextV1,stmtNext			; 2nd part of NEXT

tryFor:		tStr	trySetRnd,	"FOR"			; Setup for the FOR loop
		do	runMode					; ... Only when running
		tVar	synErr					; Start
		tStr	synErr,		"="			;	=
		call	relExp					;	Value
		tStr	synErr,		"TO"			;	TO
		call	relExp					;	Limit
		tStr	forStep1,	"STEP"			;	STEP - if not preset then ...
		call	relExp
		jump	tryFor2
forStep1:	do	push1					; ... load 1
tryFor2:	do	stmtDone,saveFor,storeV,stmtNext

trySetRnd:	tStr	tryDollar,	"RND"			; RND = ... Seed the PRNG
		tStr	synErr,		"="
		call	relExp
		do	stmtDone,popAE,seedRnd,stmtNext

tryDollar:	tStr	tryPrint,	"$"			; $ factor = "string" ...
		call	factor
		tStr	synErr,		"="
		tStr	tryDollar1,	"\""
		do	popAE,putString
		jump	tryDollar2
tryDollar1:	tStr	synErr,		"$"			; ... or = $ factor
		call	factor
		do	moveString
tryDollar2:	do	stmtDone,stmtNext

; Printing stuff

tryPrint:	tStr	tryVDU,		"PR"			; PRINT can be shortened to PR
		tStr	tryPrint1,	"INT"
tryPrint1:	tStr	tryPrint2,	"\""			; String?
		do	pStringP
		jump	prComma

tryPrint2:	tStr	tryPrint3,	"$"			; $ factor?
		call	factor
		do	popAE,pStringV
		jump	prComma

tryPrint3:	tStr	tryPrint3a,	"~"			; Print as Hex?
		call	relExp
		do	popAE,pHex
		jump	prComma

;tryPrint3a:	tStr	tryPrint4,	"@"			; VDU?
;		call	relExp
;		do	popAE,vdu
;		jump	prComma

tryPrint3a:
tryPrint4:	call	relExp					; Printing as decimal
		do	popAE,pDec

prComma:	tStr	tryPrint5,	","			; Comma separates items
		jump	tryPrint1				; Keep going

tryPrint5:	tStr	tryPrint6,	";"			; Semicolon only at end
		jump	printDone

tryPrint6:	do	newLine
printDone:	do	stmtDone,stmtNext

tryVDU:		tStr	tryInput,	"VDU"			; VDU expr [, expr ...]
tryVDU1:	call	relExp
		do	popAE,vdu
vduComma:	tStr	vduDone,	","
		jump	tryVDU1
vduDone:	do	stmtDone,stmtNext

; Input stuff
;	Single variable at a time input

tryInput:	tStr	tryEnd,		"INPUT"
		do	runMode					; Only in run mode.
		tVar	tryInput2				; Ordinary variable?
		do	saveCursor
tryInput0:	do	doGetLine
		testCR	tryInput1
		jump	tryInput0

tryInput1:	call	relExp
		do	storeV,restoreCursor,stmtDone,stmtNext
tryInput2:	tStr	synErr,		"$"			; String variable?
		call	factor
		do	saveCursor,doGetLine,popAE,iString,restoreCursor,stmtDone,stmtNext

tryEnd:		tStr	tryCall,	"END"
		do	stmtDone,progFin

tryCall:	tStr	tryRem,		"CALL"
		call	factor
		do	popAE,callML,stmtDone,stmtNext 

tryRem:		tStr	:+,	"REM"				; Remarkable
		do	comment,stmtNext
:

.if	.defined(sxb_ram) | .defined(sxb_rom)
tryLED:		tStr	:+,		"LED"			; LED = ...
		tStr	synErr,		"="
		call	relExp
		do	stmtDone,popAE,doSetLED,stmtNext
:
.endif

tryChain:	tStr	:+,	"CH"			; Load and Run ...
		tNum	synErr
		do      doLd,stmtDone
ilDoRun:	do	oldProg				; Auto-Run entry
		do	progStart
		jump	ilStatement
:

.if	.defined(sxb_ram)

tryERA:		tStr	tryFLA,		"ERA"
		do	doEra,stmtDone,stmtNext

tryFLA:		tStr	tryMon,		"FLA"
		do	doFla,stmtDone,stmtNext
.endif

tryMon:		tStr	tryNext3,	"MON"
		do	doMon,stmtDone,stmtNext
tryNext3:



synErr:		do	syntaxErr				; Doesn't return

; relExp:
;	Relational operators - compares.
;	Note that each one does an automatic ilReturn to save space/time...

relExp:		call	expr		; Evaluate expression
		tStr	rel1,	"="
		call	expr
		do	EQ		; ... with auto-return

rel1:		tStr	rel4,	"<"
		tStr	rel2,	"="
		call	expr
		do	LEQ

rel2:		tStr	rel3,	">"
		call	expr
		do	NEQ

rel3:		call	expr
		do	LSS

rel4:		tStr	retExp,	">"
		tStr	rel5,	"="
		call	expr
		do	GEQ

rel5:		call	expr
gtrOP:		do	GTR			; Auto-return - Enter here in FOR processing

; expr:
;	Arithmetic expressions

expr:		tStr	EX1,	"-"
		call	term
		do	NEG
		jump	EX3
EX1:		tStr	EX2,	"+"
EX2:		call	term
EX3:		tStr	EX4,	"+"
		call	term
		do	ADD
		jump	EX3

EX4:		tStr	tryOR,	"-"
		call	term
		do	SUB
		jump	EX3

tryOR:		tStr	tryEOR,	"OR"
		call	term
		do	orOP
		jump	EX3

tryEOR:		tStr	retExp,	"EOR"
		call	term
		do	eorOP
		jump	EX3

retExp:		do	ilReturn

; term:
;	? higher precidence expressions

term:		call	factor
t1:		tStr	tryDiv,	"*"
		call	factor
		do	MUL
		jump	t1

tryDiv:		tStr	tryMod,	"/"
		call	factor
		do	DIV 
		jump	t1

tryMod:		tStr	tryAND,	"%"
		call	factor
		do	MOD
		jump	t1

tryAND:		tStr	retExp,	"AND"
		call	factor
		do	andOP
		jump	t1

; factor:
;	Moves a value to the stack - variable, constant, system variable, etc.
;	May call itself recursively.

factor:		tVar	tryNum			; See if its a variable
		do	loadV,ilReturn
tryNum:		tNum	tryHexNum
		do	ilReturn
tryHexNum:	tStr	tryBraCet,	"&"	; Hex?
		do	getHex,ilReturn

tryBraCet:	tStr	tryPeekB,	"("	; Brackets?
		call	relExp
		tStr	synErr,		")"	; Must match...
		do	ilReturn

tryPeekB:	tStr	tryPeekW,	"?"
		call	factor
		do	peekByte,ilReturn
tryPeekW:	tStr	tryNot,		"!"
		call	factor
		do	peekWord,ilReturn

tryNot:		tStr	tryGetChar,	"NOT"
		call	factor
		do	notOP,ilReturn

tryGetChar:	tStr	tryGetTop,	"GET"	; Get single character from keyboard
		do	doGetChar,ilReturn

tryGetTop:	tStr	tryGetPage,	"TOP"	; Get start of free RAM
		do	getTop,ilReturn

tryGetPage:	tStr	tryGetRnd,	"PAGE"	; Get start of program RAM
		do	getPage,ilReturn

tryGetRnd:	tStr	:+,	"RND"	; Get random number
		do	getRnd,ilReturn
:

.if	.defined(sxb_ram) | .defined (sxb_rom)

tryGetLED:	tStr	:+,		"LED"	; Get LED register
		do	doGetLED,ilReturn
:
.endif

		jump	synErr
