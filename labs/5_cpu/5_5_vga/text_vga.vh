`define VGA_BASE_0  16'hA000                                 /* msword of mem address        */
`define VGA_BASE_1  16'hA001                                 /* msword of mem address        */


module text_vga 
# (
    screen_width  = 640,
    screen_height = 480,

    w_red         = 4,
    w_green       = 4,
    w_blue        = 4,

    w_x           = $clog2 ( screen_width  ),
    w_y           = $clog2 ( screen_height )
)

(
  input             clk,
  input             rst,

  //YRV bus
  input  [31:0] mem_addr,
  input  [ 3:0] mem_ble,
  input  [ 1:0] mem_trans,
  input  [31:0] mem_wdata,
  input         mem_write,
  input         mem_lock,
  output        mem_ready,
  output [31:0] mem_rdata, 
  

  //HDMI bus
  input       [w_x     - 1:0] x,
  input       [w_y     - 1:0] y,
  input             hsync,
  input             vsync,
  input             display_on,
 
   output   reg [7:0] char_row,
   input clk_TMDS,
   output logic [w_red   - 1:0] red,
   output logic [w_green - 1:0] green,
   output logic [w_blue  - 1:0] blue
);
    
    wire vga_clk;
    reg       [w_x     - 1:0] rx;
    reg       [w_y     - 1:0] ry;

    reg [12:0] text_symbol; // Simbol place in ram
    reg  [12:0] text_wr_addr; // Simbol place in ram
    reg  [7:0] character_wr;// = 8'h42;

    reg  [10:0] row_in_ram;  //pixels row of char 


   
    reg      [7:0] character;// = 8'h42;
    wire [6:0] d_row;
    reg  [2:0] pixel_pos;
    reg  [2:0] row_pos;



  //Memory bus interface
  reg    [15:0] mem_addr_reg;                              /* reg'd memory address         */
  reg     [3:0] mem_ble_reg;                               /* reg'd memory byte lane en    */


  wire    [3:0] vga_wr_byte_0;                                 /* vga ram byte enables      */
  reg           vga_wr_reg_0;                                  /* mem write                    */
  reg           vga_wr;                                  /* mem write                    */


  wire    [3:0] vga_wr_byte_1;                                 /* vga ram byte enables      */
  reg           vga_wr_reg_1;                                  /* mem write                    */

  assign vga_wr_byte_0 = {4{vga_wr_reg_0}} & mem_ble_reg & {4{mem_ready}};

  
  always @ (posedge clk ) begin
    if (rst) begin
      mem_addr_reg <= 16'h0;
      mem_ble_reg  <=  4'h0;
      vga_wr_reg_0   <=  1'b0;
    end
    else if (mem_ready) begin
      mem_addr_reg <= mem_addr[15:0];
      mem_ble_reg  <= mem_ble;
      vga_wr_reg_0   <= mem_write && &mem_trans    && (mem_addr[31:16] == `VGA_BASE_0);
      end
  end

  always @ (posedge clk) begin
      if(|vga_wr_reg_0) begin
            vga_wr <='1;
            if(vga_wr_byte_0[0]) begin
                character_wr <= mem_wdata[7:0];
                text_wr_addr <= {mem_addr_reg[12:2],2'b00};
            end
            else if(vga_wr_byte_0[1]) begin
                character_wr <= mem_wdata[15:8];
                text_wr_addr <= {mem_addr_reg[12:2],2'b01};
            end
            else if(vga_wr_byte_0[2]) begin
                character_wr <= mem_wdata[23:16];
                text_wr_addr <= {mem_addr_reg[12:2],2'b10};
            end
            else if(vga_wr_byte_0[3]) begin
                character_wr <= mem_wdata[31:24];
                text_wr_addr <= {mem_addr_reg[12:2],2'b11};
            end

          end
        else begin
            vga_wr<='0;
            character_wr <= 'z;
            text_wr_addr <= 'z;
          end
  end

    //------------------------------------------------------------------------

       assign led        = '0;
       assign abcdefgh   = '0;
       assign digit      = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------
    //256x192, for 32x24 

    assign vga_clk =clk_TMDS;
    wire [12:0] row;
    assign row = y >> 3;
    assign col = x >> 3;
    wire start;
    assign start = (x[2:0] == 3'b100);
    wire end_of_row;
    assign end_of_row = (x[9:0] == 10'b10_0111_1101);


    always_ff @ (posedge vga_clk ) begin  
         begin
            if(start) begin
                    text_symbol <= (row<<6)+(row<<4)+(x>>3)+1;
                    ry<=y;       
            end 
         end
    end
  
    wire [7:0] dout;
        
    Gowin_SDPB vga_mem(
        .dout(dout), //output [7:0] dout
        .clka(clk), //input clka
        .cea(vga_wr), //input cea
        .reseta(rst), //input reseta
        .clkb(vga_clk), //input clkb
        .ceb(~vga_wr), //input ceb
        .resetb(rst), //input resetb
        .oce(1'b1), //input oce
        .ada(text_wr_addr), //input [12:0] ada
        .din(character_wr), //input [7:0] din
        .adb(text_symbol) //input [12:0] adb
    );

    wire get_ch;
    assign get_ch = (x[2:0] == 3'b101);
    always_ff @ (posedge vga_clk)
        if(get_ch) 
            character<= dout;    

    wire get_row;
    assign get_row = (x[2:0] == 3'b110);
    always_ff @ (posedge vga_clk)
            if(get_row) 
                row_in_ram <= (character<<3)+3'(ry);

    wire [7:0] char_dout;

    wire get_out;
    assign get_out = (x[2:0] == 3'b111);
    always_ff @(posedge vga_clk)
      if(get_out) 
        char_row <= char_dout;
    
    Gowin_pROM font(
        .dout(char_dout), //output [7:0] dout
        .clk(vga_clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(rst), //input reset
        .ad(row_in_ram) //input [10:0] ad
    );




     always_ff @ (posedge vga_clk)  begin    
        if (( char_row[3'b111-3'(x)] )) begin
              red   <= 32'h0000;
              blue  <= 32'h0000;
              green <= 32'h00ff;
         end
         else 
          begin
              red   <= 32'h0000;
              blue  <= 32'h0000;
              green <= 32'h0000;
         end
     end

endmodule