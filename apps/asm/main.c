/* vim: set et ts=4 sw=4 */

/* asm © 2022-2023 David Given, (https://github.com/davidgiven/cpm65)
 *
 * Ported to SFOS by David Latham - 2025
*/

#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#include "sfos.h"

uint8_t currentByte;
uint16_t lineNum = 0;
char parseBuffer[128];

uint8_t error;

uint16_t ram;
uint8_t* top;

struct SymbolRecord;

typedef struct
{
    uint8_t descr;
} Record;

typedef struct
{
    Record record;
    uint8_t bytes[];
} ByteRecord;

typedef struct
{
    Record record;
    uint16_t length;
} FillRecord;

typedef struct
{
    Record record;
    struct SymbolRecord* variable;
} LabelDefinitionRecord;

enum
{
    PP_NONE         =0,
    PP_LSB          =1,
    PP_MSB          =2,
};

typedef struct
{
    Record record;
    uint8_t opcode;
    struct SymbolRecord* variable;
    uint16_t offset;
    uint8_t length;
    uint8_t postprocessing;
} ExpressionRecord;

typedef struct SymbolRecord
{
    Record record;
    uint8_t type;
    struct SymbolRecord* variable;
    uint16_t offset;
    struct SymbolRecord* next;
    char name[];
} SymbolRecord;

typedef struct
{
    char name[3];
    uint8_t opcode;
    uint16_t addressingModes;
} Instruction;

typedef struct
{
    const char* string;
    void (*callback)();
} SymbolCallbackEntry;


static char token = 0;
static uint16_t tokenValue;
static uint8_t tokenLength;
static SymbolRecord* tokenVariable;
static uint8_t tokenPostProcessing;
static uint8_t tokenLength;
static SymbolRecord* lastSymbol;
static uint8_t defaultBranchSize = 5;
uint8_t badProgram = 0;
uint8_t zpUsage = 0;
uint16_t bssUsage = 0;
uint16_t textUsage = 0;

#define EXPR_STACK_SIZE 8
static uint16_t exprValue[EXPR_STACK_SIZE];
static SymbolRecord* exprVariable[EXPR_STACK_SIZE];
//
//typedef struct
//{
//    uint8_t pos;
//    uint16_t lineNumber;
//    _fcb fcb;
//    uint8_t buffer[512];
//} InputStream;

enum
{
    TOKEN_ID        =0,
    TOKEN_NUMBER    =1,
    TOKEN_STRING    =2,
    TOKEN_EOF       =26,
};

enum
{
    RECORD_EOF = 0 << 5,
    RECORD_BYTES = 1 << 5,
    RECORD_EXPR = 2 << 5,
    RECORD_SYMBOL = 3 << 5,
    RECORD_LABELDEF = 4 << 5,
    RECORD_FILL = 5 << 5,
};

enum
{
    SYMBOL_UNINITIALISED = 0,
    SYMBOL_REFERENCE,
    SYMBOL_ZP,
    SYMBOL_BSS,
    SYMBOL_TEXT,
    SYMBOL_COMPUTED,
};

const char symbolTypeChars[] = "URZBTC";

typedef enum
{
    AM_XPTR = 1 << 0,  /* (0x12, x) */
    AM_ZP   = 1 << 1,  /* 0x12      */
    AM_IMM  = 1 << 2,  /* #0x12     */
    AM_ABS  = 1 << 3,  /* 0x1234    */
    AM_YPTR = 1 << 4,  /* (0x12), y */
    AM_XOFZ = 1 << 5,  /* 0x12, x   */
    AM_YOFF = 1 << 6,  /* 0x1234, y */
    AM_XOFF = 1 << 7,  /* 0x1234, x */
    AM_IMP  = 1 << 8,  /* (nothing) */
    AM_A    = 1 << 9,  /* A         */
    AM_IMMS = 1 << 10, /* #0x12     */
    AM_WIND = 1 << 11, /* (0x1234)  */
    AM_YOFZ = 1 << 12, /* 0x12, y   */
} AddressingMode;
enum
{
    B_XPTR  = 0 << 2,
    B_ZP    = 1 << 2,
    B_IMM   = 2 << 2,
    B_ABS   = 3 << 2,
    B_YPTR  = 4 << 2,
    B_XOFZ  = 5 << 2,
    B_YOFF  = 6 << 2,
    B_XOFF  = 7 << 2,

