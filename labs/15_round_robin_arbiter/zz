   `define IMPLEMENTATION_1
// `define IMPLEMENTATION_2
// `define IMPLEMENTATION_3

module top
(
    input        clk,
    input        rst_n,
    input  [2:0] key,
    output [7:0] led,
    output       vcc_for_keys
);

    assign vcc_for_keys = '1;

    wire rst = ~ rst_n;

    //------------------------------------------------------------------------

    wire enable;
    logic toggle_by_enable;

    always_ff @ (posedge clk)
        if (rst)
            toggle_by_enable <= 1'b0;
        else if (enable)
            toggle_by_enable <= ~ toggle_by_enable;

    //------------------------------------------------------------------------

    wire [7:0] req = { 5'b0, ~ key };

    wire [7:0] gnt1, gnt2;
    assign led = ~ { toggle_by_enable, 1'b0, gnt1 [2:0], gnt2 [2:0] };

    //------------------------------------------------------------------------

    `ifdef IMPLEMENTATION_1

    strobe_gen # (.width (24))
    enable_src
    (
        .clk    ( clk    ),
        .rst    ( rst    ),
        .strobe ( enable )
    );

       arbiter_1_dumb_big_blob
    // arbiter_2_rotate_priority_rotate_verbose
    // arbiter_3_rotate_priority_case_rotate
    // arbiter_4_rotate_priority_3_assigns_rotate
    // arbiter_5_rotate_priority_rotate_brief
    arb1
    (
        .clk ( clk    ),
        .rst ( rst    ),
        .ena ( enable ),
        .req ( req    ),
        .gnt ( gnt1   )
    );

    // arbiter_1_dumb_big_blob
       arbiter_2_rotate_priority_rotate_verbose
    // arbiter_3_rotate_priority_case_rotate
    // arbiter_4_rotate_priority_3_assigns_rotate
    // arbiter_5_rotate_priority_rotate_brief
    arb2
    (
        .clk ( clk    ),
        .rst ( rst    ),
        .ena ( enable ),
        .req ( req    ),
        .gnt ( gnt2   )
    );

    `endif

    //------------------------------------------------------------------------

    `ifdef IMPLEMENTATION_2

    // New shorter System Verilog syntax

    strobe_gen # (.width (24)) enable_src (.strobe (enable), .*);

    arbiter_3_rotate_priority_case_rotate arb1
        (.ena (enable), .gnt (gnt1), .*);

    arbiter_4_rotate_priority_3_assigns_rotate arb2
        (.ena (enable), .gnt (gnt2), .*);

    `endif

    //------------------------------------------------------------------------

    `ifdef IMPLEMENTATION_3

    // Passing signals by position - not recommended.
    // Can lead to difficult to debug bugs
    // in industrial code with many signals.

    strobe_gen # (24) enable_src (clk, rst, enable);

    arbiter_1_dumb_big_blob
    arb1 (clk, rst, enable, req, gnt1);

    arbiter_5_rotate_priority_rotate_brief
    arb2 (clk, rst, enable, req, gnt2);

    `endif

endmodule
