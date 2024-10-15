`include "config.svh"

module board_specific_top
# (
    parameter clk_mhz  = 50,
              w_key    = 3,
              w_sw     = 0,
              w_led    = 8,
              w_digit  = 4,
              w_gpio   = 23 //MCY112 GPIO-B connector
)
(
	input wire clk, //100MHz on MCY112 FPGA board
	
	//keys & leds
	input wire  [1:0]key,
	output wire [7:0]led,
	
	//7-Segment Indicator
	output wire seg_a,
	output wire seg_b,
	output wire seg_c,
	output wire seg_d,
	output wire seg_e,
	output wire seg_f,
	output wire seg_g,
	output wire seg_p,
	output wire [3:0]seg_sel,

	//serial
	input  wire serial_rx,
	output wire serial_tx,

	//PCM1801 or PCM 1808 ADC
	output wire pcm_scki,
	output wire pcm_lrck,
	output wire pcm_bck,
	input wire  pcm_dout,

	//audio output delta-sigma
	output wire sound_out_l,
	output wire sound_out_r,
	
	//serial flash interface
	output wire flash_csb,
	output wire flash_clk,
	inout  wire flash_io0,
	inout  wire flash_io1,
	inout  wire flash_io2,
	inout  wire flash_io3,

	//Raspberry GPIO pins
	//inout wire gpio0, //JTAG TMS
	//inout wire gpio1, //JTAG TDO
	inout wire gpio2,
	input wire gpio3,
	input wire gpio4,
	inout wire gpio5,
	inout wire gpio6,
	//inout wire gpio7, //JTAG TCK
	inout wire gpio8,
	inout wire gpio9,
	inout wire gpio10,
	//inout wire gpio11, //JTAG TDI
	inout wire gpio12,
	inout wire gpio13,
	inout wire gpio14,
	inout wire gpio15,
	inout wire gpio16,
	inout wire gpio17,
	inout wire gpio18,
	inout wire gpio19,
	inout wire gpio20,
	inout wire gpio21,
	inout wire gpio22,
	inout wire gpio23,
	inout wire gpio24,
	inout wire gpio25,
	inout wire gpio26,
	inout wire gpio27,
	
	inout wire [27:0]gpio_a,
	
	inout wire [22:0]gpio_b,
	input wire [2:0]RESERVE

	//SDRAM
	/*
	output wire [11:0]mem_a,
	output wire [1:0]mem_ba,
	output wire mem_cs,
	output wire mem_cke,
	output wire mem_clk,
	output wire [3:0]mem_dqm,
	output wire mem_ras,
	output wire mem_cas,
	output wire mem_we,
	inout  wire [31:0]mem_dq
	*/
);

wire locked;
wire clk50;
wire clk24;
pll_div2 pll_div2_i(
	.inclk0( clk ),
	.c0( clk50 ),
	.c1( clk24 ),
	.locked( locked )
	);

    //------------------------------------------------------------------------
	//HIGH-COLOR VGA via Raspberry Pi VGA extender on MCY112 board GPIO-A conn
    wire vga_vs, vga_hs;
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;
	
	reg vga_vs_, vga_hs_;
    reg [3:0] vga_r_;
    reg [3:0] vga_g_;
    reg [3:0] vga_b_;
	 
	always @(posedge clk50)
	begin
		vga_r_  <= vga_r;
		vga_g_  <= vga_g;
		vga_b_  <= vga_b;
		vga_vs_ <= vga_vs;
		vga_hs_ <= vga_hs;
	end
	 
	assign gpio_a[21:16] = {vga_r_,2'b00};
	assign gpio_a[15:10] = {vga_g_,2'b00};
	assign gpio_a[ 9: 4] = {vga_b_,2'b00};
	assign gpio_a[2] = vga_vs_;
	assign gpio_a[3] = vga_hs_;
	assign gpio_a[1:0] = 0;
	assign gpio_a[27:22] = 0;

	//7-segment assignment bAfCgD.e
    wire [7:0]abcdefgh;
    wire [3:0]digit;
	assign seg_b = ~abcdefgh[6];
	assign seg_a = ~abcdefgh[7];
	assign seg_f = ~abcdefgh[2];
	assign seg_c = ~abcdefgh[5];
	assign seg_g = ~abcdefgh[1];
	assign seg_d = ~abcdefgh[4];
	assign seg_p = ~abcdefgh[0];
	assign seg_e = ~abcdefgh[3];
	assign seg_sel = { digit[0],digit[1],digit[2],digit[3] };
	
	wire [7:0]xleds;
	assign led = { xleds[0],xleds[1],xleds[2],xleds[3],xleds[4],xleds[5],xleds[6],xleds[7] };
	
	wire [23:0]mic; assign mic = 0;

    //------------------------------------------------------------------------
    //PCM sample rate is clk24/512=46875Hz
    assign pcm_scki = clk24;

	wire [15:0]Lchannel;
	wire [15:0]Rchannel;
	pcm1801 pcm1801_inst(
		.scki(clk24),
		.dout(pcm_dout),
		.lrck(pcm_lrck),
		.bck(pcm_bck),
		.Left(Lchannel),
		.Right(Rchannel)
	);

	//pass sound data to different clock domain
	reg [15:0]Lchannel_r;
	reg [15:0]Rchannel_r;
	reg [7:0]lrck_r;
	reg lrck_edge;
	always @(posedge clk50)
	begin
		lrck_r <= {lrck_r[6:0],pcm_lrck};
		lrck_edge <= (lrck_r==8'b00111111);
		if(lrck_edge)
		begin
			Lchannel_r <= Lchannel;
			Rchannel_r <= Rchannel;
		end
	end
	
	//additional 2button pcb required :-(
	//GPIO3 is used as a RESET 
	//GPIO4 is used as 3rd button
	wire [2:0]vkey = { ~gpio4, ~key[1], ~key[0] };
	wire reset = ~gpio3;
    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz     ),
        .w_key   ( w_key       ),
        .w_sw    ( 0           ),
        .w_led   ( w_led       ),
        .w_digit ( w_digit     ),
        .w_gpio  ( w_gpio      )
        /*
		.w_vgar  ( 5 ),
		.w_vgag  ( 5 ),
		.w_vgab  ( 5 )
		*/
    )
    i_top
    (
        .clk      ( clk50  ),
        .rst      ( reset  ),

        .key      ( vkey   ),
        .sw       ( 0      ),

        .led      ( xleds  ),

        .abcdefgh ( abcdefgh   ),
        .digit    ( digit      ),

        .vsync    ( vga_vs     ),
        .hsync    ( vga_hs     ),

        .red      ( vga_r      ),
        .green    ( vga_g      ),
        .blue     ( vga_b      ),

        .mic      ( {Lchannel_r,8'h00} ),
        .gpio     ( gpio_b     )
    );

//------------------------------------------------------------------------

endmodule
