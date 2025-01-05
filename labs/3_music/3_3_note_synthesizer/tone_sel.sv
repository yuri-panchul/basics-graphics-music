// pre-generated with gen_tone_table.sh specify sampling_rate hz and volume
`include "tone_table.svh"

module tone_sel
# (
    parameter clk_mhz    = 50,
              y_width    = 16, // sound samples resolution, see tone_table.svh
              note_width = 4
)
(
    input                     clk,
    input                     reset,
    input               [2:0] octave,
    input  [note_width - 1:0] note,
    output [y_width    - 1:0] y
);

    // We are grouping together clk_mhz ranges of
    // (12-19), (20-35), (36-67), (68-131).

    localparam CLK_BIT  =  $clog2 ( clk_mhz - 4 ) + 4;
    localparam CLK_DIV_DATA_OFFSET = { { CLK_BIT - 2 { 1'b0 } }, 1'b1 };
    
    wire   [y_width - 1:0] tone_y [11:0];
    wire             [8:0] tone_x;
    wire             [8:0] tone_x_max [11:0];

    logic  [CLK_BIT - 1:0] clk_div;
    logic  [          1:0] quadrant; // Quadrant (quarter period)

    logic           [ 8:0] x;        // Current sample
    wire            [ 8:0] x_max;    // Last sample in a quadrant (quarter period)
    logic  [y_width - 1:0] y_mod;

    always_ff @ (posedge clk or posedge reset)
        if (reset) 
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            x <= 9'b1;
        else if (clk_div == CLK_DIV_DATA_OFFSET ) // One sample for L and R audio channels
            x <= (quadrant [0] & (x > 1'b0) | (x >= x_max)) ? (x - 1'b1) : (x + 1'b1);

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            quadrant <= 2'b0;
        else if ((clk_div == CLK_DIV_DATA_OFFSET ) & ((x == x_max) | (x == 9'b0)))
            quadrant <= quadrant + 1'b1;

    assign tone_x = x << octave;
    assign x_max = (note < 8'd12) ? (tone_x_max [note] >> octave) : 9'b1;
    assign y_mod = (note < 8'd12) ? (tone_y [note]) : 16'b0;
    assign y     = (quadrant [1]) ? (~y_mod + 1'b1) : y_mod;

generate

//table_sampling_rate_C sampling_rate = clk_mhz / 512  ( < 36 mhz)
//                                    = clk_mhz / 1024 (36-67 mhz)
//                                    = clk_mhz / 2048 ( > 67 mhz)

    if (clk_mhz == 33)
    begin : clk_mhz_33
    table_64453_C  table_64453_C  ( .x(tone_x), .y(tone_y [0] ), .x_max(tone_x_max [0] ));
    table_64453_Cs table_64453_Cs ( .x(tone_x), .y(tone_y [1] ), .x_max(tone_x_max [1] ));
    table_64453_D  table_64453_D  ( .x(tone_x), .y(tone_y [2] ), .x_max(tone_x_max [2] ));
    table_64453_Ds table_64453_Ds ( .x(tone_x), .y(tone_y [3] ), .x_max(tone_x_max [3] ));
    table_64453_E  table_64453_E  ( .x(tone_x), .y(tone_y [4] ), .x_max(tone_x_max [4] ));
    table_64453_F  table_64453_F  ( .x(tone_x), .y(tone_y [5] ), .x_max(tone_x_max [5] ));
    table_64453_Fs table_64453_Fs ( .x(tone_x), .y(tone_y [6] ), .x_max(tone_x_max [6] ));
    table_64453_G  table_64453_G  ( .x(tone_x), .y(tone_y [7] ), .x_max(tone_x_max [7] ));
    table_64453_Gs table_64453_Gs ( .x(tone_x), .y(tone_y [8] ), .x_max(tone_x_max [8] ));
    table_64453_A  table_64453_A  ( .x(tone_x), .y(tone_y [9] ), .x_max(tone_x_max [9] ));
    table_64453_As table_64453_As ( .x(tone_x), .y(tone_y [10]), .x_max(tone_x_max [10]));
    table_64453_B  table_64453_B  ( .x(tone_x), .y(tone_y [11]), .x_max(tone_x_max [11]));
    end
    else if (clk_mhz == 27)
    begin : clk_mhz_27
    table_52734_C  table_52734_C  ( .x(tone_x), .y(tone_y [0] ), .x_max(tone_x_max [0] ));
    table_52734_Cs table_52734_Cs ( .x(tone_x), .y(tone_y [1] ), .x_max(tone_x_max [1] ));
    table_52734_D  table_52734_D  ( .x(tone_x), .y(tone_y [2] ), .x_max(tone_x_max [2] ));
    table_52734_Ds table_52734_Ds ( .x(tone_x), .y(tone_y [3] ), .x_max(tone_x_max [3] ));
    table_52734_E  table_52734_E  ( .x(tone_x), .y(tone_y [4] ), .x_max(tone_x_max [4] ));
    table_52734_F  table_52734_F  ( .x(tone_x), .y(tone_y [5] ), .x_max(tone_x_max [5] ));
    table_52734_Fs table_52734_Fs ( .x(tone_x), .y(tone_y [6] ), .x_max(tone_x_max [6] ));
    table_52734_G  table_52734_G  ( .x(tone_x), .y(tone_y [7] ), .x_max(tone_x_max [7] ));
    table_52734_Gs table_52734_Gs ( .x(tone_x), .y(tone_y [8] ), .x_max(tone_x_max [8] ));
    table_52734_A  table_52734_A  ( .x(tone_x), .y(tone_y [9] ), .x_max(tone_x_max [9] ));
    table_52734_As table_52734_As ( .x(tone_x), .y(tone_y [10]), .x_max(tone_x_max [10]));
    table_52734_B  table_52734_B  ( .x(tone_x), .y(tone_y [11]), .x_max(tone_x_max [11]));
    end
    else
    begin : clk_mhz_50    
    table_48828_C  table_48828_C  ( .x(tone_x), .y(tone_y [0] ), .x_max(tone_x_max [0] ));
    table_48828_Cs table_48828_Cs ( .x(tone_x), .y(tone_y [1] ), .x_max(tone_x_max [1] ));
    table_48828_D  table_48828_D  ( .x(tone_x), .y(tone_y [2] ), .x_max(tone_x_max [2] ));
    table_48828_Ds table_48828_Ds ( .x(tone_x), .y(tone_y [3] ), .x_max(tone_x_max [3] ));
    table_48828_E  table_48828_E  ( .x(tone_x), .y(tone_y [4] ), .x_max(tone_x_max [4] ));
    table_48828_F  table_48828_F  ( .x(tone_x), .y(tone_y [5] ), .x_max(tone_x_max [5] ));
    table_48828_Fs table_48828_Fs ( .x(tone_x), .y(tone_y [6] ), .x_max(tone_x_max [6] ));
    table_48828_G  table_48828_G  ( .x(tone_x), .y(tone_y [7] ), .x_max(tone_x_max [7] ));
    table_48828_Gs table_48828_Gs ( .x(tone_x), .y(tone_y [8] ), .x_max(tone_x_max [8] ));
    table_48828_A  table_48828_A  ( .x(tone_x), .y(tone_y [9] ), .x_max(tone_x_max [9] ));
    table_48828_As table_48828_As ( .x(tone_x), .y(tone_y [10]), .x_max(tone_x_max [10]));
    table_48828_B  table_48828_B  ( .x(tone_x), .y(tone_y [11]), .x_max(tone_x_max [11]));
    end
    
endgenerate

endmodule
