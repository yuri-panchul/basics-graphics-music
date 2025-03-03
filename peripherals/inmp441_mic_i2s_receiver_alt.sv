`include "config.svh"

module inmp441_mic_i2s_receiver_alt
# (
    parameter clk_mhz = 50
)
(
    input               clk,
    input               rst,
    input               right,
    output              lr,
    output logic        ws,
    output              sck,
    input               sd,
    output logic [23:0] value
);
    localparam CLK_BIT = $clog2(clk_mhz + 5) - 4;
    logic     [CLK_BIT - 1:0] clk_div;
    logic     [          6:0] cnt;
    logic                     clk_mic;
    logic                     clk_12;   // For clk_mhz < 13 MHz
    logic     [          1:0] state;    // For divisor by 3
    logic     [         23:0] shift;    // Data

    assign lr = (right == 1'bz) ? 1'b0 : right;

    //------------------------------------------------------------------------

generate

    //  For clk_mhz 27-38 MHz
    if ((clk_mhz > 26) && (clk_mhz < 39)) begin

        // Divisor by 3
        always_ff @(posedge clk or posedge rst) begin
            if (rst)
                state   <= 2'b00;
            else begin
                state   <= (state == 2'b10) ? 2'b00 : state + 1'b1;
                clk_mic <= !state;
            end
        end
        assign  clk_12   = 1'b0;
    end

    // For clk_mhz < 13 MHz
    else if (clk_mhz < 13) begin
        assign clk_mic = clk;
        assign clk_12  = cnt[0];
    end

    else begin
        always_ff @(posedge clk or posedge rst) begin
            if (rst)
                clk_div <= '0;
            else
                clk_div <= clk_div + 1'd1;
        end
        always_ff @(posedge clk or posedge rst) begin
            if (rst)
                clk_mic <= 1'b0;
            else if (clk_div == '1)
                clk_mic <= 1'b1;
            else
                clk_mic <= 1'b0;
        end
        assign  clk_12   = 1'b0;
    end

endgenerate

    //------------------------------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            cnt <= '0;
        else if (clk_mic)
            cnt <= cnt + 1'b1;
    end

    //------------------------------------------------------------------------

    assign sck = cnt[1];    // 100 MHz / 32 = 3.125 MHz 48.828 KHz
                            //  50 MHz / 16 = 3.125 MHz 48.828 KHz
                            //  33 MHz / 12 = 2.75  MHz 42.969 KHz
                            //  27 MHz / 12 = 2.25  MHz 35.156 KHz
                            //  25 MHz /  8 = 3.125 MHz 48.828 KHz
                            //  12 MHz /  4 = 3     MHz 46.875 KHz

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            ws <= 1'b1;
        else if (clk_mic && cnt == 3'd3)
            ws <= ~ ws;
    end

    wire sample_bit
        =    ws == lr
          && (clk_mic || clk_12)    // 1   clk cycle
          && cnt >= 4'd9            // 1.5 sck cycle
          && cnt <= 7' (9 + 23 * 4) // sampling 0 to 23
          && cnt[1:0] == 1'b1;      // before posedge sck

    wire value_done = (ws == lr) & (cnt == '1);

    //------------------------------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            shift <= '0;
            value <= '0;
        end
        else begin
            if (sample_bit)
                shift <= {shift[22:0], sd};
            else if (value_done)
                value <= shift;
        end
    end

endmodule
