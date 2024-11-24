// pre-generated with gen_tone_table.sh
`include "tone_table.svh"

module tone_sel
# (
    parameter clk_mhz    = 50,
              y_width    = 16,         // sound samples resolution, see tone_table.svh
              note_width = 4
)
(
    input                     clk,
    input                     reset,
    input               [2:0] octave,
    input  [note_width - 1:0] note,
    output    [y_width - 1:0] y
);
    localparam CLK_DIV  =  4'd10;
    localparam CLK_STEP = int' (7'd100 / clk_mhz); // Tuning tone_table.svh to the frequency of the board

    wire   [y_width - 1:0] tone_y [11:0];
    wire             [8:0] tone_x;
    wire             [8:0] tone_x_max [11:0];

    logic  [CLK_DIV - 1:0] clk_div;

    logic           [ 8:0] x;      // Current sample
    wire            [ 8:0] x_max;  // Last sample in a period

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            clk_div <= 1'b0;
        else
            clk_div <= clk_div + 1'b1;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            x <= 0;
        else if (clk_div == 'b1)        // i2s_audio_out.lrclk up and down - send one sample for L and R audio channels
            x <= (x >= x_max) ? 9'b0 : (x + CLK_STEP);

    assign tone_x = x << octave;
    assign x_max = (note < 8'd12) ? (tone_x_max [note] >> octave) : 9'b0;
    assign y = (note < 8'd12) ? (tone_y [note]) : 16'b0;

    lut_C  lut_C  ( .x(tone_x), .y(tone_y [0] ), .x_max(tone_x_max [0] ));
    lut_Cs lut_Cs ( .x(tone_x), .y(tone_y [1] ), .x_max(tone_x_max [1] ));
    lut_D  lut_D  ( .x(tone_x), .y(tone_y [2] ), .x_max(tone_x_max [2] ));
    lut_Ds lut_Ds ( .x(tone_x), .y(tone_y [3] ), .x_max(tone_x_max [3] ));
    lut_E  lut_E  ( .x(tone_x), .y(tone_y [4] ), .x_max(tone_x_max [4] ));
    lut_F  lut_F  ( .x(tone_x), .y(tone_y [5] ), .x_max(tone_x_max [5] ));
    lut_Fs lut_Fs ( .x(tone_x), .y(tone_y [6] ), .x_max(tone_x_max [6] ));
    lut_G  lut_G  ( .x(tone_x), .y(tone_y [7] ), .x_max(tone_x_max [7] ));
    lut_Gs lut_Gs ( .x(tone_x), .y(tone_y [8] ), .x_max(tone_x_max [8] ));
    lut_A  lut_A  ( .x(tone_x), .y(tone_y [9] ), .x_max(tone_x_max [9] ));
    lut_As lut_As ( .x(tone_x), .y(tone_y [10]), .x_max(tone_x_max [10]));
    lut_B  lut_B  ( .x(tone_x), .y(tone_y [11]), .x_max(tone_x_max [11]));

endmodule
