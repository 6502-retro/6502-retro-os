/* vim: set et ts=4 sw=4 */
#include <stdio.h>
#include "sfos.h"
#include <stdint.h>

extern void __fastcall__ bios_putc(char c);
extern void __fastcall__ bios_puts(char* s);

uint32_t old_ticks;
uint32_t start_ticks;
uint32_t end_ticks;
char k;

uint8_t seconds, minutes, hours;

void main(void) {

    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    bios_puts("\033[2J");
    old_ticks = ticks;
    start_ticks = old_ticks;
    bios_puts("\033[29;0H");
    printf("Clock: (ESC to quit)");
    for (;;)
    {
        k = sfos_c_status();
        if (k == 0x1b) break;
        if ((ticks - old_ticks) > 54) {
            old_ticks = ticks;
            ++seconds;
            if (seconds > 59) {
                ++minutes;
                seconds=0;
            }
            if (minutes > 59) {
                ++hours;
                minutes = 0;
            }
            if (hours > 23) {
                hours = 0;
            }
            bios_puts("\033[30;0H");
            printf("\r\n%02u:%02u:%02u", hours, minutes, seconds);
        }
    }
    end_ticks = ticks;
    printf("start ticks: %lu\r\n",start_ticks);
    printf("end ticks: %lu\r\n",end_ticks);
    printf("difference: %lu\r\n", end_ticks-start_ticks);
    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}

