`include "config.svh"

module board_specific_top
# (
    parameter   clk_mhz = 27,  
                w_key   = 2,  // The last key is used for a reset
                w_sw    = 0,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 23
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

    localparam w_top_sw   = w_sw - 1;  // One onboard SW is used as a reset

    wire                  rst     = SW [w_top_sw];
    wire [w_top_sw - 1:0] top_sw  = SW [w_top_sw - 1:0];

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    //------------------------------------------------------------------------

    `ifdef DUPLICATE_TM_SIGNALS_WITH_REGULAR

        localparam w_top_key   = w_tm_key   > w_key   ? w_tm_key   : w_key   ,
                   w_top_led   = w_tm_led   > w_led   ? w_tm_led   : w_led   ,
                   w_top_digit = w_tm_digit > w_digit ? w_tm_digit : w_digit ;

    `else  // Concatenate the signals

        localparam w_top_key   = w_tm_key   + w_key   ,
                   w_top_led   = w_tm_led   + w_led   ,
                   w_top_digit = w_tm_digit + w_digit ;
    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_top_key   - 1:0] top_key;
    wire  [w_top_led   - 1:0] top_led;
    wire  [w_top_digit - 1:0] top_digit;

    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;

    wire                      VGA_HS;
    wire                      VGA_VS;

    wire  [              3:0] VGA_R;
    wire  [              3:0] VGA_G;
    wire  [              3:0] VGA_B;

    //------------------------------------------------------------------------

    `ifdef CONCAT_TM_SIGNALS_AND_REGULAR

        assign top_key = { tm_key, ~ KEY };

        assign { tm_led   , LED   } = { top_led[w_tm_led - 1:w_led], ~ top_led[w_led    - 1:0] };
        assign { tm_digit , digit } = top_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM

        assign top_key = { ~ KEY, tm_key };

        assign { LED   , tm_led   } = { ~ top_led[w_led    - 1:w_tm_led], top_led[w_tm_led - 1:0] };
        assign { digit , tm_digit } = top_digit;

    `else  // DUPLICATE_TM_SIGNALS_WITH_REGULAR

        always_comb
        begin
            top_key = '0;

            top_key [w_key    - 1:0] |= ~ KEY;
            top_key [w_tm_key - 1:0] |= tm_key;
        end

        assign LED      = ~ top_led   [w_led      - 1:0];
        assign tm_led   =   top_led   [w_tm_led   - 1:0];

        assign digit    = top_digit [w_digit    - 1:0];
        assign tm_digit = top_digit [w_tm_digit - 1:0];

    `endif

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz      ),
        .w_key   ( w_top_key    ),  // The last key is used for a reset
        .w_sw    ( w_top_sw     ),
        .w_led   ( w_top_led    ),
        .w_digit ( w_top_digit  ),
        .w_gpio  ( w_gpio       )
    )
    i_top
    (
        .clk      ( CLK       ),
        .rst      ( rst       ),

        .key      ( top_key   ),
        .sw       ( top_sw    ),

        .led      ( top_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( top_digit ),

        .vsync    ( VGA_VS    ),
        .hsync    ( VGA_HS    ),

        .red      ( VGA_R     ),
        .green    ( VGA_G     ),
        .blue     ( VGA_B     ),

        .mic      ( mic       ),
        .gpio     (           )
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
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk      ( CLK        ),
        .rst      ( rst        ), // Don't make reset tm1638_board_controller by it's tm_key
        .hgfedcba ( hgfedcba   ),
        .digit    ( tm_digit   ),
        .ledr     ( tm_led     ),
        .keys     ( tm_key     ),
        .sio_clk  ( GPIO [15]  ),
        .sio_stb  ( GPIO [14]  ),
        .sio_data ( GPIO [16]  )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .lr    ( GPIO [18]  ),
        .ws    ( GPIO [19]  ),
        .sck   ( GPIO [20]  ),
        .sd    ( GPIO [17]  ),
        .value ( mic        )
    );

    assign GPIO [21] = 1'b0;  // GND
    assign GPIO [22] = 1'b1;  // VCC

    //------------------------------------------------------------------------

    assign GPIO [12]   = VGA_HS;
    assign GPIO [13]   = VGA_VS;
    assign GPIO [3:0]  = VGA_G;
    assign GPIO [7:4]  = VGA_R;
    assign GPIO [11:8] = VGA_B;

endmodule
