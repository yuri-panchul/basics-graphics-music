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
module lcd_display
(
	input	 		clk,		//system clock
	input			rst_n,		//sync clock
	
	input	[8:0]	alpha_data,	//0-256
	input	[10:0]	lcd_xpos,	//lcd horizontal coordinate
	input	[10:0]	lcd_ypos,	//lcd vertical coordinate
	
	input	[15:0]	lcd_data_in,//out input vga data
	output	[15:0]	lcd_data	//lcd data
);

//定义颜色变量RGB--5|6|5
//define colors RGB--5|6|5
`define RED		16'hF800   /*111110,000000,000000	F800 红*/
`define GREEN	16'h07E0   /*000000,111111,000000	07E0 绿*/
`define BLUE  	16'h001F   /*000000,000000,111110	001F 蓝*/
`define WHITE 	16'hFFFF   /*111110,111111,111110	FFFF 白*/
`define BLACK 	16'h0000   /*000000,000000,000000	0000 黑*/
`define YELLOW	16'hFFE0   /*111110,111111,000000	FFE0 黄*/
`define CYAN  	16'hF81F   /*111110,000000,111110	F81F 青*/
`define ROYAL 	16'h07FF   /*000000,111111,111110	07FF 品*/

/***************************************************			
R(C)=( (256-alpha)*R(B) + alpha*R(A) ) >> 8
G(C)=( (256-alpha)*G(B) + alpha*G(A) ) >> 8
B(C)=( (256-alpha)*B(B) + alpha*B(A) ) >> 8
***************************************************/		
//wire	[15:0]	lcd_data2 = `YELLOW;
//wire	[15:0]	lcd_data2 = lcd_xpos * lcd_ypos;
//wire	[15:0]	lcd_data2 = (lcd_xpos >= (H_DISP/8)*0 && lcd_xpos < (H_DISP/8)*1) ? `RED	:
//							(lcd_xpos >= (H_DISP/8)*1 && lcd_xpos < (H_DISP/8)*2) ? `GREEN	:
//							(lcd_xpos >= (H_DISP/8)*2 && lcd_xpos < (H_DISP/8)*3) ? `BLUE	:
//							(lcd_xpos >= (H_DISP/8)*3 && lcd_xpos < (H_DISP/8)*4) ? lcd_data2	:
//							(lcd_xpos >= (H_DISP/8)*4 && lcd_xpos < (H_DISP/8)*5) ? `BLACK	:
//							(lcd_xpos >= (H_DISP/8)*5 && lcd_xpos < (H_DISP/8)*6) ? `YELLOW	:
//							(lcd_xpos >= (H_DISP/8)*6 && lcd_xpos < (H_DISP/8)*7) ? `CYAN	:	`ROYAL;


/****************************************************************
			Display: "HDU Logo" 
****************************************************************/
//wire	logo_area =	(lcd_xpos >= 0 && lcd_xpos < 64) && (lcd_ypos >= 0 && lcd_ypos < 64);  
//wire	[63:0]	logo_data;					//64
//wire	[5:0]	logo_addr = lcd_xpos[5:0];	//64
//logo_rom	logo_rom 
//(
//	.clock		(clk),
//	.address	(logo_addr),
//	.q			(logo_data)
//);

/****************************************************************
			Display : "VIP System" 
****************************************************************/
wire	vip_area =	(lcd_xpos >= 128 && lcd_xpos < 512) && (lcd_ypos >= 0 && lcd_ypos < 64);  
wire	[63:0]	vip_data;							//64
wire	[8:0]	vip_addr = lcd_xpos[8:0] - 9'd128;	//64*8=512
vip_rom	vip_rom 
(
	.clock		(clk),
	.address	(vip_addr),
	.q			(vip_data)
);		


/***************************************************************************
"OV7670 Video Display, Frame Rate:32fps, 640*480 Pixels, Made By AMFPGA"
****************************************************************************/
wire	osd_area =	(lcd_ypos >= 100 && lcd_ypos < 132); 
wire	[31:0]	osd_data;							//32
wire	[10:0]	osd_addr = lcd_xpos + shift_data;	//16 1424
osd_rom	osd_rom 
(
	.clock		(clk),
	.address	(osd_addr),
	.q			(osd_data)
);	

//-----------------------------------------------------
//	delay shift 
reg	[17:0]	delay_cnt;	
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		delay_cnt <= 0;
	else
		begin
		if(delay_cnt < 18'd200000)
			delay_cnt <= delay_cnt + 1'b1;
		else
			delay_cnt <= 0;
		end

end
wire	delay_shift = (delay_cnt == 18'd200000) ? 1'b1 : 1'b0;

reg	[10:0]	shift_data;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		shift_data <= 0;
	else if(delay_shift)
		shift_data <= shift_data + 1'b1;
end

//-------------------------------------------------------------
reg	[15:0]	lcd_data_reg;
always@(*)
begin
	/*if(logo_area)				//Display : "HDU Logo" 
		if(logo_data[6'd63-lcd_ypos[5:0]] == 1'b1)	lcd_data_reg = `BLUE;
		else										lcd_data_reg = lcd_data_in;
	else */if(vip_area == 1'b1)	//Display : "VIP System"	
		if(vip_data[6'd63-lcd_ypos[5:0]] == 1'b1)	lcd_data_reg = `RED;
		else										lcd_data_reg = lcd_data_in;//lcd_data2;
	else if(osd_area)			//Display : "OV7670 Video Display, Frame Rate:32fps, 640*480 Pixels, Made By AMFPGA.com"
		if(osd_data[5'd31-lcd_ypos[4:0]] == 1'b1)	lcd_data_reg = `BLUE;
		else										lcd_data_reg = `WHITE;//lcd_data2;	
	else
		lcd_data_reg = lcd_data_in;
end

wire	[15:0] 	red_data	=	( (9'd256 - alpha_data) * lcd_data_reg[15:11] + alpha_data * lcd_data_in[15:11] ) >> 8;
wire	[15:0] 	gre_data	= 	( (9'd256 - alpha_data) * lcd_data_reg[10:5]  + alpha_data * lcd_data_in[10:5] )  >> 8;
wire	[15:0] 	blu_data	= 	( (9'd256 - alpha_data) * lcd_data_reg[4:0]   + alpha_data * lcd_data_in[4:0] )   >> 8;
assign	lcd_data = osd_area ? {red_data[4:0], gre_data[5:0], blu_data[4:0]} : lcd_data_reg;	




endmodule
