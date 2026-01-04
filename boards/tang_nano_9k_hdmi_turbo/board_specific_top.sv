`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

//----------------------------------------------------------------------------

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        `ifndef FORCE_NO_VIRTUAL_TM1638_USING_GRAPHICS
            `define INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        `endif
    `endif
`endif

`define IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION
`define REVERSE_KEY
`define REVERSE_LED

//`define INSTANTIATE_SOUND_DAC_OUTPUT_INTERFACE_MODULE

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 25,

              // We use sw as an alias to key on Tang Nano 9K,
              // either with or without TM1638

              w_key         = 2,
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 10,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        CLK,
    input                       HCLK,

    input  [w_key        - 1:0]  KEY,

    output [w_led        - 1:0]  LED,

    // Some LARGE_LCD pins share bank with TMDS pins
    // which have different voltage requirements.
    //
    // However we can use LARGE_LCD_DE, VS, HS, CK,
    // because they are assigned to a different bank.

       output                    LARGE_LCD_DE,
       output                    LARGE_LCD_VS,
       output                    LARGE_LCD_HS,
       output                    LARGE_LCD_CK,
    // output                    LARGE_LCD_INIT,
    // output                    LARGE_LCD_BL,

    // output [            4:0]  LARGE_LCD_R,
    // output [            5:0]  LARGE_LCD_G,
    // output [            4:0]  LARGE_LCD_B,

    input                        UART_RX,
    output                       UART_TX,

    // The following 4 pins (TF_CS, TF_MOSI, TF_SCLK, TF_MISO)
    // are used for INMP441 microphone
    // in basics-graphics-music labs

    inout                        TF_CS,
    inout                        TF_MOSI,
    inout                        TF_SCLK,
    inout                        TF_MISO,

    inout  [w_gpio       - 1:0]  GPIO,

    // The 4 pins SMALL_LCD_CLK, _CS, _RS and _DATA
    // share bank with TMDS pins
    // which have different voltage requirements.
    //
    // It means we cannot use them
    // for I2S audio output module PCM5102
    // in basics-graphics-music labs
    // when we use HDMI interface

    // inout                     SMALL_LCD_CLK,
    // inout                     SMALL_LCD_RESETN,
    // inout                     SMALL_LCD_CS,
    // inout                     SMALL_LCD_RS,
    // inout                     SMALL_LCD_DATA,

    // output                       TMDS_CLK_N,
    // output                       TMDS_CLK_P,
    // output [               2:0]  TMDS_D_N,
    // output [               2:0]  TMDS_D_P
         output [2:0] TMDSp, TMDSn,
	  output TMDSp_clock, TMDSn_clock

    // This pins have bank conflict when used with HDMI

    // ,
    // output                    FLASH_CLK,
    // output                    FLASH_CSB,
    // output                    FLASH_MOSI,
    // input                     FLASH_MISO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        // Instantiate virtual tm1638
        localparam w_lab_key   = w_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;
    `else
        // No need in TM1638 in any form
        // We create a dummy seven-segment digit
        // to avoid errors in the labs with seven-segment display

        localparam w_lab_key   = w_key,
                   w_lab_led   = w_led,
                   w_lab_digit = 1;  // w_digit;
    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] lab_red;
    wire  [w_green     - 1:0] lab_green;
    wire  [w_blue      - 1:0] lab_blue;

    wire  vtm_red, vtm_green, vtm_blue;

    wire  [w_red       - 1:0] red   = lab_red   ^ { w_red   { vtm_red   } };
    wire  [w_green     - 1:0] green = lab_green ^ { w_green { vtm_green } };
    wire  [w_blue      - 1:0] blue  = lab_blue  ^ { w_blue  { vtm_blue  } };

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        wire rst_on_power_up;
        imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

        wire rst = rst_on_power_up | (| (~ KEY));

    `elsif IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

        wire rst_on_power_up;
        imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

        wire rst = rst_on_power_up;

    `else  // Reset using an on-board button

        `ifdef REVERSE_KEY
            wire rst = ~ KEY [0];
        `else
            wire rst = ~ KEY [w_key - 1];
        `endif

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;
        assign lab_key  = tm_key;

        assign LED      = w_led' (~ lab_led);

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS

        // Virtual tm1638 - tm_keys are input, not output

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY);
        `else
            assign lab_key = ~ KEY;
        `endif

        assign tm_key   = lab_key;
        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (~ lab_led);

    `else  // no any form of TM1638

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY);
        `else
            assign lab_key = ~ KEY;
        `endif

        //--------------------------------------------------------------------

        `ifdef REVERSE_LED
            `SWAP_BITS (LED, ~ lab_led);
        `else
            assign LED = ~ lab_led;
        `endif

    `endif  // `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_lab_key     ),
        .w_sw          ( w_lab_key     ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_key       ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( x             ),
        .y             ( y             ),
        .red           ( lab_red       ),
        .green         ( lab_green     ),
        .blue          ( lab_blue      ),
        .clk_TMDS      (clk_TMDS),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          ( GPIO          ),
        .hsync         (hSync),
        .vsync          (vSync),
        .display_on     (DrawArea)
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;
    `SWAP_BITS (hgfedcba, abcdefgh);

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz    ),
            .w_digit  ( w_tm_digit )
        )
        i_tm1638
        (
            .clk      ( clk        ),
            .rst      ( rst        ),
            .hgfedcba ( hgfedcba   ),
            .digit    ( tm_digit   ),
            .ledr     ( tm_led     ),
            .keys     ( tm_key     ),
            .sio_data ( GPIO [0]   ),  // DIO PIN 25
            .sio_clk  ( GPIO [1]   ),  // CLK PIN 26
            .sio_stb  ( GPIO [2]   )   // STB PIN 27
        );
    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

       
    ////////////////////////////////////////////////////////////////////////
    wire clk_TMDS, DCM_TMDS_CLKFX;  // 25MHz x 10 = 250MHz
    wire pixclk;

        Gowin_rPLL_250 i_pll(
        .clkout(DCM_TMDS_CLKFX), //output clkout
        .clkin(clk) //input clkin
    );

        Gowin_rPLL_25 your_instance_name(
        .clkout(pixclk), //output clkout
        .clkin(clk_TMDS) //input clkin
    );



        BUFG  BUFG_TMDSp(.I(DCM_TMDS_CLKFX), .O(clk_TMDS));
    


    reg [9:0] CounterX=0, CounterY=0;
    reg hSync, vSync, DrawArea;
    
    always @(posedge pixclk) DrawArea <= (CounterX<640) && (CounterY<480);

    always @(posedge pixclk) CounterX <= (CounterX==799) ? 0 : CounterX+1;  
    always @(posedge pixclk) if(CounterX==799) CounterY <= (CounterY==524) ? 0 : CounterY+1;

    always @(posedge pixclk) hSync <= (CounterX>=656) && (CounterX<752);
    always @(posedge pixclk) vSync <= (CounterY>=490) && (CounterY<492);

    ////////////////
    wire [7:0] W = {8{CounterX[7:0]==CounterY[7:0]}};
    wire [7:0] A = {8{CounterX[7:5]==3'h2 && CounterY[7:5]==3'h2}};
    reg [7:0] red_r, green_r, blue_r;
     
    always @(posedge pixclk) red_r <= (({CounterX[3:0] & {6{CounterY[4:3]==~CounterX[4:3]}}, 2'b00} | W) & ~A) | red[7:0] ;
    always @(posedge pixclk) green_r <= green[7:0] ;
    always @(posedge pixclk) blue_r <= (CounterY[5:0] ) | blue[7:0];
//| W | A
// ((CounterX[7:0] & {8{CounterY[6]}} | W) & ~A) |
    // always @(posedge pixclk) red_r <=  red[7:0] ;
    // always @(posedge pixclk) green_r <= green[7:0] ;
    // always @(posedge pixclk) blue_r <=  blue[7:0];

    assign x = CounterX;
    assign y = CounterY;
    // always @(posedge pixclk) begin
    //                 red_r <=   red;
    //                 green_r <= green;
    //                 blue_r <=  red;
    //     end

    ////////////////////////////////////////////////////////////////////////
    wire [9:0] TMDS_red, TMDS_green, TMDS_blue;
    TMDS_encoder encode_R(.clk(pixclk), .VD(red_r  ), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_red));
    TMDS_encoder encode_G(.clk(pixclk), .VD(green_r), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_green));
    TMDS_encoder encode_B(.clk(pixclk), .VD(blue_r ), .CD({vSync,hSync}), .VDE(DrawArea), .TMDS(TMDS_blue));



    ////////////////////////////////////////////////////////////////////////
    reg [3:0] TMDS_mod10=0;  // modulus 10 counter
    reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
    reg TMDS_shift_load=0;
    always @(posedge clk_TMDS) TMDS_shift_load <= (TMDS_mod10==4'd9);

    always @(posedge clk_TMDS)
    begin
	    TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];
	    TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];
	    TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];	
	    TMDS_mod10 <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;
    end


    OBUFDS OBUFDS_red  (.I(TMDS_shift_red  [0]), .O(TMDSp[2]), .OB(TMDSn[2]));
    OBUFDS OBUFDS_green(.I(TMDS_shift_green[0]), .O(TMDSp[1]), .OB(TMDSn[1]));
    OBUFDS OBUFDS_blue (.I(TMDS_shift_blue [0]), .O(TMDSp[0]), .OB(TMDSn[0]));
    OBUFDS OBUFDS_clock(.I(pixclk), .O(TMDSp_clock), .OB(TMDSn_clock));





    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz  ( clk_mhz )
        )
        i_microphone
        (
            .clk      ( clk     ),
            .rst      ( rst     ),
            .lr       ( TF_CS   ),  // 38
            .ws       ( TF_MOSI ),  // 37
            .sck      ( TF_SCLK ),  // 36
            .sd       ( TF_MISO ),  // 39
            .value    ( mic     )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_DAC_OUTPUT_INTERFACE_MODULE

        wire dac_out;

        sigma_delta_dac
        #(
            .MSBI (   7  ),
            .INV  ( 1'b0 )
        )
        SD_DAC
        (
            .DACout ( dac_out        ),  // Average Output feeding analog lowpass
            .DACin  ( sound [15 -:8] ),  // DAC input (excess 2**MSBI)
            .CLK    ( clk            ),
            .RESET  ( rst            )
        );

        assign LARGE_LCD_HS =   dac_out;
        assign LARGE_LCD_CK = ~ dac_out;

    //------------------------------------------------------------------------

    `elsif INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz  ( clk_mhz      )
        )
        inst_audio_out
        (
            .clk      (    clk             ),
            .reset    (    rst             ),
            .data_in  (    sound           ),
            .mclk     ( /* LARGE_LCD_DE */ ),
            .bclk     (    LARGE_LCD_VS    ),
            .lrclk    (    LARGE_LCD_HS    ),
            .sdata    (    LARGE_LCD_CK    )
        );

        // PCM 5102 can recover mclk using PLL.
        // It is better to put this pin to 0, it works more reliably this way.

        assign LARGE_LCD_DE = 1'b0;

    `endif

endmodule
