# Sources and objects
SOURCES = \
	  snake.s \
	  vdp.s
APPNAME = snake

copy: build/snake.com
	../../py_sfs_v2/cli.py rm -i ../../py_sfs_v2/6502-retro-sdcard.img -d g://snake.com
	../../py_sfs_v2/cli.py cp -i ../../py_sfs_v2/6502-retro-sdcard.img -s build/snake.com -d g://snake.com
# DO NOT EDIT THIS
include ../Make.rules# Sources and objects

