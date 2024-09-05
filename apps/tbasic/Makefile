
# Makefile:
#################################################################################

DESTDIR?=/usr
PREFIX?=/local

ifneq ($V,1)
Q ?= @
endif

ALIST=-l $(*F).l

CPU		=	65C02
#CPU		=	6502


#################################################################################
# Files for the interpreter
#################################################################################

SRC	=	system-$(PLATFORM).s			\
		data-$(PLATFORM).s			\
		gibl.s					\
		il.s ilExec.s ilUtils.s  flow.s		\
		relationals.s logic.s arith.s string.s	\
		goto.s findLine.s error.s		\
		input.s print.s				\
		list.s editor.s

OBJ	=	$(SRC:.s=.o)

.PHONY:	all
all:
	$Q echo "No Platform.  Try:"
	$Q echo "    make ruby"
	$Q echo "    make sxb-rom"
	$Q echo "    make sxb-ram"
	$Q echo "    make retro"
.s.o:
	$Q echo [ Asm] $< 
	$Q ca65 --cpu $(CPU) -D$(PLATFORM)=1 -o $@ $(ALIST) $<


#################################################################################
# gibl:
#	This is the main target. It's fully linked in a form to run on the
#	target system either as-is, or requiting some further massaging to
#	facilitate the loading on the target.
#################################################################################

gibl:	$(OBJ)
	$Q echo [Link] $@
	$Q ld65 -o $@ -C $(PLATFORM).cfg -m $@.map $(OBJ)
	$Q ls -l $@


#################################################################################
# Platfom specific finishing-off - You will need to add one of these
#	for your own system.
#################################################################################

.PHONY:	ruby
ruby:
	$Q make --no-print-directory PLATFORM=ruby ruby2

ruby2:		gibl
	$Q echo [Copy]
	$Q /bin/cp gibl /home/gordon/rubyFtp/gibl

#################################################################################
# sxb-ram:
#	We create the SREC file with a start offset of $1000 which is where it
#	runs in RAM.
#################################################################################

.PHONY:	sxb-ram
sxb-ram:
	$Q make --no-print-directory PLATFORM=sxb_ram  sxb-ram2

sxb-ram2:	gibl
	@rm -f sxb/ram.srec
	@echo [sxb/ram.srec @ 1000]
	@srec_cat gibl -binary -offset 0x1000	\
		-O -Motorola -DISable Header -DISable Footer | head -n -1 > sxb/ram.srec

#################################################################################
# retro:
#	We create the SREC file with a start offset of $1000 which is where it
#	runs in RAM.
#################################################################################

.PHONY:	retro
retro:
	make PLATFORM=retro  retro2

retro2:	gibl
	@rm -f retro/retro.bin
	../../scripts/loadtrim.py gibl retro/tbasic.com 800

#################################################################################
# sxb-rom:
#	We create the SREC file with a start offset of $6000 which is where it
#	gets loaded into RAM before being transfered into the EEPROM (@ $E000)
#################################################################################

.PHONY:	sxb-rom
sxb-rom:
	$Q make --no-print-directory PLATFORM=sxb_rom sxb_rom2

sxb_rom2:	gibl
	@rm -f sxb/rom.srec
	@echo [sxb/rom.srec @ 6000]
	@srec_cat gibl -binary -offset 0x6000	\
		-O -Motorola -DISable Header -DISable Footer | head -n -1 > sxb/rom.srec


#################################################################################
# Utilities
#################################################################################

.PHONY:	size
size:
	$Q echo "[Size]"
	$Q size65 ${OBJ}


.PHONY:	clean
clean:
	$Q echo "[Clean]"
	$Q rm -f *.o *.map *~ core tags *.bak *.lst *.l gibl
	$Q rm -f retro/*

.PHONY: tar
tar:
	make clean
	make --no-print-directory -C sxb-mon clean
	rm -f ../gibl.tgz
	cd .. ; tar cfz gibl.tgz gibl/

.PHONY: zip
zip:
	make clean
	make --no-print-directory -C sxb-mon clean
	rm -f ../gibl.zip
	cd .. ; zip -r -9 gibl.zip  gibl/


.PHONY:	depend
depend:
	@./mkdep	$(ISRC)

-include	depends