    B_IMP   = 8 << 2, /* not a real B-value */
    B_REL   = 9 << 2, /* likewise */
};

enum
{
    BPROP_ZP    = 1 << 0,
    BPROP_ABS   = 1 << 1,
    BPROP_PTR   = 1 << 2,
    BPROP_SHR   = 1 << 3,
    BPROP_IMM   = 1 << 4,
    BPROP_RELATIVE = 1 << 5,

    BPROP_SIZE_SHIFT = 6,
};

#define ILLEGAL 0xff

static void createLabelDefinition(SymbolRecord* r);
static void consumeExpressionNode(uint8_t sp);
static void consumeExpression();
static void printSymbol(SymbolRecord* r);

/* --- I/O --------------------------------------------------------------- */

static void crlf()
{
    sfos_c_printstr("\r\n");
}

static void __fastcall__ fatal(char* msg)
{
    sfos_c_printstr(msg);
    sfos_s_warmboot();
}

static void badEscape()
{
    fatal("bad escape sequence");
}

static void errormessage(char* msg)
{
    sfos_c_printstr(msg);
}

static void printi(uint16_t n)
{
    if (n > 9)
    {
        uint16_t a = n / 10;

        n -= 10 * a;
        printi(a);
    }
    sfos_c_write('0' + n);
}

/* --- lexer ------------------------------------------------------------- */

static void consumeByte()
{
    currentByte = sfos_d_readseqbyte(&fcb2);
}

static int __fastcall__ ishex(int c)
{
    char ch = (char)c;
    return ((ch>='A') && (ch<='F')) || ((ch>='a') && (ch<='f')) || ((ch>='0') && (ch<='9'));
}

static char consumeToken()
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
/* --- Instruction data -------------------------------------------------- */
#define AM_ALU \
    (AM_XPTR | AM_ZP | AM_IMM | AM_ABS | AM_YPTR | AM_XOFZ | AM_XOFF | AM_YOFF)

