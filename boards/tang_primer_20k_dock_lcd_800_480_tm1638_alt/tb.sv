`include "config.svh"

module tb;

    //------------------------------------------------------------------------

    logic               clk;
    logic               rst;
    bit   [0:12] [31:0] data_rgb;
    wire                sk9822_clk;
    wire                sk9822_data;

    //------------------------------------------------------------------------

    led_strip_combo i_led_strip_combo (.*);

    assign data_rgb = {13 { 3'b111, 5'b01111, {3 {8'h01} } } };

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # 1 clk = ! clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 'bx;
        repeat (2) @ (posedge clk);
        rst <= 1;
        repeat (2) @ (posedge clk);
        rst <= 0;
    end

    //------------------------------------------------------------------------

    initial
    begin
        #0
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        #140000

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule
