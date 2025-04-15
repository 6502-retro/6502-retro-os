# Assembler, linker and scripts
AS = ca65
LD = ld65
RELIST = scripts/relist.py
FINDSYM = scripts/findsymbols
LOADTRIM = scripts/loadtrim.py
TTY_DEVICE = /dev/ttyUSB0

# Assembler flags
ASFLAGS += -I inc -g --feature labels_without_colons --cpu 65C02 --feature string_escapes

# Set DEBUG=1 for debugging.
DEBUG = -D DEBUG=0

# Set CFG to the config for size of rom
CFG = rom.cfg

SDDEVICE = /dev/sdd

# Where should the builds be placed
BUILD_DIR = build

# Sources and objects
BIOS_SOURCES = \
	       bios/bios.s \
	       bios/acia.s \
	       bios/sdcard.s \
	       bios/sn76489.s \
	       bios/zerobss.s \
	       bios/via.s \
	       bios/vectors.s \

BIOS_OBJS = $(addprefix $(BUILD_DIR)/, $(BIOS_SOURCES:.s=.o))

SFOS_SOURCES = \
	       sfos/sfos.s

SFOS_OBJS = $(addprefix $(BUILD_DIR)/, $(SFOS_SOURCES:.s=.o))

SFCP_SOURCES = \
	       sfcp/sfcp.s

SFCP_OBJS = $(addprefix $(BUILD_DIR)/, $(SFCP_SOURCES:.s=.o))

all: clean $(BUILD_DIR)/rom.raw

clean:
	rm -fr $(BUILD_DIR)/*

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) $(DEBUG) -l $(BUILD_DIR)/$*.lst $< -o $@

$(BUILD_DIR)/rom.raw: $(SFCP_OBJS) $(SFOS_OBJS) $(BIOS_OBJS)
	@mkdir -p $$(dirname $@)
	$(LD) -C config/$(CFG) $^ -o $@ -m $(BUILD_DIR)/rom.map -Ln $(BUILD_DIR)/rom.sym
	$(RELIST) $(BUILD_DIR)/rom.map $(BUILD_DIR)/bios
	$(RELIST) $(BUILD_DIR)/rom.map $(BUILD_DIR)/sfos
	$(RELIST) $(BUILD_DIR)/rom.map $(BUILD_DIR)/sfcp
	$(LOADTRIM) $(BUILD_DIR)/rom.raw $(BUILD_DIR)/rom.bin E000

grep:
	grep bios_boot $(BUILD_DIR)/ram.sym

lines:
	cloc --exclude-dir=py_sfs_v2,.gitignore,scripts,msbasic,ehbasic .

burn:
	sudo dd if=$(BUILD_DIR)/rom.raw seek=1 bs=512 count=16 of=$(SDDEVICE)
