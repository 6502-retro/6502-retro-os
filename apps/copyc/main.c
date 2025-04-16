// vim: set ts=4 sw=4 et:

#include <stdio.h>
#include <string.h>
#include "sfos.h"

static _fcb destFile = {0};
static _fcb inputFile;
static uint8_t error;

static uint8_t i = 0;

static void crlf()
{
    sfos_c_write(13);
    sfos_c_write(10);
}

static void __fastcall__ dumpfcb(char* f)
{
    i = 0;
    crlf();
    do
    {
        printf("%02x ", *f);
        f++;
        i++;
    } while (i<27);
}

static void __fastcall__ fatal(char* s)
{
    crlf();
    sfos_c_printstr("FATAL: ");
    sfos_c_printstr(s);
    crlf();
}

static void printnl(char* s)
{
    sfos_c_printstr(s);
    crlf();
}

void main()
{

    // XXX: FUNDIMENTAL FLAW IN LOGIC.
    // THE DMA USED FOR READSEQBYTE IS SET INTO THE BIOS
    // IT STANDS TO REASON THEN, THAT THE DMA FOR WRITESEQBYTE
    // THAT'S ALSO SET IN THE BIOS WILL BE A PROBLEM.
    char c;

    inputFile = fcb2;       // alias fcb2 into inputFile
    parse_args(cmd);
    if (argc > 2 )
    {

        // parse destination filename into an FCB
        sfos_d_setdma((uint16_t*)&destFile);
        error = sfos_d_parsefcb((uint16_t*)argv[2]);

        // source filename is given to us in fcb2 by SFCP
        dumpfcb((char*)&inputFile);
        dumpfcb((char*)&destFile);
    } else {
        fatal("Could not parse");
    }
    printnl("making...");

    sfos_d_setdma((uint16_t*)&sfos_buf);
    sfos_d_make(&destFile);

    printnl("dumping...");
    dumpfcb((char*)&destFile);

    printnl("writing...");
    sfos_d_readseqblock(&inputFile);
    for (;;) {
        c = sfos_d_readseqbyte(&inputFile);
        if (sfos_error_code)
            break;
        else
            sfos_d_writeseqbyte(&destFile, c);
    }

    printnl("closing...");

    sfos_d_close(&destFile);
    sfos_s_warmboot();
}
