module sr_latch
(
	input r,
	input s,
	output q,
	output q_n
);
	assign q = ~(q_n | r);
	assign q_n = ~(q | s);
endmodule
