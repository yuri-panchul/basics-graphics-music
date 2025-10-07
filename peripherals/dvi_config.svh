`ifndef DVI_CONFIG_SVH
`define DVI_CONFIG_SVH

parameter SCREEN_H_RES  = 640;
parameter SCREEN_V_RES  = 480;

parameter HSYNC_PULSE   = 96;
parameter H_FRONT_PORCH = 16;
parameter H_BACK_PORCH  = 48;
parameter H_BORDER      = 0;

parameter VSYNC_PULSE   = 2;
parameter V_FRONT_PORCH = 10;
parameter V_BACK_PORCH  = 33;
parameter V_BORDER      = 0;

// HSYNC
parameter HSYNC_START   = SCREEN_H_RES + H_BORDER + H_FRONT_PORCH;
parameter HSYNC_END     = HSYNC_START + HSYNC_PULSE;
parameter H_TOTAL       = HSYNC_END + H_BACK_PORCH + H_BORDER;

// VSYNC
parameter VSYNC_START   = SCREEN_V_RES + V_BORDER + V_FRONT_PORCH;
parameter VSYNC_END     = VSYNC_START + VSYNC_PULSE;
parameter V_TOTAL       = VSYNC_END + V_BACK_PORCH + V_BORDER;

parameter X_POS_W       = $clog2(SCREEN_H_RES + 1);
parameter Y_POS_W       = $clog2(SCREEN_V_RES + 1);

parameter HS_W          = $clog2(H_TOTAL + 1);
parameter VS_W          = $clog2(V_TOTAL + 1);

parameter COLOR_W       = 8;

`endif
