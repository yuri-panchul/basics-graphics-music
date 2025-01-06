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
    output [w_digit - 1:0][ w_seg   - 1:0] hex
);

`ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS
    localparam static_hex = 0;
`else
    localparam static_hex = 1;
`endif

    wire [0:w_digit-1][w_seg - 1:0] init76543210 =

                      //hgfedcba             --a--
                     {8'b00111111, // 0      |     |
                      8'b00000110, // 1      f     b
                      8'b01011011, // 2      |     |
                      8'b01001111, // 3       --g--
                      8'b01100110, // 4      |     |
                      8'b01101101, // 5      e     c
                      8'b01111101, // 6      |     |
                      8'b00000111};// 7       --d--

    ////////////// TM1563 data /////////////////

    // HEX registered
    logic [w_seg - 1:0] r_hex[w_digit];

    genvar i;

    generate

        for (i = 0; i < w_digit; i++)
        begin : gen_r_hex

            always @( posedge clk or posedge rst)
                if (rst)
                    r_hex[i] <= r_init ? init76543210[i] : '0;
                else if (digit [i])
                    r_hex[i] <= hgfedcba;
        end

    endgenerate

    // HEX combinational
    wire [w_seg - 1:0] c_hex[w_digit];

    generate
        for (i = 0; i < w_digit; i++) begin : assign_registers
            assign c_hex[i] = digit [i] ? hgfedcba : '0;
            // Select combinational or registered HEX (blink or not)
            assign hex[i] = static_hex ? r_hex[i] : c_hex[i];
        end
    endgenerate

endmodule
