#ifndef BIOS_H
#define BIOS_H

extern uint8_t bios_getc(void);
extern void __fastcall__ bios_putc(uint8_t c);
extern void __fastcall__ bios_puts(char* str);

#endif
