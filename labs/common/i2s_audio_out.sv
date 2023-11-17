module i2s_audio_out
# (
    parameter clk_mhz = 50,
              in_res  = 16        // sound samples resolution, see tone_table.svh
)
(
    input                 clk,
    input                 reset,
    input  [in_res - 1:0] data_in,
    output                mclk,
    output                bclk,
    output                lrclk,  // LRCLK - 32-bit L, 32-bit R
    output                sdata
);

    localparam MCLK_DIV = $clog2 (clk_mhz * 1000 / 12500);  // MCLK  - 12.5 MHz
    localparam BCLK_DIV = $clog2 (clk_mhz * 1000 / 3125 );  // BCLK  - 3.125 MHz serial clock - for a 48 KHz Sample Rate
    localparam CLK_DIV  = $clog2 (clk_mhz * 1000 / 50   );  // LRCLK - 50 KHz, the slowest clock

    logic  [CLK_DIV - 1:0] clk_div;
    logic  [         31:0] shift;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1'b1;

    assign mclk  = clk_div [ MCLK_DIV - 1];
    assign bclk  = clk_div [ BCLK_DIV - 1];
    assign lrclk = clk_div [ CLK_DIV  - 1];

    assign sdata = shift   [           31];

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            shift <= 0;
        else
        begin
            if (clk_div [CLK_DIV - 2:0] == 'b1)
                shift <= data_in << in_res;
            else if (clk_div [BCLK_DIV - 1:0] == 'b1)
                shift <= shift << 1;
        end

endmodule
