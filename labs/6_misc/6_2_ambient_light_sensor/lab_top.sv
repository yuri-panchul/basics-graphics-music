`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_digit       = 2,
               w_sw          = 8,
               w_led         = 8,
               w_gpio        = 4,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input  logic       clk,
    input  logic       slow_clk, // unused
    input  logic       rst,

    input  logic [7:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
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

    inout  logic [w_gpio - 1:0] gpio
 );
   wire adc_valid_w;
   wire [7:0] adc_data_w;
   logic [7:0] valid_data_r;

   // reads light levels from TI ADC081S021, and displays the analog value in 2 seven-segment displays
   // Uses GPIO[5:3] for interfacing with the ADC

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         valid_data_r <= '0;
      end else begin
         if (adc_valid_w) begin
            valid_data_r <= adc_data_w;
         end else begin
            valid_data_r <= valid_data_r;
         end
      end
   end

    seven_segment_display
    # (.w_digit (2))
    i_7segment
    (
       .clk      ( clk          ),
       .rst      ( rst          ),
       .number   ( valid_data_r ),
       .dots     ( '0             ),
       .abcdefgh ( abcdefgh       ),
       .digit    ( digit          )
    );

    adc_adapter
    adc_inst
    (
        .clk_i(clk),
        .rst_i(rst),
        .sclk_o(gpio[5]),
        .cs_o(gpio[4]),
        .sdo_i(gpio[3]),
        .valid_o(adc_valid_w),
        .data_o(adc_data_w)
    );

endmodule
