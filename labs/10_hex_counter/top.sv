`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 20
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,

    // General-purpose Input/Output

    inout  logic [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led      = '0;
    // assign abcdefgh = '0;
    // assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;

    //------------------------------------------------------------------------

    // Synthesize the counter controlled by two keys.
    // When one key is in pressed position - the frequency increases,
    // when another key is in pressed position - the frequency decreases.

    logic [31:0] period;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            period <= 32'h12345678;
        else if (key [0])
            period <= period + 1'd1;
        else if (key [1])
            period <= period - 1'd1;

    logic [31:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (cnt == period - 1'b1)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    assign led = cnt [$left (cnt) -: w_led];

    //------------------------------------------------------------------------

    // 4 bits per hexadecimal digit
    localparam w_display_number = w_digit * 4;

    logic [w_digit * 4 - 1:0] disp_cnt;

    always_comb
        if ($bits (disp_cnt) >= $bits (cnt))
            disp_cnt = w_display_number' (cnt);
        else
            disp_cnt = cnt [$left (cnt) -: $bits (disp_cnt)];

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .number   ( disp_cnt ),
        .dots     ( '0       ),
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

    //------------------------------------------------------------------------

    // Exercise: Change the example above to:
    //
    // 1. Double the frequency when one key is pressed and released.
    // 2. Halve the frequency when another key is pressed and released.

endmodule
