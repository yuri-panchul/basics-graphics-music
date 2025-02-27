`include "config.svh"

module tb;

    timeunit      1ns;
    timeprecision 1ps;

    //------------------------------------------------------------------------

    localparam clk_mhz = 50,
               w_key   = 4,
               w_sw    = 4,
               w_led   = 8,
               w_digit = 8,
               w_sound = 16,
               w_gpio  = 100;

    localparam clk_period = 20ns;

    //------------------------------------------------------------------------

    logic                 clk;
    logic                 rst;
    logic [w_key   - 1:0] key;
    logic [w_sw    - 1:0] sw;

    // Graphics
    logic [          9:0] x;
    logic [          8:0] y;

    logic [          3:0] red;
    logic [          3:0] green;
    logic [          3:0] blue;

    //------------------------------------------------------------------------

    logic [         10:0] rms_out;
    logic [         15:0] sound;

    //------------------------------------------------------------------------

    converter i_converter
    (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .mic        ( sound[15:8] ), // waveform generator
        .band_count ( 17'd2410    ), // f=440 Hz band_count=(clk_mhz*31250)/f
        .rms_out    ( rms_out     )
    );

    waveform_gen
    # (
        .clk_mhz    (clk_mhz      )
    )
    i_waveform_gen
    (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .octave     ( 3'd0        ),
        .waveform   ( 4'd1        ), // waveform 1-Sine 2-Triangle 4-Square
        .y          ( sound       )
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

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        // Based on timescale is 1 ns / 1 ps

        # 0.005s

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule

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
    input                         rst,
    input        [           2:0] octave,
    input        [           3:0] waveform, // waveform type
    output logic [y_width  - 1:0] y
);

    localparam CLK_BIT  =  $clog2 ( clk_mhz - 4 ) + 4;
    localparam CLK_DIV_DATA_OFFSET = { { CLK_BIT - 2 { 1'b0 } }, 1'b1 };

    //  Vertical step of triangle waveform generator

    localparam   [         15:0] step = ((y_max * freq *
        ((clk_mhz < 36) ? 1 : ((clk_mhz > 67) ? 4 : 2)))
                                     / (clk_mhz * 488));

    logic        [CLK_BIT - 1:0] clk_div;
    logic        [          0:0] down = '0;

    logic signed [y_width - 1:0] yt   = '0;
    logic        [y_width - 1:0] ys;
    logic        [y_width - 1:0] yq;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    //------------------------------------------------------------------------
    //  Triangle waveform generator ( signed format )
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
    //  Wave selector
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
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
    input  logic    [15:0] y_max,
    input  logic    [15:0] yt,
    output logic    [15:0] ys
);
    localparam [15:0] MAX = '1;

    always_ff @ (posedge clk)
    begin
    if     (yt > (MAX >> 1)) // Shifting to right >> 1 for positive numbers is equivalent to dividing by 2
    begin
        if       (yt >   MAX - (y_max >> 1) + (y_max >> 4))                   // negative half-wave
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
        if        (yt < (y_max >> 1) - (y_max >> 4))                           // < 0.4375  y_max
            ys <=  yt + (yt >> 1) - (yt >> 5);                                 //                 + 1.46875 yt
        else if   (yt < (y_max >> 1) + (y_max >> 3))                           // < 0.625   y_max
            ys <=  yt - (yt >> 4) + (y_max >> 2);                              //   0.25    y_max + 0.9375  yt
        else if   (yt < (y_max >> 1) + (y_max >> 2) + (y_max >> 4))            // < 0.8125  y_max
            ys <= (yt >> 1) + (yt >> 4) + (y_max >> 1);                        //   0.5     y_max + 0.5625  yt
        else
            ys <= (yt >> 3) + (yt >> 5) + y_max - (y_max >> 3) - (y_max >> 5); //   0.84375 y_max + 0.15625 yt
    end
    end

endmodule

    //------------------------------------------------------------------------
    //  Square from triangle waveform generator ( signed format )
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
