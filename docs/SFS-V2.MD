# SFS V2

This document describes the Simple File System - Version 2 for use with SD
Cards and the 6502-Retro!

## Physical Drive Format

The SDCARD is divided into 3 parts:

- Volume ID and reserved space
- Directories
- Data

### Volume ID

The Volume ID contains the name of the volume and the version.  It has a magic
number at the end of Sector 0 that programmers can use to help determin the
validity of the volume.

|Offset  |DESCRIPTION            |
|--------|-----------------------|
|00 - 07 | Volume Name           |
|08 - 0B | Version Number        |
|1FE-1FF | Magic Number (0xBB66) |

### Directories

The directory structure consumes 128 sectors from 0x80 to 0xFF.  Each sector
contains 16 x 32byte dirents.  The 128 sectors are divided into 8 drives with
each drive containing 256 dirents.

|LBA      | Drive |
|---------|-------|
|0x80-0x8F| A     |
|0x90-0x9F| B     |
|0xA0-0xAF| C     |
|0xB0-0xBF| D     |
|0xC0-0xCF| E     |
|0xD0-0xDF| F     |
|0xE0-0xEF| G     |
|0xF0-0xFF| H     |

Each Drive contains 16 sectors with 16 dirents per sector.  A single dirent
structure contains the Drive, Filename, Extension, Attributes, load and execute
address and number of consumed data sectors.

#### FCB Structure

|..|00|01|02|03|04|05|06|07|08|09|0A|0B|0C|0D|0E|0F|
|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
|00|DD|N1|N2|N3|N4|N5|N6|N7|N8|T1|T2|T3|L1|L2|SC|FN|
|01|FA|E1|E2|Z1|Z2|S0|S1|S2|xx|xx|xx|xx|xx|xx|xx|xx|

#### Dirent Elements

| Code | Offset | Description                                                        |
|----- | -------|--------------------------------------------------------------------|
| DD   | 00-00  | Drive number. 0-7                                                  |
| Nn   | 01-08  | File name. 8 chars                                                 |
| Tn   | 09-0B  | File extension. 3 chars                                            |
| Ln   | 0C-0D  | Load Address. 16 bit address to save file into                     |
| SC   | 0E-0E  | Sector Count. Number of 512byte sectors used by file rounded up)   |
| FN   | 0F-0F  | File Number. The number of the file between 0 and 255              |
| FA   | 10-10  | File Attribute. E5 = deleted                                       |
| En   | 11-12  | Execution Address. Can be zero if file is not executable           |
| Zn   | 13-14  | Last byte offset.  The offset to last byte in the last used sector |
| Sn   | 15-17  | File size. 24 bits                                                 |
| xx   | 18-1F  | Reserved for future expansion.  eg: files larger than 128kb.       |

### Data

The data sectors are arranged on the SDCARD starting at LBA = 00 01 00 00.

| LBA         | Description    |
|-------------|----------------|
| 00 01 00 00 | A Drive sectors|
| 00 02 00 00 | B Drive sectors|
| 00 03 00 00 | C Drive sectors|
| 00 04 00 00 | D Drive sectors|
| 00 05 00 00 | E Drive sectors|
| 00 06 00 00 | F Drive sectors|
| 00 07 00 00 | G Drive sectors|
| 00 08 00 00 | H Drive sectors|

Each Drive area has 256 Files which each have 256 sectors.  For example:

If we have an example file with these properties:

- Size: 23052 bytes
- Name DEMO.TXT
- On drive D
- File number 33 (0x21)
- Load address 0x0800
- Execution address 0x0842

#### Example calculation

Showing how to derrive the first and last data sectors of a file given by a
dirent.

|..|00|01|02|03|04|05|06|07|08|09|0A|0B|0C|0D|0E|0F|
|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
|00|04|54|45|53|54|20|20|20|20|43|4F|4D|00|08|2E|21|
|01|01|42|08|0C|00|0C|5A|00|xx|xx|xx|xx|xx|xx|xx|xx|

```text
# LBA Values in HEX
00 04 21 00
    ^  ^  ^
    |  |  + First Sector
    |  + File Number
    +-- Drive Letter

Given the file is 23052 (0x5A0C) bytes in size, that means the sector count is:

23052 / 512 = 45.0234375 which is rounded up to 46 Sectors (2E in hex)

The offset into the last sector for the last byte is given by
     23052 % 512 = 12

So last sector LBA will be:

00 04 21 2E 
    ^  ^  ^
    |  |  + First Sector
    |  + File Number
    +-- Drive Letter


xx = Don't care - initialize to zero
```

## File Formats

Standard files: All standard files are saved as follows:

- Byte order is little endian
- Bytes 0-1 are the load address in 16 bit address space.  All files have this
header.
- Bytes 2-3 are the execution address WHEN and ONLY WHEN the file name ends in
.exe or .EXE

## Algorythms

### Algorythm to calculate last byte in sector

- Start with size of file (24 bits)
- Ignore the most significant byte (bits 16-24)
- Check if the middle byte (bits 8-16) is an even number.
  - If even, then the offset in the last sector `is 0x0[S0]` Where S0 is
    the least significant byte of the filesize.
  - If odd, then the offset in the last sector is `0x01[S0]` Where S0 is the
    leaast significant byte of the filesize.

```asm
get_last_byte_offset:
  stz fcb + sFcb::LastByteOffset + 1  ; start out with offset in page 0 of sector
  lda fcb + sFcb::FileSize + 1        ; get the page value
  and #$01                            ; mask least significant bit (check for even / odd)
  beq @even                           ; if zero then even
  lda #1                              ; odd, so st offset to page 1 within sector
  sta fcb + sFcb::LastByteOffset + 1  ; save that to the offset value
@even:
  lda fcb + sFcb::FileSize + 0        ; always keep the least significant byte of the size
  sta fcb + sFcb::LastByteOffset + 0  ; in the offset value.
  rts
```
