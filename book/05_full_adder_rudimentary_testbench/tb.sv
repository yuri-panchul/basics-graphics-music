module tb;

    full_adder_testbench i_full_adder_testbench ();

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif
    end
                                    
endmodule
