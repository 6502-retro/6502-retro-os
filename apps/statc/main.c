/* vim: set et ts=4 sw=4 */
#include <sfos.h>
#include <stdio.h>
#include <ctype.h>

_fcb sfcb;
uint32_t total_bytes = 0;
char active_drive;
uint8_t error;
uint8_t i;
char *c;
static const char* wildcard = "???????????";

void crlf() {
    sfos_c_printstr("\r\n");
}

void __fastcall__ fatal(char * t) {
    printf(t);
    sfos_s_warmboot();
}

void __fastcall__ print_fcb(_fcb *f) {
    i=0;

    crlf();
    total_bytes += f->SIZE;

    putc('\t', stdout);
    printf("%6lu", f->SIZE);
    putc(' ', stdout);
    printf("%3d", f->SC);
    putc(' ', stdout);
    while (i<11) {
        putc(f->NAME[i++], stdout);
    }
}

void directory()
{
    sfcb.DRIVE = (&fcb2)->DRIVE;
    strcpy(sfcb.NAME,wildcard); 

    printf("%c:\t  SIZE  RC NAME",active_drive);

    error = sfos_d_findfirst(&sfcb);
    if (!error)
    {
        print_fcb(&sfcb);
        do {
            strcpy(sfcb.NAME, wildcard); 
            error = sfos_d_findnext(&sfcb);
            if (!error) {
                print_fcb(&sfcb);
            }
        } while (!error);
    }

    crlf();

    printf("\r\nDisk usage: %lu (%lu kb) of 33554432 (32mb)\r\n", total_bytes, total_bytes / 1024);
    printf("Disk free: %lu kb\r\n", (33554432/1024) - (total_bytes / 1024));
}

void convert_to_fcb(char * s, _fcb *f) {
    char *sc = s;
    char *fc;
    i = 0;

    fc = f->NAME;

    do {
        if (*sc == '.') {
            *fc = ' ';
            fc++;
        } else {
            *fc = toupper(*sc);
            fc ++;
            sc ++;
        }
        i++;
    } while ( (*sc != 0) && (i < 8));

    if (*sc == 0) return;

    sc ++;
    fc = f->EXT;
    i = 0;
    do {
        if (*sc != ' ' || *sc != 0) {
            *fc = toupper(*sc);
            fc ++;
            sc ++;
        } else {
            *fc = ' ';
            fc ++;
            i++;
        }
    } while ( (*sc != 0) && (i < 3));

}


/* List details about each drive */
void drives(void) {
    uint8_t file_count;
    uint16_t record_count;
    uint32_t space;
    uint8_t j = 1;
    crlf();
    sfos_c_printstr("DRIVE STATS:  FC - RECS - SPACE USED\r\n");
    while (j < 9) {
        sfos_d_getsetdrive(j);
        file_count = 0;
        record_count = 0;
        space = 0;

        sfcb.DRIVE = i;
        strcpy(sfcb.NAME,wildcard); 
        error = sfos_d_findfirst(&sfcb);
        if (!error) {
            file_count ++;
            record_count += sfcb.SC;
            space += sfcb.SIZE;
            do {
                strcpy(sfcb.NAME,wildcard); 
                error = sfos_d_findnext(&sfcb);
                if (!error) {
                    file_count ++;
                    record_count += sfcb.SC;
                    space += sfcb.SIZE;
                }
            } while (!error);
        }
        printf("          %c: %3d - %4d - %10lu\r\n", j+'A'-1, file_count, record_count, space);
        j++;
    }
}

void main(void) {
    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    if ((&fcb2)->DRIVE == 0) {
        active_drive = current_drive + 'A' - 1;
    } else {
        active_drive  = ( (&fcb2)->DRIVE == 0) ? current_drive + 'A' - 1 : (&fcb2)->DRIVE + 'A' - 1;
        sfos_d_getsetdrive((&fcb2)->DRIVE);
    }

    parse_args(cmd);

    crlf();
    printf("STAT: Utilty for printing information about the files on a disk.\r\n");
    printf("Written by David Latham (c) 2025\r\n\r\n");

    if (argc == 1) {
        drives();
    } else if (argc == 2) {
        c = argv[1];
        if (c[2] == 0) {
            directory();
        } else if (strcasecmp(c, "HELP") == 0) {
            sfos_c_printstr("INSTRUCTIONS\r\n");
            sfos_c_printstr("\r\n");
            sfos_c_printstr("STAT on it's own will print out details of each drive.\r\n");
            sfos_c_printstr("STAT A: to print out long listing of drive contents.\r\n");
            sfos_c_printstr("STAT A:filename to print out details of specific file.\r\n");
        } else {
            error = sfos_d_findfirst(&fcb2);
            if (!error) {
                crlf();
                printf("\tDRIVE:   %c\r\n", (&fcb2)->DRIVE + 'A' - 1);
                sfos_c_printstr("\tNAME:    ");
                while (i<11) {
                    putc((&fcb2)->NAME[i++], stdout);
                }
                crlf();
                printf("\tSIZE:    %lu\r\n", (&fcb2)->SIZE);
                printf("\tNUMBER:  %d\r\n", (&fcb2)->FILE_NUM);
                printf("\tRECORDS: %d\r\n", (&fcb2)->SC);
                printf("\tLOAD:    0x%04X\r\n", (&fcb2)->LOAD);
                printf("\tEXEC:    0x%04X\r\n", (&fcb2)->EXEC);
            }
        }
    }
    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}

