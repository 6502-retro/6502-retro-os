/* vim: set ts=4 sw=4 et */
/* qe © 2019 David Given
 * This library is distributable under the terms of the 2-clause BSD license.
 * See COPYING.cpmish in the distribution root directory for more information.
 *
 * Ported to SFM by David Latham - 2024
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>

#include "sfos.h"
#include "ansi.h"

#undef bool
#define bool uint8_t

enum ERRORS {
        OK               = 0,
        FILE_NOT_FOUND   = 1,
        FILE_EXISTS      = 2,
        FILE_MAX_REACHED = 3,
        FILE_EOF         = 4,
        END_OF_DIR       = 5,
        DRIVE_ERROR      = 6,
        DRIVE_FULL       = 7,
        PARSE_ERROR      = 8,
        OUT_OF_MEMORY    = 9
};

uint8_t width, height;
uint8_t viewheight;
uint8_t status_line_length;
void (*print_status)(const char*);

uint8_t* buffer_start;
uint8_t* gap_start;
uint8_t* gap_end;
uint8_t* buffer_end;
uint8_t dirty;

uint8_t* first_line;   /* <= gap_start */
uint8_t* current_line; /* <= gap_start */
uint8_t current_line_y;
uint8_t
    display_height[64];   /* array of number of screen lines per logical line */
uint16_t line_length[64]; /* array of line length per logical line */

uint16_t command_count;
typedef void command_t(uint16_t);

struct bindings
{
    const char* name;
    const char* keys;
    command_t* const* callbacks;
};

const struct bindings* bindings;

extern const struct bindings delete_bindings;
extern const struct bindings zed_bindings;
extern const struct bindings change_bindings;

#define buffer ((char*)0xC200)
#define sd_buf ((uint8_t*)0xC000)

extern void colon(uint16_t count);
extern void goto_line(uint16_t lineno);

//extern uint16_t* sfm_ram_base;
//extern uint16_t* sfm_ram_top;
#define sfm_ram_base = 0x3000;
#define sfm_ram_top  = 0xB700;
/* ======================================================================= */
/*                                MISCELLANEOUS                            */
/* ======================================================================= */

void cpm_printstring0(const char* s)
{
    for (;;)
    {
        char c = *s++;
        if (!c)
            return;
        sfos_c_write(c);
    }
}

void print_newline(void)
{
    cpm_printstring0("\r\n");
}

/* Appends a string representation of the FCB to buffer. */
void render_fcb(_fcb* f)
{
    char* inp;
    char* outp = buffer;
    uint8_t c;

    while (*outp++)
        ;
    outp--;

    if (f->DRIVE)
    {
        *outp++ = '@' + f->DRIVE;
        *outp++ = ':';
    }

    inp = &f->NAME[0];
    while (inp != &f->EXT[3])
    {
        if (inp == &f->NAME[8])
            *outp++ = '.';
        c = *inp++;
        if (c != ' ')
            *outp++ = c;
    }

    *outp++ = '\0';
}

char* strcat(char* dest, const char* src)
{
    while (*dest++)
        ;
    dest--;

    strcpy(dest, src);
    return NULL;
}
#if 0
static void my_strrev(char *str)
{
    size_t len = strlen(str);
    size_t i,j;
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
    do
    {
        uint8_t digit = val % 10;
        buf[i++] = '0' + digit;
        val /= 10;
    } while (val);
    buf[i] = '\0';
    my_strrev(buf);
}
#endif

/* ======================================================================= */
/*                                SCREEN DRAWING                           */
/* ======================================================================= */

void screen_puti(uint16_t i)
{
    itoa(i, buffer, 10);
    ansi_puts(buffer);
}

void goto_status_line(void)
{
    ansi_set_cursor(1, viewheight);
}

void set_status_line(const char* message)
{
    uint8_t screenx, screeny;
    uint8_t length;
    ansi_get_cursor(&screenx, &screeny);

    length = 0;
    goto_status_line();
    ansi_rev_on();
    for (;;)
    {
        char c = *message++;
        if (!c)
            break;
        ansi_putc(c);
        length++;
    }
    ansi_rev_off();
    while (length < status_line_length)
    {
        ansi_putc(' ');
        length++;
    }
    status_line_length = length;
    ansi_set_cursor(screenx, screeny);
}

/* ======================================================================= */
/*                              BUFFER MANAGEMENT                          */
/* ======================================================================= */

void new_file(void)
{
    gap_start = buffer_start;
    gap_end = buffer_end;

    first_line = current_line = buffer_start;
    dirty = true;
}

