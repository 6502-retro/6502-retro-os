#define VDP_RAM 0xbf30
#define VDP_REG 0xbf31

#define VRAM (*(char*)VDP_RAM)
#define VREG (*(char*)VDP_REG)

#define xy2scr(x,y) ((y*32)+x)

#define VDP_SPRITE_PATTERN_TABLE    0
#define VDP_PATTERN_TABLE           0x800
#define VDP_G2_PATTERN_TABLE        0
#define VDP_SPRITE_ATTRIBUTE_TABLE  0x1000
#define VDP_NAME_TABLE              0x1400
#define VDP_G2_NAME_TABLE           0x3800
#define VDP_COLOR_TABLE             0x2000

extern void vdp_init();
extern void vdp_init_g2();
extern void __fastcall__ vdp_set_write_address(unsigned int addr);
extern void __fastcall__ vdp_set_read_address(unsigned int addr);
extern void vdp_wait();
extern void vdp_flush();
extern void __fastcall__ vdp_write_to_screen_xy(unsigned char x, unsigned char y, unsigned char c);
extern unsigned char __fastcall__ vdp_read_from_screen_xy(unsigned char x, unsigned char y);
extern void vdp_clear_screen_buf();
extern unsigned char screen_buf[0x400];

extern unsigned char vdp_con_mode;
extern unsigned char vdp_con_width;
