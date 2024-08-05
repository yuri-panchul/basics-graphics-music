// A modification of an arbiter from
// Matt Weber. Arbiters: Design Ideas and Coding Styles. SNUG Boston 2001.

module arbiter_2_rotate_priority_rotate_verbose
(
    input              clk,
    input              rst,
    input              ena,
    input        [7:0] req,
    output logic [7:0] gnt
);

    logic [2:0] ptr;

    logic [7:0] shift_req;
    logic [7:0] shift_gnt;

    logic [7:0] d_gnt;

    always_comb
        case (ptr)
        3'd0: shift_req =              req [7:0]  ;
        3'd1: shift_req = { req [0:0], req [7:1] };
        3'd2: shift_req = { req [1:0], req [7:2] };
        3'd3: shift_req = { req [2:0], req [7:3] };
        3'd4: shift_req = { req [3:0], req [7:4] };
        3'd5: shift_req = { req [4:0], req [7:5] };
        3'd6: shift_req = { req [5:0], req [7:6] };
        3'd7: shift_req = { req [6:0], req [7:7] };
        endcase

    // Priority arbiter using if

    always_comb
    begin
        shift_gnt = 8'b0;

             if (shift_req [0]) shift_gnt [0] = 1;
        else if (shift_req [1]) shift_gnt [1] = 1;
        else if (shift_req [2]) shift_gnt [2] = 1;
        else if (shift_req [3]) shift_gnt [3] = 1;
        else if (shift_req [4]) shift_gnt [4] = 1;
        else if (shift_req [5]) shift_gnt [5] = 1;
        else if (shift_req [6]) shift_gnt [6] = 1;
        else if (shift_req [7]) shift_gnt [7] = 1;
    end

    always_comb
        case (ptr)
        3'd0: d_gnt =   shift_gnt [7:0]                   ;
        3'd1: d_gnt = { shift_gnt [6:0], shift_gnt [7:7] };
        3'd2: d_gnt = { shift_gnt [5:0], shift_gnt [7:6] };
        3'd3: d_gnt = { shift_gnt [4:0], shift_gnt [7:5] };
        3'd4: d_gnt = { shift_gnt [3:0], shift_gnt [7:4] };
        3'd5: d_gnt = { shift_gnt [2:0], shift_gnt [7:3] };
        3'd6: d_gnt = { shift_gnt [1:0], shift_gnt [7:2] };
        3'd7: d_gnt = { shift_gnt [0:0], shift_gnt [7:1] };
        endcase

    always_ff @ (posedge clk)
        if (rst)
            gnt <= 8'b0;
        else if (ena)
            gnt <= d_gnt;  // Should we & ~ gnt ?

    always_ff @ (posedge clk)
        if (rst)
            ptr <= 3'b0;
        else if (ena)
            case (1'b1)  // synopsys parallel_case
            d_gnt [0]: ptr <= 3'd1;
            d_gnt [1]: ptr <= 3'd2;
            d_gnt [2]: ptr <= 3'd3;
            d_gnt [3]: ptr <= 3'd4;
            d_gnt [4]: ptr <= 3'd5;
            d_gnt [5]: ptr <= 3'd6;
            d_gnt [6]: ptr <= 3'd7;
            d_gnt [7]: ptr <= 3'd0;
            endcase

endmodule
