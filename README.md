<!-- vim: set ft=markdown ts=4 sw=4 tw=80 cc=80: -->
# 6502-Retro Operating System

The 6502-Retro computer is a single board computer with the following harware
features:

- ROM: 64KB (4 x 16kb banks) or 4x8kb banks.  Note: the hardware supports the
SST27SF512 Flash rom.  The pin out is not the same as the popular 28C256 EEPROM
so don't try to swap it out.
- RAM: 47.767KB 0x0000 - 0xBEFF
- EXTENDED RAM: 512KB (64 x 8kb banks 0xC000-0xDFFF)

**NOTE:** Check the [memory map](./docs/6502-RETRO-MEMORY-MAP.md) for the 8k rom
layout.

- SDCARD (Supports SDHC Cards - tested with 8GB SDHC cards)
- 4MHz CPU
- Rockwell ACIA 6551 Serial interface
- F18A or Pico9918 (tms9918a emulator)
- TMS76489 Sound Generator

Schematic is available [here.](./docs/6502-retro-bank-v3.1.pdf)

## Boot Loader

On power up the Bootloader is ready to go.

```text
6502-Retro Bootloader Utility
-----------------------------

Enter desired slice:
1 - 6502-retro-os
M - Monitor ROM
X - Load from XMODEM
```

The bootloader will copy itself into low ram and disable the ROM thus enabling
RAM at address 0xE000 - 0xFFFF.  Once loaded, the operating system runs entirly
out of RAM.

- `1` to boot the OS.  This is accomplished by loading SDCard sectors from 1 to
  17 into RAM starting at 0xE000.
- `M` to enter the monitor rom.
- `X` to load into ram using XModem.  The binary file you load this way must
have the load address as the first two bytes of the file.  This way you can load
your own operating system during development for example.

## Operating System

The OS is a CP/M like enviornment taylored specifically for the 6502-Retro!.
The filesystem features are limited and simple to understand and yet provide
enough capability to run programs, upload new programs into the filesystem, copy
and erase files, and generally manage your data.

A more detailed overview of the SFM Operating System is described
[here](./docs/6502-RETRO-SFM-UG.md).

## Built in ROM banks

There are 4 available ROM banks.

- BANK 0: Bootloader
- BANK 1: Memory Monitor


