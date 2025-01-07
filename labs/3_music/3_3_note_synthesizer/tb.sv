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
    logic [w_sound - 1:0] sound;

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        // TODO .w_sound ( w_sound ),
        .w_gpio  ( w_gpio  )
    )
    i_lab_top
    (
        .clk      ( clk    ),
        .slow_clk ( clk    ),
        .rst      ( rst    ),
        .key      ( key    ),
        .sw       ( sw     ),
        .sound    ( sound  )
    );

    //------------------------------------------------------------------------

    wire mclk, bclk, lrclk, sdata;

    i2s_audio_out
    # (
        .clk_mhz  ( clk_mhz ),
        .in_res   ( w_sound ),

        // For the standard I2S, align_right = 0,
        // i.e. value is aligned to the left relative to LRCLK signal,
        // MSB - Most Significant Bit Justified.

        // For PT8211 DAC, align_right = 1,
        // i.e. value is aligned to the right relative to LRCLK signal,
        // LSB - Least Significant Bit Justified.

        .align_right (0),

        // For the standard I2S, offset_by_one_cycle = 1,
        // i.e. value transmission starts with an offset of 1 clock cycle
        // relative to LRCLK signal

        // For PT8211 DAC, offset_by_one_cycle = 0,
        // i.e. value transmission is aligned with LRCLK signal change.

        .offset_by_one_cycle (1)
    )
    i_i2s_audio_out
    (
        .clk      ( clk    ),
        .reset    ( rst    ),
        .data_in  ( sound  ),
        .mclk     ( mclk   ),
        .bclk     ( bclk   ),
        .lrclk    ( lrclk  ),
        .sdata    ( sdata  )
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

    assign key = w_key' (1);

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        // Based on timescale is 1 ns / 1 ps

        # 0.0035s

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule
