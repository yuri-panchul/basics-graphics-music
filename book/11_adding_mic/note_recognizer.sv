`include "config.svh"

module note_recognizer
# (
    parameter clk_mhz = 50
)
(
    input               clk,
    input               rst,

    input        [23:0] mic,

    output logic        note_vld,
    output logic [ 3:0] note_idx,

    output logic [ 7:0] abcdefgh   // for the seven-segment display
);

    //------------------------------------------------------------------------
    //
    //  Measuring frequency
    //
    //------------------------------------------------------------------------

    // It is enough for the counter to be 20 bit. Why?

    logic [23:0] prev_mic;
    logic [19:0] counter;
    logic [19:0] distance;

    always_ff @ (posedge clk)
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
               counter <= counter + 1'd1;
            end
        end

    //------------------------------------------------------------------------
    //
    //  Determining the note
    //
    //------------------------------------------------------------------------

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

    //------------------------------------------------------------------------

    function [19:0] high_distance (input [18:0] freq_100);
       high_distance = clk_mhz * 1000 * 1000 / freq_100 * 103;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);
       low_distance = clk_mhz * 1000 * 1000 / freq_100 * 97;
    endfunction

    //------------------------------------------------------------------------

    function check_freq_single_range (input [18:0] freq_100, input [19:0] distance);

       check_freq_single_range =    distance > low_distance  (freq_100)
                                  & distance < high_distance (freq_100);
    endfunction

    //------------------------------------------------------------------------

    function check_freq (input [18:0] freq_100, input [19:0] distance);

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

    always_ff @ (posedge clk)
        if (rst)
            d_note <= no_note;
        else
            d_note <= note;

    logic  [19:0] t_cnt;           // Threshold counter
    logic  [w_note - 1:0] t_note;  // Thresholded note

    always_ff @ (posedge clk)
        if (rst)
            t_cnt <= '0;
        else
            if (note == d_note)
                t_cnt <= t_cnt + 1'd1;
            else
                t_cnt <= '0;

    always_ff @ (posedge clk)
        if (rst)
            t_note <= no_note;
        else
            if (& t_cnt)
                t_note <= d_note;

    //------------------------------------------------------------------------
    //
    //  Encoding the output
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (rst)
            note_vld <= 1'b0;
        else
            case (t_note)
            C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B:
                      note_vld <= 1'b1;
            default : note_vld <= 1'b0;
            endcase

    always_ff @ (posedge clk)
        case (t_note)
        C  : note_idx <= 4'h0;
        Cs : note_idx <= 4'h1;
        D  : note_idx <= 4'h2;
        Ds : note_idx <= 4'h3;
        E  : note_idx <= 4'h4;
        F  : note_idx <= 4'h5;
        Fs : note_idx <= 4'h6;
        G  : note_idx <= 4'h7;
        Gs : note_idx <= 4'h8;
        A  : note_idx <= 4'h9;
        As : note_idx <= 4'ha;
        B  : note_idx <= 4'hb;
        endcase

    always_ff @ (posedge clk)
        if (rst)
            abcdefgh <= 8'b00000010;
        else
            case (t_note)
            C       : abcdefgh <= 8'b10011100;  // C   // abcdefgh
            Cs      : abcdefgh <= 8'b10011101;  // C#
            D       : abcdefgh <= 8'b01111010;  // D   //   --a--
            Ds      : abcdefgh <= 8'b01111011;  // D#  //  |     |
            E       : abcdefgh <= 8'b10011110;  // E   //  f     b
            F       : abcdefgh <= 8'b10001110;  // F   //  |     |
            Fs      : abcdefgh <= 8'b10001111;  // F#  //   --g--
            G       : abcdefgh <= 8'b10111100;  // G   //  |     |
            Gs      : abcdefgh <= 8'b10111101;  // G#  //  e     c
            A       : abcdefgh <= 8'b11101110;  // A   //  |     |
            As      : abcdefgh <= 8'b11101111;  // A#  //   --d--  h
            B       : abcdefgh <= 8'b00111110;  // B
            default : abcdefgh <= 8'b00000010;
            endcase

endmodule
