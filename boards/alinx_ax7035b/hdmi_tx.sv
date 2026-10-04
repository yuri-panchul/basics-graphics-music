//----------------------------------------------------------------------------
//
//  DVI / HDMI transmitter for Xilinx 7 series FPGAs
//
//  This is a Xilinx counterpart of boards/marsohod3gw2/hdmi.v, which does the
//  same thing with the OSER10 and ELVDS_OBUF primitives of Gowin.
//
//  The pixel data is encoded into 10-bit TMDS symbols by svo_tmds, three
//  channels in parallel, and each symbol is then shifted out by a pair of
//  OSERDESE2 primitives working as a 10:1 double data rate serializer.
//
//  The serial clock has to be 5 times the pixel clock: 10 bits per pixel
//  are sent on both edges of the serial clock. Both clocks are expected to
//  come from the same MMCM, otherwise the serializer has no defined phase
//  relationship between CLK and CLKDIV.
//
//  The fourth channel carries the pixel clock itself, sent as the constant
//  symbol 10'b00000_11111, which produces five low bits followed by five
//  high bits - a square wave of the pixel frequency.
//
//----------------------------------------------------------------------------

`default_nettype none

module hdmi_tx
(
    input  wire       pixel_clk,      // Pixel clock, 25 MHz for 640x480
    input  wire       serial_clk,     // 5 x pixel_clk, phase-related to it
    input  wire       rst,

    input  wire       hsync,          // Polarity as the sink expects it:
    input  wire       vsync,          // low during sync for 640x480@60

    input  wire       display_on,
    input  wire [7:0] red,
    input  wire [7:0] green,
    input  wire [7:0] blue,

    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n
);

    //------------------------------------------------------------------------
    //
    //  Encoding: channel 0 carries blue and the sync signals,
    //  channel 1 carries green, channel 2 carries red
    //
    //------------------------------------------------------------------------

    wire [9:0] symbol [0:2];

    svo_tmds i_svo_tmds_blue
    (
        .clk    (   pixel_clk        ),
        .resetn ( ~ rst              ),
        .de     (   display_on       ),
        .ctrl   (   { vsync, hsync } ),
        .din    (   blue             ),
        .dout   (   symbol [0]       )
    );

    svo_tmds i_svo_tmds_green
    (
        .clk    (   pixel_clk        ),
        .resetn ( ~ rst              ),
        .de     (   display_on       ),
        .ctrl   (   2'b00            ),
        .din    (   green            ),
        .dout   (   symbol [1]       )
    );

    svo_tmds i_svo_tmds_red
    (
        .clk    (   pixel_clk        ),
        .resetn ( ~ rst              ),
        .de     (   display_on       ),
        .ctrl   (   2'b00            ),
        .din    (   red              ),
        .dout   (   symbol [2]       )
    );

    //------------------------------------------------------------------------
    //
    //  Serialization: three data channels and the clock channel
    //
    //------------------------------------------------------------------------

    localparam [9:0] clock_symbol = 10'b00000_11111;

    wire [3:0] serial_data;

    genvar i;

    generate
        for (i = 0; i < 4; i = i + 1)
        begin : channel

            wire [9:0] word = (i == 3) ? clock_symbol : symbol [i];

            wire shift_1, shift_2;

            // The slave sends the two most significant bits of the symbol
            // to the master over the shift chain

            OSERDESE2
            # (
                .DATA_RATE_OQ   ( "DDR"   ),
                .DATA_RATE_TQ   ( "SDR"   ),
                .DATA_WIDTH     ( 10      ),
                .SERDES_MODE    ( "SLAVE" ),
                .TRISTATE_WIDTH ( 1       )
            )
            i_oserdes_slave
            (
                .OQ        (             ),
                .OFB       (             ),
                .TQ        (             ),
                .TFB       (             ),
                .TBYTEOUT  (             ),
                .SHIFTOUT1 ( shift_1     ),
                .SHIFTOUT2 ( shift_2     ),

                .CLK       ( serial_clk  ),
                .CLKDIV    ( pixel_clk   ),
                .RST       ( rst         ),
                .OCE       ( 1'b1        ),
                .TCE       ( 1'b0        ),
                .TBYTEIN   ( 1'b0        ),
                .SHIFTIN1  ( 1'b0        ),
                .SHIFTIN2  ( 1'b0        ),

                .D1        ( 1'b0        ),
                .D2        ( 1'b0        ),
                .D3        ( word [8]    ),
                .D4        ( word [9]    ),
                .D5        ( 1'b0        ),
                .D6        ( 1'b0        ),
                .D7        ( 1'b0        ),
                .D8        ( 1'b0        ),

                .T1        ( 1'b0        ),
                .T2        ( 1'b0        ),
                .T3        ( 1'b0        ),
                .T4        ( 1'b0        )
            );

            // The master sends the symbol least significant bit first

            OSERDESE2
            # (
                .DATA_RATE_OQ   ( "DDR"    ),
                .DATA_RATE_TQ   ( "SDR"    ),
                .DATA_WIDTH     ( 10       ),
                .SERDES_MODE    ( "MASTER" ),
                .TRISTATE_WIDTH ( 1        )
            )
            i_oserdes_master
            (
                .OQ        ( serial_data [i] ),
                .OFB       (                 ),
                .TQ        (                 ),
                .TFB       (                 ),
                .TBYTEOUT  (                 ),
                .SHIFTOUT1 (                 ),
                .SHIFTOUT2 (                 ),

                .CLK       ( serial_clk      ),
                .CLKDIV    ( pixel_clk       ),
                .RST       ( rst             ),
                .OCE       ( 1'b1            ),
                .TCE       ( 1'b0            ),
                .TBYTEIN   ( 1'b0            ),
                .SHIFTIN1  ( shift_1         ),
                .SHIFTIN2  ( shift_2         ),

                .D1        ( word [0]        ),
                .D2        ( word [1]        ),
                .D3        ( word [2]        ),
                .D4        ( word [3]        ),
                .D5        ( word [4]        ),
                .D6        ( word [5]        ),
                .D7        ( word [6]        ),
                .D8        ( word [7]        ),

                .T1        ( 1'b0            ),
                .T2        ( 1'b0            ),
                .T3        ( 1'b0            ),
                .T4        ( 1'b0            )
            );

        end
    endgenerate

    //------------------------------------------------------------------------
    //
    //  Differential output buffers, TMDS_33 standard set in the constraints
    //
    //------------------------------------------------------------------------

    OBUFDS i_obufds_clk
    (
        .I  ( serial_data [3] ),
        .O  ( tmds_clk_p      ),
        .OB ( tmds_clk_n      )
    );

    generate
        for (i = 0; i < 3; i = i + 1)
        begin : data_buffer

            OBUFDS i_obufds_data
            (
                .I  ( serial_data [i] ),
                .O  ( tmds_data_p [i] ),
                .OB ( tmds_data_n [i] )
            );

        end
    endgenerate

endmodule

`default_nettype wire
