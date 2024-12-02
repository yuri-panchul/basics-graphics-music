// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc.
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altrea Development
//   Kits made by Terasic.  Other use of this code, including the selling
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL or Verilog source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use
//   or functionality of this code.
//
// --------------------------------------------------------------------
//
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------

module I2C_AUDIO_Config (	//	Host Side
					iCLK,
					iRST_N,
					//	I2C Side
					I2C_SCLK,
					I2C_SDAT,
					READY
					 );
//	Host Side
input				iCLK;
input				iRST_N;
//	I2C Side
output			I2C_SCLK;
inout				I2C_SDAT;
output READY;

//	Internal Registers/Wires
reg	[15:0]	mI2C_CLK_DIV;
reg	[23:0]	mI2C_DATA;
reg				mI2C_CTRL_CLK;
reg				mI2C_GO;
wire				mI2C_END;
wire				mI2C_ACK;
reg	[15:0]	LUT_DATA;
reg	[5:0]		LUT_INDEX;
reg	[3:0]		mSetup_ST;
reg READY ;

//  Clock Setting
parameter   CLK_Freq     =   50000000;   //  50  MHz
parameter   I2C_Freq     =   20000;      //  20  KHz
//  LUT Data Number
parameter   LUT_SIZE     =   11;
//	Audio Data Index
parameter	Dummy_DATA	=	0;
parameter	SET_LIN_L	=	1;
parameter	SET_LIN_R	=	2;
parameter	SET_HEAD_L	=	3;
parameter	SET_HEAD_R	=	4;
parameter	A_PATH_CTRL	=	5;
parameter	D_PATH_CTRL	=	6;
parameter	POWER_ON	=	7;
parameter	SET_FORMAT	=	8;
parameter	SAMPLE_CTRL	=	9;
parameter	SET_ACTIVE	=	10;
//  Audio codec I2C address
parameter   AUD_I2C_ADDR =   8'h34;

/////////////////////	I2C Control Clock	////////////////////////
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		mI2C_CTRL_CLK	<=	0;
		mI2C_CLK_DIV	<=	0;
	end
	else
	begin
		if( mI2C_CLK_DIV	< (CLK_Freq/I2C_Freq) )
			mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
		else
		begin
			mI2C_CLK_DIV	<=	0;
			mI2C_CTRL_CLK	<=	~mI2C_CTRL_CLK;
		end
	end
end
////////////////////////////////////////////////////////////////////
I2C_Controller 	u0	(	.CLOCK(mI2C_CTRL_CLK),	//	Controller Work Clock
						.I2C_SCLK(I2C_SCLK),				//	I2C CLOCK
 	 	 	 	 	 	.I2C_SDAT(I2C_SDAT),				//	I2C DATA
						.I2C_DATA(mI2C_DATA),			//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
						.GO(mI2C_GO),						//	GO transfor
						.END(mI2C_END),					//	END transfor
						.ACK(mI2C_ACK),					//	ACK
						.RESET(iRST_N)	);
////////////////////////////////////////////////////////////////////
//////////////////////	Config Control	////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		READY		<=	0;
		LUT_INDEX	<=	0;
		mSetup_ST	<=	0;
		mI2C_GO		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
		READY<=0;
			case(mSetup_ST)
			0:	begin
					mI2C_DATA	<=	{AUD_I2C_ADDR,LUT_DATA};
					mI2C_GO		<=	1;
					mSetup_ST	<=	1;
				end
			1:	begin
					if(mI2C_END)
					begin
						if(!mI2C_ACK)
						mSetup_ST	<=	2;
						else
						mSetup_ST	<=	0;
						mI2C_GO		<=	0;
					end
				end
			2:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mSetup_ST	<=	0;
				end
			endcase
		end
		else
		begin
		  READY<=1;
		end
	end
end
////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////	
always
begin
    case(LUT_INDEX)
    //  Audio Config Data: 7 bit reg address + 9 bits of data
    Dummy_DATA  :   LUT_DATA <= 16'h0000;
    SET_LIN_L   :   LUT_DATA <= 16'h0017;   //R0 LINVOL = 17h (+0.0bB)
    SET_LIN_R   :   LUT_DATA <= 16'h0217;   //R1 RINVOL = 17h (+0.0bB)
    SET_HEAD_L  :   LUT_DATA <= 16'h0460;   //R2 LHPVOL = 60h (-43dB)
    SET_HEAD_R  :   LUT_DATA <= 16'h0660;   //R3 RHPVOL = 60h (-43dB)
    A_PATH_CTRL :   LUT_DATA <= 16'h08D2;   //R4 DACSEL = 1
    D_PATH_CTRL :   LUT_DATA <= 16'h0A06;   //R5 DEEMP = 11 (48 KHz)
    POWER_ON    :   LUT_DATA <= 16'h0C00;   //R6 PWR_CTL = 00h (disable power down)
    SET_FORMAT  :   LUT_DATA <= 16'h0E02;   //R7 FORMAT=10(I2S), 16 bit
    SAMPLE_CTRL :   LUT_DATA <= 16'h1002;   //R8 48KHz, Normal mode
    SET_ACTIVE  :   LUT_DATA <= 16'h1201;   //R9 ACTIVE
    default     :   LUT_DATA <= 16'h0000;
    endcase
end
////////////////////////////////////////////////////////////////////
endmodule
