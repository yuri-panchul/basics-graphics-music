module jk_latch
(
	input clk,
	input j,
	input k,
	output q,
	output q_n
);
wire r = ~(q_n & j & clk);
wire s = ~(q & k & clk);
	sr_latch sr_latch
	(
	.r(r),
	.s(s),
	.q(q),
	.q_n(q_n)
	);
endmodule