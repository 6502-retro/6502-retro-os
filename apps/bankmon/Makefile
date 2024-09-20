# Sources and objects
C_SOURCES = \
	  func.s \
	  main.c
APPNAME = bankmon

# DO NOT EDIT THIS
include ../Make.rules# Sources and objects

$(BUILD_DIR)/$(APPNAME).raw: $(C_SOURCES)
	mkdir -pv $(BUILD_DIR)
	$(CC) $(CCFLAGS) -o $(BUILD_DIR)/$(APPNAME).raw $(C_SOURCES) -I ../lib ../lib/build/sfoslib.lib

$(BUILD_DIR)/$(APPNAME).bin: $(BUILD_DIR)/$(APPNAME).raw
	$(LOADTRIM) $^ $@ $(LOAD_ADDR)

