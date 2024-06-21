module testbench();

    logic a, b;

    assign a = b;

//    always_comb
//        a = b;

    initial
    begin
        b = 0;
        #1;
        b = 1;
        $display (a);
    end

endmodule

/*

module m;

wire p;
reg q;

assign p = q;

initial
begin
q = 1;
# 1
q = 0;
$display (p);
end

endmodule
*/
