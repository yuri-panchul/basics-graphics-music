`timescale 1 ns / 1 ps

// Run with AMD's UNISIM models; see ../README.md.
module hdmi_tb;
    logic clk_in = 1'b0;
    logic rst_in = 1'b1;
    always #10 clk_in = ~ clk_in;

    wire clk, rst, enable;
    wire [9:0] x;
    wire [8:0] y;
    wire cp, cn;
    wire [2:0] dp, dn;

    ax7035b_hdmi dut
    (
        .clk_in (clk_in), .rst_in (rst_in), .clk (clk), .rst (rst),
        .x (x), .y (y), .red (x[7:0]), .green (y[7:0]),
        .blue (x[7:0] ^ y[7:0]), .tmds_clk_p (cp), .tmds_clk_n (cn),
        .tmds_data_p (dp), .tmds_data_n (dn), .hdmi_enable (enable)
    );

    function automatic bit is_control (input logic [9:0] s);
        return s == 10'b1101010100 || s == 10'b0010101011 ||
               s == 10'b0101010100 || s == 10'b1010101011;
    endfunction

    function automatic logic [9:0] control_symbol (input bit h, v);
        case ({v, h})
            2'b00: return 10'b1101010100;
            2'b01: return 10'b0010101011;
            2'b10: return 10'b0101010100;
            2'b11: return 10'b1010101011;
        endcase
    endfunction

    // Undo disparity inversion, then the XOR/XNOR transition encoding.
    function automatic logic [7:0] decode (input logic [9:0] s);
        logic [7:0] q, d;
        q = s[9] ? ~ s[7:0] : s[7:0];
        d[0] = q[0];

        for (int i = 1; i < 8; i++)
            d[i] = q[i] ^ q[i-1] ^ ~ s[8];

        return d;
    endfunction

    logic [9:0] symbols [0:2];
    bit previous_clock = 0;
    bit aligned = 0;
    bit tracking = 0;
    bit saw_vsync_high = 0;
    int bit_number = 0;
    int column = 0;
    int row = 490;
    int checked = 0;
    int active_pixels = 0;
    int completed_frames = 0;

    // The forwarded clock's falling edge marks bit zero of each TMDS word.
    always @(dut.serial_clk)
    begin
        #1;

        if (!enable)
        begin
            previous_clock = 0;
            aligned = 0;
            tracking = 0;
            saw_vsync_high = 0;
            bit_number = 0;
            column = 0;
            row = 490;
            checked = 0;
            active_pixels = 0;
        end
        else
        begin
            if (cn !== ~ cp || dn !== ~ dp)
                $fatal (1, "Differential outputs are not complementary");

            if (!aligned && previous_clock && !cp)
                aligned = 1;

            previous_clock = cp;

            if (aligned)
            begin
                if (cp !== (bit_number >= 5))
                    $fatal (1, "Forwarded pixel clock is not 5 low / 5 high bits");

                for (int lane = 0; lane < 3; lane++)
                    symbols[lane][bit_number] = dp[lane];

                if (bit_number == 9)
                begin
                    bit_number = 0;

                    // Lock to the start of vertical sync: pixel (0, 490).
                    if (!tracking && is_control (symbols[0]))
                    begin
                        if (symbols[0] == control_symbol (1, 1))
                            saw_vsync_high = 1;
                        else if (saw_vsync_high && symbols[0] == control_symbol (1, 0))
                            tracking = 1;
                    end

                    if (tracking)
                    begin
                        if (column < 640 && row < 480)
                        begin
                            if (is_control (symbols[0]) || is_control (symbols[1]) ||
                                is_control (symbols[2]) ||
                                decode (symbols[2]) !== 8'(column) ||
                                decode (symbols[1]) !== 8'(row) ||
                                decode (symbols[0]) !== (8'(column) ^ 8'(row)))
                                $fatal (1, "Wrong active RGB at (%0d, %0d)", column, row);

                            active_pixels++;
                        end
                        else if (symbols[0] !== control_symbol (
                                     !(column >= 656 && column < 752),
                                     !(row >= 490 && row < 492)) ||
                                 symbols[1] !== control_symbol (0, 0) ||
                                 symbols[2] !== control_symbol (0, 0))
                            $fatal (1, "Wrong blanking or sync at (%0d, %0d)", column, row);

                        column++;

                        if (column == 800)
                        begin
                            column = 0;
                            row = (row + 1) % 525;
                        end

                        checked++;

                        if (checked == 800 * 525)
                        begin
                            if (active_pixels != 640 * 480)
                                $fatal (1, "Wrong number of visible pixels");

                            completed_frames++;
                            tracking = 0;
                            saw_vsync_high = 0;
                            $display ("PASS: frame %0d, RGB, sync and serialization", completed_frames);
                        end
                    end
                end
                else
                    bit_number++;
            end
        end
    end

    initial
    begin
        #200 rst_in = 0;
        wait (completed_frames == 1);
        #7 rst_in = 1;
        #1;

        if (enable !== 0 || rst !== 1)
            $fatal (1, "Reset did not disable HDMI and reset the lab");

        #200 rst_in = 0;
        wait (completed_frames == 2);
        $display ("PASS: HDMI reset recovery");
        $finish;
    end

    initial
    begin
        #70000000;
        $fatal (1, "Timeout waiting for two valid frames");
    end
endmodule
