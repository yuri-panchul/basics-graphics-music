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

    localparam clk_period    = 37ns;

    //------------------------------------------------------------------------

    logic                      clk;
    logic                      pixel_clk;
    logic                      rst;
    logic                      rst_2;
    logic  [w_sw        - 1:0] sw;
    logic  [w_key       - 1:0] key;
    logic  [w_x         - 1:0] x;
    logic  [w_y         - 1:0] y;
    logic  [              0:0] pixel;
    logic                      LCD_DE;
    logic                      LCD_VS;
    logic                      LCD_HS;
    logic                      LCD_CLK;
    logic                      LCD_BL;
    logic               [ 4:0] LCD_R;
    logic               [ 5:0] LCD_G;
    logic               [ 4:0] LCD_B;
    logic               [23:0] sound_1, sound_2;

    assign  pixel = |LCD_R || |LCD_G || |LCD_B;

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),
        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),
        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        ),
        .w_x           ( w_x           ),
        .w_y           ( w_y           )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .x             ( x             ),
        .y             ( y             ),
        .red           ( LCD_R         ),
        .green         ( LCD_G         ),
        .blue          ( LCD_B         ),
        .mic           ( {24'd0, sound_2, sound_2, sound_1,
                                 sound_1, sound_1, sound_2} )
    );

    // Test (input waveforms)
    waveform_gen
    # (
        .clk_mhz    ( clk_mhz     )
    )
    i_waveform_gen_1
    (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .octave     ( 3'd0        ),
        .waveform   ( 4'd1        ), // waveform 1-Sine 2-Triangle 4-Square
        .y          ( sound_1     )
    );

    waveform_gen
    # (
        .clk_mhz    ( clk_mhz     )
    )
    i_waveform_gen_2
    (
        .clk        ( clk         ),
        .rst        ( rst_2       ),
        .octave     ( 3'd0        ),
        .waveform   ( 4'd1        ), // waveform 1-Sine 2-Triangle 4-Square
        .y          ( sound_2     )
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
        rst   <= 'bx;
        rst_2 <= 'bx;
        repeat (2) @(posedge clk);
        rst   <= 1;
        rst_2 <= 1;
        repeat (2) @(posedge clk);
        rst   <= 0;
        repeat (3000) @(posedge clk);
        rst_2 <= 0;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        // Based on timescale is 1 ns / 1 ps simulation time

        # 0.002s

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

    //------------------------------------------------------------------------

    initial
    begin
        pixel_clk = 1'b0;

        forever
            # (clk_period / 6) pixel_clk = ~ pixel_clk;
    end

    tb_lcd_480_272         i_lcd
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
    //  Virtual display
    //------------------------------------------------------------------------

    // Display variables pixel_29 to pixel_00 tb_lcd_display
    // from top to bottom and zoom the left and right screen borders to
    // adjacent frame syncs LCD_VSYNC or high level LCD_DE
    // see \labs\2_graphics\2_10_color_shapes_and_functions\
    // The module tb_lcd_display is located in the common folder

    /* tb_lcd_display         i_display
    (
        .PixelClk      (   pixel_clk   ),
        .rst           (   rst         ),
        .LCD_DE        (   LCD_DE      ),
        .LCD_HSYNC     (   LCD_HS      ),
        .LCD_VSYNC     (   LCD_VS      ),
        .pixel         (   pixel       )
    ); */

    //------------------------------------------------------------------------

endmodule

    // Test (input waveform)
module waveform_gen
# (
    parameter clk_mhz        = 50,
              y_width        = 24,                 // sound samples resolution
              waveform_width = 4,
              y_max          = $signed (24'd127000), // amplitude
              freq           = 1000                // frequency
)
(
    input                         clk,
    input                         rst,
    input        [           2:0] octave,
    input        [           3:0] waveform,       // waveform type
    output logic [y_width  - 1:0] y
);

    localparam CLK_BIT  =  $clog2 ( clk_mhz - 4 ) + 4;
    localparam CLK_DIV_DATA_OFFSET = { { CLK_BIT - 2 { 1'b0 } }, 1'b1 };

    //  Vertical step of triangle waveform generator
    localparam   [         15:0] step = ((y_max * freq *
        ((clk_mhz < 36) ? 1 : ((clk_mhz > 67) ? 4 : 2)))
                                     / (clk_mhz * 488));

    logic        [CLK_BIT - 1:0] clk_div;
    logic        [          0:0] down;

    logic signed [y_width - 1:0] yt;
    logic        [y_width - 1:0] ys;
    logic        [y_width - 1:0] yq;

    always_ff @(posedge clk or posedge rst)
        if (rst)
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    //------------------------------------------------------------------------
    //  Triangle waveform generator ( signed format )
    //------------------------------------------------------------------------

    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            down <= '0;
            yt   <= '0;
        end
        else if ((clk_div == CLK_DIV_DATA_OFFSET)
              && (((yt < -y_max) &&  down) || ((yt > y_max) && ~down)))
            down <= ~down;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) && !down)
            yt   <= yt + step;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) &&  down)
            yt   <= yt - step;

    //------------------------------------------------------------------------
    //  Wave selector
    //------------------------------------------------------------------------

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
            y <= '0;
        else
        case (waveform)
            'b0001: y <= ys; // sinus
            'b0010: y <= yt; // triangle
            'b0100: y <= yq; // square
           default: y <= '0;
        endcase
    end

    //------------------------------------------------------------------------

    sinus i_sinus
    (
        .clk      ( clk   ),
        .rst      ( rst   ),
        .y_max    ( y_max ),
        .yt       ( yt    ),
        .ys       ( ys    )
    );

    //------------------------------------------------------------------------

    square i_square
    (
        .y_max    ( y_max ),
        .yt       ( yt    ),
        .yq       ( yq    )
    );

endmodule

    //------------------------------------------------------------------------
    //  Sinus from triangle waveform generator ( signed format )
    //------------------------------------------------------------------------

module sinus
(
    input                  clk,
    input                  rst,
    input  logic    [23:0] y_max,
    input  logic    [23:0] yt,
    output logic    [23:0] ys
);
    localparam [23:0] MAX = '1;

    always_ff @(posedge clk)
    begin
    if     (yt > (MAX >> 1))
    begin
        if       (yt >   MAX - (y_max >> 1) + (y_max >> 4))         // negative half-wave
            ys <= yt - ((MAX - yt) >> 1) + ((MAX - yt) >> 5);
        else if  (yt >  (MAX - (y_max >> 1) - (y_max >> 3)))
            ys <= yt + ((MAX - yt) >> 4) - (y_max >> 2);
        else if  (yt >   MAX - (y_max >> 1) - (y_max >> 2) - (y_max >> 4))
            ys <= MAX - ((MAX - yt) >> 1) - ((MAX - yt) >> 4) - (y_max >> 1);
        else
            ys <= MAX - ((MAX - yt) >> 3) - ((MAX - yt) >> 5) - y_max + (y_max >> 3) + (y_max >> 5);
    end
    else
    begin
        if        (yt < (y_max >> 1) - (y_max >> 4))                // < 0.4375  y_max
            ys <=  yt + (yt >> 1) - (yt >> 5);                      //                 + 1.46875 yt
        else if   (yt < (y_max >> 1) + (y_max >> 3))                // < 0.625   y_max
            ys <=  yt - (yt >> 4) + (y_max >> 2);                   //   0.25    y_max + 0.9375  yt
        else if   (yt < (y_max >> 1) + (y_max >> 2) + (y_max >> 4)) // < 0.8125  y_max
            ys <= (yt >> 1) + (yt >> 4) + (y_max >> 1);             //   0.5     y_max + 0.5625  yt
        else                                                        //   0.84375 y_max + 0.15625 yt
            ys <= (yt >> 3) + (yt >> 5) + y_max - (y_max >> 3) - (y_max >> 5);
    end
    end

endmodule

    //------------------------------------------------------------------------
    //  Square from triangle waveform generator ( signed format )
    //------------------------------------------------------------------------

module square
(
    input      [23:0] y_max,
    input      [23:0] yt,
    output     [23:0] yq
);
    localparam [23:0] MAX = '1;

    assign yq = (yt > (MAX >> 1)) ?
               ((yt > (MAX - (y_max >> 6))) ? MAX : (MAX - y_max)) :
              (((yt < (y_max >> 6))) ? '0 : y_max);

endmodule
