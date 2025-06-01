# Sources and objects
# Sources and objects
C_SOURCES = \
	  main.c
AS_SOURCES = \
	     vdp.s
APPNAME = snake

# DO NOT EDIT THIS
include ../Make.rules# Sources and objects

$(BUILD_DIR)/$(APPNAME).raw: $(C_SOURCES)
	mkdir -pv $(BUILD_DIR)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/vdp.lst -o $(BUILD_DIR)/vdp.o $(AS_SOURCES) -I ../lib
	$(CC) $(CCFLAGS) -o $(BUILD_DIR)/$(APPNAME).raw $(C_SOURCES) -I ../lib ../lib/build/sfoslib.lib $(BUILD_DIR)/vdp.o

$(BUILD_DIR)/$(APPNAME).bin: $(BUILD_DIR)/$(APPNAME).raw

copy: clean $(BUILD_DIR)/$(APPNAME).com
	../../py_sfs_v2/cli.py rm -i ../../py_sfs_v2/6502-retro-sdcard.img -d g://snake.com
	../../py_sfs_v2/cli.py cp -i ../../py_sfs_v2/6502-retro-sdcard.img -s build/snake.com -d g://snake.com
