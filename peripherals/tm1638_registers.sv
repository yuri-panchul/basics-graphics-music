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
              logic [w_seg - 1:0] r_init[w_digit] = '{default:0}
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

    ////////////// TM1563 data /////////////////

    // HEX registered
    logic [w_seg - 1:0] r_hex[w_digit];

    always @( posedge clk )
    begin
        if (rst)
            r_hex <= r_init;
        else
            for (int i = 0; i < $bits (digit); i++)
                if(digit == 'b1<<i)
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
