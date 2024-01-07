// Asynchronous reset here is needed for the FPGA board we use

`include "config.svh"

`ifndef SIMULATION

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
    input                        slow_clk,
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

    input                        uart_rx,
    output                       uart_tx,

    input                        mic_ready,
    input        [         23:0] mic,
    output       [         15:0] sound,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
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
       assign sound    = '0;

    //------------------------------------------------------------------------

    wire a = key [0];
    wire b = key [1];
    wire sum;

    serial_adder adder
    (
        .clk  ( slow_clk ),
        .rst  ( rst      ),
        .a    ( a        ),
        .b    ( b        ),
        .sum  ( sum      )
    );

    assign led = w_led' ({ sum, b, a });

    //------------------------------------------------------------------------

    wire [3:0] a4;

    shift_reg # (4) shift_a
    (
        .clk     ( slow_clk ),
        .rst     ( rst      ),
        .en      ( 1'b1     ),
        .seq_in  ( a        ),
        .seq_out (          ),
        .par_out ( a4       )
    );

    wire [3:0] b4;

    shift_reg # (4) shift_b
    (
        .clk     ( slow_clk ),
        .rst     ( rst      ),
        .en      ( 1'b1     ),
        .seq_in  ( b        ),
        .seq_out (          ),
        .par_out ( b4       )
    );

    wire [3:0] sum4;

    shift_reg # (4) shift_sum
    (
        .clk     ( slow_clk ),
        .rst     ( rst      ),
        .en      ( 1'b1     ),
        .seq_in  ( sum      ),
        .seq_out (          ),
        .par_out ( sum4     )
    );

    //------------------------------------------------------------------------

    localparam w_number = w_digit * 4;
    wire [w_number - 1:0] number = w_number' ({ sum4, b4, a4 });

    wire [7:0] abcdefgh_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      ( clk          ),
        .number   ( number       ),
        .dots     ( '0           ),
        .abcdefgh ( abcdefgh_pre ),
        .digit    ( digit        ),
        .*
    );

    always_comb
        if (digit & 3'b111)
            abcdefgh = abcdefgh_pre;
        else
            abcdefgh = '0;

endmodule

`endif
