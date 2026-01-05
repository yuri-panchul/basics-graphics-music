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

   // reads light levels from TI ADC081S021, and displays the analog value in 2 seven-segment displays
   // Uses GPIO[5:3] for interfacing with the ADC

   localparam cycle_rd_en_lp = 30_000;

   // potential issue with Gowin synthesizer not properly recognizing 7:-16?
   // logic [15:0] one_fourth_pt_lp = 16'h0040;;

   wire adc_valid_w;
   wire [7:0] adc_data_w;

   // registers for implementing 1D convolution to smooth ADC output
   logic [15:0] sr_data_r[3:0];
   // sum shift register data to complete convolution
   logic [15:0] conv_data_l;

   logic [$clog2(cycle_rd_en_lp) - 1:0] rd_ctr_r;
   wire                                 adc_rd_en;

   assign adc_rd_en = rd_ctr_r == cycle_rd_en_lp - 1;
   assign conv_data_l = '0 + sr_data_r[3] + sr_data_r[2] + sr_data_r[1] + sr_data_r[0];

   // registers that shifts in valid data from ADC.
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         sr_data_r[0] <= '0;
         sr_data_r[1] <= '0;
         sr_data_r[2] <= '0;
         sr_data_r[3] <= '0;
      end else begin
         if (adc_valid_w && adc_rd_en) begin
            sr_data_r[0] <= ({ adc_data_w[7:0], {8{1'b0}} } >> 2);
            sr_data_r[1] <= sr_data_r[0];
            sr_data_r[2] <= sr_data_r[1];
            sr_data_r[3] <= sr_data_r[2];
         end else begin
            sr_data_r[0] <= sr_data_r[0];
            sr_data_r[1] <= sr_data_r[1];
            sr_data_r[2] <= sr_data_r[2];
            sr_data_r[3] <= sr_data_r[3];
         end
      end
   end

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         rd_ctr_r <= '0;
      end else begin
         if (rd_ctr_r == cycle_rd_en_lp - 1) begin
            rd_ctr_r <= '0;
         end else begin
            rd_ctr_r <= rd_ctr_r + 1;
         end
      end
   end

    seven_segment_display
    # (.w_digit (2))
    i_7segment
    (
       .clk      ( clk          ),
       .rst      ( rst          ),
       .number   ( conv_data_l[15:8] ),
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
