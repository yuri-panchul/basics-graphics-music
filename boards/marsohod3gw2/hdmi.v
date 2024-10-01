// (c) fpga4fun.com & KNJN LLC 2013

////////////////////////////////////////////////////////////////////////
module HDMI(
	input clk_pixel,
	input clk_5x_pixel,
	input hsync,
	input vsync,
	input active,
	input [7:0]red,
	input [7:0]green,
	input [7:0]blue,
	output       tmds_clk_n,
	output       tmds_clk_p,
	output [2:0] tmds_d_n,
	output [2:0] tmds_d_p
);

wire [2:0] tmds_d0, tmds_d1, tmds_d2, tmds_d3, tmds_d4;
wire [2:0] tmds_d5, tmds_d6, tmds_d7, tmds_d8, tmds_d9;
wire [2:0] tmds_d;

	svo_tmds svo_tmds_0 (
		.clk( clk_pixel ),
		.resetn( 1'b1 ),
		.de( active ),
		.ctrl( {vsync,hsync} ),
		.din( blue ),
		.dout( {tmds_d9[0], tmds_d8[0], tmds_d7[0], tmds_d6[0], tmds_d5[0],
		       tmds_d4[0], tmds_d3[0], tmds_d2[0], tmds_d1[0], tmds_d0[0]} )
	);

	svo_tmds svo_tmds_1 (
		.clk( clk_pixel ),
		.resetn( 1'b1 ),
		.de( active ),
		.ctrl( 2'b0 ),
		.din( green ),
		.dout( {tmds_d9[1], tmds_d8[1], tmds_d7[1], tmds_d6[1], tmds_d5[1],
		       tmds_d4[1], tmds_d3[1], tmds_d2[1], tmds_d1[1], tmds_d0[1]} )
	);

	svo_tmds svo_tmds_2 (
		.clk( clk_pixel ),
		.resetn( 1'b1 ),
		.de( active ),
		.ctrl( 2'b0 ),
		.din( red ),
		.dout( {tmds_d9[2], tmds_d8[2], tmds_d7[2], tmds_d6[2], tmds_d5[2],
		       tmds_d4[2], tmds_d3[2], tmds_d2[2], tmds_d1[2], tmds_d0[2]} )
	);

	OSER10 tmds_serdes [2:0] (
		.Q(tmds_d),
		.D0(tmds_d0),
		.D1(tmds_d1),
		.D2(tmds_d2),
		.D3(tmds_d3),
		.D4(tmds_d4),
		.D5(tmds_d5),
		.D6(tmds_d6),
		.D7(tmds_d7),
		.D8(tmds_d8),
		.D9(tmds_d9),
		.PCLK(clk_pixel),
		.FCLK(clk_5x_pixel),
		.RESET(1'b0)
	);
	
	ELVDS_OBUF tmds_bufds [3:0] (
		.I({clk_pixel, tmds_d}),
		.O({tmds_clk_p, tmds_d_p}),
		.OB({tmds_clk_n, tmds_d_n})
	);

endmodule
