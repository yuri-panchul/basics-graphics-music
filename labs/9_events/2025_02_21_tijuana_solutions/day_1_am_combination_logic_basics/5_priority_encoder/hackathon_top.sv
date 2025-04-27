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

    wire [2:0] in = key [2:0];

    //------------------------------------------------------------------------

    logic [1:0] enc0, enc1, enc2;

    // Implementation 1. Priority encoder using a chain of "ifs"

    always_comb
             if (in [0]) enc0 = 2'd0;
        else if (in [1]) enc0 = 2'd1;
        else if (in [2]) enc0 = 2'd2;
        else             enc0 = 2'd0;

    // Implementation 2. Priority encoder using casez

    always_comb
        casez (in)
        3'b??1:  enc1 = 2'd0;
        3'b?10:  enc1 = 2'd1;
        3'b100:  enc1 = 2'd2;
        default: enc1 = 2'd0;
        endcase

    // Implementation 3 (advanced): Using "for" loop
    // Note that in order to be synthesizable,
    // Verilog loop unrolls

    always_comb
    begin
        enc2 = '0;

        for (int i = 0; i < 3; i ++)
        begin
            if (in [i])
            begin
                enc2 = 2' (i);
                break;
            end
        end
    end

    //------------------------------------------------------------------------

    assign led = { 2'b00, enc2, enc1, enc0 };

endmodule
