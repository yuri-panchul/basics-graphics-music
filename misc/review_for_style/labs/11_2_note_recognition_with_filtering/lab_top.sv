`include "config.svh"
`define ENABLE_TP1638
`define USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
`define ENABLE_INMP441

module lab_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 100
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

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,
    input                        mic_ready,
    output       [         15:0] sound,

    // UART
    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
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
       assign sound    = '0;
       assign uart_tx  = '1;

    //------------------------------------------------------------------------
    //
    //  Measuring frequency
    //
    //------------------------------------------------------------------------

    // It is enough for the counter to be 20 bit. Why?

    logic [23:0] prev_mic;
    logic [19:0] counter;
    logic [19:0] distance_avg[4];
    logic [19:0] distance;
    logic [23:0] mic_avg[4];


    localparam level_thrshld = 'h0100;    // Defines min audio level to enable detection
    localparam distance_filter_order = 3; // Defines filter order for distance, should be 0 - 3

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic        <= '0;
            counter         <= '0;
            distance        <= '0;
            distance_avg[0] <= '0;
            distance_avg[1] <= '0;
            distance_avg[2] <= '0;
            distance_avg[3] <= '0;
            mic_avg[0]      <= '0;
            mic_avg[1]      <= '0;
            mic_avg[2]      <= '0;
            mic_avg[3]      <= '0;
        end
        else
        begin
            if (counter != ~ 20'h0)  // To prevent overflow
                counter <= counter + 20'h1;

            if (mic_ready && ~mic[23])
                begin
                    // Poor man's averaging: shift and sum positive values
                    // i.e. mic_avg[x] = mic_avg[x]/2 + mic_avg[x-1]/2
                    mic_avg[0] <= {1'b0, mic_avg[0][23:1]} + {1'b0, mic[23:1]};
                    mic_avg[1] <= {1'b0, mic_avg[1][23:1]} + {1'b0, mic_avg[0][23:1]};
                    mic_avg[2] <= {1'b0, mic_avg[2][23:1]} + {1'b0, mic_avg[1][23:1]};
                    mic_avg[3] <= {1'b0, mic_avg[3][23:1]} + {1'b0, mic_avg[2][23:1]};
                end

            if(mic_avg[3] > level_thrshld)
                begin
                    prev_mic <= mic;

                    // Crossing from negative to positive numbers

                    if (  prev_mic [$left ( prev_mic )] == 1'b1
                        & mic      [$left ( mic      )] == 1'b0 )
                    begin
                       distance_avg[0] <= {1'b0, distance_avg[0] [19:1]} + {1'b0, counter [19:1]};
                       distance_avg[1] <= {1'b0, distance_avg[1] [19:1]} + {1'b0, distance_avg[0] [19:1]};
                       distance_avg[2] <= {1'b0, distance_avg[2] [19:1]} + {1'b0, distance_avg[1] [19:1]};
                       distance_avg[3] <= {1'b0, distance_avg[3] [19:1]} + {1'b0, distance_avg[2] [19:1]};
                       distance <= distance_avg[distance_filter_order];
                       counter  <= 20'h0;
                    end
                 end
        end



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
       high_distance = clk_mhz * 1000 * 1000 / freq_100 * 103;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);
       low_distance = clk_mhz * 1000 * 1000 / freq_100 * 97;
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
                    | check_freq_single_range (freq_100     , distance);

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
    //  Display current note and audio level on 7-seg display (8 digits)
    //
    //  The note will be shown in highest (8's) digit
    //
    //------------------------------------------------------------------------

    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;


    logic [w_number - 1:0] number;

    seven_segment_display # (w_digit, clk_mhz, 16)
    i_7segment (.number (w_number' (number)), .*);

    // Since display module accepts only hex number we need
    // to translate note to hex digit

    function [3:0] note_to_disp (input [w_note - 1:0] note);
        case (note)
        12'b1000_0000_0000: note_to_disp = 4'hc;
        12'b0100_0000_0000: note_to_disp = 4'hb;
        12'b0010_0000_0000: note_to_disp = 4'ha;
        12'b0001_0000_0000: note_to_disp = 4'h9;
        12'b0000_1000_0000: note_to_disp = 4'h8;
        12'b0000_0100_0000: note_to_disp = 4'h7;
        12'b0000_0010_0000: note_to_disp = 4'h6;
        12'b0000_0001_0000: note_to_disp = 4'h5;
        12'b0000_0000_1000: note_to_disp = 4'h4;
        12'b0000_0000_0100: note_to_disp = 4'h3;
        12'b0000_0000_0010: note_to_disp = 4'h2;
        12'b0000_0000_0001: note_to_disp = 4'h1;
        default:            note_to_disp = 4'h0;
        endcase
    endfunction


    always_ff @ (posedge clk)
        if(!key[0])
            if(mic_avg[3] > level_thrshld)
                number <= {note_to_disp(t_note), 4'd0, 24'(mic_avg[3])};
                /* Uncomment below to see distance instead of audio level */
                //number <= {note_to_disp(t_note), 4'd0, 24'(distance_avg[3])};
            else
                number <= {note_to_disp(t_note), 4'd0, 24'(0)};


endmodule

