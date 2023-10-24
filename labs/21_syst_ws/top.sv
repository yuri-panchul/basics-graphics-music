`timescale 1ns / 1ps

module top
(
    input  logic clk,
    input  logic rst,

    input  logic [7:0] x1,
    input  logic [7:0] x2,

    output logic [17:0] y1,
    output logic [17:0] y2
);

    localparam W11 = 8'd3;
    localparam W12 = 8'd4;
    localparam W21 = 8'd5;
    localparam W22 = 8'd6;

    localparam W_WIDTH = 8;
    localparam X_WIDTH = 8;

    logic [7:0]  x1_pipe;
    logic [7:0]  x2_pipe;
    logic [16:0] psumm1;
    logic [16:0] psumm2;

    syst_node #(
        .W_WIDTH  (8),
        .X_WIDTH  (8),
        .SI_WIDTH (1),
        .SO_WIDTH (17)
    ) node_11 (
        .clk      (clk),
        .rst      (rst),
        .weight_i (W11),
        .psumm_i  ('0),
        .x_i      (x1),
        .psumm_o  (psumm1),
        .x_o      (x1_pipe)
    );


    syst_node #(
        .W_WIDTH  (8),
        .X_WIDTH  (8),
        .SI_WIDTH (17),
        .SO_WIDTH (18)
    ) node_12 (
        .clk      (clk),
        .rst      (rst),
        .weight_i (W12),
        .psumm_i  (psumm1),
        .x_i      (x2),
        .psumm_o  (y1),
        .x_o      (x2_pipe)
    );


    syst_node #(
        .W_WIDTH  (8),
        .X_WIDTH  (8),
        .SI_WIDTH (1),
        .SO_WIDTH (17)
    ) node_21 (
        .clk      (clk),
        .rst      (rst),
        .weight_i (W21),
        .psumm_i  ('0),
        .x_i      (x1_pipe),
        .psumm_o  (psumm2),
        .x_o      ()
    );


    syst_node #(
        .W_WIDTH  (8),
        .X_WIDTH  (8),
        .SI_WIDTH (17),
        .SO_WIDTH (18)
    ) node_22 (
        .clk      (clk),
        .rst      (rst),
        .weight_i (W22),
        .psumm_i  (psumm2),
        .x_i      (x2_pipe),
        .psumm_o  (y2),
        .x_o      ()
    );


endmodule
