`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter   clk_mhz   = 27,
                pixel_mhz = 27,
                w_key     = 2,
                w_sw      = 0,
                w_led     = 3,
                w_digit   = 0,

                w_red     = 4,
                w_green   = 4,
                w_blue    = 4,

                w_gpio    = 0 // 32
)
(
    input                clk,
    input  [w_key - 1:0] key,
    output [w_led - 1:0] led
);

    wire rst = key [0];

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz   ( clk_mhz    ),
        .pixel_mhz ( pixel_mhz  ),

        .w_key     ( w_key      ),
        .w_sw      ( w_sw       ),
        .w_led     ( w_led      ),
        .w_digit   ( w_digit    ),

        .w_red     ( w_red      ),
        .w_green   ( w_green    ),
        .w_blue    ( w_blue     ),

        .w_gpio    ( w_gpio     )
    )
    i_lab_top
    (
        .clk       ( clk        ),
        .slow_clk  ( slow_clk   ),
        .rst       ( rst        ),

        .key       ( key        ),
        .sw        (            ),

        .led       ( led        ),

        .abcdefgh  (            ),
        .digit     (            ),

        .vsync     (            ),
        .hsync     (            ),

        .red       (            ),
        .green     (            ),
        .blue      (            ),

        .uart_rx   (            ),
        .uart_tx   (            ),

        .mic       (            ),
        .gpio      (            )
    );

endmodule
