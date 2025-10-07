// `default_nettype none

module tmds_encoder (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic       C0,
    input  logic       C1,
    input  logic       DE,
    input  logic [7:0] D,
    output logic [9:0] q_out
);

    localparam W_CNT = 8;

    logic signed [W_CNT-1:0] cnt;
    logic signed [W_CNT-1:0] cnt_next;
    logic              [8:0] q_m;
    logic              [9:0] q_next;
    logic              [3:0] N1D;
    logic              [3:0] N1_qm;
    logic              [3:0] N0_qm;


    always_comb begin
        N1D = 4'(D[0]) + 4'(D[1]) + 4'(D[2]) + 4'(D[3])
            + 4'(D[4]) + 4'(D[5]) + 4'(D[6]) + 4'(D[7]);

        q_m[0] = D[0];

        if ((N1D > 4) || (N1D == 4 && ~D[0])) begin
            // verilator lint_off ALWCOMBORDER
            q_m[8] = 1'b0;

            for (int i = 0; i < 7; i++) begin
                q_m[i + 1] = q_m[i] ~^ D[i + 1];
            end
            // verilator lint_on ALWCOMBORDER

        end else begin
            q_m[8] = 1'b1;

            for (int i = 0; i < 7; i++) begin
                q_m[i + 1] = q_m[i] ^ D[i + 1];
            end
        end

        N1_qm = 4'(q_m[0]) + 4'(q_m[1]) + 4'(q_m[2]) + 4'(q_m[3])
              + 4'(q_m[4]) + 4'(q_m[5]) + 4'(q_m[6]) + 4'(q_m[7]);

        N0_qm = 4'(!q_m[0]) + 4'(!q_m[1]) + 4'(!q_m[2]) + 4'(!q_m[3])
              + 4'(!q_m[4]) + 4'(!q_m[5]) + 4'(!q_m[6]) + 4'(!q_m[7]);

        if (DE) begin
            if ((cnt == 0) || (N1_qm == N0_qm)) begin
                q_next[9]   = ~q_m[8];
                q_next[8]   =  q_m[8];
                q_next[7:0] =  q_m[8] ? q_m[7:0] : ~q_m[7:0];

                if (~q_m[8]) begin
                    cnt_next = cnt + W_CNT'(N0_qm) -  W_CNT'(N1_qm);
                end else begin
                    cnt_next = cnt + W_CNT'(N1_qm) - W_CNT'(N0_qm);
                end

            end else begin
                if (((cnt > 0) && (N1_qm > N0_qm)) ||
                    ((cnt < 0) && (N0_qm > N1_qm))) begin

                    q_next[9]   = 1'b1;
                    q_next[8]   = q_m[8];
                    q_next[7:0] = ~q_m[7:0];
                    cnt_next    = cnt + (W_CNT'(q_m[8]) << 1) +
                                        W_CNT'(N0_qm) - W_CNT'(N1_qm);

                end else begin
                    q_next[9]   = 1'b0;
                    q_next[8]   = q_m[8];
                    q_next[7:0] = q_m[7:0];
                    cnt_next    = cnt - (W_CNT'({~q_m[8]}) << 1) +
                                        W_CNT'(N1_qm) - W_CNT'(N0_qm);
                end
            end

        end else begin
            cnt_next = '0;

            case ({C1, C0})
                2'b00: q_next = 10'b1101010100;
                2'b01: q_next = 10'b0010101011;
                2'b10: q_next = 10'b0101010100;
                2'b11: q_next = 10'b1010101011;
            endcase
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            cnt <= '0;
        end else begin
            cnt <= cnt_next;
        end
    end

    always_ff @(posedge clk_i) begin
        q_out <= q_next;
    end

endmodule
