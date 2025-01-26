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
`timescale 1 ns / 1 ns
module system_ctrl
(
	input 		clk,		//50MHz
	input 		rst_n,		//global reset

	output 		sys_rst_n,	//system reset
	output 		clk_c0,		
	output 		clk_c1,
	output		clk_c2	//-75deg
);

//----------------------------------------------
//rst_n synchronism, is controlled by the input clk
reg     rst_nr1,rst_nr2;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		rst_nr1 <= 1'b0;
		rst_nr2 <= 1'b0;
		end
	else
		begin
		rst_nr1 <= 1'b1;
		rst_nr2 <= rst_nr1;
		end
end

//----------------------------------
//component instantiation for system_delay
wire	delay_done;
system_delay	u_system_delay
(
	.clk		(clk),
	.rst_n		(rst_nr2),
	.delay_done	(delay_done)
);
wire	pll_rst = ~rst_nr2 & ~delay_done;	//active High

//----------------------------------------------
//Component instantiation
wire 	locked;	
sdram_pll	u_sdram_pll
(
	.inclk0	(clk),
	.areset	(pll_rst),
	.locked	(locked),
			
	.c0		(clk_c0),
	.c1		(clk_c1),
	.c2		(clk_c2)
);

//----------------------------------------------
//sys_rst_n synchronism, is control by the highest output clk
  
wire	sysrst_nr0 = rst_nr2 & locked & delay_done;  
reg 	sysrst_nr1, sysrst_nr2; 
always @(posedge clk_c1 or negedge sysrst_nr0)
begin
	if(!sysrst_nr0) 
        begin
        sysrst_nr1 <= 1'b0;
        sysrst_nr2 <= 1'b0;
        end        
	else 
        begin
        sysrst_nr1 <= 1'b1;
        sysrst_nr2 <= sysrst_nr1;
        end
end
assign sys_rst_n = sysrst_nr2;	//active Low

endmodule

//################################################//
//################################################//

module system_delay
(
	input	clk,		//50MHz
	input	rst_n,
	output	delay_done
);

//------------------------------------------
// Delay 100ms for steady state
localparam	DELAY_CNT = 23'd100_0000;	//50ms
reg	[22:0] cnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt <= 0;
	else
		begin
		if(cnt < DELAY_CNT) //1ms
			cnt <= cnt + 1'b1;
		else
			cnt <= cnt;
		end
end

//------------------------------------------
//sys_rst_n synchronism
assign	delay_done = (cnt == DELAY_CNT)? 1'b1 : 1'b0;

endmodule
