// "FPGA NIOS KIT Board Cyclone IV" by TodayStart, sold by BETTERSHENGSUN,
// with an INMP441 microphone and a WeAct PCM5100A or GY-PCM5102 I2S DAC
// on the 2 x 11 expansion header P4. See README.md in this directory.
//
// GPIO are the 16 FPGA pins of P4, in ascending order of the pins.
// Each column of P4 holds two consecutive GPIO, for example GPIO [15:14]
// is the column with the silkscreen label "P142 P141". The silkscreen
// gives the pairs but not which row holds which pin, so the microphone
// and the DAC use both pins of a column for each of their signals,
// and a wire can go to either pin of the column.

`include "config.svh"
`include "lab_specific_board_config.svh"

`define USE_INTERNALLY_WIDE_COLOR_CHANNELS

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 0,
              w_led         = 5,
              w_digit       = 4,
              w_gpio        = 16,

              screen_width  = 640,
              screen_height = 480,

              `ifdef USE_INTERNALLY_WIDE_COLOR_CHANNELS

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              `else

              w_red         = 1,
              w_green       = 1,
              w_blue        = 1,

              `endif

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                  CLK,

    input  [w_key   - 1:0] KEY_N,  // One key is used as a reset
    output [w_led   - 1:0] LED_N,

    output [          7:0] ABCDEFGH_N,
    output [w_digit - 1:0] DIGIT_N,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output                 VGA_R,
    output                 VGA_G,
    output                 VGA_B,

    inout  [w_gpio  - 1:0] GPIO    // Header P4
);

    //------------------------------------------------------------------------

    localparam w_lab_key = w_key - 1;  // One onboard key is used as a reset

    wire                   clk     = CLK;
    wire                   rst     = ~ KEY_N [w_key     - 1];
    wire [w_lab_key - 1:0] lab_key = ~ KEY_N [w_lab_key - 1:0];

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;

    // Seven-segment display

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    // Graphics

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    // Sound

    wire [         23:0] mic;
    wire [         15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz       ),

        .w_key         (   w_lab_key     ),
        .w_sw          (   w_lab_key     ),
        .w_led         (   w_led         ),
        .w_digit       (   w_digit       ),
        .w_gpio        (   w_gpio        ),

        .screen_width  (   screen_width  ),
        .screen_height (   screen_height ),

        .w_red         (   w_red         ),
        .w_green       (   w_green       ),
        .w_blue        (   w_blue        )
    )
    i_lab_top
    (
        .clk           (   clk           ),
        .slow_clk      (   slow_clk      ),
        .rst           (   rst           ),

        .key           (   lab_key       ),
        .sw            (   lab_key       ),

        .led           (   led           ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .uart_rx       (   1'b1          ),  // The UART pins are not known yet
        .uart_tx       (                 ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .gpio          (   GPIO          )
    );

    //------------------------------------------------------------------------

    assign LED_N      = ~ led;

    assign ABCDEFGH_N = ~ abcdefgh;
    assign DIGIT_N    = ~ digit;

    assign VGA_R      = display_on & ( | red   );
    assign VGA_G      = display_on & ( | green );
    assign VGA_B      = display_on & ( | blue  );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

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
            .hsync       ( VGA_HSYNC  ),
            .vsync       ( VGA_VSYNC  ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

    `else

        assign VGA_HSYNC  = 1'b0;
        assign VGA_VSYNC  = 1'b0;
        assign display_on = 1'b0;

    `endif

    //------------------------------------------------------------------------

    // The microphone uses GPIO [9:0], the five columns from "P133 P132"
    // to "P121 P120". Lab 3_12 also uses the microphone, and it drives
    // GPIO [15:14] for an LED strip.

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        wire mic_ws, mic_sck;

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz  )
        )
        i_microphone
        (
            .clk     ( clk      ),
            .rst     ( rst      ),
            .lr      (          ),  // The L/R pin goes to the GND column
            .ws      ( mic_ws   ),
            .sck     ( mic_sck  ),

            // The microphone is on one pin of the column. The other pin
            // is open and reads 1 through its weak pull-up resistor.

            .sd      ( & GPIO [9:8] ),  // P133 P132 : INMP441 SD
            .value   ( mic      )
        );

        // INMP441 needs 1.4 mA, so it takes its power from FPGA pins,
        // as on the other boards of the repository

        assign GPIO [7:6] = 2'b11;                // P129 P128 : VDD
        assign GPIO [5:4] = 2'b00;                // P127 P126 : GND and L/R,
                                                  // low selects the left channel
        assign GPIO [3:2] = { 2 { mic_ws  } };    // P125 P124 : WS
        assign GPIO [1:0] = { 2 { mic_sck } };    // P121 P120 : SCK

    `endif

    //------------------------------------------------------------------------

    // The DAC uses GPIO [15:10], the three columns from "P142 P141"
    // to "P136 P135". It takes its power from header JP2.

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        wire dac_bclk, dac_lrclk, dac_sdata;

        // MCLK is not used: WeAct pulls its MC pin low, the SCK pin
        // of GY-PCM5102 goes to GND, and PCM510x makes its own master clock

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz   )
        )
        inst_audio_out
        (
            .clk     ( clk       ),
            .reset   ( rst       ),
            .data_in ( sound     ),
            .mclk    (           ),
            .bclk    ( dac_bclk  ),
            .lrclk   ( dac_lrclk ),
            .sdata   ( dac_sdata )
        );

        assign GPIO [15:14] = { 2 { dac_bclk  } };  // P142 P141 : BCK
        assign GPIO [13:12] = { 2 { dac_sdata } };  // P138 P137 : DIN
        assign GPIO [11:10] = { 2 { dac_lrclk } };  // P136 P135 : WS, LCK

    `endif

endmodule
