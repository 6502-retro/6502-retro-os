#!/usr/bin/env bash
find . -name "*.s" | entr -s 'clear; make && grep bios_boot build/rom.sym'
