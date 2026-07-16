package jtag_pkg;
  localparam logic [31:0] IDCODE = 32'hA5A5_A5A5;
  //============================================================
  // IR значения (как в RTL)
  //============================================================
  typedef enum logic [2:0] {
    IR_BYPASS     = 3'h7,
    IR_IDCODE     = 3'h1,
    IR_CONTROL    = 3'h2,
    IR_STATUS     = 3'h3,
    IR_BREAKPOINT = 3'h4,
    IR_CPU_RST    = 3'h5,
    IR_BLUSTER_RST= 3'h6
  } ir_t;

  //============================================================
  // STATUS struct (ДОЛЖЕН совпадать с RTL!)
  //============================================================
  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] mem_addr;
    logic [31:0] mem_data;
    logic        mem_we;
    logic [3:0]  mem_be;
    logic        halted;
    logic [31:0] breakpoint;
    logic        bp_armed;
    logic        padding;
  } status_t;

  localparam int STATUS_WIDTH = $bits(status_t);

  //============================================================
  // CONTROL struct
  //============================================================
  typedef struct packed {
    logic halt_request;
    logic resume_request;
    logic bp_arm_request;
    logic bp_disarm_request;
    logic step_request;
  } control_t;

  localparam int CONTROL_WIDTH = $bits(control_t);
