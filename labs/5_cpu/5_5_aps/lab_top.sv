`include "config.svh"

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
    assign sound      = '0;

    /*
    =====================================================
    CLK/RST adapter
    =====================================================
    */
    localparam APS_SYS_CLK_MHZ = 10;
    localparam APS_VGA_CLK_MHZ = 25;

    logic clk10MHz, clk10MHz_raw;
    logic clk25MHz, clk25MHz_raw;
    logic sync_rst;
    clock_divider #(
        .FAST_CLK_FREQ(clk_mhz          ),
        .SLOW_CLK_FREQ(APS_SYS_CLK_MHZ  )
    ) sys_clk_div (
        .clk_i(clk),
        .aresetn_i(!rst),
        .clk_o(clk10MHz_raw),
        .rst_o(sync_rst)
    );
    clock_divider #(
        .FAST_CLK_FREQ(clk_mhz          ),
        .SLOW_CLK_FREQ(APS_VGA_CLK_MHZ  )
    ) vga_clk_div (
        .clk_i(clk),
        .aresetn_i(!rst),
        .clk_o(clk25MHz_raw),
        .rst_o()
    );
    `ifdef SIMULATION
        `define NO_CLOCK_ROUTING_FOR_SLOW_CLOCK
    `endif

    `ifndef CLOCK_ROUTING_FOR_SLOW_CLOCK
        `define NO_CLOCK_ROUTING_FOR_SLOW_CLOCK
    `endif

    `ifdef NO_CLOCK_ROUTING_FOR_SLOW_CLOCK
        assign clk10MHz = clk10MHz_raw;
        assign clk25MHz = clk25MHz_raw;
    `else
        `ifdef ALTERA_RESERVED_QIS

            // "global" is Intel FPGA-specific primitive to route
            // a signal coming from data into clock tree

            global i_global (.in (clk10MHz_raw), .out (clk10MHz));
            global i_global (.in (clk25MHz_raw), .out (clk25MHz));

        `elsif XILINX_VIVADO

            // "BUFG" is Xilinx-specific primitive to route
            // a signal coming from data into clock tree

            BUFG i_BUFG (.I (clk10MHz_raw), .O (clk10MHz));
            BUFG i_BUFG (.I (clk25MHz_raw), .O (clk25MHz));

        `else

            // `error_Unsupported_synthesis_tool

            assign clk25MHz = clk25MHz_raw;

        `endif
    `endif
    //===================================================

    /*
    =====================================================
    LED adapter
    =====================================================
    */
    logic [15:0] aps_led;
    if(w_led > 16) begin
        assign led[w_led-1:16] = '0;
        assign led[15:0] = aps_led;
    end
    else begin
        assign led = aps_led[0+:w_led];
    end
    //===================================================



    /*
    =====================================================
    SW adapter
    =====================================================
    */
    logic [15:0] aps_sw;
    if(w_sw > 16) begin
        assign aps_sw=sw[15:0];
    end
    else begin
        assign aps_sw[0+:w_sw] = sw;
    end
    //===================================================



    /*
    =====================================================
    7seg adapter
    =====================================================
    */
    logic [6:0] hex_led;
    logic [7:0] hex_sel;
    assign abcdefgh   = ~{hex_led, 1'b0};

    if(w_digit > 8) begin
        assign digit[w_digit-1:8] = '0;
        assign digit[7:0] = ~hex_sel;
    end else begin
        assign digit = ~hex_sel[0+:w_digit];
    end
    //===================================================



    /*
    =====================================================
    VGA adapter
    =====================================================
    */
    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;
    if(w_red > 4) begin
        assign red      = vga_r << (w_red - 4);
    end else begin
        assign red      = vga_r >> (4 - w_red);
    end
    if(w_green > 4) begin
        assign green    = vga_g << (w_green - 4);
    end else begin
        assign green    = vga_g >> (4 - w_green);
    end
    if(w_blue > 4) begin
        assign blue     = vga_b << (w_blue - 4);
    end else begin
        assign blue     = vga_b >> (4 - w_blue);
    end
    //===================================================


    processor_system system(
        .clk10mhz_i     (clk10MHz       ),
        .clk25175khz_i  (clk25MHz       ),
        .rst_i          (sync_rst       ),

        .sw_i           (aps_sw         ),
        .led_o          (aps_led        ),

        .kclk_i         (kclk           ),
        .kdata_i        (kdata          ),

        .hex_led_o      (hex_led        ),
        .hex_sel_o      (hex_sel        ),

        .rx_i           (uart_rx        ),
        .tx_o           (uart_tx        ),

        .vga_r_o        (vga_r          ),
        .vga_g_o        (vga_g          ),
        .vga_b_o        (vga_b          ),
`ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        .vga_x_i        (x              ),
        .vga_y_i        (y              ),
`else
        .vga_hs_o       (vga_hs         ),
        .vga_vs_o       (vga_vs         ),
`endif
        .tck_i          (),
        .tms_i          (),
        .tdi_i          (),
        .tdo_o          (),
        .tdo_en_o       ()
    );


endmodule
