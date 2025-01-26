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
// Description	: SDRAM状态控制模块
//							SDRAM初始化以及定时刷新、读写控制
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////
module sdram_ctrl(
				clk,rst_n,
				/*sdram_udqm,sdram_ldqm,*/
				sdram_wr_req,sdram_rd_req,
				sdwr_byte,sdrd_byte,
				sdram_wr_ack,sdram_rd_ack,
				//sdram_busy,
				sdram_init_done,
				init_state,work_state,cnt_clk,sys_r_wn
			);
	//系统信号接口
input clk;				//系统时钟，50MHz
input rst_n;			//复位信号，低电平有效

	// SDRAM硬件接口
//output sdram_udqm;	// SDRAM高字节屏蔽
//output sdram_ldqm;	// SDRAM低字节屏蔽
	// SDRAM封装接口
input sdram_wr_req;			//系统写SDRAM请求信号
input sdram_rd_req;			//系统读SDRAM请求信号
input[8:0] sdwr_byte;		//突发写SDRAM字节数（1-256个）
input[8:0] sdrd_byte;		//突发读SDRAM字节数（1-256个）
output sdram_wr_ack;		//系统写SDRAM响应信号,作为wrFIFO的输出有效信号
output sdram_rd_ack;		//系统读SDRAM响应信号	

output	sdram_init_done;		//系统初始化完毕信号
//output sdram_busy;		// SDRAM忙标志位，高表示忙

	// SDRAM内部接口
output[3:0] init_state;	// SDRAM初始化寄存器
output[3:0] work_state;	// SDRAM工作状态寄存器
output[8:0] cnt_clk;	//时钟计数
output sys_r_wn;		// SDRAM读/写控制信号

wire done_200us;		//上电后200us输入稳定期结束标志位
//wire sdram_init_done;	// SDRAM初始化完成标志，高表示完成
wire sdram_busy;		// SDRAM忙标志，高表示SDRAM处于工作中
reg sdram_ref_req;		// SDRAM自刷新请求信号
wire sdram_ref_ack;		// SDRAM自刷新请求应答信号

