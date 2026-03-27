module uart_sw
(
        input clk, 
        input rst, 
        input btn,  
        input rx, 
        output prog_rx, 
        output usert_rx, 
        output led
);

reg isUser;
reg btn_flag;
wire dbButton;


debouncer i_debouncer(.clk(clk), .sw_in(btn), .sw_out(dbButton));

    always @(posedge clk) begin
        if(rst)
            btn_flag<=0;
        if(dbButton) 
        begin
            btn_flag <= 1'b1;
            if(btn_flag == 1'b0)
                isUser <= ~isUser;
        end
        else
            btn_flag <='0;
    end

    assign usert_rx = isUser ? rx : 1'b1;
    assign prog_rx = isUser ? 1'b1 : rx;
    assign led = isUser;

endmodule


// From MipsFpga
// https://github.com/MIPSfpga/mipsfpga-plus/blob/master/system_rtl/mfp_switch_and_button_debouncers.v
module debouncer
# (
    parameter DEPTH = 8
)
(   
    input      clk,
    input      sw_in,
    output reg sw_out
);

    reg  [ DEPTH - 1 : 0] cnt;
    reg  [         2 : 0] sync;
    wire                  sw_in_s;

    assign sw_in_s = sync [2];

    always @ (posedge clk)
        sync <= { sync [1:0], sw_in };

    always @ (posedge clk)
        if (sw_out ^ sw_in_s)
            cnt <= cnt + 1'b1;
        else
            cnt <= { DEPTH { 1'b0 } };

    always @ (posedge clk)
        if (cnt == { DEPTH { 1'b1 } })
            sw_out <= sw_in_s;

endmodule