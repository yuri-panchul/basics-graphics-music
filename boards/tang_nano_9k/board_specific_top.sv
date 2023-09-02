   `define ENABLE_TM1638

module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 2,  // The last key is used for a reset
                w_sw    = 0,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 0
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio      - 1:0]  GPIO
);

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh;
    wire [         23:0] mic;

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;


    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        localparam w_top_key   = w_tm_key,
                   w_top_led   = w_tm_led,
                   w_top_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_top_key   = w_key,
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

    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        assign top_key = tm_key;

        assign top_led = tm_led;
        assign top_digit = tm_digit;

    `else                   // TM1638 module is not connected

        assign top_key = KEY;

        assign top_led = LED;
        assign top_digit = '1;

    `endif

    //------------------------------------------------------------------------

    wire                   rst     = ~ KEY [w_key - 1];
    wire [w_top_key - 1:0] top_key = ~ KEY [w_top_key - 1:0];

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;
    wire [w_gpio  - 1:0] gpio;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz   ),
        .w_key   ( w_top_key ),  // The last key is used for a reset
        .w_sw    ( w_sw      ),
        .w_led   ( w_led     ),
        .w_digit ( w_digit   ),
        .w_gpio  ( w_gpio    )
    )
    i_top
    (
        .clk      ( CLK       ),
        .rst      ( rst       ),

        .key      ( top_key  ),
        .sw       (           ),

        .led      ( top_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( top_digit ),

        .vsync    (           ),
        .hsync    (           ),

        .red      (           ),
        .green    (           ),
        .blue     (           ),

        .mic      (           ),
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
        .w_digit ( w_digit )
    )
    i_tm1638
    (
        .clk      ( CLK       ),
        .rst      ( rst       ),
        .hgfedcba ( hgfedcba  ),
        .digit    ( tm_digit  ),
        .ledr     ( tm_led    ),
        .keys     ( tm_key    ),
        .sio_clk  (  ),
        .sio_stb  (  ),
        .sio_data (  )
    );

    //------------------------------------------------------------------------

    assign LED = ~ led;

endmodule