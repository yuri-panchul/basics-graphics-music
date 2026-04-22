module led_strip_combo
(
    input                    clk,
    input                    rst,

    input  bit [0:12] [31:0] data_rgb,

    output logic             sk9822_clk,
    output logic             sk9822_data
);
    logic [0 :415] data_rgb_reg;
    logic [14:  0] clk_div;
    logic          ws2812;
    logic [5 :  0] cnt_48;
    logic [4 :  0] cnt_ws2812;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div      <= 15'd7320;
            sk9822_clk   <= '0;
            data_rgb_reg <= '0;
            sk9822_data  <= 1'b0;
            ws2812       <= 1'b1;
            cnt_48       <= 1'b1;
            cnt_ws2812   <= 1'b0;
        end
        else begin
            clk_div <= clk_div + 1'b1;
            sk9822_clk <= clk_div[3] & ws2812;
            if (clk_div <= 15'd6151)
                sk9822_data <= data_rgb_reg[clk_div[12:4]];
            else if ((clk_div >= 15'd6152 ) && (clk_div <= 15'd7319 ))
                sk9822_data <= 1'b0;
            else if ((clk_div >= 15'd30728) && (clk_div <= 15'd31895)) begin
                ws2812 <= 1'b0;
                sk9822_data <= ((cnt_48 >= 6'd32) ?
                               data_rgb_reg[cnt_ws2812 + 10'd392] : &cnt_48[4:3]);
                if (cnt_48 <= 6'd46)
                    cnt_48 <= cnt_48 + 1'b1;
                else begin
                    cnt_48 <= 1'b0;
                    cnt_ws2812 <= cnt_ws2812 + 1'b1;
                end
            end
            else begin
                data_rgb_reg <= data_rgb;
                sk9822_data  <= 1'b0;
                ws2812       <= 1'b1;
                cnt_48       <= 1'b1;
                cnt_ws2812   <= 1'b0;
            end
        end
    end

endmodule