`include "sdram_para.v"		// 包含SDRAM参数定义模块

	// SDRAM时序延时参数
parameter		TRP_CLK		= 9'd4,//1,	//TRP=18ns预充电有效周期
				TRFC_CLK	= 9'd6,//3,	//TRC=60ns自动预刷新周期
				TMRD_CLK	= 9'd6,//2,	//模式寄存器设置等待时钟周期
				TRCD_CLK	= 9'd2,//1,	//TRCD=18ns行选通周期
				TCL_CLK		= 9'd3,		//潜伏期TCL_CLK=3个CLK，在初始化模式寄存器中可设置
				//TREAD_CLK	= 9'd256,//8,		//突发读数据周期8CLK
				//TWRITE_CLK	= 9'd256,//8,  	//突发写数据8CLK
				TDAL_CLK	= 9'd3;		//写入等待

//------------------------------------------------------------------------------
//assign sdram_udqm = 1'b0;	// SDRAM数据高字节有效
//assign sdram_ldqm = 1'b0;	// SDRAM数据低字节有效

//------------------------------------------------------------------------------
//上电后200us计时,计时时间到,则done_200us=1
//------------------------------------------------------------------------------
reg[14:0] cnt_200us; 
always @ (posedge clk or negedge rst_n) 
	if(!rst_n) cnt_200us <= 15'd0;
	else if(cnt_200us < 15'd20_000) cnt_200us <= cnt_200us+1'b1;	//计数

assign done_200us = (cnt_200us == 15'd20_000);

//------------------------------------------------------------------------------
//SDRAM的初始化操作状态机
//------------------------------------------------------------------------------
reg[3:0] init_state_r;	// SDRAM初始化状态

always @ (posedge clk or negedge rst_n)
	if(!rst_n) init_state_r <= `I_NOP;
	else 
		case (init_state_r)
				`I_NOP: 	init_state_r <= done_200us ? `I_PRE:`I_NOP;		//上电复位后200us结束则进入下一状态
				`I_PRE: 	init_state_r <= `I_TRP;		//预充电状态
				`I_TRP: 	init_state_r <= (`end_trp) ? `I_AR1:`I_TRP;			//预充电等待TRP_CLK个时钟周期
				`I_AR1: 	init_state_r <= `I_TRF1;	//第1次自刷新
				`I_TRF1:	init_state_r <= (`end_trfc) ? `I_AR2:`I_TRF1;			//等待第1次自刷新结束,TRFC_CLK个时钟周期
				`I_AR2: 	init_state_r <= `I_TRF2; 	//第2次自刷新	
				`I_TRF2:	init_state_r <= (`end_trfc) ? `I_MRS:`I_TRF2; 		//等待第2次自刷新结束,TRFC_CLK个时钟周期
				`I_MRS:		init_state_r <= `I_TMRD;//模式寄存器设置（MRS）	
				`I_TMRD:	init_state_r <= (`end_tmrd) ? `I_DONE:`I_TMRD;		//等待模式寄存器设置完成,TMRD_CLK个时钟周期
				`I_DONE:	init_state_r <= `I_DONE;		// SDRAM的初始化设置完成标志
				default: init_state_r <= `I_NOP;
				endcase


assign init_state = init_state_r;
assign sdram_init_done = (init_state_r == `I_DONE);		// SDRAM初始化完成标志
//------------------------------------------------------------------------------
//15us计时，每60ms全部4096行存储区进行一次自刷新
// ( 存储体中电容的数据有效保存期上限是64ms )
//------------------------------------------------------------------------------	 
reg[10:0] cnt_15us;	//计数寄存器
always @ (posedge clk or negedge rst_n)
	if(!rst_n) cnt_15us <= 11'd0;
	else if(cnt_15us < 11'd1499) cnt_15us <= cnt_15us+1'b1;	// 60ms(64ms)/4096=15us循环计数
	else cnt_15us <= 11'd0;	

always @ (posedge clk or negedge rst_n)
	if(!rst_n) sdram_ref_req <= 1'b0;
	else if(cnt_15us == 11'd1498) sdram_ref_req <= 1'b1;	//产生自刷新请求
	else if(sdram_ref_ack) sdram_ref_req <= 1'b0;		//已响应自刷新 

//------------------------------------------------------------------------------
//SDRAM的读写以及自刷新操作状态机
//------------------------------------------------------------------------------
reg[3:0] work_state_r;	// SDRAM读写状态
reg sys_r_wn;			// SDRAM读/写控制信号

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 
		work_state_r <= `W_IDLE;
	else
		begin
		case (work_state_r)
		//初始化空闲状态
		`W_IDLE:	if(sdram_ref_req & sdram_init_done) 
						begin
						work_state_r <= `W_AR; 		//定时自刷新请求
						sys_r_wn <= 1'b1;
						end 		
					else if(sdram_wr_req & sdram_init_done) 
						begin
						work_state_r <= `W_ACTIVE;	//写SDRAM
						sys_r_wn <= 1'b0;	
						end											
					else if(sdram_rd_req && sdram_init_done) 
						begin
						work_state_r <= `W_ACTIVE;	//读SDRAM
						sys_r_wn <= 1'b1;	
						end
					else 
						begin 
						work_state_r <= `W_IDLE;
						sys_r_wn <= 1'b1;
						end
		/*************************************************************/
		//行有效状态
		`W_ACTIVE: 	if(TRCD_CLK == 0)
						 if(sys_r_wn) work_state_r <= `W_READ;
						 else work_state_r <= `W_WRITE;
					else work_state_r <= `W_TRCD;
		//行有效等待
		`W_TRCD:	 if(`end_trcd)
						 if(sys_r_wn) work_state_r <= `W_READ;
						 else work_state_r <= `W_WRITE;
					else work_state_r <= `W_TRCD;
					
		/*************************************************************/
		//读数据状态
		`W_READ:	work_state_r <= `W_CL;	
		//等待潜伏期
		`W_CL:		work_state_r <= (`end_tcl) ? `W_RD:`W_CL;	
		//读数据
		`W_RD:		work_state_r <= (`end_tread) ? `W_IDLE:`W_RD;
		//读完成后的预充电等待状态	
		`W_RWAIT:	work_state_r <= (`end_trwait) ? `W_IDLE:`W_RWAIT;
		
		/*************************************************************/
		//写数据状态
		`W_WRITE:	work_state_r <= `W_WD;
		//写数据
		`W_WD:		work_state_r <= (`end_twrite) ? `W_TDAL:`W_WD;
		//等待写数据并自刷新结束
		`W_TDAL:	work_state_r <= (`end_tdal) ? `W_IDLE:`W_TDAL;
		
		/*************************************************************/
		//自动刷新状态
		`W_AR:		work_state_r <= `W_TRFC; 
		//自刷新等待
		`W_TRFC:	work_state_r <= (`end_trfc) ? `W_IDLE:`W_TRFC;
		/*************************************************************/
		default: 	work_state_r <= `W_IDLE;
		endcase
		end
end

assign work_state = work_state_r;		// SDRAM工作状态寄存器
assign sdram_ref_ack = (work_state_r == `W_AR);		// SDRAM自刷新应答信号


