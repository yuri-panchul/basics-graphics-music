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
module dcfifo_ctrl
(
	//global clock
	input				clk_ref,		//全局时钟
	input 				clk_write,		//fifo写数据时钟
	input				clk_read,		//fifo读数据时钟
	input 				rst_n,			//全局复位
	
	//burst length
	input		[8:0]	wr_length,		//sdram读突发长度
	input		[8:0]	rd_length,		//sdram写突发长度
	input				wr_load,		//sdram写地址参数置位
	input		[21:0]	wr_addr,		//sdram写地址
	input		[21:0]	wr_max_addr,	//sdram最大写地址
	input				rd_load,		//sdram读地址参数置位
	input		[21:0]	rd_addr,		//sdram读地址
	input		[21:0]	rd_max_addr,	//sdram最大读地址
	
	//wrfifo:  fifo 2 sdram
	input 				wrf_wrreq,		//写入sdram数据缓存fifo输入请求,作为fifo写信号
	input		[15:0] 	wrf_din,		//写入sdram数据缓存fifo写入总线（写入sdram数据）
	output 	reg			sdram_wr_req,	//写入sdram请求信号
	input 				sdram_wr_ack,	//写入sdram响应信号,作为fifo读信号
	output		[15:0] 	sdram_din,		//写入sdram数据缓存fifo输出数据总线
	output	reg	[21:0] 	sdram_wraddr,	//写入sdram时地址暂存器，{bank[1:0],row[11:0],column[7:0]} 

	//rdfifo: sdram 2 fifo
	input 				rdf_rdreq,		//读取sdram数据缓存fifo输出请求
	output		[15:0] 	rdf_dout,		//读取sdram数据缓存fifo输出总线（读取sdram数据）
	output 	reg			sdram_rd_req,	//读取sdram请求信号
	input 				sdram_rd_ack,	//读取sdram响应信号,作为fifo的输写有效信号
	input		[15:0] 	sdram_dout,		//读取sdram数据缓存fifo输入数据
	output	reg	[21:0] 	sdram_rdaddr,	//读取sdram时地址暂存器，{bank[1:0],row[11:0],column[7:0]} 
	
	//sdram address control	
	input				sdram_init_done,	//sdram初始化完成信号
	output	reg			frame_write_done,	//sdram write one frame
	output	reg			frame_read_done,	//sdram read one frame
	input 				data_valid			//使能sdram读数据单元进行寻址或地址清零
);

//------------------------------------------------
//sdram读写响应完成标致下降沿捕获
reg	sdram_wr_ackr1, sdram_wr_ackr2;	
reg sdram_rd_ackr1, sdram_rd_ackr2;
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n) 
		begin
		sdram_wr_ackr1 <= 1'b0;
		sdram_wr_ackr2 <= 1'b0;
		sdram_rd_ackr1 <= 1'b0;
		sdram_rd_ackr2 <= 1'b0;
		end
	else 
		begin
		sdram_wr_ackr1 <= sdram_wr_ack;
		sdram_wr_ackr2 <= sdram_wr_ackr1;
		sdram_rd_ackr1 <= sdram_rd_ack;
		sdram_rd_ackr2 <= sdram_rd_ackr1;		
		end
end	
wire write_done = sdram_wr_ackr2 & ~sdram_wr_ackr1;	//sdram_wr_ack下降沿标志位
wire read_done = sdram_rd_ackr2 & ~sdram_rd_ackr1;	//sdram_rd_ack下降沿标志位