uint16_t compute_length(
    const uint8_t* inp, const uint8_t* endp, const uint8_t** nextp)
{
    uint8_t xo;
    char c;

    xo = 0;
    for (;;)
    {
        if (inp == endp)
            break;
        if (inp == gap_start)
            inp = gap_end;

        c = *inp++;
        if (c == '\n')
            break;
        if (c == '\t')
            xo = (xo + 8) & ~7;
        else if (c < 32)
            xo += 2;
        else
            xo++;
    }

    if (nextp)
        *nextp = inp;
    return xo;
}

uint8_t* draw_line(uint8_t* startp)
{
    uint8_t* inp = startp;

    uint8_t screenx, starty;
    uint8_t x,y;
    char c;
    ansi_get_cursor(&screenx, &starty);

    x = 0;
    y = starty;
    for (;;)
    {
        if (y == viewheight)
            goto bottom_of_screen;

        if (inp == gap_start)
        {
            inp = gap_end;
            startp += (gap_end - gap_start);
        }
        if (inp == buffer_end)
        {
            if (x == 0)
                ansi_putc('~');
            break;
        }

        c = *inp++;
        if (c == '\n')
            break;

        if (x == width)
        {
            x = 0;
            y++;
            ansi_set_cursor(x, y);
        }

        if (c == '\t')
        {
            do
            {
                ansi_putc(' ');
                x++;
            } while ((x & 7) || (x == width));
        }
        else
        {
            ansi_putc(c);
            x++;
        }
    }

    if (x != width)
        ansi_clear_eol();
    ansi_set_cursor(1, y+1);

bottom_of_screen:
    display_height[starty] = y - starty + 1;
    line_length[starty] = inp - startp;

    return inp;
}

/* inp <= gap_start */
void render_screen(uint8_t* inp)
{
    uint8_t x, y;
    ansi_get_cursor(&x, &y);

    while (y != viewheight)
        display_height[y++] = 0;

    for (;;)
    {
        ansi_get_cursor(&x, &y);
        if (y >= viewheight)
            break;

        if (inp == current_line)
            current_line_y = y;

        inp = draw_line(inp);
    }
}

void adjust_scroll_position(void)
{
    uint8_t total_height = 0;

    first_line = current_line;
    while (first_line != buffer_start)
    {
        uint8_t* line_start = first_line;
        const uint8_t* line_end = line_start--;
        while ((line_start != buffer_start) && (line_start[-1] != '\n'))
            line_start--;

        total_height +=
            (compute_length(line_start, line_end, NULL) / width) + 1;
        if (total_height > (viewheight / 2))
            break;
        first_line = line_start;
    }

    ansi_set_cursor(1, 1);
    render_screen(first_line);
}

void recompute_screen_position(void)
{
    const uint8_t* inp;
    uint8_t h;
    uint8_t length;
    if (current_line < first_line)
        adjust_scroll_position();

    for (;;)
    {
        inp = first_line;
        current_line_y = 1;
        while (current_line_y < viewheight)
        {
            if (inp == current_line)
                break;

            h = display_height[current_line_y];
            inp += line_length[current_line_y];

            current_line_y += h;
        }

        if ((current_line_y >= viewheight) ||
            ((current_line_y + display_height[current_line_y]) > viewheight))
        {
            adjust_scroll_position();
        }
        else
            break;
    }

    length = compute_length(current_line, gap_start, NULL);
    ansi_set_cursor((length % width) + 1, current_line_y + (length / width));
}

void redraw_current_line(void)
{
    uint8_t* nextp;
    uint8_t oldheight;

    oldheight = display_height[current_line_y];
    ansi_set_cursor(1, current_line_y);
    nextp = draw_line(current_line);
    if (oldheight != display_height[current_line_y])
        render_screen(nextp);

    recompute_screen_position();
}

/* ======================================================================= */
/*                                LIFECYCLE                                */
/* ======================================================================= */
uint8_t sfos_d_delete(_fcb* f)
{
    while (sfos_d_findfirst(f) == 0) {
        sfos_c_printstr("\r\nDeleting file...");
        f->ATTRIB = 0xE5;
        sfos_d_close(f);
    }
    return 0;
}

uint8_t sfos_d_rename(_fcb* f, char* name)
{
    if (sfos_d_findfirst(f) == 0) {
        memcpy(f->NAME, name, 11);
        f->DS = 0;
        sfos_d_close(f);
        return 0;
    } else
        return 1;
}

