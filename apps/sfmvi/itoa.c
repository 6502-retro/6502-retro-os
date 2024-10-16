#include <stdint.h>
#include <string.h>

static void my_strrev(char *str)
{
	uint16_t len = strlen(str);
	uint16_t i, j;
	uint8_t a;
	for (i = 0, j = len - 1; i < j; i++, j--)
	{
		a = str[i];
		str[i] = str[j];
		str[j] = a;
	}
}

void itoa(uint16_t val, char* buf)
{
	uint8_t i = 0;
	uint8_t digit;
	do
	{
		digit = val % 10;
		buf[i++] = '0' + digit;
		val /= 10;
	} while (val);
	buf[i] = '\0';
	my_strrev(buf);
}

