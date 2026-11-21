// "FPGA NIOS KIT Board Cyclone IV" by TodayStart, sold by BETTERSHENGSUN,
// with an INMP441 microphone and a WeAct PCM5100A or GY-PCM5102 I2S DAC
// on the 2 x 11 expansion header P4. See README.md in this directory.
//
// Every microphone and DAC signal goes to BOTH pins of one column of P4:
// the column with the silkscreen label "P142 P141" carries the DAC BCK
// on pin 142 and on pin 141, and so on. A wire can go to either pin of the
// column, so the instructions do not depend on which row of P4 holds which
// FPGA pin. The silkscreen gives the pairs but not the rows.

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
              w_gpio        = 0,

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

    // Header P4. Each signal has two pins, one in each row of a column.

    output [          1:0] DAC_BCK,   // P142 P141
    output [          1:0] DAC_DIN,   // P138 P137
    output [          1:0] DAC_LRCK,  // P136 P135

    input  [          1:0] MIC_SD,    // P133 P132, weak pull-ups
    output [          1:0] MIC_VDD,   // P129 P128, 3.3 V for the microphone
    output [          1:0] MIC_GND,   // P127 P126, GND and L/R
    output [          1:0] MIC_WS,    // P125 P124
    output [          1:0] MIC_SCK    // P121 P120
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

        .gpio          (                 )
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

    // The microphone gets its power from two FPGA pins, as on the other
    // boards of the repository: INMP441 needs 1.4 mA. The pins are driven
    // in every lab, so the supply can be checked with a multimeter.

    assign MIC_VDD = 2'b11;
    assign MIC_GND = 2'b00;  // Also L/R: low selects the left channel

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        wire mic_lr, mic_ws, mic_sck;

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz  )
        )
        i_microphone
        (
            .clk     ( clk      ),
            .rst     ( rst      ),
            .lr      ( mic_lr   ),  // Unused: L/R goes to the MIC_GND column
            .ws      ( mic_ws   ),
            .sck     ( mic_sck  ),

            // The microphone is on one pin of the column. The other pin
            // is open and reads 1 through its weak pull-up resistor.

            .sd      ( & MIC_SD ),
            .value   ( mic      )
        );

        assign MIC_SCK = { 2 { mic_sck } };
        assign MIC_WS  = { 2 { mic_ws  } };

    `else

        assign MIC_SCK = 2'b00;
        assign MIC_WS  = 2'b00;

    `endif

    //------------------------------------------------------------------------

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

        assign DAC_BCK  = { 2 { dac_bclk  } };
        assign DAC_LRCK = { 2 { dac_lrclk } };
        assign DAC_DIN  = { 2 { dac_sdata } };

    `else

        assign DAC_BCK  = 2'b00;
        assign DAC_LRCK = 2'b00;
        assign DAC_DIN  = 2'b00;

    `endif

endmodule
