/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from amfpga.
(C) COPYRIGHT 2013.www.amfpga.com ALL RIGHTS RESERVED
Filename			:		sdram_ov7670_vga.v
Author				:		Amfpga
Data				:		2013-02-1
Version				:		1.0
Description			:		sdram vga controller with ov7670 display.
Modification History	:
Data			By			Version			Change Description
===========================================================================
13/02/1
--------------------------------------------------------------------------*/
module	sdbank_switch
(
	input				clk,
	input				rst_n,
	input				bank_valid,
	input				frame_write_done,
	input				frame_read_done,
	
	output	reg	[1:0]	wr_bank,
	output	reg	[1:0]	rd_bank,
	output	reg			wr_load,
	output	reg			rd_load
);

//----------------------------------
//negedge of bank_valid signal
reg	bank_valid_r0, bank_valid_r1;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		bank_valid_r0 <= 0;
		bank_valid_r1 <= 0;
		end
	else
		begin
		bank_valid_r0 <= bank_valid;
		bank_valid_r1 <= bank_valid_r0;
		end
end
wire	bank_switch_flag = (bank_valid_r1 & ~bank_valid_r0) ? 1'b1 : 1'b0;	//negedge

//----------------------------------------
//switch banks--ping pang write
reg	[2:0]	state_write;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		wr_bank <= 2'b00;	//2'b11;
		wr_load <= 0;
		end
	else
		begin
		case(state_write)
		3'd0:	begin	wr_load <= 1'b0;	state_write <= 3'd1;	end
		3'd1:	begin	wr_load <= 1'b1; 	state_write <= 3'd2;	end
		3'd2:	begin	wr_load <= 1'b0; 	state_write <= 3'd3;	end
		3'd3:	begin
				if(bank_switch_flag)
					state_write <= 3'd4;
				else
					state_write <= 3'd3;
				end
		3'd4:	begin	
				if(frame_write_done)		//to be sure data with the same image has been wrote
					begin
					wr_bank <= ~wr_bank;
					state_write <= 3'd0;
					end
				else
					begin
					wr_bank <= wr_bank;
					state_write <= 3'd4;
					end
				end
		default:;
		endcase
		end
end

//----------------------------------------
//switch banks--ping pang read
reg	[2:0]	state_read;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		rd_bank <= 2'b11;	//2'b00;
		rd_load <= 1'b0;
		end
	else
		begin
		case(state_read)
		3'd0:	begin	rd_load <= 1'b0; 	state_read <= 3'd1;	end
		3'd1:	begin	rd_load <= 1'b1;	state_read <= 3'd2;	end
		3'd2:	begin	rd_load <= 1'b0;	state_read <= 3'd3;	end
		3'd3:	begin
				if(bank_switch_flag)
					state_read <= 3'd4;
				else
					state_read <= 3'd3;
				end
		3'd4:	begin	
				if(frame_read_done)		//to be sure data with the same image has been read
					begin
					rd_bank <= ~rd_bank;
					state_read <= 3'd0;
					end
				else
					begin
					rd_bank <= rd_bank;
					state_read <= 3'd4;
					end
				end
		default:;
		endcase
		end
end

endmodule
