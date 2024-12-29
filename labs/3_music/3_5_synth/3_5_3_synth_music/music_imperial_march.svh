localparam   MEMORY_DEPTH = 28;

logic [10:0] melody_rom;

// Notes (from 0 to 11) C, Cd, D, Dd, E, F, Fd, G, Gd, A, Ad, B
// Octaves (from 0 to 3) THIRD, SECOND, FIRST, SMALL

always_comb begin
    case(quant_cnt_ff) //  en    1/8   note  octave
        'd0: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd1: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};

        'd2: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd3: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};

        'd4: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd5: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};
  
        'd6: melody_rom = {1'b1, 4'd1, 4'd3, 2'd2};
        'd7: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd8: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd9: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};

        'd10: melody_rom = {1'b1, 4'd1, 4'd3, 2'd2};
        'd11: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd12: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd13: melody_rom = {1'b0, 4'd3, 4'd7, 2'd2};

        'd14: melody_rom = {1'b1, 4'd1, 4'd2, 2'd1};
        'd15: melody_rom = {1'b0, 4'd1, 4'd2, 2'd1};

        'd16: melody_rom = {1'b1, 4'd1, 4'd2, 2'd1};
        'd17: melody_rom = {1'b0, 4'd1, 4'd2, 2'd1};

        'd18: melody_rom = {1'b1, 4'd1, 4'd2, 2'd1};
        'd19: melody_rom = {1'b0, 4'd1, 4'd2, 2'd1};

        'd20: melody_rom = {1'b1, 4'd1, 4'd3, 2'd1};
        'd21: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd22: melody_rom = {1'b1, 4'd1, 4'd6, 2'd2};
        'd23: melody_rom = {1'b0, 4'd1, 4'd6, 2'd2};

        'd24: melody_rom = {1'b1, 4'd1, 4'd3, 2'd2};
        'd25: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd26: melody_rom = {1'b1, 4'd3, 4'd7, 2'd2};

        'd27: melody_rom = {1'b0, 4'd8, 4'd0, 2'd0};

        default: melody_rom = {1'b0, 4'd1, 4'd0, 2'd0};
    endcase
end
