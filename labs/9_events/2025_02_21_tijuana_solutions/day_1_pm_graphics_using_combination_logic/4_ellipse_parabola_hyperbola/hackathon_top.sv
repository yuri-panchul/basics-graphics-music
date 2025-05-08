// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);
    // START_SOLUTION

    //ellipse
    localparam [9:0] a_menor = 100;
    localparam [9:0] a_mayor = 300;
    localparam [9:0] b_arriba = 50;
    localparam [9:0] b_abajo = 150;
    localparam [9:0] radio_a = (a_mayor-a_menor)/2;
    localparam [9:0] radio_b = (b_abajo-b_arriba)/2;
    localparam [9:0] a_centro = (a_mayor+a_menor)/2;
    localparam [9:0] b_centro = (b_abajo+b_arriba)/2;
    reg [31:0] dx2, dy2;        // Diferencias al cuadrado
    reg [63:0] term1, term2;   // Términos intermedios
    reg [63:0] rhs;            // Lado derecho de la desigualdad

    //parabola
    localparam [9:0] x_vertice = 200; // Coordenada X del vértice
    localparam [9:0] y_vertice = 125; // Coordenada Y del vértice
    localparam [9:0] p_parabola = 50; // Distancia del vértice al foco

    //hyperbola
    localparam [9:0] x_centro = 200; // Centro X
    localparam [9:0] y_centro = 100; // Centro Y
    localparam [9:0] a_hiperbola = 30; // Semieje a
    localparam [9:0] b_hiperbola = 10; // Semieje b

    // Registros auxiliares para cálculos intermedios
    reg [31:0] x_diff2, y_diff2; // Diferencias al cuadrado

    always_comb begin
        red   = 0;
        green = 0;
        blue  = 0;

        // Cálculos  elipse
        dx2 = (x - a_centro) * (x - a_centro); // (x - a_centro)^2
        dy2 = (y - b_centro) * (y - b_centro); // (y - b_centro)^2
        term1 = dx2 * (radio_b * radio_b);     // (x - a_centro)^2 * b_radio^2
        term2 = dy2 * (radio_a * radio_a);     // (y - b_centro)^2 * a_radio^2
        rhs = (radio_a * radio_a) * (radio_b * radio_b); // a_radio^2 * b_radio^2

        // Elipse
        if ((x >= a_menor) & (x <= a_mayor) & // Dentro del rango horizontal
            (y >= b_arriba) & (y <= b_abajo)// Dentro del rango vertical
            & ((term1 + term2) <= rhs))
                red = 31;

        //parabola
        //hacia arriba
        if ((y <= y_vertice) & (((y_vertice - y) * (4 * p_parabola)) >= ((x - x_vertice) * (x - x_vertice))))
            blue = 31;
        /*
        //hacia arriba
        if ((y >= y_vertice) & (((y- y_vertice) * (4 * p_parabola)) >= ((x - x_vertice) * (x - x_vertice))))
            blue = 31;
        */
        // Cálculos hyperbola
        x_diff2 = (x - x_centro) * (x - x_centro); // (x - x_centro)^2
        y_diff2 = (y - y_centro) * (y - y_centro); // (y - y_centro)^2
        term1 = x_diff2 * (b_hiperbola * b_hiperbola); // (x - x_centro)^2 * b^2
        term2 = y_diff2 * (a_hiperbola * a_hiperbola); // (y - y_centro)^2 * a^2
        rhs = (a_hiperbola * a_hiperbola) * (b_hiperbola * b_hiperbola); // a^2 * b^2
         // Hipérbola horizontal
         if (~((term1 - term2) >= rhs))
            green = 61;

        //parabola
        /* para cara
        //hacia arriba
        if (((y >= y_vertice) & (((y- y_vertice) * (4 * p_parabola)) >= ((x - x_vertice) * (x - x_vertice))))& red ==31 )
            blue = 31;

        // Cálculos hyperbola
        x_diff2 = (x - x_centro) * (x - x_centro); // (x - x_centro)^2
        y_diff2 = (y - y_centro) * (y - y_centro); // (y - y_centro)^2
        term1 = x_diff2 * (b_hiperbola * b_hiperbola); // (x - x_centro)^2 * b^2
        term2 = y_diff2 * (a_hiperbola * a_hiperbola); // (y - y_centro)^2 * a^2
        rhs = (a_hiperbola * a_hiperbola) * (b_hiperbola * b_hiperbola); // a^2 * b^2
         // Hipérbola horizontal
         if ((~((term1 - term2) >= rhs)) & red ==31 )
            green = 61;
        */
    end

    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock        ),
        .rst      ( reset        ),
        .number   ( 32'h1234abcd ),
        .dots     ( '0           ),  // This syntax means "all 0s in the context"
        .abcdefgh ( abcdefgh     ),
        .digit    ( digit        )
    );

    // END_SOLUTION

endmodule
