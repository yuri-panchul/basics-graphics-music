`include "config.svh"
`include "lab_specific_board_config.svh"

`define USE_HDMI
`undef  INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 2,  // The last key is used for a reset
                w_sw    = 0,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 9
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    output                      tmds_clk_n,
    output                      tmds_clk_p,
    output [              2:0]  tmds_d_n,
    output [              2:0]  tmds_d_p,

    inout  [w_gpio      - 1:0]  GPIO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    =   8,
               w_tm_led    =   8,
               w_tm_digit  =   8,
               vid_clk_mhz = 125;


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_lab_key   = w_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_led,
                   w_lab_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire                      clk_hdl;
    wire                      clk_hd;
    wire                      clk_px;
    wire                      pll_lock;
    wire                      sys_resetn;

    wire                      vsync;
    wire                      hsync;
    wire                      display_on;
    logic [              7:0] red;
    logic [              7:0] green;
    logic [              7:0] blue;

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;

   //------------------------------------------------------------------------

`ifdef USE_HDMI
   BUFG clHD(.I(clk_hdl), .O(clk_hd));

   Gowin_rPLL hdPLL(
        .clkout( clk_hdl  ), //output clkout
        .clkin ( clk      ), //input clkin
        .lock  ( pll_lock )
    );
`endif
   //------------------------------------------------------------------------


    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

      `ifdef USE_HDMI
        assign rst      = ~ ( ~tm_key[w_tm_key - 1] & pll_lock );
      `else
        assign rst      = tm_key [w_tm_key - 1];
      `endif
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

      `ifdef USE_HDMI
        assign rst      = ~ ( KEY[w_key - 1] & pll_lock );
      `else
        assign rst      = ~KEY[w_key - 1];
      `endif
        assign lab_key  = ~ KEY [w_key - 1:0];

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------


    lab_top
    # (
`ifdef USE_HDMI
        .clk_mhz ( vid_clk_mhz ),
`else
        .clk_mhz ( clk_mhz     ),
`endif
        .w_key   ( w_lab_key     ),  // The last key is used for a reset
        .w_sw    ( w_lab_sw      ),
        .w_led   ( w_lab_led     ),
        .w_digit ( w_lab_digit   ),
        .w_gpio  ( w_gpio        )
`ifdef USE_HDMI
        ,
        .w_red   ( 8             ),
        .w_green ( 8             ),
        .w_blue  ( 8             )
`endif
    )
    i_lab_top
    (
`ifdef USE_HDMI
        .clk        ( clk_hd     ),
`else
        .clk        ( clk        ),
`endif
        .slow_clk   ( slow_clk   ),
        .rst        ( rst        ),

        .key        ( lab_key    ),
        .sw         (            ),

        .led        ( lab_led    ),

        .abcdefgh   ( abcdefgh   ),
        .digit      ( lab_digit  ),

        .vsync      ( vsync      ),
        .hsync      ( hsync      ),

        .red        ( red        ),
        .green      ( green      ),
        .blue       ( blue       ),

        .display_on ( display_on ),
        .pixel_clk  ( clk_px     ),

        .uart_rx    ( UART_RX    ),
        .uart_tx    ( UART_TX    ),

        .mic        ( mic        ),
        .sound      (            ),
        .gpio       (            )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk      ( clk       ),
        .rst      ( rst       ),
        .hgfedcba ( hgfedcba  ),
        .digit    ( tm_digit  ),
        .ledr     ( tm_led    ),
        .keys     ( tm_key    ),
        .sio_clk  ( GPIO [1]  ),
        .sio_stb  ( GPIO [2]  ),
        .sio_data ( GPIO [0]  )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz )
    )
    i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [5] ),
        .ws    ( GPIO [4] ),
        .sck   ( GPIO [3] ),
        .sd    ( GPIO [6] ),
        .value ( mic      )
    );

`ifdef USE_HDMI
    DVI_TX_Top myDVI(
        .I_rst_n      ( ~rst        ), //input I_rst_n
        .I_serial_clk ( clk_hd      ), //input I_serial_clk
        .I_rgb_clk    ( clk_px      ), //input I_rgb_clk
        .I_rgb_vs     ( ~vsync      ), //input I_rgb_vs
        .I_rgb_hs     ( ~hsync      ), //input I_rgb_hs
        .I_rgb_de     ( display_on  ), //input I_rgb_de
        .I_rgb_r      ( red         ), //input [7:0] I_rgb_r
        .I_rgb_g      ( green       ), //input [7:0] I_rgb_g
        .I_rgb_b      ( blue        ), //input [7:0] I_rgb_b
        .O_tmds_clk_p ( tmds_clk_p  ), //output O_tmds_clk_p
        .O_tmds_clk_n ( tmds_clk_n  ), //output O_tmds_clk_n
        .O_tmds_data_p( tmds_d_p    ), //output [2:0] O_tmds_data_p
        .O_tmds_data_n( tmds_d_n    ) //output [2:0] O_tmds_data_n
    );
`endif

    assign GPIO [8] = 1'b0;  // GND
    assign GPIO [7] = 1'b1;  // VCC

endmodule
