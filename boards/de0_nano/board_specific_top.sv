// `define EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

   `define DUPLICATE_TM_SIGNALS_WITH_REGULAR
// `define CONCAT_REGULAR_SIGNALS_AND_TM
// `define CONCAT_TM_SIGNALS_AND_REGULAR

module board_specific_top
# (
    parameter clk_mhz  = 50,
              w_key    = 2,
              w_sw     = 4,
              w_led    = 8,
              w_digit  = 0,
              w_gpio   = 34                   // GPIO_0 [31], [32], [33] reserved for tm1638, GPIO_0[5:0] reserved for mic, no GPIO_x_IN because it's input only
)
(
    input                     CLOCK_50,

    input  [w_key      - 1:0] KEY,
    input  [w_sw       - 1:0] SW,
    output [w_led      - 1:0] LED,            // LEDG onboard

    inout  [w_gpio     - 1:0] GPIO_0,
    inout  [w_gpio     - 1:0] GPIO_1
);

    //------------------------------------------------------------------------

    localparam w_top_sw   = w_sw - 1;         // One onboard SW is used as a reset

    wire                  clk    = CLOCK_50;

    wire                  rst    = SW [w_top_sw];
    wire [w_top_sw - 1:0] top_sw = SW [w_top_sw - 1:0];

    //------------------------------------------------------------------------

    wire [           7:0] abcdefgh;

    wire                  vga_vs, vga_hs;
    wire [           3:0] vga_r, vga_g, vga_b;

    wire [          23:0] mic;

    //------------------------------------------------------------------------

    localparam w_tm_key     = 8,
               w_tm_led     = 8,
               w_tm_digit   = 8;

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

    //------------------------------------------------------------------------

    `ifdef CONCAT_TM_SIGNALS_AND_REGULAR

        assign top_key = { tm_key, ~ KEY };

        assign { tm_led   , LED   } = top_led;
        assign             tm_digit = top_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM

        assign top_key = { ~ KEY, tm_key };

        assign { LED   , tm_led   } = top_led;
        assign             tm_digit = top_digit;

    `else  // DUPLICATE_TM_SIGNALS_WITH_REGULAR

        always_comb
        begin
            top_key = '0;

            top_key [w_key    - 1:0] |= ~ KEY;
            top_key [w_tm_key - 1:0] |= tm_key;
        end

        assign LED      = top_led   [w_led      - 1:0];
        assign tm_led   = top_led   [w_tm_led   - 1:0];

        assign tm_digit = top_digit [w_tm_digit - 1:0];

    `endif

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz     ),
        .w_key   ( w_top_key   ),
        .w_sw    ( w_top_sw    ),
        .w_led   ( w_top_led   ),
        .w_digit ( w_top_digit ),
        .w_gpio  ( w_gpio      )      // GPIO_0 [31], [33], [35] reserved for tm1638, GPIO_0[5:0] for mic
    )
    i_top
    (
        .clk      ( clk        ),
        .rst      ( rst        ),

        .key      ( top_key    ),
        .sw       ( top_sw     ),

        .led      ( top_led    ),

        .abcdefgh ( abcdefgh   ),
        .digit    ( top_digit  ),

        .vsync    ( vga_vs     ),
        .hsync    ( vga_hs     ),

        .red      ( vga_r      ),
        .green    ( vga_g      ),
        .blue     ( vga_b      ),

        .mic      ( mic        ),
        .gpio     ( GPIO_0     )
    );

    //------------------------------------------------------------------------

    // VGA out at GPIO_1
    assign GPIO_1 [14] = vga_vs;        // JP2 pin 19
    assign GPIO_1 [15] = vga_hs;        // JP2 pin 20
    // R
    assign GPIO_1 [29] = vga_r [0];     // JP2 pin 36
    assign GPIO_1 [27] = vga_r [1];     // JP2 pin 34
    assign GPIO_1 [25] = vga_r [2];     // JP2 pin 32
    assign GPIO_1 [23] = vga_r [3];     // JP2 pin 28
    // G
    assign GPIO_1 [28] = vga_g [0];     // JP2 pin 35
    assign GPIO_1 [26] = vga_g [1];     // JP2 pin 33
    assign GPIO_1 [24] = vga_g [2];     // JP2 pin 31
    assign GPIO_1 [22] = vga_g [3];     // JP2 pin 27
    // B
    assign GPIO_1 [21] = vga_b [0];     // JP2 pin 26
    assign GPIO_1 [20] = vga_b [1];     // JP2 pin 25
    assign GPIO_1 [18] = vga_b [2];     // JP2 pin 23
    assign GPIO_1 [16] = vga_b [3];     // JP2 pin 21

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

    `ifdef EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

        // Con: This makes blink the 7-segment LEDs of TM1638

        wire tm_static_hex;
        assign tm_static_hex = 'b0;
    `else
        wire tm_static_hex;
        assign tm_static_hex = 'b1;
    `endif

    //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .w_digit ( w_tm_digit )        // fake parameter, digit count is hardcode in tm1638_board_controller
    )
    i_ledkey
    (
        .clk        ( clk           ),
        .rst        ( rst           ), // Don't make reset tm1638_board_controller by it's tm_key
        .static_hex ( tm_static_hex ),
        .hgfedcba   ( hgfedcba      ),
        .digit      ( tm_digit      ),
        .ledr       ( tm_led        ),
        .keys       ( tm_key        ),
        .sio_stb    ( GPIO_0 [25]   ), // JP1 pin 32
        .sio_clk    ( GPIO_0 [27]   ), // JP1 pin 34
        .sio_data   ( GPIO_0 [29]   )  // JP1 pin 36
    );                                 // JP1 pin 30 - GND, pin 29 - VCC 3.3V

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .lr    ( GPIO_0 [2] ),  // JP1 pin 5
        .ws    ( GPIO_0 [4] ),  // JP1 pin 7
        .sck   ( GPIO_0 [6] ),  // JP1 pin 9
        .sd    ( GPIO_0 [7] ),  // JP1 pin 10
        .value ( mic        )
    );

    assign GPIO_0 [3] = 1'b0;   // GND - JP1 pin 6
    assign GPIO_0 [5] = 1'b1;   // VCC - JP1 pin 8

endmodule
