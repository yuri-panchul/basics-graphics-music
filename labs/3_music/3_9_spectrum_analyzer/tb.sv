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

    wire                  lr;
    wire                  ws;
    wire                  sck;
    logic                 sd;
    wire  [         23:0] value;

    logic [         10:0] rms_out;

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone (.*);

    //------------------------------------------------------------------------

    converter i_converter
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .mic        ({{value[23]}, {value[12:6]}}),
        .band_count ( 17'd2410   ),
        .rms_out    ( rms_out    )
    );

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

        @ (negedge rst);

        repeat (600000)
        begin
            sd <= $urandom ();
            @ (posedge clk);
        end

        // Based on timescale is 1 ns / 1 ps

        # 0.005s

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule
