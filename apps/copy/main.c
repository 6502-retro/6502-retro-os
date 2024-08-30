/* vim: set et ts=4 sw=4 */
#include "sfos.h"
#include <stdlib.h>

uint16_t i;
uint8_t result;
uint8_t cr = 0;

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

void crlf() {
    sfos_c_printstr("\r\n");
}

void fatal(char * t) {
    sfos_c_printstr(t);
    sfos_s_warmboot();
}


void main(void) {

    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    sfos_c_printstr("\r\nCopy File\r\n");

    // Parse new filename
    sfos_d_setdma((uint16_t*)&fcb);
    sfos_d_parsefcb((uint16_t*)cmdoffset);

    // Open Source filename
    sfos_d_getsetdrive((&fcb2)->DRIVE);
    result = sfos_d_open(&fcb2);
    if (result) {
        sfos_c_write('0' + result);
        fatal("Error opening FCB2");
    }

    // Copy Source details (not filename or drive) over new FCB
    (&fcb)->LOAD = (&fcb2)->LOAD;
    (&fcb)->EXEC = (&fcb2)->EXEC;
    (&fcb)->SIZE = (&fcb2)->SIZE;
    (&fcb)->SC = (&fcb2)->SC;
    (&fcb)->ATTRIB = (&fcb2)->ATTRIB;

    // Make new file with new FCB.
    sfos_d_getsetdrive((&fcb)->DRIVE);
    result = sfos_d_make(&fcb);
    if (result) {
        fatal("Error making FCB");
    };

    sfos_c_printstr("Copying ");
    print_fcb(&fcb2);
    sfos_c_printstr(" -> ");
    print_fcb(&fcb);
    crlf();

    cr = (&fcb2)->SC;
    do {
        sfos_d_setdma((uint16_t *)&sfos_buf);
        sfos_d_readseqblock(&fcb2);

        sfos_d_setdma((uint16_t *)&sfos_buf);
        sfos_d_writeseqblock(&fcb);
        cr --;
    } while (cr > 0);

    sfos_d_getsetdrive((&fcb)->DRIVE);
    sfos_d_close(&fcb);
    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}

