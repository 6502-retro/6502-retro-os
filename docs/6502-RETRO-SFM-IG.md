<!-- vim: set ft=markdown cc=80 tw=80 : -->
# 6502-RETRO-SFM - INTEGRATION GUIDE

## Table of Contents

- [Chapter 1: Introduction](#chapter-1-introduction)
- [Chapter 2: File System Internals](#chapter-2-filesystem-internals)
- [Chapter 3: BIOS](#chapter-3-bios)

## Chapter 1: Introduction

This document describes the internals of the SFM operating system and the
backend filesystem it's built on.

A common question asked when talking about this project is, "Why didn't you just
impliment FAT16 or FAT32?"  It's a valid question.  Certainly, if I'd gone with
a standard filesystem, we could easily transfer files to the SD card on a modern
computer.  Doing so, however, would strip away any chance of learning what it
takes to write one's own filesystem from scratch.  That means designing a layout
and choosing how the data will be arranged on the disk.  This was a major driver
for me choosing to go with my own design.

Before I started, I laid out two core objectives for the filesystem.  I hope
that by clarifying them here, the design choices you will see in the later
chapters will seem less arbitrary.

1. Easy to debug.  The filesystem should be easy to understand and reverse
   engineer with only a minimal amount of documentation.
2. Must support SDHC type SD cards.  Other types are not supported.  This is
   mainly due to the simple fixed 512 byte sector size and logical block
   addressing mode.

## Chapter 2: Filesystem Internals

This chapter will contain a few tables and will deal mainly in Logical Block
Addresses (LBA).  The LBA is the 32 bit sector number on the SD card.  Each
sector is 512 bytes.  You can think of a sector as the minimum unit of storage
on the SD card.  So any time the operating system needs to write data to or
fetch data from the sdcard, it will do so in 512 byte sectors.  One sector at a
time.

### Sector 0x00000000: ID

The ID Sector contains some basic metadata about the filesystem.

|Offset  |Value      |Description
|--------|--------   |---------------------------------------------
|00-07   |SFMDISK    | 8 Byte ascii name of the drive.
|08-11   |0002       | 4 Byte version number in ascii.
|510-511 |0xBB66     | SFM Signature (randomly invented value)

### Sectors 0x80 - 0xFF: Directories

There are 8 drives with each drive able to support 256 files.  Each file is
referneced by a directory entry (dirent) which is stored in one of these
sectors.  The relationship between drives dirents and directory sectors is given
below:

| LBA      | Drive
|----------|-------
|0x80-0x8F | Drive A
|0x90-0x9F | Drive B
|0xA0-0xAF | Drive C
|0xB0-0xBF | Drive D
|0xC0-0xCF | Drive E
|0xD0-0xDF | Drive F
|0xE0-0xEF | Drive G
|0xF0-0xFF | Drive H

There are 16 sectors per drive.  Each dirent consumes 32 bytes so each sector
can support 16 dirents.  16x16 = 256 and that's where the 256 file count limit
comes from.

#### Directory Entry

A dirent is a 32byte structure that desribes a file on disk.  It contains all
the information required by SFM to locate the data sectors as well as to
uniquely identify the file, where to load it into memory when opened, and where
(in case of `.com` executable) to jump to to begin program execution.

|Offset | Ref |Description
|-------|-----|----------------
|  0    | DD  | drive
|  1    | N1  | filename char 1
|  2    | N2  | filename char 2
|  3    | N3  | filename char 3
|  4    | N4  | filename char 4
|  5    | N5  | filename char 5
|  6    | N6  | filename char 6
|  7    | N7  | filename char 7
|  8    | N8  | filename char 8
|  9    | T1  | extension char 1
| 10    | T2  | extension char 2
| 11    | T3  | extension char 3
| 12    | L1  | load low byte
| 13    | L2  | load high byte
| 14    | SC  | sector count
| 15    | FN  | file number
| 16    | FA  | file attribute
| 17    | E1  | execute low
| 18    | E2  | execute high
| 19    | Z1  | last byte offset low
| 20    | Z2  | last byte offset hight
| 21    | S0  | filesize low
| 22    | S1  | filesize middle
| 23    | S2  | filesize high
| 24    | S3  | filesize unused
| 25    | CR  | current record
| 26-31 | XX  | unused

### Sectors 0x010000 - 0x07FFFF: Data

Actual file data is stored in sectors assigned by the drive + file number.  The
way this works is shown below:

```text
   Sector LBA: 0xDDFNxx

   - DD = Drive number (0x01 - 0x07) matching A - H
   - FN = File Number  (0x00 - 0xFF) There can be 256 files per drive.
   - xx = sectors used by the file.  There can be 256 sectors in a single file.
```

Like this it's very easy to find the start of data for a given file.  Just look
at the directory index, retreive the `DD` and `FN` bytes from the structure and
build an LBA address with xx=0x00 to get the start of the file data.

To read a file, simply keep reading the next LBA from the SDCARD and
decrementing the `SC` value from the dirent until `SC` = 0 or you hit the start
of the next file.

## Chapter 3: BIOS

The BIOS contains the low level routines that are responsible for interfacing
with your hardware.  The two primary harware drives you need to write are:

- Serial interface driver
- SDCard driver

### Serial Interface Driver

The 6502-Retro! has an ACIA6551 on board but you can use any serial interface
you like so long as you impliment these 3 main functions:

#### Get Character - Blocking

Waits for a character from the serial interface and returns it in A when
received.

#### Get Character - Non Blocking

Checks for a character on the serial interface.  If none is available return
carry clear, and A = 0.  Otherwise return carry Set and the value in A.

#### Put Character

Writes the character in A to the serial terminal.

### SDCARD Interface Driver

Typically the SDCARD interface is done via SPI against the SDCARD SPI interface.
How you impliment your storage solution is very much up to you, so long as the
interfaces you provide match the following specifications:

#### Write SD Card Sector

Writes 512 bytes of data to a sector at the LBA address provided.  There are
other BIOS interfaces used to store and manage the LBA address.  The data
written must start at the given DMA address.  Again there are BIOS interfaces
used to store and manage the DMA address.  DMA here just refers to the address
in memory that the SD Card driver is working with to either save data to or read
data from.

The write SD Card Sector function will read data from the address defined by the
DMA and write it to the sector addressed by the LBA.

#### Read SD Card Sector

Reads a single sector from the SD Card at the given LBA address and writes it
into memory at the current DMA address.

The Operating system will call the SETDMA and SETLBA routines to save this
information so your BIOS needs to provide them.

#### SET DMA

Sets the RAM address that will be used by the next call to a Write Sector or
Read Sector SD Card operation.

#### SET LBA

Sets the LBA address that will be used by the next call to a Write Sector or
Read Sector SD Card operation.

### Other drive hardware routines

You are free to impliment any other routines you like in your bios.  A
convenient jump table is provided at the SYSTEM Memory address space starting at
0x200.  This page of ram can contain any memory banking routines you might need
as well as bios jump routines that you might want to make available as known
locations by your applications. The most useful ones of these are the:

```asm
    jmp dispatch    ; 0x200
    jmp bios_boot   ; 0x203
    jmp bios_wboot  ; 0x206
```

- dispatch: function dispatcher.  Saves XA into zp `param` and expects Y to
point to an index in the SFOS function table.  The routine will store the XA
arguments and jump to the routine indexed by Y.  This is how calls are made into
the Operating system so the BIOS must place the jump vector table at 0x200 so
the dispatch function is always at 0x200.
- bios_boot: this is the code boot routine.  It will cause the whole of system
memory to be refreshed including this jump table.
- bios_wboot: Function to return back to the SFCP.

As long as these functions are at this known location, then some of the
applications written for the OS will work.  I say some, because some of them
expect raw access to bios routines which might not be provided by the person
porting the OS.
