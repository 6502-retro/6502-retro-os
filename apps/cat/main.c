/* vim: set et ts=4 sw=4 */
#include "sfos.h"

uint8_t result;
uint16_t i;
unsigned char c;

void crlf() {
    sfos_c_printstr("\r\n");
}

void fatal(char * t) {
    sfos_c_printstr(t);
    sfos_s_warmboot();
}

void print_fcb(volatile _fcb * f) {
    uint8_t c = f->DRIVE;

    if (c) {
        sfos_c_write('A' - 1 + (c & 0x7F));
        sfos_c_write(':');
    }

    for (i=0; i<8; i++) {
        c = f->NAME[i];
        if (c == ' ')
            break;
        sfos_c_write(c);
    }

    if (f->NAME[8] != ' ') {
        sfos_c_write('.');
    }

    for (i=0; i<3; i++) {
        c = f->EXT[i];
        if (c==' ')
            break;
        sfos_c_write(c);
    }
    sfos_c_write('[');
    sfos_c_write(f->SC + '0');
    sfos_c_write(']');
    sfos_c_write('[');
    sfos_c_write(f->CR + '0');
    sfos_c_write(']');

}


void main(void) {


    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    // Open file
    sfos_d_getsetdrive((&fcb2)->DRIVE);
    crlf();
    result = sfos_d_open(&fcb2);
    print_fcb(&fcb2);
    if (result) {
        sfos_c_write('0' + result);
        fatal("Error opening FCB2");
    }
    // Set the dma
    sfos_d_setdma((uint16_t *)&sfos_buf);
    // Read the first block
    sfos_d_readseqblock(&fcb2);

    crlf();

    for (;;) {
        c = sfos_d_readseqbyte(&fcb2);
        if (sfos_error_code)
            break;
        else {
            sfos_c_write(c);
            if (c == '\n')
            sfos_c_write('\r');
        }
    }

    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}

