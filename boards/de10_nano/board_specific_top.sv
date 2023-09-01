// Note that TM1638 display is not compatible with the labs/*_7segment_word
// that demonstrates the idea of a dynamic 7-segment display.

module board_specific_top
# (
    parameter clk_mhz  = 50,
              w_key    = 2,
              w_sw     = 4,
              w_led    = 8,
              w_gpio   = 36
)
(
    input                    FPGA_CLK1_50,

    input  [w_key     - 1:0] KEY,
    input  [w_sw      - 1:0] SW,
    output [w_led     - 1:0] LED,

    inout  [w_gpio    - 1:0] GPIO_0,
    inout  [w_gpio    - 1:0] GPIO_1
);

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_digit  = 8;

    localparam  w_top_sw = w_sw - 1;       // One onboard sw is used as a reset
    localparam w_ext_key = w_tm_key - 1;   // One tm1638 board key is used as a reset

    wire                     clk    = FPGA_CLK1_50;
    wire                     rst;

    wire [w_top_sw - 1:0]    top_sw = SW [w_top_sw - 1:0];

    wire [             7:0]  abcdefgh;
    wire [w_tm_digit - 1:0]  digit;

    wire [            23:0]  mic;

    wire                     tm1638_rst;
    wire [     w_ext_key:0]  tm1638_key;

    assign tm1638_rst = SW [w_top_sw] | ~ GPIO_1 [14]; // GPIO_1 [14] is BTN_RESET key on MiSTer I/O board
    assign rst = tm1638_key [w_ext_key] | tm1638_rst;

    //------------------------------------------------------------------------

    wire [w_ext_key   - 1:0] top_key;
    wire [w_led       - 1:0] top_led;
    wire                     vga_vs, vga_hs;
    wire [              3:0] vga_r, vga_g, vga_b;

    top
    # (
        .clk_mhz ( clk_mhz     ),
        .w_key   ( w_ext_key   ),
        .w_sw    ( w_sw        ),
        .w_led   ( w_led       ),
        .w_digit ( w_tm_digit     ),
        .w_gpio  ( w_gpio      )
    )
    i_top
    (
        .clk      ( clk         ),
        .rst      ( rst         ),

        .key      ( top_key     ),
        .sw       ( top_sw      ),

        .led      ( top_led     ),

        .abcdefgh ( abcdefgh    ),
        .digit    ( digit       ),

        .vsync    ( vga_vs      ),
        .hsync    ( vga_hs      ),

        .red      ( vga_r       ),
        .green    ( vga_g       ),
        .blue     ( vga_b       ),

        .mic      ( mic         ),
        .gpio     ( GPIO_0      )
    );

    // Use onboard and tm1638 keys
    assign top_key = { tm1638_key [w_ext_key - 1:w_key], tm1638_key [w_key - 1:0] | ~ KEY };

    // VGA out at GPIO_1 (MiSTer I/O board compatible, 4 bit color used)
    assign GPIO_1[16] = vga_vs;       // JP1 pin 19
    assign GPIO_1[17] = vga_hs;       // JP1 pin 20
    // R
    assign GPIO_1[35] = 1'b1;         // JP1 pin 40
    assign GPIO_1[33] = 1'b1;         // JP1 pin 38
    assign GPIO_1[31] = vga_r[0];     // JP1 pin 36
    assign GPIO_1[29] = vga_r[1];     // JP1 pin 34
    assign GPIO_1[27] = vga_r[2];     // JP1 pin 32
    assign GPIO_1[25] = vga_r[3];     // JP1 pin 28
    // G
    assign GPIO_1[34] = 1'b1;         // JP1 pin 39
    assign GPIO_1[32] = 1'b1;         // JP1 pin 37
    assign GPIO_1[30] = vga_g[0];     // JP1 pin 35
    assign GPIO_1[28] = vga_g[1];     // JP1 pin 33
    assign GPIO_1[26] = vga_g[2];     // JP1 pin 31
    assign GPIO_1[24] = vga_g[3];     // JP1 pin 27
    // B
    assign GPIO_1[19] = 1'b1;         // JP1 pin 22
    assign GPIO_1[21] = 1'b1;         // JP1 pin 24
    assign GPIO_1[23] = vga_b[0];     // JP1 pin 26
    assign GPIO_1[22] = vga_b[1];     // JP1 pin 25
    assign GPIO_1[20] = vga_g[2];     // JP1 pin 23
    assign GPIO_1[18] = vga_g[3];     // JP1 pin 21

    // LEDG onboard
    assign LED = top_led;

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
    i_ledkey
    (
        .clk      ( clk            ), // 50 MHz
        .rst      ( tm1638_rst     ), // Don't make reset tm1638_board_controller by tm1638_key
        .hgfedcba ( hgfedcba       ),
        .digit    ( digit          ),
        .ledr     ( top_led        ),
        .keys     ( tm1638_key     ), // S8 key reserved for reset
        .sio_clk  ( GPIO_0 [31]    ), // JP1 pin 36
        .sio_stb  ( GPIO_0 [33]    ), // JP1 pin 38
        .sio_data ( GPIO_0 [35]    )  // JP1 pin 40
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk           ),
        .rst   ( rst           ),
        .lr    ( GPIO_0 [5]    ),  // JP1 pin 6
        .ws    ( GPIO_0 [3]    ),  // JP1 pin 4
        .sck   ( GPIO_0 [1]    ),  // JP1 pin 2
        .sd    ( GPIO_0 [0]    ),  // JP1 pin 1
        .value ( mic           )
    );

    assign GPIO_0 [4] = 1'b0;      // GND - JP1 pin 5
    assign GPIO_0 [2] = 1'b1;      // VCC - JP1 pin 3

endmodule
