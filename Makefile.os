TOP=.

include $(TOP)/Make.default
-include $(TOP)/Make.local

INCLUDES :=-I$(TOP)/inc
ASFLAGS  +=$(INCLUDES) --feature labels_without_colons --cpu $(CPU) --feature string_escapes

BUILD    =build

SRC_BIOS=$(wildcard $(TOP)/bios/*.s)
SRC_SFOS=$(wildcard $(TOP)/sfos/*.s)
SRC_SFCP=$(wildcard $(TOP)/sfcp/*.s)

OBJ_BIOS=$(SRC_BIOS:%.s=%.o)
OBJ_SFOS=$(SRC_SFOS:%.s=%.o)
OBJ_SFCP=$(SRC_SFCP:%.s=%.o)

.PHONY: all clean

all: $(BUILD)/rom.raw

%.o:%.s
	@mkdir -pv $(BUILD)/$$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD)/$*.lst -o $@ $^

$(BUILD)/rom.raw: $(OBJ_SFCP) $(OBJ_SFOS) $(OBJ_BIOS)
	@mkdir -p $(BUILD)
	$(LD) -C $(CFG) -m $(BUILD)/rom.map -Ln $(BUILD)/rom.sym -o $@ $^

clean:
	rm -frv $(BUILD)
	rm -fv $(OBJ_BIOS) $(OBJ_SFCP) $(OBJ_SFOS)
	find . -name "*.lst" -exec rm -fv {} \;

all: $(BUILD)/rom.raw

