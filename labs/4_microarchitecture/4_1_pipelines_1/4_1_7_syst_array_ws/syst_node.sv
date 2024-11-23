`timescale 1ns / 1ps

module syst_node
#(
    parameter W_WIDTH  = 8,
    parameter X_WIDTH  = 8,
    parameter SI_WIDTH = 8,
    parameter SO_WIDTH = 17
)
(
    input  logic                clk,
    input  logic                rst,
    input  logic [W_WIDTH -1:0] weight_i,
    input  logic [SI_WIDTH-1:0] psumm_i,
    input  logic [X_WIDTH -1:0] x_i,
    output logic [SO_WIDTH-1:0] psumm_o,
    output logic [X_WIDTH -1:0] x_o
);

    logic [X_WIDTH        -1:0] x_reg;
    logic [SO_WIDTH       -1:0] psumm_reg;
    logic [X_WIDTH+W_WIDTH-1:0] weight_mult;

    assign weight_mult = x_i * weight_i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            psumm_reg <= '0;
        else
            psumm_reg <= psumm_i + weight_mult;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            x_reg <= '0;
        else
            x_reg <= x_i;
    end

    assign psumm_o = psumm_reg;
    assign x_o     = x_reg;

endmodule
