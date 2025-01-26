`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: 
// Engineer		: 特权 franchises3
// Create Date	: 2009.05.11
// Design Name	: 
// Module Name	: sdram_top
// Project Name	: 
// Target Device: Cyclone EP1C3T144C8 
// Tool versions: Quartus II 8.1
// Description	: SDRAM封装控制顶层模块
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////
/*-----------------------------------------------------------------------------
SDRAM接口说明：
	上电复位时，SDRAM会自动等待200us然后进行初始化，具体模式寄存器的
设置参看sdram_ctrl模块。
	SDRAM的操作：
		控制sys_en=1,sys_r_wn=0,sys_addr,sys_data_in进行SDRAM数据写入
	操作；控制sys_en=1,sys_r_wn=1,sys_addr即可从sys_data_out读出数据。
	同时可以通过查询sdram_busy的状态查看读写是否完成。	
-----------------------------------------------------------------------------*/
module sdram_top(
				clk,rst_n,
				sdram_wr_req,sdram_rd_req,sdram_wr_ack,sdram_rd_ack,
				sys_wraddr,sys_rdaddr,
				sys_data_in,sys_data_out,sdwr_byte,sdrd_byte,//sdram_busy,sys_dout_rdy,
				/*sdram_clk,*/sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,
				sdram_we_n,sdram_ba,sdram_addr,sdram_data,//sdram_udqm,sdram_ldqm
				sdram_init_done
			);

input clk;		//系统时钟，100MHz
input rst_n;	//复位信号，低电平有效

	// SDRAM的封装接口
input sdram_wr_req;			//系统写SDRAM请求信号
input sdram_rd_req;			//系统读SDRAM请求信号
output sdram_wr_ack;		//系统写SDRAM响应信号,作为wrFIFO的输出有效信号
output sdram_rd_ack;		//系统读SDRAM响应信号
input[21:0] sys_wraddr;		// 写SDRAM时地址暂存器，(bit21-20)L-Bank地址:(bit19-8)为行地址，(bit7-0)为列地址 
input[21:0] sys_rdaddr;		// 读SDRAM时地址暂存器，(bit21-20)L-Bank地址:(bit19-8)为行地址，(bit7-0)为列地址 
input[15:0] sys_data_in;	//写SDRAM时数据暂存器，4个突发读写字数据，默认为00地址bit15-0;01地址bit31-16;10地址bit47-32;11地址bit63-48
output[15:0] sys_data_out;	//读SDRAM时数据暂存器,(格式同上)
input[8:0] sdwr_byte;		//突发写SDRAM字节数（1-256个）
input[8:0] sdrd_byte;		//突发读SDRAM字节数（1-256个）
//output sdram_busy;			// SDRAM忙标志，高表示SDRAM处于工作中
//output sys_dout_rdy;		// SDRAM数据输出完成标志
output	sdram_init_done;	//系统初始化完毕信号

	// FPGA与SDRAM硬件接口
//output sdram_clk;			// SDRAM时钟信号
output sdram_cke;			// SDRAM时钟有效信号
output sdram_cs_n;			// SDRAM片选信号
output sdram_ras_n;			// SDRAM行地址选通脉冲
output sdram_cas_n;			// SDRAM列地址选通脉冲
output sdram_we_n;			// SDRAM写允许位
output[1:0] sdram_ba;		// SDRAM的L-Bank地址线
output[11:0] sdram_addr;	// SDRAM地址总线
inout[15:0] sdram_data;		// SDRAM数据总线
//output sdram_udqm;		// SDRAM高字节屏蔽
//output sdram_ldqm;		// SDRAM低字节屏蔽

	// SDRAM内部接口
wire[3:0] init_state;	// SDRAM初始化寄存器
wire[3:0] work_state;	// SDRAM工作状态寄存器
wire[8:0] cnt_clk;		//时钟计数	
wire sys_r_wn;			// SDRAM读/写控制信号
				
sdram_ctrl		module_001(		// SDRAM状态控制模块
									.clk(clk),						
									.rst_n(rst_n),
							//		.sdram_udqm(sdram_udqm),
							//		.sdram_ldqm(sdram_ldqm)													
									.sdram_wr_req(sdram_wr_req),
									.sdram_rd_req(sdram_rd_req),
									.sdram_wr_ack(sdram_wr_ack),
									.sdram_rd_ack(sdram_rd_ack),
									.sdwr_byte(sdwr_byte),
									.sdrd_byte(sdrd_byte),							
							//		.sdram_busy(sdram_busy),
							//		.sys_dout_rdy(sys_dout_rdy),
									.sdram_init_done(sdram_init_done),
									//
									.init_state(init_state),
									.work_state(work_state),
									.cnt_clk(cnt_clk),
									.sys_r_wn(sys_r_wn)
								);

sdram_cmd		module_002(		// SDRAM命令模块
									.clk(clk),
									.rst_n(rst_n),
									.sdram_cke(sdram_cke),		
									.sdram_cs_n(sdram_cs_n),	
									.sdram_ras_n(sdram_ras_n),	
									.sdram_cas_n(sdram_cas_n),	
									.sdram_we_n(sdram_we_n),	
									.sdram_ba(sdram_ba),			
									.sdram_addr(sdram_addr),									
									.sys_wraddr(sys_wraddr),	
									.sys_rdaddr(sys_rdaddr),
									.sdwr_byte(sdwr_byte),
									.sdrd_byte(sdrd_byte),		
									.init_state(init_state),	
									.work_state(work_state),
									.sys_r_wn(sys_r_wn),
									.cnt_clk(cnt_clk)
								);

sdram_wr_data	module_003(		// SDRAM数据读写模块
									.clk(clk),
									.rst_n(rst_n),
							//		.sdram_clk(sdram_clk),
									.sdram_data(sdram_data),
									.sys_data_in(sys_data_in),
									.sys_data_out(sys_data_out),
									.work_state(work_state),
									.cnt_clk(cnt_clk)
								);
endmodule

