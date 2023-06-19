module top
# (
  parameter w_key   = 4,
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

  wire enable;
  wire fsm_in, moore_fsm_out, mealy_fsm_out;

  strobe_gen i_strobe_gen (.strobe (enable), .*);

  shift_reg # (.depth (w_led)) i_shift_reg
  (
      .en      ( enable ),
      .seq_in  ( ~& key ),  // Same as key != { w_key { 1'b1 } }
      .seq_out ( fsm_in ),
      .par_out ( led    ),
      .*
  );

  snail_moore_fsm i_moore_fsm
      (.en (enable), .a (fsm_in), .y (moore_fsm_out), .*);

  snail_mealy_fsm i_mealy_fsm
      (.en (enable), .a (fsm_in), .y (mealy_fsm_out), .*);

  //------------------------------------------------------------------------

  //   --a--
  //  |     |
  //  f     b
  //  |     |
  //   --g--
  //  |     |
  //  e     c
  //  |     |
  //   --d--  h
  //
  //  0 means light

  always_comb
  begin
    case ({ mealy_fsm_out, moore_fsm_out })
    2'b00: abcdefgh = 8'b1111_1111;
    2'b01: abcdefgh = 8'b0011_1001;  // Moore only
    2'b10: abcdefgh = 8'b1100_0101;  // Mealy only
    2'b11: abcdefgh = 8'b0000_0001;
    endcase

    digit = '1;
    digit [0] = 1'b0;
  end

  // Exercise: Implement FSM for recognizing other sequence,
  // for example 0101

endmodule
