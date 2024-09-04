<!-- vim: set ft=markdown -->
# SFM Bios

These are the BIOS functions are needed by SFM to interact with hardware:

| Num | Name    | Description
|-----|---------|---------------------------------------------------------
| 00  | boot    | Boot the system
| 01  | wboot   | Warm boot the system
| 02  | conin   | serial console in
| 03  | conout  | serial console out
| 04  | const   | serial console status
| 05  | setdma  | set the memory address for disk operations
| 06  | setlba  | set the lba address for disk operations
| 07  | sdread  | read 1 sector from the SDCARD at LBA to DMA
| 08  | sdwrite | write 1 sector of data from DMA to the SDCARD at LBA

## 00 - boot

Boots the system. This is called by the system reset vector and will clear the
stack, reset the memory banks and display the BIOS banner.  It will then fall
through to WBOOT which performs the soft boot routines as discribed.

## 01 - wboot

Reset the LBA to 0, drive to 0 (A:), clear the SDCARD buffer ready for further
disk operations.  Display a banner jump to the SFCP entry point.

## 02 - conin

Wait for a character on the serial terminal and return it in A

## 03 - conout

Wait for the serial to be ready to transmit, transmit character given in A

## 04 - const

Checks if a character is waiting on the serial and if so, return it in A else A
= 0

## 05 - setdma

Sets the memory address in user memory for the SDCARD read and write routines.

Address is given in AX

## 06 - setlba

Sets the SDCARD Logical Block Address (LBA) for the next sdread or sdwrite
call.

AX points to 4 bytes of data that contain the LBA in little endian order.

## 07 - sdread

Reads one sector (512 bytes) of data from the SDCARD from the sector defined by
the previously set LBA into the memory location given by the previously set DMA
address.

Returns result in A and Carry.

- Carry Clear, A = 0x00 SUCCESS
- Carry Set, A = 0x01 SDCARD ERROR

## 08 - sdwrite

Writes one sector (512 bytes) of data from memory at the previously set DMA
address into the SDCARD at the location given by the previously set LBA
address.

Returns result in A and Carry

- Carry Clear, A = 0x00 SUCCESS
- Carry Set, A = 0x01 SDCARD ERROR
