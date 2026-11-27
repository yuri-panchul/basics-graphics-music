`include "config.svh"
`include "linked_list_controller_configuration_and_types_package.sv"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
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
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    `include "seven_segment_alphabet_function.svh"

    import linked_list_controller_configuration_and_types_package::*;

    pointer_t start_pointer;
    wire      start_pointer_valid;
    wire      start_pointer_ready;

    wire      out_data_valid;
    data_t    out_data;

    start_pointer_request_generator i_spr
    (
        .clock  ( slow_clk ),
        .reset  ( rst      ),

        .start_pointer,
        .start_pointer_valid,
        .start_pointer_ready
    );

    linked_list_controller_1_fetching_next_from_constant_array i_llc
    (
        .clock  ( slow_clk ),
        .reset  ( rst      ),

        .start_pointer,
        .start_pointer_valid,
        .start_pointer_ready,

        .out_data_valid,
        .out_data
    );

    assign led      = out_data_valid ? out_data : '0;
    assign abcdefgh = out_data_valid ? seven_segment_alphabet (out_data) : '0;
    assign digit    = w_digit' (1);

endmodule
