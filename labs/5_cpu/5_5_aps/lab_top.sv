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
    assign abcdefgh   = '0;
    assign digit      = '0;
    assign red        = '0;
    assign green      = '0;
    assign blue       = '0;
    assign sound      = '0;
    assign uart_tx    = '1;

    //------------------------------------------------------------------------
    logic [255:0] req;
    logic [31:0]  rdata[9];
    logic         ready[9];

    logic irq_req;
    logic irq_ret;

    // Instr mem ports signals
    logic [31:0] instr_addr;
    logic [31:0] instr;

    // LSU ports signals
    logic         core_stall;
    logic         core_req;
    logic         core_we;
    logic [ 2:0]  core_size;
    logic [31:0]  core_wd;
    logic [31:0]  core_addr;
    logic [31:0]  core_rd;
    logic         mem_ready;
    logic         mem_req;
    logic         mem_we;
    logic [ 3:0]  mem_be;
    logic [31:0]  mem_wd;
    logic [31:0]  mem_addr;
    logic [31:0]  mem_rd;

    // ----------------------
    // Modules instantiations

    instr_mem imem(
        .read_addr_i(instr_addr),
        .read_data_o(instr     )
    );

    lsu lsu_inst (
        .clk_i        (slow_clk   ),
        .rst_i        (rst        ),
        .core_req_i   (core_req   ),
        .core_we_i    (core_we    ),
        .core_size_i  (core_size  ),
        .core_addr_i  (core_addr  ),
        .core_wd_i    (core_wd    ),
        .core_rd_o    (core_rd    ),
        .core_stall_o (core_stall ),
        .mem_req_o    (mem_req    ),
        .mem_we_o     (mem_we     ),
        .mem_be_o     (mem_be     ),
        .mem_addr_o   (mem_addr   ),
        .mem_wd_o     (mem_wd     ),
        .mem_rd_i     (mem_rd     ),
        .mem_ready_i  (mem_ready  )
    );

    logic [31:0] clear_addr;
    assign clear_addr = {8'd0, mem_addr[23:0]};

    logic trap;  // Exposed for demo

    processor_core core_inst(
        .clk_i        (slow_clk   ),
        .rst_i        (rst        ),
        .instr_addr_o (instr_addr ),
        .instr_i      (instr      ),
        .stall_i      (core_stall ),
        .mem_rd_i     (core_rd    ),
        .irq_req_i    (irq_req    ),
        .mem_req_o    (core_req   ),
        .mem_we_o     (core_we    ),
        .mem_size_o   (core_size  ),
        .mem_wd_o     (core_wd    ),
        .mem_addr_o   (core_addr  ),
        .irq_ret_o    (irq_ret    ),
        .trap_o       (trap       )
    );

    data_mem dmem_inst(
        .clk_i          (slow_clk   ),
        .mem_req_i      (req[0]     ),
        .write_enable_i (mem_we     ),
        .byte_enable_i  (mem_be     ),
        .write_data_i   (mem_wd     ),
        .addr_i         (clear_addr ),
        .read_data_o    (rdata[0]   ),
        .ready_o        (ready[0]   )
    );

    sw_sb_ctrl #(.w_sw(w_sw)) sw_inst(
        .clk_i          (slow_clk   ),
        .deb_clk_i      (clk        ),
        .rst_i          (rst        ),
        .req_i          (req[1]     ),
        .write_enable_i (mem_we     ),
        .addr_i         (clear_addr ),
        .write_data_i   (mem_wd     ),
        .read_data_o    (rdata[1]   ),
        .irq_ret_i      (irq_ret    ),
        .irq_req_o      (irq_req    ),
        .sw_i           (sw         )
    );

    logic [w_led - 4:0] led_o;

    led_sb_ctrl #(.w_led(w_led - 3)) led_inst(
        .clk_i          (slow_clk   ),
        .rst_i          (rst        ),
        .req_i          (req[2]     ),
        .write_enable_i (mem_we     ),
        .addr_i         (clear_addr ),
        .write_data_i   (mem_wd     ),
        .read_data_o    (rdata[2]   ),
        .led_o          (led_o      )
    );

    assign led = {led_o, trap, 1'(|req), slow_clk};

    //=====================================================

    assign req = (255'd1 << mem_addr[31:24]) & {{256{mem_req}}};

    always_comb begin
    case(mem_addr[31:24])
        8'd0: mem_rd = rdata[0];
        8'd1: mem_rd = rdata[1];
        8'd2: mem_rd = rdata[2];
        // 8'd3: mem_rd = rdata[3];
        // 8'd4: mem_rd = rdata[4];
        // 8'd5: mem_rd = rdata[5];
        // 8'd6: mem_rd = rdata[6];
        // 8'd7: mem_rd = rdata[7];
        // 8'd8: mem_rd = rdata[8];
        default: mem_rd = '0;
    endcase
    end

    always_comb begin
    case(mem_addr[31:24])
        8'd0: mem_ready = ready[0];
        8'd1: mem_ready = 1'b1;
        8'd2: mem_ready = 1'b1;
        // 8'd3: mem_ready = ready[3];
        // 8'd4: mem_ready = ready[4];
        // 8'd5: mem_ready = ready[5];
        // 8'd6: mem_ready = ready[6];
        // 8'd7: mem_ready = ready[7];
        // 8'd8: mem_ready = ready[8];
        default: mem_ready = '0;
    endcase
    end

endmodule
