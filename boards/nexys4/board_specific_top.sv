`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 100,
    	      pixel_mhz     = 25,
              w_key         = 5,
              w_sw          = 16,
              w_led         = 16,
              w_digit       = 8,
              w_gpio        = 32,
              
              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   clk,
    input                   btnCpuReset,
  
    input                   btnC,
    input                   btnU,
    input                   btnL,
    input                   btnR,
    input                   btnD,

    input  [w_sw     - 1:0] sw,
    output [w_led    - 1:0] led,

    output                  RGB1_Red,
    output                  RGB1_Green,
    output                  RGB1_Blue,
  
    output                  RGB2_Red,
    output                  RGB2_Green,
    output                  RGB2_Blue,

    output [6           :0] seg,
    output                  dp,
    output [7           :0] an,

    output                  Hsync,
    output                  Vsync,

    output [w_red    - 1:0] vgaRed,
    output [w_blue   - 1:0] vgaBlue,
    output [w_green  - 1:0] vgaGreen,

    input                   RsRx,

    inout  [7           :0] JA,
    inout  [7           :0] JB,
    inout  [7           :0] JC,
    inout  [7           :0] JD,

    output                  micClk,
    input                   micData,
    output                  micLRSel,

    output                  ampPWM,
    output                  ampSD
);

    //------------------------------------------------------------------------

    wire rst = ~ btnCpuReset;

    //------------------------------------------------------------------------

    assign RGB1_Red   = 1'b0;
    assign RGB1_Green = 1'b0;
    assign RGB1_Blue  = 1'b0;

    assign RGB2_Red   = 1'b0;
    assign RGB2_Green = 1'b0;
    assign RGB2_Blue  = 1'b0;

    assign micClk     = 1'b0;
    assign micLRSel   = 1'b0;

    assign ampPWM     = 1'b0;
    assign ampSD      = 1'b0;

    //------------------------------------------------------------------------

    wire [7:0] abcdefgh;
    wire [7:0] digit;

    assign { seg [0], seg [1], seg [2], seg [3],
             seg [4], seg [5], seg [6], dp       } = ~ abcdefgh;

    assign an = ~ digit;

    wire [23:0] mic;

    // FIXME: Should be assigned to some GPIO!
    wire        UART_TX;
    wire        UART_RX = '1;
    
    wire [w_gpio      - 1:0]  gpio;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz        ),
        .w_key         (   w_key          ),
        .w_sw          (   w_sw           ),
        .w_led         (   w_led          ),
        .w_digit       (   w_digit        ),
        .w_gpio        (   w_gpio         ),
        
        .screen_width  (   screen_width   ),
        .screen_height (   screen_height  ),

        .w_red         (   w_red          ),
        .w_green       (   w_green        ),
        .w_blue        (   w_blue         )
    )
    i_lab_top
    (
        .clk           ( clk              ),
        .slow_clk      ( slow_clk         ),
        .rst           ( rst              ),

        .key           ( { btnD, btnU, btnL, btnC, btnR } ),
        .sw            ( sw               ),

        .led           ( led              ),

        .abcdefgh      ( abcdefgh         ),

        .digit         ( digit            ),
        
        .x             ( x                ),
        .y             ( y                ),

        .red           ( vgaRed           ),
        .green         ( vgaBlue          ),
        .blue          ( vgaGreen         ),

        .uart_rx       ( UART_RX          ),
        .uart_tx       ( UART_TX          ),

        .mic           ( mic              ),
        .gpio          ( gpio             )
    );


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

	wire display_on;
	wire pixel_clk;
        
     vga
     # (
         .CLK_MHZ     ( clk_mhz    ),
         .PIXEL_MHZ   ( pixel_mhz  )
     )
     i_vga
     (
         .clk         ( clk        ),
         .rst         ( rst        ),
         .hsync       ( Hsync      ),
         .vsync       ( Vsync      ),
         .display_on  ( display_on ),
         .hpos        ( x10        ),
         .vpos        ( y10        ),
         .pixel_clk   ( pixel_clk  )
      );

    `endif
    
    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (
    	.clk_mhz ( clk_mhz )
    )
    i_microphone
    (
        .clk   ( clk    ),
        .rst   ( rst    ),
        .lr    ( JD [6] ),
        .ws    ( JD [5] ),
        .sck   ( JD [4] ),
        .sd    ( JD [0] ),
        .value ( mic    )
    );

    assign JD [2] = 1'b0;  // GND - JD pin 3
    assign JD [1] = 1'b1;  // VCC - JD pin 2

endmodule
