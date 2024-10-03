/* vim: set et ts=4 sw=4: */

/**
 * The code in this file is borrowed from David Given's Submit application
 * in cpm65 - https://github.com/davidgiven/cpm65/blob/master/apps/submit.c
 * But modified to support the SFM OS and the cc65 compiler.
 * Of particular help was the process byte routine and the method in which
 * the commands are reversed into the output file.
 */

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "sfos.h"

#define extram 0x2000

uint8_t sys;
static uint16_t lineno = 0;
static uint8_t* record_ptr;
static uint8_t record_fill;
static uint8_t escaped = 0;

char src_buf[512];
char dst_buf[512];

void fatal(char * t) {
    printf("\r\n%s", t);
    sfos_s_warmboot();
}

static void process_byte(uint8_t b) {
    uint8_t len;
    uint8_t p;
    char *param;

    if (!escaped && (b=='$')) {
        escaped = 1;
        return;
    }

    if (b=='\n') {
        record_ptr[0] = record_fill;
        printf("\r\nL: %d, RP:%p",lineno, record_ptr);
        while (record_fill != 127) {
            record_ptr[1 + record_fill] = '\0';
            record_fill ++;
        }
        record_ptr += 128;
        record_fill = 0;
        lineno ++;
    } else if (b != '\r') {
        if (escaped) {
            if (b == '$') {
                /* just emit a '$' */
            } else if (isdigit(b)) {
                p = b - '0' + 1;
                if (p < argc) {
                    param = argv[p];
                    len = strlen(param);
                    memcpy (&record_ptr[1 + record_fill], param, len);
                    record_fill += len;
                }
                goto exit;
            } else {
                fatal("bad escape character");
            }
        } /*else {
            b = toupper(b) - '@';
        }*/
        record_ptr[1 + record_fill] = b;
        record_fill ++;
    }
exit:
    if (record_fill >= 127)
        fatal("line too long");
    escaped = 0;
}

void empty_dst_buf(void) {
    uint16_t i;
    for (i=0; i<512; i++) {
        dst_buf[i] = '\0';
    }
}

void main(void) {
    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    uint8_t i, b;
    uint16_t dstbufidx;
    sys = 0;

    (&fcb)->DRIVE=0;
    strcpy((char*)(&fcb)->NAME, "$$$     ");
    strcpy((char*)(&fcb)->EXT, "SUB");

    parse_args(cmd);
    if (argc < 2) fatal("NO SUBMIT FILE PROVIDED");

    sys = sfos_d_open(&fcb2);
    if (sys) {
        printf("\r\nError opening %s", argv[1]);
        sfos_s_warmboot();
    } else {
        printf("\r\nOpened %s", argv[1]);
    }

    sys = sfos_d_make(&fcb);

    if (sys) {
        printf("\r\nError creating A:$$$.SUB");
        sfos_s_warmboot();
    } else {
        printf("\r\nCreated $$$.SUB");
        (&fcb)->CR = 0;
    }

    record_ptr = (uint8_t*)extram;
    record_fill = 0;
    lineno = 1;
    for (;;) {
        sfos_d_setdma((uint16_t*)src_buf);
        sys = sfos_d_readseqblock(&fcb2);
        if (!sys) {
            printf("\r\nERR: %d", sys);
            fatal("READ IO ERROR");
        }
        else printf("\r\nRead first block of source file");
        for (i = 0; i<128; i++) {
            b = src_buf[i];
            if (escaped && b == 'Z') goto eof;
            process_byte(b);
        }
    }
    eof:
        /* The last line gets written to the front of the file */
        printf("\r\nDone processing - writing file now...");
        dstbufidx = 0;
        empty_dst_buf();
        while(record_ptr != (uint8_t*)extram) {
            // Copy 128 bytes from record_pointer to record_ptr - 128 into end of dst_buf

            printf("\r\nBI: %d, RP:%p",dstbufidx, record_ptr-128);
            memcpy(&dst_buf[dstbufidx], record_ptr-128 ,128);
            record_ptr -= 128;
            dstbufidx += 128;
            if (dstbufidx == 512) {
                sfos_d_setdma((uint16_t*)dst_buf);
                sfos_d_writeseqblock(&fcb);
                dstbufidx = 0;
                empty_dst_buf();
            }
        }
        if (dstbufidx > 0) {
            sfos_d_setdma((uint16_t*)dst_buf);
            sfos_d_writeseqblock(&fcb);
        }

    (&fcb)->Z1 = lineno - 1;
    (&fcb)->SIZE = (lineno - 1)* 128;
    (&fcb)->LOAD = 0;
    (&fcb)->EXEC = 0;
    (&fcb)->SC = (&fcb)->CR;
    sfos_c_printstr("\r\nClosing $$$.SUB");
    sfos_d_close(&fcb);
    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}
