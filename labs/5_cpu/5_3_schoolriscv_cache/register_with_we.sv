//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Alexander Kirichenko
//  for systemverilog-homework project.
//

module register_with_we
(
    input             clk,
    input             rst,
    input             we,
    input      [31:0] d,
    output reg [31:0] q
);
    always_ff @ (posedge clk)
        if (rst)
            q <= '0;
        else
            if (we) q <= d;

endmodule
