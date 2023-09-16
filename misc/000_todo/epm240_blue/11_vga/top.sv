module top
(
    input              clk,
    input              rst_n,
    input        [2:0] key,
    output       [7:0] led,
    output             vcc_for_keys,

    output             hsync,
    output             vsync,

    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue,

    output       [3:0] vcc_for_vga,
    output       [3:0] gnd_for_vga
);

    assign vcc_for_keys = '1;
    assign vcc_for_vga  = '1;
    assign gnd_for_vga  = '0;

    wire rst = ~ rst_n;

    //------------------------------------------------------------------------

    localparam X_WIDTH = 10,
               Y_WIDTH = 10,
               CLK_MHZ = 50;

    //------------------------------------------------------------------------

    assign led = '1;

    //------------------------------------------------------------------------

    wire display_on;

    wire [X_WIDTH - 1:0] x;
    wire [Y_WIDTH - 1:0] y;

    vga
    # (
        .HPOS_WIDTH ( X_WIDTH    ),
        .VPOS_WIDTH ( Y_WIDTH    ),

        .CLK_MHZ    ( CLK_MHZ    )
    )
    i_vga
    (
        .clk        ( clk        ),
        .reset      ( rst        ),
        .hsync      ( hsync      ),
        .vsync      ( vsync      ),
        .display_on ( display_on ),
        .hpos       ( x          ),
        .vpos       ( y          )
    );

    //------------------------------------------------------------------------
    // Pattern 1

    /*
    wire [Y_WIDTH * 2 - 1:0] x_2 = x * x;

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (display_on & x_2 [9 +: Y_WIDTH] < y)
        begin
            red   = x [X_WIDTH - 2 -: 4];
            green = y [Y_WIDTH - 2 -: 4];
            blue  = '1;
        end
    end
    */

    //------------------------------------------------------------------------
    // Pattern 2

    logic [22:0] cnt;

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    wire enable = (cnt == '0);

    //------------------------------------------------------------------------

    logic [7:0] dx, dy;

    always_ff @ (posedge clk)
        if (rst)
        begin
            dx <= 4'b0;
            dy <= 4'b0;
        end
        else if (enable)
        begin
            dx <= dx + key [2];
            dy <= dy + key [1];
        end

    //------------------------------------------------------------------------

    wire [3:0] xc = x [X_WIDTH - 2 -: 4];
    wire [3:0] yc = y [Y_WIDTH - 2 -: 4];

    always_comb
    begin
      red   = '0;
      green = '0;
      blue  = '0;

      if (display_on)
      begin
        red   = xc + xc + yc + dx;
        green = xc - yc - dy;
        blue  = { 4 { ~ key [0] } };
      end
    end

endmodule
