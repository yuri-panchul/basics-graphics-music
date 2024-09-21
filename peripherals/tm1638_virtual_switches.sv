`include "config.svh"
`include "lab_specific_board_config.svh"

`ifdef HCW132
    `error_HCW132_is_not_compatible_with_tm1638_switches_module
`endif

module tm1638_virtual_switches
# (
    parameter clk_mhz = 50,
              w_digit = 8,
              w_seg   = 8,
              w_key   = 8
)
(
    input                         clk,
    input                         rst,
    input        [           7:0] hgfedcba,
    input        [ w_digit - 1:0] digit,
    output logic [ w_key   - 1:0] switches,
    output                        sio_clk,
    output logic                  sio_stb,
    inout                         sio_data
);
    logic [ w_key - 1:0] keys_r;
    logic [ w_key - 1:0] keys, keys_press;

    assign keys_press = (~ keys_r) & keys;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            switches  <= '0;
            keys_r <= '0;
        end
        else begin
            keys_r <= keys;
            switches  <= switches ^ keys_press;
        end
    end

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz )
    )
    i_ledkey
    (
        .clk        ( clk      ),
        .rst        ( rst      ), // Don't make reset tm1638_board_controller by it's tm_key
        .hgfedcba   ( hgfedcba ),
        .digit      ( digit    ),
        .ledr       ( switches ),
        .keys       ( keys     ),
        .sio_clk    ( sio_clk  ),
        .sio_stb    ( sio_stb  ),
        .sio_data   ( sio_data )
    );

endmodule
