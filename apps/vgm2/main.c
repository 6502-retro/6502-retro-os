/* vim: set et ts=4 sw=4 */
#include <stdbool.h>
#include "sfos.h"
#include "bios.h"

#define NTSC 735
#define PAL 882

uint8_t current_drive;
uint8_t result;
uint16_t i;
uint8_t record_count;
unsigned char c;

uint8_t banknum = 0;
uint8_t *bptr = &bank[0];

uint16_t j = 0;
uint8_t command = 0;
uint8_t reg = 0;
uint8_t val = 0;
bool stop = false;

void crlf() { sfos_c_printstr("\r\n"); }

void fatal(char *t) {
  sfos_c_printstr(t);
  sfos_s_warmboot();
}

void load_file() {
  current_drive = sfos_d_getsetdrive(0xFF);
  // Open file
  sfos_d_getsetdrive(fcb2.DRIVE);
  crlf();
  result = sfos_d_open(&fcb2);
  if (result) {
    sfos_c_write('0' + result);
    fatal("Error opening file");
  }

  record_count = fcb2.SC;

  for (i = 0; i < record_count; ++i) {
    // Set the dma
    sfos_d_setdma((uint16_t *)&sfos_buf);
    // Read the first block
    sfos_d_readseqblock(&fcb2);
    // copy into ram.
    setbank(banknum++);
    memcpy(bptr, (uint16_t *)&sfos_buf, 512);
    bptr += 512;
  }
}

void main(void) {
  load_file();

  sfos_d_getsetdrive(current_drive);
  sfos_s_warmboot();
}
