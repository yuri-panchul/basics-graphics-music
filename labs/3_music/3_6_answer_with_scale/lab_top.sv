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

    wire [7:0] mic_abcdefgh;

    //------------------------------------------------------------------------

    lab_top_3_1_note_recognizer
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
    i_lab_top_3_1_note_recognizer
    (
        .clk           ( clk           ),
        .slow_clk      (               ),
        .rst           ( rst           ),

        .key           ( '0            ),
        .sw            ( '0            ),
        .led           (               ),

        .abcdefgh      ( mic_abcdefgh  ),
        .digit         (               ),

        .x             (               ),
        .y             (               ),

        .red           (               ),
        .green         (               ),
        .blue          (               ),

        .mic           ( mic           ),
        .sound         (               ),

        .uart_rx       (               ),
        .uart_tx       (               ),

        .gpio          (               )
    );

    //------------------------------------------------------------------------

    logic mic_on;
    logic [w_key - 1:0] mic_note;

    always_comb
    begin
        mic_on   = 1'b1;
        mic_note = '0;  // 'x

        case (mic_abcdefgh)
        8'b10011100 : mic_note = w_key' (  0 );  // C   // abcdefgh
        8'b10011101 : mic_note = w_key' (  1 );  // C#
        8'b01111010 : mic_note = w_key' (  2 );  // D   //   --a--
        8'b01111011 : mic_note = w_key' (  3 );  // D#  //  |     |
        8'b10011110 : mic_note = w_key' (  4 );  // E   //  f     b
        8'b10001110 : mic_note = w_key' (  5 );  // F   //  |     |
        8'b10001111 : mic_note = w_key' (  6 );  // F#  //   --g--
        8'b10111100 : mic_note = w_key' (  7 );  // G   //  |     |
        8'b10111101 : mic_note = w_key' (  8 );  // G#  //  e     c
        8'b11101110 : mic_note = w_key' (  9 );  // A   //  |     |
        8'b11101111 : mic_note = w_key' ( 10 );  // A#  //   --d--  h
        8'b00111110 : mic_note = w_key' ( 11 );  // B
        default     : mic_on   = 1'b0;           // Not recognized
        endcase
    end

    //------------------------------------------------------------------------

    logic enable;

    strobe_gen # (.clk_mhz (clk_mhz), .strobe_hz (1))
    i_strobe_gen (clk, rst, enable);

    //------------------------------------------------------------------------

    logic [2:0] cnt;
    logic [w_key - 1:0] out_note, next_out_note;

    always_comb
        case (cnt)

        3'd0, 3'd1, 3'd3, 3'd4, 3'd5:  // Tone

            next_out_note
               = out_note < w_key' (10)
               ? out_note + w_key' ( 2)
               : out_note - w_key' (10);

        default:  // 3'd2, 3'd6        // Half-tone

            next_out_note
               = out_note < w_key' (11)
               ? out_note + w_key' ( 1)
               :            w_key' ( 0);

        endcase

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            cnt      <= '0;
            out_note <= '0;
        end
        else if (mic_on)
        begin
            cnt      <= '0;
            out_note <= mic_note;
        end
        else if (enable)
        begin
            if (cnt == 3'd6)
                cnt <= '0;
            else
                cnt <= cnt + 1'd1;

            out_note <= next_out_note;
        end

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

        .key           ( out_note      ),
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
