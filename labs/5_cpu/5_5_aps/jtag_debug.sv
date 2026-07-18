//============================================================
// Minimal OpenOCD-compatible JTAG Debug Module
// - IEEE-like TAP FSM
// - IR: IDCODE / BYPASS / CONTROL / STATUS
// - DR: deterministic scan registers
//============================================================

module jtag_debug (
  // JTAG
  input  logic trst_i,
  input  logic tck_i,
  input  logic tms_i,
  input  logic tdi_i,
  output logic tdo_o,
  output logic tdo_en_o,

  // CPU clock domain
  input  logic clk_i,
  input  logic rst_i,

  // system inputs (STATUS)
  input  logic [31:0] pc_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_addr_i,
  input  logic [31:0] mem_data_i,
  input  logic        mem_we_i,
  input  logic [3:0]  mem_be_i,

  // control outputs
  output logic halt_o,
  output logic step_o,
  output logic cpu_rst_o,
  output logic bluster_rst_o

`ifdef PLATFORM_NMTECH_130
  , input logic       dft_test_en
`endif
);

  import jtag_pkg::ir_t;
  import jtag_pkg::IR_BYPASS;
  import jtag_pkg::IR_IDCODE;
  import jtag_pkg::IR_CONTROL;
  import jtag_pkg::IR_STATUS;
  import jtag_pkg::IR_BREAKPOINT;
  import jtag_pkg::IR_CPU_RST;
  import jtag_pkg::IR_BLUSTER_RST;

  import jtag_pkg::status_t;
  import jtag_pkg::control_t;
  import jtag_pkg::IDCODE;

  typedef enum logic [3:0] {
    TEST_LOGIC_RESET  = 4'h0,
    RUN_TEST_IDLE     = 4'h1,

    SELECT_DR_SCAN    = 4'h2,
    CAPTURE_DR        = 4'h3,
    SHIFT_DR          = 4'h4,
    EXIT1_DR          = 4'h5,
    PAUSE_DR          = 4'h6,
    EXIT2_DR          = 4'h7,
    UPDATE_DR         = 4'h8,

    SELECT_IR_SCAN    = 4'h9,
    CAPTURE_IR        = 4'ha,
    SHIFT_IR          = 4'hb,
    EXIT1_IR          = 4'hc,
    PAUSE_IR          = 4'hd,
    EXIT2_IR          = 4'he,
    UPDATE_IR         = 4'hf
  } tap_state_t;

  tap_state_t state, next;

  always_ff @(posedge tck_i or posedge trst_i) begin
    if (trst_i)
      state <= TEST_LOGIC_RESET;
    else
      state <= next;
  end

  always_comb begin
    next = state;

    case (state)
      TEST_LOGIC_RESET: next = tms_i ? TEST_LOGIC_RESET : RUN_TEST_IDLE;

      RUN_TEST_IDLE:    next = tms_i ? SELECT_DR_SCAN : RUN_TEST_IDLE;

      SELECT_DR_SCAN:   next = tms_i ? SELECT_IR_SCAN : CAPTURE_DR;

      CAPTURE_DR:       next = tms_i ? EXIT1_DR : SHIFT_DR;
      SHIFT_DR:         next = tms_i ? EXIT1_DR : SHIFT_DR;
      EXIT1_DR:         next = tms_i ? UPDATE_DR : PAUSE_DR;
      PAUSE_DR:         next = tms_i ? EXIT2_DR : PAUSE_DR;
      EXIT2_DR:         next = tms_i ? UPDATE_DR : SHIFT_DR;
      UPDATE_DR:        next = tms_i ? SELECT_DR_SCAN : RUN_TEST_IDLE;

      SELECT_IR_SCAN:   next = tms_i ? TEST_LOGIC_RESET : CAPTURE_IR;

      CAPTURE_IR:       next = tms_i ? EXIT1_IR : SHIFT_IR;
      SHIFT_IR:         next = tms_i ? EXIT1_IR : SHIFT_IR;
      EXIT1_IR:         next = tms_i ? UPDATE_IR : PAUSE_IR;
      PAUSE_IR:         next = tms_i ? EXIT2_IR : PAUSE_IR;
      EXIT2_IR:         next = tms_i ? UPDATE_IR : SHIFT_IR;
      UPDATE_IR:        next = tms_i ? SELECT_DR_SCAN : RUN_TEST_IDLE;
    endcase
  end

  wire tlr        = (state == TEST_LOGIC_RESET);
  wire capture_ir = (state == CAPTURE_IR);
  wire shift_ir   = (state == SHIFT_IR);
  wire update_ir  = (state == UPDATE_IR);

  wire capture_dr = (state == CAPTURE_DR);
  wire shift_dr   = (state == SHIFT_DR);
  wire update_dr  = (state == UPDATE_DR);

  logic jtag_rst;
`ifdef PLATFORM_NMTECH_130 
  assign jtag_rst = dft_test_en ? trst_i : trst_i | tlr;
`else
  assign jtag_rst = trst_i | tlr;
