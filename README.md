<!-- vim: set ft=markdown ts=4 sw=4 tw=80 cc=80: -->
# 6502-Retro Operating System

The 6502-Retro computer is a single board computer with the following harware
features:

- ROM: 64KB (4 x 16kb banks) or 4x8kb banks.  Note: the hardware supports the
SST27SF512 Flash rom.  The pin out is not the same as the popular 28C256 EEPROM
so don't try to swap it out.
- RAM: 39.75KB 0x0000 - 0x9EFF
- EXTENDED RAM: 512KB (64 x 8kb banks 0xA000-0xBFFF)

**NOTE:** Check the [memory map](./docs/6502-RETRO-MEMORY-MAP.md) for the 8k rom
layout.

- SDCARD (Supports SDHC Cards)
- 4MHz CPU
- Rockwell ACIA 6551 Serial interface
- F18A or Pico9918 (tms9918a emulator)
- TMS76489 Sound Generator

Schematic is available [here.](./docs/6502-retro-bank-v3.pdf)

## Operating System

On powerup the SFM operating system present and ready.  The OS is a CP/M like
enviornment taylored specifically for the 6502-Retro!.  The filesystem features
are limited and simple to understand and yet provide enough capability to run
programs, upload new programs into the filesystem, copy and erase files, and
generally manage your data.

A more detailed overview of the SFM Operating System is described
[here](./docs/6502-RETRO-SFM-UG.md).

## Built in ROM banks

There are 4 available ROM banks.

- BANK 0: SFM Operating System
- BANK 1: Memory Monitor