static const Instruction simpleInsns[] = {
    {"ADC", 0x61, AM_ALU},
    {"AND", 0x21, AM_ALU},
    {"ASL", 0x02, AM_ZP | AM_A | AM_ABS | AM_XOFZ | AM_XOFF},
    {"BCC", 0x90, AM_ABS},
    {"BCS", 0xb0, AM_ABS},
    {"BEQ", 0xf0, AM_ABS},
    {"BIT", 0x20, AM_ZP | AM_ABS},
    {"BMI", 0x30, AM_ABS},
    {"BNE", 0xd0, AM_ABS},
    {"BPL", 0x10, AM_ABS},
    {"BRK", 0x00, AM_IMP},
    {"BVC", 0x50, AM_ABS},
    {"BVS", 0x70, AM_ABS},
    {"CLC", 0x18, AM_IMP},
    {"CLD", 0xd8, AM_IMP},
    {"CLI", 0x58, AM_IMP},
    {"CLV", 0xb8, AM_IMP},
    {"CMP", 0xc1, AM_ALU},
    {"CPX", 0xe0, AM_IMMS | AM_ZP | AM_ABS},
    {"CPY", 0xc0, AM_IMMS | AM_ZP | AM_ABS},
    {"DEC", 0xc2, AM_ZP | AM_ABS | AM_XOFZ | AM_XOFF},
    {"DEX", 0xca, AM_IMP},
    {"DEY", 0x88, AM_IMP},
    {"EOR", 0x41, AM_ALU},
    {"INC", 0xe2, AM_ZP | AM_ABS | AM_XOFZ | AM_XOFF},
    {"INX", 0xe8, AM_IMP},
    {"INY", 0xc8, AM_IMP},
    {"JMP", 0x40, AM_ABS | AM_WIND},
    {"JSR", 0x20 - B_ABS, AM_ABS},
    {"LDA", 0xa1, AM_ALU},
    {"LDX", 0xa2, AM_IMMS | AM_ZP | AM_ABS | AM_YOFZ | AM_YOFF},
    {"LDY", 0xa0, AM_IMMS | AM_ZP | AM_ABS | AM_XOFZ | AM_XOFF},
    {"LSR", 0x42, AM_ZP | AM_A | AM_ABS | AM_XOFZ | AM_XOFF},
    {"NOP", 0xea, AM_IMP},
    {"ORA", 0x01, AM_ALU},
    {"PHA", 0x48, AM_IMP},
    {"PHP", 0x08, AM_IMP},
    {"PLA", 0x68, AM_IMP},
    {"PLP", 0x28, AM_IMP},
    {"ROL", 0x22, AM_ZP | AM_A | AM_ABS | AM_XOFZ | AM_XOFF},
    {"ROR", 0x62, AM_ZP | AM_A | AM_ABS | AM_XOFZ | AM_XOFF},
    {"RTI", 0x40, AM_IMP},
    {"RTS", 0x60, AM_IMP},
    {"SBC", 0xe1, AM_ALU},
    {"SEC", 0x38, AM_IMP},
    {"SED", 0xf8, AM_IMP},
    {"SEI", 0x78, AM_IMP},
    {"STA", 0x81, AM_ALU & ~AM_IMM},
    {"STX", 0x82, AM_ZP | AM_ABS | AM_YOFZ},
    {"STY", 0x80, AM_ZP | AM_ABS | AM_XOFZ},
    {"TAX", 0xaa, AM_IMP},
    {"TAY", 0xa8, AM_IMP},
    {"TSX", 0xba, AM_IMP},
    {"TXA", 0x8a, AM_IMP},
    {"TXS", 0x9a, AM_IMP},
    {"TYA", 0x98, AM_IMP},
    {}
};

static const uint8_t bOfAm[] = {
    B_XPTR,       /* AM_XPTR */
    B_ZP,         /* AM_ZP */
    B_IMM,        /* AM_IMM */
    B_ABS,        /* AM_ABS */
    B_YPTR,       /* AM_YPTR */
    B_XOFZ,       /* AM_XOFZ */
    B_YOFF,       /* AM_YOFF */
    B_XOFF,       /* AM_XOFF */
    0,            /* AM_IMP */
    2 << 2,       /* AM_A */
    0 << 2,       /* AM_IMMS */
    0x20 | B_ABS, /* AM_WIND: 0x20 bumps the opcode from 0x4c to 0x6c */
    B_XOFZ,       /* AM_YOFZ */
};

static const Instruction* __fastcall__ findInstruction(const Instruction* insn)
{
    char opcode[3];
    uint8_t i;
    for (i=0; i<3; i++)
        opcode[i] = toupper(parseBuffer[i]);

    while (insn->name[0])
    { if ((opcode[0] == insn->name[0]) && (opcode[1] == insn->name[1]) &&
        (opcode[2] == insn->name[2])) {
            return insn;
        }
        insn++;
    }
    return NULL;
}

static uint8_t __fastcall__ getBofAM(uint16_t am)
{
    uint8_t p = 0;
    while (!(am & 1))
    {
        p++;
        am >>= 1;
    }
    return bOfAm[p];
}

