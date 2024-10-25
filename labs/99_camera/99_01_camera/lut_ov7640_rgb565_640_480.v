module lut_ov7640_rgb565_640_480(
	input[9:0]             lut_index,   //Look-up table address
	output reg[31:0]       lut_data,     //Device address (8bit I2C address), register address, register data
	output i2c_addr_2byte
);

 assign i2c_addr_2byte = 1'b0;

always@(*)
begin
	case(lut_index)			  
//	OV7670 : VGA RGB565
		10'd  0: lut_data <= {8'h42 , 24'h001204};	//复位，VGA，RGB565 (00:YUV,04:RGB)(8x全局复位)
		10'd  1: lut_data <= {8'h42 , 24'h0040d0};	//RGB565, 00-FF(d0)（YUV下要改01-FE(80)）
		10'd  2: lut_data <= {8'h42 , 24'h003a04};	//TSLB(TSLB[3], COM13[0])00:YUYV, 01:YVYU, 10:UYVY(CbYCrY), 11:VYUY
		10'd  3: lut_data <= {8'h42 , 24'h003dc8};	//COM13(TSLB[3], COM13[0])00:YUYV, 01:YVYU, 10:UYVY(CbYCrY), 11:VYUY
		10'd  4: lut_data <= {8'h42 , 24'h001e31};	//默认01，Bit[5]水平镜像，Bit[4]竖直镜像
		10'd  5: lut_data <= {8'h42 , 24'h006b00};	//旁路PLL倍频；0x0A：关闭内部LDO；0x00：打开LDO
		10'd  6: lut_data <= {8'h42 , 24'h0032b6};	//HREF 控制(80)
		10'd  7: lut_data <= {8'h42 , 24'h001713};	//HSTART 输出格式-行频开始高8位(11) 
		10'd  8: lut_data <= {8'h42 , 24'h001801};	//HSTOP  输出格式-行频结束高8位(61)
		10'd  9: lut_data <= {8'h42 , 24'h001902};	//VSTART 输出格式-场频开始高8位(03)
		10'd 10: lut_data <= {8'h42 , 24'h001a7a};	//VSTOP  输出格式-场频结束高8位(7b)
		10'd 11: lut_data <= {8'h42 , 24'h00030a};	//VREF	 帧竖直方向控制(00)
		10'd 12: lut_data <= {8'h42 , 24'h000c00};	//DCW使能 禁止(00)
		10'd 13: lut_data <= {8'h42 , 24'h003e00};	//PCLK分频00 Normal，10（1分频）,11（2分频）,12（4分频）,13（8分频）14（16分频）
		10'd 14: lut_data <= {8'h42 , 24'h007000};	//00:Normal, 80:移位1, 00:彩条, 80:渐变彩条   7000
		10'd 15: lut_data <= {8'h42 , 24'h007100};	//00:Normal, 00:移位1, 80:彩条, 80：渐变彩条  7100
		10'd 16: lut_data <= {8'h42 , 24'h007211};	//默认 水平，垂直8抽样(11)	        
		10'd 17: lut_data <= {8'h42 , 24'h007300};	//DSP缩放时钟分频00 Normal，10（1分频）,11（2分频）,12（4分频）,13（8分频）14（16分频） 
		10'd 18: lut_data <= {8'h42 , 24'h00a202};	//默认 像素始终延迟	(02)
		10'd 19: lut_data <= {8'h42 , 24'h001180};	//内部工作时钟设置，直接使用外部时钟源(80)
		10'd 20: lut_data <= {8'h42 , 24'h007a20};
		10'd 21: lut_data <= {8'h42 , 24'h007b1c};
		10'd 22: lut_data <= {8'h42 , 24'h007c28};
		10'd 23: lut_data <= {8'h42 , 24'h007d3c};
		10'd 24: lut_data <= {8'h42 , 24'h007e55};
		10'd 25: lut_data <= {8'h42 , 24'h007f68};
		10'd 26: lut_data <= {8'h42 , 24'h008076};
		10'd 27: lut_data <= {8'h42 , 24'h008180};
		10'd 28: lut_data <= {8'h42 , 24'h008288};
		10'd 29: lut_data <= {8'h42 , 24'h00838f};
		10'd 30: lut_data <= {8'h42 , 24'h008496};
		10'd 31: lut_data <= {8'h42 , 24'h0085a3};
		10'd 32: lut_data <= {8'h42 , 24'h0086af};
		10'd 33: lut_data <= {8'h42 , 24'h0087c4};
		10'd 34: lut_data <= {8'h42 , 24'h0088d7};
		10'd 35: lut_data <= {8'h42 , 24'h0089e8};
		10'd 36: lut_data <= {8'h42 , 24'h0013e0};
		10'd 37: lut_data <= {8'h42 , 24'h000000};
		10'd 38: lut_data <= {8'h42 , 24'h001000};
		10'd 39: lut_data <= {8'h42 , 24'h000d00};
		10'd 40: lut_data <= {8'h42 , 24'h001428};	//
		10'd 41: lut_data <= {8'h42 , 24'h00a505};
		10'd 42: lut_data <= {8'h42 , 24'h00ab07};
		10'd 43: lut_data <= {8'h42 , 24'h002475};
		10'd 44: lut_data <= {8'h42 , 24'h002563};
		10'd 45: lut_data <= {8'h42 , 24'h0026a5};
		10'd 46: lut_data <= {8'h42 , 24'h009f78};
		10'd 47: lut_data <= {8'h42 , 24'h00a068};
		10'd 48: lut_data <= {8'h42 , 24'h00a103};
		10'd 49: lut_data <= {8'h42 , 24'h00a6df};
		10'd 50: lut_data <= {8'h42 , 24'h00a7df};
		10'd 51: lut_data <= {8'h42 , 24'h00a8f0};
		10'd 52: lut_data <= {8'h42 , 24'h00a990};
		10'd 53: lut_data <= {8'h42 , 24'h00aa94};
		10'd 54: lut_data <= {8'h42 , 24'h0013ef};	//
		10'd 55: lut_data <= {8'h42 , 24'h000e61};
		10'd 56: lut_data <= {8'h42 , 24'h000f4b};
		10'd 57: lut_data <= {8'h42 , 24'h001602};

	
		10'd 58: lut_data <= {8'h42 , 24'h002102};
		10'd 59: lut_data <= {8'h42 , 24'h002291};
		10'd 60: lut_data <= {8'h42 , 24'h002907};
		10'd 61: lut_data <= {8'h42 , 24'h00330b};
		10'd 62: lut_data <= {8'h42 , 24'h00350b};
		10'd 63: lut_data <= {8'h42 , 24'h00371d};
		10'd 64: lut_data <= {8'h42 , 24'h003871};
		10'd 65: lut_data <= {8'h42 , 24'h00392a};
		10'd 66: lut_data <= {8'h42 , 24'h003c78};
		10'd 67: lut_data <= {8'h42 , 24'h004d40};
		10'd 68: lut_data <= {8'h42 , 24'h004e20};
		10'd 69: lut_data <= {8'h42 , 24'h006900};
	
		10'd 70: lut_data <= {8'h42 , 24'h007419};
		10'd 71: lut_data <= {8'h42 , 24'h008d4f};
		10'd 72: lut_data <= {8'h42 , 24'h008e00};
		10'd 73: lut_data <= {8'h42 , 24'h008f00};
		10'd 74: lut_data <= {8'h42 , 24'h009000};
		10'd 75: lut_data <= {8'h42 , 24'h009100};
		10'd 76: lut_data <= {8'h42 , 24'h009200};
		10'd 77: lut_data <= {8'h42 , 24'h009600};
		10'd 78: lut_data <= {8'h42 , 24'h009a80};
		10'd 79: lut_data <= {8'h42 , 24'h00b084};
		10'd 80: lut_data <= {8'h42 , 24'h00b10c};
		10'd 81: lut_data <= {8'h42 , 24'h00b20e};
		10'd 82: lut_data <= {8'h42 , 24'h00b382};
		10'd 83: lut_data <= {8'h42 , 24'h00b80a};

		10'd 84: lut_data <= {8'h42 , 24'h004314};
		10'd 85: lut_data <= {8'h42 , 24'h0044f0};
		10'd 86: lut_data <= {8'h42 , 24'h004534};
		10'd 87: lut_data <= {8'h42 , 24'h004658};
		10'd 88: lut_data <= {8'h42 , 24'h004728};
		10'd 89: lut_data <= {8'h42 , 24'h00483a};
		10'd 90: lut_data <= {8'h42 , 24'h005988};
		10'd 91: lut_data <= {8'h42 , 24'h005a88};
		10'd 92: lut_data <= {8'h42 , 24'h005b44};
		10'd 93: lut_data <= {8'h42 , 24'h005c67};
		10'd 94: lut_data <= {8'h42 , 24'h005d49};
		10'd 95: lut_data <= {8'h42 , 24'h005e0e};
		10'd 96: lut_data <= {8'h42 , 24'h006404};
		10'd 97: lut_data <= {8'h42 , 24'h006520};
		10'd 98: lut_data <= {8'h42 , 24'h006605};
		10'd 99: lut_data <= {8'h42 , 24'h009404};
		10'd100: lut_data <= {8'h42 , 24'h009508};
		10'd101: lut_data <= {8'h42 , 24'h006c0a};
		10'd102: lut_data <= {8'h42 , 24'h006d55};
		10'd103: lut_data <= {8'h42 , 24'h006e11};
		10'd104: lut_data <= {8'h42 , 24'h006f9f};
		10'd105: lut_data <= {8'h42 , 24'h006a40};
		10'd106: lut_data <= {8'h42 , 24'h000140};
		10'd107: lut_data <= {8'h42 , 24'h000240};
		10'd108: lut_data <= {8'h42 , 24'h0013e7};
		10'd109: lut_data <= {8'h42 , 24'h001500};
	
		10'd110: lut_data <= {8'h42 , 24'h004f80};
		10'd111: lut_data <= {8'h42 , 24'h005080};
		10'd112: lut_data <= {8'h42 , 24'h005100};
		10'd113: lut_data <= {8'h42 , 24'h005222};
		10'd114: lut_data <= {8'h42 , 24'h00535e};
		10'd115: lut_data <= {8'h42 , 24'h005480};
		10'd116: lut_data <= {8'h42 , 24'h00589e};
	
		10'd117: lut_data <= {8'h42 , 24'h004108};
		10'd118: lut_data <= {8'h42 , 24'h003f00};
		10'd119: lut_data <= {8'h42 , 24'h007505};
		10'd120: lut_data <= {8'h42 , 24'h0076e1};
		10'd121: lut_data <= {8'h42 , 24'h004c00};
		10'd122: lut_data <= {8'h42 , 24'h007701};
	
		10'd123: lut_data <= {8'h42 , 24'h004b09};
		10'd124: lut_data <= {8'h42 , 24'h00c9F0};//16'hc960;
		10'd125: lut_data <= {8'h42 , 24'h004138};
		10'd126: lut_data <= {8'h42 , 24'h005640};
	
	
		10'd127: lut_data <= {8'h42 , 24'h003411};
		10'd128: lut_data <= {8'h42 , 24'h003b02};
		10'd129: lut_data <= {8'h42 , 24'h00a489};
		10'd130: lut_data <= {8'h42 , 24'h009600};
		10'd131: lut_data <= {8'h42 , 24'h009730};
		10'd132: lut_data <= {8'h42 , 24'h009820};
		10'd133: lut_data <= {8'h42 , 24'h009930};
		10'd134: lut_data <= {8'h42 , 24'h009a84};
		10'd135: lut_data <= {8'h42 , 24'h009b29};
		10'd136: lut_data <= {8'h42 , 24'h009c03};
		10'd137: lut_data <= {8'h42 , 24'h009d4c};
		10'd138: lut_data <= {8'h42 , 24'h009e3f};
		10'd139: lut_data <= {8'h42 , 24'h007804};
	
	
		10'd140: lut_data <= {8'h42 , 24'h007901};
		10'd141: lut_data <= {8'h42 , 24'h00c8f0};
		10'd142: lut_data <= {8'h42 , 24'h00790f};
		10'd143: lut_data <= {8'h42 , 24'h00c800};
		10'd144: lut_data <= {8'h42 , 24'h007910};
		10'd145: lut_data <= {8'h42 , 24'h00c87e};
		10'd146: lut_data <= {8'h42 , 24'h00790a};
		10'd147: lut_data <= {8'h42 , 24'h00c880};
		10'd148: lut_data <= {8'h42 , 24'h00790b};
		10'd149: lut_data <= {8'h42 , 24'h00c801};
		10'd150: lut_data <= {8'h42 , 24'h00790c};
		10'd151: lut_data <= {8'h42 , 24'h00c80f};
		10'd152: lut_data <= {8'h42 , 24'h00790d};
		10'd153: lut_data <= {8'h42 , 24'h00c820};
		10'd154: lut_data <= {8'h42 , 24'h007909};
		10'd155: lut_data <= {8'h42 , 24'h00c880};
		10'd156: lut_data <= {8'h42 , 24'h007902};
		10'd157: lut_data <= {8'h42 , 24'h00c8c0};
		10'd158: lut_data <= {8'h42 , 24'h007903};
		10'd159: lut_data <= {8'h42 , 24'h00c840};
		10'd160: lut_data <= {8'h42 , 24'h007905};
		10'd161: lut_data <= {8'h42 , 24'h00c830}; 
		10'd162: lut_data <= {8'h42 , 24'h007926};
	
		10'd163: lut_data <= {8'h42 , 24'h000903};
		10'd164: lut_data <= {8'h42 , 24'h003b42};
		default: lut_data <= {8'hff , 24'hffffff};
	endcase
end


endmodule 