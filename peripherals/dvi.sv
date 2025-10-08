`include "dvi_config.svh"

module dvi_top (
    input  logic               serial_clk_i,
    input  logic               pixel_clk_i,
    input  logic               rst_i,

    input  logic [COLOR_W-1:0] red_i,
    input  logic [COLOR_W-1:0] green_i,
    input  logic [COLOR_W-1:0] blue_i,

    output logic [X_POS_W-1:0] x_o,
    output logic [Y_POS_W-1:0] y_o,

    output logic               red_serial_o,
    output logic               green_serial_o,
    output logic               blue_serial_o
);

    logic               hsync;
    logic               vsync;
    logic               visible_range;
    logic               hsync_r;
    logic               vsync_r;
    logic               visible_range_r;

    logic [        9:0] red_tmds;
    logic [        9:0] green_tmds;
    logic [        9:0] blue_tmds;

    // ------------------------------------------------------------------------
    // Sync
    // ------------------------------------------------------------------------

    dvi_sync i_dvi_sync (
        .clk_i           ( pixel_clk_i   ),
        .rst_i           ( rst_i         ),
        .hsync_o         ( hsync         ),
        .vsync_o         ( vsync         ),
        .pixel_x_o       ( x_o           ),
        .pixel_y_o       ( y_o           ),
        .visible_range_o ( visible_range )
    );

    // ------------------------------------------------------------------------
    // Encode
    // ------------------------------------------------------------------------

    // Delay hsync/vsync and visible_range by 1 clock cycle to account for color
    // delay in image_gen
    always_ff @(posedge pixel_clk_i) begin
        if (rst_i) begin
            hsync_r         <= '0;
            vsync_r         <= '0;
            visible_range_r <= '0;
        end else begin
            hsync_r         <= hsync;
            vsync_r         <= vsync;
            visible_range_r <= visible_range;
        end
    end

    tmds_encoder blue_encoder (
        .clk_i ( pixel_clk_i     ),
        .rst_i ( rst_i           ),
        .C0    ( hsync_r         ),
        .C1    ( vsync_r         ),
        .DE    ( visible_range_r ),
        .D     ( blue_i          ),
        .q_out ( blue_tmds       )
    );

    tmds_encoder green_encoder (
        .clk_i ( pixel_clk_i     ),
        .rst_i ( rst_i           ),
        .C0    ( 1'b0            ),
        .C1    ( 1'b0            ),
        .DE    ( visible_range_r ),
        .D     ( green_i         ),
        .q_out ( green_tmds      )
    );

    tmds_encoder red_encoder (
        .clk_i ( pixel_clk_i     ),
        .rst_i ( rst_i           ),
        .C0    ( 1'b0            ),
        .C1    ( 1'b0            ),
        .DE    ( visible_range_r ),
        .D     ( red_i           ),
        .q_out ( red_tmds        )
    );

    // ------------------------------------------------------------------------
    // Serialize
    // ------------------------------------------------------------------------

    serializer #(
        .DATA_W ( 10 )
    ) blue_serializer (
        .clk_i  ( serial_clk_i ),
        .rst_i  ( rst_i        ),
        .data_i ( blue_tmds    ),
        .data_o ( blue_serial_o  )
    );

    serializer #(
        .DATA_W ( 10 )
    ) green_serializer (
        .clk_i  ( serial_clk_i ),
        .rst_i  ( rst_i        ),
        .data_i ( green_tmds   ),
        .data_o ( green_serial_o )
    );

    serializer #(
        .DATA_W ( 10 )
    ) red_serializer (
        .clk_i  ( serial_clk_i ),
        .rst_i  ( rst_i        ),
        .data_i ( red_tmds     ),
        .data_o ( red_serial_o   )
    );

endmodule


module dvi_sync (
    input  logic               clk_i,
    input  logic               rst_i,
    output logic               hsync_o,
    output logic               vsync_o,
    output logic [X_POS_W-1:0] pixel_x_o,
    output logic [Y_POS_W-1:0] pixel_y_o,
    output logic               visible_range_o
);

    logic            h_cnt_max;
    logic [HS_W-1:0] h_cnt_next;
    logic [HS_W-1:0] h_cnt;
    logic [VS_W-1:0] v_cnt_next;
    logic [VS_W-1:0] v_cnt;

    always_comb begin
        h_cnt_max  = h_cnt == (H_TOTAL - 1);
        h_cnt_next = h_cnt_max ? '0 : h_cnt + 1'b1;
        v_cnt_next = v_cnt;

        if (h_cnt_max) begin
            v_cnt_next = v_cnt + 1'b1;

            if (v_cnt == (V_TOTAL - 1))
                v_cnt_next = '0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            h_cnt <= '0;
            v_cnt <= '0;
        end else begin
            h_cnt <= h_cnt_next;
            v_cnt <= v_cnt_next;
        end
    end

    // Register outputs
    always_ff @(posedge clk_i)
        if (rst_i) begin
            hsync_o         <= '0;
            vsync_o         <= '0;
            pixel_x_o       <= '0;
            pixel_y_o       <= '0;
            visible_range_o <= '0;
        end else begin
            hsync_o         <= !(h_cnt_next >= HSYNC_START && h_cnt_next < HSYNC_END);
            vsync_o         <= !(v_cnt_next >= VSYNC_START && v_cnt_next < VSYNC_END);

            pixel_x_o       <=  (h_cnt_next > SCREEN_H_RES - 1) ? '0 : X_POS_W'(h_cnt_next);
            pixel_y_o       <=  (v_cnt_next > SCREEN_V_RES - 1) ? '0 : Y_POS_W'(v_cnt_next);

            visible_range_o <=  ((h_cnt_next < SCREEN_H_RES) && (v_cnt_next < SCREEN_V_RES));
        end

endmodule


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
