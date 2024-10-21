#ifndef ANSI_H
#define ANSI_H

#define ANSI_CLEAR		"\033[2J"
#define ANSI_HOME		"\033[H"
#define ANSI_CLEAR_EOL		"\033[0K"
#define ANSI_NEWLINE		"\r\n"
#define ANSI_SET_CURSOR		"\033[{line};{column}H" // 
#define ANSI_GET_CURSOR		"\033[6n" // Responds into \033[{line};{column}R
#define ANSI_REV_ON		"\033[7m"
#define ANSI_REV_OFF		"\033[27m"
#define ANSI_SAVE_CURSOR	"\0337"
#define ANSI_RESTORE_CURSOR	"\0338"
#define ANSI_BOLD_ON		"\033[1m"
#define ANSI_BOLD_OFF		"\033[22m"
#define ANSI_ITALIC_ON		"\033[3m"
#define ANSI_ITALIC_OFF		"\033[23m"
#define ANSI_UNDERLINE_ON	"\033[4m"
#define ANSI_UNDERLINE_OFF	"\033[24m"


void ansi_init(uint8_t ansi_width, uint8_t ansi_height);

void ansi_clear(void);
void ansi_clear_eol(void);
void ansi_newline(void);


void ansi_set_cursor(uint8_t x, uint8_t y);
void ansi_get_cursor(uint8_t* x, uint8_t* y);

void ansi_rev_on(void);
void ansi_rev_off(void);

uint8_t ansi_getc(void);
void ansi_putc(uint8_t c);
void ansi_puts(char* str);
void ansi_puti(uint16_t i);

void ansi_save_cursor(void);
void ansi_restore_cursor(void);

void ansi_get_size(uint8_t* x, uint8_t* y);
#endif