static int8_t __fastcall__ getB(uint8_t opcode)
{
    if ( (opcode & 0b00000011) == 0b00000001) /* c=1 */
    {
        /* Normal ALU block */
        return opcode & 0b00011100;
    }
    else if ((opcode & 0b00000011) == 0b00000010) /* c=2 */
    {
        /* Shift instructions with ALU-compatible b-values? */
        if (opcode & 000000100)
            return opcode & 0b00011100;

        /* ldx is special */
        if (opcode == 0xa2)
            return B_IMM;
        return B_IMP;
    }
    else /* c=0 */
    {
        /* Misc instructions with ALU-compatible b-values? */

        if (opcode & 0b00000100)
            return opcode & 0b00011100;

        /* Relative branches */
        if ((opcode & 0b00011100) == 0b00010000)
            return B_REL;

        /* JSR is special */

        if (opcode == 0x20)
            return B_ABS;

        /* LDY/CPX/CPY are special */

        if ((opcode & 0b10011100) == 0b10000000)
            return B_IMM;

        return B_IMP;
    }
}

static int8_t __fastcall__ getBProps(uint8_t b)
{
    const uint8_t flags[] = {
        (2 << BPROP_SIZE_SHIFT) | BPROP_ZP  | BPROP_PTR,  // B_XPTR
        (2 << BPROP_SIZE_SHIFT) | BPROP_ZP,              // B_ZP
        (2 << BPROP_SIZE_SHIFT) | BPROP_IMM,             // B_IMM
        (3 << BPROP_SIZE_SHIFT) | BPROP_ABS | BPROP_SHR, // B_ABS
        (2 << BPROP_SIZE_SHIFT) | BPROP_ZP  | BPROP_PTR,  // B_YPTR
        (2 << BPROP_SIZE_SHIFT) | BPROP_ZP,              // B_XOFZ
        (3 << BPROP_SIZE_SHIFT) | BPROP_ABS,             // B_YOFF
        (3 << BPROP_SIZE_SHIFT) | BPROP_ABS | BPROP_SHR, // B_XOFF
        (1 << BPROP_SIZE_SHIFT),                         // B_IMP
        (2 << BPROP_SIZE_SHIFT) | BPROP_RELATIVE,        // B_REL
    };
    return flags[b >> 2];
}

static int8_t __fastcall__ getInsnProps(uint8_t opcode)
{
    /* JMP is special */
    if ((opcode == 0x4c) || (opcode == 0x6c))
        return (3 << BPROP_SIZE_SHIFT) | BPROP_ABS;

    return getBProps(getB(opcode));
}

static int8_t __fastcall__ getInsnLength(uint8_t opcode)
{
    return getInsnProps(opcode) >> BPROP_SIZE_SHIFT;
}


/* --- record management ------------------------------------------------- */

static void* addRecord(uint8_t descr)
{
    Record* r = (Record*)top;
    if ((r->descr & 0xe0) == RECORD_BYTES)
    {
        uint8_t len = r->descr & 0x1f;
        top += len;
        r = (Record*)top;
    }

    r->descr = descr;
    top += descr & 0x1f;
    return r;
}

static void emitByte(uint8_t byte)
{
    ByteRecord* r = (ByteRecord*)top;
    uint8_t len;
    if (((r->record.descr & 0xe0) != RECORD_BYTES) ||
        ((r->record.descr & 0x1f) == 0x1f))
    {
        r = addRecord(0 | RECORD_BYTES);
        r->record.descr++;
    }

    len = r->record.descr & 0x1f;
    r->bytes[len-1] = byte;
    r->record.descr++;
}

static void emitFill(uint16_t len)
{
    FillRecord* r = addRecord(sizeof(FillRecord) | RECORD_FILL);
    r->length = len;
}

