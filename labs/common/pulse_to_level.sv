`include "config.svh"

module pulse_to_level
# (
    parameter w = 1
)
(
    input                  clk,
    input                  rst,
    input        [w - 1:0] pulse,
    output logic [w - 1:0] level
);

    generate

        genvar i;

        for (i = 0; i < w); i ++)
        begin : g
            always_ff @ (posedge clk)
                if (rst)
                    level [i] <= 1'b0;
                else if (pulse [i])
                    level [i] <= ~ level [i];
        end

    endgenerate

endmodule
