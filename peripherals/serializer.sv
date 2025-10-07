// `default_nettype none

module serializer #(
    parameter DATA_W = 10
) (
    input  logic              clk_i,
    input  logic              rst_i,
    input  logic [DATA_W-1:0] data_i,
    output logic              data_o
);

    localparam CNT_MAX = DATA_W - 1;

    logic [DATA_W-1:0] shift_reg;
    logic [       3:0] cnt;
    logic              load;

    assign load = cnt == CNT_MAX;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            cnt <= '0;
        end else if (load) begin
            cnt <= '0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            shift_reg <= '0;
        end else if (load) begin
            shift_reg <= data_i;
        end else begin
            shift_reg <= { 1'b0, shift_reg[DATA_W-1:1] };
        end
    end

    assign data_o = shift_reg[0];

endmodule
