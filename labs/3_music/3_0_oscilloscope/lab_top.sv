`include "config.svh"

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

    assign led        = '0;
    assign abcdefgh   = '0;
    assign digit      = '0;
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
    assign sound      = '0;
    assign uart_tx    = '1;
    
    logic                   white;
    assign red   = {w_red  {white}};
    assign green = {w_green{white}};
    assign blue  = {w_blue {white}};


    //------------------------------------------------------------------------
    //
    //  Oscilloscope
    //
    //------------------------------------------------------------------------
    localparam                  mic_shift = 18 - w_y;
    localparam signed [23:0]    mic_min =-((screen_height-4)<<mic_shift) / 2;
    localparam signed [23:0]    mic_max = ((screen_height)<<mic_shift) / 2;
    localparam signed [w_y-1:0] midy = screen_height / 2;

    // It is enough for the counter to be 20 bit. Why?
    logic        [23:0]    prev_mic;
    wire  signed [23:0]    mics = ($signed(mic)<mic_min)? mic_min : (($signed(mic)>mic_max)? mic_max : mic);
    logic        [19:0]    counter;
    logic        [19:0]    distance;
    logic signed [w_y-1:0] bufy[screen_width/2];
    logic        [w_x-1:0] vldx;                        // validity of bufy elements
    wire  signed [w_y-1:0] micy = mics >>> mic_shift;
    // Another way:        micy = {mic[23], (mic[23]?~&mic[22:16]:|mic[22:16])? ~{(w_y-1){$signed(mic[23])}} : mic[15-:w_y-1]};
    wire         [w_x-1:0] cntx = counter[19-:w_x];
    wire                   cntx_in_buf = cntx < screen_width / 2;
    
    // Excercise 1: Implement Zoom by x-axis with keys
    // Excercise 2: Optimize to reduce bits of bufy
    assign white = x <= vldx                            // Design practice: Check if element of bufy is initialized
            && (x>>2) <  (distance[19-:w_x])
            && (y>>3) == (midy - bufy[(x>>2)])>>3       // draw bolder lines with shift by 3 bits
            && x < screen_width && y < screen_height;   // do not draw outside the screen

    always_ff @ (posedge clk)                           // Design practice: Separate always_ff blocks with reset and without
        if (cntx_in_buf)
            bufy[cntx] <= micy;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic <= '0;
            counter  <= '0;
            distance <= '0;
            vldx     <= '0;
        end
        else
        begin
            if (vldx < cntx)
                vldx <= cntx;

            prev_mic <= mic;

            // Crossing from negative to positive numbers
            if (  prev_mic [$left ( prev_mic )] == 1'b1
                & mic      [$left ( mic      )] == 1'b0 )
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)  // To prevent overflow
            begin
               counter <= counter + 20'h1;
            end
        end

endmodule
