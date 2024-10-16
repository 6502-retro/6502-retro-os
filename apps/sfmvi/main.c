#include "sfos.h"
#include "ansi.h"
#include "itoa.h"


void init(void) {
	/* inititialize ansi terminal */
	ansi_init(80, 24);
	ansi_clear();
}

void main(void) {
	/* prologue */
	uint8_t current_drive = sfos_d_getsetdrive(0xFF);
	init();

	/* main attraction */
	ansi_rev_on();
	ansi_puts("hellorld\r\n");
	ansi_rev_off();

	/* epilgoue */
	sfos_d_getsetdrive(current_drive);
	sfos_s_warmboot();
}

