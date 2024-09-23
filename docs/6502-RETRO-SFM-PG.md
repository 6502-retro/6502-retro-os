<!-- vim: set ft=markdown cc=80 tw=80 : -->
# 6502-RETRO-SFM - PROGRAMMERS GUIDE

## Table of Contents

- [Chapter 1: Introduction](#chapter-1-introduction)

## Chapter 1: Introduction

The programmers guide explains how to write transient applications for the SFM
operating system.

These are the core principals to keep in mind when designing applications for
the 6502-Retro OS:

- Applications can be loaded into memory starting at the TPA (Transient Program
Address) and can fill memory up to TPA_END.  See the [memory
linker](../config/rom_8k.cfg) for the symbols that declare these values.
- The address to load into is given by the L1,L2 (load address) and E1,E2
(execute address) on the file FCB.
- At present there is header support for files uploaded via XMODEM to set the
load address.  The execution address is automatically copied from the load
address by the xmodem.com application
- As much as possible use the SFOS entry points for working with files and
serial IO.
- There are also the [BIOS jump table in SYSTEM ram](../bios/bios.s) which can
be used if you prefer a more low level interface.
- There is an included header file for working with C if you prefer.
- Look at the example code in [apps](../apps/) for inspiration.

## Chapter 2: Serial Input / Output

SFOS Provides 5 functions for handling user IO.

- void sfos_c_printstr(const char * text);
- void sfos_c_write(const uint8_t c);
- uint8_t sfos_c_read();
- void sfos_c_readstr(uint8_t len, char * buf);
- uint8_t sfos_c_status();

In most cases, these should be sufficient.  The sfos_c_readstr() will
automatically echo the entered characters back to the serial terminal.  The
output functions (printstr and write) will also check for a CTRL+C at each
character outputted.  If one is found a warm boot is executed and your program
will be existed and the user returned to the OS prompt at drive A:

The BIOS equivalents are:

- bios_conout ; $209
- bios_conin  ; $20B
- bios_const  ; $20F
- bios_puts   ; $212
- bios_prbyte ; $215

Note there is no assembly bios routine for reading in a line of text to match
the `sfos_c_readstr()` function.

The bios functions do not automatically echo text back to the terminal or check
for CTRL+C.

### Serial Settings

The serial interface does not support hardware flow control.  A future revision
of the PCB will have a jumper for enabling RTS or not.

Set up your serial terminal to use 115200 BAUD, 8 data bits and 1 stop bit.
(115200-8N1)

## Chapter 3: File Headers for XModem

When an application is loaded by the XModem utiltiy it reads the first 2 bytes
of the file to determin the LOAD address (L1,L2) in the FCB.  These values are
also copied into the execution address (E1,E2) in the FCB.

### TODO: Enhance File Headers

A future enhancment to XModem will be to support file types with the following
header structure:

|Offset|Description
|------|-----------
|0     |Header type*
|1-2   |Load Address
|3-4   |Execution Address

- Header type:
  - 0 No load or execution address.  Data starts at offset 1.
  - 1 Load address only.  Low byte followed by high byte, data starts at offset
     3.
  - 2 Load address and execution address.  Low bytes followed by high bytes,
   data starts at offset 5.

Example file with load address and execution address set:

```text
0000: 02 00 08 e4 10 30 31 32 ... | .....012
```

- Header type = 02
- Load address = 0x0800
- Execution address = 0x10E4

Example file with load address only set.

```text
0000: 01 00 08 30 31 32 33 34 ... | ...01234
```

- Header type = 01
- Load address = 0x0800
- Execution address = 0x0800 (default set by xmodem to match load address)

Example file with no load address or execution address:

```text
0000: 00 30 31 32 33 34 35 36 ... | .0123456...
```

- Header type = 00
- Load address = 0000 (xmodem will set this to zero)
- Execution address = 0000 (xmodem will set this zero)
