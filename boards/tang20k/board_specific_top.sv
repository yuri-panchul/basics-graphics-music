
module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 5,
                w_sw    = 5,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 64         
)
(
    input                   CLK,
    input                   RESET,

    input  [w_key   - 1:0]  KEY,
    input  [w_sw    - 1:0]  SW,
    
    output [w_led   - 1:0]  LED,

    inout  [w_gpio  - 1:0]  GPIO
);

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
        .clk      (   CLOCK        ),
        .rst      ( ~ RESET        ),

        .key      ( ~ KEY          ),
        .sw       (   SW           ),

        .led      (   LED          ),

        .abcdefgh (                ),
        .digit    (                ),

        .vsync    (                ),
        .hsync    (                ),

        .red      (                ),
        .green    (                ),
        .blue     (                ),

        .mic      (                ),
        .gpio     (   GPIO         )
    );

endmodule