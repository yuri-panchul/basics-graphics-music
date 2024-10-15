`include "config.svh"

// Enable a period-averaging note filter instead of a time-based one
`define NOTE_PERIOD_COUNTING_AVERAGING_FILTER


module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------
    //
    //  Exercise 1: Uncomment this instantation
    //  to see the value coming from the microphone (in hexadecimal).
    //  Comment out a "The output to seven segment display" section below.
    //
    //------------------------------------------------------------------------

    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (mic)), .*);

    //------------------------------------------------------------------------
    //
    //  Measuring frequency
    //
    //------------------------------------------------------------------------

    // Filter out noise by averaging over several periods of the wave.
    `ifdef NOTE_PERIOD_COUNTING_AVERAGING_FILTER

    // It is enough for the counter to be 24 bit. Why?

    logic [23:0] prev_mic;
    logic [23:0] counter;
    localparam int w_period_count = $clog2(440/4); // Measure 440 Hz note ~4 times a second
    logic [w_period_count - 1:0] period_counter; // average over several wave periods
    logic [19:0] distance;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic <= '0;
            counter  <= '0;
            period_counter <= '0;
            distance <= '0;
        end
        else
        begin
            prev_mic <= mic;

            // Crossing from negative to positive numbers

            if (  prev_mic [$left ( prev_mic )] == 1'b1
                & mic      [$left ( mic      )] == 1'b0 )
            begin
                period_counter = period_counter + 1'b1;
                if (& period_counter)
                begin
                    distance <= counter / (1 << w_period_count); // estimate cycles per period
                    counter <= '0;
                end
                else
                    counter <= counter + 1'b1;
            end
            else if (counter != '1)  // To prevent overflow
                counter <= counter + 1'b1;
        end

    // Filter out noise by checking note value over a period of time.
    `else

    // It is enough for the counter to be 20 bit. Why?

    logic [23:0] prev_mic;
    logic [19:0] counter;
    logic [19:0] distance;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic <= '0;
            counter  <= '0;
            distance <= '0;
        end
        else
        begin
            prev_mic <= mic;

            // Crossing from negative to positive numbers

            if (  prev_mic [$left ( prev_mic )] == 1'b1
                & mic      [$left ( mic      )] == 1'b0 )
            begin
               distance <= counter;
               counter  <= '0;
            end
            else if (counter != '1)  // To prevent overflow
            begin
               counter <= counter + 1'b1;
            end
        end

    `endif

    //------------------------------------------------------------------------
    //
    //  Exercise 2: Uncomment this instantation
    //  to see the value of the counter.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (period_counter)), .*);

    //------------------------------------------------------------------------
    //
    //  Exercise 3: Uncomment this instantation
    //  to see the period of the sound wave in cycles coming from the microphone.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (distance)), .*);

    //------------------------------------------------------------------------
    //
    //  Exercise 4: Uncomment this instantation
    //  to see the frequency of the sound wave coming from the microphone.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (clk_mhz * 1000 * 1000 / distance)), .*);

    //------------------------------------------------------------------------
    //
    //  Determining the note
    //
    //------------------------------------------------------------------------

    `ifdef USE_STANDARD_FREQUENCIES

    // Standard note frequencies using A440 (Stuttgart pitch standard): https://en.wikipedia.org/wiki/A440_(pitch_standard)
    localparam freq_100_C  = 26163, // 261.63 Hz for 'C' note: https://en.wikipedia.org/wiki/C_(musical_note)
               freq_100_Cs = 27718, // 277.18 Hz for 'C#' note: https://en.wikipedia.org/wiki/C_(musical_note)
               freq_100_D  = 29366, // 293.66 Hz for 'D' note: https://en.wikipedia.org/wiki/D_(musical_note)
               freq_100_Ds = 31113, // 311.13 Hz for 'D#' note: https://en.wikipedia.org/wiki/D_(musical_note)
               freq_100_E  = 32963, // 329.63 Hz for 'E' note: https://en.wikipedia.org/wiki/E_(musical_note)
               freq_100_F  = 34923, // 349.23 Hz for 'F' note: https://en.wikipedia.org/wiki/F_(musical_note)
               freq_100_Fs = 36999, // 369.99 Hz for 'F#' note: https://en.wikipedia.org/wiki/F_(musical_note)
               freq_100_G  = 39200, // 392 Hz for 'G' note: https://en.wikipedia.org/wiki/G_(musical_note)
               freq_100_Gs = 41530, // 415.30 Hz for 'G#' note: https://en.wikipedia.org/wiki/G_(musical_note)
               freq_100_A  = 44000, // 440 Hz for 'A' note: https://en.wikipedia.org/wiki/A_(musical_note)
               freq_100_As = 46616, // 466.16 Hz for 'A#' note: https://en.wikipedia.org/wiki/A_(musical_note)
               freq_100_B  = 49388; // 493.88 Hz for 'B' note: https://en.wikipedia.org/wiki/B_(musical_note)
    `else

    // Custom measured frequencies

    localparam freq_100_C  = 26163,
               freq_100_Cs = 27718,
               freq_100_D  = 29366,
               freq_100_Ds = 31113,
               freq_100_E  = 32963,
               freq_100_F  = 34923,
               freq_100_Fs = 36999,
               freq_100_G  = 39200,
               freq_100_Gs = 41530,
               freq_100_A  = 44000,
               freq_100_As = 46616,
               freq_100_B  = 49388;
    `endif

    //------------------------------------------------------------------------

    function [19:0] high_distance (input [18:0] freq_100);
       high_distance = clk_mhz * 1000 * 1000 * 103 / freq_100;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);
       low_distance = clk_mhz * 1000 * 1000 * 97 / freq_100;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq_single_range (input [18:0] freq_100, input [19:0] distance);

       check_freq_single_range =    distance > low_distance  (freq_100)
                                  & distance < high_distance (freq_100);
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq (input [18:0] freq_100, input [19:0] distance);

       check_freq =   check_freq_single_range (freq_100 * 4 , distance)
                    | check_freq_single_range (freq_100 * 2 , distance)
                    | check_freq_single_range (freq_100     , distance)
                    | check_freq_single_range (freq_100 / 2 , distance);

    endfunction

    //------------------------------------------------------------------------

    wire check_C  = check_freq (freq_100_C  , distance );
    wire check_Cs = check_freq (freq_100_Cs , distance );
    wire check_D  = check_freq (freq_100_D  , distance );
    wire check_Ds = check_freq (freq_100_Ds , distance );
    wire check_E  = check_freq (freq_100_E  , distance );
    wire check_F  = check_freq (freq_100_F  , distance );
    wire check_Fs = check_freq (freq_100_Fs , distance );
    wire check_G  = check_freq (freq_100_G  , distance );
    wire check_Gs = check_freq (freq_100_Gs , distance );
    wire check_A  = check_freq (freq_100_A  , distance );
    wire check_As = check_freq (freq_100_As , distance );
    wire check_B  = check_freq (freq_100_B  , distance );

    //------------------------------------------------------------------------

    localparam w_note = 12;

    wire [w_note - 1:0] note = { check_C  , check_Cs , check_D  , check_Ds ,
                                 check_E  , check_F  , check_Fs , check_G  ,
                                 check_Gs , check_A  , check_As , check_B  };

    localparam [w_note - 1:0] no_note = 12'b0,

                              C  = 12'b1000_0000_0000,
                              Cs = 12'b0100_0000_0000,
                              D  = 12'b0010_0000_0000,
                              Ds = 12'b0001_0000_0000,
                              E  = 12'b0000_1000_0000,
                              F  = 12'b0000_0100_0000,
                              Fs = 12'b0000_0010_0000,
                              G  = 12'b0000_0001_0000,
                              Gs = 12'b0000_0000_1000,
                              A  = 12'b0000_0000_0100,
                              As = 12'b0000_0000_0010,
                              B  = 12'b0000_0000_0001;

    localparam [w_note - 1:0] Df = Cs, Ef = Ds, Gf = Fs, Af = Gs, Bf = As;

    //------------------------------------------------------------------------
    //
    //  Note filtering
    //
    //------------------------------------------------------------------------

    logic  [w_note - 1:0] d_note;  // Delayed note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            d_note <= no_note;
        else
            d_note <= note;

    localparam int w_t_cnt = $clog2(clk_mhz * 1000 * 1000 / 10); // Filter ~N times a second
    logic  [w_t_cnt - 1:0] f_cnt;         // Filter counter
    logic  [w_note - 1:0] filtered_note;  // Filtered note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            f_cnt <= '0;
        else
            if (note == d_note)
                f_cnt <= f_cnt + 1'b1; // Increase the counter if note has not changed
            else
                f_cnt <= '0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            filtered_note <= no_note;
        else
            if (& f_cnt)
                filtered_note <= d_note; // If the counter is full, update the filtered note

    //------------------------------------------------------------------------
    //
    //  The output to seven segment display
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            abcdefgh <= 8'b00000000;
        else
            case (filtered_note)
            C  : abcdefgh <= 8'b10011100;  // C   // abcdefgh
            Cs : abcdefgh <= 8'b10011101;  // C#
            D  : abcdefgh <= 8'b01111010;  // D   //   --a--
            Ds : abcdefgh <= 8'b01111011;  // D#  //  |     |
            E  : abcdefgh <= 8'b10011110;  // E   //  f     b
            F  : abcdefgh <= 8'b10001110;  // F   //  |     |
            Fs : abcdefgh <= 8'b10001111;  // F#  //   --g--
            G  : abcdefgh <= 8'b10111100;  // G   //  |     |
            Gs : abcdefgh <= 8'b10111101;  // G#  //  e     c
            A  : abcdefgh <= 8'b11101110;  // A   //  |     |
            As : abcdefgh <= 8'b11101111;  // A#  //   --d--  h
            B  : abcdefgh <= 8'b00111110;  // B
            default : abcdefgh <= 8'b00000000; // Invalid notes
            endcase

    assign digit = w_digit' (1);

    //------------------------------------------------------------------------
    //
    //  Exercise 5: Replace filtered note with unfiltered note.
    //  Do you see the difference?
    //
    //------------------------------------------------------------------------

endmodule
