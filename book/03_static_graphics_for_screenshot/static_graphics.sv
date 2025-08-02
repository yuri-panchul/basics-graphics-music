module static_graphics
(
    input  [9:0] x, y,

    output logic red,
    output logic green,
    output logic blue
);
    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        if (  x > 100 & x < 300
            & y > 50  & y < 100)
        begin
            red = 1;
        end
    end

endmodule
