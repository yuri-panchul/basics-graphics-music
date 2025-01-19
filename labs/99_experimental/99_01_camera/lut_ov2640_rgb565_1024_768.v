module lut_ov2640_rgb565_1024_768(
	input[9:0]             lut_index,   //Look-up table address
	output reg[31:0]       lut_data,    //Device address (8bit I2C address), register address, register data
	output i2c_addr_2byte
);

 assign i2c_addr_2byte = 1'b0;

always@(*)
begin
	case(lut_index)			  
		10'd000 : lut_data <= {8'h60 , 24'h00FF_01};
		10'd001 : lut_data <= {8'h60 , 24'h0012_80};
		10'd002 : lut_data <= {8'h60 , 24'h00FF_00};
		10'd003 : lut_data <= {8'h60 , 24'h002c_ff};
		10'd004 : lut_data <= {8'h60 , 24'h002e_df};
		10'd005 : lut_data <= {8'h60 , 24'h00FF_01};
		10'd006 : lut_data <= {8'h60 , 24'h003c_32};
		10'd007 : lut_data <= {8'h60 , 24'h0011_80};/* Set PCLK divider */
		10'd008 : lut_data <= {8'h60 , 24'h0009_02};/* Output drive x2 */
		10'd009 : lut_data <= {8'h60 , 24'h0004_28};
		10'd010 : lut_data <= {8'h60 , 24'h0013_E5};
		10'd011 : lut_data <= {8'h60 , 24'h0014_48};
		10'd012 : lut_data <= {8'h60 , 24'h0015_00};//Invert VSYNC
		10'd013 : lut_data <= {8'h60 , 24'h002c_0c};
		10'd014 : lut_data <= {8'h60 , 24'h0033_78};
		10'd015 : lut_data <= {8'h60 , 24'h003a_33};
		10'd016 : lut_data <= {8'h60 , 24'h003b_fb};
		10'd017 : lut_data <= {8'h60 , 24'h003e_00};
		10'd018 : lut_data <= {8'h60 , 24'h0043_11};
		10'd019 : lut_data <= {8'h60 , 24'h0016_10};
		10'd020 : lut_data <= {8'h60 , 24'h0039_02};
		10'd021 : lut_data <= {8'h60 , 24'h0035_88};
		10'd022 : lut_data <= {8'h60 , 24'h0022_0a};
		10'd023 : lut_data <= {8'h60 , 24'h0037_40};
		10'd024 : lut_data <= {8'h60 , 24'h0023_00};
		10'd025 : lut_data <= {8'h60 , 24'h0034_a0};
		10'd026 : lut_data <= {8'h60 , 24'h0006_02};
		10'd027 : lut_data <= {8'h60 , 24'h0006_88};
		10'd028 : lut_data <= {8'h60 , 24'h0007_c0};
		10'd029 : lut_data <= {8'h60 , 24'h000d_b7};
		10'd030 : lut_data <= {8'h60 , 24'h000e_01};
		10'd031 : lut_data <= {8'h60 , 24'h004c_00};
		10'd032 : lut_data <= {8'h60 , 24'h004a_81};
		10'd033 : lut_data <= {8'h60 , 24'h0021_99};
		10'd034 : lut_data <= {8'h60 , 24'h0024_40};
		10'd035 : lut_data <= {8'h60 , 24'h0025_38};
		10'd036 : lut_data <= {8'h60 , 24'h0026_82};/* AGC/AEC fast mode operating region */	
		10'd037 : lut_data <= {8'h60 , 24'h0048_00};/* Zoom control 2 MSBs */
		10'd038 : lut_data <= {8'h60 , 24'h0049_00};/* Zoom control 8 MSBs */
		10'd039 : lut_data <= {8'h60 , 24'h005c_00};
		10'd040 : lut_data <= {8'h60 , 24'h0063_00};
		10'd041 : lut_data <= {8'h60 , 24'h0046_00};
		10'd042 : lut_data <= {8'h60 , 24'h0047_00};
		10'd043 : lut_data <= {8'h60 , 24'h000C_3A};/* Set banding filter */
		10'd044 : lut_data <= {8'h60 , 24'h005D_55};
		10'd045 : lut_data <= {8'h60 , 24'h005E_7d};
		10'd046 : lut_data <= {8'h60 , 24'h005F_7d};
		10'd047 : lut_data <= {8'h60 , 24'h0060_55};
		10'd048 : lut_data <= {8'h60 , 24'h0061_70};
		10'd049 : lut_data <= {8'h60 , 24'h0062_80};
		10'd050 : lut_data <= {8'h60 , 24'h007c_05};
		10'd051 : lut_data <= {8'h60 , 24'h0020_80};
		10'd052 : lut_data <= {8'h60 , 24'h0028_30};
		10'd053 : lut_data <= {8'h60 , 24'h006c_00};
		10'd054 : lut_data <= {8'h60 , 24'h006d_80};
		10'd055 : lut_data <= {8'h60 , 24'h006e_00};
		10'd056 : lut_data <= {8'h60 , 24'h0070_02};
		10'd057 : lut_data <= {8'h60 , 24'h0071_94};
		10'd058 : lut_data <= {8'h60 , 24'h0073_c1};
		10'd059 : lut_data <= {8'h60 , 24'h003d_34};
		10'd060 : lut_data <= {8'h60 , 24'h005a_57};
		10'd061 : lut_data <= {8'h60 , 24'h004F_bb};
		10'd062 : lut_data <= {8'h60 , 24'h0050_9c};
		10'd063 : lut_data <= {8'h60 , 24'h00FF_00};
		10'd064 : lut_data <= {8'h60 , 24'h00e5_7f};
		10'd065 : lut_data <= {8'h60 , 24'h00F9_C0};
		10'd066 : lut_data <= {8'h60 , 24'h0041_24};
		10'd067 : lut_data <= {8'h60 , 24'h00E0_14};
		10'd068 : lut_data <= {8'h60 , 24'h0076_ff};
		10'd069 : lut_data <= {8'h60 , 24'h0033_a0};
		10'd070 : lut_data <= {8'h60 , 24'h0042_20};
		10'd071 : lut_data <= {8'h60 , 24'h0043_18};
		10'd072 : lut_data <= {8'h60 , 24'h004c_00};
		10'd073 : lut_data <= {8'h60 , 24'h0087_D0};
		10'd074 : lut_data <= {8'h60 , 24'h0088_3f};
		10'd075 : lut_data <= {8'h60 , 24'h00d7_03};
		10'd076 : lut_data <= {8'h60 , 24'h00d9_10};
		10'd077 : lut_data <= {8'h60 , 24'h00D3_82};
		10'd078 : lut_data <= {8'h60 , 24'h00c8_08};
		10'd079 : lut_data <= {8'h60 , 24'h00c9_80};
		10'd080 : lut_data <= {8'h60 , 24'h007C_00};
		10'd081 : lut_data <= {8'h60 , 24'h007D_00};
		10'd082 : lut_data <= {8'h60 , 24'h007C_03};
		10'd083 : lut_data <= {8'h60 , 24'h007D_48};
		10'd084 : lut_data <= {8'h60 , 24'h007D_48};
		10'd085 : lut_data <= {8'h60 , 24'h007C_08};
		10'd086 : lut_data <= {8'h60 , 24'h007D_20};
		10'd087 : lut_data <= {8'h60 , 24'h007D_10};
		10'd088 : lut_data <= {8'h60 , 24'h007D_0e};
		10'd089 : lut_data <= {8'h60 , 24'h0090_00};
		10'd090 : lut_data <= {8'h60 , 24'h0091_0e};
		10'd091 : lut_data <= {8'h60 , 24'h0091_1a};
		10'd092 : lut_data <= {8'h60 , 24'h0091_31};
		10'd093 : lut_data <= {8'h60 , 24'h0091_5a};
		10'd094 : lut_data <= {8'h60 , 24'h0091_69};
		10'd095 : lut_data <= {8'h60 , 24'h0091_75};
		10'd096 : lut_data <= {8'h60 , 24'h0091_7e};
		10'd097 : lut_data <= {8'h60 , 24'h0091_88};
		10'd098 : lut_data <= {8'h60 , 24'h0091_8f};
		10'd099 : lut_data <= {8'h60 , 24'h0091_96};
		10'd100 : lut_data <= {8'h60 , 24'h0091_a3};
		10'd101 : lut_data <= {8'h60 , 24'h0091_af};
		10'd102 : lut_data <= {8'h60 , 24'h0091_c4};
		10'd103 : lut_data <= {8'h60 , 24'h0091_d7};
		10'd104 : lut_data <= {8'h60 , 24'h0091_e8};
		10'd105 : lut_data <= {8'h60 , 24'h0091_20};
		10'd106 : lut_data <= {8'h60 , 24'h0092_00};
		10'd107 : lut_data <= {8'h60 , 24'h0093_06};
		10'd108 : lut_data <= {8'h60 , 24'h0093_e3};
		10'd109 : lut_data <= {8'h60 , 24'h0093_03};
		10'd110 : lut_data <= {8'h60 , 24'h0093_03};
		10'd111 : lut_data <= {8'h60 , 24'h0093_00};
		10'd112 : lut_data <= {8'h60 , 24'h0093_02};
		10'd113 : lut_data <= {8'h60 , 24'h0093_00};
		10'd114 : lut_data <= {8'h60 , 24'h0093_00};
		10'd115 : lut_data <= {8'h60 , 24'h0093_00};
		10'd116 : lut_data <= {8'h60 , 24'h0093_00};
		10'd117 : lut_data <= {8'h60 , 24'h0093_00};
		10'd118 : lut_data <= {8'h60 , 24'h0093_00};
		10'd119 : lut_data <= {8'h60 , 24'h0093_00};
		10'd120 : lut_data <= {8'h60 , 24'h0096_00};
		10'd121 : lut_data <= {8'h60 , 24'h0097_08};
		10'd122 : lut_data <= {8'h60 , 24'h0097_19};
		10'd123 : lut_data <= {8'h60 , 24'h0097_02};
		10'd124 : lut_data <= {8'h60 , 24'h0097_0c};
		10'd125 : lut_data <= {8'h60 , 24'h0097_24};
		10'd126 : lut_data <= {8'h60 , 24'h0097_30};
		10'd127 : lut_data <= {8'h60 , 24'h0097_28};
		10'd128 : lut_data <= {8'h60 , 24'h0097_26};
		10'd129 : lut_data <= {8'h60 , 24'h0097_02};
		10'd130 : lut_data <= {8'h60 , 24'h0097_98};
		10'd131 : lut_data <= {8'h60 , 24'h0097_80};
		10'd132 : lut_data <= {8'h60 , 24'h0097_00};
		10'd133 : lut_data <= {8'h60 , 24'h0097_00};
		10'd134 : lut_data <= {8'h60 , 24'h00a4_00};
		10'd135 : lut_data <= {8'h60 , 24'h00a8_00};
		10'd136 : lut_data <= {8'h60 , 24'h00c5_11};
		10'd137 : lut_data <= {8'h60 , 24'h00c6_51};
		10'd138 : lut_data <= {8'h60 , 24'h00bf_80};
		10'd139 : lut_data <= {8'h60 , 24'h00c7_10};
		10'd140 : lut_data <= {8'h60 , 24'h00b6_66};
		10'd141 : lut_data <= {8'h60 , 24'h00b8_A5};
		10'd142 : lut_data <= {8'h60 , 24'h00b7_64};
		10'd143 : lut_data <= {8'h60 , 24'h00b9_7C};
		10'd144 : lut_data <= {8'h60 , 24'h00b3_af};
		10'd145 : lut_data <= {8'h60 , 24'h00b4_97};
		10'd146 : lut_data <= {8'h60 , 24'h00b5_FF};
		10'd147 : lut_data <= {8'h60 , 24'h00b0_C5};
		10'd148 : lut_data <= {8'h60 , 24'h00b1_94};
		10'd149 : lut_data <= {8'h60 , 24'h00b2_0f};
		10'd150 : lut_data <= {8'h60 , 24'h00c4_5c};
		10'd151 : lut_data <= {8'h60 , 24'h00a6_00};
		10'd152 : lut_data <= {8'h60 , 24'h00a7_20};
		10'd153 : lut_data <= {8'h60 , 24'h00a7_d8};
		10'd154 : lut_data <= {8'h60 , 24'h00a7_1b};
		10'd155 : lut_data <= {8'h60 , 24'h00a7_31};
		10'd156 : lut_data <= {8'h60 , 24'h00a7_00};
		10'd157 : lut_data <= {8'h60 , 24'h00a7_18};
		10'd158 : lut_data <= {8'h60 , 24'h00a7_20};
		10'd159 : lut_data <= {8'h60 , 24'h00a7_d8};
		10'd160 : lut_data <= {8'h60 , 24'h00a7_19};
		10'd161 : lut_data <= {8'h60 , 24'h00a7_31};
		10'd162 : lut_data <= {8'h60 , 24'h00a7_00};
		10'd163 : lut_data <= {8'h60 , 24'h00a7_18};
		10'd164 : lut_data <= {8'h60 , 24'h00a7_20};
		10'd165 : lut_data <= {8'h60 , 24'h00a7_d8};
		10'd166 : lut_data <= {8'h60 , 24'h00a7_19};
		10'd167 : lut_data <= {8'h60 , 24'h00a7_31};
		10'd168 : lut_data <= {8'h60 , 24'h00a7_00};
		10'd169 : lut_data <= {8'h60 , 24'h00a7_18};
		10'd170 : lut_data <= {8'h60 , 24'h007f_00};
		10'd171 : lut_data <= {8'h60 , 24'h00e5_1f};
		10'd172 : lut_data <= {8'h60 , 24'h00e1_77};
		10'd173 : lut_data <= {8'h60 , 24'h00dd_7f};
		10'd174 : lut_data <= {8'h60 , 24'h00C2_0E};
		10'd175 : lut_data <= {8'h60 , 24'h00FF_01};
		10'd176 : lut_data <= {8'h60 , 24'h00FF_00};
		10'd177 : lut_data <= {8'h60 , 24'h00E0_04};
		10'd178 : lut_data <= {8'h60 , 24'h00DA_04};//08:RGB565  04:RAW10
		10'd179 : lut_data <= {8'h60 , 24'h00D7_03};
		10'd180 : lut_data <= {8'h60 , 24'h00E1_77};
		10'd181 : lut_data <= {8'h60 , 24'h00E0_00};
		10'd182 : lut_data <= {8'h60 , 24'h00FF_00};
		10'd183 : lut_data <= {8'h60 , 24'h0005_01};
		10'd184 : lut_data <= {8'h60 , 24'h005A_A0};//(w>>2)&0xFF	//28:w=160 //A0:w=640 //C8:w=800
		10'd185 : lut_data <= {8'h60 , 24'h005B_78};//(h>>2)&0xFF	//1E:h=120 //78:h=480 //96:h=600
		10'd186 : lut_data <= {8'h60 , 24'h005C_00};//((h>>8)&0x04)|((w>>10)&0x03)		
		10'd187 : lut_data <= {8'h60 , 24'h00FF_01};
		10'd188 : lut_data <= {8'h60 , 24'h0011_80};//clkrc=0x83 for resolution <= SVGA		
		10'd189 : lut_data <= {8'h60 , 24'h00FF_01};
		10'd190 : lut_data <= {8'h60 , 24'h0012_40};/* DSP input image resoultion and window size control */
		10'd191 : lut_data <= {8'h60 , 24'h0003_0A};/* UXGA=0x0F, SVGA=0x0A, CIF=0x06 */
		10'd192 : lut_data <= {8'h60 , 24'h0032_09};/* UXGA=0x36, SVGA/CIF=0x09 */
		10'd193 : lut_data <= {8'h60 , 24'h0017_11};/* UXGA=0x11, SVGA/CIF=0x11 */
		10'd194 : lut_data <= {8'h60 , 24'h0018_43};/* UXGA=0x75, SVGA/CIF=0x43 */
		10'd195 : lut_data <= {8'h60 , 24'h0019_00};/* UXGA=0x01, SVGA/CIF=0x00 */
		10'd196 : lut_data <= {8'h60 , 24'h001A_4b};/* UXGA=0x97, SVGA/CIF=0x4b */
		10'd197 : lut_data <= {8'h60 , 24'h003d_38};/* UXGA=0x34, SVGA/CIF=0x38 */
		10'd198 : lut_data <= {8'h60 , 24'h0035_da};
		10'd199 : lut_data <= {8'h60 , 24'h0022_1a};
		10'd200 : lut_data <= {8'h60 , 24'h0037_c3};
		10'd201 : lut_data <= {8'h60 , 24'h0034_c0};
		10'd202 : lut_data <= {8'h60 , 24'h0006_88};
		10'd203 : lut_data <= {8'h60 , 24'h000d_87};
		10'd204 : lut_data <= {8'h60 , 24'h000e_41};
		10'd205 : lut_data <= {8'h60 , 24'h0042_03};
		10'd206 : lut_data <= {8'h60 , 24'h00FF_00};/* Set DSP input image size and offset. The sensor output image can be scaled with OUTW/OUTH */
		10'd207 : lut_data <= {8'h60 , 24'h0005_01};
		10'd208 : lut_data <= {8'h60 , 24'h00E0_04};
		10'd209 : lut_data <= {8'h60 , 24'h00C0_64};/* Image Horizontal Size 0x51[10:3] */  //11_0010_0000 = 800
		10'd210 : lut_data <= {8'h60 , 24'h00C1_4B};/* Image Vertiacl Size 0x52[10:3] */    //10_0101_1000 = 600   
		10'd211 : lut_data <= {8'h60 , 24'h008C_00};/* {0x51[11], 0x51[2:0], 0x52[2:0]} */
		10'd212 : lut_data <= {8'h60 , 24'h0053_00};/* OFFSET_X[7:0] */
		10'd213 : lut_data <= {8'h60 , 24'h0054_00};/* OFFSET_Y[7:0] */
		10'd214 : lut_data <= {8'h60 , 24'h0051_C8};/* H_SIZE[7:0]= 0x51/4 */ //200
		10'd215 : lut_data <= {8'h60 , 24'h0052_96};/* V_SIZE[7:0]= 0x52/4 */ //150       
		10'd216 : lut_data <= {8'h60 , 24'h0055_00};/* V_SIZE[8]/OFFSET_Y[10:8]/H_SIZE[8]/OFFSET_X[10:8] */
		10'd217 : lut_data <= {8'h60 , 24'h0057_00};/* H_SIZE[9] */
		10'd218 : lut_data <= {8'h60 , 24'h0086_3D};
		10'd219 : lut_data <= {8'h60 , 24'h0050_80};/* H_DIVIDER/V_DIVIDER */        
		10'd220 : lut_data <= {8'h60 , 24'h00D3_80};/* DVP prescalar */
		10'd221 : lut_data <= {8'h60 , 24'h0005_00};
		10'd222 : lut_data <= {8'h60 , 24'h00E0_00};
		10'd223 : lut_data <= {8'h60 , 24'h00FF_00};
		10'd224 : lut_data <= {8'h60 , 24'h0005_00};
		10'd225 : lut_data <= {8'h60 , 24'h00FF_00};
		10'd226 : lut_data <= {8'h60 , 24'h00E0_04};
		10'd227 : lut_data <= {8'h60 , 24'h00DA_04};//08:RGB565  04:RAW10
		10'd228 : lut_data <= {8'h60 , 24'h00D7_03};
		10'd229 : lut_data <= {8'h60 , 24'h00E1_77};
		10'd230 : lut_data <= {8'h60 , 24'h00E0_00};            
		default: lut_data <= {8'hff , 24'hffffff};
	endcase
end


endmodule 