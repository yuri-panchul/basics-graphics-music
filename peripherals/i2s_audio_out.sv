// For PCM5102A pin XSMT should be connected to 3.3v, pins FLT, DEMP, FMT to GND
// For Digilent Pmod AMP3 jumper JP3 is loaded, I2S mode

module i2s_audio_out
# (
    parameter clk_mhz             = 50,
              in_res              = 16,   // Sound samples resolution
              align_right         = 1'b0, // For I2S = 0 For PT8211 DAC (Least Significant Bit Justified) = 1
              offset_by_one_cycle = 1'b1  // For I2S = 1 For Left Justified Audio Data Format = 0
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
    localparam MCLK_BIT   =  $clog2 ( clk_mhz - 4 ) - 4;  // clk_mhz range (12-19) (20-35) (36-67) (68-131)
    localparam BCLK_BIT   =  MCLK_BIT + 2;
    localparam LRCLK_BIT  =  BCLK_BIT + 6;

    logic  [LRCLK_BIT - 1:0] clk_div;
    logic  [           31:0] shift;
    logic  [           31:0] data_aligned;

    assign mclk  = MCLK_BIT ? clk_div [MCLK_BIT - 1] : clk;
    assign bclk  = clk_div [BCLK_BIT  - 1];
    assign lrclk = clk_div [LRCLK_BIT - 1];

    assign sdata = shift   [           31];

// Put the data on the right side of LRCLK or WS or put the data starting with the highest bytes on the left side
    assign data_aligned = align_right ? 32' ( data_in ) : {data_in, {32 - in_res {1'b0}}};

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
            if      ( clk_div [LRCLK_BIT - 2:0] == { { 5 { ~offset_by_one_cycle } }, { BCLK_BIT { 1'b1 } } } )
                              shift <= data_aligned; 
            else if ( clk_div [BCLK_BIT  - 1:0] == '1 )
                              shift <= shift << 1'b1;    // Serial shift on the left side
        end

endmodule