void insert_file(void)
{
    uint16_t inptr;
    uint8_t c;
    uint8_t sc = fcb2.SC;

    strcpy(buffer, "Reading ");
    render_fcb(&fcb2);
    print_status(buffer);

    if (sfos_d_open(&fcb2))
        goto error;

    for (;;)
    {
        sfos_d_setdma((uint16_t*)0xC000);
        sfos_d_readseqblock(&fcb2);

        inptr = 0;
        while (inptr != 512)
        {
            c = sd_buf[inptr++];
            if (c == 26) /* EOF */
                goto done;
            if (c != '\r')
            {
                if (gap_start == gap_end)
                {
                    print_status("Out of memory");
                    goto done;
                }
                *gap_start++ = c;
            }
        }
        sc --;
        if (sc == 0) goto done;
    }

error:
    print_status("Could not read file");
done:
    dirty = true;
    return;
}

void load_file(void)
{
    new_file();
    if (fcb2.NAME[0])
        insert_file();

    dirty = false;
    goto_line(1);
}

uint8_t really_save_file(_fcb* f)
{
    const uint8_t* inp;
    uint8_t c;
    uint8_t pushed = 0;
    uint16_t outp = 0;

    strcpy(buffer, "Writing ");
    render_fcb(f);
    print_status(buffer);

    f->SC = 0;
    f->SIZE = 0;

    if (sfos_d_make(f))
        return 0xff;
    f->CR = 0;


    inp = buffer_start;
    while ((inp != buffer_end) || (outp != 0) || pushed)
    {

        if (pushed)
        {
            c = pushed;
            pushed = 0;
        }
        else
        {
            if (inp == gap_start)
                inp = gap_end;
            c = (inp != buffer_end) ? *inp++ : 26;

            if (c == '\n')
            {
                pushed = '\n';
                c = '\r';
            }
        }

        sd_buf[outp++] = c;

        if (outp == 512)
        {
            sfos_d_setdma((uint16_t*)0xC000);
            sfos_d_writeseqblock(f);
            f->SC ++;
            f->SIZE += 512;
            outp = 0;
        }
    }

    dirty = false;
    return sfos_d_close(f);
}

bool save_file(void)
{
    static _fcb tempfcb;

    fcb2.SC = 0;
    if (sfos_d_open(&fcb2))
    {
        print_status("New file.");
        /* The file does not exist. */
        if (really_save_file(&fcb2))
        {
            print_status("Failed to save file");
            return false;
        }
        else
        {
            dirty = false;
            return true;
        }
    }

    /* Write to a temporary file. */

    tempfcb.DRIVE = fcb2.DRIVE;
    strcpy((char*)tempfcb.NAME, "QETEMP  $$$");
    sfos_d_delete(&tempfcb);
    if (sfos_d_make(&tempfcb) )
        goto tempfile;

    if (really_save_file(&tempfcb))
        goto tempfile;

    strcpy(buffer, "Removing old ");
    render_fcb(&fcb2);
    print_status(buffer);

    if (sfos_d_delete(&fcb2))
        goto cant_commit;

    strcpy(buffer, "Renaming ");
    render_fcb(&tempfcb);
    strcat(buffer, " to ");
    render_fcb(&fcb2);
    print_status(buffer);

    if (sfos_d_rename(&tempfcb, (char*)(&fcb2)->NAME))
        goto cant_commit;
    return true;

tempfile:
    print_status("Cannot create QETEMP.$$$ file (it may exist)");
    return false;

cant_commit:
    print_status("Cannot commit file; your data may be in QETEMP.$$$");
    return false;
}

void quit(void)
{
    //goto_status_line();
    cpm_printstring0("Goodbye!\r\n");
    sfos_s_warmboot();
}

/* ======================================================================= */
/*                            EDITOR OPERATIONS                            */
/* ======================================================================= */

void cursor_home(uint16_t count)
{
    (void)count;
    while (gap_start != current_line)
        *--gap_end = *--gap_start;
}

void cursor_end(uint16_t count)
{
    (void)count;
    while ((gap_end != buffer_end) && (gap_end[0] != '\n'))
        *gap_start++ = *gap_end++;
}

void cursor_left(uint16_t count)
{
    while (count--)
    {
        if ((gap_start != buffer_start) && (gap_start[-1] != '\n'))
            *--gap_end = *--gap_start;
    }
}

void cursor_right(uint16_t count)
{
    while (count--)
    {
        if ((gap_end != buffer_end) && (gap_end[0] != '\n'))
            *gap_start++ = *gap_end++;
    }
}

