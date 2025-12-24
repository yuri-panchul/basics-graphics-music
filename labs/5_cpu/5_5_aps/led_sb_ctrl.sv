// -----------------------------------------------------------------
// Original APS course solution didn't include this module.
//
// Added & modified from:
// https://github.com/ButterSus/APS/blob/master/Labs/Extra._Peripheral_units/rtl/peripheral/led_sb_ctrl.sv
// -----------------------------------------------------------------

module led_sb_ctrl #(
    parameter int w_led = 16
) (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        req_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    output logic [31:0] read_data_o,

    output logic [w_led - 1:0] led_o
);

  localparam bit [23:0] VALUE_ADDR = 24'h00;
  localparam bit [23:0] MODE_ADDR  = 24'h04;
  localparam bit [23:0] RESET_ADDR = 24'h24;

  wire ext_rst = (req_i & write_enable_i) & (addr_i [23:0] == RESET_ADDR);

  // -------------
  // Register file

  typedef enum logic {
    STATIC = 1'b0,
    BLINK  = 1'b1
  } led_state_e;

  logic [w_led - 1:0] value_r;
  led_state_e  mode_r;

  always_ff @ (posedge clk_i)
    if (rst_i | ext_rst) begin
      value_r <= (w_led)'(0);
      mode_r  <= led_state_e'(STATIC);
    end
    else if (req_i & write_enable_i)
      case (addr_i [23:0])
        VALUE_ADDR : value_r <= write_data_i [w_led - 1:0];
        MODE_ADDR  : mode_r <= led_state_e'(write_data_i [0]);
        default :;
      endcase

  // -----------
  // Driving led

  localparam int CNT_MAX = 10_000_000;

  logic [31:0] cnt_r;

  always_ff @ (posedge clk_i)
    if (rst_i | ext_rst | (mode_r == led_state_e'(STATIC)))
      cnt_r <= 32'd0;
    else if (mode_r == led_state_e'(BLINK))
      cnt_r <= cnt_r >= 32'(2 * CNT_MAX) ? 32'd0 : cnt_r + 32'd1;

  always_comb begin
    led_o = (w_led)'(0);

    if (cnt_r < 32'(CNT_MAX))
      led_o = value_r;
  end

  // ------------
  // Output logic

  always_ff @ (posedge clk_i)
    if (rst_i)
      read_data_o <= 32'd0;
    else if (req_i & ~write_enable_i)
      case (addr_i [23:0])
        VALUE_ADDR : read_data_o <= 32'(value_r);
        MODE_ADDR  : read_data_o <= { 31'd0, 1'(mode_r) };
        default :;
      endcase

endmodule
