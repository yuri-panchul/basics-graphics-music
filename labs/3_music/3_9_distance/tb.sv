`include "config.svh"

module tb;

    timeunit      1ns;
    timeprecision 1ps;

    //------------------------------------------------------------------------

    localparam clk_mhz = 50,
               w_key   = 4,
               w_sw    = 4,
               w_led   = 8,
               w_digit = 8,
               w_sound = 16,
               w_gpio  = 100;

    localparam clk_period = 20ns;

    //------------------------------------------------------------------------

    logic                 clk;
    logic                 rst;
    logic [w_key   - 1:0] key;
    logic [w_sw    - 1:0] sw;

    // Graphics
    logic [          9:0] x;
    logic [          8:0] y;

    logic [          3:0] red;
    logic [          3:0] green;
    logic [          3:0] blue;

    //------------------------------------------------------------------------

    logic                 echo;
    logic [          7:0] relative_distance;

    ultrasonic_distance_sensor
    # (
        .clk_frequency ( clk_mhz * 1000 * 1000 )
    )
    i_sensor
    (
        .clk,
        .rst,
        .trig              (                   ),
        .echo              ( echo              ),
        .relative_distance ( relative_distance )
    );

    //------------------------------------------------------------------------

    initial
    begin
        echo = 1'b0;
        # 0.001s
        echo = 1'b1;
        # 0.005s
        echo = 1'b0;
    end

    initial
    begin
        # 0.007s
        $display ( "relative_distance                 : %0d", relative_distance);
    end

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # (clk_period / 2) clk = ~ clk;
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
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        // Based on timescale is 1 ns / 1 ps

        # 0.008s

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule
