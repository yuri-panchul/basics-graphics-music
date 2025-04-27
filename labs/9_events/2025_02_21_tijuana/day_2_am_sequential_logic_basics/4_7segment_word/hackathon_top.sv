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

    wire update_ring;

    strobe_gen # (.clk_mhz (27), .strobe_hz (200))  // Try changing strobe_hz
    i_strobe_gen_1 (.clk (clock), .rst (reset), .strobe (update_ring));

    //------------------------------------------------------------------------

    logic [7:0] ring;

    always_ff @ (posedge clock)
      if (reset)
        ring <= 8'b10000000;
      else if (update_ring)
        ring <= { ring [0], ring [7:1] };

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

    always_comb
        case (ring)
        8'b0000_1000: letter = F;
        8'b0000_0100: letter = P;
        8'b0000_0010: letter = G;
        8'b0000_0001: letter = A;
        default:      letter = space;
        endcase

    always_ff @ (posedge clock)
        if (reset)
        begin
            abcdefgh <= space;
            digit    <= 8'b0;
        end
        else
        begin
            abcdefgh <= letter;
            digit    <= ring;
        end

    // Exercise: Put your name or another word to the display.


endmodule
