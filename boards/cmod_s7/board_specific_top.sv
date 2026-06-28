`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

module board_specific_top
(
    input  wire       clk,
    input  wire [1:0] btn,
    output wire [3:0] led,

    // TM1638 connections
    inout  wire       pio21,  // DIO
    output wire       pio22,  // CLK
    output wire       pio23   // STB
);

    // --------------------------------------------------------
    // Board configuration
    // --------------------------------------------------------

    // The Cmod S7 oscillator runs at 12 MHz.
    localparam int CLK_MHZ = 12;

    // The TM1638 contains 8 buttons, LEDs, and digits.
    localparam int W_TM = 8;

    // --------------------------------------------------------
    // Reset
    // --------------------------------------------------------

    wire rst_on_power_up;

    imitate_reset_on_power_up i_reset_on_power_up
    (
        .clk (clk),
        .rst (rst_on_power_up)
    );

    // Reset at startup or while button 0 is pressed.
    wire rst = rst_on_power_up | btn[0];

    // btn[1] is currently unused.

    // --------------------------------------------------------
    // Slow clock used by some educational labs
    // --------------------------------------------------------

    wire slow_clk;

    slow_clk_gen
    #(
        .fast_clk_mhz (CLK_MHZ),
        .slow_clk_hz  (1)
    )
    i_slow_clk_gen
    (
        .clk      (clk),
        .rst      (rst),
        .slow_clk (slow_clk)
    );

    // --------------------------------------------------------
    // Connections between lab_top and the TM1638
    // --------------------------------------------------------

    // Button states read from the TM1638.
    wire [W_TM-1:0] tm_btns;

    // Outputs created by the selected lab.
    wire [W_TM-1:0] lab_led;
    wire [W_TM-1:0] lab_digit;

    // Seven-segment pattern created by the lab.
    wire [7:0] abcdefgh;

    // Reversed segment order required by the TM1638 controller.
    wire [7:0] hgfedcba;

    `SWAP_BITS (hgfedcba, abcdefgh);

    // Dummy GPIO connection for labs that do not use GPIO.
    wire [0:0] gpio_unused;

    // Also show the first four lab LED outputs on the Cmod LEDs.
    assign led = lab_led[3:0];

    // --------------------------------------------------------
    // Selected educational lab
    // --------------------------------------------------------

    lab_top
    #(
        .clk_mhz (CLK_MHZ),

        .w_key   (W_TM),
        .w_sw    (W_TM),
        .w_led   (W_TM),
        .w_digit (W_TM),
        .w_gpio  (1)
    )
    i_lab_top
    (
        .clk      (clk),
        .slow_clk (slow_clk),
        .rst      (rst),

        // TM1638 buttons act as both keys and switches.
        .key      (tm_btns),
        .sw       (tm_btns),

        // Lab outputs.
        .led      (lab_led),
        .abcdefgh (abcdefgh),
        .digit    (lab_digit),

        // Graphics are not connected yet.
        .x        ('0),
        .y        ('0),
        .red      (),
        .green    (),
        .blue     (),

        // UART is not connected yet.
        // An idle UART input is logic 1.
        .uart_rx  (1'b1),
        .uart_tx  (),

        // Audio is not connected yet.
        .mic      (24'd0),
        .sound    (),

        // Generic GPIO is not used by the first labs.
        .gpio     (gpio_unused)
    );

    // --------------------------------------------------------
    // TM1638 controller
    // --------------------------------------------------------

    tm1638_board_controller
    #(
        .clk_mhz (CLK_MHZ),
        .w_digit (W_TM)
    )
    i_tm1638
    (
        .clk       (clk),
        .rst       (rst),

        // Display and LED information going to the TM1638.
        .hgfedcba  (hgfedcba),
        .digit     (lab_digit),
        .ledr      (lab_led),

        // Button information coming from the TM1638.
        .keys      (tm_btns),

        // Physical three-wire TM1638 interface.
        .sio_data  (pio21),
        .sio_clk   (pio22),
        .sio_stb   (pio23)
    );

endmodule