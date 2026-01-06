module find_min_index
(
    input  logic              clk,
    input  logic              start,
    input  logic [15:0][12:0] level,
    output logic       [ 3:0] min_index
);

    logic        [ 7:0][13:0] sum_1;
    logic        [ 3:0][14:0] sum_2;
    logic        [ 1:0][15:0] sum_3;
    logic              [ 2:0] counter;

    always_ff @(posedge clk) begin
        if (start) begin
            min_index <= '0;
            sum_1     <= '0;
            sum_2     <= '0;
            sum_3     <= '0;
            counter   <= '0;
        end
        else if (counter < 7) begin
            case (counter)
            // Finding pairwise sums, simplified algorithm finding the minimum number
                0: begin // 1/8 from range
                    sum_1[0] <= level[ 0] + level[ 1];
                    sum_1[1] <= level[ 2] + level[ 3];
                    sum_1[2] <= level[ 4] + level[ 5];
                    sum_1[3] <= level[ 6] + level[ 7];
                    sum_1[4] <= level[ 8] + level[ 9];
                    sum_1[5] <= level[10] + level[11];
                    sum_1[6] <= level[12] + level[13];
                    sum_1[7] <= level[14] + level[15];
                end
                1: begin // 1/4 from range
                    sum_2[0] <= sum_1[0] + sum_1[1];
                    sum_2[1] <= sum_1[2] + sum_1[3];
                    sum_2[2] <= sum_1[4] + sum_1[5];
                    sum_2[3] <= sum_1[6] + sum_1[7];
                end
                2: begin // 1/2 from range
                    sum_3[0] <= sum_2[0] + sum_2[1];
                    sum_3[1] <= sum_2[2] + sum_2[3];
                end
            // Comparison from large halves to small ones
                3: min_index[3] <= sum_3[1] <= sum_3[0];     // 1/2 If all = then the middle
                4: min_index[2] <= sum_2[min_index[3]*2 + 1] < sum_2[min_index[3]*2]; // 1/4
                5: min_index[1] <= sum_1[{min_index[3], min_index[2]}*2 + 1] <        // 1/8
                                   sum_1[{min_index[3], min_index[2]}*2];
                6: min_index[0] <= level[{min_index[3], min_index[2], min_index[1]}*2 + 1] <
                                   level[{min_index[3], min_index[2], min_index[1]}*2];
            endcase
            counter <= counter + 1'b1;
        end
    end

endmodule