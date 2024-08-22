# SFOS

The Simple Filesystem Operating System (SFOS) is a collection of routines that
are exposed to the programmer via a dispatcher routine located a known /
predefined location.  These functions are responsible for organising the files
on disk and enhancing the serial capabilities provided by the BIOS.  Each
function is described below.

## How to call the SFOS

The SFOS entry point is given at memory address 200.  Immediately after the
stack. <!--TODO: Validate this-->

The function number being called is given in Y and parameters are passed in XA.
This allows pointers to be passed into the SFOS functions.  SFOS functions all
return their results in XA and the Carry Flag.

By convention, for functions that use the carry flag to return a result of an
operation, Carry Clear means success and Carry Set means failure.  In some
cases, the error code will be given in A.

| Num | Name            | Description
|-----|---------        |---------------------------------------------------------
| 00  | s_reset         | Resets SFOS and jumps to the SFCP entry
| 01  | c_read          | Reads a character from the serial console
| 02  | c_write         | Writes a character to the serial console
| 03  | c_printstr      | Prints a null terminated string to the serial console
| 04  | c_readstr       | Reads a line of input from the serial console
| 05  | c_status        | Returns 0 or a characater from the serial console
| 06  | d_getsetdrive   | Returns or changes the current drive
| 07  | d_createfcb     | 
| 08  | d_parsefcb      | x
| 09  | d_findfirst     | x
| 10  | d_findnext      | x
| 11  | d_make          | x
| 12  | d_open          | x
| 13  | d_close         | x
| 14  | d_setdma        | x
| 15  | d_readseqblock  | x
| 16  | d_writeseqblock | x
| 17  | d_readseqbyte   | x
| 18  | d_writeseqbyte  | x

## 00 s_reset

Calls BIOS wboot to reset the disk dsystem and memory.  Switches back to drive
A and starts the SFCP.

## 01 c_read

Waits for a character to be available on the serial terminal and returns it in
A.  The character is echod to the screen unless A is = 0xFF on entry, then the
character is not echoed to the screen.  All input characaters from the terminal
(if in the printable ascii range) are converted to UPPER case if possible. (ie:
a-z are all converted to A-Z).

## 02 c_write

Sends a character to the serial terminal.  When outputing to the terminal, this
function also checks for for a CTRL+C.  If found, output is stopped, and the
s_reset routine is called.  If a CTRL+S is found, then the system is paused
until another keypress is given.  This way it is possible to pause the output
of the TYPE command for example.

## 03 c_printstr

Given a pointer to a memory location, this function will print out the string
at that location and will terminate when it encounteres a null char (\n).
Internally this function uses c_write to display the characters.

## 04 c_readstr

Given a pointer to a memory location this function will read user input until a
carriage return or line feed is received.  It supports basic line editing.

On entry, the first byte of the input buffer pointed to by XA contains the
maximum length of the input buffer.  The system maximum of 0x7F (128) chars.

- BACKSPACE is honoured
- TAB characters are stored in the buffer
- Either a \r or a \n will terminate the input and substitute the last input
characater (either \r or \n) with a \0 to mark the end of the input buffer.

## 05 c_status

Returns a 0 in A if no character, and the character if there is one.  This is a
raw function, the data is not translated into UPPER case as it comes through.

## 06 d_getsetdrive

If A = 0xFF on entry, this routine returns the active drive in A.  Otherwise
the drive number given in A is set and returned.

If the drive hasn't changed, no further actions are taken.

If the drive is changed, then the new drive is selected, the current LBA is
reset to the start of the drive and the drive number is returned.

If the selected drive number is out of range the carry flag is set and the
value 0x81 is returned in A.  The most significant bit set is useful for
testing without the carry flag if preferred.

All successful operations including the no-op implied by changing the drive to
the currently active drive, results in carry flag clear.

## 07 d_createfcb

<!-- TODO: We are not using this - remove it!-->
Given a pointer to an FCB in XA, this routine will populate the FCB with the
drive number, all spaces for the file name and extension and zeros for the
remaining elements.

## 08 d_parsefcb

Given a pointer to an FCB in XA, this routine will attempt to convert a
commanline input given by the previously set DMA address into an FCB.  It will
populate the following details of the FCB:

Filenames are in the 8.3 format and both the file name and the extension are
RIGHT SPACE PADDED.

For example to use the XR.COM application to receive a file over XMODEM and
save the result into FILE.COM, the user might issue this command.

`A:XR.COM B:FILE.COM`

- 0x00 will be placed into the DD element of the FCB (Drive A is 0x00)
- XRx\20x\20\x20\x20\x20\x20 will be placed into the N1 to N8 elements of the
FCB where \x20 is a space.
- COM will be placed into the T1-T3 elements of the FCB.
- 0x01 will be placed into the 16th element of the FCB.

The arguments will be saved as follows

- FILE\x20\x20\x20\x20 will be placed into the 17th to the 23rd elements of the FCB.
- COM will be placed into the 24th to the 26th elements of the FCB.
- All other elements will be set to zero.

In the event that a DRIVE SPECFIER (eg A: or B:) is not provided for either the
application or the argument to the application, the currently
active drive will be assigned to the relevant positions in the FCB.

If no filename argument is given to the command, the second half of the FCB is
initialised to zeros.

If a `*` is given in either the filename or the extension for either the
application being executed OR the argument to the application, then the
remaining characters up to 8 for filenames and 3 for extensions will be
initialised to a `?`.  The d_find routine will skip `?` characters when
matching filename and extension strings.

The routine will respond with the following conditions:

- Carry Clear on success.  The fcb sent is now updated with the result of the
  parse routine.
- Carry Set on error with the error code in A. The FCB is left in the sate it
  was in when the error occurred.

## 09 - d_findfirst

Given a populated FCB pointed to by XA, find the first occurrence of a file
matching the name in the FCB

The FCB is populated with the details of the file found and carry is clear.

If the file can not be found, then carry is set and the END OF DIRECTORY error
code is in A

## 10 - d_findnext

Lorem Ipsum,

## 11 - d_make

Given a pointer to an FCB in XA populated with the file name and optional drive
number, find the next free file on the drive from the dirent table and update
the FCB.

Returns with carry clear on success and carry set on failure with the error
code in A.

- 0x01 no free sectors
- 0x02 disk error
- 0x03 file exists

## 12 - d_open

Given a populated FCB pointed to by XA, open the specific file, validate the
fields and return with carry clear if successful.

Carry is set if failed and error code in A:

- 0x01 file not found
- 0x02 disk error

## 13 d_close

Given a populated FCB pointed to by XA, close the file by writing the contents
of the FCB back to disk.

Carry is set on failure and error code in A:

- 0x01 undefined error
- 0x02 disk error

## 14 d_setdma

Lorem Ipsum,

## 15 d_readseqblock

Read a single sector of bytes (512) from the SDCARD at the previously defined
LBA into memory at the DMA

## d_writeseqblock

## d_readseqbyte

## d_writeseqbyte

