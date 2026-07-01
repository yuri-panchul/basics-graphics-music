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

    logic pulse_3;

    always_ff @ (posedge clk)
        if (rst)
            pulse_3 <= '0;
        else
            pulse_3 <= pulse_2;
    
    logic pulse_4;

    always_ff @ (posedge clk)
        if (rst)
            pulse_4 <= '0;
        else
            pulse_4 <= pulse_3;

   logic pulse_5;

    always_ff @ (posedge clk)
        if (rst)
            pulse_5 <= '0;
        else
            pulse_5 <= pulse_4;

   logic pulse_6;

    always_ff @ (posedge clk)
        if (rst)
            pulse_6 <= '0;
        else
            pulse_6 <= pulse_5;



    assign pulse = pulse_1 | pulse_2 | pulse_3 | pulse_4 | pulse_5|pulse_6;

endmodule
