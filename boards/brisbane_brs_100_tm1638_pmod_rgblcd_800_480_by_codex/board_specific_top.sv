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
    input                      pad_clk_27Mhz,
    input  [2:1]               pad_user_buttons_n,
    output [6:1]               pad_leds_n,
    input                      pad_ser_rx,
    output                     pad_ser_tx,
    inout  [32:1]              pad_io,
    output                     pad_flash_clk,
    output                     pad_flash_csb,
    output                     pad_flash_mosi,
    input                      pad_flash_miso
);
    // Keep the manufacturer's port names and one-based GPIO numbering.
    // pad_io[1..16] is J5.1..16; pad_io[17..32] is J6.1..16.
    wire CLK = pad_clk_27Mhz;
    wire [w_key - 1:0] KEY = pad_user_buttons_n;
    wire [w_led - 1:0] LED;
    wire UART_RX = pad_ser_rx;
    wire UART_TX;
    assign pad_leds_n = LED;
    assign pad_ser_tx = UART_TX;

    // LCD RGB565: bit zero of each color goes to the lowest GPIO in its slice.
    wire [w_red - 1:0] LCD_R;
    wire [w_green - 1:0] LCD_G;
    wire [w_blue - 1:0] LCD_B;
    wire LCD_CLK, LCD_HS, LCD_VS, LCD_DE;
    assign pad_io [ 5: 1] = LCD_R;
    assign pad_io [11: 6] = LCD_G;
    assign pad_io [16:12] = LCD_B;
    assign pad_io [17] = LCD_CLK;
    assign pad_io [18] = LCD_HS;
    assign pad_io [19] = LCD_VS;
    assign pad_io [20] = LCD_DE;

    // TM1638 DIO connects directly to pad_io[21] below: preserve both directions.
    wire TM_CLK, TM_STB;
    assign pad_io [22] = TM_CLK;
    assign pad_io [23] = TM_STB;

    // INMP441: SD is an input; this wrapper must never drive pad_io[26].
    wire MIC_WS, MIC_SCK;
    wire MIC_SD = pad_io [26];
    assign pad_io [24] = MIC_WS;
    assign pad_io [25] = MIC_SCK;

    // PCM5102: all three serial signals are outputs.
    wire DAC_BCK, DAC_DIN, DAC_LRCK;
    assign pad_io [27] = DAC_BCK;
    assign pad_io [28] = DAC_DIN;
    assign pad_io [29] = DAC_LRCK;

    // The lab's three bidirectional GPIOs connect directly to pad_io[32:30]
    // below; lab gpio[0] is physical GPIO 30. Avoid one-way inout aliases.

    `ifdef BRS100_LAB_USES_PIXEL_CLOCK
        wire clk = pixel_clk;
    `else
        wire clk = CLK;
    `endif

    // The user flash and PSRAM are not used by this configuration.
    assign pad_flash_csb = 1'b1;
    assign pad_flash_clk = 1'b0;
    assign pad_flash_mosi = 1'b0;
    // pad_flash_miso remains an input; the inactive flash is never selected.

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
            .keys (lab_key), .sio_data (pad_io [21]),
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
        assign pad_io [21] = 1'bz;
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
            .gpio (pad_io [32:30])
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
            .mic (mic), .sound (sound), .gpio (pad_io [32:30])
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
