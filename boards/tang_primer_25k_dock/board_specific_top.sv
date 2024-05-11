`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter   clk_mhz = 50,
                w_key   = 2,  // The last key is used for a reset
                w_sw    = 0,
                w_led   = 0,
                w_digit = 0,
                w_gpio  = 38
)
(
    input                  clk,
    input  [w_key  - 1:0]  key,
    inout  [w_gpio - 1:0]  gpio
);

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire                      rst = tm_key [w_tm_key - 1];

    wire  [w_tm_led    - 1:0] led;

    wire  [              7:0] abcdefgh;
    wire  [w_tm_digit  - 1:0] digit;

    wire  [             23:0] mic;
    wire                      mic_ready;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz      ),
        .w_key   ( w_tm_key     ),  // The last key is used for a reset
        .w_sw    ( w_tm_key     ),
        .w_led   ( w_tm_led     ),
        .w_digit ( w_tm_digit   ),
        .w_gpio  ( w_gpio       )
    )
    i_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( tm_key    ),
        .sw       ( tm_key    ),

        .led      ( led       ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( digit     ),

        .vsync    (           ),
        .hsync    (           ),

        .red      (           ),
        .green    (           ),
        .blue     (           ),

        .uart_rx  (           ),
        .uart_tx  (           ),

        .mic_ready( mic_ready ),
        .mic      ( mic       ),
        .gpio     ( gpio      )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk        ( clk       ),
        .rst        ( rst       ),
        .hgfedcba   ( hgfedcba  ),
        .digit      ( digit     ),
        .ledr       ( led       ),
        .keys       ( tm_key    ),
        .sio_clk    ( gpio [35] ),
        .sio_stb    ( gpio [33] ),
        .sio_data   ( gpio [37] )
    );

    assign gpio [31] = 1'b0;
    assign gpio [29] = 1'b1;

    //------------------------------------------------------------------------

    /*
    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .lr    ( GPIO_3 [1] ),
        .ws    ( GPIO_3 [2] ),
        .sck   ( GPIO_3 [3] ),
        .sd    ( GPIO_3 [0] ),
        .ready ( mic_ready  ),
        .value ( mic        )
    );
    */

endmodule
