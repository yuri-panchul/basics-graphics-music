// `define DUPLICATE_TM_SIGNALS_WITH_REGULAR
   `define CONCAT_REGULAR_SIGNALS_AND_TM
// `define CONCAT_TM_SIGNALS_AND_REGULAR

`ifndef DUPLICATE_TM_SIGNALS_WITH_REGULAR
    `define ADD_REGULAR_AND_TM_SIGNAL_WIDTH
`endif

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 2,
              w_sw    = 10,
              w_led   = 10,
              w_digit = 6,
              w_gpio  = 36
)
(
    input                   MAX10_CLK1_50,

    input  [w_key  - 1:0] KEY,
    input  [w_sw   - 1:0] SW,
    output [w_led  - 1:0] LEDR,

    output logic    [7:0] HEX0,
    output logic    [7:0] HEX1,
    output logic    [7:0] HEX2,
    output logic    [7:0] HEX3,
    output logic    [7:0] HEX4,
    output logic    [7:0] HEX5,

    output                VGA_HS,
    output                VGA_VS,
    output [         3:0] VGA_R,
    output [         3:0] VGA_G,
    output [         3:0] VGA_B,

    inout  [w_gpio - 1:0] GPIO
);

    //------------------------------------------------------------------------

    wire              clk = MAX10_CLK1_50;

    localparam w_top_sw = w_sw - 1;  // One sw is used as a reset

    wire                  rst = SW [w_sw - 1];
    wire [w_top_sw - 1:0] sw  = SW [w_top_sw - 1:0];

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [         23:0] mic;

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

    //------------------------------------------------------------------------

    `ifdef CONCAT_TM_SIGNALS_AND_REGULAR

        assign top_key = { tm_key, ~ KEY };

        assign { tm_led   , LEDR  } = top_led;
        assign { tm_digit , digit } = top_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM

        assign top_key = { ~ KEY, tm_key };

        assign { LEDR  , tm_led   } = top_led;
        assign { digit , tm_digit } = top_digit;

    `else  // DUPLICATE_TM_SIGNALS_WITH_REGULAR

        always_comb
        begin
            top_key = '0;

            top_key [w_key    - 1:0] |= ~ KEY;
            top_key [w_tm_key - 1:0] |= tm_key;
        end

        assign LEDR     = top_led   [w_led      - 1:0];
        assign tm_led   = top_led   [w_tm_led   - 1:0];

        assign digit    = top_digit [w_digit    - 1:0];
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
        .w_gpio  ( w_gpio      )
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

        .vsync    ( VGA_VS     ),
        .hsync    ( VGA_HS     ),

        .red      ( VGA_R      ),
        .green    ( VGA_G      ),
        .blue     ( VGA_B      ),

        .mic      ( mic        ),
        .gpio     ( GPIO       )
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

    always_ff @ (posedge clk)
    begin
        if (digit [0]) HEX0 <= ~ hgfedcba;
        if (digit [1]) HEX1 <= ~ hgfedcba;
        if (digit [2]) HEX2 <= ~ hgfedcba;
        if (digit [3]) HEX3 <= ~ hgfedcba;
        if (digit [4]) HEX4 <= ~ hgfedcba;
        if (digit [5]) HEX5 <= ~ hgfedcba;
    end

   //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .w_digit ( w_digit )
    )
    i_tm1638
    (
        .clk      ( clk       ),
        .rst      ( rst       ),
        .hgfedcba ( hgfedcba  ),
        .digit    ( tm_digit  ),
        .ledr     ( tm_led    ),
        .keys     ( tm_key    ),
        .sio_clk  ( GPIO [32] ),
        .sio_stb  ( GPIO [30] ),
        .sio_data ( GPIO [34] )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [5] ),
        .ws    ( GPIO [3] ),
        .sck   ( GPIO [1] ),
        .sd    ( GPIO [0] ),
        .value ( mic      )
    );

    assign GPIO [4] = 1'b0;  // GND
    assign GPIO [2] = 1'b1;  // VCC

endmodule
