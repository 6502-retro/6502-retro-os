
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

# CHANGE THIS

# Files for the interpreter

ISRC	=	mon.s

IOBJ	=	$(ISRC:.s=.o)

OBJ	=	mon

all:		$(OBJ)

.s.o:
	$Q echo [ Asm] $< 
	$Q ca65 --cpu $(CPU) -o $@ $(ALIST) $<

mon:	$(IOBJ)
	$Q echo [Link] $@
	$Q ld65 -o $@ -C mon.cfg -m $(OBJ).map $(IOBJ)
	$Q ls -l $@
	@echo [mon.srec @ 7000]
	@srec_cat mon -binary -offset 0x7000	\
		-O -Motorola -DISable Header -DISable Footer | head -n -1 > ../sxb/mon.srec


.PHONY:	size
size:
	$Q echo "[Size]"
	$Q size65 ${IOBJ}


.PHONY:	clean
clean:
	$Q echo "[Clean]"
	$Q rm -f $(OBJ) $(IOBJ) *.map *~ core tags *.bak *.lst *.l srec

.PHONY: com
com:
	$Q minicom lf #-D /dev/ttyUSB0 -b 9600 -w

.PHONY: com2
com2:
	$Q minicom -D /dev/ttyUSB0 -b 9600


.PHONY:	depend
depend:
	@../mkdep	$(ISRC)

-include	depends
