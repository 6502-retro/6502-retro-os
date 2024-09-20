/* vim: set et ts=4 sw=4 */
#include <stdio.h>
#include <ctype.h>

#include "sfos.h"

extern void __fastcall__ go(const uint16_t addr);

char input[32];
size_t i, j;
char ascii[17];
char byte_buf[3];
char addr_buf[6];

void DumpHex(const void* data, size_t size) {

    ascii[16] = '\0';
    for (i = 0; i < size; ++i) {
        if (i % 16 == 0) {
            sprintf(addr_buf, "%04X: ", i + (uint16_t)data);
            sfos_c_printstr(addr_buf);
        }
        if (i+1 % 8 == 0) sfos_c_printstr("- ");
        sprintf(byte_buf, "%02X ", ((unsigned char*)data)[i]);
        sfos_c_printstr(byte_buf);

        if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
            ascii[i % 16] = ((unsigned char*)data)[i];
        } else {
            ascii[i % 16] = '.';
        }
        if ((i+1) % 8 == 0 || i+1 == size) {
            if ((i+1) % 16 == 0) {
                sfos_c_write('|');
                sfos_c_write(' ');
                sfos_c_printstr(ascii);
                sfos_c_printstr("\r\n");
            } else if (i+1 == size) {
                ascii[(i+1) % 16] = '\0';
                if ((i+1) % 16 <= 8) {
                    sfos_c_write(' ');
                }
                for (j = (i+1) % 16; j < 16; ++j) {
                    sfos_c_printstr("   ");
                }
                sfos_c_write('|');
                sfos_c_write(' ');
                sfos_c_printstr(ascii);
                sfos_c_printstr("\r\n");
            }
        }
    }
}
uint16_t hex2int(char *hex) {
    uint16_t val = 0;
    while (*hex) {
        uint8_t byte = *hex++; 
        if (byte >= '0' && byte <= '9') byte = byte - '0';
        else if (byte >= 'a' && byte <='f') byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <='F') byte = byte - 'A' + 10;
        val = (val << 4) | (byte & 0xF);
    }
    return val;
}

void slice(const char* str, char* result, uint8_t start, uint8_t end) {
    str += start;
    do {
        *result++ = *str++;
        start++;
    } while (start <= end);
}

void help(void) {
    sfos_c_write(12);
    sfos_c_printstr("\r\nBANK Monitor\r\n");
    sfos_c_printstr("\r\n"
                    "B x     - Switch to ram bank x\r\n"
                    "G xxxx  - Jump to address given by xxxx\r\n"
                    "H       - Print help\r\n"
                    "M xxxx  - Dump a page of memory given by xxxx\r\n"
                    "[SPACE] - Dump next page of memory\r\n"
                    "Q       - Quit\r\n"
                    "R x     - Switch to rom bank x\r\n"
                    );
}

void main(void) {
    char * inp = input;
    char hexaddr[5] = "";
    uint16_t addr;
    char b;
    help();
    while (1) {
        sfos_c_readstr(16, input);
        sfos_c_printstr("\r\n");
        b = toupper(input[1]);
        switch (b) {
            case 'B':
                {
                    b = input[3];
                    if ( 0 <= b <= 63 ) {
                        (*(uint8_t*)0xBF00) = b-0x30;
                        sprintf(ascii, "RAM BANK %d - OK\r\n", b-0x30);
                        sfos_c_printstr(ascii);
                    }
                    break;
                }
            case 'G':
                {
                    slice(input, hexaddr, 3, 3+4);
                    addr = hex2int(hexaddr);
                    go(addr);
                    break;
                }
            case 'M':
                {
                    slice(input, hexaddr, 3, 3+4);
                    addr = hex2int(hexaddr);
                    DumpHex((void*)addr, 0x100);
                    break;
                }
            case ' ':
                {
                    addr = addr + 0x100;
                    DumpHex((void*)addr, 0x100);
                    break;
                }
            case 'H':
                {
                    help();
                    break;
                }
            case 'Q':
                sfos_s_warmboot();
            case 'R':
                {
                    b = input[3];
                    if ( 0 <= b <= 3 ) {
                        /*
                          A9 ??            lda b
                          8D 01 BF         sta rombankreg
                          6C FC FF         jmp ($FFFC)
                        */
                        // Doing it like this because I need this routine in RAM
                        (*(uint8_t*)0x700) = 0xA9;
                        (*(uint8_t*)0x701) = b-0x30;
                        (*(uint8_t*)0x702) = 0x8D;
                        (*(uint8_t*)0x703) = 0x01;
                        (*(uint8_t*)0x704) = 0xBF;
                        (*(uint8_t*)0x705) = 0x6C;
                        (*(uint8_t*)0x706) = 0xFC;
                        (*(uint8_t*)0x707) = 0xFF;
                        sprintf(ascii, "Switching to ROM Bank %d...\r\n", b-0x30);
                        sfos_c_printstr(ascii);
                        __asm__("jmp $700");
                    }
                    break;
                }
            default:
                break;
        }
    }
}