void cursor_down(uint16_t count)
{
    while (count--)
    {
        uint16_t offset = gap_start - current_line;
        cursor_end(1);
        if (gap_end == buffer_end)
            return;

        *gap_start++ = *gap_end++;
        current_line = gap_start;
        cursor_right(offset);
    }
}

void cursor_up(uint16_t count)
{
    while (count--)
    {
        uint16_t offset = gap_start - current_line;

        cursor_home(1);
        if (gap_start == buffer_start)
            return;

        do
            *--gap_end = *--gap_start;
        while ((gap_start != buffer_start) && (gap_start[-1] != '\n'));

        current_line = gap_start;
        cursor_right(offset);
    }
}

bool word_boundary(char left, char right)
{
    if (!isalnum(left) && isalnum(right))
        return 1;
    if (isspace(left) && !isspace(right))
        return 1;
    return 0;
}

void cursor_wordleft(uint16_t count)
{
    while (count--)
    {
        bool linechanged = false;

        while (gap_start != buffer_start)
        {
            uint16_t right = *--gap_start = *--gap_end;
            uint16_t left = gap_start[-1];
            if (right == '\n')
                linechanged = true;

            if (word_boundary(left, right))
                break;
        }

        if (linechanged)
        {
            current_line = gap_start;
            while ((current_line != buffer_start) && (current_line[-1] != '\n'))
                current_line--;
        }
    }
}

void cursor_wordright(uint16_t count)
{
    while (count--)
    {
        while (gap_end != buffer_end)
        {
            uint16_t left = *gap_start++ = *gap_end++;
            uint16_t right = *gap_end;
            if (left == '\n')
                current_line = gap_start;

            if (word_boundary(left, right))
                break;
        }
    }
}

void insert_newline(void)
{
    uint8_t x;
    if (gap_start != gap_end)
    {
        *gap_start++ = '\n';
        ansi_set_cursor(1, current_line_y);
        current_line = draw_line(current_line);

        ansi_get_cursor(&x, &current_line_y);
        display_height[current_line_y] = 0;
    }
}

void insert_mode(bool replacing)
{
    //uint8_t* nextp;
    uint8_t c;
    set_status_line(replacing ? "Replace mode" : "Insert mode");

    for (;;)
    {
        c = ansi_getc();
        if (c == 27)
            break;
        else if(c>127)
            /* Ignore arrow keys in insert mode*/
            continue;


        dirty = true;
        
            
        if (c == 8 || c == 127)
        {
            if (gap_start != current_line)
                gap_start--;
        }
        else if (gap_start == gap_end)
        {
            /* Do nothing, out of memory */
        }
        else
        {
            if (replacing && (gap_end != buffer_end) && (*gap_end != '\n'))
                gap_end++;

            if (c == 13)
                insert_newline();
            else
                *gap_start++ = c;
        }

        redraw_current_line();
    }

    set_status_line("");
}

void insert_text(uint16_t count)
{
    (void)count;
    insert_mode(false);
}

void append_text(uint16_t count)
{
    cursor_end(1);
    recompute_screen_position();
    insert_text(count);
}

void goto_line(uint16_t lineno)
{
    while (gap_start != buffer_start)
        *--gap_end = *--gap_start;
    current_line = buffer_start;

    while ((gap_end != buffer_end) && --lineno)
    {
        while (gap_end != buffer_end)
        {
            uint16_t c = *gap_start++ = *gap_end++;
            if (c == '\n')
            {
                current_line = gap_start;
                break;
            }
        }
    }
}

void delete_right(uint16_t count)
{
    while (count--)
    {
        if (gap_end == buffer_end)
            break;
        gap_end++;
    }

    redraw_current_line();
    dirty = true;
}

void delete_rest_of_line(uint16_t count)
{
    while ((gap_end != buffer_end) && (*++gap_end != '\n'))
        ;

    if (count != 0)
        redraw_current_line();
    dirty = true;
}

void delete_line(uint16_t count)
{
    while (count--)
    {
        cursor_home(1);
        delete_rest_of_line(0);
        if (gap_end != buffer_end)
        {
            gap_end++;
            display_height[current_line_y] = 0;
        }
    }

    redraw_current_line();
    dirty = true;
}

