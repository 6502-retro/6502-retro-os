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
