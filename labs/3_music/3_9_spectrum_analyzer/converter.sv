module converter 
# (
    parameter  stripe = 7,  // stripe narrower > 7, stripe wider < 7
               level  = 15, // output level (shift)
               smooth = 9   // smoothing output fluctuations
)
(
    input  logic  clk,
    input  logic  rst,
    input  logic signed [ 8:0] mic,
    input  logic        [16:0] band_count,
    output logic        [10:0] rms_out
);

    // The initial values will be needed if you exclude reset
    logic               [16:0] count      = '0;
    logic                      pulse_out;
    logic               [ 4:0] switch     = '0;
    logic  signed       [ 8:0] in, q00, q90;
    logic  signed       [17:0] i_filtered = '0;
    logic  signed       [17:0] q_filtered = '0;
    logic               [17:0] abs_i, abs_q;
    logic               [18:0] sum_abs;
    logic               [21:0] ema        = '0;

    // Reference frequency * 32 control pulses generator
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

    // Quadrature mixer
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
            in  <= '0;
        end else begin
            in  <= mic;
    //------------------------------------------------------------------------
        case (switch)
             0: begin 
            q00 <= '0;
            q90 <=  in;
            end
             1: begin 
            q00 <= (in >>> 1) - (in >>> 6);
            q90 <=  in - (in >>> 7);
            end
             2: begin 
            q00 <= (in >>> 1) + (in >>> 3) + (in >>> 5);
            q90 <=  in - (in >>> 5);
            end
             3: begin 
            q00 <=  in - (in >>> 2) + (in >>> 5);
            q90 <=  in - (in >>> 4) - (in >>> 7);
            end
             4: begin 
            q00 <=  in - (in >>> 3) - (in >>> 7);
            q90 <=  in - (in >>> 3) - (in >>> 7);
            end
             5: begin 
            q00 <=  in - (in >>> 4) - (in >>> 7);
            q90 <=  in - (in >>> 2) + (in >>> 5);
            end
             6: begin 
            q00 <=  in - (in >>> 5);
            q90 <= (in >>> 1) + (in >>> 3) + (in >>> 5);
            end
             7: begin 
            q00 <=  in - (in >>> 7);
            q90 <= (in >>> 1) - (in >>> 6);
            end
             8: begin 
            q00 <=  in;
            q90 <= '0;
            end
    //------------------------------------------------------------------------
             9: begin 
            q00 <=  in - (in >>> 7);
            q90 <= - ((in >>> 1) - (in >>> 6));
            end
            10: begin 
            q00 <=  in - (in >>> 5);
            q90 <= - ((in >>> 1) + (in >>> 3) + (in >>> 5));
            end
            11: begin 
            q00 <=  in - (in >>> 4) - (in >>> 7);
            q90 <= - (in - (in >>> 2) + (in >>> 5));
            end
            12: begin 
            q00 <=  in - (in >>> 3) - (in >>> 7);
            q90 <= - (in - (in >>> 3) - (in >>> 7));
            end
            13: begin 
            q00 <=  in - (in >>> 2) + (in >>> 5);
            q90 <= - (in - (in >>> 4) - (in >>> 7));
            end
            14: begin 
            q00 <= (in >>> 1) + (in >>> 3) + (in >>> 5);
            q90 <= - (in - (in >>> 5));
            end
            15: begin 
            q00 <= (in >>> 1) - (in >>> 6);
            q90 <= - (in - (in >>> 7));
            end
            16: begin 
            q00 <= '0;
            q90 <= - in;
            end
    //------------------------------------------------------------------------
            17: begin 
            q00 <= - ((in >>> 1) - (in >>> 6));
            q90 <= - (in - (in >>> 7));
            end
            18: begin 
            q00 <= - ((in >>> 1) + (in >>> 3) + (in >>> 5));
            q90 <= - (in - (in >>> 5));
            end
            19: begin 
            q00 <= - (in - (in >>> 2) + (in >>> 5));
            q90 <= - (in - (in >>> 4) - (in >>> 7));
            end
            20: begin 
            q00 <= - (in - (in >>> 3) - (in >>> 7));
            q90 <= - (in - (in >>> 3) - (in >>> 7));
            end
            21: begin 
            q00 <= - (in - (in >>> 4) - (in >>> 7));
            q90 <= - (in - (in >>> 2) + (in >>> 5));
            end
            22: begin 
            q00 <= - (in - (in >>> 5));
            q90 <= - ((in >>> 1) + (in >>> 3) + (in >>> 5));
            end
            23: begin 
            q00 <= - (in - (in >>> 7));
            q90 <= - ((in >>> 1) - (in >>> 6));
            end
            24: begin 
            q00 <= - in;
            q90 <= '0;
            end
    //------------------------------------------------------------------------
            25: begin 
            q00 <= - (in - (in >>> 7));
            q90 <= (in >>> 1) - (in >>> 6);
            end
            26: begin 
            q00 <= - (in - (in >>> 5));
            q90 <= (in >>> 1) + (in >>> 3) + (in >>> 5);
            end
            27: begin 
            q00 <= - (in - (in >>> 4) - (in >>> 7));
            q90 <= in - (in >>> 2) + (in >>> 5);
            end
            28: begin 
            q00 <= - (in - (in >>> 3) - (in >>> 7));
            q90 <= in - (in >>> 3) - (in >>> 7);
            end
            29: begin 
            q00 <= - (in - (in >>> 2) + (in >>> 5));
            q90 <= in - (in >>> 4) - (in >>> 7);
            end
            30: begin 
            q00 <= - ((in >>> 1) + (in >>> 3) + (in >>> 5));
            q90 <= in - (in >>> 5);
            end
            31: begin 
            q00 <= - ((in >>> 1) - (in >>> 6));
            q90 <= in - (in >>> 7);
            end
            default: begin 
            q00 <= '0;
            q90 <= '0;
            end
        endcase
    //------------------------------------------------------------------------
        end
        end

    // RC filter I
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            i_filtered <= '0;
        else if (i_filtered [16] != i_filtered [17])
            i_filtered <= {i_filtered [17], i_filtered [17], {16 {~i_filtered [17]}}};
        else if (pulse_out)
            i_filtered <= i_filtered - (i_filtered >>> stripe) + q00;
    end

    // RC filter Q
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            q_filtered <= '0;
        else if (q_filtered [16] != q_filtered [17])
            q_filtered <= {q_filtered [17], q_filtered [17], {16 {~q_filtered [17]}}};
        else if (pulse_out)
            q_filtered <= q_filtered - (q_filtered >>> stripe) + q90;
    end

    // Rectifier
    assign abs_i = i_filtered [17] ? -i_filtered : i_filtered;
    assign abs_q = q_filtered [17] ? -q_filtered : q_filtered;
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
