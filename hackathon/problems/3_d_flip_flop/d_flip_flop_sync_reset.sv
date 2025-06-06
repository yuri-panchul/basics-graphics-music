module d_flip_flop_sync_reset
(
    input  clock,
    input  reset,
    input  d,
    output logic q
);

    always_ff @ (posedge clock)
        if (reset)
            q <= 1'b0;
        else
            q <= d;

endmodule
