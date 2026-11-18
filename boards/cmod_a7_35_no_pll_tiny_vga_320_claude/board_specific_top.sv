`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

// A board configuration named like this one with _no_tm1638 before _claude
// defines the macro below and includes this file. The design then has no
// TM1638: the two buttons and the two LEDs of Cmod A7 are the keys and the
// LEDs of the labs, and there is no seven-segment display.

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

// Digilent Cmod A7-35T on a breadboard, with the hardware and the wiring of
// boards/cmod_a7_35_claude_tiny_vga_640, but without the MMCM: the whole
// design runs on the 12 MHz oscillator. See README.md. The breadboard holds:
//
//   * TinyVGA in the Pmod socket JA, 2 bits per color;
//   * TM1638 module with 8 digits, 8 LEDs and 8 keys;
//   * INMP441 I2S microphone;
//   * I2S DAC module: WeAct I2S Earphone Module (PCM5100A)
//     or the usual purple GY-PCM5102 module (PCM5102A).
//
// board_specific.xdc is Digilent's Cmod-A7-Master.xdc with only the used
// lines uncommented. It keeps Digilent's port names: sysclk, btn, led,
// led0_*, ja, pioNN, uart_*. This module maps them to the signals of
// TinyVGA, TM1638, the microphone and the DAC. pioNN is DIP pin NN.
// See README.md for the wiring.
//
// VGA without a clock multiplier. 640x480 at 60 Hz needs a pixel clock of
// 25.175 MHz, which the 12 MHz oscillator cannot give without an MMCM or a
// PLL. Here the pixel clock is the 12 MHz oscillator itself, and a line
// takes 400 clocks instead of 800:
//
//     320 visible + 8 front porch + 48 sync + 24 back porch = 400 clocks
//
// This is the horizontal timing of 640x480 at a 24 MHz pixel clock, with
// each pixel two pixels of 640 wide. The vertical timing is the standard
// one, 525 lines:
//
//     line   12 MHz / 400  = 30.0 kHz    (standard 31.47 kHz)
//     frame  30 kHz / 525  = 57.1 Hz     (standard 59.94 Hz)
//
// 30 kHz is at the low end of what monitors accept: many show the picture,
// some report the mode as out of range.
// boards/cmod_a7_35_no_pll_tiny_vga_304_claude has a timing closer to the
// standard one.

module board_specific_top
# (
    parameter clk_mhz       = 12,  // The oscillator, no MMCM
              pixel_mhz     = 12,  // One pixel per clock

              // Without TM1638 the two Cmod buttons are the keys
              // and also the switches

              w_key         = 2,
              w_sw          = 0,
              w_led         = 2,
              w_digit       = 0,
              w_gpio        = 1,   // No GPIO pins, a dummy one for the labs

              screen_width  = 320,
              screen_height = 480,

              w_red         = 2,   // TinyVGA has 2 bits per color
              w_green       = 2,
              w_blue        = 2,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                sysclk,        // 12 MHz

    input  [w_key - 1:0] btn,           // Pressed is 1
    output [w_led - 1:0] led,           // 1 is on

    output               led0_b,        // RGB LED, 0 is on
    output               led0_g,
    output               led0_r,

    output [        7:0] ja,            // Pmod JA with TinyVGA

    input                uart_txd_in,   // From the computer to the FPGA
    output               uart_rxd_out,  // From the FPGA to the computer

    // DIP pins, see the pin mapping below

    output               pio21,
    output               pio22,
    output               pio23,

    output               pio26,
    output               pio27,
    inout                pio28,

    output               pio29,
    output               pio30,
    output               pio31,
    input                pio32
);

    //------------------------------------------------------------------------
    // Pin mapping

    wire [w_red   - 1:0] VGA_R;
    wire [w_green - 1:0] VGA_G;
    wire [w_blue  - 1:0] VGA_B;
    wire                 VGA_HS;
    wire                 VGA_VS;

    wire                 DAC_BCK;
    wire                 DAC_DIN;
    wire                 DAC_LCK;

    wire                 TM_CLK;
    wire                 TM_STB;

    wire                 MIC_SCK;
    wire                 MIC_WS;
    wire                 MIC_LR;
    wire                 MIC_SD;

    // TinyVGA: Pmod pins 1 to 4 are R1, G1, B1 and VS,
    // Pmod pins 7 to 10 are R0, G0, B0 and HS.
    // ja [0] to ja [3] are Pmod pins 1 to 4,
    // ja [4] to ja [7] are Pmod pins 7 to 10.

    assign ja [0] = VGA_R [1];  // Pmod pin 1
    assign ja [1] = VGA_G [1];  // Pmod pin 2
    assign ja [2] = VGA_B [1];  // Pmod pin 3
    assign ja [3] = VGA_VS;     // Pmod pin 4
    assign ja [4] = VGA_R [0];  // Pmod pin 7
    assign ja [5] = VGA_G [0];  // Pmod pin 8
    assign ja [6] = VGA_B [0];  // Pmod pin 9
    assign ja [7] = VGA_HS;     // Pmod pin 10

    // The DAC is on the DIP pins next to VU, pin 24

    assign pio21  = DAC_BCK;    // DIP 21  BCK
    assign pio22  = DAC_DIN;    // DIP 22  DIN
    assign pio23  = DAC_LCK;    // DIP 23  LCK on GY-PCM5102, WS on WeAct

    // TM1638 and the microphone are on the DIP pins next to GND, pin 25.
    // DIP pins 25 to 28 are GND, STB, CLK and DIO, the order of the pins
    // GND, STB, CLK and DIO on the TM1638 header. DIP 28, pio28, is DIO,
    // an inout connected in the tm1638_board_controller instance below.

    assign pio26  = TM_STB;     // DIP 26  TM1638 STB
    assign pio27  = TM_CLK;     // DIP 27  TM1638 CLK

    assign pio29  = MIC_SCK;    // DIP 29  INMP441 SCK
    assign pio30  = MIC_WS;     // DIP 30  INMP441 WS
    assign pio31  = MIC_LR;     // DIP 31  INMP441 L/R
    assign MIC_SD = pio32;      // DIP 32  INMP441 SD

    //------------------------------------------------------------------------
    // The 12 MHz oscillator is the clock of the whole design. Its pin, L17,
    // is a clock-capable pin, and Vivado puts a global clock buffer on it.

    wire clk = sysclk;

    // The horizontal timing of VGA in 12 MHz clocks, 400 clocks a line.
    // See the comment on top of this file.

    localparam h_front = 8,
               h_sync  = 48,
               h_back  = 24;

    //------------------------------------------------------------------------
    // Reset. With no MMCM there is no lock to wait for: the reset chain is
    // all ones when the FPGA is configured, so the design starts in reset
    // and leaves it on the third clock edge. With TM1638 the labs take their
    // keys from TM1638, and either Cmod button resets the design. Without
    // TM1638 the two buttons are the keys of the labs.
    //
    // A button reset comes on at once and goes off on the third clock edge
    // after the button is released.

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        wire reset_request = | btn;
    `else
        wire reset_request = 1'b0;
    `endif

    (* ASYNC_REG = "TRUE" *)
    logic [2:0] reset_chain = '1;

    always_ff @ (posedge clk or posedge reset_request)
        if (reset_request)
            reset_chain <= '1;
        else
            reset_chain <= { reset_chain [1:0], 1'b0 };

    wire rst = reset_chain [2];

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else  // TM1638 module is not connected

        // A dummy seven-segment digit
        // avoids errors in the labs with a seven-segment display

        localparam w_lab_key   = w_key,
                   w_lab_led   = w_led,
                   w_lab_digit = 1;

    `endif

    //------------------------------------------------------------------------

    wire  [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] red;
    wire  [w_green     - 1:0] green;
    wire  [w_blue      - 1:0] blue;

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    wire  [w_gpio      - 1:0] gpio_unused;

    //------------------------------------------------------------------------

    // The Cmod LEDs show the first two LEDs of the labs,
    // TM1638 shows all eight

    assign led = lab_led [w_led - 1:0];

    // The RGB LED is not used. Driving its pins high keeps it dark:
    // the default pull-downs of unused pins would make it glow.

    assign led0_r = 1'b1;
    assign led0_g = 1'b1;
    assign led0_b = 1'b1;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_lab_key     ),
        .w_sw          ( w_lab_key     ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
        .w_gpio        ( w_gpio        ),

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
        .sw            ( lab_key       ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

        .uart_rx       ( uart_txd_in   ),
        .uart_tx       ( uart_rxd_out  ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          ( gpio_unused   )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        wire [w_tm_key - 1:0] tm_key;

        assign lab_key = tm_key;

        wire [$left (abcdefgh):0] hgfedcba;
        `SWAP_BITS (hgfedcba, abcdefgh);

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz    ),
            .w_digit  ( w_tm_digit )
        )
        i_tm1638
        (
            .clk      ( clk        ),
            .rst      ( rst        ),
            .hgfedcba ( hgfedcba   ),
            .digit    ( lab_digit  ),
            .ledr     ( lab_led    ),
            .keys     ( tm_key     ),
            .sio_data ( pio28      ),  // DIP 28  TM1638 DIO
            .sio_clk  ( TM_CLK     ),
            .sio_stb  ( TM_STB     )
        );

    `else

        assign lab_key = btn;

        assign TM_CLK  = 1'b1;
        assign TM_STB  = 1'b1;  // TM1638 is not selected

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire       display_on;
        wire [9:0] x10;
        wire [9:0] y10;

        assign x = w_x' (x10);
        assign y = w_y' (y10);

        // With CLK_MHZ equal to PIXEL_MHZ, vga.sv moves to the next pixel
        // on every clock. Its vertical timing stays the standard one.

        vga
        # (
            .H_DISPLAY   ( screen_width ),
            .H_FRONT     ( h_front      ),
            .H_SYNC      ( h_sync       ),
            .H_BACK      ( h_back       ),

            .CLK_MHZ     ( clk_mhz      ),
            .PIXEL_MHZ   ( pixel_mhz    )
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( VGA_HS     ),
            .vsync       ( VGA_VS     ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

        // A monitor expects black outside the visible area

        assign VGA_R = display_on ? red   : '0;
        assign VGA_G = display_on ? green : '0;
        assign VGA_B = display_on ? blue  : '0;

    `else

        assign x      = '0;
        assign y      = '0;

        assign VGA_R  = '0;
        assign VGA_G  = '0;
        assign VGA_B  = '0;
        assign VGA_HS = 1'b1;
        assign VGA_VS = 1'b1;

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        // At 12 MHz the receiver makes SCK of 12 MHz / 16 = 0.75 MHz, within
        // the 0.5 to 3.2 MHz of INMP441, and samples at 12 MHz / 1024 =
        // 11.7 kHz, against 48.8 kHz at 50 MHz.

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz  ( clk_mhz )
        )
        i_microphone
        (
            .clk      ( clk     ),
            .rst      ( rst     ),
            .lr       ( MIC_LR  ),
            .ws       ( MIC_WS  ),
            .sck      ( MIC_SCK ),
            .sd       ( MIC_SD  ),
            .value    ( mic     )
        );

    `else

        assign mic     = '0;

        assign MIC_LR  = 1'b0;
        assign MIC_WS  = 1'b0;
        assign MIC_SCK = 1'b0;

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        // The master clock output stays unconnected. Connect SCK of
        // GY-PCM5102 to GND and leave MC of WeAct unconnected: the DAC
        // then makes its own master clock from BCK. At 12 MHz BCK is
        // 3 MHz and the sample rate 12 MHz / 256 = 46.9 kHz.

        i2s_audio_out
        # (
            .clk_mhz  ( clk_mhz )
        )
        i_audio_out
        (
            .clk      ( clk     ),
            .reset    ( rst     ),
            .data_in  ( sound   ),
            .mclk     (         ),
            .bclk     ( DAC_BCK ),
            .sdata    ( DAC_DIN ),
            .lrclk    ( DAC_LCK )
        );

    `else

        assign DAC_BCK = 1'b0;
        assign DAC_DIN = 1'b0;
        assign DAC_LCK = 1'b0;

    `endif

endmodule
