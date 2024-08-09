module lcd_timing
(
    input                   lcd_clk,
    input                   rst_n, // user button 3

    output                  lcd_en,

	output          [5:0]   lcd_r,
	output          [5:0]   lcd_b,
	output          [5:0]   lcd_g
);
	
    // Horizen count to Hsync, then next Horizen line.

    parameter       H_Pixel_Valid    = 16'd480; 
    parameter       H_FrontPorch     = 16'd50;
    parameter       H_BackPorch      = 16'd30;  

    parameter       PixelForHS       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

    parameter       V_Pixel_Valid    = 16'd272; 
    parameter       V_FrontPorch     = 16'd20;  
    parameter       V_BackPorch      = 16'd5;    

    parameter       PixelForVS       = V_Pixel_Valid + V_FrontPorch + V_BackPorch;

    // Horizen pixel count

    reg         [15:0]  H_PixelCount;
    reg         [15:0]  V_PixelCount;

    always @(  posedge lcd_clk or negedge rst_n  )begin
        if( !rst_n ) begin
            V_PixelCount      <=  16'b0;    
            H_PixelCount      <=  16'b0;
            end
        else if(  H_PixelCount == PixelForHS ) begin
            V_PixelCount      <=  V_PixelCount + 1'b1;
            H_PixelCount      <=  16'b0;
            end
        else if(  V_PixelCount == PixelForVS ) begin
            V_PixelCount      <=  16'b0;
            H_PixelCount      <=  16'b0;
            end
        else begin
            V_PixelCount      <=  V_PixelCount ;
            H_PixelCount      <=  H_PixelCount + 1'b1;
        end
    end

    // SYNC-DE MODE

    assign  lcd_en =    ( H_PixelCount >= H_BackPorch ) && ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                        ( V_PixelCount >= V_BackPorch ) && ( V_PixelCount <= V_Pixel_Valid + V_BackPorch ) && lcd_clk;

    // color bar
    localparam          Colorbar_width   =   H_Pixel_Valid / 18;

    assign  lcd_r     = ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 0  )) ? 6'b000000 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 1  )) ? 6'b000001 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 2  )) ? 6'b000010 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 3  )) ? 6'b000100 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 4  )) ? 6'b001000 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 5  )) ? 6'b010000 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 6  )) ? 6'b100000 : 6'b000000;

    assign  lcd_g    =  ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 7  )) ? 6'b000001:
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 8  )) ? 6'b000010:
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 9  )) ? 6'b000100:
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 10 )) ? 6'b001000:
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 11 )) ? 6'b010000:
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 12 )) ? 6'b100000:  6'b000000;

    assign  lcd_b    =  ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 13 )) ? 6'b000001 : 
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 14 )) ? 6'b000010 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 15 )) ? 6'b000100 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 16 )) ? 6'b001000 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 17 )) ? 6'b010000 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 18 )) ? 6'b100000 : 6'b000000;

endmodule
