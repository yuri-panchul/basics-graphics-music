module hub75e_led_matrix
# (
    parameter clk_mhz       = 50,

              screen_width  = 64,
              screen_height = 64,

              w_red         = 1,
              w_green       = 1,
              w_blue        = 1,

              brightness    = 1,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        rst,

    // Coordinates for the user

    output logic [w_x     - 1:0] x,
    output logic [w_y     - 1:0] y,

    // Colors coming from the user

    input        [w_red   - 1:0] red,
    input        [w_green - 1:0] green,
    input        [w_blue  - 1:0] blue,

    // Output control signals

    output logic                 ck,
    output logic                 oe,
    output logic                 st,

    // Output address

    output logic                 a,
    output logic                 b,
    output logic                 c,
    output logic                 d,
    output logic                 e,

    // Output colors

    output logic                 r1,
    output logic                 r2,

    output logic                 g1,
    output logic                 g2,

    output logic                 b1,
    output logic                 b2
);

    //------------------------------------------------------------------------

    localparam w_cnt = clk_mhz > 50 ? 2 : 1;

    logic [w_cnt - 1:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= w_cnt' (1);
        else
            cnt <= cnt + 1'b1;

    wire en = (cnt == '0);

    //------------------------------------------------------------------------

    localparam w_state = brightness + 3;

    localparam [w_state - 1:0]
        state_burst = 0,
        state_1     = 1,
        state_2     = 2,
        state_3     = 3,
        state_last  = w_state' (~ 0);

    logic [w_state - 1:0] state, state_d;

    //------------------------------------------------------------------------

    logic [w_x - 1:0] x_r;
    logic [w_y - 1:0] y_r;

    always_comb
    begin
        state_d = state;
        x       = x_r;
        y       = y_r;

        case (state)

        state_burst:
        begin
            x ++;

            if (x == screen_width - 1)
                state_d = state_1;
        end

        state_last:
        begin
            x = '0;

            if (y == screen_height - 1)
                y = '0;
            else
                y ++;

            state_d = state_burst;
        end

        default:
            state_d ++;

        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (rst)
            ck <= 1'b0;
        else
            ck <= cnt [$left (cnt)] & (state <= state_1);

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            state <= state_burst;
            x_r   <= '0;
            y_r   <= '0;

            oe    <= 1'b1;
            st    <= 1'b0;
        end
        else if (en)
        begin
            state <= state_d;
            x_r   <= x;
            y_r   <= y;

            oe    <= (state <= state_3 | state == state_last);
            st    <= (state == state_2);
        end

    //------------------------------------------------------------------------

    assign { e, d, c, b, a } = y_r;

    //------------------------------------------------------------------------

    wire first_32_lines = (y [w_y - 1] == 1'b0);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            r1 <= 1'b0;
            r2 <= 1'b0;

            g1 <= 1'b0;
            g2 <= 1'b0;

            b1 <= 1'b0;
            b2 <= 1'b0;
        end
        else if (en)
        begin
            r1 <= ( | red   ) &   first_32_lines;
            r2 <= ( | red   ) & ~ first_32_lines;

            g1 <= ( | green ) &   first_32_lines;
            g2 <= ( | green ) & ~ first_32_lines;

            b1 <= ( | blue  ) &   first_32_lines;
            b2 <= ( | blue  ) & ~ first_32_lines;
        end

endmodule

//----------------------------------------------------------------------------

`ifndef YOSYS

// `define LOCAL_TESTBENCH

`ifdef LOCAL_TESTBENCH

module tb_hub75e_led_matrix;

    logic clk;
    logic rst;

    logic [5:0] x;

    logic red, green, blue;

    hub75e_led_matrix
    # (.clk_mhz (50))
    dut
    (
        .clk   ( clk   ),
        .rst   ( rst   ),

        .x     ( x     ),

        .red   ( red   ),
        .green ( green ),
        .blue  ( blue  )
    );

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (100) @ (posedge clk);
        rst <= 1'b0;
    end

    initial
    begin
        $dumpvars;

        for (int i = 0; i < 10000; i ++)
        begin
            { red, green, blue } <= 3' (x);
            @ (posedge clk);
        end

        $finish;
    end

endmodule

`endif
`endif
