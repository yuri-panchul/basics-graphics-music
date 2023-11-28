`include "config.svh"
`include "lab_specific_config.svh"

// `define INMP441_MIC

module board_specific_top
# (
    parameter clk_mhz = 100,
              w_key   = 4,
              w_sw    = 4,
              w_led   = 4,
              w_digit = 0,
              w_gpio  = 42
)
(
    input                  CLK100MHZ,
    input                  CPU_RESETN,

    input                  BTN_0,
    input                  BTN_1,
    input                  BTN_2,
    input                  BTN_3,

    input  [w_sw   - 1:0]  SW,
    output [w_led  - 1:0]  LED,

    output                 LED0_B,
    output                 LED0_G,
    output                 LED0_R,

    output                 LED1_B,
    output                 LED1_G,
    output                 LED1_R,

    output                 LED2_B,
    output                 LED2_G,
    output                 LED2_R,

    output                 LED3_B,
    output                 LED3_G,
    output                 LED3_R,

    input                  UART_TXD_IN,

    inout  [7:0]           JA,
    inout  [7:0]           JB,  // VGA_B and VGA_R
    inout  [7:0]           JC,  // VGA_G and VGA_HS, VGA, VS
    inout  [7:0]           JD,

    inout  [w_gpio - 1:0]  GPIO
);

    //------------------------------------------------------------------------

    wire clk =   CLK100MHZ;
    wire rst = ~ CPU_RESETN;

    // FIXME: Should be assigned to some GPIO!
    wire UART_RXD_OUT;

    //------------------------------------------------------------------------

    assign LED0_B = 1'b0;
    assign LED0_G = 1'b0;
    assign LED0_R = 1'b0;

    assign LED1_B = 1'b0;
    assign LED1_G = 1'b0;
    assign LED1_R = 1'b0;

    assign LED2_B = 1'b0;
    assign LED2_G = 1'b0;
    assign LED2_R = 1'b0;

    assign LED3_B = 1'b0;
    assign LED3_G = 1'b0;
    assign LED3_R = 1'b0;

    //------------------------------------------------------------------------

    wire               mic_ready;
    wire [       23:0] mic;
    wire [        7:0] abcdefgh;

    //------------------------------------------------------------------------

    wire [        3:0] KEY    = { BTN_3, BTN_2, BTN_1, BTN_0 };
    wire [ w_sw - 1:0] top_sw = SW [w_sw - 1:0];

    localparam  w_tm_key     = 8,
                w_tm_led     = 8,
                w_tm_digit   = 8;

    `ifdef DUPLICATE_TM_SIGNALS_WITH_REGULAR

        localparam w_top_key   = w_tm_key   > w_key   ? w_tm_key   : w_key   ,
                   w_top_led   = w_tm_led   > w_led   ? w_tm_led   : w_led   ,
                   w_top_digit = w_tm_digit > w_digit ? w_tm_digit : w_digit ;

    `else  // Concatenate the signals

        localparam w_top_key   = w_tm_key   + w_key   ,
                   w_top_led   = w_tm_led   + w_led   ,
                   w_top_digit = w_tm_digit + w_digit ;
    `endif


    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_top_key   - 1:0] top_key;
    wire  [w_top_led   - 1:0] top_led;
    wire  [w_top_digit - 1:0] top_digit;


    //------------------------------------------------------------------------

    `ifdef CONCAT_TM_SIGNALS_AND_REGULAR

        assign top_key = { tm_key,  KEY };

        assign { tm_led   , LED   } = top_led;
        assign             tm_digit = top_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM

        assign top_key = {  KEY, tm_key };

        assign { LED   , tm_led   } = top_led;
        assign             tm_digit = top_digit;

    `else  // DUPLICATE_TM_SIGNALS_WITH_REGULAR

        always_comb
        begin
            top_key = '0;

            top_key [w_key    - 1:0] |=  KEY;
            top_key [w_tm_key - 1:0] |= tm_key;
        end

        assign LED      = top_led   [w_led      - 1:0];
        assign tm_led   = top_led   [w_tm_led   - 1:0];

        assign tm_digit = top_digit [w_tm_digit - 1:0];

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz     ),
        .w_key   ( w_top_key   ),
        .w_sw    ( w_sw        ),
        .w_led   ( w_top_led   ),
        .w_digit ( w_top_digit ),
        .w_gpio  ( w_gpio      )
    )
    i_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( top_key   ),
        .sw       ( top_sw    ),

        .led      ( top_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( top_digit ),

        .vsync    ( JC [1]    ),
        .hsync    ( JC [0]    ),

        .red      ( JB [7:4]  ),
        .green    ( JC [7:4]  ),
        .blue     ( JB [3:0]  ),

        .uart_rx  (UART_TXD_IN),
        .uart_tx  (UART_RXD_OUT),

        .mic      ( mic       ),
        .mic_ready( mic_ready ),
        .gpio     ( GPIO      )
    );

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    tm1638_board_controller
    # (
        .w_digit   ( w_tm_digit ),  // fake parameter, digit count is hardcode in tm1638_board_controller
        .clk_mhz   ( clk_mhz    )
    )
    i_ledkey
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .hgfedcba  ( hgfedcba   ),
        .digit     ( tm_digit   ),
        .ledr      ( tm_led     ),
        .keys      ( tm_key     ),
        .sio_clk   ( GPIO [40]  ),
        .sio_stb   ( GPIO [41]  ),
        .sio_data  ( GPIO [39]  )
    );

    `ifdef INMP441_MIC

    inmp441_mic_i2s_receiver
    #(
        .clk_mhz   ( clk_mhz    )
    )
    i_mic
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .lr        ( JD [5]     ),
        .ws        ( JD [4]     ),
        .sck       ( JD [7]     ),
        .sd        ( JD [6]     ),
        .ready     ( mic_ready  ),
        .value     ( mic        )
    );

    `else

    wire [11:0] mic_12;
    wire [11:0] mic_12_minus_offset = mic_12 - 12'h800;

    assign mic = { { 12 { mic_12_minus_offset [11] } }, mic_12_minus_offset };

    digilent_pmod_mic3_spi_receiver
    #(
        .clk_mhz   ( clk_mhz    )
    )
    i_mic
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .cs        ( JD [4]     ),
        .sck       ( JD [7]     ),
        .sdo       ( JD [6]     ),
        .value     ( mic_12     )
    );

    `endif

endmodule
