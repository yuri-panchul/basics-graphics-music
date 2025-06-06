module converter
# (
    parameter                  stripe = 9,  // stripe narrower > 7 wider < 7
                               level  = 16, // output level (shift)
                               smooth = 9   // smoothing output fluctuations
)
(
    input  logic               clk,
    input  logic               rst,
    input  logic signed [ 9:0][10:0] in,
    input  logic        [16:0] band_count,
    output logic        [10:0] rms_out
);

    // Initial values will be needed if you exclude reset code
    logic               [16:0] count      = '0;
    logic                      pulse_out;
    logic               [ 4:0] switch     = '0;
    logic        signed [10:0] q00, q90;
    logic        signed [16:0] i_filtered = '0;
    logic        signed [16:0] q_filtered = '0;
    logic               [16:0] abs_i, abs_q;
    logic               [16:0] sum_abs;
    logic               [16:0] ema        = '0;

    // Reference frequency * 32 of control pulses generator
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count     <= '0;
            pulse_out <= '0;
        end else if (count == band_count - 1'b1) begin
            count     <= '0;
            pulse_out <= 1'b1;
        end else begin
            count     <= count + 1'b1;
            pulse_out <= 1'b0;
        end
    end

    // Quadrature mixer * 32 steps with a 90 degree shift
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            switch <= '0;
        else if (pulse_out)
            switch <= switch + 1'b1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            q00 <= '0;
            q90 <= '0;
        end else if (pulse_out) begin
        case (switch)
    //------------------------------------q00--9-h----q90-12-h----------------
             0: begin                              //
            q00 <= '0;                             //  0
            q90 <= in[4];                          //  1
            end                                    //
             1: begin                              //
            q00 <= in[0];                          //  0.5
            q90 <= in[4];                          //  1
            end                                    //
             2: begin                              //
            q00 <= in[1];                          //  0.625
            q90 <= in[4];                          //  1
            end                                    //
             3: begin                              //
            q00 <= in[2];                          //  0.75
            q90 <= in[4];                          //  1
            end                                    //
             4: begin                              //
            q00 <= in[3];                          //  0.875
            q90 <= in[3];                          //  0.875
            end                                    //
             5: begin                              //
            q00 <= in[4];                          //  1
            q90 <= in[2];                          //  0.75
            end                                    //
             6: begin                              //
            q00 <= in[4];                          //  1
            q90 <= in[1];                          //  0.625
            end                                    //
             7: begin                              //
            q00 <= in[4];                          //  1
            q90 <= in[0];                          //  0.5
            end                                    //
    //------------------------------------q00-12-h----q90--3-h----------------
             8: begin                              //
            q00 <= in[4];                          //  1
            q90 <= '0;                             //  0
            end                                    //
             9: begin                              //
            q00 <= in[4];                          //  1
            q90 <= in[5];                          // -0.5
            end                                    //
            10: begin                              //
            q00 <= in[4];                          //  1
            q90 <= in[6];                          // -0.625
            end                                    //
            11: begin                              //
            q00 <= in[4];                          //  1
            q90 <= in[7];                          // -0.75
            end                                    //
            12: begin                              //
            q00 <= in[3];                          //  0.875
            q90 <= in[8];                          // -0.875
            end                                    //
            13: begin                              //
            q00 <= in[2];                          //  0.75
            q90 <= in[9];                          // -1
            end                                    //
            14: begin                              //
            q00 <= in[1];                          //  0.625
            q90 <= in[9];                          // -1
            end                                    //
            15: begin                              //
            q00 <= in[0];                          //  0.5
            q90 <= in[9];                          // -1
            end                                    //
    //------------------------------------q00--3-h----q90--6-h----------------
            16: begin                              //
            q00 <= '0;                             //  0
            q90 <= in[9];                          // -1
            end                                    //
            17: begin                              //
            q00 <= in[5];                          // -0.5
            q90 <= in[9];                          // -1
            end                                    //
            18: begin                              //
            q00 <= in[6];                          // -0.625
            q90 <= in[9];                          // -1
            end                                    //
            19: begin                              //
            q00 <= in[7];                          // -0.75
            q90 <= in[9];                          // -1
            end                                    //
            20: begin                              //
            q00 <= in[8];                          // -0.875
            q90 <= in[8];                          // -0.875
            end                                    //
            21: begin                              //
            q00 <= in[9];                          // -1
            q90 <= in[7];                          // -0.75
            end                                    //
            22: begin                              //
            q00 <= in[9];                          // -1
            q90 <= in[6];                          // -0.625
            end                                    //
            23: begin                              //
            q00 <= in[9];                          // -1
            q90 <= in[5];                          // -0.5
            end                                    //
    //------------------------------------q00--6-h----q90--9-h----------------
            24: begin                              //
            q00 <= in[9];                          // -1
            q90 <= '0;                             //  0
            end                                    //
            25: begin                              //
            q00 <= in[9];                          // -1
            q90 <= in[0];                          //  0.5
            end                                    //
            26: begin                              //
            q00 <= in[9];                          // -1
            q90 <= in[1];                          //  0.625
            end                                    //
            27: begin                              //
            q00 <= in[9];                          // -1
            q90 <= in[2];                          //  0.75
            end                                    //
            28: begin                              //
            q00 <= in[8];                          // -0.875
            q90 <= in[3];                          //  0.875
            end                                    //
            29: begin                              //
            q00 <= in[7];                          // -0.75
            q90 <= in[4];                          //  1
            end                                    //
            30: begin                              //
            q00 <= in[6];                          // -0.625
            q90 <= in[4];                          //  1
            end                                    //
            31: begin                              //
            q00 <= in[5];                          // -0.5
            q90 <= in[4];                          //  1
            end                                    //
    //------------------------------------q00--9-h----q90-12-h----------------
            default: begin
            q00 <= '0;
            q90 <= '0;
            end
        endcase
        end
    end

    // Similar RC low frequency filter I
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            i_filtered <= '0;
        else if (pulse_out)
            i_filtered <= i_filtered - (i_filtered >>> stripe) + q00;
    end

    // Similar RC low frequency filter Q
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            q_filtered <= '0;
        else if (pulse_out)
            q_filtered <= q_filtered - (q_filtered >>> stripe) + q90;
    end

    // Rectifier
    assign abs_i = i_filtered[16] ? -i_filtered : i_filtered;
    assign abs_q = q_filtered[16] ? -q_filtered : q_filtered;
    assign sum_abs = abs_i + abs_q;

    // Averaging
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            ema <= '0;
        else if (pulse_out)
            ema <= ema - (ema >>> smooth) + (sum_abs >>> smooth);
    end

    // Normalization of output
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            rms_out <= '0;
        else
            rms_out <= ema [level -: 11];
    end

endmodule
