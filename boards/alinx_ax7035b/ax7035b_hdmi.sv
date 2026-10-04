`include "config.svh"

// Fixed 640x480 video mode: 25 MHz pixels, 800x525 total, about 59.52 Hz.
// Reuse the common timing generator and encoder; serialize in Artix-7 I/O.
module ax7035b_hdmi
(
    input        clk_in,
    input        rst_in,
    output       clk,
    output       rst,
    output [9:0] x,
    output [8:0] y,
    input  [7:0] red,
    input  [7:0] green,
    input  [7:0] blue,
    output       tmds_clk_p,
    output       tmds_clk_n,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n,
    output       hdmi_enable
);
    wire feedback, feedback_buf;
    wire pixel_clk_raw, serial_clk_raw, lab_clk_raw;
    wire pixel_clk, serial_clk, locked;

    // 50 MHz * 20 = 1000 MHz VCO. DDR serialization needs 5x pixel clock.
    MMCME2_BASE
    # (
        .CLKIN1_PERIOD    (20.0),
        .DIVCLK_DIVIDE    (1),
        .CLKFBOUT_MULT_F  (20.0),
        .CLKOUT0_DIVIDE_F (8.0),
        .CLKOUT1_DIVIDE   (40),
        .CLKOUT2_DIVIDE   (20)
    )
    i_mmcm
    (
        .CLKIN1  (clk_in),
        .RST     (rst_in),
        .PWRDWN  (1'b0),
        .CLKFBIN (feedback_buf),
        .CLKFBOUT(feedback),
        .CLKOUT0 (serial_clk_raw),
        .CLKOUT1 (pixel_clk_raw),
        .CLKOUT2 (lab_clk_raw),
        .LOCKED  (locked)
    );

    BUFG i_feedback (.I (feedback),       .O (feedback_buf));
    BUFG i_pixel    (.I (pixel_clk_raw),  .O (pixel_clk));
    BUFG i_serial   (.I (serial_clk_raw), .O (serial_clk));
    BUFG i_lab      (.I (lab_clk_raw),    .O (clk));

    // Assert resets on button press or loss of lock; release in each domain.
    wire reset_request = rst_in | ~ locked;
    (* ASYNC_REG = "TRUE" *) logic [2:0] lab_reset = '1;
    (* ASYNC_REG = "TRUE" *) logic [2:0] video_reset = '1;

    always_ff @(posedge clk or posedge reset_request)
        if (reset_request)
            lab_reset <= '1;
        else
            lab_reset <= {lab_reset[1:0], 1'b0};

    always_ff @(posedge pixel_clk or posedge reset_request)
        if (reset_request)
            video_reset <= '1;
        else
            video_reset <= {video_reset[1:0], 1'b0};

    assign rst = lab_reset[2];
    wire pixel_rst = video_reset[2];

    // M6 controls HDMI1's +5 V supply and is active high, despite OEN's name.
    assign hdmi_enable = ~ pixel_rst;

    wire hsync, vsync, visible;
    dvi_sync i_sync
    (
        .clk_i (pixel_clk), .rst_i (pixel_rst),
        .hsync_o (hsync), .vsync_o (vsync),
        .pixel_x_o (x), .pixel_y_o (y), .visible_range_o (visible)
    );

    // Sample lab colors and their matching control signals together.
    logic [7:0] rgb [0:2];
    logic hsync_r, vsync_r, visible_r;

    always_ff @(posedge pixel_clk)
    begin
        if (pixel_rst)
        begin
            rgb[0] <= '0;
            rgb[1] <= '0;
            rgb[2] <= '0;
            hsync_r <= 1'b0;
            vsync_r <= 1'b0;
            visible_r <= 1'b0;
        end
        else
        begin
            rgb[0] <= blue;
            rgb[1] <= green;
            rgb[2] <= red;
            hsync_r <= hsync;
            vsync_r <= vsync;
            visible_r <= visible;
        end
    end

    for (genvar lane = 0; lane < 3; lane++)
    begin : g_data
        wire [9:0] symbol;

        tmds_encoder i_encoder
        (
            .clk_i (pixel_clk), .rst_i (pixel_rst),
            .C0 (lane == 0 ? hsync_r : 1'b0),
            .C1 (lane == 0 ? vsync_r : 1'b0),
            .DE (visible_r), .D (rgb[lane]), .q_out (symbol)
        );

        ax7035b_tmds_lane i_lane
        (
            .pixel_clk (pixel_clk), .serial_clk (serial_clk),
            .rst (pixel_rst), .symbol (symbol),
            .p (tmds_data_p[lane]), .n (tmds_data_n[lane])
        );
    end

    // Forward a 50% duty-cycle pixel clock with the same serializer latency.
    ax7035b_tmds_lane i_clock_lane
    (
        .pixel_clk (pixel_clk), .serial_clk (serial_clk),
        .rst (pixel_rst), .symbol (10'b1111100000),
        .p (tmds_clk_p), .n (tmds_clk_n)
    );
endmodule

// Ten-bit DDR output, LSB first. Bits 8 and 9 enter the slave's D3/D4.
module ax7035b_tmds_lane
(
    input       pixel_clk,
    input       serial_clk,
    input       rst,
    input [9:0] symbol,
    output      p,
    output      n
);
    wire shift1, shift2, serial_data;

    OSERDESE2
    # (
        .DATA_RATE_OQ ("DDR"), .DATA_RATE_TQ ("SDR"),
        .DATA_WIDTH (10), .TRISTATE_WIDTH (1), .SERDES_MODE ("MASTER")
    )
    i_master
    (
        .CLK (serial_clk), .CLKDIV (pixel_clk), .RST (rst), .OCE (1'b1),
        .D1 (symbol[0]), .D2 (symbol[1]), .D3 (symbol[2]), .D4 (symbol[3]),
        .D5 (symbol[4]), .D6 (symbol[5]), .D7 (symbol[6]), .D8 (symbol[7]),
        .SHIFTIN1 (shift1), .SHIFTIN2 (shift2), .OQ (serial_data),
        .T1 (1'b0), .T2 (1'b0), .T3 (1'b0), .T4 (1'b0),
        .TCE (1'b0), .TBYTEIN (1'b0)
    );

    OSERDESE2
    # (
        .DATA_RATE_OQ ("DDR"), .DATA_RATE_TQ ("SDR"),
        .DATA_WIDTH (10), .TRISTATE_WIDTH (1), .SERDES_MODE ("SLAVE")
    )
    i_slave
    (
        .CLK (serial_clk), .CLKDIV (pixel_clk), .RST (rst), .OCE (1'b1),
        .D1 (1'b0), .D2 (1'b0), .D3 (symbol[8]), .D4 (symbol[9]),
        .D5 (1'b0), .D6 (1'b0), .D7 (1'b0), .D8 (1'b0),
        .SHIFTIN1 (1'b0), .SHIFTIN2 (1'b0),
        .SHIFTOUT1 (shift1), .SHIFTOUT2 (shift2),
        .T1 (1'b0), .T2 (1'b0), .T3 (1'b0), .T4 (1'b0),
        .TCE (1'b0), .TBYTEIN (1'b0)
    );

    OBUFDS # (.IOSTANDARD ("TMDS_33"), .SLEW ("FAST"))
        i_output (.I (serial_data), .O (p), .OB (n));
endmodule
