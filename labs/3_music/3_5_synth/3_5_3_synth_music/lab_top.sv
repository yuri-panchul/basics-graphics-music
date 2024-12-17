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

    logic [3:0] note; // C, Cd, D, Dd, E, F, Fd, G, Gd, A, Ad, B
    logic [1:0] octave; // THIRD, SECOND, FIRST, SMALL
    logic       enable;

    melody_memory 
    #(
      .CLK_MHZ (clk_mhz),
      .BPM     (80)
    )
    inst_memory_imperial_march
    (
      .clk_i (clk),
      .rst_i (rst),
      
      .note_o (note), // C, Cd, D, Dd, E, F, Fd, G, Gd, A, Ad, B
      .octave_o (octave), // THIRD, SECOND, FIRST, SMALL
      .enable_o (enable)
    );

    logic [15:0] freq_music;

    note_freq_mem #(
      .CLK_MHZ (clk_mhz)
    )
    inst_note_rom
    (
      .note_sel_i   (note),
      .octave_sel_i (octave),

      .freq_o (freq_music)
    );

    logic [7:0] sample_data;

    audio_channel audio_channel_inst
    (
      .clk_i         (clk),
      .rst_i         (rst),
      .en_i          (enable),
      .gen_sel_i     (sw[2:0]),
      .freq_i        (freq_music),
      .volume_i      (8'd255),
      .sample_data_o (sample_data)
    );

    assign sound = {1'd0, sample_data, 7'd0};

endmodule
