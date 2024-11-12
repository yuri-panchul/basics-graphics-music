module seg4x7(
	input		wire	clk,			// 100MHZ
	input		wire	[15:0] in,
	output	reg	[3:0] digit_sel,
	output	reg	[7:0] out
);

reg     [19:0] cnt;
always @ (posedge clk)
	cnt <= cnt +1'b1;

wire [1:0]digit_idx; assign digit_idx = cnt[19:18];
always @ (posedge clk)
	digit_sel <= 4'b0001 << digit_idx;

wire [3:0]a;
assign a = 	digit_sel[0] ? in[15:12] : 
				digit_sel[1] ? in[11:8] : 
				digit_sel[2] ? in[7:4]: in[3:0];
	
always @ (posedge clk)
	case(a)
		//	bAfCgD.e  
		4'h0:out <= 8'b00001010;//0
		4'h1:out <= 8'b01101111;//1
		4'h2:out <= 8'b00110010;//2
		4'h3:out <= 8'b00100011;//3
		4'h4:out <= 8'b01000111;//4
		4'h5:out <= 8'b10000011;//5
		4'h6:out <= 8'b10000010;//6
		4'h7:out <= 8'b00101111;//7
		4'h8:out <= 8'b00000010;//8
		4'h9:out <= 8'b00000011;//9
		4'ha:out <= 8'b00000110;//a
		4'hb:out <= 8'b11000010;//b
		4'hc:out <= 8'b10011010;//c
		4'hd:out <= 8'b01100010;//d
		4'he:out <= 8'b10010010;//e
		4'hf:out <= 8'b10010100;//f
	endcase

endmodule
