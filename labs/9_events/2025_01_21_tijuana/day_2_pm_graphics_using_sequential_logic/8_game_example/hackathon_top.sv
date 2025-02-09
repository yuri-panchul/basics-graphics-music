// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue
);

    //------------------------------------------------------------------------
    //
    //  Screen, object and color constants

    localparam screen_width  = 480,
               screen_height = 272,

               wx            = 30,
               wy            = 30,

               max_red       = 31,
               max_green     = 63,
               max_blue      = 31;

    //------------------------------------------------------------------------
    //
    //  Pulse generator, 50 times a second

    logic pulse;

    strobe_gen # (.clk_mhz (27), .strobe_hz (50))
    i_strobe_gen (clock, reset, pulse);

    //------------------------------------------------------------------------
    //
    //  Updating object coordinates

    //------------------------------------------------------------------------

    logic [8:0] x0, y0, x1, y1;
   
    always_ff @ (posedge clock)
        if (reset)
        begin
            x0 <= 0;
            y0 <= screen_height / 5;

            x1 <= screen_width  / 2;
            y1 <= screen_height * 4 / 5;
        end
        else if (pulse)
        begin
            if (x0 == screen_width)
                x0 <= 0;
            else
                x0 <= x0 + 1;

            x1 <= x1 + key [3:0] - key [6:4];
            
            if (y1 == 0)
               y1 <= screen_height * 4 / 5;
            else
               y1 <= y1 - 1;
        end

    //------------------------------------------------------------------------
    //
    //  Determine pixel color

    //------------------------------------------------------------------------

    always_comb
    begin
        red = 0; green = 0; blue = 0;

        if (  x >= x0 & x < x0 + wx
            & y >= y0 & y < y0 + wy)
        begin
            blue = max_blue;
        end

        if (  x >= x1 & x < x1 + wx
            & y >= y1 & y < y1 + wy)
        begin
            red = max_red;
        end
    end

    //------------------------------------------------------------------------
    //
    //  Output to LED and 7-segment display

    assign led = x1;

    wire [31:0] number
        = key [7] ? { 7'b0, x0, 7'b0, y0 }
                  : { 7'b0, x1, 7'b0, y1 };
    
    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock    ),
        .rst      ( reset    ),
        .number   ( number   ),
        .dots     ( 0        ),
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
