`include "config.svh"
`include "lab_specific_board_config.svh"

// `define ENABLE_VGA16
// `define ENABLE_VGA666
 `undef  ENABLE_VGA16
 `define ENABLE_HDMI

`undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 5,  // The last key is used for a reset
                w_sw    = 5,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 32
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3

`ifdef ENABLE_HDMI
    , output                      tmds_clk_n
    , output                      tmds_clk_p
    , output [              2:0]  tmds_d_n
    , output [              2:0]  tmds_d_p
`endif
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

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

    `ifdef ENABLE_VGA16
        localparam w_lab_red   = 5,
                   w_lab_green = 6,
                   w_lab_blue  = 5;
    `elsif ENABLE_VGA666
        localparam w_lab_red   = 6,
                   w_lab_green = 6,
                   w_lab_blue  = 6;
    `elsif ENABLE_HDMI
        localparam vid_clk_mhz = 125,
                   w_lab_red   = 8,
                   w_lab_green = 8,
                   w_lab_blue  = 8;
    `else
        localparam w_lab_red   = 4,
                   w_lab_green = 4,
                   w_lab_blue  = 4;
    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    logic [w_lab_sw    - 1:0] lab_sw;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;

    //------------------------------------------------------------------------

    wire                      clk_hdl;
    wire                      clk_hd;
    wire                      clk_px;
    wire                      pll_lock;
    wire                      sys_resetn;
    wire                      display_on;

    wire                     VGA_HS;
    wire                     VGA_VS;

    logic [ w_lab_red   - 1:0] VGA_R;
    logic [ w_lab_green - 1:0] VGA_G;
    logic [ w_lab_blue  - 1:0] VGA_B;

    //------------------------------------------------------------------------

   `ifdef ENABLE_HDMI
      BUFG clHD(.I(clk_hdl), .O(clk_hd));

      Gowin_rPLL hdPLL(
           .clkout( clk_hdl  ), //output clkout
           .clkin ( clk      ), //input clkin
           .lock  ( pll_lock )
       );
   `endif
   //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

      `ifdef ENABLE_HDMI
        assign rst      = ~ ( ~tm_key[w_tm_key - 1] & pll_lock );
      `else
        assign rst      = tm_key [w_tm_key - 1];
      `endif
        assign lab_key  = tm_key [w_tm_key - 1:0];
        assign lab_sw   = ~ SW;

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

      `ifdef ENABLE_HDMI
        assign rst      = ~ ( KEY[w_key - 1] & pll_lock );
      `else
        assign rst      = ~KEY[w_key - 1];
      `endif
        assign lab_key  = ~ KEY [w_key - 1:0];
        assign lab_sw   = ~ SW;

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
`ifdef ENABLE_HDMI
        .clk_mhz ( vid_clk_mhz ),
`else
        .clk_mhz ( clk_mhz     ),
`endif
        .w_key   ( w_lab_key    ),  // The last key is used for a reset
        .w_sw    ( w_lab_sw     ),
        .w_led   ( w_lab_led    ),
        .w_digit ( w_lab_digit  ),
        .w_gpio  ( w_gpio       ),
        .w_red   ( w_lab_red    ),
        .w_green ( w_lab_green  ),
        .w_blue  ( w_lab_blue   )
    )
    i_lab_top
    (
`ifdef ENABLE_HDMI
        .clk      ( clk_hd    ),
`else
        .clk      ( clk       ),
`endif
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( lab_key   ),
        .sw       ( lab_sw    ),

        .led      ( lab_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( lab_digit ),

        .vsync    ( VGA_VS    ),
        .hsync    ( VGA_HS    ),

        .red      ( VGA_R     ),
        .green    ( VGA_G     ),
        .blue     ( VGA_B     ),
        .display_on( display_on ),
        .pixel_clk ( clk_px     ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .mic      ( mic       ),
        .gpio     (           )
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
        .clk        ( clk           ),
        .rst        ( rst           ),
        .hgfedcba   ( hgfedcba      ),
        .digit      ( tm_digit      ),
        .ledr       ( tm_led        ),
        .keys       ( tm_key        ),
        .sio_clk    ( GPIO_0[2]     ),
        .sio_stb    ( GPIO_0[3]     ),
        .sio_data   ( GPIO_0[1]     )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz    )
    )
    i_microphone
    (
        .clk     ( clk        ),
        .rst     ( rst        ),
        .lr      ( GPIO_0 [5] ),
        .ws      ( GPIO_0 [6] ),
        .sck     ( GPIO_0 [7] ),
        .sd      ( GPIO_0 [4] ),
        .value   ( mic        )
    );

    //------------------------------------------------------------------------

//    assign GPIO_3 = {VGA_B, VGA_R};
//    assign GPIO_2 = {VGA_HS, VGA_VS, 2'bz, VGA_G};
   `ifdef ENABLE_VGA16

      assign GPIO_3 = {2'bz, VGA_R[3], VGA_R[1], 2'bz, VGA_R[4], VGA_R[2]};
      assign GPIO_2 = {VGA_G[5], VGA_G[3], VGA_G[1], VGA_B[4], VGA_R[0], VGA_G[4], VGA_G[2], VGA_G[0]};
      assign GPIO_1 = {VGA_B[2], VGA_B[0], VGA_HS, 1'bz, VGA_B[3], VGA_B[1], VGA_VS, 1'bz};

   `elsif ENABLE_VGA666

      assign GPIO_3 = { VGA_G[4], VGA_G[5], VGA_R[2], VGA_B[4], VGA_VS,   VGA_HS,   VGA_B[0], VGA_R[1] };
      assign GPIO_2 = { VGA_B[3], VGA_G[2], VGA_R[0], VGA_R[4], VGA_G[0], VGA_B[5], VGA_G[1], VGA_B[1] };
      assign GPIO_1 = { VGA_R[5], 3'bz,                         VGA_B[2], VGA_G[3], VGA_R[3], 1'bz };

   `elsif ENABLE_HDMI
    DVI_TX_Top myDVI(
        .I_rst_n      ( ~rst        ), //input I_rst_n
        .I_serial_clk ( clk_hd      ), //input I_serial_clk
        .I_rgb_clk    ( clk_px      ), //input I_rgb_clk
        .I_rgb_vs     ( ~VGA_VS     ), //input I_rgb_vs
        .I_rgb_hs     ( ~VGA_HS     ), //input I_rgb_hs
        .I_rgb_de     ( display_on  ), //input I_rgb_de
        .I_rgb_r      ( VGA_R       ), //input [7:0] I_rgb_r
        .I_rgb_g      ( VGA_G       ), //input [7:0] I_rgb_g
        .I_rgb_b      ( VGA_B       ), //input [7:0] I_rgb_b
        .O_tmds_clk_p ( tmds_clk_p  ), //output O_tmds_clk_p
        .O_tmds_clk_n ( tmds_clk_n  ), //output O_tmds_clk_n
        .O_tmds_data_p( tmds_d_p    ), //output [2:0] O_tmds_data_p
        .O_tmds_data_n( tmds_d_n    ) //output [2:0] O_tmds_data_n
    );

   `else

      assign GPIO_2 = { VGA_B, VGA_R };
      assign GPIO_3 = { 2'bz, VGA_VS, VGA_HS, VGA_G };

   `endif

endmodule
