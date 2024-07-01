// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"

module vga
# (


    parameter N_MIXER_PIPE_STAGES = 0,
              HPOS_WIDTH          = 11,  //2024 points + sync+ front + back
              VPOS_WIDTH          = 11,
`ifdef VGA
              CLK_MHZ             =  50,  // Clock frequency (50 or 100 MHz)
              PIXEL_MHZ           =  25,   // Pixel clock frequency of VGA in MHz
              // Horizontal constants
              H_DISPLAY           = 640,  // Horizontal display width
              H_FRONT             =  16,  // Horizontal right border (front porch)
              H_SYNC              =  96,  // Horizontal sync width
              H_BACK              =  48,  // Horizontal left border (back porch)
              H_TOTAL             = 520 ,
              // Vertical constants
              V_DISPLAY           = 480,  // Vertical display height
              V_BOTTOM            =  10,  // Vertical bottom border
              V_SYNC              =   2,  // Vertical sync # lines
              V_TOP               =  33,  // Vertical top border
	      V_TOTAL             = 525
`endif
`ifdef _480_272_LCD_RGB      // 4.3" display
         CLK_MHZ     =  27,  // Clock frequency (MHz)
         PIXEL_MHZ   =  9,   // Pixel clock frequency of display (MHz)

	 H_SYNC      = 4,
	 H_BACK      = 23,
	 H_DISPLAY   = 480,
	 H_FRONT     = 13,
	 H_TOTAL     = 520,

	 V_SYNC      = 4,
	 V_BACK      = 15,
	 V_DISPLAY   = 272,
	 V_TOP       = 9,
	 V_TOTAL     = 300
`endif

`ifdef _800_480_LCD_RGB     // 5.0", 7.0" display
         CLK_MHZ     = 27,  // Clock frequency (MHz)
         PIXEL_MHZ   = 27,  // Pixel clock frequency of display (MHz)
	 H_SYNC      = 10,
	 H_BACK      = 46,
	 H_DISPLAY   = 800,
	 H_FRONT     = 210,
	 H_TOTAL     = 1066,

	 V_SYNC      = 4,
	 V_BACK      = 23,
	 V_DISPLAY   = 480,
	 V_TOP       = 13,
	 V_TOTAL     = 520
`endif
`ifdef _1280_1024_LCD_RGB
         CLK_MHZ     =  27,  // Clock frequency (MHz)
         PIXEL_MHZ   =  25,  // Pixel clock frequency of display (MHz)
	 H_SYNC      = 112,  // Horizontal Sync count
	 H_BACK      = 248,  // Back Porch
	 H_DISPLAY   = 1280, // Display Period
	 H_FRONT     = 48,   // Front Porch
	 H_TOTAL     = 1688, // Total Period

	 V_SYNC      = 3,    // Vertical Sync count
	 V_BACK      = 38,   // Back Porch
	 V_DISPLAY   = 1024, // Display Period
	 V_TOP       = 1,    // Front Porch
	 V_TOTAL     = 1066  // Total Period
`endif
)

(
    input                           clk,
    input                           rst,
    output logic                    hsync,
    output logic                    vsync,
    output logic                    display_on,
    output logic [HPOS_WIDTH - 1:0] hpos,
    output logic [VPOS_WIDTH - 1:0] vpos,
    output logic                    pixel_clk
);

    // Calculating next values of the counters
    localparam	H_AHEAD = 	12'd1;

reg [11:0] hcnt;
reg [11:0] vcnt;
wire lcd_request;

/*******************************************
		SYNC--BACK--DISP--FRONT
*******************************************/
//h_sync counter & generator
always @ (posedge clk or posedge rst)
begin
	if (rst)
		hcnt <= 11'd0;
	else
	begin
        if(hcnt < H_TOTAL - 1'b1)		//line over
            hcnt <= hcnt + 1'b1;
        else
            hcnt <= 11'd0;
	end
end

assign	hsync = (hcnt <= H_SYNC - 1'b1) ? 1'b0 : 1'b1; // line over flag

//v_sync counter & generator
always@(posedge clk or posedge rst)
begin
	if (rst)
		vcnt <= 11'b0;
	else if(hcnt == H_TOTAL - 1'b1)	//line over
		begin
		if(vcnt == V_TOTAL - 1'b1)		//frame over
			vcnt <= 11'd0;
		else
			vcnt <= vcnt + 1'b1;
		end
end

assign	vsync = (vcnt <= V_SYNC - 1'b1) ? 1'b0 : 1'b1; // frame over flag

// Control Display
assign	display_on = (hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISPLAY) &&
                     (vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISPLAY)
                      ? 1'b1 : 1'b0;                   // Display Enable Signal

//ahead x clock
assign	lcd_request = (hcnt >= H_SYNC + H_BACK - H_AHEAD && hcnt < H_SYNC + H_BACK + H_DISPLAY - H_AHEAD) &&
						(vcnt >= V_SYNC + V_BACK && vcnt < V_SYNC + V_BACK + V_DISPLAY)
						? 1'b1 : 1'b0;
//lcd xpos & ypos
assign	hpos	= 	lcd_request ? (hcnt - (H_SYNC + H_BACK - H_AHEAD)) : 11'd0;
assign	vpos	= 	lcd_request ? (vcnt - (V_SYNC + V_BACK)) : 11'd0;

`ifndef VGA
assign pixel_clk = clk ;
`else
    // Enable to divide clock from 50 or 100 MHz to 25 MHz

    logic [3:0] clk_en_cnt;
    logic clk_en;

    assign pixel_clk = clk_en;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            clk_en_cnt <= 3'b0;
            clk_en <= 1'b0;
        end
        else
        begin
            if (clk_en_cnt == (CLK_MHZ / PIXEL_MHZ) - 1)
            begin
                clk_en_cnt <= 3'b0;
                clk_en <= 1'b1;
            end
            else
            begin
                clk_en_cnt <= clk_en_cnt + 1;
                clk_en <= 1'b0;
            end
        end
    end
`endif

endmodule
