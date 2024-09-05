
;********************************************************************************
;* This file is part of gibl:							*
;*	Gordons Interactive Basic Language                                      *
;********************************************************************************
;*    A Tiny Basic for the 6502 inspired by the NIBL Tiny Basic interpreter;	*
;*    "National Industrial Basic Language" originally for the INS8060 SC/MP	*
;*    system.									*
;*										*
;*    gibl is distributed under a "Source Available" license.			*
;*	It is NOT Open source and must not be treated as such.			*
;*										*
;*    See the file LICENSE for details.						*
;*										*
;*    gibl is Copyright (c) 2023 by Gordon Henderson				*
;********************************************************************************

	GIBL is based on NIBL:
	  National Industrial Basic Language
	    by Mark Alexander & Steve Leininger for the SC/MP, 1976.
	      Which was based on Tiny Basic by Dennis Allison, 1975.

  GIBL is an I.L. (Intermediate Language) Tiny Basic interpreter designed
  to run on the 6502 processor. It requires just 4KB of RAM and at least
  4KB or ROM to hold the interpreter and minimal serial IO routines.

  It can be adapted to use the IO routines that a typical "monitor" or
  operating system to assist with basic character IO and line entry. It
  requires 240 bytes of data, preferably in Zero page but this can be split
  (as it is in the Ruby system)

  A minimal system could have:

    4KB RAM from	$0000 through $0FFF
      GIBL source programs being stored from $0200 through $0FFF
      with the input line buffer being at $0100 for 78 bytes, assuming
      the stack is initialised at $01FF.
   4KB ROM from		$F000 through $FFFF
      Containing the GIBL interpreter and the most basic of character IO.

  Obviously with more RAM and ROM, then more is possible.

  In the RubyOS system it was developed for we have 64KB of RAM, GIBL
  source programs start at $0E00 and can extend up to $7FFF. The GIBL
  interpreter is from $8000 for just under 4KB and the RubyOS operating
  system is from $C000 through $FFFF with a small hole for IO.

  The data section is split from $00 through $8F in zero page and a
  small amount starting at $0400.

PORTING:

  See PORTING.TXT for details of porting it to a new system.


EXAMPLES:

  See the examples directory for some code examples.

MANUAL:

  See the MANUAL.TXT file for a brief description of the features this TinyBasic
  supports.
