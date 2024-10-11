module hub75e_led_matrix
# (
    parameter clk_mhz       = 50,

              screen_width  = 64,
              screen_height = 64,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input              clk,
    input              rst,

    output logic       ck,
    output             oe,
    output             st,

    output             a,
    output             b,
    output             e,
    output             c,
    output             d,

    output [w_x - 1:0] x,
    output [w_y - 1:0] y
);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ck <= 1'b0;
        else
            ck <= ~ ck;

    // TODO

    assign oe = 1'b1;
    assign st = 1'b1;

    assign a  = 1'b1;
    assign b  = 1'b1;
    assign e  = 1'b1;
    assign c  = 1'b1;
    assign d  = 1'b1;

    assign x  = 1'b1;
    assign y  = 1'b1;

endmodule
