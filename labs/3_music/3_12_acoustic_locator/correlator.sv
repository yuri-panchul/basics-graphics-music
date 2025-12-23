module correlator
(
    input  logic               clk,
    input  logic               rst,
    input  logic               ws,
    input  logic signed [12:0] in_1, in_2,
    input  logic               inv,
    input  logic        [ 3:0] shift,
    output logic        [12:0] rms_out
);

    logic signed   [8:0][12:0] delay;
    logic signed        [12:0] delay_2;
    logic signed        [13:0] out;
    logic               [13:0] abs;
    logic               [19:0] ema;

    always_ff @(posedge ws or posedge rst) begin
        if (rst) begin
            delay    <= '0;
            delay_2  <= '0;
            out      <= '0;
            abs      <= '0;
            ema      <= '0;
        end
        else begin
            delay[8] <= delay[7];
            delay[7] <= delay[6];
            delay[6] <= delay[5];
            delay[5] <= delay[4];
            delay[4] <= delay[3];
            delay[3] <= delay[2];
            delay[2] <= delay[1];
            delay[1] <= delay[0];
            delay[0] <= inv ? in_1 : in_2;
            delay_2  <= inv ? in_2 : in_1;
            out      <= delay_2 - delay[shift];
            abs      <= out[13] ? -out : out;
            ema      <= ema - (ema >>> 12) + (&ema[19:10] ? '0 : (abs >>> 4));
            rms_out  <= ema[19:7];
        end
    end

endmodule
