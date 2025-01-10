// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module seven_segment_display
# (
    parameter w_digit   = 2,
    parameter clk_mhz   = 50,
    parameter update_hz = 120  // The default of 4 is too low for FIFO lab // Looks like a sane default
)
(
    input  clk,
    input  rst,

    input  [w_digit * 4 - 1:0] number,
    input  [w_digit     - 1:0] dots,

    output [              7:0] abcdefgh,
    output [w_digit     - 1:0] digit
);

    function [7:0] dig_to_seg (input [3:0] dig);

        case (dig)

        'h0: dig_to_seg = 'b11111100;  // a b c d e f g h
        'h1: dig_to_seg = 'b01100000;
        'h2: dig_to_seg = 'b11011010;  //   --a--
        'h3: dig_to_seg = 'b11110010;  //  |   |
        'h4: dig_to_seg = 'b01100110;  //  f   b
        'h5: dig_to_seg = 'b10110110;  //  |   |
        'h6: dig_to_seg = 'b10111110;  //   --g--
        'h7: dig_to_seg = 'b11100000;  //  |   |
        'h8: dig_to_seg = 'b11111110;  //  e   c
        'h9: dig_to_seg = 'b11100110;  //  |   |
        'ha: dig_to_seg = 'b11101110;  //   --d--  h
        'hb: dig_to_seg = 'b00111110;
        'hc: dig_to_seg = 'b10011100;
        'hd: dig_to_seg = 'b01111010;
        'he: dig_to_seg = 'b10011110;
        'hf: dig_to_seg = 'b10001110;

        endcase

    endfunction

    // Calculate display update freq divider

    localparam cnt_max = clk_mhz * 1_000_000 / update_hz,
               w_cnt   = $clog2 (cnt_max + 1);

    logic [w_cnt - 1:0] cnt;


    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (cnt == cnt_max)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;


    // Update display output register with specified frequency

    logic  [w_digit * 4 - 1:0] r_number;
    wire enable = cnt == cnt_max;


    always_ff @ (posedge clk or posedge rst)
        if (rst)
            r_number <= '0;
        else if (enable)
            r_number <= number;


    localparam w_index = $clog2 (w_digit);
    logic [w_index - 1:0] index;


    always_ff @ (posedge clk or posedge rst)
        if (rst)
            index <= '0;
        else if (cnt[15:0] == 16'b0) // Perhaps a check is needed that w_cnt >= 16
            index <= (index == w_index' (w_digit - 1) ?
                w_index' (0) : index + 1'd1);

    // Outputs are combinational like before
    assign abcdefgh = dig_to_seg (r_number [index * 4 +: 4]) ^ dots [index];
    assign digit    = w_digit' (1'b1) << index;

endmodule