//------------------------------------------------
//同步sdram读写地址初始值复位信号
reg	wr_load_r1, wr_load_r2;	
reg	rd_load_r1, rd_load_r2;	
always@(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		wr_load_r1 <= 1'b0;
		wr_load_r2 <= 1'b0;
		rd_load_r1 <= 1'b0;
		rd_load_r2 <= 1'b0;
		end
	else
		begin
		wr_load_r1 <= wr_load;
		wr_load_r2 <= wr_load_r1;
		rd_load_r1 <= rd_load;
		rd_load_r2 <= rd_load_r1;
		end
end
wire	wr_load_flag = ~wr_load_r2 & wr_load_r1;	//地址加载上升沿标志位
wire	rd_load_flag = ~rd_load_r2 & rd_load_r1;	//地址加载上升沿标志位

//------------------------------------------------
//sdram写地址产生模块（优先）
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		sdram_wraddr <= 22'd0;	
		frame_write_done <= 1'b0;
		end			
	else if(wr_load_flag)						//加载sdram写入基地址
		begin
		sdram_wraddr <= wr_addr;	
		frame_write_done <= 1'b0;	
		end
	else if(write_done)						//突发写入完毕
		begin
		if(sdram_wraddr < wr_max_addr - wr_length)
			begin
			sdram_wraddr <= sdram_wraddr + wr_length;
			frame_write_done <= 1'b0;
			end
		else
			begin
			sdram_wraddr <= sdram_wraddr;		//防止溢出，锁存地址
			frame_write_done <= 1'b1;
			end
		end
	else
		begin
		sdram_wraddr <= sdram_wraddr;			//锁存地址
		frame_write_done <= frame_write_done;
		end
end

//------------------------------------------------
//sdram读地址产生模块(其次)
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		sdram_rdaddr <= 22'd0;
		frame_read_done <= 0;
		end
	else if(rd_load_flag)						//加载sdram读取基地址
		begin
		sdram_rdaddr <= rd_addr;
		frame_read_done <= 0;
		end
	else if(~data_valid_r)						//显示无效期
		begin
		sdram_rdaddr <= rd_addr;
		frame_read_done <= 0;
		end
	else if(read_done)							//突发写入完毕
		begin
		if(sdram_rdaddr < rd_max_addr - rd_length)
			begin
			sdram_rdaddr <= sdram_rdaddr + rd_length;
			frame_read_done <= 0;
			end
		else
			begin
			sdram_rdaddr <= sdram_rdaddr;		//防止溢出，锁存地址
			frame_read_done <= 1;
			end
		end
	else
		begin
		sdram_rdaddr <= sdram_rdaddr;			//锁存地址
		frame_read_done <= frame_read_done;
		end
end

//------------------------------------------------
//同步 读写sdram有效信号
reg	data_valid_r;
always@(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n) 
		data_valid_r <= 1'b0;
	else 
		data_valid_r <= data_valid;
end

//-------------------------------------
//sdram 读写信号产生模块
wire	[8:0] 	wrf_use;
wire	[8:0] 	rdf_use;
always@(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)	
		begin
		sdram_wr_req <= 0;
		sdram_rd_req <= 0;
		end
	else if(sdram_init_done == 1'b1)
		begin						//写入优先，带宽内防止数据丢失
		if(wrf_use >= wr_length)	// && wr_load_flag == 1'b0)	
			begin					//wrfifo满突发长度
			sdram_wr_req <= 1;		//写sdarm使能
			sdram_rd_req <= 0;		//读sdram空闲
			end
		else if(rdf_use < rd_length && data_valid_r == 1'b1)// && rd_load_flag == 1'b0)
			begin					//rdfifo满突发长度
			sdram_wr_req <= 0;		//写sdram空闲
			sdram_rd_req <= 1;		//读sdram使能
			end
		else
			begin
			sdram_wr_req <= 0;		//写sdram空闲
			sdram_rd_req <= 0;		//读sdram空闲
			end
		end
	else
		begin
		sdram_wr_req <= 0;			//写sdram空闲
		sdram_rd_req <= 0;			//读sdram空闲
		end
end
//assign sdram_wr_req = (sdram_init_done == 1'b1 && wrf_use >= wr_length) ? 1'b1 : 1'b0;						//fifo写入sdram请求
//assign sdram_rd_req = (sdram_init_done == 1'b1 && rdf_use < rd_length && data_valid_r == 1'b1) ? 1'b1 : 1'b0;	//sdram写入fifo请求

//------------------------------------------------
//例化sdram写入数据缓存fifo模块
wrfifo	u_wrfifo
(
	//input 2 fifo
	.wrclk		(clk_write),		//wrfifo写时钟50MHz
	.wrreq		(wrf_wrreq),		//wrfifo写使能信号
	.data		(wrf_din),			//wrfifo数据输入总线
	//fifo 2sdram
	.rdclk		(clk_ref),			//wrfifo读时钟100MHz
	.rdreq		(sdram_wr_ack),		//wrfifo读使能信号
	.q			(sdram_din),		//wrfifo数据输出总线
	//user port
	.aclr		(~rst_n),			//wrfifo异步清零信号（很重要）
	.rdusedw	(wrf_use)			//wrfifo存储数据总量
);	

//------------------------------------------------
//例化sdram读出数据缓存fifo模块
rdfifo	u_rdfifo
(
	//sdram 2 fifo
	.wrclk		(clk_ref),       	//rdfifo写时钟100MHz
	.wrreq		(sdram_rd_ack),  	//rdfifo写使能信号
	.data		(sdram_dout),  		//rdfifo数据输入总线
	//fifo 2 output 
	.rdclk		(clk_read),        	//rdfifo读时钟50MHz
	.rdreq		(rdf_rdreq),     	//rdfifo读使能信号
	.q			(rdf_dout),			//rdfifo数据输出总线
	//user port
	.aclr		(~rst_n | ~data_valid_r | rd_load_flag),		//rdfifo异步清零信号
	.wrusedw	(rdf_use)        	//rdfifo存储数据总量
);

endmodule
