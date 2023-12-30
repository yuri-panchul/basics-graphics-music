`include "config.svh"
`include "lab_specific_config.svh"

// `define USE_DIGILENT_PMOD_MIC3

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 3,
              w_sw    = 3,
              w_led   = 4,
              w_digit = 8,
              w_gpio  = 34 * 2
)
(
    input                     CLK,
    input                     RST_N,

    input                     KEY2,
    input                     KEY3,
    input                     KEY4,

    output [w_led      - 1:0] LED,

    output [             7:0] SEG_DATA,
    output [w_digit    - 1:0] SEG_SEL,

    output                    VGA_OUT_HS,
    output                    VGA_OUT_VS,

    output [             4:0] VGA_OUT_R,
    output [             5:0] VGA_OUT_G,
    output [             4:0] VGA_OUT_B,

    input                     UART_RXD,

    inout  [w_gpio / 2 - 1:0] GPIO_0,
    inout  [w_gpio / 2 - 1:0] GPIO_1
);

    //------------------------------------------------------------------------

    wire                 clk = CLK;
    wire                 rst = ~ RST_N;
    wire [w_key   - 1:0] key = ~ { KEY2, KEY3, KEY4 };

    wire [w_led   - 1:0] led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [          3:0] red, green, blue;
    wire [         23:0] mic;
    wire                 mic_ready;
    wire [         15:0] sound;

    // FIXME: Should be assigned to some GPIO!
    wire                 UART_TXD;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk      ( clk        ),
        .slow_clk ( slow_clk   ),
        .rst      ( rst        ),

        .key      ( key        ),
        .sw       ( key        ),

        .led      ( LED        ),

        .abcdefgh ( abcdefgh   ),
        .digit    ( digit      ),

        .vsync    ( VGA_OUT_VS ),
        .hsync    ( VGA_OUT_HS ),

        .red      ( red        ),
        .green    ( green      ),
        .blue     ( blue       ),

        .uart_rx  ( UART_RXD   ),
        .uart_tx  ( UART_TXD   ),

        .mic_ready( mic_ready  ),
        .mic      ( mic        ),
        .sound    ( sound      ),

        .gpio ( { GPIO_0, GPIO_1 } )
    );

    //------------------------------------------------------------------------

    assign SEG_DATA  = ~ abcdefgh;
    assign SEG_SEL   = ~ digit;

    assign VGA_OUT_R = { red   , 1'b0 };
    assign VGA_OUT_G = { green , 2'b0 };
    assign VGA_OUT_B = { blue  , 1'b0 };

    `ifdef USE_DIGILENT_PMOD_MIC3

    wire [11:0] mic_12;

    digilent_pmod_mic3_spi_receiver i_microphone
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .cs    ( GPIO_1 [26] ), // J2 pin 29
        .sck   ( GPIO_1 [32] ), // J2 pin 35
        .sdo   ( GPIO_1 [30] ), // J2 pin 33
        .ready ( mic_ready   ),
        .value ( mic_12      )
    );

    wire [11:0] mic_12_minus_offset = mic_12 - 12'h800;
    assign mic = { { 12 { mic_12_minus_offset [11] } }, mic_12_minus_offset };

    `else

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .lr    ( GPIO_0 [0] ), // J1 pin 36
        .ws    ( GPIO_0 [2] ), // J1 pin 34
        .sck   ( GPIO_0 [4] ), // J1 pin 32
        .sd    ( GPIO_0 [5] ), // J1 pin 31
        .ready ( mic_ready  ),
        .value ( mic        )
    );

    assign GPIO_0 [1] = 1'b0;  // GND - J1 pin 35
    assign GPIO_0 [3] = 1'b1;  // VCC - J1 pin 33

    `endif

    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz     )
    )
    o_audio
    (
        .clk     ( clk         ),
        .reset   ( rst         ),
        .data_in ( sound       ),
        .mclk    ( GPIO_0 [12] ), // J1 pin 24
        .bclk    ( GPIO_0 [10] ), // J1 pin 26
        .lrclk   ( GPIO_0 [ 6] ), // J1 pin 30
        .sdata   ( GPIO_0 [ 8] )  // J1 pin 28
    );                            // J1 pin 37 - GND, pin 40 - D3V3 3.3V (30-45 mA)

endmodule
