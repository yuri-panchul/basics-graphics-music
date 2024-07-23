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

    //------------------------------------------------------------------------

    // assign led        = '0;
       assign abcdefgh   = '0;
       assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire [2:0] in;

    generate

        if (w_key >= 3)              // Board with at least 3 keys
            assign in = key [2:0];
        else if (w_sw >= 3)          // Board with at least 3 switches
            assign in = sw  [2:0];
        else if (w_key + w_sw >= 3)  // Board with at least 3 keys + switches
            assign in = 3' ({ key, sw });
        else if (w_key >= 2)         // Board with at least 2 keys
            assign in = { key [0], key [1:0] };
        else                         // Corner case: repeat a key 3 times
            assign in = { 3 { key [0] } };

    endgenerate

    //------------------------------------------------------------------------

    logic [1:0] enc0, enc1, enc2, enc3;

    // Implementation 1. Priority encoder using a chain of "ifs"

    always_comb
             if (in [0]) enc0 = 2'd0;
        else if (in [1]) enc0 = 2'd1;
        else if (in [2]) enc0 = 2'd2;
        else             enc0 = 2'd0;

    // Implementation 2. Priority encoder using casez

    always_comb
        casez (in)
        3'b??1:  enc1 = 2'd0;
        3'b?10:  enc1 = 2'd1;
        3'b100:  enc1 = 2'd2;
        default: enc1 = 2'd0;
        endcase

    // Implementation 3: Combination of priority arbiter
    // and encoder without priority

    localparam w = 3;

    `ifdef YOSYS

        wire [w - 1:0] c;

        genvar i;

        generate
            for (i = 0; i < w; i = i + 1) begin
                if (i == 0)
                    assign c [0] = 1'b1;
                else
                    assign c [i] = ~ in [i - 1] & c [i - 1];
            end
        endgenerate

    `else

        wire [w - 1:0] c = { ~ in [w - 2:0] & c [w - 2:0], 1'b1 };

    `endif

    wire [w - 1:0] g = in & c;


    always_comb
        unique case (g)
        3'b001:  enc2 = 2'd0;
        3'b010:  enc2 = 2'd1;
        3'b100:  enc2 = 2'd2;
        default: enc2 = 2'd0;
        endcase

    /*
    // A variation of Implementation 3: Using unusual case of "case"

    always_comb
        unique case (1'b1)
        g [0]:   enc2 = 2'd0;
        g [1]:   enc2 = 2'd1;
        g [2]:   enc2 = 2'd2;
        default: enc2 = 2'd0;
        endcase
    */

    // A note on obsolete practice:
    //
    // Before the SystemVerilog construct "unique case"
    // got supported by the synthesis tools,
    // the designers were using pseudo-comment "synopsys parallel_case":
    //
    // SystemVerilog : unique case (1'b1)
    // Verilog 2001  : case (1'b1)  // synopsys parallel_case

    // Implementation 4: Using "for" loop

    always_comb
    begin
        enc3 = '0;

        for (int i = 0; i < $bits (in); i ++)
        begin
            if (in [i])
            begin
                enc3 = 2' (i);

                // Since both Icarus and Yosys do not support break statement
                // we simply imitate it by setting i to final value

                `ifdef __ICARUS__
                     i = $bits (in);
                `else
                    `ifdef YOSYS
                        i = $bits (in);
                    `else
                        break;
                    `endif
                `endif
            end
        end
    end

    //------------------------------------------------------------------------

    assign led = w_led' ({ enc0, enc1, enc2, enc3 });

endmodule
