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
    output logic [4:0] blue
);

    //------------------------------------------------------------------------

    logic [31:0] counter;

    always_ff @ (posedge clock)
        if (reset)
            counter <= 0;
        else
            counter <= counter + 1;

    wire enable = (counter [22:0] == 0);

    // Try different slices here, for example "counter [20:0] == 0"

    // Alternatively you can instantiate strobe generator:

/*
    wire enable0, enable1;

    strobe_gen # (.clk_mhz (27), .strobe_hz (3))
    i_strobe_gen_0 (.clk (clock), .rst (reset), .strobe (enable0));

    strobe_gen # (.clk_mhz (27), .strobe_hz (13))
    i_strobe_gen_1 (.clk (clock), .rst (reset), .strobe (enable1));

    always_ff @ (posedge clock)
        if (reset)
        begin
            led <= 8'b11001110;
        end
        else
        begin
            if (enable0)
                led [7:4] <= ~ led [7:4];

            if (enable1)
                led [3:0] <= ~ led [3:0];
        end

*/

    //------------------------------------------------------------------------

    wire button_on = | key;
    // wire button_on = key [0] | key [1] | key [2] | key [3] | key [4] | key [5] | key [6] | key [7];

    logic [7:0] shift_reg;

    always_ff @ (posedge clock)
        if (reset)
            shift_reg <= 8'b0;
        else if (enable)
            shift_reg <=
                { button_on | shift_reg [0],
                  shift_reg [7:1] };

            // Alternatively you can write:
            // shift_reg <= (button_on << 7) | (shift_reg >> 1);

    assign led = shift_reg;

//////

//   --a--       --1--
    //  |     |     |
    //  f     b     1     0
    //  |     |     |
    //   --g--       --1--
    //  |     |     |
    //  e     c     1     0
    //  |     |     |
    //   --d--  h      0    0
    localparam P = 8'b1100_1110,
               A = 8'b1110_1110,
               N = 8'b0010_1010,
               C = 8'b1001_1100,
               H = 8'b0110_1110,
               U = 8'b0111_1100,
               L = 8'b0001_1100,
               nothing = 8'b0;

    always_comb
    begin
        casez (led)
        8'b1???_????: abcdefgh = P;
        8'b01??_????: abcdefgh = A;
        8'b001?_????: abcdefgh = N;
        8'b0001_????: abcdefgh = C;
        8'b0000_1???: abcdefgh = H;
        8'b0000_01??: abcdefgh = U;
        8'b0000_001?: abcdefgh = L;
        default:      abcdefgh = nothing;
        endcase

             if (led [7]) digit = 8'b10000000;
        else if (led [6]) digit = 8'b01000000;
        else if (led [5]) digit = 8'b00100000;
        else if (led [4]) digit = 8'b00010000;
        else if (led [3]) digit = 8'b00001000;
        else if (led [2]) digit = 8'b00000100;
        else if (led [1]) digit = 8'b00000010;
        else              digit = 8'b00000000;
    end


////





    //assign led = { enable, 1'b0, enable } ; // shift_reg;

    // Exercise 1: Make the light move in the opposite direction.


    // Exercise 2: Make the light moving in a loop.
    // Use another key to reset the moving lights back to no lights.


    // Exercise 3: Display the state of the shift register
    // on a seven-segment display, moving the light in a circle.


endmodule
