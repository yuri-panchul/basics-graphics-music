`include "config.svh"

typedef enum {ov5640_rgb565_1024_768,
              ov7640_rgb565_640_480} cameras_t;

module lab_top
# (
    parameter           clk_mhz        = 50,
	 parameter cameras_t cam            = ov7640_rgb565_640_480
)
(
   input                       clk,
   input                       rst,
   input                       cmos_clk,          //cmos externl clock 
 	inout                       cmos_scl,          //cmos i2c clock
	inout                       cmos_sda,          //cmos i2c data
	input                       cmos_vsync,        //cmos vsync
	input                       cmos_href,         //cmos hsync refrence,data valid
	input                       cmos_pclk,         //cmos pxiel clock
   output                      cmos_xclk,         //cmos externl clock 
	input   [7:0]               cmos_db,           //cmos data
	output                      cmos_rst_n,        //cmos reset 
	output                      cmos_pwdn,         //cmos power down
	output reg[15:0]            pdata_o,
	output reg	                hblank,
	output reg                  de_o
);

wire[9:0]                       lut_index;
wire[31:0]                      lut_data;
wire                            i2c_addr_2byte;
reg [15:0] 						     write_data;

localparam logic [15:0] clk_div_cnt = clk_mhz * 10;

assign cmos_xclk = cmos_clk;
assign cmos_pwdn = 1'b0;
assign cmos_rst_n = 1'b1;

//I2C master controller
i2c_config i2c_config_m0(
	.rst                        (rst                      ),
	.clk                        (clk                      ),
	.clk_div_cnt                (clk_div_cnt              ),
	.i2c_addr_2byte             (i2c_addr_2byte           ),
	.lut_index                  (lut_index                ),
	.lut_dev_addr               (lut_data[31:24]          ),
	.lut_reg_addr               (lut_data[23:8]           ),
	.lut_reg_data               (lut_data[7:0]            ),
	.error                      (                         ),
	.done                       (                         ),
	.i2c_scl                    (cmos_scl                 ),
	.i2c_sda                    (cmos_sda                 )
);

generate
if(cam==ov5640_rgb565_1024_768) begin: b1
//configure look-up table
lut_ov5640_rgb565_1024_768 lut_ov5640_rgb565_1024_768_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 ),
	.i2c_addr_2byte             (i2c_addr_2byte           )
);
//assign pdata_o = {write_data[4:0],write_data[10:5],write_data[15:11]};
end: b1
else begin: b2
//configure look-up table
lut_ov7640_rgb565_640_480 lut_ov7640_rgb565_640_480_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 ),
	.i2c_addr_2byte             (i2c_addr_2byte           )
);
//assign pdata_o = {write_data[15:11],write_data[10:5],write_data[4:0]};
end: b2
endgenerate

//CMOS sensor 8bit data is converted to 16bit data
cmos_8_16bit cmos_8_16bit_m0(
	.rst                        (rst                      ),
	.pclk                       (cmos_pclk                ),
	.pdata_i                    (cmos_db                  ),
	.de_i                       (cmos_href                ),
	.pdata_o                    (write_data               ),
	.hblank                     (hblank                   ),
	.de_o                       (de_o                     )
);

assign pdata_o = {write_data[4:0],write_data[10:5],write_data[15:11]};

endmodule