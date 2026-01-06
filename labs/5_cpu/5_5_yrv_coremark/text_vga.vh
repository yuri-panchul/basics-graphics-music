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
  input             resetb,

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

  output logic [w_red   - 1:0] red,
  output logic [w_green - 1:0] green,
  output logic [w_blue  - 1:0] blue


);



 //------------------------------------------------------------------------


    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (  y[2:0]== 3'b110 && x[2:0] == 3'b110 )
        begin
               green = 32'hffff;
        end
    end
endmodule