# Sources and objects
C_SOURCES = \
	  main.c
AS_SOURCES = \
	     vdp.s
APPNAME = conway

# DO NOT EDIT THIS
include ../Make.rules# Sources and objects

$(BUILD_DIR)/$(APPNAME).raw: $(C_SOURCES)
	mkdir -pv $(BUILD_DIR)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/vdp.lst -o $(BUILD_DIR)/vdp.o $(AS_SOURCES) -I ../lib
	$(CC) $(CCFLAGS) -o $(BUILD_DIR)/$(APPNAME).raw $(C_SOURCES) -I ../lib ../lib/build/sfoslib.lib $(BUILD_DIR)/vdp.o

$(BUILD_DIR)/$(APPNAME).bin: $(BUILD_DIR)/$(APPNAME).raw
	$(LOADTRIM) $^ $@ $(LOAD_ADDR)

