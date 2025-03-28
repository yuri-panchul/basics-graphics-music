module convert
# (
    parameter  w_in  = 24, // Number of bits of the input signal
               w_out = 16, // Number of bits of the output signal
               lev   = 17, // Input signal bit corresponding to most significant output
                           // bit, lower level value corresponds to higher output volume
               agc   = 1   // Automatic gain control is enabled
)
(
    input                             clk,
    input                             rst,
    input  logic signed [w_in  - 1:0] in,  // Input signal
    output logic signed [w_out - 1:0] out, // Output signal
    output logic                      led, // Output signal limit indication
    output logic        [        2:0] vol  // Volume level indicator, at 2-5 increase lev
);

    logic signed [w_in  - 1:0] ina; // Input signal after automatic gain control
    logic        [w_in  - 1:0] ing; // Average input signal level after gain adjustment
    logic        [        2:0] gk;  // Input signal attenuation coefficient
    logic        [        1:0] gka; // 1 part of coefficient by input signal shift
    logic        [        1:0] gkb; // 2 part of coefficient by input signal shift
    logic        [       24:0] cnt; // Sync counter

    assign vol = gk;

    // Input signal level and bit depth converter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= '0;
            led <= '0;
        end
        // Limiting the output signal if the input level exceeds the threshold
        else if (ina [w_in - 1 : lev] != {(w_in - lev) {ina [w_in - 1]}}) begin
            out <= {ina [w_in - 1], {w_out - 1 { ~ ina [w_in - 1]}}};
            led <= '1;              // Output signal limit indication
        end
        else begin
        // If we take less bits of the input signal than the width of the output signal,
        // we pad them with zeros at the end.
            out <= {lev < (w_out - 1) ? ina [lev : 0]   : ina [lev -: w_out],
                   {lev < (w_out - 1) ? w_out - 1 - lev : 0 {ina [w_in - 1]}}};
            led <= '0;              // Resetting the output signal limit indication
        end
    end

generate

if (agc) begin : agc_y  // Automatic gain control is enabled

    // Sync counter
    always_ff @(posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'b1;

    // Rectifier and low-pass anti-aliasing filter for input signal level estimation
    always_ff @(posedge clk or posedge rst)
        if (rst)
            ing <= '0;
        else if ( & cnt[8:0] )
            ing <= ing - (ing >>> 8) + ((ina [w_in - 1] ? - ina : ina) >>> 8);

    // Input signal level attenuation counter with hysteresis
    always_ff @(posedge clk or posedge rst)
        if (rst)
            gk <= '0;
        // When the average volume level is exceeded, counter is triggered periodically
        else if ( | ing [lev -: 4] && & cnt[20:0] && (gk < 5))
            gk <= gk + 1'b1;
        // If the volume level is less than the minimum level, the volume is restored
        else if ( ~| ing [lev -: 5] && & cnt && gk)
            gk <= gk - 1'b1;

    // Recording shift coefficients at the moment the input signal passes through zero,
    // so that there are no clicks in the output signal
    always_ff @(posedge clk or posedge rst)
        if (rst) begin
            gka <= '0;
            gkb <= '0;
        end
        else if (in [w_in - 1] != ina [w_in - 1]) begin
            gka <= {gk[2], gk[1]};
            gkb <= {gk[0], {gk[0] & (gk[1] | gk[2])}};
        end

    // Input signal shift for volume control, when gkb = 0 the second part is disabled
    // Coefficients 1, 0.75, 0.5, 0.375, 0.25, 0.125 by which input signal is multiplied
    always_ff @(posedge clk or posedge rst)
        if (rst)
            ina <= '0;
        else
            ina <= (in >>> gka) - (gkb ? (in >>> gkb) : 1'sb0);

end

else begin : agc_n  // Automatic gain control is off

    assign ina = in;

end

endgenerate

endmodule
