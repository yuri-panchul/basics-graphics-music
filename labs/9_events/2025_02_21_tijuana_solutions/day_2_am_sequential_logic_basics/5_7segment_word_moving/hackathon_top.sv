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

    wire update_digit;

    strobe_gen # (.clk_mhz (27), .strobe_hz (200))
    i_strobe_gen_1 (.clk (clock), .rst (reset), .strobe (update_digit));

    wire update_offset;

    strobe_gen # (.clk_mhz (27), .strobe_hz (5))
    i_strobe_gen_2 (.clk (clock), .rst (reset), .strobe (update_offset));

    //------------------------------------------------------------------------

    logic [2:0] i_digit;

    always_ff @ (posedge clock)
      if (reset)
        i_digit <= 0;
      else if (update_digit)
        i_digit <= i_digit + 1;

    logic [2:0] offset;

    always_ff @ (posedge clock)
      if (reset)
        offset <= 0;
      else if (update_offset)
        offset <= offset + 1;

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

    typedef enum bit [7:0]
    {
        F     = 8'b1000_1110,
        P     = 8'b1100_1110,
        G     = 8'b1011_1100,
        A     = 8'b1110_1110,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

    seven_seg_encoding_e letter;

    wire [2:0] shifted_i_digit = i_digit - offset;

    always_comb
        case (shifted_i_digit)
        3'd4: letter = F;
        3'd5: letter = P;
        3'd6: letter = G;
        3'd7: letter = A;
        default: letter = space;
        endcase

    always_ff @ (posedge clock)
        if (reset)
        begin
            abcdefgh <= space;
            digit    <= 0;
        end
        else
        begin
            abcdefgh <= letter;
            digit    <= 8'b10000000 >> i_digit;
        end

    // Exercise: Make the word moving another direction

    // START_SOLUTION
    // END_SOLUTION

endmodule
