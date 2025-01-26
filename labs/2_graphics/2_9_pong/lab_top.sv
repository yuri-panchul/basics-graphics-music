/*
 * Pong game by Allen Baker (botbakery.net)
 * 
 * Controls:
 * Player 1 (left): SW1 = down, SW2 = up
 * Player 2 (right): SW7 = down, SW8 = up
 */

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

    assign abcdefgh = 8'd0;
    assign digit = 8'd0;

    wire [w_x-1:0]            pix_x;
    wire [w_y-1:0]            pix_y;
    assign pix_x = x;
    assign pix_y = y;

    logic [w_red-1:0]             R;
    logic [w_green-1:0]           G;
    logic [w_blue-1:0]            B;
    assign red = R;
    assign green = G;
    assign blue = B;

    assign sound = 16'd0;

    assign led = {w_led{1'b0}};

    assign uart_tx = 1'b0;

    logic                 pulse;
    strobe_gen
    # (
        .clk_mhz   ( clk_mhz ),
        .strobe_hz ( 30      )
    )
    i_strobe_gen   (clk, rst, pulse);

    localparam                lcd_width = screen_width;
    localparam                lcd_height = screen_height;

    localparam                player_width = 30;
    localparam                player_height = 80;
    localparam                player_init_offset = (lcd_height / 2) - (player_height / 2);

    localparam                p1_left_bound = 0;
    localparam                p1_right_bound = player_width;
    localparam                p1_upper_bound = 0;
    localparam                p1_lower_bound = player_height;

    localparam                p2_left_bound = lcd_width - player_width;
    localparam                p2_right_bound = lcd_width;
    localparam                p2_upper_bound = 0;
    localparam                p2_lower_bound = player_height;

    localparam                ball_width = 20;
    localparam                ball_height = 20;
    localparam                ball_x_init = (lcd_width / 2) - (ball_width / 2);
    localparam                ball_y_init = (lcd_height / 2) + (ball_height / 2);

    localparam [w_y-1:0]          player_speed = 'd15;
    localparam [w_y-1:0]          ball_speed = 'd7;

    logic [w_y-1:0]           p1_offset;
    logic [w_y-1:0]           p2_offset;
    logic [w_x-1:0]           ball_x_offset;
    logic [w_y-1:0]           ball_y_offset;
    logic                 ball_x_fwd;
    logic                 ball_y_fwd;

    function logic [w_y-1:0] get_player_offset(input up,
             input       down,
             input [w_y-1:0] current_offset);
        if (down)
        begin
            if (current_offset < (lcd_height - player_height))
                get_player_offset = current_offset + player_speed;
            else
            get_player_offset = current_offset;
        end
        else if (up)
        begin
            if (current_offset > player_speed)
                get_player_offset = current_offset - player_speed;
            else
                get_player_offset = current_offset;
        end
        else
            get_player_offset = current_offset;
    endfunction // get_player_offset

    function logic [w_x-1:0] get_ball_x_offset(input [w_x-1:0] current_offset);
        if (ball_x_fwd)
        begin
            if (current_offset < (lcd_width - ball_width))
                get_ball_x_offset = current_offset + ball_speed;
            else
                get_ball_x_offset = current_offset;
        end
        else
        begin
            if (current_offset > 0)
                get_ball_x_offset = current_offset - ball_speed;
            else
                get_ball_x_offset = current_offset;
        end
    endfunction // get_ball_x_offset

    function logic [w_y-1:0] get_ball_y_offset(input [w_y-1:0] current_offset);
        if (ball_y_fwd)
        begin
            if (current_offset < (lcd_height - ball_height))
                get_ball_y_offset = current_offset + ball_speed;
            else
                get_ball_y_offset = current_offset;
        end
        else
        begin
            if (current_offset > 0)
                get_ball_y_offset = current_offset - ball_speed;
            else
                get_ball_y_offset = current_offset;
        end
    endfunction // get_ball_y_offset

    // Game objects
    logic  at_p1;
    assign at_p1 = (pix_x > p1_left_bound) &&
          (pix_x < p1_right_bound) &&
          (pix_y > (p1_offset + p1_upper_bound)) &&
          (pix_y < (p1_offset + p1_lower_bound));
    logic  at_p2;
    assign at_p2 = (pix_x > p2_left_bound) &&
          (pix_x < p2_right_bound) &&
          (pix_y > (p2_offset + p2_upper_bound)) &&
          (pix_y < (p2_offset + p2_lower_bound));
    logic  at_ball;
    assign at_ball = (pix_x > ball_x_offset) &&
          (pix_x < (ball_x_offset + ball_width)) &&
          (pix_y > ball_y_offset) &&
          (pix_y < (ball_y_offset + ball_width));
    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            p1_offset <= player_init_offset;
            p2_offset <= player_init_offset;
            ball_x_offset <= ball_x_init;
            ball_y_offset <= ball_y_init;
            ball_x_fwd <= 1;
            ball_y_fwd <= 1;
        end
        else if (pulse)
        begin
            if (w_key > 1)
            begin : gen_multi_keys
            p1_offset <= get_player_offset(key[w_key - 2], key[w_key - 1], p1_offset);
            p2_offset <= get_player_offset(key[0], key[1], p2_offset);
            end
            else if (w_key == 1)
            begin : gen_one_key
            p1_offset <= get_player_offset(~key[0], key[0], p1_offset);
            p2_offset <= get_player_offset(~key[0], key[0], p2_offset);
            end
            ball_x_offset <= get_ball_x_offset(ball_x_offset);
            ball_y_offset <= get_ball_y_offset(ball_y_offset);

        // Ball interaction
            if ((ball_x_offset >= (lcd_width - ball_width)) || !ball_x_offset)
            begin
        // Score
            p1_offset <= player_init_offset;
            p2_offset <= player_init_offset;
            ball_x_offset <= ball_x_init;
            ball_y_offset <= ball_y_init;
            ball_x_fwd <= 1;
            ball_y_fwd <= 1;
            end
            if (ball_y_offset >= (lcd_height - ball_height))
            begin
        // Bounce ball off bottom
            ball_y_fwd <= 0;
            end
            if ((ball_y_offset + 1) < ball_height)
            begin
          // Bounce ball off top
            ball_y_fwd <= 1;
            end
            if (((ball_x_offset + ball_width + 1) >= p2_left_bound) &&
          ((((ball_y_offset + ball_height) >= (p2_offset + p2_upper_bound)) && // Ball lower edge contact
            ((ball_y_offset + ball_height) <= (p2_offset + p2_lower_bound))) ||
            ((ball_y_offset >= (p2_offset + p2_upper_bound)) && // Ball upper edge contact
             (ball_y_offset <= (p2_offset + p2_upper_bound)))))
            begin
        // Bounce ball off P2 paddle
            ball_x_fwd <= 0;
            end
            if (((ball_x_offset - 1) <= p1_right_bound) &&
          ((((ball_y_offset + ball_height) >= (p1_offset + p1_upper_bound)) && // Ball lower edge contact
            ((ball_y_offset + ball_height) <= (p1_offset + p1_lower_bound))) ||
            ((ball_y_offset >= (p1_offset + p1_upper_bound)) && // Ball upper edge contact
             (ball_y_offset <= (p1_offset + p1_upper_bound)))))
            begin
        // Bounce ball off P1 paddle
            ball_x_fwd <= 1;
            end
        end
    end

    always_comb
    begin
    if (at_p1 || at_p2 || at_ball)
        begin
            R = {w_red  {1'b1}};
            G = {w_green{1'b1}};
            B = {w_blue {1'b1}};
        end
    else
        begin
            R = 0;
            G = 0;
            B = 0;
        end
    end

endmodule // lab_top
