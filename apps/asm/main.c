/* vim: set et ts=4 sw=4 */

/* asm © 2022-2023 David Given, (https://github.com/davidgiven/cpm65)
 *
 * Ported to SFOS by David Latham - 2025
*/

#include <ctype.h>
#include "sfos.h"

uint8_t currentByte;
uint8_t token;
uint16_t tokenValue;
uint8_t tokenLength;
uint16_t lineNum = 0;
uint8_t parseBuffer[128];

uint8_t error;

#define ram (*(uint8_t*)0xC000)      // start of high ram
#define top (*(uint8_t*)0xDFFF)      // end of high ram

enum
{
    TOKEN_ID        =0,
    TOKEN_NUMBER    =1,
    TOKEN_STRING    =2,
    TOKEN_EOF       =26
};

void crlf()
{
    sfos_c_printstr("\r\n");
}

void __fastcall__ fatal(char* msg)
{
    sfos_c_printstr(msg);
    sfos_s_warmboot();
}

void badEscape()
{
    fatal("bad escape sequence");
}

/* --- lexer ------------------------------------------------------------- */

void consumeByte()
{
    currentByte = sfos_d_readseqbyte(&fcb2);
}

int __fastcall__ ishex(int c)
{
    char ch = (char)c;
    return ((ch>='A') && (ch<='F')) || ((ch>='a') && (ch<='f')) || ((ch>='0') && (ch<='9'));
}

char consumeToken()
{
    tokenLength = 0;

    if (currentByte == 26) {
        token = currentByte;
        return token;
    }

    for (;;)
    {
        if (currentByte == '\\')
        {
            do
            {
                consumeByte();
            } while ((currentByte != 26) && (currentByte!='\n'));
        }
        else if ( (currentByte == ' ') || (currentByte == '\t') || (currentByte == '\r'))
            consumeByte();
        else
            break;
    }

    if (currentByte == '\n')
    {
        lineNum ++;
        currentByte = ';';
    }

    switch (currentByte)
    {
        case 26:
        case '&':
        case '^':
        case '|':
        case '~':
        case '#':
        case '(':
        case ')':
        case '*':
        case '+':
        case ',':
        case '-':
        case '.':
        case '/':
        case ':':
        case ';':
        case '<':
        case '=':
        case '>':
        {
                token = currentByte;
                consumeByte();
                return token;
        }
    }

    if (isalpha(currentByte))
    {
        do
        {
            parseBuffer[tokenLength++] = currentByte;
            consumeByte();
        } while (isdigit(currentByte) || isalpha(currentByte) || (currentByte =='_'));
        parseBuffer[tokenLength] = 0;
        token = TOKEN_ID;
        return token;
    }

    if (isdigit(currentByte) || (currentByte =='$'))
    {
        uint8_t base = 10;
        tokenValue = 0;
        if (currentByte == '0')
        {
            consumeByte();
            switch(currentByte)
            {
                case 'x':
                    base = 16;
                    consumeByte();
                    break;
                case 'b':
                    base = 2;
                    consumeByte();
                    break;
                case '0':
                    base = 8;
                    consumeByte();
                    break;
            }
        }
        else if (currentByte == '$')
        {
            consumeByte();
            base = 16;
        }

        for (;;)
        {
            uint8_t c;
            if (!ishex(currentByte))
                break;
            tokenValue *= base;
            c = currentByte;
            if (c >='a')
                c = (c-'a')+10;
            else if (c >= 'A')
                c = (c-'A')+10;
            else
                c -= '0';

            if (c >= base)
                fatal("invalid number");
            tokenValue += c;
            consumeByte();
        }
        token = TOKEN_NUMBER;
        return token;
    }

    if (currentByte == '"')
    {
        consumeByte();
        tokenLength = 0;
        for (;;)
        {
            char c = currentByte;
            consumeByte();
            if (c=='"')
                break;
            if (c=='\n')
                fatal("unterminated string constant");
            if (c=='\\')
            {
                c = currentByte;
                consumeByte();
                if (c=='n')
                    c = 10;
                else if (c == 'r')
                    c= 13;
                else if (c=='t')
                    c = 9;
                else if (c =='\\')
                    badEscape();
            }
            parseBuffer[tokenLength++] = c;
        }
        parseBuffer[tokenLength] = 0;
        token = TOKEN_STRING;
        return token;
    }

    if (currentByte == '\\')
    {
        consumeByte();
        if (currentByte == '\\')
        {
            consumeByte();
            switch (currentByte)
            {
                case 'n':
                    currentByte = 10;
                    break;
                case 'r':
                    currentByte = 13;
                    break;
                case 't':
                    currentByte = 9;
                    break;
                case '\\':
                    break;
                default:
                    badEscape();
            }
        }
        tokenValue = currentByte;
        consumeByte();
        consumeByte();
        token = TOKEN_NUMBER;
        return token;
    }
    fatal("bad parse");
}

/* --- parser ------------------------------------------------------------ */

void parse()
{
    for (;;)
    {
        switch(token)
        {
            case TOKEN_EOF:
                goto exit;
        }
    }
exit:;
}

/* --- main -------------------------------------------------------------- */

void main(void)
{
    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    sfos_d_getsetdrive((&fcb2)->DRIVE);

    crlf();
    sfos_c_printstr("ASM: a stab in the dark\r\n");
    sfos_c_printstr("Written by David Latham (c) 2025\r\n\r\n");

    error = sfos_d_open(&fcb2);
    if (!error) {
        sfos_d_setdma((uint16_t*)&sfos_buf);
        sfos_d_readseqblock(&fcb2);
        consumeByte();
        consumeToken();
        parse();
    }

    sfos_d_getsetdrive(current_drive);
    sfos_s_warmboot();
}

