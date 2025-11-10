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
    // assign abcdefgh   = '0;
    // assign digit      = '0;
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire any_sw = | sw;

    localparam w_in = w_key > w_sw ? w_key : w_sw;

    wire [w_in - 1:0] in = any_sw ? w_in' (sw) : w_in' (key);

    //------------------------------------------------------------------------

    logic [19:0] cnt_e;

    always_ff @ (posedge clk)
        if (rst)
            cnt_e <= '0;
        else
            cnt_e <= cnt_e + 1'd1;

    // 2 ** 20 = (2 ** 10) * (2 ** 10) = 1024 * 1024 = approximate 1000000.
    // For 27 MHz clock:
    // 27 MHz 27000000 / 2 ** 20 = 27 times a cnt_e overflows.

    wire enable = (cnt_e == '0);

    //------------------------------------------------------------------------

    logic [w_x - 1:0] cnt1, cnt1_d;
    logic [w_y - 1:0] cnt2, cnt2_d;

    always_comb
    begin
        cnt1_d = (cnt1 == w_x' (screen_width - 1)) ? '0 : cnt1 + 1'd1;

        if (cnt2 == '0 | cnt2 == w_y' (screen_height - 1))
            cnt2_d = w_y' (screen_height / 2);
        else
            cnt2_d = cnt2 + w_y' (in [0]) - w_y' (| in [w_in - 1:1]);
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (rst)
        begin
            cnt1 <= '0;
            cnt2 <= w_y' (screen_height / 2);
        end
        else if (enable)
        begin
            cnt1 <= cnt1_d;
            cnt2 <= cnt2_d;
        end

    //------------------------------------------------------------------------

    logic       note_vld;
    logic [3:0] note_idx, sticky_note;

      note_recognizer
    # (.clk_mhz (clk_mhz))
    i_note_recognizer
    (
        .clk,
        .rst,

        .mic,

        .note_vld,
        .note_idx,

        .abcdefgh
    );

    assign digit = '1;

    always_ff @ (posedge clk)
        if (rst)
            sticky_note <= '1;
        else if (note_vld)
            sticky_note <= note_idx;

    //------------------------------------------------------------------------

    localparam w_xy = (w_x > w_y ? w_x : w_y) * 2;

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        case (sticky_note)
        4'd0, 4'd3, 4'd6, 4'd9:

            if (x < cnt1)
            begin
                red   = w_red'   ((x + y) >> 3);
                green = w_green' ((x - y) >> 3);
                blue  = w_blue'  ( x      >> 3);
            end

        4'd1, 4'd4, 4'd7, 4'd10:

            // if ((x - cnt1) * (y - cnt2) < w_xy' ((screen_width * screen_height) / 16))
            if (y > cnt2)
            begin
                red   = w_red'   (x >> 3);
                green = w_green' (y >> 3);
                blue  = '1;
            end

        4'd2, 4'd5, 4'd8, 4'd11:

            // if ((x - cnt1) ** 2 + (y - cnt2) ** 2 < w_xy' ((screen_width * screen_height) / 12))
            if (x + y < cnt1 + cnt2)
            begin
                red   = '1;
                green = '1;
                blue  = w_blue' ((x + y) >> 3);
            end

        default:

            begin
                if (x < cnt1)
                    red = '1;
                else
                    blue = '1;

                if (y < cnt2)
                    green = '1;
            end

        endcase
    end

endmodule
