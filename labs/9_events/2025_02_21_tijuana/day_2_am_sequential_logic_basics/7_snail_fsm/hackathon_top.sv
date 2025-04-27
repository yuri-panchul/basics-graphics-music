// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);

    //------------------------------------------------------------------------

    wire enable;
    wire fsm_in, moore_fsm_out, mealy_fsm_out;

    // Generate a strobe signal 3 times a second

    strobe_gen
    # (.clk_mhz (27), .strobe_hz (3))
    i_strobe_gen (.clk (clock), .rst (reset), .strobe (enable));

    shift_reg # (8) i_shift_reg
    (
        .clk     (   clock  ),
        .rst     (   reset  ),
        .en      (   enable ),
        .seq_in  ( | key    ),
        .seq_out (   fsm_in ),
        .par_out (   led    )
    );

    snail_moore_fsm i_moore_fsm
    (
        .clock,  // a shortcut for ".clock (clock)"
        .reset,
        .enable,
        .a       ( fsm_in        ),
        .y       ( moore_fsm_out )
    );

    snail_mealy_fsm i_mealy_fsm
    (
        .clock,
        .reset,
        .enable,
        .a       ( fsm_in        ),
        .y       ( mealy_fsm_out )
    );

    //------------------------------------------------------------------------

    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h

    always_comb
    begin
        case ({ mealy_fsm_out, moore_fsm_out })
        2'b00: abcdefgh = 8'b0000_0000;
        2'b01: abcdefgh = 8'b1100_0110;  // Moore only
        2'b10: abcdefgh = 8'b0011_1010;  // Mealy only
        2'b11: abcdefgh = 8'b1111_1110;
        endcase

        digit = 8'b00000001;
    end

    // Exercise: Implement FSM for recognizing other sequence,
    // for example 0101

endmodule
