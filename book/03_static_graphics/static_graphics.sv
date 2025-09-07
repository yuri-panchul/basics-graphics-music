module static_graphics
(
    input  [9:0] x,
    input  [9:0] y,

    output logic red,
    output logic green,
    output logic blue
);

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        if (x > 100 & x < 300 & y > 50 & y < 100)
            red = 1;

        if (x > 150 & x < 350 & y > 70 & y < 120)
            green = 1;

        if (x > 200 & x < 400 & y > 90 & y < 140)
            blue = 1;

        if (x * x + y * y < 3000)
            red = 1;
    end

endmodule
