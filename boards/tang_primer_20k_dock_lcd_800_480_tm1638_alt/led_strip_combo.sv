module led_strip_combo
(
    input                      clk,
    input                      rst,

    input  bit   [0:12] [31:0] data_rgb,

    output logic        [0 :0] sk9822_clk,
    output logic        [0 :0] sk9822_data
);
    logic [0 :415] data_rgb_reg;
    logic [14:  0] clk_div;
    logic [0 :  0] ws2812;
    logic [1 :  0] cnt_3;
    logic [4 :  0] cnt_ws2812;

    always_ff @(posedge clk or posedge rst)
        if (rst)
            clk_div <= 15'd7320;
        else
            clk_div <= clk_div + 1'b1;

    always_ff @(posedge clk or posedge rst)
        if (rst)
            sk9822_clk <= '0;
        else
            sk9822_clk <= ~clk_div[3] & ~ws2812;

    always_ff @(posedge clk_div[3])
        if (clk_div < 15'd6152)
            sk9822_data <= data_rgb_reg[clk_div[12:4]];
        else if ((clk_div > 15'd6151 ) && (clk_div < 15'd7320 ))
            sk9822_data <= 1'b0;
        else if ((clk_div > 15'd30727) && (clk_div < 15'd31896)) begin
            ws2812      <= 1'b1;
            sk9822_data <= ((cnt_3 == 2'd2) ? data_rgb_reg[cnt_ws2812 + 10'd392] : cnt_3[0]);
            if (cnt_3 < 2'd2)
                cnt_3      <= cnt_3 + 1'b1;
            else begin
                cnt_3      <= 1'b0;
                cnt_ws2812 <= cnt_ws2812 + 1'b1;
            end
        end
        else begin
            data_rgb_reg <= data_rgb;
            sk9822_data  <= 1'b0;
            ws2812       <= 1'b0;
            cnt_3        <= 1'b1;
            cnt_ws2812   <= 1'b0;
        end

endmodule
