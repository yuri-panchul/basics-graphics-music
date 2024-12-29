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
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    // Truncate used SW number to 8
    localparam w_sw_actual = (w_sw > 8) ? 8
                                        : w_sw;

    //------------------------------------------------------------------------


    logic [w_sw_actual-1:0] input_stage_0_ff;
    logic [w_sw_actual-1:0] input_stage_1_ff;
    logic [w_sw_actual-1:0] input_stage_2_ff;
    logic [w_sw_actual-1:0] input_stage_3_ff;
    logic [w_sw_actual-1:0] input_stage_4_ff;
    logic [w_sw_actual-1:0] input_stage_5_ff;
    logic [w_sw_actual-1:0] input_stage_6_ff;

    logic [w_sw_actual+1:0] summ_stage_0_ff;
    logic [w_sw_actual+1:0] summ_stage_1_ff;
    logic [w_sw_actual+1:0] summ_stage_2_ff;
    logic [w_sw_actual+1:0] summ_stage_3_ff;

    logic [w_sw_actual-1:0] filter_output;

    // Data pipeline
    always_ff @ (posedge slow_clk or posedge rst)
        if (rst) begin
            input_stage_0_ff <= '0;
            input_stage_1_ff <= '0;
            input_stage_2_ff <= '0;
            input_stage_3_ff <= '0;
            input_stage_4_ff <= '0;
            input_stage_5_ff <= '0;
            input_stage_6_ff <= '0;
        end
        else begin
            input_stage_0_ff <= sw;
            input_stage_1_ff <= input_stage_0_ff;
            input_stage_2_ff <= input_stage_1_ff;
            input_stage_3_ff <= input_stage_2_ff;
            input_stage_4_ff <= input_stage_3_ff;
            input_stage_5_ff <= input_stage_4_ff;
            input_stage_6_ff <= input_stage_5_ff;
        end


    always_ff @ (posedge slow_clk or posedge rst)
        if (rst) begin
            summ_stage_0_ff <= '0;
            summ_stage_1_ff <= '0;
            summ_stage_2_ff <= '0;
            summ_stage_3_ff <= '0;
        end
        else begin
            summ_stage_0_ff <= input_stage_0_ff; // + 0
            summ_stage_1_ff <= summ_stage_0_ff + input_stage_2_ff;
            summ_stage_2_ff <= summ_stage_1_ff + input_stage_4_ff;
            summ_stage_3_ff <= summ_stage_2_ff + input_stage_6_ff;
        end


    assign filter_output = summ_stage_3_ff >> 2;


    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                               ),
        .rst      ( rst                               ),
        .number   ( w_display_number' (filter_output) ),
        .dots     ( w_digit' (0)                      ),
        .abcdefgh ( abcdefgh                          ),
        .digit    ( digit                             )
    );


endmodule
