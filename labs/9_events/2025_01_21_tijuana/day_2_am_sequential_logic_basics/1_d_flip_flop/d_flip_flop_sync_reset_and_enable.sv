module d_flip_flop_sync_reset_and_enable
(
    input  clock,
    input  reset,
    input  enable,
    input  d,
    output logic q
);

    always_ff @ (posedge clock)
        if (reset)
            q <= 1'b0;
        else if (enable)
            q <= d;

endmodule
