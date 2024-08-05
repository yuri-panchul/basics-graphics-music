`include "config.svh"
`include "lab_specific_board_config.svh"

`undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`undef ENABLE_INMP441

module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 2,  // The last key is used for a reset
                w_sw    = 4,
                w_led   = 0,
                w_digit = 0,
                w_gpio  = 32
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_lab_key   = w_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_led,
                   w_lab_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    logic [w_lab_sw    - 1:0] lab_sw;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;

    wire                      VGA_HS;
    wire                      VGA_VS;

    wire  [              3:0] VGA_R;
    wire  [              3:0] VGA_G;
    wire  [              3:0] VGA_B;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];
        assign lab_sw   = ~ SW;

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign lab_key  = ~ KEY [w_key - 1:0];
        assign lab_sw   = ~ SW;

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz      ),
        .w_key   ( w_lab_key    ),  // The last key is used for a reset
        .w_sw    ( w_lab_sw     ),
        .w_led   ( w_lab_led    ),
        .w_digit ( w_lab_digit  ),
        .w_gpio  ( w_gpio       )
    )
    i_lab_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( lab_key   ),
        .sw       ( lab_sw    ),

        .led      ( lab_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( lab_digit ),

        .vsync    ( VGA_VS    ),
        .hsync    ( VGA_HS    ),

        .red      ( VGA_R     ),
        .green    ( VGA_G     ),
        .blue     ( VGA_B     ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .mic      ( mic       ),
        `ifndef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
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

`ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk        ( clk           ),
        .rst        ( rst           ),
        .hgfedcba   ( hgfedcba      ),
        .digit      ( tm_digit      ),
        .ledr       ( tm_led        ),
        .keys       ( tm_key        ),
        .sio_clk    ( GPIO_2 [2]    ),
        .sio_stb    ( GPIO_2 [3]    ),
        .sio_data   ( GPIO_2 [1]    )
    );

    //------------------------------------------------------------------------
`endif

`ifdef ENABLE_INMP441
    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz )
    )
    i_microphone
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .lr    ( GPIO_3 [1] ),
        .ws    ( GPIO_3 [2] ),
        .sck   ( GPIO_3 [3] ),
        .sd    ( GPIO_3 [0] ),
        .value ( mic        )
    );
`endif

    //------------------------------------------------------------------------

    assign GPIO_0= { VGA_B, VGA_R };
    assign GPIO_1 = { VGA_HS, VGA_VS, 2'bz, VGA_G };

endmodule
