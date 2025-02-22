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

    logic enable;

    strobe_gen # (.clk_mhz (27), .strobe_hz (100))
    i_strobe_gen (clock, reset, enable);

    //------------------------------------------------------------------------
    //
    //  Finite State Machine (FSM) for the game

    localparam [2:0]
        STATE_START = 0,
        STATE_AIM   = 1,
        STATE_SHOOT = 2,
        STATE_WON   = 3,
        STATE_LOST  = 4;

    logic [2:0] state, new_state;

    //------------------------------------------------------------------------

    // Conditions to change the state - declarations

    logic out_of_screen, collision, launch, timeout;

    //------------------------------------------------------------------------

    always_comb
    begin
        new_state = state;

        case (state)

        STATE_START : new_state =                   STATE_AIM;

        STATE_AIM   : new_state =   out_of_screen ? STATE_LOST
                                  : collision     ? STATE_WON
                                  : launch        ? STATE_SHOOT
                                  : timeout       ? STATE_SHOOT
                                  :                 STATE_AIM;

        STATE_SHOOT : new_state =   out_of_screen ? STATE_LOST
                                  : collision     ? STATE_WON
                                  :                 STATE_SHOOT;

        STATE_WON   : new_state =   timeout       ? STATE_START
                                  :                 STATE_WON;

        STATE_LOST  : new_state =   timeout       ? STATE_START
                                  :                 STATE_LOST;

        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clock)
        if (reset)
            state <= STATE_START;
        else if (enable)
            state <= new_state;

    //------------------------------------------------------------------------
    //
    //  Computing new object coordinates

    logic [8:0] x0,  y0,  x1,  y1,
                x0r, y0r, x1r, y1r;

    wire left  = | key [6:1];
    wire right =   key [0];

    always_comb
    begin
        x0 = x0r;
        y0 = y0r;
        x1 = x1r;
        y1 = y1r;

        if (state == STATE_START)
        begin
            x0 = start_0_x;
            y0 = start_0_y;
            x1 = start_1_x;
            y1 = start_1_y;
        end
        else
        begin
            x0 = x0 + 1;

            if (state == STATE_SHOOT)
            begin
                x1 = x1 + right - left;
                y1 = y1 - 1;
            end
        end
    end

    //------------------------------------------------------------------------
    //
    //  Updating object coordinates

    always_ff @ (posedge clock)
        if (reset)
        begin
            x0r <= 0;
            y0r <= 0;
            x1r <= 0;
            y1r <= 0;
        end
        else if (enable)
        begin
            x0r <= x0;
            y0r <= y0;
            x1r <= x1;
            y1r <= y1;
        end

    //------------------------------------------------------------------------
    //
    // Conditions to change the state - implementations

    assign out_of_screen =   x0 == screen_width
                           | x1 == 0
                           | x1 == screen_width
                           | y1 == 0;

    assign collision = ~ (  x0 + wx <= x1
                          | x1 + wx <= x0
                          | y0 + wy <= y1
                          | y1 + wy <= y0 );

    assign launch = left | right;

    //------------------------------------------------------------------------
    //
    // Timeout condition

    logic [7:0] timer;

    always_ff @ (posedge clock)
        if (reset)
            timer <= 0;
        else if (state == STATE_START)
            timer <= 200;
        else if (state == STATE_SHOOT)
            timer <= 100;
        else if (enable)
            timer <= timer - 1;

    assign timeout = (timer == 0);

    //------------------------------------------------------------------------
    //
    //  Determine pixel color

    //------------------------------------------------------------------------

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        // verilator lint_off CASEINCOMPLETE

        case (state)

        STATE_WON:
        begin
            red = max_red;
        end

        STATE_LOST:
        begin
            red   = max_red;
            green = max_green;
        end

        default:
        begin
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

        endcase

        // verilator lint_on CASEINCOMPLETE
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
        .dots     ( '0       ),  // This syntax means "all 0s in the context"
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
