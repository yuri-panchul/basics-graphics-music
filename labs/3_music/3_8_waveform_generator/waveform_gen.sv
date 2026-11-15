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

    // We are grouping together clk_mhz ranges of
    // (12-19), (20-35), (36-67), (68-131).
    // Sampling_rate = clk (mhz) / 32  ( < 36 mhz)
    //               = clk (mhz) / 64  (36-67 mhz)
    //               = clk (mhz) / 128 ( > 67 mhz)

    localparam CLK_BIT  =  $clog2 (clk_mhz - 4);
    localparam CLK_DIV_DATA_OFFSET = {{CLK_BIT - 1 {1'b0}}, 1'b1};

    //  Vertical step of triangle waveform generator

    localparam   [y_width - 1:0] step = ((y_max / clk_mhz) * freq *
                 (clk_mhz < 36 ? 1 : (clk_mhz > 67 ? 4 : 2))) / 7808;

    logic        [CLK_BIT - 1:0] clk_div;
    logic        [          0:0] down = '0;

    logic signed [y_width - 1:0] yt   = '0;
    logic        [y_width - 1:0] ys;
    logic        [y_width - 1:0] yq;

    always_ff @(posedge clk or posedge rst)
        if (rst)
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    //  Triangle waveform generator ( signed format )
    //  One sample for L and R audio channels

    always_ff @(posedge clk)
        if ((clk_div == CLK_DIV_DATA_OFFSET)
              && (((yt < - $signed (y_max)) &&   down) ||
                  ((yt >   $signed (y_max)) && ~ down)))
            down <= ~ down;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) && ! down)
            yt   <= yt +   $signed (step);
        else if ((clk_div == CLK_DIV_DATA_OFFSET) &&   down)
            yt   <= yt -   $signed (step);

    //  Wave selector

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

    sinus
    # (
        .y_width  ( y_width )
    )
    i_sinus
    (
        .clk      ( clk     ),
        .rst      ( rst     ),
        .y_max    ( y_max   ),
        .yt       ( yt      ),
        .ys       ( ys      )
    );

    square
    # (
        .y_width  ( y_width )
    )
    i_square
    (
        .y_max    ( y_max   ),
        .yt       ( yt      ),
        .yq       ( yq      )
    );

endmodule

    //  Sinus from triangle waveform generator ( signed format )

module sinus
# (
    parameter y_width = 24  // sound samples resolution
)
(
    input                        clk,
    input                        rst,
    input  logic [y_width - 1:0] y_max,
    input  logic [y_width - 1:0] yt,
    output logic [y_width - 1:0] ys
);
    localparam   [y_width - 1:0] MAX = '1;

    // Works as analog waveform generator ICL8038.
    // The sine wave is created by feeding the triangle wave into a
    // nonlinear sine converter. This converter provides a
    // decreasing transmission ratio as the level of the triangle
    // moves toward the two extremes. Accuracy of the sine is 1%.

    always_ff @(posedge clk) begin
    if     (yt > (MAX >> 1)) begin
        if       (yt >    MAX - (y_max >> 1) + (y_max >> 4)) // negative half-wave
            ys <= yt -  ((MAX - yt) >> 1) + ((MAX - yt) >> 5);
        else if  (yt >   (MAX - (y_max >> 1) - (y_max >> 3)))
            ys <= yt +  ((MAX - yt) >> 4) - (y_max >> 2);
        else if  (yt >    MAX - (y_max >> 1) - (y_max >> 2) - (y_max >> 4))
            ys <= MAX - ((MAX - yt) >> 1) - ((MAX - yt) >> 4) - (y_max >> 1);
        else
            ys <= MAX - ((MAX - yt) >> 3) - ((MAX - yt) >> 5) - y_max +
                                                (y_max >> 3) + (y_max >> 5);
    end
    else begin
        if        (yt < (y_max >> 1) - (y_max >> 4)) // < 0.4375  y_max
            ys <=  yt + (yt >> 1) - (yt >> 5);       //                 + 1.46875 yt
        else if   (yt < (y_max >> 1) + (y_max >> 3)) // < 0.625   y_max
            ys <=  yt - (yt >> 4) + (y_max >> 2);    //   0.25    y_max + 0.9375  yt
        else if   (yt < (y_max >> 1) +
                        (y_max >> 2) + (y_max >> 4)) // < 0.8125  y_max
         ys <= (yt >> 1) + (yt >> 4) + (y_max >> 1); //   0.5     y_max + 0.5625  yt
        else                                         //   0.84375 y_max + 0.15625 yt
            ys <= (yt >> 3) + (yt >> 5) +
                y_max - (y_max >> 3) - (y_max >> 5);
    end
    end

endmodule

    //  Square from triangle waveform generator ( signed format )

module square
# (
    parameter y_width = 24  // sound samples resolution
)
(
    input      [y_width - 1:0] y_max,
    input      [y_width - 1:0] yt,
    output     [y_width - 1:0] yq
);
    localparam [y_width - 1:0] MAX = '1;

    assign yq = (yt > (MAX >> 1)) ?
               ((yt > (MAX - (y_max >> 6))) ? MAX : (MAX - y_max)) :
              (((yt < (y_max >> 6))) ? '0 : y_max);

endmodule

    // ---------------------------------------------------------------------------
    //
    // The waveforms are "drawn" like vector graphics: there is no lookup table
    // with precomputed samples, the value of the signal is computed on the fly.
    // The "waveform" input selects what is drawn:
    // 'b0001 - sine, 'b0010 - triangle, 'b0100 - square.
    //
    // 1. Triangle. The easy part: a signed accumulator yt is incremented and
    //    decremented by a fixed step at the sample rate, bouncing between
    //    -y_max and +y_max. The step sets the frequency, y_max sets the
    //    amplitude. The amplitude is an arbitrary parameter: any value that
    //    does not overflow the intermediate computations.
    //
    // 2. Sine. The triangle is fed to the "sinus" module together with y_max,
    //    so the sine follows whatever amplitude is chosen. The converter
    //    mimics the analog function generator chip ICL8038: the corners of
    //    the triangle are smoothed by a nonlinear converter whose gain
    //    decreases as the level approaches the peak (in the original chip
    //    this is done by analog means, see the figure in the ICL8038
    //    datasheet; ICL8038.jpg and Waves.jpg in this directory illustrate
    //    the idea).
    //
    //    Digitally, the converter is a piecewise-linear approximation.
    //    Both polarities are processed separately, by symmetric branches of
    //    the if statement. Each half-wave is split at 3 points - where the
    //    triangle reaches 43.75%, 62.5% and 81.25% of y_max - into 4 segments.
    //    Within a segment the output is computed by shifts and additions
    //    only: every coefficient is a combination of powers of two, so no
    //    hardware multiplier is needed. A fixed fraction of y_max (the input
    //    amplitude) is added at the same time to restore the level at the
    //    segment transitions. The segment gains are 1.46875, 0.9375, 0.5625
    //    and 0.15625 of the input - see the comments with the coefficients
    //    at the end of the sinus module. The accuracy of the resulting sine
    //    is about 1% for any chosen amplitude.
    //
    // 3. Square. Derived from the triangle by threshold comparison in the
    //    "square" module.
    //
    // The module is also handy as a test signal generator in testbenches:
    // instantiate (or copy) it in tb.sv and drive the DUT with it instead
    // of, for example, a microphone - see labs/3_music/3_11_microphone_monitor.
    //
    // ---------------------------------------------------------------------------
