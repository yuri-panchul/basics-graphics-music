`include "config.svh"

    // Shows the image on the VGA screen using signal lines in Wave Analyzer

module tb;

    timeunit      1ns;
    timeprecision 1ps;

    //------------------------------------------------------------------------

    localparam clk_mhz       = 27,
               pixel_mhz     = 9,
               w_key         = 4,
               w_sw          = 4,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 32,
               w_red         = 5,
               w_green       = 6,
               w_blue        = 5,
               screen_width  = 480,
               screen_height = 272,
               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height );

    localparam clk_period    = 30ns;

    //------------------------------------------------------------------------

    logic                       clk;
    logic                       pixel_clk;
    logic                       rst;
    logic  [w_key       - 1:0]  key;
    logic  [w_x         - 1:0]  x;
    logic  [w_y         - 1:0]  y;
    logic  [              0:0]  pixel;
    logic                       LCD_DE;
    logic                       LCD_VS;
    logic                       LCD_HS;
    logic                       LCD_CLK;
    logic                       LCD_BL;
    logic  [              4:0]  LCD_R;
    logic  [              5:0]  LCD_G;
    logic  [              4:0]  LCD_B;

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),
        .w_key         ( w_key         ),
        .w_sw          ( w_key         ),
        .w_led         ( w_led         ),
        .w_digit       ( w_digit       ),
        .w_gpio        ( w_gpio        ),
        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),
        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),
        .key           ( key           ),
        .x             ( x             ),
        .y             ( y             ),
        .red           ( LCD_R         ),
        .green         ( LCD_G         ),
        .blue          ( LCD_B         )

    );

    // We output all the green pixels to signal lines in Wave Analyzer

    assign  pixel = |LCD_R; // You can try it |LCD_G or |LCD_B or a mix of them

    //------------------------------------------------------------------------

    tb_lcd_480_272        i_lcd
    (
        .PixelClk      (   pixel_clk   ),
        .rst           (   rst         ),
        .LCD_DE        (   LCD_DE      ),
        .LCD_HSYNC     (   LCD_HS      ),
        .LCD_VSYNC     (   LCD_VS      ),
        .x             (   x           ),
        .y             (   y           )
    );

    //------------------------------------------------------------------------

    // We output pixels to signal lines in Wave Analyzer

    tb_lcd_display        i_display
    (
        .PixelClk      (   pixel_clk   ),
        .rst           (   rst         ),
        .LCD_DE        (   LCD_DE      ),
        .LCD_HSYNC     (   LCD_HS      ),
        .LCD_VSYNC     (   LCD_VS      ),
        .pixel         (   pixel       )
    );

    //------------------------------------------------------------------------
    initial
    begin
        clk = 1'b0;

        forever
            # (clk_period / 2) clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        pixel_clk = 1'b0;

        forever
            # (clk_period / 6) pixel_clk = ~ pixel_clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 'bx;
        repeat (2) @ (posedge clk);
        rst <= 1;
        repeat (2) @ (posedge clk);
        rst <= 0;
    end

    //------------------------------------------------------------------------

    assign key = w_key' (0);

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        // Based on timescale is 1 ns / 1 ps

        # 0.0001740s  // We simulate until the end of the first frame

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule

    // Scan and Sync signal generator for VGA screen

module tb_lcd_480_272
(
    input        PixelClk,
    input        rst,
    output       LCD_DE,
    output       LCD_HSYNC,
    output       LCD_VSYNC,
    output [8:0] x,
    output [8:0] y
);

    // Calculation of visible, invisible pixel fields and synchronization signals

    parameter       H_Pixel_Valid    = 16'd480;
    parameter       H_FrontPorch     = 16'd50;
    parameter       H_BackPorch      = 16'd30;
    parameter       PixelForHS       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;
    parameter       V_Pixel_Valid    = 16'd272;
    parameter       V_FrontPorch     = 16'd20;
    parameter       V_BackPorch      = 16'd5;
    parameter       PixelForVS       = V_Pixel_Valid + V_FrontPorch + V_BackPorch;

    // Pixel counter

    logic   [15:0]  H_PixelCount;
    logic   [15:0]  V_PixelCount;

    always_ff @ ( posedge PixelClk or posedge rst )begin
        if ( rst ) begin
            V_PixelCount       <=  16'b0;
            H_PixelCount       <=  16'b0;
            end
        else if ( H_PixelCount == PixelForHS ) begin   // We show every 9 lines using 
            V_PixelCount       <= V_PixelCount + 4'd9; // signal lines in Wave Analyzer
            H_PixelCount       <=  16'b0;
            end
        else if ( V_PixelCount >= PixelForVS ) begin
            V_PixelCount       <=  16'b0;
            H_PixelCount       <=  16'b0;
            end
        else begin
            V_PixelCount       <= V_PixelCount ;
            H_PixelCount       <= H_PixelCount + 1'b1;
        end
    end

    // Synchronization signals

    assign  LCD_HSYNC = H_PixelCount   <= ( PixelForHS - H_FrontPorch ) ? 1'b0 : 1'b1;
    assign  LCD_VSYNC = V_PixelCount   <  ( PixelForVS )  ? 1'b0 : 1'b1;
    assign  LCD_DE    = ( H_PixelCount >= H_BackPorch ) && 
                        ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                        ( V_PixelCount >= V_BackPorch ) &&
                        ( V_PixelCount <= V_Pixel_Valid + V_BackPorch ) && PixelClk;

    // Current pixel position

    assign x = 9' (H_PixelCount - H_BackPorch);
    assign y = 9' (V_PixelCount - V_BackPorch);

endmodule

    // Shows the image on the VGA screen using signal lines in Wave Analyzer

module tb_lcd_display
(
    input                  PixelClk,
    input                  rst,
    input                  LCD_DE,
    input                  LCD_HSYNC,
    input                  LCD_VSYNC,
    input                  pixel,
    output                 pixel_00,
    output                 pixel_01,
    output                 pixel_02,
    output                 pixel_03,
    output                 pixel_04,
    output                 pixel_05,
    output                 pixel_06,
    output                 pixel_07,
    output                 pixel_08,
    output                 pixel_09,
    output                 pixel_10,
    output                 pixel_11,
    output                 pixel_12,
    output                 pixel_13,
    output                 pixel_14,
    output                 pixel_15,
    output                 pixel_16,
    output                 pixel_17,
    output                 pixel_18,
    output                 pixel_19,
    output                 pixel_20,
    output                 pixel_21,
    output                 pixel_22,
    output                 pixel_23,
    output                 pixel_24,
    output                 pixel_25,
    output                 pixel_26,
    output                 pixel_27,
    output                 pixel_28,
    output                 pixel_29
);

    logic  [29:0] [481:0]  mem;

    always_ff @ ( posedge LCD_DE or posedge rst )
        if ( rst )
            mem <= '0;
        else
            mem <= {mem, pixel};

    assign  pixel_00 = mem [00] [0];
    assign  pixel_01 = mem [01] [0];
    assign  pixel_02 = mem [02] [0];
    assign  pixel_03 = mem [03] [0];
    assign  pixel_04 = mem [04] [0];
    assign  pixel_05 = mem [05] [0];
    assign  pixel_06 = mem [06] [0];
    assign  pixel_07 = mem [07] [0];
    assign  pixel_08 = mem [08] [0];
    assign  pixel_09 = mem [09] [0];
    assign  pixel_10 = mem [10] [0];
    assign  pixel_11 = mem [11] [0];
    assign  pixel_12 = mem [12] [0];
    assign  pixel_13 = mem [13] [0];
    assign  pixel_14 = mem [14] [0];
    assign  pixel_15 = mem [15] [0];
    assign  pixel_16 = mem [16] [0];
    assign  pixel_17 = mem [17] [0];
    assign  pixel_18 = mem [18] [0];
    assign  pixel_19 = mem [19] [0];
    assign  pixel_20 = mem [20] [0];
    assign  pixel_21 = mem [21] [0];
    assign  pixel_22 = mem [22] [0];
    assign  pixel_23 = mem [23] [0];
    assign  pixel_24 = mem [24] [0];
    assign  pixel_25 = mem [25] [0];
    assign  pixel_26 = mem [26] [0];
    assign  pixel_27 = mem [27] [0];
    assign  pixel_28 = mem [28] [0];
    assign  pixel_29 = mem [29] [0];

endmodule
