/* vim: set et ts=4 sw=4 */
#include "sfos.h"
static const char cls[] = {0x1b,'[','2','J',0x1b,'[','H',0};

void main(void) {
    sfos_c_printstr(cls);
    sfos_s_warmboot();
}

