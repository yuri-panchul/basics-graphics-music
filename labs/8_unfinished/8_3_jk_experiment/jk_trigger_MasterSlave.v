module jk_trigger_MasterSlave
(
	input clk,
	input j,
	input k,
	output q,
	output q_n
);
	wire q1, q1_n;
	wire r1 = ~(j & clk & q_n);
	wire s1 = ~(k & clk & q);	
	sr_latch master
		(
			.r(r1),
			.s(s1),
			.q(q1),
			.q_n(q1_n)
		);
		wire r2 = ~(r1 & q1);
		wire s2 = ~(s1 & q1_n);
		sr_latch slave
		(
			.r(r2),
			.s(s2),
			.q(q),
			.q_n(q_n)
		);
endmodule