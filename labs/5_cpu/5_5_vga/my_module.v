module my_module (
    input wire clk,
    input wire rst,
    input wire [11:0] x,
    input wire [11:0] y,
    output wire [12:0] text_symbol,
    output reg [11:0] ry
);


    reg     [7:0] text_mem[0:4799];
    initial $readmemh("text.mem8", text_mem);
    wire [11:0] row;
    assign row = y >> 3;
    reg [12:0] text_symbol_r;
      reg [7:0] character;
          reg  [10:0] row_in_ram;  //pixels row of char 


        
    assign start = (x[2:0] == 3'b100);
    assign end_of_row = (x[11:0] == 12'b0010_0111_1101);


    always_ff @ (posedge clk) begin
         begin
            if(end_of_row) begin
                    text_symbol_r<= (((y+1)>>3)<<6)+(((y+1)>>3)<<4);
                    ry<=y+1;
            end
            else  if(start) begin
                    text_symbol_r<= (row<<6)+(row<<4)+(x>>3)+1;
                    ry<=y;       
            end 
         end
    end 

    always_ff @ (posedge clk)
        if(3'(x)==3'b101) 
            character<= text_mem[text_symbol_r];    

    always_ff @ (posedge clk)
            if(3'(x)==3'b110) 
                row_in_ram <= (character<<3)+3'(ry);

    assign text_symbol = text_symbol_r;

endmodule