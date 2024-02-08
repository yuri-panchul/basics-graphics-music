// Asynchronous reset here is needed for the FPGA board we use

`include "config.vh"

module fpga_top
# (
    parameter width = 12
)
(
    input              clk,
    input              reset_n,

    input        [3:0] key_sw,
    output       [3:0] led,

    output logic [7:0] abcdefgh,
    output       [3:0] digit,

    output             buzzer,

    output             hsync,
    output             vsync,
    output       [2:0] rgb
);

    //--------------------------------------------------------------------------

    wire rst = ~ reset_n;

    assign buzzer = 1'b1;
    assign hsync  = 1'b1;
    assign vsync  = 1'b1;
    assign rgb    = 3'b0;

    //--------------------------------------------------------------------------

    `ifdef SIMULATION

        wire slow_clk = clk;

    `else

        wire slow_clk_raw, slow_clk;

        slow_clk_gen # (26) i_slow_clk_gen (.slow_clk_raw (slow_clk_raw), .*);

        // "global" is Intel FPGA-specific primitive to route
        // a signal coming from data into clock tree

        global i_global (.in (slow_clk_raw), .out (slow_clk));

    `endif  // `ifdef SIMULATION

    //--------------------------------------------------------------------------

    // Upstream

    // Either of two leftmost keys is pressed

    wire               up_vld = key_sw [3:2] != 2'b11;
    wire               up_rdy;
    wire [width - 1:0] up_data;

    // Downstream

    // Two rightmost keys are not pressed - rdy is ON by default

    wire               down_vld;
    wire               down_rdy = key_sw [1:0] == 2'b11;
    wire [width - 1:0] down_data;

    //--------------------------------------------------------------------------

    localparam max_cnt   = 5,
                         cnt_width = $clog2 (max_cnt);

    logic [cnt_width - 1:0] cnt;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (up_vld & up_rdy)
            cnt <= (cnt == max_cnt ? '0 : cnt + 1'd1);

    assign up_data = width' (cnt);

    //--------------------------------------------------------------------------

    pow_5_pipelined
    # (.width (width))
    pow_5 (.clk (slow_clk), .*);

    //--------------------------------------------------------------------------

    wire [7:0] abcdefgh_pre;

    seven_segment_4_digits i_display
    (
        .clk      (clk),
        .number   ({ up_data [3:0], down_data [11:0] }),
        .dots     ('0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    localparam sign_nothing = 8'b11111111;

    assign abcdefgh =
            ( digit [3]   != 1'b1   & ~ up_rdy   )
        | ( digit [2:0] != 3'b111 & ~ down_vld )
                    ? sign_nothing : abcdefgh_pre;

    assign led = ~ { up_vld, up_rdy, down_vld, down_rdy };

endmodule
