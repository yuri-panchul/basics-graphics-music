`include "config.svh"
`include "lab_specific_board_config.svh"

//--- VGA external ---
   `define VGA666_BOARD
// `define PMOD_VGA_BOARD

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 10,
              w_led         = 8,
              w_digit       = 4,
              w_gpio        = 22,

              // GPIO[9:6], [21:11] are reserved for VGA.
              // GPIO[5:0] are reserved for INMP 441 I2S microphone.

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                 CLOCK_50_B8A,
    input                 CPU_RESET_n,

    input  [w_key  - 1:0] KEY,
    input  [w_sw   - 1:0] SW,
    output logic [   9:0] LEDR,       // The last 4 LEDR are used like a 7SEG dp
    output logic [   7:0] LEDG,

    output                HDMI_TX_CLK,
    output       [  23:0] HDMI_TX_D,
    output                HDMI_TX_DE,
    output                HDMI_TX_HS,
    input                 HDMI_TX_INT,
    output                HDMI_TX_VS,

    output logic [   6:0] HEX0,       // HEX[7] aka dp are not connected to FPGA at "Cyclone V GX Starter Kit"
    output logic [   6:0] HEX1,
    output logic [   6:0] HEX2,
    output logic [   6:0] HEX3,

    output                I2C_SCL,
    inout                 I2C_SDA,

    input                 UART_RX,

    inout  [w_gpio - 1:0] GPIO
);

    //------------------------------------------------------------------------

    localparam w_lab_sw   = w_sw - 1; // One onboard SW is used as a reset

    //------------------------------------------------------------------------

    wire                  clk     = CLOCK_50_B8A;
    wire                  rst     = ~ CPU_RESET_n;

    // Keys, switches, LEDs

    wire [ w_key    - 1:0] lab_key = ~ KEY;
    wire [ w_lab_sw - 1:0] lab_sw  = SW [w_lab_sw - 1:0];
    wire [ w_led    - 1:0] lab_led;

    // A dynamic seven-segment display

    wire [            7:0] abcdefgh;
    wire [  w_digit - 1:0] digit;

    // Graphics

    wire [ w_x      - 1:0] x;
    wire [ w_y      - 1:0] y;

    wire                   vs, hs;

    wire [ w_red    - 1:0] red;
    wire [ w_green  - 1:0] green;
    wire [ w_blue   - 1:0] blue;

    // Microphone and UART

    wire [           23:0] mic;

    wire                   UART_TX; // FIXME: Should be assigned to some GPIO

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz       ),
        .w_key         (   w_key         ),
        .w_sw          (   w_lab_sw      ),
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
        .sw            (   lab_sw        ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .mic           (   mic           ),
        .sound         (                 ),

        .uart_rx       (   UART_RX       ),
        .uart_tx       (   UART_TX       ),

        .gpio          (   GPIO          )
    );

    //------------------------------------------------------------------------

    // External VGA out at GPIO
    `ifdef  VGA666_BOARD

        // 4 bit color used
        assign GPIO [21] = vs;              // vga666_pi_Vsync - JP9 pin 24
        assign GPIO [19] = hs;              // vga666_pi_Hsync - JP9 pin 22
        // R
        assign GPIO [16] = red [0];         // vga666_red[4]   - JP9 pin 19
        assign GPIO [11] = red [1];         // vga666_red[5]   - JP9 pin 14
        assign GPIO [ 9] = red [2];         // vga666_red[6]   - JP9 pin 10
        assign GPIO [ 7] = red [3];         // vga666_red[7]   - JP9 pin  8
        // G
        assign GPIO [ 6] = green [0];       // vga666_green[4] - JP9 pin  7
        assign GPIO [13] = green [1];       // vga666_green[5] - JP9 pin 16
        assign GPIO [20] = green [2];       // vga666_green[6] - JP9 pin 23
        assign GPIO [18] = green [3];       // vga666_green[7] - JP9 pin 21
        // B
        assign GPIO [15] = blue [0];        // vga666_blue[4]  - JP9 pin 18
        assign GPIO [12] = blue [1];        // vga666_blue[5]  - JP9 pin 15
        assign GPIO [14] = blue [2];        // vga666_blue[6]  - JP9 pin 17
        assign GPIO [17] = blue [3];        // vga666_blue[7]  - JP9 pin 20
                                            // vga666_GND      - JP9 pin 12

    `elsif PMOD_VGA_BOARD

        assign GPIO [19] = vs;              // JP9 pin 22
        assign GPIO [21] = hs;              // JP9 pin 24
        // R
        assign GPIO [ 6] = red [0];         // JP9 pin  7
        assign GPIO [ 8] = red [1];         // JP9 pin  9
        assign GPIO [ 7] = red [2];         // JP9 pin  8
        assign GPIO [ 9] = red [3];         // JP9 pin 10
        // G
        assign GPIO [11] = green [0];       // JP9 pin 14
        assign GPIO [13] = green [1];       // JP9 pin 16
        assign GPIO [15] = green [2];       // JP9 pin 18
        assign GPIO [17] = green [3];       // JP9 pin 20
        // B
        assign GPIO [12] = blue [0];        // JP9 pin 15
        assign GPIO [14] = blue [1];        // JP9 pin 17
        assign GPIO [16] = blue [2];        // JP9 pin 19
        assign GPIO [18] = blue [3];        // JP9 pin 21
                                            // GND  - JP9 pin 30
                                            // 3.3V - JP9 pin 29

    `endif

    //------------------------------------------------------------------------

    // HDMI Video
    wire       pixel_clk;
    wire       display_on;

    assign HDMI_TX_CLK      = pixel_clk;
    assign HDMI_TX_D        = {{red,{(8 - w_red){1'b1}}},{green,{(8 - w_green){1'b1}}},{blue,{(8 - w_blue){1'b1}}}}; // eight bit color is max
    assign HDMI_TX_DE       = display_on;
    assign HDMI_TX_HS       = hs;
    assign HDMI_TX_VS       = vs;

    // HDMI I2C configurator
    I2C_HDMI_Config i_i2c_hdmi_conf (
        .iCLK(clk),
        .iRST_N(~rst),
        .I2C_SCLK(I2C_SCL),
        .I2C_SDAT(I2C_SDA),
        .HDMI_TX_INT(HDMI_TX_INT)
    );

    //------------------------------------------------------------------------

    assign LEDG = { { $bits (LEDG) - w_led { 1'b0 } }, lab_led };

    //------------------------------------------------------------------------

    wire  [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.

        // inverted logic

        assign HEX0 = digit [0] ? ~ hgfedcba [$left (HEX0):0] : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba [$left (HEX1):0] : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba [$left (HEX2):0] : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba [$left (HEX3):0] : '1;

        // positive logic

        always_comb
        begin
            LEDR = '0;

            for (int i = 0; i < w_digit; i ++)
                LEDR [$bits (LEDR) - w_digit + i]
                    = digit [i] ? hgfedcba [$left (HEX0) + 1] : '0;
        end

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3 } <= '1;
                LEDR <= '0;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba [$left (HEX0):0];
                if (digit [1]) HEX1 <= ~ hgfedcba [$left (HEX1):0];
                if (digit [2]) HEX2 <= ~ hgfedcba [$left (HEX2):0];
                if (digit [3]) HEX3 <= ~ hgfedcba [$left (HEX3):0];

                for (int i = 0; i < w_digit; i ++)
                    if (digit [i])
                        LEDR [$bits (LEDR) - w_digit + i] <=  hgfedcba [$left (HEX0) + 1];
            end

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .H_DISPLAY   ( screen_width  ),
            .V_DISPLAY   ( screen_height ),
            .CLK_MHZ     ( clk_mhz       ),
            .PIXEL_MHZ   ( pixel_mhz     )
        )
        i_vga
        (
            .clk         ( clk           ),
            .rst         ( rst           ),
            .hsync       ( hs            ),
            .vsync       ( vs            ),
            .display_on  ( display_on    ),
            .hpos        ( x10           ),
            .vpos        ( y10           ),
            .pixel_clk   ( pixel_clk     )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz  ( clk_mhz  )
        )
        i_microphone
        (
            .clk      ( clk      ),
            .rst      ( rst      ),
            .lr       ( GPIO [0] ),  // JP9 pin 1
            .ws       ( GPIO [2] ),  // JP9 pin 3
            .sck      ( GPIO [4] ),  // JP9 pin 5
            .sd       ( GPIO [5] ),  // JP9 pin 6
            .value    ( mic      )
        );

        assign GPIO [1] = 1'b0;   // GND - JP9 pin 2
        assign GPIO [3] = 1'b1;   // VCC - JP9 pin 4

    `endif

endmodule
