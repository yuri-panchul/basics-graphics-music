// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module inmp441_mic_i2s_receiver
# (
    parameter clk_mhz = 50
)
(
    input               clk,
    input               rst,
    output              lr,
    output logic        ws,
    output              sck,
    input               sd,
    output logic [23:0] value
);

    assign lr = 1'b0;

    //------------------------------------------------------------------------

    logic clk_en;

    generate
        if (clk_mhz == 100)
        begin : clk_100
            always_ff @ (posedge clk or posedge rst)
                if (rst)
                    clk_en <= '0;
                else
                    clk_en <= ~ clk_en;
        end
        else
        begin : not_clk_100
            assign clk_en = '1;
        end
    endgenerate

    //------------------------------------------------------------------------

    logic [8:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (clk_en)
            cnt <= cnt + 1'd1;

    //------------------------------------------------------------------------

    assign sck = cnt [3];                // 50 MHz / 16   = 3.13 MHz

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ws <= 1'b1;
        else if (clk_en & cnt == 9'd15)  // 50 MHz / 1024 = 48.8  KHz
            ws <= ~ ws;

    wire sample_bit
        =    ws == lr
          && cnt >= 9'd39                // 1.5 sck cycle
          && cnt <= 9' (39 + 23 * 16)    // sampling 0 to 23
          && cnt [3:0] == 4'd7;          // posedge sck

    wire value_done = (ws == lr) & (cnt == '1);


    //------------------------------------------------------------------------

    logic [23:0] shift;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            shift <= '0;
            value <= '0;
        end
        else if (clk_en)
        begin
            if (sample_bit)
                shift <= { shift [22:0], sd };
            else if (value_done)
                value <= shift;
        end

endmodule
