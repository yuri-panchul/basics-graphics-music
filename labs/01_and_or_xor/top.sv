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
     assign abcdefgh = '0;
     assign digit    = '0;
     assign vsync    = '0;
     assign hsync    = '0;
     assign red      = '0;
     assign green    = '0;
     assign blue     = '0;

  //--------------------------------------------------------------------------

  
  wire a = key [0];
  wire b = key [1];   

  wire result = a ^ b;

  assign led [0] = result;

  assign led [1] = key [0] ^ key [1]);

  // Exercise 1: Change the code below.
  // Assign to led [2] the result of AND operation

  assign led [2] = 1'b0;

  // Exercise 2: Change the code below.
  // Assign to led [3] the result of XOR operation 
  // without using "^" operation.
  // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

  assign led [3] = 1'b0;

endmodule
