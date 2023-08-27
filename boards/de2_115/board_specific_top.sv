module board_specific_top
# (
    parameter clk_mhz   = 50,
              w_key     = 4,
              w_sw      = 18,
              w_led     = 18,
              w_digit   = 8,
              w_gpio    = 36,
              vga_clock = 25   // Pixel clock of VGA in MHz, recommend be equal with VGA_CLOCK from labs/common/vga.sv
)
(
    input                   CLOCK_50,

    input  [w_key    - 1:0] KEY,
    input  [w_sw     - 1:0] SW,
    output [w_led    - 1:0] LEDR, // LEDR[17:10] used like HEX dp

    output logic [     6:0] HEX0, // HEX[7] aka dp doesn't connected to FPGA at DE2-115
    output logic [     6:0] HEX1,
    output logic [     6:0] HEX2,
    output logic [     6:0] HEX3,
    output logic [     6:0] HEX4,
    output logic [     6:0] HEX5,
    output logic [     6:0] HEX6,
    output logic [     6:0] HEX7,

    output                  VGA_CLK, // VGA DAC input triggers CLK
    output                  VGA_HS,
    output                  VGA_VS,
    output [           7:0] VGA_R,
    output [           7:0] VGA_G,
    output [           7:0] VGA_B,
    output                  VGA_BLANK_N,
    output                  VGA_SYNC_N,

    inout  [w_gpio   - 1:0] GPIO
);

    localparam w_top_sw = w_sw - 1;  // One sw is used as a reset

    wire                  clk     = CLOCK_50;
    wire                  rst     = SW [w_top_sw];
    wire [w_top_sw - 1:0] top_sw  = SW [w_top_sw - 1:0];

    assign            LEDR[17:10] = dp; // LEDR[17:10] used like a HEX dp

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [         23:0] mic;

    wire [          3:0] red_4b,green_4b,blue_4b;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz         ),
        .w_key   ( w_key           ),
        .w_sw    ( w_top_sw        ),
        .w_led   ( w_led - w_digit ), // LEDR[17:10] used like HEX dp
        .w_digit ( w_digit         ),
        .w_gpio  ( w_gpio          )
    )
    i_top
    (
        .clk      (   clk                          ),
        .rst      (   rst                          ),

        .key      ( ~ KEY                          ),
        .sw       (   top_sw                       ),

        .led      (   LEDR [w_led - w_digit - 1:0] ),

        .abcdefgh (   abcdefgh                     ),
        .digit    (   digit                        ),

        .vsync    (   VGA_VS                       ),
        .hsync    (   VGA_HS                       ),

        .red      (   red_4b                       ),
        .green    (   green_4b                     ),
        .blue     (   blue_4b                      ),

        .mic      (   mic                          ),
        .gpio     (   GPIO                         )
    );

    //------------------------------------------------------------------------

    assign VGA_R = {   red_4b,4'd0 };
    assign VGA_G = { green_4b,4'd0 };
    assign VGA_B = {  blue_4b,4'd0 };

    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N  = 0;

    // Enable to divide clock from 50 or 100 MHz to 25 MHz

    logic [3:0] clk_en_cnt;
    logic clk_en;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            clk_en_cnt <= 3'b0;
            clk_en     <= 1'b0;
        end
        else
        begin
            if (clk_en_cnt == (clk_mhz / vga_clock) - 1)
            begin
                clk_en_cnt <= 3'b0;
                clk_en     <= 1'b1;
            end
            else
            begin
                clk_en_cnt <= clk_en_cnt + 1;
                clk_en     <= 1'b0;
            end
        end
    end

    assign VGA_CLK = clk_en;

    //------------------------------------------------------------------------

    wire  [$left (abcdefgh):0] hgfedcba;
    logic [$left    (digit):0] dp;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 } <= '1;
            dp <= '0;
        end
        else
        begin
            // inverted logic
            if (digit [0]) HEX0 <= ~ hgfedcba [6:0];
            if (digit [1]) HEX1 <= ~ hgfedcba [6:0];
            if (digit [2]) HEX2 <= ~ hgfedcba [6:0];
            if (digit [3]) HEX3 <= ~ hgfedcba [6:0];
            if (digit [4]) HEX4 <= ~ hgfedcba [6:0];
            if (digit [5]) HEX5 <= ~ hgfedcba [6:0];
            if (digit [6]) HEX6 <= ~ hgfedcba [6:0];
            if (digit [7]) HEX7 <= ~ hgfedcba [6:0];

            // positive logic
            if (digit [0]) dp[0] <=  hgfedcba [7];
            if (digit [1]) dp[1] <=  hgfedcba [7];
            if (digit [2]) dp[2] <=  hgfedcba [7];
            if (digit [3]) dp[3] <=  hgfedcba [7];
            if (digit [4]) dp[4] <=  hgfedcba [7];
            if (digit [5]) dp[5] <=  hgfedcba [7];
            if (digit [6]) dp[6] <=  hgfedcba [7];
            if (digit [7]) dp[7] <=  hgfedcba [7];
        end
    end

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [5] ),
        .ws    ( GPIO [3] ),
        .sck   ( GPIO [1] ),
        .sd    ( GPIO [0] ),
        .value ( mic      )
    );

    assign GPIO [4] = 1'b0;  // GND
    assign GPIO [2] = 1'b1;  // VCC

endmodule
