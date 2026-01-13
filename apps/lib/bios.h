// vim: set et ts=4 sw=4
#ifndef BIOS_H
#define BIOS_H
#include <stdint.h>

extern void __fastcall__ bios_conout(char c);
extern uint8_t bios_conin();
extern uint8_t bios_const();
extern void __fastcall__ bios_puts(char* s);

extern void bios_led_on();
extern void bios_led_off();
extern uint8_t bios_get_button();

extern void setbank(uint8_t b);

#endif