`endif

  //============================================================
  // TCK domain logic
  //============================================================
  logic [$bits(ir_t)-1:0] ir;
  logic [$bits(ir_t)-1:0] ir_shift;
  logic [31:0] idcode_shift;

  logic [31:0] breakpoint;
  logic [31:0] breakpoint_shift;

  control_t control_reg, control_shift;
  status_t status_shift, status_sync;
  //============================================================
  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      ir <= IR_IDCODE;
    end
    else begin
      if(update_ir)
        ir <= ir_shift;
    end
  end

  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      ir_shift <= '0;
    end
    else begin
      if(capture_ir) begin
        ir_shift <= 3'b001;
      end
      else if(shift_ir) begin
        ir_shift <= {tdi_i, ir_shift[$bits(ir_t)-1:1]};
      end
    end
  end

  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if (jtag_rst)
      idcode_shift <= IDCODE;
    else if (capture_dr && ir == IR_IDCODE)
      idcode_shift <= IDCODE;
    else if (shift_dr && ir == IR_IDCODE)
      idcode_shift <= {tdi_i, idcode_shift[31:1]};
  end

  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      breakpoint <= '0;
    end
    else begin
      if(update_dr && (ir == IR_BREAKPOINT)) begin
        breakpoint <= breakpoint_shift;
      end
    end
  end

  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      breakpoint_shift <= '0;
    end
    else begin
      if(capture_dr && (ir == IR_BREAKPOINT)) begin
        breakpoint_shift <= breakpoint;
      end
      else if(shift_dr && (ir == IR_BREAKPOINT)) begin
        breakpoint_shift <= {tdi_i, breakpoint_shift[31:1]};
      end
    end
  end

  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      control_reg <= '0;
    end
    else begin
      if(update_dr && (ir == IR_CONTROL)) begin
        control_reg <= control_shift;
      end
    end
  end

  always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      control_shift <= '0;
    end
    else begin
      if(capture_dr && (ir == IR_CONTROL)) begin
        control_shift <= control_reg;
      end
      else if(shift_dr && (ir == IR_CONTROL)) begin
        control_shift <= {tdi_i, control_shift[$bits(control_t)-1:1]};
      end
    end
  end

   always_ff @(posedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      status_shift <= '0;
    end
    else begin
      if(capture_dr && (ir == IR_STATUS)) begin
        status_shift <= status_sync;
      end
      else if(shift_dr && (ir == IR_STATUS)) begin
        status_shift <= {tdi_i, status_shift[$bits(status_t)-1:1]};
      end
    end
  end

  assign tdo_en_o = state inside {SHIFT_IR, SHIFT_DR};

  always_ff @(negedge tck_i or posedge jtag_rst) begin
    if(jtag_rst) begin
      tdo_o <= 1'b0;
    end
    else begin
      case (state)
        SHIFT_IR: tdo_o <= ir_shift[0];
        SHIFT_DR: begin
          case (ir)
            IR_IDCODE     : tdo_o <= idcode_shift[0];
            IR_STATUS     : tdo_o <= status_shift[0];
            IR_CONTROL    : tdo_o <= control_shift[0];
            IR_BYPASS     : tdo_o <= tdi_i;
            IR_BREAKPOINT : tdo_o <= breakpoint_shift[0];
            default       : tdo_o <= 1'b0;
          endcase
        end
        default: tdo_o <= 1'b0;
      endcase
    end
  end

  //============================================================
  // System domain logic
  //============================================================
  logic halt, halt_set, bp_arm, bp_hit;
  logic [31:0] breakpoint_sync;
  logic halt_req, resume_req, bp_arm_req, bp_disarm_req;
  status_t status_snapshot;

  assign bp_hit = bp_arm && (pc_i == breakpoint_sync);
  assign halt_set = halt_req | bp_hit;
  assign halt_o = halt | halt_set;

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      halt <= 1'b0;
    end
    else begin
      if(halt_set)
        halt <= 1'b1;
      else if(resume_req)
        halt <= 1'b0;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      bp_arm <= 1'b0;
    end
    else begin
      if(bp_arm_req)
        bp_arm <= 1'b1;
      else if(bp_disarm_req)
        bp_arm <= 1'b0;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      status_snapshot <= '0;
    end
    else begin
      if(halt) begin
        status_snapshot <= status_t'({
        pc_i,
        instr_i,
        mem_addr_i,
        mem_data_i,
        mem_we_i,
        mem_be_i,
        halt_o,
        breakpoint_sync,
        bp_arm,
        1'b0
      });
      end
    end
  end
  //============================================================


  //============================================================
  // CDC
  //============================================================
    cdc_pulse_sync halt_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_dr & (ir == IR_CONTROL) & control_shift.halt_request),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(halt_req)
  );

  cdc_pulse_sync resume_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_dr & (ir == IR_CONTROL) & control_shift.resume_request),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(resume_req)
  );

  cdc_pulse_sync bp_arm_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_dr & (ir == IR_CONTROL) & control_shift.bp_arm_request),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(bp_arm_req)
  );

  cdc_pulse_sync bp_disarm_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_dr & (ir == IR_CONTROL) & control_shift.bp_disarm_request),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(bp_disarm_req)
  );

  cdc_pulse_sync step_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_dr & (ir == IR_CONTROL) & control_shift.step_request),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(step_o)
  );

  cdc_pulse_sync cpu_rst_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_ir & (ir_shift == IR_CPU_RST)),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(cpu_rst_o)
  );

  cdc_pulse_sync bluster_rst_sync (
    .src_clk_i(tck_i),
    .src_rst_i(jtag_rst),
    .src_pulse_i(update_ir & (ir_shift == IR_BLUSTER_RST)),
    .dst_clk_i(clk_i),
    .dst_rst_i(rst_i),
    .dst_pulse_o(bluster_rst_o)
  );

  always_ff @(posedge tck_i) begin
    if(jtag_rst) begin
      status_sync <= '0;
    end else begin
      status_sync <= status_snapshot;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      breakpoint_sync <= '0;
    end else begin
      breakpoint_sync <= breakpoint;
    end
  end
  //============================================================

endmodule
