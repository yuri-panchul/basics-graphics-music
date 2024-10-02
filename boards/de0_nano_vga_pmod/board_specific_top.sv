`include "config.svh"
`include "lab_specific_board_config.svh"

`ifndef VGA666_BOARD
   `define PMOD_VGA_BOARD
`endif

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 2,
              w_sw          = 4,
              w_led         = 8,
              w_digit       = 0,
              w_gpio        = 34,  // GPIO_0 [31], [32], [33] reserved for tm1638
                                   // GPIO_0[5:0] reserved for mic,
                                   // no GPIO_x_IN because it's input only

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                     CLOCK_50,

    input  [w_key      - 1:0] KEY,
    input  [w_sw       - 1:0] SW,
    output [w_led      - 1:0] LED,

    inout  [w_gpio     - 1:0] GPIO_0,
    inout  [w_gpio     - 1:0] GPIO_1
);

    //------------------------------------------------------------------------

    localparam w_lab_sw = w_sw - 1;  // One onboard SW is used as a reset

    //------------------------------------------------------------------------

    wire                  clk    = CLOCK_50;

    wire                  rst    = SW [w_lab_sw];
    wire [w_lab_sw - 1:0] lab_sw = SW [w_lab_sw - 1:0];

    //------------------------------------------------------------------------

    // A dynamic seven-segment display

    wire [7:0] abcdefgh;

    // Graphics

    wire                  display_on;

    wire [w_x      - 1:0] x;
    wire [w_y      - 1:0] y;

    wire [w_red    - 1:0] red;
    wire [w_green  - 1:0] green;
    wire [w_blue   - 1:0] blue;

    // Microphone and sound output

    wire [          23:0] mic;
    wire [          15:0] sound;

    // FIXME: Should be assigned to some GPIO!
    wire                  UART_TX;
    wire                  UART_RX = '1;

    //------------------------------------------------------------------------

    localparam w_tm_key     = 8,
               w_tm_led     = 8,
               w_tm_digit   = 8;

    //------------------------------------------------------------------------

    `ifdef DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        localparam w_lab_key   = w_tm_key   > w_key   ? w_tm_key   : w_key   ,
                   w_lab_led   = w_tm_led   > w_led   ? w_tm_led   : w_led   ,
                   w_lab_digit = w_tm_digit > w_digit ? w_tm_digit : w_digit ;

    `else  // Concatenate the signals

        localparam w_lab_key   = w_tm_key   + w_key   ,
                   w_lab_led   = w_tm_led   + w_led   ,
                   w_lab_digit = w_tm_digit + w_digit ;
    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    //------------------------------------------------------------------------

    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR

        assign lab_key = { tm_key, ~ KEY };

        assign { tm_led   , LED   } = lab_led;
        assign             tm_digit = lab_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638

        assign lab_key = { ~ KEY, tm_key };

        assign { LED   , tm_led   } = lab_led;
        assign             tm_digit = lab_digit;

    `else  // DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        always_comb
        begin
            lab_key = '0;

            lab_key [w_key    - 1:0] |= ~ KEY;
            lab_key [w_tm_key - 1:0] |= tm_key;
        end

        assign LED      = lab_led   [w_led      - 1:0];
        assign tm_led   = lab_led   [w_tm_led   - 1:0];

        assign tm_digit = lab_digit [w_tm_digit - 1:0];

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),
        .w_key         ( w_lab_key     ),
        .w_sw          ( w_lab_sw      ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
        .w_gpio        ( w_gpio        ),  // GPIO_0 [31], [33], [35]
                                           // reserved for tm1638,
                                           // GPIO_0[5:0] for mic
        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_sw        ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),

        .gpio          ( GPIO_0        )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire vga_vs, vga_hs;

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz    ),
            .PIXEL_MHZ   ( pixel_mhz  )
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( vga_hs     ),
            .vsync       ( vga_vs     ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );


        //--------------------------------------------------------------------

        logic [3:0] reg_vga_r, reg_vga_g, reg_vga_b;
        logic       reg_vga_vs, reg_vga_hs;

        // Registers to remove the noise from combinational logic (glitches)

        always_ff @ (posedge clk or posedge rst)
        begin
            if (rst)
            begin
                reg_vga_r  <= '0;
                reg_vga_g  <= '0;
                reg_vga_b  <= '0;
                reg_vga_vs <= '0;
                reg_vga_hs <= '0;
            end
            else
            begin
                reg_vga_r  <= display_on ? red   : '0;
                reg_vga_g  <= display_on ? green : '0;
                reg_vga_b  <= display_on ? blue  : '0;
                reg_vga_vs <= vga_vs;
                reg_vga_hs <= vga_hs;
            end
        end

        // External VGA out at GPIO_1

        `ifdef  VGA666_BOARD

            // 4 bit color used
            assign GPIO_1 [33] = reg_vga_vs;        // vga666_pi_Vsync - JP2 pin 40
            assign GPIO_1 [31] = reg_vga_hs;        // vga666_pi_Hsync - JP2 pin 38
            // R
            assign GPIO_1 [11] = reg_vga_r [0];     // vga666_red[4]   - JP2 pin 16
            assign GPIO_1 [17] = reg_vga_r [1];     // vga666_red[5]   - JP2 pin 22
            assign GPIO_1 [ 3] = reg_vga_r [2];     // vga666_red[6]   - JP2 pin 6
            assign GPIO_1 [ 1] = reg_vga_r [3];     // vga666_red[7]   - JP2 pin 4
            // G
            assign GPIO_1 [ 5] = reg_vga_g [0];     // vga666_green[4] - JP2 pin 8
            assign GPIO_1 [19] = reg_vga_g [1];     // vga666_green[5] - JP2 pin 24
            assign GPIO_1 [15] = reg_vga_g [2];     // vga666_green[6] - JP2 pin 20
            assign GPIO_1 [13] = reg_vga_g [3];     // vga666_green[7] - JP2 pin 18
            // B
            assign GPIO_1 [21] = reg_vga_b [0];     // vga666_blue[4]  - JP2 pin 26
            assign GPIO_1 [ 7] = reg_vga_b [1];     // vga666_blue[5]  - JP2 pin 10
            assign GPIO_1 [ 9] = reg_vga_b [2];     // vga666_blue[6]  - JP2 pin 14
            assign GPIO_1 [23] = reg_vga_b [3];     // vga666_blue[7]  - JP2 pin 28
                                                    // vga666_GND      - JP2 pin 30

        `elsif PMOD_VGA_BOARD

            assign GPIO_1 [ 5] = reg_vga_vs;        // JP2 pin  8
            assign GPIO_1 [ 3] = reg_vga_hs;        // JP2 pin  6
            // R
            assign GPIO_1 [33] = reg_vga_r [0];     // JP2 pin 40
            assign GPIO_1 [31] = reg_vga_r [1];     // JP2 pin 38
            assign GPIO_1 [29] = reg_vga_r [2];     // JP2 pin 36
            assign GPIO_1 [27] = reg_vga_r [3];     // JP2 pin 34
            // G
            assign GPIO_1 [23] = reg_vga_g [0];     // JP2 pin 28
            assign GPIO_1 [21] = reg_vga_g [1];     // JP2 pin 26
            assign GPIO_1 [19] = reg_vga_g [2];     // JP2 pin 24
            assign GPIO_1 [17] = reg_vga_g [3];     // JP2 pin 22
            // B
            assign GPIO_1 [15] = reg_vga_b [0];     // JP2 pin 20
            assign GPIO_1 [13] = reg_vga_b [1];     // JP2 pin 18
            assign GPIO_1 [11] = reg_vga_b [2];     // JP2 pin 16
            assign GPIO_1 [ 9] = reg_vga_b [3];     // JP2 pin 14
                                                    // GND  - JP2 pin 30
                                                    // 3.3V - JP2 pin 29

        `endif

    `endif

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

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz   ( clk_mhz     )
        )
        i_ledkey
        (
            .clk       ( clk         ),
            .rst       ( rst         ),  // Don't make reset tm1638_board_controller by it's tm_key
            .hgfedcba  ( hgfedcba    ),
            .digit     ( tm_digit    ),
            .ledr      ( tm_led      ),
            .keys      ( tm_key      ),
            .sio_stb   ( GPIO_0 [25] ),  // JP1 pin 32
            .sio_clk   ( GPIO_0 [27] ),  // JP1 pin 34
            .sio_data  ( GPIO_0 [29] )   // JP1 pin 36
        );                               // JP1 pin 30 - GND, pin 29 - VCC 3.3V

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz    )
        )
        i_microphone
        (
            .clk     ( clk        ),
            .rst     ( rst        ),
            .lr      ( GPIO_0 [2] ),  // JP1 pin 5
            .ws      ( GPIO_0 [4] ),  // JP1 pin 7
            .sck     ( GPIO_0 [6] ),  // JP1 pin 9
            .sd      ( GPIO_0 [7] ),  // JP1 pin 10
            .value   ( mic        )
        );

        assign GPIO_0 [3] = 1'b0;   // GND - JP1 pin 6
        assign GPIO_0 [5] = 1'b1;   // VCC - JP1 pin 8

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz     )
        )
        inst_audio_out
        (
            .clk     ( clk         ),
            .reset   ( rst         ),
            .data_in ( sound       ),
            .mclk    ( GPIO_1 [30] ),  // JP2 pin 37
            .bclk    ( GPIO_1 [28] ),  // JP2 pin 35
            .lrclk   ( GPIO_1 [24] ),  // JP2 pin 31
            .sdata   ( GPIO_1 [26] )   // JP2 pin 33
        );                             // JP2 pin 12 - GND, pin 29 - VCC 3.3V (30-45 mA)

    `endif

endmodule
