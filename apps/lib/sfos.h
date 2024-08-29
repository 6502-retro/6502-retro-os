// vim: set et ts=4 sw=4
#ifndef SFOS_H
#define SFOS_H

#include <stdint.h>

//hard coded addresses that SFCP uses
#define FCB          0x380
#define FCB2         0x3A0
#define CMDLINE      0x300
#define CMDOFFSET    0x3C0    // address of commandline
#define SFOS_BUF     0x400
#define SFOS_BUF_END 0x600
#define SFOS_LBA     0x633

typedef struct __fcb{
    uint8_t     DRIVE;
    uint8_t*    NAME[8];
    uint8_t*    EXT[3];
    uint16_t    LOAD;
    uint8_t     SECTOR_COUNT;
    uint8_t     FILE_NUM;
    uint8_t     ATTRIB;
    uint16_t    EXEC;
    uint16_t    LAST_BYTE_OFFSET;
    uint32_t    SIZE;               // Note we only need 24 bytes for the size.
    uint8_t     CURRENT_RECORD;
} _fcb;

_fcb * fcb = (_fcb*)FCB;
_fcb * fcb2 = (_fcb*)FCB2;

uint8_t * sfos_lba = (uint8_t*)SFOS_LBA;

extern void __fastcall__ sfos_c_printstr(char * text);
extern void __fastcall__ sfos_c_write(uint8_t c);
extern uint8_t __fastcall__ sfos_c_read();
extern void __fastcall__ sfos_c_readstr(uint8_t len, char * buf);
extern void __fastcall__ sfos_c_status();

/* set dma, takes a pointer to the buffer to set the DMA to */
extern void __fastcall__ sfos_d_setdma(char * buf);

/* parse fcb, takes a pointer to a buffer that contains the text to be parsed.
* Returns a pointer to the new location in the buffer after parsing
*/
extern uint8_t* __fastcall__ sfos_d_parsefcb(char * buf);
extern uint8_t __fastcall__ sfos_d_findfirst(_fcb * f);
extern uint8_t __fastcall__ sfos_d_make(_fcb * f);
extern uint8_t __fastcall__ sfos_d_open(_fcb * f);
extern uint8_t __fastcall__ sfos_d_readseqblock();
extern uint8_t __fastcall__ sfos_d_writeseqblock();

extern void sfos_s_warmboot();

#endif
