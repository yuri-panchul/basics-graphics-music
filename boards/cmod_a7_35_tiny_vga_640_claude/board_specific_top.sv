`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

// This file is the top level of all six Cmod A7 configurations of Claude.
// The other five include it after defining one or two macros:
//
//   CMOD_A7_NO_PLL_SCREEN_WIDTH  304 or 320: no MMCM, see "VGA without
//       a clock multiplier" below. cmod_a7_35_no_pll_tiny_vga_304_claude
//       and cmod_a7_35_no_pll_tiny_vga_320_claude define it.
//
//   FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE: no TM1638. The two
//       buttons and the two LEDs of Cmod A7 are the keys and the LEDs of the
//       labs, and there is no seven-segment display, and DIP 12 to 14, the
//       pins of TM1638, are three more GPIO pins. The three configurations
//       with _no_tm1638 in the name define it.

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef  INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `define CMOD_A7_W_GPIO        37
`else
    `define CMOD_A7_W_GPIO        34
`endif

`ifdef CMOD_A7_NO_PLL_SCREEN_WIDTH
    `define CMOD_A7_CLK_MHZ       12
    `define CMOD_A7_PIXEL_MHZ     12
    `define CMOD_A7_SCREEN_WIDTH  `CMOD_A7_NO_PLL_SCREEN_WIDTH
`else
    `define CMOD_A7_CLK_MHZ       50
    `define CMOD_A7_PIXEL_MHZ     25
    `define CMOD_A7_SCREEN_WIDTH  640
