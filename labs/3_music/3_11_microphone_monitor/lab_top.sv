`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,
               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,
               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height ),

               w_sound       = 16
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs
    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display
    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics
    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART
    input  logic signed [         23:0] mic,
    output logic signed [w_sound - 1:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output
    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
    // assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    logic signed [10:0] mic_11bit;
    wire         [ 7:0] vol;

    // Spectrum analyzer level adjust
    convert
    # (
        .w_in  ( 24        ),
        .w_out ( 11        ),
        .lev   ( 17        ),
        .agc   ( 1         )
    )
    i_convert
    (
        .clk   ( clk       ),
        .rst   ( rst       ),
        .in    ( mic       ),
        .out   ( mic_11bit ),
        .led   ( led[0]    ),
        .vol   ( vol[2:0]  )
    );

    // Sound output level adjust
    convert
    # (
        .w_in  ( 24        ),
        .w_out ( 16        ),
        .lev   ( 17        ),
        .agc   ( 1         )
    )
    i_convert_line
    (
        .clk   ( clk       ),
        .rst   ( rst       ),
        .in    ( mic       ),
        .out   ( sound     ),
        .led   ( led[1]    ),
        .vol   ( vol[6:4]  )
    );

    seven_segment_display i_7segment
    (
        .clk      ( clk       ),
        .rst      ( rst       ),
        .number   ( 8' (vol)  ),
        .dots     ( 2'b0      ),
        .abcdefgh ( abcdefgh  ),
        .digit    ( digit     )
    );

    //------------------------------------------------------------------------

    spectrum
    # (
        .clk_mhz       ( clk_mhz       ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),
        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        ),

    // Frequency bands of the spectrum analyzer
        .freq          ('{200, 230, 264, 303,
                          348, 400, 458, 525})
    )
    i_spectrum
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .x             ( x             ),
        .y             ( y             ),
        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),
        .mic           ( mic_11bit     )
    );

endmodule