void delete_word(uint16_t count)
{
    while (count--)
    {
        uint16_t left = (gap_start == buffer_start) ? '\n' : gap_start[-1];

        while (gap_end != buffer_end)
        {
            uint16_t right = *++gap_end;

            if ((gap_end == buffer_end) || (right == '\n'))
                break;
            if (word_boundary(left, right))
                break;

            left = right;
        }
    }

    redraw_current_line();
    dirty = true;
}

void change_word(uint16_t count)
{
    delete_word(1);
    insert_text(count);
}

void change_rest_of_line(uint16_t count)
{
    delete_rest_of_line(1);
    insert_text(count);
}

void join(uint16_t count)
{
    while (count--)
    {
        uint8_t* ptr = gap_end;
        while ((ptr != buffer_end) && (*ptr != '\n'))
            ptr++;

        if (ptr != buffer_end)
            *ptr = ' ';
    }

    ansi_set_cursor(1, current_line_y);
    render_screen(current_line);
    dirty = true;
}

void open_above(uint16_t count)
{
    if (gap_start == gap_end)
        return;

    cursor_home(1);
    *--gap_end = '\n';

    recompute_screen_position();
    ansi_set_cursor(1, current_line_y);
    render_screen(current_line);
    recompute_screen_position();

    insert_text(count);
}

void open_below(uint16_t count)
{
    cursor_down(1);
    open_above(count);
}

void replace_char(uint16_t count)
{
    uint8_t c = ansi_getc();
    (void)count;

    if (gap_end == buffer_end)
        return;
    if (c == '\n')
    {
        gap_end++;
        /* The cursor ends up *after* the newline. */
        insert_newline();
    }
    else if (isprint(c))
    {
        *gap_end = c;
        /* The cursor ends on *on* the replace character. */
        redraw_current_line();
    }
}

void replace_line(uint16_t count)
{
    (void)count;
    insert_mode(true);
}

void zed_save_and_quit(uint16_t count)
{
    (void)count;
    if (!dirty)
        quit();
    if (!fcb2.NAME[0])
    {
        set_status_line("No filename set");
        return;
    }
    if (save_file())
        quit();
}

void zed_force_quit(uint16_t count)
{
    (void)count;
    quit();
}

void redraw_screen(uint16_t count)
{
    (void)count;
    ansi_clear();
    render_screen(first_line);
}

void enter_delete_mode(uint16_t count)
{
    bindings = &delete_bindings;
    command_count = count;
}

void enter_zed_mode(uint16_t count)
{
    bindings = &zed_bindings;
    command_count = count;
}

void enter_change_mode(uint16_t count)
{
    bindings = &change_bindings;
    command_count = count;
}

const char normal_keys[] = "^$hjklbwiAGxJOorR:\022dZc\210\211\212\213";

command_t* const normal_cbs[] = {
    cursor_home,
    cursor_end,
    cursor_left,
    cursor_down,
    cursor_up,
    cursor_right,
    cursor_wordleft,
    cursor_wordright,
    insert_text,
    append_text,
    goto_line,
    delete_right,
    join,
    open_above,
    open_below,
    replace_char,
    replace_line,
    colon,
    redraw_screen,
    enter_delete_mode,
    enter_zed_mode,
    enter_change_mode,
    cursor_left,
    cursor_right,
    cursor_down,
    cursor_up,
};

const struct bindings normal_bindings = {NULL, normal_keys, normal_cbs};

const char delete_keys[] = "dw$";
command_t* const delete_cbs[] = {
    delete_line,
    delete_word,
    delete_rest_of_line,
};

const struct bindings delete_bindings = {"Delete", delete_keys, delete_cbs};

const char change_keys[] = "w$";
command_t* const change_cbs[] = {
    change_word,
    change_rest_of_line,
};

const struct bindings change_bindings = {"Change", change_keys, change_cbs};

const char zed_keys[] = "ZQ";
command_t* const zed_cbs[] = {
    zed_save_and_quit,
    zed_force_quit,
};

const struct bindings zed_bindings = {"Zed", zed_keys, zed_cbs};

/* ======================================================================= */
/*                             COLON COMMANDS                              */
/* ======================================================================= */

void set_current_filename(const char* f)
{
    sfos_d_setdma((uint16_t*)&fcb2);
    if (!sfos_d_parsefcb((uint16_t*)f))
    {
        cpm_printstring0("Bad filename\r\n");
        fcb2.NAME[0] = 0;
        return;
    }
        
    dirty = true;
}

void print_no_filename(void)
{
    cpm_printstring0("No filename set\r\n");
}

void print_document_not_saved(void)
{
    cpm_printstring0("Document not saved (use ! to confirm)\r\n");
}

