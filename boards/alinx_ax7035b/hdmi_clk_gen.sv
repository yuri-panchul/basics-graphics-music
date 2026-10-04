//----------------------------------------------------------------------------
//
//  Pixel clock and TMDS serial clock for Xilinx 7 series FPGAs
//
//  Both clocks are produced by a single MMCM, which is what the OSERDESE2
//  serializer in hdmi_tx requires: its CLK and CLKDIV inputs have to have
//  a known phase relationship.
//
//  For the 50 MHz board clock and a 25 MHz pixel clock the numbers are
//
//      VCO         = 50 MHz * 20     = 1000 MHz
//      serial_clk  = 1000 MHz / 8    =  125 MHz
//      pixel_clk   = 1000 MHz / 40   =   25 MHz
//
//  The 1000 MHz VCO frequency is inside the range of the Artix-7 MMCM for
//  every speed grade. Other combinations of clk_mhz and pixel_mhz work as
//  long as 1000 divides evenly by both the input and the output frequencies.
//
//----------------------------------------------------------------------------

`default_nettype none

module hdmi_clk_gen
# (
    parameter clk_mhz   = 50,
              pixel_mhz = 25
)
(
    input  wire clk_in,
    input  wire rst,

    output wire pixel_clk,
    output wire serial_clk,
    output wire locked
);

    localparam real vco_mhz        = 1000.0,

                    clkin_period   = 1000.0 / clk_mhz,
                    clkfbout_mult  = vco_mhz / clk_mhz,
                    clkout0_divide = vco_mhz / (5 * pixel_mhz),
                    clkout1_divide = vco_mhz / pixel_mhz;

    wire clk_fb;
    wire serial_clk_raw, pixel_clk_raw;

    MMCME2_BASE
    # (
        .BANDWIDTH          ( "OPTIMIZED"        ),
        .CLKIN1_PERIOD      ( clkin_period       ),
        .DIVCLK_DIVIDE      ( 1                  ),
        .CLKFBOUT_MULT_F    ( clkfbout_mult      ),
        .CLKOUT0_DIVIDE_F   ( clkout0_divide     ),
        .CLKOUT1_DIVIDE     ( int'(clkout1_divide) ),
        .STARTUP_WAIT       ( "FALSE"            )
    )
    i_mmcm
    (
        .CLKIN1    ( clk_in         ),
        .CLKFBIN   ( clk_fb         ),
        .CLKFBOUT  ( clk_fb         ),
        .CLKFBOUTB (                ),

        .CLKOUT0   ( serial_clk_raw ),
        .CLKOUT0B  (                ),
        .CLKOUT1   ( pixel_clk_raw  ),
        .CLKOUT1B  (                ),
        .CLKOUT2   (                ),
        .CLKOUT2B  (                ),
        .CLKOUT3   (                ),
        .CLKOUT3B  (                ),
        .CLKOUT4   (                ),
        .CLKOUT5   (                ),
        .CLKOUT6   (                ),

        .LOCKED    ( locked         ),
        .PWRDWN    ( 1'b0           ),
        .RST       ( rst            )
    );

    // A clock leaving an MMCM has to reach the logic through a clock buffer

    BUFG i_bufg_serial (.I (serial_clk_raw), .O (serial_clk));
    BUFG i_bufg_pixel  (.I (pixel_clk_raw ), .O (pixel_clk ));

endmodule

`default_nettype wire
