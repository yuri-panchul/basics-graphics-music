module waveform_gen
# (
    parameter clk_mhz        = 50,
              y_width        = 16,      // sound samples resolution
              waveform_width = 4,
              y_max          = 21844,   // amplitude, to avoid overflow < 30000
              freq           = 440      // frequency
)
(
    input                         clk,
    input                         reset,
    input  [                 2:0] octave,
    input  [waveform_width - 1:0] waveform, // waveform type
    output [y_width        - 1:0] y
);

    // We are grouping together clk_mhz ranges of
    // (12-19), (20-35), (36-67), (68-131).
    // Sampling_rate = clk_mhz / 512  ( < 36 mhz)
    //               = clk_mhz / 1024 (36-67 mhz)
    //               = clk_mhz / 2048 ( > 67 mhz)

    localparam CLK_BIT  =  $clog2 ( clk_mhz - 4 ) + 4;
    localparam CLK_DIV_DATA_OFFSET = { { CLK_BIT - 2 { 1'b0 } }, 1'b1 };

    //  Vertical step of triangle waveform generator

    localparam int step = ((y_max * freq * ((clk_mhz < 36) ? 1 :
                          ((clk_mhz > 67) ? 4 : 2))) / (clk_mhz * 488));

    logic        [CLK_BIT - 1:0] clk_div;
    logic        [          0:0] down = '0;

    logic signed [y_width - 1:0] yt   = '0;
    logic        [y_width - 1:0] ys;
    logic        [y_width - 1:0] yq;
    logic        [y_width - 1:0] yg;

    assign y = yg;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    //------------------------------------------------------------------------
    //
    //  Triangle waveform generator ( signed format )
    //  One sample for L and R audio channels
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if ((clk_div == CLK_DIV_DATA_OFFSET)
              && (((yt < -y_max) &&  down) || ((yt > y_max) && ~down)))
            down <= ~down;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) && !down)
            yt   <= yt + step;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) &&  down)
            yt   <= yt - step;

    //------------------------------------------------------------------------
    //
    //  Wave selector
    //
    //------------------------------------------------------------------------

    always_comb begin
        case (waveform)
           'b0001: yg = ys; // sinus
           'b0010: yg = yt; // triangle
           'b0100: yg = yq; // square
          default: yg = '0;
        endcase
    end

    //------------------------------------------------------------------------

    sinus i_sinus
    (
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
    //
    //  Sinus from triangle waveform generator ( signed format )
    //
    //------------------------------------------------------------------------

module sinus
(
    input      [15:0] y_max,
    input      [15:0] yt,
    output     [15:0] ys
);
    localparam [15:0] MAX = '1;

    logic      [15:0] yt1;
    logic      [15:0] yt2;
    logic      [15:0] yt3;
    logic      [15:0] yt4;
    logic      [15:0] yt5;
    logic      [15:0] yt6;
    logic      [15:0] yt_inv;

    logic      [15:0] y_max1;
    logic      [15:0] y_max2;
    logic      [15:0] y_max3;
    logic      [15:0] y_max4;
    logic      [15:0] y_max5;
    logic      [15:0] y_max6;
    logic      [15:0] y_max7;
    logic      [15:0] y_max8;

    // Shifting to right >> 1 is equivalent to dividing by 2

    assign yt_inv = (MAX - yt);         // inverted
    assign yt1    = (yt  >> 1) - (yt >> 6);
    assign yt2    = (yt  >> 1) + (yt >> 3);
    assign yt3    = (yt2 >> 2);
    assign yt4    = (yt_inv >> 1) - (yt_inv >> 6);
    assign yt5    = (yt_inv >> 1) + (yt_inv >> 3);
    assign yt6    = (yt5 >> 2);

    assign y_max1 = (y_max  >> 1);
    assign y_max2 =  y_max1 + (y_max >> 3);
    assign y_max3 = (y_max  >> 2) - (y_max >> 5) - (y_max >> 6);
    assign y_max4 =  y_max2 + (y_max >> 2);
    assign y_max5 = (y_max4 >> 1);
    assign y_max6 =  y_max1 + (y_max >> 2);
    assign y_max7 = (y_max6 >> 3);
    assign y_max8 =  y_max6 +  y_max7;

    // Made as analog waveform generator ICL8038.
    // The sine wave is created by feeding the triangle wave into a
    // nonlinear sine converter. This converter provides a
    // decreasing transmission ratio as the level of the triangle
    // moves toward the two extremes. Accuracy of the sine is 1%.

    assign ys = (yt > (MAX >> 1)) ?
               ((yt > (MAX - y_max5)) ? // negative half-wave
                      (yt  - yt4) :
               ((yt > (MAX - y_max2)) ?
                      (yt  - y_max3) :
               ((yt > (MAX - y_max4)) ?
                      (MAX - y_max5 - yt5) :
                      (MAX - y_max8 - yt6)))) :
               ((yt < y_max5) ?         // < 0.44 y_max
                     (yt + yt1) :       //              + 1.48 yt
               ((yt < y_max2) ?         // < 0.63 y_max
                     (yt + y_max3) :    //   0.21 y_max + 1.00 yt
               ((yt < y_max4) ?         // < 0.88 y_max
                     (yt2 + y_max5) :   //   0.44 y_max + 0.63 yt
                     (yt3 + y_max8)))); //   0.84 y_max + 0.16 yt

endmodule

    //------------------------------------------------------------------------
    //
    //  Square from triangle waveform generator ( signed format )
    //
    //------------------------------------------------------------------------

module square
(
    input      [15:0] y_max,
    input      [15:0] yt,
    output     [15:0] yq
);
    localparam [15:0] MAX = '1;

    assign yq = (yt > (MAX >> 1)) ?
               ((yt > (MAX - (y_max >> 6))) ? MAX : (MAX - y_max)) :
              (((yt < (y_max >> 6))) ? '0 : y_max);

endmodule
