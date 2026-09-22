`include "config.svh"

module tb;

    testbench i_tb ();

    `ifdef __ICARUS__
    initial $dumpvars;
    `endif

endmodule
