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

    parameter int BASE_CLK_MHZ = 50;

    logic clk_en;

    generate
        if (clk_mhz > BASE_CLK_MHZ) 
        begin : g_cnt_enable
            
            localparam int clk_ratio = (clk_mhz * 1000 * 1000) / (BASE_CLK_MHZ * 1000 * 1000);
            localparam int w_cnt = $clog2 (clk_ratio);

            logic [w_cnt - 1:0] cnt;

            always_ff @ (posedge clk or posedge rst)
            begin
                if (rst)
                begin
                    cnt     <= '0;
                    clk_en  <= '0;
                end
                else if (cnt == '0)
                begin
                    cnt     <= w_cnt' (clk_ratio - 1);
                    clk_en  <= '1;
                end
                else
                begin
                    cnt     <= cnt - 1'd1;
                    clk_en  <= '0;
                end
            end

        end
        else if (clk_mhz == BASE_CLK_MHZ)
        begin : g_full_enable
            assign clk_en = '1;
        end
        else
        begin : g_enable_is_not_possible
            $fatal("Generation of clk_enable is not possible for given frequency. Input frequency must by greater then 50 MHz.");
            assign clk_en = '0;
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