void print_colon_status(const char* s)
{
    cpm_printstring0(s);
    print_newline();
}

void colon(uint16_t count)
{
    char* w;
    char* arg;
    bool quitting;
    _fcb backupfcb;
    (void)count;
    print_status = print_colon_status;

    for (;;)
    {
        goto_status_line();
        sfos_c_write(':');
        buffer[0] = 126;
        buffer[1] = 0;
        sfos_c_readstr(126, (char*)buffer);
        print_newline();

        buffer[buffer[1] + 2] = '\0';

        w = strtok(buffer + 2, " ");
        if (!w)
            break;
        arg = strtok(NULL, " ");
        switch (*w)
        {
            case 'w':
            {
                quitting = w[1] == 'q';
                if (arg)
                    set_current_filename(arg);
                if (!fcb2.NAME[0])
                    print_no_filename();
                else if (save_file())
                {
                    if (quitting)
                        quit();
                }
                break;
            }

            case 'r':
            {
                if (arg)
                {
                    memcpy(&backupfcb, &fcb2, sizeof(_fcb));
                    sfos_d_setdma((uint16_t*)&fcb2);
                    sfos_d_parsefcb((uint16_t*)arg);
                    if (fcb2.NAME[0])
                        insert_file();
                    memcpy(&fcb2, &backupfcb, sizeof(_fcb));
                }
                else
                    print_no_filename();
                break;
            }

            case 'e':
            {
                if (!arg)
                    print_no_filename();
                else if (dirty && (w[1] != '!'))
                    print_document_not_saved();
                else
                {
                    set_current_filename(arg);
                    if (fcb2.NAME[0])
                        load_file();
                }
                break;
            }

            case 'p':
                render_fcb(&fcb2);
                print_colon_status(buffer);
                break;

            case 'n':
            {
                if (dirty && (w[1] != '!'))
                    print_document_not_saved();
                else
                {
                    new_file();
                    fcb2.NAME[0] = 0; /* no filename */
                }
                break;
            }

            case 'q':
            {
                if (!dirty || (w[1] == '!'))
                    quit();
                else
                    print_document_not_saved();
                break;
            }

            default:
                cpm_printstring0("Unknown command\r\n");
        }
    }

    ansi_clear();
    print_status = set_status_line;
    render_screen(first_line);
}

/* ======================================================================= */
/*                            EDITOR OPERATIONS                            */
/* ======================================================================= */

void main(void)
{
    char c;
    const char* cmdp;
    command_t* cmd;
    uint16_t count;

#if 0
    if (!screen_init())
    {
        cpm_printstring0("No SCREEN");
        print_newline();
        return;
    }
#else
    ansi_init(80, 30);
#endif

    if (fcb2.NAME[0] == ' ')
        fcb2.NAME[0] = 0;

    ansi_get_size(&width, &height);
    if (height > sizeof(display_height) - 1)
        height = sizeof(display_height) - 1;
    width++;
    viewheight = height;
    height++;

    buffer_start = (uint8_t*)0x3000;
    buffer_end = (uint8_t*)0xb700 - 1;

    ansi_clear();

    *buffer_end = '\n';
    print_status = set_status_line;

    itoa((uint16_t)(buffer_end - buffer_start), buffer, 10);
    strcat(buffer, " bytes free");
    print_status(buffer);

    sfos_d_setdma((uint16_t*)sd_buf);
    load_file();

    ansi_set_cursor(1, 1);
    render_screen(first_line);
    bindings = &normal_bindings;

    command_count = 0;
    for (;;)
    {
        recompute_screen_position();

        for (;;)
        {
            c = ansi_getc();
            if (isdigit(c))
            {
                command_count = (command_count * 10) + (c - '0');
                itoa(command_count, buffer, 10);
                strcat(buffer, " repeat");
                set_status_line(buffer);
            }
            else
            {
                set_status_line("");
                break;
            }
        }

        cmdp = strchr(bindings->keys, c);
        if (cmdp)
        {
            cmd = bindings->callbacks[cmdp - bindings->keys];
            count = command_count;
            if (count == 0)
            {
                if (cmd == goto_line)
                    count = UINT_MAX;
                else
                    count = 1;
            }
            command_count = 0;

            bindings = &normal_bindings;
            set_status_line("");
            cmd(count);
            if (bindings->name)
                set_status_line(bindings->name);
        }
        else
        {
            set_status_line("Unknown key");
            bindings = &normal_bindings;
            command_count = 0;
        }
    }
}

