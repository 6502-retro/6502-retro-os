/* vim: set et ts=4 sw=4 */
#include <stdio.h>
#include "sfos.h"
#include "bios.h"

char textbuffer[64];

void delay(void)
{
    static uint16_t j;
    for (j=0; j<0x8FFF; ++j);
}
void main(void) {
    char * inp = textbuffer;
    uint8_t flag = 0;
    uint8_t btn = 0;
    uint8_t k = 0;

    sfos_c_printstr("\r\nHello, World!\r\n");
    sfos_c_readstr(24, textbuffer);
    sfos_c_printstr("\r\nYou wrote: ");
    inp ++;

    sfos_c_printstr(inp);


    printf("\r\nThis is a test : %04X\r\n", 0x5a5a);

    printf("\r\nLED AND BUTTONS:"
           "\r\nPress button to turn on LED."
           "\r\nPress again to turn it off."
           "\r\nPress Q to quit.");
    for (;;)
    {
        btn = bios_get_button();
        if (btn == 1 && flag == 0)
        {
            bios_led_on();
            flag = 1;
            delay();
        }
        else if (btn == 1 && flag == 1)
        {
            bios_led_off();
            flag = 0;
            delay();
        }
        k = sfos_c_status();
        if (k == 'q' || k == 'Q')
            break;
    }
    sfos_s_warmboot();
}

