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

  wire [3:0] in;

  generate

    if (w_key >= 4)              // Board with at least 4 keys
      assign in = key [3:0];
    else if (w_sw >= 4)          // Board with at least 4 switches
      assign in = sw  [3:0];
    else if (w_key + w_sw >= 4)  // Board with at least 4 keys + switches
      assign in = 4' ({ key, sw });
    else if (w_key >= 2)         // Board with at least 2 keys
      assign in = { key [3:2], key [1:0] };
    else                         // Corner case: repeat a key 4 times
      assign in = { 4 { key [0] } };

  endgenerate

  //--------------------------------------------------------------------------

  logic [1:0] enc0, enc1, enc2, enc3;

  // Implementation 1. Priority encoder using a chain of "ifs"

  always_comb
         if (in [0]) enc0 = 2'd0;
    else if (in [1]) enc0 = 2'd1;
    else if (in [2]) enc0 = 2'd2;
    else if (in [3]) enc0 = 2'd3;
    else             enc0 = 2'd0;

  // Implementation 2. Priority encoder using casez

  always_comb
    casez (in)
    4'b???1: enc1 = 2'd0;
    4'b??10: enc1 = 2'd1;
    4'b?100: enc1 = 2'd2;
    4'b1000: enc1 = 2'd3;
    default: enc1 = 2'd0;
    endcase

  // Implementation 3: Combination of priority arbiter
  // and encoder without priority

  localparam w = 4;

  wire [w - 1:0] c = { ~ in [w - 2:0] & c [w - 2:0], 1'b1 };
  wire [w - 1:0] g = in & c;

  always_comb
    unique case (g)
    4'b0001: enc2 = 2'd0;
    4'b0010: enc2 = 2'd1;
    4'b0100: enc2 = 2'd2;
    4'b1000: enc2 = 2'd3;
    default: enc2 = 2'd0;
    endcase

  /*
  // A variation of Implementation 3: Using unusual case of "case"

  always_comb
    unique case (1'b1)
    g [0]:   enc2 = 2'd0;
    g [1]:   enc2 = 2'd1;
    g [2]:   enc2 = 2'd2;
    g [3]:   enc2 = 2'd3;
    default: enc2 = 2'd0;
    endcase
  */

  // A note on obsolete practice:
  //
  // Before the SystemVerilog construct "unique case"
  // got supported by the synthesis tools,
  // the designers were using pseudo-comment "synopsys parallel_case":
  //
  // SystemVerilog : unique case (1'b1)
  // Verilog 2001  : case (1'b1)  // synopsys parallel_case

  // Implementation 4: Using "for" loop

  `ifdef __ICARUS__

    // Icarus does not support break statement

    assign enc3 = enc2;

  `else

    always_comb
    begin
      enc3 = '0;

      for (int i = 0; i < $bits (in); i ++)
      begin
        if (in [i])
        begin
          enc3 = 2' (i);
          break;
        end
      end
    end

  `endif

  //--------------------------------------------------------------------------

  assign led      = w_led'   ({ enc0, enc1, enc2, enc3 });
  assign abcdefgh =           { enc0, enc1, enc2, enc3 };
  assign digit    = w_digit' ({ enc0, enc1, enc2, enc3 });

endmodule
