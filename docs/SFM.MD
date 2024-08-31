# Simple File System

The Simple File System (SFS) is named as such because it's designed to be
simple.  It is designed with the following features:

1. Works only with SDCARDS
2. A file on disk consumed a maximum of 256 SDCARD Sectors which are 512 bytes
   each.  IE: maximum file size is 128kb.
3. The whole filesystem is divided into 8 drives.  Each drive can have 256
   files.  The directory entries (dirents) are pre-allocated at format time
into the beginning of the SDCARD
4. The directory structure is fixed in place.  The dirents are an ordered
collection of structures that each consume 32bytes.
    - dirents consume disk storage from LBA-0x80 to LBA-0xFF (inclusive)
    - as dirents are 32 bytes long, SFS allocates 16 dirents per LBA on the
    SDCARD.  It takes 16 sectors to address all files in a drive.
    - This allows for 8 drives between LBA=0x80 and LBA=0xFF where the most
    significant nibble of the LBA is the drive letter.
        - A = 0x80, B = 0x90, C = 0xA0, D = 0xB0, E = 0xC0, F = 0xD0, G = 0xE0,
        H = 0xF0
5. The file data begins at LBA=0x010000. Drive files are structured like this
with each on supporting 256 files and each file supporting 256 sectors.
    - A = 0x010000
    - B = 0x020000
    - C = 0x030000
    - D = 0x040000
    - E = 0x050000
    - F = 0x060000
    - G = 0x070000
    - H = 0x080000

6. Within a single drive in the data area, there are 256 files.
    - A = 0x010000 (LBA)
        - A:file0 = 0x010000 - 0x0100FF
        - A:file1 = 0x010100 - 0x0101FF
        - etc
    - B = 0x020000 (LBA)
        - B:file0 = 0x020000 - 0x0200FF
        - B:file1 = 0x020100 - 0x0201FF
        - etc

## File System Inerface

The system is divded into 3 main sections of operations:

As per the traditional CP/M systems the 6502-Retro! has the SFM (Simple File
Manager) which functions as the primary "operating system".

### SFM (Simple File Manger)

- BIOS: Low level system drivers and boot up logic
- SFOS: Simple File Operating System
- SFCP: Simple File Command Processor

### BIOS

- Provides the low level serial console and sdcard routines.
- Provides the first boot memory management and disk initization.

### SFOS

The SFOS is a group of functions that can be called by the programer to perform
the various tasks relating to working with files on and user input via the
serial terminal.

### SFCP

The SFCP is the Simple Filesystem Command Processor that serves as the primary
user interface into the system.  The SFCP executes as a special kind of
application in either RAM or Rom.  In the case of it running in RAM, it can be
overwritten and re-initialised by the BIOS and SFOS subsystems from disk.

The 6502-Retro! has enough ROM to hold the BIOS, SFOS and SFCP and so the SFCP
is bundled together in the ROM to maximise RAM for user applications.

## Boot Sequence

### Cold Start

- Clears BSS, copies the jump table and dispatch routine into run area, resets
the hardware stack.
- Initialise Drive A and jump to SFCP

### Warm Start

- Jumps to prompt in the SFCP

## Default OS Programs

### HELLO.COM

This is the standard assembly version of a helloworld program.  Run it and it
says, "Hello"

### DUMP.COM

Dumps in ASCII HEX format the contents of a file.

### STAT.COM

Lists filesize, used sectors and file names of the files on a given drive or
the default drive.

### XM.COM

XMODEM RECEIVE

Specify a filename to save to.  If the file name does not already exist on the
drive then XMODEM receive starts listening for the first byte.  Use your serial
terminal to initiate an XMODEM send and the file will be transferred with CRC
Checking into the file given on the disk.   File will be loaded into the start
of TPA so make sure that all the files you compile to be delivered this way are
compiled to start at TPA. (on SFM that's 0x800)

### COPY.COM

Copy files between drives and on the same drive but to a new filename.
(probably needs this check to be actually implimented.)
