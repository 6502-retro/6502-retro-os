<!-- vim: set ft=markdown cc=80 tw=80 : -->

# 6502-RETRO-SFM - OPERATING SYSTEM ROUTINES

## Table of Contents

- [Chapter 1: Introduction](#chapter-1-introduction)
- [Chapter 2: File System Internals](#chapter-2-filesystem-internals)
- [Chapter 3: BIOS](#chapter-3-bios)
- [Chapter 4: SFOS](#chapter-4-sfos)

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
| 20    | Z2  | last byte offset high
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

The 6502-Retro! has an ACIA 6551 on board but you can use any serial interface
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

#### Set DMA

Sets the RAM address that will be used by the next call to a Write Sector or
Read Sector SD Card operation.

#### Set LBA

Sets the LBA address that will be used by the next call to a Write Sector or
Read Sector SD Card operation.

### LED and user button routines

#### LED on

Turns on the LED

#### LED off

Turns off the LED

#### Get Button

Returns 1 if button is pressed.  Note the user button is pulled high through a
10kohm resistor while open and pressing the button connects it to ground.  This
routine inverts the value read by the VIA so that a `1` means pressed and a `0`
means released.

### Tick Counter

The Pico9918 interrupts 60 times a second.  The 32bit _tick variable is used to
record the number of ticks since the last reset.  It's not an exact science but
it should give an approximation of time.  The number of elapsed ticks can be
used to measure a second of time for example.  Just wait until (long) ticks has
increased by 60.

This is by no means accurate.

The bios sets up the pico9918 to trigger the interrupts.

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

## Chapter 4: SFOS

The SFOS is a collection of routines that the programmer can call to interface
with the operating system.  It stands for Simple Filesystem Operating System.

The SFCP (See Chapter 5) uses these same calls to provide the user interface to
the operating system.

The functions provide access to the Serial interface and the filesystem.

### Errors

SFOS will report errors by setting the carry flag and storing the error
condition in the [ERROR_CODE memory address](./6502-RETRO-MEMORY-MAP.md).

- **0 OK** Success / no error
- **1 FILE_NOT_FOUND** File not found
- **2 FILE_EXISTS** Returned by `d_make` when requested file exists
- **3 FILE_MAX_REACHED** Returned when file max size is reached (128kb)
- **4 FILE_EOF** Returned when file end is reached. Usually with carry set.
- **5 END_OF_DIR** Returned by `d_findfirst` when trying to find an empty directory
entry.
- **6 DRIVE_ERROR** Any error encountered with calling low level sdcard routines.
- **7 DRIVE_FULL** Returned by `d_make` when its internal call to `d_findfirst`
returns END_OF_DIR
- **8 PARSE_ERROR** Returned by `d_parsefcb` when the FCB can not be parsed.
- **9 OUT_OF_MEMORY** Returned by the SFCP when trying to load a file into memory
and the top of ram is reached.

### List of SFOS Routines

Each function has a number.  This number is passed by the Y register and any
arguments are given in XA which is either two bytes, a word, or a pointer.  The
dispatch function assumes its a pointer and assignes the value into the `param`
zeropage variable.

|Number|Name
|-----:|-----------------
|   0  |[s_reset](#0---s_reset)
|   1  |[c_read](#1---c_read)
|   2  |[c_write](#2---c_write)
|   3  |[c_printstr](#3---c_printstr)
|   4  |[c_readstr](#4---c_readstr)
|   5  |[c_status](#5---c_status)
|   6  |[d_getsetdrive](#6---d_getsetdrive)
|   7  |[d_createfcb](#7---d_createfcb)
|   8  |[d_parsefcb](#8---d_parsefcb)
|   9  |[d_findfirst](#9---d_findfirst)
|   10 |[d_findnext](#10---d_findnext)
|   11 |[d_make](#11---d_make)
|   12 |[d_open](#12---d_open)
|   13 |[d_close](#13---d_close)
|   14 |[d_setdma](#14---d_setdma)
|   15 |[d_readseqblock](#15---d_readseqblock)
|   16 |[d_writeseqblock](#16---d_writeseqblock)
|   17 |[d_readseqbyte](#17---d_readseqbyte)
|   18 |[d_writeseqbyte](#18---d_writeseqbyte)
|   19 |[d_setlba](#19---d_setlba)
|   20 |[d_readrawblock](#20---d_readrawblock)
|   21 |[d_writerawblock](#21---d_writerawblock)

### SFOS Routines

#### 0 - s_reset

INPUT: VOID
| A | X | Y
|---|---|--
| - | - | 0

OUTPUT: VOID
| A | X | Y | Carry | Error Code
|---|---|---|-------|:----------
| - | - | - | -     | -

Resets with a warm boot and logs into drive A.

#### 1 - c_read

INPUT: VOID
| A | X | Y
|---|---|--
| - | - | 1

OUTPUT: CHAR
| A         | X | Y | Carry | Error Code
|-----------|---|---|-------|:----------
| Character | - | - | -     | -

Waits for a character on the serial interface and returns it in A.

#### 2 - c_write

INPUT: CHAR
| A         | X | Y
|-----------|---|--
| Character | - | 2

OUTPUT: CHAR
| A         | X | Y | Carry | Error Code
|-----------|---|---|-------|:----------
| Character | - | - | -     | -

Writes the character in A to the serial interface.  Character written is
returned in A.  After sending the character to the serial interface, this
routine checks for a CTRL+C on the input and jumps to `s_reset` if found.
Effectively this means that during output to the serial interface a CTRL+C from
the user will warm boot the system.

#### 3 - c_printstr

INPUT: POINTER TO STRING
| A         | X      | Y
|-----------|--------|--
| Lobyte    | Hibyte | 3

OUTPUT: VOID
| A | X | Y | Carry | Error Code
|---|---|---|-------|:----------
| - | - | - | -     | -

Prints the zeroterminated string pointed to by XA to the serial interface.
Internally, this routine calls c_write to write each character to the serial
interface.

#### 4 - c_readstr

INPUT: POINTER TO BUFFER
| A         | X      | Y
|-----------|--------|--
| Lobyte    | Hibyte | 4

OUTPUT: UPDATED BUFFER
| A | X | Y | Carry | Error Code
|---|---|---|-------|:----------
| - | - | - | -     | -

Reads a line of text from the serial interface terminated by a newline.  The
characters read are appended to the buffer pointed to by XA.  The first
character of the buffer pointed to by XA contains the maximum length of the
input line.  The maximum length of the buffer is 127 characters regardless of
the value given in the first byte of the buffer.  On exit this routine will
replace the first byte of the buffer with the actual length of the text entered.

#### 5 - c_status

INPUT: VOID
| A | X | Y
|---|---|--
| - | - | 5

OUTPUT: CHAR & CARRY FLAG STATUS
| A         | X | Y | Carry | Error Code
|-----------|---|---|-------|:----------
| Character | - | - | C/S   | -

- Carry is CLEAR when there is no byte waiting.
- Carry is SET when a byte was found.
- A contains the character if one is found else 0

Checks if a character is waiting on the serial interface.  If one is found, the
carry flag is set and the character is returned in A.  If no data is present on
the serial interface, then the carry flag is cleared and a 0 is returned in A.

#### 6 - d_getsetdrive

INPUT: BYTE
| A             | X | Y
|---------------|---|--
| DRIVE or 0xFF | - | 6

OUTPUT: BYTE & CARRY FLAG STATUS
| A         | X | Y | Carry | Error Code
|-----------|---|---|-------|:----------
| DRIVE or ?| - | - | C/S   | DRIVE ERROR

- Carry is CLEAR when there is no error.
- Carry is SET when there is an error.
- A contains the drive if one was requested with input 0xFF

If A = 0xFF on input then return the current logged in drive in A.  Otherwise
set the drive to the value provided in A.  A DRIVE ERROR can occur if the given
drive number is out of bounds.  Valid values for the input to this function are
0x01 (for DRIVE A) to 0x08 (for DRIVE H) for setting the drive or 0xFF to "get"
the current drive.

When a drive is first logged into, a scan of the drive is carried out to
determin the position of the last used file on the drive.  This helps to reduce
the time spent searching for files in `d_findfirst` and `d_findnext` routines.

#### 7 - d_createfcb

Unimplimented

#### 8 - d_parsefcb

INPUT: POINTER TO BUFFER (PREVIOUSLY SET DMA TO FCB)
| A         | X      | Y
|-----------|--------|--
| Lobyte    | Hibyte | 8

OUTPUT: UPDATED FCB
| A         | X      | Y | Carry   | Error Code
|-----------|--------|---|---------|:----------
| Lobyte    | Hibyte | - | C/S     | PARSE ERROR

Parse the string pointed to by XA into an FCB pointed to by the DMA pointer.
The DMA pointer must be set by a call to `d_setdma` before calling this
function.  The routine returns with XA pointing at the next character in the
input buffer after the parsed string.  If there was no error, the carry flag is
clear on return else it is set and the error code is set to PARSE ERROR.

#### 9 - d_findfirst

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|--
| Lobyte    | Hibyte | 9

OUTPUT: UPDATED FCB
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:-----------------------------------
| - | - | - | C/S     | DRIVE ERROR or FILE NOT FOUND ERROR

Finds the first filename matching the filename given in the FCB pointed to by
XA.  The find routine will seach in the drive given by the FCB if a drive number
is provided.  If the provided drive number is 0 then the current drive is
searched.  

If the drive number is 0xE5 then d_findfirst will return the first
available / deleted directory entry.  Use this to find an empty file slot in the
directory table - used internally by `d_make`

The search is case insenstive as all filenames are normalized to UPPER CASE.

The search begins at the beginning of the drive.

The search ends when the last directory is scanned.  The last directory is that
recorded in the file table memory structure when the drive was "logged into".

The search will honor the ? wildcard to match on any single characer.  The `*`
wildcard may also be used which will match on all characters from the position
of the `*` until the end of the filename or the extension depending on which
side of the `.` the wildcard is provided.

The results of the serch are stored into the input FCB.  The carry flag is set
on error and clear on success.

#### 10 - d_findnext

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 10

OUTPUT: UPDATED FCB
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:-----------------------------------
| - | - | - | C/S     | DRIVE ERROR or FILE NOT FOUND ERROR

Finds the next filename matching the filename given in the FCB pointed to by
XA.  The find routine will seach in the drive given by the FCB if a drive number
is provided.  If the provided drive number is 0 then the current drive is
searched.

If the drive number is 0xE5 then d_findfirst will return the first
available / deleted directory entry.  Use this to find an empty file slot in the
directory table - used internally by `d_make`

The search is case insenstive as all filenames are normalized to UPPER CASE.

The search begins at the end of a result from a call to `d_findfirst`.

The search will honor the ? wildcard to match on any single characer.  The `*`
wildcard may also be used which will match on all characters from the position
of the `*` until the end of the filename or the extension depending on which
side of the `.` the wildcard is provided.

The results of the serch are stored into the input FCB.  The carry flag is set
on error and clear on success.  

#### 11 - d_make

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 11

OUTPUT: UPDATED FCB
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR, FILE_EXISTS, END_OF_DIR

; param points to FCB containing filename to create.
; Returns updated FCB containing Drive, FN and CR
; Uses temp_fcb to stash the incomming fcb so the filename can be
; extracted and restored over the new FCB found.

Finds a free / unused directory entry in the current drive or the drive given in
the FCB if one is provided.  The provided FCB is updated with the file number
(`FN`) and the provided filename.  The file attribute (`FA`) is set to 0x40 and
all other metadata is set to 0.

Carry is set on error, clear on success.  Error condition is recorded in
ERROR_CODE and can be one of:

- DRIVE_ERROR
- FILE_EXISTS
- END_OF_DIR

#### 12 - d_open

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 12

OUTPUT: UPDATED FCB
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:---------------------------
| - | - | - | C/S     | DRIVE ERROR, FILE_NOT_FOUND

XA Points to an FCB containing the drive and file pattern to open.  When a file
is found, the FCB is updated with the details of the file taken from the
directory entry on disk.

#### 13 - d_close

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 13

OUTPUT:
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR

XA points to an FCB to close.  If the FCB is marked as "dirty" meaning there
could be more data to write to disk, that data is written to disk first.  After
the dirty sector is flushed, the FCB is flushed back into the directory sector
containing its directory entry.

#### 14 - d_setdma

INPUT: POINTER TO ADDRESS
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 14

OUTPUT:
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | -       | -

XA is a pointer to an address in memory that will be used as the DMA address for
subsequent disk reads or writes.

#### 15 - d_readseqblock

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 15

OUTPUT: DATA WRITTEN TO DMA ADDRESS
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR

XA points to the FCB relating to the block read.  The FCB current record (`CR`)
field is incremented and then the sdcard LBA address is calculated by combining
the FCB drive (`DD`), file number (`FN`) and current record (`CR`).  The sector
at that address is read into the DMA address given by a previous call to
`d_setdma`

#### 16 - d_writeseqblock

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 16

OUTPUT: DATA COPIED FROM DMA TO SDCARD
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR, FILE_MAX_REACHED

XA points to the FCB relating to the block being written to.  The sdcard LBA is
calculated by combining the FCB drive (`DD`), file number (`FN`) and current
record (`CR`).  The sector is written from the DMA address given by a previous
call to `d_setdma`.  After the sector write is complete, the FCB current record
(`CR`) is incremented.  If the `CR` increment results in `CR` being equal to 0
then a FILE_MAX_REACHED error is returned.

#### 17 - d_readseqbyte

INPUT: POINTER TO FCB
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 17

OUTPUT: CHAR
| A         | X | Y | Carry   | Error Code
|-----------|---|---|---------|:------------------------------------
| Character | - | - | C/S     | DRIVE ERROR

#### 18 - d_writeseqbyte

INPUT: POINTER TO FCB, CHAR IN REGA
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 18

OUTPUT: VOID
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR

#### 19 - d_setlba

INPUT: POINTER TO 32BIT LBA ADDRESS IN LITTLE ENDIAN FORMAT
| A         | X      | Y
|-----------|--------|---
| Lobyte    | Hibyte | 19

OUTPUT: VOID
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR

#### 20 - d_readrawblock

Unimplimented

#### 21 - d_writerawblock

INPUT: VOID
| A | X | Y
|---|---|---
| - | - | 21

OUTPUT:
| A | X | Y | Carry   | Error Code
|---|---|---|---------|:------------------------------------
| - | - | - | C/S     | DRIVE ERROR

Writes a block of data to the previously set LBA address from the previously set
DMA address without impacting any FCBs.
