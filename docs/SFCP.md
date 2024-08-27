# SFCP

This is the primary user interface into the operating system.  When the
computer is reset, and after BIOS initialisation, this application will be
loaded and a prompt will appear on the terminal.

There are a few intrinsic functions within the SFCP and these are:

- X: where X is a drive letter from A to H to change to that drive.
- DIR list the contents of a drive
- ERA delete a file
- REN rename a drive
- SAVE save memory into a file
- TYPE print the ascii contents of a file to the serial terminal

All other features of the operating system are provided as applications that
run in userspace.

## Details

The following sections describe the inner workings of how the intrinsic
commands in sfcp work.

### BANK

```text
bank <#>
```

Set the rom bank and switch to it by jumping to the vector defined at 0xFFFC.
Accepts a value from 0 to 3.

### DIR

The way DIR works is by setting the fcb to be all wildcards.  Then searching
for a matching file.  The first file on the drive will be returned in the fcb
so it can be displayed.  Then call sfos.find_next() function to to find the
next matching file.  SFOS tracks where it is in the drive and loads the next
sector from disk if required.  SFOS will also track the number of files and if
the end is reached (255) then it returns an error conditions which sfcp can
catch to know that the last file has been found.  Any file on the directory
with a file attribute of 0xE5 will cause sfos to retun an end of directory
error too.

### ERA

```text
era <filename>
```

Deletes `<filename>` from current drive if it can be found.  Wildcards are
accepted but only the first found file will be removed.  Perhaps this
functionality can be extended to something more brutal.

### FREE

Print out the memory assignments:

```text
free

MEMORY Assignments
ZEROPAGE: E0-F8 0018
SYSTEM:   0200-0211 0011
BSS:      0300-0642 0342
TPA:      0800-9E00 9600
```

### HELP

Display SFCP intrinsic commands.

### SAVE

```text
save <filename> <count>
```

Saves `<count>` pages of data from the start of the TPA into `<filename>`

### TYPE

```text
type [drive:]<filename>
```

Prints the ascii contents of `<filename>` from `[drive]`.

### REN

```text
ren <source> <dest>
```

Renames a file in the current directory to a new name in the same directory.
You can not use rename to move a file.
