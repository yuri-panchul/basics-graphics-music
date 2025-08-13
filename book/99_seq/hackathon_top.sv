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
    // Counter with a slow 1 Hz clock (one beat per second)
/*
    wire reset_from_key = key [0];

    logic [31:0] counter;

    always_ff @ (posedge slow_clock)
        if (reset_from_key)
            counter <= 0;
        else
            counter <= counter + 1;

    assign led = counter [7:0];
*/
    //------------------------------------------------------------------------
    //  Output to the 7-segment display

    /*
    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock    ),
        .rst      ( reset    ),
        .number   ( counter  ),
        .dots     ( '0       ),  // This syntax means "all 0s in the context"
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );
    */

    //------------------------------------------------------------------------
    // A free running counter with a 27 MHz clock.
    // Comment out the code above and uncomment the code below.
    //
    // Exercise 1:
    //
    // How do you change the speed of LED blinking?
    // Try different bit slices to display.

    logic [19:0] counter;

    always_ff @ (posedge clock)
        if (reset)
            counter <= 0;
        else
            counter <= counter + 1;

    // assign led = counter [23:16];  // Try to put [23:16] here

    logic [9:0] counter2;

// 2 * 2 * 2 = 8
// 2 ** 10 == 1024
// 2 ** 20 == 1024 * 1024 = approximate 1000000

// 27 MHz 27000000 / 2 ** 20 = 27

    always_ff @ (posedge clock)
        if (reset)
            counter2 <= 0;
        else if (counter == 0)
        begin
            if (counter2 > 480)
                counter2 = 0;
            else
                counter2 <= counter2 + 1;
        end

    logic [9:0] c3;

    always_ff @ (posedge clock)
        if (reset)
            c3 <= 0;
        else if (counter == 0)
        begin
            if (c3 > 272)
                c3 = 0;
            else
                c3 <= c3 + 10;
        end


    always_comb
    begin    
        red = 0;
        blue = 0;
        green = 0;

        if (x > counter2)
            red = 31;

        if (y > c3)
            green = x;

        if (x * x + y * y < 10000)
            blue = 31;
    end



    // assign led = counter >> 20;  // Try alternative way to shift the value

    // Try to add "if (key)" after "else".

    //------------------------------------------------------------------------
    // Exercise 2: Key-controlled counter.
    // Comment out the code above.
    // Uncomment and synthesize the code below.
    // Press the key to see the counter incrementing.
    //
    // Change the design, for example:
    //
    // 1. One key is used to increment, another to decrement.
    //
    // 2. Two counters controlled by different keys
    // displayed in different groups of LEDs.

endmodule
