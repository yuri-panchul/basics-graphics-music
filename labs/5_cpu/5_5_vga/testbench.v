`timescale 1 ns / 1 ns

`define CLK_FREQUENCY (50 * 1000 * 1000)

module testbench;

    logic clk;
      reg rst;
    logic [11:0] x;
    logic [11:0] y;
    wire [12:0] text_symbol;
    reg [12:0] text_symbol_r;
    
    wire [11:0] ry;
  
  initial
  begin
    clk = '0;
    forever # 10 clk = ~ clk;
  end


    initial
  begin
    `ifdef __ICARUS__
      $dumpvars;
    `endif
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;

    x=0;
    y=0;
    for (int i = 0; i < 3000; i ++)
    begin

          @ (posedge clk);
          
            if (x == 639) begin
                x = 0;
                if (y == 479) begin
                    y = 0;
                    x=0;
                end else begin
                    y = y + 1;
                end
            end else begin
                x = x + 1;
            end
    end


    $display("\n");
    `ifdef MODEL_TECH  // Mentor ModelSim and Questa
      $stop;
    `else
      $finish;
    `endif
  end

    my_module uut (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .text_symbol(text_symbol),
        .ry(ry)
    );

            always @(clk) begin
            text_symbol_r<=text_symbol;
            end
  
    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0,testbench);
    end
endmodule