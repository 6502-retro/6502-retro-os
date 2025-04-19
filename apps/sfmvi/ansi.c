#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "bios.h"
#include "ansi.h"

uint8_t ansix, ansiy, ansi_width, ansi_height;

void ansi_init(uint8_t width, uint8_t height)
{
	ansix = ansiy = 0;
	ansi_width = width;
	ansi_height = height;
}

void ansi_clear(void)
{
	bios_puts(ANSI_CLEAR);
	bios_puts(ANSI_HOME);
}

void ansi_clear_eol(void)
{
	bios_puts(ANSI_CLEAR_EOL);
}

void ansi_newline(void)
{
	bios_puts(ANSI_NEWLINE);
}

void ansi_set_cursor(uint8_t x, uint8_t y)
{
	char buffer[10];

	bios_puts("\033[");
	itoa(y, buffer, 10);
	bios_puts(buffer);
	bios_putc(';');
	itoa(x, buffer, 10);
	bios_puts(buffer);
	bios_putc('H');

	ansix = x;
	ansiy = y;
}

void ansi_get_cursor(uint8_t* x, uint8_t* y)
{
	*x = ansix;
	*y = ansiy;
}

void ansi_rev_on(void)
{
	bios_puts(ANSI_REV_ON);
}

void ansi_rev_off(void)
{
	bios_puts(ANSI_REV_OFF);
}

uint8_t ansi_getc(void)
{
	return bios_getc();
}
void ansi_putc(uint8_t c)
{
	if (c < 31)
	{
		bios_putc('^');
		bios_putc('@' + c);
		ansix+=2;
	}
	else
	{
		bios_putc(c);
		ansix++;
	}
}

void ansi_puts(char* str)
{
	uint8_t c;
	for (;;)
	{
		c = *str++;
		if (c)
		{
			ansi_putc(c);
			ansix++;
			if (ansix==ansi_width)
			{
				ansix = 0;
				ansiy++;
			}
		}
		else
			break;
	}
}

void ansi_puti(uint16_t i)
{
	char buffer[10];
	itoa(i, buffer, 10);
	ansi_puts(buffer);
}

void ansi_save_cursor(void)
{
	bios_puts(ANSI_SAVE_CURSOR);
}

void ansi_restore_cursor(void)
{
	bios_puts(ANSI_RESTORE_CURSOR);
}

void ansi_get_size(uint8_t* x, uint8_t* y)
{
	*x = ansi_width;
	*y = ansi_height;
}
