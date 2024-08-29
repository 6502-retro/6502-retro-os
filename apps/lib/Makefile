# Assembler, linker and scripts
AS = ca65
LD = ld65
CC = cl65
AR = ar65

TOP = ..
INCLUDES = -I $(TOP)/../inc

# Assembler flags
ASFLAGS += $(INCLUDES) -g --feature labels_without_colons --cpu 65C02 --feature string_escapes

BUILD_DIR = build

SOURCES = \
	  sfos_c_write.s \
	  sfos_c_read.s \
	  sfos_c_printstr.s \
	  sfos_c_readstr.s \
	  sfos_c_status.s \
	  sfos_d_setdma.s \
	  sfos_d_parsefcb.s \
	  sfos_d_findfirst.s \
	  sfos_d_make.s \
	  sfos_d_open.s \
	  sfos_d_readseqblock.s \
	  sfos_d_writeseqblock.s \
	  sfos_s_warmboot.s

OBJS = $(addprefix $(BUILD_DIR)/, $(SOURCES:.s=.o))

all: clean $(BUILD_DIR)/sfoslib.lib

clean:
	rm -fr $(BUILD_DIR)/*

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

$(BUILD_DIR)/sfoslib.lib: $(OBJS)
	cp ../../../cc65/lib/none.lib $@
	$(AR) a $@ $(OBJS)
