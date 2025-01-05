// For PCM5102A pin XSMT should be connected to 3.3v,
// pins FLT, DEMP, FMT to GND.
//
// For Digilent Pmod AMP3 jumper JP3 is loaded, I2S mode.

module i2s_audio_out
# (
    parameter clk_mhz             = 50,
              in_res              = 16,  // Sound sample resolution

              // For the standard I2S, align_right = 0,
              // i.e. value is aligned to the left relative to LRCLK signal,
              // MSB - Most Significant Bit Justified.

              // For PT8211 DAC, align_right = 1,
              // i.e. value is aligned to the right relative to LRCLK signal,
              // LSB - Least Significant Bit Justified.

              align_right         = 0,

              // For the standard I2S, offset_by_one_cycle = 1,
              // i.e. value transmission starts with an offset of 1 clock cycle
              // relative to LRCLK signal

              // For PT8211 DAC, offset_by_one_cycle = 0,
              // i.e. value transmission is aligned with LRCLK signal change.

              offset_by_one_cycle = 1
)
(
    input                 clk,
    input                 reset,
    input  [in_res - 1:0] data_in,
    output                mclk,
    output                bclk,
    output                lrclk,  // LRCLK - 32-bit L, 32-bit R
    output                sdata
);

    // Number of bits in one transmission during half a period of LRCLK
 
    localparam W_OUT_VALUE = 32;

    // Standard frequencies are 12.288 MHz, 3.072 MHz and 48 KHz. 
    // We are using frequencies somewhat higher
    // but with the same relationship 256:64:1.

    // We are grouping together clk_mhz ranges of
    // (12-19), (20-35), (36-67), (68-131).

    localparam MCLK_BIT  =  $clog2 (clk_mhz - 4) - 4,
               BCLK_BIT  =  MCLK_BIT + 2,
               LRCLK_BIT =  BCLK_BIT + 6;

    logic  [LRCLK_BIT   - 1:0] clk_div;
    logic  [W_OUT_VALUE - 1:0] shift;
    logic  [W_OUT_VALUE - 1:0] data_aligned;

    generate

        if (MCLK_BIT)
        begin : gen_MCLK_BIT
            assign mclk = clk_div [MCLK_BIT - 1];
        end
        else
        begin : gen_not_MCLK_BIT
            assign mclk = clk;
        end

    endgenerate

    assign bclk  = clk_div [BCLK_BIT    - 1];
    assign lrclk = clk_div [LRCLK_BIT   - 1];
    assign sdata = shift   [W_OUT_VALUE - 1];

    // Put data right-aligned relative to LRCLK (sometimes called WS)
    // or align data to the left, with the most significant bit, MSB.

    assign data_aligned
        = align_right ?
              W_OUT_VALUE' (data_in)
            : { data_in, { W_OUT_VALUE - in_res { 1'b0 } } };

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'd1;

    always_ff @ (posedge clk or posedge reset)
    begin
        if (reset)
        begin
            shift <= '0;
        end
        else
        begin
            if ( clk_div [LRCLK_BIT - 2:0]
                 ==
                 { { LRCLK_BIT - BCLK_BIT - 1
                         { ! offset_by_one_cycle } },

                   { BCLK_BIT { 1'b1 } } } )
            begin
                shift <= data_aligned;
            end
            else if (clk_div [BCLK_BIT - 1:0] == '1)
            begin
                // Shift to generate serial data
                shift <= shift << 1;
            end
        end
    end

endmodule
