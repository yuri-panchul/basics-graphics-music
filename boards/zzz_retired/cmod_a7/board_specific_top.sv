`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 12,
              w_key   = 2,
              w_sw    = 0,
              w_led   = 2,
              w_digit = 0,
              w_gpio  = 44
)
(
// continue from here
    input                sysclk,

    input  [w_key - 1:0] btn,

    output [w_led - 1:0] led,

    output               led0_b,
    output               led0_g,
    output               led0_r,

    inout  [7:0]         ja,

    input                uart_txd_in,
    output               uart_rxd_out

);

    //------------------------------------------------------------------------

    wire clk =   sysclk;
    wire rst =   0;

    //------------------------------------------------------------------------

    assign LED16_B = 1'b0;
    assign LED16_G = 1'b0;
    assign LED16_R = 1'b0;
    assign LED17_B = 1'b0;
    assign LED17_G = 1'b0;
    assign LED17_R = 1'b0;

    assign M_CLK   = 1'b0;
    assign M_LRSEL = 1'b0;

    assign AUD_PWM = 1'b0;
    assign AUD_SD  = 1'b0;

    //------------------------------------------------------------------------

    wire [ 7:0] abcdefgh;
    wire [ 7:0] digit;

    wire [23:0] mic = '0;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_lab_top
    (
        .clk      ( clk      ),
        .slow_clk ( slow_clk ),
        .rst      ( rst      ),

        .key      ( btn      ),
        .sw       (          ),

        .led      ( led      ),

        .abcdefgh ( abcdefgh ),

        .digit    (          ),

        .vsync    ( 0        ),
        .hsync    ( 0        ),

        .red      ( 0        ),
        .green    ( 0        ),
        .blue     ( 0        ),

        .uart_rx  ( uart_txd_in),
        .uart_tx  ( uart_rxd_out),

        .mic      ( mic      ),
        .gpio     (          )
    );

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz  )
    )
    i_microphone
    (
        .clk     ( clk      ),
        .rst     ( rst      ),
        .lr      ( ja [4]   ),
        .ws      ( ja [5]   ),
        .sck     ( ja [7]   ),
        .sd      ( ja [6]   ),
        .value   ( mic      )
    );

endmodule
