`include "config.svh"
`include "lab_specific_config.svh"

`undef ENABLE_TM1638
`undef ENABLE_INMP441

module board_specific_top
# (
    parameter   clk_mhz = 48,
                w_key   = 2, // w_key[1] is external RST input signal
                w_sw    = 2,
                w_led   = 3,
                w_digit = 0,
                w_gpio  = 8 // gpio[6] and gpio[7] are on SD card slot
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    output                      VGA_HS,
    output                      VGA_VS,
    output [              3:0]  VGA_R,
    output [              3:0]  VGA_G,
    output [              3:0]  VGA_B,

    inout  [w_gpio      - 1:0]  GPIO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;


    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        localparam w_top_key   = w_tm_key,
                   w_top_sw    = w_sw,
                   w_top_led   = w_tm_led,
                   w_top_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_top_key   = w_key,
                   w_top_sw    = w_sw,
                   w_top_led   = w_led,
                   w_top_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_top_key   - 1:0] top_key;
    wire  [w_top_led   - 1:0] top_led;
    wire  [w_top_digit - 1:0] top_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;
    wire                      mic_ready;

   //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        assign rst      = tm_key [w_tm_key - 1];
        assign top_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = top_led;
        assign tm_digit = top_digit;

    `else                   // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign top_key  = ~ KEY [w_key - 1:0];

        assign LED      = ~ top_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;
    wire slow_clk_local;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk_local), .*);

    DCCA slow_clk_buf (.CLKI(slow_clk_local), .CLKO(slow_clk), .CE(1));

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz   ),
        .w_key   ( w_top_key ),  // The last key is used for a reset
        .w_sw    ( w_top_sw      ),
        .w_led   ( w_top_led     ),
        .w_digit ( w_top_digit   ),
        .w_gpio  ( w_gpio    )
    )
    i_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( top_key   ),
        .sw       (           ),

        .led      ( top_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( top_digit ),

        .vsync    ( VGA_VS    ),
        .hsync    ( VGA_HS    ),

        .red      ( VGA_R     ),
        .green    ( VGA_G     ),
        .blue     ( VGA_B     ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .mic_ready( mic_ready ),
        .mic      ( mic       ),
        `ifndef ENABLE_TM1638
        .gpio     ( GPIO      )
        `else
        .gpio     (           )
        `endif
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

`ifdef ENABLE_TM1638
    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk      ( clk       ),
        .rst      ( rst       ),
        .hgfedcba ( hgfedcba  ),
        .digit    ( tm_digit  ),
        .ledr     ( tm_led    ),
        .keys     ( tm_key    ),
        .sio_clk  ( GPIO [0]  ),
        .sio_stb  ( GPIO [1]  ),
        .sio_data ( GPIO [2]  )
    );
`endif

    //------------------------------------------------------------------------

`ifdef ENABLE_INMP441
    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz )
    )
    i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [5] ),
        .ws    ( GPIO [4] ),
        .sck   ( GPIO [3] ),
        .sd    ( GPIO [6] ),
        .ready ( mic_ready),
        .value ( mic      )
    );
`endif

endmodule
