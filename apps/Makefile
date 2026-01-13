#****************************************************************************
#
#    Copyright (C) 2025 David Latham
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
#    USA
#
# https://github.com/6502-retro/6502-retro-os
#
#****************************************************************************

SUBDIRS =   \
	C         \
	asm       \
	bankmon   \
	bytetst   \
	cat       \
	cls       \
	conway    \
	copy      \
	dump      \
	ehbasic   \
	format    \
	hello     \
	irq       \
	mon       \
	msbasic   \
	sfmvi     \
	shadowrom \
	statc     \
	submit    \
	uart      \
	vgm       \
	xm


CLEAN_DIRS=$(SUBDIRS:%=clean-%)
ALL_DIRS=$(SUBDIRS:%=all-%)

.PHONY: all clean world $(CLEAN_DIRS) $(ALL_DIRS)

TOP=..
include $(TOP)/Make.default
-include $(TOP)/Make.local

all:: $(ALL_DIRS)

lib:
	$(MAKE) -C lib

$(ALL_DIRS):
	$(MAKE) -C lib
	$(MAKE) -C $(@:all-%=%) all

$(CLEAN_DIRS):
	$(MAKE) -C $(@:clean-%=%) clean

clean:: $(CLEAN_DIRS)
	$(MAKE) -C lib clean

world:: clean all


