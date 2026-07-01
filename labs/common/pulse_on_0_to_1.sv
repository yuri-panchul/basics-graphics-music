`include "config.svh"

module pulse_on_0_to_1
# (
    parameter w = 1
)
(
    input            clk,
    input            rst,
    input  [w - 1:0] level,
    output [w - 1:0] pulse
);

    logic  [w - 1:0] level_r;

    always_ff @ (posedge clk)
        if (rst)
            level_r <= '0;
        else
            level_r <= level;

    // Pulse extender

    wire pulse_1;
    assign pulse_1 = level & ~ level_r;

    logic pulse_2;

    always_ff @ (posedge clk)
        if (rst)
            pulse_2 <= '0;
        else
            pulse_2 <= pulse_1;
            
    assign pulse = pulse_1 | pulse_2;

endmodule
