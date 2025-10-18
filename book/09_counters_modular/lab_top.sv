`include "config.svh"

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

    localparam w_in = 8;
    logic [w_in - 1:0] in;

    generate
        if (w_key < w_in && w_sw >= w_in)
        begin : use_switches
            assign in = w_in' (sw);
        end
        else
        begin : use_keys
            assign in = w_in' (key);
        end
    endgenerate

    //------------------------------------------------------------------------

    wire rst_from_key0    = in [0];
    wire enable_from_key1 = in [1];

    //------------------------------------------------------------------------

    logic [31:0] o_counter32_verbose_slow_clk;

      counter32_verbose
    i_counter32_verbose_slow_clk
    (
        .clk ( slow_clk                     ),
        .rst ( rst_from_key0                ),
        .cnt ( o_counter32_verbose_slow_clk )
    );

    //------------------------------------------------------------------------

    logic [31:0] o_counter32_verbose;

      counter32_verbose
    i_counter32_verbose
    (
        .clk,
        .rst (rst_from_key0),
        .cnt (o_counter32_verbose)
    );

    //------------------------------------------------------------------------

    logic [31:0] o_counter32_less_verbose;

      counter32_less_verbose
    i_counter32_less_verbose
    (
        .clk,
        .rst (rst_from_key0),
        .cnt (o_counter32_less_verbose)
    );

    //------------------------------------------------------------------------

    logic [31:0] o_counter32_brief;

      counter32_brief
    i_counter32_brief
    (
        .clk,
        .rst (rst_from_key0),
        .cnt (o_counter32_brief)
    );

    //------------------------------------------------------------------------

    logic [2:0] o_counter_with_width;

    counter_with_width
    # (.width ($bits (o_counter_with_width)))
    i_counter_with_width
    (
        .clk ( slow_clk             ),
        .rst ( rst_from_key0        ),
        .cnt ( o_counter_with_width )
    );

    //------------------------------------------------------------------------

    logic [2:0] o_counter_with_max_up;

    counter_with_max_up
    # (.max (4))
    i_counter_with_max_up
    (
        .clk ( slow_clk              ),
        .rst ( rst_from_key0         ),
        .cnt ( o_counter_with_max_up )
    );

    //------------------------------------------------------------------------

    logic [2:0] o_counter_with_max_down;

    counter_with_max_down
    # (.max (5))
    i_counter_with_max_down
    (
        .clk ( slow_clk                ),
        .rst ( rst_from_key0           ),
        .cnt ( o_counter_with_max_down )
    );

    //------------------------------------------------------------------------

    logic [2:0] o_counter_with_max_down_brief;

    counter_with_max_down_brief
    # (.max (6))
    i_counter_with_max_down_brief
    (
        .clk ( slow_clk                      ),
        .rst ( rst_from_key0                 ),
        .cnt ( o_counter_with_max_down_brief )
    );

    //------------------------------------------------------------------------

    logic [4:0] o_counter_with_max_and_enable;

    counter_with_max_and_enable
    # (.max (8))
    i_counter_with_max_and_enable
    (
        .clk    ( slow_clk                      ),
        .rst    ( rst_from_key0                 ),
        .enable ( enable_from_key1              ),
        .cnt    ( o_counter_with_max_and_enable )
    );

    //------------------------------------------------------------------------

    logic [15:0] o_counter_enables_counter;

    counter_enables_counter
    i_counter_enables_counter
    (
        .clk    ( clk                       ),
        .rst    ( rst_from_key0             ),
        .cnt    ( o_counter_enables_counter )
    );

    //------------------------------------------------------------------------

    logic [15:0] o_counter_and_strobe_generator;

    counter_and_strobe_generator
    i_counter_and_strobe_generator
    (
        .clk    ( clk                            ),
        .rst    ( rst_from_key0                  ),
        .cnt    ( o_counter_and_strobe_generator )
    );

    //------------------------------------------------------------------------

    localparam w_number = w_digit * 4;
    logic [w_number - 1:0] number;

    seven_segment_display # (.w_digit (w_digit)) i_7segment
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .number   ( number   ),
        .dots     ( '0       ),
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

    //------------------------------------------------------------------------

    always_comb
        case (in [5:2])
        4'd0    : led = w_led' ( o_counter32_verbose_slow_clk     );
        4'd1    : led = w_led' ( o_counter32_verbose              );
        4'd2    : led = w_led' ( o_counter32_verbose      [31:24] );
        4'd3    : led = w_led' ( o_counter32_less_verbose         );
        4'd4    : led = w_led' ( o_counter32_less_verbose [31:24] );
        4'd5    : led = w_led' ( o_counter32_brief                );
        4'd6    : led = w_led' ( o_counter32_brief        [31:24] );
        4'd7    : led = w_led' ( o_counter_with_width             );
        4'd8    : led = w_led' ( o_counter_with_max_up            );
        4'd9    : led = w_led' ( o_counter_with_max_down          );
        4'd10   : led = w_led' ( o_counter_with_max_down_brief    );
        4'd11   : led = w_led' ( o_counter_with_max_and_enable    );
        4'd12   : led = w_led' ( o_counter_enables_counter        );
        4'd13   : led = w_led' ( o_counter_and_strobe_generator   );
        default : led = '0;
        endcase

    //------------------------------------------------------------------------

    always_comb
        case (in [5:2])
        4'd0    : number = w_number' ( o_counter32_verbose_slow_clk     );
        4'd1    : number = w_number' ( o_counter32_verbose              );
        4'd2    : number = w_number' ( o_counter32_verbose      [31:24] );
        4'd3    : number = w_number' ( o_counter32_less_verbose         );
        4'd4    : number = w_number' ( o_counter32_less_verbose [31:24] );
        4'd5    : number = w_number' ( o_counter32_brief                );
        4'd6    : number = w_number' ( o_counter32_brief        [31:24] );
        4'd7    : number = w_number' ( o_counter_with_width             );
        4'd8    : number = w_number' ( o_counter_with_max_up            );
        4'd9    : number = w_number' ( o_counter_with_max_down          );
        4'd10   : number = w_number' ( o_counter_with_max_down_brief    );
        4'd11   : number = w_number' ( o_counter_with_max_and_enable    );
        4'd12   : number = w_number' ( o_counter_enables_counter        );
        4'd13   : number = w_number' ( o_counter_and_strobe_generator   );
        default : number = '0;
        endcase

endmodule
