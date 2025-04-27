`include "config.vh"

module sync_and_debounce_one
# (
    parameter depth = 8
)
(   
    input      clk,
    input      reset,
    input      sw_in,
    output reg sw_out
);

    reg  [depth - 1:0] cnt;
    reg  [        2:0] sync;
    wire               sw_in_s;

    assign sw_in_s = sync [2];

    always @ (posedge clk or posedge reset)
        if (reset)
            sync <= 3'b0;
        else
            sync <= { sync [1:0], sw_in };

    always @ (posedge clk or posedge reset)
        if (reset)
            cnt <= { depth { 1'b0 } };
        else if (sw_out ^ sw_in_s)
            cnt <= cnt + 1'b1;
        else
            cnt <= { depth { 1'b0 } };

    always @ (posedge clk or posedge reset)
        if (reset)
            sw_out <= 1'b0;
        else if (cnt == { depth { 1'b1 } })
            sw_out <= sw_in_s;

endmodule
