`include "game_config.svh"

module game_strobe # ( parameter width = 32 )
(
    input        clk,
    input        rst,
    output logic strobe
);

    logic [width - 1:0] counter;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            counter <= '0;
            strobe  <= 1'b0;
        end
        else
        begin
            counter <= counter + 1'b1;
            strobe  <= & counter;
        end

endmodule