static void addExpressionRecord(uint8_t op)
{
    if (tokenVariable)
    {
        ExpressionRecord* r = addRecord(sizeof(ExpressionRecord) | RECORD_EXPR);
        r->opcode = op;
        r->variable = tokenVariable;
        r->offset = tokenValue;
        r->length = 0xff;
        r->postprocessing = tokenPostProcessing;
    }
    else
    {
        uint8_t len = getInsnLength(op);
        emitByte(op);
        if (len != 1)
        {
            emitByte(tokenValue & 0xff);
            if (len != 2)
                emitByte(tokenValue >> 8);
        }
    }
}
/* --- Symbol table management ------------------------------------------- */

static SymbolRecord* lookupSymbol()
{
    SymbolRecord* r = lastSymbol;
    while (r)
    {
        uint8_t len = (r->record.descr & 0x1f) - offsetof(SymbolRecord, name);
        if ((len == tokenLength) && (memcmp(parseBuffer, r->name, len)==0))
            return r;
        r = r->next;
    }
    return NULL;
}

static SymbolRecord* appendSymbol()
{
    uint8_t len = tokenLength + offsetof(SymbolRecord, name);
    SymbolRecord* r;
    if (len > 0x1f)
        fatal("symbol too long");

    r = addRecord(RECORD_SYMBOL | len);
    memcpy(r->name, parseBuffer, tokenLength);
    r->next = lastSymbol;
    lastSymbol = r;
    return r;
}

static SymbolRecord* appendAnonymousSymbol()
{
    uint8_t oldLength = tokenLength;
    SymbolRecord* r;
    tokenLength = 0;
    r  = appendSymbol();
    tokenLength = oldLength;
    return r;
}

static SymbolRecord* addOrFindSymbol()
{
    SymbolRecord* r = lookupSymbol();
    if (r)
        return r;

    return appendSymbol();
}

static void symbolExists()
{
    errormessage("symbol exists: ");
    sfos_c_printstr(parseBuffer);
    crlf();
    sfos_s_warmboot();
}

static SymbolRecord* addSymbol()
{
    if(lookupSymbol())
        symbolExists();
    return appendSymbol();
}




/* --- parser ------------------------------------------------------------ */

static void syntaxError()
{
    fatal("syntax error");
}

static void expect(char t)
{
    if (token != t)
        syntaxError();
}

static void consume(char t)
{
    expect(t);
    consumeToken();
}

static char consumeXorY()
{
    if ((token == TOKEN_ID) && (tokenLength == 1))
    {
        char c = toupper(parseBuffer[0]);
        if ((c == 'X') || (c == 'Y'))
        {
            consumeToken();
            return c;
        }
    }
    fatal("expected X or Y");
}
/*
static uint16_t postProcess(uint16_t value)
{
    switch (tokenPostProcessing)
    {
        case PP_LSB:
            value = value & 0xff;
            break;

        case PP_MSB:
            value = value >> 8;
            break;
    }
    tokenPostProcessing = PP_NONE;
    return value;
}
*/
static void checkNodeConstant(uint8_t sp)
{
    if (exprVariable[sp])
        fatal("operation requires non-constant value");
}

static void consumeTokenThenConstant(uint8_t sp)
{
    consumeToken();
    consumeExpressionNode(sp + 1);
    checkNodeConstant(sp + 1);
}
static void checkConstantThenConsumeTokenThenConstant(uint8_t sp)
{
    checkNodeConstant(sp);
    consumeTokenThenConstant(sp);
}

