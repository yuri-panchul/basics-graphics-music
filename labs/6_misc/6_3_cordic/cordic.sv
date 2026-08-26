`include "config.svh"

module cordic (
    input   clk,
    input   rst,

    input logic  start,
    input logic  [15:0] angle,

    output logic calc,    // Is calculating
    output logic finish,  // Finished calculating

    output logic signed [15:0] cos_out,
    output logic signed [15:0] sin_out
);

    logic signed [17:0] x_val;  // Store current X coordinate
    logic signed [17:0] y_val;  // Store current Y coordinate
    logic signed [16:0] z_val;  // Store remaining Angle

    logic [3:0] iterations; 



function automatic logic signed [16:0] atan_lut(
    input logic [3:0] i
);

    begin 
        case(i)
            4'd0:  atan_lut = 17'sd8192;    // 45
            4'd1:  atan_lut = 17'sd4836;    // 26.565051
            4'd2:  atan_lut = 17'sd2555;    // 14.036243
            4'd3:  atan_lut = 17'sd1297;    // 7.125016
            4'd4:  atan_lut = 17'sd651;     // 3.576334
            4'd5:  atan_lut = 17'sd326;     // 1.789911
            4'd6:  atan_lut = 17'sd163;     // 0.895174
            4'd7:  atan_lut = 17'sd81;      // 0.447614
            4'd8:  atan_lut = 17'sd41;      // 0.223811
            4'd9:  atan_lut = 17'sd20;      // 0.111906
            4'd10: atan_lut = 17'sd10;      // 0.055953
            4'd11: atan_lut = 17'sd5;       // 0.027976
            4'd12: atan_lut = 17'sd3;       // 0.013988
            4'd13: atan_lut = 17'sd1;       // 0.006994

            default:
                atan_lut = '0;
        endcase         
    end
endfunction


    logic signed [17:0] x_next_val;  
    logic signed [17:0] y_next_val;  
    logic signed [16:0] z_next_val;

    /*
    X = x - y*2^(-i)
    Y = y + x*2^(-i)
    Z = z - atan(2^(-i))
    */
always_comb
begin
    if(z_val >= 0) 
    begin   
        x_next_val = x_val - (y_val >>> iterations); 
        y_next_val = y_val + (x_val >>> iterations);
        z_next_val = z_val - atan_lut(iterations);
    end
    else 
    begin
        x_next_val = x_val + (y_val >>> iterations);
        y_next_val = y_val - (x_val >>> iterations);
        z_next_val = z_val + atan_lut(iterations);        
    end
end


always_ff @(posedge clk or posedge rst )
begin
    if(rst)
    begin 
        x_val       <= 18'sd0;
        y_val       <= 18'sd0;
        z_val       <= 17'sd0;
        iterations  <= 4'd0;
        calc        <= 1'b0;
        finish      <= 1'b0;
        cos_out     <= 16'sd0;
        sin_out     <= 16'sd0;
    end
    else
    begin   
        finish <= 1'b0;
        if(start & ~calc)
        begin
            iterations <= 4'd0;
            calc <= 1'b1;
            x_val <= 18'sd19898; // x = 1/K ~= 0.607252935
            y_val <= 18'sd0;      
            z_val <= {1'b0, angle}; // Put one 0 bit in front of the 16 bits of angle, becasue angle is 16 bit and z_val 17
        end
        else if (calc) 
        begin
            x_val <= x_next_val;
            y_val <= y_next_val;
            z_val <= z_next_val;
            if(iterations >= 4'd13) 
            begin 
                calc <= 1'b0;
                finish <= 1'b1;
                cos_out <= x_next_val[15:0];
                sin_out <= y_next_val[15:0];
            end
        else
        begin
         iterations <= iterations + 1'b1;
        end
        end
    end
end

endmodule
