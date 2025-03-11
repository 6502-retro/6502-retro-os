# Shadow Rom

-copy the ROM from E000-FFFF to C000-DFFF
-disable the ROM
-copy the ROM image from C000-DFFF to E000-FFFF (Now in RAM)

After running this tool, the ROM is disabled and the system still works.

Verify by running WOZ MON (A:mon) and editing a byte at FE00

```text
A>mon
Welcome to EWOZ 1.0.
\
FE00
FE00: EA
FE00:1
FE00: EA
FE00
FE00: 01
Q
```
