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

module I2C_Config (	//	Host Side
					iCLK,
					iRST_N,
					//	I2C Side
					I2C_SCLK,
					I2C_SDAT,
					HDMI_TX_INT,
					READY
					 );
//	Host Side
input				iCLK;
input				iRST_N;
//	I2C Side
output				I2C_SCLK;
inout				I2C_SDAT;
input				HDMI_TX_INT;
output 				READY ;

//	Internal Registers/Wires
reg	[15:0]		mI2C_CLK_DIV;
reg	[23:0]		mI2C_DATA;
reg				mI2C_CTRL_CLK;
reg				mI2C_GO;
wire			mI2C_END;
wire			mI2C_ACK;
reg	[15:0]		LUT_DATA;
reg	[5:0]		LUT_INDEX;
reg	[3:0]		mSetup_ST;
reg 			READY;
wire [7:0]		I2C_ADDR;

//	Clock Setting
parameter	CLK_Freq	=	50000000;	//	50	MHz
parameter	I2C_Freq	=	20000;		//	20	KHz
//	LUT Data Number

parameter	AUD_LUT_SIZE	=	11;
parameter	VID_LUT_SIZE	=	31;
parameter	LUT_SIZE	=	AUD_LUT_SIZE + VID_LUT_SIZE;

// Audio codec I2C address
parameter   AUD_I2C_ADDR =   8'h34;
// HDMI IC address
parameter   VID_I2C_ADDR =   8'h72;

// Addr mux
assign I2C_ADDR = (LUT_INDEX < AUD_LUT_SIZE) ? AUD_I2C_ADDR : VID_I2C_ADDR;

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
	READY<=0;
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
					mI2C_DATA	<=	{I2C_ADDR, LUT_DATA};
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
					LUT_INDEX	<=	LUT_INDEX + 1;
					mSetup_ST	<=	0;
				end
			endcase
		end
		else
		begin
		  READY<=1;
		  if(!HDMI_TX_INT)
		  begin
		    LUT_INDEX <= AUD_LUT_SIZE;
		  end
		  else
		    LUT_INDEX <= LUT_INDEX;
		end
	end
end
////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////
always
begin
	case(LUT_INDEX)

    //  Audio Config Data: 7 bit reg address + 9 bits of data
    0	:   LUT_DATA <= 16'h0000;
    1	:   LUT_DATA <= 16'h0017;   //R0 LINVOL = 17h (+0.0bB)
    2	:   LUT_DATA <= 16'h0217;   //R1 RINVOL = 17h (+0.0bB)
    3	:   LUT_DATA <= 16'h0460;   //R2 LHPVOL = 60h (-43dB)
    4	:   LUT_DATA <= 16'h0660;   //R3 RHPVOL = 60h (-43dB)
    5	:   LUT_DATA <= 16'h08D2;   //R4 DACSEL = 1
    6	:   LUT_DATA <= 16'h0A06;   //R5 DEEMP = 11 (48 KHz)
    7	:   LUT_DATA <= 16'h0C00;   //R6 PWR_CTL = 00h (disable power down)
    8	:   LUT_DATA <= 16'h0E02;   //R7 FORMAT=10(I2S), 16 bit
    9	:   LUT_DATA <= 16'h1002;   //R8 48KHz, Normal mode
    10	:   LUT_DATA <= 16'h1201;   //R9 ACTIVE	

	//	Video Config Data
	11	:	LUT_DATA	<=	16'h9803;  //Must be set to 0x03 for proper operation
	12	:	LUT_DATA	<=	16'h0100;  //Set 'N' value at 6144
	13	:	LUT_DATA	<=	16'h0218;  //Set 'N' value at 6144
	14	:	LUT_DATA	<=	16'h0300;  //Set 'N' value at 6144
	15	:	LUT_DATA	<=	16'h1470;  // Set Ch count in the channel status to 8.
	16	:	LUT_DATA	<=	16'h1520;  //Input 444 (RGB or YCrCb) with Separate Syncs, 48kHz fs
	17	:	LUT_DATA	<=	16'h1630;  //Output format 444, 24-bit input
	18	:	LUT_DATA	<=	16'h1846;  //Disable CSC
	19	:	LUT_DATA	<=	16'h4080;  //General control packet enable
	20	:	LUT_DATA	<=	16'h4110;  //Power down control
	21	:	LUT_DATA	<=	16'h49A8;  //Set dither mode - 12-to-10 bit
	22	:	LUT_DATA	<=	16'h5510;  //Set RGB in AVI infoframe
	23	:	LUT_DATA	<=	16'h5608;  //Set active format aspect
	24	:	LUT_DATA	<=	16'h96F6;  //Set interrup
	25	:	LUT_DATA	<=	16'h7307;  //Info frame Ch count to 8
	26	:	LUT_DATA	<=	16'h761f;  //Set speaker allocation for 8 channels
	27	:	LUT_DATA	<=	16'h9803;  //Must be set to 0x03 for proper operation
	28	:	LUT_DATA	<=	16'h9902;  //Must be set to Default Value
	29	:	LUT_DATA	<=	16'h9ae0;  //Must be set to 0b1110000
	30	:	LUT_DATA	<=	16'h9c30;  //PLL filter R1 value
	31	:	LUT_DATA	<=	16'h9d61;  //Set clock divide
	32	:	LUT_DATA	<=	16'ha2a4;  //Must be set to 0xA4 for proper operation
	33	:	LUT_DATA	<=	16'ha3a4;  //Must be set to 0xA4 for proper operation
	34	:	LUT_DATA	<=	16'ha504;  //Must be set to Default Value
	35	:	LUT_DATA	<=	16'hab40;  //Must be set to Default Value
	36	:	LUT_DATA	<=	16'haf16;  //Select HDMI mode
	37	:	LUT_DATA	<=	16'hba60;  //No clock delay
	38	:	LUT_DATA	<=	16'hd1ff;  //Must be set to Default Value
	39	:	LUT_DATA	<=	16'hde10;  //Must be set to Default for proper operation
	40	:	LUT_DATA	<=	16'he460;  //Must be set to Default Value
	41	:	LUT_DATA	<=	16'hfa7d;  //Nbr of times to look for good phase

	default:		LUT_DATA	<=	16'h9803;
	endcase
end
////////////////////////////////////////////////////////////////////
endmodule
