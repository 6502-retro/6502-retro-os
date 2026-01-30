/* vim: set et ts=4 sw=4 */
#include "bios.h"
#include "sfos.h"
#include <stdio.h>

char textbuffer[64];

void delay(void) {
  static uint16_t j;
  for (j = 0; j < 0x8FFF; ++j)
    ;
}
void main(void) {
  char *inp = textbuffer;
  uint8_t flag = 0;
  uint8_t btn = 0;
  uint8_t k = 0;

  sfos_c_printstr("\r\nHello, World!\r\n");
  sfos_c_readstr(24, textbuffer);
  sfos_c_printstr("\r\nYou wrote: ");
  inp++;

  sfos_c_printstr(inp);

  printf("\r\nThis is a test : %04X\r\n", 0x5a5a);

  printf("\r\nLED:"
         "\r\nPress Q to quit.");
  for (;;) {
    bios_led_off();
    delay();
    bios_led_on();
    delay();
    k = sfos_c_status();
    if (k == 'q' || k == 'Q') {
      bios_led_off();
      break;
    }
  }
  sfos_s_warmboot();
}
