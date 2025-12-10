module display_static_digit
(
    input        [3:0] dig,
    output logic [6:0] gfedcba
);

    always_comb
        case (dig)
        'h0: gfedcba = 'b1000000;  // g f e d c b a
        'h1: gfedcba = 'b1111001;
        'h2: gfedcba = 'b0100100;  //   --a--
        'h3: gfedcba = 'b0110000;  //  |     |
        'h4: gfedcba = 'b0011001;  //  f     b
        'h5: gfedcba = 'b0010010;  //  |     |
        'h6: gfedcba = 'b0000010;  //   --g--
        'h7: gfedcba = 'b1111000;  //  |     |
        'h8: gfedcba = 'b0000000;  //  e     c
        'h9: gfedcba = 'b0011000;  //  |     |
        'ha: gfedcba = 'b0001000;  //   --d-- 
        'hb: gfedcba = 'b0000011;
        'hc: gfedcba = 'b1000110;
        'hd: gfedcba = 'b0100001;
        'he: gfedcba = 'b0000110;
        'hf: gfedcba = 'b0001110;
        endcase

endmodule
