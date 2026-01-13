# Assembler, linker and scripts
TOP=../..
include $(TOP)/Make.default
-include $(TOP)/Make.local

INCLUDES = -I $(TOP)/inc
NONE = ./none.lib

# Assembler flags
ASFLAGS += $(INCLUDES) -g --feature labels_without_colons --cpu 65C02 --feature string_escapes

BUILD = build

SOURCES =                  \
	  sfos_wrappers.s        \
	  sfos_c_write.s         \
	  sfos_c_read.s          \
	  sfos_c_printstr.s      \
	  sfos_c_readstr.s       \
	  sfos_c_status.s        \
	  sfos_d_getsetdrive.s   \
	  sfos_d_setdma.s        \
	  sfos_d_parsefcb.s      \
	  sfos_d_findfirst.s     \
	  sfos_d_findnext.s      \
	  sfos_d_make.s          \
	  sfos_d_open.s          \
	  sfos_d_close.s         \
	  sfos_d_readseqblock.s  \
	  sfos_d_readseqbyte.s   \
	  sfos_d_writeseqblock.s \
	  sfos_d_writeseqbyte.s  \
	  sfos_d_setlba.s        \
	  sfos_d_writerawblock.s \
	  sfos_s_warmboot.s      \
	  sfos_s_settpa.s        \
	  sfos_s_gettpa.s        \
	  write.s                \
	  read.s


OBJS = $(SOURCES:.s=.o)

all: build $(BUILD)/sfoslib.lib

build:
	@mkdir -p $(BUILD)

clean:
	rm -fr $(BUILD)/*
	find . -name "*.o" -exec rm -fv {} \;

%.o: %.s
	$(AS) $(ASFLAGS) -l $(BUILD)/$*.lst $< -o $@

$(BUILD)/sfoslib.lib: $(OBJS)
	cp $(NONE) $@
	$(AR) a $@ $(OBJS)
