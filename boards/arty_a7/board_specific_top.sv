module board_specific_top
# (
    parameter clk_mhz = 100,
              w_key   = 4,
              w_sw    = 4,
              w_led   = 4,
              w_digit = 8,
              w_gpio  = 41
)
(
    input         CLK100MHZ,
    input         CPU_RESETN,

    input         BTNC,
    input         BTNU,
    input         BTNL,
    input         BTNR,
    input         BTND,

    input  [w_sw-1:0] SW,
    output [w_led-1:0] LED,

    output        LED0_B,
    output        LED0_G,
    output        LED0_R,

    output        LED1_B,
    output        LED1_G,
    output        LED1_R,
	
	output        LED2_B,
    output        LED2_G,
    output        LED2_R,
	
	output        LED3_B,
    output        LED3_G,
    output        LED3_R,
	
	output        LED4_B,
    output        LED4_G,
    output        LED4_R,

    output        CA,
    output        CB,
    output        CC,
    output        CD,
    output        CE,
    output        CF,
    output        CG,

    output        DP,

    output [ 7:0] AN,

  //output [ 3:0] VGA_R,
  //output [ 3:0] VGA_G,
  //output [ 3:0] VGA_B,

  //output        VGA_HS,
  //output        VGA_VS,

  //input         UART_TXD_IN,

    inout  [12:1] JA,
    inout  [12:1] JB,
    inout  [12:1] JC,
    inout  [12:1] JD,

  //output        M_CLK,
  //input         M_DATA,
  //output        M_LRSEL,

  //output        AUD_PWM,
  //output        AUD_SD
);

    //------------------------------------------------------------------------

    wire clk =   CLK100MHZ;
    wire rst = ~ CPU_RESETN;

    //------------------------------------------------------------------------

    assign LED0_B = 1'b0;
    assign LED0_G = 1'b0;
    assign LED0_R = 1'b0;
    assign LED1_B = 1'b0;
    assign LED1_G = 1'b0;
    assign LED1_R = 1'b0;
	assign LED2_B = 1'b0;
    assign LED2_G = 1'b0;
    assign LED2_R = 1'b0;
    assign LED3_B = 1'b0;
    assign LED3_G = 1'b0;
    assign LED3_R = 1'b0;
	
  //assign M_CLK   = 1'b0;
  //assign M_LRSEL = 1'b0;

  //assign AUD_PWM = 1'b0;
  //assign AUD_SD  = 1'b0;

    //------------------------------------------------------------------------

  //wire [23:0] mic = '0;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk      ( clk    ),
        .rst      ( rst    ),

        .key      ( { BTNU, BTND, BTNL, BTNC, BTNR } ),
        .sw       ( SW     ),

        .led      ( LED    ),

        .abcdefgh ( { CA, CB, CC, CD, CE, CF, CG, DP } ),

        .digit    ( AN     ),

        .vsync    ( VGA_VS ),
        .hsync    ( VGA_HS ),

        .red      ( VGA_R  ),
        .green    ( VGA_G  ),
        .blue     ( VGA_B  ),

        .mic      ( mic    ),
        .gpio     (        )
    );

endmodule
