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
               w_y           = $clog2 ( screen_height )
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
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    wire [7:0] intern_abcdefgh;

    //------------------------------------------------------------------------

    lab_top_3_1_note_recognizer
    # (
        .clk_mhz       ( clk_mhz         ),
        .w_key         ( w_key           ),
        .w_sw          ( w_sw            ),
        .w_led         ( w_led           ),
        .w_digit       ( w_digit         ),
        .w_gpio        ( w_gpio          ),

        .screen_width  ( screen_width    ),
        .screen_height ( screen_height   ),

        .w_red         ( w_red           ),
        .w_green       ( w_green         ),
        .w_blue        ( w_blue          )
    )
    i_lab_top_3_1_note_recognizer
    (
        .clk           ( clk             ),
        .slow_clk      (                 ),
        .rst           ( rst             ),

        .key           ( '0              ),
        .sw            ( '0              ),
        .led           (                 ),

        .abcdefgh      ( intern_abcdefgh ),
        .digit         (                 ),

        .x             (                 ),
        .y             (                 ),

        .red           (                 ),
        .green         (                 ),
        .blue          (                 ),

        .mic           ( mic             ),
        .sound         (                 ),

        .uart_rx       (                 ),
        .uart_tx       (                 ),

        .gpio          (                 )
    );

    //------------------------------------------------------------------------

    logic [w_key - 1:0] intern_key;

    always @ (posedge clk)
        if (rst)
            intern_key <= '0;
        else
            case (intern_abcdefgh)
            8'b10011100 : intern_key <= w_key' (  0 );  // C   // abcdefgh
            8'b10011101 : intern_key <= w_key' (  1 );  // C#
            8'b01111010 : intern_key <= w_key' (  2 );  // D   //   --a--
            8'b01111011 : intern_key <= w_key' (  3 );  // D#  //  |     |
            8'b10011110 : intern_key <= w_key' (  4 );  // E   //  f     b
            8'b10001110 : intern_key <= w_key' (  5 );  // F   //  |     |
            8'b10001111 : intern_key <= w_key' (  6 );  // F#  //   --g--
            8'b10111100 : intern_key <= w_key' (  7 );  // G   //  |     |
            8'b10111101 : intern_key <= w_key' (  8 );  // G#  //  e     c
            8'b11101110 : intern_key <= w_key' (  9 );  // A   //  |     |
            8'b11101111 : intern_key <= w_key' ( 10 );  // A#  //   --d--  h
            8'b00111110 : intern_key <= w_key' ( 11 );  // B
            8'b00000010 :                            ;  // Previous one
            endcase

    //------------------------------------------------------------------------

    lab_top_3_3_note_synthesizer
    # (
        .clk_mhz       ( clk_mhz       ),
        .w_key         ( w_key         ),
        .w_sw          ( w_sw          ),
        .w_led         ( w_led         ),
        .w_digit       ( w_digit       ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top_3_3_note_synthesizer
    (
        .clk           ( clk           ),
        .slow_clk      (               ),
        .rst           ( rst           ),

        .key           ( intern_key    ),
        .sw            ( '0            ),
        .led           (               ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( digit         ),

        .x             (               ),
        .y             (               ),

        .red           (               ),
        .green         (               ),
        .blue          (               ),

        .mic           (               ),
        .sound         ( sound         ),

        .uart_rx       (               ),
        .uart_tx       (               ),

        .gpio          (               )
    );

endmodule
