// This module assumes the configuration with Tang Nano 9K board,
// LCD 480x272 and TM1638 interface module.

module hackathon_top
(
    input  logic       clock,
    input  logic       reset,

    output logic [9:0] strobe_hz,
    input  logic       strobe,

    input        [7:0] key,
    output logic [7:0] led,
    output logic [7:0] number,

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue
);

    logic [7:0] counter;

    always_ff @ (posedge clock)
        if (reset)
            counter <= 0;
        else if (strobe)
            counter <= counter + 1 + key [0] - key [1];

    assign led    = counter;
    assign number = counter;

    always_comb
    begin
        red = 0; green = 0; blue = 0;

        if (  x > 100 + c * 2 & x < 150 + c * 2
            & y > 100 + c     & y < 200 + c )
        begin
            red   = 30;
            blue  = key [1] ? x : 0;
        end

        if ((x - c) ** 2 + y ** 2 < 100 ** 2)
            blue = 30;

        if (x * y > 100 ** 2)
            green = 10;
    end

endmodule
