`include "game_config.svh"

module game_timer # ( parameter width = 32 )
(
    input                      clk,
    input                      rst,
    input        [width - 1:0] value,
    input                      start,
    output logic               running
);

    logic [width - 1:0] counter;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            running <= 1'b0;
        end
        else if (start)
        begin
            counter <= value;
            running <= 1'b1;
        end
        else if (running)
        begin
            if (counter == '0)
                running <= 1'b0;

            counter <= counter - 1'd1;
        end

endmodule
