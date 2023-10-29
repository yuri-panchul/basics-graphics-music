`include "config.svh"

module tb;


    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;

    logic [7:0] x1;
    logic [7:0] x2;
    logic [7:0] x3;

    logic [18:0] y1;
    logic [18:0] y2;

    //------------------------------------------------------------------------

    top uut
    (
    .clk (clk),
    .rst (rst),

    .x1 (x1),
    .x2 (x2),
    .x3 (x3),

    .y1 (y1),
    .y2 (y2)
    );

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif
        x1 = '0;
        x2 = '0;
        x3 = '0;

        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;

        repeat (32)
        begin
             # 10
             x1  <= $urandom ();
             # 10
             x2  <= $urandom ();
             # 10
             x3  <= $urandom ();
        end

        $finish;
    end

endmodule
