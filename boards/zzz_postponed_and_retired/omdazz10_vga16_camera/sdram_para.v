`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: 
// Engineer		: 特权 franchises3
// Create Date	: 2009.05.11
// Design Name	: 
// Module Name	: sdram_para
// Project Name	: 
// Target Device: Cyclone EP1C3T144C8 
// Tool versions: Quartus II 8.1
// Description	: SDRAM模块参数定义
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////
//module sdram_para;


//------------------------------------------------------------------------------
	// SDRAM读写工作状态参数
`define		W_IDLE		 4'd0		//空闲状态
`define		W_ACTIVE	 4'd1		//行有效，判断读写
`define		W_TRCD		 4'd2		//行有效等待
/*************************************************************/
`define		W_READ		 4'd3		//读数据状态
`define		W_CL		 4'd4		//等待潜伏期
`define		W_RD		 4'd5		//读数据
`define		W_RWAIT		 4'd6		//读完成后的预充电等待状态
/*************************************************************/
`define		W_WRITE		 4'd7		//写数据状态
`define		W_WD		 4'd8		//写数据
`define		W_TDAL		 4'd9		//等待写数据并自刷新结束
/*************************************************************/
`define		W_AR		 4'd10		//自刷新
`define		W_TRFC		 4'd11		//自刷新等待


	// SDRAM初始化状态参数
`define		I_NOP	 	4'd0		//等待上电200us稳定期结束
`define		I_PRE 	 	4'd1		//预充电状态
`define		I_TRP 	 	4'd2		//等待预充电完成	tRP
`define		I_AR1 	 	4'd3		//第1次自刷新
`define		I_TRF1	 	4'd4		//等待第1次自刷新结束	tRFC
`define		I_AR2 	 	4'd5		//第2次自刷新
`define		I_TRF2 	 	4'd6		//等待第2次自刷新结束	tRFC	
`define		I_MRS	 	4'd7		//模式寄存器设置
`define		I_TMRD	 	4'd8		//等待模式寄存器设置完成	tMRD
`define		I_DONE	 	4'd9		//初始化完成


	//延时参数
`define	end_trp			cnt_clk_r	== TRP_CLK
`define	end_trfc		cnt_clk_r	== TRFC_CLK
`define	end_tmrd		cnt_clk_r	== TMRD_CLK
`define	end_trcd		cnt_clk_r	== TRCD_CLK-1
`define end_tcl			cnt_clk_r   == TCL_CLK-1
`define end_rdburst		cnt_clk		== sdrd_byte-4//TREAD_CLK-4		//发出突发读中断命令
`define	end_tread		cnt_clk_r	== sdrd_byte+2//TREAD_CLK+2		//TREAD_CLK+2
`define end_wrburst		cnt_clk		== sdwr_byte-1//TWRITE_CLK-1	//发出突发写中断命令
`define	end_twrite		cnt_clk_r	== sdwr_byte-1//TWRITE_CLK-1
`define	end_tdal		cnt_clk_r	== TDAL_CLK	
`define	end_trwait		cnt_clk_r	== TRP_CLK

	//SDRAM控制信号命令
`define		CMD_INIT 	 5'b01111	//上电初始化命令端口		
`define		CMD_NOP		 5'b10111	// NOP COMMAND
`define		CMD_ACTIVE	 5'b10011	// ACTIVE COMMAND
`define		CMD_READ	 5'b10101	// READ COMMADN
`define		CMD_WRITE	 5'b10100	// WRITE COMMAND
`define		CMD_B_STOP	 5'b10110	// BURST STOP
`define		CMD_PRGE	 5'b10010	// PRECHARGE
`define		CMD_A_REF	 5'b10001	// AOTO REFRESH
`define		CMD_LMR		 5'b10000	// LODE MODE REGISTER


//endmodule
