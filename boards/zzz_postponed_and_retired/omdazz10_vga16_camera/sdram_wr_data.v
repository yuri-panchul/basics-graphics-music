`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: 
// Engineer		: 特权 franchises3
// Create Date	: 2009.05.11
// Design Name	: 
// Module Name	: sdram_wr_data
// Project Name	: 
// Target Device: Cyclone EP1C3T144C8 
// Tool versions: Quartus II 8.1
// Description	: SDRAM数据读写模块
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////
module sdram_wr_data(
					clk,rst_n,
					/*sdram_clk,*/sdram_data,
					sys_data_in,sys_data_out,
					work_state,cnt_clk
				);
	//系统信号
input clk;		//系统时钟，100MHz
input rst_n;	//复位信号，低电平有效
	// SDRAM硬件接口
//output sdram_clk;			// SDRAM时钟信号
inout[15:0] sdram_data;		// SDRAM数据总线
	// SDRAM封装接口
input[15:0] sys_data_in;	//写SDRAM时数据暂存器
output[15:0] sys_data_out;	//读SDRAM时数据暂存器

	// SDRAM内部接口
input[3:0] work_state;	//读写SDRAM时数据状态寄存器
input[8:0] cnt_clk;		//时钟计数

`include "sdram_para.v"		// 包含SDRAM参数定义模块

//assign sdram_clk = ~clk;	// SDRAM时钟信号

//------------------------------------------------------------------------------
//数据写入控制
//------------------------------------------------------------------------------
reg[15:0] sdr_din;	//突发数据写寄存器
reg sdr_dlink;		// SDRAM数据总线输入输出控制

	//将待写入数据送到SDRAM数据总线上
always @ (posedge clk or negedge rst_n) 
	if(!rst_n) sdr_din <= 16'd0;	//突发数据写寄存器复位
	else if((work_state == `W_WRITE) | (work_state == `W_WD)) sdr_din <= sys_data_in;	//连续写入存储在wrFIFO中的256个16bit数据

	//产生双向数据线方向控制逻辑
always @ (posedge clk or negedge rst_n) 
	if(!rst_n) sdr_dlink <= 1'b0;
   else if((work_state == `W_WRITE) | (work_state == `W_WD)) sdr_dlink <= 1'b1;
	else sdr_dlink <= 1'b0;

assign sdram_data = sdr_dlink ? sdr_din:16'hzzzz;

//------------------------------------------------------------------------------
//数据读出控制
//------------------------------------------------------------------------------
reg[15:0] sdr_dout;	//突发数据读寄存器	

	//将数据从SDRAM读出
always @ (posedge clk or negedge rst_n)
	if(!rst_n) sdr_dout <= 16'd0;	//突发数据读寄存器复位
	else if((work_state == `W_RD)/* & (cnt_clk > 9'd0) & (cnt_clk < 9'd10)*/) sdr_dout <= sdram_data;	//连续读出8B的16bit数据存储到rdFIFO中

assign sys_data_out = sdr_dout;

//------------------------------------------------------------------------------

endmodule
