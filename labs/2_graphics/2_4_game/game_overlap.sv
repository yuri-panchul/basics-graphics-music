`include "game_config.svh"

module game_overlap
#(
    parameter screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
//----------------------------------------------------------------------------
(
    input                       clk,
    input                       rst,

    input      [w_x      - 1:0] left_1,
    input      [w_x      - 1:0] right_1,
    input      [w_y      - 1:0] top_1,
    input      [w_y      - 1:0] bottom_1,

    input      [w_x      - 1:0] left_2,
    input      [w_x      - 1:0] right_2,
    input      [w_y      - 1:0] top_2,
    input      [w_y      - 1:0] bottom_2,

    output logic                  overlap
);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            overlap <= 1'b0;
        else
            overlap <= ! (    right_1  < left_2
                           || right_2  < left_1
                           || bottom_1 < top_2
                           || bottom_2 < top_1  );

endmodule
