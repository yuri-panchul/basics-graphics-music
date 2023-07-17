`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 20
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,

    // General-purpose Input/Output

    inout  logic [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led      = '0;
    // assign abcdefgh = '0;
    // assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;

    //------------------------------------------------------------------------

    wire [15:0] value = mic [23:8];

    //------------------------------------------------------------------------
    //
    //  Exercise 1: Uncomment this instantation
    //  to see the value coming from the microphone (in hexadecimal).
    //
    //------------------------------------------------------------------------

    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (value)), .*);

    //------------------------------------------------------------------------
    //
    //  Measuring frequency
    //
    //------------------------------------------------------------------------

    // It is enough for the counter to be 20 bit. Why?

    logic [15:0] prev_value;
    logic [19:0] counter;
    logic [19:0] distance;

    localparam [15:0] threshold = 16'h1100;

    // A way to investigate thresholds
    // wire [15:0] threshold = { ~ key_sw, 12'b0 };

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_value <= 16'h0;
            counter    <= 20'h0;
            distance   <= 20'h0;
        end
        else
        begin
            prev_value <= value;

            if (  value      >= threshold
                & prev_value < threshold)
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)  // To prevent overflow
            begin
               counter <= counter + 20'h1;
            end
        end

    //------------------------------------------------------------------------
    //
    //  Exercise 2: Uncomment this instantation
    //  to see the value of the counter.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (counter)), .*);

    //------------------------------------------------------------------------
    //
    //  Exercise 3: Uncomment this instantation
    //  to see the period of the sound wave coming from the microphone.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (distance [19:4])), .*);

    //------------------------------------------------------------------------
    //
    //  Determining the note
    //
    //------------------------------------------------------------------------

    `ifdef USE_STANDARD_FREQUENCIES

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
       high_distance = clk_mhz * 1000 * 1000 / freq_100 * 104;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);
       low_distance = clk_mhz * 1000 * 1000 / freq_100 * 96;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq_single_range (input [18:0] freq_100);

       check_freq_single_range =    distance > low_distance  (freq_100)
                                  & distance < high_distance (freq_100);
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq (input [18:0] freq_100);

       check_freq =   check_freq_single_range (freq_100 * 4)
                    | check_freq_single_range (freq_100 * 2)
                    | check_freq_single_range (freq_100);

    endfunction

    //------------------------------------------------------------------------

    wire check_C  = check_freq (freq_100_C );
    wire check_Cs = check_freq (freq_100_Cs);
    wire check_D  = check_freq (freq_100_D );
    wire check_Ds = check_freq (freq_100_Ds);
    wire check_E  = check_freq (freq_100_E );
    wire check_F  = check_freq (freq_100_F );
    wire check_Fs = check_freq (freq_100_Fs);
    wire check_G  = check_freq (freq_100_G );
    wire check_Gs = check_freq (freq_100_Gs);
    wire check_A  = check_freq (freq_100_A );
    wire check_As = check_freq (freq_100_As);
    wire check_B  = check_freq (freq_100_B );

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

    logic  [19:0] t_cnt;           // Threshold counter
    logic  [w_note - 1:0] t_note;  // Thresholded note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_cnt <= 0;
        else
            if (note == d_note)
                t_cnt <= t_cnt + 1;
            else
                t_cnt <= 0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_note <= no_note;
        else
            if (& t_cnt)
                t_note <= d_note;

    //------------------------------------------------------------------------
    //
    //  The output to seven segment display
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            abcdefgh <= 8'b00000000;
        else
            case (t_note)
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
            default : abcdefgh <= 8'b00000000;
            endcase

    assign digit = w_digit' (1);

    //------------------------------------------------------------------------
    //
    //  Exercise 4: Replace filtered note with unfiltered note.
    //  Do you see the difference?Uncomment this instantation
    //
    //------------------------------------------------------------------------

endmodule
