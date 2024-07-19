`include "config.svh"

module asic_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 0
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit
);

    lab_top
    # (
        .clk_mhz   ( clk_mhz  ),
        .w_key     ( w_key    ),
        .w_sw      ( w_sw     ),
        .w_led     ( w_led    ),
        .w_digit   ( w_digit  ),
        .w_gpio    ( w_gpio   )
    )
    i_lab_top
    (
        .clk       ( clk      ),
        .slow_clk  ( slow_clk ),
        .rst       ( rst      ),
        .key       ( key      ),
        .sw        ( sw       ),
        .led       ( led      ),
        .abcdefgh  ( abcdefgh ),
        .digit     ( digit    ),

        .vsync     (          ),
        .hsync     (          ),
        .red       (          ),
        .green     (          ),
        .blue      (          ),
        .uart_rx   (          ),
        .uart_tx   (          ),
        .mic       (          ),
        .sound     (          ),
        .gpio      (          )
    );

endmodule
