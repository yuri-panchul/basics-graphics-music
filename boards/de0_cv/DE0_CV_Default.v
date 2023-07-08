// ============================================================================
// Copyright (c) 2014 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//  
//  
//                     web: http://www.terasic.com/  
//                     email: support@terasic.com
//
// ============================================================================
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Yue Yang          :| 08/25/2014:| Initial Revision
// ============================================================================


module DE0_CV_Default(


      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      inout              CLOCK4_50,

      ///////// CLOCK /////////
      input              CLOCK_50,

      ///////// DRAM /////////
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      ///////// GPIO /////////
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      ///////// HEX0 /////////
      output      [6:0]  HEX0,

      ///////// HEX1 /////////
      output      [6:0]  HEX1,

      ///////// HEX2 /////////
      output      [6:0]  HEX2,

      ///////// HEX3 /////////
      output      [6:0]  HEX3,

      ///////// HEX4 /////////
      output      [6:0]  HEX4,

      ///////// HEX5 /////////
      output      [6:0]  HEX5,

      ///////// KEY /////////
      input       [3:0]  KEY,

      ///////// LEDR /////////
      output      [9:0]  LEDR,

      ///////// PS2 /////////
      inout              PS2_CLK,
      inout              PS2_CLK2,
      inout              PS2_DAT,
      inout              PS2_DAT2,

      ///////// RESET /////////
      input              RESET_N,

      ///////// SD /////////
      output             SD_CLK,
      inout              SD_CMD,
      inout       [3:0]  SD_DATA,

      ///////// SW /////////
      input       [9:0]  SW,

      ///////// VGA /////////
      output      [3:0]  VGA_B,
      output      [3:0]  VGA_G,
      output             VGA_HS,
      output      [3:0]  VGA_R,
      output             VGA_VS
);


//=======================================================
//  REG/WIRE declarations
//=======================================================
wire		   VGA_CTRL_CLK;
wire		   DLY_RST;
reg  [31:0]	Cont;
wire [23:0]	mSEG7_DIG;

//=======================================================
//  Structural coding
//=======================================================
// initial //  	         
assign DRAM_DQ 	   =  16'hzzzz;
assign GPIO_0  		=	36'hzzzzzzzz;
assign GPIO_1  		=	36'hzzzzzzzz;

always@(posedge CLOCK_50 or negedge RESET_N)
    begin
        if(!RESET_N)
			 Cont	<=	0;
        else
			 Cont	<=	Cont+1;
    end
	 

assign	LEDR      	=	RESET_N? {	Cont[25:24],Cont[25:24],Cont[25:24],Cont[25:24],Cont[25:24]	}:10'h3ff;
assign	mSEG7_DIG	=	RESET_N? {	Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24] } :{6{4'b1000}};

//7 segment LUT

SEG7_LUT_6 			u0	(	.oSEG0(HEX0),
							   .oSEG1(HEX1),
							   .oSEG2(HEX2),
							   .oSEG3(HEX3),
								.oSEG4(HEX4),
								.oSEG5(HEX5),
							   .iDIG(mSEG7_DIG) );

//	Reset Delay Timer
Reset_Delay			r0	(	
							 .iCLK(CLOCK_50),
							 .oRESET(DLY_RST));
							 
// VGA PLL clock							 
vga_pll           u1(
		                .refclk(CLOCK3_50),   //  refclk.clk
		                .rst(~DLY_RST),      //   reset.reset
		                .outclk_0(VGA_CTRL_CLK)  // outclk0.clk
	                 );
	


vga_controller vga_ins(.iRST_n(DLY_RST),
                      .iVGA_CLK(VGA_CTRL_CLK),
                      .oHS(VGA_HS),
                      .oVS(VGA_VS),
                      .oVGA_B(VGA_B),
                      .oVGA_G(VGA_G),
                      .oVGA_R(VGA_R));	
	
endmodule
