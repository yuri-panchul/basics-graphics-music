`include "config.svh"
`include "lab_specific_board_config.svh"

// Adapted from de23_lite. Pin assignments and I/O levels are DE25-Nano specific.
// External GPIO accessories are opt-in; see README.md in this directory.
module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,
              w_key         = 2,
              w_sw          = 4,
              w_led         = 8,
              w_digit       = 8,  // Logical digits; no onboard seven-segment display.
              w_gpio        = 36,
              screen_width  = 640,
              screen_height = 480,
              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,
              w_x           = $clog2 (screen_width),
              w_y           = $clog2 (screen_height)
)
(
    input                    CLOCK1_50,
    input  [w_key   - 1:0]    KEY,
    input  [w_sw    - 1:0]    SW,
    output [w_led   - 1:0]    LEDR,

    output                   HDMI_I2S0,
    output                   HDMI_LRCLK,
    output                   HDMI_MCLK,
    output                   HDMI_SCLK,
    output                   HDMI_TX_CLK,
    output                   HDMI_TX_DE,
    output [          23:0]   HDMI_TX_D,
    output                   HDMI_TX_HS,
    input                    HDMI_TX_INT,
    output                   HDMI_TX_VS,
    output                   I2C_SCL,
    inout                    I2C_SDA,

    inout  [w_gpio  - 1:0]    GPIO_0,
    inout  [w_gpio  - 1:0]    GPIO_1
);

    localparam w_lab_sw = w_sw - 1;

    wire clk = CLOCK1_50;
    wire ninit_done;

    `ifdef INTEL_VERSION
        // Required on Agilex 5, including designs that do not use the HPS.
        // Quartus generates the board's Reset Release IP during compilation.
        agilex_reset_release i_reset_release (.ninit_done (ninit_done));
    `else
        // Portable RTL simulation has no device configuration phase.
        assign ninit_done = 1'b0;
    `endif

    wire reset_request = ninit_done | SW [w_lab_sw];
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] reset_pipe = '1;

    // Assert immediately; release only after two edges of the 50 MHz clock.
    always_ff @ (posedge clk or posedge reset_request)
        if (reset_request)
            reset_pipe <= '1;
        else
            reset_pipe <= { reset_pipe [0], 1'b0 };

    wire rst = reset_pipe [1];

    // Unlike DE23-Lite, all eight LEDs are available to the lab.
    // Both the physical buttons and the physical LEDs are active-low.
    wire [w_lab_sw - 1:0] lab_sw = SW [w_lab_sw - 1:0];
    wire [w_key    - 1:0] board_key = ~KEY;
    wire [w_led    - 1:0] lab_led;
    assign LEDR = ~lab_led;

    `ifdef DE25_NANO_USE_TM1638
        localparam w_lab_key = 8;
        wire [7:0] tm_key;
        wire [w_lab_key - 1:0] lab_key = tm_key | w_lab_key' (board_key);
    `else
        localparam w_lab_key = w_key;
        wire [w_lab_key - 1:0] lab_key = board_key;
    `endif

    // A positive digit count keeps the common lab interface well-formed,
    // including labs that use $clog2(w_digit). Outputs are unused without TM1638.
    wire [7:0] abcdefgh;
    wire [w_digit - 1:0] digit;
    wire [w_x - 1:0] x;
    wire [w_y - 1:0] y;
    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;
    wire [23:0] mic;
    wire [15:0] sound;
    wire uart_rx, uart_tx;
    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    lab_top
    # (
        .clk_mhz       (clk_mhz),
        .w_key         (w_lab_key),
        .w_sw          (w_lab_sw),
        .w_led         (w_led),
        .w_digit       (w_digit),
        .w_gpio        (w_gpio),
        .screen_width  (screen_width),
        .screen_height (screen_height),
        .w_red         (w_red),
        .w_green       (w_green),
        .w_blue        (w_blue)
    )
    i_lab_top
    (
        .clk       (clk),
        .slow_clk  (slow_clk),
        .rst       (rst),
        .key       (lab_key),
        .sw        (lab_sw),
        .led       (lab_led),
        .abcdefgh  (abcdefgh),
        .digit     (digit),
        .x         (x),
        .y         (y),
        .red       (red),
        .green     (green),
        .blue      (blue),
        .mic       (mic),
        .sound     (sound),
        .uart_rx   (uart_rx),
        .uart_tx   (uart_tx),
        .gpio      (GPIO_1)
    );

    // HDMI video uses the same ADV7513 configuration as DE23-Lite.
    // HDMI audio is disabled; the optional external audio interface is on GPIO_0.
    assign { HDMI_I2S0, HDMI_LRCLK, HDMI_MCLK, HDMI_SCLK } = '0;

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        wire pixel_clk, display_on, hs, vs;
        // Timing counters include the blanking intervals. The lab coordinates
        // cover only visible pixels (480 lines fit in 9 bits; 525 do not).
        localparam w_video_x = $clog2 (screen_width + 160),
                   w_video_y = $clog2 (screen_height + 45);
        wire [w_video_x - 1:0] video_x;
        wire [w_video_y - 1:0] video_y;
        assign x = w_x' (video_x);
        assign y = w_y' (video_y);

        vga
        # (
            .HPOS_WIDTH (w_video_x),
            .VPOS_WIDTH (w_video_y),
            .H_DISPLAY  (screen_width),
            .V_DISPLAY  (screen_height),
            .CLK_MHZ    (clk_mhz),
            .PIXEL_MHZ  (pixel_mhz)
        )
        i_vga
        (
            .clk        (clk),
            .rst        (rst),
            .hsync      (hs),
            .vsync      (vs),
            .display_on (display_on),
            .hpos       (video_x),
            .vpos       (video_y),
            .pixel_clk  (pixel_clk)
        );

        assign HDMI_TX_CLK = pixel_clk;
        assign HDMI_TX_D   = { red,   {(8 - w_red)   {1'b0}},
                               green, {(8 - w_green) {1'b0}},
                               blue,  {(8 - w_blue)  {1'b0}} };
        assign HDMI_TX_DE = display_on;
        assign HDMI_TX_HS = hs;
        assign HDMI_TX_VS = vs;

        I2C_HDMI_Config # (.CLK_Freq (clk_mhz * 1000000))
        i_i2c_hdmi_conf
        (
            .iCLK        (clk),
            .iRST_N      (~rst),
            .I2C_SCLK    (I2C_SCL),
            .I2C_SDAT    (I2C_SDA),
            .HDMI_TX_INT (HDMI_TX_INT),
            .READY       ()
        );
    `else
        assign x = '0;
        assign y = '0;
        assign { HDMI_TX_CLK, HDMI_TX_DE, HDMI_TX_D, HDMI_TX_HS, HDMI_TX_VS } = '0;
        assign I2C_SCL = 1'b1;
        assign I2C_SDA = 1'bz;
    `endif

    // GPIO_1 is reserved for lab_top; accessories use only GPIO_0.
    // Power accessories from the header's supply/GND pins, never from FPGA I/O.
    `ifdef DE25_NANO_USE_TM1638
        wire [7:0] hgfedcba;
        for (genvar i = 0; i < 8; i++)
        begin : segment_order
            assign hgfedcba [i] = abcdefgh [7 - i];
        end

        tm1638_board_controller # (.clk_mhz (clk_mhz), .w_digit (w_digit))
        i_tm1638
        (
            .clk      (clk),
            .rst      (rst),
            .hgfedcba (hgfedcba),
            .digit    (digit),
            .ledr     (lab_led),
            .keys     (tm_key),
            .sio_stb  (GPIO_0 [27]),
            .sio_clk  (GPIO_0 [29]),
            .sio_data (GPIO_0 [31])
        );
    `endif

    `ifdef DE25_NANO_USE_INMP441
        inmp441_mic_i2s_receiver # (.clk_mhz (clk_mhz))
        i_microphone
        (
            .clk   (clk),
            .rst   (rst),
            .lr    (GPIO_0 [0]),
            .ws    (GPIO_0 [2]),
            .sck   (GPIO_0 [4]),
            .sd    (GPIO_0 [5]),
            .value (mic)
        );
    `else
        assign mic = '0;
    `endif

    `ifdef DE25_NANO_USE_I2S_AUDIO
        i2s_audio_out # (.clk_mhz (clk_mhz))
        i_audio_out
        (
            .clk     (clk),
            .reset   (rst),
            .data_in (sound),
            .mclk    (GPIO_0 [17]),
            .bclk    (GPIO_0 [15]),
            .lrclk   (GPIO_0 [11]),
            .sdata   (GPIO_0 [13])
        );
    `endif

    `ifdef DE25_NANO_USE_UART
        assign uart_rx = GPIO_0 [6];
        assign GPIO_0 [7] = uart_tx;
    `else
        assign uart_rx = 1'b1;
    `endif

endmodule