static void checkDivisionByZero(uint8_t sp)
{
    if (!exprValue[sp])
        fatal("division by zero");
}
static void consumeExpressionNode(uint8_t sp)
{
    if (sp == EXPR_STACK_SIZE)
        fatal("expression too complex");

    exprVariable[sp] = NULL;

    /* Prefix operators. */

    switch (token)
    {
        case '<':
            consumeTokenThenConstant(sp);
            exprValue[sp] = exprValue[sp + 1] & 0xff;
            break;

        case '>':
            consumeTokenThenConstant(sp);
            exprValue[sp] = exprValue[sp + 1] >> 8;
            break;

        case '-':
            consumeTokenThenConstant(sp);
            exprValue[sp] *= -1;
            break;

        case '~':
            consumeTokenThenConstant(sp);
            exprValue[sp] ^= 0xff;
            break;

        case '(':
            consumeToken();
            consumeExpressionNode(sp);
            expect(')');
            break;

        case TOKEN_NUMBER:
            consumeToken();
            exprValue[sp] = tokenValue;
            break;

        case '*':
        case TOKEN_ID:
        {
            SymbolRecord* r;
            if (token == '*')
            {
                r = appendAnonymousSymbol();
                createLabelDefinition(r);
            }
            else
            {
                r = addOrFindSymbol();
                if (r->type == SYMBOL_UNINITIALISED)
                    r->type = SYMBOL_REFERENCE;
            }

            if (r->type == SYMBOL_COMPUTED)
            {
                exprVariable[sp] = r->variable;
                exprValue[sp] = r->offset;
            }
            else
            {
                exprVariable[sp] = r;
                exprValue[sp] = 0;
            }

            consumeToken();
            break;
        }

        default:
            syntaxError();
    }

    /* Infix operators, if any. */

    switch (token)
    {
        case ')':
        case ';':
        case ',':
            return;

        case '+':
            consumeTokenThenConstant(sp);
            exprValue[sp] += exprValue[sp + 1];
            break;

        case '-':
            consumeTokenThenConstant(sp);
            exprValue[sp] -= exprValue[sp + 1];
            break;

        case '*':
            checkConstantThenConsumeTokenThenConstant(sp);
            exprValue[sp] *= exprValue[sp + 1];
            break;

        case '|':
            checkConstantThenConsumeTokenThenConstant(sp);
            exprValue[sp] |= exprValue[sp + 1];
            break;

        case '^':
            checkConstantThenConsumeTokenThenConstant(sp);
            exprValue[sp] ^= exprValue[sp + 1];
            break;

        case '&':
            checkConstantThenConsumeTokenThenConstant(sp);
            exprValue[sp] &= exprValue[sp + 1];
            break;

        case '/':
            checkConstantThenConsumeTokenThenConstant(sp);
            checkDivisionByZero(sp + 1);
            exprValue[sp] /= exprValue[sp + 1];
            break;

        case '%':
            checkConstantThenConsumeTokenThenConstant(sp);
            checkDivisionByZero(sp + 1);
            exprValue[sp] %= exprValue[sp + 1];
            break;

        default:
            syntaxError();
    }
}

static void consumeExpression()
{
    tokenPostProcessing = PP_NONE;

    if (token == '<')
    {
        consumeToken();
        tokenPostProcessing = PP_LSB;
    }
    else if (token == '>')
    {
        consumeToken();
        tokenPostProcessing = PP_MSB;
    }

    consumeExpressionNode(0);
    tokenVariable = exprVariable[0];
    tokenValue = exprValue[0];

    if (!tokenVariable)
    {
        if (tokenPostProcessing == PP_LSB)
            tokenValue &= 0xff;
        else if (tokenPostProcessing == PP_MSB)
            tokenValue >>= 8;
        tokenPostProcessing = PP_NONE;
    }
}

static void consumeConstExpression()
{
    consumeExpression();
    if (tokenVariable)
        fatal("expression must be constant");

}

