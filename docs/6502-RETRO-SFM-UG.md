<!-- vim: set ft=markdown cc=80 tw=80 : -->
# 6502-RETRO-SFM - USER GUIDE

## Table of Contents

- [Chapter 1: Introduction](#chapter-1-introduction)
- [Chapter 2: Filesystem Organisation](#chapter-2-filesystem-organisation)
- [Chapter 3: Intrinsic Commands](#chapter-3-intrinsic-commands)
- [Chapter 4: Supplied Utilities](#chapter-4-supplied-utilities)
- [Chapter 5: BASIC](#chapter-5-basic)

## Chapter 1: Introduction

This document describes the operating system available in Bank 0 of the
6502-Retro! homebrew computer designed and built by David Latham in 2024.

The operating system is less than 6KB in size so fits easily in one of the 16kb
ROM banks.  The OS assumes SDHC cards with 512byte sectors addressed by their
logical block address.  Any SDHC compliant card should do.

Many of the features (almost all of them actually) are inspired or copies of the
CP/M filesystem.  But that's where the similarities stop.  Under the hood, this
filesystem is very different to CP/M.  I'm not saying that SFM is better than
CP/M, in fact, it's no where near as useful as CP/M.  It is however, developed
from scratch in 6502 Assembly and designed for a simpler / easier to debug and
mange custom filesystem.

## Chapter 2: Filesystem Organisation

### Drives

The filesystem is divided into 8 drives named A - H.  Each drive can support up
to 256 files and each file can store up to 128kb of data.  These limits are
hardcoded and can not be altered.

In order to change to a different drive, simply type the drive letter followed
by a colon.  eg: `b:` or `B:`.

### Files

Files are case insenstive and are limited to 8 characters long with a 3
character file extension.  The `.com` file extension is reserved for executable
applications.

A Files can be up to 128kb in size and consume one of 256 available slots within
a drive.

You can use the included `COPY.COM` utility to copy files between drives.  There
is no rename functionality.  A rename is acheived by first copying a file to a
new name or optionally new drive.  Then erasing the original.

When working with filenames the `*` and `?` wildcard is also supported.  For
example, to run basic you could run:

```text
E>a:bas*.*
6502 EhBASIC

Memory size ?

27391 Bytes free

Enhanced BASIC 2.22p5

Ready
```

Or use a `?` for a single wildcard:

Dumps the binary contents of the `cat.com` application to screen.

```text
A>dump ca?.com
Dump

0000 | A9 00 A2 9F 85 00 86 01 20 18 0B 20 17 08 20 A8 | ........ .. .. .
0010 | 09 48 20 73 0A 68 60 A0 00 F0 07 A9 23 A2 08 4C | .H s.h`.....#..L
0020 | 90 0B 60 A9 8D A2 0B 20 40 0B 60 20 02 0B A0 01 | ..`.... @.` ....
0030 | 20 B5 0A 20 40 0B 20 74 0B 20 97 0A 60 20 02 0B |  .. @. t. ..` ..
```

## Chapter 3: Intrinsic Commands

There are a few intrinsic commands provided by the SFM operating system.

### BANK

Use the `bank` command to switch between physical rom banks on the 6502-Retro!
homebrew computer.

```text
A>bank 0
```

Switching to BANK 0 will take you back to the 6502-Retro! monitor.

### DIR (SFM)

```text
A>dir
    A: BASIC    COM : CAT      COM : CLS      COM : COPY     COM
    A: DUMP     COM : FORMAT   COM : STAT     COM : XM       COM
```

Displays a listing of the files on the current drive.  You can optionally invoke
`dir` with a drive letter as follows to list the files in the given drive.

```text
A>dir d:

Scanning drive...
    D: MAND     BAS : HIGHLOW  BAS : MANDANOY BAS : PRIMES   BAS
    D: RBTEST   BAS : SPEED    BAS
```

**NOTE:** When you first access a drive, SFM must scan it to learn how many
files are in the drive and to record some metadata about the drive.  This speeds
up future drive accesses.  When files on the drive are altered by creating, or
erasing them, SFM will perform another scan to update the metadata.

### ERA

```text
D>era temp.bas
Scanning drive...
```

Marks a file as deleted in the drive and re-scans the drive metadata.  Deleted
files are not actually deleted on disk so can be recovered through some other
means if required.  They are, however, marked which makes that file slot
available for future file save operations.

### FREE

```text
A>free

TYPE: START-END SIZE

ZEROPAGE: E0-FA 001A
SYSTEM:   0200-0227 0027
BSS:      0300-0669 0369
TPA:      0800-9EFF 96FF
SFM       C000-D3A7 13A7
```

Displays a summary of memory usage.

### HELP

```text
A>help
BANK <#> Enter a rom bank number from 1 to 3
DIR [A:] Enter a drive number to list files
ERA [A:] FILENAME Delete a file
FREE Display memory information
TYPE [A:]FILENAME Display ascii contents of a file
SAVE FILENAME ## Save ## pages of memory starting at TPA to a file
```

Displays a summary of memory usage.

### SAVE (SFM)

```text
D>save test.txt 5
...
Scanning drive...

SAVED 03 SECTORS
```

The save command accepts a filename and number of 256byte memory pages to save.
Data starting at the beginning of the TPA region of memory (0x0800) will be
saved into a new file.  The number of sectors written is returned at the end.
In this example, 5 pages of memory were requested which fits into 2.5 sectors on
the sdcard. SFM does not support partial sector management so the whole of the
last sector is written to disk.  There is no garuntee what the reaminig data
will be.  It's just whatever was in memory at that location at the time.\

### TYPE

```text
C>type todo.md
<!-- vim: set ft=markdown -->
# List of things to do

+ [x] Figure out w...
```

Print the contents of a file out to the serial terminal.

## Chapter 4: Supplied Utilities

There are a few supplied applications that are shipped in the 6502-Retro-SFM
repository.  These are just regular applications written in a mixture of 6502
Assembly and C.  All are compiled with the CC65 assembler.

Executable applications on SFM must end with a `.com` file extension and must be
compiled to run from the beginning of the TPA region (0x0800).

It's up to the developer to choose if they want to use any of the provided APIs
to work with the filesytem or not.

### BASIC

SFM Ships with a version of Lee Davidson's Enhanced Basic (ehBasic) with some
minor enhancemnts to support operation within the SFM environment.

See [Chapter 5: BASIC](#chapter-5-basic) for more details.

### CAT

This tool is idenitical to the intrinsic `type` command but works by reading
each byte at a time via the `sfs_d_readseqbyte` API.  It was developed for
testing that functionality.

### CLS

Clears the screen.

### COPY

Copy a file.

```text
A>copy [a:]<source_filename> [b:]<dest_filename>
```

Use the copy command to make a copy of a file in either the same direcotory or
in a different directory.  Because the copy.com application is on Drive A, any
file operations within drive do not require a drive prefix.  However if you are
operating on files in any other drive, they must be prefixed with a drive
prefix.

### DUMP

```text
A>dump hello.com
Dump

0000 | A9 69 A2 08 20 23 08 4C 06 02 A0 00 4C 00 02 A0 | .i.. #.L....L...
0010 | 06 4C 00 02 A0 05 4C 00 02 A0 02 4C 00 02 A0 01 | .L....L....L....
0020 | 4C 00 02 A0 03 4C 00 02 A0 04 4C 00 02 A0 0E 4C | L....L....L....L
0030 | 00 02 A0 08 4C 00 02 A0 09 4C 00 02 A0 0A 4C 00 | ....L....L....L.
0040 | 02 A0 0C 4C 00 02 A0 0D 4C 00 02 A0 0F 4C 00 02 | ...L....L....L..
0050 | A0 10 4C 00 02 A0 0B 4C 00 02 A0 14 4C 00 02 A0 | ..L....L....L...
0060 | 15 4C 00 02 A0 13 4C 00 02 0A 0D 48 65 6C 6C 6F | .L....L....Hello
0070 | 2C 20 66 72 6F 6D 20 54 50 41 0A 0D 00 00 00 00 | , from TPA......
0080 | 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 | ................
```

Displays the binary content of a file including any printable ascii characters
to the right.  Very similar to the linux `hexdump` utility.

### FORMAT

Re-initialize a drive with an empty filesystem.

```text
A>format
Which drive would you like to format [A-H]? > E

You have selected drive: E

Are you sure? (Y/n) > Y
Formatting ................
A>dir e:

Scanning drive...
    E:
A>
```

### STAT

Display more detailed information about files in a drive.

```text
A>stat
Drive Statistics:
(Values shown in HEX)

Drive: A:

          2C00 16 BASIC.COM
          03B5 02 CAT.COM
            95 01 CLS.COM
          01C6 01 COPY.COM
          01C3 01 DUMP.COM
          0225 02 FORMAT.COM
          0142 01 HELLO_C.COM
            7D 01 HELLO.COM
          0240 02 STAT.COM
          0539 03 XM.COM
          1600 0B CONWAY.COM

          5530 of 2,000,000 bytes
```

### XM

Receive files into a filename using the XMODEM protocol over the current serial
port.

```text
E>dir
    E:
E>a:xm e:user-gd.md
Begin XMODEM/CRC transfer.  Press <Esc> to abort...
CUpload Successful!

Scanning drive...

E>dir
    E: USER-GD  MD
```

## Chapter 5: BASIC

[ehBasic by Lee
Davidson](http://retro.hansotten.nl/6502-sbc/lee-davison-web-site/enhanced-6502-basic/)
is a fairly simple version of basic to port but has many powerful features.  It
has been integrated to work with the SFM operating system as follows:

1. It runs out of RAM just like any other transient application on SFM.
2. It supports the BEEP command which will beep the 6502-Retro speaker.
3. Filesystem commands supported:
    1. DIR
    2. LOAD
    3. SAVE

    These commands are all hard coded to work on the D: drive in SFM.  This
    simplied a few things and helped the integration stay within the 11kb
    budget.

### DIR (BASIC)

List only the files on D drive ending in `.bas`.

```text
Ready
dir

Scanning drive...
MAND    BAS
HIGHLOW BAS
MANDANOYBAS
PRIMES  BAS
RBTEST  BAS
SPEED   BAS

Ready
```

### LOAD

Loads a file from D Drive into memory.

```text
Ready
load "mand.bas"

Ready
list

50 PRINT CHR$(12);
100 REM A BASIC, ASCII MANDELBROT
110 REM
120 REM This imp ...
```

### SAVE (BASIC)

Saves a file to disk.  Filename must be unique on D Drive.  You can not overwrite an
existing file this way.

```text
Ready

save "test.bas"

Scanning drive...

Ready
bye

D>dir
    A: MAND     BAS : HIGHLOW  BAS : MANDANOY BAS : PRIMES   BAS
    A: RBTEST   BAS : SPEED    BAS : TEST     TXT : TEST     BAS
```

Additional file operations must be carried out within SFM.

### BYE

Exit to the system.  You will always end up on drive D: if you performed any of
the 3 supported filesystem commands during your session.

```text
............,,,,,,
Break in line 410
Ready
bye

D>
```
