#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "sfos.h"
#include "vdp.h"

#define VDP_COLOR_TABLE            0x2000
#define nop __asm__("nop")
#define DENSITY 50

uint8_t working[0x400];
uint16_t i;
uint8_t ch;
uint16_t counter;
uint16_t seed;
uint8_t x,y;

char tb[40];

void print_at_xy(uint8_t x, uint8_t y, char * s) {
        i = (y * 32) + x;
        do {
                screen_buf[i] = *s;
                ++s;
                ++i;
        } while (*s != 0);
}

void main(void) {
        seed = 0;
        vdp_init_g2();
        // Set all colours to grey on black.
        vdp_set_write_address(VDP_COLOR_TABLE);
        for(i=0; i<0x800; ++i) {
                *(char*)VDP_RAM=0xe1;
                nop;
                nop;
                nop;
        }

        memset(screen_buf, 0x20, 0x300);

        print_at_xy(0,0,"Press a key to start...\0");
        vdp_wait();
        vdp_flush();

        while (sfos_c_status() == 0) {
                ;;
        }
        do {
                seed ++;
                counter = 0;
                memset(screen_buf, 0x20, 0x300);
                vdp_wait();
                vdp_flush();

                srand(seed);

                sprintf(tb,"SEED: %d", seed);
                print_at_xy(0,23,tb);
                sfos_c_printstr(tb);

                memset(screen_buf, 0x20, 0x20);

                for(i=0; i<0x2E0; i++) {
                        if ( (rand() % 100) < 50 ) {
                                screen_buf[i] = 0x0c;
                        }
                }
                vdp_wait();
                vdp_flush();

                while (counter < 250) {
                        memset(working, 0, 0x300);

                        for( y=0; y<24; y++) {
                                for (x=0; x<31; x++) {
                                        i = y*32+x;
                                        if (screen_buf[i] == 0x0c) {
                                                if (y>0) {
                                                        working[i-33] ++;
                                                        working[i-32] ++;
                                                        working[i-31] ++;
                                                }

                                                if (y<23) {
                                                        working[i+31] ++;
                                                        working[i+32] ++;
                                                        working[i+33] ++;
                                                }

                                                if (x>0) {
                                                        working[i-1 ] ++;
                                                }

                                                if (x<31) {
                                                        working[i+1 ] ++;
                                                }

                                        }
                                }
                        }

                        for (i = 0; i < 0x2E0; i++) {
                                if (working[i] == 3 && screen_buf[i] == ' ') {
                                        screen_buf[i] = 0x0c;
                                } else if (working[i] < 2 || working[i] > 3) {
                                        screen_buf[i] = ' ';
                                }
                        }

                        counter ++;
                        sprintf(tb, "% 5d", counter);
                        print_at_xy(27,23,tb);

                        vdp_wait();
                        vdp_wait();
                        vdp_flush();

                        ch = sfos_c_status();
                        if (ch == 'n') {
                                break;
                        } else if (ch==0x1b) {
                                seed = 100; // will break out of outer loop.
                        }
                }
                sprintf(tb, " - %d iterations.", counter);
                sfos_c_printstr(tb);
                sfos_c_printstr("\r\n");
        } while (seed < 50);
        return;
}
