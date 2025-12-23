// -----------------------------------------------------------------
// Original APS course solution didn't include this module.
//
// Added & modified from:
// https://github.com/ButterSus/APS/blob/master/Labs/Extra._Peripheral_units/rtl/peripheral/sw_sb_ctrl.sv
// -----------------------------------------------------------------

module sw_sb_ctrl #(
    parameter int w_sw = 16
) (
    input  logic        clk_i,
    input  logic        deb_clk_i,
    input  logic        rst_i,
    input  logic        req_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    output logic [31:0] read_data_o,

    input  logic        irq_ret_i,
    output logic        irq_req_o,

    input  logic [w_sw - 1:0] sw_i
);

  localparam bit [23:0] VALUE_ADDR = 24'h0;

  logic [w_sw - 1:0] sw;

  logic [w_sw - 1:0] sw_r;
  logic        sw_r_vld;

  // ---------------------------
  // Buffer sw_i (async to sync)

  localparam int SHIFT_DEPTH = 4;

  logic [w_sw - 1:0] sw_sync;
  logic [SHIFT_DEPTH - 1:0][w_sw - 1:0] sw_shift_r;

  always_ff @ (posedge clk_i)
    sw_shift_r <= { sw_i, sw_shift_r [SHIFT_DEPTH - 1:1] };

  assign sw_sync = sw_shift_r [0];

  // ----------------
  // Debounce sw_sync

  debouncer #(.WIDTH(w_sw)) i_debouncer
  (
    .clk_i  ( deb_clk_i ),
    .rst_i  ( rst_i     ),
    .data_i ( sw_sync   ),
    .data_o ( sw        )
  );

  // ------------
  // Driver logic

  logic [w_sw - 1:0] sw_snapshot;
  logic irq_req_r;

  always_ff @ (posedge clk_i)
    if (rst_i)
      sw_snapshot <= sw;
    else if (irq_req_gen &~ irq_req_r)
      sw_snapshot <= sw;

  // ----------------
  // Interrupts logic

  wire irq_req_gen = sw_r_vld & (sw_r != sw);

  always_ff @ (posedge clk_i)
    sw_r <= sw;

  always_ff @ (posedge clk_i)
    if (rst_i)
      sw_r_vld <= 1'b0;
    else
      sw_r_vld <= 1'b1;

  always_ff @ (posedge clk_i)
    if (rst_i)
      irq_req_r <= 1'b0;
    else if (irq_req_gen &~ irq_req_r)
      irq_req_r <= 1'b1;
    else if (irq_ret_i & irq_req_r)
      irq_req_r <= 1'b0;

  // ------------
  // Output logic

  always_ff @ (posedge clk_i)
    if (rst_i)
      read_data_o <= 32'd0;
    else if (req_i &~ write_enable_i)
      case (addr_i [23:0])
        VALUE_ADDR : read_data_o <= 32'(sw_snapshot);
        default :;
      endcase

  // Here we won't turn req_o into combinational circuit
  // dependent on irq_req_gen, since in some testbenches
  // this can lead to X state propagation, which ruins
  // whole cpu's "trap" logic, therefore "stall" logic,
  // therefore "i_rf.write_enable_i" logic and so on.
  assign irq_req_o = /* irq_req_gen | */ irq_req_r;

endmodule
