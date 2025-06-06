# Assembler

The assembler in the Apps directory is a port of the assembler written by David
Given for the CPM65 project at:
[https://github.com/davidgiven/cpm65.git](https://github.com/davidgiven/cpm65.git)

## License

```text
© 2022-2023 David Given, and is licensed under the two-clause BSD open source
license. Please see [LICENSE](LICENSE) for the full text. The tl;dr is: you can
do what you like with it provided you don't claim you wrote it.
```

## CP/M-65 Assembler

An assembler comes with CP/M-65. It's pretty stupid but it does work. It's an
in-memory assembler, so you need enough spare RAM to hold the program you're
currently assembling --- you need 1/2 to 1/3 the amount of RAM as the source
file is big. This makes it unsuitable for large programs, but does make it
pretty fast. It will generate CP/M-65 relocatable binaries so once assembled
you should be able to run them on any machine.

### Syntax

It supports the normal 6502 opcodes (currently, no 65c02 opcodes) and the usual
addressing modes. Labels are defined with `label:`. Equates can be made with
`VALUE = expression`. Label forward references are supported; equate forward
references are not.

Branch instructions will be automatically expanded to 5-byte long branches if
out of range (see `.expand` below).

Expression parsing works now, mostly. Operator precedence is undefined, so use
parentheses. You can use these operators: `+` `-` `*` `/` `%` `&` `|` `^` `~`
`<` `>`.

The following pseudoops are available:

- .byte ...
  - Takes a list of numbers, or string constants, and emits them.

- .word ...
  - Takes a list of number, and emits them (in little-endian format).

- .fill number
  - Emits `number` zeroes.

- .zp symbol, number
  - Defines an area of zero page of length `number`, defining `symbol` to point
  to it. This must be done before use.

- .bss symbol, number
  - Defines an area of bss of length `number`, defining `symbol` to point to
  it. This must be done before use.

- .include "string"
  - Includes a file.

.expand 0/1
    Turns off/on branch expansion.

### Structured programming

In addition, there is a set of structured programming operations. Each block
will create a new scope. Code inside the scope can refer to labels outside the
scope, but not vice versa --- this allows easy local labels.

**Note:** due to the primitive nature of the assembler, if you have a forward
reference inside a block to a label outside it, the assembler cannot
automatically resolve the forward reference. Use `.label` to declare labels
ahead of time to get around this.

- Procedure:

  ```asm
  .zproc <symbol>
  .zendproc

  ```

  - Defines a procedure (or other scope). `symbol` points to it.

- loop:

  ```asm
  .zloop
    .zbreak <conditional>
  .zendloop

  ```

  - Creates an infinite loop. `.zbreak` will jump out of the loop. If a
  conditional is supplied --- e.g. `cc` or `ne` --- then it will jump
  conditionally.

- repeat:

   ```asm
   .zrepeat
     .zbreak <conditional>
   .zuntil <conditional>
   ```

  - As for `.zloop`, but with a conditional terminator.

- if:

   ```asm
   .zif <conditional>
   .zendif
   ```

  - A simple if..endif (with no else, currently). You can break from loops
   from within this.

- `.label <symbol>`
  - Declares a label before use. This is ueful for forward references in cases
  - where the assembler can't handle these automatically.
