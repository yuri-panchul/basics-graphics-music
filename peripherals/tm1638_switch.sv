`include "config.svh"
`include "lab_specific_board_config.svh"

`ifdef HCW132
    `define W_TM_KEY 16
`else
    `define W_TM_KEY 8
`endif

module tm1638_switch
# (
    parameter clk_mhz  = 50,
              w_digit  = 8,
              w_seg    = 8
)
(
    input                             clk,
    input                             rst,
    input        [               7:0] hgfedcba,
    input        [     w_digit - 1:0] digit,
    output logic [   `W_TM_KEY - 1:0] switches,
    output                            sio_clk,
    output logic                      sio_stb,
    inout                             sio_data
);
    logic [   `W_TM_KEY - 1:0] tm_keys_r;
    logic [   `W_TM_KEY - 1:0] tm_keys, tm_keys_press;
    logic [               7:0] tm_leds;

    assign tm_leds = switches[7:0];
    assign tm_keys_press = (~ tm_keys_r) & tm_keys;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            switches <= '0;
            tm_keys_r <= '0;
        end
        else begin
            tm_keys_r <= tm_keys;
            switches <= switches ^ tm_keys_press;
        end
    end

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz    ),
        .w_digit ( w_digit )        // fake parameter, digit count is hardcode in tm1638_board_controller
    )
    i_ledkey
    (
        .clk        ( clk           ),
        .rst        ( rst           ), // Don't make reset tm1638_board_controller by it's tm_key
        .hgfedcba   ( hgfedcba      ),
        .digit      ( digit         ),
        .ledr       ( tm_leds       ),
        .keys       ( tm_keys       ),
        .sio_stb    ( sio_clk       ),
        .sio_clk    ( sio_stb       ),
        .sio_data   ( sio_data      )
    );

endmodule
