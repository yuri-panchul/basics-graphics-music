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

    localparam shield_gpio_base = 36;

    wire [1:0] geiger_input = gpio [shield_gpio_base + 2 +: 2];
    wire [1:0] shield_led;
    wire       shield_speaker;
    wire       shield_pwm;

    assign gpio [shield_gpio_base + 8 +: 2] = shield_led;
    assign gpio [shield_gpio_base + 4 +: 2] = { shield_pwm, shield_speaker };

    // assign shield_led     = geiger_input;
    // assign shield_speaker = | geiger_input;
    // assign shield_pwm     = '0;

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

    logic [1:0] geiger_input_r;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            geiger_input_r <= '0;
        else
            geiger_input_r <= geiger_input;

    wire [1:0] geiger_posedge     = geiger_input & ~ geiger_input_r;
    wire [1:0] num_geiger_posedge = geiger_posedge [0] + geiger_posedge [1];

    //------------------------------------------------------------------------

    localparam w_particle_cnt = w_digit * 4;
    logic [w_particle_cnt - 1:0] particle_cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            particle_cnt <= '0;
        else
            particle_cnt <= particle_cnt + num_geiger_posedge;

    //------------------------------------------------------------------------

    localparam w_particle_cnt = w_digit * 4;
    logic [w_particle_cnt - 1:0] particle_cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            particle_cnt <= '0;
        else
            particle_cnt <= particle_cnt + num_geiger_posedge;

    //------------------------------------------------------------------------

    assign led = w_led' ({ w_led / 2 { geiger_input_ext } });

    //------------------------------------------------------------------------

    // 4 bits per hexadecimal digit
    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                                  ),
        .rst      ( rst                                  ),
        .number   ( w_display_number' (particle_cnt)     ),
        .dots     ( { w_digit / 2 { geiger_input_ext } } ),
        .abcdefgh ( abcdefgh                             ),
        .digit    ( digit                                )
    );

    //------------------------------------------------------------------------

endmodule
