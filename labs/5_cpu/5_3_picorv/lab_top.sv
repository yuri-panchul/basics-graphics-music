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
    wire                trap;
    wire                mem_valid;
	wire                mem_instr;
	reg                 mem_ready;
	wire [31:0]         mem_addr;
	wire [31:0]         mem_wdata;
	wire [3:0]          mem_wstrb;
	reg  [31:0]         mem_rdata;


	picorv32 picorv (
		.clk         (clk       ),
		.resetn      (rst       ),
		.trap        (trap      ),
		.mem_valid   (mem_valid ),
		.mem_instr   (mem_instr ),
		.mem_ready   (mem_ready ),
		.mem_addr    (mem_addr  ),
		.mem_wdata   (mem_wdata ),
		.mem_wstrb   (mem_wstrb ),
		.mem_rdata   (mem_rdata )
	);

	reg [31:0] memory [0:255];

	initial begin
        memory[0]  = 32'h0x00100413; 
        memory[1]  = 32'h0x100104b7;
        memory[2]  = 32'h0x00048493;
        // memory[3]  = 32'h0x10000913; // for w_led = 8
        memory[3]  = {12'(w_led**2), 20'h913};
        memory[4]  = 32'h0x00100293;
        memory[5]  = 32'h0xfff28293;
        memory[6]  = 32'h0xfe029ee3;
        memory[7]  = 32'h0x0084a023;
        memory[8]  = 32'h0x00141413;
        memory[9]  = 32'h0xff2416e3;
        memory[10] = 32'h0x00100413;
        memory[11] = 32'h0xfe5ff06f;
	end

	always @(posedge clk) begin
		if (mem_valid) begin
			if (mem_addr < 1024) begin
				mem_rdata <= memory[mem_addr >> 2];
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
			end
		end
	end

    assign mem_ready = mem_addr < 1024;

    // Bind LEDs into 128 with bit shift 0..w_led
    always_comb begin
        for (int idx = 0; idx < w_led; idx++) begin
            led[idx] = memory[128][idx];
        end
    end

endmodule
