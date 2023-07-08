// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"

module shift_reg
# (
    parameter depth = 2
)
(
    input                      clk,
    input                      rst,
    input                      en,
    input                      seq_in,
    output                     seq_out,
    output logic [depth - 1:0] par_out
);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            par_out <= '0;
        else if (en)
            par_out <= { seq_in, par_out [depth - 1:1] };

    assign seq_out = par_out [0];

endmodule
