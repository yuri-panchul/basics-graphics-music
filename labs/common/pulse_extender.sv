`include "config.svh"

module pulse_extender
# (
    parameter width = 1, depth = 2
)
(
    input                clk,
    input                rst,
    input  [width - 1:0] pulse,
    output [width - 1:0] extended
);
    genvar i;

    generate
    
        for (i = 0; i < width; i ++)
        begin : gen

            wire [depth - 1:0] par_out;

              shift_reg # (.depth (depth))
            i_shift_reg
            (
                .clk,
                .rst,
                .en      ( 1'b1      ),
                .seq_in  ( pulse [i] ),
                .seq_out (           ),
                .par_out
            );

            assign extended [i] = | par_out;
        end

    endgenerate

endmodule
