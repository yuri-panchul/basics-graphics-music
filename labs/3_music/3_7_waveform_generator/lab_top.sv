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

    input        [         23:0] mic,
    output       [w_sound - 1:0] sound,

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

    wire [        2:0] octave   = 3'b0;
    wire [w_key - 1:0] waveform = key;

    assign             led      = waveform;
    assign             digit    = w_digit' (1);

    //------------------------------------------------------------------------

    waveform_gen
    # (
        .clk_mhz        (clk_mhz       ),
        .waveform_width (w_key         ),
        .y_width        (w_sound       )
    )
    i_waveform_gen
    (
        .clk            ( clk          ),
        .reset          ( rst          ),
        .octave         ( octave       ),
        .waveform       ( waveform     ),

        .y              ( sound        )
    );

    //------------------------------------------------------------------------

    oscilloscope
    # (
        .clk_mhz       ( clk_mhz       ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),
        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_oscilloscope
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .x             ( x             ),
        .y             ( y             ),
        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

        .mic           ( sound         )
    );

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            abcdefgh <= 'b00000000;
        else
            case (waveform)
            'd1:    abcdefgh <= 'b10110110;  // S   // abcdefgh
            'd2:    abcdefgh <= 'b00011110;  // T
            'd4:    abcdefgh <= 'b11100110;  // Q   //   --a--
                                                    //  |     |
                                                    //  f     b
                                                    //  |     |
                                                    //   --g--
                                                    //  |     |
                                                    //  e     c
                                                    //  |     |
            default: abcdefgh <= 'b00000000;        //   --d--  h
            endcase

endmodule
