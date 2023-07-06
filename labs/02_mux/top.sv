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

  // General-purpose Input/Output

  inout  logic [w_gpio  - 1:0] gpio
);

  //--------------------------------------------------------------------------

  // assign led      = '0;
  // assign abcdefgh = '0;
  // assign digit    = '0;
     assign vsync    = '0;
     assign hsync    = '0;
     assign red      = '0;
     assign green    = '0;
     assign blue     = '0;

  //--------------------------------------------------------------------------

  wire a   = key [0];
  wire b   = key [1];
  wire sel = key [2];

  //--------------------------------------------------------------------------

  // Five different implementations

  wire mux0 = sel ? a : b;

  //--------------------------------------------------------------------------

  wire [1:0] ab = { a, b };
  assign mux1 = ab [sel];

  //--------------------------------------------------------------------------

  logic mux2;

  always_comb
    if (sel)
      mux2 = a;
    else
      mux2 = b;

  //--------------------------------------------------------------------------

  logic mux3;

  always_comb
    case (sel)
    1'b1: mux3 = a;
    1'b0: mux3 = b;
    endcase

  //--------------------------------------------------------------------------

  // Exercise: Implement mux
  // without using "?" operation, "if", "case" or a bit selection.
  // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

  wire mux4 = 1'b0;

  //--------------------------------------------------------------------------

  // Use concatenation operation for 5 signals:

  assign led      = w_led'   ({ mux0, mux1, mux2, mux3, mux4 });
  assign abcdefgh = { 3'b0,     mux0, mux1, mux2, mux3, mux4 };
  assign digit    = w_digit' ({ mux0, mux1, mux2, mux3, mux4 });

endmodule