`endif

// Digilent Cmod A7-35T on a breadboard with:
//
//   * TinyVGA in the Pmod socket JA, 2 bits per color;
//   * TM1638 module with 8 digits, 8 LEDs and 8 keys;
//   * INMP441 I2S microphone;
//   * I2S DAC module: WeAct I2S Earphone Module (PCM5100A)
//     or the usual purple GY-PCM5102 module (PCM5102A);
//   * 34 GPIO pins of the labs, 37 without TM1638: every digital DIP pin
//     that the modules above do not use.
//
// board_specific.xdc is Digilent's Cmod-A7-Master.xdc with only the used
// lines uncommented. It keeps Digilent's port names: sysclk, btn, led,
// led0_*, ja, pioNN, uart_*. This module maps them to the signals of
// TinyVGA, TM1638, the microphone and the DAC. pioNN is DIP pin NN.
// See boards/cmod_a7_35_tiny_vga_640_claude/README.md for the wiring.
//
// The clock. The Cmod A7 oscillator runs at 12 MHz. peripherals/vga.sv
// makes its 25 MHz pixel rate with a clock enable, so it needs a clock of
// 25 MHz or a multiple of it. Without CMOD_A7_NO_PLL_SCREEN_WIDTH the MMCM
// below makes 50 MHz from 12 MHz, the clock most boards of this repository
// run at, and the whole design uses it.
//
// VGA without a clock multiplier. 640x480 at 60 Hz needs a pixel clock of
// 25.175 MHz, which the 12 MHz oscillator cannot give without an MMCM or a
// PLL. With CMOD_A7_NO_PLL_SCREEN_WIDTH the 12 MHz oscillator is the clock
// of the whole design and the pixel clock as well, and a line is shorter:
//
//     304 visible + 8 front porch + 46 sync + 23 back porch = 381 clocks
//     320 visible + 8 front porch + 48 sync + 24 back porch = 400 clocks
//
// 381 clocks of 12 MHz last 31.75 us, as the 800 clocks of 25.175 MHz of a
// standard line, 31.78 us, and each part keeps its standard length: the
// sync pulse, for example, lasts 3.83 us against 3.81 us. 400 clocks is
// the horizontal timing of 640x480 at a 24 MHz pixel clock, with each
// pixel two pixels of 640 wide. The vertical timing is the standard one,
// 525 lines:
//
//     304: line 12 MHz / 381 = 31.50 kHz, frame 59.99 Hz  (standard 31.47 kHz, 59.94 Hz)
//     320: line 12 MHz / 400 = 30.0 kHz,  frame 57.1 Hz
//
// A monitor takes either for 640x480 and samples each line at its own 640
// points. Each of the 304 pixels covers 2.1 of them, so on a sharp pattern
// some pixels look 2 and some 3 points wide. The 320 pixels are exactly 2
// points wide, but 30 kHz is at the low end of what monitors accept: many
// show the picture, some report the mode as out of range.

module board_specific_top
# (
    parameter clk_mhz       = `CMOD_A7_CLK_MHZ,    // 50 from the MMCM or the 12 MHz oscillator
              pixel_mhz     = `CMOD_A7_PIXEL_MHZ,

              // Without TM1638 the two Cmod buttons are the keys
              // and also the switches

              w_key         = 2,
              w_sw          = 0,
              w_led         = 2,
              w_digit       = 0,
              w_gpio        = `CMOD_A7_W_GPIO,  // 34, or 37 without TM1638

              screen_width  = `CMOD_A7_SCREEN_WIDTH,
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

    inout                pio1,
    inout                pio2,
    inout                pio3,
    inout                pio4,
    inout                pio5,
    inout                pio6,
    inout                pio7,
    inout                pio8,
    inout                pio9,
    inout                pio10,
    inout                pio11,

    inout                pio12,         // TM1638 STB, CLK and DIO,
    inout                pio13,         // or GPIO pins without TM1638
    inout                pio14,

    output               pio17,         // INMP441 SCK, WS, L/R and SD
    output               pio18,
    output               pio19,
    input                pio20,

    output               pio21,         // DAC BCK, DIN and LCK
    output               pio22,
    output               pio23,

    inout                pio26,
    inout                pio27,
    inout                pio28,
    inout                pio29,
    inout                pio30,
    inout                pio31,
    inout                pio32,
    inout                pio33,
    inout                pio34,
    inout                pio35,
    inout                pio36,
    inout                pio37,
    inout                pio38,
    inout                pio39,
    inout                pio40,
    inout                pio41,
    inout                pio42,
    inout                pio43,
    inout                pio44,
    inout                pio45,
    inout                pio46,
    inout                pio47,
    inout                pio48
);

    //------------------------------------------------------------------------
    // The horizontal timing of VGA. 640 is the standard one, at 25 MHz
    // pixels from the 50 MHz clock; 304 and 320 are in 12 MHz clocks, see
    // the comment on top of this file. These values of 640 are the defaults
    // of peripherals/vga.sv.

    localparam h_front = screen_width == 640 ? 16 : 8,
               h_sync  = screen_width == 640 ? 96 : screen_width == 320 ? 48 : 46,
               h_back  = screen_width == 640 ? 48 : screen_width == 320 ? 24 : 23;

    `ifdef CMOD_A7_NO_PLL_SCREEN_WIDTH
        if (screen_width != 304 && screen_width != 320)
            $error ("CMOD_A7_NO_PLL_SCREEN_WIDTH must be 304 or 320");
    `endif

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

    // The GPIO pins of the labs are all the digital DIP pins that TM1638,
    // the microphone and the DAC do not use. They start at DIP 48 and run
    // down the side of DIP 48 to 26, then go on from DIP 1:
    //
    //     gpio [22: 0]  DIP 48 down to 26: gpio [0] is DIP 48
    //     gpio [33:23]  DIP  1 to 11:      gpio [23] is DIP 1
    //     gpio [36:34]  DIP 12 to 14, only without TM1638
    //
    // DIP 15 and 16 are analog inputs, and DIP 24 and 25 are VU and GND.
    // See the gpio port of lab_top below. The GPIO pins are inouts, as on
    // the other boards: a lab drives the ones it uses as outputs and reads
    // the rest.

    // All the modules are on the side of DIP 1 to 24, near its end with
    // VU, pin 24: TM1638 on DIP 12 to 14, the microphone on 17 to 20 and
    // the DAC on 21 to 23. The other side, DIP 26 to 48, is all GPIO.

    assign pio21  = DAC_BCK;    // DIP 21  BCK
    assign pio22  = DAC_DIN;    // DIP 22  DIN
    assign pio23  = DAC_LCK;    // DIP 23  LCK on GY-PCM5102, WS on WeAct

    assign pio17  = MIC_SCK;    // DIP 17  INMP441 SCK
    assign pio18  = MIC_WS;     // DIP 18  INMP441 WS
    assign pio19  = MIC_LR;     // DIP 19  INMP441 L/R
    assign MIC_SD = pio20;      // DIP 20  INMP441 SD

    // DIP 12 to 14 are STB, CLK and DIO, the order of these pins on the
    // TM1638 header. DIP 14, pio14, is DIO, an inout connected in the
    // tm1638_board_controller instance below. Without TM1638 the three
    // pins are gpio [34] to gpio [36].

    `ifndef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        assign pio12 = TM_STB;  // DIP 12  TM1638 STB
        assign pio13 = TM_CLK;  // DIP 13  TM1638 CLK
    `endif

    //------------------------------------------------------------------------
    // The clock of the design

    wire clk, locked;

    `ifdef CMOD_A7_NO_PLL_SCREEN_WIDTH

        // The 12 MHz oscillator is the clock of the whole design. Its pin,
        // L17, is a clock-capable pin, and Vivado puts a global clock buffer
        // on it. With no MMCM there is no lock to wait for.

        assign clk    = sysclk;
        assign locked = 1'b1;

    `else

        // 50 MHz clock from the 12 MHz oscillator:
        //
        //     VCO = 12 MHz * 62.5  = 750 MHz
        //     clk = 750 MHz / 15   =  50 MHz
        //
        // 750 MHz is inside the 600-1200 MHz VCO range of the MMCM in
        // Artix-7 speed grade -1, and the 12 MHz input is above its 10 MHz
        // minimum.

        wire clk_mmcm, clk_fb;

        MMCME2_BASE
        # (
            .CLKIN1_PERIOD    ( 83.333   ),
            .DIVCLK_DIVIDE    ( 1        ),
            .CLKFBOUT_MULT_F  ( 62.5     ),
            .CLKOUT0_DIVIDE_F ( 15.0     )
        )
        i_mmcm
        (
            .CLKIN1           ( sysclk   ),
            .CLKFBIN          ( clk_fb   ),
            .CLKFBOUT         ( clk_fb   ),
            .CLKFBOUTB        (          ),

            .CLKOUT0          ( clk_mmcm ),
            .CLKOUT0B         (          ),
            .CLKOUT1          (          ),
            .CLKOUT1B         (          ),
            .CLKOUT2          (          ),
            .CLKOUT2B         (          ),
            .CLKOUT3          (          ),
            .CLKOUT3B         (          ),
            .CLKOUT4          (          ),
            .CLKOUT5          (          ),
            .CLKOUT6          (          ),

            .LOCKED           ( locked   ),
            .PWRDWN           ( 1'b0     ),
            .RST              ( 1'b0     )
        );

        // A clock from an MMCM reaches the logic through a global clock buffer

        BUFG i_bufg (.I (clk_mmcm), .O (clk));

    `endif

    //------------------------------------------------------------------------
    // Reset. It is on after power-up until the MMCM locks; without the MMCM
    // the reset chain is all ones when the FPGA is configured, so the design
    // starts in reset all the same. With TM1638 the labs take their keys
    // from TM1638, and either Cmod button resets the design. Without TM1638
    // the two buttons are the keys of the labs.
    //
    // The reset comes on at once and goes off on the third clock edge
    // after its cause is gone.

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        wire reset_request = ~ locked | (| btn);
    `else
        wire reset_request = ~ locked;
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

    //------------------------------------------------------------------------

    // The Cmod LEDs show the first two LEDs of the labs,
    // TM1638 shows all eight

    assign led = lab_led [w_led - 1:0];

    // The RGB LED shows the state of the design: red in reset, green when
    // the design runs. At full brightness it dazzles, so it is lit 1/16 of
    // the time, at 12 MHz / 4096 = 2.9 kHz. The counter runs on the
    // oscillator, which runs while the MMCM is not locked as well.

    logic [11:0] rgb_dim_cnt = '0;

    always_ff @ (posedge sysclk)
        rgb_dim_cnt <= rgb_dim_cnt + 1'd1;

    wire rgb_dim_on = rgb_dim_cnt [11:8] == '0;

    assign led0_r = ~ (rgb_dim_on &   rst);  // 0 is on
    assign led0_g = ~ (rgb_dim_on & ~ rst);
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
    `ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        .gpio          ( { pio14, pio13, pio12,          // gpio [36:34]
                           pio11, pio10, pio9,  pio8,    // gpio [33:30]
                           pio7,  pio6,  pio5,  pio4,    // gpio [29:26]
                           pio3,  pio2,  pio1,           // gpio [25:23]
                           pio26, pio27, pio28, pio29,   // gpio [22:19]
                           pio30, pio31, pio32, pio33,   // gpio [18:15]
                           pio34, pio35, pio36, pio37,   // gpio [14:11]
                           pio38, pio39, pio40, pio41,   // gpio [10: 7]
                           pio42, pio43, pio44, pio45,   // gpio [ 6: 3]
                           pio46, pio47, pio48 } )       // gpio [ 2: 0]
    `else
        .gpio          ( { pio11, pio10, pio9,  pio8,    // gpio [33:30]
                           pio7,  pio6,  pio5,  pio4,    // gpio [29:26]
                           pio3,  pio2,  pio1,           // gpio [25:23]
                           pio26, pio27, pio28, pio29,   // gpio [22:19]
                           pio30, pio31, pio32, pio33,   // gpio [18:15]
                           pio34, pio35, pio36, pio37,   // gpio [14:11]
                           pio38, pio39, pio40, pio41,   // gpio [10: 7]
                           pio42, pio43, pio44, pio45,   // gpio [ 6: 3]
                           pio46, pio47, pio48 } )       // gpio [ 2: 0]
    `endif
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        // peripherals/tm1638_board.sv can split DIO into an input and an
        // output for boards that buffer it. Cmod A7 connects DIO straight
        // to an FPGA pin, so that mode does not apply here.

        `ifdef SPLIT_TM1638_DIO_INOUT_SIGNAL
            $error ("SPLIT_TM1638_DIO_INOUT_SIGNAL is not supported on Cmod A7: TM1638 DIO is the inout pin pio14");
        `endif

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
            .sio_data ( pio14      ),  // DIP 14  TM1638 DIO
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

        // With CLK_MHZ equal to PIXEL_MHZ, as without the MMCM, vga.sv moves
        // to the next pixel on every clock. Its vertical timing is the
        // standard one in all configurations.

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
            .clk         ( clk          ),
            .rst         ( rst          ),
            .hsync       ( VGA_HS       ),
            .vsync       ( VGA_VS       ),
            .display_on  ( display_on   ),
            .hpos        ( x10          ),
            .vpos        ( y10          ),
            .pixel_clk   (              )
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

        // The receiver makes SCK of clk / 16 and takes a sample every 1024
        // clocks: SCK of 3.125 MHz and 48.8 kHz at 50 MHz, SCK of 0.75 MHz
        // and 11.7 kHz at 12 MHz. Both SCK rates are within the 0.5 to
        // 3.2 MHz of INMP441.

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
        // then makes its own master clock from BCK. At 50 MHz BCK is
        // 50 MHz / 16 = 3.125 MHz and the sample rate 50 MHz / 1024 =
        // 48.8 kHz; at 12 MHz BCK is 12 MHz / 4 = 3 MHz and the sample rate
        // 12 MHz / 256 = 46.9 kHz.

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
