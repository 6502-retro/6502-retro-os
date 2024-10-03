<!-- vim: set ft=markdown sw=4 ts=4 tw=80 cc: -->
# SUBMIT User Guide

The SUBMIT feature of the SFCP is used to automate tasks in the OS.  There is an
application called, `SUBMIT.COM` which parses a submit file and creates a system
submit file that is then processed by the SFCP when the system enters a warm
boot.

## Submit Files

A Submit File is a list of CPM commands and, optionally, arguments that you want
to automatically execute.  Think of them as CPM shell scripts.   Here is an
example of a trivial submit file:

```text
c> type test.sub

c:
era c:$1.com
xm c:$1.com
$Z
```

And to run the submit job, you need to run the `SUBMIT.COM` application like
this:

```text
c> a:submit test.sub rocket
```

`SUBMIT.COM` will create a `$$$.SUB` file in A: that contains each command in a
128byte buffer in the format expected by the commandline processor in SFCP.  The
`$1` placeholders will be replaced with `rocket`.  You can add additional
substitutions and each instance of the additional substitutions will be replaced
with the corrpsonding entry in the command you used to invoke `SUBMIT.COM`.

- Commands are spearated by the newline characater (0x0A).
- The carriage reuturn and additional whitespace are ignored entirely.
- "tokens" are seperated by whitespace.
- $1 is the first argument after the name of the submit file.
- $2 is the next argument following $1 etc...
- A maximum of 8 commandline arguments are supported as long as the total
command line length does not exceed 127 characters.
- the end of the submit file must be terminated with a `$Z`
- Each command in the `.SUB` file is placed into a zero-filled 128 byte buffer
in the format expected by the commandline processor.

At a minimum `SUBMIT.COM` expects the name of a submit file ending in `.SUB`.

## Submit Execution by SFCP

When `SUBMIT.COM` exits it calls the warm boot routine.  As the SFCP begins, it
checks if there is an existing `$$$.SUB` file on drive A.  If one is found then
user input is effectively replaced by reading the command directly from the
`$$$.SUB` file.  The `Z1` attribute in the system FCB is used to track which
command needs to be copied into the commandline buffer.

### Tracking the Current Command

`SUBMIT.COM` stores the number of lines parsed into the Z1 attribute of the
$$$.SUB fcb.  The submit processor in the sfcp will perform the following steps
on each warmboot until the $$$.SUB file has been deleted.

- Load the datasector given by DRIVE + FILENUM + RC
- Read the Z1 attribute
- Subtract 1
- AND 0x03
- MULT 128

This is the starting address of the command in the sector buffer.

- Copy 128 bytes of data from the sector buffer at starting position into the
commandline buffer
- Decrement Z1.
  - If Z1 becomes negative (ie: 0xFF) then delete the $$$.SUB file.
  - If Z1 AND 0x03 == 0, decrement RC
  - Save the $$$.SUB fcb for the next time around
- Continue processing

Here is an example of how this might play out.

```text
FCB: DRIVE 3, FN = 7, SC=2, Z1 = 6

(6 instructions in the submit file)

- Copy (SC-1) to CR                          DDFNCR
- Find the LBA of the last data sector:  0x00030701  (SC-1 = 01)
- read the data into the sfos_buffer
- Z1 - 1 = 5.
- 5 AND 0x03 = 1
- 1 * 128 = 128
- copy 128 bytes of data starting at sofs_buffer + 128 into commandline
- Update Z1 = 5
- check if Z1 AND 0x03 == 0:  NO
  - Do not update CR
- Write $$$.SUB FCB to disk
- Process.

NEXT WARMBOOT - $$$.SUB still exists

- Find the LBA of the last data sector: 0x00030701 (same as first go round)
- read to buffer
- Z1 - 1 = 4
- 4 AND 0x03 = 0
- 0 * 128 = 0
- copy 128 bytes of data starting at sfos_buffer + 0 into commandline
- update Z1 = 4
- check if Z1 AND 0x03 == 0:  YES
  - decrement CR
  - IS CR negative (0xFF): NO

- write $$$.SUB FCB to disk
- Process

NEXT WARMBOOT - $$$.SUB still exists
                                            DDFNCR
- Find the LBA of the last data sector: 0x00030700 (CR = 0)
- read to buffer
- Z1 - 1 = 3
- 4 AND 0x03 = 3
- 3 * 128 = 384
- copy 128 bytes of data starting at sfos_buffer + 384 into commandline
- update Z1 = 3
- check if Z1 AND 0x03 == 0:  NO
  - Do not update CR
- write $$$.SUB FCB to disk
- Process

Keep going until the CR < 0:

When CR is negative we delete the $$$.SUB file by setting FA attribute to 0xE5
and writing $$$.SUB FCB to disk.

```

### Exits and Errors

Whenever an error is encountered, the `$$$.SUB` file is deleted and control is
returned to user input.