`ifndef SYNTHESIS
  //============================================================
  // Low-level clock
  //============================================================
  task automatic jtag_clock(
    //task interface
    input logic tms_i,
    input logic tdi_i,
    output logic tdo_o,
    //dut interface
    ref logic tms_o,
    ref logic tdi_o,
    ref logic tck_o,
    ref  logic tdo_i
  );
    begin
      tck_o = 0;
      tms_o = tms_i;
      tdi_o = tdi_i;
      #100 tck_o = 1;
      tdo_o = tdo_i;
      #100 tck_o = 0;
    end
  endtask

  //============================================================
  // RESET
  //============================================================
  task automatic jtag_reset(ref logic tms_o, ref logic tdi_o, ref logic tck_o);
    logic dummy, tdo = 0;
    begin
      repeat (6) jtag_clock(1, 0, dummy, tms_o, tdi_o, tck_o, tdo);
      jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);
    end
  endtask

  //============================================================
  // SHIFT IR
  //============================================================
  task automatic jtag_shift_ir(input logic [2:0] ir_in, ref logic tms_o, ref logic tdi_o, ref logic tck_o);
    int i;
    logic dummy, tdo = 0;

    begin
      jtag_clock(1, 0, dummy, tms_o, tdi_o, tck_o, tdo);
      jtag_clock(1, 0, dummy, tms_o, tdi_o, tck_o, tdo);

      jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);
      jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);

      for (i = 0; i < 3; i++) begin
        jtag_clock((i == 2), ir_in[i], dummy, tms_o, tdi_o, tck_o, tdo);
      end

      jtag_clock(1, 0, dummy, tms_o, tdi_o, tck_o, tdo);
      jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);
    end
  endtask

  //============================================================
  // GENERIC SHIFT DR (параметризованный)
  //============================================================
  class jtag_task_wrapper #(int WIDTH = 32);
    static task automatic jtag_shift_dr(
      input  logic [WIDTH-1:0] din,
      output logic [WIDTH-1:0] dout,
      ref logic tms_o,
      ref logic tdi_o,
      ref logic tck_o,
      ref logic tdo_i
    );
      int i;
      logic dummy, tdo = 0;

      begin
        dout = '0;
        jtag_clock(1, 0, dummy, tms_o, tdi_o, tck_o, tdo);
        jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);
        jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);

        for (i = 0; i < WIDTH; i++) begin
          jtag_clock((i == WIDTH-1), din[i], dout[i],
                      tms_o, tdi_o, tck_o, tdo_i);
        end

        jtag_clock(1, 0, dummy, tms_o, tdi_o, tck_o, tdo);
        jtag_clock(0, 0, dummy, tms_o, tdi_o, tck_o, tdo);
      end
    endtask
  endclass

  //============================================================
  // READ IDCODE
  //============================================================
  task automatic read_idcode(output logic [31:0] idcode,
                              ref logic tms_o, ref logic tdi_o,
                              ref logic tck_o, ref logic tdo_i
  );
    logic [31:0] dout;
    logic [31:0] din;

    begin
      jtag_shift_ir(IR_IDCODE, tms_o, tdi_o, tck_o);

      din = '0;
      jtag_task_wrapper#(32)::jtag_shift_dr(din, dout, tms_o, tdi_o, tck_o, tdo_i);

      idcode = dout;
    end
  endtask

  //============================================================
  // Update CONTROL register
  //============================================================
  task automatic ctrl_req(input string field, ref logic tms_o, ref logic tdi_o, ref logic tck_o);
    control_t ctrl_in = '0;
    control_t ctrl_out;
    logic tdo = 0;

    case(field)
      "halt"      : ctrl_in.halt_request      = 1'b1;
      "resume"    : ctrl_in.resume_request    = 1'b1;
      "bp_arm"    : ctrl_in.bp_arm_request    = 1'b1;
      "bp_disarm" : ctrl_in.bp_disarm_request = 1'b1;
      "step"      : ctrl_in.step_request      = 1'b1;
    endcase
    jtag_shift_ir(IR_CONTROL, tms_o, tdi_o, tck_o);
    jtag_task_wrapper#(CONTROL_WIDTH)::jtag_shift_dr(
      ctrl_in,
      ctrl_out,
      tms_o,
      tdi_o,
      tck_o,
      tdo
    );
  endtask


  //============================================================
  // MONITOR (UNPACK через struct)
  //============================================================
  task automatic read_status(output status_t status, ref logic tms_o, ref logic tdi_o, ref logic tck_o, ref logic tdo_i);
    logic [STATUS_WIDTH-1:0] raw;
    logic [STATUS_WIDTH-1:0] din;

    begin
      jtag_shift_ir(IR_STATUS, tms_o, tdi_o, tck_o);

      din = '0;

      jtag_task_wrapper#(STATUS_WIDTH)::jtag_shift_dr(
        din,
        raw,
        tms_o,
        tdi_o,
        tck_o,
        tdo_i
      );

      status = status_t'(raw); // UNPACK
    end
  endtask

  task automatic set_breakpoint(input logic [31:0] addr, ref logic tms_o, ref logic tdi_o, ref logic tck_o, ref logic tdo_i);
    logic [31:0] dummy;

    jtag_shift_ir(IR_BREAKPOINT, tms_o, tdi_o, tck_o);
    jtag_task_wrapper#(32)::jtag_shift_dr(addr, dummy, tms_o, tdi_o, tck_o, tdo_i);
  endtask

  task automatic cpu_reset(ref logic tms_o, ref logic tdi_o, ref logic tck_o, ref logic tdo_i);
    jtag_shift_ir(IR_CPU_RST, tms_o, tdi_o, tck_o);
  endtask

  task automatic bluster_reset(ref logic tms_o, ref logic tdi_o, ref logic tck_o, ref logic tdo_i);
    jtag_shift_ir(IR_BLUSTER_RST, tms_o, tdi_o, tck_o);
  endtask

  function automatic void print_status(status_t status);
    $display("STATUS:\n  PC=%08x\n  INSTR=%08x\n  MEM_ADDR=%08x\n  MEM_DATA=%08x\n  MEM_WE=%b\n  MEM_BE=%b\n  HALTED=%b\n  BREAKPOINT=%08x\n  BP_ARMED=%b",
      status.pc, status.instr, status.mem_addr, status.mem_data, status.mem_we, status.mem_be, status.halted, status.breakpoint, status.bp_armed
    );
  endfunction
`endif
endpackage