//要提前一个时钟才能写入
//写SDRAM响应信号
assign sdram_wr_ack = 	((work_state == `W_TRCD) & ~sys_r_wn) | 
						(work_state == `W_WRITE)|
						((work_state == `W_WD) & (cnt_clk_r < sdwr_byte -2'd2));		
//读SDRAM响应信号
assign sdram_rd_ack = 	(work_state_r == `W_RD) & 
						(cnt_clk_r >= 9'd1) & (cnt_clk_r < sdrd_byte + 2'd1);		

//assign sdram_busy = (sdram_init_done && work_state_r == `W_IDLE) ? 1'b0:1'b1;	// SDRAM忙标志位

//------------------------------------------------------------------------------
//产生SDRAM时序操作的延时
//------------------------------------------------------------------------------
reg[8:0] cnt_clk_r;	//时钟计数
reg cnt_rst_n;		//时钟计数复位信号	

always @ (posedge clk or negedge rst_n) 
	if(!rst_n) cnt_clk_r <= 9'd0;			//计数寄存器复位
	else if(!cnt_rst_n) cnt_clk_r <= 9'd0;	//计数寄存器清零
	else cnt_clk_r <= cnt_clk_r+1'b1;		//启动计数延时
	
assign cnt_clk = cnt_clk_r;			//计数寄存器引出，内部`define中使用 

	//计数器控制逻辑
always @ (init_state_r or work_state_r or cnt_clk_r or sdwr_byte or sdrd_byte) begin
	case (init_state_r)
	    	`I_NOP:	cnt_rst_n <= 1'b0;
	   		`I_PRE:	cnt_rst_n <= 1'b1;	//预充电延时计数启动	
	   		`I_TRP:	cnt_rst_n <= (`end_trp) ? 1'b0:1'b1;	//等待预充电延时计数结束后，清零计数器
	    	`I_AR1,`I_AR2:
	         		cnt_rst_n <= 1'b1;			//自刷新延时计数启动
	    	`I_TRF1,`I_TRF2:
	         		cnt_rst_n <= (`end_trfc) ? 1'b0:1'b1;	//等待自刷新延时计数结束后，清零计数器
			`I_MRS:	cnt_rst_n <= 1'b1;			//模式寄存器设置延时计数启动
			`I_TMRD:	cnt_rst_n <= (`end_tmrd) ? 1'b0:1'b1;	//等待自刷新延时计数结束后，清零计数器
		   	`I_DONE:
				begin
				case (work_state_r)
				`W_IDLE:	cnt_rst_n <= 1'b0;
				`W_ACTIVE: 	cnt_rst_n <= 1'b1;
				`W_TRCD:	cnt_rst_n <= (`end_trcd) ? 1'b0:1'b1;
				`W_CL:		cnt_rst_n <= (`end_tcl) ? 1'b0:1'b1;
				`W_RD:		cnt_rst_n <= (`end_tread) ? 1'b0:1'b1;
				`W_RWAIT:	cnt_rst_n <= (`end_trwait) ? 1'b0:1'b1;
				`W_WD:		cnt_rst_n <= (`end_twrite) ? 1'b0:1'b1;
				`W_TDAL:	cnt_rst_n <= (`end_tdal) ? 1'b0:1'b1;
				`W_TRFC:	cnt_rst_n <= (`end_trfc) ? 1'b0:1'b1;
				default: cnt_rst_n <= 1'b0;
				endcase
				end
		default: cnt_rst_n <= 1'b0;
		endcase
end

endmodule
