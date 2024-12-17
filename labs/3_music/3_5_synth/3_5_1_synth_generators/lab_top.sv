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
    // assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    logic [7:0] sample_data_square;
    logic [7:0] sample_data_saw;
    logic [7:0] sample_data_saw_inv;
    logic [7:0] sample_data_triangle;
    logic [7:0] sample_data_sine;
    logic [7:0] sample_data_noise;

    localparam freq = 440; // In Hz
    localparam bit [63:0] generator_freq =(((2**27) * freq)/(clk_mhz * 1000000))-1;

    audio_square inst_square
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .freq_i        (generator_freq),
      .sample_data_o (sample_data_square)
    );

    audio_saw inst_saw
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .freq_i        (generator_freq),
      .sample_data_o (sample_data_saw)
    );

    audio_saw_inv inst_saw_inv
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .freq_i        (generator_freq),
      .sample_data_o (sample_data_saw_inv)
    );

    audio_triangle inst_triangle
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .freq_i        (generator_freq),
      .sample_data_o (sample_data_triangle)
    );

    audio_sine inst_sine
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .freq_i        (generator_freq),
      .sample_data_o (sample_data_sine)
    );

    audio_noise inst_noise
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .freq_i        (generator_freq),
      .sample_data_o (sample_data_noise)
    );

    logic [7:0] sound_mux;

    always_comb begin
        case(sw)
          'd0: sound_mux = sample_data_square;
          'd1: sound_mux = sample_data_saw;
          'd2: sound_mux = sample_data_saw_inv;
          'd3: sound_mux = sample_data_triangle;
          'd4: sound_mux = sample_data_sine;
          'd5: sound_mux = sample_data_noise;
          default: sound_mux = '0;
        endcase

    end

    assign sound = {1'd0, sound_mux, 7'd0};

endmodule
