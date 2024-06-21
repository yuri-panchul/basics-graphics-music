`include "config.svh"

module no_starvation_priority_arbiter_from_2_fifos_wrapped_in_valid_ready
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,

    input                a_valid,
    output               a_ready,
    input  [width - 1:0] a_data,

    input                b_valid,
    output               b_ready,
    input  [width - 1:0] b_data,

    output               out_valid,
    input                out_ready,
    output [width - 1:0] out_data
);

    //------------------------------------------------------------------------

    wire               a_down_valid;
    wire               a_down_ready;
    wire [width - 1:0] a_down_data;

    //------------------------------------------------------------------------

    ff_fifo_wrapped_in_valid_ready
    # (.width (width), .depth (depth))
    fifo_a
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( a_valid      ),
        .up_ready    ( a_ready      ),
        .up_data     ( a_data       ),

        .down_valid  ( a_down_valid ),
        .down_ready  ( a_down_ready ),
        .down_data   ( a_down_data  )
    );

    //------------------------------------------------------------------------

    wire               b_down_valid;
    wire               b_down_ready;
    wire [width - 1:0] b_down_data;

    //------------------------------------------------------------------------

    ff_fifo_wrapped_in_valid_ready
    # (.width (width), .depth (depth))
    fifo_b
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( b_valid      ),
        .up_ready    ( b_ready      ),
        .up_data     ( b_data       ),

        .down_valid  ( b_down_valid ),
        .down_ready  ( b_down_ready ),
        .down_data   ( b_down_data  )
    );

    //------------------------------------------------------------------------

    wire a_grant, b_grant;

    no_starvation_priority_arbiter_2_requests arb
    (
        .clk      ( clk ),
        .rst      ( rst ),
        .requests ( { a_down_valid , b_down_valid } ),
        .grants   ( { a_grant      , b_grant      } )
    );

    //------------------------------------------------------------------------

    assign out_valid    = a_down_valid | b_down_valid;

    assign a_down_ready = out_ready & a_grant;
    assign b_down_ready = out_ready & b_grant;

    assign out_data     = a_down_valid & a_grant ? a_down_data : b_down_data;

endmodule
