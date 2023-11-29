`include "config.svh"

module top
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

    input                        uart_rx,
    output                       uart_tx,

    input                        mic_ready,
    input        [         23:0] mic,
    output       [         15:0] sound,

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

    // Truncate used SW number to 8
    localparam w_sw_actual = (w_sw > 8) ? 8
                                        : w_sw;

    //------------------------------------------------------------------------

    logic [w_sw_actual-1:0] pow_input;

    logic [(2*w_sw_actual)-1:0] pow_mul_stage_1;
    logic [(3*w_sw_actual)-1:0] pow_mul_stage_2;
    logic [(4*w_sw_actual)-1:0] pow_mul_stage_3;
    logic [(5*w_sw_actual)-1:0] pow_mul_stage_4;

    logic [(2*w_sw_actual)-1:0] pow_data_stage_1;
    logic [(3*w_sw_actual)-1:0] pow_data_stage_2;
    logic [(4*w_sw_actual)-1:0] pow_data_stage_3;

    logic [w_sw_actual-1:0] pow_input_stage_1;
    logic [w_sw_actual-1:0] pow_input_stage_2;
    logic [w_sw_actual-1:0] pow_input_stage_3;

    logic [(5*w_sw_actual)-1:0] pow_output;


    logic input_valid;
    logic data_valid_stage_1;
    logic data_valid_stage_2;
    logic data_valid_stage_3;
    logic output_valid;


    // "Valid" flags
    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            input_valid <= '0;
        else
            input_valid <= key[0];

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst) begin
            data_valid_stage_1 <= '0;
            data_valid_stage_2 <= '0;
            data_valid_stage_3 <= '0;
        end
        else begin
            data_valid_stage_1 <= input_valid;
            data_valid_stage_2 <= data_valid_stage_1;
            data_valid_stage_3 <= data_valid_stage_2;
        end

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            output_valid <= '0;
        else
            output_valid <= data_valid_stage_3;


    // Input data pipeline

    // Exercise: 1) remove unnecessary resets here to reduce ASIC area
    //           2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_input <= '0;
        else
            pow_input <= sw;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_input_stage_1 <= '0;
        else
            pow_input_stage_1 <= pow_input;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_input_stage_2 <= '0;
        else
            pow_input_stage_2 <= pow_input_stage_1;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_input_stage_3 <= '0;
        else
            pow_input_stage_3 <= pow_input_stage_2;


    // Multiply numbers
    assign pow_mul_stage_1 = pow_input        * pow_input;
    assign pow_mul_stage_2 = pow_data_stage_1 * pow_input_stage_1;
    assign pow_mul_stage_3 = pow_data_stage_2 * pow_input_stage_2;
    assign pow_mul_stage_4 = pow_data_stage_3 * pow_input_stage_3;


    // Exercise: 1) remove unnecessary resets here to reduce ASIC area
    //           2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_1 <= '0;
        else
            pow_data_stage_1 <= pow_mul_stage_1;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_2 <= '0;
        else
            pow_data_stage_2 <= pow_mul_stage_2;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_data_stage_3 <= '0;
        else
            pow_data_stage_3 <= pow_mul_stage_3;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            pow_output <= '0;
        else
            pow_output <= pow_mul_stage_4;


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

    assign led[0] = input_valid;
    assign led[1] = data_valid_stage_1;
    assign led[2] = data_valid_stage_2;
    assign led[3] = data_valid_stage_3;
    assign led[4] = output_valid;

endmodule
