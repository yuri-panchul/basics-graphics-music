// Asynchronous reset here is needed for the FPGA board we use

`include "config.svh"

module fpga_top
# (
    parameter width = 4, depth = 4
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

    //------------------------------------------------------------------------

    wire rst = ~ reset_n;

    assign led    = '1;
    assign buzzer = 1'b1;
    assign hsync  = 1'b1;
    assign vsync  = 1'b1;
    assign rgb    = 3'b0;

    //------------------------------------------------------------------------

    `ifdef SIMULATION

        wire slow_clk = clk;

    `else

        wire slow_clk_raw, slow_clk;

        slow_clk_gen # (26) i_slow_clk_gen (.slow_clk_raw (slow_clk_raw), .*);

        // "global" is Intel FPGA-specific primitive to route
        // a signal coming from data into clock tree

        global i_global (.in (slow_clk_raw), .out (slow_clk));

    `endif  // `ifdef SIMULATION

    //------------------------------------------------------------------------

    // Upstream

    // Either of two leftmost keys is pressed

    wire               up_valid = key_sw [3:2] != 2'b11;
    wire               up_ready;
    wire [width - 1:0] up_data;

    // Downstream

    // Two rightmost keys are not pressed - ready is ON by default

    wire               down_valid;
    wire               down_ready = key_sw [1:0] == 2'b11;
    wire [width - 1:0] down_data;

    //------------------------------------------------------------------------

    `ifdef __ICARUS__

        logic [width - 1:0] up_data_const_array [0:2 ** width - 1];

        assign up_data_const_array [ 0] = 4'h2;
        assign up_data_const_array [ 1] = 4'h6;
        assign up_data_const_array [ 2] = 4'hd;
        assign up_data_const_array [ 3] = 4'hb;
        assign up_data_const_array [ 4] = 4'h7;
        assign up_data_const_array [ 5] = 4'he;
        assign up_data_const_array [ 6] = 4'hc;
        assign up_data_const_array [ 7] = 4'h4;
        assign up_data_const_array [ 8] = 4'h1;
        assign up_data_const_array [ 9] = 4'h0;
        assign up_data_const_array [10] = 4'h9;
        assign up_data_const_array [11] = 4'ha;
        assign up_data_const_array [12] = 4'hf;
        assign up_data_const_array [13] = 4'h5;
        assign up_data_const_array [14] = 4'h8;
        assign up_data_const_array [15] = 4'h3;

    `else

        // New SystemVerilog syntax for array assignment

        wire [width - 1:0] up_data_const_array [0:2 ** width - 1]
            = '{ 4'h2, 4'h6, 4'hd, 4'hb, 4'h7, 4'he, 4'hc, 4'h4,
                      4'h1, 4'h0, 4'h9, 4'ha, 4'hf, 4'h5, 4'h8, 4'h3 };

    `endif

    //------------------------------------------------------------------------

    wire [width - 1:0] up_data_index;

    counter_with_enable # (width) i_counter
    (
        .clk    (slow_clk),
        .enable (up_valid & up_ready),
        .cnt    (up_data_index),
        .*
    );

    assign up_data = up_data_const_array [up_data_index];

    //------------------------------------------------------------------------

    ff_fifo_wrapped_in_valid_ready
    # (.width (width), .depth (depth))
    wrapped_fifo (.clk (slow_clk), .*);

    //------------------------------------------------------------------------

    wire [7:0] abcdefgh_pre;

    seven_segment_4_digits i_display
    (
        .clk      (clk),
        .number   ({ up_data, 4'd0, 4'd0, down_data }),
        .dots     (4'b0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    //------------------------------------------------------------------------

    localparam sign_valid   = 8'b01111111,
                          sign_ready   = 8'b11111101,
                          sign_nothing = 8'b11111111;

    function [7:0] valid_ready_to_abcdefgh (logic valid, ready);

        case ({ valid, ready })
        2'b00: return sign_nothing;
        2'b10: return sign_valid;
        2'b01: return sign_ready;
        2'b11: return sign_valid & sign_ready;
        endcase

    endfunction

    //------------------------------------------------------------------------

    always_comb
        case (digit)
        4'b1011: abcdefgh = valid_ready_to_abcdefgh ( up_valid   , up_ready   );
        4'b1101: abcdefgh = valid_ready_to_abcdefgh ( down_valid , down_ready );
        4'b1110: abcdefgh = down_valid ? abcdefgh_pre : sign_nothing;
        default: abcdefgh = abcdefgh_pre;
        endcase

endmodule
