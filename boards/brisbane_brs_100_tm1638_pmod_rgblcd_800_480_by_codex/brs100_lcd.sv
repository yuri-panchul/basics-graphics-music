// RGB565 raster. The wrapper supplies panel-specific timing parameters.
// Check the actual panel pinout, timing and backlight before connecting it.
//
// Coordinates advance on a falling pixel-clock edge. On the NEXT falling
// edge, RGB and its corresponding DE/HS/VS are captured together. The panel
// samples them on the following rising edge. This gives the lab a
// whole pixel period to calculate RGB, and the panel half a period of setup.

module brs100_lcd
# (
    parameter screen_width  = 480,
              screen_height = 272,
              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,
              h_sync        = 41,
              h_back        = 2,
              h_front       = 2,
              v_sync        = 10,
              v_back        = 2,
              v_front       = 4,
              w_x           = $clog2 (screen_width),
              w_y           = $clog2 (screen_height)
)
(
    input                     pixel_clk,
    input                     rst,
    input  [w_red   - 1:0]     red,
    input  [w_green - 1:0]     green,
    input  [w_blue  - 1:0]     blue,
    output logic [w_x - 1:0]   x,
    output logic [w_y - 1:0]   y,
    output logic              lcd_de,
    output logic              lcd_hs,
    output logic              lcd_vs,
    // Keep separate RGB registers so identical color bits can use I/O flops.
    (* syn_preserve = 1 *) output logic [w_red   - 1:0] lcd_r,
    (* syn_preserve = 1 *) output logic [w_green - 1:0] lcd_g,
    (* syn_preserve = 1 *) output logic [w_blue  - 1:0] lcd_b
);
    localparam h_start = h_sync + h_back,
               v_start = v_sync + v_back,
               h_total = h_start + screen_width  + h_front,
               v_total = v_start + screen_height + v_front;

    logic [$clog2 (h_total) - 1:0] h;
    logic [$clog2 (v_total) - 1:0] v;

    wire active = h >= h_start && h < h_start + screen_width
               && v >= v_start && v < v_start + screen_height;

    // Register coordinates, including the blanking clamp. This removes the
    // raster subtraction/mux from paths into a lab's registered RGB logic.
    wire [$clog2 (h_total) - 1:0] next_h = h == h_total - 1 ? '0 : h + 1'b1;
    wire [$clog2 (v_total) - 1:0] next_v = h == h_total - 1
        ? (v == v_total - 1 ? '0 : v + 1'b1) : v;
    wire next_active = next_h >= h_start && next_h < h_start + screen_width
                    && next_v >= v_start && next_v < v_start + screen_height;

    always_ff @ (negedge pixel_clk or posedge rst)
        if (rst)
        begin
            x      <= '0;
            y      <= '0;
            h      <= '0;
            v      <= '0;
            lcd_de <= 1'b0;
            lcd_hs <= 1'b1;
            lcd_vs <= 1'b1;
            lcd_r  <= '0;
            lcd_g  <= '0;
            lcd_b  <= '0;
        end
        else
        begin
            h <= next_h;
            v <= next_v;
            x <= next_active ? w_x' (next_h - h_start) : '0;
            y <= next_active ? w_y' (next_v - v_start) : '0;

            lcd_de <= active;
            lcd_hs <= h >= h_sync;
            lcd_vs <= v >= v_sync;
            lcd_r  <= active ? red   : '0;
            lcd_g  <= active ? green : '0;
            lcd_b  <= active ? blue  : '0;
        end
endmodule
