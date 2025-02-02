`include "config.svh"

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
