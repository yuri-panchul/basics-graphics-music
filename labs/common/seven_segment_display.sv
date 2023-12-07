// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module seven_segment_display
# (
    parameter w_digit = 2,
    parameter clk_mhz = 50,
    parameter digit_update_hz = 128, // How often to updat ea single digit, should be quite high to avoid flicker
    parameter data_update_hz = 4 // How often to update data register, should not be too high
)
(
    input  clk,
    input  rst,

    input  [w_digit * 4 - 1:0] number,
    input  [w_digit     - 1:0] dots,

    output logic [              7:0] abcdefgh,
    output logic [w_digit     - 1:0] digit
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

    localparam display_update_cnt_top = clk_mhz * 1000000 / w_digit / digit_update_hz,
               w_display_update_cnt   = $clog2 (display_update_cnt_top + 1);

    logic [w_display_update_cnt - 1:0] display_update_cnt;

    // Calculate data update freq divider
    
    localparam data_update_cnt_top = digit_update_hz / data_update_hz,
               w_data_update_cnt   = $clog2 (data_update_cnt_top + 1);

    logic [w_data_update_cnt - 1:0] data_update_cnt;

    localparam w_index = $clog2 (w_digit);
    logic [w_index - 1:0] index;

    logic [w_digit * 4 - 1:0] number_r;

    // Update one digit only when necessary

    always_ff @ (posedge clk or posedge rst)
        if (rst) begin
            index              <= '0;
            display_update_cnt <= '0;
            data_update_cnt    <= '0;
        end else begin
            display_update_cnt <= display_update_cnt + 1'd1;

            if (display_update_cnt == w_display_update_cnt'(display_update_cnt_top))
            begin
                display_update_cnt <= '0;

                index <= (index == w_index' (w_digit - 1) ?
                        '0 : index + 1'd1);

                if (index == w_digit - 1)
                begin
                    index <= '0;
                    data_update_cnt <= data_update_cnt + 1'd1;

		    if (data_update_cnt == w_data_update_cnt'(data_update_cnt_top))
                    begin
                        number_r        <= number;
                        data_update_cnt <= '0;
                    end

                end

                abcdefgh <= dig_to_seg (number_r [index * 4 +: 4]) ^ dots [index];
                digit    <= w_digit' (1'b1) << index;
            end
        end

endmodule
