/* vim: set et ts=4 sw=4 */
#include "sfos.h"
#include <stdlib.h>

uint16_t i;
uint8_t result;
uint8_t cr = 0;

void crlf() {
    sfos_c_printstr("\r\n");
}

void fatal(char * t) {
    sfos_c_printstr(t);
    sfos_s_warmboot();
}

void main(void) {

    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    sfos_c_printstr("\r\nWrite sequential data to a file.\r\n");

    // make target file
    sfos_d_getsetdrive((&fcb2)->DRIVE);
    result = sfos_d_make(&fcb2);
    if (result) {
        sfos_c_write('0' + result);
        fatal("Error making new file.");
    }

    sfos_d_setdma((uint16_t*)&sfos_buf);

    for (i = 0; i<600; i++) {
        sfos_d_writeseqbyte(&fcb2, (uint8_t)i);
    }
    sfos_c_printstr("\r\nClosing file...\r\n");

    sfos_d_close(&fcb2);

    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}

