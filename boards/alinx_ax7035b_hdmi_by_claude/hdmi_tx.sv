//----------------------------------------------------------------------------
//
//  DVI / HDMI transmitter for Xilinx 7 series FPGAs
//
//  The TMDS symbols are produced by the tmds_encoder of peripherals/dvi.sv,
//  which is shared by the whole repository, and each symbol is then shifted
//  out by a pair of OSERDESE2 primitives working as a 10:1 double data rate
//  serializer.
//
//  The serial clock has to be 5 times the pixel clock: 10 bits per pixel
//  are sent on both edges of the serial clock. Both clocks are expected to
//  come from the same MMCM, otherwise the serializer has no defined phase
//  relationship between CLK and CLKDIV.
//
//  The reset has to be released synchronously with the pixel clock, which
//  is CLKDIV of the serializer. If it were released asynchronously, the
//  master and the slave of a pair could leave the reset on different edges
//  and frame the ten bits of a symbol differently. hdmi_clk_gen produces
//  such a reset.
//
//  The fourth channel carries the pixel clock itself, sent as the constant
//  symbol 10'b1111100000, which produces five high bits followed by five
//  low bits - a square wave of the pixel frequency, in the same phase as
//  the symbols of the data channels.
//
//----------------------------------------------------------------------------

`default_nettype none

module hdmi_tx
(
    input  wire       pixel_clk,      // Pixel clock, 25 MHz for 640x480
    input  wire       serial_clk,     // 5 x pixel_clk, phase-related to it
    input  wire       rst,            // Released synchronously with pixel_clk

    input  wire       hsync,          // Active low, as 640x480@60 expects,
    input  wire       vsync,          // which is what vga and dvi_sync give

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
    //  Channel 0 carries blue and the sync signals, channel 1 carries
    //  green, channel 2 carries red
    //
    //------------------------------------------------------------------------

    wire [7:0] channel_data [0:2];

    assign channel_data [0] = blue;
    assign channel_data [1] = green;
    assign channel_data [2] = red;

    localparam [9:0] clock_symbol = 10'b1111100000;

    //------------------------------------------------------------------------

    genvar i;

    generate
        for (i = 0; i < 4; i = i + 1)
        begin : channel

            wire [9:0] symbol;

            if (i == 3)
            begin : clock_channel

                assign symbol = clock_symbol;

            end
            else
            begin : data_channel

                tmds_encoder i_tmds_encoder
                (
                    .clk_i ( pixel_clk            ),
                    .rst_i ( rst                  ),
                    .C0    ( i == 0 ? hsync : 1'b0 ),
                    .C1    ( i == 0 ? vsync : 1'b0 ),
                    .DE    ( display_on           ),
                    .D     ( channel_data [i]     ),
                    .q_out ( symbol               )
                );

            end

            //----------------------------------------------------------------

            wire shift_1, shift_2, serial_data;

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
                .D3        ( symbol [8]  ),
                .D4        ( symbol [9]  ),
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
                .OQ        ( serial_data ),
                .OFB       (             ),
                .TQ        (             ),
                .TFB       (             ),
                .TBYTEOUT  (             ),
                .SHIFTOUT1 (             ),
                .SHIFTOUT2 (             ),

                .CLK       ( serial_clk  ),
                .CLKDIV    ( pixel_clk   ),
                .RST       ( rst         ),
                .OCE       ( 1'b1        ),
                .TCE       ( 1'b0        ),
                .TBYTEIN   ( 1'b0        ),
                .SHIFTIN1  ( shift_1     ),
                .SHIFTIN2  ( shift_2     ),

                .D1        ( symbol [0]  ),
                .D2        ( symbol [1]  ),
                .D3        ( symbol [2]  ),
                .D4        ( symbol [3]  ),
                .D5        ( symbol [4]  ),
                .D6        ( symbol [5]  ),
                .D7        ( symbol [6]  ),
                .D8        ( symbol [7]  ),

                .T1        ( 1'b0        ),
                .T2        ( 1'b0        ),
                .T3        ( 1'b0        ),
                .T4        ( 1'b0        )
            );

            //----------------------------------------------------------------

            // The I/O standard is also set in the constraints, but setting
            // it here keeps the buffer and the pins from disagreeing

            if (i == 3)
            begin : clock_buffer

                OBUFDS # (.IOSTANDARD ("TMDS_33"), .SLEW ("FAST"))
                i_obufds (.I (serial_data), .O (tmds_clk_p), .OB (tmds_clk_n));

            end
            else
            begin : data_buffer

                OBUFDS # (.IOSTANDARD ("TMDS_33"), .SLEW ("FAST"))
                i_obufds (.I (serial_data),
                          .O (tmds_data_p [i]), .OB (tmds_data_n [i]));

            end

        end
    endgenerate

endmodule

`default_nettype wire
