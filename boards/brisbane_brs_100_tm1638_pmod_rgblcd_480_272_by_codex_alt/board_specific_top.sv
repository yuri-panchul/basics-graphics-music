`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"
`include "brs100_config.svh"

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

module board_specific_top
# (
    parameter clk_mhz       = `BRS100_CLK_MHZ,
              w_key         = 2,
              w_led         = 6,
              w_gpio        = 3,
              screen_width  = `BRS100_WIDTH,
              screen_height = `BRS100_HEIGHT,
              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,
              w_x           = $clog2 (screen_width),
              w_y           = $clog2 (screen_height)
)
(
    input                      CLK,
    input  [w_key   - 1:0]      KEY,
    output [w_led   - 1:0]      LED,
    output                     LCD_CLK,
    output                     LCD_DE,
    output                     LCD_HS,
    output                     LCD_VS,
    output [w_red   - 1:0]      LCD_R,
    output [w_green - 1:0]      LCD_G,
    output [w_blue  - 1:0]      LCD_B,
    inout                      TM_DIO,
    output                     TM_CLK,
    output                     TM_STB,
    output                     MIC_WS,
    output                     MIC_SCK,
    input                      MIC_SD,
    output                     DAC_BCK,
    output                     DAC_DIN,
    output                     DAC_LRCK,
    input                      UART_RX,
    output                     UART_TX,
    inout  [w_gpio - 1:0]       GPIO,
    output                     FLASH_CSB
);
    `ifdef BRS100_LAB_USES_PIXEL_CLOCK
        wire clk = pixel_clk;
    `else
        wire clk = CLK;
    `endif

    // The user flash and PSRAM are not used by this configuration.
    assign FLASH_CSB = 1'b1;

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        localparam w_lab_key = 8, w_lab_led = 8, w_lab_digit = 8;
        wire reset_button = | (~ KEY);
    `else
        localparam w_lab_key = w_key, w_lab_led = w_led, w_lab_digit = 1;
        wire reset_button = 1'b0;
    `endif

    // Initial values map to Gowin power-up state. Hold reset for 64 clocks;
    // button assertion is asynchronous, but release is synchronized.
    logic [5:0] power_up = '1;
    logic [2:0] reset_pipe = '1;

    always_ff @ (posedge clk)
        if (power_up != 0)
            power_up <= power_up - 1'b1;

    wire reset_request = (power_up != 0) | reset_button | ~ pll_locked;

    always_ff @ (posedge clk or posedge reset_request)
        if (reset_request)
            reset_pipe <= '1;
        else
            reset_pipe <= { reset_pipe [1:0], 1'b0 };

    wire rst = reset_pipe [2];
    wire slow_clk;
    wire [w_lab_key   - 1:0] lab_key;
    wire [w_lab_led   - 1:0] lab_led;
    wire [w_lab_digit - 1:0] lab_digit;
    wire [7:0] abcdefgh;
    wire [w_x - 1:0] x;
    wire [w_y - 1:0] y;
    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;
    wire [23:0] mic;
    wire [15:0] sound;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    // LED[0] follows LED1 in the manufacturer's pinout/reference CST.
    assign LED = ~ w_led' (lab_led);

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        wire [7:0] hgfedcba;
        `SWAP_BITS (hgfedcba, abcdefgh);

        tm1638_board_controller # (.clk_mhz (clk_mhz), .w_digit (8))
        i_tm1638
        (
            .clk (clk), .rst (rst),
            .hgfedcba (hgfedcba), .digit (lab_digit), .ledr (lab_led),
            .keys (lab_key), .sio_data (TM_DIO),
            .sio_clk (TM_CLK), .sio_stb (TM_STB)
        );
    `else
        logic [w_key - 1:0] key_meta = '0, key_sync = '0;

        always_ff @ (posedge clk)
        begin
            key_meta <= ~ KEY;
            key_sync <= key_meta;
        end

        assign lab_key = key_sync;
        assign TM_DIO = 1'bz;
        assign TM_CLK = 1'b1;
        assign TM_STB = 1'b1;
    `endif

    `ifdef USE_HACKATHON_TOP
        hackathon_top i_hackathon_top
        (
            .clock (clk), .slow_clock (slow_clk), .reset (rst),
            .key (lab_key), .led (lab_led),
            .abcdefgh (abcdefgh), .digit (lab_digit),
            .x (x), .y (y), .red (red), .green (green), .blue (blue),
            .gpio (GPIO)
        );

        assign sound = '0;
        assign UART_TX = 1'b1;
    `else
        lab_top
        # (
            .clk_mhz (clk_mhz), .w_key (w_lab_key), .w_sw (w_lab_key),
            .w_led (w_lab_led), .w_digit (w_lab_digit), .w_gpio (w_gpio),
            .screen_width (screen_width), .screen_height (screen_height),
            .w_red (w_red), .w_green (w_green), .w_blue (w_blue)
        )
        i_lab_top
        (
            .clk (clk), .slow_clk (slow_clk), .rst (rst),
            .key (lab_key), .sw (lab_key), .led (lab_led),
            .abcdefgh (abcdefgh), .digit (lab_digit),
            .x (x), .y (y), .red (red), .green (green), .blue (blue),
            .uart_rx (UART_RX), .uart_tx (UART_TX),
            .mic (mic), .sound (sound), .gpio (GPIO)
        );
    `endif

    // This is the LCD configuration: keep its clock running even for a lab
    // without graphics. The SDC can then constrain the same clock in all labs.
    wire pixel_clk, pll_locked;
    brs100_pll i_lcd_pll
    (
        .clkin (CLK), .clkout (pixel_clk), .locked (pll_locked)
    );

    assign LCD_CLK = pixel_clk;

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        wire pixel_reset_request = rst | ~ pll_locked;
        logic [2:0] pixel_reset_pipe = '1;

        always_ff @ (negedge pixel_clk or posedge pixel_reset_request)
            if (pixel_reset_request)
                pixel_reset_pipe <= '1;
            else
                pixel_reset_pipe <= { pixel_reset_pipe [1:0], 1'b0 };

        brs100_lcd
        # (
            .screen_width (screen_width), .screen_height (screen_height),
            .w_red (w_red), .w_green (w_green), .w_blue (w_blue),
            .h_sync (`BRS100_H_SYNC), .h_back (`BRS100_H_BACK), .h_front (`BRS100_H_FRONT),
            .v_sync (`BRS100_V_SYNC), .v_back (`BRS100_V_BACK), .v_front (`BRS100_V_FRONT)
        )
        i_lcd
        (
            .pixel_clk (pixel_clk), .rst (pixel_reset_pipe [2]),
            .x (x), .y (y), .red (red), .green (green), .blue (blue),
            .lcd_de (LCD_DE), .lcd_hs (LCD_HS), .lcd_vs (LCD_VS),
            .lcd_r (LCD_R), .lcd_g (LCD_G), .lcd_b (LCD_B)
        );
    `else
        assign x = '0;
        assign y = '0;
        assign LCD_DE = 1'b0;
        assign LCD_HS = 1'b1;
        assign LCD_VS = 1'b1;
        assign LCD_R = '0;
        assign LCD_G = '0;
        assign LCD_B = '0;
    `endif

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
        inmp441_mic_i2s_receiver # (.clk_mhz (clk_mhz)) i_microphone
        (
            .clk (clk), .rst (rst), .lr (),
            .ws (MIC_WS), .sck (MIC_SCK), .sd (MIC_SD), .value (mic)
        );
    `else
        assign MIC_WS = 1'b0;
        assign MIC_SCK = 1'b0;
        assign mic = '0;
    `endif

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
        i2s_audio_out # (.clk_mhz (clk_mhz)) i_audio
        (
            .clk (clk), .reset (rst), .data_in (sound), .mclk (),
            .bclk (DAC_BCK), .sdata (DAC_DIN), .lrclk (DAC_LRCK)
        );
    `else
        assign DAC_BCK = 1'b0;
        assign DAC_DIN = 1'b0;
        assign DAC_LRCK = 1'b0;
    `endif
endmodule
