/* vim: set et ts=4 sw=4 */
#include "sfos.h"

char textbuffer[64];

void main(void) {
    char * inp = textbuffer;

    sfos_c_printstr("\r\nHello, World!\r\n");
    sfos_c_readstr(24, textbuffer);
    sfos_c_printstr("\r\nYou wrote: ");
    inp ++;

    sfos_c_printstr(inp);
    sfos_s_warmboot();
}

