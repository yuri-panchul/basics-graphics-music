// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
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
    //
    //  Screen, object and color constants

    localparam screen_width  = 480,
               screen_height = 272,

               wx            = 30,
               wy            = 30,
               
               start_0_x     = 0,
               start_0_y     = screen_height     / 5,

               start_1_x     = screen_width      / 2,
               start_1_y     = screen_height * 4 / 5,

               max_red       = 31,
               max_green     = 63,
               max_blue      = 31;

    //------------------------------------------------------------------------
    //
    //  Pulse generator, 50 times a second

    logic pulse;

    strobe_gen # (.clk_mhz (27), .strobe_hz (80))
    i_strobe_gen (clock, reset, pulse);

    //------------------------------------------------------------------------
    //
    //  Finite State Machine (FSM) for the game

    enum bit [2:0]
    {
        STATE_START = 0,
        STATE_AIM   = 1,
        STATE_SHOOT = 2,
        STATE_WON   = 3,
        STATE_LOST  = 4
    }
    state, new_state;

    //------------------------------------------------------------------------

    // Conditions to change the state - declarations

    logic out_of_screen, collision, launch;

    //------------------------------------------------------------------------

    always_comb
    begin
        new_state = state;
        
        case (state)

        STATE_START : new_state =                   STATE_AIM;

        STATE_AIM   : new_state =   out_of_screen ? STATE_LOST
                                  : collision     ? STATE_WON
                                  : launch        ? STATE_SHOOT
                                  :                 STATE_AIM;

        STATE_SHOOT : new_state =   out_of_screen ? STATE_LOST
                                  : collision     ? STATE_WON
                                  :                 STATE_SHOOT;

        STATE_WON   : new_state = STATE_START;
        STATE_LOST  : new_state = STATE_START;

        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clock)
        if (reset)
            state <= STATE_START;
        else if (pulse)
            state <= new_state;

    //------------------------------------------------------------------------
    //
    //  Computing new object coordinates

    logic [8:0] x0,  y0,  x1,  y1,
                x0r, y0r, x1r, y1r;

    wire left  = | key [6:4];
    wire right = | key [3:0];

    always_comb
    begin
        x0 = x0r;
        y0 = y0r;
        x1 = x1r;
        y1 = y1r;

        if (state == STATE_START)
            x0 = 0;
        else
            x0 = x0 + 1;

        x1 = x1 + right - left;
            
        if (y1 == 0)
            y1 = start_1_y;
        else if (left & right & y1 > 1)
            y1 = y1 - 2;
        else
            y1 = y1 - 1;
    end
    
    //------------------------------------------------------------------------
    //
    //  Updating object coordinates

    always_ff @ (posedge clock)
        if (reset)
        begin
            x0r <= start_0_x;
            y0r <= start_0_y;
            x1r <= start_1_x;
            y1r <= start_1_y;
        end
        else if (pulse)
        begin
            x0r <= x0;
            y0r <= y0;
            x1r <= x1;
            y1r <= y1;
        end

    //------------------------------------------------------------------------

    // Conditions to change the state - implementations

    logic out_of_screen, collision, launch;

    //------------------------------------------------------------------------
    //
    //  Determine pixel color

    //------------------------------------------------------------------------

    always_comb
    begin
        red = 0; green = 0; blue = 0;

        if (  x >= x0 & x < x0 + wx
            & y >= y0 & y < y0 + wy)
        begin
            blue = max_blue;
        end

        if (  x >= x1 & x < x1 + wx
            & y >= y1 & y < y1 + wy)
        begin
            red = max_red;
        end
    end

    //------------------------------------------------------------------------
    //
    //  Output to LED and 7-segment display

    assign led = x1;

    wire [31:0] number
        = key [7] ? { 7'b0, x0, 7'b0, y0 }
                  : { 7'b0, x1, 7'b0, y1 };
    
    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock    ),
        .rst      ( reset    ),
        .number   ( number   ),
        .dots     ( 0        ),
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
