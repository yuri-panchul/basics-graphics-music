`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter   clk_mhz = 100,
                w_key   = 4,  //4 keys on 7seg add-on shield
                w_sw    = 0,
                w_led   = 8,  //native board LEDs
                w_digit = 4,  //4 digits on 7seg add-on shield
                w_gpio  = 0,
				screen_width = 640,
				screen_height = 480
)
(
	input  CLK,
    input  KEY0,
    input  KEY1,
	input  [7:0] ADC_D,
	input  [7:0] FTD,
	input  [7:0] FTC,
	input  FTB0,
	output FTB1,
	output ADC_CLK,
	output [7:0] LED,
	inout  [19:0] IO,
	output       TMDS_CLK_N,
	output       TMDS_CLK_P,
	output [2:0] TMDS_D_N,
	output [2:0] TMDS_D_P
);

//------------------------------------------------------------------------
//clocks (HDMI needs x5 from pixel clock)

localparam vid_clk_mhz = 125;

wire pll_lock;
wire pixel_clk_x5;
Gowin_rPLL u_pll(
	.clkin( CLK ),
	.clkout( pixel_clk_x5 ), //vid_clk_mhz
	.lock( pll_lock )
	);

wire pixel_clk;
Gowin_CLKDIV u_clkdiv(
	.hclkin( pixel_clk_x5 ),
	.clkout( pixel_clk ),
	.resetn( pll_lock )
    );

//------------------------------------------------------------------------
//ADC & MIC code
//ADC onboard is 20MHz/8bit only, pixel clock is 25MHz, is too high
//divide on 2 then
reg [9:0]adc_cnt_ = 0;
reg [7:0]adc_=0;
assign ADC_CLK = adc_cnt_[1];
always @(posedge pixel_clk)
begin
	adc_cnt_ <= adc_cnt_+1;
    if(adc_cnt_==0)
        adc_ <= ADC_D;
end

//make ADC data "signed" (need resistor voltage divider on ADC input)
wire [23:0] mic; assign mic = { adc_^8'h80,16'h0000 };

//------------------------------------------------------------------------
//serial port code
wire UART_RX;
wire UART_TX;
assign FTB1 = UART_TX;
assign UART_RX = FTB0;

//------------------------------------------------------------------------
//7seg code
wire [7:0]abcdefgh;
wire [3:0]digit;

// 7-segment assignment bAfCgD.e	
assign IO[6]= ~abcdefgh[7]; //A
assign IO[7]= ~abcdefgh[6]; //B
assign IO[4]= ~abcdefgh[5]; //C
assign IO[2]= ~abcdefgh[4]; //D
assign IO[0]= ~abcdefgh[3]; //E
assign IO[5]= ~abcdefgh[2]; //F
assign IO[3]= ~abcdefgh[1]; //G
assign IO[1]= ~abcdefgh[0]; //Dot

assign IO[15]= digit[3];
assign IO[13]= digit[2];
assign IO[12]= digit[1];
assign IO[14]= digit[0];

assign IO[19:16]= 4'b0000;

//------------------------------------------------------------------------
//KEY Buttons and LEDs
wire key_rst_n; assign key_rst_n = KEY0 & KEY1;
wire rst; assign rst = ~( key_rst_n & pll_lock );

wire [w_key-1:0]top_key;
assign top_key  = ~ {IO[8],IO[9],IO[10],IO[11]};

wire [w_led - 1:0]top_led;
assign LED = top_led;

//------------------------------------------------------------------------
wire [9:0] x10;
wire [9:0] y10;
wire vsync;
wire hsync;
wire display_on;
wire pixel_en;

vga
# (
	.H_DISPLAY   ( screen_width  ),
	.V_DISPLAY   ( screen_height ),
	.CLK_MHZ     ( clk_mhz       )
)
i_vga
(
	.clk         ( CLK           ),
	.rst         ( rst           ),
	.hsync       ( hsync         ),
	.vsync       ( vsync         ),
	.display_on  ( display_on    ),
	.hpos        ( x10           ),
	.vpos        ( y10           ),
	.pixel_clk   ( pixel_en      )
);

wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;

reg pixel_en_;
reg vsync_;
reg hsync_;
reg display_on_;
reg [7:0] red_;
reg [7:0] green_;
reg [7:0] blue_;

always @(posedge CLK)
begin
	pixel_en_ <= pixel_en;
    if(pixel_en_)
    begin
        display_on_ <= display_on;
        vsync_ <= vsync;
        hsync_ <= hsync;
        red_   <= red;
        green_ <= green;
        blue_  <= blue;
    end
end

HDMI u_hdmi(
	.clk_pixel( pixel_clk ),
	.clk_5x_pixel( pixel_clk_x5 ),
	.hsync(  hsync_ ),
	.vsync(  vsync_ ),
	.active( display_on_ ),
	.red( red_ ),
	.green( green_ ),
	.blue( blue_ ),
	.tmds_clk_n( TMDS_CLK_N ),
	.tmds_clk_p( TMDS_CLK_P ),
	.tmds_d_n( TMDS_D_N ),
	.tmds_d_p( TMDS_D_P )
	);

//------------------------------------------------------------------------
lab_top # (
        .clk_mhz ( clk_mhz   ),
        .w_key   ( w_key     ),  // The last key is used for a reset
        .w_sw    ( w_sw      ),
        .w_led   ( w_led     ),
        .w_digit ( w_digit   ),
        .w_gpio  ( w_gpio    ),
        .w_red   ( 8         ),
        .w_green ( 8         ),
        .w_blue  ( 8         )
    )
    i_top
    (
        .clk        ( CLK     ),
        .slow_clk   ( pixel_clk  ),
        .rst        ( rst        ),

        .key        ( top_key    ),
        .sw         (            ),

        .led        ( top_led    ),

        .abcdefgh   ( abcdefgh   ),
        .digit      ( digit      ),

        .x          ( x10        ),
        .y          ( y10        ),

        .red        ( red        ),
        .green      ( green      ),
        .blue       ( blue       ),

        .uart_rx    ( UART_RX    ),
        .uart_tx    ( UART_TX    ),

        .mic        ( mic        ),
        .sound      (            ),
        .gpio       (            )
    );

endmodule
