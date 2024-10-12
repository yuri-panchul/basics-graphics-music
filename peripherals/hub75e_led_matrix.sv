module hub75e_led_matrix
# (
    parameter clk_mhz       = 50,

              screen_width  = 64,
              screen_height = 64,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                    clk,
    input                    rst,

    output logic [w_x - 1:0] x,
    output logic [w_y - 1:0] y,

    output logic             ck,
    output logic             oe,
    output logic             st,

    output logic             a,
    output logic             b,
    output logic             c,
    output logic             d,
    output logic             e
);

    assign oe = 1'b1;

    //--------------------------------------------------------------

    localparam w_cnt = 5;

    logic [w_cnt - 1:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'b1;

    wire en = (cnt == w_cnt' (1'b1));

    //--------------------------------------------------------------

    logic [1:0] state, state_r;
    logic       burst, burst_r;
    logic       latch;

    logic [w_x - 1:0] x_r;
    logic [w_y - 1:0] y_r;

    //--------------------------------------------------------------

    always_comb
    begin
        state = state_r;

        burst = 1'b0;
        latch = 1'b0;

        x     = x_r;
        y     = y_r;

        case (state)

        2'd0:
        begin
            if (x == screen_width - 1)
            begin
                state = 2'd1;
                x     = '0;
                burst = 1'b0;
            end
            else
            begin
                x ++;
                burst = 1'b1;
            end
        end

        2'd1:
        begin
            state = 2'd2;
        end

        2'd2:
        begin
            latch = 1'b1;
            state = 2'd3;
        end

        2'd3:
        begin
            if (y == screen_height - 1)
                y = '0;
            else
                y ++;

            burst = 1'b1;
            latch = 1'b0;
            state = 2'd0;
        end

        endcase
    end

    //--------------------------------------------------------------

    always_ff @ (posedge clk)
        if (rst)
            ck <= 1'b0;
        else
            ck <= cnt [$left (cnt)] & burst_r;

    //--------------------------------------------------------------

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            state_r <= '0;
            burst_r <= 1'b1;

            x_r     <= '0;
            y_r     <= '0;

            st      <= 1'b0;

            { a, b, c, d, e } <= '0;
        end
        else if (en)
        begin
            state_r <= state;
            burst_r <= burst;

            x_r     <= x;
            y_r     <= y;

            st      <= latch;

            { a, b, c, d, e } <= y;
        end
    end

endmodule
