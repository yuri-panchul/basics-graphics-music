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

    input        [         23:0] mic,

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

    //------------------------------------------------------------------------

    // Truncate used SW number to 8
    localparam w_sw_actual = (w_sw > 8) ? 8
                                        : w_sw;

    //------------------------------------------------------------------------

    logic [w_sw_actual-1:0] pow_input;

    logic [(2*w_sw_actual)-1:0] mul_stage_1;
    logic [(3*w_sw_actual)-1:0] mul_stage_2;
    logic [(4*w_sw_actual)-1:0] mul_stage_3;
    logic [(5*w_sw_actual)-1:0] mul_stage_4;

    logic [(2*w_sw_actual)-1:0] reg_stage_1;
    logic [(3*w_sw_actual)-1:0] reg_stage_2;
    logic [(4*w_sw_actual)-1:0] reg_stage_3;

    logic [(5*w_sw_actual)-1:0] pow_output;


    logic input_valid;
    logic stage_1_valid;
    logic stage_2_valid;
    logic stage_3_valid;
    logic output_valid;


    // Multiply numbers
    assign mul_stage_1 = pow_input   * pow_input;
    assign mul_stage_2 = reg_stage_1 * pow_input;
    assign mul_stage_3 = reg_stage_2 * pow_input;
    assign mul_stage_4 = reg_stage_3 * pow_input;

    // "Valid" flag
    always_ff @ (posedge clk or posedge rst)
        if (rst) begin
            input_valid   <= '0;
            stage_1_valid <= '0;
            stage_2_valid <= '0;
            stage_3_valid <= '0;
            output_valid  <= '0;
        end
        else begin
            input_valid   <= key[0];
            stage_1_valid <= input_valid;
            stage_2_valid <= stage_1_valid;
            stage_3_valid <= stage_2_valid;
            output_valid  <= stage_3_valid;
        end


    // TODO: 1) do we actually need reset here?
    //       2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            pow_input <= '0;
        else
            pow_input <= sw;

    // TODO: 1) do we actually need reset here?
    //       2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge clk or posedge rst)
        if (rst) begin
            reg_stage_1 <= '0;
            reg_stage_2 <= '0;
            reg_stage_3 <= '0;
        end
        else begin
            reg_stage_1 <= mul_stage_1;
            reg_stage_2 <= mul_stage_2;
            reg_stage_3 <= mul_stage_3;
        end

    // TODO: 1) do we actually need reset here?
    //       2) use clock gating to reduce pipeline power consumption

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            pow_output <= '0;
        else
            pow_output <= mul_stage_4;


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

    assign led[0] = output_valid;

endmodule
