`include "config.svh"
`include "lab_specific_board_config.svh"

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 12,
              pixel_mhz     = 0,

              w_key         = 3,
              w_sw          = 0,
              w_led         = 7,
              w_digit       = 0,
              w_gpio        = 16,

              w_red         = 0,
              w_green       = 0,
              w_blue        = 0,

              screen_width  = 0,
              screen_height = 0,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)

//----------------------------------------------------------------------------

(
    // 12 MHz clock
    input      CLK,

    // RS232
    input      RX,
    output     TX,

    // LEDs and Button
    input      BTN_N,
    output     LEDR_N,
    output     LEDG_N,

    // RGB LED Driver
    output     LED_RED_N,
    output     LED_GRN_N,
    output     LED_BLU_N,
    output     LED_RGB[0],
    output     LED_RGB[1],
    output     LED_RGB[2],

    // SPI Flash
    output     FLASH_SCK,
    output     FLASH_SSB,
    input      FLASH_IO0,
    input      FLASH_IO1,
    input      FLASH_IO2,
    input      FLASH_IO3,

    // PMOD 1A
    inout      P1A1,
    inout      P1A2,
    inout      P1A3,
    inout      P1A4,
    inout      P1A7,
    inout      P1A8,
    inout      P1A9,
    inout      P1A10,

    // PMOD 1B
    inout      P1B1,
    inout      P1B2,
    inout      P1B3,
    inout      P1B4,
    inout      P1B7,
    inout      P1B8,
    inout      P1B9,
    inout      P1B10,

    // PMOD 2
    inout      P2_1,
    inout      P2_2,
    inout      P2_3,
    inout      P2_4,
    inout      P2_7,
    inout      P2_8,
    inout      P2_9,
    inout      P2_10,

    // LEDs and Buttons (PMOD 2)
    output     LED1,
    output     LED2,
    output     LED3,
    output     LED4,
    output     LED5,
    input      BTN1,
    input      BTN2,
    input      BTN3
);

    wire clk = CLK;
    wire rst = ~ BTN_N;

    //------------------------------------------------------------------------

    wire [w_key - 1:0] key = { BTN1, BTN2, BTN3 }
    wire [w_led - 1:0] led;

    assign LEDR_N = ~ led [6];
    assign LEDG_N = ~ led [5];
    assign LED1   =   led [4];
    assign LED2   =   led [3];
    assign LED3   =   led [2];
    assign LED4   =   led [1];
    assign LED5   =   led [0];

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_key         ),
        .w_sw          ( w_key         ),
        .w_led         ( w_led         ),
        .w_digit       ( 1             ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( 1             ),
        .w_green       ( 1             ),
        .w_blue        ( 1             )
    )
    i_lab_top
    (
        .clk           ,
        .slow_clk      ,
        .rst           ,

        .key           ,
        .sw            ( key           ),

        .led           ,

        .abcdefgh      (               ),
        .digit         (               ),

        .x             (               ),
        .y             (               ),

        .red           (               ),
        .green         (               ),
        .blue          (               ),

        .uart_rx       ( RX            ),
        .uart_tx       ( TX            ),

        .mic           (               ),
        .sound         (               ),

        .gpio          ( {
                           P1A10,
                           P1A9,
                           P1A8,
                           P1A7,
                           P1A4,
                           P1A3,
                           P1A2,
                           P1A1,

                           P1B10,
                           P1B9,
                           P1B8,
                           P1B7,
                           P1B4,
                           P1B3,
                           P1B2,
                           P1B1
                       } )
    );

endmodule
