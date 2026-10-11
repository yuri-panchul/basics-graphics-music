`timescale 1ns / 1ps
`include "brs100_config.svh"

module tb;
    parameter LATENCY = 0;
    localparam WIDTH = `BRS100_WIDTH, HEIGHT = `BRS100_HEIGHT,
               HSTART = `BRS100_H_SYNC + `BRS100_H_BACK,
               VSTART = `BRS100_V_SYNC + `BRS100_V_BACK,
               HTOTAL = HSTART + WIDTH + `BRS100_H_FRONT,
               VTOTAL = VSTART + HEIGHT + `BRS100_V_FRONT;
    logic clk = 0, pixel_clk = 0, rst = 1;
    always #(500.0 / `BRS100_CLK_MHZ) clk = ~clk;
    integer divider = 0;

    // Derive the clocks from the same edges, just as the PLL does. Independent
    // rounded delays drift in a long simulation and invent a clock crossing.
    `ifdef BRS100_LAB_USES_PIXEL_CLOCK
    always @ (clk) pixel_clk = clk;
    `else
    always @ (clk)
        if (divider == 2)
        begin
            pixel_clk = ~pixel_clk;
            divider = 0;
        end
        else
            divider = divider + 1;

    `endif

    wire [$clog2(WIDTH)-1:0] x;
    wire [$clog2(HEIGHT)-1:0] y;
    wire [15:0] color = {x[4:0], y[5:0], x[4:0] ^ y[4:0]};
    wire [15:0] rgb;
    wire [4:0] r, b;
    wire [5:0] g;
    wire de, hs, vs;

    generate
        if (LATENCY == 0)
            assign rgb = color;
        else
        begin : pipeline
            logic [15:0] stages [0:LATENCY-1];

            always @ (posedge clk)
            begin
                stages[0] <= color;

                for (integer i = 1; i < LATENCY; i = i + 1)
                    stages[i] <= stages[i-1];
            end

            assign rgb = stages[LATENCY-1];
        end
    endgenerate

    brs100_lcd # (
        .screen_width(WIDTH), .screen_height(HEIGHT),
        .h_sync(`BRS100_H_SYNC), .h_back(`BRS100_H_BACK), .h_front(`BRS100_H_FRONT),
        .v_sync(`BRS100_V_SYNC), .v_back(`BRS100_V_BACK), .v_front(`BRS100_V_FRONT)
    ) dut
    (
        .pixel_clk(pixel_clk), .rst(rst), .x(x), .y(y),
        .red(rgb[15:11]), .green(rgb[10:5]), .blue(rgb[4:0]),
        .lcd_de(de), .lcd_hs(hs), .lcd_vs(vs),
        .lcd_r(r), .lcd_g(g), .lcd_b(b)
    );

    integer visible, ex, ey;
    logic active;
    logic [15:0] expected;

    initial
    begin
        #500;
        rst = 0;
        @(negedge vs);

        for (integer frame = 0; frame < 2; frame = frame + 1)
        begin
            visible = 0;

            for (integer v = 0; v < VTOTAL; v = v + 1)
                for (integer h = 0; h < HTOTAL; h = h + 1)
                begin
                    @(posedge pixel_clk);
                    active = h >= HSTART && h < HSTART + WIDTH && v >= VSTART && v < VSTART + HEIGHT;

                    if ({de, hs, vs} !== {active, (h >= `BRS100_H_SYNC), (v >= `BRS100_V_SYNC)})
                        $fatal(1, "Raster mismatch at frame=%0d h=%0d v=%0d", frame, h, v);

                    expected = 0;

                    if (active)
                    begin
                        ex = h - HSTART;
                        ey = v - VSTART;
                        expected = {ex[4:0], ey[5:0], ex[4:0] ^ ey[4:0]};
                        visible = visible + 1;
                    end

                    if ({r,g,b} !== expected)
                        $fatal(1, "RGB mismatch latency=%0d x=%0d y=%0d got=%h expected=%h",
                            LATENCY, ex, ey, {r,g,b}, expected);

                    if ((^ {x,y}) === 1'bx || x >= WIDTH || y >= HEIGHT)
                        $fatal(1, "Coordinates invalid, including blanking");
                end

            if (visible != WIDTH * HEIGHT)
                $fatal(1, "Wrong visible pixel count: %0d", visible);
        end

        rst = 1;
        #1;

        if ({de,r,g,b} !== 17'b0 || {hs,vs} !== 2'b11)
            $fatal(1, "Reset did not blank the panel");

        $display("PASS LCD: two complete frames, RGB latency=%0d", LATENCY);
        $finish;
    end

    initial #40000000 $fatal(1, "Timeout");
endmodule
