# Sources and objects
SOURCES = \
	  min_mon.s
APPNAME = basic

# DO NOT EDIT THIS
#include ../Make.rules# Sources and objects
AS = ca65
LD = ld65
CC = cl65

TOP = ..
RELIST = $(TOP)/../scripts/relist.py
FINDSYM = $(TOP)/../scripts/findsymbols
LOADTRIM = $(TOP)/../scripts/loadtrim.py
CFG = $(TOP)/apps.cfg
INCLUDES = -I $(TOP)/../inc
LIB = -I $(TOP)/lib

# Assembler flags
ASFLAGS += $(INCLUDES) -g --feature labels_without_colons --cpu 65C02 --feature string_escapes
# Compiler flags
CCFLAGS = --cpu 65C02 -t none -Ln $(BUILD_DIR)/$(APPNAME).sym -C $(CFG) -m $(BUILD_DIR)/$(APPNAME).map -o $(BUILD_DIR)/$(APPNAME).raw $(LIB) $(INCLUDES) -l $(BUILD_DIR)/$(APPNAME).lst

LOAD_ADDR = 800

BUILD_DIR = build

OBJS = $(addprefix $(BUILD_DIR)/, $(SOURCES:.s=.o))

all: clean $(BUILD_DIR)/$(APPNAME).com

clean:
	rm -fr $(BUILD_DIR)/*

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@ \
		`$(FINDSYM) ../../build/rom.sym acia_putc acia_getc_nw sn_beep dirty_sector bios_prbyte fsize`

$(BUILD_DIR)/$(APPNAME).raw: $(OBJS)
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG) $^ -o $@ -m $(BUILD_DIR)/$(APPNAME).map -Ln $(BUILD_DIR)/$(APPNAME).sym \

$(BUILD_DIR)/$(APPNAME).com: $(BUILD_DIR)/$(APPNAME).raw
	$(LOADTRIM) build/$(APPNAME).raw build/$(APPNAME).com $(LOAD_ADDR)
