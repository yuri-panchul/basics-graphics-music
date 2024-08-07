`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 2,
              w_sw          = 10,
              w_led         = 10,
              w_digit       = 6,
              w_gpio        = 32,             // GPIO[5:0] reserved for mic

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )

)
(
    input                 MAX10_CLK1_50,

    input  [w_key  - 1:0] KEY,
    input  [w_sw   - 1:0] SW,
    output [w_led  - 1:0] LEDR,

    output logic    [7:0] HEX0,
    output logic    [7:0] HEX1,
    output logic    [7:0] HEX2,
    output logic    [7:0] HEX3,
    output logic    [7:0] HEX4,
    output logic    [7:0] HEX5,


    output                  VGA_HS,
    output                  VGA_VS,
    output [w_red    - 1:0] VGA_R,
    output [w_green  - 1:0] VGA_G,
    output [w_blue   - 1:0] VGA_B,
   // output                  VGA_BLANK_N,
   // output                  VGA_SYNC_N,
    
    inout  [w_gpio - 1:0] GPIO
);

    //------------------------------------------------------------------------

    localparam w_lab_sw   = w_sw - 1;  // One onboard SW is used as a reset

    wire clk = MAX10_CLK1_50;

    wire                  rst    = SW [w_sw - 1];
    wire [w_lab_sw - 1:0] lab_sw = SW [w_lab_sw - 1:0];
    wire [w_key    - 1:0] lab_key = ~ KEY;

    //------------------------------------------------------------------------

    wire  [          7:0] abcdefgh;
    wire  [w_digit - 1:0] digit;

    // Graphics

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;
    
    //temporary wire by sisa
    logic  vga_clk;


    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;


    wire  [         23:0] mic;
    wire  [         15:0] sound;

    // FIXME: Should be assigned to some GPIO!
    //wire                  UART_TX;
    //wire                  UART_RX = '1;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz  ),
        .w_key   ( w_key    ),
        .w_sw    ( w_lab_sw ),
        .w_led   ( w_led    ),
        .w_digit ( w_digit  ),
        .w_gpio  ( w_gpio   ),          // GPIO[5:0] reserved for mic


        .screen_width  (   screen_width  ),
        .screen_height (   screen_height ),

        .w_red         (   w_red         ),
        .w_green       (   w_green       ),
        .w_blue        (   w_blue        )


    )
    i_lab_top
    (
        .clk      (   clk      ),
        .slow_clk (   slow_clk ),
        .rst      (   rst      ),

        .key      (   lab_key  ),
        .sw       (   lab_sw   ),

        .led      (   LEDR     ),

        .abcdefgh (   abcdefgh ),
        .digit    (   digit    ),

        .x        (   x        ),
        .y        (   y        ),

        .red      (   VGA_R    ),
        .green    (   VGA_G    ),
        .blue     (   VGA_B    ),

       // .uart_rx  (   UART_RX  ),
       //.uart_tx  (   UART_TX  ),

        .mic      (   mic      ),
        .sound    (   sound    ),

        .gpio     (   GPIO     )
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

    `ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.

        assign HEX0 = digit [0] ? ~ hgfedcba : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba : '1;
        assign HEX4 = digit [4] ? ~ hgfedcba : '1;
        assign HEX5 = digit [5] ? ~ hgfedcba : '1;

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 } <= '1;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba;
                if (digit [1]) HEX1 <= ~ hgfedcba;
                if (digit [2]) HEX2 <= ~ hgfedcba;
                if (digit [3]) HEX3 <= ~ hgfedcba;
                if (digit [4]) HEX4 <= ~ hgfedcba;
                if (digit [5]) HEX5 <= ~ hgfedcba;
            end

    `endif

      `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;


       vga
        # (
            .CLK_MHZ     ( clk_mhz   ),
            .PIXEL_MHZ   ( pixel_mhz )
        )
        i_vga
        (
            .clk         ( clk       ),
            .rst         ( rst       ),
            .hsync       ( VGA_HS    ),
            .vsync       ( VGA_VS    ),
            .display_on  (           ),
            .hpos        ( x10       ),
            .vpos        ( y10       ),
            .pixel_clk   ( vga_clk   )
        );

       // assign VGA_BLANK_N = 1'b1;
       // assign VGA_SYNC_N  = 1'b0;

    `endif

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [0] ), // JP1 pin 1
        .ws    ( GPIO [2] ), // JP1 pin 3
        .sck   ( GPIO [4] ), // JP1 pin 5
        .sd    ( GPIO [5] ), // JP1 pin 6
        .value ( mic      )
    );

    assign GPIO [1] = 1'b0;  // GND - JP1 pin 2
    assign GPIO [3] = 1'b1;  // VCC - JP1 pin 4

    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz     )
    )
    inst_audio_out
    (
        .clk     ( clk         ),
        .reset   ( rst         ),
        .data_in ( sound       ),
       // .mclk    ( GPIO [33]   ), // JP1 pin 38
        .bclk    ( GPIO [31]   ), // JP1 pin 36
        .lrclk   ( GPIO [27]   ), // JP1 pin 32
        .sdata   ( GPIO [29]   )  // JP1 pin 34
   );                             // JP1 pin 30 - GND, pin 29 - VCC 3.3V (30-45 mA)


endmodule