static AddressingMode consumeArgument()
{
    tokenValue = 0;
    tokenVariable = NULL;
    switch (token)
    {
        case '#':
            consumeToken();
            consumeExpression();
            return AM_IMM;

        case '(':
            consumeToken();
            consumeExpression();
            if (token == ')')
            {
                char c;
                consumeToken();
                if (token != ',')
                    return AM_WIND;

                consumeToken();
                c = consumeXorY();
                if (c != 'Y')
                    fatal("bad addressing mode");

                return AM_YPTR;
            }
            else
            {
                char c;
                consume(',');
                c = consumeXorY();
                if (c != 'X')
                    fatal("bad addressing mode");
                consume(')');

                return AM_XPTR;
            }

        case TOKEN_ID:
            if ((tokenLength == 1) && (toupper(parseBuffer[0]) == 'A'))
            {
                consumeToken();
                return AM_A;
            }
            /* fall through */
        case '*':
        case TOKEN_NUMBER:
            consumeExpression();
            if (token == ',')
            {
                char c;
                consumeToken();
                c = consumeXorY();
                if (c == 'X')
                {
                    if (!tokenVariable && (tokenValue < 0x100))
                        return AM_XOFZ;
                    else
                        return AM_XOFF;
                }
                else
                {
                    /* Must be Y */
                    if (!tokenVariable && (tokenValue < 0x100))
                        return AM_YOFZ;
                    else
                        return AM_YOFF;
                }
            }
            else if (!tokenVariable && (tokenValue < 0x100))
                return AM_ZP;
            else
                return AM_ABS;

        default:
            fatal("bad addressing mode");
    }
}

static SymbolRecord* consumeSymbolCommaNumber()
{
    SymbolRecord* r;
    expect(TOKEN_ID);
    r = addSymbol();
    consumeToken();

    consume(',');
    consumeConstExpression();
    return r;
}

static void consumeDotZp()
{
    SymbolRecord* r = consumeSymbolCommaNumber();
    if ((zpUsage + tokenValue) < zpUsage)
        fatal("ran out of zeropage");

    r->type = SYMBOL_ZP;
    r->offset = zpUsage;
    zpUsage += tokenValue;
}

static void consumeDotBss()
{
    SymbolRecord* r = consumeSymbolCommaNumber();
    if ((bssUsage + tokenValue) < bssUsage)
        fatal("ran out of BSS");
    r->type = SYMBOL_BSS;
    r->offset = bssUsage;
    bssUsage += tokenValue;
}

static void consumeDotByte()
{
    for (;;)
    {
        if (token == TOKEN_STRING)
        {
            const char* p = parseBuffer;
            while (tokenLength--)
                emitByte(*p++);

            consumeToken();
        }
        else
        {
            consumeExpression();
            if (tokenVariable)
                addExpressionRecord(0x00);
            else
                emitByte(tokenValue);
        }

        if (token != ',')
            break;
        consumeToken();
    }
}

static void consumeDotWord()
{
    for (;;)
    {
        consumeExpression();
        if (tokenVariable)
            addExpressionRecord(0xff);
        else
        {
            emitByte(tokenValue & 0xff);
            emitByte(tokenValue >> 8);
        }

        if (token != ',')
            break;
        consumeToken();
    }
}

static void consumeDotFill()
{
    consumeConstExpression();
    emitFill(tokenValue);
}

static void consumeDotExpand()
{
    consumeConstExpression();
    defaultBranchSize = tokenValue ? 5 : 2;
}

static void consumeDotLabel()
{
    consumeExpression();
}

static void createLabelDefinition(SymbolRecord* r)
{
    LabelDefinitionRecord* r2;
    if ((r->type != SYMBOL_UNINITIALISED) && (r->type != SYMBOL_REFERENCE))
        symbolExists();
    r->type = SYMBOL_TEXT;

    r2 = addRecord(sizeof(LabelDefinitionRecord) | RECORD_LABELDEF);
    r2->variable = r;
}


static void lookupAndCall(const SymbolCallbackEntry* entries)
{
    for (;;)
    {
        if (strcmp(entries->string, parseBuffer) == 0)
        {
            consumeToken();
            entries->callback();
            return;
        }
        entries ++;

        if (!entries->string)
            fatal("unknown psudo-op");
    }
}

