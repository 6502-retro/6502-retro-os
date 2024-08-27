# Assembler, linker and scripts
AS = ca65
LD = ld65
RELIST = scripts/relist.py
FINDSYM = scripts/findsymbols
LOADTRIM = scripts/loadtrim.py
TTY_DEVICE = /dev/ttyUSB0

# Assembler flags
ASFLAGS += -I inc -g --feature labels_without_colons --cpu 65C02 --feature string_escapes

SFM_LOAD_ADDR = 8000

# Where should the builds be placed
BUILD_DIR = build

# Sources and objects
BIOS_SOURCES = \
	       bios/acia.s \
	       bios/bios.s \
	       bios/sdcard.s \
	       bios/vectors.s \
	       bios/zerobss.s

BIOS_OBJS = $(addprefix $(BUILD_DIR)/, $(BIOS_SOURCES:.s=.o))

SFOS_SOURCES = \
	       sfos/sfos.s

SFOS_OBJS = $(addprefix $(BUILD_DIR)/, $(SFOS_SOURCES:.s=.o))

SFCP_SOURCES = \
	       sfcp/sfcp.s

SFCP_OBJS = $(addprefix $(BUILD_DIR)/, $(SFCP_SOURCES:.s=.o))

all: clean $(BUILD_DIR)/rom.bin

clean:
	rm -fr $(BUILD_DIR)/*

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

$(BUILD_DIR)/rom.raw: $(SFCP_OBJS) $(SFOS_OBJS) $(BIOS_OBJS)
	@mkdir -p $$(dirname $@)
	$(LD) -C config/rom.cfg $^ -o $@ -m $(BUILD_DIR)/rom.map -Ln $(BUILD_DIR)/rom.sym
	$(RELIST) $(BUILD_DIR)/rom.map $(BUILD_DIR)/bios
	$(RELIST) $(BUILD_DIR)/rom.map $(BUILD_DIR)/sfos
	$(RELIST) $(BUILD_DIR)/rom.map $(BUILD_DIR)/sfcp

$(BUILD_DIR)/rom.bin: $(BUILD_DIR)/rom.raw
	$(LOADTRIM) build/rom.raw build/rom.img $(SFM_LOAD_ADDR)

upload:
	sx -b --delay-startup 3 -X $(BUILD_DIR)/rom.img > $(TTY_DEVICE) < $(TTY_DEVICE)
