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
    // assign abcdefgh   = '0;
    // assign digit      = '0;
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
		.clk        ( slow_clk  ),
		.resetn     ( ~rst      ),
		.trap       ( trap      ),
		.mem_valid  ( mem_valid ),
		.mem_instr  ( mem_instr ),
		.mem_ready  ( mem_ready ),
		.mem_addr   ( mem_addr  ),
		.mem_wdata  ( mem_wdata ),
		.mem_wstrb  ( mem_wstrb ),
		.mem_rdata  ( mem_rdata )
	);

    instruction_ram memory_file (
        .clk        ( slow_clk  ),
        .mem_valid  ( mem_valid ),
        .mem_ready  ( mem_ready ),
        .mem_addr   ( mem_addr  ),
        .mem_wstrb  ( mem_wstrb ),
        .mem_rdata  ( mem_rdata ),
        .mem_wdata  ( mem_wdata )
    );

    logic [w_led-1:0] led_reg;

    // Bind LEDs into 128 with bit shift 0..w_led
    always_ff @(posedge clk) begin
        if (rst) begin
            led_reg <= '0;
        end
        else if (mem_addr == 32'h10010100 && mem_valid) begin
            led_reg <= mem_wdata [0 +: w_led];
        end
    end

    assign led[w_led-1]   = mem_valid;
    assign led[w_led-2]   = mem_ready;
    assign led[w_led-3]   = trap;
    assign led[w_led-4:0] = led_reg;

    seven_segment_display
    # (
        .w_digit  ( w_digit * 4 ),
        .clk_mhz  ( clk_mhz  )
    )
    display
    (
        .clk      ( clk      ),
        .rst      ( rst      ),

        .number   ( ~key[0] ? (mem_addr >> 2) : mem_rdata ),
        .dots     ( '0       ),

        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