static void parse()
{

    static const SymbolCallbackEntry dotEntries[] = {
        {"zp", consumeDotZp},
        {"bss", consumeDotBss},
        {"byte", consumeDotByte},
        {"word", consumeDotWord},
        {"fill", consumeDotFill},
        {"expand", consumeDotExpand},
        {"label", consumeDotLabel},
        //{"zproc", consumeZproc},
        //{"zendproc", consumeZendproc},
        //{"zloop", consumeZloop},
        //{"zendloop", consumeZendloop},
        //{"zbreak", consumeZbreak},
        //{"zcontinue", consumeZcontinue},
        //{"zrepeat", consumeZloop},
        //{"zuntil", consumeZuntil},
        //{"zif", consumeZif},
        //{"zendif", consumeZendif},
        //{"include", consumeInclude},
        {}
    };

    SymbolRecord* r;
    top = (uint8_t*)ram;

    for (;;)
    {
        switch (token)
        {
            case TOKEN_EOF:
                goto exit;

            case ';':
                consumeToken();
                continue;

            case '.':
                consumeToken();
                expect(TOKEN_ID);
                lookupAndCall(dotEntries);
                break;

            case TOKEN_ID:
                /* Process instructions. */
                if (tokenLength == 3)
                {
                    /* Look up the instruction. */

                    const Instruction* insn = findInstruction(simpleInsns);
                    if (insn)
                    {
                        AddressingMode am;
                        uint8_t op;
                        consumeToken();
                        if (insn->addressingModes & AM_IMP)
                        {
                            emitByte(insn->opcode);
                            break;
                        }

                        am = consumeArgument();
                        if ((insn->addressingModes & AM_IMMS) && (am == AM_IMM))
                            am = AM_IMMS;
                        if (!(insn->addressingModes & AM_YOFZ) &&
                            (am == AM_YOFZ))
                            am = AM_YOFF;
                        if (!(insn->addressingModes & AM_ZP) && (am == AM_ZP))
                            am = AM_ABS;
                        if (!(insn->addressingModes & am))
                            fatal("invalid addressing mode");
                        if ((insn->opcode == 0xa2) && (am == AM_YOFF))
                            am = AM_XOFF; /* ldx abs,y is special */

                        op = insn->opcode;
                        if (!(getInsnProps(op) & BPROP_RELATIVE))
                            op += getBofAM(am);
                        addExpressionRecord(op);
                        break;
                    }
                }

                /* Not an instruction. Must be a symbol definition. */

                r = addOrFindSymbol();
                consumeToken();
                if (token == ':')
                {
                    createLabelDefinition(r);
                    consumeToken();
                    continue;
                }
                else if (token == '=')
                {
                    if (r->type != SYMBOL_UNINITIALISED)
                        symbolExists();

                    consumeToken();
                    consumeExpression();
                    if (tokenPostProcessing != PP_NONE)
                        fatal("cannot postprocess value here");
                    if (tokenVariable)
                        r->variable = tokenVariable;
                    r->type = SYMBOL_COMPUTED;
                    r->offset = tokenValue;
                    break;
                }
                /* fall through */
            default:
                fatal("unexpected token");
        }

        if (token == 26)
            break;
        if (token != ';')
            fatal("unexpected garbage at end of line");
        consumeToken();
    }

exit:
    addRecord(1 | RECORD_EOF);
}


/* --- main -------------------------------------------------------------- */

static void print_ram() {
    ram = sfos_s_gettpa(); /* returns the address of free space pointed to by ram */
    top = (uint8_t*)ram;
    sfos_c_printstr("Free memory: ");
    printi(0xBF00 - ram);
    sfos_c_printstr("\r\n\r\n");
    memset(top, 0, 0xBEFF - ram);
}

void main(void)
{
    uint8_t current_drive = sfos_d_getsetdrive(0xFF);
    sfos_d_getsetdrive((&fcb2)->DRIVE);

    crlf();
    sfos_c_printstr("ASM: a stab in the dark\r\n");
    sfos_c_printstr("Written by David Latham (c) 2025\r\n");
    print_ram();

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

