`include "config.vh"

module sync_and_debounce
# (
    parameter w = 1, depth = 8
)
(   
    input            clk,
    input            reset,
    input  [w - 1:0] sw_in,
    output [w - 1:0] sw_out
);

    genvar sw_cnt;

    generate
        for (sw_cnt = 0; sw_cnt < w; sw_cnt = sw_cnt + 1)
        begin : gen_sync_and_debounce
           
           sync_and_debounce_one
           # (.depth (depth))
           i_sync_and_debounce_one
           (    
              .clk    ( clk             ),
              .reset  ( reset           ),
              .sw_in  ( sw_in  [sw_cnt] ),
              .sw_out ( sw_out [sw_cnt] )
           );

        end
    endgenerate 

endmodule
