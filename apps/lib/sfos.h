// vim: set et ts=4 sw=4
#ifndef SFOS_H
#define SFOS_H

#include <stdint.h>
#include <string.h>

//hard coded addresses that SFCP uses
#define FCB          0x380
#define FCB2         0x3A0

#define fcb (*(_fcb*)FCB)
#define fcb2 (*(_fcb*)FCB2)

uint8_t argc;
char *argv[8];
char *cmd = (char*)0x301;

void parse_args(char* cmd) {
    char *p2;
    p2 = strtok(cmd, " ");

    while (p2 && argc < 7) {
        argv[argc++] = p2;
        p2 = strtok('\0', " ");
    }
    argv[argc] = '\0';
}

typedef struct _FCB{
    uint8_t     DRIVE;
    uint8_t     NAME[8];
    uint8_t     EXT[3];
    uint16_t    LOAD;
    uint8_t     SC;
    uint8_t     FILE_NUM;
    uint8_t     ATTRIB;
    uint16_t    EXEC;
    uint8_t     Z1;
    uint8_t     Z2;
    uint32_t    SIZE;               // Note we only need 24 bytes for the size.
    uint8_t     CR;
} _fcb;

extern uint8_t sfos_error_code;
extern uint16_t sfos_cmdline;

extern uint16_t sfos_commandline;
extern uint16_t sfos_buf;
extern uint16_t sfos_buf_end;

extern void __fastcall__ sfos_c_printstr(const char * text);
extern void __fastcall__ sfos_c_write(const uint8_t c);
extern uint8_t __fastcall__ sfos_c_read();
extern void __fastcall__ sfos_c_readstr(uint8_t len, char * buf);
extern uint8_t __fastcall__ sfos_c_status();

/* set dma, takes a pointer to the buffer to set the DMA to */
extern void __fastcall__ sfos_d_setdma(uint16_t * buf);
/* set lba, takes a pointer to a 32bit value */
extern void __fastcall__ sfos_d_setlba(uint32_t * lba);

/* parse fcb, takes a pointer to a buffer that contains the text to be parsed.
* Returns a pointer to the new location in the buffer after parsing
*/
extern uint8_t __fastcall__ sfos_d_getsetdrive(uint8_t d);
extern uint8_t __fastcall__ sfos_d_parsefcb(uint16_t * buf);
extern uint8_t __fastcall__ sfos_d_findfirst(volatile _fcb * f);
extern uint8_t __fastcall__ sfos_d_make(volatile _fcb * f);
extern uint8_t __fastcall__ sfos_d_open(volatile _fcb * f);
extern uint8_t __fastcall__ sfos_d_close(volatile _fcb * f);
extern uint8_t __fastcall__ sfos_d_readseqblock(volatile _fcb * f);
extern uint8_t __fastcall__ sfos_d_readseqbyte(volatile _fcb * f);
extern uint8_t __fastcall__ sfos_d_writeseqblock(volatile _fcb * f);
extern void sfos_d_writerawblock();
extern void __fastcall__ sfos_d_writeseqbyte(volatile _fcb * f, char c);

extern void sfos_s_warmboot();
extern void sfos_s_reboot();

#endif
