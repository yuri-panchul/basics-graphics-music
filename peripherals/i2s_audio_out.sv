
// For PCM5102A. If the board has pins FLT, DMP, FMT and XMT,
// then pin XMT should be connected to 3.3v,
// rest of them (optionally) to the ground. Pin FMT to the ground (I2S mode)!
// For Digilent Pmod AMP3 jumper JP3 is loaded (I2S mode)!

module i2s_audio_out
# (
    parameter clk_mhz             = 50,
              in_res              = 16,   // Sound samples resolution, see tone_table.svh
              align_right         = 1'b0, // For I2S = 0. For PT8211 DAC (Least Significant Bit Justified) = 1.
              offset_by_one_cycle = 1'b1  // For I2S = 1. For Left Justified Audio Data Format = 0.
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

// Standard frequencies are 12.288 MHz, 3.072 MHz and 48 KHz. 
// We are using frequencies somewhat higher but with the same relationship 256:64:1
    localparam MCLK_BIT   =  $clog2 ( clk_mhz - 4 ) - 4; // clk_mhz range (12-19) (20-35) (36-67) (68-131)
    localparam BCLK_BIT   =  MCLK_BIT + 2;
    localparam LRCLK_BIT  =  BCLK_BIT + 6;
    localparam CLK_DIV_DATA_OFFSET = { BCLK_BIT { 1'b1 } };

    logic  [LRCLK_BIT - 1:0] clk_div;
    logic  [           31:0] shift;

    assign mclk  = MCLK_BIT ? clk_div [MCLK_BIT - 1] : clk;
    assign bclk  = clk_div [BCLK_BIT  - 1];
    assign lrclk = clk_div [LRCLK_BIT - 1];

    assign sdata = shift   [           31];

    always_ff @ ( posedge clk or posedge reset )
        if ( reset )
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    always_ff @ ( posedge clk or posedge reset )
        if ( reset )
            shift <= '0;
        else
        begin
            if ( ! offset_by_one_cycle )
            begin
                if ( ! align_right )
                begin
                    if      ( clk_div [LRCLK_BIT - 2:0] == '1  )            // Data front position (MSB) regarding LRCLK or WS position
                              shift   [31    -: in_res] <= 32' ( data_in ); // Put the data starting with the highest bytes, on the left side
                    else if ( clk_div [BCLK_BIT  - 1:0] == '1  )
                              shift   <= shift << 1'b1;                     // Serial shift on the left side
                end
                else
                begin
                    if      ( clk_div [LRCLK_BIT - 2:0] == { { LRCLK_BIT - 2 { 1'b0 } }, 1'b1 } ) 
                              shift   [0     +: in_res] <= 32' ( data_in ); // Put the data on the right side of the LRCLK or WS, align_right
                    else if ( clk_div [BCLK_BIT  - 1:0] == '1  )
                              shift   <= shift << 1'b1;
                end
            end
            else
            begin
                if      ( clk_div [LRCLK_BIT - 2:0] == CLK_DIV_DATA_OFFSET ) // Data front position (MSB) regarding LRCLK position + 1 bit
                            shift [31    -: in_res] <= 32' ( data_in );      // Put the data starting with the highest bytes, on the left side
                else if ( clk_div [BCLK_BIT  - 1:0] == CLK_DIV_DATA_OFFSET ) // Data end position (LSB) regarding LRCLK position + 1 + in_res
                            shift <= shift << 1'b1;                          // Serial shift on the left side
            end
        end

endmodule
