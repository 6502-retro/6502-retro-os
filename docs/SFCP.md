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

