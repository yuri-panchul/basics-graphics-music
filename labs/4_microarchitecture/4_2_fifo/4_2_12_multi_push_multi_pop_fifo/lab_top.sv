`include "config.svh"

localparam N_MAX_POP = 4;

`ifndef SIMULATION

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

    localparam width = 4, depth = w_digit;

    logic [3:0]    n_pop, n_push;
    logic                push_data;

    logic          clk_hand, clk_med ;
    logic          inc_pop, inc_push;
    logic [3:0]    led_pop, led_push;
    logic [31:0]   display_data;
    logic [15:0]   in_data, out_data;

// -----  Key & LED --------------------------------------------------------
    one_pusle   gen_hand_clk(.clk(clk), .in_sig(key[2]), .out_sig(clk_hand));

    a_bounce  #(12)key_flt_1(.clk(clk), .in_sig(key[0]), .out_sig(inc_pop));
    a_bounce  #(12)key_flt_2(.clk(clk), .in_sig(key[1]), .out_sig(inc_push));


    always_ff @(posedge inc_pop) begin
      if (n_pop == N_MAX_POP)  n_pop <= '0;
      else  n_pop <= n_pop + 1;
      if (&led_pop) led_pop <= '0;
      else led_pop <= {led_pop[2:0], 1'b1};
    end

    always_ff @(posedge inc_push)begin
      if (n_push == N_MAX_POP) n_push <= '0;
      else  n_push <= n_push + 1;
      if (&led_push) led_push <= '0;
      else led_push <= {led_push[2:0], 1'b1};
    end

    assign led [7:3] = led_pop;

   // reverse order LED
   assign led [11] = led_push[0];
   assign led [10] = led_push[1];
   assign led [9]  = led_push[2];
   assign led [8]  = led_push[3];

   assign led[1] = 1'b1;                           // просто эстетика

    //----- instans DUT ------------------------------------------------------
    localparam w = 4;
    localparam d = 9;
    localparam max_pop_push = 4;

    multi_push_pop_fifo #(w, d, max_pop_push) dut
                         (
                          .clk(clk_hand),
                          .rst(rst),
                          .push(n_push),
                          .push_data(in_data),
                          .pop(n_pop),
                          .pop_data(out_data),
                          .can_push(),         // how many items can I push
                          .can_pop()
                         );



  //  assign in_data      = {2'h0,sw[7:6], 2'h0,sw[5:4], 2'h0,sw[3:2], 2'h0,sw[1:0]};       // у меня не работают 5 из 8 dip переключатели по этому
      assign in_data      = {4'h04,4'h03,4'h02,4'h01};                                      // применяем набор "костылей"
  //    assign in_data      = {2'h0,sw[1:0], 2'h0,sw[3:2], 2'h0,sw[5:4], 2'h0,sw[7:6]};

    assign display_data = {in_data, out_data};

    //------------------------------------------------------------------------



    //---------- 7 SEG DISPLAY -----------------------------------------------

    wire [7:0] abcdefgh_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      (clk),
        .number   (display_data),
        .dots     (8'b00000000),
        .abcdefgh (abcdefgh),
        .digit    (digit),
        .*
    );

    //------------------------------------------------------------------------



endmodule

`endif
