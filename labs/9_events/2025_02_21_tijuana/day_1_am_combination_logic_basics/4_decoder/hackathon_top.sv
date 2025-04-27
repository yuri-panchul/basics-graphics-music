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

    // Read the theory https://es.wikipedia.org/wiki/Decodificador

    //------------------------------------------------------------------------

    wire [1:0] in  = { key [1], key [0] };

    //------------------------------------------------------------------------

    // Implementation 1: tedious

    wire [3:0] dec0;

    assign dec0 [0] = ~ in [1] & ~ in [0];
    assign dec0 [1] = ~ in [1] &   in [0];
    assign dec0 [2] =   in [1] & ~ in [0];
    assign dec0 [3] =   in [1] &   in [0];

    // Implementation 2: case

    logic [3:0] dec1;

    always_comb
        case (in)
        2'b00: dec1 = 4'b0001;
        2'b01: dec1 = 4'b0010;
        2'b10: dec1 = 4'b0100;
        2'b11: dec1 = 4'b1000;
        endcase

    // Implementation 3: shift

    wire [3:0] dec2 = 4'b0001 << in;

    // Implementation 4: index

    logic [3:0] dec3;

    always_comb
    begin
        dec3 = 8'b0;
        dec3 [in] = 1'b1;
    end

    //------------------------------------------------------------------------

    assign led = key [2] ? { dec3, dec2 } : { dec1, dec0 };

    // Exercise: Change the code to decode 3-bit value to 8-bit vector

endmodule
