/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from amfpga.
(C) COPYRIGHT 2013.amfpga ALL RIGHTS RESERVED
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
`timescale 1ns / 1ps
module board_specific_top
#(
    parameter clk_mhz = 50
)
(
	//global clock 50MHz
	//input			clk_27,			//27MHz
	input			CLOCK,	
	input			RESET,	
	//input			rst_n,			//global reset
	
	//sdram control
	output			S_CLK,		//sdram clock
	output			S_CKE,		//sdram clock enable
	output			S_NCS,		//sdram chip select
	output			S_NWE,		//sdram write enable
	output			S_NCAS,	//sdram column address strobe
	output			S_NRAS,	//sdram row address strobe
	output[1:0] 	S_DQM,		//sdram data enable 
	output	[1:0]	S_BA,		//sdram bank address
	output	[11:0]	S_A,		//sdram address
	inout	[15:0]	S_DB,		//sdram data
	
	//VGA port			
	output			VGA_HSYNC,			//horizontal sync 
	output			VGA_VSYNC,			//vertical sync
	output	[15:0]	VGAD,		//VGA data
	
	//cmos interface
	output			CMOS_SCLK,		//cmos i2c clock
	inout			CMOS_SDAT,		//cmos i2c data
	input			CMOS_VSYNC,		//cmos vsync
	input			CMOS_HREF,		//cmos hsync refrence
	input			CMOS_PCLK,		//cmos pxiel clock
	output			CMOS_XCLK,		//cmos externl clock
	input	[7:0]	CMOS_DB,		//cmos data
//	output			cmos_rst_n,		//cmos reset
//	output			cmos_pwdn,		//cmos pwer down

	output	[3:0]	LED		//led data input	
);

wire                            rst_n;
wire[15:0]                      cmos_16bit_data;
wire                            cmos_16bit_clk;
wire                            cmos_16bit_wr;

//assign rst_n = 1'b1;
assign  rst_n = RESET;
//---------------------------------------------
wire	clk_vga;		//vga clock
wire	clk_ref;		//sdram ctrl clock
wire	clk_refout;		//sdram clock output
wire	sys_rst_n;		//global reset
system_ctrl	u_system_ctrl
(
	.clk				   (CLOCK),			//global clock  50MHZ
	.rst_n				(rst_n),		//external reset
	
	.sys_rst_n			(sys_rst_n),	//global reset
	.clk_c0				(clk_vga),		//25MHz
	.clk_c1				(clk_ref),		//100MHz -45deg
	.clk_c2				(clk_refout)	//100MHz
);

lab_top 
# ( 
  .clk_mhz( 25               ),
  .cam    ( ov7640_rgb565_640_480 )
)
mylab
(
    .clk       ( clk_vga           ),
//    .clk       ( CLOCK           ),
//    .rst       ( ~RESET          ),
    .rst       ( ~sys_rst_n      ),
    .cmos_clk  ( clk_vga         ),
 	 .cmos_scl  ( CMOS_SCLK       ),        //cmos i2c clock
	 .cmos_sda  ( CMOS_SDAT       ),        //cmos i2c data
	 .cmos_vsync( CMOS_VSYNC      ),        //cmos vsync
	 .cmos_href ( CMOS_HREF       ),        //cmos hsync refrence,data valid
	 .cmos_pclk ( CMOS_PCLK       ),        //cmos pxiel clock
    .cmos_xclk ( CMOS_XCLK       ),        //cmos externl clock 
	 .cmos_db   ( CMOS_DB         ),        //cmos data
	 .cmos_rst_n(                 ),        //cmos reset 
	 .cmos_pwdn (                 ),        //cmos power down
	 .pdata_o   ( cmos_16bit_data ),
	 .hblank    ( cmos_16bit_wr   ),
	 .de_o      ( cmos_16bit_clk  )

);

//-----------------------------
/*wire	[7:0]	I2C_RDATA;		//i2c register data
wire	[7:0]	LUT_INDEX;		//lut index
wire			Config_Done;	//I2C config done		
I2C_AV_Config	u_I2C_AV_Config 
(
	//Global clock
	.iCLK				(clk_vga),		//25MHz
	.iRST_N				(sys_rst_n),	//Global Reset
	
	//I2C Side
	.I2C_SCLK			(CMOS_SCLK),	//I2C CLOCK
	.I2C_SDAT			(CMOS_SDAT),	//I2C DATA
	
	//CMOS Signal
	.Config_Done		(Config_Done),	//I2C Config done
	.I2C_RDATA			(I2C_RDATA),	//CMOS ID
	.LUT_INDEX			()//(LUT_INDEX)		//ID Index
);
assign	led_data = I2C_RDATA;				//diaplay I2C_RDATA
*/
//-----------------------------------------------
//Seg7_lut	u5	(	LUT_INDEX[7:4],	oSEG5	);	
//Seg7_lut	u4	(	LUT_INDEX[3:0],	oSEG4	);
//Seg7_lut	u1	(	I2C_RDATA[7:4],	oSEG1	);
//Seg7_lut	u0	(	I2C_RDATA[3:0],	oSEG0	);

//-----------------------------------------------               
wire			frame_valid;		//data valid, or address restart
wire	[7:0]	cmos_fps_data;		//cmos frame rate
/*CMOS_Capture	u_CMOS_Capture
(
	//Global Clock
	.iCLK				(clk_vga),		//25MHz
	.iRST_N				(sys_rst_n),	//global reset
	
	//I2C Initilize Done
	.Init_Done			(Config_Done & sdram_init_done),	//Init Done
	
	//Sensor Interface
	.CMOS_RST_N			(),//(cmos_rst_n),	//cmos work state 
	.CMOS_PWDN			(),//(cmos_pwdn),	//cmos power on	
	.CMOS_XCLK			(CMOS_XCLK),		//cmos
	.CMOS_PCLK			(CMOS_PCLK),		//25MHz
	.CMOS_iDATA			(CMOS_DB),    	//CMOS Data
	.CMOS_VSYNC			(CMOS_VSYNC),  	 	//L: Vaild
	.CMOS_HREF			(CMOS_HREF), 		//H: Vaild
	                                    
	//Ouput Sensor Data                 
	.CMOS_oCLK			(sys_we),			//Data PCLK
	.CMOS_oDATA			(sys_data_in),  	//16Bits RGB
	.CMOS_VALID			(frame_valid),		//Data Enable
	.CMOS_FPS_DATA		()//(cmos_fps_data)		//cmos frame rate
);
*/

//Seg7_lut	u7	(	cmos_fps_data[7:4],	oSEG7	);	//fsp rate
//Seg7_lut	u6	(	cmos_fps_data[3:0],	oSEG6	);	//fps rate


//wire	[8:0]	alpha_data;					//alpha adjust data
//assign	led_data = alpha_data;				//diaplay alpha data
//alpha_control	u_alpha_control
//(
//	.clk				(clk_vga),			//vga clock
//	.rst_n				(sys_rst_n),		//global reset
//	
//	.key_data			(key_data),			//key data
//	.alpha_data			(alpha_data)		//aplha adjust data
//);

//-------------------------------------
//sdram vga ctrl system
wire			sys_we;						//system data write enable
wire	[15:0]	sys_data_in;				//system data input
wire			sdram_init_done;			//sdram init done
wire  VGAHSYNC;			//lcd horizontal sync 
wire  VGAVSYNC;			//lcd vertical sync

assign VGA_HSYNC = ~VGAHSYNC;
assign VGA_VSYNC = ~VGAVSYNC;

sdram_vga_top	u_sdram_vga_top
(
	//global clock
	.clk_vga			(clk_vga),			//vga clock
	.clk_ref			(clk_ref),			//sdram ctrl clock
	.clk_refout			(clk_refout),		//sdram clock output
	.rst_n				(sys_rst_n),		//global reset

	//sdram control
	.sdram_clk			(S_CLK),		//sdram clock
	.sdram_cke			(S_CKE),		//sdram clock enable
	.sdram_cs_n			(S_NCS),		//sdram chip select
	.sdram_we_n			(S_NWE),		//sdram write enable
	.sdram_cas_n		(S_NCAS),		//sdram column address strobe
	.sdram_ras_n		(S_NRAS),		//sdram row address strobe
	.sdram_udqm			(S_DQM[1]),		//sdram data enable (H:8)
	.sdram_ldqm			(S_DQM[0]),		//sdram data enable (L:8)
	.sdram_ba			(S_BA),			//sdram bank address
	.sdram_addr			(S_A),		//sdram address
	.sdram_data			(S_DB),		//sdram data
		
	//lcd port
	.lcd_dclk			(),			//lcd pixel clock			
	.lcd_hs				(VGAHSYNC),			//lcd horizontal sync 
	.lcd_vs				(VGAVSYNC),			//lcd vertical sync
	.lcd_sync			(),//(lcd_sync),			//lcd sync
	.lcd_blank			(),		//lcd blank(L:blank)
	.lcd_red			(VGAD[15:11]),			//lcd red data
	.lcd_green			(VGAD[10:5]),		//lcd green data
	.lcd_blue			(VGAD[4:0]),			//lcd blue data
	
	//user interface
	.clk_write			(cmos_16bit_clk),			//fifo write clock
	.sys_we				(cmos_16bit_wr),			//fifo write enable
	.sys_data_in		(cmos_16bit_data),		//fifo data input

	/*.clk_write			(clk_vga),			//fifo write clock
	.sys_we				(sys_we),			//fifo write enable
	.sys_data_in		(sys_data_in),		//fifo data input*/

	
	.sdram_init_done	(sdram_init_done),	//sdram init done
//	.frame_valid		(frame_valid)		//frame valid
	.frame_valid		(cmos_16bit_wr)
);


endmodule
