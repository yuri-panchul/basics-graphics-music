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

    // assign led        = '0;
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



    logic [(2*w_sw_actual)-1:0] pow_mul_stage_1;
    logic [(3*w_sw_actual)-1:0] pow_mul_stage_2;
    logic [(4*w_sw_actual)-1:0] pow_mul_stage_3;
    logic [(5*w_sw_actual)-1:0] pow_mul_stage_4;

    logic [(2*w_sw_actual)-1:0] pow_data_stage_1_ff;
    logic [(3*w_sw_actual)-1:0] pow_data_stage_2_ff;
    logic [(4*w_sw_actual)-1:0] pow_data_stage_3_ff;
    logic [(5*w_sw_actual)-1:0] pow_data_stage_4_ff;

    logic [w_sw_actual-1:0] input_stage_0_ff;
    logic [w_sw_actual-1:0] input_stage_1_ff;
    logic [w_sw_actual-1:0] input_stage_2_ff;
    logic [w_sw_actual-1:0] input_stage_3_ff;

    logic data_valid_stage_0_ff;
    logic data_valid_stage_1_ff;
    logic data_valid_stage_2_ff;
    logic data_valid_stage_3_ff;
    logic data_valid_stage_4_ff;

    logic [(5*w_sw_actual)-1:0] pow_output;
    logic                       pow_output_valid;



    // "Valid" flags
    always_ff @ (posedge slow_clk or posedge rst)
        if (rst) begin
            data_valid_stage_0_ff <= '0;
            data_valid_stage_1_ff <= '0;
            data_valid_stage_2_ff <= '0;
            data_valid_stage_3_ff <= '0;
            data_valid_stage_4_ff <= '0;
        end
        else begin
            data_valid_stage_0_ff <= key[0];
            data_valid_stage_1_ff <= data_valid_stage_0_ff;
            data_valid_stage_2_ff <= data_valid_stage_1_ff;
            data_valid_stage_3_ff <= data_valid_stage_2_ff;
            data_valid_stage_4_ff <= data_valid_stage_3_ff;
        end


    // Input data pipeline

    // Exercise: 1) remove unnecessary resets here to reduce ASIC area
    //           2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            input_stage_0_ff <= '0;
        else
            input_stage_0_ff <= sw;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            input_stage_1_ff <= '0;
        else
            input_stage_1_ff <= input_stage_0_ff;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            input_stage_2_ff <= '0;
        else
            input_stage_2_ff <= input_stage_1_ff;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            input_stage_3_ff <= '0;
        else
            input_stage_3_ff <= input_stage_2_ff;


    // Multiply numbers
    assign pow_mul_stage_1 = input_stage_0_ff * input_stage_0_ff;
    assign pow_mul_stage_2 = input_stage_1_ff * pow_data_stage_1_ff;
    assign pow_mul_stage_3 = input_stage_2_ff * pow_data_stage_2_ff;
    assign pow_mul_stage_4 = input_stage_3_ff * pow_data_stage_3_ff;


    // Exercise: 1) remove unnecessary resets here to reduce ASIC area
    //           2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_1_ff <= '0;
        else
            pow_data_stage_1_ff <= pow_mul_stage_1;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_2_ff <= '0;
        else
            pow_data_stage_2_ff <= pow_mul_stage_2;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_3_ff <= '0;
        else
            pow_data_stage_3_ff <= pow_mul_stage_3;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_4_ff <= '0;
        else
            pow_data_stage_4_ff <= pow_mul_stage_4;


    assign pow_output_valid = data_valid_stage_4_ff;
    assign pow_output       = pow_data_stage_4_ff;

    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                            ),
        .rst      ( rst                            ),
        .number   ( w_display_number' (pow_output) ),
        .dots     ( w_digit' (0)                   ),
        .abcdefgh ( abcdefgh                       ),
        .digit    ( digit                          )
    );

    assign led[0] = data_valid_stage_1_ff;
    assign led[1] = data_valid_stage_2_ff;
    assign led[2] = data_valid_stage_3_ff;
    assign led[3] = data_valid_stage_4_ff;

endmodule
