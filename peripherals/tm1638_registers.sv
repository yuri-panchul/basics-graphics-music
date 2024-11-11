/*============================================================================
SPDX-License-Identifier: Apache-2.0

Copyright 2023 Alexander Kirichenko
Copyright 2023 Ruslan Zalata (HCW-132 variation support)

Based on https://github.com/alangarf/tm1638-verilog
Copyright 2017 Alan Garfield
Copyright Contributors to the basics-graphics-music project.
==============================================================================*/

`include "config.svh"
`include "lab_specific_board_config.svh"

module tm1638_registers
# (
    parameter                     w_digit = 8,
                                  w_seg   = 8,
                                  r_init  = 0
)
(
    input                         clk,
    input                         rst,
    input        [ w_seg   - 1:0] hgfedcba,
    input        [ w_digit - 1:0] digit,
    output       [ w_seg   - 1:0] hex[w_digit]
);

`ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS
    localparam static_hex = 1'b0;
`else
    localparam static_hex = 1'b1;
`endif

    wire [w_digit-1:0][w_seg - 1:0] init76543210 =
                      //hgfedcba             --a--
                    '{'b00111111, // 0      |     |
                      'b00000110, // 1      f     b
                      'b01011011, // 2      |     |
                      'b01001111, // 3       --g--
                      'b01100110, // 4      |     |
                      'b01101101, // 5      e     c
                      'b01111101, // 6      |     |
                      'b00000111};// 7       --d--

    ////////////// TM1563 data /////////////////

    // HEX registered
    logic [w_seg - 1:0] r_hex[w_digit];

    always @( posedge clk or posedge rst)
    begin
        for (int i = 0; i < $bits (digit); i++)
            if (rst)
                if (r_init)
                    r_hex[i] <= init76543210[i];
                else
                    r_hex[i] <= 'b0;
            else if (digit == 'b1<<i)
                    r_hex[i] <= hgfedcba;
    end

    // HEX combinational
    wire [w_seg - 1:0] c_hex[w_digit];

    genvar i;

    generate
        for (i = 0; i < w_digit; i++) begin : assign_registers
            assign c_hex[i] = digit [i] ? hgfedcba : '0;
            // Select combinational or registered HEX (blink or not)
            assign hex[i] = static_hex ? r_hex[i] : c_hex[i];
        end
    endgenerate

endmodule
