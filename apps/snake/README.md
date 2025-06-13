<!-- vim: set cc=80 tw=80 ft=markdown: -->
# Snake game 6502 Assembly

Designed to run on a tms9918a type display.  Specifically the pico9918 device.
The main difference between this version of snake and previous versions is that
the display grid will be divided up into 4x4 pixels.

``` text
  7 6 5 4 3 2 1 0
0 A A A A B B B B
1 A A A A B B B B
2 A A A A B B B B
3 A A A A B B B B
4 C C C C D D D D
5 C C C C D D D D
6 C C C C D D D D
7 C C C C D D D D
```

This should allow for double the resolution from 32x24 to 64x48.  Of course text
characters at this resolution will be garbage, but it could be quite good for
graphics.

The colours are going to be a bit messy too.  Each 4x4 pixel block will be the
same color as the enclosing 8x8 pixel tile.  So really we are limited to
monochrome.  But that could be okay for some applications.  Like Snake or
conway for example.

Routines needed.

small_tile_x -> tile_x + offset
small_tile_y -> tile_y + offset

We also need to define characters for each combination of small tile within an
8x8 tile. 4 ^ 2 = 16.

00 0000 - no small tiles
01 0001 - bottom right
02 0010 - bottom left
03 0011 - bottom left and right
04 0100 - top left
05 0101 - top left + bottom right
06 0110 - top left + bottom left
07 0111 - top left + bottom left + bottom right
08 1000 - top right
09 1001 - top right + bottom right
10 1010 - top right + bottom left
11 1011 - top right + bottom left + bottom right
12 1100 - top right + top left
13 1101 - top right + top left + bottom right
14 1110 - top right + top left + bottom left
15 1111 - top right + top left + bottom left + bottom right

