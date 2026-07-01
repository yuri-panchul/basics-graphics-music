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
    
        if (depth == 0)
        begin : depth_0

            assign extended = pulse;

        end
        else if (depth == 1)
        begin : depth_1

            logic [width - 1:0] pulse_r;

            always_ff @ (posedge clk)
                if (rst)
                    pulse_r <= '0;
                else
                    pulse_r <= pulse;

            assign extended = pulse | pulse_r;

        end
        else
        begin : depth_gt_1

            for (i = 0; i < width; i ++)
            begin : for_depth_gt_1

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
        end

    endgenerate

endmodule
