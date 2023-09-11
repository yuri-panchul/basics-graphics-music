`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 20
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,

    // General-purpose Input/Output

    inout  logic [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led      = '0;
       assign abcdefgh = '0;
       assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;

    //------------------------------------------------------------------------

    wire a   = key [0];
    wire b   = key [1];
    wire sel = key [2];

    //------------------------------------------------------------------------

    // Five different implementations

    wire mux0 = sel ? a : b;

    //------------------------------------------------------------------------

    wire [1:0] ab = { a, b };
    assign mux1 = ab [sel];

    //------------------------------------------------------------------------

    logic mux2;

    always_comb
        if (sel)
            mux2 = a;
        else
            mux2 = b;

    //------------------------------------------------------------------------

    logic mux3;

    always_comb
        case (sel)
        1'b1: mux3 = a;
        1'b0: mux3 = b;
        endcase

    //------------------------------------------------------------------------

    // Exercise: Implement mux
    // without using "?" operation, "if", "case" or a bit selection.
    // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

    wire mux4 = 1'b0;

    //------------------------------------------------------------------------

    // Use table 1

    wire [0:7] table1 =
    {
        1'b0, // a = 0, b = 0, sel = 0 
        1'b0, // a = 0, b = 0, sel = 1 
        1'b1, // a = 0, b = 1, sel = 0 
        1'b0, // a = 0, b = 1, sel = 1 
        1'b0, // a = 1, b = 0, sel = 0 
        1'b1, // a = 1, b = 0, sel = 1 
        1'b1, // a = 1, b = 1, sel = 0 
        1'b1  // a = 1, b = 1, sel = 1 
    };
    
    wire mux5 = table1 [{ a, b, sel }];

    //------------------------------------------------------------------------

    // Use table 2

    wire [7:0] table2 =
    {
        1'b1, // a = 1, b = 1, sel = 1 
        1'b1, // a = 1, b = 1, sel = 0 
        1'b1, // a = 1, b = 0, sel = 1 
        1'b0, // a = 1, b = 0, sel = 0 
        1'b0, // a = 0, b = 1, sel = 1 
        1'b1, // a = 0, b = 1, sel = 0 
        1'b0, // a = 0, b = 0, sel = 1 
        1'b0  // a = 0, b = 0, sel = 0 
    };
    
    wire mux6 = table2 [{ a, b, sel }];

    //------------------------------------------------------------------------

    // Use table 3

    wire [0:1][0:1][0:1] table3 =
    {
        1'b0, // a = 0, b = 0, sel = 0 
        1'b0, // a = 0, b = 0, sel = 1 
        1'b1, // a = 0, b = 1, sel = 0 
        1'b0, // a = 0, b = 1, sel = 1 
        1'b0, // a = 1, b = 0, sel = 0 
        1'b1, // a = 1, b = 0, sel = 1 
        1'b1, // a = 1, b = 1, sel = 0 
        1'b1  // a = 1, b = 1, sel = 1 
    };
    
    wire mux7 = table3 [a][b][sel];

    //------------------------------------------------------------------------

    // Use table 4

    wire [1:0][1:0][1:0] table4 =
    {
        1'b1, // a = 1, b = 1, sel = 1 
        1'b1, // a = 1, b = 1, sel = 0 
        1'b1, // a = 1, b = 0, sel = 1 
        1'b0, // a = 1, b = 0, sel = 0 
        1'b0, // a = 0, b = 1, sel = 1 
        1'b1, // a = 0, b = 1, sel = 0 
        1'b0, // a = 0, b = 0, sel = 1 
        1'b0  // a = 0, b = 0, sel = 0 
    };
    
    wire mux8 = table4 [a][b][sel];

    //------------------------------------------------------------------------

    // Use table 5

    wire [0:1][0:1][0:1] table5 =
    '{
        '{
            '{ 1'b0, 1'b0 },  // a = 0, b = 0, sel = 0/1
            '{ 1'b1, 1'b0 }   // a = 0, b = 1, sel = 0/1
        },
        
        '{
            '{ 1'b1, 1'b0 },  // a = 1, b = 0, sel = 0/1
            '{ 1'b1, 1'b1 }   // a = 1, b = 1, sel = 0/1
        }
    };
    
    wire mux9 = table5 [a][b][sel];

    //------------------------------------------------------------------------

    // Use table 6

    wire table6 [0:1][0:1][0:1] =
    '{
        '{
            '{ 1'b0, 1'b0 },  // a = 0, b = 0, sel = 0/1
            '{ 1'b1, 1'b0 }   // a = 0, b = 1, sel = 0/1
        },
        
        '{
            '{ 1'b1, 1'b0 },  // a = 1, b = 0, sel = 0/1
            '{ 1'b1, 1'b1 }   // a = 1, b = 1, sel = 0/1
        }
    };

    wire mux10 = table6 [a][b][sel];

    //------------------------------------------------------------------------

    // Use concatenation operation for all signals:

    // assign led = w_led' ({ mux10 , mux9 , mux8 ,
    //                        mux7  , mux6 , mux5 , mux4,
    //                        mux3  , mux2 , mux1 , mux0 });
    
    // Use concatenation operation for the boards with 4 LEDs:
    
    // assign led = w_led' ({ mux3  , mux2 , mux1 , mux0 });
    // assign led = w_led' ({ mux6  , mux5 , mux4 , mux0 });
       assign led = w_led' ({ mux9  , mux8 , mux7 , mux0 });
    // assign led = w_led' ({ mux10 , mux4 , mux1 , mux0 });

    /*
    initial
    begin
        # 1
        
        for (int i = 0; i <= 1; i ++)
        for (int j = 0; j <= 1; j ++)
        for (int k = 0; k <= 1; k ++)
            $write (" %b", table3 [i][j][k]);

        $display;
        
        for (int i = 0; i <= 1; i ++)
        for (int j = 0; j <= 1; j ++)
        for (int k = 0; k <= 1; k ++)
            $write (" %b", table4 [i][j][k]);

        $display;
        
        for (int i = 0; i <= 1; i ++)
        for (int j = 0; j <= 1; j ++)
        for (int k = 0; k <= 1; k ++)
            $write (" %b", table5 [i][j][k]);

        $display;
        
        for (int i = 0; i <= 1; i ++)
        for (int j = 0; j <= 1; j ++)
        for (int k = 0; k <= 1; k ++)
            $write (" %b", table6 [i][j][k]);

        $display;
    end
    */

endmodule
