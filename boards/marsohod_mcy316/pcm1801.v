
module pcm1801(
	input wire scki,
	input wire dout,
	output wire lrck,
	output wire bck,
	output reg[15:0]Left,
	output reg[15:0]Right
);

reg [8:0]cnt;
always @(posedge scki)
	cnt <= cnt+1;

assign lrck = cnt[8];
assign bck = cnt[3];

reg [15:0]LeftSR;
reg [15:0]RightSR;

always @(posedge bck)
begin
	if(lrck==1'b1)
	begin
		LeftSR <= { LeftSR[14:0], dout };
		if( cnt[7:4]==4'hF )
			Left<= { LeftSR[14:0], dout };
	end
	if(lrck==1'b0)
	begin
		RightSR <= { RightSR[14:0], dout };
		if( cnt[7:4]==4'hF )
			Right<= { RightSR[14:0], dout };
	end
end

endmodule
