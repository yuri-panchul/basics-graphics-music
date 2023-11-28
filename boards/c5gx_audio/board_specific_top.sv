`include "config.svh"
`include "lab_specific_config.svh"

//--- VGA external ---
   `define VGA666_BOARD
// `define PMOD_VGA_BOARD

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 10,
              w_led   = 18,
              w_digit = 4,
              w_gpio  = 22          // GPIO[5:0] reserved for mic
)
(
    input                 CLOCK_50_B8A,
    input                 CPU_RESET_n,

    input  [w_key  - 1:0] KEY,
    input  [w_sw   - 1:0] SW,
    output [         9:0] LEDR,     // The last 4 LEDR are used like a 7SEG dp
    output [         7:0] LEDG,

    output logic [   6:0] HEX0,     // HEX[7] aka dp doesn't connected to FPGA at "Cyclone V GX Starter Kit"
    output logic [   6:0] HEX1,
    output logic [   6:0] HEX2,
    output logic [   6:0] HEX3,

    input                 UART_RX,

    inout  [w_gpio - 1:0] GPIO
);

    localparam w_top_sw = w_sw - 1; // One sw is used as a reset

    wire                  clk     = CLOCK_50_B8A;
    wire                  rst     = ~ CPU_RESET_n;

    wire [w_top_sw - 1:0] top_sw  = SW [w_top_sw - 1:0];
    wire [w_key    - 1:0] top_key = ~ KEY;

    //------------------------------------------------------------------------

    wire [ w_led - w_digit - 1:0] top_led;

    wire [                   7:0] abcdefgh;
    wire [         w_digit - 1:0] digit;

    wire                          mic_ready;
    wire [                  23:0] mic;
    wire [                  15:0] sound;

    wire                          UART_TX; // FIXME: Should be assigned to some GPIO!

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz         ),
        .w_key   ( w_key           ),
        .w_sw    ( w_top_sw        ),
        .w_led   ( w_led - w_digit ), // The last 4 LEDR are used like a 7SEG dp
        .w_digit ( w_digit         ),
        .w_gpio  ( w_gpio          )  // GPIO[5:0] reserved for mic
    )
    i_top
    (
        .clk      (   clk       ),
        .slow_clk ( slow_clk    ),
        .rst      (   rst       ),

        .key      (   top_key   ),
        .sw       (   top_sw    ),

        .led      (   top_led   ),

        .abcdefgh (   abcdefgh  ),
        .digit    (   digit     ),

        .vsync    (             ),
        .hsync    (             ),

        .red      (             ),
        .green    (             ),
        .blue     (             ),

        .uart_rx  (   UART_RX   ),
        .uart_tx  (   UART_TX   ),

        .mic_ready(   mic_ready ),
        .mic      (   mic       ),
        .sound    (   sound     ),

        .gpio     (   GPIO      )
    );

    //------------------------------------------------------------------------

    assign { LEDR [$left(LEDR) - w_digit:0], LEDG } = top_led; // The last 4 LEDR are used like a 7SEG dp

    //------------------------------------------------------------------------

    wire  [$left (abcdefgh):0] hgfedcba;
    logic [$left    (digit):0] dp;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

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

        assign LEDR [$left(LEDR) - w_digit + 1] = digit [0] ? hgfedcba [$left (HEX0) + 1] : '0;
        assign LEDR [$left(LEDR) - w_digit + 2] = digit [1] ? hgfedcba [$left (HEX1) + 1] : '0;
        assign LEDR [$left(LEDR) - w_digit + 3] = digit [2] ? hgfedcba [$left (HEX2) + 1] : '0;
        assign LEDR [$left(LEDR) - w_digit + 4] = digit [3] ? hgfedcba [$left (HEX3) + 1] : '0;

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3 } <= '1;
                dp <= '0;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba [$left (HEX0):0];
                if (digit [1]) HEX1 <= ~ hgfedcba [$left (HEX1):0];
                if (digit [2]) HEX2 <= ~ hgfedcba [$left (HEX2):0];
                if (digit [3]) HEX3 <= ~ hgfedcba [$left (HEX3):0];

                if (digit [0]) dp[0] <=  hgfedcba [$left (HEX0) + 1];
                if (digit [1]) dp[1] <=  hgfedcba [$left (HEX1) + 1];
                if (digit [2]) dp[2] <=  hgfedcba [$left (HEX2) + 1];
                if (digit [3]) dp[3] <=  hgfedcba [$left (HEX3) + 1];
            end

        assign LEDR [$left(LEDR):$left(LEDR) - w_digit + 1] = dp;  // The last 4 LEDR are used like a 7SEG dp

    `endif

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [0] ), // JP9 pin 1
        .ws    ( GPIO [2] ), // JP9 pin 3
        .sck   ( GPIO [4] ), // JP9 pin 5
        .sd    ( GPIO [5] ), // JP9 pin 6
        .ready ( mic_ready),
        .value ( mic      )
    );

    assign GPIO [1] = 1'b0;  // GND - JP9 pin 2
    assign GPIO [3] = 1'b1;  // VCC - JP9 pin 4

    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz     )
    )
    o_audio
    (
        .clk     ( clk       ),
        .reset   ( rst       ),
        .data_in ( sound     ),
        .mclk    ( GPIO [17] ), // JP9 pin 20
        .bclk    ( GPIO [15] ), // JP9 pin 18
        .lrclk   ( GPIO [11] ), // JP9 pin 14
        .sdata   ( GPIO [13] )  // JP9 pin 16
    );                          // JP9 pin 12 - GND, pin 29 - VCC 3.3V (30-45 mA)

endmodule
